module PostProcessing

using JuMP, JSON3, Dates, Statistics
include(joinpath(@__DIR__, "utils.jl"))
using .Utils: import_time_series

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

    results["timestamp"] = string(Dates.now())
    results["project_id"] = project_id

    enabled = system_config["enabled_components"]
    has_solar = enabled["solar_pv"]
    has_wind = enabled["wind_turbine"]
    has_mini_hydro = enabled["mini_hydro"]
    has_battery = enabled["battery"]
    has_generator = enabled["diesel_generator"]
    has_biogas = enabled["biogas_generator"]
    has_grid = enabled["grid_connection"]
    if has_grid
        grid_params = get(tech_params["technology_parameters"], "grid_connection", Dict())
        allow_export = get(grid_params, "allow_export", false)
    else
        allow_export = false
    end

    project_settings = project_setup["project_settings"]
    project_lifetime = project_settings["time_horizon"]
    num_seasons = project_settings["seasonality"] ? (project_settings["seasonality_option"] == "4 seasons" ? 4 : 2) : 1
    T = project_settings["operation_time_steps"] 

    discount = tech_params["economic_settings"]["discount_rate"]
    currency = tech_params["economic_settings"]["currency"]
    discount_factors = [1 / ((1 + discount) ^ y) for y in 1:project_lifetime]

    ts_dir = joinpath("projects", project_id, "time_series")
    load = import_time_series(joinpath(ts_dir, "load_demand.csv"), num_seasons, true)

    # === Sizing
    results["sizing"] = Dict(
        "solar_kw" => has_solar ? safe_value(model, :solar_units) * res_potential["solar_pv"]["nominal_capacity"] : 0.0,
        "wind_kw" => has_wind ? safe_value(model, :wind_units) * res_potential["wind_turbine"]["nominal_capacity"] : 0.0,
        "mini_hydro_kw" => has_mini_hydro ? safe_value(model, :hydro_units) * res_potential["mini_hydro"]["nominal_capacity"] : 0.0,
        "battery_kwh" => has_battery ? safe_value(model, :battery_units) * tech_params["technology_parameters"]["battery"]["nominal_capacity"] : 0.0,
        "generator_kw" => has_generator ? safe_value(model, :generator_units) * tech_params["technology_parameters"]["diesel_generator"]["nominal_capacity"] : 0.0,
        "biogas_kw" => has_biogas ? safe_value(model, :biogas_units) * tech_params["technology_parameters"]["biogas_generator"]["nominal_capacity"] : 0.0
    )

    # === Costs
    results["costs"] = Dict(
        "NPC[kUSD]" => round(safe_value(model, :NPC) / 1000, digits=2),
        "CAPEX[kUSD]" => round(safe_value(model, :CAPEX) / 1000, digits=2),
        "Subsidies[kUSD]" => round(safe_value(model, :Subsidies) / 1000, digits=2),
        "Replacement[kUSD]" => round(safe_value(model, :Replacement_Cost_npv) / 1000, digits=2),
        "OPEX[kUSD]" => round(safe_value(model, :OPEX_npv) / 1000, digits=2),
        "Salvage[kUSD]" => round(safe_value(model, :Salvage_npv) / 1000, digits=2)
    )

    # === LCOE
    demand_sum = sum(sum(season_weights[s] * load[t, s] for t in 1:T, s in 1:num_seasons) * discount_factors[y] for y in 1:project_lifetime)
    results["LCOE[USD/kWh]"] = round(safe_value(model, :NPC) / demand_sum, digits=3)

    # === Operation KPIs
    op = Dict(
        "solar[MWh]" => 0.0,
        "wind[MWh]" => 0.0,
        "mini_hydro[MWh]" => 0.0,
        "generator[MWh]" => 0.0,
        "biogas[MWh]" => 0.0,
        "fuel_liters" => 0.0,
        "biogas_fuel_units" => 0.0,
        "battery_charge[MWh]" => 0.0,
        "battery_discharge[MWh]" => 0.0,
        "grid_import[MWh]" => 0.0,
        "grid_export[MWh]" => 0.0,
        "lost_load[MWh]" => 0.0
    )

    if has_solar
        op["solar[MWh]"] = round(sum(season_weights[s] * value(model[:solar_production][t,s]) for t in 1:T, s in 1:num_seasons) / 1000, digits=2)
    end
    if has_wind
        op["wind[MWh]"] = round(sum(season_weights[s] * value(model[:wind_production][t,s]) for t in 1:T, s in 1:num_seasons) / 1000, digits=2)
    end
    if has_mini_hydro
        op["mini_hydro[MWh]"] = round(sum(season_weights[s] * value(model[:hydro_production][t,s]) for t in 1:T, s in 1:num_seasons) / 1000, digits=2)
    end
    if has_generator
        gen = sum(season_weights[s] * value(model[:generator_production][t,s]) for t in 1:T, s in 1:num_seasons)
        op["generator[MWh]"] = round(gen / 1000, digits=2)
        lhv = tech_params["technology_parameters"]["diesel_generator"]["lower_heating_value"]
        op["fuel_liters"] = round(gen / lhv, digits=2)
    end
    if has_biogas
        bio = sum(season_weights[s] * value(model[:biogas_production][t,s]) for t in 1:T, s in 1:num_seasons)
        op["biogas[MWh]"] = round(bio / 1000, digits=2)
        bio_lhv = tech_params["technology_parameters"]["biogas_generator"]["lower_heating_value"]
        op["biogas_fuel_units"] = round(bio / bio_lhv, digits=2)
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

    # Lost Load
    op["lost_load[MWh]"] = if haskey(model, :lost_load)
        round(sum(season_weights[s] * value(model[:lost_load][t,s]) for t in 1:T, s in 1:num_seasons) / 1000, digits=2)
    else
        0.0
    end

    results["operation"] = op

    # === Dispatch
    dispatch = Dict{String, Any}()
    for s in 1:4
        if s <= num_seasons
            data = Dict(
                "timestep" => collect(1:T),
                "Load Demand (kWh)" => load[:, s],
                "Solar Production (kWh)" => has_solar ? value.(model[:solar_production])[:, s] : fill(0.0, T),
                "Wind Production (kWh)" => has_wind ? value.(model[:wind_production])[:, s] : fill(0.0, T),
                "Mini-Hydro Production (kWh)" => has_mini_hydro ? value.(model[:hydro_production])[:, s] : fill(0.0, T),
                "Battery Charge (kWh)" => has_battery ? value.(model[:battery_charge])[:, s] : fill(0.0, T),
                "Battery Discharge (kWh)" => has_battery ? value.(model[:battery_discharge])[:, s] : fill(0.0, T),
                "State of Charge (kWh)" => has_battery ? value.(model[:SOC])[:, s] : fill(0.0, T),
                "Generator Production (kWh)" => has_generator ? value.(model[:generator_production])[:, s] : fill(0.0, T),
                "Biogas Production (kWh)" => has_biogas ? value.(model[:biogas_production])[:, s] : fill(0.0, T),
                "Grid Import (kWh)" => has_grid ? value.(model[:grid_import])[:, s] : fill(0.0, T),
                "Grid Export (kWh)" => if has_grid && allow_export value.(model[:grid_export])[:, s] else fill(0.0, T) end,
                "Lost Load (kWh)" => haskey(model, :lost_load) ? value.(model[:lost_load])[:, s] : fill(0.0, T)
            )
            dispatch["season_$(s)"] = data
        else
            dispatch["season_$(s)"] = Dict("timestep" => collect(1:T))
        end
    end
    results["dispatch"] = dispatch

    results_path = joinpath("projects", project_id, "results", "results.json")
    mkpath(dirname(results_path))
    open(results_path, "w") do io
        JSON3.write(io, results; indent=2)
    end
    println("✅ Results saved to $results_path")
end

end
