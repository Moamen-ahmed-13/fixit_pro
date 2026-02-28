import 'package:fixit_pro/features/customer/home/service_card.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  final _keywords = {
    'ac':     ['تكييف', 'مكيف', 'تبريد', 'بارد', 'ac'],
    'fridge': ['ثلاجة', 'تبريد', 'بارد', 'fridge'],
    'washer': ['غسالة', 'ملابس', 'هدوم', 'washer'],
    'gas':    ['بوتاجاز', 'غاز', 'طبخ', 'نار', 'gas'],
    'tv':     ['تلفزيون', 'شاشة', 'tv'],
    'heater': ['سخان', 'دش', 'ساخن', 'heater'],
    'dryer':  ['نشافة', 'تجفيف', 'dryer'],
    'other':  ['المزيد', 'أخرى', 'other'],
  };

  List<ServiceItem> get _results {
    if (_query.isEmpty) return kServices;
    final q = _query.toLowerCase().trim();
    return kServices.where((s) {
      if (s.name.contains(q)) return true;
      return (_keywords[s.type] ?? []).any((k) => k.contains(q) || q.contains(k));
    }).toList();
  }

  final _popular = ['❄️ تكييف', '🫧 غسالة', '🔥 بوتاجاز', '📺 تلفزيون', '🧊 ثلاجة'];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.bgCard2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMain, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث عن خدمة...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                      onPressed: () { _controller.clear(); setState(() => _query = ''); },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      body: _query.isEmpty ? _buildEmpty() : _buildResults(),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('عمليات بحث شائعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _popular.map((label) => GestureDetector(
              onTap: () {
                final clean = label.replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z ]'), '').trim();
                _controller.text = clean;
                setState(() => _query = clean);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textMuted)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 28),
          const Text('كل الخدمات', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
              ),
              itemCount: kServices.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => Navigator.pushNamed(ctx, '/customer/new-request', arguments: kServices[i].type),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.bgCard2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(kServices[i].emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(kServices[i].name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final results = _results;
    if (results.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔍', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text('مفيش نتائج لـ "$_query"', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        const Text('جرب كلمة تانية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textMuted)),
      ]));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${results.length} نتيجة', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
            ),
            itemCount: results.length,
            itemBuilder: (ctx, i) => ServiceCard(
              item: results[i],
              onTap: () => Navigator.pushNamed(ctx, '/customer/new-request', arguments: results[i].type),
            ),
          ),
        ),
      ]),
    );
  }
}
