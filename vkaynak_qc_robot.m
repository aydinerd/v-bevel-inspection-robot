%% V-Kaynak Agzi ve Plaka Radyusu Kalite Kontrol Robotu - Simulink Modeli
% =========================================================================
% S335 celik plaka, 80 mm kalinlik, 13 m tarama, 20 mm/s -> 650 s
% CIFT PROB MIMARISI:
%   Kanal 1: Kaynak Agzi Pah Derinligi e(x) [Dusey LVDT, Ideal: 30 mm, Tol: +-2.0 mm]
%            Kusurlar: 100-120 s ve 350-380 s (+3.5 mm dalma)
%   Kanal 2: Konik Kesim Plaka Radyusu R(x) [Yatay LVDT, 3-Nokta Kiris-Sehim Metodu]
%            Kiris L = 400 mm, R_nom = 50.0 m (h_nom = 0.400 mm), Tol: +-1.5 m
%            Kusurlar: 200-240 s (R = 38 m, dh = +0.126 mm) ve 480-520 s (R = 65 m, dh = -0.092 mm)
% Calistirma: >> vkaynak_qc_robot
% =========================================================================

clear; clc;

mdl = 'V_Kaynak_QC_Robot';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
open_system(mdl);

%% Simulasyon ayarlari
Tstop = 650;
set_param(mdl, 'StopTime', num2str(Tstop), ...
               'SolverType', 'Fixed-step', ...
               'Solver', 'ode4', ...
               'FixedStep', '0.01');

%% Blok ekleme  [x y genislik yukseklik]
L = 'simulink/';

%% ========================================================================
%% KANAL 1: V-KAYNAK AGZI DERINLIK KONTROLU (DUSEY PROB)
%% ========================================================================
add_block([L 'Sources/Constant'], [mdl '/Taban_Derinlik'], ...
    'Value', '50', 'Position', [30 30 90 60]);

% Kusur 1: 100-120 s (sure 20 s -> Period 1000 s icin %2)
add_block([L 'Sources/Pulse Generator'], [mdl '/Kusur_1_100_120s'], ...
    'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
    'Amplitude', '3.5', 'Period', '1000', ...
    'PulseWidth', '2', 'PhaseDelay', '100', ...
    'Position', [30 100 90 130]);

% Kusur 2: 350-380 s (sure 30 s -> Period 1000 s icin %3)
add_block([L 'Sources/Pulse Generator'], [mdl '/Kusur_2_350_380s'], ...
    'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
    'Amplitude', '3.5', 'Period', '1000', ...
    'PulseWidth', '3', 'PhaseDelay', '350', ...
    'Position', [30 160 90 190]);

add_block([L 'Math Operations/Sum'], [mdl '/Kusur_Birlestir'], ...
    'Inputs', '++', 'IconShape', 'rectangular', ...
    'Position', [140 120 170 170]);

add_block([L 'Sources/Band-Limited White Noise'], [mdl '/Atolye_Titresimi'], ...
    'Cov', '0.001', 'Ts', '0.01', 'Seed', '[23341]', ...
    'Position', [30 220 90 250]);

% Sensor = Taban - Kusur + Titresim
add_block([L 'Math Operations/Sum'], [mdl '/Kirli_Sensor_Add'], ...
    'Inputs', '+-+', 'IconShape', 'rectangular', ...
    'Position', [230 60 260 140]);

add_block([L 'Continuous/Transfer Fcn'], [mdl '/Filtre_TransferFcn'], ...
    'Numerator', '[1]', 'Denominator', '[0.1 1]', ...
    'Position', [310 85 390 115]);

% Derinlik ve sapma
add_block([L 'Sources/Constant'], [mdl '/Z1_Referans'], ...
    'Value', '80', 'Position', [310 20 370 50]);

add_block([L 'Math Operations/Sum'], [mdl '/Anlik_Derinlik_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [450 50 480 100]);

add_block([L 'Sources/Constant'], [mdl '/Ideal_Derinlik'], ...
    'Value', '30', 'Position', [450 140 510 170]);

add_block([L 'Math Operations/Sum'], [mdl '/Sapma_Hesabi_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [560 80 590 130]);

% Tolerans karari (+-2 mm)
add_block([L 'Math Operations/Abs'], [mdl '/Mutlak_Sapma'], ...
    'Position', [640 40 680 70]);

add_block([L 'Sources/Constant'], [mdl '/Tolerans_Siniri'], ...
    'Value', '2', 'Position', [640 130 700 160]);

add_block([L 'Logic and Bit Operations/Relational Operator'], ...
    [mdl '/Hata_Kiyaslama'], ...
    'Operator', '>', 'Position', [760 60 810 110]);

% Workspace kayit (Derinlik Sapmasi)
add_block([L 'Sinks/To Workspace'], [mdl '/Sapma_Kayit'], ...
    'VariableName', 'sapma_log', 'SaveFormat', 'Timeseries', ...
    'Position', [900 180 980 210]);


%% ========================================================================
%% KANAL 2: PLAKA KAVIS YARICAPI R KONTROLU (YATAY PROB / 3-NOKTA SEHIM)
%% ========================================================================
% Kiris mesafesi L = 400 mm, R_nom = 50 m -> h_nom = L^2 / (8*R) = 0.400 mm
% R [m] = 20 / h [mm]
add_block([L 'Sources/Constant'], [mdl '/Nominal_Sehim_h0'], ...
    'Value', '0.400', 'Position', [30 310 90 340]);

% Kusur R1: 200-240 s (sure 40 s -> Period 1000 s icin %4, R = 38 m -> h = 0.5263 mm -> dh = +0.1263 mm)
add_block([L 'Sources/Pulse Generator'], [mdl '/Kusur_R1_200_240s'], ...
    'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
    'Amplitude', '0.1263', 'Period', '1000', ...
    'PulseWidth', '4', 'PhaseDelay', '200', ...
    'Position', [30 370 90 400]);

% Kusur R2: 480-520 s (sure 40 s -> Period 1000 s icin %4, R = 65 m -> h = 0.3077 mm -> dh = -0.0923 mm)
add_block([L 'Sources/Pulse Generator'], [mdl '/Kusur_R2_480_520s'], ...
    'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
    'Amplitude', '-0.0923', 'Period', '1000', ...
    'PulseWidth', '4', 'PhaseDelay', '480', ...
    'Position', [30 430 90 460]);

add_block([L 'Math Operations/Sum'], [mdl '/Kusur_R_Birlestir'], ...
    'Inputs', '++', 'IconShape', 'rectangular', ...
    'Position', [140 390 170 440]);

add_block([L 'Sources/Band-Limited White Noise'], [mdl '/Atolye_Titresimi_R'], ...
    'Cov', '0.0001', 'Ts', '0.01', 'Seed', '[54321]', ...
    'Position', [30 490 90 520]);

% Toplam Sehim = h0 + dh + titresim
add_block([L 'Math Operations/Sum'], [mdl '/Kirli_Sehim_Add'], ...
    'Inputs', '+++', 'IconShape', 'rectangular', ...
    'Position', [230 330 260 410]);

% Alcak geciren filtre (tau = 0.1 s)
add_block([L 'Continuous/Transfer Fcn'], [mdl '/Filtre_R_TransferFcn'], ...
    'Numerator', '[1]', 'Denominator', '[0.1 1]', ...
    'Position', [310 355 370 385]);

% Sifira bolmeyi ve baslangic gecicisini onleyen guvenlik sinirlayici (0.05 - 5.0 mm)
add_block([L 'Discontinuities/Saturation'], [mdl '/Sehim_Sinirlayici'], ...
    'UpperLimit', '5.0', 'LowerLimit', '0.05', ...
    'Position', [390 355 425 385]);

% R hesabi: R [m] = 20 / h [mm]
add_block([L 'Sources/Constant'], [mdl '/Geometri_Sabiti_20'], ...
    'Value', '20', 'Position', [310 290 370 320]);

add_block([L 'Math Operations/Divide'], [mdl '/Radyus_Hesabi_Div'], ...
    'Inputs', '*/', 'Position', [460 320 490 370]);

% Sapma hesabi: delta_R = R_olculen - 50.0 m
add_block([L 'Sources/Constant'], [mdl '/Nominal_Radyus'], ...
    'Value', '50', 'Position', [450 410 510 440]);

add_block([L 'Math Operations/Sum'], [mdl '/Radyus_Sapma_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [560 350 590 400]);

% Tolerans karari (+-1.5 m)
add_block([L 'Math Operations/Abs'], [mdl '/Mutlak_Radyus_Sapma'], ...
    'Position', [640 310 680 340]);

add_block([L 'Sources/Constant'], [mdl '/Radyus_Tolerans_Siniri'], ...
    'Value', '1.5', 'Position', [640 400 700 430]);

add_block([L 'Logic and Bit Operations/Relational Operator'], ...
    [mdl '/Radyus_Hata_Kiyaslama'], ...
    'Operator', '>', 'Position', [760 330 810 380]);

% Workspace kayit (Radyus Hesabi ve Sapmasi)
add_block([L 'Sinks/To Workspace'], [mdl '/Radyus_Kayit'], ...
    'VariableName', 'radyus_log', 'SaveFormat', 'Timeseries', ...
    'Position', [900 360 980 390]);

add_block([L 'Sinks/To Workspace'], [mdl '/Radyus_Sapma_Kayit'], ...
    'VariableName', 'radyus_sapma_log', 'SaveFormat', 'Timeseries', ...
    'Position', [900 420 980 450]);


%% ========================================================================
%% ORTAK SCOPE (4 KANAL GORUNTULEME)
%% ========================================================================
add_block([L 'Sinks/Scope'], [mdl '/Scope_Grafik'], ...
    'NumInputPorts', '4', 'Position', [900 30 940 150]);


%% ========================================================================
%% BAGLANTILAR
%% ========================================================================
% --- Kanal 1 Hatlari ---
add_line(mdl, 'Kusur_1_100_120s/1', 'Kusur_Birlestir/1', 'autorouting', 'on');
add_line(mdl, 'Kusur_2_350_380s/1', 'Kusur_Birlestir/2', 'autorouting', 'on');

add_line(mdl, 'Taban_Derinlik/1',   'Kirli_Sensor_Add/1', 'autorouting', 'on');  % +
add_line(mdl, 'Kusur_Birlestir/1',  'Kirli_Sensor_Add/2', 'autorouting', 'on');  % -
add_line(mdl, 'Atolye_Titresimi/1', 'Kirli_Sensor_Add/3', 'autorouting', 'on');  % +

add_line(mdl, 'Kirli_Sensor_Add/1', 'Filtre_TransferFcn/1', 'autorouting', 'on');

add_line(mdl, 'Z1_Referans/1',        'Anlik_Derinlik_Sub/1', 'autorouting', 'on'); % +
add_line(mdl, 'Filtre_TransferFcn/1', 'Anlik_Derinlik_Sub/2', 'autorouting', 'on'); % -

add_line(mdl, 'Anlik_Derinlik_Sub/1', 'Sapma_Hesabi_Sub/1', 'autorouting', 'on');  % +
add_line(mdl, 'Ideal_Derinlik/1',     'Sapma_Hesabi_Sub/2', 'autorouting', 'on');  % -

add_line(mdl, 'Sapma_Hesabi_Sub/1', 'Scope_Grafik/1', 'autorouting', 'on');
add_line(mdl, 'Sapma_Hesabi_Sub/1', 'Sapma_Kayit/1',  'autorouting', 'on');
add_line(mdl, 'Sapma_Hesabi_Sub/1', 'Mutlak_Sapma/1', 'autorouting', 'on');

add_line(mdl, 'Mutlak_Sapma/1',    'Hata_Kiyaslama/1', 'autorouting', 'on');
add_line(mdl, 'Tolerans_Siniri/1', 'Hata_Kiyaslama/2', 'autorouting', 'on');
add_line(mdl, 'Hata_Kiyaslama/1',  'Scope_Grafik/2',   'autorouting', 'on');

% --- Kanal 2 Hatlari ---
add_line(mdl, 'Kusur_R1_200_240s/1', 'Kusur_R_Birlestir/1', 'autorouting', 'on');
add_line(mdl, 'Kusur_R2_480_520s/1', 'Kusur_R_Birlestir/2', 'autorouting', 'on');

add_line(mdl, 'Nominal_Sehim_h0/1',   'Kirli_Sehim_Add/1', 'autorouting', 'on');
add_line(mdl, 'Kusur_R_Birlestir/1',   'Kirli_Sehim_Add/2', 'autorouting', 'on');
add_line(mdl, 'Atolye_Titresimi_R/1', 'Kirli_Sehim_Add/3', 'autorouting', 'on');

add_line(mdl, 'Kirli_Sehim_Add/1',      'Filtre_R_TransferFcn/1', 'autorouting', 'on');
add_line(mdl, 'Filtre_R_TransferFcn/1', 'Sehim_Sinirlayici/1',   'autorouting', 'on');

add_line(mdl, 'Geometri_Sabiti_20/1',   'Radyus_Hesabi_Div/1',   'autorouting', 'on');
add_line(mdl, 'Sehim_Sinirlayici/1',    'Radyus_Hesabi_Div/2',   'autorouting', 'on');

add_line(mdl, 'Radyus_Hesabi_Div/1',   'Radyus_Kayit/1', 'autorouting', 'on');
add_line(mdl, 'Radyus_Hesabi_Div/1',   'Radyus_Sapma_Sub/1', 'autorouting', 'on');
add_line(mdl, 'Nominal_Radyus/1',      'Radyus_Sapma_Sub/2', 'autorouting', 'on');

add_line(mdl, 'Radyus_Sapma_Sub/1',    'Scope_Grafik/3', 'autorouting', 'on');
add_line(mdl, 'Radyus_Sapma_Sub/1',    'Radyus_Sapma_Kayit/1', 'autorouting', 'on');
add_line(mdl, 'Radyus_Sapma_Sub/1',    'Mutlak_Radyus_Sapma/1', 'autorouting', 'on');

add_line(mdl, 'Mutlak_Radyus_Sapma/1',   'Radyus_Hata_Kiyaslama/1', 'autorouting', 'on');
add_line(mdl, 'Radyus_Tolerans_Siniri/1','Radyus_Hata_Kiyaslama/2', 'autorouting', 'on');
add_line(mdl, 'Radyus_Hata_Kiyaslama/1', 'Scope_Grafik/4', 'autorouting', 'on');


%% ========================================================================
%% Scope Veri Sinirini ve 2 Panelli Yerlesimini Ayarla
%% ========================================================================
scopeBlk = [mdl '/Scope_Grafik'];
try
    cfg = get_param(scopeBlk, 'ScopeConfiguration');
    cfg.DataLoggingLimitDataPoints = false;
    cfg.TimeSpan = 'Auto';
    cfg.TimeSpanOverrunAction = 'Wrap';
    cfg.LayoutDimensions = [2 1]; % 2 Ayri Panel (Ust: Derinlik [mm], Alt: Radyus [m])
catch
    try
        set_param(scopeBlk, 'DataLoggingLimitDataPoints', 'off');
    catch
    end
end

%% Kaydet ve Dogrula
save_system(mdl, fullfile(pwd, [mdl '.slx']));
set_param(mdl, 'SimulationCommand', 'update');
fprintf('=================================================================\n');
fprintf('Model "%s" basariyla cift kanalli olarak guncellendi.\n', mdl);
fprintf('  Kanal 1: V-Kaynak Pah Derinligi e(x) [+-2.0 mm]\n');
fprintf('  Kanal 2: Konik Plaka Kesim Radyusu R(x) [+-1.5 m]\n');
fprintf('Kayit tamamlandi: %s.slx\n', mdl);
fprintf('=================================================================\n');
