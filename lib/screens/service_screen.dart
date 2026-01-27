import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dish_provider.dart';
import '../providers/service_provider.dart';
import 'summary_screen.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dishProvider = Provider.of<DishProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    
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
        appBar: AppBar(
          title: const Text('Service in Progress'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showServiceInfo(context, serviceProvider),
            ),
          ],
        ),
        body: Column(
          children: [
            // Total Profit Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade500,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade700.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Current Profit',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${serviceProvider.totalProfit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Dishes Grid
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: dishProvider.dishes.isEmpty
                    ? _buildEmptyDishesState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
            ),
            
            // End Service Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _endService(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle, size: 28),
                        SizedBox(width: 12),
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
    );
  }
  
  Widget _buildEmptyDishesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No dishes available',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add dishes first in Dish Management',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
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
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.green.shade400 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.white, Colors.grey.shade50],
            ),
          ),
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              // Dish Icon
              Icon(
                Icons.restaurant,
                size: 48,
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade400,
              ),
              
              // Dish Name
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green.shade900 : Colors.black87,
                ),
              ),
              
              // Price
              Text(
                '€${price.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              
              // Remove Button (only if quantity > 0)
              if (quantity > 0)
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ),
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
        title: const Text('Service Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Start Time', _formatTime(startTime ?? DateTime.now())),
            const SizedBox(height: 8),
            _buildInfoRow('Duration', _formatDuration(duration)),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Items Sold',
              serviceProvider.currentOrders.fold(
                0,
                (sum, item) => sum + item.quantity,
              ).toString(),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Unique Dishes',
              serviceProvider.currentOrders.length.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
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
        title: const Text('Exit Service?'),
        content: const Text(
          'Are you sure you want to exit? The service will continue running.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
        title: const Text('End Service?'),
        content: const Text(
          'Are you sure you want to end this service? This will finalize the shift and save the results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
