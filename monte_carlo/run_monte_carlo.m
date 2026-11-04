%% Monte Carlo dogrulama: V-agzi kalite kontrol robotu
% Rastgele kusur (0-5 adet) uretir, olcum zincirinden gecirir, tespit ve
% dogruluk metriklerini cikarir. Ayrintilar: docs/MONTE_CARLO_NOTLAR.md
% Calistirma:  >> cd monte_carlo; run_monte_carlo
clear; clc; close all;

P = mc_params();
outDir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% 1) Ana kosu: P.nRuns kosu, mekanik gurultu kosu basina rastgele
rng(P.seed, 'twister');
main = cell(P.nRuns, 1);
tic
for i = 1:P.nRuns
    main{i} = mc_simulate_run(P);
end
fprintf('Ana kosu: %d tarama, %.1f s\n', P.nRuns, toc);
M = aggregate(main);

%% 2) Duyarlilik taramasi: sabit mekanik gurultu sigma'lari
nS = numel(P.mechSigmaSweep);
S  = cell(nS, 1);
for k = 1:nS
    rng(P.seed + k, 'twister');
    runs = cell(P.nRuns, 1);
    for i = 1:P.nRuns
        runs{i} = mc_simulate_run(P, P.mechSigmaSweep(k));
    end
    S{k} = aggregate(runs);
end

%% 3) Ozet
bigDef = M.depth > P.Tol;
smallDef = ~bigDef;
fprintf('\n===== ANA KOSU OZETI (%d tarama, %d kusur) =====\n', P.nRuns, numel(M.depth));
fprintf('Tolerans-disi kusur (>%.1f mm): %d adet, tespit orani = %.2f %%\n', ...
    P.Tol, nnz(bigDef), 100*mean(M.detected(bigDef)));
fprintf('Tolerans-ici kusur (<=%.1f mm): %d adet, alarm orani  = %.2f %% (yanlis ret)\n', ...
    P.Tol, nnz(smallDef), 100*mean(M.detected(smallDef)));
fprintf('Yanlis alarm bolumu / tarama: %.3f  (alarmli tarama orani %.2f %%)\n', ...
    mean(M.nFalse), 100*mean(M.nFalse > 0));
fprintf('Tespit gecikmesi [s]: ort %.2f, std %.2f, p95 %.2f\n', ...
    mean(M.delay(bigDef & M.detected)), std(M.delay(bigDef & M.detected)), ...
    prctile(M.delay(bigDef & M.detected), 95));
fprintf('Derinlik olcum hatasi (plato ort) [mm]: ort %.4f, std %.4f, |max| %.4f\n', ...
    mean(M.errMean), std(M.errMean), max(abs(M.errMean)));
fprintf('Konum hatasi [mm]: ort %.1f, std %.1f, |max| %.1f (13 m''de +-4 mm/m = +-52 mm)\n', ...
    mean(M.posErr(bigDef & M.detected)), std(M.posErr(bigDef & M.detected)), ...
    max(abs(M.posErr(bigDef & M.detected))));
fprintf('Ornek bazli: TP %d FP %d FN %d TN %d\n', M.tp, M.fp, M.fn, M.tn);

fprintf('\n===== DUYARLILIK (mekanik gurultu sigma) =====\n');
fprintf('%10s | %18s | %20s | %14s\n', 'sigma [mm]', 'tespit (>tol) [%]', 'tol-ici alarm [%]', 'yanlis alarm/tarama');
for k = 1:nS
    d = S{k}.depth > P.Tol;
    fprintf('%10.2f | %18.2f | %20.2f | %14.3f\n', P.mechSigmaSweep(k), ...
        100*mean(S{k}.detected(d)), 100*mean(S{k}.detected(~d)), mean(S{k}.nFalse));
end

%% 4) Grafikler
% Derinlige gore tespit olasiligi (Wilson %95 GA)
edges = P.depthRange(1):0.25:P.depthRange(2);
ctr = (edges(1:end-1) + edges(2:end)) / 2;
pHat = nan(size(ctr)); lo = pHat; hi = pHat;
for b = 1:numel(ctr)
    in = M.depth >= edges(b) & M.depth < edges(b+1);
    [pHat(b), lo(b), hi(b)] = wilson(sum(M.detected(in)), nnz(in));
end

f1 = figure('Position', [50 50 1100 800], 'Name', 'Monte Carlo ozeti');
tl = tiledlayout(2, 2, 'TileSpacing', 'compact');
title(tl, sprintf('Monte Carlo: %d tarama, kusur derinligi %.1f-%.1f mm, tol = %.1f mm', ...
    P.nRuns, P.depthRange(1), P.depthRange(2), P.Tol));

nexttile; hold on; grid on;
fill([ctr fliplr(ctr)], [lo fliplr(hi)], [0.8 0.88 1], 'EdgeColor', 'none');
plot(ctr, pHat, 'o-', 'LineWidth', 1.5);
xline(P.Tol, 'r--', 'tol');
xlabel('Gercek ekstra derinlik [mm]'); ylabel('Tespit olasiligi');
title('Derinlige gore tespit (Wilson %95 GA)'); ylim([0 1.02]);

nexttile; grid on;
histogram(M.delay(bigDef & M.detected), 40);
xlabel('Tespit gecikmesi [s]'); ylabel('Kusur sayisi');
title('Tespit gecikmesi (tol-disi kusurlar)');

nexttile; grid on;
histogram(M.errMean * 1000, 50);
xlabel('Plato derinlik hatasi [\mum]'); ylabel('Kusur sayisi');
title('Derinlik olcum hatasi (olculen - gercek)');

nexttile; grid on;
histogram(M.posErr(bigDef & M.detected), 50);
xlabel('Konum hatasi [mm]'); ylabel('Kusur sayisi');
title('Kusur konum hatasi (enkoder + gecikme)');

f2 = figure('Position', [100 100 800 450], 'Name', 'Duyarlilik');
detS = cellfun(@(s) mean(s.detected(s.depth > P.Tol)), S);
detNear = cellfun(@(s) mean(s.detected(s.depth > P.Tol & s.depth < P.Tol + 1)), S);
faS = cellfun(@(s) mean(s.nFalse), S);
yyaxis left; hold on; grid on;
plot(P.mechSigmaSweep, 100*detS, 'o-', 'LineWidth', 1.5);
plot(P.mechSigmaSweep, 100*detNear, 's-', 'LineWidth', 1.5);
ylabel('Tespit orani [%]');
yyaxis right;
plot(P.mechSigmaSweep, faS, '^-', 'LineWidth', 1.5);
ylabel('Yanlis alarm bolumu / tarama');
xlabel('Mekanik gurultu sigma [mm] (VARSAYIM)');
legend('tum tol-disi kusurlar', sprintf('%.0f-%.0f mm kusurlar', P.Tol, P.Tol+1), ...
    'yanlis alarm', 'Location', 'best');
title('Duyarlilik: mekanik gurultuye karsi');

try
    exportgraphics(f1, fullfile(outDir, 'mc_ozet.png'), 'Resolution', 150);
    exportgraphics(f2, fullfile(outDir, 'mc_duyarlilik.png'), 'Resolution', 150);
catch
    saveas(f1, fullfile(outDir, 'mc_ozet.png'));
    saveas(f2, fullfile(outDir, 'mc_duyarlilik.png'));
end
save(fullfile(outDir, 'mc_results.mat'), 'M', 'S', 'P', '-v7');
fprintf('\nSonuclar kaydedildi: %s\n', outDir);

%% ---- yerel fonksiyonlar ----
function A = aggregate(runs)
    cat1 = @(f) cell2mat(cellfun(@(r) r.(f)(:), runs, 'UniformOutput', false));
    A.depth    = cat1('depth');
    A.start    = cat1('start');
    A.dur      = cat1('dur');
    A.detected = logical(cat1('detected'));
    A.delay    = cat1('delay');
    A.posErr   = cat1('posErr');
    A.errMean  = cat1('errMean');
    A.errStd   = cat1('errStd');
    A.nFalse   = cat1('nFalse');
    A.nomStd   = cat1('nomStd');
    A.sigma    = cat1('sigma');
    A.tp = sum(cat1('tp')); A.fp = sum(cat1('fp'));
    A.fn = sum(cat1('fn')); A.tn = sum(cat1('tn'));
end

function [p, lo, hi] = wilson(k, n)
    if n == 0, p = NaN; lo = NaN; hi = NaN; return; end
    z = 1.96; p = k / n;
    c = (p + z^2/(2*n)) / (1 + z^2/n);
    h = z * sqrt(p*(1-p)/n + z^2/(4*n^2)) / (1 + z^2/n);
    lo = c - h; hi = c + h;
end
