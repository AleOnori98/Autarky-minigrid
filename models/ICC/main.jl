"""
This code is used to define a minigrid dispatch optimization model with expected values rather than probabilistic constraints. 
Here, uncertainties are replaced with their expected values, creating a deterministic model that optimizes based on average scenarios rather than accounting for high-probability outcomes.
The Expected Value model assumes the model will operate “on average” rather than guaranteeing performance under uncertain or extreme conditions. 
"""

# Importing the required packages and functions
using JuMP, Ipopt, CSV, DataFrames, LinearAlgebra, Statistics, Distributions
import HSL_jll

include(joinpath(@__DIR__,"..", "..", "..", "utils.jl"))
using .Utils: import_time_series, load_and_validate_time_series, load_and_validate_grid_params, load_and_validate_errors,
              write_results_to_csv, write_raw_results_to_csv, create_dispatch_plot
include(joinpath(@__DIR__,"..", "..", "..", "utils_uncertainty.jl"))
using .Utils_Uncertainty: test_normality, ensure_positive_semidefinite

"""
Main function to run the expected values sizing model.
"""
function main()
    
    # PRE-PROCESSING
    # --------------

    # Initialize parameters
    include(joinpath(@__DIR__, "parameters_initialization.jl"))

    # Define input paths relative to the current directory
    load_predictions_path = joinpath(@__DIR__, "inputs", "load_predictions.csv")
    solar_predictions_path = joinpath(@__DIR__, "inputs", "solar_predictions.csv")
    grid_parameters_path = joinpath(@__DIR__, "inputs", "grid_parameters.csv")
    load_errors_path = joinpath(@__DIR__, "inputs", "load_errors.csv")
    solar_errors_path = joinpath(@__DIR__, "inputs", "solar_errors.csv")

    # Load and validate time series data
    load = load_and_validate_time_series(load_predictions_path, parameters, "Load Predictions Data", uncertainty=true)
    solar_unit_production = load_and_validate_time_series(solar_predictions_path, parameters, "Solar Predictions Data", uncertainty=true)

    # Load grid parameters
    grid_params = import_time_series(grid_parameters_path)
    grid_cost, grid_price, grid_cap = load_and_validate_grid_params(grid_params, parameters, uncertainty=true)

    # Load predictions errors 
    load_errors = load_and_validate_errors(load_errors_path, parameters, "Load Predictions Errors")
    solar_errors = load_and_validate_errors(solar_errors_path, parameters, "Solar Predictions Errors")

    println("\nTesting normality...")
    test_normality(load_errors, "Load")
    test_normality(solar_errors, "Solar")

    println("\nCalculating covariance matrix...")
    load_cov_matrix = cov(Matrix(load_errors); dims=2)   # Transpose to get the right shape
    solar_cov_matrix = cov(Matrix(solar_errors); dims=2) # Transpose to get the right shape

    println("\nEnsuring positive semi-definiteness...")
    load_cov_matrix = ensure_positive_semidefinite(load_cov_matrix, "Load")
    solar_cov_matrix = ensure_positive_semidefinite(solar_cov_matrix, "Solar")

    # Compute the multi-variate covariance matrix of the errors (ASSUMPTION: errors are independent and normally distributed)
    errors_cov_matrix = load_cov_matrix + solar_cov_matrix
    errors_cov_matrix = ensure_positive_semidefinite(errors_cov_matrix, "Multi-variate")

    # Compute the standard deviation vector of the forecasting errors (ASSUMPTION: errors distribution are centred around zero -> for unbiased forecasts).
    σ = diag(errors_cov_matrix, 0).^0.5 
    println("Average standard deviation  of the forecasting errors: ", round(mean(σ), digits=2), " kW")

    # Compute the mean vector of the forecasting errors
    μ = vec([0 for i in 1:operation_time_steps+outage]) # (ASSUMPTION: errors distribution are centred around zero -> for unbiased forecasts).
    println("Average mean of the forecasting errors: ", round(mean(μ), digits=2), " kW")

    # Error function for the individual case (defined with the variance)
    ξ = []
    for i in 1:operation_time_steps+outage
	    append!(ξ, [Normal(μ[i], σ[i])]) # normal distribution for the errors
    end
        
    # Calculate the quantiles for the islanding probability
    Q_t = [quantile(ξ[t], islanding_probability) for t in 1:operation_time_steps+outage]

    # MODEL INITIALIZATION
    # --------------------

    # Initialize the optimization model
    model = Model()

    # SETS 
    T = operation_time_steps + outage # Total number of time steps for operation time series [hours]

    # DECISION VARIABLES
    # ------------------

    # System Sizing
    @variable(model, solar_capacity >= 0, start=123, base_name="Solar_Capacity") # [kW]
    @variable(model, battery_capacity >= 0, start=0, base_name="Battery_Capacity") # [kWh]
    @variable(model, gen_capacity >= 0, start=18.95, base_name="Generator_Capacity") # [kW]

    # Operation
    @variable(model, solar_production[t=1:T] >= 0, base_name="Solar_Production") # [kWh]
    @variable(model, battery_charge[t=1:T] >= 0, base_name="Battery_Charge") # [kWh]
    @variable(model, battery_discharge[t=1:T] >= 0, base_name="Battery_Discharge") # [kWh]
    @variable(model, SOC[t=1:T], base_name="State_of_Charge") # [kWh]
    @variable(model, gen_production[t=1:T] >= 0, base_name="Generator_Production") # [kWh]
    @variable(model, 0 <= grid_import[t=1:T]<=grid_cap[t], base_name="Grid_Import") # [kWh]
    @variable(model, 0 <= grid_export[t=1:T]<=grid_cap[t], base_name="Grid_Export") # [kWh]
    # Uncertainty
    @variable(model, expected_shortfall[t=1:T] >= 0, base_name="Expected_Shortfall") # [kWh]

    # Reserves to account for outages
    @variable(model, battery_reserve[t=1:T] >= 0, base_name="Battery_Reserve") # [kWh]
    @variable(model, gen_reserve[t=1:T] >= 0, base_name="Generator_Reserve") # [kWh]

    # OPERATION CONSTRAINTS
    # ---------------------

    # Energy balance constraint with reserves
    @constraint(model, [t=1:T], solar_production[t] + (battery_discharge[t] - battery_charge[t]) + battery_reserve[t] + gen_production[t] + gen_reserve[t] - load[t] >= Q_t[t])

    # Solar PV Operation
    @constraint(model, [t=1:T], solar_production[t] <= (solar_capacity*solar_unit_production[t]))
    
    # Battery Energy Flows 
    @constraint(model, [t=1:T], battery_charge[t] <= (battery_capacity/t_charge)*Δt)
    @constraint(model, [t=1:T], battery_discharge[t] + battery_reserve[t] <= (battery_capacity/t_discharge)*Δt)

    # Battery SOC 
    @constraint(model, [t=1:T], SOC[t] >= SOC_min*battery_capacity)
    @constraint(model, [t=1:T], SOC[t] <= SOC_max*battery_capacity)
    @constraint(model, SOC[1] == (SOC_0*battery_capacity) + (battery_charge[1]*η_charge - battery_discharge[1]*η_discharge)) # Initial SOC [kWh]
    @constraint(model, [t=2:T], SOC[t] == SOC[t-1] + (battery_charge[t]*η_charge - battery_discharge[t]*η_discharge)) # SOC continuity [kWh]
    @constraint(model, SOC[T] == SOC_0*battery_capacity)  # End-of-horizon SOC continuity [kWh]
    # SOC Under Reserves (During Outages)
    for t in 1:T
        for τ in 1:max(t-outage, 1)
            @constraint(model, SOC_min*battery_capacity <= SOC[t] - sum(battery_reserve[s]*η_discharge for s in τ:min(τ+outage, t)))
        end 
    end

    # Generator Operation
    @constraint(model, [t=1:T], gen_production[t] + gen_reserve[t] <= (gen_capacity*Δt))
	
    # Function to calculate the expected cost (and its gradient) of importing energy, considering uncertainty in solar generation and demand (expected shortfall)
	function define(t, grid_cost, grid_exchange_cost, σ)
		c = grid_cost[t] + grid_exchange_cost
		var = σ[t]
        # Nonlinear dispatch cost function
		ψ(y...) = c * var * pdf(Normal(), y[t]/var) + c * y[t] * cdf(Normal(), y[t]/var)
		# Gradient of the expected dispatch function
		function ∇ψ(g::AbstractVector{T}, y::T...) where {T}
			for i in eachindex(y)
				if i == t
					g[i] = c * cdf(Normal(), y[i]/var) * 1
				else
					g[i] = 0.00000
				end
			end
			return 			
		end
        # return cost function and its gradient
		return ψ, ∇ψ
	end

	# Expected Shortfall Balance (net forecast mismatch) for expected penalty cost in OPEX
	y = load - solar_production - gen_production + (battery_charge - battery_discharge) + (grid_export - grid_import)

	# Register nonlinear constraints for the expected shortfall cost
	for t in eachindex(y)
		register(model, Symbol("expected_$t"), length(y), define(t, grid_cost, grid_exchange_cost, σ)[1], define(t, grid_cost, grid_exchange_cost, σ)[2])
		add_nonlinear_constraint(model, :($(Symbol("expected_$t"))($(y...)) == $(expected_shortfall[t])))
	end

    # PROJECT COSTS EXPRESSIONS
    #--------------------------

    # CAPEX (based on the chosen model)
    if capex_model == "upfront"
        @expression(model, CAPEX, (solar_capacity   * solar_capex) + 
                                  (battery_capacity * battery_capex) + 
                                  (gen_capacity     * gen_capex))

    else  # "annuity" case
        @expression(model, CAPEX, (((solar_capacity   * solar_capex) * CRF_solar) + 
                                  ((battery_capacity * battery_capex) * CRF_battery) + 
                                  ((gen_capacity     * gen_capex) * CRF_gen)) * project_lifetime)
    end

    # Replacement Costs
    @expression(model, Replacement_Costs, (solar_capacity * replacement_cost_solar * discount_factor[solar_lifetime]) +
                                          (battery_capacity * replacement_cost_battery * discount_factor[battery_lifetime]) +
                                          (gen_capacity * replacement_cost_gen * discount_factor[gen_lifetime]))

    # Core operational costs (normal operation costs for solar, battery, generator)
    @expression(model, core_operational_costs, (sum(solar_production[t] * solar_opex for t in 1:T) +
                                               sum((battery_charge[t] + battery_discharge[t]) * battery_opex for t in 1:T) +
                                               sum(gen_production[t] * fuel_cost for t in 1:T) -
                                               sum(load[t] * retail_tariff for t in 1:T)) * steps_per_year)

    # Costs during outage periods (grid imports/exports and expected shortfall)
    @expression(model, outage_costs, 
        sum(
            sum(
                (grid_import[t] * grid_cost[t]) - (grid_export[t] * grid_price[t]) + expected_shortfall[t] 
                for t in 1:T if !(t in τ:(τ+outage))
            ) 
            for τ in 1:T
        ) * steps_per_year
    )

    # Reserve costs during outages (fuel costs for reserves and battery reserve costs)
    @expression(model, reserve_costs, 
        sum(
            sum(
                (gen_reserve[t] * fuel_cost) + (battery_reserve[t] * battery_opex) 
                for t in 1:T if !(t in τ:min(τ+outage, T))
            ) 
            for τ in 1:T
        ) * steps_per_year
    )

    # Non-outage costs (grid imports/exports and expected shortfall outside outages)
    @expression(model, non_outage_costs, 
        sum(
            (grid_import[t] * grid_cost[t]) - 
            (grid_export[t] * grid_price[t]) + 
            expected_shortfall[t] 
            for t in 1:T
        ) * steps_per_year
    )

    # Annual OPEX & revenue:
    @expression(model, Annual_Opex, core_operational_costs + 
                                    ((outage_probability / T)*(outage_costs + reserve_costs)) + 
                                    ((1 - outage_probability)*non_outage_costs))

    # Total Discounted Operation costs
    @expression(model, OPEX_npv, sum(Annual_Opex * discount_factor[y] for y in 1:project_lifetime))

    # Subsidies
    @expression(model, Subsidies, CAPEX * (1 - capital_cost_subsidies) + (connections * subsidies_per_connection))

    # Salvage value
    @expression(model, Salvage_Value,   (solar_capacity*solar_capex)*(max(0, solar_lifetime - project_lifetime)/(solar_lifetime)) + 
                                        (battery_capacity*battery_capex)*(max(0, battery_lifetime - project_lifetime)/(battery_lifetime)) + 
                                        (gen_capacity*gen_capex)*(max(0, gen_lifetime - project_lifetime)/(gen_lifetime)))

    # Revenues from grid sales
    @expression(model, Revenues, sum((sum(load[t] * retail_tariff for t in 1:T) * steps_per_year) * discount_factor[y] for y in 1:project_lifetime))

    # Net Present Cost
    @expression(model, NPC, (CAPEX + Replacement_Costs + OPEX_npv) - (Subsidies + Revenues + Salvage_Value))

    # OPTIMIZATION CONSTRAINTS
    # ------------------------

    # Maximum CAPEX constraint based on number of connections
    @constraint(model, CAPEX <= (max_capex * connections))

    # OBJECTIVE FUNCTION
    # ------------------

    @objective(model, Min, NPC)

    println("Model initialized successfully")

    # SOLVING THE MODEL
    # -----------------

    # Initialize Ipopt solver
    optimizer = optimizer_with_attributes(Ipopt.Optimizer)

    # Setting solver options
    solver_settings = parameters["solver_settings"]["ipopt_options"]
    # set_optimizer_attribute(optimizer, "algorithm", :LD_SLSQP)
    println("\nSolving the optimization model using Ipopt...")
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
    println("Objective Value (NPC)    : ", round(objective_value(model) / 1000, digits=2), " kUSD")

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
    println("  Average Yearly Grid Import: ", round((sum(value(grid_import[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    println("  Average Yearly Grid Export: ", round((sum(value(grid_export[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")
    println("  Average Yearly Expected Shortfall: ", round((sum(value(expected_shortfall[t]) for t in 1:T) * steps_per_year) / 1000, digits=2), " MWh")

    # PAYBACK PERIOD
    # ---------------

    # Calculate the base case OPEX (buying all energy from the grid)
    base_case_OPEX = (sum(grid_cost[t] * load[t] for t in 1:T) * steps_per_year)  # USD/year

    # Calculate the project's actual OPEX with renewables
    project_OPEX = round(value(Annual_Opex), digits=2)  # USD/year

    # Compute annual Revenues
    annual_revenues = round((sum(load[t] * retail_tariff for t in 1:T) * steps_per_year), digits=2)  # USD/year

    # Compute annual savings
    annual_savings = round((base_case_OPEX - project_OPEX), digits=2)  # USD/year

    # Payback Period Calculation
    if annual_savings > 0
        println("\nAnnual Savings: ", annual_savings, " kUSD/year")
        payback_period = round(value(CAPEX) / annual_savings, digits=1)
        println("Payback Period without Revenues: ", payback_period, " years")
        payback_period_rev = round(value(CAPEX) / (annual_savings + annual_revenues), digits=1)
        println("Payback Period with Revenues: ", payback_period_rev, " years")
    elseif annual_savings <= 0 && annual_revenues > 0
        println("\nAnnual Savings <= 0 kUSD/year, Payback Period without Revenues is not applicable")
        payback_period_rev = round(value(CAPEX) / (annual_savings + annual_revenues), digits=1)
        println("Payback Period with Revenues: ", payback_period_rev, " years")
    else
        println("\nAnnual Savings and Revenues <= 0 kUSD/year, Payback Period is not applicable")
    end
    println("================================================================")

    # POST-PROCESSING
    # ---------------

    # File path for the results Excel file
    project_sizing_path = joinpath(@__DIR__, "results", "project_sizing.csv")
    dispatch_path = joinpath(@__DIR__, "results", "optimal_dispatch.csv")
    # Write results to Excel
    optimal_dispatch = write_results_to_csv(project_sizing_path, dispatch_path, model, load, solar_unit_production, T, uncertainty=true)
    println("Results exported to $project_sizing_path and $dispatch_path")

end

main()