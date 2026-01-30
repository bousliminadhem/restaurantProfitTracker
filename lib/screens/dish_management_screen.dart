import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../providers/dish_provider.dart';
import '../theme/app_theme.dart';

class DishManagementScreen extends StatefulWidget {
  const DishManagementScreen({super.key});

  @override
  State<DishManagementScreen> createState() => _DishManagementScreenState();
}

class _DishManagementScreenState extends State<DishManagementScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory; // Null means showing category list
  
  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final dishProvider = Provider.of<DishProvider>(context);
    
    // Logic: show categories if no category selected AND no search query
    final bool showCategories = _selectedCategory == null && _searchQuery.isEmpty;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (_selectedCategory != null) {
          setState(() {
            _selectedCategory = null;
          });
          return;
        }
        
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildHeader(context, dishProvider.dishes.length),
              
              // Search Bar
              _buildSearchBar(),
              
              // Breadcrumbs
              if (_selectedCategory != null && _searchQuery.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLarge,
                    vertical: AppTheme.spaceSmall,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back, size: 16, color: AppTheme.darkBrown),
                            const SizedBox(width: 4),
                            Text(
                              'All Categories',
                              style: TextStyle(
                                color: AppTheme.darkBrown.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.warmGray),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCategory!,
                        style: const TextStyle(
                          color: AppTheme.goldenOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Main content
              Expanded(
                child: dishProvider.dishes.isEmpty
                    ? _buildEmptyState()
                    : (showCategories
                        ? _buildCategoryGrid(dishProvider)
                        : _buildDishList(dishProvider)),
              ),
            ],
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: _fabController,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Pre-fill category if selected
              _showAddEditDishDialog(context, initialCategory: _selectedCategory);
            },
            backgroundColor: AppTheme.goldenOrange,
            foregroundColor: AppTheme.offWhite,
            elevation: 8,
            icon: const Icon(Icons.add_circle_outline, size: 28),
            label: const Text(
              'Add Dish',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(DishProvider dishProvider) {
    // Exclude 'All' if present, or keep it? Usually management is better specific.
    // Provider adds 'All'. Filter it out.
    final categories = dishProvider.categories.where((c) => c != 'All').toList();
    
    if (categories.isEmpty) {
      // Should effectively be empty state handled above if no dishes, 
      // but if dishes exist with NO category (default 'Plates'), it shows Plates.
      // If code works correctly, we always have at least one category if dishes exist.
      return const SizedBox.shrink(); 
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85, 
        crossAxisSpacing: AppTheme.spaceMedium,
        mainAxisSpacing: AppTheme.spaceMedium,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final itemCount = dishProvider.dishes.where((d) => d.type == category).length;
        
        return _buildCategoryCard(category, itemCount, index);
      },
    );
  }

  Widget _buildCategoryCard(String category, int itemCount, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.scale(scale: val, child: child);
      },
      child: Material(
        elevation: 4,
        shadowColor: AppTheme.goldenOrange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.offWhite,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldenOrange.withOpacity(0.2),
                        AppTheme.caramel.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: AppTheme.goldenOrange,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBrown,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$itemCount items',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkBrown.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, int dishCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bordeauxRed,
            Color(0xFF8A0E1C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.spaceSmall,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.offWhite),
                  onPressed: () {
                    if (_selectedCategory != null) {
                      setState(() {
                        _selectedCategory = null;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    _selectedCategory ?? 'Menu Management',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.offWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance with back button
              ],
            ),
          ),
          
          // Stats Section
          // Only show key stats if in main view to save space? Or keep it.
          // Let's keep it but maybe simplify if in category view.
          if (_selectedCategory == null)
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLarge,
              AppTheme.spaceSmall,
              AppTheme.spaceLarge,
              AppTheme.spaceLarge,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(
                  icon: Icons.restaurant_menu,
                  label: 'Total Dishes',
                  value: '$dishCount',
                  color: AppTheme.goldenOrange,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.offWhite.withOpacity(0.3),
                ),
                _buildStatBadge(
                  icon: Icons.category,
                  label: 'Status',
                  value: dishCount > 0 ? 'Ready' : 'Empty',
                  color: AppTheme.successGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.offWhite.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.offWhite,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.offWhite.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
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
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.goldenOrange.withOpacity(0.1),
                      AppTheme.caramel.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.menu_book,
                  size: 80,
                  color: AppTheme.goldenOrange,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              const Text(
                'Your Menu is Empty',
                style: AppTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Start building your menu by adding your first dish',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDishDialog(context, initialCategory: _selectedCategory),
                icon: const Icon(Icons.add),
                label: const Text('Add First Dish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldenOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLarge,
                    vertical: AppTheme.spaceMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMedium,
        AppTheme.spaceMedium,
        AppTheme.spaceMedium,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkBrown.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search menu items...',
            hintStyle: TextStyle(
              color: AppTheme.darkBrown.withOpacity(0.5),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.goldenOrange,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.warmGray),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.goldenOrange,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.darkBrown,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppTheme.goldenOrange,
        ),
      ),
    );
  }

  Widget _buildDishList(DishProvider dishProvider) {
    // Determine filter: Search + Category if selected
    // If not selected, assume 'All' (but this widget should only be called when selected OR search active)
    final categoryToFilter = _selectedCategory ?? 'All';
    final filteredDishes = dishProvider.filterDishes(_searchQuery, categoryToFilter);
    
    if (filteredDishes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.warmGray.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No dishes found matching "$_searchQuery"'
                  : 'No dishes in this category',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.darkBrown.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDishes.length,
      itemBuilder: (context, index) {
        final dish = filteredDishes[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildDishCard(dish, dishProvider),
        );
      },
    );
  }
  
  Widget _buildDishCard(Dish dish, DishProvider dishProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      child: Material(
        elevation: 4,
        shadowColor: AppTheme.darkBrown.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showAddEditDishDialog(context, dish: dish),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.warmGray.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                // Dish Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.goldenOrange,
                        AppTheme.caramel,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldenOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: AppTheme.offWhite,
                    size: 36,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spaceMedium),
                
                // Dish Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBrown,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: AppTheme.successGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${dish.price.toStringAsFixed(2)} Dt',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: AppTheme.bordeauxRed,
                      onPressed: () => _showAddEditDishDialog(context, dish: dish),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFD32F2F),
                      onPressed: () => _confirmDelete(context, dish, dishProvider),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAddEditDishDialog(BuildContext context, {Dish? dish, String? initialCategory}) {
    final nameController = TextEditingController(text: dish?.name ?? '');
    final priceController = TextEditingController(
      text: dish != null ? dish.price.toStringAsFixed(2) : '',
    );
    final categoryController = TextEditingController(
      text: dish?.type ?? initialCategory ?? 'Plates',
    );
    
    // Variant State
    bool hasVariant = dish?.hasVariant ?? false;
    String? variant = dish?.variant;
    if (hasVariant && variant == null) variant = 'sec';

    final formKey = GlobalKey<FormState>();
    
    // Get distinct categories for suggestions (excluding 'All')
    final dishProvider = Provider.of<DishProvider>(context, listen: false);
    final categories = dishProvider.categories.where((c) => c != 'All').toList();
    // specific default suggestions if list is empty
    if (categories.isEmpty) {
      categories.addAll(['Volailles', 'Grillades', 'Spécialités', 'Sandwichs', 'Boissons']);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Icon(
                            dish == null ? Icons.add_circle : Icons.edit,
                            color: AppTheme.offWhite,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(
                          dish == null ? 'Add New Dish' : 'Edit Dish',
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.bordeauxRed,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spaceLarge),
                    
                    // Form
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Dish Name',
                              hintText: 'e.g., Margherita Pizza',
                              prefixIcon: const Icon(Icons.restaurant_menu, color: AppTheme.bordeauxRed),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                borderSide: const BorderSide(color: AppTheme.bordeauxRed, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a dish name';
                              }
                              return null;
                            },
                            autofocus: true,
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priceController,
                                  decoration: InputDecoration(
                                    labelText: 'Price (Dt)',
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.attach_money, color: AppTheme.successGreen),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      borderSide: const BorderSide(color: AppTheme.successGreen, width: 2),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final price = double.tryParse(value);
                                    if (price == null || price <= 0) {
                                      return 'Invalid price';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              Expanded(
                                child: TextFormField(
                                  controller: categoryController,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    hintText: 'Volailles',
                                    prefixIcon: const Icon(Icons.category, color: AppTheme.goldenOrange),
                                    suffixIcon: PopupMenuButton<String>(
                                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldenOrange),
                                      onSelected: (String value) {
                                        categoryController.text = value;
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return categories.map((String value) {
                                          return PopupMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList();
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      borderSide: const BorderSide(color: AppTheme.goldenOrange, width: 2),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppTheme.spaceMedium),

                          // Variant Selector
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warmGray.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppTheme.warmGray.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.layers, color: AppTheme.darkBrown),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Has Variant?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.darkBrown,
                                      ),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: hasVariant,
                                      activeColor: AppTheme.goldenOrange,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          hasVariant = val;
                                          if (val && variant == null) {
                                            variant = 'sec';
                                          }
                                          if (!val) {
                                            variant = null;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (hasVariant) ...[
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildVariantOption(
                                          'Sec',
                                          variant == 'sec',
                                          () => setDialogState(() => variant = 'sec'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildVariantOption(
                                          'Complet',
                                          variant == 'complet',
                                          () => setDialogState(() => variant = 'complet'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceLarge),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppTheme.warmGray),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMedium),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final name = nameController.text.trim();
                                final price = double.parse(priceController.text);
                                final category = categoryController.text.trim();
                                
                                if (dish == null) {
                                  dishProvider.addDish(
                                    name, price, category, 
                                    hasVariant: hasVariant, 
                                    variant: variant,
                                  );
                                } else {
                                  dishProvider.updateDish(
                                    dish.id, name, price, category, 
                                    hasVariant: hasVariant, 
                                    variant: variant,
                                  );
                                }
                                
                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: AppTheme.offWhite),
                                        const SizedBox(width: AppTheme.spaceSmall),
                                        Text(dish == null ? 'Dish added!' : 'Dish updated!'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.successGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.goldenOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(dish == null ? 'Add Dish' : 'Update'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVariantOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldenOrange : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.goldenOrange : AppTheme.warmGray.withOpacity(0.5)
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.offWhite : AppTheme.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, Dish dish, DishProvider dishProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.delete_forever,
                  size: 48,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Delete Dish?',
                style: AppTheme.headlineMedium.copyWith(
                  color: const Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Are you sure you want to delete "${dish.name}"? This action cannot be undone.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        dishProvider.deleteDish(dish.id);
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppTheme.offWhite),
                                const SizedBox(width: AppTheme.spaceSmall),
                                const Text('Dish deleted'),
                              ],
                            ),
                            backgroundColor: const Color(0xFFD32F2F),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                        );
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
