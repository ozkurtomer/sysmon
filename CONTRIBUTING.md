# Contributing / Katkıda bulunma

**English** · [Türkçe aşağıda](#türkçe)

Thanks for wanting to help! SysMon is small on purpose, which makes it a friendly project to contribute to.

## Quick start

```bash
git clone https://github.com/ozkurtomer/sysmon.git
cd sysmon
./scripts/build.sh && open build/SysMon.app
```

Requires macOS 13+ and the Xcode Command Line Tools. No package manager, no dependencies.

## Project layout

| File | What it does |
| --- | --- |
| `Sources/Monitor.swift` | Reads CPU / RAM / disk / battery / processes; holds the observable model and demo data |
| `Sources/Views.swift` | The SwiftUI HUD (gauges, banner, enemies list) |
| `Sources/App.swift` | Menu bar item, popover, settings menu |
| `Sources/Strings.swift` | All UI text, English + Türkçe |
| `Sources/Snapshot.swift` | `--snapshot` mode that renders the real view for README media |
| `assets/`, `scripts/` | Icon, media generators, build script |

## Adding a language

1. Open `Sources/Strings.swift`, copy the `"en"` dictionary, translate the values.
2. Register the code in `Lang` and `Loc.code`, and add it to the language submenu in `App.swift`.
3. Run `./scripts/build.sh` and switch to it from ⚙︎ → Language.

## Guidelines

- **No third-party dependencies.** Apple frameworks only.
- **Stay light.** The app should idle near 0% CPU. Anything expensive must only run while the panel is open.
- **Respect light and dark mode.** Use semantic colors (`.primary`, `.secondary`, system tints), never hard-coded greys.
- **Every user-facing string goes through `t("key")`** and needs both English and Turkish text.
- **One concern per PR**, with a short description (screenshots welcome for UI changes).
- If you change the UI, regenerate the media: `pip install pillow && ./scripts/make-media.sh`.

## Pull request flow

1. Fork and create a branch (`feat/gpu-gauge`, `fix/battery-desktop`, …).
2. Make your change and run `./scripts/build.sh`.
3. Open a PR using the template. CI will build the app on macOS.

## Reporting bugs & ideas

Use the [issue templates](https://github.com/ozkurtomer/sysmon/issues/new/choose). For questions and open-ended ideas, [Discussions](https://github.com/ozkurtomer/sysmon/discussions) are a better home.

---

## Türkçe

Yardım etmek istediğin için teşekkürler! SysMon bilerek küçük tutuldu; bu da katkı vermeyi kolaylaştırır.

### Hızlı başlangıç

```bash
git clone https://github.com/ozkurtomer/sysmon.git
cd sysmon
./scripts/build.sh && open build/SysMon.app
```

macOS 13+ ve Xcode Command Line Tools gerekir. Paket yöneticisi ya da bağımlılık yok.

### Dil ekleme

1. `Sources/Strings.swift` dosyasında `"en"` sözlüğünü kopyala, değerleri çevir.
2. Dil kodunu `Lang` ve `Loc.code` içine ekle, `App.swift`'teki dil alt menüsüne yerleştir.
3. `./scripts/build.sh` ile derle, ⚙︎ → Dil menüsünden seç.

### Kurallar

- **Üçüncü parti bağımlılık yok.** Sadece Apple framework'leri.
- **Hafif kal.** Uygulama boştayken ~%0 CPU kullanmalı. Pahalı işler sadece panel açıkken çalışmalı.
- **Açık ve koyu temaya saygı göster.** Sabit gri yerine anlamsal renkler (`.primary`, `.secondary`, sistem tonları) kullan.
- **Kullanıcıya görünen her metin `t("anahtar")` üzerinden geçer** ve hem İngilizce hem Türkçe metin ister.
- **PR başına tek konu**, kısa açıklamayla (arayüz değişikliklerinde ekran görüntüsü çok iyi olur).
- Arayüzü değiştirdiysen medyayı yenile: `pip install pillow && ./scripts/make-media.sh`.

### Hata ve fikir bildirme

[Issue şablonlarını](https://github.com/ozkurtomer/sysmon/issues/new/choose) kullan. Sorular ve açık uçlu fikirler için [Discussions](https://github.com/ozkurtomer/sysmon/discussions) daha uygun.
