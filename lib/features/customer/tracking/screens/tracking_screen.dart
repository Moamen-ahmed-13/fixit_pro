import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:fixit_pro/features/technician/dashboard/status_timeline.dart';
import 'package:fixit_pro/features/technician/dashboard/technician_card.dart';
import 'package:fixit_pro/features/technician/dashboard/tracking_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../../../core/theme/app_theme.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';


class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return BlocProvider(
      create: (_) =>
          TrackingBloc()..add(TrackingStarted(orderId)),
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatefulWidget {
  const _TrackingView();

  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView> {
  GoogleMapController? _mapController;
  final _draggableController = DraggableScrollableController();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Cairo default
  static const _defaultCamera = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 14,
  );

  void _updateMap(TrackingData data) {
    final newMarkers = <Marker>{};
    final newPolylines = <Polyline>{};

    // ماركر العميل
    if (data.order.location != null) {
      final homePos = LatLng(
        data.order.location!.latitude,
        data.order.location!.longitude,
      );
      newMarkers.add(Marker(
        markerId: const MarkerId('home'),
        position: homePos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '🏠 منزلك'),
      ));
    }

    // ماركر الفني + الخط
    if (data.techLocation != null) {
      final techPos = LatLng(
          data.techLocation!.lat, data.techLocation!.lng);
      newMarkers.add(Marker(
        markerId: const MarkerId('tech'),
        position: techPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: '🔧 ${data.techLocation!.name}'),
      ));

      // خط بين الفني والعميل
      if (data.order.location != null) {
        newPolylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: [
            techPos,
            LatLng(
              data.order.location!.latitude,
              data.order.location!.longitude,
            ),
          ],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));

        // تركيز الكاميرا بين الاثنين
        _fitBounds(
          techPos,
          LatLng(
            data.order.location!.latitude,
            data.order.location!.longitude,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
      });
    }
  }

  void _fitBounds(LatLng p1, LatLng p2) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
            p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
          ),
          northeast: LatLng(
            p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
            p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
          ),
        ),
        100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TrackingBloc, TrackingState>(
        listener: (context, state) {
          if (state is TrackingData) _updateMap(state);
        },
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              children: [
                // ── الخريطة ───────────────────────────────────────────
                GoogleMap(
                  initialCameraPosition: _defaultCamera,
                  onMapCreated: (c) => _mapController = c,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  style: _mapDarkStyle,
                ),

                // ── AppBar شفاف ───────────────────────────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _MapButton(
                            icon: Icons.arrow_forward_ios_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  if (state is TrackingData) ...[
                                    const _LiveDot(),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${state.order.id.substring(0, 6).toUpperCase()}',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _statusBadge(state.order.status),
                                  ] else
                                    const Text('تتبع الطلب',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          color: AppColors.textMain,
                                        )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _MapButton(
                            icon: Icons.my_location_rounded,
                            onTap: () {
                              if (state is TrackingData &&
                                  state.order.location != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLng(LatLng(
                                    state.order.location!.latitude,
                                    state.order.location!.longitude,
                                  )),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom Sheet ──────────────────────────────────────
                DraggableScrollableSheet(
                  controller: _draggableController,
                  initialChildSize: 0.42,
                  minChildSize: 0.18,
                  maxChildSize: 0.88,
                  builder: (_, scrollCtrl) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _buildBottomSheet(context, state, scrollCtrl),
                  ),
                ),

                // ── Loading ───────────────────────────────────────────
                if (state is TrackingLoading)
                  const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    TrackingState state,
    ScrollController scrollCtrl,
  ) {
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        if (state is TrackingError) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(state.msg,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textMuted)),
          ),
        ],

        if (state is TrackingData) ...[
          // ─ كارت الفني ──────────────────────────────────────────────
          if (state.techLocation != null) ...[
            TechnicianCard(
              tech: state.techLocation!,
              etaMinutes: state.etaMinutes,
            ),
            const SizedBox(height: 16),
          ] else if (state.order.status == OrderStatus.pending) ...[
            _PendingCard(),
            const SizedBox(height: 16),
          ],

          // ─ Timeline ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حالة الطلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                StatusTimeline(currentStatus: state.order.status),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─ تفاصيل الطلب ────────────────────────────────────────────
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
                  'تفاصيل الطلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: '🔧',
                  label: state.order.deviceType,
                  value: state.order.brand,
                ),
                _DetailRow(
                  icon: '❗',
                  label: 'المشكلة',
                  value: state.order.issue,
                ),
                _DetailRow(
                  icon: '📍',
                  label: 'العنوان',
                  value: state.order.address,
                ),
                if (state.order.estimatedPriceMin != null)
                  _DetailRow(
                    icon: '💰',
                    label: 'التقدير',
                    value:
                        '${state.order.estimatedPriceMin!.toInt()}–${state.order.estimatedPriceMax!.toInt()} ج',
                    valueColor: AppColors.accent,
                    isLast: true,
                  ),
              ],
            ),
          ),

          // ─ زرار الإلغاء (فقط لو pending) ──────────────────────────
          if (state.order.status == OrderStatus.pending) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showCancelDialog(context, state.order.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                ),
                child: const Center(
                  child: Text(
                    'إلغاء الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ─ شاشة التقييم لو مكتمل ───────────────────────────────────
          if (state.order.status == OrderStatus.completed &&
              state.order.rating == null) ...[
            const SizedBox(height: 16),
            _RatingCard(orderId: state.order.id),
          ],
        ],
      ],
    );
  }

  Widget _statusBadge(OrderStatus status) {
    final colors = {
      OrderStatus.pending:    AppColors.warning,
      OrderStatus.assigned:   AppColors.accent,
      OrderStatus.onTheWay:   AppColors.primary,
      OrderStatus.inProgress: AppColors.primary,
      OrderStatus.completed:  AppColors.accent,
      OrderStatus.cancelled:  AppColors.danger,
    };
    final color = colors[status] ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:    return 'انتظار';
      case OrderStatus.assigned:   return 'تم التعيين';
      case OrderStatus.onTheWay:   return 'في الطريق';
      case OrderStatus.inProgress: return 'جاري';
      case OrderStatus.completed:  return 'مكتمل ✅';
      case OrderStatus.cancelled:  return 'ملغي';
    }
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('إلغاء الطلب',
              style: TextStyle(
                  fontFamily: 'Cairo', color: AppColors.textMain)),
          content: const Text(
            'هل أنت متأكد إنك عايز تلغي الطلب؟',
            style:
                TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لأ',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({'status': 'cancelled'});
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('نعم، إلغاء',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets مساعدة ───────────────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textMain, size: 18),
        ),
      );
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _PendingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Text('⏳', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('بنبحث عن أقرب فني',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      )),
                  SizedBox(height: 4),
                  Text('عادةً بنلاقي فني خلال 5-10 دقائق',
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
      );
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textMuted,
                )),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Rating Card ──────────────────────────────────────────────────────────────
class _RatingCard extends StatefulWidget {
  final String orderId;
  const _RatingCard({required this.orderId});
  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _stars = 0;
  bool _submitted = false;

  void _submit() {
    if (_stars == 0) return;
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({'rating': _stars.toDouble()});
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: const Center(
          child: Column(
            children: [
              Text('🎉', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text('شكراً على تقييمك!',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  )),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text('⭐ قيّم الخدمة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < _stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _stars > 0 ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إرسال التقييم',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dark Map Style ───────────────────────────────────────────────────────────
const _mapDarkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0f0f1a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8888aa"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0f0f1a"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#252540"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2d2d50"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0a14"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1a1a2e"}]}
]
''';

