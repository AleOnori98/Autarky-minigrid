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

Handles uncertainty configuration inputs from the frontend. Supports:
- Formulation: "linear", "expected_values", "probabilistic"
- Grid outage settings (optional if grid is not connected)
- Forecast error profiles (load and renewables)
- Probabilistic config: ICC/JCC toggle and islanding probability

# Input JSON structure:
{
  "project_id": "abc123",
  "formulation": "linear",  # or "expected_values", "icc", "jcc"
  "grid_connected": true,   # or false
  "grid_outage_settings": {
    "availability_matrix": [[1, 0], [0, 1]],  # Example matrix
    "outage_probability": 0.1
  },
  "forecast_errors": {
    "solar_pv": [0.05, 0.07, ...],
    "wind_turbine": [0.03, 0.04, ...]
  },
  "probabilistic_config": {
    "icc_enabled": true,
    "islanding_probability": 0.2
  }
}
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

            # Initialize file paths for saved files
            saved_files = String[]

            # Linear formulation does not require forecast errors or probabilistic config
            if formulation == "linear"
                if grid_connected
                    grid_settings = data[:grid_outage_settings]
                    yaml_content["grid_outage_settings"] = Dict(
                        "avg_outages_per_year" => grid_settings[:avg_outages_per_year],
                        "avg_outage_duration" => grid_settings[:avg_outage_duration]
                    )
                    save_availability_matrix_csv(project_id, Dict(grid_settings[:availability_matrix]))
                    push!(saved_files, "projects/$project_id/time_series/grid_availability_matrix.csv")
                end
            
            # Expected values formulation requires forecast errors
            elseif formulation == "expected_values"
                forecast_errors = data[:forecast_errors]
                yaml_content["forecast_errors"] = Dict()

                for (tech, errors) in forecast_errors
                    save_forecast_error_csv(project_id, tech, errors)
                    yaml_content["forecast_errors"][tech] = true
                    push!(saved_files, "projects/$project_id/time_series/$(tech)_forecast_errors.csv")
                end

                if grid_connected
                    grid_settings = data[:grid_outage_settings]
                    yaml_content["grid_outage_settings"] = grid_settings
                end

            # Probabilistic formulation requires forecast errors and probabilistic config
            elseif formulation in ["icc", "jcc"]
                forecast_errors = data[:forecast_errors]
                yaml_content["forecast_errors"] = Dict()

                for (tech, errors) in forecast_errors
                    save_forecast_error_csv(project_id, tech, errors)
                    yaml_content["forecast_errors"][tech] = true
                    push!(saved_files, "projects/$project_id/time_series/$(tech)_forecast_errors.csv")
                end

                if grid_connected
                    grid_settings = data[:grid_outage_settings]
                    yaml_content["grid_outage_settings"] = grid_settings
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


