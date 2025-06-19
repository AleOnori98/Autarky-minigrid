FROM julia:1.10

WORKDIR /app/backend

# Copy and instantiate environment with correct activation
COPY backend/Project.toml backend/Manifest.toml ./
RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate();"

# Copy full backend code
COPY backend/ .

# Develop local HSL_jll package and precompile
RUN julia -e "using Pkg; Pkg.develop(path=\"./HSL_jll\"); Pkg.precompile()"

# Launch backend
CMD ["julia", "--project=.", "server.jl"]
