import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sedweb/constants/constants.dart';

class ApiService {
  static final instance = ApiService._();
  late Dio _dio;

  ApiService._() {
    _dio = Dio();
  }

  Future summarize(String text) async {
    try {
      var res = await _dio.post(baseUrl + 'summarize', data: {"text": text});
      return Map.of(res.data);
    } catch (e) {
      return 'Error connecting to api';
    }
  }

  Future downloadDoc(
      String url, String appDocumentsPath, String docName) async {
    try {
      var value = await _dio.get(url,
          options: Options(responseType: ResponseType.bytes));
      var file = File('$appDocumentsPath/$docName');
      file.writeAsBytesSync(value.data);
      return file;
      // setState(() {
      //   isReadLoading = false;
      // });
      // OpenFile.open(file.path).then((value) => print(value.message));
    } on Exception {
      return 'Error downloading file';
      // setState(() {
      //   isReadLoading = false;
      // });
    }
  }
}
