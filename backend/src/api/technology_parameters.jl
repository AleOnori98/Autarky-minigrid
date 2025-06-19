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
            save_technology_parameters(data[:project_id], Dict(data))
            return data[:project_id]  # Ensure project_id is included in response
        end
    )
end
