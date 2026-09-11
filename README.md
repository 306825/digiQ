# Strut

Ride and lift sharing for South Africa. Flutter client for the Strut platform,
backed by the API at `api.struttech.co.za`.

## Roles

The app serves four roles, each with its own home screen and navigation gated by
`user.role` in `lib/core/routing/app_router.dart`:

- **Passenger** — search trips, book seats, pay, track the driver live, chat
- **Driver** — create trips, manage bookings and vehicles, pickup routing, payouts
- **Fleet owner** — manage multiple drivers and vehicles
- **Admin** — driver verification, routes, payments, incidents

## Architecture

- **State** — Riverpod 3 (`NotifierProvider` / `FutureProvider`), hand-written providers
- **Navigation** — `go_router`, single `redirect` handling auth and role gating
- **Networking** — one `Dio` instance with a token interceptor, wrapped by `lib/core/api/*_api.dart`
- **Auth** — token and cached user in `flutter_secure_storage`
- **Realtime** — `socket_io_client` for live tracking and chat
- **Maps** — `google_maps_flutter` + `geolocator`
- **Push** — Firebase Messaging + `flutter_local_notifications`

## Getting started

```sh
flutter pub get
flutter run
```

### Release builds

Release signing reads `android/key.properties`, which is not in version control.
Create it alongside your keystore:

```properties
storeFile=<path to keystore>
storePassword=<password>
keyAlias=<alias>
keyPassword=<password>
```

Without that file the build falls back to debug signing.

## Notes

- The Google Maps API key in `android/app/src/main/AndroidManifest.xml` must be
  package- and SHA-restricted in the Google Cloud console.
- Regenerate the launcher icon and splash after changing brand assets:
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
