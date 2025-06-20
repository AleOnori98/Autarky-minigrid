module PostProcessing

using JuMP, JSON3, Dates, Statistics
include(joinpath(@__DIR__, "utils.jl"))
using .Utils: import_time_series

"""
    write_results_to_json(model::Model, tech_params::Dict, res_potential::Dict, project_setup::Dict, system_config::Dict, season_weights::Dict{Int, Float64}, project_id::String)

Writes the optimization results from the JuMP model to a JSON file.
- `model`: The JuMP model containing optimization results.
- `tech_params`: Dictionary containing technology parameters.
- `res_potential`: Dictionary containing renewable energy potential data.
- `project_setup`: Dictionary containing project setup information.
- `system_config`: Dictionary containing system configuration settings.
- `season_weights`: Dictionary mapping season indices to their weights.
- `project_id`: Unique identifier for the project, used to name the output file.
"""
function write_results_to_json(model::Model, tech_params::Dict, res_potential::Dict, project_setup::Dict, system_config::Dict, season_weights::Dict{Int, Float64}, project_id::String)

    results = Dict()

    # === Meta Info ===
    results["timestamp"] = string(Dates.now())
    results["project_id"] = project_id

    # === Extract Flags ===
    enabled = system_config["enabled_components"]
    has_solar = enabled["solar_pv"]
    has_wind = enabled["wind_turbine"]
    has_battery = enabled["battery"]
    has_generator = enabled["diesel_generator"]
    has_grid_connection = enabled["grid_connection"]

    grid_conf = get(system_config, "grid_connection", Dict())
    allow_grid_export = get(grid_conf, "allow_export", false)

    project_settings = project_setup["project_settings"]
    project_lifetime = project_settings["time_horizon"]
    has_seasonality = project_settings["seasonality"]
    num_seasons = has_seasonality ? (project_settings["seasonality_option"] == "4 seasons" ? 4 : 2) : 1
    operation_time_steps = project_settings["typical_profile"] == "day" ? 24 : error("Unsupported time profile")

    discount_factors = [1 / ((1 + tech_params["economic_settings"]["discount_rate"]) ^ y) for y in 1:project_lifetime]
    currency = tech_params["economic_settings"]["currency"]
    fuel_lhv = tech_params["technology_parameters"]["diesel_generator"]["lower_heating_value"]
    generator_nominal_capacity = tech_params["technology_parameters"]["diesel_generator"]["nominal_capacity"]

    # === Load Time Series ===
    ts_dir = joinpath("projects", project_id, "time_series")
    load = import_time_series(joinpath(ts_dir, "load_demand.csv"), num_seasons, has_seasonality)
    T = operation_time_steps

    # === Sizing ===
    sizing = Dict()
    if has_solar
        solar_cap = res_potential["solar_pv"]["nominal_capacity"]
        sizing["solar_kw"] = value(model[:solar_units]) * solar_cap
    end
    if has_wind
        wind_cap = res_potential["wind_turbine"]["nominal_capacity"]
        sizing["wind_kw"] = value(model[:wind_units]) * wind_cap
    end
    if has_battery
        battery_cap = tech_params["technology_parameters"]["battery"]["nominal_capacity"]
        sizing["battery_kwh"] = value(model[:battery_units]) * battery_cap
    end
    if has_generator
        sizing["generator_kw"] = value(model[:generator_units]) * generator_nominal_capacity
    end
    results["sizing"] = sizing

    # === Costs ===
    results["costs"] = Dict(
        "NPC[k$currency]" => round(value(model[:NPC]) / 1000, digits=2),
        "CAPEX[k$currency]" => round(value(model[:CAPEX]) / 1000, digits=2),
        "Subsidies[k$currency]" => round(value(model[:Subsidies]) / 1000, digits=2),
        "Replacement[k$currency]" => round(value(model[:Replacement_Cost_npv]) / 1000, digits=2),
        "OPEX[k$currency]" => round(value(model[:OPEX_npv]) / 1000, digits=2),
        "Salvage[k$currency]" => round(value(model[:Salvage_npv]) / 1000, digits=2)
    )

    # === LCOE ===
    actualized_demand = sum(sum(season_weights[s] * load[t, s] for t in 1:T, s in 1:num_seasons) * discount_factors[y] for y in 1:project_lifetime)
    results["LCOE[$currency/kWh]"] = round(value(model[:NPC]) / actualized_demand, digits=3)

    # === Operation KPIs ===
    op = Dict()
    if has_solar
        op["solar[MWh]"] = round(sum(season_weights[s] * value(model[:solar_production][t,s]) for t in 1:T, s in 1:num_seasons) / 1000, digits=2)
    end
    if has_wind
        op["wind[MWh]"] = round(sum(season_weights[s] * value(model[:wind_production][t,s]) for t in 1:T, s in 1:num_seasons) / 1000, digits=2)
    end
    if has_generator
        gen = sum(season_weights[s] * value(model[:generator_production][t,s]) for t in 1:T, s in 1:num_seasons)
        op["generator[MWh]"] = round(gen / 1000, digits=2)
        op["fuel_liters"] = round(gen / fuel_lhv, digits=2)
    end
    if has_battery
        charge = sum(season_weights[s] * value(model[:battery_charge][t,s]) for t in 1:T, s in 1:num_seasons)
        discharge = sum(season_weights[s] * value(model[:battery_discharge][t,s]) for t in 1:T, s in 1:num_seasons)
        op["battery_charge[MWh]"] = round(charge / 1000, digits=2)
        op["battery_discharge[MWh]"] = round(discharge / 1000, digits=2)
    end
    if has_grid_connection
        grid_import = sum(season_weights[s] * value(model[:grid_import][t,s]) for t in 1:T, s in 1:num_seasons)
        op["grid_import_[MWh]"] = round(grid_import / 1000, digits=2)
        if allow_grid_export
            grid_export = sum(season_weights[s] * value(model[:grid_export][t,s]) for t in 1:T, s in 1:num_seasons)
            op["grid_export[MWh]"] = round(grid_export / 1000, digits=2)
        end
    end
    results["operation"] = op

    # === Dispatch (per season) ===
    dispatch = Dict{String, Any}()
    for s in 1:num_seasons
        data = Dict("timestep" => collect(1:T), "load[kWh]" => load[:, s])
        if has_solar data["solar[kWh]"] = value.(model[:solar_production])[:, s] end
        if has_wind data["wind[kWh]"] = value.(model[:wind_production])[:, s] end
        if has_battery
            data["charge[kWh]"] = value.(model[:battery_charge])[:, s]
            data["discharge[kWh]"] = value.(model[:battery_discharge])[:, s]
            data["soc[kWh]"] = value.(model[:SOC])[:, s]
        end
        if has_generator data["generator[kWh]"] = value.(model[:generator_production])[:, s] end
        if has_grid_connection
            data["grid_import[kWh]"] = value.(model[:grid_import])[:, s]
            if allow_grid_export data["grid_export[kWh]"] = value.(model[:grid_export])[:, s] end
        end
        dispatch["season_$(s)"] = data
    end
    results["dispatch"] = dispatch

    # === Save to results.json ===
    results_path = joinpath("projects", project_id, "results", "results.json")
    mkpath(dirname(results_path))
    open(results_path, "w") do io
        JSON3.write(io, results; indent=2)
    end
    println("Results saved to $results_path")
end

end
