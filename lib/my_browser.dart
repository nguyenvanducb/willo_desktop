import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
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
import 'package:willo_desktop/new_screen.dart';
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
  APIManager apiManager = APIManager(HTTPManager(Dio()));

  InAppWebViewController? webViewController;
  CookieManager cookieManager = CookieManager();
  bool backUp = false;

  InAppWebViewSettings settings = InAppWebViewSettings(
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

    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              id: 1,
              title: "Special",
              action: () async {
                print("Menu item Special clicked!");
                print(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          print("onCreateContextMenu");
          print(hitTestResult.extra);
          print(await webViewController?.getSelectedText());
        },
        onHideContextMenu: () {
          print("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = contextMenuItemClicked.id;
          print(
              "onContextMenuActionItemClicked: $id ${contextMenuItemClicked.title}");
        });

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest: URLRequest(
                        url: await webViewController?.getUrl(),
                        cachePolicy: URLRequestCachePolicy
                            .RELOAD_REVALIDATING_CACHE_DATA));
              }
            },
          );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var widthS = MediaQuery.of(context).size.width;
    var heightS = MediaQuery.of(context).size.height;
    return Scaffold(
        body: SafeArea(
            child: Column(children: <Widget>[
      // const TitleBar(),
      Expanded(
        child: Stack(
          children: [
            DropTarget(
              onDragDone: (details) async {
                final files = <Map<String, String>>[];

                for (final file in details.files) {
                  final bytes = await file.readAsBytes();
                  final base64Str = base64Encode(bytes)
                      .replaceAll('\n', '')
                      .replaceAll('\r', '');
                  final name = file.name;
                  final mime = file.mimeType ?? 'application/octet-stream';

                  files.add({
                    'base64': base64Str,
                    'name': name,
                    'mime': mime,
                  });
                }

                final filesJson = jsonEncode(files);

                await webViewController?.evaluateJavascript(source: '''
                (async () => {
                  try {
                    const files = $filesJson;
                    const fileList = [];
                    // 👉 Focus lại sau khi thêm file (tránh mất sự kiện chuột)
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
              },
              child: InAppWebView(
                key: webViewKey,
                webViewEnvironment: webViewEnvironment,
                initialUrlRequest:
                    URLRequest(url: WebUri('https://msg.winitech.com/chat')),
                initialUserScripts: UnmodifiableListView<UserScript>([]),
                initialSettings: settings,
                contextMenu: contextMenu,
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) async {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) async {
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                  });
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT);
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) async {
                  pullToRefreshController?.endRefreshing();
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                  });

                  print(url);
                  try {
                    List<Cookie> cookies =
                        await cookieManager.getCookies(url: url!);
                    for (var cookie in cookies) {
                      print('Cookie: ${cookie.name} = ${cookie.value}');
                    }
                    notify(cookies[0].value);
                  } catch (e) {
                    String token = url.toString();
                    token = token.replaceFirst(
                        'https://msg.winitech.com/?token=', '');
                    notify(token);
                  }
                },
                onReceivedError: (controller, request, error) {
                  pullToRefreshController?.endRefreshing();
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    pullToRefreshController?.endRefreshing();
                  }
                  setState(() {
                    this.progress = progress / 100;
                    urlController.text = url;
                  });
                },
                onUpdateVisitedHistory: (controller, url, isReload) {
                  String domain = url!.host;
                  print('ducnguyenbbb');
                  print(domain);
                  if (domain == 'msg.winitech.com' ||
                      domain == 'msgauth.winitech.com') {
                    setState(() {
                      backUp = false;
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  } else {
                    setState(() {
                      backUp = true;
                    });
                  }
                },
                onConsoleMessage: (controller, consoleMessage) {
                  print(consoleMessage);
                },
              ),
            ),
            progress < 1.0
                ? LinearProgressIndicator(value: progress)
                : Container(),
            if (widthS > heightS * 1.3)
              if (!backUp)
                Positioned(
                    bottom: 5,
                    left: 3,
                    child: Tooltip(
                      message: 'Web',
                      textStyle: const TextStyle(
                        color: Colors.yellow, // Màu chữ vàng cho tooltip
                        fontWeight: FontWeight.w400,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          WebUri webUri = WebUri(
                              'https://msg.winitech.com/chat' + getTocken());
                          if (await canLaunchUrl(webUri)) {
                            await launchUrl(webUri);
                          }
                        },
                        icon: const Icon(
                          Icons.web,
                          size: 35,
                          color: Colors.orange,
                        ),
                      ),
                    )),
            if (backUp)
              Positioned(
                  top: 5,
                  left: 3,
                  child: ElevatedButton(
                    child: const Icon(Icons.arrow_back),
                    onPressed: () {
                      webViewController?.goBack();
                    },
                  ))
          ],
        ),
      ),
    ])));
  }

  notify(token) async {
    print('kkkkkkkkkkkkk\n$token');
    Provider.of<UserData>(context, listen: false).connectWebSocket(token);
    await DataCenter.shared()?.saveToken(token);
    getMe();
  }

  getMe() async {
    var data = await apiManager.getMe(data: {});
    if (data.success) {
      setState(() {
        dataUser = data.data;
      });
    }
  }

  getTocken() {
    try {
      // ignore: prefer_interpolation_to_compose_strings
      return '?token=' + dataUser['user']['accessToken'];
    } catch (e) {
      return '';
    }
  }
}
