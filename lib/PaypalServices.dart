import 'package:http/http.dart' as http;
import 'package:http_auth/http_auth.dart';
import 'dart:convert' as convert;

class PaypalServices {
  String domain = "http://api.sandbox.paypal.com";
  String clientId =
      'AYd1oE-Y7971_krQGL6vEgmNtdocufGNrCtHallPnlthpQb7H7ZKexpWONBs3d3aYfiou1olKQIPFi5H';
  String secret =
      'EMm7eiBIEVNtvlNA5GTeufEt6VKMO8yRDMjvNZTU7tfoNej_AFB40cxO26O1obRBWLb-Gog_m-WbztT8';

  Future<String> getAcessToken() async {
    try {
      var client = BasicAuthClient(clientId, secret);
      var response = await client.post(
          Uri.parse('$domain/v1/oauth2/token?grant_type=client_credentials'));
      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body);
        return body["access_token"];
      }
      return "0";
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> createPaypalPayment(
      transaction, accessToken) async {
    try {
      var response = await http.post(
          Uri.parse('$domain/v1/oauth2/token?grant_type=client_credetials'));

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (body["links"] != null && body["links"].length > 0) {
          List links = body["links"];
          String executeUrl = "";
          String approvalUrl = "";

          final item = links.firstWhere((o) => o["rel"] == "approval_url",
              orElse: () => null);
          if (item != null) {
            approvalUrl = item["href"];
          }
          final item1 = links.firstWhere((o) => o["rel"] == "execute",
              orElse: () => null);
          if (item != null) {
            executeUrl = item1["href"];
          }
          return {"executeUrl": executeUrl, "approvalUrl": approvalUrl};
        }
        throw Exception("0");
      } else {
        throw Exception(body["message"]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> executePayment(url, payerId, accesToken) async {
    try {
      var response = await http.post(url,
          body: convert.jsonEncode({"payer_id": payerId}),
          headers: {
            "content-type": "application/json",
            "Authorization": "Bearer" + accesToken
          });
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body["id"];
      }
      return "0";
    } catch (e) {
      rethrow;
    }
  }
}
