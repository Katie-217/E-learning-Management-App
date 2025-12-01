// Web-specific PDF helper for registering platform views
// This file should only be imported/used on web platform

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

// Conditional import - only loads dart:ui_web on web
// ignore: uri_does_not_exist
import 'dart:ui_web' if (dart.library.io) 'web_pdf_helper_stub.dart';

/// Registers a platform view factory for PDF iframe (web only)
void registerPdfViewFactory(String viewType, String blobUrl) {
  if (!kIsWeb) {
    // Non-web platforms - do nothing
    return;
  }

  try {
    // This will only execute on web where platformViewRegistry exists
    // ignore: undefined_prefixed_name
    platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        return html.IFrameElement()
          ..src = blobUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
      },
    );
  } catch (e) {
    // Already registered or other error
    print('View factory registration: $e');
  }
}
