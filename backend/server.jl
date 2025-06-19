# Activating the project environment
# This ensures that the server uses the correct package versions and dependencies defined in the Project.toml
using Pkg
Pkg.activate(@__DIR__)

using HTTP

# === Load API endpoint handlers ===
include("src/api/project_setup.jl")
include("src/api/system_configuration.jl")
include("src/api/technology_parameters.jl")
include("src/api/load_demand.jl")
include("src/api/renewables_potential.jl")
include("src/api/model_uncertainties.jl")
include("src/api/model_optimize.jl")

# === Register endpoint functions to URL targets ===
const ROUTES = Dict(
    "/project-setup" => project_setup_handler,
    "/system-configuration" => system_configuration_handler,
    "/technology-parameters" => technology_parameters_handler,
    "/load-demand" => load_demand_handler, 
    "/renewables-potential" => renewables_potential_handler,
    "/model-uncertainties" => model_uncertainties_handler,
    "/model-optimize" => model_optimize_handler
)

"""
    router(req::HTTP.Request) -> HTTP.Response

Generic router function that dispatches incoming HTTP requests
to the correct endpoint handler based on the URL target.

Returns:
- 200-series responses from API handlers
- 404 Not Found if the route is not recognized
"""
function router(req::HTTP.Request)
    if haskey(ROUTES, req.target)
        return ROUTES[req.target](req)
    else
        return HTTP.Response(404, "Route not found")
    end
end

# === Start the HTTP multi-threaded server ===
# This will run the HTTP router on port 8000, with support for multi-threaded request handling.
# To enable asynchronous handling (i.e., avoid blocking the main thread), we launch the server in a background task.

Threads.@spawn begin
    HTTP.serve!(router, "0.0.0.0", 8000; reuseaddr=true, verbose=false)
end

# Note:
# - The server runs indefinitely in the background.
# - Incoming HTTP requests are handled by the `router` function.
# - Julia threads will be used to handle concurrent requests, as long as endpoints are designed non-blocking.

