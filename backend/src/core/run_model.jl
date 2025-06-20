module RunModel

using Dates, JSON3, YAML

export run_model_async

# === Internal Helper: Timestamped log entry ===
function log_line(io::IO, msg::AbstractString)
    timestamp = Dates.format(now(), "HH:MM:SS")
    println(io, "[$timestamp] $msg")
end

# === Internal Helper: write status.txt ===
function write_status(project_dir::String, status::String)
    status_file = joinpath(project_dir, "status.txt")
    open(status_file, "w") do io
        write(io, status)
    end
end

"""
    run_model_async(project_id::String, solver::String, settings::Dict)

Launches the JuMP optimization model using the formulation
defined in model_uncertainties.yaml. Logs activity and writes status.txt.
"""
function run_model_async(project_id::String, solver::String, settings::Dict)
    project_dir = joinpath("projects", project_id)
    @info "🟢 Starting run_model_async for project $project_id with solver $solver"
    @info "🟢 Settings: $settings"
    @info "🟢 Project directory: $project_dir"

    try
        isdir(project_dir) || error("❌ Project folder does not exist: $project_id")

        yaml_path = joinpath(project_dir, "model_uncertainties.yaml")
        isfile(yaml_path) || error("❌ Missing model_uncertainties.yaml for project $project_id")

        formulation = YAML.load_file(yaml_path)["formulation"]
        main_script = joinpath("models", formulation, "main.jl")
        log_file = joinpath(project_dir, "logs.txt")
        results_file = joinpath(project_dir, "results", "results.json")

        @info "🟢 Formulation: $formulation"
        @info "🟢 Main script: $main_script"

        # Set initial status
        write_status(project_dir, "running")

        # Build command
        settings_json = JSON3.write(settings)
        cmd = `julia --project $main_script $project_id $solver $settings_json`
        @info "🟢 Command prepared: $cmd"

        # Run and log
        open(log_file, "w") do log_io
            try
                log_line(log_io, "Launching model for formulation: $formulation")
                log_line(log_io, "Running command: $cmd")

                # Stream logs directly (lower memory pressure)
                run(pipeline(cmd; stdout=log_io, stderr=log_io))

                log_line(log_io, "Optimization completed successfully.")
                log_line(log_io, "Checking for results file at: $results_file")

            catch err
                log_line(log_io, "❌ ERROR during model execution")
                log_line(log_io, sprint(showerror, err))
            end
        end

        # Set final status based on results file
        final_status = isfile(results_file) ? "done" : "error"
        write_status(project_dir, final_status)
        @info "🟢 Final status for $project_id: $final_status"

    catch err_outer
        @error "❌ FATAL ERROR in run_model_async for $project_id" exception=err_outer
        try
            write_status(project_dir, "error")
            open(joinpath(project_dir, "logs.txt"), "a") do log_io
                log_line(log_io, "FATAL ERROR: Unexpected failure in run_model_async")
                log_line(log_io, sprint(showerror, err_outer))
            end
        catch
            @warn "⚠ Unable to write fallback status or logs for $project_id"
        end
    end
end

end # module
