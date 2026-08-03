import 'package:flutter/material.dart';

import '../../../controllers/subscription_controller.dart';
import '../../../routes/page_index.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: SubscriptionController.to,
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Choose a Plan'),
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Monthly'),
                          selected: controller.selectedBillingCycle == 'monthly',
                          onSelected: (_) => controller.setBillingCycle('monthly'),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Yearly'),
                          selected: controller.selectedBillingCycle == 'yearly',
                          onSelected: (_) => controller.setBillingCycle('yearly'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.plans.length,
                        itemBuilder: (context, index) {
                          final plan = controller.plans[index] as Map<String, dynamic>;
                          final planName = plan['name']?.toString() ?? 'Plan';
                          final code = plan['code']?.toString() ?? '';
                          final monthly = plan['monthly_price']?.toString() ?? '0';
                          final yearly = plan['yearly_price']?.toString() ?? '0';
                          final price = controller.selectedBillingCycle == 'yearly' ? yearly : monthly;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    planName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Price: INR $price / ${controller.selectedBillingCycle}'),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: controller.isCheckoutLoading
                                          ? null
                                          : () => controller.startPlanPurchase(
                                                planCode: code,
                                                planName: planName,
                                              ),
                                      child: const Text('Select Plan'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
