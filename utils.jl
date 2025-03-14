module Utils

using JuMP, CSV, DataFrames, YAML, Statistics, XLSX


"""
Load time series data from a CSV file.

# Arguments
- `csv_file_path::String`: The path to the CSV file.

# Keyword Arguments
- `delimiter::Char`: The delimiter used in the CSV file (default is `';'`).
- `decimal::Char`: The decimal separator used in the CSV file (default is `','`).

# Returns
- `DataFrame`: A DataFrame containing the data from the CSV file.

# Errors
- Throws an error if the file does not exist or if the CSV content cannot be parsed.
"""
function import_time_series(csv_file_path::String; delimiter::Char=';', decimal::Char=',')::DataFrame
    if !isfile(csv_file_path)
        error("The CSV file at path '$csv_file_path' does not exist.")
    end

    try
        data = CSV.read(csv_file_path, DataFrame; delim=delimiter, decimal=decimal)
        return data
    catch e
        error("Error loading CSV file: $(e.msg)")
    end
end

"""
Checks the number of rows in a time series vector.

# Arguments
- `time_series::Vector{Float64}`: The input time series data as a vector.
- `expected_rows::Int`: The expected number of rows (e.g., `T`).
- `label::String`: A label for the time series (for error messages).

# Returns
- `Vector{Float64}`: The validated (and possibly truncated) time series.

# Throws
- An error if the number of rows is less than `expected_rows`.
"""
function validate_time_series(time_series::Vector, expected_rows::Int, label::String)
    actual_rows = length(time_series)

    if actual_rows > expected_rows
        println("Warning: $label exceeds the expected number of rows ($actual_rows > $expected_rows). Truncating to match the expected rows.")
        return time_series[1:expected_rows]
    elseif actual_rows < expected_rows
        error("Error: $label has fewer rows ($actual_rows < $expected_rows) than expected. Please check your data.")
    else
        return time_series
    end
end

"""
Checks the number of rows in a errors dataframe.

# Arguments
- `errors::DataFrame`: The input errors data as a DataFrame.
- `expected_rows::Int`: The expected number of rows (e.g., `T`).
- `expected_columns::Int`: The expected number of columns (e.g., `n_simulations`).
- `label::String`: A label for the errors (for error messages).

# Returns
- `DataFrame`: The validated (and possibly truncated) errors data.

# Throws
- An error if the number of rows is less than `expected_rows`.
- An error if the number of columns is less than `expected_columns`.
"""
function validate_errors(errors::DataFrame, expected_rows::Int, expected_columns::Int, label::String)
    actual_rows = nrow(errors)
    actual_columns = ncol(errors)

    # Validate the number of rows in the errors data
    if actual_rows > expected_rows
        println("Warning: $label exceeds the expected number of rows ($actual_rows > $expected_rows). Truncating to match the expected rows.")
        errors = errors[1:expected_rows, :]
    elseif actual_rows < expected_rows
        error("Error: $label has fewer rows ($actual_rows < $expected_rows) than expected. Please check your data.")
    end

    # Validate the number of columns in the errors data
    if actual_columns > expected_columns
        println("Warning: $label exceeds the expected number of columns ($actual_columns > $expected_columns). Truncating to match the expected columns.")
        errors = errors[:, 1:expected_columns]
    elseif actual_columns < expected_columns
        error("Error: $label has fewer columns ($actual_columns < $expected_columns) than expected. Please check your data.")
    end

    # Return the validated errors data
    return errors
end

"""
Load and validate time series data from a CSV file.

# Positional Arguments
- `file_path::String`: Path to the CSV file containing time series data.
- `params::Dict`: A dictionary containing project settings, including the expected time horizon.
- `label::String`: A descriptive label for the data being loaded (e.g., "Load Data").
# Keyword Arguments
- `uncertainty::Bool`: A boolean indicating whether the model apply probabilistic constraints (default is `false`).

# Returns
- `Vector{Float64}`: A vector containing the validated time series data.

# Prints
- Key metrics such as minimum, maximum, and average values of the time series data.

# Errors
- Throws an error if the number of rows in the CSV file does not match the expected time horizon.
"""
function load_and_validate_time_series(file_path::String, params::Dict, label::String; uncertainty::Bool=false)::Vector{Float64}
    println("\nLoading $label...")
    data_df = import_time_series(file_path)
    time_series = data_df[:, 1]
    expected_rows = params["project_settings"]["operation_time_steps"]
    if uncertainty
        expected_rows += params["uncertainty"]["outage_duration"]
    end
    data = validate_time_series(time_series, expected_rows, label)

    println("$label loaded successfully.")
    println("Key Metrics:")
    println("  min = $(round(minimum(data), digits=2)) kW")
    println("  max = $(round(maximum(data), digits=2)) kW")
    println("  avg = $(round(mean(data), digits=2)) kWh")
    return data
end

"""
Load and validate errors data from a CSV file.

# Positional Arguments
- `file_path::String`: Path to the CSV file containing errors data.
- `params::Dict`: A dictionary containing project settings, including the expected time horizon.
- `label::String`: A descriptive label for the data being loaded (e.g., "Load Data").

# Returns
- `DataFrame`: A vector containing the validated time series data.

# Prints
- Key metrics such as minimum, maximum, and average values of the time series data.

# Errors
- Throws an error if the number of rows in the CSV file does not match the expected time horizon.
"""
function load_and_validate_errors(file_path::String, params::Dict, label::String)::DataFrame
    println("\nLoading $label...")
    errors = import_time_series(file_path)

    # Validate the number of rows in the time series data
    expected_rows = expected_rows = params["project_settings"]["operation_time_steps"] + params["uncertainty"]["outage_duration"]
    expected_columns = params["uncertainty"]["n_simulations"]
    data = validate_errors(errors, expected_rows, expected_columns, label)

    column_averages = mean(Matrix(errors), dims=1)[:]
    println("$label loaded successfully.")
    println("Key Metrics (average across all simulations):")
    println("  min = $(round(minimum(column_averages), digits=2)) kW")
    println("  max = $(round(maximum(column_averages), digits=2)) kW")
    println("  avg = $(round(mean(column_averages), digits=2)) kW")

    return data
end

"""
Extract and display grid parameters from a DataFrame.

# Arguments
- `grid_params::DataFrame`: A DataFrame containing grid parameters such as import cost, export price, and maximum grid exchange capacity.
- `params::Dict`: A dictionary containing project settings, including the expected time horizon.
# Keyword Arguments
- `uncertainty::Bool`: A boolean indicating whether the model apply probabilistic constraints (default is `false`).

# Prints
- Average grid import cost, average grid export price, and maximum grid exchange capacity.
"""
function load_and_validate_grid_params(grid_params::DataFrame, params::Dict; uncertainty::Bool=false)
    c_g_plus = grid_params[:, 1]  # Grid import cost [USD/kWh]
    p_g_minus = grid_params[:, 2] # Grid export price [USD/kWh]
    g_max = grid_params[:, 3]     # Maximum grid exchange [kW]
    expected_rows = params["project_settings"]["operation_time_steps"]

    if uncertainty
        expected_rows += params["uncertainty"]["outage_duration"]
    end
    validate_time_series(c_g_plus, expected_rows, "Grid Import Cost")
    validate_time_series(p_g_minus, expected_rows, "Grid Export Price")
    validate_time_series(g_max, expected_rows, "Maximum Grid Exchange")

    # Display grid parameters
    println("\nGrid Parameters:")
    println("  Average Grid Import Cost: $(round(mean(c_g_plus), digits=2)) USD/kWh")
    println("  Average Grid Export Price: $(round(mean(p_g_minus), digits=2)) USD/kWh")
    println("  Max Grid Exchange: $(round(maximum(g_max), digits=2)) kW")

    return c_g_plus, p_g_minus, g_max
end

"""
Write results to an Excel file and return a DataFrame containing the results.

# Arguments
- `file_path::String`: The path to save the Excel file.
- `model::Model`: The JuMP optimization model.
- `load::Vector{Float64}`: The load time series data.
- `solar_unit::Vector{Float64}`: The solar time series data.
- `T::Int`: Time horizon (number of time steps).
- `uncertainty::Bool`: A boolean indicating whether the model apply probabilistic constraints (default is `false`).

# Returns
- A dataframe containing the results.
"""
function write_results_to_csv(
    project_sizing_path::String,
    dispatch_path::String,
    model::Model,
    load::Vector{Float64},
    solar_unit::Vector{Float64},
    T::Int,
    grid_mode::String;
    steps_per_year::Int = 365,
    project_lifetime::Int = 20,
    uncertainty::Bool = false
)
    # 1) EXTRACT SOLUTION VALUES
    # --------------------------

    # System sizing
    solar_capacity   = value(model[:solar_capacity])
    battery_capacity = value(model[:battery_capacity])
    gen_capacity     = value(model[:gen_capacity])

    # Operation variables
    solar_production = value.(model[:solar_production])
    battery_charge   = value.(model[:battery_charge])
    battery_discharge = value.(model[:battery_discharge])
    SOC             = value.(model[:SOC])
    gen_production  = value.(model[:gen_production])
    if grid_mode == "ongrid"
        grid_import     = value.(model[:grid_import])
        grid_export     = value.(model[:grid_export])
    end

    # For uncertain models
    if uncertainty
        # Check if these variables exist in the model
        battery_reserve     = value.(model[:battery_reserve])
        gen_reserve         = value.(model[:gen_reserve])
        expected_shortfall  = value.(model[:expected_shortfall])
    end

    # 3) BUILD DATAFRAMES
    # -------------------

    ## 3.1 Project Sizing & Cost Summary
    sizing_table = DataFrame(
        Parameter = [
            "Solar Capacity (kW)",
            "Battery Capacity (kWh)",
            "Generator Capacity (kW)",
        ],
        Value = [
            solar_capacity,
            battery_capacity,
            gen_capacity,
        ]
    )

    ## 3.2 Dispatch / Energy Balance Detail
    # Calculate solar maximum for each t to see how much was curtailed
    solar_max_production = solar_unit .* solar_capacity
    curtailment = solar_max_production .- solar_production

    energy_balance_table = DataFrame(
        "Time Step"           => 1:T,
        "Load (kWh)"          => load,
        "Solar Production (kWh)"   => solar_production,
        "Curtailment (kWh)"   => curtailment,
        "Battery Charge (kWh)"    => battery_charge,
        "Battery Discharge (kWh)"   => battery_discharge,
        "State of Charge (kWh)"   => SOC,
        "Generator Production (kWh)"   => gen_production)

    if grid_mode == "ongrid"
        energy_balance_table[!,"Grid Import (kWh)"] = grid_import
        energy_balance_table[!,"Grid Export (kWh)"] = grid_export
    end

    if uncertainty
        energy_balance_table[!,"Battery Reserve (kWh)"]    = battery_reserve
        energy_balance_table[!,"Generator Reserve (kWh)"]  = gen_reserve
        energy_balance_table[!,"Expected Shortfall (kWh)"] = expected_shortfall
    end

    # 4) WRITE TO CSV
    # ---------------
    CSV.write(project_sizing_path, sizing_table)
    println("Project sizing results written to $project_sizing_path")

    CSV.write(dispatch_path, energy_balance_table)
    println("Dispatch results written to $dispatch_path")

    return energy_balance_table
end

"""
Write raw results to CSV files.
"""
function write_raw_results_to_csv(model::Model, csv_path::String)
    # Create a DataFrame to store the variable names and values
    variables_df = DataFrame(
        Variable_Name = String[],
        Optimal_Value = Float64[])

    # Iterate through all variables in the model
    for var in all_variables(model)
        var_name = string(var)
        var_value = value(var)

        # Add to scalar variables if not indexed over time
        push!(variables_df, (Variable_Name = var_name,
                             Optimal_Value = var_value))
    end

    # Save variables to a CSV file
    CSV.write(csv_path, variables_df)

end

"""
Load start values from a CSV file.
"""
function get_start_values(variable_name::String, csv_path::String)::Union{Float64, Vector{Float64}}
    # Load the CSV file into a DataFrame
    variables_df = CSV.read(csv_path, DataFrame)

    # Filter the DataFrame for rows matching the variable name
    matches = filter(row -> row.Variable_Name == variable_name, variables_df)

    if nrow(matches) == 0
        println("Warning: Variable '$variable_name' not found in CSV file at $csv_path. Assigning a default value of nothing.")
        return 0
    else
        value = matches.Optimal_Value[1]
        return abs(value) < 1e-5 ? 0.0 : value  # Treat values close to 10^-5 as zero
    end
end


end # module Utils