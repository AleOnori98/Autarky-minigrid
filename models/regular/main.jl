"""
This code is used to define a minigrid dispatch optimization model with the regular "deterministic" model.
The regular model does not include probabilistic constraints or expected values, but instead optimizes based on deterministic values for all variables.

IGNORES FORECASTING ERRORS and OUTAGES (LINEAR MODEL)
"""

# Importing the required packages and functions
using JuMP, GLPK

include(joinpath(@__DIR__, "..", "..", "utils.jl"))
using .Utils: import_time_series, load_and_validate_time_series, load_and_validate_grid_params, write_results_to_csv


"""
Main function to run the regular sizing model.
"""
function main()

    # PRE-PROCESSING
    # --------------

    # Initialize parameters
    include(joinpath(@__DIR__, "parameters_initialization.jl"))

    # Define input paths relative to the current directory
    load_predictions_path = joinpath(@__DIR__, "inputs", "load_predictions.csv")
    solar_predictions_path = joinpath(@__DIR__, "inputs", "solar_predictions.csv")

    # Load and validate time series data
    load = load_and_validate_time_series(load_predictions_path, parameters, "Load Predictions Data") # [kWh]
    solar_unit_production = load_and_validate_time_series(solar_predictions_path, parameters, "Solar Predictions Data") # [kWh/kW]

    # Load grid parameters
    grid_parameters_path = joinpath(@__DIR__, "inputs", "grid_parameters.csv")
    grid_params = import_time_series(grid_parameters_path)
    grid_cost, grid_price, grid_cap = load_and_validate_grid_params(grid_params, parameters)

    # MODEL INITIALIZATION
    # --------------------

    # Initialize the optimization model
    println("\nInitializing the optimization model...")
    model = Model()
    
    # SETS 
    T = operation_time_steps # Total number of time steps for operation time series [hours]

    # DECISION VARIABLES
    # ------------------

    # System Sizing
    @variable(model, solar_capacity >= 0, base_name="Solar_Capacity") # [kW]
    @variable(model, battery_capacity >= 0, base_name="Battery_Capacity") # [kWh]
    @variable(model, gen_capacity >= 0, base_name="Generator_Capacity") # [kW]

    # Operation
    @variable(model, solar_production[t=1:T] >= 0, base_name="Solar_Production") # [kWh]
    @variable(model, battery_charge[t=1:T] >= 0, base_name="Battery_Charge") # [kWh]
    @variable(model, battery_discharge[t=1:T] >= 0, base_name="Battery_Discharge") # [kWh]
    @variable(model, SOC[t=1:T], base_name="State_of_Charge") # [kWh]
    @variable(model, gen_production[t=1:T] >= 0, base_name="Generator_Production") # [kWh]
    # Grid Import/Export (if applicable)
    if grid_mode_model == "ongrid"
        @variable(model, 0 <= grid_import[t=1:T]<=grid_cap[t], base_name="Grid_Import") # [kWh]
        @variable(model, 0 <= grid_export[t=1:T]<=grid_cap[t], base_name="Grid_Export") # [kWh]
        @variable(model, grid_mode[t=1:T], Bin)  # Binary variable to control import/export mode
    end

    # Pricing model (if applicable)
    if pricing_model == "payback_driven"
        @variable(model, retail_tariff >= 0, base_name="Retail_Tariff") # [USD/kWh]
    else
        retail_tariff = parameters["project_settings"]["pricing_model"]["retail_tariff"] # Fixed value from input parameters
    end

    # CONSTRAINTS
    # -----------

    # Energy Balance
    if grid_mode_model == "ongrid"
        @constraint(model, [t=1:T], solar_production[t] + (battery_discharge[t] - battery_charge[t]) + gen_production[t] + (grid_import[t] - grid_export[t]) == load[t])
    else
        @constraint(model, [t=1:T], solar_production[t] + (battery_discharge[t] - battery_charge[t]) + gen_production[t] == load[t])
    end

    # Solar PV Operation
    @constraint(model, [t=1:T], solar_production[t] <= (solar_capacity*solar_unit_production[t]))
    
    # Battery Energy Flows 
    @constraint(model, [t=1:T], battery_charge[t] <= (battery_capacity/t_charge)*Δt)
    @constraint(model, [t=1:T], battery_discharge[t] <= (battery_capacity/t_discharge)*Δt)

    # Battery SOC 
    @constraint(model, [t=1:T], SOC[t] >= SOC_min*battery_capacity)
    @constraint(model, [t=1:T], SOC[t] <= SOC_max*battery_capacity)
    @constraint(model, SOC[1] == (SOC_0*battery_capacity) + (battery_charge[1]*η_charge - battery_discharge[1]*η_discharge)) # Initial SOC [kWh]
    @constraint(model, [t=2:T], SOC[t] == SOC[t-1] + (battery_charge[t]*η_charge - battery_discharge[t]*η_discharge)) # SOC continuity [kWh]
    @constraint(model, SOC[T] == SOC_0*battery_capacity)  # End-of-horizon SOC continuity [kWh]

    # Generator Operation
    @constraint(model, [t=1:T], gen_production[t] <= (gen_capacity*Δt))

    # Grid Import/Export single flow constraints (if applicable)
    if grid_mode_model == "ongrid"
        @constraint(model, [t=1:T], grid_import[t] <= grid_cap[t] * grid_mode[t])       # Import only if grid_mode[t] == 1
        @constraint(model, [t=1:T], grid_export[t] <= grid_cap[t] * (1 - grid_mode[t])) # Export only if grid_mode[t] == 0
    end

    # PROJECT COSTS EXPRESSIONS
    #--------------------------

    # CAPEX (based on the chosen model)
    if capex_model == "upfront"
        @expression(model, CAPEX, (solar_capacity   * solar_capex) + 
                                  (battery_capacity * battery_capex) + 
                                  (gen_capacity     * gen_capex))

    else  # "loan" case
        @expression(model, CAPEX, ((solar_capacity  * solar_capex) + 
                                  (battery_capacity * battery_capex) + 
                                  (gen_capacity     * gen_capex)) * loan_factor)
    end

    # Replacement Costs
    @expression(model, Replacement_Costs, (solar_capacity   * solar_capex   * replacement_factor_solar) + 
                                          (battery_capacity * battery_capex * replacement_factor_battery) + 
                                          (gen_capacity     * gen_capex     * replacement_factor_gen))

    # OPEX (per hour) for each t
    if grid_mode_model == "ongrid"
        @expression(model, OPEX[t=1:T], (solar_production[t] * solar_opex) + 
                                        ((battery_charge[t] + battery_discharge[t]) * battery_opex) + 
                                        (gen_production[t] * fuel_cost) + 
                                        (grid_import[t] * grid_cost[t]) - (grid_export[t] * grid_price[t]))
    else
        @expression(model, OPEX[t=1:T], (solar_production[t] * solar_opex) + 
                                        ((battery_charge[t] + battery_discharge[t]) * battery_opex) + 
                                        (gen_production[t] * fuel_cost))
    end

    # Total Discounted OPEX (Present Value)
    @expression(model, OPEX_npv, sum((sum(OPEX[t] for t in 1:T) * steps_per_year) * discount_factor[y] for y in 1:project_lifetime))

    # Subsidies
    @expression(model, Subsidies, (CAPEX * (1 - capital_cost_subsidies)) + (connections * subsidies_per_connection))

    # Salvage Value
    @expression(model, Salvage_Value, ((solar_capacity  * solar_capex)   * (unused_life_solar   / solar_lifetime) + 
                                      (battery_capacity * battery_capex) * (unused_life_battery / battery_lifetime) + 
                                      (gen_capacity     * gen_capex)     * (unused_life_gen     / gen_lifetime)) * discount_factor[project_lifetime])

    # Revenues from grid sales
    @expression(model, Revenues, sum((sum(load[t] * retail_tariff for t in 1:T) * steps_per_year) * discount_factor[y] for y in 1:project_lifetime))

    # Net Present Cost
    @expression(model, NPC, (CAPEX + Replacement_Costs + OPEX_npv) - (Subsidies + Revenues + Salvage_Value))

    # OPTIMIZATION CONSTRAINTS
    # ------------------------

    # Maximum CAPEX constraint based on number of connections
    @constraint(model, CAPEX <= (max_capex * connections))

    if pricing_model == "payback_driven"
        # Calculate the base case OPEX (buying all energy from the grid)
        base_case_OPEX = (sum(grid_cost[t] * load[t] for t in 1:T) * steps_per_year)  # USD/year

        # Ensure that the CAPEX is recovered within the specified payback period using annual cash flows (savings + revenues)
        @constraint(model, sum(((sum(load[t] * retail_tariff for t in 1:T) * steps_per_year)) / ((1 + discount_rate)^y) for y in 1:payback_period) == CAPEX)
    end

    # OBJECTIVE FUNCTION
    # ------------------

    @objective(model, Min, NPC)

    println("Model initialized successfully")

    # SOLVING THE MODEL
    # -----------------

    # Initialize Ipopt solver
    optimizer = optimizer_with_attributes(GLPK.Optimizer)

    # Setting solver options
    solver_settings = parameters["solver_settings"]["glpk_options"]
    println("\nSolving the optimization model using GLPK...")
    for (key, value) in solver_settings
        set_optimizer_attribute(optimizer, key, value)
    end

    # Attach the solver to the model
    set_optimizer(model, optimizer)

    # Solve the optimization problem
    @time optimize!(model)
    solution_summary(model, verbose = true)

    # Display the main results
    println("\n====================== Optimization Results ======================")
    println("Objective Value (NPC): ", round(objective_value(model) / 1000, digits=2), " kUSD")

    println("\nSystem Sizing:")
    println("  Solar Capacity: ", round(value(solar_capacity), digits=2), " kW")
    println("  Battery Capacity: ", round(value(battery_capacity), digits=2), " kWh")
    println("  Generator Capacity: ", round(value(gen_capacity), digits=2), " kW")

    println("\nProject Costs and Revenues:")
    println("  Total CAPEX ($capex_model model): ", round(value(CAPEX) / 1000, digits=2), " kUSD")
    println("  Discounted Replacement Costs: ", round(value(Replacement_Costs) / 1000, digits=2), " kUSD")
    println("  Discounted OPEX: ", round(value(OPEX_npv) / 1000, digits=2), " kUSD")
    println("  Salvage Value: ", round(value(Salvage_Value) / 1000, digits=2), " kUSD")
    println("  Revenue from Electricity Sales: ", round(value(Revenues) / 1000, digits=2), " kUSD")
    println("  Total Subsidies Applied: ", round(value(Subsidies) / 1000, digits=2), " kUSD")

    println("\nSystem Operation:")
    println("  Average Yearly PV Production: ", round((sum(value(solar_production[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    println("  Average Yearly Battery Charging: ", round((sum(value(battery_charge[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    println("  Average Yearly Battery Discharging: ", round((sum(value(battery_discharge[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    println("  Average Yearly Generator Production: ", round((sum(value(gen_production[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    if grid_mode_model == "ongrid"
        println("  Average Yearly Grid Import: ", round((sum(value(grid_import[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
        println("  Average Yearly Grid Export: ", round((sum(value(grid_export[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    end

    println("\nPricing Model:")
    if pricing_model == "tariff_driven"

        # Returns the discounted payback period in years, or 0 if not reached within max_years.
        function compute_discounted_payback(capex::Float64,annual_cashflow::Float64,discount_rate::Float64,max_years::Int)

            discounted_sum = 0.0
            payback_yr = 0

            for y in 1:max_years
                # discount the cashflow from year y
                discounted_flow = annual_cashflow / (1.0 + discount_rate)^y
                # accumulate
                discounted_sum += discounted_flow

                # check if we've covered CAPEX
                if discounted_sum >= capex
                    payback_yr = y
                    break
                end
            end

            return payback_yr
        end

        payback_yr_d = compute_discounted_payback(value(CAPEX), annual_savings, discount_rate, project_lifetime)
        if payback_yr_d > 0
            println("  Discounted Payback (w/o Revenues): $payback_yr_d years")
        else
            println("  Discounted Payback not reached (w/o Revenues) within project lifetime ($project_lifetime years).")
        end

        # With Revenues
        payback_yr_d_rev = compute_discounted_payback(value(CAPEX), (annual_savings + annual_revenues), discount_rate, project_lifetime)
        if payback_yr_d_rev > 0
            println("  Discounted Payback (with Revenues): $payback_yr_d_rev years")
        else
            println("  Discounted Payback not reached (with Revenues) within project lifetime ($project_lifetime years).")
        end
        println("  Retail Tariff (input parameter): $retail_tariff USD/kWh")
    else
        println("  Payback Period (input parameter): $payback_period years")
        println("  Optimal Retail Tariff: ", round(value(retail_tariff), digits=4), " USD/kWh")
    end
    println("================================================================")

    # POST-PROCESSING
    # ---------------

    # File path for the results Excel file
    project_sizing_path = joinpath(@__DIR__, "results", "project_sizing.csv")
    dispatch_path = joinpath(@__DIR__, "results", "optimal_dispatch.csv")
    # Write results to Excel
    optimal_dispatch = write_results_to_csv(project_sizing_path, dispatch_path, model, load, solar_unit_production, T, grid_mode_model)
    println("Results exported to $project_sizing_path and $dispatch_path")


end

# Run the main function
main()



