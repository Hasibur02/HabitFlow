import 'package:flutter/material.dart';

import 'package:habitflow/app_locale.dart';

// ==================================================
// ADD HABIT DIALOG
// ==================================================

class AddHabitDialog extends StatefulWidget {
  final Map<String, IconData> habitIcons;

  const AddHabitDialog({
    super.key,
    required this.habitIcons,
  });

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  late final TextEditingController nameController;

  String selectedIcon = 'star';

  // 1 = Monday ... 7 = Sunday
  final Set<int> selectedDays = {1, 2, 3, 4, 5, 6, 7};

  bool counterMode = false;
  late final TextEditingController targetController;
  late final TextEditingController unitController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    targetController = TextEditingController(text: '3');
    unitController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    targetController.dispose();
    unitController.dispose();
    super.dispose();
  }

  void _addHabit() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    final target = counterMode
        ? (int.tryParse(targetController.text.trim()) ?? 0)
        : 1;

    if (counterMode && target < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.pick(
              'Goal must be 2 or more',
              'লক্ষ্য কমপক্ষে ২ হতে হবে',
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'name': name,
      'icon': selectedIcon,
      'days': (selectedDays.toList()..sort()),
      'target': target,
      'unit': counterMode ? unitController.text.trim() : '',
    });
  }

  List<String> get _dayLabels => AppLocale.pick(
        'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
        'সোম,মঙ্গল,বুধ,বৃহঃ,শুক্র,শনি,রবি',
      ).split(',');

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return AlertDialog(
      title: const Tr(
        'Add New Habit',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: AppLocale.tr('Habit name'),
              hintText: AppLocale.tr('Enter habit name'),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addHabit(),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: selectedIcon,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: AppLocale.tr('Select icon'),
              border: OutlineInputBorder(),
            ),
            items: widget.habitIcons.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(entry.value),
                    const SizedBox(width: 10),
                    Text(entry.key),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedIcon = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // ---------- repeat days ----------
          Text(
            AppLocale.pick('Repeat on', 'কোন কোন দিন'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: selectedDays.contains(i + 1),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (on) {
                    setState(() {
                      if (on) {
                        selectedDays.add(i + 1);
                      } else if (selectedDays.length > 1) {
                        selectedDays.remove(i + 1);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            selectedDays.length == 7
                ? AppLocale.pick('Every day', 'প্রতিদিন')
                : AppLocale.pick('Only on selected days', 'শুধু নির্বাচিত দিনে'),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // ---------- numeric goal ----------
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocale.pick('Numeric goal', 'সংখ্যার লক্ষ্য'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              AppLocale.pick(
                'Count up instead of a single tick (e.g. 3 L water)',
                'টিকের বদলে গুনে এগোবে (যেমন ৩ লিটার পানি)',
              ),
              style: const TextStyle(fontSize: 11),
            ),
            value: counterMode,
            onChanged: (v) => setState(() => counterMode = v),
          ),
          if (counterMode)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocale.pick('Daily goal', 'দৈনিক লক্ষ্য'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    decoration: InputDecoration(
                      labelText: AppLocale.pick('Unit', 'একক'),
                      hintText: AppLocale.pick('pages, L, times', 'পৃষ্ঠা, লিটার, বার'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Tr('Cancel'),
        ),

        FilledButton.icon(
          onPressed: _addHabit,
          icon: const Icon(Icons.add),
          label: const Tr('Add'),
        ),
      ],
    );
  }
}
