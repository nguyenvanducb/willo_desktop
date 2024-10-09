import 'package:willo_desktop/api/http_manager.dart';
import 'package:willo_desktop/url.dart';

class APIManager {
  HTTPManager httpManager;
  APIManager(
    this.httpManager,
  );

  Future<dynamic> login({var data}) async {
    return httpManager.post(
        url: AUTHENTICATION_API_URL + URL_LOGIN, data: data);
  }

  Future<dynamic> getMe({var data}) async {
    return httpManager.get(url: AUTHENTICATION_API_URL + URL_GETME);
  }

  Future<dynamic> addevice({var data}) async {
    return httpManager.post(url: 'other/Addevice', data: data);
  }

  Future<dynamic> register({var data}) async {
    return httpManager.post(url: 'user/register', data: data);
  }

  Future<dynamic> rePassWord({var data}) async {
    return httpManager.post(url: 'User/ChangePassword', data: data);
  }

  Future<dynamic> organizationSearch({var data}) async {
    return httpManager.post(
        url: REACT_APP_BASE_API_URL + URL_ORG_SEARCH, data: data);
  }

  Future<dynamic> organizationAdd(data) async {
    return httpManager.post(
        url: REACT_APP_BASE_API_URL + URL_ORG_ADD, data: data);
  }
}
