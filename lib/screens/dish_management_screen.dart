import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../providers/dish_provider.dart';

class DishManagementScreen extends StatefulWidget {
  const DishManagementScreen({super.key});

  @override
  State<DishManagementScreen> createState() => _DishManagementScreenState();
}

class _DishManagementScreenState extends State<DishManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final dishProvider = Provider.of<DishProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Dishes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple,
              Colors.deepPurple.shade50,
            ],
          ),
        ),
        child: dishProvider.dishes.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dishProvider.dishes.length,
                itemBuilder: (context, index) {
                  final dish = dishProvider.dishes[index];
                  return _buildDishCard(dish, dishProvider);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDishDialog(context),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 100,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No dishes yet',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first dish',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDishCard(Dish dish, DishProvider dishProvider) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple,
            radius: 28,
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
            ),
          ),
          title: Text(
            dish.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '€${dish.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showAddEditDishDialog(
                  context,
                  dish: dish,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, dish, dishProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddEditDishDialog(BuildContext context, {Dish? dish}) {
    final nameController = TextEditingController(text: dish?.name ?? '');
    final priceController = TextEditingController(
      text: dish != null ? dish.price.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dish == null ? 'Add Dish' : 'Edit Dish'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Dish Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a dish name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final dishProvider = Provider.of<DishProvider>(
                  context,
                  listen: false,
                );
                
                final name = nameController.text.trim();
                final price = double.parse(priceController.text);
                
                if (dish == null) {
                  dishProvider.addDish(name, price);
                } else {
                  dishProvider.updateDish(dish.id, name, price);
                }
                
                Navigator.pop(context);
              }
            },
            child: Text(dish == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, Dish dish, DishProvider dishProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dish'),
        content: Text('Are you sure you want to delete "${dish.name}"?'),
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
            onPressed: () {
              dishProvider.deleteDish(dish.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
