import 'package:flutter/material.dart';

class WheelTimePicker {
  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WheelTimePickerSheet(initialTime: initialTime),
    );
  }
}

class _WheelTimePickerSheet extends StatefulWidget {
  const _WheelTimePickerSheet({required this.initialTime});
  final TimeOfDay initialTime;

  @override
  State<_WheelTimePickerSheet> createState() => _WheelTimePickerSheetState();
}

class _WheelTimePickerSheetState extends State<_WheelTimePickerSheet> {
  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _done() {
    Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set time',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Scroll the wheels to choose an hour and minute.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.schedule_rounded, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 218,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Container(
                      height: 54,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.primary.withValues(alpha: .2)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: _wheel(_hourController, 24, true)),
                      Text(':', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Expanded(child: _wheel(_minuteController, 60, false)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _done,
                    icon: const Icon(Icons.check_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('Set time'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: media.viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _wheel(FixedExtentScrollController controller, int count, bool isHour) {
    final scheme = Theme.of(context).colorScheme;
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 54,
      diameterRatio: 1.7,
      perspective: 0.002,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          if (isHour) {
            _hour = index;
          } else {
            _minute = index;
          }
        });
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final selected = isHour ? index == _hour : index == _minute;
          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: selected ? 30 : 21,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: .62),
              ),
            ),
          );
        },
      ),
    );
  }
}
