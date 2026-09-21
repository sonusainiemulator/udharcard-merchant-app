import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../controllers/bottom_nav_controller.dart';
import '../../../controllers/voice_entry_controller.dart';
import '../../widgets/spacing.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen>
    with TickerProviderStateMixin {
  late final VoiceEntryController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  bool _showKeyboard = false;
  int _exampleIndex = 0;
  int _activeTab = 0; // 0: Ledger, 1: Purchase Orders

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

    unawaited(_controller.initializeVoiceFeatures());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _nextExample() {
    setState(() {
      _exampleIndex = (_exampleIndex + 1) % _promptExamples.length;
    });
  }

  void _useExamplePhrase(String phrase) {
    final clean = phrase.replaceAll('"', '').trim();
    _controller.sandboxTextCtrl.text = clean;
    _controller.parseSentence(clean);
  }

  Widget _buildCategoryPill(String label, String code, VoiceEntryController controller) {
    final bool isSelected = controller.activeCategory == code;
    const Color emerald = Color(0xFF00A86B);
    return GestureDetector(
      onTap: () => controller.setActiveCategory(code),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? emerald : emerald.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? emerald : emerald.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : emerald,
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(VoiceEntryController controller, String langCode, String label) {
    final bool isSelected = controller.talkBackLanguage == langCode;
    const Color emerald = Color(0xFF00A86B);
    return GestureDetector(
      onTap: () => controller.changeTalkBackLanguage(langCode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? emerald : emerald.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? emerald : emerald.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : emerald,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;
    const Color emerald = Color(0xFF00A86B);
    final Color pageBg = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF6F9FD);
    final Color cardBg = isDark ? const Color(0xFF131B26) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtleText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GetBuilder<VoiceEntryController>(
      init: _controller,
      builder: (controller) {
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

        final parsed = controller.latestParsedResult;
        final hasResult = controller.hasQuickEntry;

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Brand Bar: Close, VoiceKhata Badge, Category Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back / Close
                      GestureDetector(
                        onTap: () {
                          if (controller.isListening) {
                            controller.stopListening();
                          }
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else if (Get.isRegistered<BottomNavController>()) {
                            Get.find<BottomNavController>().changeScreen(0);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 18.sp, color: subtleText),
                        ),
                      ),

                      // VoiceKhata Brand Pill Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: emerald.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, color: emerald, size: 16.sp),
                            HSpace(6.w),
                            Text(
                              "VoiceKhata",
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: emerald,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Active Category Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: emerald.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          parsed?.category ?? "SALE",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: emerald,
                          ),
                        ),
                      ),
                    ],
                  ),

                  VSpace(14.h),

                  // Hero Headlines (matching screenshot!)
                  Text(
                    "Invoices by Voice",
                    style: GoogleFonts.outfit(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  VSpace(2.h),
                  Text(
                    "Speak. Bill. Done.",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: emerald,
                    ),
                  ),

                  VSpace(12.h),

                  // Category Selector Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryPill("All Modes", "ALL", controller),
                        HSpace(8.w),
                        _buildCategoryPill("Sale / Bill", "BILL", controller),
                        HSpace(8.w),
                        _buildCategoryPill("Udhaar Diya", "UDHAR", controller),
                        HSpace(8.w),
                        _buildCategoryPill("Paise Mile", "COLLECTION", controller),
                        HSpace(8.w),
                        _buildCategoryPill("Purchase Order", "PURCHASE", controller),
                      ],
                    ),
                  ),

                  VSpace(16.h),

                  // Main VoiceKhata Interactive Canvas Mockup Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Try saying card with rotating prompt
                        GestureDetector(
                          onTap: _nextExample,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
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
                                    HSpace(6.w),
                                    Icon(Icons.touch_app_outlined, size: 13.sp, color: subtleText),
                                  ],
                                ),
                                VSpace(6.h),
                                Text(
                                  _promptExamples[_exampleIndex],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: emerald,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VSpace(20.h),

                        // Center Pulsing Emerald Microphone
                        Center(
                          child: GestureDetector(
                            onTap: () => controller.toggleListening(),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Pulse Ring
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 125.w * _pulseAnimation.value,
                                      height: 125.w * _pulseAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (controller.isListening ? emerald : AppColors.mainColor)
                                            .withValues(alpha: controller.isListening ? 0.12 : 0.03),
                                      ),
                                    );
                                  },
                                ),
                                // Middle Pulse Ring
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 100.w * (_pulseAnimation.value * 0.9),
                                      height: 100.w * (_pulseAnimation.value * 0.9),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (controller.isListening ? emerald : AppColors.mainColor)
                                            .withValues(alpha: controller.isListening ? 0.22 : 0.07),
                                      ),
                                    );
                                  },
                                ),
                                // Core Mic Button
                                Container(
                                  width: 74.w,
                                  height: 74.w,
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
                                        blurRadius: 18,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    controller.isListening ? Icons.mic : Icons.mic_none,
                                    size: 34.sp,
                                    color: controller.isListening ? Colors.white : emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VSpace(14.h),

                        // Listening Status Indicator
                        Center(
                          child: Text(
                            controller.isListening
                                ? "Listening..."
                                : controller.isThinking
                                    ? "Processing VoiceKhata AI..."
                                    : "Tap to Speak",
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: controller.isListening ? emerald : textColor,
                            ),
                          ),
                        ),
                        VSpace(2.h),
                        Center(
                          child: Text(
                            "Say the whole bill or transaction.",
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: subtleText,
                            ),
                          ),
                        ),

                        VSpace(14.h),

                        // Live Speech Transcription
                        if (controller.transcribedText.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(bottom: 12.h),
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

                        // Parsed Result Card
                        if (hasResult) ...[
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F8F5),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: emerald.withValues(alpha: 0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Party & Badge
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
                                                "Linked: ${parsed?.matchedCustomer?['name'] ?? ''}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 11.sp,
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

                                // Itemized Bill Breakdown
                                if (parsed != null && parsed.items.isNotEmpty) ...[
                                  VSpace(10.h),
                                  Text(
                                    "Invoice Items:",
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: subtleText,
                                    ),
                                  ),
                                  VSpace(4.h),
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

                                // Purchase items list
                                if (parsed != null && parsed.isPurchaseOrder && parsed.purchaseItems.isNotEmpty) ...[
                                  VSpace(10.h),
                                  Text(
                                    "Order Items to buy:",
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
                                          (it) => Chip(
                                            label: Text(
                                              it,
                                              style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            backgroundColor: emerald.withValues(alpha: 0.12),
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  VSpace(10.h),
                                  ElevatedButton.icon(
                                    onPressed: () => controller.sharePurchaseOrderWhatsApp(''),
                                    icon: const Icon(Icons.share, size: 16, color: Colors.white),
                                    label: Text(
                                      "Share Order on WhatsApp",
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    ),
                                  ),
                                ],

                                // Amount
                                if (controller.parsedAmount > 0) ...[
                                  VSpace(10.h),
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
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w800,
                                          color: emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Attached Bill Photo
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
                                          "Bill paper receipt attached",
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

                                // Direct 1-Tap Save to Ledger Button
                                VSpace(14.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: controller.isSubmittingEntry
                                        ? null
                                        : () async {
                                            if (parsed?.isPurchaseOrder == true) {
                                              controller.sharePurchaseOrderWhatsApp('');
                                            } else {
                                              await controller.saveParsedEntryDirectly();
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: emerald,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      elevation: 2,
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
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                parsed?.isPurchaseOrder == true
                                                    ? Icons.shopping_bag_outlined
                                                    : Icons.check_circle_outline,
                                                size: 18.sp,
                                              ),
                                              HSpace(8.w),
                                              Text(
                                                parsed?.isPurchaseOrder == true
                                                    ? "Share Purchase Order on WhatsApp"
                                                    : (parsed?.matchedCustomer != null
                                                        ? "खाते में सेव करें (Save to Ledger)"
                                                        : "नया ग्राहक सेव करें (Save to Ledger)"),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
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
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
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
                                  icon: const Icon(Icons.check, color: emerald),
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

                        // Bottom Control Dock Bar (exact match to screenshot!)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Row(
                            children: [
                              // Pause / Resume Mic Button
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
                                              ? 4.0 + (index % 3 == 0 ? 9.0 * _waveController.value : 5.0 * (1 - _waveController.value))
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
                                  } else if (hasResult) {
                                    await controller.saveParsedEntryDirectly();
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

                  VSpace(16.h),

                  // Quick Suggestion Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _promptExamples.map((ex) {
                        return GestureDetector(
                          onTap: () => _useExamplePhrase(ex),
                          child: Container(
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.flash_on, size: 13.sp, color: emerald),
                                HSpace(4.w),
                                Text(
                                  ex.replaceAll('"', ''),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  VSpace(16.h),

                  // TalkBack Control Panel
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.record_voice_over, color: emerald, size: 22.sp),
                                HSpace(10.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Voice Confirmation (TalkBack)",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      "Speaks aloud after every entry",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: subtleText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: controller.isTalkBackEnabled,
                              activeThumbColor: emerald,
                              onChanged: (val) => controller.toggleTalkBack(val),
                            ),
                          ],
                        ),
                        if (controller.isTalkBackEnabled) ...[
                          VSpace(10.h),
                          const Divider(),
                          VSpace(6.h),
                          Row(
                            children: [
                              Text(
                                "Language: ",
                                style: GoogleFonts.inter(fontSize: 12.sp, color: subtleText),
                              ),
                              HSpace(8.w),
                              _buildLangChip(controller, "hi-IN", "Hindi (हिंदी)"),
                              HSpace(6.w),
                              _buildLangChip(controller, "en-IN", "English"),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  VSpace(20.h),

                  // History Section Tabs: Voice Ledger Entries vs Purchase Orders
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? emerald : emerald.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Voice Ledger (${controller.voiceTransactions.length})",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == 0 ? Colors.white : emerald,
                              ),
                            ),
                          ),
                        ),
                      ),
                      HSpace(10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? emerald : emerald.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Purchase Orders (${controller.purchaseOrders.length})",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == 1 ? Colors.white : emerald,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  VSpace(14.h),

                  // Content of selected tab
                  if (_activeTab == 0) ...[
                    if (controller.voiceTransactions.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 36.h),
                        child: Column(
                          children: [
                            Icon(Icons.mic_none, size: 44.sp, color: subtleText),
                            VSpace(8.h),
                            Text(
                              "No voice entries yet. Speak a transaction above!",
                              style: GoogleFonts.inter(fontSize: 13.sp, color: subtleText),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.voiceTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = controller.voiceTransactions[index];
                          final bool isRec = tx['type'] == 'Received';

                          String formattedDate = "";
                          try {
                            DateTime dt = DateTime.parse(tx['date'].toString());
                            formattedDate = DateFormat('dd MMM, hh:mm a').format(dt);
                          } catch (e) {
                            formattedDate = tx['date'].toString();
                          }

                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: (isRec ? emerald : AppColors.redColor).withValues(alpha: 0.12),
                                  child: Icon(
                                    isRec ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isRec ? emerald : AppColors.redColor,
                                    size: 18.sp,
                                  ),
                                ),
                                HSpace(10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['name'] ?? "Customer",
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: GoogleFonts.inter(fontSize: 11.sp, color: subtleText),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${isRec ? '+' : '-'}₹${tx['amount']}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isRec ? emerald : AppColors.redColor,
                                      ),
                                    ),
                                    VSpace(4.h),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // TalkBack Button
                                        GestureDetector(
                                          onTap: () => controller.talkBackTransaction(tx),
                                          child: Container(
                                            padding: EdgeInsets.all(4.r),
                                            decoration: BoxDecoration(
                                              color: emerald.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Icon(Icons.volume_up, size: 14.sp, color: emerald),
                                          ),
                                        ),
                                        HSpace(6.w),
                                        // WhatsApp Reminder Button
                                        GestureDetector(
                                          onTap: () => controller.shareReminderWhatsApp(
                                            tx['phone'] ?? '',
                                            (tx['amount'] as num?)?.toDouble() ?? 0.0,
                                            tx['name'] ?? '',
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(4.r),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: const Icon(Icons.share, size: 14, color: Color(0xFF25D366)),
                                          ),
                                        ),
                                        HSpace(6.w),
                                        // Add to Udhar Ledger
                                        GestureDetector(
                                          onTap: () => controller.postToUdharLedger(tx),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: emerald,
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              "Add Udhar",
                                              style: GoogleFonts.inter(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ] else ...[
                    // Purchase Orders tab
                    if (controller.purchaseOrders.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 36.h),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 44.sp, color: subtleText),
                            VSpace(8.h),
                            Text(
                              "No purchase orders. Say '5 kilo sugar mangwana'!",
                              style: GoogleFonts.inter(fontSize: 13.sp, color: subtleText),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.purchaseOrders.length,
                        itemBuilder: (context, index) {
                          final po = controller.purchaseOrders[index];
                          final items = (po['items'] as List?)?.map((e) => e.toString()).toList() ?? [];

                          String dateStr = "";
                          try {
                            DateTime dt = DateTime.parse(po['date'].toString());
                            dateStr = DateFormat('dd MMM, hh:mm a').format(dt);
                          } catch (e) {
                            dateStr = po['date'].toString();
                          }

                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Supplier Order • $dateStr",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: subtleText,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => controller.sharePurchaseOrderWhatsApp(''),
                                      icon: const Icon(Icons.share, size: 14, color: Colors.white),
                                      label: Text(
                                        "WhatsApp",
                                        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                      ),
                                    ),
                                  ],
                                ),
                                VSpace(8.h),
                                Wrap(
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: items
                                      .map((it) => Chip(
                                            label: Text(
                                              it,
                                              style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600),
                                            ),
                                            backgroundColor: emerald.withValues(alpha: 0.1),
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],

                  VSpace(40.h),
                ],
              ),
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
              title: const Text("Take Photo of Bill Receipt"),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickBillImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00A86B)),
              title: const Text("Upload Bill from Gallery"),
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
