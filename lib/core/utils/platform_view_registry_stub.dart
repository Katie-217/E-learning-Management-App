// Stub implementation for non-web platforms
// This file is used when running on Windows/Mobile/Desktop

void registerWebViewFactory(
  String viewType,
  dynamic Function(int viewId) viewFactory,
) {
  // Empty implementation for non-web platforms
  // This prevents compilation errors on platforms that don't support dart:ui_web
  throw UnsupportedError(
    'Platform views are not supported on this platform',
  );
}
