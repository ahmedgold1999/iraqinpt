import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class CertificateVerificationScreen extends StatefulWidget {
  const CertificateVerificationScreen({super.key});

  @override
  State<CertificateVerificationScreen> createState() =>
      _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState
    extends State<CertificateVerificationScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';
  bool _cameraPermissionGranted = false;

  static const String _certificateCheckUrl = 'https://qr.uob.edu.iq/';

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _cameraPermissionGranted = status.isGranted;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Camera permission check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFACC15), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'فحص وتدقيق الشهادة',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'منظومة التحقق من الوثائق (QR)',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: Color(0xFFFACC15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'إعادة التحميل',
            onPressed: () => _webViewController?.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 1.0
              ? LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFFACC15),
                  minHeight: 3,
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط تنبيه في حال عدم منح إذن الكاميرا
            if (!_cameraPermissionGranted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'يلزم تفعيل الكاميرا لمسح رمز الـ QR مباشرة من الوثيقة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final status = await Permission.camera.request();
                        if (status.isPermanentlyDenied) {
                          await openAppSettings();
                        }
                        if (mounted) {
                          setState(() {
                            _cameraPermissionGranted = status.isGranted;
                          });
                          if (status.isGranted) {
                            _webViewController?.reload();
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'سماح للكاميرا',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_certificateCheckUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      supportMultipleWindows: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      userAgent: (defaultTargetPlatform == TargetPlatform.iOS)
                          ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1'
                          : 'Mozilla/5.0 (Linux; Android 13; SM-S908E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.210 Mobile Safari/537.36',
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      setState(() {
                        _hasError = true;
                        _errorMessage = error.description;
                      });
                    },
                    onPermissionRequest: (controller, request) async {
                      // طلب إذن الكاميرا من نظام التشغيل ثم منح الإذن للويب
                      final status = await Permission.camera.request();
                      if (status.isGranted) {
                        setState(() => _cameraPermissionGranted = true);
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      }
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.DENY,
                      );
                    },
                  ),

                  if (_hasError)
                    Container(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'تعذر الاتصال ببوابة فحص الشهادات',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى التأكد من اتصال الإنترنت أو معاودة المحاولة لاحقاً',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                              });
                              _webViewController?.reload();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text(
                              'إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C31) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: () async {
                    if (await _webViewController?.canGoBack() ?? false) {
                      _webViewController?.goBack();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  onPressed: () async {
                    if (await _webViewController?.canGoForward() ?? false) {
                      _webViewController?.goForward();
                    }
                  },
                ),
              ],
            ),
            const Text(
              '🔒 بوابة رسمية آمنة ومشفرة · جامعة بغداد',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11.5,
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
