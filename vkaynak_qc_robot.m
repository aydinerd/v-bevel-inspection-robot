%% V-Kaynak Agzi Kalite Kontrol Robotu - Simulink Modeli (otomatik cizim)
% S335 celik plaka, 80 mm kalinlik, 13 m tarama, 20 mm/s -> 650 s
% Lokal kusur: 100-120 s ve 350-380 s arasinda 3.5 mm fazla dalma
% Calistirma: >> vkaynak_qc_robot
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

% --- Sensor tarafi ---
add_block([L 'Sources/Constant'], [mdl '/Taban_Derinlik'], ...
    'Value', '50', 'Position', [30 30 90 60]);

% Kusur 1: 100-120 s (sure 20 s)
add_block([L 'Sources/Pulse Generator'], [mdl '/Kusur_1_100_120s'], ...
    'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
    'Amplitude', '3.5', 'Period', num2str(Tstop), ...
    'PulseWidth', num2str(20/Tstop*100), 'PhaseDelay', '100', ...
    'Position', [30 100 90 130]);

% Kusur 2: 350-380 s (sure 30 s)
add_block([L 'Sources/Pulse Generator'], [mdl '/Kusur_2_350_380s'], ...
    'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
    'Amplitude', '3.5', 'Period', num2str(Tstop), ...
    'PulseWidth', num2str(30/Tstop*100), 'PhaseDelay', '350', ...
    'Position', [30 160 90 190]);

add_block([L 'Math Operations/Sum'], [mdl '/Kusur_Birlestir'], ...
    'Inputs', '++', 'IconShape', 'rectangular', ...
    'Position', [140 120 170 170]);

add_block([L 'Sources/Band-Limited White Noise'], [mdl '/Atolye_Titresimi'], ...
    'Cov', '0.001', 'Ts', '0.01', 'Seed', '[23341]', ...
    'Position', [30 230 90 260]);

% Sensor = Taban - Kusur + Titresim  (3.5 mm fazla dalma -> sensor mesafesi azalir)
add_block([L 'Math Operations/Sum'], [mdl '/Kirli_Sensor_Add'], ...
    'Inputs', '+-+', 'IconShape', 'rectangular', ...
    'Position', [230 60 260 140]);

add_block([L 'Continuous/Transfer Fcn'], [mdl '/Filtre_TransferFcn'], ...
    'Numerator', '[1]', 'Denominator', '[0.1 1]', ...
    'Position', [310 85 390 115]);

% --- Derinlik ve sapma ---
add_block([L 'Sources/Constant'], [mdl '/Z1_Referans'], ...
    'Value', '80', 'Position', [310 20 370 50]);

add_block([L 'Math Operations/Sum'], [mdl '/Anlik_Derinlik_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [450 50 480 100]);

add_block([L 'Sources/Constant'], [mdl '/Ideal_Derinlik'], ...
    'Value', '30', 'Position', [450 170 510 200]);

add_block([L 'Math Operations/Sum'], [mdl '/Sapma_Hesabi_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [560 80 590 130]);

% --- Tolerans karari ---
add_block([L 'Math Operations/Abs'], [mdl '/Mutlak_Sapma'], ...
    'Position', [640 40 680 70]);

add_block([L 'Sources/Constant'], [mdl '/Tolerans_Siniri'], ...
    'Value', '2', 'Position', [640 130 700 160]);

add_block([L 'Logic and Bit Operations/Relational Operator'], ...
    [mdl '/Hata_Kiyaslama'], ...
    'Operator', '>', 'Position', [760 60 810 110]);

% --- Ciktilar ---
add_block([L 'Sinks/Scope'], [mdl '/Scope_Grafik'], ...
    'NumInputPorts', '2', 'Position', [900 50 940 130]);

add_block([L 'Sinks/To Workspace'], [mdl '/Sapma_Kayit'], ...
    'VariableName', 'sapma_log', 'SaveFormat', 'Timeseries', ...
    'Position', [900 200 980 230]);

%% Baglantilar
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

%% Scope veri sinirini kaldir (5000 nokta siniri -> 0...650 s tamami gorunsun)
scopeBlk = [mdl '/Scope_Grafik'];
try
    cfg = get_param(scopeBlk, 'ScopeConfiguration');
    cfg.DataLoggingLimitDataPoints = false;   % "Limit data points to last" kapali
    cfg.TimeSpan = 'Auto';
    cfg.TimeSpanOverrunAction = 'Wrap';
catch
    try
        set_param(scopeBlk, 'DataLoggingLimitDataPoints', 'off');
    catch ME
        warning('Scope veri siniri otomatik kapatilamadi: %s\nScope > Settings > Logging > "Limit data points to last" kutusunu elle kapatin.', ME.message);
    end
end

%% Kaydet ve dogrula
save_system(mdl, fullfile(pwd, [mdl '.slx']));
set_param(mdl, 'SimulationCommand', 'update');   % baglanti/port hatalarini yakalar
fprintf('Model "%s" olusturuldu, port baglantilari dogrulandi.\n', mdl);
fprintf('Calistirmak icin: sim(''%s'')\n', mdl);