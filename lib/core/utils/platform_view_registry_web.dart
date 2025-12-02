// Web implementation using dart:ui_web
// This file is used when running on Web platform

import 'dart:ui_web' as ui_web;

// Track registered view types to avoid duplicate registration
final Set<String> _registeredViews = {};

void registerWebViewFactory(
  String viewType,
  dynamic Function(int viewId) viewFactory,
) {
  // Only register if not already registered
  if (!_registeredViews.contains(viewType)) {
    try {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        viewFactory,
      );
      _registeredViews.add(viewType);
    } catch (e) {
      // View type already registered, ignore error
      _registeredViews.add(viewType);
    }
  }
}
