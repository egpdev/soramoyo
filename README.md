# AURA — Weather, made quiet

A minimal native macOS weather desk for the moment you are about to leave. Aura gets your location, retrieves live weather from Open-Meteo, and turns the conditions into a clear outfit recommendation.

## What is real

- Location permission through macOS Core Location
- Current temperature, feels-like temperature, wind, rain chance and five-day forecast from Open-Meteo
- A local outfit engine that reacts to weather conditions — no API key and no account needed
- A glass-like weather widget designed as the visual centre of the app
- A generated macOS app icon: a luminous weather ring, used in the Dock and Finder

## Run

```sh
swift run
```

Build the standalone app:

```sh
zsh Scripts/build-app.sh
open outputs/Aura.app
```

## Tech

Swift 5 · SwiftUI · Core Location · URLSession · Open-Meteo API
