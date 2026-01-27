import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dish.dart';

/// Connection Test Screen
/// Use this to verify backend connectivity before full integration
class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final ApiService _api = ApiService();
  String _status = 'Ready to test';
  bool _testing = false;
  Color _statusColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        backgroundColor: Colors.deepPurple,
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                Icon(
                  _getStatusIcon(),
                  size: 100,
                  color: _statusColor,
                ),
                const SizedBox(height: 24),
                
                // Status Text
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Test Buttons
                _buildTestButton(
                  label: '1. Test GET /api/dishes',
                  onPressed: _testing ? null : _testGetDishes,
                  icon: Icons.download,
                ),
                const SizedBox(height: 16),
                
                _buildTestButton(
                  label: '2. Test POST /api/dishes',
                  onPressed: _testing ? null : _testCreateDish,
                  icon: Icons.upload,
                ),
                const SizedBox(height: 16),
                
                _buildTestButton(
                  label: '3. Test DELETE /api/dishes',
                  onPressed: _testing ? null : _testDeleteDish,
                  icon: Icons.delete,
                ),
                const SizedBox(height: 40),
                
                // Configuration Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuration:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Backend URL:', ApiService.baseUrl),
                      _buildInfoRow('Platform:', _getPlatform()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_testing) return Icons.hourglass_empty;
    if (_status.contains('✅')) return Icons.check_circle;
    if (_status.contains('❌')) return Icons.error;
    return Icons.cloud_outlined;
  }

  String _getPlatform() {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return 'Android';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'iOS';
    } else {
      return 'Web';
    }
  }

  Future<void> _testGetDishes() async {
    setState(() {
      _testing = true;
      _status = 'Testing GET /api/dishes...';
      _statusColor = Colors.orange;
    });

    try {
      final dishes = await _api.getAllDishes();
      setState(() {
        _status = '✅ Success!\nFound ${dishes.length} dishes\n\nResponse: $dishes';
        _statusColor = Colors.green;
        _testing = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed\n\nError: $e\n\nCheck:\n• Backend running on port 8081?\n• CORS configured correctly?\n• Correct baseUrl?';
        _statusColor = Colors.red;
        _testing = false;
      });
    }
  }

  Future<void> _testCreateDish() async {
    setState(() {
      _testing = true;
      _status = 'Testing POST /api/dishes...';
      _statusColor = Colors.orange;
    });

    try {
      final testDish = Dish(
        id: '',
        name: 'Test Pizza',
        price: 10.99,
      );
      
      final created = await _api.createDish(testDish);
      setState(() {
        _status = '✅ Success!\nDish created with ID: ${created.id}\n\nName: ${created.name}\nPrice: €${created.price}';
        _statusColor = Colors.green;
        _testing = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed\n\nError: $e';
        _statusColor = Colors.red;
        _testing = false;
      });
    }
  }

  Future<void> _testDeleteDish() async {
    setState(() {
      _testing = true;
      _status = 'Getting dishes to delete...';
      _statusColor = Colors.orange;
    });

    try {
      // First get all dishes
      final dishes = await _api.getAllDishes();
      
      if (dishes.isEmpty) {
        setState(() {
          _status = '❌ No dishes to delete\n\nCreate a dish first using test 2';
          _statusColor = Colors.orange;
          _testing = false;
        });
        return;
      }

      // Delete the first one
      final dishToDelete = dishes.first;
      await _api.deleteDish(dishToDelete.id);
      
      setState(() {
        _status = '✅ Success!\nDeleted dish: ${dishToDelete.name}';
        _statusColor = Colors.green;
        _testing = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed\n\nError: $e';
        _statusColor = Colors.red;
        _testing = false;
      });
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
