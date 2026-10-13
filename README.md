# Whisper 💬

> 🇬🇧 English · [🇪🇸 Español](#-español)

A real-time messaging app for Android, built with **Flutter**. Messages are delivered over **WebSockets**. The app also covers the full account flow: registration, email verification, friends and profile management.

## Features

- 🔐 Sign up, log in and verify the account by email code. Cookie-based sessions refresh automatically.
- 💬 Real-time 1:1 chat over WebSockets (`web_socket_channel`)
- 👥 Discover people, send and accept friend requests, manage friends
- 🖼️ Profile editing with avatar upload and email change
- 🎨 Custom theme with Google Fonts and swipe actions on chat tiles

## Tech stack

| Layer | Tools |
|---|---|
| UI / navigation | Flutter, `go_router`, `flutter_slidable` |
| Networking | `dio` + `dio_cookie_manager`, `web_socket_channel` |
| State | Controllers per feature (`lib/state`) |
| Architecture | `core/` (API client, errors) · `services/` · `state/` · `screens/` · `widgets/` |

## Running

```bash
flutter pub get
./scripts/run.sh             # picks the connected Android phone automatically
./scripts/run.sh --release
flutter test
```

---

## 🇪🇸 Español

App de mensajería en tiempo real para Android hecha con **Flutter**. Los mensajes viajan por **WebSockets**, y la app incluye el flujo completo de cuenta: registro, verificación por correo, amigos y edición de perfil.

- Autenticación con sesión por cookies y refresco automático
- Chat en tiempo real
- Solicitudes de amistad y búsqueda de personas
- Perfil con foto y cambio de correo

```bash
flutter pub get
./scripts/run.sh   # detecta el teléfono Android conectado
```
