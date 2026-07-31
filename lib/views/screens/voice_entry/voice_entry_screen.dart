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

  Widget _buildFeatureBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLangChip(
      BuildContext context, VoiceEntryController controller, String langCode, String label) {
    final bool isSelected = controller.talkBackLanguage == langCode;
    return GestureDetector(
      onTap: () => controller.changeTalkBackLanguage(langCode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mainColor
              : AppColors.mainColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.whiteColor : AppColors.mainColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTryChip(
      BuildContext context, VoiceEntryController controller, String phrase) {
    return GestureDetector(
      onTap: () {
        controller.sandboxTextCtrl.text = phrase;
        controller.parseSentence(phrase);
      },
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? AppColors.darkCardColor
              : AppColors.fillColorColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 13.sp, color: AppColors.mainColor),
            HSpace(6.w),
            Text(
              phrase,
              style: context.t.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppThemes.getIconBlackColor(),
              ),
            ),
          ],
        ),
      ),
    );
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
                        VSpace(15.h),

                        // Qoder Voice Key Features Header Banner
                        Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.mainColor.withValues(alpha: .15),
                                AppColors.greenColor.withValues(alpha: .1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.mainColor.withValues(alpha: .3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.graphic_eq, color: AppColors.mainColor, size: 22.sp),
                                  HSpace(8.w),
                                  Text(
                                    "Udhar Voice Assistant",
                                    style: context.t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppThemes.getIconBlackColor(),
                                    ),
                                  ),
                                ],
                              ),
                              VSpace(10.h),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: [
                                  _buildFeatureBadge(context, "🎙️ Hears you", AppColors.mainColor),
                                  _buildFeatureBadge(context, "🔊 Talks back", AppColors.greenColor),
                                  _buildFeatureBadge(context, "⚡ Gets it done", Colors.orangeAccent),
                                ],
                              ),
                              VSpace(6.h),
                              Text(
                                "Full-duplex real-time voice entry with Talk Back assistant",
                                style: context.t.bodySmall?.copyWith(
                                  color: AppColors.black50,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        VSpace(15.h),

                        // Talk Back Feature Control Panel Card
                        Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.all(14.h),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode ? AppColors.darkCardColor : AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Get.isDarkMode ? AppColors.black70 : AppColors.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.record_voice_over, color: AppColors.mainColor, size: 22.sp),
                                      HSpace(8.w),
                                      Text(
                                        storedLanguage['Talk Back Feature'] ?? "Talk Back Feature",
                                        style: context.t.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppThemes.getIconBlackColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: controller.isTalkBackEnabled,
                                    activeColor: AppColors.mainColor,
                                    onChanged: (val) => controller.toggleTalkBack(val),
                                  ),
                                ],
                              ),
                              if (controller.isTalkBackEnabled) ...[
                                VSpace(8.h),
                                Row(
                                  children: [
                                    Text(
                                      "Voice Language: ",
                                      style: context.t.bodySmall?.copyWith(color: AppColors.black50),
                                    ),
                                    HSpace(8.w),
                                    _buildLangChip(context, controller, "hi-IN", "Hindi"),
                                    HSpace(6.w),
                                    _buildLangChip(context, controller, "en-IN", "English"),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        VSpace(15.h),

                        // Talk Back Active (Speaking Response) Indicator Banner
                        if (controller.isSpeaking) ...[
                          Container(
                            width: double.maxFinite,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: AppColors.greenColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.greenColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.volume_up, color: AppColors.greenColor, size: 24.sp),
                                    HSpace(10.w),
                                    Text(
                                      "Talk Back Active (Speaking...)",
                                      style: context.t.bodyMedium?.copyWith(
                                        color: AppColors.greenColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => controller.stopSpeaking(),
                                  child: Icon(Icons.stop_circle_outlined, color: AppColors.redColor, size: 26.sp),
                                ),
                              ],
                            ),
                          ),
                          VSpace(15.h),
                        ],
                        
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

                        // Try Saying / Asking (Talk Back Suggestions)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Try saying / asking (Talk Back Q&A):",
                              style: context.t.bodySmall?.copyWith(
                                color: AppColors.black50,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            VSpace(8.h),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTryChip(context, controller, "Total balance kitna hai?"),
                                  _buildTryChip(context, controller, "Ramesh ka balance batao"),
                                  _buildTryChip(context, controller, "Ramesh ko 500 udhar diye"),
                                  _buildTryChip(context, controller, "Suresh se 200 mil gaye"),
                                  _buildTryChip(context, controller, "Help — Tum kya kar sakte ho?"),
                                ],
                              ),
                            ),
                          ],
                        ),

                        VSpace(15.h),

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

                        // AI Thinking State
                        if (controller.isThinking) ...[
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mainColor),
                                ),
                                HSpace(12.w),
                                Text(
                                  "Processing with AI...",
                                  style: context.t.bodyMedium?.copyWith(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          VSpace(15.h),
                        ],

                        // AI Reply Display
                        if (controller.aiReply.isNotEmpty) ...[
                          Container(
                            width: double.maxFinite,
                            padding: EdgeInsets.all(16.h),
                            decoration: BoxDecoration(
                              color: AppColors.greenColor.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.greenColor.withValues(alpha: .3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, color: AppColors.greenColor, size: 24.sp),
                                    HSpace(8.w),
                                    Text(
                                      "AI Assistant Response",
                                      style: context.t.titleMedium?.copyWith(
                                        color: AppColors.greenColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                VSpace(12.h),
                                Text(
                                  controller.aiReply,
                                  textAlign: TextAlign.center,
                                  style: context.t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppThemes.getIconBlackColor(),
                                  ),
                                ),
                                VSpace(12.h),
                                // Talk Back / Speak Again Button
                                GestureDetector(
                                  onTap: () => controller.speakReply(controller.aiReply),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(color: AppColors.greenColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.volume_up, size: 16.sp, color: AppColors.greenColor),
                                        HSpace(6.w),
                                        Text(
                                          "Speak Again (Talk Back)",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.greenColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          VSpace(15.h),
                        ],
                        
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
                                           Row(
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
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
                                               HSpace(6.w),
                                               // Speak (Talk Back) button for transaction
                                               GestureDetector(
                                                 onTap: () => controller.talkBackTransaction(tx),
                                                 child: Container(
                                                   padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                   decoration: BoxDecoration(
                                                     color: AppColors.greenColor.withValues(alpha: 0.15),
                                                     borderRadius: BorderRadius.circular(4.r),
                                                     border: Border.all(color: AppColors.greenColor),
                                                   ),
                                                   child: Row(
                                                     children: [
                                                       Icon(Icons.volume_up, size: 10.sp, color: AppColors.greenColor),
                                                       HSpace(2.w),
                                                       Text(
                                                         "Speak",
                                                         style: TextStyle(
                                                           fontSize: 9.sp,
                                                           fontWeight: FontWeight.bold,
                                                           color: AppColors.greenColor,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ),
                                               HSpace(6.w),
                                               GestureDetector(
                                                 onTap: () => controller.postToUdharLedger(tx),
                                                 child: Container(
                                                   padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                   decoration: BoxDecoration(
                                                     color: AppColors.mainColor.withValues(alpha: 0.2),
                                                     borderRadius: BorderRadius.circular(4.r),
                                                     border: Border.all(color: AppColors.mainColor),
                                                   ),
                                                   child: Row(
                                                     children: [
                                                       Icon(Icons.add_task, size: 10.sp, color: AppColors.blackColor),
                                                       HSpace(2.w),
                                                       Text(
                                                         "Add Udhar",
                                                         style: TextStyle(
                                                           fontSize: 9.sp,
                                                           fontWeight: FontWeight.bold,
                                                           color: AppColors.blackColor,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ),
                                             ],
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
}
