import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:paysecure/config/app_colors.dart';
import 'package:paysecure/controllers/udhar_controller.dart';
import 'package:paysecure/controllers/worklist_controller.dart';
import 'package:paysecure/data/models/worklist_model.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/utils/services/localstorage/hive.dart';
import 'package:paysecure/utils/services/localstorage/keys.dart';
import 'package:paysecure/views/widgets/custom_appbar.dart';
import 'package:paysecure/views/widgets/spacing.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';

class WorkListScreen extends StatefulWidget {
  const WorkListScreen({super.key});

  @override
  State<WorkListScreen> createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  late final WorkListController controller;
  late final UdharController udharController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<WorkListController>();
    udharController = Get.find<UdharController>();
    if (udharController.usersList.isEmpty && !udharController.isUsersLoading) {
      udharController.fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storedLanguage = HiveHelp.read(Keys.languageData) ?? {};
    return GetBuilder<WorkListController>(
      builder: (workListController) {
        return Scaffold(
          appBar: CustomAppBar(
            title: storedLanguage['Today Work List'] ?? 'Today Work List',
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.mainColor,
            onPressed: () => _openTaskEditor(),
            icon: const Icon(Icons.add_task_rounded, color: Colors.black),
            label: Text(
              'Add Task',
              style: context.t.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: controller.fetchWorkItems,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              children: [
                _buildSummary(workListController),
                VSpace(20.h),
                if (!workListController.isLoaded)
                  const Center(child: CircularProgressIndicator())
                else if (workListController.items.isEmpty)
                  _buildEmptyState(context)
                else ...[
                  _buildSection(
                    context,
                    title: 'Overdue',
                    toneColor: AppColors.redColor,
                    items: workListController.overdueItems,
                  ),
                  _buildSection(
                    context,
                    title: 'Today',
                    toneColor: AppColors.mainColor,
                    items: workListController.todayItems,
                  ),
                  _buildSection(
                    context,
                    title: 'Tomorrow',
                    toneColor: Colors.blueAccent,
                    items: workListController.tomorrowItems,
                  ),
                  _buildSection(
                    context,
                    title: 'Upcoming',
                    toneColor: Colors.deepPurpleAccent,
                    items: workListController.upcomingItems,
                  ),
                  _buildSection(
                    context,
                    title: 'Completed',
                    toneColor: Colors.green,
                    items: workListController.completedItems,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(WorkListController workListController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Today',
                value: workListController.todayCount.toString(),
                color: AppColors.mainColor,
              ),
            ),
            HSpace(12.w),
            Expanded(
              child: _SummaryCard(
                label: 'Tomorrow',
                value: workListController.tomorrowCount.toString(),
                color: Colors.blueAccent,
              ),
            ),
            HSpace(12.w),
            Expanded(
              child: _SummaryCard(
                label: 'Overdue',
                value: workListController.overdueCount.toString(),
                color: AppColors.redColor,
              ),
            ),
          ],
        ),
        VSpace(12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppThemes.getFillColor(),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                workListController.isOffline
                    ? Icons.cloud_off_rounded
                    : workListController.isSyncing
                        ? Icons.sync_rounded
                        : Icons.cloud_done_rounded,
                color: workListController.isOffline
                    ? AppColors.redColor
                    : AppColors.mainColor,
              ),
              HSpace(10.w),
              Expanded(
                child: Text(
                  workListController.isOffline
                      ? 'Offline mode active. Changes stay queued on this device.'
                      : workListController.isSyncing
                          ? 'Syncing work items...'
                          : 'Work list is synced to the backend.',
                  style: context.t.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: workListController.isOffline || workListController.isSyncing
                    ? null
                    : workListController.syncWorkItems,
                child: const Text('Sync'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppThemes.getFillColor(),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 48.r,
            color: AppColors.mainColor,
          ),
          VSpace(12.h),
          Text(
            'Start with your next work item',
            style: context.t.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          VSpace(8.h),
          Text(
            'Capture today, tomorrow, and follow-up reminders here so nothing slips when the next day starts.',
            textAlign: TextAlign.center,
            style: context.t.bodyMedium?.copyWith(
              color: AppThemes.getParagraphColor(),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Color toneColor,
    required List<WorkListItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: toneColor,
                  shape: BoxShape.circle,
                ),
              ),
              HSpace(8.w),
              Text(
                title,
                style: context.t.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              HSpace(8.w),
              Text(
                '${items.length}',
                style: context.t.bodySmall?.copyWith(
                  color: AppThemes.getParagraphColor(),
                ),
              ),
            ],
          ),
          VSpace(10.h),
          ...items.map((item) => _buildTaskCard(context, item, toneColor)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WorkListItem item, Color toneColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppThemes.getFillColor(),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: toneColor.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => _openTaskEditor(task: item),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: item.isCompleted,
                activeColor: Colors.green,
                onChanged: (value) {
                  controller.toggleCompletion(item.id, value ?? false);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: context.t.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration:
                                  item.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        _PriorityChip(priority: item.priority),
                      ],
                    ),
                    if (item.note.trim().isNotEmpty) ...[
                      VSpace(6.h),
                      Text(
                        item.note,
                        style: context.t.bodyMedium?.copyWith(
                          color: AppThemes.getParagraphColor(),
                          height: 1.35,
                        ),
                      ),
                    ],
                    VSpace(10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _MetaChip(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat('dd MMM, EEE').format(item.dueDate),
                        ),
                        if ((item.customerName ?? '').trim().isNotEmpty)
                          _MetaChip(
                            icon: Icons.person_outline_rounded,
                            label: item.customerName!.trim(),
                          ),
                        if (!item.isSynced)
                          const _MetaChip(
                            icon: Icons.cloud_off_rounded,
                            label: 'Saved offline',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final shouldDelete = await _confirmDelete(item);
                  if (shouldDelete) {
                    controller.deleteItem(item.id);
                  }
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.redColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTaskEditor({WorkListItem? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final noteController = TextEditingController(text: task?.note ?? '');
    DateTime selectedDate = task?.dueDate ?? DateTime.now();
    String selectedPriority = task?.priority ?? 'medium';
    String? selectedCustomerId = task?.customerId;
    String? selectedCustomerName = task?.customerName;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppThemes.getDarkCardColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 20.h,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20.h,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.black30,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                      VSpace(18.h),
                      Text(
                        task == null ? 'Add Work Item' : 'Edit Work Item',
                        style: context.t.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18.sp,
                        ),
                      ),
                      VSpace(16.h),
                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Title'),
                      ),
                      VSpace(12.h),
                      TextField(
                        controller: noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _inputDecoration('Note'),
                      ),
                      VSpace(12.h),
                      InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () async {
                          final selectedCustomer = await _pickCustomer(
                            selectedCustomerId: selectedCustomerId,
                          );
                          if (selectedCustomer == null) return;
                          setSheetState(() {
                            selectedCustomerId = selectedCustomer['id']?.toString();
                            selectedCustomerName = _customerName(selectedCustomer);
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.borderColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                color: AppColors.mainColor,
                                size: 20.sp,
                              ),
                              HSpace(10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer follow-up (optional)',
                                      style: context.t.bodySmall?.copyWith(
                                        color: AppThemes.getParagraphColor(),
                                      ),
                                    ),
                                    VSpace(4.h),
                                    Text(
                                      (selectedCustomerName ?? '').trim().isEmpty
                                          ? 'Choose a customer for this reminder'
                                          : selectedCustomerName!,
                                      style: context.t.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: (selectedCustomerName ?? '').trim().isEmpty
                                            ? AppColors.textFieldHintColor
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if ((selectedCustomerName ?? '').trim().isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedCustomerId = null;
                                      selectedCustomerName = null;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18.sp,
                                    color: AppThemes.getParagraphColor(),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppThemes.getParagraphColor(),
                                  size: 20.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                      VSpace(12.h),
                      InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: sheetContext,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                          decoration: BoxDecoration(
                            color: AppThemes.getFillColor(),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.borderColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.mainColor,
                                size: 20.sp,
                              ),
                              HSpace(10.w),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy, EEEE').format(selectedDate),
                                  style: context.t.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      VSpace(12.h),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        decoration: _inputDecoration('Priority'),
                        items: const [
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            selectedPriority = value;
                          });
                        },
                      ),
                      VSpace(20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            onPressed: () {
                              final title = titleController.text.trim();
                              if (title.isEmpty) {
                                Get.snackbar(
                                  'Missing title',
                                  'Add a title so this item is easy to scan tomorrow.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              final now = DateTime.now();
                              final item = (task ??
                                      WorkListItem(
                                        id: controller.createLocalId(),
                                        title: '',
                                        note: '',
                                        dueDate: selectedDate,
                                        status: WorkListItem.statusPending,
                                        priority: selectedPriority,
                                        customerId: null,
                                        customerName: null,
                                        isSynced: false,
                                        createdAt: now,
                                        updatedAt: now,
                                      ))
                                  .copyWith(
                                    title: title,
                                    note: noteController.text.trim(),
                                    dueDate: selectedDate,
                                    priority: selectedPriority,
                                    customerId: selectedCustomerId,
                                    customerName: selectedCustomerName,
                                    updatedAt: now,
                                  );

                              controller.saveItem(item);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(task == null ? 'Save Task' : 'Update Task'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      noteController.dispose();
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppThemes.getFillColor(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: AppColors.borderColor.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: AppColors.mainColor,
          width: 1.3,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _pickCustomer({String? selectedCustomerId}) async {
    final searchController = TextEditingController();
    try {
      return await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppThemes.getDarkCardColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return GetBuilder<UdharController>(
                builder: (udharState) {
                  final availableCustomers = _customerOptions();
                  final query = searchController.text.trim().toLowerCase();
                  final filteredCustomers = availableCustomers.where((customer) {
                    if (query.isEmpty) return true;
                    final name = _customerName(customer).toLowerCase();
                    final phone = _customerPhone(customer).toLowerCase();
                    return name.contains(query) || phone.contains(query);
                  }).toList();

                  return SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 20.h,
                        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20.h,
                      ),
                      child: SizedBox(
                        height: 520.h,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: AppColors.black30,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                          ),
                          VSpace(18.h),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Choose Customer',
                                  style: context.t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  udharController.fetchUsers();
                                },
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                          VSpace(12.h),
                          TextField(
                            controller: searchController,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: _inputDecoration('Search by name or phone'),
                          ),
                          VSpace(16.h),
                          if (udharState.isUsersLoading && availableCustomers.isEmpty)
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (filteredCustomers.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  availableCustomers.isEmpty
                                      ? 'No customers found yet. Add customers in Udhar to attach follow-ups.'
                                      : 'No customer matches that search.',
                                  textAlign: TextAlign.center,
                                  style: context.t.bodyMedium?.copyWith(
                                    color: AppThemes.getParagraphColor(),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                itemCount: filteredCustomers.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: AppColors.borderColor.withValues(alpha: 0.25),
                                ),
                                itemBuilder: (sheetContext, index) {
                                  final customer = filteredCustomers[index];
                                  final name = _customerName(customer);
                                  final phone = _customerPhone(customer);
                                  final customerId = customer['id']?.toString();
                                  final isSelected = customerId == selectedCustomerId;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () => Navigator.of(sheetContext).pop(customer),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.mainColor.withValues(alpha: 0.12),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                        style: TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: context.t.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      phone.isEmpty ? 'No phone registered' : phone,
                                      style: context.t.bodySmall?.copyWith(
                                        color: AppThemes.getParagraphColor(),
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.mainColor,
                                          )
                                        : const Icon(Icons.chevron_right_rounded),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } finally {
      searchController.dispose();
    }
  }

  Future<bool> _confirmDelete(WorkListItem item) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "${item.title}" from the work list?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }

  List<Map<String, dynamic>> _customerOptions() {
    return udharController.usersList
        .whereType<Map>()
        .map((customer) => Map<String, dynamic>.from(customer.cast<dynamic, dynamic>()))
        .toList();
  }

  String _customerName(Map<String, dynamic> customer) {
    return (customer['name'] ?? customer['customer_name'] ?? 'Customer').toString();
  }

  String _customerPhone(Map<String, dynamic> customer) {
    return (customer['phone'] ?? customer['mobile'] ?? '').toString();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.t.bodySmall?.copyWith(
              color: AppThemes.getParagraphColor(),
            ),
          ),
          VSpace(6.h),
          Text(
            value,
            style: context.t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final normalized = priority.toLowerCase();
    final color = switch (normalized) {
      'high' => AppColors.redColor,
      'low' => Colors.green,
      _ => Colors.orange,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        normalized[0].toUpperCase() + normalized.substring(1),
        style: context.t.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppThemes.getFillColor(),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppThemes.getParagraphColor()),
          HSpace(6.w),
          Text(
            label,
            style: context.t.bodySmall?.copyWith(
              color: AppThemes.getParagraphColor(),
            ),
          ),
        ],
      ),
    );
  }
}