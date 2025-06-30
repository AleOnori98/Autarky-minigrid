using JSON3

# Load helpers and core logic
include("../core/save_csv.jl")
include("../schemas/schema_paths.jl")
include("../utils/request_handler.jl")
include("../utils/simulate_grid_availability.jl")

using .SchemaPaths: SCHEMA_PATHS
using .RequestHandlerUtils: handle_post_request
using .CSVWriter: save_availability_matrix_csv
using .GridAvailabilityUtils: simulate_and_save_grid_availability

"""
    grid_availability_handler(req::HTTP.Request) -> HTTP.Response

Handles a request to simulate a grid availability matrix.
Takes:
- avg_outages_per_year (numeric)
- avg_outage_duration (numeric, hours)

Calls backend logic to simulate the availability matrix,
saves the CSV under the project folder, and returns the file path.

# Example Input JSON:
{
  "project_id": "abc123",
  "avg_outages_per_year": 20,
  "avg_outage_duration": 2.5
}

# Returns:
{
  "project_id": "abc123",
  "file_path": "projects/abc123/time_series/grid_availability_matrix.csv"
}
"""
function grid_availability_handler(req)
    return handle_post_request(
        req,
        SCHEMA_PATHS["grid_availability"],
        data -> begin
            project_id = data[:project_id]
            avg_outages = data[:avg_outages_per_year]
            avg_duration = data[:avg_outage_duration]

            file_path = simulate_and_save_grid_availability(
                project_id,
                avg_outages,
                avg_duration
            )

            return Dict(
                "project_id" => project_id,
                "file_path" => file_path
            )
        end
    )
end
