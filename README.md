# Contact-Resistance-MC-Simulation

Monte Carlo simulation of carrier transport at the graphene-metal interface.
Supports GPU acceleration (RTX 5090 / CUDA) with automatic CPU fallback.

## Research Context

This simulation accompanies experimental work comparing **TLCD** (Top-Lead Contact Device, 20x20 um) and **TECD** (Top-Electrode Contact Device, 20x500 um) structures to investigate whether graphene-metal contact resistance is governed solely by edge current crowding or also by distributed surface injection across the interface area.

## Simulation Codes

| File | Description |
| --- | --- |
| `step1_edge_probability_sweep.m` | P_edge sweep (0.6-0.9), P_surface fixed at 0.015. Verifies area effect robustness. |
| `step2_surface_probability_sweep.m` | P_surface sweep (0.015-0.001), P_edge fixed at 0.6. Demonstrates distributed injection via residence time accumulation. |
| `step3_contact_length_sweep.m` | Contact length Lc sweep (20-500 um) with fixed probabilities. Quantifies surface contribution vs geometry. |

## Physics Model

- **Drift-Diffusion** based stochastic transport (1e8 particles)
- **Edge region**: y = 0 to 0.05 um (50 nm), transfer probability P_edge
- **Surface region**: y > 0.05 um, transfer probability P_surface
- Contact width fixed at 20 um across all simulations
- Realtime visualization: carrier diffusion, log-scale heatmap, edge/surface transfer counts

## Requirements

- MATLAB with Parallel Computing Toolbox (for GPU acceleration)
- NVIDIA GPU with CUDA support (tested on RTX 5090, 32GB VRAM)
- Runs on CPU automatically if GPU is not available

## Author

**Junsu Park** - Department of Physics and Photon Science, GIST
