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
    results_path = joinpath(project_dir, "results", "results.json") 

    println("Looking into project directory: $project_dir")
    println("Checking paths:")
    println("    - status.txt → $status_path")
    println("    - logs.txt   → $logs_path")
    println("    - results.json → $results_path")

    println("File existence:")
    println("    - status.txt exists? ", isfile(status_path))
    println("    - logs.txt exists?   ", isfile(logs_path))
    println("    - results.json exists? ", isfile(results_path))

    # Read status
    if isfile(status_path)
        status = strip(read(status_path, String))
        println("Read status.txt: \"$status\"")
    else
        status = "unknown"
        println("status.txt not found. Defaulting to: \"$status\"")
    end

    # Read logs
    if isfile(logs_path)
        logs_raw = read(logs_path, String)
        logs = split(logs_raw, '\n')
        println("Loaded logs.txt (", length(logs), " lines)")
    else
        logs = []
        println("logs.txt not found. Returning empty logs")
    end

    # Base response
    response = Dict(
        "status" => status,
        "logs" => logs
    )

    # Add results if done
    if status == "done"
        if isfile(results_path)
            println("Loading results.json...")
            results = JSON3.read(read(results_path, String))
            response["results"] = results
            println("results.json loaded and added to response.")
        else
            println("status == \"done\" but results.json is missing!")
        end
    else
        println("ℹStatus is \"$status\" — skipping results.json.")
    end

    return response
end

end # module
