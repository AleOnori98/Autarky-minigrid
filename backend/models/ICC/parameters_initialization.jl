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
capex_model = parameters["project_settings"]["capex_model"] # Capex model: "upfront" or "annuity"
max_capex = parameters["project_settings"]["max_capex"] # Maximum CAPEX constraint [USD]
wacc_calculation = parameters["project_settings"]["wacc_calculation"] # WACC calculation "true" or "false"
wacc_params = parameters["project_settings"]["wacc"] # Weighted Average Cost of Capital (WACC) parameters

# Extract Subsidies
capital_cost_subsidies = parameters["project_settings"]["subsidies"]["capital_cost_subsidies"]
subsidies_per_connection = parameters["project_settings"]["subsidies"]["subsidies_per_connection"]

# Extract probability settings
n_simulations = parameters["uncertainty"]["n_simulations"]    # Number of simulations in errors data
outage = parameters["uncertainty"]["outage_duration"]         # Expected outage duration [hours]
outage_probability = parameters["uncertainty"]["outage_probability"]        # Probability of an outage [-]
islanding_probability = parameters["uncertainty"]["islanding_probability"]  # Probability of islanding [-]

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

# Extract Grid params (scalars)
day_ahead_price = parameters["grid"]["day_ahead_price"]            # Day-ahead electricity price [USD/kWh]
grid_exchange_cost = parameters["grid"]["grid_exchange_cost"]      # Grid exchange cost [USD/kWh]

# Extract retail tariff
retail_tariff = parameters["retail_tariff"]["elec_price"]     # Retail electricity tariff [USD/kWh]

# PREPROCESS PARAMETERS
# ---------------------

# Calculate the number of time steps per year
steps_per_year = 8760 / (operation_time_steps + outage)
println("\nNumber of time steps per year: ", steps_per_year)

# Calculate the Replacement Costs for each component
n_replacement_solar = max(0, floor(Int, project_lifetime / solar_lifetime) - 1)
n_replacement_battery = max(0, floor(Int, project_lifetime / battery_lifetime) - 1)
n_replacement_gen = max(0, floor(Int, project_lifetime / gen_lifetime) - 1)

# Print the number of replacements for each component
println("\nReplacements for each componenet:")
println("   Number of replacements for Solar PV: ", n_replacement_solar)
println("   Number of replacements for Battery: ", n_replacement_battery)
println("   Number of replacements for Diesel Generator: ", n_replacement_gen)

# Calculate the Replacement Costs for each component
replacement_cost_solar = solar_capex * n_replacement_solar
replacement_cost_battery = battery_capex * n_replacement_battery
replacement_cost_gen = gen_capex * n_replacement_gen

# Define a function to calculate CRF
function calc_crf(r::Float64, lifetime::Int)
    if lifetime <= 0
        error("Lifetime must be a positive integer.")
    end
    return r * (1+r)^lifetime / ((1+r)^lifetime - 1)
end

# Calculate the Capital Recovery Factors (CRF) to Annualize CAPEX
if capex_model == "annuity"
    # Compute CRF for each component
    CRF_solar     = calc_crf(discount_rate, solar_lifetime)
    CRF_battery   = calc_crf(discount_rate, battery_lifetime)
    CRF_gen       = calc_crf(discount_rate, gen_lifetime)

    # Print the CRF values
    println("\nCapital Recovery Factors (CRF):")
    println("   CRF for Solar PV: ", CRF_solar)
    println("   CRF for Battery: ", CRF_battery)
    println("   CRF for Diesel Generator: ", CRF_gen)
end

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