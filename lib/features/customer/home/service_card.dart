import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ServiceItem {
  final String emoji;
  final String name;
  final String type; // الـ key اللي بنبعته للـ new_request
  const ServiceItem({required this.emoji, required this.name, required this.type});
}

const kServices = [
  ServiceItem(emoji: '❄️', name: 'تكييف',   type: 'ac'),
  ServiceItem(emoji: '🧊', name: 'ثلاجة',   type: 'fridge'),
  ServiceItem(emoji: '🫧', name: 'غسالة',   type: 'washer'),
  ServiceItem(emoji: '🔥', name: 'بوتاجاز', type: 'gas'),
  ServiceItem(emoji: '📺', name: 'تلفزيون', type: 'tv'),
  ServiceItem(emoji: '♨️', name: 'سخان',    type: 'heater'),
  ServiceItem(emoji: '🧺', name: 'نشافة',   type: 'dryer'),
  ServiceItem(emoji: '➕', name: 'المزيد',  type: 'other'),
];

class ServiceCard extends StatefulWidget {
  final ServiceItem item;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.item, required this.onTap});

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:    (_) => _ctrl.reverse(),
      onTapUp:      (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel:  ()  => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.item.emoji,
                  style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                widget.item.name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
