"""
RequestHandlerUtils

This module provides a generic utility function (`handle_post_request`) to handle
typical POST API behavior across endpoints in a consistent and reusable way:
- Method validation
- JSON body parsing
- Schema-based input validation
- Execution of user-defined logic
- Structured success and error responses
"""

module RequestHandlerUtils

include("../utils/response.jl")
include("../utils/validation.jl")

using JSON3
using .ResponseUtils: success_response, error_response
using .ValidationUtils: validate_with_schema

export handle_post_request

"""
    handle_post_request(req::HTTP.Request, schema_path::String, save_callback::Function)

Generic handler for POST endpoints that:
1. Verifies the request method
2. Parses and validates the JSON body
3. Validates against a JSON Schema
4. Executes a user-defined save_callback
5. Returns a structured HTTP response

# Arguments:
- `req`: Incoming HTTP request
- `schema_path`: Path to the JSON schema for input validation
- `save_callback`: Function that accepts a parsed Dict or JSON3.Object and returns the `project_id` (or `nothing`)

# Returns:
- On success: HTTP 200 response with `status`, `message`, and optional `project_id`
- On failure: HTTP 400 response with error details
"""
function handle_post_request(req, schema_path::String, save_callback::Function)
    if req.method != "POST"
        return error_response("Only POST requests are allowed")
    end

    try
        # Read and validate the JSON payload
        body = String(req.body)
        data = JSON3.read(body)
        validate_with_schema(data, schema_path)

        # Execute user-defined logic and return project_id (if any)
        result = save_callback(data)

        # Build a standard success payload
        response_dict = Dict(:status => "ok", :message => "Data saved successfully")
        if result !== nothing
            response_dict[:project_id] = result
        end

        return success_response(response_dict)
    catch err
        return error_response("Request failed: $(err)")
    end
end

end # module
