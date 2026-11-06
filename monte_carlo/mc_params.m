function P = mc_params()
%MC_PARAMS  Cift Kanalli Monte Carlo Parametreleri (Tek Noktadan Yonetim)
% =========================================================================
%   Kanal 1: V-Kaynak Agzi Pah Derinligi (Dusey Solartron LVDT Probu)
%   Kanal 2: Konik Plaka Kesim Radyusu (Yatay LVDT, 3-Nokta Kiris-Sehim Metodu)
% =========================================================================

%% 1) Zaman ve Robot Kinematigi
P.dt     = 0.05;     % [s]  Monte Carlo ornekleme adimi (Simulink 0.01 s)
P.Tstop  = 650;      % [s]  13 000 mm / 20 mm/s tarama suresi
P.v      = 20;       % [mm/s] sabit tarama hizi

%% 2) Kanal 1: V-Kaynak Agzi Geometrisi ve Toleransi
P.Z1     = 80;       % [mm] plaka ust referans duzlemi (80 mm S335 celik plaka)
P.Taban  = 50;       % [mm] sensor nominal temas montaj konumu
P.Ideal  = 30;       % [mm] nominal V-agzi pah derinligi
P.Tol    = 2.0;      % [mm] ISO 5817 Seviye B derinlik toleransi (+-2 mm)
P.tau    = 0.1;      % [s]  1. derece filtre zaman sabiti (fc = 1.59 Hz)

%% 3) Kanal 2: Plaka Kavis Yaricapi (3-Nokta Kiris-Sehim Sferometre Metodu)
P.rad.L        = 400;      % [mm] sabit kilavuz makaralari arasi kiris mesafesi
P.rad.R_nom    = 50.0;     % [m]  konik ruzgar kulesi acinim plakasi nominal kesim yaricapi
P.rad.h_nom    = (P.rad.L^2) / (8 * P.rad.R_nom * 1000); % [mm] 0.400 mm nominal sehim
P.rad.geomK    = (P.rad.L^2) / 8 / 1000;                 % [m*mm] = 20.0 (R [m] = geomK / h [mm])
P.rad.range    = 1.0;      % [mm] yatay sehim LVDT calisma araligi (+-0.5 mm)
P.rad.Tol      = 1.5;      % [m]  yaricap kabul toleransi (+-1.5 m, %3 kesim toleransi)
P.rad.tau      = 0.15;     % [s]  yaricap filtresi zaman sabiti

%% 4) Kusur Uretimi (Kanal 1: Derinlik Kusurlari)
P.nMax       = 5;          % kosu basina max derinlik kusur sayisi ~ U{0..5}
P.depthRange = [0.5 5.0];  % [mm] ekstra dalma derinligi
P.durRange   = [5 40];     % [s]  kusur suresi (100 - 800 mm arasi lokal bozulma)
P.edgeMargin = 10;         % [s]  plaka bas/son marji
P.minGap     = 10;         % [s]  kusurlar arasi minimum emniyet mesafesi

%% 5) Kusur Uretimi (Kanal 2: Yaricap Kusurlari / Torc Yolu Sapmalari)
P.rad.nMax     = 3;        % kosu basina max yaricap kusuru ~ U{0..3}
P.rad.devRange = [0.5 15]; % [m] yaricap sapmasi mutlak degeri (asiri kavis / duzlesme)
P.rad.durRange = [10 50];  % [s] kavis bozulma bolgesi suresi

%% 6) LVDT Probu (Solartron AX/5/S - Her iki kanalda ozdes yuksek hassasiyet)
P.lvdt.range      = 5;       % [mm] +-5 mm tam skala olcum araligi
P.lvdt.linPct     = 0.005;   % dogrusallik hatasi: %0.5 okuma
P.lvdt.linMin_mm  = 0.005;   % minimum dogrusallik hatasi (5 um)
P.lvdt.repSigma   = 7e-5;    % [mm] tekrarlanabilirlik 0.07 um (1 sigma)
P.lvdt.tempCoef   = 1e-4;    % [1/C] sicaklik katsayisi
P.lvdt.sens_mVmm  = 1575/5;  % [mV/mm] duyarllik

%% 7) Sinyal Sartlandirici (Solartron OD5 MK II)
P.od5.noise_mV    = 1;       % [mV rms] cikis gurultusu (< 1 mV rms)
P.od5.linFRO      = 1e-3;    % tam skala dogrusallik < %0.1
P.od5.tempCoef    = 1e-4;    % [1/C] termal kayma
P.od5.bw_Hz       = 500;     % [Hz] analog bant genisligi
P.noise_elec_mm   = P.od5.noise_mV / P.lvdt.sens_mVmm; % [mm rms] ~ 3.2 um
P.dT              = 20;      % [C] atolye ici calisma sicakligi dalgalanmasi

%% 8) Temasli Tekerlek Enkoderi (SICK DBV50E-22ELA1000)
P.enc.res         = 0.2;     % [mm/darbe] cozunurluk
P.enc.scaleErr    = 0.004;   % +-4 mm/m tekerlek yuvarlanma olcek toleransi
P.enc.stepDev     = 0.05;    % +-%5 elektriksel darbe sapmasi

%% 9) Mekanik ve Yuzey Gurultuleri
P.mechSigmaRange  = [0.05 0.5];          % [mm] Kanal 1 mekanik titresim / puruzluluk
P.mechSigmaSweep  = [0.05 0.15 0.3 0.5]; % [mm] duyarlilik taramasi seviyeleri
P.rad.sigmaRange  = [0.001 0.004];       % [mm] Kanal 2 frezelenmis kok burnu sehim temas gurultusu

%% 10) Degerlendirme ve Kosu Ayarlari
P.evalMargin      = 1.0;     % [s] gecikme tolerans penceresi
P.nRuns   = 1000;            % standart Monte Carlo kosu adedi
P.seed    = 20261104;        % tekrarlanabilir rastgele sayi uretici tohumu
end
