import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_colors.dart';
import '../../../controllers/voice_entry_controller.dart';
import '../../widgets/spacing.dart';

class VoiceKhataSheet extends StatefulWidget {
  const VoiceKhataSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceKhataSheet(),
    );
  }

  @override
  State<VoiceKhataSheet> createState() => _VoiceKhataSheetState();
}

class _VoiceKhataSheetState extends State<VoiceKhataSheet>
    with SingleTickerProviderStateMixin {
  late final VoiceEntryController _controller;
  late AnimationController _waveController;
  bool _showKeyboard = false;
  int _exampleIndex = 0;

  final List<String> _promptExamples = const [
    '"2 kilo sugar 40 rupees, 3 soap 30 each — Ramesh, unpaid"',
    '"Rajesh ko 2000 rupay udhaar diya"',
    '"Sandipan se 500 rupay mile"',
    '"Supplier se 5000 ka maal liya"',
    '"Dudhwale ko 3000 diye"',
    '"Good Day biscuits khatam, 5 kilo sugar mangwana"',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<VoiceEntryController>()
        ? Get.find<VoiceEntryController>()
        : Get.put(VoiceEntryController());

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Auto-start listening on sheet open for seamless voice UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.isListening) {
        _controller.startListening();
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _nextExample() {
    setState(() {
      _exampleIndex = (_exampleIndex + 1) % _promptExamples.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final Color cardBg = isDark ? const Color(0xFF131B26) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtleText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color emerald = const Color(0xFF00A86B);

    return GetBuilder<VoiceEntryController>(
      init: _controller,
      builder: (controller) {
        final parsed = controller.latestParsedResult;
        final hasResult = controller.hasQuickEntry;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 14.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle & top bar
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                VSpace(12.h),

                // VoiceKhata Pill Header & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close (X)
                    GestureDetector(
                      onTap: () {
                        if (controller.isListening) {
                          controller.stopListening();
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18.sp,
                          color: subtleText,
                        ),
                      ),
                    ),

                    // VoiceKhata Brand Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, color: emerald, size: 16.sp),
                          HSpace(5.w),
                          Text(
                            "VoiceKhata",
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: emerald,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gemini 3.8 / Live Mode Toggle Switch
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.toggleLiveMode();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _controller.isLiveMode
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: _controller.isLiveMode
                                ? const Color(0xFFEF4444)
                                : Colors.blue.withValues(alpha: 0.4),
                            width: _controller.isLiveMode ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: _controller.isLiveMode
                                    ? const Color(0xFFEF4444)
                                    : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            HSpace(5.w),
                            Text(
                              _controller.isLiveMode ? "LIVE AI" : "Gemini Live",
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: _controller.isLiveMode
                                    ? const Color(0xFFEF4444)
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Category Pill Indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: emerald.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        parsed?.category ?? "SALE",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: emerald,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                VSpace(20.h),

                // Try saying card with rotating prompt
                GestureDetector(
                  onTap: _nextExample,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Try saying",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: subtleText,
                              ),
                            ),
                            HSpace(4.w),
                            Icon(Icons.swap_horiz, size: 14.sp, color: subtleText),
                          ],
                        ),
                        VSpace(8.h),
                        Text(
                          _promptExamples[_exampleIndex],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: emerald,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                VSpace(20.h),

                // Center Stage: Pulsing Soundwave Mic
                Center(
                  child: GestureDetector(
                    onTap: () {
                      controller.toggleListening();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse wave ring
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            final scale = controller.isListening ? 1.0 + (_waveController.value * 0.3) : 1.0;
                            return Container(
                              width: 110.w * scale,
                              height: 110.w * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (controller.isListening ? emerald : AppColors.mainColor)
                                    .withValues(alpha: controller.isListening ? 0.12 : 0.04),
                              ),
                            );
                          },
                        ),
                        // Inner wave ring
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            final scale = controller.isListening ? 1.0 + (_waveController.value * 0.15) : 1.0;
                            return Container(
                              width: 86.w * scale,
                              height: 86.w * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (controller.isListening ? emerald : AppColors.mainColor)
                                    .withValues(alpha: controller.isListening ? 0.22 : 0.08),
                              ),
                            );
                          },
                        ),
                        // Main Mic Icon Circle
                        Container(
                          width: 68.w,
                          height: 68.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.isListening ? emerald : Colors.white,
                            border: Border.all(
                              color: controller.isListening ? emerald : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (controller.isListening ? emerald : Colors.black)
                                    .withValues(alpha: controller.isListening ? 0.35 : 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            controller.isListening ? Icons.mic : Icons.mic_none,
                            size: 32.sp,
                            color: controller.isListening ? Colors.white : emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                VSpace(14.h),

                // Listening Status Text
                Center(
                  child: Text(
                    controller.isListening
                        ? (controller.isLiveMode ? "● Gemini Live: Listening..." : "Listening...")
                        : controller.isThinking
                            ? "Gemini AI Processing..."
                            : (controller.isLiveMode ? "Gemini Live Active (Waiting...)" : "Tap Mic to Speak"),
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: controller.isLiveMode
                          ? const Color(0xFFEF4444)
                          : (controller.isListening ? emerald : textColor),
                    ),
                  ),
                ),
                VSpace(3.h),
                Center(
                  child: Text(
                    controller.isLiveMode
                        ? "Hands-free Live mode on. Say 'Band karo' to stop."
                        : "Say the whole bill or transaction.",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: subtleText,
                    ),
                  ),
                ),

                VSpace(16.h),

                // Live Transcribed Text (if any)
                if (controller.transcribedText.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 14.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: emerald.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.graphic_eq, color: emerald, size: 18.sp),
                        HSpace(8.w),
                        Expanded(
                          child: Text(
                            '"${controller.transcribedText}"',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Parsed Result Card (if detected)
                if (hasResult) ...[
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F8F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: emerald.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Party & Type Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16.r,
                                  backgroundColor: emerald.withValues(alpha: 0.2),
                                  child: Icon(Icons.person, size: 18.sp, color: emerald),
                                ),
                                HSpace(8.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.parsedName.isNotEmpty
                                          ? controller.parsedName
                                          : (parsed?.isPurchaseOrder == true ? "Purchase Order" : "Customer"),
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    if (parsed?.matchedCustomer != null)
                                      Text(
                                        "Existing Customer Linked",
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: emerald,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: (controller.parsedType.toLowerCase() == 'received' || parsed?.isPaid == true)
                                    ? emerald
                                    : AppColors.redColor,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                controller.parsedType.toLowerCase() == 'received'
                                    ? "Paise Mile"
                                    : (parsed?.isPurchaseOrder == true ? "Order" : "Udhaar Diya"),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Itemized Bill List (if parsed items present)
                        if (parsed != null && parsed.items.isNotEmpty) ...[
                          VSpace(12.h),
                          Text(
                            "Items Breakdown:",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: subtleText,
                            ),
                          ),
                          VSpace(6.h),
                          ...parsed.items.map((item) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${item.quantity > 1 ? '${item.quantity.toInt()} ' : ''}${item.title}",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      "₹${item.totalPrice.toInt()}",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],

                        // Purchase Order Items (if purchase order)
                        if (parsed != null && parsed.isPurchaseOrder && parsed.purchaseItems.isNotEmpty) ...[
                          VSpace(12.h),
                          Text(
                            "Items to Order:",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: subtleText,
                            ),
                          ),
                          VSpace(6.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: parsed.purchaseItems
                                .map(
                                  (item) => Chip(
                                    label: Text(
                                      item,
                                      style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: emerald.withValues(alpha: 0.12),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],

                        // Amount / Subtotal
                        if (controller.parsedAmount > 0) ...[
                          VSpace(12.h),
                          const Divider(),
                          VSpace(6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount",
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: subtleText,
                                ),
                              ),
                              Text(
                                "₹${controller.parsedAmount.toInt()}",
                                style: GoogleFonts.outfit(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color: emerald,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Attached Bill Photo Thumbnail
                        if (controller.attachedBillImage != null) ...[
                          VSpace(10.h),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(
                                  File(controller.attachedBillImage!.path),
                                  width: 48.w,
                                  height: 48.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              HSpace(10.w),
                              Expanded(
                                child: Text(
                                  "Bill receipt attached",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: emerald,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => controller.clearAttachedBillImage(),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  VSpace(14.h),
                ],

                // Keyboard Fallback Input (collapsible)
                if (_showKeyboard) ...[
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.sandboxTextCtrl,
                            autofocus: true,
                            onChanged: (val) => controller.parseSentence(val),
                            decoration: InputDecoration(
                              hintText: "E.g. Ramesh ko 500 udhar diya",
                              hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: subtleText),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: emerald),
                          onPressed: () {
                            setState(() => _showKeyboard = false);
                            controller.parseSentence(controller.sandboxTextCtrl.text);
                          },
                        ),
                      ],
                    ),
                  ),
                  VSpace(14.h),
                ],

                // Bottom Dock Controls (exact match to screenshot!)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Row(
                    children: [
                      // Pause / Play Button
                      GestureDetector(
                        onTap: () {
                          if (controller.isListening) {
                            controller.stopListening();
                          } else {
                            controller.startListening();
                          }
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            controller.isListening ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: textColor,
                            size: 22.sp,
                          ),
                        ),
                      ),

                      HSpace(10.w),

                      // Camera Button (attach paper bill)
                      GestureDetector(
                        onTap: () => _showImageSourcePicker(context, controller),
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: textColor,
                            size: 20.sp,
                          ),
                        ),
                      ),

                      HSpace(10.w),

                      // Audio Waveform Dots
                      Expanded(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(11, (index) {
                                  final double h = controller.isListening
                                      ? 4.0 + (index % 3 == 0 ? 8.0 * _waveController.value : 5.0 * (1 - _waveController.value))
                                      : 4.0;
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                                    width: 4.w,
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: controller.isListening
                                          ? emerald.withValues(alpha: 0.7 + (index % 4) * 0.08)
                                          : subtleText.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),

                      HSpace(8.w),

                      // Keyboard Toggle Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showKeyboard = !_showKeyboard;
                          });
                        },
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.keyboard_outlined,
                            color: _showKeyboard ? emerald : textColor,
                            size: 19.sp,
                          ),
                        ),
                      ),

                      HSpace(8.w),

                      // Done Checkmark (Green Button)
                      GestureDetector(
                        onTap: () async {
                          if (controller.isSubmittingEntry) return;
                          if (parsed?.isPurchaseOrder == true) {
                            controller.sharePurchaseOrderWhatsApp('');
                            Navigator.of(context).pop();
                          } else if (hasResult) {
                            await controller.saveParsedEntryDirectly();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } else {
                            if (controller.isListening) {
                              controller.stopListening();
                            } else {
                              controller.startListening();
                            }
                          }
                        },
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: emerald,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: emerald.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: controller.isSubmittingEntry
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 26.sp,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageSourcePicker(BuildContext context, VoiceEntryController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00A86B)),
              title: const Text("Take Photo of Bill"),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickBillImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00A86B)),
              title: const Text("Upload from Gallery"),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickBillImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
