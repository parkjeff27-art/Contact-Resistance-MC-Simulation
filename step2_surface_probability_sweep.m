%% Graphene-Metal Interface: STEP2 Sweep (REALTIME) - Fixed Width Geometry
%  Target: Threadripper PRO & RTX 5090 (runs on CPU if GPU not found)
%  Scale: 100,000,000 particles (GPU) / reduced on CPU
%  Constraint: Contact Width FIXED at 20 um
%  Comparison: TLCD (20x20 um) vs TECD (20x500 um)
%  STEP2 Sweep: P_edge fixed = 0.6, P_surface = [0.015 0.01 0.005 0.001]
%  Realtime Monitoring: Sample carrier diffusion + Log Heatmap + Edge/Surface counts
%
%  Paste-and-run single script.

clear; clc; close all;

%% ===================== 1) Hardware & scale =====================
try
    d = gpuDevice;
    fprintf('🚀 GPU Detected: %s (VRAM: %.1f GB)\n', d.Name, d.TotalMemory/1e9);
    reset(d);
    USE_GPU = true;
    N_PARTICLES = 100000000; % 1e8
catch
    fprintf('⚠️ GPU not found. Falling back to CPU.\n');
    USE_GPU = false;
    N_PARTICLES = 200000;    % CPU debug scale (adjust if needed)
end

%% ===================== 2) Geometry configs (FIXED WIDTH) =====================
FIXED_WIDTH_UM = 20;

% 2-column cell array: CONFIGS{k,1} (name), CONFIGS{k,2} (L_um)
CONFIGS = {
    'Case 1: TLCD (20x20 um)', 20
    'Case 2: TECD (20x500 um)', 500
};

%% ===================== 3) Physics params =====================
EDGE_DEPTH_UM  = 0.05;      % 50 nm (edge strip depth)

P_EDGE_FIXED   = 0.60;                 % fixed for STEP2
P_SURF_LIST    = [0.015 0.01 0.005 0.001];  % sweep for STEP2

DIFFUSION_COEF = 0.5;
DRIFT_VELOCITY = 0.2;
MAX_STEPS      = 5000;

UPDATE_EVERY   = 50;        % realtime refresh cadence

%% ===================== 4) Main Sweep Loop (Realtime per run) =====================
final_stats = struct([]);
run_idx = 0;

for pSurf = P_SURF_LIST

    for k = 1:size(CONFIGS,1)
        run_idx = run_idx + 1;

        name = CONFIGS{k,1};
        L_um = CONFIGS{k,2};
        W_um = FIXED_WIDTH_UM;

        fprintf('\n=================================================\n');
        fprintf('▶ STEP2 REALTIME RUN %d/%d\n', run_idx, numel(P_SURF_LIST)*size(CONFIGS,1));
        fprintf('   %s\n', name);
        fprintf('   Geometry: W=%d um (Fixed) x L=%d um\n', W_um, L_um);
        fprintf('   P_edge=%.3f (fixed) | P_surface=%.4f\n', P_EDGE_FIXED, pSurf);

        %% ---- Geometry placement ----
        grid_x_max  = W_um * 1.5;
        pad_x_start = (grid_x_max - W_um)/2;
        pad_x_end   = pad_x_start + W_um;

        %% ---- Particle initialization ----
        if USE_GPU
            px = pad_x_start + rand(N_PARTICLES, 1, 'gpuArray') * W_um;
            py = -0.5 + rand(N_PARTICLES, 1, 'gpuArray') * 0.5;

            active = true(N_PARTICLES, 1, 'gpuArray');
            status = zeros(N_PARTICLES, 1, 'gpuArray');
        else
            px = pad_x_start + rand(N_PARTICLES, 1) * W_um;
            py = -0.5 + rand(N_PARTICLES, 1) * 0.5;

            active = true(N_PARTICLES, 1);
            status = zeros(N_PARTICLES, 1);
        end

        %% ---- Realtime Figure (3 panels) ----
        f = figure('Name', sprintf('%s | Psurf=%.4f', name, pSurf), ...
            'Color', 'w', 'Position', [80, 80, 1250, 720]);

        % Panel 1: sample particle diffusion
        ax1 = subplot(1,3,1); hold on; box on;
        title(ax1, 'Carrier Diffusion (Sample)');
        xlabel(ax1, 'Width (\mum)'); ylabel(ax1, 'Length (\mum)');
        axis(ax1, [0 grid_x_max -1 L_um]);

        if L_um > 100
            daspect(ax1, [1 10 1]);
        else
            axis(ax1, 'equal');
        end

        rectangle(ax1, 'Position', [pad_x_start, 0, W_um, L_um], ...
            'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle', '--');
        rectangle(ax1, 'Position', [pad_x_start, 0, W_um, EDGE_DEPTH_UM], ...
            'FaceColor', 'y', 'EdgeColor', 'none', 'FaceAlpha', 0.5);

        vis_idx = 1:ceil(N_PARTICLES/20000):N_PARTICLES;
        if USE_GPU
            h_parts = scatter(ax1, gather(px(vis_idx)), gather(py(vis_idx)), 1, 'b', ...
                'filled', 'MarkerFaceAlpha', 0.1);
        else
            h_parts = scatter(ax1, px(vis_idx), py(vis_idx), 1, 'b', ...
    'filled', 'MarkerFaceAlpha', 0.1);

        end

        % Panel 2: log heatmap (ONLINE accumulation)
        ax2 = subplot(1,3,2); box on;
        title(ax2, 'Transfer Density (Log Scale)');
        xlabel(ax2, 'Width (\mum)'); ylabel(ax2, 'Length (\mum)');

        x_edges = linspace(pad_x_start, pad_x_end, 21);
        y_edges = linspace(0, L_um, 101);
        H = zeros(length(y_edges)-1, length(x_edges)-1, 'double');

        h_img = imagesc(ax2, x_edges(1:end-1), y_edges(1:end-1), log10(H+1));
        set(ax2, 'YDir', 'normal');
        colormap(ax2, hot);
        colorbar(ax2);

        axis(ax2, [pad_x_start pad_x_end 0 L_um]);
        if L_um > 100
            daspect(ax2, [1 10 1]);
        else
            axis(ax2, 'equal');
        end

        % Panel 3: counts
        ax3 = subplot(1,3,3); box on;
        h_bar = bar(ax3, [0 0], 'FaceColor', 'flat');
        h_bar.CData = [1 0.3 0.3; 0.3 0.3 1];
        grid(ax3, 'on');
        set(ax3, 'XTickLabel', {'Edge', 'Surface'});
        ylabel(ax3, 'Count');
        title(ax3, sprintf('Pedge=%.2f | Psurf=%.4f', P_EDGE_FIXED, pSurf));
        ax3.YAxis.Exponent = 0; ytickformat(ax3, '%,d');

        drawnow;

        %% ===================== Physics Loop =====================
        start_time = tic;

        for t = 1:MAX_STEPS

            if USE_GPU
                dx = randn(N_PARTICLES, 1, 'gpuArray') * sqrt(DIFFUSION_COEF);
                dy = randn(N_PARTICLES, 1, 'gpuArray') * sqrt(DIFFUSION_COEF) + DRIFT_VELOCITY;
                r  = rand(N_PARTICLES, 1, 'gpuArray');
            else
                dx = randn(N_PARTICLES, 1) * sqrt(DIFFUSION_COEF);
                dy = randn(N_PARTICLES, 1) * sqrt(DIFFUSION_COEF) + DRIFT_VELOCITY;
                r  = rand(N_PARTICLES, 1);
            end

            px = px + dx .* active;
            py = py + dy .* active;

            % reflect width boundaries
            px(px < pad_x_start) = pad_x_start + abs(pad_x_start - px(px < pad_x_start));
            px(px > pad_x_end)   = pad_x_end   - abs(px(px > pad_x_end) - pad_x_end);

            in_contact = active & (py >= 0) & (py <= L_um);

            if USE_GPU
                any_in = gather(any(in_contact));
            else
                any_in = any(in_contact);
            end

            if any_in
                is_edge = in_contact & (py <= EDGE_DEPTH_UM);
                is_surf = in_contact & ~is_edge;

                trans_edge = is_edge & (r < P_EDGE_FIXED);
                trans_surf = is_surf & (r < pSurf);

                status(trans_edge) = 1;
                status(trans_surf) = 2;

                new_trans = trans_edge | trans_surf;
                active(new_trans) = false;

                if USE_GPU
                    has_new = gather(any(new_trans));
                else
                    has_new = any(new_trans);
                end

                if has_new
                    if USE_GPU
                        tx = gather(px(new_trans));
                        ty = gather(py(new_trans));
                    else
                        tx = px(new_trans);
                        ty = py(new_trans);
                    end

                    bx = discretize(tx, x_edges);
                    by = discretize(ty, y_edges);
                    valid = ~isnan(bx) & ~isnan(by);
                    bx = bx(valid); by = by(valid);

                    if ~isempty(bx)
                        lin = sub2ind(size(H), by, bx);
                        add = accumarray(lin, 1, [numel(H), 1]);
                        H(:) = H(:) + add;
                    end
                end
            end

            if mod(t, UPDATE_EVERY) == 0
                if USE_GPU
                    h_parts.XData = gather(px(vis_idx));
                    h_parts.YData = gather(py(vis_idx));
                    cnt_edge = gather(sum(status==1));
                    cnt_surf = gather(sum(status==2));
                else
                    h_parts.XData = px(vis_idx);
                    h_parts.YData = py(vis_idx);
                    cnt_edge = sum(status==1);
                    cnt_surf = sum(status==2);
                end

                h_bar.YData = double([cnt_edge, cnt_surf]);
                title(ax3, sprintf('Edge: %s | Surf: %s', ...
                    num2str(cnt_edge,'%,d'), num2str(cnt_surf,'%,d')));

                cur_max = max([cnt_edge, cnt_surf]);
                if cur_max > ax3.YLim(2)*0.8
                    ylim(ax3, [0 cur_max*1.2]);
                end

                h_img.CData = log10(H + 1);
                caxis(ax2, [0 max(h_img.CData(:))]);

                drawnow limitrate;
            end

            if USE_GPU
                if gather(sum(active)) < N_PARTICLES * 0.01, break; end
            else
                if sum(active) < N_PARTICLES * 0.01, break; end
            end
        end

        elapsed = toc(start_time);
        fprintf('⏱ Done in %.2f sec (steps=%d).\n', elapsed, t);

        if USE_GPU
            edge_cnt = double(gather(sum(status==1)));
            surf_cnt = double(gather(sum(status==2)));
        else
            edge_cnt = double(sum(status==1));
            surf_cnt = double(sum(status==2));
        end

        final_stats(run_idx).name = sprintf('%s | Psurf=%.4f', name, pSurf);
        final_stats(run_idx).case = name;
        final_stats(run_idx).P_edge = P_EDGE_FIXED;
        final_stats(run_idx).P_surf = pSurf;
        final_stats(run_idx).edge = edge_cnt;
        final_stats(run_idx).surf = surf_cnt;
        final_stats(run_idx).elapsed = elapsed;
    end
end

%% ===================== 5) Final Comparison across all runs =====================
figure('Name', 'STEP2 Final Comparison (Fixed Width)', 'Color', 'w', 'Position', [200, 200, 1300, 520]);

names  = {final_stats.name};
edges  = [final_stats.edge]';
surfs  = [final_stats.surf]';
ratios = surfs ./ max(1, (edges + surfs)) * 100;

subplot(1,2,1);
b = bar(categorical(names), [edges surfs]);
b(1).FaceColor = [1 0.3 0.3];
b(2).FaceColor = [0.3 0.3 1];
ylabel('Total Transfer Count');
legend('Edge', 'Surface');
title('Absolute Counts');
ax = gca; ax.YAxis.Exponent = 0; ytickformat('%,d'); grid on;

subplot(1,2,2);
b2 = bar(categorical(names), ratios);
b2.FaceColor = [0.5 0.8 0.5];
ylabel('Surface Contribution (%)');
title(sprintf('Surface Ratio (Pedge=%.2f fixed)', P_EDGE_FIXED));
ylim([0 100]); grid on;

fprintf('\n=== STEP2 FINAL VERIFICATION ===\n');
for i = 1:numel(final_stats)
    fprintf('[%s]\n', final_stats(i).name);
    fprintf('  - Edge:   %s\n', num2str(final_stats(i).edge, '%,d'));
    fprintf('  - Surface:%s\n', num2str(final_stats(i).surf, '%,d'));
    fprintf('  - Time(s):%.2f\n', final_stats(i).elapsed);
end
