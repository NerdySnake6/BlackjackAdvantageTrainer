import 'package:blackjack_advantage_trainer/domain/purchase/purchase_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakePurchaseGateway', () {
    test('returns expected defaults and empty stream', () async {
      const gateway = FakePurchaseGateway();

      expect(await gateway.currentEntitlement(), EntitlementState.free);
      expect(await gateway.purchaseProLifetime(), PurchaseResult.unavailable);
      expect(await gateway.restorePurchases(), EntitlementState.free);
      expect(await gateway.entitlementChanges.isEmpty, isTrue);
    });
  });

  group('FeatureAccessPolicy', () {
    test('controls access based on entitlement', () {
      const freePolicy = FeatureAccessPolicy(EntitlementState.free);
      expect(freePolicy.canAccessPro, isFalse);

      const proPolicy = FeatureAccessPolicy(EntitlementState.pro);
      expect(proPolicy.canAccessPro, isTrue);
    });
  });
}
