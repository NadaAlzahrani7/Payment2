import 'dart:core';
import 'package:flutter/material.dart';
import 'package:paypalintegration/PaypalServices.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalPayment extends StatefulWidget {
  final Function onFinish;
  PaypalPayment({required this.onFinish});

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  GlobalKey<ScaffoldState> scaffoldkey = GlobalKey<ScaffoldState>();
  var checkoutUrl;
  var executeUrl;
  var accessToken;

  PaypalServices services = PaypalServices();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await services.getAcessToken();
        final transaction = getOrderParams();
        final res =
            await services.createPaypalPayment(transaction, accessToken);
        if (res != null) {
          setState(() {
            checkoutUrl = res["approvalUrl"];
            executeUrl = res["executeUrl"];
          });
        }
      } catch (e) {
        print('exception' + e.toString());
      }
    });
  }

  String returnURL = "return.example.com";
  String cancelURL = "cancel.example.com";
  Map<dynamic, dynamic> defaultCurrency = {
    "symbol": "USD",
    "decimalDigints": 2,
    "symbolBeforeTheNumber": true,
    "currency": "USD"
  };
  bool isEnableShipping = false;
  bool isEnableAddress = false;

  String itemName = "Locker";
  String itemPrice = '1.99';
  int quantity = 1;

  Map<String, dynamic> getOrderParams() {
    List items = [
      {
        "name": itemName,
        "quantity": quantity,
        "price": itemPrice,
        "currency": defaultCurrency["currency"]
      }
    ];
    //checkout invoice details
    String totalAmount = '1.99';
    String subTotalAmount = '1.99';
    String shippingCost = '0';
    int shippingDiscountCost = 0;
    String userFirstName = "Nada";
    String userLastName = "Alzahrani";
    String addressCity = "Riyadh";
    String addressStreet = "Alareesh";
    String addressZipCode = "11223";
    String addressCountry = "Saudi";
    String addressSatate = "Riyadh";
    String addressPhoneNumber = "+966590044959";

    Map<String, dynamic> temp = {
      "imtent": "sale",
      "payer": {"payment_method": "paypal"},
      "transactions": [
        {
          "amount": {
            "total": totalAmount,
            "currency": defaultCurrency["currency"],
            "details": {
              "subtotal": subTotalAmount,
              "shipping": shippingCost,
              "shipping_discount": ((-1.0) * shippingDiscountCost).toString()
            }
          },
          "description": "The payment transaction description",
          "payment_options": {
            "allowed_payment_method": "INSTANT_FUNDING_SOURCE"
          },
          "item_list": {
            "items": items,
            if (isEnableShipping && isEnableAddress)
              "shipping_address": {
                "recipient_name": userFirstName + " " + userLastName,
                "line1": addressStreet,
                "line2": "",
                "city": addressCity,
                "country_code": addressCountry,
                "postal_code": addressZipCode,
                "phone": addressPhoneNumber,
                "state": addressSatate
              },
          }
        }
      ],
      "note_to_payer": "Contact us for any questions on your reservation",
      "redirect_urls": {"return_url": returnURL, "cancel_url": cancelURL}
    };
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    print(checkoutUrl);
    if (checkoutUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back_ios),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: WebView(
          initialUrl: checkoutUrl,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (NavigationRequest request) {
            if (request.url.contains(returnURL)) {
              final uri = Uri.parse(request.url);
              final payerID = uri.queryParameters['PayerID'];
              if (payerID != null) {
                services
                    .executePayment(executeUrl, payerID, accessToken)
                    .then((id) {
                  widget.onFinish(id);
                  Navigator.pop(context);
                });
              } else {
                Navigator.of(context).pop();
              }
              Navigator.of(context).pop();
            }
            if (request.url.contains(cancelURL)) {
              Navigator.of(context).pop();
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    } else {
      return Scaffold(
        key: scaffoldkey,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: Container(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
  }
}
