using JSON3
include("../core/save_csv.jl")
include("../core/save_yaml.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")

using .CSVWriter: save_renewables_potential_csv
using .YAMLSaver: save_renewables_technical_yaml
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    renewables_potential_handler(req::HTTP.Request) -> HTTP.Response

Handles renewables potential profile (electricity production per unit of nominal capacity) upload from the frontend. 
Expects a parsed JSON dictionary representing a time series (e.g., hourly seasonal values).

# Input JSON structure:
{
  "project_id": "abc123",
  "technology": "solar_pv",
  "mode": "csv_upload",
  "technical_parameters": {
    "component_name": "CS3U-350MS", 
    "nominal_capacity": 1.0,
    "inverter_efficiency": 0.95
  },
  "renewables_potential_profile": {
    "timestep": [0, 1, ..., 23],
    "dry": [ ... ],
    "wet": [ ... ]
  }
}
"""
function renewables_potential_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["renewables_potential"],
        data -> begin
            project_id = data[:project_id]
            technology = data[:technology]
            profile_dict = Dict(data[:renewables_potential_profile])
            parameters_dict = Dict(data[:technical_parameters])

            save_renewables_potential_csv(project_id, technology, profile_dict)
            save_renewables_technical_yaml(project_id, technology, parameters_dict)
        end
    )
end