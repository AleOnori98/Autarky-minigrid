using JSON3

# Load utilities and core logic
include("../core/save_yaml.jl")
include("../core/save_csv.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")

using .YAMLSaver: save_technology_parameters
using .CSVWriter: save_grid_cost_csv, save_grid_price_csv
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    technology_parameters_handler(req::HTTP.Request) -> HTTP.Response

Handles POST requests to store technology parameters, economic settings,
and system-level constraints for a project. Data is validated against a JSON schema 
and saved to YAML. If grid connection data includes time series, the backend 
saves the corresponding CSV files under the project folder.

# Expected Input JSON:
{
  "project_id": "abc123",
  "economic_settings": {
    "discount_rate": 6.5,
    "currency": "USD"
  },
  "system_constraints": {
    "maximum_lost_load": 5.0,
    "minimum_renewable_penetration": 70.0
  },
  "technology_parameters": {
    "solar_pv": { ... },
    "battery": { ... },
    "diesel_generator": { ... },
    "grid_connection": {
      "allow_export": true,
      "line_capacity": 100.0,
      "grid_cost": { "timestep": [...], "winter": [...], ... },
      "grid_price": { "timestep": [...], "winter": [...], ... }
    }
  }
}

# Returns:
- On success: Dict with status, message, project_id, file_paths
- On error: Dict with status, message
"""
function technology_parameters_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["technology_parameters"],
        data -> begin
            project_id = data[:project_id]
            tech_params = Dict(string(k) => v for (k, v) in data[:technology_parameters])
            file_paths = ["projects/$project_id/technology_parameters.yaml"]

            # Save YAML with economic settings + system constraints + tech parameters
            save_technology_parameters(project_id, Dict(data))

            # If grid connection is provided, save cost/price CSVs
            if haskey(tech_params, "grid_connection")
                grid_data = tech_params["grid_connection"]

                if haskey(grid_data, "grid_cost")
                    grid_cost = Dict(grid_data["grid_cost"])
                    save_grid_cost_csv(project_id, grid_cost)
                    push!(file_paths, "projects/$project_id/time_series/grid_cost.csv")
                end

                if get(grid_data, "grid_prices", nothing) !== nothing
                    grid_price = Dict(grid_data["grid_prices"])
                    save_grid_price_csv(project_id, grid_price)
                    push!(file_paths, "projects/$project_id/time_series/grid_price.csv")
                end
            end

            return Dict(
                "project_id" => project_id,
                "file_paths" => file_paths
            )
        end
    )
end
