module GridAvailabilityUtils

using Random
using Distributions
using DataFrames
using CSV
using YAML

export simulate_and_save_grid_availability

"""
    simulate_and_save_grid_availability(
        project_id::String,
        avg_outages::Number,
        avg_duration::Number
    ) -> String

Simulates a grid availability matrix using a Weibull distribution for Time Between Outages (TBO)
and Outage Duration (OD).

This function:
- Loads `operation_time_steps` and `seasonality_option` from `project_setup.yaml` in the given project folder.
- Determines the number of seasons and uses meaningful column names:
  - "dry" and "wet" for 2 seasons
  - "winter", "spring", "summer", "fall" for 4 seasons
  - "season_1" if no seasonality
- Rescales annual outage stats to the block length.
- Saves the final matrix to `projects/{project_id}/time_series/grid_availability_matrix.csv`.

Returns:
- The relative path to the saved CSV file.
"""
function simulate_and_save_grid_availability(
    project_id::String,
    avg_outages::Number,
    avg_duration::Number
)::String

    # === Load project config ===
    setup_path = joinpath("projects", project_id, "project_setup.yaml")
    project_setup = YAML.load_file(setup_path)
    settings = project_setup["project_settings"]

    periods = settings["operation_time_steps"]
    has_seasonality = settings["seasonality"]
    seasonality_option = settings["seasonality_option"]

    seasons = if has_seasonality
        seasonality_option == "2 seasons" ? 2 :
        seasonality_option == "4 seasons" ? 4 : 1
    else
        1
    end

    # Define meaningful column names
    season_names = if seasons == 2
        ["dry", "wet"]
    elseif seasons == 4
        ["winter", "spring", "summer", "fall"]
    else
        ["season_1"]
    end

    @info "Simulating grid availability for $periods time steps and $seasons season(s)"

    # === Weibull distribution parameters ===
    λ_TBO = 1620 / 60   # scale parameter for Time Between Outages (hours)
    k_TBO = 0.77        # shape parameter for TBO
    λ_OD = 36 / 60      # scale parameter for Outage Duration (hours)
    k_OD = 0.56         # shape parameter for OD

    rng = MersenneTwister()

    data = DataFrame()

    for (i, name) in enumerate(season_names)
        availability = ones(Float64, periods)

        if avg_outages == 0.0 && avg_duration == 0.0
            availability .= 1.0
        else
            # === Rescale to block size ===
            annual_hours = 8760.0
            block_hours = periods
            scale = block_hours / annual_hours

            OD_tot = avg_outages * avg_duration * scale
            TBO_tot = block_hours - OD_tot

            samples_OD = Float64[]
            while sum(samples_OD) < OD_tot
                spl = λ_OD * rand(rng, Weibull(k_OD))
                push!(samples_OD, spl)
                if sum(samples_OD) > OD_tot
                    samples_OD[end] = ceil(samples_OD[end] - (sum(samples_OD) - OD_tot))
                end
            end

            samples_TBO = [λ_TBO * rand(rng, Weibull(k_TBO)) for _ in 1:length(samples_OD)]

            # Rescale TBO samples to match total block length
            k_factor = abs(TBO_tot / sum(samples_TBO))
            samples_TBO .= samples_TBO .* k_factor

            seq = Int[]
            for i in 1:length(samples_OD)
                TBO = round(Int, samples_TBO[i])
                OD = round(Int, samples_OD[i])
                append!(seq, ones(Int, TBO))
                append!(seq, zeros(Int, OD))
                if length(seq) >= periods
                    seq = seq[1:periods]
                    break
                end
            end

            availability .= seq
        end

        data[!, name] = availability
    end

    ts_dir = joinpath("projects", project_id, "time_series")
    isdir(ts_dir) || mkpath(ts_dir)
    file_path = joinpath(ts_dir, "grid_availability_matrix.csv")

    CSV.write(file_path, data)

    return "projects/$project_id/time_series/grid_availability_matrix.csv"
end

end # module
