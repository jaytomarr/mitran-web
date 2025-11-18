## Overview
- Implement the Mitran Web MVP per PRD using Flutter Web, Riverpod, and Firebase (Auth, Firestore, Storage).
- Deliver core pages: Landing (`/`), Auth (`/auth`), Create Profile (`/create-profile`), Hub (`/hub`), Directory (`/directory` and `/directory/{dogId}`), AI Care (placeholder) (`/ai-care`), My Profile (`/profile`).
- Respect out-of-scope constraints: no web-based dog creation, no comments/replies, no notifications, AI tabs are UI-only.

## Current State
- Project already initializes Firebase in `lib/main.dart:5-9` and targets web (`lib/firebase_options.dart`).
- Dependencies present: `firebase_core` only (`pubspec.yaml:37`). Pages and Riverpod/providers not yet implemented.

## Architecture & Dependencies
- Add dependencies:
  - `flutter_riverpod` for state management
  - `go_router` for declarative routing and auth-guard redirects
  - `firebase_auth`, `cloud_firestore`, `firebase_storage` for backend
  - `google_sign_in` for Google login
  - `file_picker` (or `image_picker_for_web`) for web image uploads
  - `cached_network_image` for efficient image rendering
- Project structure (under `lib/`):
  - `models/` (UserModel, PostModel, DogModel, DogFilters)
  - `services/` (AuthService, FirestoreService)
  - `providers/` (auth, user profile, posts, dogs, filters, search term)
  - `router.dart` (GoRouter setup, route guards)
  - `widgets/` (shared: NavBar, PostItem, DogCard)
  - `pages/` (landing, auth, create_profile, hub, directory, dog_detail, ai_care, profile)
  - `theme.dart` (Material 3 theme, accessibility defaults)

## Routing
- Routes:
  - `/` Landing (public)
  - `/auth` Auth (public; reads `mode` query for login/signup)
  - `/create-profile` (requires `auth.currentUser`)
  - `/hub` (requires auth)
  - `/directory` (requires auth)
  - `/directory/:dogId` (requires auth)
  - `/ai-care` (requires auth; “Coming Soon” UI)
  - `/profile` (requires auth; current user only)
- Guards:
  - If not authenticated: redirect protected routes to `/auth`.
  - After first sign-up: always route to `/create-profile` until Firestore `users/{uid}` exists.

## State Management (Riverpod)
- Providers per PRD Appendix B:
  - `authProvider` (FirebaseAuth authStateChanges)
  - `userProfileProvider(userId)` streams `users/{userId}`
  - `postsProvider` streams global feed ordered by `timestamp` desc
  - `userPostsProvider(userId)` streams posts by author
  - `dogsProvider` streams dogs ordered by `createdAt` desc
  - `filteredDogsProvider` derives from `dogsProvider`, `dogFiltersProvider`, `searchTermProvider` for client-side filters (MVP)
  - `dogProvider(dogId)` streams a single dog
  - `userDogsProvider(userId)` streams dogs by `addedBy.userId`
  - `dogFiltersProvider` and `searchTermProvider` as state providers

## Data & Security
- Firestore collections per PRD:
  - `users`: profile and activity refs (`postIds`, `dogIds`)
  - `posts`: denormalized `author` block for fast feed
  - `dogs`: denormalized `addedBy` block for faster adoption contact
- Rules (implement in Firebase console):
  - Users: read if authed; write only self
  - Posts: read if authed; create if authed; update/delete only author
  - Dogs: read if authed; create if authed; update/delete only `addedBy.userId`
- Indexes: add composite indexes for any multi-where queries (post-MVP). MVP uses client-side filter to avoid index complexity.

## Services
- AuthService per Appendix D: Google sign-in, email/password login/signup, password reset, sign out, friendly error mapping.
- FirestoreService per Appendix D: CRUD for users/posts/dogs, image uploads to Storage, batch updates of denormalized data.

## UI Pages & Components
- Landing (`/`):
  - Hero, mission statement, visuals; CTA buttons to `/auth?mode=signup` and `/auth?mode=login`.
  - Acceptance: responsive hero, accessible, fast load.
- Auth (`/auth`):
  - Tabs: Login / Sign Up; honor `mode` query. Primary Google Sign-In; email/password forms.
  - Flows:
    - Login: on success, if user doc exists → `/hub`; else → `/create-profile`.
    - Sign-up: create auth user → `/create-profile`.
  - Acceptance: Google auth working, email/password, validators, error messages, reset password.
- Create Profile (`/create-profile`):
  - Form: username (unique), profile picture upload (≤5MB), phone (optional), city, area, user type.
  - On submit: validate → uniqueness check → upload image → write `users/{uid}` → redirect `/hub`.
  - Acceptance: validations, upload progress, preview, Firestore write, redirect.
- Hub (`/hub`):
  - Global NavBar: links to Hub/Directory/AI Care, profile menu, logout.
  - Create Post component: textarea ≤500 chars, counter, loading state, submit to `posts`, update `users.postIds`.
  - Community Feed: stream of `posts`, real-time, relative timestamps.
  - Acceptance: nav visible, post submit, real-time feed, character limit, loading/empty states, avatars.
- Directory (`/directory`):
  - Search + filters (vaccinated, sterilized, adoption); “Clear Filters”.
  - Grid of dog cards: main photo, name, location, status badges; responsive.
  - MVP search/filter: client-side over streamed `dogs` with debounced search; upgrade to server queries post-MVP.
  - Acceptance: search/filter correctness, responsiveness, navigation, loading/empty states, icons.
- Dog Detail (`/directory/{dogId}`):
  - Header with carousel, status badges, info block, “Interested in Adopting?” (if adoptable) showing contact modal.
  - Acceptance: fetch by `dogId`, responsive gallery, badges, modal contact, 404 handling.
- AI Care (`/ai-care`):
  - Tabs: Health Chat, Disease Scan; placeholder “Coming Soon” content and feature descriptions.
  - Acceptance: tab switching, clear descriptions; no backend calls in MVP.
- My Profile (`/profile`):
  - Editor: username (unique), picture upload, phone, city, area, type; save/cancel.
  - Activity tabs: “My Posts”, “Dogs I’ve Added”.
  - On changes: update user doc; batch update denormalized data in `posts` if username/picture changed.
  - Acceptance: load/edit/save, denormalized updates, tabs and empty states.

## UX/Accessibility & Responsive
- Material 3 theme; light simple UI; consistent paddings.
- Overflow-safe layouts: `SingleChildScrollView`/`ListView`, `Expanded`/`Flexible`, `SafeArea`, `TextOverflow.ellipsis/fade`, `BoxFit.cover/contain`.
- Breakpoints: mobile/tablet/desktop per PRD; touch target sizes and color contrast.

## Performance
- Lazy-load images with placeholders; cache network images.
- Debounced search; avoid excessive Firestore listeners.
- Compress images client-side where feasible; cap upload sizes (5MB profile, 10MB dog).

## Testing & Verification
- Unit tests for models and validation (username/password/post content rules).
- Widget tests for key flows: Auth page tab switching, Create Profile validation, Post creation updates feed, Directory filters derivation.
- Manual scenarios:
  - New user signup via Google → profile → hub → post → directory → detail → adoption modal.
  - Existing user login → hub & profile edit → posts denormalized update.

## Implementation Phases
- Phase 1 (MVP build):
  - Add dependencies and configure Riverpod/GoRouter.
  - Implement routing and auth guards.
  - Build pages: Landing, Auth, Create Profile.
  - Implement Hub (NavBar, Post creation, Feed).
  - Implement Directory and Dog Detail (client-side filters/search).
  - Implement My Profile editor and activity tabs.
  - AI Care placeholder.
  - Polish accessibility/performance; basic tests.
- Phase 2 (post-MVP):
  - Server-side queries with indexes; AI feature integrations; comments/replies; notifications; public profiles.

## Risks & Mitigations
- Firestore quotas → pagination and caching; monitor usage.
- Image performance → compression, CDN, lazy-load.
- Denormalized consistency → batch writes; future Cloud Functions.
- Username conflicts → real-time uniqueness checks during profile edit/create.

## Next Steps
- On approval, I will:
  - Add required dependencies and scaffold the folder structure.
  - Implement routing, providers, services, and build each page per acceptance criteria.
  - Validate with tests and run the web app for verification.
