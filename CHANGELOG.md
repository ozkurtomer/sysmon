# Changelog

All notable changes are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/), versions follow [SemVer](https://semver.org/).

## [1.1.0] — 2026-11-20

### Added
- **Game-style HUD** popover (SwiftUI): segmented gauges for CPU, RAM, Disk and Battery
- Status banner (*All clear / Enemies nearby / Boss fight! / Low health!*), level & XP from uptime
- Top apps as **enemies** with a BOSS badge and a polite "quit app" button
- **Light / dark mode** support that follows the system automatically
- **English and Türkçe** UI, following the system language by default; manual override in ⚙︎ → Language
- App icon, "Star on GitHub" and "Report an idea" shortcuts
- Menu bar readout turns red under heavy load

### Changed
- Replaced the plain text menu with a native popover (`NSPopover` + SwiftUI)
- Process list is only fetched while the panel is open (idle ≈ 0.4% CPU)

## [1.0.0] — 2026-11-20

- Initial release: menu bar CPU / RAM readout with top processes
