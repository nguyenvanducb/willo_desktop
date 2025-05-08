import 'dart:collection';
import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:willo_desktop/api/api_manager.dart';
import 'package:willo_desktop/api/http_manager.dart';
import 'package:willo_desktop/my_notifier.dart';
import 'package:willo_desktop/share_preferences/data_center.dart';
import 'main.dart';

dynamic dataUser = '';

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({super.key});

  @override
  _InAppWebViewExampleScreenState createState() =>
      _InAppWebViewExampleScreenState();
}

class _InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen> {
  final GlobalKey webViewKey = GlobalKey();
  // Sử dụng late để tạo một lần khi cần thiết
  late final APIManager apiManager = APIManager(HTTPManager(Dio()));

  InAppWebViewController? webViewController;
  final CookieManager cookieManager = CookieManager();
  bool backUp = false;
  String urlOrigin = '';

  // Cấu hình settings cho InAppWebView
  final InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      appCachePath: "C:\\willo",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;

  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await getToken();
    _initializeContextMenu();
    _initializePullToRefresh();
  }

  void _initializeContextMenu() {
    contextMenu = ContextMenu(
      menuItems: [
        ContextMenuItem(
            id: 1,
            title: "Special",
            action: () async {
              try {
                final selectedText = await webViewController?.getSelectedText();
                debugPrint(
                    "Menu item Special clicked! Selected text: $selectedText");
                await webViewController?.clearFocus();
              } catch (e) {
                debugPrint("Error in context menu action: $e");
              }
            })
      ],
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
      onCreateContextMenu: (hitTestResult) async {
        try {
          final selectedText = await webViewController?.getSelectedText();
          debugPrint(
              "onCreateContextMenu: ${hitTestResult.extra}, Selected: $selectedText");
        } catch (e) {
          debugPrint("Error in onCreateContextMenu: $e");
        }
      },
      onHideContextMenu: () {
        debugPrint("onHideContextMenu");
      },
      onContextMenuActionItemClicked: (contextMenuItemClicked) {
        debugPrint(
            "onContextMenuActionItemClicked: ${contextMenuItemClicked.id} ${contextMenuItemClicked.title}");
      },
    );
  }

  void _initializePullToRefresh() {
    // Kiểm tra nền tảng trước khi tạo controller
    final bool supportedPlatform = !kIsWeb &&
        [TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform);

    if (!supportedPlatform) {
      pullToRefreshController = null;
      return;
    }

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: () async {
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            await webViewController?.reload();
          } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            final currentUrl = await webViewController?.getUrl();
            if (currentUrl != null) {
              await webViewController?.loadUrl(
                  urlRequest: URLRequest(
                      url: currentUrl,
                      cachePolicy: URLRequestCachePolicy
                          .RELOAD_REVALIDATING_CACHE_DATA));
            }
          }
        } catch (e) {
          debugPrint("Error during refresh: $e");
        } finally {
          pullToRefreshController?.endRefreshing();
        }
      },
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    // Giải phóng các tài nguyên khác nếu cần
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > screenSize.height * 1.3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  _buildWebView(),
                  if (progress < 1.0) LinearProgressIndicator(value: progress),
                  if (isWideScreen && !backUp) _buildWebButton(),
                  if (backUp) _buildBackButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    // Chỉ hiển thị WebView khi URL có sẵn
    if (urlOrigin.length < 50) {
      return const SizedBox();
    }

    return DropTarget(
      onDragDone: _handleFileDrop,
      child: InAppWebView(
        key: webViewKey,
        webViewEnvironment: webViewEnvironment,
        initialUrlRequest: URLRequest(url: WebUri(urlOrigin)),
        initialUserScripts: UnmodifiableListView<UserScript>([]),
        initialSettings: settings,
        contextMenu: contextMenu,
        pullToRefreshController: pullToRefreshController,
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: _handleLoadStart,
        onPermissionRequest: _handlePermissionRequest,
        shouldOverrideUrlLoading: _handleUrlLoading,
        onLoadStop: _handleLoadStop,
        onReceivedError: _handleError,
        onProgressChanged: _handleProgressChanged,
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("WebView Console: ${consoleMessage.message}");
        },
      ),
    );
  }

  Widget _buildWebButton() {
    return Positioned(
      bottom: 5,
      left: 3,
      child: Tooltip(
        message: 'Web',
        textStyle: const TextStyle(
          color: Colors.yellow,
          fontWeight: FontWeight.w400,
        ),
        child: IconButton(
          onPressed: _openInBrowser,
          icon: const Icon(
            Icons.web,
            size: 35,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 5,
      left: 3,
      child: ElevatedButton(
        onPressed: () {
          webViewController?.goBack();
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  Future<void> _handleFileDrop(DropDoneDetails details) async {
    try {
      final files = <Map<String, String>>[];

      for (final file in details.files) {
        final bytes = await file.readAsBytes();
        final base64Str =
            base64Encode(bytes).replaceAll('\n', '').replaceAll('\r', '');
        final name = file.name;
        final mime = file.mimeType ?? 'application/octet-stream';

        files.add({
          'base64': base64Str,
          'name': name,
          'mime': mime,
        });
      }

      final filesJson = jsonEncode(files);
      await _injectFileUploadScript(filesJson);
    } catch (e) {
      debugPrint("Error handling file drop: $e");
    }
  }

  Future<void> _injectFileUploadScript(String filesJson) async {
    await webViewController?.evaluateJavascript(source: '''
    (async () => {
      try {
        const files = $filesJson;
        const fileList = [];
        // Focus lại sau khi thêm file (tránh mất sự kiện chuột)
        setTimeout(() => {
          document.activeElement?.focus();
        }, 10);
        for (const f of files) {
          const binary = atob(f.base64);
          const array = Uint8Array.from(binary, c => c.charCodeAt(0));
          const file = new File([array], f.name, { type: f.mime });
          fileList.push(file);
        }

        const inputs = document.querySelectorAll('input[type="file"]');
        if (inputs.length > 0) {
          const input = inputs[0];
          const dt = new DataTransfer();
          for (const file of fileList) {
            dt.items.add(file);
          }
          input.files = dt.files;

          const evt = new Event("change", { bubbles: true });
          input.dispatchEvent(evt);
        } else {
          console.warn("❌ Không tìm thấy input file!");
        }
      } catch (e) {
        console.error("🚨 Lỗi xử lý đa file:", e);
      }
    })();
    ''');
  }

  void _handleLoadStart(InAppWebViewController controller, WebUri? url) {
    if (url == null) return;

    setState(() {
      this.url = url.toString();
      urlController.text = this.url;
    });
  }

  Future<PermissionResponse> _handlePermissionRequest(
      InAppWebViewController controller, PermissionRequest request) async {
    return PermissionResponse(
        resources: request.resources, action: PermissionResponseAction.GRANT);
  }

  Future<NavigationActionPolicy> _handleUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _handleLoadStop(
      InAppWebViewController controller, WebUri? url) async {
    if (url == null) return;

    pullToRefreshController?.endRefreshing();

    setState(() {
      this.url = url.toString();
      urlController.text = this.url;
    });

    debugPrint("Loaded URL: $url");

    try {
      // Trích xuất token từ cookie hoặc URL
      String token;
      try {
        List<Cookie> cookies = await cookieManager.getCookies(url: url);
        if (cookies.isNotEmpty) {
          token = cookies[0].value;
        } else {
          throw Exception("No cookies found");
        }
      } catch (e) {
        token =
            url.toString().replaceFirst('https://msg.winitech.com/?token=', '');
      }

      await notify(token);
    } catch (e) {
      debugPrint("Error handling load stop: $e");
    }
  }

  void _handleError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error) {
    pullToRefreshController?.endRefreshing();
    debugPrint("WebView Error: ${error.description} at ${request.url}");
  }

  void _handleProgressChanged(InAppWebViewController controller, int progress) {
    setState(() {
      this.progress = progress / 100;
      urlController.text = url;
    });

    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
  }

  void _handleVisitedHistory(
      InAppWebViewController controller, WebUri? url, bool isReload) {
    if (url == null) return;

    String domain = url.host;

    setState(() {
      backUp =
          !(domain == 'msg.winitech.com' || domain == 'msgauth.winitech.com');
      if (!backUp) {
        this.url = url.toString();
        urlController.text = this.url;
      }
    });
  }

  Future<void> _openInBrowser() async {
    try {
      final webUri = WebUri(urlOrigin);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      } else {
        debugPrint("Cannot launch URL: $urlOrigin");
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  Future<void> notify(String token) async {
    try {
      if (!mounted) return;

      Provider.of<UserData>(context, listen: false).connectWebSocket(token);
      await DataCenter.shared()?.saveToken(token);
      await getMe();
    } catch (e) {
      debugPrint("Error in notify: $e");
    }
  }

  Future<void> getMe() async {
    try {
      final response = await apiManager.getMe(data: {});
      if (response.success && mounted) {
        setState(() {
          dataUser = response.data;
        });
      }
    } catch (e) {
      debugPrint("Error in getMe: $e");
    }
  }

  Future<void> getToken() async {
    String token = '';
    try {
      // Lấy token từ DataCenter
      token = await DataCenter.shared()?.getToken() ?? '';

      // Cố gắng lấy token từ dataUser nếu có
      if (dataUser != null &&
          dataUser is Map &&
          dataUser['user'] != null &&
          dataUser['user'] is Map &&
          dataUser['user']['accessToken'] != null &&
          dataUser['user']['accessToken'].toString().isNotEmpty) {
        urlOrigin =
            'https://msg.winitech.com?token=${dataUser['user']['accessToken']}';
      } else {
        // Sử dụng token dự phòng nếu không lấy được từ dataUser
        if (token.isNotEmpty) {
          urlOrigin = 'https://msg.winitech.com?token=$token';
        } else {
          // Xử lý trường hợp không có token nào hợp lệ
          debugPrint('Warning: No valid token available');
          urlOrigin = 'https://msg.winitech.com';
        }
      }
    } catch (e) {
      debugPrint('Error in getToken: $e');
      // Sử dụng token đã lấy được trước khi xảy ra lỗi (nếu có)
      if (token.isNotEmpty) {
        urlOrigin = 'https://msg.winitech.com?token=$token';
      } else {
        urlOrigin = 'https://msg.winitech.com';
      }
    } finally {
      // Cập nhật UI
      if (mounted) {
        setState(() {});
      }
    }
  }
}
