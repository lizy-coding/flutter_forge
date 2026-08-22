import 'package:flutter/material.dart';

import 'pages/provider/provider_route.dart';
import 'pages/provider/provider_lifting_route.dart';
import 'pages/provider/provider_future_route.dart';
import 'pages/provider/provider_todo_route.dart';
import 'pages/riverpod/riverpod_route.dart';
import 'pages/riverpod/riverpod_lifting_route.dart';
import 'pages/riverpod/riverpod_future_route.dart';
import 'pages/riverpod/riverpod_todo_route.dart';
import 'pages/bloc/bloc_route.dart';

class StatusManagementRoutes {
  StatusManagementRoutes._();

  static Map<String, WidgetBuilder> get routes => {
    '/provider': (_) => const ProviderRoute(),
    '/provider/lifting': (_) => const ProviderLiftingRoute(),
    '/provider/future': (_) => const ProviderFutureRoute(),
    '/provider/todo': (_) => const ProviderTodoRoute(),
    '/riverpod': (_) => const RiverpodRoute(),
    '/riverpod/lifting': (_) => const RiverpodLiftingRoute(),
    '/riverpod/future': (_) => const RiverpodFutureRoute(),
    '/riverpod/todo': (_) => const RiverpodTodoRoute(),
    '/bloc': (_) => const BlocRoute(),
  };
}
