function P = mc_params()
%MC_PARAMS  Monte Carlo icin tum parametreler (tek yerde).
%   Her parametrenin yaninda kaynak yazilidir:
%     [DS]  = datasheet / katalog degeri
%     [HES] = datasheet degerlerinden hesaplanan
%     [VAR] = VARSAYIM (datasheet yok, dogrulanmadi)
%   Kaynak dosyalar: Solartron analogue catalogue 2023 (sf. 14-15),
%   OD5 MK II user manual 502645 (sf. 24), OD4/OD5 link table 502633,
%   SICK DBV50E-22ELA1000 online datasheet.

%% Zaman ve robot
P.dt     = 0.05;     % [s]  Monte Carlo adimi. [VAR] (Simulink modeli 0.01 s)
P.Tstop  = 650;      % [s]  13 000 mm / 20 mm/s
P.v      = 20;       % [mm/s] robot hizi (sabit varsayildi) [VAR]

%% Nominal geometri (Simulink modeliyle ayni)
P.Z1     = 80;       % [mm] ust referans yuzey
P.Taban  = 50;       % [mm] sensor nominal okumasi
P.Ideal  = 30;       % [mm] nominal V-agzi derinligi
P.Tol    = 2;        % [mm] tolerans siniri
P.tau    = 0.1;      % [s]  Transfer Fcn 1/(0.1 s + 1)

%% Kusur uretimi (rastgele)
P.nMax       = 5;           % kusur sayisi ~ U{0..5}
P.depthRange = [0.5 5];     % [mm] ekstra dalma derinligi ~ U
P.durRange   = [5 40];      % [s]  kusur suresi (100 - 800 mm) [VAR]
P.edgeMargin = 10;          % [s]  plaka basi/sonu bos pay [VAR]
P.minGap     = 10;          % [s]  iki kusur arasi min bosluk [VAR]

%% LVDT probu Solartron AX/5/S  [DS: katalog sf. 15]
P.lvdt.range      = 5;       % [mm] +-5 mm olcum araligi
P.lvdt.linPct     = 0.005;   % dogrusallik: %0.5 okuma
P.lvdt.linMin_mm  = 0.005;   % ... veya 5 um, hangisi buyukse
P.lvdt.repSigma   = 7e-5;    % [mm] tipik tekrarlanabilirlik 0.07 um (1 sigma)
P.lvdt.tempCoef   = 1e-4;    % [1/C] 0.01 %FS/C (maksimum deger)
P.lvdt.sens_mVmm  = 1575/5;  % [mV/mm] AX/5 tam skala 1575 mV / 5 mm [HES, link table]

%% OD5 sartlandirici  [DS: OD5 MK II manual sf. 24]
P.od5.noise_mV    = 1;       % [mV rms] cikis gurultusu (< 1 mV rms)
P.od5.linFRO      = 1e-3;    % dogrusallik < %0.1 FRO
P.od5.tempCoef    = 1e-4;    % [1/C] kazanc/ofset < %0.01 FRO/C
P.od5.bw_Hz       = 500;     % [Hz] -3 dB bant genisligi (filtreden cok genis)
P.noise_elec_mm   = P.od5.noise_mV / P.lvdt.sens_mVmm;   % [mm rms] ~ 3.2 um [HES]
P.dT              = 20;      % [C] sicaklik sapmasi ~ U(-dT, dT) [VAR]

%% Enkoder SICK DBV50E-22ELA1000  [DS: online datasheet sf. 2-3]
P.enc.res         = 0.2;     % [mm/darbe] 1000 P/R, 200 mm cevre
P.enc.scaleErr    = 0.004;   % +-4 mm/m olcek hatasi (tekerlek+yuzeye bagli)
P.enc.stepDev     = 0.05;    % +-18 derece elektriksel = +-%5 darbe

%% Mekanik / yuzey gurultusu  [VAR - datasheet YOK]
% Beyaz gurultu sigma'si, dt = P.dt orneklemesinde. Atolye titresimi,
% V-agzi yuzey puruzu, uc asinmasi, robot egilmesini temsil eder.
P.mechSigmaRange  = [0.05 0.5];          % [mm] ana kosu: kosu basina ~ U
P.mechSigmaSweep  = [0.05 0.15 0.3 0.5]; % [mm] duyarlilik taramasi

%% Degerlendirme
P.evalMargin      = 1;       % [s] kusur penceresi toleransi (filtre gecikmesi)

%% Monte Carlo
P.nRuns   = 1000;
P.seed    = 20261104;
end
