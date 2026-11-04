# V-Bevel Quality Control & Inspection Robot

[![MATLAB](https://img.shields.io/badge/MATLAB-R2026b-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Simulink](https://img.shields.io/badge/Simulink-Enabled-orange.svg)](https://www.mathworks.com/products/simulink.html)
[![Validation](https://img.shields.io/badge/Monte%20Carlo-5000%20Runs%20Verified-brightgreen.svg)](#2-monte-carlo-stochastic-validation-5000-runs)
[![Detection Rate](https://img.shields.io/badge/Detection%20Rate-100%25-success.svg)](#2-monte-carlo-stochastic-validation-5000-runs)
[![Institution](https://img.shields.io/badge/%C4%B0T%C3%9C-Mechanical%20Engineering-darkred.svg)](https://makina.itu.edu.tr/en)

> [!NOTE]
> **Academic Notice:** This project was developed as an undergraduate engineering capstone study for the **Mechatronic System Design** course within the **Mechanical Engineering Undergraduate Program** at **Istanbul Technical University (ITU)**.

This repository hosts the dynamic Simulink simulation model and stochastic Monte Carlo validation framework for an autonomous **V-Bevel Quality Control (QC) Robot** designed to inspect groove depth and dimensional profile tolerances on thick structural steel plates (S335, $80\text{ mm}$ thickness) along a $13\text{ m}$ weld seam.

---

## 📌 Project Overview & Working Principle

The inspection robot traverses the pre-machined V-groove at a constant velocity of $v = 20\text{ mm/s}$ ($13\text{ meters} = 650\text{ seconds}$). An LVDT contact displacement probe coupled with a high-resolution measuring wheel encoder records the continuous longitudinal depth profile.

* **Nominal Geometry:** Upper reference plate surface $Z_1 = 80\text{ mm}$, sensor fixture baseline $50\text{ mm}$, nominal V-groove depth $30\text{ mm}$.
* **Tolerance Boundary:** $\pm 2.0\text{ mm}$ depth deviation from the nominal $30\text{ mm}$ profile is defined as the acceptable tolerance limit. Any excursion beyond this threshold triggers a real-time defect alarm.
* **Signal Conditioning & Filtering:** Workshop floor vibrations, mechanical chatter, and surface roughness are filtered via a first-order low-pass transfer function:
  $$G(s) = \frac{1}{0.1s + 1}$$

```
[ Solartron LVDT Probe ] ---> [ Noise / Vibration ] ---> [ Low-Pass Filter (0.1s) ]
                                                                     |
[ SICK Wheel Encoder ] ----------------------------------> [ Differential Depth Estimation ]
                                                                     |
                                                           [ Tolerance Evaluator (|e| > 2mm) ]
                                                                     |
                                                               [ ALARM / LOG ]
```

---

## 🛠️ Hardware & Sensor Specifications

Sensor parameters implemented in the numerical model are derived directly from manufacturer datasheets and technical link tables:

| Component | Model / Type | Technical Specifications | Source |
|---|---|---|---|
| **Contact Displacement Probe** | Solartron Metrology AX/5/S | $\pm 5\text{ mm}$ stroke, $0.5\%$ reading linearity, $0.07\text{ }\mu\text{m}$ repeatability | Catalog p. 15 |
| **Signal Conditioning Unit** | Solartron OD5 MK II | $500\text{ Hz}$ bandwidth ($-3\text{ dB}$), $<1\text{ mV rms}$ output noise ($\approx 3.2\text{ }\mu\text{m}$ elec.) | Manual p. 24 |
| **Position Encoder** | SICK DBV50E-22ELA1000 | Measuring wheel encoder, $0.2\text{ mm/pulse}$ ($1000\text{ P/R}$), $\pm 4\text{ mm/m}$ scale error limit | Datasheet pp. 2–3 |
| **Traverse Drive System** | Autonomous Carriage | $20\text{ mm/s}$ constant velocity, $13\text{ m}$ continuous single-pass scan | Design Spec |

---

## 📊 Simulation Outputs & Performance Metrics

### 1. Simulink Dynamic Inspection (`V_Kaynak_QC_Robot.slx`)
The baseline dynamic model evaluates a full 650-second plate scan containing two localized excessive penetration defects ($3.5\text{ mm}$ depth deviation) located at intervals $100–120\text{ s}$ and $350–380\text{ s}$:
* **Defect 1 (100–120 s):** $3.508\text{ mm}$ measured deviation $\rightarrow$ **DETECTED [ALARM TRIGGERED]**
* **Defect 2 (350–380 s):** $3.499\text{ mm}$ measured deviation $\rightarrow$ **DETECTED [ALARM TRIGGERED]**
* **Baseline Filtered Noise:** $\pm 0.069\text{ mm}$ standard deviation (retains steady-state reading safely within tolerance limits).

### 2. Monte Carlo Stochastic Validation (5000 Runs)
To evaluate the inspection system under realistic manufacturing conditions, a comprehensive Monte Carlo campaign ($1000$ baseline runs $+ 4 \times 1000$ sensitivity sweeps) was conducted. Each run synthesizes random defect counts ($0–5$ defects/plate), random defect locations along the $13\text{ m}$ plate, durations ($5–40\text{ s}$, corresponding to $100–800\text{ mm}$ length), depths ($0.5–5.0\text{ mm}$), temperature drift ($\pm 20^\circ\text{C}$), and mechanical contact noise:

* **Out-of-Tolerance Defect Detection ($>2.0\text{ mm}$):** **100.00%** ($1660 / 1660$ defects accurately identified)
* **False Alarm Rate in Defect-Free Zones:** **0.000 episodes/scan** (zero false rejections on clean bevel sections)
* **Mean Detection Latency:** **$0.12\text{ s}$** (consistent with the $\tau = 0.1\text{ s}$ filter time constant)
* **Plateau Depth Measurement Error:** Mean **$-5.7\text{ }\mu\text{m}$**, standard deviation $29.0\text{ }\mu\text{m}$
* **Defect Localization Error (Encoder):** Mean **$2.1\text{ mm}$**, standard deviation $16.9\text{ mm}$ (well within the $\pm 52\text{ mm}$ cumulative limit over $13\text{ m}$)

#### Validation Distributions
![Monte Carlo Validation Summary](docs/assets/mc_ozet.png)

#### Mechanical Vibration Sensitivity Sweep
Even as workshop vibration and bevel surface roughness increase ten-fold from $\sigma = 0.05\text{ mm}$ to $\sigma = 0.50\text{ mm}$, the robot maintains a **100.00%** detection rate for all out-of-tolerance weld preparation defects:
![Mechanical Vibration Sensitivity Curve](docs/assets/mc_duyarlilik.png)

---

## 📚 Applicable Standards & Engineering References

The mechanical tolerances, defect criteria, and measurement decision rules are established in accordance with the following international standards:

### 1. Welding & Joint Preparation Standards
* **ISO 9692-1:** *Welding and allied processes — Types of joint preparation — Part 1: Manual metal arc welding, gas-shielded metal arc welding, gas welding, TIG welding and beam welding of steels.*  
  $\rightarrow$ Governs nominal V-groove bevel angles, root faces, root gap geometries, and dimensional tolerances.
* **ISO 5817:** *Welding — Fusion-welded joints in steel, nickel, titanium and their alloys — Quality levels for imperfections.*  
  $\rightarrow$ Defines defect acceptance boundaries and geometric deviation limits (Quality levels B and C).
* **ISO 17637:** *Non-destructive testing of welds — Visual testing of fusion-welded joints.*  
  $\rightarrow$ Dimensional inspection methodologies for pre-weld and post-weld joint assessment.

### 2. Structural Materials Standards
* **EN 10025-2:** *Hot rolled products of structural steels — Part 2: Technical delivery conditions for non-alloy structural steels.*  
  $\rightarrow$ Specifies mechanical properties and dimensional tolerances for structural S335 / S355 steel grade plates.

### 3. Metrology & Decision Rule Standards
* **ISO 14253-1:** *Geometrical product specifications (GPS) — Inspection by measurement of workpieces and measuring equipment — Part 1: Decision rules for verifying conformity or nonconformity with specifications.*  
  $\rightarrow$ Defines statistical decision rules under measurement uncertainty for evaluating in-tolerance versus out-of-tolerance states.

### 4. Sensor & Equipment Technical Documentation
* **Solartron Metrology:** *Analogue Gauging Probes & Signal Conditioning Units Technical Specifications (AX/5/S, OD5 MK II).*
* **SICK Sensor Intelligence:** *DBV50 Core Measuring Wheel Encoders Technical Documentation (DBV50E-22ELA1000).*

---

## 📁 Repository Structure

```text
v-bevel-inspection-robot/
├── main.m                    # Master execution script (Simulink simulation + Monte Carlo)
├── V_Kaynak_QC_Robot.slx      # Simulink block diagram model
├── vkaynak_qc_robot.m        # Model generation script
├── docs/                     # Technical documentation and graphical assets
│   ├── MONTE_CARLO_NOTLAR.md # Detailed mathematical background and assumptions
│   └── assets/               # High-resolution validation figures
└── monte_carlo/              # Modular stochastic simulation library
    ├── mc_params.m           # Nominal system parameters
    ├── mc_simulate_run.m     # Single-run simulation engine
    └── run_monte_carlo.m     # Standalone Monte Carlo runner
```

---

## ⚙️ System Requirements

* **MATLAB & Simulink:** R2020a or later (verified on MATLAB R2026b).
* Standard MATLAB and Simulink installations; no specialized external toolboxes are required.
