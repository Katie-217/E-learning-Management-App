// Stub for non-web platforms
// This file is imported when dart.library.io is available (non-web)

// Empty class to satisfy import on non-web platforms
class platformViewRegistry {
  static void registerViewFactory(
      String viewType, dynamic Function(int) callback) {
    // Stub - does nothing on non-web platforms
    throw UnsupportedError('platformViewRegistry is only available on web');
  }
}
