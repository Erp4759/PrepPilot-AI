import 'package:flutter/material.dart';

RouteInformationParser<Object> createRouterInformationParser() =>
    const _PlaceholderParser();
RouterDelegate<Object> createRouterDelegate() => _PlaceholderDelegate();

RouterConfig<Object> createRouter() => RouterConfig(
  routerDelegate: createRouterDelegate(),
  routeInformationParser: createRouterInformationParser(),
);

class _PlaceholderParser extends RouteInformationParser<Object> {
  const _PlaceholderParser();
  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation.location ?? '/';
  }
}

class _PlaceholderDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _location = '/';

  @override
  Future<void> setNewRoutePath(configuration) async {
    _location = configuration.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [const MaterialPage(child: _SplashScreen())],
      onPopPage: (route, result) => route.didPop(result),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('PrepPilot AI')));
  }
}
