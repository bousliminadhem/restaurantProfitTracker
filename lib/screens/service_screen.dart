import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dish_provider.dart';
import '../providers/service_provider.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dishProvider = Provider.of<DishProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return PopScope(
     canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom AppBar
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.  successGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // AppBar Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMedium,
                        vertical: AppTheme.spaceSmall,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppTheme.offWhite),
                            onPressed: () async {
                              final shouldPop = await _showExitConfirmation(context);
                              if (shouldPop && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Service in Progress',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.offWhite,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: AppTheme.offWhite),
                            onPressed: () => _showServiceInfo(context, serviceProvider),
                          ),
                        ],
                      ),
                    ),
                    
                    // Profit Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceLarge,
                        vertical: AppTheme.spaceLarge,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.offWhite.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: AppTheme.goldenOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceSmall),
                              const Text(
                                'Current Profit',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.offWhite,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceSmall),
                          Text(
                            'Dt${serviceProvider.totalProfit.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.offWhite,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Color(0x40000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dishes Grid
              Expanded(
                child: dishProvider.dishes.isEmpty
                    ? _buildEmptyDishesState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppTheme.spaceMedium),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.80,
                          crossAxisSpacing: AppTheme.spaceMedium,
                          mainAxisSpacing: AppTheme.spaceMedium,
                        ),
                        itemCount: dishProvider.dishes.length,
                        itemBuilder: (context, index) {
                          final dish = dishProvider.dishes[index];
                          final orderItem = serviceProvider.getOrderItem(dish.id);
                          final quantity = orderItem?.quantity ?? 0;
                          
                          return _buildDishCard(
                            context,
                            dish.name,
                            dish.price,
                            quantity,
                            () => serviceProvider.addDishToService(dish),
                            () => serviceProvider.removeDishFromService(dish.id),
                          );
                        },
                      ),
              ),
              
              // End Service Button
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkBrown.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _endService(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bordeauxRed,
                        foregroundColor: AppTheme.offWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        elevation: 4,
                        shadowColor: AppTheme.bordeauxRed.withOpacity(0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle, size: 28),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'End Service',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyDishesState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spaceLarge),
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                color: AppTheme.warmGray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: AppTheme.warmGray,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            const Text(
              'No dishes available',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Add dishes first in Dish Management',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkBrown.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDishCard(
    BuildContext context,
    String name,
    double price,
    int quantity,
    VoidCallback onAdd,
    VoidCallback onRemove,
  ) {
    final isSelected = quantity > 0;
    
    return Material(
      elevation: isSelected ? 6 : 2,
      shadowColor: isSelected 
          ? AppTheme.freshGreen.withOpacity(0.4)
          : AppTheme.darkBrown.withOpacity(0.15),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.successGreen.withOpacity(0.1),
                      AppTheme.successGreen.withOpacity(0.05),
                    ],
                  )
                : null,
            color: isSelected ? null : AppTheme.offWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.successGreen
                  : AppTheme.warmGray.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quantity Badge
              Align(
                alignment: Alignment.topRight,
                child: quantity > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.successGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.successGreen.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'x$quantity',
                          style: const TextStyle(
                            color: AppTheme.offWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox(height: 32),
              ),
              
              // Dish Icon
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.warmGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 40,
                  color: isSelected ? AppTheme.successGreen : AppTheme.warmGray,
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceSmall),
              
              // Dish Name
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.successGreen : AppTheme.darkBrown,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Price
              Text(
                'Dt${price.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.goldenOrange : AppTheme.bordeauxRed,
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceSmall),
              
              // Remove Button (only if quantity > 0)
              if (quantity > 0)
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppTheme.bordeauxRed,
                      side: const BorderSide(color: AppTheme.bordeauxRed, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    child: const Icon(Icons.remove, size: 20),
                  ),
                )
              else
                const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showServiceInfo(BuildContext context, ServiceProvider serviceProvider) {
    final startTime = serviceProvider.serviceStartTime;
    final duration = startTime != null
        ? DateTime.now().difference(startTime)
        : Duration.zero;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.offWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(
                Icons.info,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            const Text('Service Information', style: AppTheme.headlineMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('Start Time', _formatTime(startTime ?? DateTime.now()), Icons.access_time),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildInfoRow('Duration', _formatDuration(duration), Icons.timer),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildInfoRow(
              'Items Sold',
              serviceProvider.currentOrders.fold(
                0,
                (sum, item) => sum + item.quantity,
              ).toString(),
              Icons.shopping_cart,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildInfoRow(
              'Unique Dishes',
              serviceProvider.currentOrders.length.toString(),
              Icons.restaurant_menu,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bordeauxRed,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.warmGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.warmGray.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.bordeauxRed, size: 20),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.bordeauxRed,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
  
  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.offWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppTheme.bordeauxRed),
            SizedBox(width: AppTheme.spaceSmall),
            Text('Exit Service?', style: AppTheme.headlineMedium),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit? The service will continue running.',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bordeauxRed,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  void _endService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.offWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Row(
          children: [
            Icon(Icons.stop_circle, color: AppTheme.bordeauxRed),
            SizedBox(width: AppTheme.spaceSmall),
            Text('End Service?', style: AppTheme.headlineMedium),
          ],
        ),
        content: const Text(
          'Are you sure you want to end this service? This will finalize the shift and save the results.',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bordeauxRed,
            ),
            onPressed: () async {
              final serviceProvider = Provider.of<ServiceProvider>(
                context,
                listen: false,
              );
              
              final totalProfit = serviceProvider.totalProfit;
              await serviceProvider.endService();
              
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SummaryScreen(totalProfit: totalProfit),
                  ),
                );
              }
            },
            child: const Text('End Service'),
          ),
        ],
      ),
    );
  }
}
