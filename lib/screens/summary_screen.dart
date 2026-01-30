import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryScreen extends StatelessWidget {
  final double totalProfit;
  
  const SummaryScreen({super.key, required this.totalProfit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceLarge),
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppTheme.goldenOrange,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldenOrange.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: AppTheme.goldenOrange,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXLarge),
                    
                    // Title
                    const Text(
                      'Service Completed!',
                      style: AppTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppTheme.spaceSmall),
                    
                    Text(
                      'Great work today',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.offWhite.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXLarge * 1.5),
                    
                    // Profit Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spaceLarge * 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: AppTheme.elevatedShadow,
                        border: Border.all(
                          color: AppTheme.goldenOrange.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: const Icon(
                                  Icons.monetization_on,
                                  color: AppTheme.offWhite,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Text(
                                'Total Profit',
                                style: AppTheme.headlineMedium.copyWith(
                                  color: AppTheme.bordeauxRed,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppTheme.spaceMedium),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceLarge,
                              vertical: AppTheme.spaceMedium,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.successGreen.withOpacity(0.1),
                                  AppTheme.successGreen.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: AppTheme.successGreen.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'Dt${totalProfit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successGreen,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXLarge * 1.5),
                    
                    // Return Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home, size: 28),
                        label: const Text(
                          'Return to Home',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldenOrange,
                          foregroundColor: AppTheme.offWhite,
                          elevation: 6,
                          shadowColor: AppTheme.goldenOrange.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    // Secondary Action
                    TextButton.icon(
                      onPressed: () {
                        // Could add share or export functionality here
                      },
                      icon: const Icon(Icons.share, color: AppTheme.offWhite),
                      label: Text(
                        'Share Results',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.offWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
