import 'package:flutter/material.dart';
import 'package:smartspend/services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  bool _remindEveryday = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_themeService.bgTop, _themeService.bgBottom],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _themeService.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    _themeService.isDarkMode ? 0.3 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: _themeService.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Preferences",
                          style: TextStyle(
                            color: _themeService.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Settings List ---
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 10),

                        // --- APPEARANCE (Keep) ---
                        _buildSectionHeader("APPEARANCE"),

                        _buildTile(
                          icon: Icons.smartphone_rounded,
                          title: "UI mode",
                          subtitle: _themeService.currentThemeString,
                          onTap: () => _showRadioDialog(
                            "UI mode",
                            ["Light", "Dark", "System default"],
                            _themeService.currentThemeString,
                            (val) => _themeService.setThemeMode(val),
                          ),
                        ),

                        _buildTile(
                          icon: Icons.attach_money_rounded,
                          title: "Currency sign",
                          subtitle: _themeService.currencyName,
                          onTap: () => _showCurrencyDialog(),
                        ),

                        _buildTile(
                          icon: Icons.format_align_left_rounded,
                          title: "Currency position",
                          subtitle: _themeService.currencyPosition,
                          onTap: () => _showRadioDialog(
                            "Currency position",
                            [
                              "At start of amount",
                              "At end of amount",
                              "Do not use currency sign",
                            ],
                            _themeService.currencyPosition,
                            (val) => _themeService.setCurrencyPosition(val),
                          ),
                        ),
                        _buildTile(
                          icon: Icons.onetwothree,
                          title: "Decimal places",
                          subtitle:
                              "${_themeService.decimalPlaces} (eg. 10.${'45'.substring(0, _themeService.decimalPlaces.clamp(0, 2))})",
                          onTap: () => _showDecimalDialog(),
                        ),

                        const SizedBox(height: 24),

                        // --- NOTIFICATION (Keep) ---
                        _buildSectionHeader("NOTIFICATION"),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _themeService.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _themeService.primaryBlue.withOpacity(
                                  0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: _buildIconContainer(
                                Icons.notifications_active_rounded,
                              ),
                              title: Text(
                                "Remind everyday",
                                style: TextStyle(
                                  color: _themeService.textMain,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Remember to manage your money today!",
                                  style: TextStyle(
                                    color: _themeService.textSub,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _remindEveryday,
                                  activeColor: Colors.white,
                                  activeTrackColor: _themeService.primaryBlue,
                                  inactiveThumbColor: Colors.grey.shade400,
                                  inactiveTrackColor: Colors.grey.shade700,
                                  onChanged: (bool value) =>
                                      setState(() => _remindEveryday = value),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildTile(
                          icon: Icons.settings_suggest_rounded,
                          title: "Notification settings",
                          subtitle: null,
                          onTap: () {},
                        ),

                        // --- REMOVED MANAGEMENT & APPLICATION SECTIONS ---
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

  // --- Helpers ---
  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _themeService.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _themeService.primaryBlue, size: 24),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: _themeService.primaryBlue,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              _themeService.isDarkMode ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: _buildIconContainer(icon),
        title: Text(
          title,
          style: TextStyle(
            color: _themeService.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: TextStyle(color: _themeService.textSub, fontSize: 13),
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showRadioDialog(
    String title,
    List<String> options,
    String currentVal,
    Function(String) onSelect,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themeService.isDarkMode
              ? const Color(0xFF122545)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: _themeService.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(
                  option,
                  style: TextStyle(
                    color: _themeService.isDarkMode
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
                value: option,
                groupValue: currentVal,
                activeColor: _themeService.primaryBlue,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    onSelect(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(
                  color: _themeService.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDecimalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themeService.isDarkMode
              ? const Color(0xFF122545)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Decimal places",
            style: TextStyle(
              color: _themeService.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadio("0 (eg. 10)", 0),
              _buildRadio("1 (eg. 10.1)", 1),
              _buildRadio("2 (eg. 10.45)", 2),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(
                  color: _themeService.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadio(String title, int val) {
    return RadioListTile<int>(
      title: Text(
        title,
        style: TextStyle(
          color: _themeService.isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      value: val,
      groupValue: _themeService.decimalPlaces,
      activeColor: _themeService.primaryBlue,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        if (value != null) {
          _themeService.setDecimalPlaces(value);
          Navigator.pop(context);
        }
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themeService.isDarkMode
              ? const Color(0xFF122545)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Currency sign",
            style: TextStyle(
              color: _themeService.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _themeService.currencies.length,
              itemBuilder: (context, index) {
                final currency = _themeService.currencies[index];
                return RadioListTile<String>(
                  title: Text(
                    currency['name']!,
                    style: TextStyle(
                      color: _themeService.isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                  secondary: Text(
                    currency['symbol']!,
                    style: TextStyle(
                      color: _themeService.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  value: currency['name']!,
                  groupValue: _themeService.currencyName,
                  activeColor: _themeService.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    if (value != null) {
                      _themeService.setCurrency(
                        currency['name']!,
                        currency['symbol']!,
                      );
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(
                  color: _themeService.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
