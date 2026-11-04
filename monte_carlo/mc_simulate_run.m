function R = mc_simulate_run(P, sigmaMech)
%MC_SIMULATE_RUN  Tek tarama kosusu (Simulink modelinin sinyal zinciriyle esdeger).
%   Zincir: sensor = Taban + olculen_yer_degistirme -> 1. derece filtre ->
%           derinlik = Z1 - filtre -> sapma = derinlik - Ideal -> |sapma| > Tol
%   sigmaMech: mekanik gurultu sigma [mm]; bos ise P.mechSigmaRange'den cekilir.
%   Rastgelelik global rng akisindan gelir (rng cagiran tarafindan ayarlanir).

if nargin < 2 || isempty(sigmaMech)
    sigmaMech = P.mechSigmaRange(1) + diff(P.mechSigmaRange) * rand;
end

t = (0:P.dt:P.Tstop)';
N = numel(t);

%% 1) Rastgele kusurlar (birbiriyle cakismaz)
nWant = randi([0 P.nMax]);
dS = zeros(0,1); dD = zeros(0,1); dZ = zeros(0,1);   % baslangic, sure, derinlik
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

defect = zeros(N,1);                       % gercek ekstra dalma [mm]
for i = 1:nDef
    defect(t >= dS(i) & t < dS(i) + dD(i)) = dZ(i);
end

%% 2) Run basina rastgele sistematik hatalar
kLin  = 2*rand - 1;                        % LVDT dogrusallik isareti/buyuklugu
kOd   = 2*rand - 1;                        % OD5 dogrusallik
dTemp = P.dT * (2*rand - 1);               % sicaklik sapmasi [C]
gTemp = dTemp * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef);   % kazanc
oTemp = dTemp * (2*rand - 1) * (P.lvdt.tempCoef + P.od5.tempCoef) * P.lvdt.range; % ofset [mm]

%% 3) Probun gordugu yer degistirme ve olcum zinciri
mTrue = -defect;                           % fazla dalma -> sensor okumasi azalir
mTrue = min(max(mTrue + sigmaMech*randn(N,1), -P.lvdt.range), P.lvdt.range);

eLin = kLin * max(P.lvdt.linPct * abs(mTrue), P.lvdt.linMin_mm);
eOd  = kOd  * P.od5.linFRO * P.lvdt.range;
mMeas = mTrue * (1 + gTemp) + eLin + eOd + oTemp ...
      + P.lvdt.repSigma * randn(N,1) ...
      + P.noise_elec_mm * randn(N,1);

u = P.Taban + mMeas;                       % sensor okumasi [mm]

%% 4) Filtre 1/(tau s + 1), tam ayriklastirma
a = exp(-P.dt / P.tau);
y = filter(1 - a, [1 -a], u, a * u(1));

depth = P.Z1 - y;                          % olculen derinlik
dev   = depth - P.Ideal;                   % olculen sapma
flag  = abs(dev) > P.Tol;                  % alarm (1 = HATA)

%% 5) Enkoder konumu
scale = P.enc.scaleErr * (2*rand - 1);
xTrue = P.v * t;
xHat  = xTrue * (1 + scale) + P.enc.stepDev * P.enc.res * (2*rand(N,1) - 1);
xHat  = round(xHat / P.enc.res) * P.enc.res;

%% 6) Degerlendirme
trueOut = defect > P.Tol;                  % gercekten tolerans disi mi

R.nDef    = nDef;
R.sigma   = sigmaMech;
R.depth   = dZ;
R.start   = dS;
R.dur     = dD;
R.detected = false(nDef,1);
R.delay    = nan(nDef,1);
R.posErr   = nan(nDef,1);
R.errMean  = nan(nDef,1);   % plato sapma ortalamasi - gercek derinlik [mm]
R.errStd   = nan(nDef,1);   % plato ornek std [mm]
near = false(N,1);
for i = 1:nDef
    win = t >= dS(i) - P.evalMargin & t <= dS(i) + dD(i) + P.evalMargin;
    near = near | win;
    hit = find(flag & t >= dS(i) & t <= dS(i) + dD(i) + P.evalMargin, 1);
    R.detected(i) = ~isempty(hit);
    if R.detected(i)
        R.delay(i)  = t(hit) - dS(i);
        R.posErr(i) = xHat(hit) - P.v * dS(i);
    end
    pl = t >= dS(i) + 1 & t < dS(i) + dD(i);
    R.errMean(i) = mean(dev(pl)) - dZ(i);
    R.errStd(i)  = std(dev(pl));
end

% Yanlis alarm: HICBIR kusur penceresiyle ortusmeyen alarm bolumleri.
% (Tolerans-ici kusur penceresindeki alarmlar burada sayilmaz; onlar
%  "tolerans-ici alarm orani" olarak ayri raporlanir.)
dd = diff([0; flag; 0]);
sIdx = find(dd == 1);
eIdx = find(dd == -1) - 1;
nFalse = 0;
for k = 1:numel(sIdx)
    if ~any(near(sIdx(k):eIdx(k)))
        nFalse = nFalse + 1;
    end
end
R.nFalse = nFalse;

% Kusursuz bolgede sapma istatistigi
nom = ~near;
R.nomMean = mean(dev(nom));
R.nomStd  = std(dev(nom));

% Ornek bazli karisiklik matrisi
R.tp = sum(flag &  trueOut);
R.fp = sum(flag & ~trueOut);
R.fn = sum(~flag &  trueOut);
R.tn = sum(~flag & ~trueOut);
end
