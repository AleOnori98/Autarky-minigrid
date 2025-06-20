
# === Activate environment ===
using Pkg
Pkg.activate(@__DIR__)

@info "Activated environment at: $(Base.active_project())"
@info "Current LOAD_PATH: $(LOAD_PATH)"

# === Load packages ===
using HTTP

@info "Working directory: $(pwd())"

# === Load API handlers ===
include("src/api/project_setup.jl")
include("src/api/system_configuration.jl")
include("src/api/technology_parameters.jl")
include("src/api/load_demand.jl")
include("src/api/renewables_potential.jl")
include("src/api/model_uncertainties.jl")
include("src/api/model_optimize.jl")
include("src/api/status.jl")

# === Define routes ===
const ROUTES = Dict(
    "/project-setup" => project_setup_handler,
    "/system-configuration" => system_configuration_handler,
    "/technology-parameters" => technology_parameters_handler,
    "/load-demand" => load_demand_handler,
    "/renewables-potential" => renewables_potential_handler,
    "/model-uncertainties" => model_uncertainties_handler,
    "/model-optimize" => model_optimize_handler,
)

# === Add CORS headers ===
function add_cors_headers(res::HTTP.Response)
    HTTP.setheader(res, "Access-Control-Allow-Origin" => "*")
    HTTP.setheader(res, "Access-Control-Allow-Methods" => "GET, POST, OPTIONS")
    HTTP.setheader(res, "Access-Control-Allow-Headers" => "Content-Type")
    return res
end

# === Central router with /status support ===
function router(req::HTTP.Request)
    if req.method == "OPTIONS"
        return add_cors_headers(HTTP.Response(200))  # CORS preflight
    elseif req.method in ("GET", "HEAD") && req.target == "/"
        return add_cors_headers(HTTP.Response(200, "Autarky backend is live!"))
    elseif startswith(req.target, "/status")
        return add_cors_headers(status_handler(req))
    elseif haskey(ROUTES, req.target)
        return add_cors_headers(ROUTES[req.target](req))
    else
        return add_cors_headers(HTTP.Response(404, "Route not found"))
    end
end

# === Start HTTP server ===
try
    port = parse(Int, get(ENV, "PORT", "8000"))
    @info "Starting server on 0.0.0.0:$port"
    HTTP.serve(router, "0.0.0.0", port)
catch e
    @error "Failed to start server: $e"
    Base.exit(1)
end
