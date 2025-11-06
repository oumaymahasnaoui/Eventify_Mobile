import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  // ✅ Clé publique seulement (tu peux la laisser ici)
  static const String publishableKey =
      'pk_test_51RDW4eHBxLxJpje2MbGXEXSAWDqz76hRsMghKYPYQDB6xn02rX67jtW4g6C2aaRlSy7lw4lfhcNoCrSmMwlarwU100jGpN7TVy';

  // ❌ Supprimer la clé secrète ici — elle sera utilisée côté serveur uniquement

  // ⚙️ Initialisation Stripe
  static Future<void> init() async {
    try {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      developer.log('✅ Stripe initialisé avec succès');
    } catch (e) {
      developer.log('❌ Erreur initialisation Stripe: $e');
      rethrow;
    }
  }

  // 💳 Création du PaymentIntent via ton backend sécurisé
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    try {
      final int amountInCents = (amount * 100).toInt();
      developer.log('💳 Demande de PaymentIntent: $amountInCents centimes');

      // 👉 Remplace cette URL par celle de ton backend (Node.js, Spring Boot, etc.)
      final url = Uri.parse('https://ton-backend.com/api/create-payment-intent');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amountInCents,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✅ PaymentIntent créé côté serveur: ${data['id']}');
        return data;
      } else {
        developer.log('❌ Erreur backend: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('❌ Exception: $e');
      return null;
    }
  }

  // 💰 Effectuer un paiement
  Future<bool> makePayment({
    required BuildContext context,
    required double amount,
    required String currency,
    String? customerEmail,
  }) async {
    try {
      developer.log('💰 Tentative de paiement: $amount€');

      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      if (paymentIntent == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur de connexion au serveur de paiement.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      // 1️⃣ Initialiser la feuille de paiement
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Eventify',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFCE1126),
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFFCE1126),
                  text: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      developer.log('✅ Paiement réussi !');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement effectué avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } on StripeException catch (e) {
      developer.log('❌ Erreur Stripe: ${e.error.message}');
      if (e.error.code == FailureCode.Canceled) {
        developer.log('ℹ️ Paiement annulé');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement annulé'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.error.localizedMessage ?? e.error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      developer.log('❌ Erreur inattendue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  bool isConfigured() {
    return publishableKey.isNotEmpty;
  }
}
