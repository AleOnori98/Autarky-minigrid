"""
YAMLSaver

This module contains utility functions to save various structured project data
(e.g., project setup, system configuration) as YAML files inside a 
per-project folder tree under `/projects/{project_id}/`.

All save operations are centralized via `save_yaml_data(...)` for consistency.
"""
module YAMLSaver


using YAML
export save_yaml_data, 
       save_project_setup, 
       save_system_configuration, 
       save_technology_parameters, 
       save_renewables_technical_yaml,
       save_model_uncertainties_yaml,
       save_solver_settings_yaml

"""
    save_yaml_data(project_id::String, filename::String, content::Dict)

Generic function to save any YAML dictionary to a project-specific file.
Creates the project directory if it doesn't exist.
"""
function save_yaml_data(project_id::String, filename::String, content::Dict)
    project_dir = joinpath("projects", project_id)
    isdir(project_dir) || mkpath(project_dir)

    yaml_path = joinpath(project_dir, filename)
    YAML.write_file(yaml_path, content)
    @info "✅ Saved $filename for project ID $project_id at $yaml_path"
end


"""
    save_project_setup(project_id::String, data::Dict)

Processes and saves the project setup data to project_setup.yaml.
"""
function save_project_setup(project_id::String, data::Dict)
    yaml_content = Dict(
        "project_settings" => Dict(
            "project_name" => data[:project_name],
            "description" => data[:description],
            "latitude" => data[:location][:latitude],
            "longitude" => data[:location][:longitude],
            "time_horizon" => data[:time_horizon],
            "time_resolution" => data[:time_resolution],
            "seasonality" => data[:seasonality_enabled],
            "seasonality_option" => data[:seasonality_option],
            "typical_profile" => data[:typical_profile]
        )
    )
    save_yaml_data(project_id, "project_setup.yaml", yaml_content)

end

"""
    save_system_configuration(project_id::String, data::Dict)

Processes and saves the system configuration data to system_configuration.yaml.
Throws an error if the project directory is not found.
"""
function save_system_configuration(project_id::String, data::Dict)
    project_dir = joinpath("projects", project_id)
    isdir(project_dir) || error("Project ID does not exist: $project_id")

    yaml_content = Dict(
        "enabled_components" => data[:enabled_components],
        "layout_id" => data[:layout_id]
    )
    save_yaml_data(project_id, "system_configuration.yaml", yaml_content)
end


"""
    save_technology_parameters(project_id::String, data::Dict)

Processes and saves all project-wide economic settings and technology-specific parameters
to technology_parameters.yaml.
"""
function save_technology_parameters(project_id::String, data::Dict)
    project_dir = joinpath("projects", project_id)
    isdir(project_dir) || error("Project ID does not exist: $project_id")

    yaml_content = Dict(
        "economic_settings" => data[:economic_settings],
        "technology_parameters" => data[:technology_parameters]
    )

    save_yaml_data(project_id, "technology_parameters.yaml", yaml_content)
end

"""
    save_renewables_technical_yaml(project_id::String, technology::String, parameters::Dict)

Saves or updates technical parameters for the given technology inside:
projects/{project_id}/renewables_potential.yaml
"""
function save_renewables_technical_yaml(project_id::String, technology::String, parameters::Dict)
    filepath = joinpath("projects", project_id, "renewables_potential.yaml")

    # Load existing content if file exists
    config = isfile(filepath) ? YAML.load_file(filepath) : Dict()

    # Update specific technology
    config[technology] = parameters

    # Write back
    YAML.write_file(filepath, config)
end

"""
    save_model_uncertainties_yaml(project_id::String, data::Dict)

Processes and saves model uncertainty configuration to model_uncertainties.yaml.
"""
function save_model_uncertainties_yaml(project_id::String, data::Dict)
    project_dir = joinpath("projects", project_id)
    isdir(project_dir) || error("Project ID does not exist: $project_id")

    save_yaml_data(project_id, "model_uncertainties.yaml", data)
end

"""
    save_solver_settings_yaml(project_id::String, solver_name::String, solver_settings::Dict)

Saves the solver name and its settings to solver_settings.yaml inside the project folder.
"""
function save_solver_settings_yaml(project_id::String, solver_name::String, solver_settings::Dict)
    yaml_content = Dict(
        "solver_name" => solver_name,
        "solver_settings" => solver_settings
    )
    save_yaml_data(project_id, "solver_parameters.yaml", yaml_content)
end


end  # module
