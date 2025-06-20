module Utils

using JuMP, CSV, DataFrames, YAML, Interpolations

"""
Load time series data from a CSV file and validate its structure based on seasonality settings.
"""
function import_time_series(csv_file_path::String, num_seasons::Int, seasonality::Bool; delimiter::Char=',', decimal::Char='.')::DataFrame
    if !isfile(csv_file_path)
        error("The CSV file at path '$csv_file_path' does not exist.")
    end

    try
        df = CSV.read(csv_file_path, DataFrame; delim=delimiter, decimal=decimal)

        # Drop "timestep" column if present
        has_timestep = "timestep" in names(df)
        if has_timestep
            select!(df, Not("timestep"))
        end

        # Validate number of seasonal columns
        if seasonality
            if size(df, 2) != num_seasons
                error("Invalid CSV format: Expected $num_seasons seasonal columns, but found $(size(df, 2)).")
            end
        else
            if size(df, 2) > 1
                println("Warning: Seasonality is disabled but CSV has multiple columns. Using only the first column.")
                df = DataFrame(:Time_Series => df[:, 1])
            end
        end

        return df
    catch e
        error("Error loading CSV file: $(e.msg)")
    end
end

end # module Utils