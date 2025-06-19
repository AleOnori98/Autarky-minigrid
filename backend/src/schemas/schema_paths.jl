module SchemaPaths

export SCHEMA_PATHS

"""
SCHEMA_PATHS

A central registry of all API-related JSON Schema file paths.
Each key corresponds to a logical API name.
"""
const SCHEMA_PATHS = Dict(
    "project_setup" => "src/schemas/project_setup.schema.json",
    "system_configuration" => "src/schemas/system_configuration.schema.json",
    "technology_parameters" => "src/schemas/technology_parameters.schema.json",
    "load_demand" => "src/schemas/load_demand.schema.json",
    "renewables_potential" => "src/schemas/renewables_potential.schema.json",
    "model_uncertainties" => "src/schemas/model_uncertainties.schema.json",
    "model_optimize" => "src/schemas/model_optimize.schema.json",
)

end
