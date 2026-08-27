# Changelog

## [2.11.0] - 2026-08-26

### Added

- Host-driven ad units — host apps can provide a VAST tag and explicitly select the ad shape instead of relying on the creative. `showPauseAd` supports pause-ad formats (`PauseVastFullBleed`, `PauseVastAd`, `PauseAdSidebar11`, `PauseAdSidebar21`), while `showAd` supports playback formats (`SideBar21`, `LBar21`, `SideBarImageOnly`, `LBarImageOnly`, `SideBySide`). Omitting the type preserves the previous behaviour
- Host-driven standard ad units use the existing programmatic pipeline, including ad pods, impressions, `creativeView`, and video quartile tracking
- Host ads can optionally show a notification teaser using the same title, description, and sponsor logo as the ad
- `isEventReady` — new observable field indicating when the SDK has resolved an event and is ready to serve ads

### Changed

- `showPauseAd` now accepts `{ vastUrl, type, isNotificationEnabled }`

### Fixed

- Fixed analytics so every ad in a VAST pod is counted correctly
- Fixed heartbeat and feed polling stopping when video pause ads temporarily pause the host player
- Fixed startup failure and potential channel crash when an ad card has no background image
- Fixed notification startup when no background image is configured
- Fixed notification button labels when no button colour is configured
- Fixed Poll and Trivia answer percentage fills so they reflect the actual vote share
- Fixed Trivia so the correct answer is marked whether or not the viewer selected it
- Fixed Poll answer styling so answers are not treated as correct or incorrect
- Fixed previously answered Polls reopening when shown again
- Vote results now remain visible for 3.5 seconds
- Fixed overlays and pause ads no longer appearing after pausing while a Poll or Trivia card was still on its way to the screen
- Fixed playback staying paused after closing a Trivia, Poll or Prediction card
- Fixed the stream restarting from the beginning instead of continuing after closing a Trivia, Poll or Prediction card

## [2.10.0] - 2026-08-14

### Added

- Image-Only layout for Standard Ad units — L-Bar and Sidebar can render a single full-bleed advertiser image instead of the structured template, while keeping the close button, CTA, and the 6:1 bottom banner on L-Bar; Template remains the default
- Full-bleed pause ad for programmatic VAST MP4 creatives
- Notification background image — Sidebar notifications now use their own background when configured, falling back to the shared question background
- Programmatic ad pods — VAST responses containing multiple ads now play them sequentially within the same card, with transitions and an "X of Y" counter; each ad uses its own creative, sponsor logo, and QR target

### Fixed

- Fixed notification sponsor logo fallback when Studio leaves the notification logo unset; the advertiser logo is used when "use general logo" is enabled, otherwise the notification uses its own logo or falls back to the campaign logo

## [2.9.1] - 2026-08-06

### Fixed

- Unified sponsor logo sizing and alignment across all ad formats
- Fixed the Prediction result overlay for programmatic cards
- Smoothed the Side-by-Side transition back to the host player
- Fixed Side-by-Side QR/CTA panel and return-to-video button alignment; removed redundant CTA instructions

## [2.9.0] - 2026-06-30

### Added

- Programmatic ads (GAM, PubMatic, Magnite) on standard ad units (L-Bar, Sidebar, Side-by-Side) and interactive units (Trivia, Poll, Insight, Prediction)
- Multi-ad playback within a single overlay, with an "X of Y" counter
- Prediction results now open in the Sidebar overlay and are revealed in phases: results announcement, question, viewer pick, and outcome
- Side-by-Side support for a static banner image

### Fixed

- Corrected analytics events across standard ad units, Side-by-Side, Poll, and Trivia
- Fixed missing sponsor logos on Trivia and Poll cards without a background image
- Insight — the remote's Play button now starts the media
- Insight — description text no longer fades on focus
- Insight — fixed spacing around the description plate so it no longer overlaps the sponsor logo
- Insight — added a drop shadow behind focused media and descriptions
- Prediction — the picked answer is now marked as selected rather than correct
- Prediction — fixed vote percentages showing a fixed 100% instead of the actual result
- Prediction — the question is now shown on the "Stay tuned" view after voting
- Fixed programmatic interactive cards not appearing when the VAST response has no sponsor logo
- Side-by-Side — fixed send-info status alignment, centred descriptions when no buttons are present, and moved focus to the close button after Send Email
- "Return to Video" no longer reports a button-navigation event

## [2.8.0] - 2026-05-28

### Added

- Side-by-Side ad unit — QR/CTA panel with return-to-video and send-to-user (Email/Phone) buttons
- Trivia pause ad — full-bleed variant

### Changed

- Unanswered Poll and Trivia cards now stay open after a moderator deactivates them

### Fixed

- Trivia — restored the close (X) button
- Insight — improved detail focus and scrolling; body text is now capped at 6 lines
- Poll and Trivia — fixed cards freezing after voting; focus now moves to the close button as soon as an answer is selected
- Poll — fixed a crash when displaying vote results
- Insight — fixed media-less cards breaking the overlay; focus now starts on the close button
- Trivia and Prediction — answer highlighting now clears reliably when focus leaves the answer list
- Trivia — fixed answer focus getting stuck during fast navigation or when returning from the close button
- Trivia pause ad now closes automatically after the vote result is shown
- Insight — media is now hidden when "No media" is selected
- Insight — corrected body text spacing and selection highlighting
- Poll and Trivia — answer lists now show a scroll hint and adapt to the question length

## [2.7.0] - 2026-05-06

### Added

- Prediction ad unit with a results overlay
- Send-to-user button on standard ad units (L-Bar/Sidebar) — Email and Phone variants

### Changed

- Unified sponsor logo handling across ad units
- Improved webhook event routing

## [2.6.0] - 2026-04-14

### Added

- Poll ad unit

### Changed

- Extended analytics to cover Poll interactions

## [2.5.0] - 2026-04-06

### Added

- Trivia ad unit

## [2.4.0] - 2026-04-01

### Added

- Insight ad unit with factoid support

## [2.3.0] - 2026-03-12

### Added

- Trivia pause ad — Sidebar mode

### Fixed

- Fixed a heartbeat issue when closing a Bell ad with Back and resuming the stream

## [2.2.2] - 2026-03-13

### Changed

- Pause ad (VAST) lifecycle is now managed by the host app
- Back hands close handling to the host without resuming playback
- Play resumes playback and closes the ad with the appropriate analytics
- Separated "ad closed" (Back) and "stream resumed" (Play) analytics events

## [2.2.1] - 2026-03-10

### Changed

- Updated Bell ad gradient styling
- Added the `sl-sdk-version` header to analytics requests

### Fixed

- Fixed missing analytics events after a second pause
- Fixed the semi-transparent background on the Bell ad

## [2.2.0] - 2026-02-12

### Added

- Pause ad full-bleed overlay
- Pause ad VAST prefetch caching
- Bell ad analytics
- Authentication via JWE-based JWT exchange

### Changed

- Added VAST mode configuration for pause-ad playback
- Updated analytics tracking and payload structure

## [2.1.0] - 2026-01-07

### Added

- Notifications for SDK events
- Sidebar notification overlay

### Changed

- Improved analytics event handling

### Notes

- Builds on the 2.0 runtime, focused on event notifications

## [2.0.0] - 2025-12-17

### Added

- Pause ad VAST support
- Play and resume events for the host player
- Sponsor logo dimension loading to reduce texture warnings

### Changed

- Improved promo visibility handling
- Refactored the SDK structure and player attachment interface

### Fixed

- Fixed a crash during response parsing
- Fixed promo visibility issues during presentation

### Notes

- Major update to the SDK runtime and ad flow architecture

## [1.0.0] - 2025-09-30

### Added

- Initial StreamLayer Roku SDK
- Authentication and organization management
- Feed, leaderboard, and SDK settings APIs
- Device ID support for API requests
- Interactive ad units
- Analytics for SDK usage, events, and ad interactions
- Promo and event callback interface
- QR code generator

### Notes

- First production-ready release of the Roku SDK
