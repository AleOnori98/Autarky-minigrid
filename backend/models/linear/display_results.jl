println("\n------ System Optimization Settings ------")

println("\nProject Time Settings:")
println(" Project Time Horizon: ", project_lifetime, " years")
println(" Number of Operation Time Steps: ", operation_time_steps, " hours")
println(" Number of Seasons: ", num_seasons)

println("\nOptimization Settings:")
println("  System Components: ",
    has_solar ? "Solar PV, " : "",
    has_wind ? "Wind Turbine, " : "",
    has_battery ? "Battery Bank, " : "",
    has_diesel_generator ? "Backup Generator" : "")
# TODO: Add other components 

if has_grid_connection
    println("  Grid Connection: Yes")
    println("  Grid Export: ", allow_grid_export ? "Yes" : "No")
end

println("\n------ System Optimization Results ------")

println("\nSystem Sizing:")
if has_solar
    println("  Solar Capacity: ", round(value(model[:solar_units]) * solar_nominal_capacity, digits=2), " kW")
end
if has_wind
    println("  Wind Capacity: ", round(value(model[:wind_units]) * wind_nominal_capacity, digits=2), " kW")
end
if has_battery
    println("  Battery Capacity: ", round(value(model[:battery_units]) * battery_nominal_capacity, digits=2), " kWh")
end
if has_diesel_generator
    println("  Generator Capacity: ", round(value(model[:generator_units]) * generator_nominal_capacity, digits=2), " kW")
end
# TODO: Add other components 

println("\nProject Costs:")
println("  Net Present Cost: ", round(value(model[:NPC]) / 1000, digits=2), " k$currency")
println("  Total Investment Cost: ", round(value(model[:CAPEX]) / 1000, digits=2), " k$currency")
println("  Total Subsidies: ", round(value(model[:Subsidies]) / 1000, digits=2), " k$currency")
println("  Discounted Replacement Cost: ", round(value(model[:Replacement_Cost_npv]) / 1000, digits=2), " k$currency")
println("  Discounted Total Operation Cost: ", round(value(model[:OPEX_npv]) / 1000, digits=2), " k$currency")

if has_grid_connection
    total_grid_cost = sum(season_weights[s] * value(model[:grid_import][t, s]) * grid_cost[t, s] for t in 1:T, s in 1:S)
    println("  Total Annual Grid Cost: ", round(total_grid_cost / 1000, digits=2), " k$currency/year")
    if allow_grid_export
        total_grid_revenue = sum(season_weights[s] * value(model[:grid_export][t, s]) * grid_price[t, s] for t in 1:T, s in 1:S)
        println("  Total Annual Grid Revenue: ", round(total_grid_revenue / 1000, digits=2), " k$currency/year")
    end
end

println("  Discounted Salvage Value: ", round(value(model[:Salvage_npv]) / 1000, digits=2), " k$currency")

actualized_demand = sum(sum(season_weights[s] * load[t, s] for t in 1:T, s in 1:S) * discount_factor[y] for y in 1:project_lifetime)
lcoe = value(model[:NPC]) / actualized_demand
println("  Levelized Cost of Energy (LCOE): ", round(lcoe, digits=2), " $currency/kWh")

println("\nOptimal Operation:")

if has_solar
    total_solar_production = sum(season_weights[s] * value(model[:solar_production][t, s]) for t in 1:T, s in 1:S)
    total_solar_max = sum(season_weights[s] * (solar_unit_production[t, s] * value(model[:solar_units])) for t in 1:T, s in 1:S)
    println("  Total Annual Solar Production: ", round(total_solar_production / 1000, digits=2), " MWh/year")
    println("  Solar Curtailment: ", round((total_solar_max - total_solar_production) / total_solar_max * 100, digits=2), " %")
end

if has_wind
    total_wind_production = sum(season_weights[s] * value(model[:wind_production][t, s]) for t in 1:T, s in 1:S)
    total_wind_max = sum(season_weights[s] * (wind_power[t, s] * value(model[:wind_units])) for t in 1:T, s in 1:S)
    println("  Total Annual Wind Production: ", round(total_wind_production / 1000, digits=2), " MWh/year")
    println("  Wind Curtailment: ", round((total_wind_max - total_wind_production) / total_wind_max * 100, digits=2), " %")
end

if has_battery
    total_charge = sum(season_weights[s] * value(model[:battery_charge][t, s]) for t in 1:T, s in 1:S)
    total_discharge = sum(season_weights[s] * value(model[:battery_discharge][t, s]) for t in 1:T, s in 1:S)
    println("  Total Battery Charge: ", round(total_charge / 1000, digits=2), " MWh/year")
    println("  Total Battery Discharge: ", round(total_discharge / 1000, digits=2), " MWh/year")
end

if has_diesel_generator
    total_generator_production = sum(season_weights[s] * value(model[:generator_production][t, s]) for t in 1:T, s in 1:S)
    println("  Total Annual Generator Production: ", round(total_generator_production / 1000, digits=2), " MWh/year")
    total_fuel = sum(season_weights[s] * (value(model[:generator_production][t, s]) / fuel_lhv) for t in 1:T, s in 1:S)
    println("  Total Fuel Consumption: ", round(total_fuel, digits=2), " liters/year")
end

if has_grid_connection
    total_grid_import = sum(season_weights[s] * value(model[:grid_import][t, s]) for t in 1:T, s in 1:S)
    println("  Total Grid Import: ", round(total_grid_import / 1000, digits=2), " MWh/year")
    if allow_grid_export
        total_grid_export = sum(season_weights[s] * value(model[:grid_export][t, s]) for t in 1:T, s in 1:S)
        println("  Total Grid Export: ", round(total_grid_export / 1000, digits=2), " MWh/year")
    end
    avg_grid_avail = sum(season_weights[s] * grid_availability[t, s] for t in 1:T, s in 1:S) / 8760
    println("  Average Grid Availability: ", round(avg_grid_avail * 100, digits=2), " %")
end
# TODO: Add other components 

if has_solar || has_wind
    total_renewables = 0.0
    if has_solar
        total_renewables += sum(season_weights[s] * value(model[:solar_production][t, s]) for t in 1:T, s in 1:S)
    end
    if has_wind
        total_renewables += sum(season_weights[s] * value(model[:wind_production][t, s]) for t in 1:T, s in 1:S)
    end
    total_generation = total_renewables
    if has_diesel_generator
        total_generation += sum(season_weights[s] * value(model[:generator_production][t, s]) for t in 1:T, s in 1:S)
    end
    println("  Renewable Penetration: ", round(total_renewables / total_generation * 100, digits=2), " %")
end
# TODO: Add other components 

println("\n----------------------------------------")
