# Use the official Julia image
FROM julia:1.10

# Set environment variables
ENV JULIA_DEPOT_PATH=/root/.julia \
    JULIA_PROJECT=.

# Set working directory
WORKDIR /backend

# Copy project files
COPY . .

# Precompile dependencies (this will run `Pkg.instantiate` and `precompile`)
RUN julia -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# Expose the port Render will use
EXPOSE 8000

# Run your HTTP server (adjust the file if needed)
CMD ["julia", "server.jl"]
