import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:willo_desktop/api/api_manager.dart';
import 'package:willo_desktop/api/http_manager.dart';
import 'package:willo_desktop/my_notifier.dart';
import 'package:willo_desktop/share_preferences/data_center.dart';
import 'main.dart';

dynamic dataUserGB = '';

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
    return InAppWebView(
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

        WebUri webUri = url!;
        List<Cookie> cookies = await cookieManager.getCookies(url: webUri);
        for (var cookie in cookies) {
          print('Cookie: ${cookie.name} = ${cookie.value}');
        }
        Provider.of<UserData>(context, listen: false)
            .connectWebSocket(cookies[0].value);
        await DataCenter.shared()?.saveToken(cookies[0].value);
        getMe();
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
        setState(() {
          this.url = url.toString();
          urlController.text = this.url;
        });
      },
      onConsoleMessage: (controller, consoleMessage) {
        print(consoleMessage);
      },
    );
  }

  getMe() async {
    var data = await apiManager.getMe(data: {});
    if (data.success) {
      setState(() {
        dataUserGB = data.data;
      });
    }
  }
}
