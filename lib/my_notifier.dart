import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:willo_desktop/main.dart';
import 'package:willo_desktop/my_browser.dart';
import 'package:willo_desktop/share_preferences/data_center.dart';
import 'package:willo_desktop/url.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

bool isNetwork = true;
Map<String, dynamic> idConversationMap = {};

class UserData extends ChangeNotifier {
  bool showWindows = false;
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
          print(dataChat['basicConversationInfo']['alarm']);
          if (dataChat['announcer']['userId'] != dataUser['user']['userId']) {
            if (dataChat['basicConversationInfo']['alarm'] ?? false) {
              filterNotify(dataChat);
            }
          }
        } catch (e) {}
      }, onDone: () {
        try {
          if (!isNetwork) return;
          debugPrint('WebSocket connection closed');
          channel.sink.close();
          Future.delayed(const Duration(milliseconds: 100), () {
            channel.sink.close();
            connectWebSocket(token);
          });
        } catch (e) {}
      }, onError: (e) {});
    } catch (e) {}
  }

  String removeHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void filterNotify(dataChat) async {
    try {
      if (!dataChat['basicConversationInfo']['alarm']) return;
    } catch (e) {
      return;
    }
    var myID = await DataCenter.shared()?.getUserName() ?? '';
    var requestUuidOnly = await DataCenter.shared()?.getRequestUuidOnly() ?? '';
    var token = await DataCenter.shared()?.getToken() ?? '';
    dynamic dataMess = dataChat['message'] ?? dataChat['mail'];
    if (token.length < 5) return;
    dataMess['senderId'] = dataMess['senderId'].toLowerCase();
    myID = myID.toLowerCase();
    if (dataMess['senderId'] == myID) return;
    if (requestUuidOnly == dataMess['requestUuid']) return;
    DataCenter.shared()?.saveRequestUuidOnly(dataMess['requestUuid']);
    try {
      switch (dataChat['type']) {
        case 'REACTION_MESSAGE':
          if (dataChat['announcer']['userId'] != myID) {
            if (dataMess['senderId'] == myID) {
              showDynamicNotification(
                  content: dataChat["languageMap"]["message.event.reaction"],
                  title: dataChat['announcer']['userName']);
            }
          }
          break;
        case 'SHARE_MESSAGE':
          if (dataChat['announcer']['userId'] != myID) {
            showDynamicNotification(
              title: dataChat['announcer']['userName'],
              content: dataChat["languageMap"]["message.event.shareMessage"],
            );
          }
          break;
        default:
          if (dataMess['senderId'] != myID) {
            if (dataMess['contentType'] == 'TEXT' ||
                dataMess['contentType'] == 'IMAGE' ||
                dataMess['contentType'] == null) {
              showDynamicNotification(
                content: removeHtmlTags(dataMess['content']),
                title:
                    dataMess['senderName'] ?? dataChat['announcer']['userName'],
              );
            }
            if (dataMess['contentType'] == 'FILE') {
              showDynamicNotification(
                content: dataMess['shortName'],
                title: dataMess['senderName'],
              );
            }
          }
      }
    } catch (e) {}
  }

  void clearDataSocket() {
    dataChat = {
      'basicConversationInfo': {'conversationId': ''},
      'message': null,
    };
  }

  void showDynamicNotification({String content = '', title = ''}) {
    print('aaaaaaaaaaaaaabbbbbbbbbbbbbbb');
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
            <text>$title</text>
             <text>$content</text>
        </binding>
    </visual>
</toast>
''';

    NotificationMessage message = NotificationMessage.fromCustomTemplate(
      "test1",
      group: "jj",
    );
    _winNotifyPlugin.showNotificationCustomTemplate(message, template);
    WindowsTaskbar.setFlashTaskbarAppIcon(
      mode: TaskbarFlashMode.all,
      flashCount: 500,
      timeout: const Duration(milliseconds: 100),
    );
    _winNotifyPlugin.initNotificationCallBack((s) async {
      if (s.eventType == EventType.onActivate) {
        await windowManager.show(inactive: true);
        print('ddddddddd');
      }
    });
    WindowsTaskbar.resetFlashTaskbarAppIcon;
  }
}
