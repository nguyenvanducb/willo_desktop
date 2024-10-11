import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:willo_desktop/my_browser.dart';
import 'package:willo_desktop/my_notifier.dart';
import 'package:willo_desktop/myclose.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_taskbar/windows_taskbar.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final localhostServer = InAppLocalhostServer(documentRoot: 'assets');
bool isNotify = false, windowFocus = false;
WebViewEnvironment? webViewEnvironment;
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowsSingleInstance.ensureSingleInstance(args, "instance_checker",
      onSecondWindow: (args) {});
  // Khởi tạo window manager
  await windowManager.ensureInitialized();

  // Cấu hình cửa sổ khi ứng dụng khởi động
  windowManager.setBackgroundColor(backgroundEndColor);
  windowManager.waitUntilReadyToShow().then((_) async {
    windowManager.setPreventClose(true);
    windowManager.addListener(MyWindowListener());
    //   // Ẩn các nút Close, Minimize, Maximize
    //   await windowManager.setClosable(false);
    //   await windowManager.setMinimizable(false);
    //   await windowManager.setMaximizable(false);
    //   await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    //   await windowManager.show();
    //   await windowManager.focus();
  });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserData()),
        // Cung cấp các provider khác nếu cần
      ],
      child: const MyApp(),
    ),
  );

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(600, 450);
    win.alignment = Alignment.center;
    win.title = "WillO";
    win.show();
  });
}

String getTrayImagePath(String imageName) {
  return Platform.isWindows ? 'assets/$imageName.ico' : 'assets/$imageName.png';
}

String getImagePath(String imageName) {
  return Platform.isWindows ? 'assets/$imageName.bmp' : 'assets/$imageName.png';
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  final AppWindow _appWindow = AppWindow();
  final SystemTray _systemTray = SystemTray();
  final Menu _menuMain = Menu();
  final Menu _menuSimple = Menu();

  Timer? _timer;
  bool _toogleTrayIcon = true;

  bool _toogleMenu = true;

  @override
  void initState() {
    super.initState();
    initSystemTray();
    windowManager.addListener(this);
  }

  @override
  void onWindowFocus() {
    // Cửa sổ có tiêu điểm
    print("Cửa sổ đã được lấy tiêu điểm");
    isNotify = false;
    windowFocus = true;
    WindowsTaskbar.resetOverlayIcon();
  }

  @override
  void onWindowUnfocus() {
    windowFocus = false;
    print("Cửa sổ đã mất tiêu điểm");
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  Future<void> initSystemTray() async {
    List<String> iconList = ['darts_icon', 'gift_icon'];

    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(iconPath: getTrayImagePath('app_icon'));
    _systemTray.setTitle("system tray");
    _systemTray.setToolTip("WillO");

    // handle system tray event
    _systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? _appWindow.show() : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? _systemTray.popUpContextMenu() : _appWindow.show();
      }
    });

    await _menuMain.buildFrom(
      [
        MenuItemLabel(
            label: 'Show',
            image: getImagePath('darts_icon'),
            onClicked: (menuItem) => _appWindow.show()),
        MenuItemLabel(
            label: 'Hide',
            image: getImagePath('darts_icon'),
            onClicked: (menuItem) => _appWindow.hide()),
        MenuItemLabel(
          label: 'Start flash tray icon',
          image: getImagePath('darts_icon'),
          onClicked: (menuItem) {
            debugPrint("Start flash tray icon");

            _timer ??= Timer.periodic(
              const Duration(milliseconds: 500),
              (timer) {
                _toogleTrayIcon = !_toogleTrayIcon;
                _systemTray.setImage(
                    _toogleTrayIcon ? "" : getTrayImagePath('app_icon'));
              },
            );
          },
        ),
        MenuItemLabel(
          label: 'Stop flash tray icon',
          image: getImagePath('darts_icon'),
          onClicked: (menuItem) {
            debugPrint("Stop flash tray icon");

            _timer?.cancel();
            _timer = null;

            _systemTray.setImage(getTrayImagePath('app_icon'));
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
            label: 'Exit', onClicked: (menuItem) => _appWindow.close()),
      ],
    );

    await _menuSimple.buildFrom([
      MenuItemLabel(
        label: 'Change Context Menu',
        image: getImagePath('app_icon'),
        onClicked: (menuItem) {
          debugPrint("Change Context Menu");

          _toogleMenu = !_toogleMenu;
          _systemTray.setContextMenu(_toogleMenu ? _menuMain : _menuSimple);
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
          label: 'Show',
          image: getImagePath('app_icon'),
          onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(
          label: 'Hide',
          image: getImagePath('app_icon'),
          onClicked: (menuItem) => _appWindow.hide()),
      MenuItemLabel(
          label: 'Exit',
          image: getImagePath('app_icon'),
          onClicked: (menuItem) {
            windowManager.setPreventClose(false);
            _appWindow.close();
          }),
    ]);

    _systemTray.setContextMenu(_menuMain);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const InAppWebViewExampleScreen(),
    );
  }
}

const backgroundStartColor = Color(0xFFFFFFFF);
const backgroundEndColor = Color(0xFFFFFFFF);

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundStartColor, backgroundEndColor],
              stops: [0.0, 1.0]),
        ),
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(),
            ),
            const WindowButtons()
          ],
        ),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
    iconNormal: const Color(0xFF805306),
    mouseOver: const Color(0xFFF6A00C),
    mouseDown: const Color(0xFF805306),
    iconMouseOver: const Color(0xFF805306),
    iconMouseDown: const Color(0xFFFFD500));

final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0xFF805306),
    iconMouseOver: Colors.white);

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    var widthS = MediaQuery.of(context).size.width;
    return SizedBox(
      width: widthS,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text(
          '  WillO',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black45),
        ),
        Row(
          children: [
            MinimizeWindowButton(colors: buttonColors),
            MaximizeWindowButton(colors: buttonColors),
            CloseWindowButton(
              colors: closeButtonColors,
              onPressed: () {
                appWindow.hide();
              },
            ),
          ],
        )
      ]),
    );
  }
}
