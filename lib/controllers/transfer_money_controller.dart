import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/transfer_repo.dart';

import '../../utils/services/helpers.dart';
import 'dart:convert';

class TransferMoneyController extends GetxController {
  bool isLoading = false;

  TextEditingController emailOrPhoneCtrl = TextEditingController();
  TextEditingController amountCtrl = TextEditingController();

  Future<void> submitTransfer() async {
    if (emailOrPhoneCtrl.text.isEmpty) {
      Helpers.showSnackBar(msg: 'Please enter recipient email or phone');
      return;
    }
    if (amountCtrl.text.isEmpty) {
      Helpers.showSnackBar(msg: 'Please enter amount');
      return;
    }

    isLoading = true;
    update();

    try {
      var response = await TransferRepo.submitTransfer(
        emailOrPhone: emailOrPhoneCtrl.text.trim(),
        amount: amountCtrl.text.trim(),
      );

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        if (decodedData['status'] == 'success') {
          Helpers.showSnackBar(
            msg: decodedData['message'] ?? 'Transfer Successful',
          );
          emailOrPhoneCtrl.clear();
          amountCtrl.clear();
          Get.back();
        } else {
          Helpers.showSnackBar(
            msg: decodedData['message'] ?? 'Transfer Failed',
          );
        }
      } else {
        Helpers.showSnackBar(msg: 'Something went wrong. Please try again.');
      }
    } catch (e) {
      Helpers.showSnackBar(msg: 'Error: ${e.toString()}');
    }

    isLoading = false;
    update();
  }

  bool isContactsLoading = false;
  List<dynamic> contactsList = [];
  List<dynamic> filteredContactsList = [];
  TextEditingController searchCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  void searchContacts(String query) {
    if (query.isEmpty) {
      filteredContactsList = contactsList;
    } else {
      filteredContactsList =
          contactsList.where((contact) {
            final name = (contact['name'] ?? '').toString().toLowerCase();
            final email = (contact['email'] ?? '').toString().toLowerCase();
            final phone = (contact['phone'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || email.contains(q) || phone.contains(q);
          }).toList();
    }
    update();
  }

  Future<void> fetchContacts() async {
    isContactsLoading = true;
    update();

    try {
      var response = await TransferRepo.getContactsList();
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        if (decodedData['status'] == 'success') {
          contactsList = decodedData['data']['contacts'] ?? [];
        } else {
          contactsList = [];
        }
      } else {
        contactsList = [];
      }
    } catch (e) {
      contactsList = [];
    }

    filteredContactsList = contactsList;
    isContactsLoading = false;
    update();
  }

  void selectContact(dynamic contact) {
    emailOrPhoneCtrl.text = contact['email'] ?? contact['phone'] ?? '';
    update();
  }

  @override
  void onClose() {
    emailOrPhoneCtrl.dispose();
    amountCtrl.dispose();
    searchCtrl.dispose();
    super.onClose();
  }
}
