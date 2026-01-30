import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/service_provider.dart';
import '../theme/app_theme.dart';
import 'dish_management_screen.dart';
import 'service_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _buttonsController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  
  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    
    _logoRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    
    _logoController.forward().then((_) {
      _buttonsController.forward();
    });
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLarge,
                vertical: AppTheme.spaceMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spaceXLarge),
                  
                  // Animated Logo and Title
                  _buildAnimatedHeader(),
                  
                  const SizedBox(height: AppTheme.spaceXLarge * 1.5),
                  
                  // PRIMARY ACTION: Start Service (Full Width, Dominant)
                  _buildAnimatedButton(
                    context: context,
                    index: 0,
                    icon: Icons.play_circle_filled,
                    label: 'Start Service',
                    gradient: AppTheme.successGradient,
                    isPrimary: true,
                    onPressed: () {
                      serviceProvider.startService();
                      Navigator.push(
                        context,
                        _createRoute(const ServiceScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spaceLarge),
                  
                  // SECONDARY ACTIONS: Side by Side Buttons
                  Row(
                    children: [
                      // History Button
                      Expanded(
                        child: _buildAnimatedButton(
                          context: context,
                          index: 1,
                          icon: Icons.history,
                          label: 'History',
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                          ),
                          isPrimary: false,
                          isCompact: true,
                          onPressed: () => _showShiftHistory(context),
                        ),
                      ),
                      
                      const SizedBox(width: AppTheme.spaceMedium),
                      
                      // Manage Dishes Button
                      Expanded(
                        child: _buildAnimatedButton(
                          context: context,
                          index: 2,
                          icon: Icons.restaurant,
                          label: 'Manage Dishes',
                          gradient: AppTheme.accentGradient,
                          isPrimary: false,
                          isCompact: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              _createRoute(const DishManagementScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spaceXLarge),
                  
                  // Animated Statistics Card
                  if (serviceProvider.shiftHistory.isNotEmpty)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStatisticsCard(serviceProvider),
                    ),
                  
                  const SizedBox(height: AppTheme.spaceLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Animated Restaurant Icon with Glow
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.offWhite.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(
                  color: AppTheme.goldenOrange.withOpacity(0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldenOrange.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (0.05 * (value < 0.5 ? value * 2 : (1 - value) * 2)),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: AppTheme.goldenOrange,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          
          // App Title with Shimmer Effect
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                AppTheme.offWhite,
                AppTheme.goldenOrange,
                AppTheme.offWhite,
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: const Text(
              'Restaurant Profit',
              textAlign: TextAlign.center,
              style: AppTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'TRACKER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: AppTheme.goldenOrange,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 100.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Container(
                height: 2,
                width: value,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedButton({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        final delay = index * 0.15;
        final progress = (_buttonsController.value - delay).clamp(0.0, 1.0);
        
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: _buildActionButton(
        context: context,
        icon: icon,
        label: label,
        gradient: gradient,
        onPressed: onPressed,
        isPrimary: isPrimary,
        isCompact: isCompact,
      ),
    );
  }
  
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    final double buttonHeight = isPrimary ? 72.0 : (isCompact ? 120.0 : 64.0);
    final double iconSize = isPrimary ? 36.0 : (isCompact ? 28.0 : 32.0);
    final double fontSize = isPrimary ? 22.0 : (isCompact ? 16.0 : 20.0);
    final double elevationValue = isPrimary ? 10.0 : 6.0;
    
    return Material(
      elevation: elevationValue,
      shadowColor: AppTheme.darkBrown.withOpacity(0.4),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Container(
            height: buttonHeight,
            padding: EdgeInsets.symmetric(
              horizontal: isPrimary ? AppTheme.spaceLarge : AppTheme.spaceMedium,
              vertical: isPrimary ? 20 : (isCompact ? AppTheme.spaceMedium : 16),
            ),
            child: isCompact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.offWhite.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: iconSize, color: AppTheme.offWhite),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.offWhite,
                          letterSpacing: 0.3,
                          shadows: const [
                            Shadow(
                              color: Color(0x40000000),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'button_${label}_icon',
                        child: Container(
                          padding: EdgeInsets.all(isPrimary ? 14 : 12),
                          decoration: BoxDecoration(
                            color: AppTheme.offWhite.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: iconSize, color: AppTheme.offWhite),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMedium),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.offWhite,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(
                                color: Color(0x40000000),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
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
  
  Widget _buildStatisticsCard(ServiceProvider serviceProvider) {
    final totalShifts = serviceProvider.shiftHistory.length;
    final totalRevenue = serviceProvider.shiftHistory.fold(
      0.0,
      (sum, shift) => sum + shift.totalProfit,
    );
    final avgRevenue = totalRevenue / totalShifts;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
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
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: AppTheme.goldenOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Quick Stats',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.bordeauxRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warmGray.withOpacity(0.1),
                  AppTheme.warmGray.withOpacity(0.5),
                  AppTheme.warmGray.withOpacity(0.1),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildStatItem(
                  'Total Shifts',
                  '$totalShifts',
                  Icons.calendar_today,
                  AppTheme.bordeauxRed,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.warmGray.withOpacity(0.3),
              ),
              Flexible(
                child: _buildStatItem(
                  'Total Revenue',
                  'Dt${totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  AppTheme.freshGreen,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.warmGray.withOpacity(0.3),
              ),
              Flexible(
                child: _buildStatItem(
                  'Avg/Shift',
                  'Dt${avgRevenue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  AppTheme.goldenOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.darkBrown.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Custom page route with slide transition
  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
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
      final partsA = a.split('/').map(int.parse).toList();
      final partsB = b.split('/').map(int.parse).toList();
      final dateA = DateTime(partsA[2], partsA[1], partsA[0]);
      final dateB = DateTime(partsB[2], partsB[1], partsB[0]);
      return dateB.compareTo(dateA);
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusLarge),
                    topRight: Radius.circular(AppTheme.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: AppTheme.goldenOrange,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    const Expanded(
                      child: Text(
                        'Shift History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.offWhite,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.offWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: serviceProvider.shiftHistory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppTheme.spaceXLarge),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: AppTheme.warmGray,
                            ),
                            SizedBox(height: AppTheme.spaceMedium),
                            Text(
                              'No shift history yet',
                              style: AppTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(AppTheme.spaceMedium),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final shifts = groupedShifts[date]!;
                          final dailyTotal = shifts.fold(0.0, (sum, s) => sum + s.totalProfit);
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceMedium,
                                  vertical: AppTheme.spaceSmall,
                                ),
                                margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.offWhite,
                                      ),
                                    ),
                                    Text(
                                      'Daily: Dt${dailyTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppTheme.goldenOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Shifts for this date
                              ...shifts.reversed.map((shift) => Card(
                                margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  side: BorderSide(
                                    color: AppTheme.freshGreen.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.freshGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.freshGreen,
                                    ),
                                  ),
                                  title: Text(
                                    'Dt${shift.totalProfit.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.freshGreen,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${_formatTime(shift.startTime)} - ${shift.endTime != null ? _formatTime(shift.endTime!) : "Active"}',
                                    style: TextStyle(
                                      color: AppTheme.darkBrown.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              )),
                              
                              const SizedBox(height: AppTheme.spaceMedium),
                            ],
                          );
                        },
                      ),
              ),
              
              // Actions
              if (serviceProvider.shiftHistory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.warmGray.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusLarge),
                      bottomRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            serviceProvider.clearHistory();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear History'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.bordeauxRed,
                            side: const BorderSide(color: AppTheme.bordeauxRed),
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
