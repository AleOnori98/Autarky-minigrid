module Utils_Uncertainty

# Import necessary packages
using LinearAlgebra, Statistics, Distributions, HypothesisTests, DataFrames

"""
Performs a normality test (Shapiro-Wilk) on the columns of a given matrix.
"""
function test_normality(errors::DataFrame, label::String)
    errors = Matrix(errors)
    p_values = []
    for col in eachcol(errors)
        test = ShapiroWilkTest(col)
        push!(p_values, pvalue(test))
    end

    # Log warnings if normality is not satisfied
    if any(p -> p < 0.05, p_values)
        println("\nWarning: Some $(label) error distributions are not normal. Proceeding under normality assumption.")
    else
        println("All $(label) error distributions passed the Shapiro-Wilk normality test.")
    end

end

"""
Checks if a covariance matrix is positive semi-definite (PSD) and regularizes it if necessary.
# Positional Arguments:
- `covariance_matrix::Matrix{Float64}`: The covariance matrix to check.

# Keyword Arguments:
- `epsilon::Float64 = 1e-6`: Small value to add to the diagonal for regularization.

# Returns:
- `covariance_matrix::Matrix{Float64}`: A positive semi-definite covariance matrix.
"""
function ensure_positive_semidefinite(covariance_matrix::Matrix{Float64}, label::String; epsilon::Float64 = 1e-6)
    eigenvalues = eigvals(covariance_matrix)
    if all(eigenvalues .>= 0)
        println("\n$(label) covariance matrix is positive semi-definite.")
    elseif -minimum(eigenvalues) < epsilon
        println("\n$(label) covariance matrix is not positive semi-definite but the minimum negative eigenvalue ($(minimum(eigenvalues))) is less than the defined epsilon ($(epsilon)). Regularizing...")
        covariance_matrix += epsilon * I(size(covariance_matrix, 1))
        eigenvalues = eigvals(covariance_matrix)
        
        if all(eigenvalues .>= 0)
            println("\n$(label) covariance matrix is now positive semi-definite after regularization.")
        else
            error("$(label) covariance matrix could not be regularized to positive semi-definiteness.")
        end
    else
        error("\n$(label) covariance matrix is not positive semi-definite and the minimum negative eigenvalue ($(minimum(eigenvalues))) is greater than the defined epsilon ($(epsilon)).")
    end

    return covariance_matrix
end

end