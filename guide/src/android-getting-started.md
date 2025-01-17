# Getting Started on Android

This section of the guide covers how to integrate Ferrostar into an Android app.
We'll cover the "batteries included" approach, but flag areas for customization and overrides along the way.

Note that while this section is WIP, we have a well-documented [demo app](https://github.com/stadiamaps/ferrostar/tree/main/android/demo-app).
The TODOs will get filled in eventually, but the demo app is a good reference for now.

## Minimum requirements

See the [platform support targets](./platform-support-targets.md) document
for details on supported Android versions.

## Add dependencies

Ferrostar releases are hosted on GitHub Packages.
You’ll need to authenticate first in order to access them.
GitHub has a [guide on setting this up](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-gradle-registry#authenticating-to-github-packages).

### Maven repository setup

Once you’ve configured GitHub credentials as project properties or environment variables,
Add the repository to your build script.

If you are using `settings.gradle` for your dependency resolution management,
you’ll end up with something like along these lines:

```groovy
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven {
            url = 'https://maven.pkg.github.com/stadiamaps/ferrostar'
            credentials {
                username = settings.ext.find('gpr.user') ?: System.getenv('GITHUB_ACTOR')
                password = settings.ext.find('gpr.token') ?: System.getenv('GITHUB_TOKEN')
            }
        }
        
        // For the MapLibre compose integration
        maven {
            url = 'https://maven.pkg.github.com/Rallista/maplibre-compose-playground'
            credentials {
                username = settings.ext.find('gpr.user') ?: System.getenv('GITHUB_ACTOR')
                password = settings.ext.find('gpr.token') ?: System.getenv('GITHUB_TOKEN')
            }
        }

        google()
        mavenCentral()
    }
}
```

And if you’re doing this directly in `build.gradle`, things look slightly different:

```groovy
repositories {
    google()
    mavenCentral()

    maven {
        url = uri("https://maven.pkg.github.com/stadiamaps/ferrostar")
        credentials {
            username = project.findProperty("gpr.user") ?: System.getenv("GITHUB_ACTOR")
            password = project.findProperty("gpr.token") ?: System.getenv("GITHUB_TOKEN")
        }
    }
    
    // For the MapLibre compose integration
    maven {
        url = uri("https://maven.pkg.github.com/Rallista/maplibre-compose-playground")
        credentials {
            username = settings.ext.find("gpr.user") ?: System.getenv("USERNAME")
            password = settings.ext.find("gpr.token") ?: System.getenv("TOKEN")
        }
    }
}
```

### Add dependencies

#### `build.gradle` with explicit version strings

If you’re using the classic `build.gradle`
with `implementation` strings using hard-coded versions,
here’s how to set things up.
Replace `X.Y.Z` with an [appropriate version](https://github.com/orgs/stadiamaps/packages?repo_name=ferrostar).

```groovy
dependencies {
    // Elided: androidx dependencies: ktx and compose standard deps

    // Ferrostar
    def ferrostarVersion = 'X.Y.Z'
    implementation "com.stadiamaps.ferrostar:core:${ferrostarVersion}"
    implementation "com.stadiamaps.ferrostar:maplibreui:${ferrostarVersion}"

    // okhttp3
    implementation platform("com.squareup.okhttp3:okhttp-bom:4.11.0")
    implementation 'com.squareup.okhttp3:okhttp'
}
```

#### `libs.versions.toml` “modern style”

If you’re using the newer `libs.versions.toml` approach,
add the versions like so:

```toml
[versions]
ferrostar = "X.Y.X"
okhttp3 = "4.11.0"

[libraries]
ferrostar-core = { group = "com.stadiamaps.ferrostar", name = "core", version.ref = "ferrostar" }
ferrostar-maplibreui = { group = "com.stadiamaps.ferrostar", name = "maplibreui", version.ref = "ferrostar" }
okhttp3 = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp3" }
```

Then reference it in your `build.gradle`:

```groovy
dependencies {
    // Elided: androidx dependencies: ktx and compose standard deps

    // Ferrostar
    implementation libs.ferrostar.core
    implementation libs.ferrostar.maplibreui

    // okhttp3
    implementation libs.okhttp3
}
```

## Configure location services

### Declaring permissions used

Your app will need access to the user’s location.
First, you’ll need the requisite permissions in your Android manifest:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

You’ll then need to request permission from the user to access their precise location.

### Requesting location access

The “best” way to do this tends to change over time and varies with your app structure.
If you’re using Jetpack Compose,
you’ll want the `rememberLauncherForActivityResult` API.
If you’re just using plain activities,
the `registerForActivityResult` has what you need.

In either case, you’ll want to review [Google’s documentation](https://developer.android.com/develop/sensors-and-location/location/permissions#kotlin).

### Ensuring updates when the app loses focus

Note that Ferrostar does *not* require “background” location access!
This may be confusing if you’re new to mobile development.
On Android, we can use something called a *foreground service*
which lets us keep getting location updates even when the app isn’t front and center.

TODO: Tutorial on this

### Location providers

You'll need to configure a provider to get location updates.
We bundle a few implementations to get you started, or you can create your own.
The broad steps are the same regardless of which provider you use:
create an instance of the class,
store it in an instance variable where it makes sense,
and (if simulating a route) set the location manually or enter a simulated route.

Similar to the Android location APIs you may already know,
you can add or remove listeners which will receive updates.

#### `SimulatedLocationProvider`

The `SimulatedLocationProvider` allows for simulating location within Ferrostar
without needing GPX files or complicated environment setup.
This is great for testing and development without stepping outside.

First, instantiate the class.
This will typically be saved as an instance variable.

```kotlin
private val locationProvider = SimulatedLocationProvider()
```

Later, most likely somewhere in your activity creation code or similar,
set a location to your desired simulation start point.

```kotlin
locationProvider.lastLocation = initialSimulatedLocation
```

Once you have a route, you can simulate the replay of the route.
This is technically optional (you can just set `lastLocation` yourself too),
but playing back a route saves you the effort.
You can set a `warpFactor` to play it back faster.

```kotlin
locationProvider.warpFactor = 2u
locationProvider.setSimulatedRoute(route)
```

You don’t need to do anything else after setting a simulated route;
`FerrostarCore` will automatically add itself as a listener,
which will trigger updates.

#### TODO: Google Play Services-backed provider

## Configure an HTTP client

Before we configure the Ferrostar core, we need to set up an HTTP client.
This is typically stored as an instance variable in one of your classes (ex: activity).
We use the popular OkHttp library for this.
Here we’ve set up a client with a global timeout of 15 seconds.
Refer to the [OkHttp documentation](https://square.github.io/okhttp/) for further details on configuration.

```kotlin
private val httpClient = OkHttpClient.Builder()
    .callTimeout(Duration.ofSeconds(15))
    .build()
```

## Configure the `FerrostarCore` instance

We now have all the pieces we need to set up a `FerrostarCore` instance!
The `FerrostarCore` instance should live for at least the duration of a navigation session.
Bringing it all together, a typical init looks something like this:

```kotlin
private val core =
      FerrostarCore(
          valhallaEndpointURL = URL("https://api.stadiamaps.com/route/v1?api_key=YOUR-API-KEY"),
          profile = "bicycle",
          httpClient = httpClient,
          locationProvider = locationProvider,
      )
```

`FerrostarCore` exposes a number of convenience constructors for common cases,
such as using a Valhalla [Route Provider](./route-providers.md#bundled-support).

`FerrostarCore` automatically subscribes to location updates from the `LocationProvider`.

## Set up voice guidance

Ferrostar is able to process spoken instructions generated from some routing engines.
The `com.stadiamaps.ferrostar.core.SpokenInstructionObserver` interface
specifies haw to create your own observer.
A reference implementation is provided in the `AndroidTtsObserver` class,
which uses the text-to-speech engine built into Android.
PRs welcome for other popular services (ex: Amazon Polly;
note that some APIs also provide SSML instructions which work great with this!).

TODO documentation:

* Android Manifest
* Set the language
* Additional config (you have full control)

## Getting a route

Getting a route is easy!
All you need is the start location (from the location provider)
and a list of at least one waypoint to visit.

```kotlin
val routes =
    core.getRoutes(
        userLocation,
        listOf(
            Waypoint(
                coordinate = GeographicCoordinate(37.807587, -122.428411),
                kind = WaypointKind.BREAK),
        ))
```

Note that this is a `suspend` function, so you’ll need to use it within a coroutine scope.
You probably want something like `launch(Dispatchers.IO) { .. }`
for most cases to ensure it’s running on the correct dispatcher.
You may select a different dispatcher if you are doing offline route calculation.

## Starting a navigation session

Once you have a route (ex: by grabbing the first one from the list
or by presenting the user with a selection screen),
you’re ready to start a navigation session!

When you start a navigation session, the core returns a view model
which will automatically be updated with state updates.

You can save “rememberable” state somewhere near the top of your composable block like so:

```kotlin
var navigationViewModel by remember { mutableStateOf<NavigationViewModel?>(null) }
```

And then use it to store the result of your `startNavigation` invocation:

```kotlin
navigationViewModel =
    core.startNavigation(
        route = route,
        config =
        NavigationControllerConfig(
            StepAdvanceMode.RelativeLineStringDistance(
                minimumHorizontalAccuracy = 25U, automaticAdvanceDistance = 10U),
            RouteDeviationTracking.StaticThreshold(25U, 10.0)),
    )
```

Finally, If you’re simulating route progress
(ex: in the emulator) with a `SimulatedLocationProvider`),
set the route:

```kotlin
locationProvider.setSimulatedRoute(route)
```

## Using the `NavigationMapView`

We’re finally ready to turn that view model into a beautiful navigation map!
It’s really as simple as creating a `NavigationMapView` with the view model.
Here’s an example:

```kotlin
 val viewModel = navigationViewModel
 if (viewModel != null) {
     // Demo tiles illustrate a basic integration without any API key required,
     // but you can replace the styleURL with any valid MapLibre style URL.
     // See https://stadiamaps.github.io/ferrostar/vendors.html for some vendors.
     NavigationMapView(
         styleUrl =
         "https://tiles.stadiamaps.com/styles/outdoors.json?api_key=$stadiaApiKey",
         viewModel = viewModel) { uiState ->
         // You can add your own overlays here!
         // See https://github.com/Rallista/maplibre-compose-playground
     }
 } else {
     // Loading indicator
     Column(
         verticalArrangement = Arrangement.Center,
         horizontalAlignment = Alignment.CenterHorizontally) {
         Text(text = "Calculating route...")
         CircularProgressIndicator(modifier = Modifier.width(64.dp))
     }
 }
```

## Demo app

We've put together a minimal [demo app](https://github.com/stadiamaps/ferrostar/tree/main/android/demo-app) with an example integration.

## Going deeper

This covers the basic “batteries included” configuration which works for simple apps.
But there’s a lot of room for customization!
Skip on over to the customization chapters that interest you.