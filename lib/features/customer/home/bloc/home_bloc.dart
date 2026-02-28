import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class HomeEvent {}
class HomeLoaded extends HomeEvent {}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class HomeState {}
class HomeInitial   extends HomeState {}
class HomeLoading   extends HomeState {}
class HomeError     extends HomeState { final String msg; HomeError(this.msg); }

class HomeData extends HomeState {
  final String userName;
  final List<OrderModel> activeOrders;
  final List<OrderModel> recentOrders;
  HomeData({
    required this.userName,
    required this.activeOrders,
    required this.recentOrders,
  });
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  HomeBloc() : super(HomeInitial()) {
    on<HomeLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(HomeLoaded event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final uid = _auth.currentUser!.uid;

      // اسم المستخدم
      final userDoc = await _db.collection('users').doc(uid).get();
      final userName = userDoc.data()?['name'] ?? 'أهلاً';

      // الطلبات النشطة (pending → inProgress)
      final activeSnap = await _db
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .where('status', whereIn: ['pending', 'assigned', 'onTheWay', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      // آخر الطلبات المكتملة
      final recentSnap = await _db
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      emit(HomeData(
        userName: userName,
        activeOrders: activeSnap.docs.map(OrderModel.fromFirestore).toList(),
        recentOrders: recentSnap.docs.map(OrderModel.fromFirestore).toList(),
      ));
    } catch (e) {
      emit(HomeError('حصل خطأ، حاول تاني'));
    }
  }
}
