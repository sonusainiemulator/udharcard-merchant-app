import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:paysecure/data/repositories/withdraw_repo.dart';
import '../data/models/bank_from_bank_model.dart';
import '../data/models/bank_from_currency_model.dart' as currency;
import '../data/models/payout_gateways_model.dart' as payout;
import '../data/models/bank_from_bank_model.dart' as bank;
import '../data/source/errors/check_api_status.dart';
import '../routes/page_index.dart';
import '../routes/routes_name.dart';
import '../utils/services/helpers.dart';

class WithdrawController extends GetxController {
  static WithdrawController get to => Get.find<WithdrawController>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  TextEditingController amountCtrl = TextEditingController();

  List<DynamicFieldModel> dynamicList = [];
  List<DynamicFieldModel> selectedDynamicList = [];
  List<payout.Gateway> paymentGatewayList = [];
  List<String> flutterwaveTransferList = [];
  Future getPayouts() async {
    _isLoading = true;
    update();
    http.Response response = await WithdrawRepo.getPayouts();
    _isLoading = false;
    paymentGatewayList = [];
    dynamicList = [];
    flutterwaveTransferList = [];
    update();

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        paymentGatewayList
            .addAll(payout.PayoutModel.fromJson(data).message!.gateways!);

        // filter the dynamic field data
        List list = data['message']['gateways'];
        for (var i in list) {
          if (i['inputForm'] != null && i['inputForm'] is Map) {
            // dynamic field
            Map<String, dynamic> dForm = i['inputForm'];
            dForm.forEach((key, value) {
              if (value['field_name'] != null && value['field_label'] != null) {
                dynamicList.add(DynamicFieldModel(
                  name: i['name'],
                  fieldName: value['field_name'],
                  fieldLevel: value['field_label'],
                  type: value['type'],
                  validation: value['validation'],
                ));
              }
            });
          }
          // if the payment gateway is flutterwave
          if (i['name'] == "Flutterwave") {
            if (i['bank_name'] != null && i['bank_name'] is Map) {
              Map<String, dynamic> dBankMap = i['bank_name'];
              dBankMap.entries.forEach((e) {
                Map<String, dynamic> dNestedBankMap = e.value;
                dNestedBankMap.entries.forEach((x) {
                  flutterwaveTransferList.add(x.value);
                });
              });
            }
          }
        }

        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['data']);
        update();
      }
    } else {
      Helpers.showSnackBar(msg: jsonDecode(response.body)['data']);

      update();
    }
  }

  int selectedGatewayIndex = -1;
  List<payout.Gateway> searchedGatewayItem = [];
  bool isGatewaySearching = false;
  TextEditingController gatewaySearchCtrl = TextEditingController();
  queryPaymentGateway(String v) {
    searchedGatewayItem = paymentGatewayList
        .where((payout.Gateway e) =>
            e.name.toString().toLowerCase().contains(v.toLowerCase()))
        .toList();
    selectedGatewayIndex = -1;
    if (v.isEmpty) {
      isGatewaySearching = false;
      searchedGatewayItem.clear();
      update();
    } else if (v.isNotEmpty) {
      isGatewaySearching = true;
      update();
    }
    update();
  }

  int gatewayId = 0;
  String gatewayName = "";
  dynamic selectedCurrency = null;
  List<payout.PayoutCurrency> payoutCurrencyList = [];
  List<dynamic> supportedCurrencyList = [];
  getSelectedGatewayData(index) {
    var data = isGatewaySearching
        ? searchedGatewayItem[index]
        : paymentGatewayList[index];
    gatewayId = data.id;
    gatewayName = data.name;
    // get the selected payment gateway's currency for getting the min, max, charge
    payoutCurrencyList = [];
    if (data.payoutCurrencies != null) {
      payoutCurrencyList = data.payoutCurrencies!;
    }
    // get the supported currencies for displaying in the payout page
    supportedCurrencyList = [];
    selectedCurrency = null;
    if (data.supportedCurrency != null) {
      supportedCurrencyList = data.supportedCurrency!;
      selectedCurrency = supportedCurrencyList[0];
      if (gatewayName == "Paystack") {
        getBankFromCurrency(currencyCode: selectedCurrency);
      }
    }
    update();
  }

  // get the selected currency data
  String minAmount = "0.00";
  String maxAmount = "0.00";
  String charge = "0.00";
  String conversion_rate = "0.00";
  String percentage = "0";
  getSelectedCurrencyData(value) async {
    try {
      amountCtrl.clear();
      amountValue = "";
      var selectedCurr = await payoutCurrencyList.firstWhere((e) {
        return e.name == value || e.currencySymbol == value;
      });
      minAmount =
          double.parse(selectedCurr.minLimit.toString()).toStringAsFixed(2);
      maxAmount = selectedCurr.maxLimit.toString();
      charge = selectedCurr.fixedCharge.toString();
      conversion_rate = selectedCurr.conversionRate.toString();
      percentage = selectedCurr.percentageCharge.toString();
      calculateAmount();
    } catch (e) {
      Helpers.showSnackBar(msg: e.toString());
    }
    update();
  }

  // calculate amount
  String totalChargedAmount = "0.00";
  String totalPayoutAmountInBaseCurrency = "0.00";
  calculateAmount() {
    try {
      if (amountValue.isNotEmpty && selectedCurrency != null) {
        totalChargedAmount =
            (double.parse(amountValue.toString()) + double.parse(charge))
                .toStringAsFixed(2);
        totalPayoutAmountInBaseCurrency =
            ((double.parse(totalChargedAmount.toString())) /
                    double.parse(conversion_rate))
                .toStringAsFixed(2); 
        update();
      }
    } catch (e) {
      Helpers.showSnackBar(msg: e.toString());
    }
  }

  String amountValue = "";
  bool isFollowedTransactionLimit = true;
  onChangedAmount(v) {
    try {
      amountValue = v.toString();
      if (v.toString().isNotEmpty) {
        if ((double.parse(v.toString()) >= double.parse(minAmount)) &&
            (double.parse(v.toString()) <= double.parse(maxAmount))) {
          isFollowedTransactionLimit = true;
        } else {
          isFollowedTransactionLimit = false;
        }
      }
      calculateAmount();
    } catch (e) {
      Helpers.showSnackBar(msg: e.toString());
    }
    update();
  }

  //------------check amount----
  // List<AmountCheckModel> amountCheckList = [];
  bool isGettingAmountCheck = false;
  /*
  Whatever section you want to check then you have to put one of the transaction_type_id of below this-
  'transfer' => 1,
  'request' => 2,
  'exchange' => 3,
  'redeem' => 4,
  'escrow' => 5,
  'voucher' => 6,
  'deposit' => 7,
  'payout' => 8,
  'invoice' => 9,
  'virtual_card' => 10,
  'bill_payment' => 11
  */


  @override
  void onInit() {
    super.onInit();
    getPayouts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  //----------PAYOUT REQUEST----------//
  bool isPayoutRequestSuccess = false;
  String utr = "";
  Future payoutRequest({required Map<String, String> fields}) async {
    isPayoutSubmitting = true;
    update();
    http.Response response = await WithdrawRepo.payoutRequest(fields: fields);
    isPayoutSubmitting = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        utr = data['message']['trx_id'] ?? "";
        await payoutPreview(utr: utr);
        await filterData();
        Get.toNamed(RoutesName.withdrawPreviewScreen);
        isPayoutRequestSuccess = true;
        update();
      } else {
        isPayoutRequestSuccess = false;
        ApiStatus.checkStatus(data['status'], data['message']);
        update();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //----------PAYOUT PREVIEW------//
  bool isPayoutConfirmRequSuccess = false;
  int selectedPayoutConfirmIndex = -1;
  String chargeAmount = "";
  String totalPayable = "";
  bool enable_for = false;
  List<String> bankList = [];
  List<String> currencyList = [];
  Future payoutPreview({required String utr}) async {
    isPayoutSubmitting = true;
    update();
    http.Response response = await WithdrawRepo.payoutPreview(utr: utr);
    isPayoutSubmitting = false;
    selectedDynamicList = [];
    bankList = [];
    currencyList = [];
    selectedBankCurrency = null;
    flutterWaveSelectedTransfer = null;
    flutterwaveSelectedBankNumber = "";
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        try {
          // for showing in the withdraw preview page
          if (data['message']['payout'] != null &&
              data['message']['payout']['method'] != null) {
            gatewayId = data['message']['payout']['method']['id'];
            gatewayName =
                data['message']['payout']['method']['name'].toString();
            selectedCurrency =
                data['message']['payout']['payout_currency_code'];
            amountCtrl.text =
                double.parse(data['message']['payout']['amount'].toString())
                    .toStringAsFixed(2);

            enable_for = data['message']['enable_for'] ?? false;
            chargeAmount =
                double.parse(data['message']['payout']['charge'].toString())
                    .toStringAsFixed(2);
            totalPayable =
                double.parse(data['message']['payout']['net_amount'].toString())
                    .toStringAsFixed(2);
          }

          if (data['message']['dynamicForm'] != null &&
              data['message']['dynamicForm'] is Map) {
            // dynamic field
            Map<String, dynamic> dForm = data['message']['dynamicForm'];
            dForm.forEach((key, value) {
              selectedDynamicList.add(DynamicFieldModel(
                fieldName: value['field_name'] ?? "",
                fieldLevel: value['field_label'] ?? "",
                type: value['type'] ?? "",
                validation: value['validation'] ?? "",
              ));
            });
          }
          // if the payment gateway is flutterwave or paystack
          if (gatewayName == "Flutterwave" ||
              gatewayName == "Paystack" ||
              gatewayName == "Paypal") {
            if (gatewayName == "Flutterwave") {
              if (data['message']['bankName'] != null &&
                  data['message']['bankName'] is List) {
                bankList = List.from(data['message']['bankName']);
                update();
              }
            }

            if (data['message']['supportedCurrency'] != null &&
                data['message']['supportedCurrency'] is Map) {
              Map<String, dynamic> map = data['message']['supportedCurrency'];
              for (var i in map.values) {
                currencyList.add(i);
              }
              update();
            }
          }

          update();
        } catch (e) {
          Helpers.showSnackBar(msg: e.toString());
        }
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //----------PAYOUT CONFIRM SUBMIT----------//
  bool isPayoutSubmitting = false;
  var selectedPaypalValue = null;
  TextEditingController securityPinController = TextEditingController();
  Future payoutConfirmSubmit(
      {required Map<String, String> fields,
      required BuildContext context,
      required Iterable<http.MultipartFile>? fileList}) async {
    isPayoutSubmitting = true;
    update();
    try {
      http.Response response = await WithdrawRepo.payoutConfirmSubmit(
          fields: fields, fileList: fileList);
      isPayoutSubmitting = false;
      update();
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ApiStatus.checkStatus(data['status'], data['message']);
        if (data['status'] == 'success') {
          Get.offAll(() => PaymentSuccessScreen(
                gateway: gatewayName,
                amount: amountCtrl.text,
                currencySymbol: selectedCurrency,
              ));
          update();
        }
        update();
      } else {
        Helpers.showSnackBar(msg: '${data['message']}');
      }
    } catch (e) {
      isPayoutSubmitting = false;
      Helpers.showSnackBar(msg: "$e");
      update();
    }
  }

  //------------FLUTTER WAVE---------//
  var flutterWaveSelectedTransfer = null;
  var selectedBankCurrency = null;
  var flutterWaveSelectedBank = null;
  String flutterwaveSelectedBankNumber = "0";
  List<bank.Data> bankFromBankList = [];
  List<String> bankFromBankDynamicList = [];
  Map<String, TextEditingController> bankFromBanktextEditingControllerMap = {};
  Future getBankFromBank({required String bankName}) async {
    isBankLoading = true;
    update();
    http.Response response =
        await WithdrawRepo.getBankFromBank(bankName: bankName);
    bankFromBankList = [];
    bankFromBankDynamicList = [];
    bankFromBanktextEditingControllerMap.clear();
    isBankLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        if (data['message']['bank'] != null &&
            data['message']['bank']['data'] != null) {
          bankFromBankList
              .addAll(BankFromBankModel.fromJson(data).message!.bank!.data!);
        }
        if (data['message']['input_form'] != null &&
            data['message']['input_form'] is Map) {
          Map<String, dynamic> map = data['message']['input_form'];
          map.forEach((key, value) {
            bankFromBankDynamicList.add(key);
            bankFromBanktextEditingControllerMap[key] = TextEditingController();
          });
        }
        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  Future submitFlutterwavePayout(
      {required Map<String, String> fields,
      required BuildContext context}) async {
    isPayoutSubmitting = true;
    update();
    http.Response response =
        await WithdrawRepo.flutterwaveSubmit(fields: fields);
    isPayoutSubmitting = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);

      if (data['status'] == 'success') {
        Get.offAll(() => PaymentSuccessScreen(
              gateway: gatewayName,
              amount: amountCtrl.text,
              currencySymbol: selectedCurrency,
            ));
        update();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //------------PAYSTACK---------//
  var paystackSelectedBank = null;
  String paystackSelectedBankNumber = "0";
  String paystackSelectedType = "";
  List<currency.Data> bankFromCurrencyList = [];
  bool isBankLoading = false;
  Future getBankFromCurrency({required String currencyCode}) async {
    isBankLoading = true;
    update();
    http.Response response =
        await WithdrawRepo.getBankFromCurrency(currencyCode: currencyCode);
    bankFromCurrencyList = [];
    isBankLoading = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['status'] == 'success') {
        if (data['message']['data'] != null &&
            data['message']['data'] is List) {
          bankFromCurrencyList.addAll(
              currency.BankFromCurrencyModel.fromJson(data).message!.data!);
        }
        update();
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  Future submitPaystackPayout(
      {required Map<String, String> fields,
      required BuildContext context}) async {
    isPayoutSubmitting = true;
    update();
    http.Response response = await WithdrawRepo.paystackSubmit(fields: fields);
    isPayoutSubmitting = false;
    update();
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ApiStatus.checkStatus(data['status'], data['message']);
      if (data['status'] == 'success') {
        Get.offAll(() => PaymentSuccessScreen(
              gateway: gatewayName,
              amount: amountCtrl.text,
              currencySymbol: selectedCurrency,
            ));
        update();
      }
      update();
    } else {
      Helpers.showSnackBar(msg: '${data['message']}');
    }
  }

  //------------------let's manupulate the dynamic form data-----//
  Map<String, TextEditingController> textEditingControllerMap = {};
  List<DynamicFieldModel> fileType = [];
  List<DynamicFieldModel> requiredFile = [];
  List<String> requiredTypeFileList = [];

  Future filterData() async {
    // reset list
    requiredTypeFileList.clear();
    // check if the field type is text or textArea
    var textType =
        await selectedDynamicList.where((e) => e.type != 'file').toList();

    for (var field in textType) {
      textEditingControllerMap[field.fieldName] = TextEditingController();
    }

    // check if the field type is file
    fileType =
        await selectedDynamicList.where((e) => e.type == 'file').toList();
    // listing the all required file
    requiredFile =
        await fileType.where((e) => e.validation == 'required').toList();
    // add the required file name in a seperate list for validation
    for (var file in requiredFile) {
      requiredTypeFileList.add(file.fieldName);
    }
  }

  Map<String, dynamic> dynamicData = {};
  List<String> imgPathList = [];

  Future renderDynamicFieldData() async {
    imgPathList.clear();
    textEditingControllerMap.forEach((key, controller) {
      dynamicData[key] = controller.text;
    });
    await Future.forEach(imagePickerResults.keys, (String key) async {
      String filePath = imagePickerResults[key]!.path;
      imgPathList.add(imagePickerResults[key]!.path);
      dynamicData[key] = await http.MultipartFile.fromPath("", filePath);
    });

    // if (kDebugMode) {
    //   print("Posting data: $dynamicData");
    // }
  }

  final formKey = GlobalKey<FormState>();
  XFile? pickedFile;
  Map<String, http.MultipartFile> fileMap = {};
  Map<String, XFile?> imagePickerResults = {};
  Future<void> pickFile(String fieldName) async {
    try {
      final picker = ImagePicker();
      final pickedImageFile =
          await picker.pickImage(source: ImageSource.camera);

      if (pickedImageFile != null) {
        imagePickerResults[fieldName] = pickedImageFile;
        final file =
            await http.MultipartFile.fromPath(fieldName, pickedImageFile.path);
        fileMap[fieldName] = file;

        if (requiredTypeFileList.contains(fieldName)) {
          requiredTypeFileList.remove(fieldName);
        }
        update();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error while picking files: $e");
      }
    }
  }

  refreshDynamicData() {
    imagePickerResults.clear();
    dynamicData.clear();
    textEditingControllerMap.clear();
    fileType.clear();
    requiredFile.clear();
    requiredTypeFileList.clear();
    pickedFile = null;
    fileMap.clear();
  }
  //--------------------------------------------------//
}

class DynamicFieldModel {
  dynamic name;
  dynamic fieldName;
  dynamic fieldLevel;
  dynamic type;
  dynamic validation;
  DynamicFieldModel(
      {this.name, this.fieldName, this.fieldLevel, this.type, this.validation});
}

class OtherGatewayCurrencyModel {
  String gatewayName;
  String currency;
  OtherGatewayCurrencyModel(
      {required this.gatewayName, required this.currency});
}
