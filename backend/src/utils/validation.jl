"""
ValidationUtils

This module provides functions to validate incoming JSON data against
predefined JSON Schema files. It ensures payload integrity before the data
is saved or used in optimization routines.

It is designed to work with both `JSON3.read` (used by HTTP.jl) and
schema validation from `JSONSchema.jl`, which requires a `Dict`-like structure.
"""
module ValidationUtils

using JSON3
using JSON
using JSONSchema

export validate_with_schema

"""
    validate_with_schema(data::Any, schema_path::String)

Validates a JSON-compatible object (`Dict`, `JSON3.Object`, etc.)
against the JSON schema found at `schema_path`.

# Arguments
- `data`: JSON data already parsed (e.g., from JSON3.read)
- `schema_path`: Path to a `.schema.json` file

# Raises
- `ErrorException` if validation fails, with explanation

# Returns
- `nothing` if valid (no exception raised)
"""
function validate_with_schema(data::Any, schema_path::String)
    schema = Schema(JSON.parsefile(schema_path))

    result = validate(schema, data)

    if result !== nothing
        error("JSON Schema validation failed:\n" * string(result))
    end
end

end # module
