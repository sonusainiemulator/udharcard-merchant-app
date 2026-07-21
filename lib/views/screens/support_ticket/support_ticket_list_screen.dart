import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../config/app_colors.dart';
import '../../../config/dimensions.dart';
import '../../../controllers/support_ticket_controller.dart';
import '../../../routes/routes_name.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import 'support_ticket_view_screen.dart';

class SupportTicketListScreen extends StatelessWidget {
  const SupportTicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    TextTheme t = Theme.of(context).textTheme;
    return GetBuilder<SupportTicketController>(builder: (supportTicketCtrl) {
      return Scaffold(
        appBar: CustomAppBar(
          title: storedLanguage['Support Ticket'] ?? "Support Ticket",
        ),
        body: RefreshIndicator(
          color: AppColors.mainColor,
          triggerMode: RefreshIndicatorTriggerMode.onEdge,
          onRefresh: () async {
            supportTicketCtrl.resetDataAfterSearching(
                isFromOnRefreshIndicator: true);
            await supportTicketCtrl.getTicketList(page: 1);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: supportTicketCtrl.scrollController,
            child: Padding(
              padding: Dimensions.kDefaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace(25.h),
                  supportTicketCtrl.isLoading
                      ? Helpers.appLoader()
                      : supportTicketCtrl.ticketList.isEmpty
                          ? Helpers.notFound()
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: supportTicketCtrl.ticketList.length,
                              itemBuilder: (context, i) {
                                var data = supportTicketCtrl.ticketList[i];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 24.h),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.r),
                                    onTap: () {
                                      Get.to(() => SupportTicketViewScreen(
                                          ticketId: data.ticket.toString()));
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Ink(
                                          height: 108.h,
                                          width: double.maxFinite,
                                          decoration: BoxDecoration(
                                            color: Get.isDarkMode
                                                ? AppColors.darkCardColor
                                                : AppColors.fillColorColor,
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 58.h,
                                                height: 58.h,
                                                margin:
                                                    EdgeInsets.only(left: 15.w),
                                                padding: EdgeInsets.all(15.h),
                                                decoration: BoxDecoration(
                                                  color: Get.isDarkMode
                                                      ? AppColors.darkBgColor
                                                      : AppColors.whiteColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Image.asset(
                                                  checkStatusIcon(data.status),
                                                  width: 28.w,
                                                  height: 26.h,
                                                ),
                                              ),
                                              HSpace(
                                                  Dimensions.screenWidth * .1),
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "${data.subject}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.clip,
                                                      style: t.displayMedium,
                                                    ),
                                                    VSpace(16.h),
                                                    RichText(
                                                        text:
                                                            TextSpan(children: [
                                                      TextSpan(
                                                        text: storedLanguage[
                                                                'Last reply:'] ??
                                                            "Last reply: ",
                                                        style: t.displayMedium
                                                            ?.copyWith(
                                                                color: Get
                                                                        .isDarkMode
                                                                    ? AppColors
                                                                        .black30
                                                                    : AppColors
                                                                        .black50),
                                                      ),
                                                      TextSpan(
                                                          text:
                                                              " ${data.lastReply}",
                                                          style:
                                                              t.displayMedium),
                                                    ]))
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: Dimensions.screenWidth * .17,
                                          top: -13.h,
                                          child: Container(
                                            height: 33.h,
                                            width: 33.h,
                                            decoration: BoxDecoration(
                                              color: Get.isDarkMode
                                                  ? AppColors.darkBgColor
                                                  : AppColors.whiteColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                            left: Dimensions.screenWidth * .205,
                                            bottom: -13.h,
                                            child: SizedBox(
                                              height: 102.h,
                                              child: DottedLine(
                                                lineThickness: .5,
                                                dashColor: Get.isDarkMode
                                                    ? AppColors.black60
                                                    : AppColors.black20,
                                                direction: Axis.vertical,
                                              ),
                                            )),
                                        Positioned(
                                          left: Dimensions.screenWidth * .17,
                                          bottom: -13.h,
                                          child: Container(
                                            height: 33.h,
                                            width: 33.h,
                                            decoration: BoxDecoration(
                                              color: Get.isDarkMode
                                                  ? AppColors.darkBgColor
                                                  : AppColors.whiteColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                  if (supportTicketCtrl.isLoadMore == true)
                    Padding(
                        padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
                        child: Helpers.appLoader()),
                  VSpace(20.h),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor:
              Get.isDarkMode ? AppColors.mainColor : AppColors.blackColor,
          onPressed: () {
            Get.toNamed(RoutesName.createSupportTicketScreen);
          },
          child: Icon(
            Icons.add,
            color: AppColors.whiteColor,
          ),
        ),
      );
    });
  }

  checkStatusIcon(dynamic status) {
    if (status == "Closed") {
      return "$rootImageDir/closed.png";
    } else if (status == "Answered" || status == "Replied") {
      return "$rootImageDir/replied.png";
    } else if (status == "Open") {
      return "$rootImageDir/open.png";
    }
  }
}
