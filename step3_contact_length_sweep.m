%% Graphene–Metal Interface Monte Carlo
%  Geometry Sweep: Lc only
%  Width, T_edge, T_surface are FIXED
%  Author: AGI Assistant (for Junsu Park)

clear; clc; close all;

%% 1. Hardware & scale (UNCHANGED)
try
    d = gpuDevice;
    fprintf('GPU detected: %s (%.1f GB)\n', d.Name, d.TotalMemory/1e9);
    reset(d);
    USE_GPU = true;
    N_PARTICLES = 1e8;
catch
    fprintf('GPU not detected → CPU fallback\n');
    USE_GPU = false;
    N_PARTICLES = 1e5;
end

%% 2. Fixed parameters (FROM ORIGINAL CODE)
FIXED_WIDTH_UM = 20;          % Width fixed
EDGE_DEPTH_UM = 0.05;         % 50 nm
PROB_EDGE = 0.90;             % T_edge (fixed)
PROB_SURFACE = 0.001;         % T_surface (fixed)

DIFFUSION_COEF = 0.5;
DRIFT_VELOCITY = 0.2;
MAX_STEPS = 5000;

%% 3. Lc sweep (ONLY variable)
Lc_list = [20, 50, 100, 200, 500];

results = struct();

%% 4. Sweep loop
for k = 1:length(Lc_list)

    L_um = Lc_list(k);
    W_um = FIXED_WIDTH_UM;

    fprintf('\n--- Running Lc = %d µm ---\n', L_um);

    % Geometry
    grid_x_max = W_um * 1.5;
    pad_x_start = (grid_x_max - W_um)/2;
    pad_x_end   = pad_x_start + W_um;

    % Initialize particles
    if USE_GPU
        px = pad_x_start + rand(N_PARTICLES,1,'gpuArray') * W_um;
        py = -0.5 + rand(N_PARTICLES,1,'gpuArray') * 0.5;
        active = true(N_PARTICLES,1,'gpuArray');
        status = zeros(N_PARTICLES,1,'gpuArray');
    else
        px = pad_x_start + rand(N_PARTICLES,1) * W_um;
        py = -0.5 + rand(N_PARTICLES,1) * 0.5;
        active = true(N_PARTICLES,1);
        status = zeros(N_PARTICLES,1);
    end

    %% Physics loop
    for t = 1:MAX_STEPS

        if USE_GPU
            dx = randn(N_PARTICLES,1,'gpuArray') * sqrt(DIFFUSION_COEF);
            dy = randn(N_PARTICLES,1,'gpuArray') * sqrt(DIFFUSION_COEF) ...
               + DRIFT_VELOCITY;
            r  = rand(N_PARTICLES,1,'gpuArray');
        else
            dx = randn(N_PARTICLES,1) * sqrt(DIFFUSION_COEF);
            dy = randn(N_PARTICLES,1) * sqrt(DIFFUSION_COEF) ...
               + DRIFT_VELOCITY;
            r  = rand(N_PARTICLES,1);
        end

        px = px + dx .* active;
        py = py + dy .* active;

        % Width reflection (UNCHANGED)
        px(px < pad_x_start) = pad_x_start ...
            + abs(px(px < pad_x_start) - pad_x_start);
        px(px > pad_x_end) = pad_x_end ...
            - abs(px(px > pad_x_end) - pad_x_end);

        % Contact region
        in_contact = active & (py >= 0) & (py <= L_um);

        if USE_GPU
            if gather(any(in_contact))
                is_edge = in_contact & (py <= EDGE_DEPTH_UM);
                is_surf = in_contact & ~is_edge;
            else
                continue;
            end
        else
            if any(in_contact)
                is_edge = in_contact & (py <= EDGE_DEPTH_UM);
                is_surf = in_contact & ~is_edge;
            else
                continue;
            end
        end

        % Transfer
        transfer_edge = is_edge & (r < PROB_EDGE);
        transfer_surf = is_surf & (r < PROB_SURFACE);
        new_tr = transfer_edge | transfer_surf;

        status(transfer_edge) = 1;
        status(transfer_surf) = 2;
        active(new_tr) = false;

        % Stop if almost all transferred
        if USE_GPU
            if gather(sum(active)) < N_PARTICLES * 0.01
                break;
            end
        else
            if sum(active) < N_PARTICLES * 0.01
                break;
            end
        end
    end

    %% Collect statistics
    if USE_GPU
        n_edge = double(gather(sum(status==1)));
        n_surf = double(gather(sum(status==2)));
    else
        n_edge = sum(status==1);
        n_surf = sum(status==2);
    end

    results(k).Lc = L_um;
    results(k).edge = n_edge;
    results(k).surface = n_surf;
    results(k).fraction = n_surf / (n_edge + n_surf);

    fprintf('Edge = %s | Surface = %s | Surface fraction = %.2f %%\n', ...
        num2str(n_edge,'%,d'), num2str(n_surf,'%,d'), ...
        100*results(k).fraction);
end

%% 5. Plot: Surface fraction vs Lc
Lc_vals = [results.Lc];
surf_frac = [results.fraction] * 100;

figure('Color','w','Position',[200 200 700 500]);
plot(Lc_vals, surf_frac,'-o','LineWidth',2,'MarkerSize',8);
xlabel('Contact Length L_c (\mum)');
ylabel('Surface Contribution (%)');
title('Surface Contribution vs Contact Length (Fixed Width & Probabilities)');
grid on;
