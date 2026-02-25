import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';

class ServiceReportScreen extends StatefulWidget {
  const ServiceReportScreen({super.key});
  @override
  State<ServiceReportScreen> createState() => _ServiceReportScreenState();
}

class _ServiceReportScreenState extends State<ServiceReportScreen> {
  final _diagnosisCtrl = TextEditingController();
  final _picker        = ImagePicker();

  File? _beforePhoto;
  File? _afterPhoto;
  final List<Map<String, dynamic>> _parts = [];
  bool _isSubmitting = false;

  // إضافة قطعة غيار
  void _addPart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPartSheet(
        onAdd: (name, price) {
          setState(() => _parts.add({'name': name, 'price': price}));
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _pickPhoto(bool isBefore) async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (img == null) return;
    setState(() {
      if (isBefore) _beforePhoto = File(img.path);
      else _afterPhoto = File(img.path);
    });
  }

  double get _totalPrice {
    final parts = _parts.fold<double>(
        0, (sum, p) => sum + (p['price'] as double));
    return parts + 100; // أجر الزيارة ثابت
  }

  Future<void> _submit() async {
    if (_diagnosisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اكتب التشخيص',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final uid     = FirebaseAuth.instance.currentUser!.uid;
    final storage = FirebaseStorage.instance;

    try {
      // رفع الصور
      String? beforeUrl, afterUrl;
      if (_beforePhoto != null) {
        final ref = storage.ref('orders/$orderId/before.jpg');
        await ref.putFile(_beforePhoto!);
        beforeUrl = await ref.getDownloadURL();
      }
      if (_afterPhoto != null) {
        final ref = storage.ref('orders/$orderId/after.jpg');
        await ref.putFile(_afterPhoto!);
        afterUrl = await ref.getDownloadURL();
      }

      // تحديث الطلب في Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status':      'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'diagnosis':   _diagnosisCtrl.text.trim(),
        'partsUsed':   _parts,
        'finalPrice':  _totalPrice,
        'photos': {
          if (beforeUrl != null) 'before': beforeUrl,
          if (afterUrl  != null) 'after':  afterUrl,
        },
      });

      // تحديث أرباح الفني
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .update({
        'todayEarnings': FieldValue.increment(_totalPrice * 0.75),
        'completedOrders': FieldValue.increment(1),
      });

      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حصل خطأ: $e',
            style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  void dispose() { _diagnosisCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('تقرير الخدمة'),
        backgroundColor: AppColors.bgCard,
        foregroundColor: AppColors.textMain,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── صور قبل / بعد ────────────────────────────────────────
            _SectionCard(
              title: '📸 صور قبل / بعد',
              child: Row(
                children: [
                  Expanded(
                    child: _PhotoBox(
                      label: 'قبل',
                      file: _beforePhoto,
                      onTap: () => _pickPhoto(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhotoBox(
                      label: 'بعد',
                      file: _afterPhoto,
                      onTap: () => _pickPhoto(false),
                      highlight: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── قطع الغيار ────────────────────────────────────────────
            _SectionCard(
              title: '🔩 قطع الغيار المستخدمة',
              child: Column(
                children: [
                  ..._parts.map((p) => _PartRow(
                    name: p['name'] as String,
                    price: p['price'] as double,
                    onDelete: () => setState(() => _parts.remove(p)),
                  )),
                  GestureDetector(
                    onTap: _addPart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '＋ إضافة قطعة غيار',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── التشخيص ────────────────────────────────────────────
            _SectionCard(
              title: '🔍 التشخيص والحل',
              child: TextField(
                controller: _diagnosisCtrl,
                textDirection: TextDirection.rtl,
                maxLines: 4,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'اشرح المشكلة اللي لقيتها والحل اللي عملته...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.bgCard2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── ملخص السعر ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.accent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _PriceRow(label: 'أجر الزيارة', value: 100),
                  ..._parts.map((p) => _PriceRow(
                    label: p['name'] as String,
                    value: p['price'] as double,
                  )),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          )),
                      Text(
                        '${_totalPrice.toInt()} ج',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── زرار الإرسال ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                  shadowColor: AppColors.accent.withOpacity(0.4),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text(
                        '✅ إرسال التقرير وإغلاق الطلب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets مساعدة ───────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                )),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _PhotoBox extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;
  final bool highlight;
  const _PhotoBox({
    required this.label,
    required this.file,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.bgCard2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? AppColors.accent : AppColors.border,
              style: file == null ? BorderStyle.solid : BorderStyle.solid,
            ),
            image: file != null
                ? DecorationImage(
                    image: FileImage(file!), fit: BoxFit.cover)
                : null,
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        color: highlight
                            ? AppColors.accent
                            : AppColors.textMuted,
                        size: 28),
                    const SizedBox(height: 6),
                    Text(label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: highlight
                              ? AppColors.accent
                              : AppColors.textMuted,
                        )),
                  ],
                )
              : null,
        ),
      );
}

class _PartRow extends StatelessWidget {
  final String name;
  final double price;
  final VoidCallback onDelete;
  const _PartRow({required this.name, required this.price, required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Text('🔩', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textMain,
                  )),
            ),
            Text('${price.toInt()} ج',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close_rounded,
                  color: AppColors.danger, size: 18),
            ),
          ],
        ),
      );
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textMuted,
                )),
            Text('${value.toInt()} ج',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                )),
          ],
        ),
      );
}

// ─── Add Part Bottom Sheet ────────────────────────────────────────────────────
class _AddPartSheet extends StatefulWidget {
  final Function(String, double) onAdd;
  const _AddPartSheet({required this.onAdd});
  @override
  State<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends State<_AddPartSheet> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _priceCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إضافة قطعة غيار',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              )),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMain),
            decoration: const InputDecoration(
              hintText: 'اسم القطعة (مثال: فريون R32)',
              hintStyle: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMain),
            decoration: const InputDecoration(
              hintText: 'السعر (بالجنيه)',
              hintStyle: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted),
              prefixText: 'ج  ',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name  = _nameCtrl.text.trim();
                final price = double.tryParse(_priceCtrl.text) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  widget.onAdd(name, price);
                }
              },
              child: const Text('إضافة',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}
