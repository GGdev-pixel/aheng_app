import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = true;
  bool _purchaseInProgress = false;
  ProductDetails? _product;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final available = await PurchaseService.isAvailable();
      if (!available) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Ödəniş xidməti hazırda əlçatan deyil (Play Store tələb olunur)';
            _loading = false;
          });
        }
        return;
      }

      PurchaseService.startListening(
        onError: (message) {
          if (mounted) {
            setState(() {
              _purchaseInProgress = false;
              _errorMessage = message;
            });
          }
        },
        onSuccess: () {
          if (mounted) {
            setState(() => _purchaseInProgress = false);
            Navigator.pop(context, true);
          }
        },
      );

      final response = await PurchaseService.getProducts();
      if (mounted) {
        if (response.productDetails.isNotEmpty) {
          setState(() {
            _product = response.productDetails.first;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Məhsul tapılmadı';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Xəta: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    PurchaseService.stopListening();
    super.dispose();
  }

  Future<void> _buy() async {
    if (_product == null) return;
    setState(() {
      _purchaseInProgress = true;
      _errorMessage = null;
    });
    await PurchaseService.buySubscription(_product!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium,
                  color: AppColors.primaryBlue, size: 40),
            ),
            const Text(
              'Ahəng Premium',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const _FeatureRow(text: 'İmtahan simulyasiyası — sərhədsiz'),
            const _FeatureRow(text: 'Bir neçə fənn üzrə gündəlik suallar'),
            const _FeatureRow(text: 'Gündəlik sualları limitsiz təkrarlamaq'),
            const _FeatureRow(text: 'Hazırlıq planı'),
            const Spacer(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.accentRed),
                ),
              ),
            if (_product != null)
              ElevatedButton(
                onPressed: _purchaseInProgress ? null : _buy,
                child: _purchaseInProgress
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text('${_product!.price} / ay abunə ol'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await PurchaseService.restorePurchases();
              },
              child: const Text('Əvvəlki alışı bərpa et'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}