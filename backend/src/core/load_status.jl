module StatusLoader

using JSON3

export get_status_response

"""
    get_status_response(project_id::String) -> Dict

Reads status.txt, logs.txt, and (optionally) results.json.
Returns a Dict matching frontend expectations.
"""
function get_status_response(project_id::String)
    # Initialize paths
    project_dir = joinpath("projects", project_id)
    status_path = joinpath(project_dir, "status.txt")
    logs_path = joinpath(project_dir, "logs.txt")
    results_path = joinpath(project_dir, "results.json")

    # Read status
    status = isfile(status_path) ? strip(read(status_path, String)) : "unknown"

    # Read logs
    logs = isfile(logs_path) ? split(read(logs_path, String), '\n') : []

    # Base response
    response = Dict(
        "status" => status,
        "logs" => logs
    )

    # Add results if done
    if status == "done" && isfile(results_path)
        results = JSON3.read(read(results_path, String))
        response["results"] = results
    end

    return response
end

end # module
