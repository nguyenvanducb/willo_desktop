import 'package:window_manager/window_manager.dart';

class MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    // windowManager.hide();
    // Ngăn cửa sổ đóng, thay vào đó ẩn nó
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      windowManager.hide(); // Ẩn cửa sổ
    }
  }

  @override
  void onWindowShow() {
    print(
        "🖼️ App vừa được show từ taskbar (ví dụ sau khi click icon tray hoặc taskbar)");
  }
}
