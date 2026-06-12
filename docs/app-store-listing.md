# App Store listing - National Grid: Live

UK-only release. Primary language: English (UK). British spelling throughout.

---

## App name  (max 30)
```
National Grid: Live
```
(19 chars)

## Subtitle  (max 30)
```
Live GB electricity & carbon
```
(28 chars)

## Promotional text  (max 170 - editable any time without review)
```
See how Great Britain is powered right now: the live mix of gas, wind, solar and nuclear, with carbon intensity, demand and prices - updated every few minutes.
```

## Description  (max 4000)
```
National Grid: Live is an independent app that displays publicly available open data about Great Britain’s electricity grid. It is not affiliated with, endorsed by, or connected to National Grid plc, the National Energy System Operator (NESO), Elexon, or any government entity, and it does not represent or provide any government service.

All data comes from official, publicly available open sources:
• Elexon Insights (BMRS) - https://bmrs.elexon.co.uk
• National Energy System Operator (NESO) Data Portal - https://www.neso.energy/data-portal
• Carbon Intensity API, by NESO and the University of Oxford - https://carbonintensity.org.uk

National Grid: Live shows you how Great Britain’s electricity is being generated right now - and how clean it is.

Open the app to see the live generation mix at a glance: how much power is coming from gas, wind, solar, nuclear, hydro, biomass and storage, alongside the current demand, carbon intensity and wholesale price. Everything refreshes automatically as new readings are published.

LIVE
• The current generation mix as a clear bar or donut chart
• Demand = generation + transfers, balanced the way the grid actually works
• Carbon intensity and market price for the latest period
• Imports and exports across the interconnectors to France, Norway, Belgium, Denmark, Ireland and the Netherlands
• Pumped-storage and battery storage

HISTORIC
• Past day, week, year and all-time views
• Trend graphs for price, emissions, demand, generation and transfers
• Tap any point on a graph to read the exact values

DESIGNED FOR iPHONE
• A native interface for iPhone
• Home Screen widgets: the live generation mix and interconnector flows, in colour, in two sizes
• Lock Screen widgets: pick demand, the live generation mix, or a minimal summary with demand, price, carbon and the top sources
• Optional alerts for high or low carbon intensity and high, low or negative prices - checked periodically, at most one of each per day
• Light and dark appearance
• Choose a bar chart or donut, or hide it

PRIVACY
National Grid: Live collects no personal data, has no accounts, and contains no advertising or tracking of any kind.

DATA SOURCES
The app uses publicly available open data from the Elexon Insights Solution, the National Energy System Operator (NESO) Data Portal, and the Carbon Intensity API (a project by NESO and the University of Oxford Department of Computer Science). Contains BMRS data © Elexon Limited copyright and database right 2026.

National Grid: Live is an independent project and is not affiliated with National Grid plc, NESO or Elexon.
```

## Keywords  (max 100 - comma separated, no spaces between words is most efficient)
```
electricity,energy,grid,power,carbon,emissions,wind,solar,renewable,nuclear,gas,demand,kwh
```
(90 chars. "National Grid" / "Live" omitted - already indexed from the title.)

## URLs  (hosted on the main repo's GitHub Pages, from /docs)
- **Privacy Policy URL:** https://jameswestgate.github.io/national-grid-live/privacy.html
- **Support URL:** https://jameswestgate.github.io/national-grid-live/support.html  _(directs to GitHub issues; no email by choice)_
- **Marketing URL:** _(optional)_ - grid.iamkate.com is Kate Morley's site, NOT ours - do not use it; leave blank or point to your own page

⚠️ Both pages link to `github.com/jameswestgate/national-grid-live/issues` - that repo **must be public** or the links 404.
⚠️ Enable Pages on `national-grid-live`: Settings → Pages → Source "Deploy from a branch" → `main` / `/docs`. After that, every push to main auto-deploys (GitHub's built-in pages-build-deployment; no workflow needed). NB this serves the whole `docs/` folder publicly (incl. this listing .md + screenshots) - fine, but be aware.

## Categories
- **Primary:** Utilities  _(matches `LSApplicationCategoryType` in the build)_
- **Secondary:** Weather  _(optional; News is an alternative)_

## Age rating
- **4+** - no objectionable content; answer "None" to every content-descriptor question.

## App Privacy (nutrition label)
- **Data collection: No** - "Data Not Collected". This is the entire answer; nothing else to fill.

## Availability
- **United Kingdom only.**

## Export compliance
- Already declared in the build: `ITSAppUsesNonExemptEncryption = NO` (standard HTTPS only) - no extra paperwork.

## What's New (v1.4)
```
Initial release, with Home Screen and Lock Screen widgets and optional price and carbon alerts.
```

## Notes for App Review  (App Store Connect → App Review Information → Notes)
```
National Grid: Live is an independent app that visualises publicly available open
data about Great Britain's electricity grid (from Elexon, NESO and the Carbon
Intensity API). It requires no account or login, collects no personal data, and
needs no special configuration to review - just launch and the live data loads.

Native functionality beyond the in-app charts:
- Two Home Screen widgets (small and medium sizes): the live generation mix and
  interconnector import/export flows, colour-coded with legends. Add via
  long-press on the Home Screen > Edit > Add Widget > National Grid: Live.
- Three Lock Screen widgets (Demand, Generation mix, Live Minimal). Add via
  long-press on the Lock Screen > Customise > tap the widget area.
- Opt-in local notifications (Settings > Notifications in the app): alerts for
  high/low carbon intensity and high/low/negative wholesale prices, evaluated on
  refresh and via background app refresh, at most one of each type per day.
- Offline support: the last readings are cached and shown immediately on launch.
- Interactive native charts (tap segments and graph points to inspect values).
```

---

### ⚠️ Before submitting - still your action
- Apple Developer Program enrolment + create the app record in App Store Connect
- Deploy the tools-repo Pages so privacy.html + support.html are live; ensure the `national-grid-live` repo is **public** (issues links)
- Fill **App Review Information → Contact** (private reviewer contact: name/phone/email - always required, separate from the public no-email support page)
- Confirm distribution signing (automatic signing in Xcode once enrolled)
