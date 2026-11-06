%% CIFT KANALLI MONTE CARLO DOGRULAMA: V-KAYNAK VE RADYUS KALITE KONTROL
% =========================================================================
%   Kanal 1: V-Kaynak Agzi Pah Derinligi e(x) [+-2.0 mm]
%   Kanal 2: Plaka Kavis Yaricapi R(x) [+-1.5 m]
% Calistirma:  >> cd monte_carlo; run_monte_carlo
% =========================================================================
clear; close all; clc;

P = mc_params();
outDir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% 1) Ana Kosu: P.nRuns Kosu
fprintf('>> [1/2] Monte Carlo calistiriliyor (%d tarama, cift kanal)...\n', P.nRuns);
rng(P.seed, 'twister');
main = cell(P.nRuns, 1);
tic;
for i = 1:P.nRuns
    main{i} = mc_simulate_run(P);
end
t_mc = toc;
fprintf('   - Ana kosu tamamlandi: %d tarama, %.1f saniye.\n', P.nRuns, t_mc);
M = aggregate(main);

%% 2) Duyarlilik Taramasi
fprintf('>> [2/2] Mekanik titresim duyarlilik taramasi yapiliyor...\n');
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

%% 3) Istatistiksel Raporlama
bigDef1   = M.depth > P.Tol;
smallDef1 = ~bigDef1;

bigDef2   = abs(M.rad_dev) > P.rad.Tol;
smallDef2 = ~bigDef2;

fprintf('\n=================================================================\n');
fprintf('   CIFT KANALLI MONTE CARLO ANALIZ SONUCLARI (%d TARAMA)        \n', P.nRuns);
fprintf('=================================================================\n');

fprintf('\n[KANAL 1: KAYNAK AGZI PAH DERINLIGI e(x) - DUSEY LVDT]\n');
fprintf('   - Toplam Uretilen Kusur Adedi             : %d adet\n', numel(M.depth));
fprintf('   - Tolerans Disi Kusur (> 2.0 mm) Tespiti   : %% %.2f (%d / %d yakalandi)\n', ...
    100*mean(M.detected(bigDef1)), sum(M.detected(bigDef1)), sum(bigDef1));
fprintf('   - Tolerans Ici Bolgede Yanlis Alarm       : %% %.2f\n', 100*mean(M.detected(smallDef1)));
fprintf('   - Ortalama LVDT Olcum Hatasi              : %.2f mikrometre (std: %.2f um)\n', ...
    mean(M.errMean)*1000, std(M.errMean)*1000);
fprintf('   - Tespit Gecikmesi                        : Ortalama %.2f s (std: %.2f s)\n', ...
    mean(M.delay(bigDef1 & M.detected)), std(M.delay(bigDef1 & M.detected)));
fprintf('   - Enkoder Kusur Konumlandirma Hatasi      : Ortalama %.1f mm\n', ...
    mean(M.posErr(bigDef1 & M.detected)));

fprintf('\n[KANAL 2: PLAKA KAVIS YARICAPI R(x) - YATAY LVDT 3-NOKTA SEHIM]\n');
fprintf('   - Toplam Uretilen Kavis Kusuru            : %d adet\n', numel(M.rad_dev));
fprintf('   - Tolerans Disi Yaricap (|dR| > 1.5 m)     : %% %.2f (%d / %d yakalandi)\n', ...
    100*mean(M.rad_detected(bigDef2)), sum(M.rad_detected(bigDef2)), sum(bigDef2));
fprintf('   - Tolerans Ici Kavis Sapmasi Alarmi       : %% %.2f\n', 100*mean(M.rad_detected(smallDef2)));
fprintf('   - Ortalama Yaricap Kestirim Hatasi        : %.2f m (50 m capta %% %.2f hata)\n', ...
    mean(abs(M.rad_errMean)), 100*mean(abs(M.rad_errMean))/P.rad.R_nom);
fprintf('   - Yaricap Tespit Gecikmesi                : Ortalama %.2f s\n', ...
    mean(M.rad_delay(bigDef2 & M.rad_detected)));
fprintf('   - Enkoder Kusur Konumlandirma Hatasi      : Ortalama %.1f mm\n', ...
    mean(M.rad_posErr(bigDef2 & M.rad_detected)));

fprintf('\n[GENEL GUVENILIRLIK]\n');
fprintf('   - Temiz Bolgede Asilsiz Yanlis Alarm (K1) : %.3f adet / tarama\n', mean(M.nFalse));
fprintf('   - Temiz Bolgede Asilsiz Yanlis Alarm (K2) : %.3f adet / tarama\n', mean(M.rad_nFalse));
fprintf('=================================================================\n\n');


%% 4) Grafikler
% --- Grafik 1: Monte Carlo Cift Kanal Ozeti ---
figure('Position', [50 50 1100 800], 'Name', 'Cift Kanalli Monte Carlo Dogrulama Ozeti');
tl = tiledlayout(2, 2, 'TileSpacing', 'compact');
title(tl, sprintf('Cift Kanalli Robot Dogrulamasi (%d Tarama, 13 m Plaka)', P.nRuns), 'FontWeight', 'bold');

% Subplot 1: Derinlik Tespit Olasiligi (Wilson %95 GA)
edges1 = P.depthRange(1):0.25:P.depthRange(2);
ctr1 = (edges1(1:end-1) + edges1(2:end)) / 2;
pHat1 = nan(size(ctr1)); lo1 = pHat1; hi1 = pHat1;
for b = 1:numel(ctr1)
    in = M.depth >= edges1(b) & M.depth < edges1(b+1);
    [pHat1(b), lo1(b), hi1(b)] = wilson(sum(M.detected(in)), nnz(in));
end

nexttile; hold on; grid on;
fill([ctr1 fliplr(ctr1)], [lo1 fliplr(hi1)], [0.8 0.88 1], 'EdgeColor', 'none');
plot(ctr1, pHat1, 'bo-', 'LineWidth', 1.5);
xline(P.Tol, 'r--', 'Tolerans (2.0 mm)', 'LineWidth', 1.3);
xlabel('Ekstra Dalma Derinligi [mm]'); ylabel('Tespit Olasiligi');
title('Kanal 1: Pah Derinligine Gore Tespit Basarisi'); ylim([0 1.05]);

% Subplot 2: Yaricap Tespit Olasiligi (Wilson %95 GA)
edges2 = P.rad.devRange(1):0.75:P.rad.devRange(2);
ctr2 = (edges2(1:end-1) + edges2(2:end)) / 2;
pHat2 = nan(size(ctr2)); lo2 = pHat2; hi2 = pHat2;
absDev2 = abs(M.rad_dev);
for b = 1:numel(ctr2)
    in = absDev2 >= edges2(b) & absDev2 < edges2(b+1);
    [pHat2(b), lo2(b), hi2(b)] = wilson(sum(M.rad_detected(in)), nnz(in));
end

nexttile; hold on; grid on;
fill([ctr2 fliplr(ctr2)], [lo2 fliplr(hi2)], [0.85 1 0.85], 'EdgeColor', 'none');
plot(ctr2, pHat2, 'go-', 'LineWidth', 1.5);
xline(P.rad.Tol, 'r--', 'Tolerans (1.5 m)', 'LineWidth', 1.3);
xlabel('Yaricap Sapmasi |\DeltaR| [m]'); ylabel('Tespit Olasiligi');
title('Kanal 2: Plaka Kavis Sapmasina Gore Tespit Basarisi'); ylim([0 1.05]);

% Subplot 3: LVDT Derinlik Olcum Hatasi
nexttile; grid on;
histogram(M.errMean * 1000, 40, 'FaceColor', [0.8 0.4 0.2]);
xlabel('Derinlik Olcum Hatasi [\mum]'); ylabel('Kusur Adedi');
title('Kanal 1: Dusey LVDT Olcum Dogrulugu');

% Subplot 4: Yaricap Kestirim Hatasi
nexttile; grid on;
histogram(M.rad_errMean, 40, 'FaceColor', [0.3 0.6 0.8]);
xlabel('Yaricap Kestirim Hatasi [m]'); ylabel('Kusur Adedi');
title('Kanal 2: 3-Nokta Sehim Yaricap Kestirim Hatasi');

% --- Grafik 2: Titresim ve Gurultu Duyarliligi ---
figure('Position', [120 120 850 450], 'Name', 'Mekanik Gurultu Duyarlilik Grafigi');
detS = cellfun(@(s) mean(s.detected(s.depth > P.Tol)), S);
detNear = cellfun(@(s) mean(s.detected(s.depth > P.Tol & s.depth < P.Tol + 1)), S);
faS = cellfun(@(s) mean(s.nFalse), S);
yyaxis left; hold on; grid on;
plot(P.mechSigmaSweep, 100*detS, 'bo-', 'LineWidth', 1.5);
plot(P.mechSigmaSweep, 100*detNear, 'gs-', 'LineWidth', 1.5);
ylabel('Kusur Tespit Orani [%]');
yyaxis right;
plot(P.mechSigmaSweep, faS, 'r^-', 'LineWidth', 1.5);
ylabel('Yanlis Alarm / Tarama');
xlabel('Mekanik Gurultu / Titresim \sigma [mm]');
legend('Tolerans Disi Kusurlar (>2 mm)', 'Sinirdaki Kusurlar (2-3 mm)', 'Yanlis Alarm', 'Location', 'best');
title('Mekanik Titresim ve Puruzluluk Karsisinda Sistemin Saglamligi');

% Gorselleri kaydet
try
    exportgraphics(findobj('Type', 'figure', 'Name', 'Cift Kanalli Monte Carlo Dogrulama Ozeti'), ...
        fullfile(outDir, 'mc_ozet.png'), 'Resolution', 150);
    exportgraphics(findobj('Type', 'figure', 'Name', 'Mekanik Gurultu Duyarlilik Grafigi'), ...
        fullfile(outDir, 'mc_duyarlilik.png'), 'Resolution', 150);
catch
    saveas(findobj('Type', 'figure', 'Name', 'Cift Kanalli Monte Carlo Dogrulama Ozeti'), ...
        fullfile(outDir, 'mc_ozet.png'));
    saveas(findobj('Type', 'figure', 'Name', 'Mekanik Gurultu Duyarlilik Grafigi'), ...
        fullfile(outDir, 'mc_duyarlilik.png'));
end
save(fullfile(outDir, 'mc_results.mat'), 'M', 'S', 'P', '-v7');
fprintf('Grafikler ve sonuclar kaydedildi: %s\n', outDir);


%% ========================================================================
%% YARDIMCI FONKSIYONLAR
%% ========================================================================
function A = aggregate(runs)
    cat1 = @(f) cell2mat(cellfun(@(r) r.(f)(:), runs, 'UniformOutput', false));
    A.depth        = cat1('depth');
    A.detected     = logical(cat1('detected'));
    A.delay        = cat1('delay');
    A.posErr       = cat1('posErr');
    A.errMean      = cat1('errMean');
    A.errStd       = cat1('errStd');
    A.nFalse       = cat1('nFalse');
    A.sigma        = cat1('sigma');
    
    A.rad_dev      = cat1('rad_dev');
    A.rad_detected = logical(cat1('rad_detected'));
    A.rad_delay    = cat1('rad_delay');
    A.rad_posErr   = cat1('rad_posErr');
    A.rad_errMean  = cat1('rad_errMean');
    A.rad_errStd   = cat1('rad_errStd');
    A.rad_nFalse   = cat1('rad_nFalse');
end

function [p, lo, hi] = wilson(k, n)
    if n == 0, p = NaN; lo = NaN; hi = NaN; return; end
    z = 1.96; p = k / n;
    c = (p + z^2/(2*n)) / (1 + z^2/n);
    h = z * sqrt(p*(1-p)/n + z^2/(4*n^2)) / (1 + z^2/n);
    lo = c - h; hi = c + h;
end
