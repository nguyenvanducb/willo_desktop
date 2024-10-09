import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:willo_desktop/helpers.dart/logger.dart';
import 'package:willo_desktop/models/base_response_model.dart';
import 'package:willo_desktop/share_preferences/data_center.dart';

const int SUCCESSFULL = 200;
const int EXPIRE_TOKEN = 401;

class HTTPManager {
  Dio _dio;

  HTTPManager(this._dio);
  static const baseUrl = '';

  BaseOptions baseOptions = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
  );

  Future<BaseOptions> exportOption(BaseOptions options) async {
    if (DataCenter.shared()?.getToken() != null) {
      options.headers["Authorization"] =
          "Bearer ${await DataCenter.shared()?.getToken()}";
    }
    return options;
  }

  /// POST METHOD
  Future<dynamic> post({
    String? url,
    dynamic data,
    Options? options,
  }) async {
    _dio = Dio(await exportOption(baseOptions));
    UtilLogger.log("POST URL", baseUrl + (url ?? ""));
    UtilLogger.log("DATA", const JsonEncoder().convert(data));
    try {
      final response = await _dio.post(
        baseUrl + (url ?? ""),
        data: data,
        options: options,
      );
      if (response.statusCode != SUCCESSFULL) {
        return BaseResponseModel(
            code: response.statusCode, data: null, message: '', success: false);
      }
      // UtilLogger.log(
      //     "POST RESPONSE", const JsonEncoder().convert(response.data));
      return BaseResponseModel(
          code: SUCCESSFULL,
          data: response.data['data'],
          message: response.data['message'],
          success: response.data['status'] == 200);
    } on DioException catch (error) {
      if (error.response?.statusCode == EXPIRE_TOKEN ||
          error.response?.statusCode == 405) {}
      return null;
    }
  }

  /// GET METHOD
  Future<BaseResponseModel> get({
    String? url,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    _dio = Dio(await exportOption(baseOptions));
    try {
      final response = await _dio.get(
        baseUrl + (url ?? ""),
        data: data,
        options: options,
      );

      if (response.statusCode != SUCCESSFULL) {
        return BaseResponseModel(
            code: response.statusCode, data: null, message: '', success: false);
      }
      UtilLogger.log(
          "POST RESPONSE", const JsonEncoder().convert(response.data));
      return BaseResponseModel(
          code: SUCCESSFULL,
          data: response.data['data'],
          message: response.data['message'],
          success: response.data['status'] == 200);
    } on DioException catch (error) {
      if (error.response?.statusCode == EXPIRE_TOKEN ||
          error.response?.statusCode == 405) {
        /// POP TO LOGIN SCREEN
      }
      return BaseResponseModel(
          code: 100, data: null, message: '', success: false);
    }
  }

  /// PUT METHOD
  Future<dynamic> put({
    String? url,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    UtilLogger.log("POST URL", baseUrl + (url ?? ""));
    UtilLogger.log("DATA", const JsonEncoder().convert(data));
    try {
      final response = await _dio.put(
        url ?? "",
        data: data,
        options: options,
      );
      if (response.statusCode != SUCCESSFULL) {
        return BaseResponseModel(
            code: response.statusCode, data: null, message: '', success: false);
      }
      UtilLogger.log(
          "POST RESPONSE", const JsonEncoder().convert(response.data));
      return BaseResponseModel(
          code: SUCCESSFULL,
          data: response.data,
          message: response.statusMessage,
          success: true);
    } on DioException catch (error) {
      if (error.response?.statusCode == EXPIRE_TOKEN) {
        /// POP TO LOGIN SCREEN
      }
      return null;
    }
  }

  /// DELETE METHOD
  Future<dynamic> delete({
    String? url,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    _dio = Dio(await exportOption(baseOptions));
    try {
      final response = await _dio.delete(
        baseUrl + (url ?? ""),
        data: data,
        options: options,
      );
      if (response.statusCode != SUCCESSFULL) {
        return BaseResponseModel(
                code: response.statusCode,
                data: null,
                message: '',
                success: false)
            .toJson();
      }
      UtilLogger.log(
          "POST RESPONSE", const JsonEncoder().convert(response.data));
      return BaseResponseModel(
          code: SUCCESSFULL,
          data: response.data['data'],
          message: response.data['message'],
          success: response.data['status'] == 200);
    } on DioException catch (error) {
      if (error.response?.statusCode == EXPIRE_TOKEN) {
        /// POP TO LOGIN SCREEN
      }
      return null;
    }
  }
}
