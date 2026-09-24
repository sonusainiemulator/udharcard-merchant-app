import 'package:flutter/material.dart';

class PlanCardWidget extends StatelessWidget {
  const PlanCardWidget({
    super.key,
    required this.plan,
    required this.isCurrent,
    required this.isTrialActive,
    required this.billingCycle,
    required this.onSelectPlan,
    required this.onStartTrial,
    this.activePlanCode = '',
    this.isLoading = false,
  });

  final Map<String, dynamic> plan;
  final bool isCurrent;
  final bool isTrialActive;
  final String billingCycle;
  final VoidCallback onSelectPlan;
  final VoidCallback onStartTrial;
  final String activePlanCode;
  final bool isLoading;

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final code = plan['code']?.toString().toLowerCase() ?? 'basic';
    final name = plan['name']?.toString() ?? 'Plan';
    final tag = plan['tag']?.toString();
    final badge = plan['badge']?.toString() ?? tag ?? '';
    final subtitle = plan['subtitle']?.toString() ?? plan['description']?.toString() ?? '';
    final trialDays = (plan['trial_days'] as num?)?.toInt() ?? 0;

    final monthlyPrice = (plan['monthly_price'] as num?)?.toDouble() ?? 0.0;
    final yearlyPrice = (plan['yearly_price'] as num?)?.toDouble() ?? 0.0;
    final isFree = monthlyPrice <= 0 && yearlyPrice <= 0;

    final displayPrice = billingCycle == 'yearly'
        ? (yearlyPrice > 0 ? '₹${yearlyPrice.toInt()}' : 'Free')
        : (monthlyPrice > 0 ? '₹${monthlyPrice.toInt()}' : 'Free');

    final periodLabel = isFree
        ? 'forever'
        : (billingCycle == 'yearly' ? '/year' : '/month');

    // Only merchants on free Basic plan can claim a free trial
    final bool isEligibleForTrial = trialDays > 0 &&
        !isTrialActive &&
        !isCurrent &&
        (activePlanCode.isEmpty || activePlanCode.toLowerCase() == 'basic');

    // Features list
    final dynamic rawFeatures = plan['features'];
    final List<String> features = rawFeatures is List
        ? rawFeatures.map((e) => e.toString()).toList()
        : [
            'Manually add and manage customer credit entries',
            'Track outstanding balances',
            'Access records from mobile, laptop, or desktop',
            'Simple and easy-to-use credit management system',
          ];

    // Sample prompts list
    final dynamic rawPrompts = plan['sample_prompts'];
    final List<String> prompts = rawPrompts is List
        ? rawPrompts.map((e) => e.toString()).toList()
        : [];

    // Distinct Theme Colors based on plan
    final rawTagColor = plan['tag_color']?.toString();
    final Color? apiThemeColor = _parseHexColor(rawTagColor);

    Color borderColor;
    Color buttonColor;
    Color badgeBg;
    Color ribbonColor;

    if (apiThemeColor != null && code != 'basic') {
      borderColor = apiThemeColor;
      buttonColor = apiThemeColor;
      badgeBg = apiThemeColor;
      ribbonColor = apiThemeColor;
    } else if (code == 'premium') {
      borderColor = const Color(0xFF1D4ED8); // Deep royal blue
      buttonColor = const Color(0xFF0F4DB8);
      badgeBg = const Color(0xFF0F3B82);
      ribbonColor = const Color(0xFFFF5938); // Most popular reddish-orange
    } else if (code == 'gold') {
      borderColor = const Color(0xFFF59E0B); // Amber / Gold
      buttonColor = const Color(0xFFE59800);
      badgeBg = const Color(0xFFD97706);
      ribbonColor = const Color(0xFFD97706);
    } else {
      borderColor = isCurrent ? const Color(0xFF10B981) : const Color(0xFFE2E8F0);
      buttonColor = const Color(0xFF1E293B);
      badgeBg = const Color(0xFF0F172A);
      ribbonColor = const Color(0xFF1E293B);
    }

    final hasRibbon = tag != null && tag.isNotEmpty && code != 'basic';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: hasRibbon ? 12 : 4, bottom: 6),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: (code != 'basic' || isCurrent) ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (code == 'premium' ? const Color(0xFF1D4ED8) : borderColor)
                    .withValues(alpha: (code != 'basic' || isCurrent) ? 0.08 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge & Plan Name Row
              Row(
                children: [
                  if (badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (badge.isNotEmpty) const SizedBox(width: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            isTrialActive ? 'TRIAL' : 'CURRENT',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Price Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Subtitle
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 16),

              // Feature Checklist
              ...features.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Color(0xFF10B981), // Emerald green checkmark
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              // Try Saying Box (Voice Prompts)
              if (prompts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0EAFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRY SAYING:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...prompts.map((prompt) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '“$prompt”',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // CTA Button
              if (isFree)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isCurrent ? null : onSelectPlan,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: isCurrent ? const Color(0xFFF8FAFC) : Colors.white,
                    ),
                    child: Text(
                      isCurrent ? 'Current Plan' : (plan['cta_text']?.toString() ?? 'Get Started Free'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Trial Button if available & merchant is currently on Basic plan
                    if (isEligibleForTrial)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : onStartTrial,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.flash_on_rounded, size: 18, color: Colors.amberAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Start $trialDays-Day Free Trial',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                    // Primary Subscribe Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onSelectPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (trialDays > 0 && !isTrialActive && !isCurrent)
                              ? Colors.white
                              : buttonColor,
                          foregroundColor: (trialDays > 0 && !isTrialActive && !isCurrent)
                              ? buttonColor
                              : Colors.white,
                          elevation: 0,
                          side: (trialDays > 0 && !isTrialActive && !isCurrent)
                              ? BorderSide(color: buttonColor, width: 1.5)
                              : BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isCurrent
                              ? (isTrialActive ? 'Upgrade to Paid Plan' : 'Active Plan')
                              : (plan['cta_text']?.toString() ?? 'Subscribe Now'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: (trialDays > 0 && !isTrialActive && !isCurrent)
                                ? buttonColor
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Ribbon Badge on Top
        if (hasRibbon)
          Positioned(
            top: 0,
            left: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: ribbonColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ribbonColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                tag.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
