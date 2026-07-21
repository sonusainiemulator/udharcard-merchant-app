import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/models/withdraw_history_model.dart' as w;
import '../data/repositories/withdraw_repo.dart';
import '../data/source/errors/check_api_status.dart';

class WithdrawHistoryController extends GetxController {
  static WithdrawHistoryController get to =>
      Get.find<WithdrawHistoryController>();
  TextEditingController dateTimeEditingCtrlr = TextEditingController();
  TextEditingController utrEditingCtrlr = TextEditingController();
  TextEditingController emailEditingCtrlr = TextEditingController();

  late ScrollController scrollController;
  int page = 1;
  bool isLoadMore = false;
  bool hasNextPage = true;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<w.Datum> withdrawList = [];
  Future loadMore() async {
    if (_isLoading == false &&
        isLoadMore == false &&
        hasNextPage == true &&
        scrollController.position.extentAfter < 300) {
      isLoadMore = true;
      update();
      page += 1;
      await getRequestList(
          page: page,
          email: emailEditingCtrlr.text,
          created_at: dateTimeEditingCtrlr.text,
          utr: utrEditingCtrlr.text,
          isLoadMoreRunning: true);
      if (kDebugMode) {
        print("====================loaded from load more: " + page.toString());
      }
      isLoadMore = false;
      update();
    }
  }

  bool isSearchTapped = false;
  resetDataAfterSearching({bool? isFromOnRefreshIndicator = false}) {
    withdrawList.clear();
    page = 1;
    isSearchTapped = true;
    hasNextPage = true;
    update();
  }

  refreshSearchData() {
    dateTimeEditingCtrlr.clear();
    utrEditingCtrlr.clear();
    emailEditingCtrlr.clear();
    update();
  }

  Future getRequestList(
      {required int page,
      required String email,
      required String utr,
      required String created_at,
      bool? isLoadMoreRunning = false}) async {
    if (isLoadMoreRunning == false) {
      _isLoading = true;
    }
    update();
    http.Response response = await WithdrawRepo.getWithdrawHistoryList(
        page: page, email: email, transaction_id: utr, created_at: created_at);
    if (page == 1 && isLoadMoreRunning == false) {
      withdrawList.clear();
    }
    if (isLoadMoreRunning == false) {
      _isLoading = false;
    }
    update();
    

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final fetchedData = data['message']['payouts']['data'];
        if (fetchedData.isNotEmpty) {
          withdrawList = [
            ...withdrawList,
            ...w.WithdrawHistoryModel.fromJson(data).message!.payouts!.data!
          ];
          if (isLoadMoreRunning == false) {
            _isLoading = false;
          }
          update();
        } else {
          withdrawList = [
            ...withdrawList,
            ...w.WithdrawHistoryModel.fromJson(data).message!.payouts!.data!
          ];
          hasNextPage = false;
          if (isLoadMoreRunning == false) {
            _isLoading = false;
          }
          if (kDebugMode) {
            print("================isDataEmpty: true");
          }

          update();
        }
      } else {
        ApiStatus.checkStatus(data['status'], data['message']);
      }
    } else {
      withdrawList = [];
    }
  }

  @override
  void onInit() {
    super.onInit();
    getRequestList(page: page, email: "", created_at: "", utr: "");
    scrollController = ScrollController()..addListener(loadMore);
  }

  @override
  void onClose() {
    scrollController.removeListener(loadMore);
    scrollController.dispose();
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    withdrawList.clear();
  }
}
