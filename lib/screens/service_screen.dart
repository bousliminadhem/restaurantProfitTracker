import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dish_provider.dart';
import '../providers/service_provider.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory; // Null means showing category list
  String? _selectedVariant; // 'sec' or 'complet', null if not selected or n/a

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dishProvider = Provider.of<DishProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    
    final bool showCategories = _selectedCategory == null && _searchQuery.isEmpty;
    
    // Check if current category has variants
    final bool categoryHasVariants = _selectedCategory != null && 
        dishProvider.dishes.any((d) => d.type == _selectedCategory && d.hasVariant);
        
    final bool showVariantSelection = !showCategories && 
        _searchQuery.isEmpty && 
        categoryHasVariants && 
        _selectedVariant == null;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Handle back navigation for variants
        if (_selectedVariant != null) {
          setState(() {
            _selectedVariant = null;
          });
          return;
        }

        // Handle back navigation for categories
        if (_selectedCategory != null) {
          setState(() {
            _selectedCategory = null;
          });
          return;
        }
        
        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern AppBar with Live Profit Display
              _buildModernHeader(serviceProvider),
              
              // Search Bar
              _buildSearchBar(),
              
              // Helper Text / Breadcrumbs
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
                            _selectedVariant = null;
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
                        style: TextStyle(
                          color: showVariantSelection ? AppTheme.goldenOrange : AppTheme.darkBrown,
                          fontWeight: showVariantSelection ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (_selectedVariant != null) ...[
                         const SizedBox(width: 8),
                         const Icon(Icons.chevron_right, size: 16, color: AppTheme.warmGray),
                         const SizedBox(width: 8),
                         Text(
                           _selectedVariant!, // Capitalize?
                            style: const TextStyle(
                              color: AppTheme.goldenOrange,
                              fontWeight: FontWeight.bold,
                            ),
                         ),
                      ],
                    ],
                  ),
                ),
              
              // Main Content
              Expanded(
                child: showCategories
                    ? _buildCategoryGrid(dishProvider)
                    : (showVariantSelection 
                        ? _buildVariantSelection(dishProvider)
                        : _buildDishesGrid(dishProvider, serviceProvider)),
              ),
              
              // Enhanced End Service Button
              if (_selectedCategory == null && _searchQuery.isEmpty)
                _buildEndServiceButton(context)
              else 
                 _buildEndServiceButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(DishProvider dishProvider) {
    final categories = dishProvider.categories.where((c) => c != 'All').toList();
    
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: AppTheme.warmGray.withOpacity(0.5)),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'No categories found',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85, // Slightly wider/shorter than dish cards
        crossAxisSpacing: AppTheme.spaceMedium,
        mainAxisSpacing: AppTheme.spaceMedium,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        // Count items in category
        final itemCount = dishProvider.dishes.where((d) => d.type == category).length;
        
        return _buildCategoryCard(category, itemCount, index);
      },
    );
  }

  Widget _buildVariantSelection(DishProvider dishProvider) {
    // Show Sec/Complet buttons and NON-variant dishes
    final nonVariantDishes = dishProvider.dishes.where((d) => 
      d.type == _selectedCategory && !d.hasVariant
    ).toList();
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _buildVariantCard('Sec', Icons.layers_outlined, () {
                    setState(() {
                      _selectedVariant = 'sec';
                    });
                  }),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: _buildVariantCard('Complet', Icons.layers, () {
                    setState(() {
                      _selectedVariant = 'complet';
                    });
                  }),
                ),
              ],
            ),
          ),
        ),
        
        if (nonVariantDishes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium, 
                vertical: AppTheme.spaceSmall
              ),
              child: Text(
                'Other Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBrown.withOpacity(0.8),
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppTheme.spaceMedium,
                mainAxisSpacing: AppTheme.spaceMedium,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                   final dish = nonVariantDishes[index];
                   final orderItem = Provider.of<ServiceProvider>(context).getOrderItem(dish.id);
                   final quantity = orderItem?.quantity ?? 0;
                   return _buildModernDishCard(
                     context, dish.name, dish.price, quantity,
                     () => Provider.of<ServiceProvider>(context, listen: false).addDishToService(dish),
                     () => Provider.of<ServiceProvider>(context, listen: false).removeDishFromService(dish.id),
                     index
                   );
                },
                childCount: nonVariantDishes.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVariantCard(String title, IconData icon, VoidCallback onTap) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Material(
        elevation: 4,
        shadowColor: AppTheme.goldenOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.offWhite,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Icon(icon, size: 36, color: AppTheme.goldenOrange),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
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
                    Icons.restaurant_menu, // Generic icon, could be mapped based on name if desired
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warmGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$itemCount items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBrown.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLarge,
        vertical: AppTheme.spaceMedium,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          borderRadius: BorderRadius.circular(16),
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
            hintText: 'Search dishes...',
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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

  Widget _buildDishesGrid(DishProvider dishProvider, ServiceProvider serviceProvider) {
    // If search is active, ignore category (or filter within category? User intent usually "find X")
    // Let's filter by selectedCategory if set, otherwise search all.
    // Actually, logic: if search is set, filterDishes uses search + category.
    // If we are in "All Categories" view (_selectedCategory == null) and search is set, filterDishes(query, 'All') works.
    // If we are in "Ojjas" view and search is set, filterDishes(query, 'Ojjas') works.
    
    final categoryToFilter = _selectedCategory ?? 'All';
    var filteredDishes = dishProvider.filterDishes(_searchQuery, categoryToFilter);

    // Apply Variant Filter if active
    if (_selectedVariant != null) {
      filteredDishes = filteredDishes.where((d) {
        if (d.hasVariant) {
          return d.variant?.toLowerCase() == _selectedVariant?.toLowerCase();
        }
        return false; // Strict filtering for variant view
      }).toList();
    }

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
                  : 'No dishes found',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.darkBrown.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery.isEmpty && _selectedCategory != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 16),
                   child: OutlinedButton(
                     onPressed: () {
                       if (_selectedVariant != null) {
                         setState(() {
                           _selectedVariant = null;
                         });
                       } else {
                         setState(() {
                           _selectedCategory = null;
                         });
                       }
                     },
                     child: Text(_selectedVariant != null ? 'Back to Variants' : 'Back to Categories'),
                   ),
                 ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppTheme.spaceMedium,
          mainAxisSpacing: AppTheme.spaceMedium,
        ),
        itemCount: filteredDishes.length,
        itemBuilder: (context, index) {
          final dish = filteredDishes[index];
          final orderItem = serviceProvider.getOrderItem(dish.id);
          final quantity = orderItem?.quantity ?? 0;
          
          return _buildModernDishCard(
            context,
            dish.name,
            dish.price,
            quantity,
            () => serviceProvider.addDishToService(dish),
            () => serviceProvider.removeDishFromService(dish.id),
            index,
          );
        },
      ),
    );
  }
  
  Widget _buildModernHeader(ServiceProvider serviceProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.freshGreen,
            AppTheme.successGreen,
            const Color(0xFF66BB6A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.freshGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSmall,
              vertical: AppTheme.spaceSmall,
            ),
            child: Row(
              children: [
                // Back Button with Style
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.offWhite, size: 20),
                    onPressed: () async {
                      final shouldPop = await _showExitConfirmation(context);
                      if (shouldPop && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                
                // Title
                const Expanded(
                  child: Text(
                    'Service Active',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.offWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                // Info Button
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: AppTheme.offWhite, size: 22),
                    onPressed: () => _showServiceInfo(context, serviceProvider),
                  ),
                ),
              ],
            ),
          ),
          
          // Animated Profit Display
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLarge,
              AppTheme.spaceSmall,
              AppTheme.spaceLarge,
              AppTheme.spaceLarge,
            ),
            child: Column(
              children: [
                // Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.goldenOrange,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldenOrange.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: AppTheme.offWhite,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    const Text(
                      'Live Profit',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.offWhite,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceSmall),
                
                // Profit Amount with Animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: serviceProvider.totalProfit),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Text(
                      '${value.toStringAsFixed(2)} Dt',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.offWhite,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Color(0x50000000),
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // Items Count
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${serviceProvider.currentOrders.fold(0, (sum, item) => sum + item.quantity)} items sold',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.offWhite.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernDishCard(
    BuildContext context,
    String name,
    double price,
    int quantity,
    VoidCallback onAdd,
    VoidCallback onRemove,
    int index,
  ) {
    final isSelected = quantity > 0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: child,
        );
      },
      child: Material(
        elevation: isSelected ? 8 : 3,
        shadowColor: isSelected 
            ? AppTheme.freshGreen.withOpacity(0.5)
            : AppTheme.warmGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.freshGreen.withOpacity(0.15),
                        AppTheme.successGreen.withOpacity(0.08),
                      ],
                    )
                  : null,
              color: isSelected ? null : AppTheme.offWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.freshGreen
                    : AppTheme.warmGray.withOpacity(0.2),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Section: Quantity Badge & Dish Icon
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    child: Column(
                      children: [
                        // Quantity Badge
                        Align(
                          alignment: Alignment.topRight,
                          child: quantity > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.freshGreen,
                                        AppTheme.successGreen,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.successGreen.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.offWhite,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'x$quantity',
                                        style: const TextStyle(
                                          color: AppTheme.offWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(height: 28),
                        ),
                        
                        const Spacer(),
                        
                        // Dish Icon
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: isSelected 
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.freshGreen.withOpacity(0.2),
                                      AppTheme.successGreen.withOpacity(0.15),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppTheme.warmGray.withOpacity(0.1),
                                      AppTheme.warmGray.withOpacity(0.05),
                                    ],
                                  ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant,
                            size: 36,
                            color: isSelected ? AppTheme.freshGreen : AppTheme.warmGray,
                          ),
                        ),
                        
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Section: Name, Price, Actions
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.freshGreen.withOpacity(0.05)
                        : AppTheme.warmGray.withOpacity(0.03),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Dish Name
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.freshGreen : AppTheme.darkBrown,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.goldenOrange.withOpacity(0.15)
                              : AppTheme.bordeauxRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${price.toStringAsFixed(2)} Dt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.goldenOrange : AppTheme.bordeauxRed,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Action Button
                      if (quantity > 0)
                        SizedBox(
                          height: 36,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onRemove,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: AppTheme.bordeauxRed,
                              side: const BorderSide(color: AppTheme.bordeauxRed, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.remove_circle_outline, size: 18),
                            label: const Text(
                              'Remove',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 36,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onAdd,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: AppTheme.freshGreen,
                              foregroundColor: AppTheme.offWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
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
  
  Widget _buildEmptyDishesState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spaceXLarge),
        padding: const EdgeInsets.all(AppTheme.spaceXLarge * 1.5),
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warmGray.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.warmGray.withOpacity(0.1),
                    AppTheme.warmGray.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppTheme.warmGray,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            const Text(
              'No Dishes Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Add dishes in Dish Management\nto start tracking orders',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.darkBrown.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEndServiceButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkBrown.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.bordeauxRed,
                Color(0xFFD32027),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.bordeauxRed.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _endService(context),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_circle, size: 28, color: AppTheme.offWhite),
                    SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'End Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.offWhite,
                        letterSpacing: 0.5,
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
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info,
                color: AppTheme.offWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            const Expanded(
              child: Text(
                'Service Info',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBrown,
                ),
              ),
            ),
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
              backgroundColor: AppTheme.freshGreen,
              foregroundColor: AppTheme.offWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warmGray.withOpacity(0.08),
            AppTheme.warmGray.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warmGray.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.freshGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.freshGreen, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkBrown,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.freshGreen,
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
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppTheme.bordeauxRed, size: 28),
            SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Text(
                'Exit Service?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBrown,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'The service will continue running in the background.',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.darkBrown,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bordeauxRed,
              foregroundColor: AppTheme.offWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
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
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bordeauxRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stop_circle, color: AppTheme.bordeauxRed, size: 28),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            const Expanded(
              child: Text(
                'End Service?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBrown,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will finalize the shift and save all results.',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.darkBrown,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bordeauxRed,
              foregroundColor: AppTheme.offWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            child: const Text('End Service', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
