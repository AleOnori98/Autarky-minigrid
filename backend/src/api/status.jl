using HTTP, JSON3
include("../core/load_status.jl")
using .StatusLoader: get_status_response

"""
    status_handler(req::HTTP.Request) -> HTTP.Response

Handles GET /status?project_id=abc123
Returns the current status, log lines, and (if completed) results summary.
"""
function status_handler(req::HTTP.Request)
    if req.method == "GET" && occursin("/status", req.target)
        try
            # Parse query parameters to extract project_id
            query = HTTP.URIs.queryparams(HTTP.URIs.URI(req.target))
            project_id = get(query, "project_id", nothing)

            # Validate project_id
            if project_id === nothing
                return HTTP.Response(400, "Missing query parameter: project_id")
            end

            # Load the status response for the given project ID
            response_data = get_status_response(project_id)
            return HTTP.Response(200, JSON3.write(response_data))
        catch err
            return HTTP.Response(500, "Internal error: $(sprint(showerror, err))")
        end
    else
        return HTTP.Response(404, "Not Found")
    end
end

