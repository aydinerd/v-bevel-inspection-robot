function R = mc_simulate_run(P, sigmaMech)
%MC_SIMULATE_RUN  Cift Kanalli Tek Tarama Kosusu
% =========================================================================
%   Kanal 1: V-Kaynak Pah Derinligi e(x) Kontrolu
%   Kanal 2: Plaka Kavis Yaricapi R(x) Kontrolu (3-Nokta Kiris-Sehim)
% =========================================================================

if nargin < 2 || isempty(sigmaMech)
    sigmaMech = P.mechSigmaRange(1) + diff(P.mechSigmaRange) * rand;
end

t = (0:P.dt:P.Tstop)';
N = numel(t);

%% ========================================================================
%% KANAL 1: V-KAYNAK AGZI DERINLIK KUSURLARI VE SINYAL ZINCIRI
%% ========================================================================
nWant = randi([0 P.nMax]);
dS = zeros(0,1); dD = zeros(0,1); dZ = zeros(0,1);
for k = 1:nWant
    for try_ = 1:200
        dur = P.durRange(1) + diff(P.durRange) * rand;
        s0  = P.edgeMargin + (P.Tstop - 2*P.edgeMargin - dur) * rand;
        if all(s0 > dS + dD + P.minGap | s0 + dur + P.minGap < dS)
            dS(end+1,1) = s0;                                          %#ok<AGROW>
            dD(end+1,1) = dur;                                         %#ok<AGROW>
            dZ(end+1,1) = P.depthRange(1) + diff(P.depthRange) * rand; %#ok<AGROW>
            break
        end
    end
end
nDef = numel(dS);

defect = zeros(N,1);
for i = 1:nDef
    defect(t >= dS(i) & t < dS(i) + dD(i)) = dZ(i);
end

% Kanal 1 Sistematik Hatalar (LVDT 1 + OD5)
kLin1  = 2*rand - 1;
kOd1   = 2*rand - 1;
dTemp1 = P.dT * (2*rand - 1);
gTemp1 = dTemp1 * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef);
oTemp1 = dTemp1 * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef) * P.lvdt.range;

mTrue1 = -defect;
mTrue1 = min(max(mTrue1 + sigmaMech*randn(N,1), -P.lvdt.range), P.lvdt.range);
eLin1  = kLin1 * max(P.lvdt.linPct * abs(mTrue1), P.lvdt.linMin_mm);
eOd1   = kOd1  * P.od5.linFRO * P.lvdt.range;
mMeas1 = mTrue1 * (1 + gTemp1) + eLin1 + eOd1 + oTemp1 ...
       + P.lvdt.repSigma * randn(N,1) ...
       + P.noise_elec_mm * randn(N,1);

u1 = P.Taban + mMeas1;

% Filtre (tau = 0.1 s)
a1 = exp(-P.dt / P.tau);
y1 = filter(1 - a1, [1 -a1], u1, a1 * u1(1));

depth1 = P.Z1 - y1;
dev1   = depth1 - P.Ideal;
flag1  = abs(dev1) > P.Tol;


%% ========================================================================
%% KANAL 2: PLAKA KAVIS YARICAPI R KUSURLARI VE SINYAL ZINCIRI
%% ========================================================================
nWantRad = randi([0 P.rad.nMax]);
rS = zeros(0,1); rD = zeros(0,1); rDev = zeros(0,1);
for k = 1:nWantRad
    for try_ = 1:200
        dur = P.rad.durRange(1) + diff(P.rad.durRange) * rand;
        s0  = P.edgeMargin + (P.Tstop - 2*P.edgeMargin - dur) * rand;
        if all(s0 > rS + rD + P.minGap | s0 + dur + P.minGap < rS)
            rS(end+1,1) = s0;                                          %#ok<AGROW>
            rD(end+1,1) = dur;                                         %#ok<AGROW>
            % Sapma hem pozitif (duzlesme / R artisi) hem negatif (asiri kavis / R azilisi)
            signDev = sign(rand - 0.5); if signDev == 0, signDev = 1; end
            rDev(end+1,1) = signDev * (P.rad.devRange(1) + diff(P.rad.devRange) * rand); %#ok<AGROW>
            break
        end
    end
end
nDefRad = numel(rS);

defectRad = zeros(N,1); % Yaricap sapmasi [m]
for i = 1:nDefRad
    defectRad(t >= rS(i) & t < rS(i) + rD(i)) = rDev(i);
end

R_true = P.rad.R_nom + defectRad; % Gercek yaricap [m]
% 3-Nokta Kiris-Sehim Iliskisi: h = L^2 / (8 * R) = geomK / R  [mm]
h_true = P.rad.geomK ./ R_true;
mTrue2 = h_true - P.rad.h_nom; % Sehimin nominalden farki [mm]

% Kanal 2 Kalibre Edilmis Yatay LVDT Probu (3-Nokta Kiris-Sehim)
% Sferometre sistemi mastar ile calisma oncesi sifirlandigi icin statik ofsetler
% kalibre edilir; sadece kalibrasyon belirsizligi (0.5 um) ve tekrarlanabilirlik kalir.
kLin2  = 2*rand - 1;
dTemp2 = P.dT * (2*rand - 1);
gTemp2 = dTemp2 * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef);

sigmaRad = P.rad.sigmaRange(1) + diff(P.rad.sigmaRange) * rand;
mTrue2_noisy = min(max(mTrue2 + sigmaRad*randn(N,1), -P.rad.range), P.rad.range);
eLin2  = kLin2 * P.lvdt.linPct * abs(mTrue2_noisy); % Dinamik yer degistirmedeki dogrusallik
resCal = 0.0005 * (2*rand - 1); % [mm] 0.5 um mastar sifirlama kalinti hatasi

mMeas2 = mTrue2_noisy * (1 + gTemp2) + eLin2 + resCal ...
       + P.lvdt.repSigma * randn(N,1) ...
       + P.noise_elec_mm * randn(N,1);

h_meas = P.rad.h_nom + mMeas2; % Olculen ham sehim [mm]

% Filtre (tau = 0.1 s)
a2 = exp(-P.dt / P.rad.tau);
h_filt = filter(1 - a2, [1 -a2], h_meas, a2 * h_meas(1));
h_filt = max(h_filt, 0.05); % Sifira bolmeyi onleyen guvenlik siniri

% Sehimden Anlik Yaricap Kestirimi: R_est = geomK / h_filt [m]
R_est = P.rad.geomK ./ h_filt;
dev2  = R_est - P.rad.R_nom; % Yaricap sapmasi [m]
flag2 = abs(dev2) > P.rad.Tol; % Yaricap alarmi (+-1.5 m disi)


%% ========================================================================
%% ENKODER KONUM HESABI
%% ========================================================================
scale = P.enc.scaleErr * (2*rand - 1);
xTrue = P.v * t;
xHat  = xTrue * (1 + scale) + P.enc.stepDev * P.enc.res * (2*rand(N,1) - 1);
xHat  = round(xHat / P.enc.res) * P.enc.res;


%% ========================================================================
%% KANAL 1 DEGERLENDIRME (DERINLIK)
%% ========================================================================
R.depth   = dZ;
R.start   = dS;
R.dur     = dD;
R.detected = false(nDef,1);
R.delay    = nan(nDef,1);
R.posErr   = nan(nDef,1);
R.errMean  = nan(nDef,1);
R.errStd   = nan(nDef,1);
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
        R.errStd(i)  = std(dev1(pl));
    else
        R.errMean(i) = 0;
        R.errStd(i)  = 0;
    end
end
faS1 = flag1 & ~near1;
dFa1 = diff([false; faS1; false]);
R.nFalse = sum(dFa1 == 1);
R.sigma  = sigmaMech;


%% ========================================================================
%% KANAL 2 DEGERLENDIRME (YARICAP)
%% ========================================================================
R.rad_dev      = rDev;
R.rad_start    = rS;
R.rad_dur      = rD;
R.rad_detected = false(nDefRad,1);
R.rad_delay    = nan(nDefRad,1);
R.rad_posErr   = nan(nDefRad,1);
R.rad_errMean  = nan(nDefRad,1); % Plato kestirilen yaricap hatasi (R_est - R_true) [m]
R.rad_errStd   = nan(nDefRad,1);
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
        R.rad_errStd(i)  = std(R_est(pl));
    else
        R.rad_errMean(i) = 0;
        R.rad_errStd(i)  = 0;
    end
end
faS2 = flag2 & ~near2;
dFa2 = diff([false; faS2; false]);
R.rad_nFalse = sum(dFa2 == 1);
end
