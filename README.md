# BizForce CRM Mobile (Flutter)

A Flutter app for **Android and iOS** recreating the exact screens of the
reference CET/mobile CRM app (mapped from 102 screenshots in `/ss`). It
targets all modern phone sizes and works in light and dark mode.

## What's implemented

- **Auth** — login (email/password), "Keep me signed in", Forgot password,
  social sign-in row (Google / Apple / Office 365), Sign in with OTP, Sign in
  with SAML, offline sign-in state.
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
  dark mode, call logging, **API Base URL editor**, app info, legal center.
- **Plus** — Inbox welcome, Actions hub, Map screen, Help center, compose email.

## Project layout

```
lib/
  main.dart                    App entry + theme + provider
  core/                        colors, config, theme, formatters
  data/                        models, mock data, ApiService (HTTP layer)
  state/app_state.dart         auth/session/dark mode/base URL state
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

## Wiring your backend

The app ships with realistic mock data behind a clean service layer. To plug
in your CRM API:

1. Put your endpoint in `lib/core/app_config.dart`
   (`apiBaseUrl`), or set it at runtime via **Settings → Connection → API Base URL**.
2. The HTTP wrapper `ApiService` (`lib/data/api_service.dart`) already handles
   GET/POST/PUT/DELETE, JSON, auth bearer tokens and errors.
3. Replace the `MockData.*()` calls in each screen with repository methods that
   call `ApiService`. Each list screen takes a `records: () => ...` function and
   a `tabFactory` — swap the mock call for a real fetch and state will update.

Example repository call:

```dart
final list = await appState.api.request('/modules/Leads',
    method: ApiMethod.get, query: {'view': 'MyLeads'});
```

Send the base URL and your endpoint list when ready and I'll wire every module
to the real API.