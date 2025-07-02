using JSON3
include("../core/save_csv.jl")
include("../core/save_yaml.jl")
include("../utils/request_handler.jl")
include("../schemas/schema_paths.jl")

using .CSVWriter: save_forecast_error_csv, save_availability_matrix_csv
using .YAMLSaver: save_model_uncertainties_yaml
using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request

"""
    model_uncertainties_handler(req::HTTP.Request) -> HTTP.Response

Handles uncertainty configuration inputs from the frontend.

Supports:
- Formulation: "linear", "expected_values", "icc", "jcc"
- Optional grid outage matrix upload (linear only)
- Forecast error profiles (load and renewables)
- Probabilistic config: ICC/JCC toggle and islanding probability

"""
function model_uncertainties_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["model_uncertainties"],
        data -> begin
            project_id = data[:project_id]
            formulation = lowercase(data[:formulation])
            grid_connected = data[:grid_connected]

            yaml_content = Dict(
                "formulation" => formulation,
                "grid_connected" => grid_connected
            )

            saved_files = String[]

            if formulation == "linear"
                if grid_connected && haskey(data, :grid_outage_settings)
                    matrix_data = get(data[:grid_outage_settings], :availability_matrix, nothing)
                    if matrix_data !== nothing
                        save_availability_matrix_csv(project_id, Dict(matrix_data))
                        push!(saved_files, "projects/$project_id/time_series/grid_availability_matrix.csv")
                    end
                    yaml_content["grid_outage_settings"] = true
                end

            elseif formulation in ["expected_values", "icc", "jcc"]
                if haskey(data, :forecast_errors)
                    yaml_content["forecast_errors"] = Dict()
                    for tech in ["load", "solar_pv", "wind_turbine", "mini_hydro"]
                        if get(data[:forecast_errors], Symbol(tech), false) == true
                            yaml_content["forecast_errors"][tech] = true
                            # Check for the nested _errors block
                            errors_key = Symbol(tech * "_errors")
                            if haskey(data[:forecast_errors], errors_key)
                                errors_by_season = data[:forecast_errors][errors_key]
                                for (season, matrix) in errors_by_season
                                    save_forecast_error_csv(
                                        project_id, tech, season, matrix
                                    )
                                    push!(saved_files, "projects/$project_id/forecast_errors/$(tech)_errors_$(season).csv")
                                end
                            else
                                error("Missing forecast errors block for $tech!")
                            end
                        end
                    end
                end

                if haskey(data, :probabilistic_config)
                    yaml_content["probabilistic_config"] = data[:probabilistic_config]
                end

            else
                error("Unsupported formulation: $formulation")
            end

            save_model_uncertainties_yaml(project_id, yaml_content)
            push!(saved_files, "projects/$project_id/model_uncertainties.yaml")

            return Dict(
                "project_id" => project_id,
                "file_paths" => saved_files
            )
        end
    )
end


