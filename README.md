Subscription Reaper (Flutter/Dart) — lib/ folder

What this includes
- Local subscription tracker (Hive-backed)
- "Cancel Assistant" WebView with:
  - Flow Recorder (records clicks + input changes as CSS selectors)
  - Flow Playback (replays recorded steps)
- You still log in yourself; the assistant automates repetitive retention-flow clicks.
  This avoids bypassing authentication, CAPTCHAs, or TOS-prohibited access.

How to use
1) flutter create subscription_reaper
2) Replace the generated lib/ with this lib/
3) Add dependencies from PUBSPEC_SNIPPET.md to pubspec.yaml
4) flutter run

Security / safety
- Credentials are never stored by this app.
- Recorded flows store selectors + (optionally) text typed during recording.
  If you type sensitive values while recording, they will be stored in the flow.
  Use "Redact value" in the step menu.

Limitations
- Sites with heavy bot detection, dynamic selectors, or CAPTCHAs may need manual steps.
- Some flows require waiting for async UI; playback includes basic delays; insert waits as needed.
