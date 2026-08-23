import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchasesService extends ChangeNotifier {
  static const String _premiumPrefKey = 'is_premium';

  // ID exacto del producto en Play Console.
  static const String removeAdsProductId = 'remove_ads';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isPurchasePending = false;
  bool get isPurchasePending => _isPurchasePending;

  String? _purchaseError;
  String? get purchaseError => _purchaseError;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  PurchasesService() {
    _init();
  }

  Future<void> _init() async {
    // 1. Cargar estado guardado localmente (para evitar parpadeos de anuncios al iniciar)
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumPrefKey) ?? false;
    notifyListeners();

    // 2. Iniciar sesión de forma anónima
    _auth.userChanges().listen((User? user) {
      if (user == null) {
        _signInAnonymously();
      } else {
        _listenToUserDoc(user.uid);
      }
    });

    // 3. Escuchar el stream de compras
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) {
        debugPrint('[IAP] Error en el stream de compras: $error');
      },
    );

    // 4. Verificar disponibilidad de la tienda y cargar productos
    await _loadProducts();
  }

  Future<void> _signInAnonymously() async {
    try {
      debugPrint('[Firebase Auth] Iniciando sesión de forma anónima...');
      await _auth.signInAnonymously();
      debugPrint('[Firebase Auth] Sesión iniciada con éxito.');
    } catch (e) {
      debugPrint('[Firebase Auth] Error al iniciar sesión anónima: $e');
    }
  }

  void _listenToUserDoc(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data() as Map<String, dynamic>;
              final firestorePremium = data['isPremium'] == true;

              if (_isPremium != firestorePremium) {
                _isPremium = firestorePremium;
                // Sincronizar también con SharedPreferences para caché offline
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_premiumPrefKey, firestorePremium);
                notifyListeners();
                debugPrint(
                  '[Firestore] Estado premium actualizado desde base de datos: $_isPremium',
                );
              }
            }
          },
          onError: (e) {
            debugPrint(
              '[Firestore] Error al escuchar documento de usuario: $e',
            );
          },
        );
  }

  Future<void> _loadProducts() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    debugPrint('[IAP] Tienda disponible: $_isAvailable');

    if (!_isAvailable) {
      debugPrint('[IAP] La tienda no está disponible en este dispositivo.');
      notifyListeners();
      return;
    }

    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails({removeAdsProductId});

    if (response.error != null) {
      debugPrint('[IAP] Error al consultar productos: ${response.error}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        '[IAP] ⚠️ Productos NO encontrados: ${response.notFoundIDs}. '
        'Verifica que el ID "$removeAdsProductId" exista en Google Play Console y esté ACTIVO.',
      );
    }

    _products = response.productDetails;
    notifyListeners();
  }

  Future<bool> buyRemoveAds() async {
    if (!_isAvailable) {
      debugPrint('[IAP] No se puede comprar: tienda no disponible.');
      return false;
    }
    if (_products.isEmpty) {
      debugPrint('[IAP] No se puede comprar: ningún producto cargado.');
      return false;
    }

    // 🟢 Control Seguro: Recuperamos tu bucle manual para evitar el crash de tipos
    ProductDetails? product;
    for (var p in _products) {
      if (p.id == removeAdsProductId) {
        product = p;
        break;
      }
    }
    product ??= _products.first;

    try {
      // ⚡ Activamos el spinner en el UI de inmediato antes de llamar a Google Play
      _isPurchasePending = true;
      _purchaseError = null;
      notifyListeners();

      debugPrint('[IAP] Iniciando compra de: ${product.id} (${product.price})');
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Lanzamos de forma asíncrona la hoja de pago de Google Play
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      // Si el sistema falla al abrir la tienda, apagamos el spinner para no bloquear la pantalla
      _isPurchasePending = false;
      _purchaseError = e.toString();
      notifyListeners();
      debugPrint('[IAP] Error inmediato al lanzar la compra: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('[IAP] Restaurando compras...');
    try {
      _isPurchasePending = true;
      _purchaseError = null;
      notifyListeners();
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _purchaseError = e.toString();
      debugPrint('[IAP] Error al restaurar compras: $e');
    } finally {
      // Google Play may emit no purchase updates when there is nothing to
      // restore. Always release the progress state when the restore request
      // itself has finished; later stream events can still deliver a product.
      _isPurchasePending = false;
      notifyListeners();
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint(
        '[IAP] Estado de compra: ${purchaseDetails.status} para ${purchaseDetails.productID}',
      );

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isPurchasePending = true;
        notifyListeners();
      } else {
        // En cualquier otro estado final (éxito, error o cancelación), liberamos el indicador de carga
        _isPurchasePending = false;

        if (purchaseDetails.status == PurchaseStatus.error) {
          _purchaseError =
              purchaseDetails.error?.message ?? 'Error desconocido';
          debugPrint('[IAP] Error en la compra: $_purchaseError');
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.productID == removeAdsProductId) {
            debugPrint(
              '[IAP] ✅ Compra válida detectada para: ${purchaseDetails.productID}',
            );
            _deliverProduct();
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _deliverProduct() async {
    _isPremium = true;
    _purchaseError = null;
    notifyListeners();

    // 1. Guardar en caché local para arranque instantáneo sin internet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumPrefKey, true);

    // 2. Sincronizar de forma segura en la nube con Firebase Firestore
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'isPremium': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint(
          '[Firestore] ✅ Estado Premium respaldado en la base de datos para el usuario ${user.uid}.',
        );
      } else {
        debugPrint(
          '[Firestore] ⚠️ No se respaldó en la nube porque no hay sesión Auth activa.',
        );
      }
    } catch (e) {
      debugPrint('[Firestore] Error al escribir en la base de datos: $e');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
