import 'package:http/http.dart' as http;
import 'package:sales_odoo_app/core/network/odoo_config.dart';

class OdooHttpClient extends http.BaseClient {
  final http.Client _inner;
  final OdooConfig _config;

  OdooHttpClient(this._inner, this._config);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_config.database.isNotEmpty) {
      request.headers['X-Odoo-Database'] = _config.database;
    }
    return _inner.send(request);
  }
}
