using JSON3

# Load utilities and core logic
include("../core/save_yaml.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")

using .YAMLSaver: save_technology_parameters
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    technology_parameters_handler(req::HTTP.Request) -> HTTP.Response

Handles POST requests to store technology parameters and economic settings
for a project. Data is validated against a schema and saved to YAML.

# Expected Input JSON:
{
  "project_id": "abc123",
  "project_economic_settings": {
    "discount_rate": 6.5,
    "currency": "USD"
  },
  "technology_parameters": {
    "solar_pv": { ... },
    "battery": { ... },
    "diesel_generator": { ... }
  }
}

# Returns:
- On success: status, message, project_id
- On error: status, message
"""
function technology_parameters_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["technology_parameters"],
        data -> begin
            project_id = data[:project_id]
            tech_params = Dict(data[:technology_parameters])
            file_paths = ["projects/$project_id/technology_parameters.yaml"]

            # Save YAML with tech + economic settings
            save_technology_parameters(project_id, Dict(data))

            # Check if grid_connection component exists
            if haskey(tech_params, "grid_connection")
                grid_data = tech_params["grid_connection"]

                # Parse and save grid cost CSV
                if haskey(grid_data, "grid_cost")
                    grid_cost = grid_data["grid_cost"]
                    save_grid_cost_csv(project_id, grid_cost)
                    push!(file_paths, "projects/$project_id/time_series/grid_cost.csv")
                end

                # Optional: grid price time series
                if get(grid_data, "grid_prices", nothing) !== nothing
                    save_grid_prices_csv(project_id, grid_data["grid_prices"])
                    push!(file_paths, "projects/$project_id/time_series/grid_price.csv")
                end
            end

            return Dict(
                :project_id => project_id,
                :file_paths => file_paths
            )
        end
    )
end
