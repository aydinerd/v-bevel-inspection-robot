%% V-Kaynak Agzi Kalite Kontrol Robotu - Simulink Modeli (Hatasiz Surum)
% S335 celik plaka, 80 mm kalinlik, 13 m tarama, 20 mm/s -> 650 s
% Lokal kusur: 100-120 s ve 350-380 s arasinda 3.5 mm fazla dalma
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

% --- 1. Sensor ve Hata Girdileri ---
add_block([L 'Sources/Constant'], [mdl '/Taban_Derinlik'], ...
    'Value', '50', 'Position', [30 30 90 60]);

% Kusur 1: 100 - 120 s arasi (3.5 mm dalma)
add_block([L 'Sources/Step'], [mdl '/Kusur1_Basla'], ...
    'Time', '100', 'Before', '0', 'After', '3.5', 'Position', [30 90 70 120]);
add_block([L 'Sources/Step'], [mdl '/Kusur1_Bitir'], ...
    'Time', '120', 'Before', '0', 'After', '3.5', 'Position', [30 140 70 170]);

% Kusur 2: 350 - 380 s arasi (3.5 mm dalma)
add_block([L 'Sources/Step'], [mdl '/Kusur2_Basla'], ...
    'Time', '350', 'Before', '0', 'After', '3.5', 'Position', [30 200 70 230]);
add_block([L 'Sources/Step'], [mdl '/Kusur2_Bitir'], ...
    'Time', '380', 'Before', '0', 'After', '3.5', 'Position', [30 250 70 280]);

% Kusurlari birlestir: (+ Kusur1_Basla - Kusur1_Bitir + Kusur2_Basla - Kusur2_Bitir)
add_block([L 'Math Operations/Sum'], [mdl '/Kusur_Birlestir'], ...
    'Inputs', '+-+-', 'IconShape', 'rectangular', ...
    'Position', [130 150 160 220]);

% Atolye motor titresimleri
add_block([L 'Sources/Band-Limited White Noise'], [mdl '/Atolye_Titresimi'], ...
    'Cov', '0.001', 'Ts', '0.01', 'Seed', '[23341]', ...
    'Position', [30 310 90 340]);

% Kirli Sensor = Taban - Kusurlar + Titresim
add_block([L 'Math Operations/Sum'], [mdl '/Kirli_Sensor_Add'], ...
    'Inputs', '+-+', 'IconShape', 'rectangular', ...
    'Position', [220 50 250 130]);

% --- 2. Sinyal Filtreleme ---
add_block([L 'Continuous/Transfer Fcn'], [mdl '/Filtre_TransferFcn'], ...
    'Numerator', '[1]', 'Denominator', '[0.1 1]', ...
    'Position', [300 75 380 105]);

% --- 3. Diferansiyel Derinlik ve Sapma Hesabi ---
add_block([L 'Sources/Constant'], [mdl '/Z1_Referans'], ...
    'Value', '80', 'Position', [300 15 360 45]);

add_block([L 'Math Operations/Sum'], [mdl '/Anlik_Derinlik_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [440 40 470 90]);

add_block([L 'Sources/Constant'], [mdl '/Ideal_Derinlik'], ...
    'Value', '30', 'Position', [440 150 500 180]);

add_block([L 'Math Operations/Sum'], [mdl '/Sapma_Hesabi_Sub'], ...
    'Inputs', '+-', 'IconShape', 'rectangular', ...
    'Position', [550 70 580 120]);

% --- 4. Tolerans Kontrol Algoritmasi ---
add_block([L 'Math Operations/Abs'], [mdl '/Mutlak_Sapma'], ...
    'Position', [630 30 670 60]);

add_block([L 'Sources/Constant'], [mdl '/Tolerans_Siniri'], ...
    'Value', '2', 'Position', [630 110 690 140]);

add_block([L 'Logic and Bit Operations/Relational Operator'], ...
    [mdl '/Hata_Kiyaslama'], ...
    'Operator', '>', 'Position', [750 50 800 100]);

% --- 5. Ciktilar ve Kayit ---
add_block([L 'Sinks/Scope'], [mdl '/Scope_Grafik'], ...
    'NumInputPorts', '2', 'Position', [880 40 920 120]);

add_block([L 'Sinks/To Workspace'], [mdl '/Sapma_Kayit'], ...
    'VariableName', 'sapma_log', 'SaveFormat', 'Timeseries', ...
    'Position', [880 180 960 210]);

%% Blok Baglantilari
add_line(mdl, 'Kusur1_Basla/1',     'Kusur_Birlestir/1', 'autorouting', 'on');
add_line(mdl, 'Kusur1_Bitir/1',     'Kusur_Birlestir/2', 'autorouting', 'on');
add_line(mdl, 'Kusur2_Basla/1',     'Kusur_Birlestir/3', 'autorouting', 'on');
add_line(mdl, 'Kusur2_Bitir/1',     'Kusur_Birlestir/4', 'autorouting', 'on');

add_line(mdl, 'Taban_Derinlik/1',   'Kirli_Sensor_Add/1', 'autorouting', 'on');
add_line(mdl, 'Kusur_Birlestir/1',  'Kirli_Sensor_Add/2', 'autorouting', 'on');
add_line(mdl, 'Atolye_Titresimi/1', 'Kirli_Sensor_Add/3', 'autorouting', 'on');
add_line(mdl, 'Kirli_Sensor_Add/1', 'Filtre_TransferFcn/1', 'autorouting', 'on');

add_line(mdl, 'Z1_Referans/1',        'Anlik_Derinlik_Sub/1', 'autorouting', 'on');
add_line(mdl, 'Filtre_TransferFcn/1', 'Anlik_Derinlik_Sub/2', 'autorouting', 'on');

add_line(mdl, 'Anlik_Derinlik_Sub/1', 'Sapma_Hesabi_Sub/1', 'autorouting', 'on');
add_line(mdl, 'Ideal_Derinlik/1',     'Sapma_Hesabi_Sub/2', 'autorouting', 'on');

add_line(mdl, 'Sapma_Hesabi_Sub/1', 'Scope_Grafik/1', 'autorouting', 'on');
add_line(mdl, 'Sapma_Hesabi_Sub/1', 'Sapma_Kayit/1',  'autorouting', 'on');
add_line(mdl, 'Sapma_Hesabi_Sub/1', 'Mutlak_Sapma/1', 'autorouting', 'on');

add_line(mdl, 'Mutlak_Sapma/1',    'Hata_Kiyaslama/1', 'autorouting', 'on');
add_line(mdl, 'Tolerans_Siniri/1', 'Hata_Kiyaslama/2', 'autorouting', 'on');
add_line(mdl, 'Hata_Kiyaslama/1',  'Scope_Grafik/2',   'autorouting', 'on');

%% Scope Ayarlari (Veri kesilmesini onleme)
scopeBlk = [mdl '/Scope_Grafik'];
try
    cfg = get_param(scopeBlk, 'ScopeConfiguration');
    cfg.DataLoggingLimitDataPoints = false;
    cfg.TimeSpan = 'Auto';
catch
    % Eski surumler icin fallback
end

%% Calistir ve Kaydet
save_system(mdl, fullfile(pwd, [mdl '.slx']));
set_param(mdl, 'SimulationCommand', 'update');
fprintf('Model hatasiz kuruldu. Simule ediliyor...\n');
sim(mdl);
open_system(scopeBlk);
fprintf('Simulasyon tamamlandi ve Scope acildi!\n');