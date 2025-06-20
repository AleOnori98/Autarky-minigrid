"""
ResponseUtils

This module provides a standardized way to generate HTTP responses for both
successful and failed API calls. It wraps JSON payloads into consistent
structures for frontend integration.
"""
module ResponseUtils

export success_response, error_response
using JSON3, HTTP

"""
Function to create a success response with a payload.
# Arguments:
- `payload`: A dictionary containing the response data.
# Returns:
- An HTTP response with status 200 and the payload serialized as JSON.
"""
function success_response(payload::Dict)
    return HTTP.Response(200, JSON3.write(merge(Dict("status" => "ok"), payload)))
end

"""
Function to create an error response with a message.
# Arguments:
- `msg`: A string containing the error message.
# Returns:
- An HTTP response with status 400 and the error message serialized as JSON.
"""
function error_response(msg::String)
    return HTTP.Response(400, JSON3.write(Dict("status" => "error", "message" => msg)))
end

end # end of module
