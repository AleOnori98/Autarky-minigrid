using JSON3
include("../core/save_csv.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")

using .CSVWriter: save_load_demand_csv
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    load_demand_handler(req::HTTP.Request) -> HTTP.Response

Handles load demand profile upload from the frontend. Expects a parsed JSON
dictionary representing a time series (e.g., hourly seasonal values).

# Input JSON structure:
{
  "project_id": "abc123",
  "load_profile": {
    "timestep": [0, 1, 2, ..., 23],
    "dry": [12.5, 13.0, ..., 10.2],
    "wet": [11.0, 11.5, ..., 9.8]
  }
}
"""
function load_demand_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["load_demand"],
        data -> begin
            project_id = data[:project_id]
            profile_dict = Dict(data[:load_profile])
            save_load_demand_csv(project_id, profile_dict)

            return Dict(
                "project_id" => project_id,
                "file_paths" => ["projects/$project_id/time_series/load_demand.csv"]
            )
        end
    )
end