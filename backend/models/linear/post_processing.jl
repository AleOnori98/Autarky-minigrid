module PostProcessing

using JuMP, JSON3, Dates, Statistics
include(joinpath(@__DIR__, "utils.jl"))
using .Utils: import_time_series

# Safe accessor for optional JuMP variables
function safe_value(model::Model, var::Symbol)
    return haskey(model, var) ? value(model[var]) : 0.0
end

function write_results_to_json(
    model::Model,
    tech_params::Dict,
    res_potential::Dict,
    project_setup::Dict,
    system_config::Dict,
    season_weights::Dict{Int, Float64},
    project_id::String
)
    results = Dict()

    # === Meta Info ===
    results["timestamp"] = string(Dates.now())
    results["project_id"] = project_id

    # === Flags ===
    enabled = system_config["enabled_components"]
    has_solar = enabled["solar_pv"]
    has_wind = enabled["wind_turbine"]
    has_battery = enabled["battery"]
    has_generator = enabled["diesel_generator"]
    has_grid = enabled["grid_connection"]
    if has_grid
        allow_export = get(system_config["grid_connection"], "allow_export", false)
    else
        allow_export = false
    end

    project_settings = project_setup["project_settings"]
    project_lifetime = project_settings["time_horizon"]
    num_seasons = project_settings["seasonality"] ?
        (project_settings["seasonality_option"] == "4 seasons" ? 4 : 2) : 1
    T = project_settings["typical_profile"] == "day" ? 24 : error("Unsupported profile")

    discount = tech_params["economic_settings"]["discount_rate"]
    currency = tech_params["economic_settings"]["currency"]
    discount_factors = [1 / ((1 + discount) ^ y) for y in 1:project_lifetime]

    # === Load Time Series ===
    ts_dir = joinpath("projects", project_id, "time_series")
    load = import_time_series(joinpath(ts_dir, "load_demand.csv"), num_seasons, true)

    # === Sizing ===
    sizing = Dict(
        "solar_kw" => has_solar ? safe_value(model, :solar_units) * res_potential["solar_pv"]["nominal_capacity"] : 0.0,
        "battery_kwh" => has_battery ? safe_value(model, :battery_units) * tech_params["technology_parameters"]["battery"]["nominal_capacity"] : 0.0,
        "generator_kw" => has_generator ? safe_value(model, :generator_units) * tech_params["technology_parameters"]["diesel_generator"]["nominal_capacity"] : 0.0
    )
    results["sizing"] = sizing

    # === Costs ===
    results["costs"] = Dict(
        "NPC[kUSD]" => round(safe_value(model, :NPC) / 1000, digits=2),
        "CAPEX[kUSD]" => round(safe_value(model, :CAPEX) / 1000, digits=2),
        "Subsidies[kUSD]" => round(safe_value(model, :Subsidies) / 1000, digits=2),
        "Replacement[kUSD]" => round(safe_value(model, :Replacement_Cost_npv) / 1000, digits=2),
        "OPEX[kUSD]" => round(safe_value(model, :OPEX_npv) / 1000, digits=2),
        "Salvage[kUSD]" => round(safe_value(model, :Salvage_npv) / 1000, digits=2)
    )

    # === LCOE ===
    demand_sum = sum(sum(season_weights[s] * load[t, s] for t in 1:T, s in 1:num_seasons) * discount_factors[y] for y in 1:project_lifetime)
    results["LCOE[USD/kWh]"] = round(safe_value(model, :NPC) / demand_sum, digits=3)

    # === Operation KPIs ===
    op = Dict(
        "solar[MWh]" => 0.0,
        "generator[MWh]" => 0.0,
        "fuel_liters" => 0.0,
        "battery_charge[MWh]" => 0.0,
        "battery_discharge[MWh]" => 0.0,
        "grid_import_[MWh]" => 0.0,
        "grid_export[MWh]" => 0.0,
        "solar_curtailment" => 0.0,
        "lost_load" => 0.0
    )

    if has_solar
        solar_prod = sum(season_weights[s] * value(model[:solar_production][t,s]) for t in 1:T, s in 1:num_seasons)
        op["solar[MWh]"] = round(solar_prod / 1000, digits=2)
    end
    if has_generator
        gen = sum(season_weights[s] * value(model[:generator_production][t,s]) for t in 1:T, s in 1:num_seasons)
        op["generator[MWh]"] = round(gen / 1000, digits=2)
        lhv = tech_params["technology_parameters"]["diesel_generator"]["lower_heating_value"]
        op["fuel_liters"] = round(gen / lhv, digits=2)
    end
    if has_battery
        charge = sum(season_weights[s] * value(model[:battery_charge][t,s]) for t in 1:T, s in 1:num_seasons)
        discharge = sum(season_weights[s] * value(model[:battery_discharge][t,s]) for t in 1:T, s in 1:num_seasons)
        op["battery_charge[MWh]"] = round(charge / 1000, digits=2)
        op["battery_discharge[MWh]"] = round(discharge / 1000, digits=2)
    end
    if has_grid
        grid_import = sum(season_weights[s] * value(model[:grid_import][t,s]) for t in 1:T, s in 1:num_seasons)
        op["grid_import[MWh]"] = round(grid_import / 1000, digits=2)
        if allow_export
            grid_export = sum(season_weights[s] * value(model[:grid_export][t,s]) for t in 1:T, s in 1:num_seasons)
            op["grid_export[MWh]"] = round(grid_export / 1000, digits=2)
        end
    end
    results["operation"] = op

    # === Dispatch ===
    dispatch = Dict{String, Any}()
    for s in 1:num_seasons
        data = Dict(
            "timestep" => collect(1:T),
            "load[kWh]" => load[:, s],
            "solar[kWh]" => fill(0.0, T),
            "charge[kWh]" => fill(0.0, T),
            "discharge[kWh]" => fill(0.0, T),
            "soc[kWh]" => fill(0.0, T),
            "generator[kWh]" => fill(0.0, T),
            "grid_import[kWh]" => fill(0.0, T),
            "grid_export[kWh]" => fill(0.0, T),
            "solar_curtailment[kWh]" => fill(0.0, T),
            "lost_load[kWh]" => fill(0.0, T)
        )
        if has_solar data["solar[kWh]"] = value.(model[:solar_production])[:, s] end
        if has_battery
            data["charge[kWh]"] = value.(model[:battery_charge])[:, s]
            data["discharge[kWh]"] = value.(model[:battery_discharge])[:, s]
            data["soc[kWh]"] = value.(model[:SOC])[:, s]
        end
        if has_generator data["generator[kWh]"] = value.(model[:generator_production])[:, s] end
        if has_grid
            data["grid_import[kWh]"] = value.(model[:grid_import])[:, s]
            if allow_export data["grid_export[kWh]"] = value.(model[:grid_export])[:, s] end
        end
        # Add if you implement curtailment/lost load in the model
        dispatch["season_$(s)"] = data
    end
    results["dispatch"] = dispatch

    # === Save ===
    results_path = joinpath("projects", project_id, "results", "results.json")
    mkpath(dirname(results_path))
    open(results_path, "w") do io
        JSON3.write(io, results; indent=2)
    end
    println("✅ Results saved to $results_path")
end

end
