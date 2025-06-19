module Utils

using JuMP, CSV, DataFrames, YAML

"""
Load time series data from a CSV file and validate its structure based on seasonality settings.
"""
function import_time_series(csv_file_path::String, num_seasons::Int, seasonality::Bool; delimiter::Char=',', decimal::Char='.')::DataFrame
    if !isfile(csv_file_path)
        error("The CSV file at path '$csv_file_path' does not exist.")
    end

    try
        data = CSV.read(csv_file_path, DataFrame; delim=delimiter, decimal=decimal)

        # Validation for seasonality
        if seasonality
            if size(data, 2) != num_seasons
                error("Invalid CSV format: Expected $num_seasons columns for seasonality, but found $(size(data, 2)).")
            end
        else
            if size(data, 2) != 1
                # Report a warning and truncate to the first column
                println("Warning: Seasonality is disabled, but the CSV file has multiple columns. Using only the first column.")
                data = data[:, 1]  # Keep only the first column
                # Convert to DataFrame with a single column
                data = DataFrame(:Time_Series => data)
            end
        end

        return data
    catch e
        error("Error loading CSV file: $(e.msg)")
    end
end

"""
Sample the generator efficiency curve at `n_samples` equally spaced relative output points,
excluding points where efficiency is zero to avoid invalid divisions later.
Also plots and saves the sampled efficiency curve into the results folder.
"""
function sample_efficiency_curve(gen_efficiency_df, n_samples)
    # Extract columns (make sure your CSV header matches exactly)
    relative_output = gen_efficiency_df[:, 1] ./ 100  # Normalize from 0–100% → 0–1
    efficiency = gen_efficiency_df[:, 2] ./ 100       # Normalize efficiency % → 0–1

    # Build interpolation
    interpolation = LinearInterpolation(relative_output, efficiency, extrapolation_bc=Line())

    # Sampling points (equally spaced between 0 and 1)
    sampled_relative_output = range(0, 1, length=n_samples)

    # Interpolated efficiencies at sampled points
    sampled_efficiency = [interpolation(r) for r in sampled_relative_output]

    # Remove sampled points where efficiency is zero
    valid_indices = findall(e -> e > 0, sampled_efficiency)
    sampled_relative_output = sampled_relative_output[valid_indices]
    sampled_efficiency = sampled_efficiency[valid_indices]

    return sampled_relative_output, sampled_efficiency
end

end # module Utils