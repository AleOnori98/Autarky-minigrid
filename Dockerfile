# Use official Julia base image
FROM julia:1.10

# Set working directory
WORKDIR /app/backend

# First copy only dependency files to leverage Docker cache
COPY backend/Project.toml backend/Manifest.toml ./

# Instantiate package environment (this will cache if deps unchanged)
RUN julia -e "using Pkg; Pkg.instantiate();"

# Then copy the full backend (source code and HSL_jll folder)
COPY backend/ .

# Develop the local HSL_jll and precompile everything
RUN julia -e "using Pkg; Pkg.develop(path=\"./HSL_jll.jl\"); Pkg.precompile()"

# Set default command to launch the backend server
CMD ["julia", "server.jl"]
