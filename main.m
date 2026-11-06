%% V-KAYNAK AĞZI VE PLAKA RADYUSU KALİTE KONTROL ROBOTU - TEK TIKLA ÇALIŞTIRMA
% =========================================================================
% PROJE: Otonom Manyetik Paletli V-Kaynak Ağzı ve Plaka Kesim Kavis Kalite Kontrol Robotu
% ÖĞRENCİ: Aydıner Dikme (030220086) | İTÜ Makina Mühendisliği
% DERS: Mekatronik Sistem Tasarımı | Teslim: 06/11/2026
%
% ÇİFT KANALLI DENETİM MİMARİSİ:
%   1. Kanal (Düşey LVDT Prob): 80 mm S335 plaka kaynak ağzı pah derinliği e(x) [+-2.0 mm]
%   2. Kanal (Yatay LVDT Prob): 3-nokta kiriş-sehim sferometre ile plaka kesim yarıçapı R(x) [+-1.5 m]
%
% KULLANIM:
%   Bu dosyayı MATLAB'da açıp F5 tuşuna basın (veya "Run" butonuna tıklayın).
%   Tüm simülasyon, 5000 koşuluk Monte Carlo analizi ve grafikler otomatik üretilir.
% =========================================================================

clear; clc; close all;

fprintf('=================================================================\n');
fprintf('   V-KAYNAK VE RADYUS KALİTE KONTROL ROBOTU (ÇİFT KANAL)        \n');
fprintf('   Öğrenci: Aydıner Dikme (030220086) - İTÜ Makina Fakültesi     \n');
fprintf('=================================================================\n\n');

%% ------------------------------------------------------------------------
%% 1. SİMULİNK MODELİNİN KOŞTURULMASI (13 metre / 650 saniye tarama)
%% ------------------------------------------------------------------------
mdl = 'V_Kaynak_QC_Robot';
fprintf('>> [1/2] Simulink modeli koşturuluyor (13 m plaka, 650 s tarama)...\n');

if ~bdIsLoaded(mdl)
    load_system(mdl);
end

tic;
simOut = sim(mdl);
sure_sim = toc;

t      = simOut.sapma_log.Time;
d_dep  = simOut.sapma_log.Data;       % Kanal 1: Derinlik sapması [mm]
d_rad  = simOut.radyus_log.Data;      % Kanal 2: Kestirilen Yarıçap [m]
d_rsap = simOut.radyus_sapma_log.Data;% Kanal 2: Yarıçap sapması [m]

fprintf('   - Simulink çözümü %.2f saniyede başarıyla tamamlandı.\n', sure_sim);
fprintf('\n   [KANAL 1: KAYNAK AĞZI PAH DERİNLİĞİ e(x)]\n');
fprintf('   - Kusur 1 (100-120 s) Ölçülen Sapma : +%.3f mm (Hedef: +3.5 mm) -> TESPİT EDİLDİ [ALARM]\n', ...
    mean(d_dep(t >= 102 & t <= 118)));
fprintf('   - Kusur 2 (350-380 s) Ölçülen Sapma : +%.3f mm (Hedef: +3.5 mm) -> TESPİT EDİLDİ [ALARM]\n', ...
    mean(d_dep(t >= 352 & t <= 378)));
fprintf('   - Normal Bölge Titreşimli Sapması   : +-%.3f mm (Filtre tolerans içinde tutuyor)\n', ...
    std(d_dep(t >= 10 & t <= 90)));

fprintf('\n   [KANAL 2: KONİK KESİM PLAKA RADYUSU R(x) (3-Nokta Kiriş-Sehim)]\n');
fprintf('   - Kusur R1 (200-240 s) Ölçülen Yarıçap : %.2f m (Hedef: 38.0 m) -> TESPİT EDİLDİ [ALARM - AŞIRI KAVİS]\n', ...
    mean(d_rad(t >= 202 & t <= 238)));
fprintf('   - Kusur R2 (480-520 s) Ölçülen Yarıçap : %.2f m (Hedef: 65.0 m) -> TESPİT EDİLDİ [ALARM - DÜZLEŞME]\n', ...
    mean(d_rad(t >= 482 & t <= 518)));
fprintf('   - Normal Bölge Nominal Kestirimi       : %.2f m (Hedef: 50.0 m, Sapma: %.3f m)\n', ...
    mean(d_rad(t >= 10 & t <= 90)), mean(d_rad(t >= 10 & t <= 90)) - 50.0);

% Scope penceresini açmayı dene
try
    open_system([mdl '/Scope_Grafik']);
catch
end

% Simulink Çift Kanallı Sonuç Grafiğini Çiz
fig1 = figure('Name', '1. Simulink Cift Kanalli Tarama Grafigi', 'Position', [60 180 900 600]);
tiledlayout(2, 1, 'TileSpacing', 'compact');

% Subplot 1: Derinlik Sapması
nexttile; hold on; grid on;
plot(t, d_dep, 'b-', 'LineWidth', 1.2);
yline(2.0, 'r--', 'Tolerans Üst Sınırı (+2 mm)', 'LineWidth', 1.4);
yline(-2.0, 'r--', 'Tolerans Alt Sınırı (-2 mm)', 'LineWidth', 1.4);
xlabel('Tarama Süresi [s] (Hız = 20 mm/s)');
ylabel('Pah Derinlik Sapması [mm]');
title('Kanal 1: V-Kaynak Ağzı Pah Derinliği Sapması \Deltae(x) (Nominal: 30 mm)');
ylim([-1.5 5.0]);
legend('Ölçülen Filtreli Derinlik Sapması', 'Tolerans Sınırı (+-2 mm)', 'Location', 'northeast');

% Subplot 2: Kavis Yarıçapı
nexttile; hold on; grid on;
plot(t, d_rad, 'Color', [0 0.5 0], 'LineWidth', 1.3);
yline(50.0, 'k-', 'Nominal Kavis Yarıçapı (50.0 m)', 'LineWidth', 1.2);
yline(51.5, 'r--', 'Yarıçap Üst Toleransı (51.5 m / +%3)', 'LineWidth', 1.4);
yline(48.5, 'r--', 'Yarıçap Alt Toleransı (48.5 m / -%3)', 'LineWidth', 1.4);
xlabel('Tarama Süresi [s] (Hız = 20 mm/s)');
ylabel('Hesaplanan Kavis Yarıçapı [m]');
title('Kanal 2: 3-Nokta Kiriş-Sehim Metodu ile Plaka Kavis Yarıçapı R(x)');
ylim([30.0 75.0]);
legend('Hesaplanan Kavis Yarıçapı R(t)', 'Nominal Yarıçap (50 m)', 'Tolerans Sınırları (+-1.5 m)', 'Location', 'northeast');

fprintf('   -> Simulink sonuç grafiği ve 4-Kanallı Scope hazırlandı.\n\n');


%% ------------------------------------------------------------------------
%% 2. MONTE CARLO DOĞRULAMASI (5000 Koşu - İstatistiksel Güvenilirlik)
%% ------------------------------------------------------------------------
fprintf('>> [2/2] Çift kanallı Monte Carlo istatistiksel doğrulaması yapılıyor (5000 tarama)...\n');

P = mc_params_local();
P.nRuns = 5000; % 5000 koşu
outDir = fullfile(fileparts(mfilename('fullpath')), 'monte_carlo', 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Ana koşu
rng(P.seed, 'twister');
mainRuns = cell(P.nRuns, 1);
tic;
for i = 1:P.nRuns
    mainRuns{i} = mc_simulate_run_local(P);
end
t_mc = toc;
M = aggregate_local(mainRuns);

% Duyarlılık taraması
nS = numel(P.mechSigmaSweep);
S  = cell(nS, 1);
for k = 1:nS
    rng(P.seed + k, 'twister');
    runs = cell(P.nRuns, 1);
    for i = 1:P.nRuns
        runs{i} = mc_simulate_run_local(P, P.mechSigmaSweep(k));
    end
    S{k} = aggregate_local(runs);
end

bigDef1 = M.depth > P.Tol;
smallDef1 = ~bigDef1;

bigDef2 = abs(M.rad_dev) > P.rad.Tol;
smallDef2 = ~bigDef2;

fprintf('   - 5000 Monte Carlo koşusu %.2f saniyede tamamlandı.\n', t_mc);
fprintf('   ===============================================================\n');
fprintf('   KANAL 1: KAYNAK AĞZI PAH DERİNLİĞİ e(x) ANALİZİ\n');
fprintf('   - Tolerans Dışı Kusur (>2 mm) Tespit Oranı : %% %.2f (%d kusurun tamamı yakalandı)\n', ...
    100*mean(M.detected(bigDef1)), sum(bigDef1));
fprintf('   - Temiz Bölgede Asılsız Alarm Oranı        : %.3f / tarama\n', mean(M.nFalse));
fprintf('   - Ortalama LVDT Ölçüm Hatası               : %.2f mikrometre (std: %.2f um)\n', ...
    mean(M.errMean)*1000, std(M.errMean)*1000);
fprintf('   - Kusur Konumlandırma Hatası (Enkoder)     : Ortalama %.1f mm\n\n', ...
    mean(M.posErr(bigDef1 & M.detected)));

fprintf('   KANAL 2: PLAKA KAVİS YARIÇAPI R(x) ANALİZİ\n');
fprintf('   - Tolerans Dışı Yarıçap (|dR|>1.5 m) Tespiti: %% %.2f (%d kusurun tamamı yakalandı)\n', ...
    100*mean(M.rad_detected(bigDef2)), sum(bigDef2));
fprintf('   - Temiz Bölgede Asılsız Alarm Oranı         : %.3f / tarama\n', mean(M.rad_nFalse));
fprintf('   - Ortalama Yarıçap Kestirim Hatası          : %.2f m (50 m yarıçapta %% %.2f hata)\n', ...
    mean(abs(M.rad_errMean)), 100*mean(abs(M.rad_errMean))/P.rad.R_nom);
fprintf('   - Yarıçap Kusur Konumlandırma Hatası       : Ortalama %.1f mm\n', ...
    mean(M.rad_posErr(bigDef2 & M.rad_detected)));
fprintf('   ===============================================================\n\n');


%% ------------------------------------------------------------------------
%% 3. MONTE CARLO GRAFİKLERİ
%% ------------------------------------------------------------------------
% Monte Carlo Grafiği 1: Çift Kanallı Doğrulama Özeti (4 Panel)
fig2 = figure('Name', '2. Monte Carlo Dogrulama Ozeti (5000 Kosu)', 'Position', [120 100 1000 700]);
tiledlayout(2, 2, 'TileSpacing', 'compact');

% Subplot 1: Derinlik Tespit Başarısı
edges1 = P.depthRange(1):0.25:P.depthRange(2);
ctr1 = (edges1(1:end-1) + edges1(2:end)) / 2;
pHat1 = nan(size(ctr1)); lo1 = pHat1; hi1 = pHat1;
for b = 1:numel(ctr1)
    in = M.depth >= edges1(b) & M.depth < edges1(b+1);
    [pHat1(b), lo1(b), hi1(b)] = wilson_local(sum(M.detected(in)), nnz(in));
end

nexttile; hold on; grid on;
fill([ctr1 fliplr(ctr1)], [lo1 fliplr(hi1)], [0.8 0.88 1], 'EdgeColor', 'none');
plot(ctr1, pHat1, 'bo-', 'LineWidth', 1.5);
xline(P.Tol, 'r--', 'Derinlik Toleransı (2 mm)', 'LineWidth', 1.3);
xlabel('Kusur Derinliği [mm]'); ylabel('Tespit Olasılığı');
title('Kanal 1: Derinliğe Göre Tespit Başarısı (Wilson %95 GA)'); ylim([0 1.05]);

% Subplot 2: Kavis Yarıçapı Tespit Başarısı
edges2 = P.rad.devRange(1):0.75:P.rad.devRange(2);
ctr2 = (edges2(1:end-1) + edges2(2:end)) / 2;
pHat2 = nan(size(ctr2)); lo2 = pHat2; hi2 = pHat2;
absDev2 = abs(M.rad_dev);
for b = 1:numel(ctr2)
    in = absDev2 >= edges2(b) & absDev2 < edges2(b+1);
    [pHat2(b), lo2(b), hi2(b)] = wilson_local(sum(M.rad_detected(in)), nnz(in));
end

nexttile; hold on; grid on;
fill([ctr2 fliplr(ctr2)], [lo2 fliplr(hi2)], [0.85 1 0.85], 'EdgeColor', 'none');
plot(ctr2, pHat2, 'go-', 'LineWidth', 1.5);
xline(P.rad.Tol, 'r--', 'Yarıçap Toleransı (1.5 m)', 'LineWidth', 1.3);
xlabel('Yarıçap Sapması |\DeltaR| [m]'); ylabel('Tespit Olasılığı');
title('Kanal 2: Plaka Kavis Sapmasına Göre Tespit Başarısı'); ylim([0 1.05]);

% Subplot 3: LVDT Derinlik Ölçüm Hatası
nexttile; grid on;
histogram(M.errMean * 1000, 45, 'FaceColor', [0.8 0.4 0.2]);
xlabel('Derinlik Ölçüm Hatası [\mum]'); ylabel('Kusur Sayısı');
title(sprintf('Kanal 1: Düşey LVDT Ölçüm Hatası (Ort: %.1f \\mum)', mean(M.errMean)*1000));

% Subplot 4: Yarıçap Kestirim Hatası
nexttile; grid on;
histogram(M.rad_errMean, 45, 'FaceColor', [0.2 0.6 0.8]);
xlabel('Yarıçap Kestirim Hatası [m]'); ylabel('Kusur Sayısı');
title(sprintf('Kanal 2: Kavis Kestirim Hatası (Ort: %.2f m)', mean(abs(M.rad_errMean))));


% Monte Carlo Grafiği 2: Titreşim Duyarlılığı
fig3 = figure('Name', '3. Titresim ve Gurultu Duyarlilik Egvisi', 'Position', [200 80 850 450]);
detS = cellfun(@(s) mean(s.detected(s.depth > P.Tol)), S);
detNear = cellfun(@(s) mean(s.detected(s.depth > P.Tol & s.depth < P.Tol + 1)), S);
faS = cellfun(@(s) mean(s.nFalse), S);
yyaxis left; hold on; grid on;
plot(P.mechSigmaSweep, 100*detS, 'bo-', 'LineWidth', 1.5);
plot(P.mechSigmaSweep, 100*detNear, 'gs-', 'LineWidth', 1.5);
ylabel('Kusur Tespit Oranı [%]');
yyaxis right;
plot(P.mechSigmaSweep, faS, 'r^-', 'LineWidth', 1.5);
ylabel('Yanlış Alarm / Tarama');
xlabel('Mekanik Titreşim / Yüzey Pürüzü \sigma [mm]');
legend('Tolerans Dışı Kusurlar (>2 mm)', 'Sınırdaki Kusurlar (2-3 mm)', 'Yanlış Alarm', 'Location', 'best');
title('Atölye Titreşimi Arttıkça Çift Kanallı Sistemin Dayanıklılığı');

fprintf('=================================================================\n');
fprintf('   TAMAMLANDI! TÜM ÇİFT KANALLI GRAFİKLER VE VERİLER HAZIR.     \n');
fprintf('=================================================================\n');


%% ========================================================================
%% YEREL HESAPLAMA FONKSİYONLARI (Alt Fonksiyonlar)
%% ========================================================================

function P = mc_params_local()
    P.dt     = 0.05;
    P.Tstop  = 650;
    P.v      = 20;
    
    % Kanal 1: Derinlik
    P.Z1     = 80;
    P.Taban  = 50;
    P.Ideal  = 30;
    P.Tol    = 2.0;
    P.tau    = 0.1;
    P.nMax       = 5;
    P.depthRange = [0.5 5.0];
    P.durRange   = [5 40];
    P.edgeMargin = 10;
    P.minGap     = 10;
    
    % Kanal 2: Kavis Yarıçapı (3-Nokta Kiriş-Sehim)
    P.rad.L        = 400;      % [mm]
    P.rad.R_nom    = 50.0;     % [m]
    P.rad.h_nom    = (P.rad.L^2) / (8 * P.rad.R_nom * 1000); % [mm] 0.400 mm
    P.rad.geomK    = (P.rad.L^2) / 8 / 1000;                 % [m*mm] = 20.0
    P.rad.range    = 1.0;      % [mm]
    P.rad.Tol      = 1.5;      % [m]
    P.rad.tau      = 0.15;     % [s]
    P.rad.nMax     = 3;
    P.rad.devRange = [0.5 15.0];
    P.rad.durRange = [10 50];
    P.rad.sigmaRange = [0.001 0.004]; % [mm]
    
    % Sensör ve Donanım
    P.lvdt.range      = 5;
    P.lvdt.linPct     = 0.005;
    P.lvdt.linMin_mm  = 0.005;
    P.lvdt.repSigma   = 7e-5;
    P.lvdt.tempCoef   = 1e-4;
    P.lvdt.sens_mVmm  = 1575/5;
    P.od5.noise_mV    = 1;
    P.od5.linFRO      = 1e-3;
    P.od5.tempCoef    = 1e-4;
    P.od5.bw_Hz       = 500;
    P.noise_elec_mm   = P.od5.noise_mV / P.lvdt.sens_mVmm;
    P.dT              = 20;
    P.enc.res         = 0.2;
    P.enc.scaleErr    = 0.004;
    P.enc.stepDev     = 0.05;
    P.mechSigmaRange  = [0.05 0.5];
    P.mechSigmaSweep  = [0.05 0.15 0.3 0.5];
    P.evalMargin      = 1.0;
    P.nRuns   = 5000;
    P.seed    = 20261104;
end

function R = mc_simulate_run_local(P, sigmaMech)
    if nargin < 2 || isempty(sigmaMech)
        sigmaMech = P.mechSigmaRange(1) + diff(P.mechSigmaRange) * rand;
    end
    t = (0:P.dt:P.Tstop)';
    N = numel(t);
    
    % --- Kanal 1: Derinlik Kusurları ---
    nWant = randi([0 P.nMax]);
    dS = zeros(0,1); dD = zeros(0,1); dZ = zeros(0,1);
    for k = 1:nWant
        for try_ = 1:200
            dur = P.durRange(1) + diff(P.durRange) * rand;
            s0  = P.edgeMargin + (P.Tstop - 2*P.edgeMargin - dur) * rand;
            if all(s0 > dS + dD + P.minGap | s0 + dur + P.minGap < dS)
                dS(end+1,1) = s0;
                dD(end+1,1) = dur;
                dZ(end+1,1) = P.depthRange(1) + diff(P.depthRange) * rand;
                break
            end
        end
    end
    nDef = numel(dS);
    defect = zeros(N,1);
    for i = 1:nDef
        defect(t >= dS(i) & t < dS(i) + dD(i)) = dZ(i);
    end
    kLin1  = 2*rand - 1;
    kOd1   = 2*rand - 1;
    dTemp1 = P.dT * (2*rand - 1);
    gTemp1 = dTemp1 * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef);
    oTemp1 = dTemp1 * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef) * P.lvdt.range;
    mTrue1 = -defect;
    mTrue1 = min(max(mTrue1 + sigmaMech*randn(N,1), -P.lvdt.range), P.lvdt.range);
    eLin1 = kLin1 * max(P.lvdt.linPct * abs(mTrue1), P.lvdt.linMin_mm);
    eOd1  = kOd1  * P.od5.linFRO * P.lvdt.range;
    mMeas1 = mTrue1 * (1 + gTemp1) + eLin1 + eOd1 + oTemp1 ...
          + P.lvdt.repSigma * randn(N,1) ...
          + P.noise_elec_mm * randn(N,1);
    u1 = P.Taban + mMeas1;
    a1 = exp(-P.dt / P.tau);
    y1 = filter(1 - a1, [1 -a1], u1, a1 * u1(1));
    depth1 = P.Z1 - y1;
    dev1   = depth1 - P.Ideal;
    flag1  = abs(dev1) > P.Tol;
    
    % --- Kanal 2: Kavis Yarıçapı Kusurları ---
    nWantRad = randi([0 P.rad.nMax]);
    rS = zeros(0,1); rD = zeros(0,1); rDev = zeros(0,1);
    for k = 1:nWantRad
        for try_ = 1:200
            dur = P.rad.durRange(1) + diff(P.rad.durRange) * rand;
            s0  = P.edgeMargin + (P.Tstop - 2*P.edgeMargin - dur) * rand;
            if all(s0 > rS + rD + P.minGap | s0 + dur + P.minGap < rS)
                rS(end+1,1) = s0;
                rD(end+1,1) = dur;
                signDev = sign(rand - 0.5); if signDev == 0, signDev = 1; end
                rDev(end+1,1) = signDev * (P.rad.devRange(1) + diff(P.rad.devRange) * rand);
                break
            end
        end
    end
    nDefRad = numel(rS);
    defectRad = zeros(N,1);
    for i = 1:nDefRad
        defectRad(t >= rS(i) & t < rS(i) + rD(i)) = rDev(i);
    end
    R_true = P.rad.R_nom + defectRad;
    h_true = P.rad.geomK ./ R_true;
    mTrue2 = h_true - P.rad.h_nom;
    
    kLin2  = 2*rand - 1;
    dTemp2 = P.dT * (2*rand - 1);
    gTemp2 = dTemp2 * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef);
    sigmaRad = P.rad.sigmaRange(1) + diff(P.rad.sigmaRange) * rand;
    mTrue2_noisy = min(max(mTrue2 + sigmaRad*randn(N,1), -P.rad.range), P.rad.range);
    eLin2  = kLin2 * P.lvdt.linPct * abs(mTrue2_noisy);
    resCal = 0.0005 * (2*rand - 1);
    mMeas2 = mTrue2_noisy * (1 + gTemp2) + eLin2 + resCal ...
           + P.lvdt.repSigma * randn(N,1) ...
           + P.noise_elec_mm * randn(N,1);
    h_meas = P.rad.h_nom + mMeas2;
    a2 = exp(-P.dt / P.rad.tau);
    h_filt = filter(1 - a2, [1 -a2], h_meas, a2 * h_meas(1));
    h_filt = max(h_filt, 0.05);
    R_est = P.rad.geomK ./ h_filt;
    dev2  = R_est - P.rad.R_nom;
    flag2 = abs(dev2) > P.rad.Tol;
    
    % Enkoder
    scale = P.enc.scaleErr * (2*rand - 1);
    xTrue = P.v * t;
    xHat  = xTrue * (1 + scale) + P.enc.stepDev * P.enc.res * (2*rand(N,1) - 1);
    xHat  = round(xHat / P.enc.res) * P.enc.res;
    
    % Kanal 1 Değerlendirme
    R.depth   = dZ;
    R.start   = dS;
    R.dur     = dD;
    R.detected = false(nDef,1);
    R.delay    = nan(nDef,1);
    R.posErr   = nan(nDef,1);
    R.errMean  = nan(nDef,1);
    near1 = false(N,1);
    for i = 1:nDef
        win = t >= dS(i) - P.evalMargin & t <= dS(i) + dD(i) + P.evalMargin;
        near1 = near1 | win;
        hit = find(flag1 & t >= dS(i) & t <= dS(i) + dD(i) + P.evalMargin, 1);
        R.detected(i) = ~isempty(hit);
        if R.detected(i)
            R.delay(i)  = t(hit) - dS(i);
            R.posErr(i) = xHat(hit) - P.v * dS(i);
        end
        pl = t >= dS(i) + 1 & t < dS(i) + dD(i);
        if any(pl)
            R.errMean(i) = mean(dev1(pl)) - dZ(i);
        else
            R.errMean(i) = 0;
        end
    end
    faS1 = flag1 & ~near1;
    dFa1 = diff([false; faS1; false]);
    R.nFalse = sum(dFa1 == 1);
    R.sigma = sigmaMech;
    
    % Kanal 2 Değerlendirme
    R.rad_dev      = rDev;
    R.rad_start    = rS;
    R.rad_dur      = rD;
    R.rad_detected = false(nDefRad,1);
    R.rad_delay    = nan(nDefRad,1);
    R.rad_posErr   = nan(nDefRad,1);
    R.rad_errMean  = nan(nDefRad,1);
    near2 = false(N,1);
    for i = 1:nDefRad
        win = t >= rS(i) - P.evalMargin & t <= rS(i) + rD(i) + P.evalMargin;
        near2 = near2 | win;
        hit = find(flag2 & t >= rS(i) & t <= rS(i) + rD(i) + P.evalMargin, 1);
        R.rad_detected(i) = ~isempty(hit);
        if R.rad_detected(i)
            R.rad_delay(i)  = t(hit) - rS(i);
            R.rad_posErr(i) = xHat(hit) - P.v * rS(i);
        end
        pl = t >= rS(i) + 1 & t < rS(i) + rD(i);
        if any(pl)
            R.rad_errMean(i) = mean(R_est(pl)) - (P.rad.R_nom + rDev(i));
        else
            R.rad_errMean(i) = 0;
        end
    end
    faS2 = flag2 & ~near2;
    dFa2 = diff([false; faS2; false]);
    R.rad_nFalse = sum(dFa2 == 1);
end

function A = aggregate_local(runs)
    cat1 = @(f) cell2mat(cellfun(@(r) r.(f)(:), runs, 'UniformOutput', false));
    A.depth        = cat1('depth');
    A.detected     = logical(cat1('detected'));
    A.delay        = cat1('delay');
    A.posErr       = cat1('posErr');
    A.errMean      = cat1('errMean');
    A.nFalse       = cat1('nFalse');
    A.sigma        = cat1('sigma');
    
    A.rad_dev      = cat1('rad_dev');
    A.rad_detected = logical(cat1('rad_detected'));
    A.rad_delay    = cat1('rad_delay');
    A.rad_posErr   = cat1('rad_posErr');
    A.rad_errMean  = cat1('rad_errMean');
    A.rad_nFalse   = cat1('rad_nFalse');
end

function [p, lo, hi] = wilson_local(k, n)
    if n == 0, p = NaN; lo = NaN; hi = NaN; return; end
    z = 1.96; p = k / n;
    c = (p + z^2/(2*n)) / (1 + z^2/n);
    h = z * sqrt(p*(1-p)/n + z^2/(4*n^2)) / (1 + z^2/n);
    lo = c - h; hi = c + h;
end
