import 'package:fixit_pro/features/customer/new_request/new_request_bloc.dart';
import 'package:fixit_pro/features/customer/new_request/selectable_chip.dart';
import 'package:fixit_pro/features/customer/new_request/step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── بيانات الخدمة ────────────────────────────────────────────────────────────
const _devices = [
  (emoji: '❄️', name: 'تكييف',    type: 'ac'),
  (emoji: '🧊', name: 'ثلاجة',    type: 'fridge'),
  (emoji: '🫧', name: 'غسالة',    type: 'washer'),
  (emoji: '🔥', name: 'بوتاجاز',  type: 'gas'),
  (emoji: '📺', name: 'تلفزيون',  type: 'tv'),
  (emoji: '♨️', name: 'سخان',     type: 'heater'),
];

const _brands = {
  'ac':     ['Samsung', 'LG', 'Carrier', 'Midea', 'Toshiba', 'Sharp', 'أخرى'],
  'fridge': ['Samsung', 'LG', 'Unionaire', 'Kiriazi', 'Fresh', 'أخرى'],
  'washer': ['Samsung', 'LG', 'Whirlpool', 'Fresh', 'Zanussi', 'أخرى'],
  'gas':    ['Universal', 'Fresh', 'Tornado', 'Olympic', 'أخرى'],
  'tv':     ['Samsung', 'LG', 'Sony', 'Hisense', 'TCL', 'أخرى'],
  'heater': ['Olympic', 'Junkers', 'Bosch', 'Fresh', 'أخرى'],
};

const _issues = {
  'ac':     ['مش بيبرد كويس','بيقطر مية','صوت غريب عالي','بيقفل لوحده','مش بيشتغل خالص','شحن فريون','تركيب جديد','صيانة دورية'],
  'fridge': ['مش بتبرد','بتعمل صوت','بتسرب مية','الضوء مش بيشتغل','الفريزر مش بيجمد','صيانة دورية'],
  'washer': ['مش بتشتغل','مش بتعصر','بتعمل صوت','بتسرب مية','مش بتملاش','صيانة دورية'],
  'gas':    ['مش بيشعل','شعلة واحدة مش بتشتغل','رائحة غاز','الفرن مش بيشتغل','صيانة'],
  'tv':     ['مش بيشتغل','الصورة مش واضحة','مفيش صوت','الشاشة فيها خطوط','مشكلة HDMI'],
  'heater': ['مش بيسخن','بيقطر مية','صوت غريب','مش بيشعل'],
};

// ─── Main Screen ──────────────────────────────────────────────────────────────
class NewRequestScreen extends StatelessWidget {
  const NewRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final initialDevice =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return BlocProvider(
      create: (_) => NewRequestBloc(initialDevice: initialDevice),
      child: const _NewRequestView(),
    );
  }
}

class _NewRequestView extends StatelessWidget {
  const _NewRequestView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewRequestBloc, NewRequestState>(
      listener: (context, state) {
        if (state is NewRequestSuccess) {
          Navigator.pushReplacementNamed(
            context,
            '/customer/tracking',
            arguments: state.orderId,
          );
        }
        if (state is NewRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.msg,
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        if (state is! NewRequestForm) return const SizedBox();
        return Scaffold(
          backgroundColor: AppColors.bgDark,
          body: SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _AppBar(step: state.currentStep),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _buildStep(context, state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, NewRequestForm state) {
    switch (state.currentStep) {
      case 1: return _Step1Device(key: const ValueKey(1), data: state.data);
      case 2: return _Step2Issue(key: const ValueKey(2), data: state.data);
      case 3: return _Step3Schedule(key: const ValueKey(3), data: state.data);
      case 4: return _Step4Confirm(key: const ValueKey(4), data: state.data, isSubmitting: state.isSubmitting);
      default: return const SizedBox();
    }
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final int step;
  const _AppBar({required this.step});

  static const _titles = ['', 'اختار الجهاز', 'نوع العطل', 'الموعد', 'تأكيد الطلب'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (step > 1) {
                    context.read<NewRequestBloc>().add(StepChanged(step - 1));
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textMain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _titles[step],
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              Text(
                '$step / 4',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StepIndicator(currentStep: step),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: اختيار الجهاز والماركة
// ─────────────────────────────────────────────────────────────────────────────
class _Step1Device extends StatefulWidget {
  final RequestData data;
  const _Step1Device({super.key, required this.data});

  @override
  State<_Step1Device> createState() => _Step1DeviceState();
}

class _Step1DeviceState extends State<_Step1Device> {
  String _selectedType  = '';
  String _selectedBrand = '';

  @override
  void initState() {
    super.initState();
    _selectedType  = widget.data.deviceType;
    _selectedBrand = widget.data.brand;
  }

  void _next() {
    if (_selectedType.isNotEmpty && _selectedBrand.isNotEmpty) {
      context.read<NewRequestBloc>().add(
            DeviceSelected(_selectedType, _selectedBrand),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = _brands[_selectedType] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepLabel(title: 'نوع الجهاز', sub: 'اختار الجهاز اللي محتاج صيانة'),
          const SizedBox(height: 16),

          // Grid الأجهزة
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _devices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (_, i) {
              final d = _devices[i];
              final selected = _selectedType == d.type;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedType  = d.type;
                  _selectedBrand = '';
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(d.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        d.name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // الماركة
          if (_selectedType.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _StepLabel(title: 'الماركة', sub: ''),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: brands.map((b) => SelectableChip(
                label: b,
                selected: _selectedBrand == b,
                onTap: () => setState(() => _selectedBrand = b),
              )).toList(),
            ),
          ],

          const SizedBox(height: 32),
          _NextButton(
            label: 'التالي — نوع العطل',
            enabled: _selectedType.isNotEmpty && _selectedBrand.isNotEmpty,
            onTap: _next,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: نوع العطل
// ─────────────────────────────────────────────────────────────────────────────
class _Step2Issue extends StatefulWidget {
  final RequestData data;
  const _Step2Issue({super.key, required this.data});

  @override
  State<_Step2Issue> createState() => _Step2IssueState();
}

class _Step2IssueState extends State<_Step2Issue> {
  String _selected = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.data.issue;
  }

  @override
  Widget build(BuildContext context) {
    final issues = _issues[widget.data.deviceType] ??
        ['مشكلة في التشغيل', 'صوت غريب', 'تسريب', 'صيانة دورية', 'أخرى'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel(
            title: 'وصف المشكلة',
            sub: 'اختار اللي بيحصل مع ${widget.data.deviceType}',
          ),
          const SizedBox(height: 16),

          ...issues.map((issue) {
            final sel = _selected == issue;
            return GestureDetector(
              onTap: () => setState(() => _selected = issue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      issue,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? AppColors.primary
                            : AppColors.textMain,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      sel
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: sel ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          _NextButton(
            label: 'التالي — تحديد الموعد',
            enabled: _selected.isNotEmpty,
            onTap: () => context.read<NewRequestBloc>().add(
                  IssueSelected(_selected),
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3: الموعد والعنوان
// ─────────────────────────────────────────────────────────────────────────────
class _Step3Schedule extends StatefulWidget {
  final RequestData data;
  const _Step3Schedule({super.key, required this.data});

  @override
  State<_Step3Schedule> createState() => _Step3ScheduleState();
}

class _Step3ScheduleState extends State<_Step3Schedule> {
  int _selectedDay  = 0;  // index في قائمة الأيام
  int _selectedSlot = -1; // index في قائمة الأوقات
  String _sla       = 'normal';
  final _addressCtrl = TextEditingController();

  // بناء أيام الأسبوع القادمة
  List<DateTime> get _days =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  static const _slots = [
    '9:00 ص', '11:00 ص', '1:00 م', '3:00 م', '5:00 م',
  ];

  static const _dayNames = [
    'السبت','الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة'
  ];

  String _dayName(DateTime d) => _dayNames[d.weekday % 7];

  DateTime? get _scheduled {
    if (_selectedSlot < 0) return null;
    final day = _days[_selectedDay];
    final hour = [9, 11, 13, 15, 17][_selectedSlot];
    return DateTime(day.year, day.month, day.day, hour);
  }

  @override
  void dispose() { _addressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── اختيار اليوم ────────────────────────────────────────────
          const _StepLabel(title: 'اختار اليوم', sub: 'امتى تحب الفني يجي؟'),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = i == _selectedDay;
                final d   = _days[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayName(d),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── اختيار الوقت ────────────────────────────────────────────
          const _StepLabel(title: 'اختار الوقت', sub: ''),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (_, i) {
              final sel = i == _selectedSlot;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSlot = i;
                  _sla = 'normal';
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _slots[i],
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ── خدمة طارئة ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() {
              _sla = 'emergency';
              _selectedSlot = -1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _sla == 'emergency'
                    ? AppColors.danger.withOpacity(0.1)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _sla == 'emergency'
                      ? AppColors.danger
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('خدمة طارئة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                              fontSize: 13,
                            )),
                        Text('فني يوصلك خلال 2-4 ساعات (+رسوم إضافية)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.textMuted,
                            )),
                      ],
                    ),
                  ),
                  Icon(
                    _sla == 'emergency'
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: _sla == 'emergency'
                        ? AppColors.danger
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── العنوان ─────────────────────────────────────────────────
          const _StepLabel(title: 'عنوان الخدمة', sub: ''),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textMain,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: شارع جامعة الدول، المهندسين، الجيزة',
              hintStyle: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              prefixIcon: const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.bgCard2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 32),
          _NextButton(
            label: 'التالي — مراجعة الطلب',
            enabled: (_selectedSlot >= 0 || _sla == 'emergency') &&
                _addressCtrl.text.trim().isNotEmpty,
            onTap: () {
              final dt = _sla == 'emergency'
                  ? DateTime.now().add(const Duration(hours: 2))
                  : _scheduled!;
              context.read<NewRequestBloc>()
                ..add(ScheduleSelected(dt, _sla))
                ..add(AddressSet(
                  _addressCtrl.text.trim(),
                  // GeoPoint مؤقت — في الـ production هنجيبه من GPS
                  const GeoPoint(30.0444, 31.2357),
                ));
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 4: مراجعة وتأكيد
// ─────────────────────────────────────────────────────────────────────────────
class _Step4Confirm extends StatefulWidget {
  final RequestData data;
  final bool isSubmitting;
  const _Step4Confirm({super.key, required this.data, required this.isSubmitting});

  @override
  State<_Step4Confirm> createState() => _Step4ConfirmState();
}

class _Step4ConfirmState extends State<_Step4Confirm> {
  String _payment = 'cash';

  static const _paymentMethods = [
    (key: 'cash',   emoji: '💵', label: 'كاش'),
    (key: 'card',   emoji: '💳', label: 'بطاقة'),
    (key: 'fawry',  emoji: '📱', label: 'Fawry'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final deviceEmoji = {
      'ac':'❄️','fridge':'🧊','washer':'🫧',
      'gas':'🔥','tv':'📺','heater':'♨️'
    }[d.deviceType] ?? '🔧';

    final estimate = {
      'ac':    '150 – 400 ج',
      'fridge':'100 – 350 ج',
      'washer':'80 – 280 ج',
      'gas':   '50 – 200 ج',
    }[d.deviceType] ?? '80 – 300 ج';

    final scheduleText = d.slaType == 'emergency'
        ? '⚡ طارئ — خلال 2-4 ساعات'
        : d.scheduledAt != null
            ? '${d.scheduledAt!.day}/${d.scheduledAt!.month} — ${d.scheduledAt!.hour}:00'
            : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepLabel(
            title: 'مراجعة الطلب',
            sub: 'اتأكد من التفاصيل قبل التأكيد',
          ),
          const SizedBox(height: 16),

          // ── كارت التفاصيل ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ConfirmRow(label: 'الجهاز',
                    value: '$deviceEmoji ${d.deviceType} — ${d.brand}'),
                _ConfirmRow(label: 'المشكلة', value: d.issue),
                _ConfirmRow(label: 'الموعد',  value: scheduleText),
                _ConfirmRow(label: 'العنوان', value: '📍 ${d.address}'),
                _ConfirmRow(
                  label: 'السعر التقريبي',
                  value: estimate,
                  valueColor: AppColors.accent,
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── طريقة الدفع ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'طريقة الدفع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _paymentMethods.map((m) {
                    final sel = _payment == m.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _payment = m.key);
                          context.read<NewRequestBloc>().add(
                                PaymentSelected(m.key),
                              );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary.withOpacity(0.12)
                                : AppColors.bgCard2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(m.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── ضمان الخدمة ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Text('🛡️', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ضمان الخدمة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            fontSize: 13,
                          )),
                      Text('ضمان 7–30 يوم حسب نوع الإصلاح',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── زرار التأكيد ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isSubmitting
                  ? null
                  : () => context
                      .read<NewRequestBloc>()
                      .add(RequestSubmitted()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 8,
                shadowColor: AppColors.accent.withOpacity(0.4),
              ),
              child: widget.isSubmitting
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      '✅ تأكيد الطلب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _StepLabel extends StatelessWidget {
  final String title;
  final String sub;
  const _StepLabel({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          )),
      if (sub.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(sub,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textMuted,
            )),
      ],
    ],
  );
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  const _ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(
              bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textMuted,
            )),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textMain,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _NextButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.bgCard2,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: enabled ? 8 : 0,
        shadowColor: AppColors.primary.withOpacity(0.35),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: enabled ? Colors.white : AppColors.textMuted,
        ),
      ),
    ),
  );
}
