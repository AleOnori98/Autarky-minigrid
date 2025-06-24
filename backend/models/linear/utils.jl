module Utils

using JuMP, CSV, DataFrames, YAML, Interpolations

"""
Load time series data from a CSV file and validate its structure based on seasonality settings.
No 'timestep' column is expected; each column corresponds to a season or a single profile.
"""
function import_time_series(csv_file_path::String, num_seasons::Int, seasonality::Bool; delimiter::Char=',', decimal::Char='.')::DataFrame
    
    # Validate the CSV file path
    if !isfile(csv_file_path)
        error("The CSV file at path '$csv_file_path' does not exist.")
    end

    try
        # Read the CSV file into a DataFrame
        df = CSV.read(csv_file_path, DataFrame; delim=delimiter, decimal=decimal)

        # Validate the structure of the DataFrame based on seasonality
        if seasonality
            if size(df, 2) != num_seasons
                error("Invalid CSV format: Expected $num_seasons seasonal columns, but found $(size(df, 2)).")
            end
        else
            if size(df, 2) != 1
                println("Warning: Seasonality is disabled but CSV has multiple columns. Using only the first column.")
                df = DataFrame(:Profile => df[:, 1])
            end
        end

        return df
    catch e
        error("Error loading CSV file: $(e.msg)")
    end
end


end # module Utils