# Autarky: Web-Based Energy System Modeling Platform

**Autarky** is a full-stack open-source platform for **modeling, designing, and optimizing decentralized energy systems** such as mini-grids and swarm-grids. It empowers users—from engineers and researchers to policymakers and electrification agencies—to run advanced energy system optimization models via an intuitive, guided web interface.

---

## Purpose & Vision

Autarky brings advanced optimization methods (including **chance-constrained stochastic optimization**) online, making them accessible to users who may not have a background in mathematical modeling or programming. Instead of relying on proprietary tools, Autarky is:

- **Free and open-source**
- **Backed by robust academic methods**
- **Designed for usability in low-resource settings**

It aims to support the planning of **resilient**, **cost-effective**, and **reliable** electrification projects in regions facing uncertain grid access, variable demand, and renewable intermittency.

---

## Platform Architecture

Autarky is built as a modular full-stack application:

| Layer      | Description |
|------------|-------------|
| **Frontend** | Built with **Next.js**, deployed via **Vercel**. Provides a guided interface for setting up projects, configuring systems, and running simulations. UI designs are created in Canva and Miro. |
| **Backend**  | Built with **Julia** and **JuMP**, exposed via lightweight **HTTP APIs**. Handles data storage, model setup, and optimization execution. Future upgrades will migrate to **Genie.jl** for full web-service support. |
| **Optimization Engine** | Core logic written in Julia using **JuMP**, solving models using **GLPK**, **Ipopt**, etc. Models include deterministic, expected value, ICC, and JCC formulations. |

---

## 🚀 Quick Links

- [Landing Page](https://autarky-energy.net): Overview, access to modeling tools.
- [Modeling App](https://app.autarky-energy.net): Interactive frontend to configure and run models.
- [Backend Repo](https://github.com/tatisgg/Autarky-minigrid/backend): Julia-based core model and API logic.

---


## Backend Optimization Engine

The optimization model is implemented in Julia and supports:

- **Deterministic Model**: Perfect foresight, fast and linear.
- **Expected Value Model**: Penalizes expected forecast errors.
- **Individual Chance Constraints (ICC)**: Guarantees per-hour reliability under uncertainty.
- **Joint Chance Constraints (JCC)**: Ensures reliability over outage windows, using multivariate probability.

The backend handles:
- YAML/CSV file storage
- Model initialization and validation
- Solver execution with log tracking
- Result delivery in CSV format

---

## Streamlit Viewer (Advanced)

In addition to the main web app, Autarky provides a **Streamlit-based desktop viewer** that allows users to:

- Visualize inputs (load, production, costs, constraints)
- Explore sizing, dispatch, cost, and performance results
- Compare two projects side by side

See the [`Autarky Streamlit App`](https://github.com/tatisgg/Autarky-minigrid/tree/main/Autarky%20App) for usage instructions.

---

## 🤝 Contributing

We welcome contributions! Open an issue or start a discussion if you'd like to:
- Extend the frontend with new configuration pages
- Add new components or constraints to the backend model
- Improve the UI/UX flow or deployment setup

---

© 2025 Autarky – Empowering Decentralized Energy Planning
