# flutter_ioc_core Ownership Contract

## Package

`flutter_ioc_core`

## Public Contract

`flutter_ioc_core` owns the pure Dart inversion-of-control container boundary, including registration lifetimes, scoped resolution, container resolver APIs, factories, conditions, property injection hooks, and container exceptions.

It must not own Flutter widgets, app bootstrap, route composition, module teaching screens, service implementations registered by callers, or platform integration behavior.

## Maintenance Owners

- Flutter Study package maintainers
- IoC core maintainers
