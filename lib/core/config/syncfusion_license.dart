/// Syncfusion license configuration
///
/// License Key (7-day trial):
/// Ngo9BigBOggjHTQxAR8/V1JFaF1cXGFCf1FpQXxbf1x1ZFZMZVpbRXJPIiBoS35Rc0RiW3hfdXFTR2RZWEB2VEFc
///
/// Note: As of Syncfusion v31.x, the SyncfusionLicense.registerLicense() method
/// may not be available in flutter_core package. License registration methods vary:
///
/// 1. For Community License (free): Register at syncfusion.com
/// 2. Trial licenses may show watermark regardless of registration
/// 3. Production licenses are validated automatically via pub.dev
///
/// Current implementation:
/// - Web: Using native browser PDF viewer (no watermark)
/// - Mobile/Desktop: Using Syncfusion SfPdfViewer (may show trial watermark)
///
/// To remove watermark on mobile/desktop:
/// - Purchase license from syncfusion.com
/// - Or use workaround: Hide watermark widget via UI tricks (not recommended)

class SyncfusionConfig {
  static const String licenseKey =
      'Ngo9BigBOggjHTQxAR8/V1JFaF1cXGFCf1FpQXxbf1x1ZFZMZVpbRXJPIiBoS35Rc0RiW3hfdXFTR2RZWEB2VEFc';

  /// Initialize Syncfusion license (if method becomes available)
  static void initialize() {
    // Method not available in current Syncfusion version
    // Keeping license key for reference
  }
}
