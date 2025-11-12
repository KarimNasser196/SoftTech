// lib/screens/home_screen.dart (Desktop Only - Responsive)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundtry/screens/maintenance_screen.dart';
import 'package:soundtry/screens/notes_screen.dart';
import 'package:soundtry/screens/products_list_screen_improved.dart';
import 'package:soundtry/screens/setting_screen.dart';
import 'package:soundtry/screens/representatives_screen.dart';
import 'package:soundtry/screens/suppliers_report_screen.dart';
import '../providers/navigation_provider.dart';
import '../utils/responsive.dart';

import 'sell_product_screen.dart';
import 'return_product_screen.dart';
import 'reports_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final navigationProvider = Provider.of<NavigationProvider>(context);

    final List<Widget> screens = [
      const DashboardScreen(),
      const ProductsListScreenUpdated(),
      const SellProductScreen(),
      const ReturnProductScreen(),
      const ReportsScreen(),
      const MaintenanceScreen(),
      const RepresentativesScreen(),
      const SuppliersReportScreen(),
      const NotesScreen(), // ⭐ أضف هذا
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // العنوان الرئيسي في الوسط
            Expanded(
              child: Center(
                child: Text(
                  'SoftTech',
                  style: TextStyle(
                    fontSize: Responsive.font(30),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),

            Text(
              'هذا البرنامج مرخّص لصالح شركة رياض سوفت.',
              style: TextStyle(
                fontSize: 12, // حجم صغير
                fontWeight: FontWeight.w400,
                color: Colors.white70,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // NavigationRail للـ Desktop
          NavigationRail(
            selectedIndex: navigationProvider.selectedIndex,
            onDestinationSelected: (index) {
              navigationProvider.setSelectedIndex(index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).cardColor,
            elevation: 4,
            minWidth: Responsive.width(80),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.home_filled, size: Responsive.icon(24)),
                label: Text('الرئيسية',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.inventory_2, size: Responsive.icon(24)),
                label: Text('المنتجات',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sell, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.sell_outlined, size: Responsive.icon(24)),
                label: Text('بيع',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_return, size: Responsive.icon(24)),
                selectedIcon: Icon(Icons.assignment_return_outlined,
                    size: Responsive.icon(24)),
                label: Text('استرجاع',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.bar_chart_outlined, size: Responsive.icon(24)),
                label: Text('التقارير',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.build_circle, size: Responsive.icon(24)),
                label: Text('الصيانة',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people, size: Responsive.icon(24)),
                selectedIcon: Icon(Icons.people_alt, size: Responsive.icon(24)),
                label: Text('المندوبين',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                // ⭐ جديد
                icon: Icon(Icons.assessment, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.assessment_outlined, size: Responsive.icon(24)),
                label: Text('تقارير الموردين',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.note_alt, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.note_alt_outlined, size: Responsive.icon(24)),
                label: Text('الملاحظات',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings, size: Responsive.icon(24)),
                selectedIcon:
                    Icon(Icons.settings_outlined, size: Responsive.icon(24)),
                label: Text('الإعدادات',
                    style: TextStyle(fontSize: Responsive.font(12))),
              ),
            ],
          ),

          // خط فاصل
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),

          // المحتوى الرئيسي
          Expanded(
            child: Builder(
              builder: (context) {
                try {
                  final index = navigationProvider.selectedIndex;
                  if (index < 0 || index >= screens.length) {
                    return Center(
                      child: Text(
                        'صفحة غير متاحة',
                        style: TextStyle(fontSize: Responsive.font(18)),
                      ),
                    );
                  }
                  return screens[index];
                } catch (e, stackTrace) {
                  debugPrint('Error rendering screen: $e\n$stackTrace');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: Responsive.icon(64),
                          color: Colors.red,
                        ),
                        Responsive.vBox(16),
                        Text(
                          'خطأ في تحميل الصفحة',
                          style: TextStyle(
                            fontSize: Responsive.font(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Responsive.vBox(8),
                        Text(
                          '$e',
                          style: TextStyle(
                            fontSize: Responsive.font(14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
