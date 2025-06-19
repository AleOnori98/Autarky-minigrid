module CSVWriter

using CSV, DataFrames

export save_load_demand_csv,
       save_renewables_potential_csv,
       save_forecast_error_csv,
       save_availability_matrix_csv

"""
    save_load_demand_csv(project_id::String, load_profile::Dict)

Converts the load_profile dictionary to a CSV and stores it under:
projects/{project_id}/time_series/load_demand.csv
"""
function save_load_demand_csv(project_id::String, load_profile::Dict)
    df = DataFrame(load_profile)
    folder = joinpath("projects", project_id, "time_series")
    isdir(folder) || mkpath(folder)
    filepath = joinpath(folder, "load_demand.csv")
    CSV.write(filepath, df)
end

"""
    save_renewables_potential_csv(project_id::String, technology::String, profile::Dict)

Converts the renewables profile to CSV and stores it under:
projects/{project_id}/time_series/{technology}_potential.csv
"""
function save_renewables_potential_csv(project_id::String, technology::String, profile::Dict)
    df = DataFrame(profile)
    folder = joinpath("projects", project_id, "time_series")
    isdir(folder) || mkpath(folder)
    filepath = joinpath(folder, "$(technology)_potential.csv")
    CSV.write(filepath, df)
end

"""
    save_forecast_error_csv(project_id::String, technology::String, errors::Dict)

Converts a forecast error dictionary to CSV and stores it under:
projects/{project_id}/time_series/{technology}_forecast_errors.csv
"""
function save_forecast_error_csv(project_id::String, technology::String, errors::Dict)
    df = DataFrame(errors)
    folder = joinpath("projects", project_id, "time_series")
    isdir(folder) || mkpath(folder)
    filepath = joinpath(folder, "$(technology)_forecast_errors.csv")
    CSV.write(filepath, df)
end

"""
    save_availability_matrix_csv(project_id::String, matrix::Dict)

Converts an availability matrix dictionary to CSV and stores it under:
projects/{project_id}/time_series/grid_availability_matrix.csv
"""
function save_availability_matrix_csv(project_id::String, matrix::Dict)
    df = DataFrame(matrix)
    folder = joinpath("projects", project_id, "time_series")
    isdir(folder) || mkpath(folder)
    filepath = joinpath(folder, "grid_availability_matrix.csv")
    CSV.write(filepath, df)
end

end # module
