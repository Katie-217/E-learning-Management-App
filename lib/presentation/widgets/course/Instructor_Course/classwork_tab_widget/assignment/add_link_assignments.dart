import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Model to store link metadata
class LinkMetadata {
  final String url;
  final String title;
  final String? imageUrl;
  final String? description;
  final String domain;

  LinkMetadata({
    required this.url,
    required this.title,
    this.imageUrl,
    this.description,
    required this.domain,
  });

  /// Create LinkMetadata from Cloud Function response
  factory LinkMetadata.fromJson(Map<String, dynamic> json) {
    return LinkMetadata(
      url: json['url'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      domain: json['domain'] as String,
    );
  }
}

/// Service to fetch link metadata using Firebase Cloud Functions
///
/// Uses Cloud Functions SDK on Web/Mobile, HTTP fallback on Desktop
class LinkMetadataService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static const String _functionHttpUrl =
      'https://us-central1-e-learning-management-79797.cloudfunctions.net/fetchLinkPreview';

  /// Check if running on Desktop platform
  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Fetch metadata using Cloud Functions
  static Future<LinkMetadata?> fetchMetadata(String url) async {
    try {
      // Validate URL
      final uri = Uri.tryParse(url);
      if (uri == null ||
          (!uri.hasScheme ||
              (!uri.isScheme('http') && !uri.isScheme('https')))) {
        print('❌ Invalid URL: $url');
        return null;
      }

      print('🔍 Fetching link preview: $url');
      print(
          '📱 Platform: ${_isDesktop ? "Desktop (HTTP)" : "Web/Mobile (SDK)"}');

      // Desktop: Use HTTP request (Cloud Functions SDK có issue trên desktop)
      if (_isDesktop) {
        return await _fetchViaHttp(url);
      }

      // Web/Mobile: Use Cloud Functions SDK
      return await _fetchViaCallable(url);
    } catch (e) {
      print('❌ Error fetching metadata: $e');
      return _createFallbackMetadata(url);
    }
  }

  /// Fetch via Callable Functions (Web/Mobile)
  static Future<LinkMetadata?> _fetchViaCallable(String url) async {
    try {
      final callable = _functions.httpsCallable(
        'fetchLinkPreview',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'url': url,
      });

      final data = result.data;

      if (data['success'] == true) {
        print('✅ Link preview success: ${data['title']}');
        return LinkMetadata.fromJson(data);
      } else {
        print('⚠️ Link preview failed: ${data['error']}');
        return _createFallbackMetadata(url);
      }
    } on FirebaseFunctionsException catch (e) {
      print('❌ Cloud Functions SDK error: ${e.code} - ${e.message}');
      return _createFallbackMetadata(url);
    }
  }

  /// Fetch via HTTP (Desktop fallback)
  static Future<LinkMetadata?> _fetchViaHttp(String url) async {
    try {
      print('📡 Calling Cloud Function via HTTP...');

      final response = await http
          .post(
        Uri.parse(_functionHttpUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {'url': url},
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Cloud Functions HTTP response wraps in 'result'
        final result = data['result'] ?? data;

        if (result['success'] == true) {
          print('✅ Link preview success: ${result['title']}');
          return LinkMetadata.fromJson(result);
        } else {
          print('⚠️ Link preview failed: ${result['error']}');
          return _createFallbackMetadata(url);
        }
      } else {
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
        return _createFallbackMetadata(url);
      }
    } catch (e) {
      print('❌ HTTP request error: $e');
      return _createFallbackMetadata(url);
    }
  }

  /// Create fallback metadata when fetching fails
  static LinkMetadata _createFallbackMetadata(String url) {
    final uri = Uri.parse(url);
    return LinkMetadata(
      url: url,
      title: uri.host,
      domain: uri.host,
    );
  }
}

/// Widget to display link preview card (similar to Google Classroom)
class LinkPreviewCard extends StatelessWidget {
  final LinkMetadata metadata;
  final VoidCallback? onRemove; // Đổi thành optional (nullable)

  const LinkPreviewCard({
    super.key,
    required this.metadata,
    this.onRemove, // Không bắt buộc
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () async {
              final uri = Uri.parse(metadata.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Thumbnail Image
                if (metadata.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: Image.network(
                      metadata.imageUrl!,
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    ),
                  )
                else
                  _buildPlaceholderImage(),

                // Right: Link Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          metadata.title,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Domain
                        Text(
                          metadata.domain,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove Button (X) - Chỉ hiện khi onRemove không null
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Icon(
        Icons.link,
        size: 32,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Dialog widget to add link with preview
class AddLinkDialog extends StatefulWidget {
  final Function(LinkMetadata) onLinkAdded;

  const AddLinkDialog({super.key, required this.onLinkAdded});

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  LinkMetadata? _preview;
  bool _isLoadingPreview = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final metadata =
          await LinkMetadataService.fetchMetadata(_urlController.text.trim());

      if (metadata != null) {
        setState(() {
          _preview = metadata;
          _isLoadingPreview = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not fetch link preview. Please check the URL.';
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading preview: $e';
        _isLoadingPreview = false;
      });
    }
  }

  void _addLink() {
    if (_preview != null) {
      widget.onLinkAdded(_preview!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.link, color: Colors.indigo, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // URL Input
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste URL here (e.g., YouTube, news article)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.indigo, width: 2),
                  ),
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _urlController.clear();
                              _preview = null;
                              _errorMessage = null;
                            });
                          },
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme) {
                    return 'Please enter a valid URL (starting with http:// or https://)';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _preview = null;
                    _errorMessage = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Load Preview Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoadingPreview ? null : _loadPreview,
                  icon: _isLoadingPreview
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label:
                      Text(_isLoadingPreview ? 'Loading...' : 'Load Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Preview Card
              if (_preview != null) ...[
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'Preview:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinkPreviewCard(
                  metadata: _preview!,
                  onRemove: () {
                    setState(() {
                      _preview = null;
                    });
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _preview != null ? _addLink : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: const Text('Add Link'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
