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

Asynchronously launches the appropriate JuMP optimization model using the formulation
defined in model_uncertainties.yaml. Logs all activity to logs.txt and sets status.txt.
"""
function run_model_async(project_id::String, solver::String, settings::Dict)
    Threads.@spawn begin
        project_dir = joinpath("projects", project_id)

        try
            isdir(project_dir) || error("Project folder does not exist: $project_id")

            # === Load formulation from YAML ===
            yaml_path = joinpath(project_dir, "model_uncertainties.yaml")
            isfile(yaml_path) || error("Missing model_uncertainties.yaml for project $project_id")
            formulation = YAML.load_file(yaml_path)["formulation"]

            # === Paths ===
            main_script  = joinpath("models", formulation, "main.jl")
            log_file     = joinpath(project_dir, "logs.txt")
            results_file = joinpath(project_dir, "results", "results.json")

            # === Write initial status ===
            write_status(project_dir, "running")

            # === Prepare command
            settings_json = JSON3.write(settings)
            cmd = `julia --project $main_script $project_id $solver $settings_json`

            # === Run and capture logs
            open(log_file, "w") do log_io
                try
                    log_line(log_io, "Launching model for formulation: $formulation")
                    log_line(log_io, "Running: julia $main_script $project_id $solver")

                    run(pipeline(cmd, stdout=log_io, stderr=log_io); wait=true)

                    log_line(log_io, "Optimization completed successfully.")
                    log_line(log_io, "Results written to $results_file")

                catch err
                    
                    log_line(log_io, "ERROR: Model execution failed.")
                    log_line(log_io, sprint(showerror, err))
                end
            end

            # === Write final status
            write_status(project_dir, isfile(results_file) ? "done" : "error")

        catch err_outer
            # Write fallback status
            try write_status(project_dir, "error") catch end

            # Attempt fallback logging
            try
                open(joinpath(project_dir, "logs.txt"), "a") do log_io
                    log_line(log_io, "FATAL ERROR: Unexpected failure in run_model_async")
                    log_line(log_io, sprint(showerror, err_outer))
                end
            catch
                # Do nothing if logs.txt can't be written
            end

            @error "Optimization failed for project $project_id" exception=err_outer
        end
    end
end

end # module
