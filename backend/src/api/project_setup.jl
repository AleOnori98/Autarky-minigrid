using JSON3, UUIDs

# Core logic and helpers
include("../core/save_yaml.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")

using .YAMLSaver: save_project_setup
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    project_setup_handler(req::HTTP.Request) -> HTTP.Response

Handles initialization of a new project. Validates user inputs (metadata, location, time config)
against a schema, generates a unique `project_id`, stores the data in a YAML file, and returns the ID.

# Input JSON (example):
{
  "project_name": "Faza Mini-Grid",
  "description": "Kenya pilot case",
  "location": {
    "latitude": -2.056276,
    "longitude": 41.110239
  },
  "time_horizon": 20,
  "time_resolution": "hourly",
  "seasonality_enabled": true,
  "seasonality_option": "4 seasons"
  "typical_profile": "day",
}

# Success Response:
{
  "status": "ok",
  "message": "Data saved successfully",
  "project_id": "c9bfcf7e-7164-4d83-b40f-03b0fa9602f7"
}
"""
function project_setup_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["project_setup"],
        data -> begin
            project_id = string(UUIDs.uuid4())
            save_project_setup(project_id, Dict(data))  # Convert to mutable Dict
            return project_id
        end
    )
end
