# Description: This file contains the initialization of the parameters used in the optimization model.

using YAML

# Construct the path to the YAML file dynamically relative to this script's location
parameters_path = joinpath(@__DIR__, "inputs", "parameters.yaml")

# Load project settings and parameters
parameters = YAML.load_file(parameters_path)

# EXTRACT PARAMETERS
# ------------------

# Extract project settings
connections = parameters["project_settings"]["connections"] # Number of connections
project_lifetime = parameters["project_settings"]["project_lifetime"] # Project lifetime [years]
operation_time_steps = parameters["project_settings"]["operation_time_steps"]   # Operation time steps [hours]
Δt = parameters["project_settings"]["time_step_duration"] # Time resolution (1 if hourly) in hours
grid_mode_model = parameters["project_settings"]["grid_mode_model"] # Grid mode model: "ongrid" or "offgrid"
capex_model = parameters["project_settings"]["capex_model"] # Capex model: "upfront" or "annuity"
max_capex = parameters["project_settings"]["max_capex"] # Maximum CAPEX constraint [USD]
wacc_calculation = parameters["project_settings"]["wacc_calculation"] # WACC calculation "true" or "false"
wacc_params = parameters["project_settings"]["wacc"] # Weighted Average Cost of Capital (WACC) parameters

# Extract Subsidies
capital_cost_subsidies = parameters["project_settings"]["subsidies"]["capital_cost_subsidies"]
subsidies_per_connection = parameters["project_settings"]["subsidies"]["subsidies_per_connection"]

# Pricing Model
pricing_model = parameters["project_settings"]["pricing_model"]["optimization_mode"] # Optimization mode: "payback_driven" or "tariff_driven"
payback_period = parameters["project_settings"]["pricing_model"]["payback_period"]   # Payback period [years]

# Extract Solar PV params
solar_capex = parameters["solar"]["capex"]                  # Specific investment cost in USD/kW
solar_opex = parameters["solar"]["opex"]                    # O&M cost in USD/kWh
solar_lifetime = parameters["solar"]["lifetime"]            # Lifetime of solar PV system [years]

# Extract Battery params    
battery_capex = parameters["battery"]["capex"]                      # Specific investment cost in USD/kWh
battery_opex = parameters["battery"]["opex"]                        # O&M cost in USD/kWh
battery_lifetime = parameters["battery"]["lifetime"]                # Expected battery lifetime [years]
η_charge = parameters["battery"]["efficiency"]["charge"]            # Charging efficiency [-]
η_discharge = parameters["battery"]["efficiency"]["discharge"]      # Discharging efficiency [-]
SOC_min = parameters["battery"]["SOC"]["min"]                       # Minimum state of charge [-]
SOC_max = parameters["battery"]["SOC"]["max"]                       # Maximum state of charge [-]
SOC_0 = parameters["battery"]["SOC"]["initial"]                     # Initial state of charge [-]
t_charge = parameters["battery"]["operation"]["charge_time"]        # Charging time [hours]
t_discharge = parameters["battery"]["operation"]["discharge_time"]  # Discharging time [hours]

# Extract Diesel Generator params
gen_capex = parameters["generator"]["capex"]                  # Specific investment cost in USD/kW
fuel_cost = parameters["generator"]["fuel_cost"]              # Diesel generation cost [USD/kWh]
gen_lifetime = parameters["generator"]["lifetime"]            # Lifetime of diesel generator [years]



# PREPROCESS PARAMETERS
# ---------------------

# Calculate the number of time steps per year
steps_per_year = 8760 / operation_time_steps
println("\nNumber of time steps per year: ", steps_per_year)

# Define a function to calculate the Weighted Average Cost of Capital
function calculate_wacc(wacc_params)
    equity_share = wacc_params["equity_share"]
    debt_share = wacc_params["debt_share"]
    cost_of_equity = wacc_params["cost_of_equity"]
    cost_of_debt = wacc_params["cost_of_debt"]
    tax_rate = wacc_params["tax_rate"]

    if equity_share == 0
        return cost_of_debt * (1 - tax_rate)
    else
        L = debt_share / equity_share  # Leverage Ratio
        return (cost_of_debt * (1 - tax_rate) * L / (1 + L)) + (cost_of_equity * (1 / (1 + L)))
    end
end

if wacc_calculation
    discount_rate = calculate_wacc(wacc_params)
    println("\nWeighted Average Cost of Capital (WACC): ", round(discount_rate * 100, digits=2), "%")
else
    discount_rate = parameters["project_settings"]["nominal_discount_rate"]  # Use nominal discount rate
end

# Calculate the yearly discount factor
discount_factor = [1 / ((1 + discount_rate) ^ y) for y in 1:project_lifetime]

# Calculate the Replacement Costs for each component
n_replacement_solar   = max(0, floor((project_lifetime - 1) / solar_lifetime))
n_replacement_battery = max(0, floor((project_lifetime - 1) / battery_lifetime))
n_replacement_gen     = max(0, floor((project_lifetime - 1) / gen_lifetime))

println("\nReplacements for each component:")
println("   Solar PV: ", n_replacement_solar)
println("   Battery:  ", n_replacement_battery)
println("   Generator:", n_replacement_gen)

# Function to calculate the discounted replacement cost
function discounted_replacement_factor(lifetime::Int, project_lifetime::Int, discount_rate::Float64)
    # Calculate the number of replacements
    N = max(0, floor((project_lifetime - 1) / lifetime))

    total = 0.0
    for k in 1:N
        year = k * lifetime
        total += 1.0 / (1.0 + discount_rate)^year
    end
    return total
end

# Calculate the replacement factors for each component
replacement_factor_solar = discounted_replacement_factor(solar_lifetime, project_lifetime, discount_rate)
replacement_factor_battery = discounted_replacement_factor(battery_lifetime, project_lifetime, discount_rate)
replacement_factor_gen = discounted_replacement_factor(gen_lifetime, project_lifetime, discount_rate)

function calculate_unused_life(n_replacement, lifetime::Int, project_lifetime::Int)
    t_last = n_replacement * lifetime
    return max(0, lifetime - (project_lifetime - t_last))
end

# Calculate the unused life for each component
unused_life_solar = calculate_unused_life(n_replacement_solar, solar_lifetime, project_lifetime)
unused_life_battery = calculate_unused_life(n_replacement_battery, battery_lifetime, project_lifetime)
unused_life_gen = calculate_unused_life(n_replacement_gen, gen_lifetime, project_lifetime)


# Function to calculate the annuity factor for a loan
function loan_annuity_factor(loan_interest_rate::Float64, discount_rate::Float64, loan_years::Int)
    # Define useful alias
    i = loan_interest_rate
    r = discount_rate
    n = loan_years

    # Annual payment to amortize $1 over n years at rate i:
    A = i * (1 + i)^n / ((1 + i)^n - 1)

    # Discounted sum of paying A each year for n years at discount rate r
    annuity_factor = 0.0
    if r == 0.0
        # if discount_rate = 0, just multiply A by n
        annuity_factor = A * n
    else
        annuity_factor = A * ((1 - (1/(1+r))^n) / r)
    end

    return annuity_factor
end

# Calculate the loan factor if capex_model is "loan"
if capex_model == "loan"
    loan_interest_rate = parameters["project_settings"]["loan_interest_rate"]  # Loan interest rate
    loan_duration = parameters["project_settings"]["loan_duration"]            # Loan duration [years]
    loan_factor   = loan_annuity_factor(loan_interest_rate, discount_rate, loan_duration)
end

