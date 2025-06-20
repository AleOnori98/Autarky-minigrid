module CSVWriter

using CSV, DataFrames

export save_load_demand_csv, save_renewables_potential_csv,
       save_grid_cost_csv, save_grid_prices_csv,
       save_forecast_error_csv, save_availability_matrix_csv

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
    @info "✅ Saved load demand profile for project ID $project_id at $filepath"
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
    @info "✅ Saved renewables potential profile for project ID $project_id at $filepath"
end

"""
    save_grid_cost_csv(project_id::String, cost_data::Dict)

Converts a grid cost dictionary to CSV and stores it under:
projects/{project_id}/time_series/grid_cost.csv
"""
function save_grid_cost_csv(project_id::String, cost_data::Dict)
    df = DataFrame(cost_data)
    folder = joinpath("projects", project_id, "time_series")
    isdir(folder) || mkpath(folder)
    filepath = joinpath(folder, "grid_cost.csv")
    CSV.write(filepath, df)
    @info "✅ Saved grid cost data for project ID $project_id at $filepath"
end

"""
    save_grid_prices_csv(project_id::String, prices_data::Dict)

    Converts a grid prices dictionary to CSV and stores it under:
projects/{project_id}/time_series/grid_prices.csv
"""
function save_grid_prices_csv(project_id::String, prices_data::Dict)
    df = DataFrame(prices_data)
    folder = joinpath("projects", project_id, "time_series")
    isdir(folder) || mkpath(folder)
    filepath = joinpath(folder, "grid_price.csv")
    CSV.write(filepath, df)
    @info "✅ Saved grid prices data for project ID $project_id at $filepath"
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
    @info "✅ Saved forecast errors for $technology in project ID $project_id at $filepath"
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
    @info "✅ Saved grid availability matrix for project ID $project_id at $filepath"
end

end # module
