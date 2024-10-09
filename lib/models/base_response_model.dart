import 'package:json_annotation/json_annotation.dart';

// part 'base_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BaseResponseModel {
  dynamic code;
  dynamic data;
  dynamic message;
  dynamic success;

  BaseResponseModel({this.code, this.data, this.message, this.success});

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    final code = json['code'];
    final data = json['data '];
    final message = json['message'];
    final success = json['success'];
    return BaseResponseModel(
        code: code, data: data, message: message, success: success);
  }
  //
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'data': data,
      'message': message,
      'success': success,
    };
  }
}
