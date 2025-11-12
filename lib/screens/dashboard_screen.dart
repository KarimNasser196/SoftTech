import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/screens/manage_categories_screen.dart';
import '../providers/product_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/responsive.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: Responsive.paddingAll(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ' مرحبًا بك في SoftTech لإدارة المخازن والصيانة.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.font(32),
                  color: Colors.grey),
            ),
            Responsive.vBox(24),
            Text(
              'الخيارات السريعة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: Responsive.font(24),
                  ),
            ),
            Responsive.vBox(16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5, // أو 5 إذا أردت صف واحد
              crossAxisSpacing: Responsive.width(24),
              mainAxisSpacing: Responsive.height(24),
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionCard(
                  context,
                  'إضافة منتج',
                  Icons.add_circle,
                  Colors.blue,
                  () => _navigateToScreen(context, 1),
                ),
                _buildQuickActionCard(
                  context,
                  'تسجيل بيع',
                  Icons.shopping_cart,
                  Colors.green,
                  () => _navigateToScreen(context, 2),
                ),
                _buildQuickActionCard(
                  context,
                  'المرتجعات',
                  Icons.reply,
                  Colors.orange,
                  () => _navigateToScreen(context, 3),
                ),
                _buildQuickActionCard(
                  context,
                  'التقارير',
                  Icons.bar_chart,
                  Colors.purple,
                  () => _navigateToScreen(context, 4),
                ),
                _buildQuickActionCard(
                  context,
                  'الصيانة',
                  Icons.build_circle,
                  Colors.red,
                  () => _navigateToScreen(context, 5),
                ),
                _buildQuickActionCard(
                  context,
                  'المندوبين والعملاء',
                  Icons.people,
                  Colors.indigo,
                  () => _navigateToScreen(context, 6),
                ),
                _buildQuickActionCard(
                  // ⭐ جديد
                  context,
                  'تقارير الموردين',
                  Icons.assessment,
                  Colors.orange,
                  () => _navigateToScreen(context, 7), // ⭐ الـ index 7
                ),
                _buildQuickActionCard(
                  context,
                  'إدارة البيانات',
                  Icons.settings_applications,
                  Colors.teal,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesScreen(),
                    ),
                  ),
                ),
                _buildQuickActionCard(
                  context,
                  'الملاحظات',
                  Icons.note_alt,
                  Colors.amber,
                  () => _navigateToScreen(context, 8),
                ),
              ],
            ),
            Responsive.vBox(32),
            Text(
              'الملخص الإحصائي',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: Responsive.font(24),
                  ),
            ),
            Responsive.vBox(16),
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: Responsive.height(24),
                  crossAxisSpacing: Responsive.width(24),
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatTile(
                      'المنتجات',
                      '${provider.totalProducts}',
                      Colors.blue,
                    ),
                    _buildStatTile(
                      'الكميات',
                      '${provider.totalQuantityInStock}',
                      Colors.green,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        child: Padding(
          padding: Responsive.paddingAll(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Responsive.icon(48),
                color: color,
              ),
              Responsive.vBox(12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.font(18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Padding(
        padding: Responsive.paddingAll(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.font(14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Responsive.vBox(8),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.font(20),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Provider.of<NavigationProvider>(
      context,
      listen: false,
    ).setSelectedIndex(index);
  }
}
