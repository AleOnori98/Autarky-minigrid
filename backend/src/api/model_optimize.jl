using JSON3
include("../core/save_yaml.jl")
include("../core/run_model.jl")
include("../utils/request_handler.jl")
include("../schemas/schema_paths.jl")

using .RequestHandlerUtils: handle_post_request
using .YAMLSaver: save_solver_settings_yaml
using .RunModel: run_model_async
using .SchemaPaths: SCHEMA_PATHS


"""
    model_optimize_handler(req::HTTP.Request) -> HTTP.Response

Handles POST request to launch model optimization asynchronously.

# Input JSON structure:
{
    "project_id": "string",
    "solver_name": "string",
    "solver_settings": {
        "setting_key": "value"
    }
}
"""
function model_optimize_handler(req::HTTP.Request)
    return handle_post_request(
        req,
        SCHEMA_PATHS["model_optimize"],
        data -> begin
            project_id = data[:project_id]
            solver_name = data[:solver_name]
            solver_settings = haskey(data, :solver_settings) ? data[:solver_settings] : Dict()

            # Save solver config to YAML
            save_solver_settings_yaml(project_id, solver_name, Dict(solver_settings))

            # Run the model asynchronously
            run_model_async(project_id, solver_name, Dict(solver_settings))
            return project_id
        end
    )
end
