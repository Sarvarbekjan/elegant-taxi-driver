// ============================================================================
// ELEGANT DRIVER - HAYDOVCHI TAKSOMETRI (DRIVER APP v5.3) - TO'LIQ KOD (XATOSIZ)
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await driverState.initializeApp();
  runApp(const ElegantDriverApp());
}

const Color kPrimaryGreen = Color(0xFF22A038);
const Color kAccentYellow = Color(0xFFFFCC00);
const Color kDarkBg = Color(0xFF12151C);
const Color kDarkCard = Color(0xFF1C202B);
const String kFirebaseDbUrl = "https://elegant-taxi-b4e46-default-rtdb.firebaseio.com";
const String kSmsRuApiId = "5E690BBC-C5D8-A611-97B8-3BC185697858";

class DriverStrings {
  static Map<String, Map<String, String>> data = {
    "O'zbek": {
      "online": "Liniyada (Bo'sh)",
      "offline": "Band (Liniyada emas)",
      "balance": "Balans",
      "topup": "Hisobni to'ldirish",
      "orders_radar": "Buyurtmalar radari",
      "active_trip": "Joriy safar",
      "earnings": "Daromad va statistika",
      "tariffs_info": "Tariflar va komissiya",
      "settings": "Sozlamalar",
      "logout": "Akkauntdan chiqish",
      "new_order_alert": "YANGI BUYURTMA!",
      "accept_btn": "QABUL QILISH",
      "skip_btn": "O'tkazib yuborish",
      "arrived_btn": "MANZILGA YETIB KELDIM",
      "start_trip_btn": "SAFARNI BOSHLASH (TAKSOMETR)",
      "finish_trip_btn": "SAFARni YAKUNLASH",
      "transfer_order": "Boshqa haydovchiga o'tkazish",
      "wait_free": "Bepul kutish",
      "wait_paid": "Pullik kutish",
      "pause_wait": "Kutish rejimi (Bozor/Do'kon)",
      "resume_drive": "Harakatni davom ettirish",
      "low_balance_warn": "Balansingizda mablag' yetarli emas (min 5 000). Buyurtma olish uchun hisobni to'ldiring!",
      "open_dest_badge": "Manzilni mijoz aytadi (Taksometr)",
      "call_client": "Mijozga qo'ng'iroq",
      "chat_client": "Mijoz bilan chat",
      "save_btn": "SAQLASH",
    },
    "Русский": {
      "online": "На линии (Свободен)",
      "offline": "Занят (Не на линии)",
      "balance": "Баланс",
      "topup": "Пополнить баланс",
      "orders_radar": "Радар заказов",
      "active_trip": "Текущая поездка",
      "earnings": "Доход и статистика",
      "tariffs_info": "Тарифы и комиссия",
      "settings": "Настройки",
      "logout": "Выйти из аккаунта",
      "new_order_alert": "НОВЫЙ ЗАКАЗ!",
      "accept_btn": "ПРИНЯТЬ ЗАКАЗ",
      "skip_btn": "Пропустить",
      "arrived_btn": "НА МЕСТЕ (ОЖИДАНИЕ)",
      "start_trip_btn": "НАЧАТЬ ПОЕЗДКУ (ТАКСОМЕТР)",
      "finish_trip_btn": "ЗАВЕРШИТЬ ПОЕЗДКУ",
      "transfer_order": "Передать другому водителю",
      "wait_free": "Бесплатное ожидание",
      "wait_paid": "Платное ожидание",
      "pause_wait": "Режим ожидания (Магазин)",
      "resume_drive": "Продолжить движение",
      "low_balance_warn": "Недостаточно средств на балансе (мин 5 000). Пополните счёт для приёма заказов!",
      "open_dest_badge": "Адрес скажет клиент (По таксометру)",
      "call_client": "Позвонить клиенту",
      "chat_client": "Чат с клиентом",
      "save_btn": "СОХРАНИТЬ",
    },
  };

  static String tr(String key) {
    final lang = driverState.currentLanguage;
    return data[lang]?[key] ?? data["O'zbek"]![key] ?? key;
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final String time;

  ChatMessage({required this.sender, required this.text, required this.time});

  Map<String, dynamic> toJson() => {'sender': sender, 'text': text, 'time': time};

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        sender: j['sender']?.toString() ?? 'client',
        text: j['text']?.toString() ?? '',
        time: j['time']?.toString() ?? '',
      );
}

class OrderModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final String fromAddress;
  final String toAddress;
  final String landmarkNote;
  final bool isOpenDestination;
  final String paymentMethod;
  final Point fromPoint;
  final Point toPoint;
  final String tariff;
  double distanceKm;
  int price;
  final List<String> wishes;
  String status;
  String? driverId;
  String? driverName;
  String? driverCar;
  String? driverPhone;
  double? driverLat;
  double? driverLon;
  int waitSeconds;
  int waitFee;
  int? rating;
  bool closedByClient;
  List<ChatMessage> messages;
  final DateTime createdAt;
  int updatedAtMs;

  OrderModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.fromAddress,
    required this.toAddress,
    this.landmarkNote = "",
    this.isOpenDestination = false,
    this.paymentMethod = "Naqd pul",
    required this.fromPoint,
    required this.toPoint,
    required this.tariff,
    required this.distanceKm,
    required this.price,
    this.wishes = const [],
    this.status = 'Kutilmoqda',
    this.driverId,
    this.driverName,
    this.driverCar,
    this.driverPhone,
    this.driverLat,
    this.driverLon,
    this.waitSeconds = 0,
    this.waitFee = 0,
    this.rating,
    this.closedByClient = false,
    this.messages = const [],
    required this.createdAt,
    int? updatedAtMs,
  }) : updatedAtMs = updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'fromAddress': fromAddress,
        'toAddress': toAddress,
        'landmarkNote': landmarkNote,
        'isOpenDestination': isOpenDestination,
        'paymentMethod': paymentMethod,
        'fromLat': fromPoint.latitude,
        'fromLon': fromPoint.longitude,
        'toLat': toPoint.latitude,
        'toLon': toPoint.longitude,
        'tariff': tariff,
        'distanceKm': distanceKm,
        'price': price,
        'wishes': wishes,
        'status': status,
        'driverId': driverId,
        'driverName': driverName,
        'driverCar': driverCar,
        'driverPhone': driverPhone,
        'driverLat': driverLat,
        'driverLon': driverLon,
        'waitSeconds': waitSeconds,
        'waitFee': waitFee,
        'rating': rating,
        'closedByClient': closedByClient,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAtMs': updatedAtMs,
      };

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id']?.toString() ?? 'ORD-100',
        clientName: j['clientName']?.toString() ?? 'Mijoz',
        clientPhone: j['clientPhone']?.toString() ?? '',
        fromAddress: j['fromAddress']?.toString() ?? '',
        toAddress: j['toAddress']?.toString() ?? '',
        landmarkNote: j['landmarkNote']?.toString() ?? '',
        isOpenDestination: j['isOpenDestination'] == true,
        paymentMethod: j['paymentMethod']?.toString() ?? 'Naqd pul',
        fromPoint: Point(
          latitude: (j['fromLat'] ?? 38.0167).toDouble(),
          longitude: (j['fromLon'] ?? 67.7875).toDouble(),
        ),
        toPoint: Point(
          latitude: (j['toLat'] ?? 38.0200).toDouble(),
          longitude: (j['toLon'] ?? 67.7950).toDouble(),
        ),
        tariff: j['tariff']?.toString() ?? 'Standart',
        distanceKm: (j['distanceKm'] ?? 1.5).toDouble(),
        price: (j['price'] ?? 4000).toInt(),
        wishes: j['wishes'] is List ? List<String>.from(j['wishes']) : [],
        status: j['status']?.toString() ?? 'Kutilmoqda',
        driverId: j['driverId']?.toString(),
        driverName: j['driverName']?.toString(),
        driverCar: j['driverCar']?.toString(),
        driverPhone: j['driverPhone']?.toString(),
        driverLat: j['driverLat'] != null ? (j['driverLat'] as num).toDouble() : null,
        driverLon: j['driverLon'] != null ? (j['driverLon'] as num).toDouble() : null,
        waitSeconds: (j['waitSeconds'] ?? 0).toInt(),
        waitFee: (j['waitFee'] ?? 0).toInt(),
        rating: j['rating'] != null ? (j['rating'] as num).toInt() : null,
        closedByClient: j['closedByClient'] == true,
        messages: j['messages'] is List
            ? (j['messages'] as List).whereType().map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m))).toList()
            : [],
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAtMs: (j['updatedAtMs'] ?? 0).toInt(),
      );
}

class DriverAppState extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.example.elegant_taxi/native');
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  Timer? _syncTimer;
  bool _isSyncing = false;

  int stdBase = 4000;
  int stdPerKm = 2000;
  int comfBase = 5000;
  int comfPerKm = 3000;
  int delivBase = 6000;
  int delivPerKm = 2500;
  int damasBase = 8000;
  int damasPerKm = 3000;
  int waitPerMin = 500;
  int commissionPercent = 10;
  int minRequiredBalance = 5000;
  double surgeMultiplier = 1.0;
  String currencyLabel = "so'm";

  bool isAuthenticated = false;
  String driverId = "DRV-101";
  String driverName = "";
  String driverPhone = "";
  String carModel = "Chevrolet Cobalt";
  String carNumber = "75 A 777 AA";
  String tariffType = "Standart";
  int balance = 25000;
  bool isOnline = true;
  bool isBlocked = false;
  int completedTripsCount = 0;
  int totalEarnedSum = 0;
  int totalCommissionPaid = 0;

  Point currentGps = const Point(latitude: 38.0167, longitude: 67.7875);
  String currentLanguage = "O'zbek";
  String addressLanguage = "RU";
  bool isDarkMode = true;
  bool isFirebaseConnected = false;

  List<OrderModel> orders = [];
  Set<String> skippedOrderIds = {};
  String? currentRingingOrderId;
  Map<String, int> knownMsgCounts = {};

  String get fullCarTitle => "$carModel ($carNumber)";
  bool get hasEnoughBalance => balance >= minRequiredBalance && !isBlocked;

  Future<void> initializeApp() async {
    await loadFromStorage();
    await applyMapLocale(addressLanguage);
    await syncFromFirebase(isInitial: true);
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) => syncFromFirebase());
  }

  Future<void> applyMapLocale(String langCode) async {
    addressLanguage = langCode;
    String nativeLoc = "ru_RU";
    if (langCode == "UZ") nativeLoc = "uz_UZ";
    if (langCode == "EN") nativeLoc = "en_US";
    try {
      await _nativeChannel.invokeMethod('setMapLocale', {'locale': nativeLoc});
    } catch (_) {}
    await saveToStorage();
    notifyListeners();
  }

  Future<void> playOrderRingtone() async {
    try {
      HapticFeedback.heavyImpact();
      await _nativeChannel.invokeMethod('playOrderRingtone');
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> stopOrderRingtone() async {
    try {
      await _nativeChannel.invokeMethod('stopOrderRingtone');
    } catch (_) {}
  }

  Future<void> playShortBeep() async {
    try {
      HapticFeedback.mediumImpact();
      await _nativeChannel.invokeMethod('playSound');
    } catch (_) {}
  }

  Future<void> dialPhoneNumber(String phone) async {
    try {
      await _nativeChannel.invokeMethod('dialPhone', {'phone': phone});
    } catch (_) {}
  }

  Future<void> loadFromStorage() async {
    try {
      final String? raw = await _nativeChannel.invokeMethod<String>('loadData');
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        isAuthenticated = data['isAuthenticated'] ?? false;
        driverId = data['driverId'] ?? "DRV-${Random().nextInt(899) + 100}";
        driverName = data['driverName'] ?? "";
        driverPhone = data['driverPhone'] ?? "";
        carModel = data['carModel'] ?? "Chevrolet Cobalt";
        carNumber = data['carNumber'] ?? "75 A 777 AA";
        tariffType = data['tariffType'] ?? "Standart";
        balance = data['balance'] ?? 25000;
        isOnline = data['isOnline'] ?? true;
        completedTripsCount = data['completedTripsCount'] ?? 0;
        totalEarnedSum = data['totalEarnedSum'] ?? 0;
        totalCommissionPaid = data['totalCommissionPaid'] ?? 0;
        currentLanguage = data['currentLanguage'] ?? "O'zbek";
        addressLanguage = data['addressLanguage'] ?? "RU";
        isDarkMode = data['isDarkMode'] ?? true;
        if (data['skippedOrderIds'] is List) {
          skippedOrderIds = List<String>.from(data['skippedOrderIds']).toSet();
        }
      }
    } catch (_) {}
  }

  Future<void> saveToStorage() async {
    try {
      final Map<String, dynamic> localData = {
        'isAuthenticated': isAuthenticated,
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'carModel': carModel,
        'carNumber': carNumber,
        'tariffType': tariffType,
        'balance': balance,
        'isOnline': isOnline,
        'completedTripsCount': completedTripsCount,
        'totalEarnedSum': totalEarnedSum,
        'totalCommissionPaid': totalCommissionPaid,
        'currentLanguage': currentLanguage,
        'addressLanguage': addressLanguage,
        'isDarkMode': isDarkMode,
        'skippedOrderIds': skippedOrderIds.toList(),
      };
      await _nativeChannel.invokeMethod('saveData', {'data': jsonEncode(localData)});
    } catch (_) {}
  }

  Future<void> _putJson(String path, Map<String, dynamic> payload) async {
    final Uri uri = Uri.parse("$kFirebaseDbUrl/$path.json");
    final HttpClientRequest req = await _http.putUrl(uri);
    req.headers.set('Content-Type', 'application/json; charset=utf-8');
    req.add(utf8.encode(jsonEncode(payload)));
    final HttpClientResponse res = await req.close();
    await res.drain();
  }

  Future<void> syncDriverToFirebase() async {
    if (!isAuthenticated || driverId.isEmpty) return;
    try {
      await _putJson("elegant_cloud/drivers/$driverId", {
        'id': driverId,
        'name': driverName,
        'phone': driverPhone,
        'carModel': carModel,
        'carNumber': carNumber,
        'tariffType': tariffType,
        'balance': balance,
        'isOnline': isOnline,
        'isBlocked': isBlocked,
        'completedTrips': completedTripsCount,
        'totalEarned': totalEarnedSum,
        'totalCommission': totalCommissionPaid,
        'lat': currentGps.latitude,
        'lon': currentGps.longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> pushOrderToFirebase(OrderModel order) async {
    try {
      await _putJson("elegant_cloud/orders/${order.id}", order.toJson());
      isFirebaseConnected = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendTopUpRequestToAdmin(int amount) async {
    final reqId = "TOP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    try {
      await _putJson("elegant_cloud/topup_requests/$reqId", {
        'id': reqId,
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'amount': amount,
        'status': 'Kutilmoqda',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> syncFromFirebase({bool isInitial = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final Uri uri = Uri.parse("$kFirebaseDbUrl/elegant_cloud.json");
      final HttpClientRequest req = await _http.getUrl(uri);
      final HttpClientResponse res = await req.close();
      if (res.statusCode == 200) {
        final String body = await res.transform(utf8.decoder).join();
        isFirebaseConnected = true;
        if (body.isNotEmpty && body != "null") {
          final Map<String, dynamic> root = jsonDecode(body);

          if (root['config'] is Map) {
            final cfg = Map<String, dynamic>.from(root['config']);
            stdBase = cfg['stdBase'] ?? stdBase;
            stdPerKm = cfg['stdPerKm'] ?? stdPerKm;
            comfBase = cfg['comfBase'] ?? comfBase;
            comfPerKm = cfg['comfPerKm'] ?? comfPerKm;
            delivBase = cfg['delivBase'] ?? delivBase;
            delivPerKm = cfg['delivPerKm'] ?? delivPerKm;
            damasBase = cfg['damasBase'] ?? damasBase;
            damasPerKm = cfg['damasPerKm'] ?? damasPerKm;
            waitPerMin = cfg['waitPerMin'] ?? waitPerMin;
            commissionPercent = cfg['commissionPercent'] ?? commissionPercent;
            surgeMultiplier = (cfg['surgeMultiplier'] ?? surgeMultiplier).toDouble();
            currencyLabel = cfg['currencyLabel']?.toString() ?? currencyLabel;
          }

          if (isAuthenticated && root['drivers'] is Map) {
            final dMap = Map<String, dynamic>.from(root['drivers']);
            if (dMap[driverId] is Map) {
              final myCloud = Map<String, dynamic>.from(dMap[driverId]);
              final int cloudBal = (myCloud['balance'] ?? balance).toInt();
              final bool cloudBlocked = myCloud['isBlocked'] == true;
              if (cloudBal != balance || cloudBlocked != isBlocked) {
                balance = cloudBal;
                isBlocked = cloudBlocked;
                await saveToStorage();
              }
            }
          }

          if (root['orders'] is Map) {
            final Map<String, dynamic> oMap = Map<String, dynamic>.from(root['orders']);
            final List<OrderModel> cloudOrders = oMap.values
                .whereType()
                .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            cloudOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            for (final co in cloudOrders) {
              final prevCnt = knownMsgCounts[co.id] ?? co.messages.length;
              if (co.driverId == driverId && co.messages.length > prevCnt && !isInitial) {
                if (co.messages.last.sender == 'client') {
                  playShortBeep();
                }
              }
              knownMsgCounts[co.id] = co.messages.length;
            }

            orders = cloudOrders;
            _evaluateIncomingOrderRingtone();
            notifyListeners();
          }
        }
      }
    } catch (_) {
      isFirebaseConnected = false;
    } finally {
      _isSyncing = false;
    }
  }

  OrderModel? get activeDriverOrder {
    for (final o in orders) {
      if (o.driverId == driverId &&
          (o.status == 'Qabul qilindi' || o.status == 'Yetib keldi' || o.status == 'Safarda')) {
        return o;
      }
    }
    return null;
  }

  List<OrderModel> get availableWaitingOrders {
    if (!isOnline || !hasEnoughBalance) return [];
    return orders.where((o) {
      if (o.status != 'Kutilmoqda') return false;
      if (skippedOrderIds.contains(o.id)) return false;
      if (o.driverId != null && o.driverId!.isNotEmpty && o.driverId != driverId) return false;
      return true;
    }).toList();
  }

  void _evaluateIncomingOrderRingtone() {
    if (!isAuthenticated || !isOnline || !hasEnoughBalance || activeDriverOrder != null) {
      if (currentRingingOrderId != null) {
        currentRingingOrderId = null;
        stopOrderRingtone();
      }
      return;
    }

    final waiting = availableWaitingOrders;
    if (waiting.isNotEmpty) {
      final topOrder = waiting.first;
      if (currentRingingOrderId != topOrder.id) {
        currentRingingOrderId = topOrder.id;
        playOrderRingtone();
      }
    } else {
      if (currentRingingOrderId != null) {
        currentRingingOrderId = null;
        stopOrderRingtone();
      }
    }
  }

  Future<void> completeRegistration({
    required String name,
    required String phone,
    required String model,
    required String number,
    required String tariff,
  }) async {
    driverName = name.trim();
    driverPhone = phone.trim();
    carModel = model.trim();
    carNumber = number.trim().toUpperCase();
    tariffType = tariff;
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.length >= 7) {
      driverId = "DRV-${cleanDigits.substring(cleanDigits.length - 7)}";
    }
    isAuthenticated = true;
    isOnline = true;
    await saveToStorage();
    await syncDriverToFirebase();
    notifyListeners();
  }

  void toggleOnlineStatus(bool val) {
    isOnline = val;
    if (!val) {
      currentRingingOrderId = null;
      stopOrderRingtone();
    } else {
      _evaluateIncomingOrderRingtone();
    }
    saveToStorage();
    syncDriverToFirebase();
    notifyListeners();
  }

  void skipOrder(String orderId) {
    skippedOrderIds.add(orderId);
    if (currentRingingOrderId == orderId) {
      currentRingingOrderId = null;
      stopOrderRingtone();
    }
    _evaluateIncomingOrderRingtone();
    saveToStorage();
    notifyListeners();
  }

  Future<void> acceptOrder(OrderModel ord) async {
    stopOrderRingtone();
    currentRingingOrderId = null;

    ord.status = 'Qabul qilindi';
    ord.driverId = driverId;
    ord.driverName = driverName;
    ord.driverCar = fullCarTitle;
    ord.driverPhone = driverPhone;
    ord.driverLat = currentGps.latitude;
    ord.driverLon = currentGps.longitude;
    ord.updatedAtMs = DateTime.now().millisecondsSinceEpoch;

    await pushOrderToFirebase(ord);
    await saveToStorage();
    notifyListeners();
  }

  Future<void> markArrivedAtClient(OrderModel ord) async {
    ord.status = 'Yetib keldi';
    ord.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await pushOrderToFirebase(ord);
    playShortBeep();
    notifyListeners();
  }

  Future<void> startRideTaxometer(OrderModel ord) async {
    ord.status = 'Safarda';
    ord.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await pushOrderToFirebase(ord);
    playShortBeep();
    notifyListeners();
  }

  Future<void> transferOrderToOtherDrivers(OrderModel ord) async {
    skippedOrderIds.add(ord.id);
    ord.status = 'Kutilmoqda';
    ord.driverId = null;
    ord.driverName = null;
    ord.driverCar = null;
    ord.driverPhone = null;
    ord.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await pushOrderToFirebase(ord);
    notifyListeners();
  }

  Future> completeTripAndDeductCommission(
    OrderModel ord, {
    required double finalKm,
    required int finalPrice,
    required int finalWaitFee,
    required int waitSec,
  }) async {
    final int totalAmount = finalPrice + finalWaitFee;
    final int commission = ((totalAmount * commissionPercent) / 100).round();

    ord.distanceKm = double.parse(finalKm.toStringAsFixed(1));
    ord.price = finalPrice;
    ord.waitFee = finalWaitFee;
    ord.waitSeconds = waitSec;
    ord.status = 'Yakunlandi';
    ord.updatedAtMs = DateTime.now().millisecondsSinceEpoch;

    balance -= commission;
    completedTripsCount += 1;
    totalEarnedSum += totalAmount;
    totalCommissionPaid += commission;

    await pushOrderToFirebase(ord);
    await saveToStorage();
    await syncDriverToFirebase();
    playShortBeep();
    notifyListeners();

    return {
      'basePrice': finalPrice,
      'waitFee': finalWaitFee,
      'total': totalAmount,
      'commission': commission,
      'newBalance': balance,
    };
  }

  void sendDriverChatMessage(String orderId, String text) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1 && text.trim().isNotEmpty) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final updatedMsgs = List<ChatMessage>.from(orders[idx].messages)
        ..add(ChatMessage(sender: 'driver', text: text.trim(), time: timeStr));
      orders[idx].messages = updatedMsgs;
      orders[idx].updatedAtMs = now.millisecondsSinceEpoch;
      knownMsgCounts[orderId] = updatedMsgs.length;
      pushOrderToFirebase(orders[idx]);
      notifyListeners();
    }
  }

  int getTariffBase(String t) {
    if (t == 'Komfort') return comfBase;
    if (t == 'Pochta') return delivBase;
    if (t == 'Damas') return damasBase;
    return stdBase;
  }

  int getTariffPerKm(String t) {
    if (t == 'Komfort') return comfPerKm;
    if (t == 'Pochta') return delivPerKm;
    if (t == 'Damas') return damasPerKm;
    return stdPerKm;
  }
}

final DriverAppState driverState = DriverAppState();

class ElegantDriverApp extends StatelessWidget {
  const ElegantDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: driverState,
      builder: (context, _) {
        final bool dark = driverState.isDarkMode;
        return MaterialApp(
          title: 'Elegant Driver',
          debugShowCheckedModeBanner: false,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: kPrimaryGreen,
            scaffoldBackgroundColor: const Color(0xFFF4F6F9),
            cardColor: Colors.white,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: kPrimaryGreen,
            scaffoldBackgroundColor: kDarkBg,
            cardColor: kDarkCard,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          home: driverState.isAuthenticated ? const DriverMainScaffold() : const DriverAuthScreen(),
        );
      },
    );
  }
}

class DriverAuthScreen extends StatefulWidget {
  const DriverAuthScreen({super.key});
  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _carModelCtrl = TextEditingController(text: "Chevrolet Cobalt");
  final TextEditingController _carNumCtrl = TextEditingController(text: "75 A 777 AA");
  String _selectedTariff = "Standart";
  String _countryCode = "+998";
  String? _err;
  bool _loading = false;

  Future<void> _submitDriverLogin() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final model = _carModelCtrl.text.trim();
    final num = _carNumCtrl.text.trim();

    if (name.isEmpty || phone.length < 7 || model.isEmpty || num.isEmpty) {
      setState(() => _err = "Barcha maydonlarni to'liq to'ldiring!");
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
    });

    await driverState.completeRegistration(
      name: name,
      phone: "$_countryCode $phone",
      model: model,
      number: num,
      tariff: _selectedTariff,
    );

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = driverState.isDarkMode;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: kAccentYellow,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: kAccentYellow.withOpacity(0.35), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.local_taxi, color: Colors.black, size: 46),
                ),
                const SizedBox(height: 14),
                const Text("Elegant Driver Pro", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const Text(
                  "Haydovchilar uchun raqamli GPS Taksometr va Zakaz Radari",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: dark ? kDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: "Ism va Familiyangiz",
                          prefixIcon: const Icon(Icons.person_outline, color: kPrimaryGreen),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade600),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _countryCode,
                                items: const [
                                  DropdownMenuItem(value: "+998", child: Text("🇺🇿 +998")),
                                  DropdownMenuItem(value: "+7", child: Text("🇷🇺 +7")),
                                ],
                                onChanged: (v) => setState(() => _countryCode = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Telefon raqam",
                                hintText: "90 123 45 67",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _carModelCtrl,
                        decoration: InputDecoration(
                          labelText: "Avtomobil rusumi (Cobalt, Gentra, Damas)",
                          prefixIcon: const Icon(Icons.directions_car_outlined, color: kAccentYellow),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _carNumCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: "Davlat raqami (75 A 777 AA)",
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, color: kPrimaryGreen),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedTariff,
                        decoration: InputDecoration(
                          labelText: "Asosiy Tarif yo'nalishi",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Standart", child: Text("Standart (Oddiy taksi)")),
                          DropdownMenuItem(value: "Komfort", child: Text("Komfort (Konditsionerli)")),
                          DropdownMenuItem(value: "Pochta", child: Text("Pochta / Bozorlik eltish")),
                          DropdownMenuItem(value: "Damas", child: Text("Damas / Yuk tashish")),
                        ],
                        onChanged: (v) => setState(() => _selectedTariff = v!),
                      ),
                      if (_err != null) ...[
                        const SizedBox(height: 8),
                        Text(_err!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _loading ? null : _submitDriverLogin,
                          icon: const Icon(Icons.login),
                          label: const Text("LINIYAGA KIRISH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DriverMainScaffold extends StatefulWidget {
  const DriverMainScaffold({super.key});

  @override
  State<DriverMainScaffold> createState() => _DriverMainScaffoldState();
}

class _DriverMainScaffoldState extends State<DriverMainScaffold> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  YandexMapController? _mapController;
  List<MapObject> _cachedMapObjects = [];
  PolylineMapObject? _activeRoutePolyline;

  Timer? _gpsTimer;
  Timer? _taxometerTimer;

  double _liveDrivenKm = 0.0;
  int _tripElapsedSeconds = 0;
  int _freeWaitSecondsLeft = 180;
  int _paidWaitSeconds = 0;
  bool _isPausedForWaiting = false;
  Point? _lastTrackPoint;
  String? _lastRoutedOrderId;
  String? _lastRoutedStatus;

  Uint8List? _carIconBytes;
  Uint8List? _pinABytes;
  Uint8List? _pinBBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDriverMapAndGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsTimer?.cancel();
    _taxometerTimer?.cancel();
    driverState.stopOrderRingtone();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      driverState.syncFromFirebase();
    }
  }

  Future<void> _ensureMarkerIcons() async {
    _carIconBytes ??= await _drawTopDownTaxiIcon();
    _pinABytes ??= await _drawPinIcon(kPrimaryGreen, "A");
    _pinBBytes ??= await _drawPinIcon(Colors.redAccent, "B");
  }

  Future<Uint8List> _drawPinIcon(Color color, String label) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 32), 28, paint);
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(32, 32), 19, paint);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(32 - tp.width / 2, 32 - tp.height / 2));

    final img = await recorder.endRecording().toImage(64, 64);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<Uint8List> _drawTopDownTaxiIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final halo = Paint()
      ..color = kPrimaryGreen.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(48, 48), 42, halo);

    final body = Paint()
      ..color = kAccentYellow
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(28, 12, 40, 70), const Radius.circular(14)),
      body,
    );

    final glass = Paint()..color = const Color(0xFF1E222D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(32, 24, 32, 44), const Radius.circular(8)),
      glass,
    );

    final roof = Paint()..color = kPrimaryGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(35, 35, 26, 22), const Radius.circular(6)),
      roof,
    );

    final img = await recorder.endRecording().toImage(96, 96);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<void> _initDriverMapAndGps() async {
    await _ensureMarkerIcons();
    await _locateDriverGps(moveCamera: true);

    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 4), (_) => _locateDriverGps(moveCamera: false));

    _taxometerTimer?.cancel();
    _taxometerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTaxometerTick());
  }

  Future<void> _locateDriverGps({required bool moveCamera}) async {
    await _ensureMarkerIcons();
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        final newPt = Point(latitude: pos.latitude, longitude: pos.longitude);
        final ord = driverState.activeDriverOrder;

        if (ord != null && ord.status == 'Safarda' && !_isPausedForWaiting) {
          if (_lastTrackPoint != null) {
            final distMeters = Geolocator.distanceBetween(
              _lastTrackPoint!.latitude,
              _lastTrackPoint!.longitude,
              newPt.latitude,
              newPt.longitude,
            );
            if (distMeters >= 4.0 && distMeters <= 350.0) {
              _liveDrivenKm += (distMeters / 1000.0);
              ord.distanceKm = double.parse(_liveDrivenKm.toStringAsFixed(2));
              _recalculateLiveTaxometerPrice(ord);
            }
          }
        }

        _lastTrackPoint = newPt;
        driverState.currentGps = newPt;
        driverState.syncDriverToFirebase();

        if (ord != null) {
          ord.driverLat = newPt.latitude;
          ord.driverLon = newPt.longitude;
          driverState.pushOrderToFirebase(ord);
        }

        if (moveCamera && _mapController != null) {
          _mapController!.moveCamera(
            CameraUpdate.newCameraPosition(CameraPosition(target: newPt, zoom: 16.4)),
            animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
          );
        }
      }
    } catch (_) {}
    _rebuildMapMarkers();
  }

  void _onTaxometerTick() {
    final ord = driverState.activeDriverOrder;
    if (ord == null) {
      _tripElapsedSeconds = 0;
      _freeWaitSecondsLeft = 180;
      _paidWaitSeconds = 0;
      _isPausedForWaiting = false;
      return;
    }

    if (ord.status == 'Yetib keldi') {
      setState(() {
        if (_freeWaitSecondsLeft > 0) {
          _freeWaitSecondsLeft--;
        } else {
          _paidWaitSeconds++;
          ord.waitSeconds = _paidWaitSeconds;
          ord.waitFee = ((_paidWaitSeconds / 60).ceil()) * driverState.waitPerMin;
        }
      });
    } else if (ord.status == 'Safarda') {
      setState(() {
        if (_isPausedForWaiting) {
          _paidWaitSeconds++;
          ord.waitSeconds = _paidWaitSeconds;
          ord.waitFee = ((_paidWaitSeconds / 60).ceil()) * driverState.waitPerMin;
        } else {
          _tripElapsedSeconds++;
        }
      });
    }
  }

  void _recalculateLiveTaxometerPrice(OrderModel ord) {
    final int base = driverState.getTariffBase(ord.tariff);
    final int perKm = driverState.getTariffPerKm(ord.tariff);
    final int calc = ((base + (ord.distanceKm * perKm)) * driverState.surgeMultiplier / 100).round() * 100;
    ord.price = max(base, calc);
  }

  Future<void> _buildNavigationRouteForOrder(OrderModel ord) async {
    if (_lastRoutedOrderId == ord.id && _lastRoutedStatus == ord.status) return;
    _lastRoutedOrderId = ord.id;
    _lastRoutedStatus = ord.status;

    final Point startPt = ord.status == 'Qabul qilindi' ? driverState.currentGps : ord.fromPoint;
    final Point endPt = ord.status == 'Qabul qilindi' ? ord.fromPoint : ord.toPoint;

    if (ord.status != 'Qabul qilindi' && ord.isOpenDestination) {
      setState(() => _activeRoutePolyline = null);
      _rebuildMapMarkers();
      return;
    }

    try {
      final resWithSession = YandexDriving.requestRoutes(
        points: [
          RequestPoint(point: startPt, requestPointType: RequestPointType.wayPoint),
          RequestPoint(point: endPt, requestPointType: RequestPointType.wayPoint),
        ],
        drivingOptions: const DrivingOptions(initialAzimuth: 0, routesCount: 1, avoidTolls: true),
      );
      final res = await resWithSession.result.timeout(const Duration(seconds: 3));
      try {
        await resWithSession.session.close();
      } catch (_) {}

      if (res.routes != null && res.routes!.isNotEmpty) {
        _activeRoutePolyline = PolylineMapObject(
          mapId: const MapObjectId('driver_nav_route'),
          polyline: Polyline(points: res.routes!.first.geometry),
          strokeColor: ord.status == 'Qabul qilindi' ? kAccentYellow : kPrimaryGreen,
          strokeWidth: 5.5,
          outlineColor: Colors.black87,
          outlineWidth: 1.2,
        );
      } else {
        _activeRoutePolyline = PolylineMapObject(
          mapId: const MapObjectId('driver_nav_route'),
          polyline: Polyline(points: [startPt, endPt]),
          strokeColor: kPrimaryGreen,
          strokeWidth: 4.5,
        );
      }
    } catch (_) {
      _activeRoutePolyline = PolylineMapObject(
        mapId: const MapObjectId('driver_nav_route'),
        polyline: Polyline(points: [startPt, endPt]),
        strokeColor: kPrimaryGreen,
        strokeWidth: 4.5,
      );
    }
    _rebuildMapMarkers();
  }

  void _rebuildMapMarkers() {
    final List<MapObject> objs = [];
    final ord = driverState.activeDriverOrder;

    if (ord != null && _activeRoutePolyline != null) {
      objs.add(_activeRoutePolyline!);
    }

    if (_carIconBytes != null) {
      objs.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('driver_self_car'),
          point: driverState.currentGps,
          opacity: 1.0,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_carIconBytes!), scale: 1.05),
          ),
        ),
      );
    }

    if (ord != null) {
      if (_pinABytes != null) {
        objs.add(
          PlacemarkMapObject(
            mapId: const MapObjectId('order_pin_a'),
            point: ord.fromPoint,
            opacity: 1.0,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_pinABytes!), scale: 1.0),
            ),
          ),
        );
      }
      if (!ord.isOpenDestination && _pinBBytes != null) {
        objs.add(
          PlacemarkMapObject(
            mapId: const MapObjectId('order_pin_b'),
            point: ord.toPoint,
            opacity: 1.0,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(_pinBBytes!), scale: 1.0),
            ),
          ),
        );
      }
    }

    _cachedMapObjects = objs;
    if (mounted) setState(() {});
  }

  String _formatTimer(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  double _calcDistanceKm(Point p1, Point p2) {
    final meters = Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
    return double.parse((meters / 1000.0).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: driverState,
      builder: (context, _) {
        final bool dark = driverState.isDarkMode;
        final OrderModel? activeOrd = driverState.activeDriverOrder;
        final List<OrderModel> waitingList = driverState.availableWaitingOrders;

        if (activeOrd != null) {
          _buildNavigationRouteForOrder(activeOrd);
        } else {
          _activeRoutePolyline = null;
          _lastRoutedOrderId = null;
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDriverDrawer(dark),
          body: Stack(
            children: [
              RepaintBoundary(
                child: YandexMap(
                  nightModeEnabled: dark,
                  fastTapEnabled: true,
                  mapObjects: _cachedMapObjects,
                  onMapCreated: (ctrl) async {
                    _mapController = ctrl;
                    await _locateDriverGps(moveCamera: true);
                  },
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "drv_menu",
                      backgroundColor: dark ? kDarkCard : Colors.white,
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(Icons.menu, color: kPrimaryGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => driverState.toggleOnlineStatus(!driverState.isOnline),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: driverState.isOnline ? kPrimaryGreen : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                driverState.isOnline ? Icons.sensors : Icons.power_settings_new,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  driverState.isOnline ? DriverStrings.tr("online") : DriverStrings.tr("offline"),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openTopUpBalanceSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: (dark ? kDarkCard : Colors.white).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: driverState.hasEnoughBalance ? kPrimaryGreen : Colors.redAccent,
                            width: 1.5,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: driverState.hasEnoughBalance ? kAccentYellow : Colors.redAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${driverState.balance}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: driverState.hasEnoughBalance ? (dark ? Colors.white : Colors.black) : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!driverState.hasEnoughBalance)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 64,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade700,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DriverStrings.tr("low_balance_warn"),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                          onPressed: _openTopUpBalanceSheet,
                          child: const Text("+ To'ldirish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                right: 14,
                bottom: activeOrd != null ? 320 : 250,
                child: FloatingActionButton.small(
                  heroTag: "drv_gps_center",
                  backgroundColor: dark ? kDarkCard : Colors.white,
                  onPressed: () => _locateDriverGps(moveCamera: true),
                  child: const Icon(Icons.my_location, color: kPrimaryGreen),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  decoration: BoxDecoration(
                    color: dark ? kDarkBg : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                  ),
                  child: activeOrd != null
                      ? _buildActiveTaxometerPanel(activeOrd, dark)
                      : (waitingList.isNotEmpty
                          ? _buildIncomingOrderRadarCard(waitingList.first, waitingList.length, dark)
                          : _buildIdleRadarBox(dark)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriverDrawer(bool dark) {
    final textColor = dark ? Colors.white : Colors.black87;
    return Drawer(
      backgroundColor: dark ? kDarkBg : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: dark ? kDarkCard : kPrimaryGreen.withOpacity(0.12)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: kAccentYellow,
                    child: Icon(Icons.local_taxi, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverState.driverName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
                        Text(driverState.fullCarTitle, style: const TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("ID: ${driverState.driverId} • ${driverState.tariffType}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: kPrimaryGreen),
              title: Text("${DriverStrings.tr("balance")}: ${driverState.balance} ${driverState.currencyLabel}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Komissiya: ${driverState.commissionPercent}%"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _openTopUpBalanceSheet();
                },
                child: const Text("+ Hisob"),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: kAccentYellow),
                    title: Text(DriverStrings.tr("earnings")),
                    subtitle: Text("${driverState.completedTripsCount} ta safar • ${driverState.totalEarnedSum} ${driverState.currencyLabel}"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_offer_outlined, color: kPrimaryGreen),
                    title: Text(DriverStrings.tr("tariffs_info")),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTariffsInfoScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.volume_up, color: Colors.orangeAccent),
                    title: const Text("Zakaz ringtonini tekshirish"),
                    subtitle: const Text("Mashhur taksi zakaz signalini eshitib ko'rish"),
                    onTap: () {
                      driverState.playOrderRingtone();
                      Future.delayed(const Duration(seconds: 3), () => driverState.stopOrderRingtone());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: Colors.grey),
                    title: Text(DriverStrings.tr("settings")),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSettingsScreen()));
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(DriverStrings.tr("logout"), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      driverState.stopOrderRingtone();
                      driverState.isAuthenticated = false;
                      driverState.saveToStorage();
                      driverState.notifyListeners();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleRadarBox(bool dark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: driverState.isOnline ? kPrimaryGreen.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                driverState.isOnline ? Icons.radar : Icons.pause_circle_outline,
                color: driverState.isOnline ? kPrimaryGreen : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverState.isOnline
                        ? "Zakaz Radari faol — buyurtmalar kutilmoqda..."
                        : "Siz hozir Band (Offline) rejimidasiz",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    driverState.isOnline
                        ? "Yangi zakaz tushishi bilan taksi ringtoni jiringlaydi"
                        : "Buyurtma qabul qilish uchun 'Liniyada' tugmasini yoqing",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: dark ? kDarkCard : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bajarilgan safarlar: ${driverState.completedTripsCount} ta", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(
                "Daromad: ${driverState.totalEarnedSum} ${driverState.currencyLabel}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingOrderRadarCard(OrderModel ord, int totalWaitingCount, bool dark) {
    final double pickupDistKm = _calcDistanceKm(driverState.currentGps, ord.fromPoint);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    "${DriverStrings.tr("new_order_alert")} ($totalWaitingCount)",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: kAccentYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(
                "${ord.tariff} • ${ord.paymentMethod}",
                style: const TextStyle(color: kAccentYellow, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const Spacer(),
            Text(
              "${ord.price} ${driverState.currencyLabel}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kPrimaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? kDarkCard : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPrimaryGreen.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 11, backgroundColor: kPrimaryGreen, child: Text("A", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ord.fromAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Text("$pickupDistKm km sizdan", style: const TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
              if (ord.landmarkNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kAccentYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "📍 Mo'ljal: ${ord.landmarkNote}",
                    style: const TextStyle(color: kAccentYellow, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
              const Divider(height: 14),
              Row(
                children: [
                  const CircleAvatar(radius: 11, backgroundColor: Colors.redAccent, child: Text("B", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ord.isOpenDestination ? DriverStrings.tr("open_dest_badge") : ord.toAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ord.isOpenDestination ? Colors.orangeAccent : null,
                      ),
                    ),
                  ),
                  if (!ord.isOpenDestination)
                    Text("${ord.distanceKm} km", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (ord.wishes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "Istaklar: ${ord.wishes.join(', ')}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => driverState.skipOrder(ord.id),
                  child: Text(DriverStrings.tr("skip_btn")),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    _liveDrivenKm = ord.isOpenDestination ? 0.2 : ord.distanceKm;
                    _tripElapsedSeconds = 0;
                    _freeWaitSecondsLeft = 180;
                    _paidWaitSeconds = 0;
                    _isPausedForWaiting = false;
                    await driverState.acceptOrder(ord);
                    _rebuildMapMarkers();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    DriverStrings.tr("accept_btn"),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveTaxometerPanel(OrderModel ord, bool dark) {
    final String st = ord.status;
    final int currentTotal = ord.price + ord.waitFee;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kPrimaryGreen.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
              child: Text(
                "${st.toUpperCase()} • ${ord.tariff}",
                style: const TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            Text("• ${ord.paymentMethod}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Text(
              "$currentTotal ${driverState.currencyLabel}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: kPrimaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person, color: kAccentYellow, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "${ord.clientName} (${ord.clientPhone})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (st != 'Safarda')
              TextButton.icon(
                onPressed: () => driverState.transferOrderToOtherDrivers(ord),
                icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.orangeAccent),
                label: const Text("O'tkazish", style: TextStyle(fontSize: 11, color: Colors.orangeAccent)),
              ),
          ],
        ),
        Text("A: ${ord.fromAddress}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        Text(
          "B: ${ord.isOpenDestination ? DriverStrings.tr("open_dest_badge") : ord.toAddress}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: ord.isOpenDestination ? kAccentYellow : Colors.grey),
        ),
        if (ord.landmarkNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "📍 Mo'ljal: ${ord.landmarkNote}",
              style: const TextStyle(fontSize: 12, color: kAccentYellow, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 10),

        if (st == 'Yetib keldi')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _freeWaitSecondsLeft > 0 ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _freeWaitSecondsLeft > 0 ? DriverStrings.tr("wait_free") : DriverStrings.tr("wait_paid"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  _freeWaitSecondsLeft > 0
                      ? _formatTimer(_freeWaitSecondsLeft)
                      : "${_formatTimer(_paidWaitSeconds)} (+${ord.waitFee} ${driverState.currencyLabel})",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _freeWaitSecondsLeft > 0 ? Colors.lightBlueAccent : kAccentYellow,
                  ),
                ),
              ],
            ),
          ),

        if (st == 'Safarda')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: dark ? kDarkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryGreen.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Masofa (GPS)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Row(
                      children: [
                        Text("${ord.distanceKm} km", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _liveDrivenKm += 0.5;
                              ord.distanceKm = double.parse(_liveDrivenKm.toStringAsFixed(1));
                              _recalculateLiveTaxometerPrice(ord);
                            });
                            driverState.pushOrderToFirebase(ord);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: kPrimaryGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: const Text("+0.5 km", style: TextStyle(fontSize: 10, color: kPrimaryGreen, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Safar vaqti", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(_formatTimer(_tripElapsedSeconds), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Kutish", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      "+${ord.waitFee} ${driverState.currencyLabel}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kAccentYellow),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => driverState.dialPhoneNumber(ord.clientPhone),
                icon: const Icon(Icons.phone, size: 17),
                label: Text(DriverStrings.tr("call_client"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccentYellow,
                  side: const BorderSide(color: kAccentYellow),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openDriverChatSheet(ord),
                icon: const Icon(Icons.chat_bubble_outline, size: 17),
                label: Text(
                  ord.messages.isEmpty ? DriverStrings.tr("chat_client") : "Chat (${ord.messages.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (st == 'Qabul qilindi')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _freeWaitSecondsLeft = 180;
                _paidWaitSeconds = 0;
                driverState.markArrivedAtClient(ord);
              },
              icon: const Icon(Icons.location_on),
              label: Text(DriverStrings.tr("arrived_btn"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          )
        else if (st == 'Yetib keldi')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _tripElapsedSeconds = 0;
                _liveDrivenKm = ord.isOpenDestination ? 0.2 : ord.distanceKm;
                if (ord.isOpenDestination) {
                  _recalculateLiveTaxometerPrice(ord);
                }
                driverState.startRideTaxometer(ord);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: Text(DriverStrings.tr("start_trip_btn"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          )
        else if (st == 'Safarda')
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isPausedForWaiting ? Colors.greenAccent : kAccentYellow,
                    side: BorderSide(color: _isPausedForWaiting ? Colors.greenAccent : kAccentYellow),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => setState(() => _isPausedForWaiting = !_isPausedForWaiting),
                  icon: Icon(_isPausedForWaiting ? Icons.play_circle_outline : Icons.pause_circle_outline, size: 18),
                  label: Text(
                    _isPausedForWaiting ? DriverStrings.tr("resume_drive") : DriverStrings.tr("pause_wait"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _finishRideAndShowReceipt(ord),
                  icon: const Icon(Icons.flag_circle, size: 24),
                  label: Text(
                    "${DriverStrings.tr("finish_trip_btn")} • $currentTotal ${driverState.currencyLabel}",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _finishRideAndShowReceipt(OrderModel ord) async {
    final res = await driverState.completeTripAndDeductCommission(
      ord,
      finalKm: ord.distanceKm,
      finalPrice: ord.price,
      finalWaitFee: ord.waitFee,
      waitSec: _paidWaitSeconds,
    );
    _rebuildMapMarkers();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: kPrimaryGreen, size: 30),
            SizedBox(width: 8),
            Expanded(child: Text("Safar cheki", style: TextStyle(fontWeight: FontWeight.w900))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _receiptRow("Masofa:", "${ord.distanceKm} km"),
            _receiptRow("Yo'l haqi:", "${res['basePrice']} ${driverState.currencyLabel}"),
            _receiptRow("Pullik kutish:", "${res['waitFee']} ${driverState.currencyLabel}"),
            const Divider(),
            _receiptRow("MIJOZDAN OLINADI:", "${res['total']} ${driverState.currencyLabel}", bold: true, color: kPrimaryGreen),
            const Divider(),
            _receiptRow("Taksopark komissiyasi (${driverState.commissionPercent}%):", "-${res['commission']} ${driverState.currencyLabel}", color: Colors.orangeAccent),
            _receiptRow("Qolgan balansingiz:", "${res['newBalance']} ${driverState.currencyLabel}", bold: true),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("TUSHUNARLI (YANGI ZAKAZ KUTISH)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String val, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            val,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: bold ? 16 : 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _openDriverChatSheet(OrderModel ord) {
    final TextEditingController chatCtrl = TextEditingController();
    final quickDriverMsgs = [
      "Yetib keldim, chiqavering",
      "Ko'k darvoza oldida turibman",
      "Yo'ldaman, 2 daqiqada boraman",
      "Qayerda kutay?",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => AnimatedBuilder(
        animation: driverState,
        builder: (context, _) {
          final liveOrd = driverState.orders.firstWhere((o) => o.id == ord.id, orElse: () => ord);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              left: 16,
              right: 16,
              top: 14,
            ),
            child: SizedBox(
              height: 410,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Mijoz bilan chat (${liveOrd.clientName})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickDriverMsgs
                          .map(
                            (q) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(q, style: const TextStyle(fontSize: 12)),
                                onPressed: () => driverState.sendDriverChatMessage(liveOrd.id, q),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: liveOrd.messages.isEmpty
                        ? const Center(child: Text("Mijozga tezkor xabar yuboring...", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: liveOrd.messages.length,
                            itemBuilder: (context, i) {
                              final m = liveOrd.messages[i];
                              final isMe = m.sender == 'driver';
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? kPrimaryGreen : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      Text(m.time, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatCtrl,
                          decoration: InputDecoration(
                            hintText: "Mijozga xabar yozing...",
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                        onPressed: () {
                          if (chatCtrl.text.trim().isNotEmpty) {
                            driverState.sendDriverChatMessage(liveOrd.id, chatCtrl.text);
                            chatCtrl.clear();
                          }
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openTopUpBalanceSheet() {
    final amountCtrl = TextEditingController(text: "50000");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 18,
          right: 18,
          top: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DriverStrings.tr("topup"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              "To'ldirmoqchi bo'lgan summangizni kiriting. So'rov darhol Super-Admin va Dispetcher ekraniga tushadi.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Summa (${driverState.currencyLabel})",
                prefixIcon: const Icon(Icons.payments_outlined, color: kPrimaryGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
                onPressed: () {
                  final amt = int.tryParse(amountCtrl.text.trim()) ?? 50000;
                  driverState.sendTopUpRequestToAdmin(amt);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$amt ${driverState.currencyLabel} to'ldirish so'rovi Admin paneliga yuborildi!"),
                      backgroundColor: kPrimaryGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text("SO'ROV YUBORISH", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: driverState,
      builder: (context, _) {
        final myDoneOrders = driverState.orders
            .where((o) => o.driverId == driverState.driverId && o.status == 'Yakunlandi')
            .toList();
        return Scaffold(
          appBar: AppBar(title: Text(DriverStrings.tr("earnings"))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Joriy Balans: ${driverState.balance} ${driverState.currencyLabel}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryGreen)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            const Text("Safarlar", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text("${driverState.completedTripsCount} ta", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ]),
                          Column(children: [
                            const Text("Jami tushum", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text("${driverState.totalEarnedSum} ${driverState.currencyLabel}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ]),
                          Column(children: [
                            const Text("Komissiya", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text("-${driverState.totalCommissionPaid}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.orangeAccent)),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text("Bajarilgan buyurtmalar tarixi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (myDoneOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text("Hozircha yakunlangan buyurtmalar yo'q", style: TextStyle(color: Colors.grey))),
                )
              else
                ...myDoneOrders.map(
                  (o) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: kPrimaryGreen, child: Icon(Icons.check, color: Colors.white)),
                      title: Text("${o.fromAddress} ➔ ${o.toAddress}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("${o.tariff} • ${o.distanceKm} km • ${o.paymentMethod}"),
                      trailing: Text(
                        "${o.price + o.waitFee} ${driverState.currencyLabel}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DriverTariffsInfoScreen extends StatelessWidget {
  const DriverTariffsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DriverStrings.tr("tariffs_info"))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tariffTile("Standart", driverState.stdBase, driverState.stdPerKm),
          _tariffTile("Komfort", driverState.comfBase, driverState.comfPerKm),
          _tariffTile("Pochta / Bozorlik", driverState.delivBase, driverState.delivPerKm),
          _tariffTile("Damas / Yuk", driverState.damasBase, driverState.damasPerKm),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: kAccentYellow),
            title: const Text("Pullik kutish (3 daqiqadan so'ng)"),
            trailing: Text("${driverState.waitPerMin} ${driverState.currencyLabel} / daq", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.percent, color: kPrimaryGreen),
            title: const Text("Taksopark komissiyasi"),
            trailing: Text("${driverState.commissionPercent}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _tariffTile(String title, int base, int perKm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.local_taxi, color: kPrimaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Minish: $base ${driverState.currencyLabel}"),
        trailing: Text("1 km: $perKm ${driverState.currencyLabel}", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen)),
      ),
    );
  }
}

class DriverSettingsScreen extends StatelessWidget {
  const DriverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: driverState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(DriverStrings.tr("settings"))),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: kPrimaryGreen),
                title: const Text("Ilova va Xarita tili"),
                subtitle: Text("${driverState.currentLanguage} (${driverState.addressLanguage})"),
                onTap: () {
                  driverState.currentLanguage = driverState.currentLanguage == "O'zbek" ? "Русский" : "O'zbek";
                  driverState.applyMapLocale(driverState.currentLanguage == "Русский" ? "RU" : "UZ");
                },
              ),
              SwitchListTile(
                activeColor: kPrimaryGreen,
                title: const Text("Tungi rejim (Dark Mode)"),
                value: driverState.isDarkMode,
                onChanged: (v) {
                  driverState.isDarkMode = v;
                  driverState.saveToStorage();
                  driverState.notifyListeners();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
