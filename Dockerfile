FROM julia:1.10

# 1. Set working dir inside backend explicitly
WORKDIR /app/backend

# 2. Copy only backend-specific files
COPY backend/Project.toml backend/Manifest.toml ./

# 3. Instantiate dependencies
RUN julia -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# 4. Copy full backend code now
COPY backend .

# 5. Expose the port
EXPOSE 8000

# 6. Run the backend server
CMD ["julia", "server.jl"]
