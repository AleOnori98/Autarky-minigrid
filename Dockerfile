# --- 1. Use official Julia image ---
FROM julia:1.10

# --- 2. Set working directory ---
WORKDIR /app

# --- 3. Copy backend code only ---
COPY backend backend
COPY backend/Project.toml backend/Manifest.toml /app/

# --- 4. Install Julia dependencies ---
RUN julia -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# --- 5. Expose the port your server uses ---
EXPOSE 8000

# --- 6. Start the server (adjust if needed) ---
CMD ["julia", "backend/server.jl"]
