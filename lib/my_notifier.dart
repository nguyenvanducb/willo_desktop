import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:willo_desktop/main.dart';
import 'package:willo_desktop/my_browser.dart';
import 'package:willo_desktop/url.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

bool isNetwork = true;

class UserData extends ChangeNotifier {
  bool showWindows = false;
  dynamic dataUser;
  dynamic infoUsers;
  dynamic dataChat = {
    'basicConversationInfo': {'conversationId': ''}
  };
  final AppWindow _appWindow = AppWindow();
  final _winNotifyPlugin = WindowsNotification(
      applicationId: '${Directory.current.path}\\willo_desktop.exe');

  void connectWebSocket(token) {
    final channel = WebSocketChannel.connect(
      Uri.parse(URL_WEBSOCKET_RECEIVE + token),
    );
    try {
      channel.stream.listen((message) {
        try {
          dataChat = jsonDecode(message);
          dataChat['isSocket'] = true;
          notifyListeners();
          try {
            if (dataChat['message']['senderId'] !=
                dataUserGB['user']['userId']) {
              if (dataChat['message']['contentType'] == 'TEXT' ||
                  dataChat['message']['contentType'] == 'IMAGE' ||
                  dataChat['message']['contentType'] == 'FILE') {
                sendMyOwnTemplate(
                    content: dataChat['message']['content'],
                    tittle: dataChat['message']['senderName']);
              }
            }
          } catch (e) {}
        } catch (e) {}
      }, onDone: () {
        try {
          if (!isNetwork) return;
          debugPrint('WebSocket connection closed');
          channel.sink.close();
          Future.delayed(const Duration(milliseconds: 100), () {
            connectWebSocket(token);
          });
        } catch (e) {}
      }, onError: (e) {
        debugPrint(e);
      });
    } catch (e) {}
  }

  void clearDataSocket() {
    dataChat = {
      'basicConversationInfo': {'conversationId': ''},
      'message': null,
    };
  }

  void sendMyOwnTemplate({String content = '', tittle = ''}) {
    if (!isNotify) {
      isNotify = true;
      WindowsTaskbar.setOverlayIcon(
          ThumbnailToolbarAssetIcon('assets/circle.ico'));
    }

    /// image tag src must be set
    /// for actions make sure your argruments contains `:` like "action:open_center"
    String template = '''
<?xml version="1.0" encoding="utf-8"?>
  <toast launch='conversationId=9813' activationType="background">
    <visual>
        <binding template='ToastGeneric'>
            <text>$tittle</text>
             <text>$content</text>
        </binding>
    </visual>
</toast>
''';

    NotificationMessage message = NotificationMessage.fromCustomTemplate(
      "test1",
      group: "jj",
    );
    _winNotifyPlugin
        .showNotificationCustomTemplate(message, template)
        .then((value) {
      // Xử lý sau khi thông báo được hiển thị thành công
      print("Thông báo đã được hiển thị!");
    }).catchError((error) {
      // Xử lý lỗi nếu có
      print("Có lỗi xảy ra: $error");
    });
    _winNotifyPlugin
        .initNotificationCallBack((NotificationCallBackDetails details) async {
      print("Notification clicked: ${details.toString()}");
      await windowManager.show(inactive: true);
    });
  }

  void resetStateWindows() {
    showWindows = false;
  }
}
