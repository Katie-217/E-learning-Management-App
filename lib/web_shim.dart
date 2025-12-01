// Web platform view registry shim
// This file provides a safe wrapper for platformViewRegistry that works on all platforms

import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import based on platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web show platformViewRegistry;

/// Registers a platform view factory for web
/// On non-web platforms, this is a no-op
void registerViewFactory(
  String viewType,
  dynamic Function(int viewId) viewFactory,
) {
  if (kIsWeb) {
    // Only call platformViewRegistry on web
    ui_web.platformViewRegistry.registerViewFactory(viewType, viewFactory);
  }
  // On other platforms, do nothing
}
