# Monte Carlo Doğrulama – Notlar

V-ağzı kalite kontrol robotu için, rastgele kusurlar üretip ölçüm zincirinin
kusuru ne kadar iyi bulduğunu ölçen Monte Carlo çalışması.

> **Durum:** Kod yazıldı, **MATLAB'da henüz çalıştırılmadı.** İlk çalıştıran
> kişi çıktıyı kontrol etsin (bkz. "Çalıştırma").

## Dosyalar

| Dosya | Görev |
|---|---|
| `monte_carlo/mc_params.m` | Tüm parametreler, her birinin yanında kaynağı |
| `monte_carlo/mc_simulate_run.m` | Tek tarama: kusur üret → sensör zinciri → filtre → alarm → metrikler |
| `monte_carlo/run_monte_carlo.m` | 1000 koşu + duyarlılık taraması + özet + grafikler |

Mevcut `vkaynak_qc_robot.m` / `untitled.m` / `V_Kaynak_QC_Robot.slx`
**değiştirilmedi.**

## Çalıştırma

```matlab
cd monte_carlo
run_monte_carlo
```

Çıktılar `monte_carlo/results/` altına yazılır (`mc_ozet.png`,
`mc_duyarlilik.png`, `mc_results.mat`; git'e girmez). Toplam 5000 koşu
(1 ana + 4 duyarlılık × 1000) var. Tek koşu 13 001 örnek olduğundan
kısa sürmesi beklenir, ama süre ölçülmedi.

## Yöntem

- **Koşu:** 650 s, `dt = 0.05 s`, robot 20 mm/s. Her koşuda 0–5 kusur
  (U{0..5}), derinlik 0.5–5 mm, süre 5–40 s (100–800 mm), kusurlar
  birbiriyle çakışmaz (aralarında ≥10 s boşluk).
- **Sinyal zinciri:** Simulink modeliyle aynı:
  `sensör = 50 + ölçülen_yer_değiştirme` → `1/(0.1s+1)` (tam
  ayrıklaştırma) → `derinlik = 80 − filtre` → `sapma = derinlik − 30` →
  `|sapma| > 2` ise alarm.
- **Kusur işareti:** Fazla dalma → sensör okuması azalır (modeldeki
  `+ − +` toplamla aynı).
- **Gerçek (ground truth):** `defect > 2 mm` ise gerçekten tolerans dışı.

## Parametre tablosu

`[DS]` datasheet, `[HES]` datasheet'ten hesap, `[VAR]` **varsayım**.

| Bileşen | Parametre | Değer | Kaynak |
|---|---|---|---|
| LVDT AX/5/S | Ölçüm aralığı | ±5 mm | [DS] katalog sf. 15 |
| | Doğrusallık | %0.5 okuma (veya 5 µm, hangisi büyükse) | [DS] |
| | Tekrarlanabilirlik | tipik 0.07 µm | [DS] |
| | Sıcaklık katsayısı | 0.01 %FS/°C | [DS] |
| | Hassasiyet | 105 mV/V/mm; tam skala 1575 mV | [DS] link tablosu |
| OD5 MK II | Çıkış gürültüsü | < 1 mV rms ≈ 3.2 µm rms | [DS] sf. 24, [HES] |
| | Doğrusallık | < %0.1 FRO | [DS] |
| | Kazanç/ofset sıcaklık | < %0.01 FRO/°C | [DS] |
| | Bant genişliği | 500 Hz (−3 dB) | [DS] |
| SICK DBV50E-22ELA1000 | Çözünürlük | 0.2 mm/darbe (1000 P/R, 200 mm çevre) | [DS] |
| | Hata sınırı | ±4 mm/m (tekerlek + yüzeye bağlı) | [DS] |
| | Adım sapması | ±18° / P/R (≈ ±%5 darbe) | [DS] |
| Mekanik / yüzey gürültüsü | σ | 0.05–0.5 mm (ana koşuda koşu başına rastgele) | **[VAR]** |
| Sıcaklık sapması | ΔT | ±20 °C | **[VAR]** |
| Kusur süresi, aralığı | 5–40 s, ≥10 s | | **[VAR]** |
| Robot hızı | 20 mm/s sabit, tekerlek kayması yok | | **[VAR]** |

Sistematik hatalar (doğrusallık, sıcaklık, enkoder ölçeği) datasheet'teki
**maksimum** değerler içinde koşu başına rastgele çekilir; gerçek dağılımı
bilinmiyor, uniform varsayıldı.

## Metrikler

- **Tespit oranı:** Tolerans dışı (>2 mm) bir kusurun penceresinde
  (`[başlangıç, bitiş+1 s]`) en az bir alarm örneği olması.
- **Tolerans-içi alarm oranı:** ≤2 mm kusurlar için aynı ölçü. Doğru
  davranış 0'dır; eşiğe yakın kusurlarda gürültüyle alarm vermesi beklenir.
- **Yanlış alarm:** Hiçbir kusur penceresiyle çakışmayan alarm bölümü
  (tarama başına sayı).
- **Tespit gecikmesi:** İlk alarm zamanı − kusur başlangıcı.
- **Derinlik ölçüm hatası:** Kusur platosunda (başlangıç+1 s … bitiş)
  ortalama ölçülen sapma − gerçek derinlik.
- **Konum hatası:** Alarm anındaki enkoder konumu − gerçek kusur
  başlangıç konumu (enkoder ölçek hatası + filtre gecikmesini içerir).
- **Duyarlılık taraması:** Mekanik gürültü σ = 0.05 / 0.15 / 0.3 / 0.5 mm
  için aynı metrikler (σ = 0.3 mm ≈ mevcut Simulink modelindeki gürültü).

## Dikkat edilmesi gerekenler

1. **Bu bir model-içi doğrulama.** Kusuru biz üretiyoruz, aynı varsayımlarla
   ölçüyoruz. Gerçek sensör verisiyle kalibre edilmedi. "Şu varsayımlar
   altında tasarım şu performansı veriyor" denebilir, "gerçek doğruluk şudur"
   denemez.
2. **Elektriksel hatalar mm altında.** Sensör gürültüsü ≈ 3 µm,
   doğrusallık on µm mertebesinde; 2 mm toleransın çok altında. Sonucu
   asıl **mekanik/yüzey gürültüsü varsayımı** belirler ve bunun datasheet'i
   yok. Bu yüzden duyarlılık taraması var; tek bir sayıya güvenmeyin.
3. **Mevcut Simulink modelindeki gürültü** (`Cov = 0.001`, `Ts = 0.01`)
   σ ≈ 0.32 mm eder, yani gerçek sensör gürültüsünün (~3 µm) yaklaşık 100
   katı. O blok "sensör gürültüsü" değil, "mekanik/yüzey" varsayımı olarak
   okunmalı. Modele dokunulmadı.
4. **Menzil:** AX/5/S ±5 mm aralıklı. 30 mm'lik V-ağzı derinliği tek probla
   doğrudan ölçülemez; probun nominalden sapmayı ölçtüğü diferansiyel bir
   yerleşim gerekir. Kodda probun gördüğü yer değiştirme ±5 mm'e kırpılır;
   5 mm'lik kusur aralığın sınırındadır.
5. **Konum hatası:** ±4 mm/m ölçek hatası 13 m'de en kötü durumda yaklaşık
   ±52 mm eder. Tekerlek kayması modellenmedi (veri yok).
6. **Mekanik gürültü örnekleme adımına bağlı.** σ, `dt = 0.05 s`
   örneklemesinde beyaz gürültü olarak tanımlı; adım değişirse filtre sonrası
   etkin gürültü değişir.
7. Alarm ham haliyle sayılır (debounce yok); eşik civarında kısa alarmlar
   ayrı bölüm olarak görünebilir.

## Açık işler

- [ ] MATLAB'da çalıştırıp çıktıları kontrol et.
- [ ] Mekanik gürültü σ için gerçek ölçüm veya ek kaynak.
- [ ] İstenirse Simulink modelini aynı parametre tablosuna taşı.
- [ ] Debounce / minimum alarm süresi kararı.
