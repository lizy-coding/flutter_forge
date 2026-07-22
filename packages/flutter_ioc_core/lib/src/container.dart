import 'dart:async';

import 'types.dart';

class _ContainerKey {
  _ContainerKey(this.type, this.name);
  final Type type;
  final String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ContainerKey &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode => type.hashCode ^ name.hashCode;

  @override
  String toString() => '${type.toString()}${name != null ? '#$name' : ''}';
}

class _Registration {
  _Registration({
    required this.key,
    required this.factory,
    required this.lifetime,
    required this.condition,
    required this.propertyInjectors,
  });

  final _ContainerKey key;
  final Factory<dynamic> factory;
  final Lifetime lifetime;
  final Condition condition;
  final List<PropertyInjector<dynamic>> propertyInjectors;
  dynamic instance;
}

/// Concrete IoC container with lifecycle management, conditional selection, and scopes.
class Container implements IoCContainer {
  Container({Map<String, Object?> environment = const {}, Container? parent})
      : _environment = Map<String, Object?>.from(environment),
        _parent = parent;

  final Map<Type, List<_Registration>> _registrations = {};
  final Map<_ContainerKey, dynamic> _scopedInstances =
      {}; // Scope-specific cache.
  final List<_ContainerKey> _resolutionPath =
      []; // Tracks resolution chain to detect cycles.
  final Map<String, Object?> _environment;
  final Container? _parent;

  @override
  void registerSingleton<T>(
    Factory<T> factory, {
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  }) {
    _register<T>(
      factory: factory,
      lifetime: Lifetime.singleton,
      name: name,
      condition: condition,
      propertyInjectors: propertyInjectors,
    );
  }

  @override
  void registerTransient<T>(
    Factory<T> factory, {
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  }) {
    _register<T>(
      factory: factory,
      lifetime: Lifetime.transient,
      name: name,
      condition: condition,
      propertyInjectors: propertyInjectors,
    );
  }

  @override
  void registerScoped<T>(
    Factory<T> factory, {
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  }) {
    _register<T>(
      factory: factory,
      lifetime: Lifetime.scoped,
      name: name,
      condition: condition,
      propertyInjectors: propertyInjectors,
    );
  }

  void _register<T>({
    required Factory<T> factory,
    required Lifetime lifetime,
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  }) {
    final registration = _Registration(
      key: _ContainerKey(T, name),
      factory: factory,
      lifetime: lifetime,
      condition: condition ?? (_) => true,
      propertyInjectors:
          propertyInjectors?.cast<PropertyInjector<dynamic>>() ?? const [],
    );
    _registrations.putIfAbsent(T, () => []).add(registration);
  }

  @override
  T resolve<T>({String? name}) {
    final result = _resolveInternal<T>(
        name: name, scope: this, allowAsyncFactories: false);
    if (result is Future) {
      throw ContainerException(
          'Async factory registered for $T; call resolveAsync<$T>() instead.');
    }
    return result as T;
  }

  @override
  Future<T> resolveAsync<T>({String? name}) async {
    final result = await _resolveInternal<T>(
      name: name,
      scope: this,
      allowAsyncFactories: true,
    );
    if (result is Future) {
      return await result;
    }
    return result as T;
  }

  dynamic _resolveInternal<T>(
      {String? name,
      required Container scope,
      required bool allowAsyncFactories}) {
    final token = _ContainerKey(T, name);
    if (_resolutionPath.contains(token)) {
      final chain =
          [..._resolutionPath, token].map((e) => e.toString()).join(' -> ');
      throw ContainerException('Circular dependency detected: $chain');
    }

    final registration = _findRegistration<T>(name: name, scope: scope);
    _resolutionPath.add(token);
    try {
      switch (registration.lifetime) {
        case Lifetime.singleton:
          return registration.instance ??=
              _createInstance<T>(registration, scope, allowAsyncFactories);
        case Lifetime.transient:
          return _createInstance<T>(registration, scope, allowAsyncFactories);
        case Lifetime.scoped:
          return scope._scopedInstances.putIfAbsent(
            registration.key,
            () => _createInstance<T>(registration, scope, allowAsyncFactories),
          );
      }
    } finally {
      _resolutionPath.removeLast();
    }
  }

  dynamic _createInstance<T>(
    _Registration registration,
    Container scope,
    bool allowAsyncFactories,
  ) {
    final created = registration.factory(scope);
    if (created is Future && !allowAsyncFactories) {
      throw ContainerException(
          'Async factory registered for $T; call resolveAsync<$T>() instead.');
    }

    if (created is Future) {
      return created.then((value) {
        _injectProperties(registration, value, scope);
        return value;
      });
    }

    _injectProperties(registration, created, scope);
    return created;
  }

  void _injectProperties(
      _Registration registration, dynamic instance, Container scope) {
    for (final injector in registration.propertyInjectors) {
      injector(instance, scope);
    }
  }

  _Registration _findRegistration<T>({String? name, required Container scope}) {
    final registrations = _collectRegistrations(T);
    final matching = registrations
        .where((r) => r.key.name == name && r.condition(scope))
        .toList();

    if (matching.isEmpty) {
      final availableNames = registrations
          .where((r) => r.key.name != null)
          .map((r) => r.key.name)
          .toSet()
          .join(', ');
      throw ContainerException(
          'No registration found for $T ${name != null ? 'with name $name ' : ''}'
          '${availableNames.isNotEmpty ? '(available names: $availableNames)' : ''}');
    }
    return matching.first;
  }

  List<_Registration> _collectRegistrations(Type type) {
    final current = _registrations[type] ?? const <_Registration>[];
    if (_parent == null) {
      return current;
    }
    return [...current, ..._parent!._collectRegistrations(type)];
  }

  @override
  IoCContainer createScope(
      {Map<String, Object?> environmentOverrides = const {}}) {
    final env = {..._environment, ...environmentOverrides};
    return Container(environment: env, parent: this);
  }

  @override
  bool flag(String key, {bool defaultValue = false}) {
    final value = env(key);
    if (value is bool) return value;
    return defaultValue;
  }

  @override
  Object? env(String key) => _environment[key] ?? _parent?.env(key);

  @override
  void autoRegister(List<AutoRegistrar> registrars) {
    for (final registrar in registrars) {
      registrar.register(this);
    }
  }
}
