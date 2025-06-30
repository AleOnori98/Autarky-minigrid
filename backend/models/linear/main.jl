# === CLI ARGUMENTS ===
using JSON3

project_id = ARGS[1]
solver_name = ARGS[2]
solver_settings = length(ARGS) > 2 ? JSON3.read(ARGS[3]) : Dict()

project_dir = joinpath(@__DIR__, "..", "..", "projects", project_id)

# =========================

# MODEL SETUP
# -----------------

# Importing the required packages and functions
using JuMP
include(joinpath(@__DIR__, "utils.jl"))
using .Utils: import_time_series 
# Display and export results
include(joinpath(@__DIR__, "post_processing.jl"))
using .PostProcessing: write_results_to_json

# MODEL INITIALIZATION
# --------------------

# Initialize parameters and time series data
include(joinpath(@__DIR__, "load_inputs.jl"))

# Define sets
T = operation_time_steps
if has_seasonality
    S = num_seasons
else
    S = 1
end

# Initialize the optimization model
println("\nInitializing the optimization model...")
model = Model()

# ========================
# VARIABLES DEFINITION
# ========================
# TODO: Add support for unit committment

# Solar PV variables
if has_solar == true
    # Sizing
    @variable(model, solar_units >= 0, base_name="Solar_Units") # [units of nominal capacity]
    # Operation
    @variable(model, solar_production[t=1:T, s=1:S] >= 0, base_name="Solar_Production") # [kWh]
end

# Wind Turbine variables
if has_wind == true
    # Sizing
    @variable(model, wind_units >= 0, base_name="Wind_Units") # [units of nominal capacity]
    # Operation
    @variable(model, wind_production[t=1:T, s=1:S] >= 0, base_name="Wind_Production") # [kWh]
end

# Mini-Hydro variables
if has_mini_hydro == true
    # Sizing
    @variable(model, hydro_units >= 0, base_name="MiniHydro_Units") # [units of nominal capacity]
    # Operation
    @variable(model, hydro_production[t=1:T, s=1:S] >= 0, base_name="MiniHydro_Production") # [kWh]
end

# Battery variables
if has_battery == true
    # Sizing
    @variable(model, battery_units >= 0, base_name="Battery_Units") # [units of nominal capacity]
    # Operation
    @variable(model, battery_charge[t=1:T, s=1:S] >= 0, base_name="Battery_Charge") # [kWh]
    @variable(model, battery_discharge[t=1:T, s=1:S] >= 0, base_name="Battery_Discharge") # [kWh]
    @variable(model, SOC[t=1:T, s=1:S], base_name="State_of_Charge") # [kWh]
end

# Backup Diesel Generator variables
if has_diesel_generator == true
    # Sizing
    @variable(model, generator_units >= 0, base_name="Generator_Units") # [units of nominal capacity]
    # Operation
    @variable(model, generator_production[t=1:T, s=1:S] >= 0, base_name="Generator_Production") # [kWh]
end

# Biogas Generator variables
if has_biogas_generator == true
    # Sizing
    @variable(model, biogas_units >= 0, base_name="BiogasGenerator_Units") # [units of nominal capacity]
    # Operation
    @variable(model, biogas_production[t=1:T, s=1:S] >= 0, base_name="BiogasGenerator_Production") # [kWh]
end

# Grid Connection variables
if has_grid_connection == true
    @variable(model, grid_import[t=1:T, s=1:S] >= 0, base_name="Grid_Import") # [kWh]
    if allow_grid_export == true 
        @variable(model, grid_export[t=1:T, s=1:S] >= 0, base_name="Grid_Export") # [kWh]
    end
end

# Lost Load variables
if maximum_lost_load > 0.0
    @variable(model, lost_load[t=1:T, s=1:S] >= 0, base_name="Lost_Load") # [kWh]
end

println("Variables added successfully to the model.")

# ========================
# ENERGY BALANCE CONSTRAINT
# ========================

for s in 1:S
    for t in 1:T
        # Initialize the energy balance expression
        energy_balance_expr = AffExpr()

        # Add production terms based on available technologies
        if has_solar
            energy_balance_expr += solar_production[t, s]
        end
        if has_wind
            energy_balance_expr += wind_production[t, s]
        end
        if has_mini_hydro
            energy_balance_expr += hydro_production[t, s]
        end
        if has_biogas_generator
            energy_balance_expr += biogas_production[t, s]
        end
        if has_diesel_generator
            energy_balance_expr += generator_production[t, s]
        end
        if has_battery
            energy_balance_expr += battery_discharge[t, s] - battery_charge[t, s]
        end
        if has_grid_connection
            energy_balance_expr += grid_import[t, s]
            if allow_grid_export
                energy_balance_expr -= grid_export[t, s]
            end
        end

        # Add Lost Load if used 
        if maximum_lost_load > 0.0
            energy_balance_expr += lost_load[t, s]
        end

        # Constrain supply to meet demand 
        @constraint(model, energy_balance_expr == load[t, s])
    end
end

println("Energy Balance Constraint added successfully.")

# ===============================
# OPERATION CONSTRAINTS
# ===============================

# Renewables capacity limit
if has_solar == true
    @constraint(model, [t=1:T, s=1:S], solar_production[t,s] <= solar_units * solar_unit_production[t,s])
end

if has_wind == true
    @constraint(model, [t=1:T, s=1:S], wind_production[t,s] <= wind_units * wind_power[t,s])
end

if has_mini_hydro == true
    @constraint(model, [t=1:T, s=1:S], hydro_production[t,s] <= hydro_units * hydro_unit_production[t,s])
end

# Battery capacity limit
if has_battery == true
    @constraint(model, [t=1:T, s=1:S], battery_charge[t,s] <= ((battery_units * battery_nominal_capacity) / t_charge) * Δt)
    @constraint(model, [t=1:T, s=1:S], battery_discharge[t,s] <= ((battery_units * battery_nominal_capacity) / t_discharge) * Δt)
    
    # Battery SOC constraints
    @constraint(model, [t=1:T, s=1:S], SOC[t,s] >= SOC_min * (battery_units * battery_nominal_capacity))
    @constraint(model, [t=1:T, s=1:S], SOC[t,s] <= SOC_max * (battery_units * battery_nominal_capacity))
    @constraint(model, [s=1:S], SOC[1, s] == (SOC_0 * (battery_units * battery_nominal_capacity)) + (battery_charge[1,s] * η_charge - battery_discharge[1,s] * η_discharge))
    @constraint(model, [t=2:T, s=1:S], SOC[t,s] == SOC[t-1,s] + (battery_charge[t,s] * η_charge - battery_discharge[t,s] * η_discharge))
    @constraint(model, [s=1:S], SOC[T, s] == SOC_0 * (battery_units * battery_nominal_capacity))  # End-of-horizon SOC continuity
end

# Generators Capacity Limit 
if has_diesel_generator == true
    @constraint(model, [t=1:T, s=1:S], generator_production[t,s] <= generator_units * generator_nominal_capacity * Δt)
 end

 if has_biogas_generator == true
    @constraint(model, [t=1:T, s=1:S], biogas_production[t,s] <= biogas_units * biogas_nominal_capacity * Δt)
end

 # Grid Connection Operation constraints
if has_grid_connection == true
    @constraint(model, [t=1:T, s=1:S], grid_import[t,s] <= grid_availability[t,s] * (max_line_capacity * Δt))
    if allow_grid_export == true
        @constraint(model, [t=1:T, s=1:S], grid_export[t,s] <= grid_availability[t,s] * (max_line_capacity * Δt))
    end
end

println("Operation Constraints added successfully to the model.")

# ===============================
# SYSTEM-LEVEL CONSTRAINTS
# ===============================

# -------------------------------
# LOST LOAD SHARE CONSTRAINT
# -------------------------------
if maximum_lost_load > 0.0
    # Weighted lost load across seasons must be <= allowed fraction of total demand
    @constraint(model,
        sum(season_weights[s] * sum(lost_load[t, s] for t in 1:T) for s in 1:S)
        <= maximum_lost_load * sum(season_weights[s] * sum(load[t, s] for t in 1:T) for s in 1:S)
    )
end

# -------------------------------
# RENEWABLE PENETRATION CONSTRAINT
# -------------------------------
if minimum_renewable_penetration > 0.0
    # Build expressions for total renewables & total generation
    total_renewable_expr = Dict((t, s) => AffExpr() for t in 1:T, s in 1:S)
    total_generation_expr = Dict((t, s) => AffExpr() for t in 1:T, s in 1:S)

    for s in 1:S
        for t in 1:T
            if has_solar
                total_renewable_expr[t, s] += solar_production[t, s]
                total_generation_expr[t, s] += solar_production[t, s]
            end
            if has_wind
                total_renewable_expr[t, s] += wind_production[t, s]
                total_generation_expr[t, s] += wind_production[t, s]
            end
            if has_mini_hydro
                total_renewable_expr[t, s] += hydro_production[t, s]
                total_generation_expr[t, s] += hydro_production[t, s]
            end
            if has_diesel_generator
                total_generation_expr[t, s] += generator_production[t, s]
            end
            if has_biogas_generator
                total_generation_expr[t, s] += biogas_production[t, s]
            end
            if has_grid_connection
                total_generation_expr[t, s] += grid_import[t, s]
                if allow_grid_export
                    total_generation_expr[t, s] += -grid_export[t, s]  # exported power reduces net supply
                end
            end
            if has_battery
                # Battery discharge counts as generation, charge counts as negative supply
                total_generation_expr[t, s] += battery_discharge[t, s] - battery_charge[t, s]
            end
        end
    end

    # Weighted annual sums
    annual_renewable = sum(season_weights[s] * sum(total_renewable_expr[t, s] for t in 1:T) for s in 1:S)
    annual_total_gen = sum(season_weights[s] * sum(total_generation_expr[t, s] for t in 1:T) for s in 1:S)

    # Enforce minimum RES share
    @constraint(model, annual_renewable >= minimum_renewable_penetration * annual_total_gen)
end

println("System-level constraints added successfully to the model.")

# ========================
# COST EXPRESSIONS
# ========================

# Initialize cost components
CAPEX_expr = 0
Replacement_Cost_npv_expr = 0
Subsidies_expr = 0
OPEX_fixed_expr = 0
OPEX_variable_expr = [AffExpr() for t in 1:T, s in 1:S]
Salvage_expr = 0

# Solar PV
if has_solar == true
    CAPEX_expr += (solar_units * solar_nominal_capacity) * solar_capex
    Replacement_Cost_npv_expr += sum(((solar_units * solar_nominal_capacity * solar_capex) * discount_factor[y]) for y in solar_replacement_years; init=0)
    Subsidies_expr += ((solar_units * solar_nominal_capacity) * solar_capex) * solar_subsidy_share
    OPEX_fixed_expr += ((solar_units * solar_nominal_capacity) * solar_capex) * solar_opex
    Salvage_expr += ((solar_units * solar_nominal_capacity) * solar_capex) * salvage_solar_fraction
end

# Wind Turbine
if has_wind == true
    CAPEX_expr += (wind_units * wind_nominal_capacity) * wind_capex
    Replacement_Cost_npv_expr += sum(((wind_units * wind_nominal_capacity * wind_capex) * discount_factor[y]) for y in wind_replacement_years; init=0)
    Subsidies_expr += ((wind_units * wind_nominal_capacity) * wind_capex) * wind_subsidy_share
    OPEX_fixed_expr += ((wind_units * wind_nominal_capacity) * wind_capex) * wind_opex
    Salvage_expr += ((wind_units * wind_nominal_capacity) * wind_capex) * salvage_wind_fraction
end

# Mini-Hydro
if has_mini_hydro == true
    CAPEX_expr += (hydro_units * hydro_nominal_capacity) * hydro_capex
    Replacement_Cost_npv_expr += sum(((hydro_units * hydro_nominal_capacity * hydro_capex) * discount_factor[y]) for y in hydro_replacement_years; init=0)
    Subsidies_expr += ((hydro_units * hydro_nominal_capacity) * hydro_capex) * hydro_subsidy_share
    OPEX_fixed_expr += ((hydro_units * hydro_nominal_capacity) * hydro_capex) * hydro_opex
    Salvage_expr += ((hydro_units * hydro_nominal_capacity) * hydro_capex) * salvage_hydro_fraction
end

# Battery
if has_battery == true
    CAPEX_expr += (battery_units * battery_nominal_capacity) * battery_capex
    Replacement_Cost_npv_expr += sum(((battery_units * battery_nominal_capacity * battery_capex) * discount_factor[y]) for y in battery_replacement_years; init=0)
    OPEX_fixed_expr += ((battery_units * battery_nominal_capacity) * battery_capex) * battery_opex
    Salvage_expr += ((battery_units * battery_nominal_capacity) * battery_capex) * salvage_battery_fraction
end

# Diesel Generator
if has_diesel_generator == true
    CAPEX_expr += (generator_units * generator_nominal_capacity) * generator_capex
    Replacement_Cost_npv_expr += sum(((generator_units * generator_nominal_capacity * generator_capex) * discount_factor[y]) for y in generator_replacement_years; init=0)
    OPEX_fixed_expr += ((generator_units * generator_nominal_capacity) * generator_capex) * generator_opex
    Salvage_expr += ((generator_units * generator_nominal_capacity) * generator_capex) * salvage_generator_fraction
end

# Biogas Generator
if has_biogas_generator == true
    CAPEX_expr += (biogas_units * biogas_nominal_capacity) * biogas_capex
    Replacement_Cost_npv_expr += sum(((biogas_units * biogas_nominal_capacity * biogas_capex) * discount_factor[y]) for y in biogas_replacement_years; init=0)
    OPEX_fixed_expr += ((biogas_units * biogas_nominal_capacity) * biogas_capex) * biogas_opex
    Salvage_expr += ((biogas_units * biogas_nominal_capacity) * biogas_capex) * salvage_biogas_fraction
end

# Grid-related operational costs
if has_grid_connection
    for s in 1:S
        for t in 1:T
            OPEX_variable_expr[t, s] += grid_import[t, s] * grid_cost[t, s]
            if allow_grid_export
                OPEX_variable_expr[t, s] -= grid_export[t, s] * grid_price[t, s]
            end
        end
    end
end

# Generator fuel cost (variable OPEX)
if has_diesel_generator
    for s in 1:S
        for t in 1:T
            # Use fuel consumption for fuel cost calculation
            OPEX_variable_expr[t, s] += (generator_production[t, s] / (generator_efficiency * fuel_lhv)) * fuel_cost
        end
    end
end

# Biogas Generator fuel cost
if has_biogas_generator
    for s in 1:S
        for t in 1:T
            OPEX_variable_expr[t, s] += (biogas_production[t, s] / (biogas_efficiency * biogas_fuel_lhv)) * biogas_fuel_cost
        end
    end
end

# Define JuMP expressions in the model
@expression(model, CAPEX, CAPEX_expr)
@expression(model, Replacement_Cost_npv, Replacement_Cost_npv_expr)
@expression(model, Subsidies, Subsidies_expr)
@expression(model, OPEX_fixed, OPEX_fixed_expr)
@expression(model, OPEX_variable[t=1:T, s=1:S], OPEX_variable_expr[t,s])
@expression(model, OPEX_npv, sum((sum(season_weights[s] * sum(OPEX_variable_expr[t, s] for t in 1:T) for s in 1:S) + OPEX_fixed) * discount_factor[y] for y in 1:project_lifetime))
@expression(model, Salvage_npv, Salvage_expr * discount_factor[project_lifetime])
@expression(model, NPC, (CAPEX - Subsidies) + Replacement_Cost_npv + OPEX_npv - Salvage_npv)

println("Cost Expressions added successfully to the model.")

# Objective Function: Minimization of NPC
@objective(model, Min, NPC)

println("Model initialized successfully")

# ==================
# SOLVING THE MODEL
# ==================

# Load solver settings
solver_params = YAML.load_file(joinpath(project_dir, "solver_parameters.yaml"))
solver_name = solver_params["solver_name"]
solver_settings = solver_params["solver_settings"]

# Initialize optimizer
if solver_name == "HiGHS"
    using HiGHS
    optimizer = optimizer_with_attributes(HiGHS.Optimizer)
elseif solver_name == "GLPK"
    using GLPK
    optimizer = optimizer_with_attributes(GLPK.Optimizer)
elseif solver_name == "Ipopt"
    using Ipopt
    optimizer = optimizer_with_attributes(Ipopt.Optimizer)
else
    error("Unsupported solver: $solver_name")
end

# Apply solver settings
for (key, value) in solver_settings
    set_optimizer_attribute(optimizer, key, value)
end

# Attach optimizer to the model
set_optimizer(model, optimizer)

# Solve the model
@time optimize!(model)
solution_summary(model, verbose = true)

# Check solution status
status = termination_status(model)
if status == MOI.INFEASIBLE
    error("\n❌ Optimization result: INFEASIBLE. Please verify constraints and input parameters.")
else
    println("\n✅ Optimization completed with status: ", status)
end

# ==================
# POST-PROCESSING
# ==================

# Display results in console
include(joinpath(@__DIR__, "display_results.jl"))

# Save results to JSON if solution is usable
if status in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.TIME_LIMIT)
    write_results_to_json(
        model,
        tech_params,
        res_potential,
        project_setup,
        system_config,
        season_weights,
        project_id
    )
end

