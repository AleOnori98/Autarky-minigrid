FROM julia:1.10

# Set working directory
WORKDIR /app/backend

# Show where we are
RUN echo "Current working directory:" && pwd && ls -la

# Copy environment files first for layer caching
COPY backend/Project.toml backend/Manifest.toml ./

# Debug what's inside
RUN echo "Copied Project.toml:" && cat Project.toml
RUN echo "Copied Manifest.toml:" && cat Manifest.toml

# Install packages
RUN julia -e "using Pkg; println(\"Activating env...\"); Pkg.activate(\".\"); println(\"Instantiating...\"); Pkg.instantiate(); println(\"Precompiling...\"); Pkg.precompile()"

# Copy the rest of the source
COPY backend ./

# Show final structure
RUN echo "Final contents of /app/backend:" && ls -la

# Run the server
CMD ["julia", "server.jl"]
