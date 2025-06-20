using JSON3

# Load core logic and utilities
include("../core/save_yaml.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")

using .YAMLSaver: save_system_configuration
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    system_configuration_handler(req::HTTP.Request) -> HTTP.Response

Handles system architecture selection. Saves enabled components and selected layout ID
to the project directory under a valid project_id.

# Input JSON structure:
{
  "project_id": "abc123",
  "enabled_components": {
    "solar_pv": true,
    "wind_turbine": false,
    "battery": true,
    "diesel_generator": false,
    "grid_connection": false,
    "fully_ac": true
  },
  "layout_id": 1
}

# Returns:
- On success: status, message, layout_id, project_id, file_paths
- On error: status, message
"""
function system_configuration_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["system_configuration"],
        data -> begin
            project_id = data[:project_id]
            save_system_configuration(project_id, Dict(data))

            return Dict(
                "project_id" => project_id,
                "file_paths" => ["projects/$project_id/system_configuration.yaml"]
            )
        end
    )
end
