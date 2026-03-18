# Contact-Resistance-MC-Simulation

> **Published Paper**: [Contact Area Effect on Graphene–Metal Contact Resistance](https://link.springer.com/article/10.1007/s40042-026-01579-8) — *Journal of the Korean Physical Society* (2026)

Monte Carlo simulation of carrier transport at the graphene–metal interface, designed to complement and validate experimental findings on how contact area affects contact resistance. Supports **GPU acceleration** (NVIDIA RTX 5090 / CUDA) with automatic CPU fallback.

---

## Research Context

### The Problem
Previous studies on graphene–metal contact resistance have predominantly assumed that **edge current crowding** is the sole dominant mechanism governing contact resistance. However, the role of the **contact area** (i.e., distributed surface injection across the metal–graphene interface) has not been systematically verified.

### Experimental Approach
Two novel device structures were designed to isolate the area effect:

| Structure | Geometry | Description |
|-----------|----------|-------------|
| **TLCD** (Top-Lead Contact Device) | 20 × 20 µm | Edge-dominant injection configuration (conventional) |
| **TECD** (Top-Electrode Contact Device) | 20 × 500 µm | Expanded contact area with identical channel width |

Both structures maintain **identical channel width (20 µm)**, so the only independent variable is the **contact length (Lc)** — enabling direct isolation of area-dependent effects from edge contributions.

### Key Experimental Finding
A **~625× enlargement** of the graphene–metal interface (20×20 → 500×500 µm²) results in a **~3.9× reduction in contact resistance (2Rc)**, demonstrating that distributed interfacial charge transfer (ρc) plays a dominant role beyond edge current crowding.

---

## Simulation Overview

This Monte Carlo simulation models the carrier transport process using a **drift–diffusion framework** with stochastic transfer events to reproduce and validate the experimental observations.

### Physics Model
- **1×10⁸ particles** (GPU) or reduced scale (CPU fallback)
- **Drift–Diffusion transport**: thermal random walk (diffusion) + voltage-bias-driven drift (+y direction)
- **Edge region** (y = 0 – 0.05 µm, 50 nm): transfer probability = `P_edge`
- **Surface region** (y > 0.05 µm): transfer probability = `P_surface`
- **Contact width fixed** at 20 µm across all simulations
- **Boundary conditions**: reflective walls at width boundaries
- **Termination**: simulation stops when <1% of particles remain active (or `MAX_STEPS = 5000`)

### Key Insight
> Even when surface transfer probability (P_surface) is orders of magnitude lower than edge transfer probability (P_edge), the **residence time** and **retry accumulation** in the expanded TECD surface region leads to a dramatic increase in total surface transfers — providing direct evidence for **distributed surface injection** as the fundamental mechanism behind contact resistance reduction.

---

## Simulation Codes

| File | Sweep Variable | Fixed Parameters | Purpose |
|------|---------------|------------------|---------|
| `step1_edge_probability_sweep.m` | P_edge = [0.6, 0.7, 0.8, 0.9] | P_surface = 0.015 | Verify that area effect is **robust** regardless of edge transfer probability |
| `step2_surface_probability_sweep.m` | P_surface = [0.015, 0.01, 0.005, 0.001] | P_edge = 0.6 | Demonstrate **distributed injection** via residence time accumulation |
| `step3_contact_length_sweep.m` | Lc = [20, 50, 100, 200, 500] µm | P_edge = 0.9, P_surface = 0.001 | Quantify **surface contribution vs. contact length** |

### Realtime Visualization
Each script provides a 3-panel realtime display:
1. **Carrier Diffusion Map** — sample particle positions updated live
2. **Transfer Density Heatmap** — log-scale spatial distribution of transferred carriers
3. **Edge vs. Surface Count** — running bar chart of transfer statistics

---

## Results Summary

### Step 1: Edge Probability Sensitivity
- Edge transfers remain nearly identical between TLCD and TECD
- TECD surface transfers are always dominant, regardless of P_edge value
- **Conclusion**: Area effect does not disappear even with high edge probability → robustness confirmed

### Step 2: Surface Probability Sensitivity
- Reducing P_surface paradoxically **increases** total surface transfers in TECD
- Mechanism: lower probability → longer particle survival → more retry attempts → higher cumulative transfer
- **Conclusion**: Distributed surface injection is governed by residence time, not single-event probability

### Step 3: Contact Length Dependence
- Surface contribution (%) increases monotonically with contact length Lc
- Sub-linear saturation behavior consistent with the distributed contact resistance model
- Matches experimental observation of ~3.9× Rc reduction for ~625× area increase

---

## Theoretical Framework

The simulation is grounded in two competing models of graphene–metal contact resistance:

| Model | Transport Mechanism | Prediction |
|-------|---------------------|------------|
| **Landauer Model** | Ballistic edge injection through discrete quantum channels | Rc depends only on edge length, insensitive to contact area |
| **BTH Model** | Distributed tunneling mediated by wavefunction overlap across the interface | Rc decreases with increasing contact area |

Our experimental and simulation results support the conclusion that **both models are essential** — contact resistance is governed by the coexistence of edge and area contributions, with the BTH mechanism becoming increasingly dominant as contact area expands.

---

## Requirements

- **MATLAB** (R2020b or later recommended)
- **Parallel Computing Toolbox** (for GPU acceleration)
- **NVIDIA GPU** with CUDA support
  - Tested on: RTX 5090 (32 GB VRAM, Compute Capability 12.0)
  - Forward compatibility: `parallel.gpu.enableCUDAForwardCompatibility(true)`
- Falls back to CPU automatically if GPU is not detected (reduced particle count: 2×10⁵)


## Citation

If you use this code in your research, please cite:Park, J., Lee, J.S. (2026). Contact Area Effect on Graphene–Metal Contact Resistance.
Journal of the Korean Physical Society.
https://doi.org/10.1007/s40042-026-01579-8


---

---

## Author

**Junsu Park (박준수)**
Department of Physics and Photon Science, GIST (Gwangju Institute of Science and Technology)

- GitHub: [@parkjeff27-art](https://github.com/parkjeff27-art)
- Related Repository: [graphene-contact-LLM](https://github.com/parkjeff27-art/graphene-contact-LLM) — Fine-tuning a 7B LLM as a condensed matter physics expert


## Citation

If you use this code in your research, please cite:
