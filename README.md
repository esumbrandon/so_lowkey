# So-Lowkey

> *A quiet corner of the internet for people who'd rather connect slowly.*

**So-Lowkey** is a Flutter mobile application designed for introverts, neurodivergent individuals, and anyone who finds conventional social networking exhausting. It strips away social anxiety triggers — no read receipts, no typing indicators, no follower counts, no real names — and replaces them with intentional, low-pressure connections, async conversations, and ambient co-presence spaces.

---

## Philosophy

Most social apps are built around speed, volume, and visibility. So-Lowkey is built around the opposite values:

- **Slow over fast** — reply when you're ready, not when you're expected to
- **Depth over breadth** — a small number of meaningful connections beats a large network
- **Presence without pressure** — share a space with others without being obligated to interact
- **Privacy by default** — no real names, no public search indexing, no profile photos

---

## Features

###  Authentication
- **Sign in with Apple** and **Sign in with Google** via Supabase OAuth
- First-time users are routed through the onboarding wizard; returning users land directly in the Lounges
- Full **offline / dev mode**: the app runs entirely with mock data when no Supabase credentials are configured

### Onboarding (4-step wizard)
New users build their introvert profile through a guided, pressure-free setup:

| Step | What it sets up |
|------|----------------|
| 1 – **Your Quiet Corner** | Choose a pseudonymous **alias** (no real name required) |
| 2 – **Set Your Pacing** | Set your current **battery level** (`recharging / low / medium / full`) and expected **reply cadence** (`same day / few days / slow mail`) |
| 3 – **Skip the Small Talk** | Pick a **spark prompt** and write a real, depth-first answer shown on your discovery card |
| 4 – **Circle & Location** | Optionally add your **country, region, and city**, and select up to 5 **interest circles** (Tech, Books, Gaming, Art, Music, Nature, Film, Science, Food, Philosophy) |

###  Lounges (Parallel Play Rooms)
The centrepiece of the app. Lounges are ambient audio rooms for *parallel play* — the practice of being quietly present alongside others without direct interaction.

- Each lounge has a **themed ambient soundscape** (e.g. *Rainy Reading Nook*, *Midnight Coffee*, *Botanical Sanctuary*, *Starlit Terrace*)
- Audio **loops continuously** at a gentle volume while you're in the room
- A **volume toggle** mutes/unmutes the audio without leaving the room
- A live **presence list** shows who else is quietly in the room with you, along with their current status text (e.g. "Reading Haruki Murakami")
- Joining and leaving is tracked in real time via **Supabase Realtime** (or mock data in dev mode)
- No chat, no reactions — just company

###  Discovery
Browse discoverable users to find quiet companions who share your energy:

- Each **profile card** shows: alias, battery level icon, reply pace label, location badges, interest circle tags, and a **spark prompt answer** — a real piece of writing that replaces a generic bio
- Filter by **Country**, **Region/State**, or **Interest Circle** using animated filter chips
- Send a **"Quiet Hello"** connection request directly from a card — no message required to initiate

###  Connections & Async Chat
A two-tab inbox for managing your connections:

**Active tab**
- Lists all accepted connections with the last message preview and timestamp
- Tapping a connection opens the async **chat screen**
- Closed (gracefully exited) conversations are shown with a 🪷 spa icon and dimmed, read-only

**Pending tab**
- Incoming requests show **Accept** / **Decline** buttons with a confirmation dialog
- Outgoing requests show an "Awaiting reply" badge
- A numeric badge on the tab shows the count of incoming requests

###  Chat Screen
The async messaging experience:
- **No typing indicators, no read receipts** — intentionally omitted
- Messages show a soft timestamp but no delivery/read status
- Multi-line input field that grows up to 5 lines
- A **Graceful Exit** button (🪷) lets you close a conversation with a thoughtful farewell message, rather than ghosting

### ß Graceful Exit
A unique feature that lets you formally close a conversation with kindness. Triggering it sends a special exit message — visually distinct in the chat — that signals to the other person that the connection is being closed gently and intentionally.

---

## 🏗 Architecture

```
lib/
├── main.dart                          # App entry point, Supabase init, ProviderScope
├── core/
│   ├── constants/app_colors.dart      # Centralised colour palette
│   ├── mock/mock_data.dart            # Full offline mock dataset
│   ├── router/app_router.dart         # GoRouter config (auth guard + all routes)
│   ├── theme/app_theme.dart           # Material 3 dark theme, Plus Jakarta Sans
│   └── widgets/app_nav_menu.dart      # Dev-mode navigation bottom sheet
└── features/
    ├── auth/                          # Login screen + Supabase OAuth controller
    ├── onboarding/                    # 4-step profile wizard
    ├── lounges/                       # Lounge list, room screen, audio controller
    ├── discovery/                     # Profile browsing, filtering, connection requests
    ├── connections/                   # Connections inbox (active + pending tabs)
    └── chat/                          # Async messaging + graceful exit
```

**State management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) — providers for all async data, notifiers for local UI state.

**Navigation:** [GoRouter](https://pub.dev/packages/go_router) with auth-aware redirects. Unauthenticated users are redirected to `/login`; new users (no profile row) are redirected to `/onboarding`.

**Backend:** [Supabase](https://supabase.com/) — authentication (OAuth), PostgreSQL database, and Realtime streams for lounge presence.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter (Material 3) |
| Language | Dart 3.x |
| State Management | Riverpod 2 |
| Navigation | GoRouter 14 |
| Backend / Auth | Supabase (PostgreSQL + Realtime + OAuth) |
| Audio | just_audio |
| Typography | Plus Jakarta Sans (via google_fonts) |
| Date Formatting | intl |

---

## Database Schema (Supabase)

| Table | Purpose |
|-------|---------|
| `profiles` | User profile: alias, battery_status, reply_pace, spark prompt/answer, location, circles, is_discoverable |
| `lounges` | Lounge definitions: name, description, icon_name, ambient_audio_url |
| `lounge_presences` | Real-time: who is currently in which lounge + their status_text |
| `connections` | Connection state between two users: pending / active / closed |
| `messages` | Chat messages: connection_id, sender_id, content, is_graceful_exit |

---

##  Getting Started

### Prerequisites
- Flutter SDK `^3.11.5`
- Dart SDK `^3.11.5`
- A [Supabase](https://supabase.com/) project (optional — the app runs fully in offline dev mode without one)

### Installation

```bash
git clone <repo-url>
cd solokey
flutter pub get
flutter run
```

### Configuring Supabase (optional)

Open [`lib/main.dart`](lib/main.dart) and replace the placeholder values:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
```

When these remain as their placeholder defaults, the app automatically enters **offline dev mode** — all screens are populated with rich mock data and full navigation is available without login.

### Running in Dev Mode (no Supabase)

No configuration is needed. Run `flutter run` and the app starts directly on the Lounges screen with mock users, lounges, connections, and chat history pre-populated.

A **dev screen switcher** button (`⊞`) is available on most screens to jump between any screen instantly.

---

##  Design Language

So-Lowkey uses a hand-curated warm dark palette:

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#181A1F` | App background |
| `surface` | `#22252C` | Cards, inputs |
| `surfaceElevated` | `#2C3039` | Modals, elevated cards |
| `biscuit` | `#D4A373` | Primary accent, CTAs |
| `sage` | `#CCD5AE` | Secondary accent, badges |
| `terracotta` | `#E07A5F` | Destructive actions, errors |
| `duskLavender` | `#8D99AE` | Graceful exit, tertiary UI |
| `textPrimary` | `#E9ECEF` | Body text |
| `textMuted` | `#ADB5BD` | Placeholder, subtitles |

Typography is set in **Plus Jakarta Sans** throughout.

---

## Screens & Routes

| Route | Screen | Auth Required |
|-------|--------|---------------|
| `/login` | Login / landing | No |
| `/onboarding` | Profile setup wizard | Yes (new users only) |
| `/lounges` | Lounge list | Yes |
| `/lounges → push` | Lounge room (ambient + presence) | Yes |
| `/discovery` | Browse & connect | Yes |
| `/connections` | Inbox (active + pending) | Yes |
| `/chat/:connectionId` | Async chat thread | Yes |

---

##  Privacy Principles

- **No real names** — users choose a pseudonymous alias
- **No profile photos** — initials-only avatars
- **No public indexing** — discovery is opt-in (`is_discoverable` flag)
- **No read receipts or typing indicators** — messaging is fully async
- **Location is optional and coarse** — city/region/country, never GPS coordinates
- **Max active chats** — users set their own limit to prevent social overwhelm
