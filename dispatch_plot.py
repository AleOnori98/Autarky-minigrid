import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load CSV file
csv_file = "models/Formulation_2/regular_model/results/optimal_dispatch.csv"  
data = pd.read_csv(csv_file)

# Standard colors for technologies
color_dict = {
    "Solar Production": "#FFD700" ,
    "Battery Charge": "#ADD8E6",
    "Battery Discharge": "#ADD8E6",
    "Generator Production": "#00008B",
    "Grid Import": "#800080",
    "Grid Export": "#800080",
    "Curtailment": "#FFA500",
    "Load": "#000000",
}

# Plot Dispatch
def create_dispatch_plot(data, day, uncertainty=False):
    """
    Creates a dispatch plot for a given day.
    
    Parameters:
    data (pd.DataFrame): DataFrame containing the energy balance data.
    day (int): Day to plot (0-indexed).
    """
    # Filter data for the selected day
    hours_per_day = 24
    start_idx = day * hours_per_day
    end_idx = start_idx + hours_per_day
    daily_data = data.iloc[start_idx:end_idx]

    # Initialize the plot
    fig, ax = plt.subplots(figsize=(12, 8))

    x = range(hours_per_day)
    cumulative_outflow = np.zeros(hours_per_day)
    cumulative_inflow = np.zeros(hours_per_day)

    # Plot Solar Production
    ax.fill_between(x, cumulative_outflow, cumulative_outflow + daily_data["Solar Production (kWh)"],
                    label="Solar Production", color=color_dict["Solar Production"], alpha=0.5)
    cumulative_outflow += daily_data["Solar Production (kWh)"]


    # Plot Battery Charge
    ax.fill_between(x, -cumulative_inflow, -(cumulative_inflow + daily_data["Battery Charge (kWh)"]),
                    label="Battery Charging", color=color_dict["Battery Charge"], alpha=0.5)
    cumulative_inflow += daily_data["Battery Charge (kWh)"]

    # Plot Battery Discharge
    ax.fill_between(x, cumulative_outflow, cumulative_outflow + daily_data["Battery Discharge (kWh)"],
                    label="Battery Discharging", color=color_dict["Battery Discharge"], alpha=0.5)
    cumulative_outflow += daily_data["Battery Discharge (kWh)"]

    # Plot Generator Production
    ax.fill_between(x, cumulative_outflow, cumulative_outflow + daily_data["Generator Production (kWh)"],
                    label="Generator Production", color=color_dict["Generator Production"], alpha=0.5)
    cumulative_outflow += daily_data["Generator Production (kWh)"]

    # Plot Grid Import
    ax.fill_between(x, cumulative_outflow, cumulative_outflow + daily_data["Grid Import (kWh)"],
                    label="Grid Import", color=color_dict["Grid Import"], alpha=0.5)
    cumulative_outflow += daily_data["Grid Import (kWh)"]

    # Plot Grid Export
    ax.fill_between(x, -cumulative_inflow, -(cumulative_inflow + daily_data["Grid Export (kWh)"]),
                    label="Grid Export", color=color_dict["Grid Export"], alpha=0.5)
    cumulative_inflow += daily_data["Grid Export (kWh)"]

    if uncertainty:
        # Plot Battery Reserve
        ax.fill_between(x, cumulative_outflow, cumulative_outflow + daily_data["Battery Reserve (kWh)"],
                        label="Battery Reserve", color=color_dict["Battery Charge"], alpha=0.5, hatch="///")
        cumulative_outflow += daily_data["Battery Reserve (kWh)"]

        # Plot Generator Reserve
        ax.fill_between(x, cumulative_outflow, cumulative_outflow + daily_data["Generator Reserve (kWh)"],
                        label="Generator Reserve", color=color_dict["Generator Production"], alpha=0.5, hatch="///")
        cumulative_outflow += daily_data["Generator Reserve (kWh)"]


    # Plot Load
    ax.plot(x, daily_data["Load (kWh)"], label="Load", color=color_dict["Load"], linewidth=2)

    # Plot maximum solar production
    ax.plot(x, daily_data["Solar Production (kWh)"] + daily_data["Curtailment (kWh)"], label="Max Solar Production", color="orange", linewidth=2, linestyle="--")

    # Add labels, title, legend, and grid
    ax.set_xlabel("Hour")
    ax.set_ylabel("Energy (kWh)")
    ax.set_title(f"Dispatch Plot - Day {day + 1}")
    ax.legend(loc="center left", bbox_to_anchor=(1, 0.5))
    ax.grid(True)

    # Adjust legend inside the plot (upper left)
    ax.legend(loc="upper left", bbox_to_anchor=(0.01, 0.99), frameon=True, fontsize=10)
    plt.tight_layout()

    # Save the plot
    plt.savefig("models/Formulation_2/regular_model/results/dispatch_plot.png")
    print("Dispatch plot saved as dispatch_plot.png in models/Formulation_1/regular_model/results folder")


# Example usage: Plot the dispatch for the first day
create_dispatch_plot(data, day=0, uncertainty=False)
