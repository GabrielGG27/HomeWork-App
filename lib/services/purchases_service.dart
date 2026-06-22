import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchasesService extends ChangeNotifier {
  static const String _premiumPrefKey = 'is_premium';

  // ⚠️ El único ID real que exige la documentación oficial
  static const String removeAdsProductId = 'remove_ads';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

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
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumPrefKey) ?? false;
    notifyListeners();

    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint('[IAP] Error en el stream de compras: $error');
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    debugPrint('[IAP] Tienda disponible: $_isAvailable');

    if (!_isAvailable) {
      debugPrint('[IAP] La tienda no está disponible en este dispositivo.');
      notifyListeners();
      return;
    }

    // Consulta limpia apuntando directo al ID raíz
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails({removeAdsProductId});

    if (response.error != null) {
      debugPrint('[IAP] Error al consultar productos: ${response.error}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        '[IAP] ⚠️ ID NO encontrado en la tienda: ${response.notFoundIDs}',
      );
    }

    if (response.productDetails.isNotEmpty) {
      debugPrint(
        '[IAP] ✅ Producto válido listo: ${response.productDetails.map((p) => p.id).toList()}',
      );
    }

    _products = response.productDetails;
    notifyListeners();
  }

  /// Inicia la compra del producto "quitar anuncios".
  bool buyRemoveAds() {
    if (!_isAvailable) {
      debugPrint('[IAP] No se puede comprar: tienda no disponible.');
      return false;
    }

    if (_products.isEmpty) {
      debugPrint(
        '[IAP] No se puede comprar: la lista de productos está vacía.',
      );
      return false;
    }

    // Buscamos el producto exacto de forma segura
    ProductDetails? product;
    for (var p in _products) {
      if (p.id == removeAdsProductId) {
        product = p;
        break;
      }
    }

    product ??= _products.first;

    debugPrint('[IAP] Iniciando compra de: ${product.id} (${product.price})');
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    return true;
  }

  Future<void> restorePurchases() async {
    debugPrint('[IAP] Restaurando compras...');
    await _inAppPurchase.restorePurchases();
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
              '[IAP] ✅ Compra válida para: ${purchaseDetails.productID}',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumPrefKey, true);
    debugPrint('[IAP] 🎉 Usuario ahora es Premium. Anuncios eliminados.');
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
