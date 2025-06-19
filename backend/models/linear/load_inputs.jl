using YAML, CSV, DataFrames
include(joinpath(@__DIR__, "utils.jl"))
using .Utils: import_time_series

# === Load YAMLs ===
project_setup = YAML.load_file(joinpath(project_dir, "project_setup.yaml"))
system_config = YAML.load_file(joinpath(project_dir, "system_configuration.yaml"))
tech_params = YAML.load_file(joinpath(project_dir, "technology_parameters.yaml"))
res_potential = YAML.load_file(joinpath(project_dir, "renewables_potential.yaml"))
model_uncert = YAML.load_file(joinpath(project_dir, "model_uncertainties.yaml"))
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

# Extract project setup settings
project_settings = project_setup["project_settings"] # Dict
latitude = project_settings["latitude"] # float
longitude = project_settings["longitude"] # float
time_resolution = project_settings["time_resolution"] # string
project_lifetime = project_settings["time_horizon"] # int
discount_rate = tech_params["economic_settings"]["discount_rate"] 
# Calculate the yearly discount factor
discount_factor = [1 / ((1 + discount_rate) ^ y) for y in 1:project_lifetime]

# Logic for time resolution
if time_resolution == "hourly"
    Δt = 1 # time step duration in hours
# TODO: Add support for other time resolutions if needed
else
    error("Unsupported time resolution: $time_resolution")
end

# Define total number of hours in a year and scaling factor
annual_hours = 8760
operation_time_steps = 24  # assuming daily simulation (e.g., 24 hourly steps)
# TODO: Add support for other operation time steps if needed
year_scale_factor = annual_hours / operation_time_steps  

# Define season_weights based on seasonality
if has_seasonality
    if seasonality_option == "4 seasons"
        num_seasons = 4
        # Standard winter, spring, summer, fall mapping (3 months each)
        season_months = Dict(
            1 => [12, 1, 2],   # Winter
            2 => [3, 4, 5],    # Spring
            3 => [6, 7, 8],    # Summer
            4 => [9, 10, 11]   # Fall
        )
    elseif seasonality_option == "2 seasons"
        num_seasons = 2
        # Typical tropical: dry and wet
        season_months = Dict(
            1 => [11, 12, 1, 2, 3],  # Dry season
            2 => [4, 5, 6, 7, 8, 9, 10]  # Wet season
        )
    else
        error("Unsupported seasonality_option: $seasonality_option")
    end

    # Compute seasonal weights as fraction of the year scaled to operation_time_steps
    season_weights = Dict(
        s => (length(season_months[s]) / 12.0) * year_scale_factor for s in keys(season_months)
    )
else
    # No seasonality → use one season with full weight
    season_weights = Dict(1 => 1.0 * year_scale_factor)
end

# Load Demand time series from CSV file
load_path = joinpath(ts_dir, "load_demand.csv")
load = import_time_series(load_path, num_seasons, seasonality)

# Solar PV
if has_solar
    solar = tech_params["technology_parameters"]["solar_pv"]
    solar_capex = solar["investment_cost"]
    solar_opex = solar["operation_cost"]
    solar_subsidy_share = solar["subsidy"]
    solar_lifetime = solar["lifetime"]
    solar_nominal_capacity = res_potential["solar_pv"]["nominal_capacity"]
    solar_inverter_efficiency = res_potential["solar_pv"]["inverter_efficiency"]
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
    wind_opex = wind["operation_cost"]
    wind_subsidy_share = wind["subsidy"]
    wind_lifetime = wind["lifetime"]
    wind_nominal_capacity = res_potential["wind_turbine"]["nominal_capacity"]
    wind_inverter_efficiency = res_potential["wind_turbine"]["inverter_efficiency"]
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
# TODO: Add support for unit committment
# TODO: Implement download from PVGIS and pre-processing of wind_power

# Mini-Hydro
if has_mini_hydro
    hydro = tech_params["technology_parameters"]["mini_hydro"]
    hydro_capex = hydro["investment_cost"]
    hydro_opex = hydro["operation_cost"]
    hydro_subsidy_share = hydro["subsidy"]
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
# TODO: Add support for unit committment

# Battery
if has_battery
    battery = tech_params["technology_parameters"]["battery"]
    battery_nominal_capacity = battery["nominal_capacity"]
    battery_capex = battery["investment_cost"]
    battery_opex = battery["operation_cost"]
    battery_lifetime = battery["lifetime"]
    η_charge = battery["charging_efficiency"] 
    η_discharge = battery["discharging_efficiency"] 
    SOC_min = battery["soc_min"] 
    SOC_max = battery["soc_max"]
    SOC_0 = battery["soc_initial"] 
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
# TODO: Add support for unit committment

# Diesel Generator
if has_diesel_generator
    dg = tech_params["technology_parameters"]["diesel_generator"]
    generator_nominal_capacity = dg["nominal_capacity"]
    generator_efficiency = dg["nominal_efficiency"] 
    allow_partial_load = dg["partial_load_enabled"]
    n_samples = dg["efficiency_samples"]
    generator_capex = dg["investment_cost"]
    generator_opex = dg["operation_cost"]
    generator_lifetime = dg["lifetime"]
    fuel_lhv = dg["lower_heating_value"]
    fuel_cost = dg["fuel_cost"]

    # Partial Load Efficiency Curve
    n_samples = 10
    generator_efficiency_curve_path = joinpath(@__DIR__, "config", "generator_efficiency_curve.csv")
    generator_efficiency_curve = CSV.read(generator_efficiency_curve_path, DataFrame)
    # Sample the efficiency curve for piece-wise linear interpolation
    sampled_relative_output, sampled_efficiency = sample_efficiency_curve(generator_efficiency_curve, n_samples)

    # Calculate number of replacements
    generator_replacements = max(0, floor((project_lifetime - 1) / generator_lifetime))
    # Build arrays of valid replacement times (in whole years), up to project_lifetime - 1 ensuring not to index discount_factor past the end.
    generator_replacement_years = generator_lifetime : generator_lifetime : Int(floor((project_lifetime - 1) / generator_lifetime) * generator_lifetime)
    # Calculate the salvage fractions based on the last replacement year
    last_install_generator = length(generator_replacement_years) == 0 ? 0 : maximum(generator_replacement_years)
    unused_generator_life = generator_lifetime - (project_lifetime - last_install_generator)
    salvage_generator_fraction = max(0, unused_generator_life / generator_lifetime)
end
# TODO: Add support for unit committment


# TODO: Add similar block for biogas generator

# TODO: Add grid cost & availability if needed

# TODO: Implement logic for inverter efficiency and losses <--> layout_id

# TODO: Add parameters for optimization settings (lost load, res penetration, etc.)