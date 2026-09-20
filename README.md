# BizForce CRM Mobile (Flutter)

A Flutter app for **Android and iOS** recreating the exact screens of the
reference CET/mobile CRM app (mapped from 102 screenshots in `/ss`). It
targets all modern phone sizes and works in light and dark mode.

## What's implemented

- **Auth** — login (email/password), "Keep me signed in", Forgot password,
  secure email/password authentication backed by the production API.
- **Home shell** — bottom navigation (Dashboard / Leads / Tasks / Calendar / More)
  and a module drawer with all groups: Favourites, SALES, MARKETING, Projects,
  INVENTORY, HELP DESK, Others (+ user footer and Sign Out).
- **Dashboard** — greeting, Map & Scan Business Card, Quick Create
  (+ Lead / Contact / Task / Meeting), Overview (Revenue, Leads, Open Tickets,
  Pipeline), Pipeline stages, Today's agenda.
- **Record modules (Leads, Contacts, Tasks, Events, Documents, Quotes, Deals,
  Products, Invoices, Employees, Payments, Organizations, Projects, etc.)** with:
  - list screen (search, empty state "There are no ...", status chips, FAB),
  - record detail with **One View / Activity / Details / Related** tabs,
  - create forms with section tabs and labeled fields,
  - status pickers, assigned-to groups, activity-type pickers,
  - business card scanner flow (Front/Back, camera/gallery sheet),
  - month calendar + day agenda + event creation,
  - task timelog with Pause/Resume/Stop,
  - quote list with printable-style preview tab.
- **Settings** — push notifications, sync/offline storage, auto-sync interval,
  dark mode, call logging, app info, legal center.
- **Plus** — Inbox welcome, Actions hub, Map screen, Help center, compose email.

## Project layout

```
lib/
  main.dart                    App entry + theme + provider
  core/                        colors, config, theme, formatters
  data/                        models and ApiService (HTTP layer)
  state/app_state.dart         auth/session/dark mode state
  widgets/                     shared widgets (detail tabs, forms, chips…)
  screens/                     one file per screen/flow
ss/                            reference screenshots you provided
```

## Run it

```bash
flutter pub get
flutter run          # select an attached device/emulator
```

Build production binaries on your machine:

```bash
flutter build apk --release                  # Android
flutter build appbundle --release            # Android (Play Store)
flutter build ipa --release                  # iOS (requires macOS + Xcode)
```

## Backend

The app uses the fixed production endpoint `https://bizforce-crm.online/api`.
The endpoint is intentionally not displayed or editable in Settings.
`ApiService` handles authenticated GET/POST/PUT/PATCH/DELETE requests, JSON,
bearer tokens, timeouts, errors, and empty API responses.
