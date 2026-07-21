import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:paysecure/config/styles.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../../../config/app_colors.dart';
import '../../../controllers/support_ticket_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/services/helpers.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_textfield.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';

class SupportTicketViewScreen extends StatefulWidget {
  final String? ticketId;
  const SupportTicketViewScreen({super.key, this.ticketId = ""});

  @override
  State<SupportTicketViewScreen> createState() =>
      _SupportTicketViewScreenState();
}

class _SupportTicketViewScreenState extends State<SupportTicketViewScreen> {
  var supportTicketCtrl = Get.find<SupportTicketController>();
  bool isShowEmoji = false;
  FocusNode focusNode = FocusNode();
  var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
  onBackspacePressed() {
    supportTicketCtrl.replyTicketEditingCtrl
      ..text =
          supportTicketCtrl.replyTicketEditingCtrl.text.characters.toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(
          offset: supportTicketCtrl.replyTicketEditingCtrl.text.length,
        ),
      );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      supportTicketCtrl.getTicketView(ticketId: widget.ticketId!);
    });
    focusNode.addListener(() {
      setState(() {
        if (focusNode.hasFocus) {
          if (isShowEmoji == true) {
            isShowEmoji = false;
          }
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    // Dispose of the FocusNode when it is no longer needed
    focusNode.dispose();
    super.dispose();
  }

  bool timeVisible = false;

  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SupportTicketController>(
      builder: (supportTicketCtrl) {
        return Scaffold(
          backgroundColor:
              Get.isDarkMode ? const Color(0xff0E111F) : AppColors.whiteColor,
          appBar: buildAppbar(supportTicketCtrl),
          
          body: Column(
            children: [
              supportTicketCtrl.isViewingTicket
                  ? Expanded(child: Helpers.appLoader())
                  : supportTicketCtrl.viewTicketList.isEmpty
                  ? Expanded(
                    child: Center(
                      child: Text("No data found", style: context.t.bodyLarge),
                    ),
                  )
                  : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      reverse:
                          true, // To make the chat messages scroll from bottom to top
                      itemCount:
                          supportTicketCtrl.viewTicketList[0].messages!.length,
                      itemBuilder: (BuildContext context, int index) {
                        var data =
                            supportTicketCtrl
                                .viewTicketList[0]
                                .messages![index];
                        return ListTile(
                          title: Column(
                            crossAxisAlignment:
                                data.adminId == null
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    timeVisible = !timeVisible;
                                    selectedIndex = index;
                                  });
                                },
                                child:
                                    data.attachments!.isEmpty
                                        ? Row(
                                          mainAxisAlignment:
                                              data.adminId != null
                                                  ? MainAxisAlignment.start
                                                  : MainAxisAlignment.end,
                                          children: [
                                            data.adminId != null
                                                ? data.adminImage == null
                                                    ? const SizedBox()
                                                    : Container(
                                                      height: 34.h,
                                                      width: 34.h,
                                                      margin: EdgeInsets.only(
                                                        right: 12.w,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.mainColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          image: DecorationImage(
                                                            image: CachedNetworkImageProvider(
                                                              data.adminImage ??
                                                                  "",
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                : const SizedBox.shrink(),
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: 300.w,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 15.w,
                                                vertical:
                                                    calculateVerticalPadding(
                                                      data.message.length,
                                                    ),
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    data.adminId == null
                                                        ? AppColors.mainColor
                                                        : Get.isDarkMode
                                                        ? const Color(
                                                          0xff161A2D,
                                                        )
                                                        : AppColors
                                                            .fillColorColor, // User and admin message bubble color
                                                borderRadius:
                                                    data.adminId != null
                                                        ? BorderRadius.only(
                                                          bottomRight:
                                                              Radius.circular(
                                                                40.r,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                40.r,
                                                              ),
                                                          topLeft:
                                                              Radius.circular(
                                                                40.r,
                                                              ),
                                                        )
                                                        : BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                40.r,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                40.r,
                                                              ),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                40.r,
                                                              ),
                                                        ),
                                                border: Border.all(
                                                  color: AppColors.mainColor,
                                                  width: .1,
                                                ),
                                              ),
                                              child: Text(
                                                data.message,
                                                style: context.t.displayMedium
                                                    ?.copyWith(
                                                      color:
                                                          data.adminId != null
                                                              ? Get.isDarkMode
                                                                  ? AppColors
                                                                      .whiteColor
                                                                  : AppColors
                                                                      .blackColor
                                                              : AppColors
                                                                  .blackColor,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        )
                                        : Column(
                                          crossAxisAlignment:
                                              data.adminId == null
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  data.adminId != null
                                                      ? MainAxisAlignment.start
                                                      : MainAxisAlignment.end,
                                              children: [
                                                data.adminId != null
                                                    ? data.adminImage == null
                                                        ? const SizedBox()
                                                        : Container(
                                                          height: 34.h,
                                                          width: 34.h,
                                                          margin:
                                                              EdgeInsets.only(
                                                                right: 12.w,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                1,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    AppColors
                                                                        .mainColor,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                              image: DecorationImage(
                                                                image: NetworkImage(
                                                                  data.adminImage ??
                                                                      "",
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                    : const SizedBox.shrink(),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20.w,
                                                    vertical: 5.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          AppColors.mainColor,
                                                      width: .1,
                                                    ),
                                                    color:
                                                        data.adminId == null
                                                            ? AppColors
                                                                .mainColor
                                                            : Get.isDarkMode
                                                            ? const Color(
                                                              0xff161A2D,
                                                            )
                                                            : AppColors
                                                                .fillColorColor, // User and admin message bubble color
                                                    borderRadius:
                                                        data.adminId != null
                                                            ? BorderRadius.only(
                                                              bottomRight:
                                                                  Radius.circular(
                                                                    40.r,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    40.r,
                                                                  ),
                                                              topLeft:
                                                                  Radius.circular(
                                                                    40.r,
                                                                  ),
                                                            )
                                                            : BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    40.r,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    40.r,
                                                                  ),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                    40.r,
                                                                  ),
                                                            ),
                                                  ),
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.sizeOf(
                                                            context,
                                                          ).width *
                                                          .5,
                                                    ),
                                                    child: Text(
                                                      data.message,
                                                      style: context.t.displayMedium?.copyWith(
                                                        color:
                                                            data.adminId != null
                                                                ? Get.isDarkMode
                                                                    ? AppColors
                                                                        .whiteColor
                                                                    : AppColors
                                                                        .blackColor
                                                                : AppColors
                                                                    .blackColor,
                                                      ), // User and admin message text color
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ),
                                              child: Wrap(
                                                alignment:
                                                    data.adminId == null
                                                        ? WrapAlignment.end
                                                        : WrapAlignment.start,
                                                runSpacing: 5,
                                                spacing: 2,
                                                children: [
                                                  data.attachments!.isEmpty
                                                      ? const SizedBox()
                                                      : Column(
                                                        children:
                                                            data.attachments!
                                                                .map(
                                                                  (
                                                                    e,
                                                                  ) => InkWell(
                                                                    onTap: () async {
                                                                      // get the file name from attachment path
                                                                      Uri
                                                                      uri = Uri.parse(
                                                                        e.attachmentPath,
                                                                      );
                                                                      String
                                                                      filename =
                                                                          uri
                                                                              .pathSegments
                                                                              .last;
                                                                      supportTicketCtrl
                                                                              .attachmentPath =
                                                                          e.attachmentPath;

                                                                      // finally download the file
                                                                      await supportTicketCtrl.downloadFile(
                                                                        fileUrl:
                                                                            e.attachmentPath,
                                                                        fileName:
                                                                            filename,
                                                                        context:
                                                                            context,
                                                                      );
                                                                    },
                                                                    child: Container(
                                                                      margin: EdgeInsets.only(
                                                                        left:
                                                                            data.adminId ==
                                                                                    null
                                                                                ? 0
                                                                                : 38.w,
                                                                        bottom:
                                                                            10.h,
                                                                      ),
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.w,
                                                                        vertical:
                                                                            5.h,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            data.adminId !=
                                                                                    null
                                                                                ? Get.isDarkMode
                                                                                    ? const Color(
                                                                                      0xff161A2D,
                                                                                    )
                                                                                    : AppColors.fillColorColor
                                                                                : AppColors.mainColor,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              20.r,
                                                                            ),
                                                                        border: Border.all(
                                                                          color:
                                                                              AppColors.mainColor,
                                                                          width:
                                                                              .1,
                                                                        ),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          supportTicketCtrl.attachmentPath ==
                                                                                      e.attachmentPath &&
                                                                                  supportTicketCtrl.isDownloadPressed
                                                                              ? Text(
                                                                                supportTicketCtrl.downloadCompleted,
                                                                                style: TextStyle(
                                                                                  fontSize:
                                                                                      15.sp,
                                                                                  fontFamily:
                                                                                      Styles.appFontFamily,
                                                                                  color:
                                                                                      data.adminId ==
                                                                                              null
                                                                                          ? AppColors.blackColor
                                                                                          : AppColors.blackColor,
                                                                                  // You can adjust the style as needed
                                                                                ),
                                                                              )
                                                                              : SizedBox.shrink(),
                                                                          Icon(
                                                                            Icons.download,
                                                                            size:
                                                                                17.h,
                                                                            color:
                                                                                data.adminId ==
                                                                                        null
                                                                                    ? AppColors.blackColor
                                                                                    : AppThemes.getIconBlackColor(),
                                                                          ),
                                                                          Text(
                                                                            e.attachmentName ??
                                                                                "",
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  15.sp,
                                                                              fontFamily:
                                                                                  Styles.appFontFamily,
                                                                              color:
                                                                                  data.adminId ==
                                                                                          null
                                                                                      ? AppColors.blackColor
                                                                                      : AppThemes.getIconBlackColor(),
                                                                              fontWeight:
                                                                                  FontWeight.w400,

                                                                              // You can adjust the style as needed
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                      ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                              VSpace(4.h),
                              Visibility(
                                visible:
                                    selectedIndex == index &&
                                    timeVisible == true,
                                child: Text(
                                  selectedIndex == index
                                      ? '${DateFormat('dd MMM, yyyy hh:mm a').format(DateTime.parse(data.createdAt.toString()))}'
                                      : '',
                                  style: context.t.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              Padding(
                padding: EdgeInsets.only(bottom: 15.h),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 60.h,
                    maxHeight: 350.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      supportTicketCtrl.selectedFilePaths.isEmpty
                          ? const SizedBox()
                          : Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(
                              vertical: 5.h,
                              horizontal: 8.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenColor,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  supportTicketCtrl.selectedFilePaths.length < 2
                                      ? "${supportTicketCtrl.selectedFilePaths.length} File selected"
                                      : "${supportTicketCtrl.selectedFilePaths.length} Files selected",
                                  style: context.t.bodySmall?.copyWith(
                                    color: AppColors.whiteColor,
                                  ),
                                ),
                                HSpace(6.w),
                                InkResponse(
                                  onTap: () {
                                    supportTicketCtrl.selectedFilePaths.clear();
                                    supportTicketCtrl.files.clear();
                                    supportTicketCtrl.result = null;
                                    supportTicketCtrl.update();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(3.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.redColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close, size: 12.h),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      VSpace(
                        supportTicketCtrl.selectedFilePaths.isNotEmpty
                            ? 5.h
                            : 0,
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                isShowEmoji = false;
                              });
                              supportTicketCtrl.pickFiles();
                            },
                            icon: Image.asset(
                              "$rootImageDir/file_pick.png",
                              height: 19.h,
                            ),
                          ),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: 46.h,
                                maxHeight: 100.h,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: AppThemes.getFillColor(),
                                  borderRadius: BorderRadius.circular(32.r),
                                  border: Border.all(
                                    color: AppColors.mainColor,
                                    width: .2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        border: InputBorder.none,
                                        focusNode: focusNode,
                                        controller:
                                            supportTicketCtrl
                                                .replyTicketEditingCtrl,
                                        contentPadding: EdgeInsets.only(
                                          left: 20.w,
                                        ),
                                        maxLines: 8,
                                        hinText:
                                            storedLanguage['Type any text here'] ??
                                            "Type any text here",
                                        onChanged: (String v) {
                                          if (v.isEmpty) {
                                            supportTicketCtrl
                                                .replyEditingCtrlEmpty = true;
                                            supportTicketCtrl.update();
                                          } else if (v.isNotEmpty) {
                                            supportTicketCtrl
                                                .replyEditingCtrlEmpty = false;
                                            supportTicketCtrl.update();
                                          }
                                        },
                                      ),
                                    ),
                                    HSpace(3.w),
                                    InkResponse(
                                      onTap: () {
                                        setState(() {
                                          isShowEmoji = !isShowEmoji;
                                          Helpers.hideKeyboard();
                                        });
                                      },
                                      radius: 8.r,
                                      child: Image.asset(
                                        "$rootImageDir/emoji.png",
                                        height: 20.h,
                                      ),
                                    ),
                                    HSpace(15.w),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          HSpace(10.w),
                          InkResponse(
                            onTap: () async {
                              if (supportTicketCtrl
                                  .replyTicketEditingCtrl
                                  .text
                                  .isEmpty) {
                                Helpers.showSnackBar(
                                  msg: 'Message field is required',
                                );
                              } else if (supportTicketCtrl
                                  .replyTicketEditingCtrl
                                  .text
                                  .isNotEmpty) {
                                supportTicketCtrl
                                    .replyTicket(
                                      context: context,
                                      id: widget.ticketId!,
                                    )
                                    .then(
                                      (value) =>
                                          supportTicketCtrl.getTicketView(
                                            ticketId: widget.ticketId!,
                                            isFromCreatingTicket: true,
                                          ),
                                    );
                                supportTicketCtrl.update();
                              }
                            },
                            child: Container(
                              height: 46.h,
                              width: 46.h,
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(10.h),
                              decoration: BoxDecoration(
                                color: AppThemes.getFillColor(),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.mainColor,
                                  width: .2,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(left: 5.w),
                                child: Image.asset(
                                  supportTicketCtrl.replyEditingCtrlEmpty
                                      ? "$rootImageDir/send_inactive.png"
                                      : "$rootImageDir/send_active.png",
                                  color:
                                      supportTicketCtrl.replyEditingCtrlEmpty
                                          ? AppColors.black20
                                          : Get.isDarkMode
                                          ? AppColors.mainColor
                                          : AppColors.blackColor,
                                ),
                              ),
                            ),
                          ),
                          HSpace(20.w),
                        ],
                      ),
                      if (isShowEmoji)
                        SizedBox(
                          height: 250.h,
                          child: emoji.EmojiPicker(
                            textEditingController:
                                supportTicketCtrl.replyTicketEditingCtrl,
                            onBackspacePressed: onBackspacePressed,
                            config: emoji.Config(
                              skinToneConfig: emoji.SkinToneConfig(
                                dialogBackgroundColor: Colors.white,
                                indicatorColor: Colors.grey,
                                enabled: true,
                              ),
                              categoryViewConfig: emoji.CategoryViewConfig(
                                indicatorColor: AppColors.mainColor,
                                iconColor: Colors.grey,
                                iconColorSelected: AppColors.mainColor,
                                backspaceColor: AppColors.mainColor,
                                initCategory: emoji.Category.RECENT,
                                backgroundColor:
                                    Get.isDarkMode
                                        ? AppColors.darkBgColor
                                        : AppColors.whiteColor,
                                tabIndicatorAnimDuration: kTabScrollDuration,
                                categoryIcons: const emoji.CategoryIcons(),
                                recentTabBehavior:
                                    emoji.RecentTabBehavior.RECENT,
                              ),
                              emojiViewConfig: emoji.EmojiViewConfig(
                                columns: 11,
                                emojiSizeMax: 24.h,
                                verticalSpacing: 0,
                                horizontalSpacing: 0,
                                gridPadding: EdgeInsets.zero,
                                recentsLimit: 28,
                                replaceEmojiOnLimitExceed: false,
                                noRecents: Text(
                                  storedLanguage['No Recents'] ?? 'No Recents',
                                  style: context.t.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                                loadingIndicator: const SizedBox.shrink(),
                                buttonMode: emoji.ButtonMode.MATERIAL,
                              ),
                              checkPlatformCompatibility: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  CustomAppBar buildAppbar(SupportTicketController supportTicketCtrl) {
    return CustomAppBar(
      fontSize: 20.sp,
      bgColor: Get.isDarkMode ? const Color(0xff0E111F) : AppColors.whiteColor,
      title:
          supportTicketCtrl.isViewingTicket == false
              ? supportTicketCtrl.viewTicketList.isEmpty
                  ? ""
                  : "${supportTicketCtrl.viewTicketList[0].pageTitle}"
              : "",
      actions: [
        PopupMenuButton<String>(
          color: AppThemes.getDarkCardColor(),
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Refresh',
                child: Text(
                  storedLanguage['Refresh'] ?? "Refresh",
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              if (supportTicketCtrl.isViewingTicket == false)
                if (supportTicketCtrl.viewTicketList.isNotEmpty)
                  if (supportTicketCtrl.viewTicketList[0].status != "Closed")
                    PopupMenuItem<String>(
                      value: "Close Ticket",
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          openDialg(supportTicketCtrl, widget.ticketId!);
                        },
                        child: Text(
                          storedLanguage['Close Ticket'] ?? "Close Ticket",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ),
            ];
          },
          onSelected: (String selectedValue) {
            if (selectedValue == "Refresh") {
              supportTicketCtrl.getTicketView(ticketId: widget.ticketId!);
            }
          },
        ),
      ],
    );
  }

  double calculateVerticalPadding(int textLength) {
    if (textLength > 35) {
      return 20.h;
    } else {
      return 15.h;
    }
  }

  openDialg(SupportTicketController supportTicketController, String id) {
    return Get.defaultDialog(
      radius: 20,
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      titlePadding: EdgeInsets.zero,
      title: "",
      content: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Text(
              storedLanguage['Are you sure you want to close this ticket?'] ??
                  "Are you sure you want to close this ticket?",
              style: TextStyle(fontFamily: "Dubai", fontSize: 15.sp),
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// cancel
                Expanded(
                  child: AppButton(
                    buttonHeight: 35.h,
                    text: storedLanguage['Cancel'] ?? "Cancel",
                    bgColor: Colors.grey,
                    onTap: () => Get.back(),
                  ),
                ),
                SizedBox(width: 70.w),

                /// close
                Expanded(
                  child: AppButton(
                    buttonHeight: 35.h,
                    text: storedLanguage['Close'] ?? "Close",
                    bgColor: AppColors.redColor,
                    onTap: () async {
                      supportTicketController
                          .replyTicket(
                            id: id,
                            context: context,
                            isCloseTicket: true,
                          )
                          .then((value) {});
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
