/// Store-independent entitlement and purchase interfaces.
library;

enum EntitlementState { free, pro }

enum PurchaseResult { purchased, cancelled, pending, unavailable, failed }

abstract interface class PurchaseGateway {
  Stream<EntitlementState> get entitlementChanges;
  Future<EntitlementState> currentEntitlement();
  Future<PurchaseResult> purchaseProLifetime();
  Future<EntitlementState> restorePurchases();
}

class FakePurchaseGateway implements PurchaseGateway {
  const FakePurchaseGateway();

  @override
  Stream<EntitlementState> get entitlementChanges =>
      const Stream<EntitlementState>.empty();

  @override
  Future<EntitlementState> currentEntitlement() async => EntitlementState.free;

  @override
  Future<PurchaseResult> purchaseProLifetime() async =>
      PurchaseResult.unavailable;

  @override
  Future<EntitlementState> restorePurchases() async => EntitlementState.free;
}

class FeatureAccessPolicy {
  const FeatureAccessPolicy(this.entitlement);

  final EntitlementState entitlement;

  bool get canAccessPro => entitlement == EntitlementState.pro;
}
