import 'package:flutter/material.dart';
import 'package:smartspend/widgets/settings.dart';
import 'package:smartspend/services/theme_service.dart';
import 'package:smartspend/widgets/export_screen.dart'; // ✅ Import Export Screen

class MainMenuDrawer extends StatelessWidget {
  const MainMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [themeService.bgTop, themeService.bgBottom],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: themeService.primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeService.cardBg,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeService.primaryBlue.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: themeService.primaryBlue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "SmartSpend",
                    style: TextStyle(
                      color: themeService.textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "v1.0.0 - Free",
                    style: TextStyle(color: themeService.textSub, fontSize: 14),
                  ),
                ],
              ),
            ),

            // --- Menu Items ---
            _buildMenuItem(
              Icons.settings_rounded,
              "Preferences",
              themeService.textMain,
              themeService.primaryBlue,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(color: themeService.primaryBlue.withOpacity(0.1)),
            ),

            // Management
            _buildSectionTitle("Management", themeService.primaryBlue),

            // ✅ EXPORT RECORDS (Linked here!)
            _buildMenuItem(
              Icons.file_download_outlined,
              "Export records",
              themeService.textMain,
              themeService.primaryBlue,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              },
            ),

            _buildMenuItem(
              Icons.save_outlined,
              "Backup & Restore",
              themeService.textMain,
              themeService.primaryBlue,
              () {},
            ),
            _buildMenuItem(
              Icons.delete_outline,
              "Delete & Reset",
              Colors.redAccent,
              Colors.redAccent,
              () {},
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(color: themeService.primaryBlue.withOpacity(0.1)),
            ),

            // Application
            _buildSectionTitle("Application", themeService.primaryBlue),
            _buildMenuItem(
              Icons.thumb_up_outlined,
              "Like SmartSpend",
              themeService.textMain,
              themeService.primaryBlue,
              () {},
            ),
            _buildMenuItem(
              Icons.help_outline,
              "Help",
              themeService.textMain,
              themeService.primaryBlue,
              () {},
            ),
            _buildMenuItem(
              Icons.feedback_outlined,
              "Feedback",
              themeService.textMain,
              themeService.primaryBlue,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color textColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      dense: true,
    );
  }
}
