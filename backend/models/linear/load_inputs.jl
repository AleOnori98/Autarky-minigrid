using YAML, CSV, DataFrames
include(joinpath(@__DIR__, "utils.jl"))
using .Utils: import_time_series

# === Load YAMLs ===
project_setup = YAML.load_file(joinpath(project_dir, "project_setup.yaml"))
system_config = YAML.load_file(joinpath(project_dir, "system_configuration.yaml"))
tech_params = YAML.load_file(joinpath(project_dir, "technology_parameters.yaml"))
res_potential = YAML.load_file(joinpath(project_dir, "renewables_potential.yaml"))
model_uncert = YAML.load_file(joinpath(project_dir, "model_uncertainties.yaml"))
solver_settings = YAML.load_file(joinpath(project_dir, "solver_parameters.yaml"))
# === Time Series Paths ===
ts_dir = joinpath(project_dir, "time_series")

# Extract boolean flags for enabled components and system properties
enabled = system_config["enabled_components"] # Dict
has_solar = enabled["solar_pv"] # bool
has_wind = enabled["wind_turbine"] # bool
has_mini_hydro = enabled["mini_hydro"] # bool
has_battery = enabled["battery"] # bool
has_diesel_generator = enabled["diesel_generator"] # bool
has_biogas_generator = enabled["biogas_generator"] # bool
has_grid_connection = enabled["grid_connection"] # bool
is_fully_ac = enabled["fully_ac"] # bool
layout_id = system_config["layout_id"] # int
has_seasonality = project_setup["project_settings"]["seasonality"] # bool
seasonality_option = project_setup["project_settings"]["seasonality_option"] # string
operation_time_steps = project_setup["project_settings"]["operation_time_steps"] # int

# Extract project setup settings
project_settings = project_setup["project_settings"] # Dict
latitude = project_settings["latitude"] # float
longitude = project_settings["longitude"] # float
time_resolution = project_settings["time_resolution"] # string
project_lifetime = project_settings["time_horizon"] # int
discount_rate = tech_params["economic_settings"]["discount_rate"] 
# Calculate the yearly discount factor
discount_factor = [1 / ((1 + discount_rate) ^ y) for y in 1:project_lifetime]
currency = tech_params["economic_settings"]["currency"] # string

# Logic for time resolution
if time_resolution == "hourly"
    Δt = 1 # time step duration in hours
# TODO: Add support for other time resolutions if needed
else
    error("Unsupported time resolution: $time_resolution")
end

# Calculate the year scale factor based on operation time steps
annual_hours = 8760 # Total hours in a year (365 days) 

# Validate operation_time_steps based on seasonality
# TODO: Add support for different time resolution 
if has_seasonality
    if seasonality_option == "2 seasons"
        num_seasons = 2
        max_steps = 4380
        season_months = Dict(
            1 => [11, 12, 1, 2, 3],  # Dry (5 months)
            2 => [4, 5, 6, 7, 8, 9, 10]  # Wet (7 months)
        )
    elseif seasonality_option == "4 seasons"
        num_seasons = 4
        max_steps = 2190
        season_months = Dict(
            1 => [12, 1, 2],   # Winter (3 months)
            2 => [3, 4, 5],    # Spring (3 months)
            3 => [6, 7, 8],    # Summer (3 months)
            4 => [9, 10, 11]   # Fall (3 months)
        )
    else
        error("Unsupported seasonality option: $seasonality_option")
    end
    if operation_time_steps > max_steps
        error("operation_time_steps exceeds max allowed $max_steps for $seasonality_option")
    end
else
    num_seasons = 1
    max_steps = 8760
    season_months = Dict(1 => [1:12;])
    if operation_time_steps > max_steps
        error("operation_time_steps exceeds max allowed 8760 for no seasonality")
    end
end

# Calculate the number of time steps per season
season_weights = Dict{Int, Float64}()

for (s, months) in season_months
    hours_in_season = (length(months) / 12.0) * annual_hours
    weight_per_step = hours_in_season / operation_time_steps
    season_weights[s] = weight_per_step
end

# Load Demand time series from CSV file
load_path = joinpath(ts_dir, "load_demand.csv")
load = import_time_series(load_path, num_seasons, has_seasonality)

# Solar PV
if has_solar
    solar = tech_params["technology_parameters"]["solar_pv"]
    solar_capex = solar["investment_cost"]
    solar_opex = solar["operation_cost"] / 100
    solar_subsidy_share = solar["subsidy"] / 100
    solar_lifetime = solar["lifetime"]
    solar_nominal_capacity = res_potential["solar_pv"]["nominal_capacity"]
    solar_inverter_efficiency = res_potential["solar_pv"]["inverter_efficiency"] / 100
    solar_unit_production = import_time_series(joinpath(ts_dir, "solar_pv_potential.csv"), num_seasons, has_seasonality)
    
    # Calculate number of replacements
    solar_replacements = max(0, floor((project_lifetime - 1) / solar_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    solar_replacement_years = solar_lifetime : solar_lifetime : Int(floor((project_lifetime - 1) / solar_lifetime) * solar_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_solar = length(solar_replacement_years) == 0 ? 0 : maximum(solar_replacement_years)
    unused_solar_life = solar_lifetime - (project_lifetime - last_install_solar)
    salvage_solar_fraction = max(0, unused_solar_life / solar_lifetime)
end
# TODO: Implement download from PVGIS and pre-processing of solar_unit_production

# Wind Turbine
if has_wind
    wind = tech_params["technology_parameters"]["wind_turbine"]
    wind_capex = wind["investment_cost"]
    wind_opex = wind["operation_cost"] / 100
    wind_subsidy_share = wind["subsidy"] / 100
    wind_lifetime = wind["lifetime"]
    wind_nominal_capacity = res_potential["wind_turbine"]["nominal_capacity"]
    wind_inverter_efficiency = res_potential["wind_turbine"]["inverter_efficiency"] / 100
    wind_power = import_time_series(joinpath(ts_dir, "wind_turbine_potential.csv"), num_seasons, has_seasonality)
    
    # Calculate number of replacements
    wind_replacements = max(0, floor((project_lifetime - 1) / wind_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    wind_replacement_years = wind_lifetime : wind_lifetime : Int(floor((project_lifetime - 1) / wind_lifetime) * wind_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_wind = length(wind_replacement_years) == 0 ? 0 : maximum(wind_replacement_years)
    unused_wind_life = wind_lifetime - (project_lifetime - last_install_wind)
    salvage_wind_fraction = max(0, unused_wind_life / wind_lifetime)
end
# TODO: Implement download from PVGIS and pre-processing of wind_power

# Mini-Hydro
if has_mini_hydro
    hydro = tech_params["technology_parameters"]["mini_hydro"]
    hydro_capex = hydro["investment_cost"]
    hydro_opex = hydro["operation_cost"] / 100
    hydro_subsidy_share = hydro["subsidy"] / 100
    hydro_lifetime = hydro["lifetime"]
    hydro_nominal_capacity = res_potential["mini_hydro"]["nominal_capacity"]
    hydro_unit_production = import_time_series(joinpath(ts_dir, "mini_hydro_potential.csv"), num_seasons, has_seasonality)
    
    # Calculate number of replacements
    hydro_replacements = max(0, floor((project_lifetime - 1) / hydro_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    hydro_replacement_years = hydro_lifetime : hydro_lifetime : Int(floor((project_lifetime - 1) / hydro_lifetime) * hydro_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_hydro = length(hydro_replacement_years) == 0 ? 0 : maximum(hydro_replacement_years)
    unused_hydro_life = hydro_lifetime - (project_lifetime - last_install_hydro)
    salvage_hydro_fraction = max(0, unused_hydro_life / hydro_lifetime)
end

# Battery
if has_battery
    battery = tech_params["technology_parameters"]["battery"]
    battery_nominal_capacity = battery["nominal_capacity"]
    battery_capex = battery["investment_cost"]
    battery_opex = battery["operation_cost"] / 100
    battery_lifetime = battery["lifetime"]
    η_charge = battery["charging_efficiency"] / 100
    η_discharge = battery["discharging_efficiency"] / 100
    SOC_min = battery["soc_min"] / 100
    SOC_max = battery["soc_max"] / 100
    SOC_0 = battery["soc_initial"] / 100
    t_charge = battery["charge_time"]
    t_discharge = battery["discharge_time"]

    # Calculate number of replacements
    battery_replacements = max(0, floor((project_lifetime - 1) / battery_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    battery_replacement_years = battery_lifetime : battery_lifetime : Int(floor((project_lifetime - 1) / battery_lifetime) * battery_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_battery = length(battery_replacement_years) == 0 ? 0 : maximum(battery_replacement_years)
    unused_battery_life = battery_lifetime - (project_lifetime - last_install_battery)  
    salvage_battery_fraction = max(0, unused_battery_life / battery_lifetime)
end

# Diesel Generator
if has_diesel_generator
    dg = tech_params["technology_parameters"]["diesel_generator"]
    generator_nominal_capacity = dg["nominal_capacity"]
    generator_efficiency = dg["nominal_efficiency"] / 100
    generator_capex = dg["investment_cost"]
    generator_opex = dg["operation_cost"] / 100
    generator_lifetime = dg["lifetime"]
    fuel_lhv = dg["lower_heating_value"]
    fuel_cost = dg["fuel_cost"]

    # Calculate number of replacements
    generator_replacements = max(0, floor((project_lifetime - 1) / generator_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    generator_replacement_years = generator_lifetime : generator_lifetime : Int(floor((project_lifetime - 1) / generator_lifetime) * generator_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_generator = length(generator_replacement_years) == 0 ? 0 : maximum(generator_replacement_years)
    unused_generator_life = generator_lifetime - (project_lifetime - last_install_generator)
    salvage_generator_fraction = max(0, unused_generator_life / generator_lifetime)
end


# Biogas Generator
if has_biogas_generator
    biogas = tech_params["technology_parameters"]["biogas_generator"]
    biogas_nominal_capacity = biogas["nominal_capacity"]
    biogas_efficiency = biogas["nominal_efficiency"] / 100
    biogas_capex = biogas["investment_cost"]
    biogas_opex = biogas["operation_cost"] / 100
    biogas_lifetime = biogas["lifetime"]
    biogas_fuel_lhv = biogas["lower_heating_value"]
    biogas_fuel_cost = biogas["fuel_cost"]

    # Calculate number of replacements
    biogas_replacements = max(0, floor((project_lifetime - 1) / biogas_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    biogas_replacement_years = biogas_lifetime : biogas_lifetime : Int(floor((project_lifetime - 1) / biogas_lifetime) * biogas_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_biogas = length(biogas_replacement_years) == 0 ? 0 : maximum(biogas_replacement_years)
    unused_biogas_life = biogas_lifetime - (project_lifetime - last_install_biogas)
    salvage_biogas_fraction = max(0, unused_biogas_life / biogas_lifetime)
end

# Grid Connection
if has_grid_connection
    grid = tech_params["technology_parameters"]["grid_connection"] # Dict
    allow_grid_export = grid["allow_export"] # bool
    max_line_capacity = grid["line_capacity"]

    # Load CSVs for cost of import and (optional) export price
    grid_cost_path = joinpath(ts_dir, "grid_cost.csv")
    grid_cost = import_time_series(grid_cost_path, num_seasons, has_seasonality)

    # Load grid prices if export is allowed
    grid_prices_path = joinpath(ts_dir, "grid_price.csv")
    if isfile(grid_prices_path) && allow_grid_export
        grid_price = import_time_series(grid_prices_path, num_seasons, has_seasonality)
    end

    # Load grid availability matrix
    grid_availability_path = joinpath(ts_dir, "grid_availability_matrix.csv")
    if isfile(grid_availability_path)
        grid_availability = import_time_series(grid_availability_path, num_seasons, has_seasonality)
    else
        error("Grid is connected but no grid_availability_matrix.csv found at $grid_availability_path")
    end
end

# TODO: Implement logic for inverter efficiency and losses <--> layout_id

# Extract system-level constraints
system_constraints = tech_params["system_constraints"]
maximum_lost_load = system_constraints["maximum_lost_load"] / 100  # store as fraction 0–1
minimum_renewable_penetration = system_constraints["minimum_renewable_penetration"] / 100  # store as fraction 0–1