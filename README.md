# National Grid: Live

A native iOS app showing where Great Britain's electricity comes from, in real
time — generation mix, demand, carbon intensity, price and interconnector flows.
A SwiftUI reimagining of Kate Morley's [grid.iamkate.com](https://grid.iamkate.com/)
(original released under CC0).

## Screens

- **Live** — the current generation mix as an expandable card: a headline
  GW / "% of demand", a generation-mix visualisation (stacked bars / donut /
  none, chosen in Settings), and tappable Fossil / Renewables / Other groups that
  disclose their individual sources, plus Interconnectors and Storage. A KPI strip
  shows time, price, emissions and the demand = generation + transfers balance.
- **Historic** — the same breakdown averaged over **Past day / week / year /
  all time**, with trend charts (price, emissions, demand, generation by source,
  transfers by interconnector).
- **About** — the energy transition story, data sources, and attribution.

## Data

All sources are public and key-less.

- **Live (last 24 h)** is fetched directly on-device and combined by
  `LiveDataAggregator`:
  - **Elexon BMRS** `FUELINST` — generation by fuel + interconnector flows
  - **Elexon BMRS** `market-index` — price (£/MWh)
  - **Carbon Intensity API** — emissions (gCO₂/kWh)
  - **NESO Data Portal** — embedded wind & solar
- **Historic (Past year / All time)** is served as a pre-aggregated
  `snapshot.json` from the companion repo
  **[national-grid-live-tools](https://github.com/jameswestgate/national-grid-live-tools)**
  (a daily GitHub Action → GitHub Pages). The app fetches it with conditional
  GETs (`ETag` → 304) and caches the last-known-good copy for offline use.

Model: `gas = CCGT+OCGT+OIL`, `wind = transmission + embedded`, `solar = embedded`,
France = IFA+IFA2+ElecLink, etc.; `demand = generation + transfers`. Percentages
are share of demand. The Past-year aggregates match grid.iamkate.com within ~0.3 GW.

## Design

iOS 26, system fonts and SF Symbols throughout. Card-based layout with headings
*inside* cards, a Health-style colour wash behind each screen, native large
titles, and a liquid-glass tab bar. The generation-mix palette is taken verbatim
from the original site's CSS so the colours read identically. Universal (iPhone +
iPad), light/dark, with light/dark/tinted app-icon variants.

## Build & run

Open `national grid live.xcodeproj` in Xcode (iOS 26 SDK) and run on an iPhone
simulator or device. No API keys or configuration required. Data sources are
selected in `Config/AppConfig.swift` (`live: .real`, `snapshot: .url(...)`); a
`.mock` mode powers previews and offline development.

## Project layout

```
national grid live/
  Views/        screens + reusable card/row components
  Networking/   API clients, LiveDataAggregator, caching, snapshot provider
  Models/       LiveGrid, TimeSeries, Snapshot, FuelType, …
  Store/        GridStore, providers, refresh scheduler
  Theme/        Palette, ScreenGradient
  Config/       AppConfig, AppSettings
```

## Credits

Inspired by **National Grid: Live** by Kate Morley (grid.iamkate.com), released
under CC0 1.0. Data © Elexon (BMRS), National Grid ESO & University of Oxford
(Carbon Intensity, CC BY 4.0), and NESO (Open Licence).
