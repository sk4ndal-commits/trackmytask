import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackmytasks/services/theme_service.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return IconButton(
      icon: Icon(
        themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      tooltip: themeService.isDarkMode
          ? 'Switch to light mode'
          : 'Switch to dark mode',
      onPressed: () {
        themeService.toggleTheme();
      },
    );
  }
}