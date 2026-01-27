import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/service_provider.dart';
import 'dish_management_screen.dart';
import 'service_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade600,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // App Title
                  const Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restaurant Profit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Start Service Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.play_circle_filled,
                    label: 'Start Service',
                    color: Colors.green.shade400,
                    onPressed: () {
                      serviceProvider.startService();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Manage Dishes Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.restaurant,
                    label: 'Manage Dishes',
                    color: Colors.orange.shade400,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DishManagementScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // View History Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.history,
                    label: 'Shift History',
                    color: Colors.blue.shade400,
                    onPressed: () => _showShiftHistory(context),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Statistics
                  if (serviceProvider.shiftHistory.isNotEmpty)
                    _buildStatisticsCard(serviceProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatisticsCard(ServiceProvider serviceProvider) {
    final totalShifts = serviceProvider.shiftHistory.length;
    final totalRevenue = serviceProvider.shiftHistory.fold(
      0.0,
      (sum, shift) => sum + shift.totalProfit,
    );
    final avgRevenue = totalRevenue / totalShifts;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(child: _buildStatItem('Total Shifts', '$totalShifts')),
              Flexible(child: _buildStatItem('Total Revenue', '€${totalRevenue.toStringAsFixed(2)}')),
              Flexible(child: _buildStatItem('Avg/Shift', '€${avgRevenue.toStringAsFixed(2)}')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  void _showShiftHistory(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    
    // Group shifts by date
    final Map<String, List<dynamic>> groupedShifts = {};
    for (var shift in serviceProvider.shiftHistory) {
      final dateStr = '${shift.startTime.day}/${shift.startTime.month}/${shift.startTime.year}';
      if (!groupedShifts.containsKey(dateStr)) {
        groupedShifts[dateStr] = [];
      }
      groupedShifts[dateStr]!.add(shift);
    }
    
    final sortedDates = groupedShifts.keys.toList()..sort((a, b) {
      // Very simple reverse sort for DD/MM/YYYY
      final partsA = a.split('/').map(int.parse).toList();
      final partsB = b.split('/').map(int.parse).toList();
      final dateA = DateTime(partsA[2], partsB[1], partsA[0]);
      final dateB = DateTime(partsB[2], partsB[1], partsB[0]);
      return dateB.compareTo(dateA);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shift History'),
        content: SizedBox(
          width: double.maxFinite,
          child: serviceProvider.shiftHistory.isEmpty
              ? const Center(child: Text('No shift history yet'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedDates.length,
                  itemBuilder: (context, dateIndex) {
                    final date = sortedDates[dateIndex];
                    final shifts = groupedShifts[date]!;
                    final dailyTotal = shifts.fold(0.0, (sum, s) => sum + s.totalProfit);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Daily: €${dailyTotal.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ...shifts.reversed.map((shift) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              '€${shift.totalProfit.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${_formatTime(shift.startTime)} - ${shift.endTime != null ? _formatTime(shift.endTime!) : "Active"}',
                            ),
                          ),
                        )),
                        const Divider(),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          if (serviceProvider.shiftHistory.isNotEmpty)
            TextButton(
              onPressed: () {
                serviceProvider.clearHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear History'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
