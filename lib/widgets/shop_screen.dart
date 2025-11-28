// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartspend/services/theme_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService theme = ThemeService();

    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.bgTop, theme.bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: theme.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Shop Partners",
                          style: TextStyle(
                            color: theme.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(24),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildShopCard(
                          "Shopee",
                          "https://shopee.ph",
                          Icons.shopping_bag,
                          Colors.orange,
                          theme,
                        ),
                        _buildShopCard(
                          "Lazada",
                          "https://www.lazada.com.ph",
                          Icons.favorite,
                          Colors.blueAccent,
                          theme,
                        ),
                        _buildShopCard(
                          "Amazon",
                          "https://www.amazon.com",
                          Icons.local_shipping,
                          Colors.black87,
                          theme,
                        ),
                        _buildShopCard(
                          "Zalora",
                          "https://www.zalora.com.ph",
                          Icons.checkroom,
                          Colors.black,
                          theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopCard(
    String name,
    String url,
    IconData icon,
    Color color,
    ThemeService theme,
  ) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        // Try to launch (external app mode helps open the actual app if installed)
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          debugPrint("Could not launch $url");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: theme.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Tap to open",
              style: TextStyle(color: theme.textSub, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
