# Autarky-minigrid
Optimal Sizing and Dispatch for off-grid and weakly-connected mini-grids to support rural electrification. 

Autarky is a software tool designed to optimize community-scale electricity systems, typically mini-grids. It enables users to forecast electricity demand and renewable energy supply at specific GPS locations with an hourly resolution. There are four models available:
1. The regular model, which does not account for uncertainties.
2. The expected model, where all random parameters are replaced by their mean values.
3. The individual/joint chance-constrained models, which consider three/four types of uncertainties for weakly-connected mini-grids:
Stochastic renewable generation.
Demand forecast errors.
Main-grid outages and their onset times.
Outage durations.

Autarky also provides insights into the system’s technical performance, costs, and operational environmental impact.
