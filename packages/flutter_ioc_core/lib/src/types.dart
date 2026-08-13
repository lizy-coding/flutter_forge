import 'dart:async';

/// Lifecycle options for registered services.
enum Lifetime { singleton, transient, scoped }

/// Factory that creates instances and can resolve other dependencies.
typedef Factory<T> = FutureOr<T> Function(ContainerResolver resolver);

/// Predicate to decide whether a registration should be used.
typedef Condition = bool Function(ContainerResolver resolver);

/// Hook to inject dependencies into already created instances.
typedef PropertyInjector<T> = void Function(
    T instance, ContainerResolver resolver);

/// Registers a bundle of services.
abstract class AutoRegistrar {
  void register(IoCContainer container);
}

/// Minimal resolver interface exposed to factories and property injectors.
abstract class ContainerResolver {
  T resolve<T>({String? name});
  Future<T> resolveAsync<T>({String? name});
  bool flag(String key, {bool defaultValue = false});
  Object? env(String key);
}

/// Public IoC container interface.
abstract class IoCContainer implements ContainerResolver {
  void registerSingleton<T>(
    Factory<T> factory, {
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  });

  void registerTransient<T>(
    Factory<T> factory, {
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  });

  void registerScoped<T>(
    Factory<T> factory, {
    String? name,
    Condition? condition,
    List<PropertyInjector<T>>? propertyInjectors,
  });

  void autoRegister(List<AutoRegistrar> registrars);

  IoCContainer createScope(
      {Map<String, Object?> environmentOverrides = const {}});
}

/// Base error type for the container.
class ContainerException implements Exception {
  ContainerException(this.message);
  final String message;

  @override
  String toString() => 'ContainerException: $message';
}
