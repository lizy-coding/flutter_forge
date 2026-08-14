# gcode_core Ownership Contract

## Package

`gcode_core`

## Public Contract

`gcode_core` owns the reusable G-code package boundary for parsing G-code, reading line streams, collecting parse errors, building toolpath segments, and rendering Flutter visualization widgets such as the canvas, command timeline, and playback controls.

It must not own host file picking, app-level route composition, app playback state, module catalog metadata, platform bootstrap policy, or feature-specific Flutter Study screens outside this package.

## Maintenance Owners

- Flutter Study package maintainers
- G-code package maintainers
