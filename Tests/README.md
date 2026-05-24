# Tests/

Unit + integration tests for `DotPinchPrototype`. The `DotPinchPrototypeTests` target is defined in `project.yml`.

## Layout

- `V2/` — V2 architecture tests (cell layout, page gradient, spike experiments, Wave 4 series, Wave R series).
- `Support/` — shared test helpers (currently empty).

## Running tests

```bash
xcodebuild -scheme DotPinchPrototype \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  test
```

iOS 18 simulator only — Maestro 2.5.1 returns an empty accessibility tree on iOS 26+ sims.
