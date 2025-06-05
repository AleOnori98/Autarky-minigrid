# MiniGrid Optimization Model

## Overview
The **MiniGrid Optimization Model** is a **Linear and Deterministic Optimization model** implemented in **JuMP**. It is designed for the **optimal sizing and operation of hybrid renewable energy systems**, determining the best configuration of **solar PV, wind turbines, batteries, backup generators, and grid interaction** to meet energy demand at the **lowest Net Present Cost (NPC)**.

### **Objective Function: Cost Minimization**
The model aims to **minimize the Net Present Cost (NPC)** of the system over its lifetime by optimizing **capital investment, operational expenses, replacement costs, and salvage value**, while ensuring that **demand is met** and operational constraints are satisfied. The objective function is:

\[
\min \text{NPC} = (\text{CAPEX} - \text{Subsidies}) + \text{Replacement Cost} + \text{OPEX} - \text{Salvage Value}
\]

where:
- **CAPEX (Capital Expenditure):** Initial investment cost for system components.
- **Subsidies:** Government or institutional financial support for renewable energy investments.
- **Replacement Cost:** Discounted cost of replacing batteries, inverters, or other components over the project lifetime.
- **OPEX (Operating Expenses):** Fixed and variable costs of system operation, including maintenance, fuel costs, and grid electricity costs.
- **Salvage Value:** The residual value of assets at the end of the project lifetime, discounted to present value.

### **Techno-Economic Analysis with Discounting**
The model incorporates a **discounted cash flow analysis**, ensuring a realistic economic assessment over the **project lifetime** by considering **the time value of money**.

- The **discount factor** for year \( y \) is given by:

  \[
  DF_y = \frac{1}{(1 + r)^y}
  \]

  where:
  - \( r \) is the **discount rate** (e.g., 10% per year).
  - \( y \) represents the year in the **project lifetime** (e.g., 20 years).

By applying these **discounting techniques**, the model provides a **realistic evaluation of long-term costs and economic feasibility** for hybrid renewable energy systems.

---

## Mathematical Formulation

### **Decision Variables**
- **Sizing Variables**: Number of solar PV units, wind turbines, battery units, and generators.
- **Operational Variables**:
  - Renewable energy generation (solar, wind).
  - Battery charging/discharging and state of charge (SOC).
  - Generator production.
  - Grid import/export.
  - Unmet demand (lost load).

### **Constraints**
- **Energy Balance**:  
  \[
  \text{Load}(t) = \text{Solar}(t) + \text{Wind}(t) + \text{Battery Discharge}(t) + \text{Generator}(t) + \text{Grid Import}(t) - \text{Grid Export}(t) - \text{Lost Load}(t)
  \]
- **Technology-Specific Constraints**:
  - Maximum generation limits.
  - Battery SOC dynamics.
  - Generator fuel consumption and efficiency.
- **Economic Constraints**:
  - Maximum capital expenditure (CAPEX).
  - Minimum renewable energy penetration.
  - Discounted cash flow for lifetime costs.

---

## **Model Inputs & Files**

### **1. Input Data** (Located in `/inputs/` folder)
- **Time-Series Data** (`.csv` files):
  - Solar unit of production (retrievable from PVGIS if enabled).
  - Wind unit of production (retrievable from PVGIS if enabled).
  - Wind Power Curve related to the Wind Turbine selected.
  - Load demand profile.
  - Grid cost for import (optional).
  - Grid prices for export (optional).
- **YAML Parameter File** (`parameters.yaml`):
  - Defines project settings (location, project lifetime, discount rate etc.)
  - Defines project constraints (e.g., max CAPEX, min renewable share).
  - Defines techno-economic parameters of each technology.
  - Specifies solver settings (Gurobi, HiGHS, GLPK, etc.).
  
---

## **Installation & Setup**

### **1. Install Julia**
Download and install **Julia** from [https://julialang.org/downloads/](https://julialang.org/downloads/).

### **2. Set Up the Julia Environment**
Navigate into your project folder and run the following commands in the Julia REPL to install the required packages:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

