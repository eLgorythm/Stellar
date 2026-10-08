# LEARN: How Stellar Was Built

This document explains the build process behind **Stellar**, from idea to implementation.

## 1) Define the Problem

The initial goal was simple:
- make it easier to get gacha history links from Android HoYoverse games,
- avoid root access,
- keep user data local,
- and provide a built-in pity counter.

This led to a project focused on **ADB Wireless Debugging + local parsing**.

## 2) Choose the Architecture

Stellar uses:
- **Flutter (Dart)** for UI and app flow,
- **Rust** for low-level ADB/TLS/SPAKE2 logic and data-heavy processing,
- **flutter_rust_bridge** to connect Flutter and Rust safely.

Why this split:
- Flutter makes multi-screen Android UI fast to iterate,
- Rust gives stronger control for protocol, crypto, and performance-sensitive tasks.

## 3) Build the Core Connection Flow

The first major milestone was building a reliable 3-step ADB workflow:

1. **Pairing**
   - Discover pairing service via mDNS.
   - Run secure handshake (TLS + SPAKE2 + peer info exchange).
   - Persist certificate/flag to track trusted state.

2. **Connection**
   - Negotiate ADB secure transport (`STLS`) and upgrade to TLS.
   - Keep an active encrypted session for shell commands.

3. **Scan**
   - Open a shell stream to read logcat.
   - Filter for supported HoYoverse URL patterns containing `authkey`.
   - Stop scan immediately once a valid link is found.

## 4) Implement History Import and Pity Logic

After link extraction worked, the next phase was product usability:

- fetch paginated wish history from HoYoverse endpoints,
- merge incrementally with local JSON files,
- deduplicate by unique IDs,
- compute pity, averages, and guaranteed status by banner/game rules.

This transformed Stellar from a scanner into a complete personal analysis tool.

## 5) Build UX Around the Technical Flow

The app then added user-facing pieces to make the workflow practical:

- guided pairing/connection states,
- clear action buttons (PAIR, CONNECT, SCAN, IMPORT),
- localized content (multiple languages),
- history/status views and notification feedback.

## 6) Keep Security and Privacy as Defaults

Design decisions made throughout development:

- no root requirement,
- local-only processing/storage,
- no third-party server used for authkey handling,
- generated credentials stored in app-private storage.

## 7) Iterate, Test, and Refine

Development followed repeated cycles:

1. implement one flow segment,
2. test directly on Android device,
3. inspect logs and edge cases,
4. harden protocol handling and UI state transitions.

Most reliability improvements came from real-device validation across pairing, reconnecting, and repeated scans.

## 8) Final Project Structure

At a high level:
- `lib/` holds Flutter UI, screens, logic, widgets, and integrations,
- native bridge/generated files connect to Rust functions,
- `assets/` stores tutorial/about/notification/localization resources.

## 9) What to Learn from This Project

If you want to build something similar, key takeaways are:

- separate UI concerns from protocol/crypto concerns,
- validate transport steps incrementally (pairing -> connect -> command stream),
- treat local privacy boundaries as a product feature,
- design UX around real operational states, not only happy paths.
