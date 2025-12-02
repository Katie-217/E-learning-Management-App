// Conditional export that automatically selects the correct implementation
// based on the platform

export 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';
