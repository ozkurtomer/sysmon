<div align="center">

# SysMon

**Mac'in için sessiz, küçük bir menü çubuğu izleyicisi.**
CPU ve RAM tek bakışta — neyin yorduğu da tek tık ötede.

<img src="assets/demo.gif" alt="SysMon menü çubuğu açılır menüsü (hareketli çizim)" width="460">

<br>

[![Build](https://github.com/ozkurtomer/sysmon/actions/workflows/build.yml/badge.svg)](https://github.com/ozkurtomer/sysmon/actions/workflows/build.yml)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-2b303c?logo=apple&logoColor=white)
![Universal](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-7ecdb8)
[![License: MIT](https://img.shields.io/badge/license-MIT-a6aebe)](LICENSE)

[English](README.md)

</div>

---

## Neden

Etkinlik Monitörü harika ama koca bir pencere. SysMon menü çubuğunda durur, kendisi neredeyse hiç kaynak harcamaz ve tek soruya hızlı cevap verir: *Mac'imi şu an ne yavaşlatıyor?*

## Özellikler

- **Menü çubuğunda canlı değerler** — `CPU 22%  RAM 72%`, 2 saniyede bir yenilenir
- CPU ve belleğe göre **en çok kaynak kullanan 5 işlem**
- **Yerel ve minik** — tek Swift dosyası, bağımlılık yok, Dock'ta simge yok
- **Universal** — Apple Silicon ve Intel
- **Girişte otomatik başlatma** — menüde tek bir seçenek
- Gerekirse tek tıkla **Etkinlik Monitörü**

## Kurulum

1. [Son sürümden](https://github.com/ozkurtomer/sysmon/releases/latest) **`SysMon.dmg`** dosyasını indir.
2. Aç ve **SysMon**'u **Applications** klasörüne sürükle.
3. Sadece ilk açılışta: **SysMon'a sağ tık → Aç → Aç**.

> Uygulama ad-hoc imzalı, notarize edilmemiş; bu yüzden macOS bir kez onay ister. Sonrasında normal açılır.

## Kaynaktan derleme

macOS 13+ ve Xcode Command Line Tools (`xcode-select --install`) gerekir.

```bash
git clone https://github.com/ozkurtomer/sysmon.git
cd sysmon
./scripts/build.sh
open build/SysMon.app
```

## Gizlilik

Her şey yerelde çalışır. SysMon ağ bağlantısı kurmaz, veri toplamaz.

## Katkı

Issue ve pull request'ler memnuniyetle karşılanır — bkz. [CONTRIBUTING.md](CONTRIBUTING.md).

## Lisans

[MIT](LICENSE) © Ömer Özkurt
