import 'package:flutter/material.dart';
import 'package:sweetmanager/Commerce/views/payment.dart';
import 'package:sweetmanager/Commerce/widgets/plan_card.dart';
import 'package:sweetmanager/shared/widgets/base_layout.dart';

class SubscriptionPlans  extends StatelessWidget {
  const SubscriptionPlans({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(role: '', childScreen: getContentView(context));
  }

  Widget getContentView(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PlanCard(
              icon: Icons.bed_outlined,
              title: 'BÁSICO',
              price: '\$29.99 al mes',
              features: const [
                'Access to room management with IoT technology',
                'Collaborative administration for up to two people',
              ],
              behavior: () => {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentCheckoutScreen(cardIdentifier: 1)))
              },
            ),
            const SizedBox(height: 16),
            PlanCard(
              icon: Icons.apartment_outlined,
              title: 'REGULAR',
              price: '\$58.99 al mes',
              features: const [
                'Access to room management with IoT technology',
                'Collaborative administration for up to two people',
                'Access to interactive business management dashboards',
              ],
              behavior: () => {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentCheckoutScreen(cardIdentifier: 2)))
              },
            ),
            const SizedBox(height: 16),
            PlanCard(
              icon: Icons.business_outlined,
              title: 'PREMIUM',
              price: '\$110.69 al mes',
              features: const [
                'Access to room management with IoT technology',
                'Collaborative administration for up to two people',
                'Access to interactive business management dashboards',
                '24/7 support and maintenance',
              ],
              behavior: () => {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentCheckoutScreen(cardIdentifier: 3)))
              },
            ),
          ],
        ),
      ),
    );
  }
}