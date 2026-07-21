import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/voice_entry_controller.dart';
import '../../../themes/themes.dart';
import '../../../utils/services/localstorage/hive.dart';
import '../../../utils/services/localstorage/keys.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/spacing.dart';
import '../../widgets/text_theme_extension.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    final String pageTitle = storedLanguage['Voice Entry'] ?? "Voice Entry";
    
    return GetBuilder<VoiceEntryController>(
      init: VoiceEntryController(),
      builder: (controller) {
        // Control pulsing animation based on listening state
        if (controller.isListening) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          if (_pulseController.isAnimating) {
            _pulseController.stop();
            _pulseController.reset();
          }
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: pageTitle,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        VSpace(20.h),
                        
                        // Waveform/Speech status banner
                        Text(
                          controller.isListening 
                              ? (storedLanguage['Listening...'] ?? "Listening...") 
                              : (storedLanguage['Tap Mic to Record voice entry'] ?? "Tap Mic to Record voice entry"),
                          style: context.t.bodyMedium?.copyWith(
                            color: controller.isListening ? AppColors.redColor : AppColors.black50,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        VSpace(15.h),

                        // Animated Pulse Microphone Button
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              if (controller.isListening) {
                                controller.stopListening();
                              } else {
                                controller.startListening();
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Concentric Pulse Rings
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 130.w * _pulseAnimation.value,
                                      height: 130.w * _pulseAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: controller.isListening
                                            ? AppColors.redColor.withValues(alpha: .15)
                                            : AppColors.mainColor.withValues(alpha: .05),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 105.w * (_pulseAnimation.value * 0.9),
                                      height: 105.w * (_pulseAnimation.value * 0.9),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: controller.isListening
                                            ? AppColors.redColor.withValues(alpha: .25)
                                            : AppColors.mainColor.withValues(alpha: .1),
                                      ),
                                    );
                                  },
                                ),
                                // Inner mic button
                                Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: controller.isListening
                                          ? [AppColors.redColor, Colors.orangeAccent]
                                          : [AppColors.mainColor, AppColors.yellowColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: controller.isListening
                                            ? AppColors.redColor.withValues(alpha: .4)
                                            : AppColors.mainColor.withValues(alpha: .3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    controller.isListening ? Icons.mic : Icons.mic_none,
                                    size: 40.sp,
                                    color: controller.isListening ? AppColors.whiteColor : AppColors.blackColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        VSpace(25.h),

                        // Bouncing waveform when listening
                        if (controller.isListening) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(7, (index) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 10.0, end: 40.0),
                                duration: Duration(milliseconds: 300 + (index * 80)),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                                    width: 4.w,
                                    height: value,
                                    decoration: BoxDecoration(
                                      color: AppColors.redColor,
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  );
                                },
                                onEnd: () {},
                              );
                            }),
                          ),
                          VSpace(15.h),
                        ],

                        // Sandbox fallback input (perfect for testing/emulator)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(
                              color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor,
                              width: 1,
                            ),
                          ),
                          color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.keyboard, size: 20.sp, color: AppColors.black50),
                                    HSpace(8.w),
                                    Text(
                                      storedLanguage['Type fallback (Simulator Sandbox)'] ?? "Type fallback (Simulator Sandbox)",
                                      style: context.t.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppThemes.getIconBlackColor(),
                                      ),
                                    ),
                                  ],
                                ),
                                VSpace(10.h),
                                TextFormField(
                                  controller: controller.sandboxTextCtrl,
                                  onChanged: (val) {
                                    controller.parseSentence(val);
                                  },
                                  decoration: InputDecoration(
                                    hintText: storedLanguage['Say or type: Ramesh ne 500 udhar liya'] ?? "Say or type: Ramesh ne 500 udhar liya",
                                    hintStyle: context.t.bodySmall?.copyWith(color: AppColors.textFieldHintColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide(color: AppColors.borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide(color: AppColors.borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide(color: AppColors.mainColor),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VSpace(15.h),

                        // Current Transcription Text Display
                        if (controller.transcribedText.isNotEmpty) ...[
                          Container(
                            width: double.maxFinite,
                            padding: EdgeInsets.all(12.h),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '"${controller.transcribedText}"',
                              textAlign: TextAlign.center,
                              style: context.t.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          VSpace(15.h),
                        ],

                        // Parsing Output Card
                        Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.all(16.h),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storedLanguage['Live Output Preview'] ?? "Live Output Preview",
                                style: context.t.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppThemes.getIconBlackColor(),
                                ),
                              ),
                              const Divider(),
                              VSpace(10.h),
                              
                              // Customer name row
                              _buildParsedRow(
                                icon: Icons.person,
                                label: storedLanguage['Customer'] ?? "Customer",
                                value: controller.parsedName.isNotEmpty ? controller.parsedName : "-",
                                valueColor: controller.parsedName.isNotEmpty && controller.parsedName != "Unknown" 
                                    ? AppThemes.getIconBlackColor() 
                                    : AppColors.black50,
                              ),
                              VSpace(12.h),

                              // Amount row
                              _buildParsedRow(
                                icon: Icons.attach_money,
                                label: storedLanguage['Amount'] ?? "Amount",
                                value: controller.parsedAmount > 0 
                                    ? "${controller.parsedAmount.toStringAsFixed(2)}" 
                                    : "-",
                                valueColor: controller.parsedAmount > 0 
                                    ? AppColors.blackColor 
                                    : AppColors.black50,
                              ),
                              VSpace(12.h),

                              // Type row
                              _buildParsedRow(
                                icon: Icons.swap_horiz,
                                label: storedLanguage['Type'] ?? "Type",
                                value: controller.parsedType.isNotEmpty ? controller.parsedType : "-",
                                valueColor: controller.parsedType == "Received" 
                                    ? AppColors.greenColor 
                                    : controller.parsedType == "Given" 
                                        ? AppColors.redColor 
                                        : AppColors.black50,
                              ),
                              VSpace(20.h),

                              // Save button
                              SizedBox(
                                width: double.maxFinite,
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: (controller.parsedName.isNotEmpty && 
                                               controller.parsedName != "Unknown" && 
                                               controller.parsedAmount > 0)
                                      ? () => controller.saveTransaction()
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                    disabledBackgroundColor: AppColors.mainColor.withValues(alpha: .3),
                                    foregroundColor: AppColors.blackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    storedLanguage['Confirm & Add Transaction'] ?? "Confirm & Add Transaction",
                                    style: context.t.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: (controller.parsedName.isNotEmpty && 
                                               controller.parsedName != "Unknown" && 
                                               controller.parsedAmount > 0)
                                          ? AppColors.blackColor
                                          : AppColors.black50,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        VSpace(25.h),

                        // Voice ledger transactions history header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              storedLanguage['Voice Ledger History'] ?? "Voice Ledger History",
                              style: context.t.titleMedium?.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${controller.voiceTransactions.length} items",
                              style: context.t.bodySmall?.copyWith(
                                color: AppColors.black50,
                              ),
                            ),
                          ],
                        ),

                        VSpace(10.h),

                        // Voice Transaction List
                        if (controller.voiceTransactions.isEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, size: 50.sp, color: AppColors.black30),
                                VSpace(8.h),
                                Text(
                                  storedLanguage['No transactions added yet'] ?? "No transactions added yet",
                                  style: context.t.bodyMedium?.copyWith(color: AppColors.black50),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.voiceTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = controller.voiceTransactions[index];
                              final bool isRec = tx['type'] == 'Received';
                              
                              // Format date
                              String formattedDate = "";
                              try {
                                DateTime dt = DateTime.parse(tx['date'].toString());
                                formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                              } catch (e) {
                                formattedDate = tx['date'].toString();
                              }

                              return Dismissible(
                                key: UniqueKey(),
                                background: Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.redColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.w),
                                  child: Icon(Icons.delete, color: AppColors.whiteColor, size: 24.sp),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  controller.deleteTransaction(index);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  padding: EdgeInsets.all(14.h),
                                  decoration: BoxDecoration(
                                    color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Circle status avatar
                                      Container(
                                        width: 40.h,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isRec 
                                              ? AppColors.greenColor.withValues(alpha: .1) 
                                              : AppColors.redColor.withValues(alpha: .1),
                                        ),
                                        child: Icon(
                                          isRec ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: isRec ? AppColors.greenColor : AppColors.redColor,
                                          size: 20.sp,
                                        ),
                                      ),
                                      HSpace(12.w),
                                      
                                      // Transaction Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx['name'] ?? "Unknown",
                                              style: context.t.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            VSpace(4.h),
                                            Text(
                                              formattedDate,
                                              style: context.t.bodySmall?.copyWith(
                                                color: AppColors.black50,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Amount Display
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${isRec ? '+' : '-'}${tx['amount'].toString()}",
                                            style: context.t.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isRec ? AppColors.greenColor : AppColors.redColor,
                                            ),
                                          ),
                                          VSpace(4.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: isRec 
                                                  ? AppColors.greenColor.withValues(alpha: .1) 
                                                  : AppColors.redColor.withValues(alpha: .1),
                                              borderRadius: BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              isRec ? "Received" : "Given",
                                              style: context.t.bodySmall?.copyWith(
                                                color: isRec ? AppColors.greenColor : AppColors.redColor,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        VSpace(30.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParsedRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.black50),
        HSpace(12.w),
        Text(
          label,
          style: context.t.bodyMedium?.copyWith(
            color: AppColors.black50,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.t.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.blackColor,
          ),
        ),
      ],
    );
  }
}
