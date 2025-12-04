import 'package:flutter/material.dart';

// =============================================================================
// PALETA DE CORES DO TRACK HABITS
// =============================================================================
// Baseada na identidade visual Emerald/Verde-esmeralda
// Gerada com Material Theme Builder + customizações manuais

// Cor semente do app (Emerald - identidade visual)
const Color _seedColor = Color(0xFF059669);

// =============================================================================
// TEMA CLARO - ColorScheme personalizado
// =============================================================================
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,

  // Cores primárias (Emerald)
  primary: Color(0xFF059669), // Emerald principal
  onPrimary: Color(0xFFFFFFFF), // Branco para contraste
  primaryContainer: Color(0xFFA7F3D0), // Emerald claro
  onPrimaryContainer: Color(0xFF00513A), // Emerald escuro

  // Cores secundárias (Indigo para complementar)
  secondary: Color(0xFF4F46E5), // Indigo
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE0E7FF), // Indigo claro
  onSecondaryContainer: Color(0xFF312E81), // Indigo escuro

  // Cores terciárias (Amber para acentos)
  tertiary: Color(0xFFD97706), // Amber
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFEF3C7), // Amber claro
  onTertiaryContainer: Color(0xFF78350F), // Amber escuro

  // Superfícies
  surface: Color(0xFFFAFAFA), // Cinza muito claro
  onSurface: Color(0xFF0F172A), // Slate escuro (texto principal)
  surfaceContainerHighest: Color(0xFFE2E8F0), // Slate 200
  onSurfaceVariant: Color(0xFF475569), // Slate 600

  // Erro
  error: Color(0xFFDC2626), // Red 600
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFEE2E2), // Red 100
  onErrorContainer: Color(0xFF7F1D1D), // Red 900

  // Outros
  outline: Color(0xFFCBD5E1), // Slate 300
  outlineVariant: Color(0xFFE2E8F0), // Slate 200
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1E293B), // Slate 800
  onInverseSurface: Color(0xFFF1F5F9), // Slate 100
  inversePrimary: Color(0xFF6EE7B7), // Emerald 300
  surfaceTint: Color(0xFF059669),
);

// =============================================================================
// TEMA ESCURO - ColorScheme personalizado
// =============================================================================
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,

  // Cores primárias (Emerald - versão clara para dark mode)
  primary: Color(0xFF6EE7B7), // Emerald 300
  onPrimary: Color(0xFF00382A), // Emerald muito escuro
  primaryContainer: Color(0xFF047857), // Emerald 700
  onPrimaryContainer: Color(0xFFA7F3D0), // Emerald 200

  // Cores secundárias (Indigo)
  secondary: Color(0xFFA5B4FC), // Indigo 300
  onSecondary: Color(0xFF1E1B4B), // Indigo 950
  secondaryContainer: Color(0xFF4338CA), // Indigo 700
  onSecondaryContainer: Color(0xFFE0E7FF), // Indigo 100

  // Cores terciárias (Amber)
  tertiary: Color(0xFFFCD34D), // Amber 300
  onTertiary: Color(0xFF451A03), // Amber 950
  tertiaryContainer: Color(0xFFB45309), // Amber 700
  onTertiaryContainer: Color(0xFFFEF3C7), // Amber 100

  // Superfícies (escuras)
  surface: Color(0xFF0F172A), // Slate 900
  onSurface: Color(0xFFF1F5F9), // Slate 100 (texto principal)
  surfaceContainerHighest: Color(0xFF334155), // Slate 700
  onSurfaceVariant: Color(0xFFCBD5E1), // Slate 300

  // Erro
  error: Color(0xFFFCA5A5), // Red 300
  onError: Color(0xFF450A0A), // Red 950
  errorContainer: Color(0xFFB91C1C), // Red 700
  onErrorContainer: Color(0xFFFEE2E2), // Red 100

  // Outros
  outline: Color(0xFF475569), // Slate 600
  outlineVariant: Color(0xFF334155), // Slate 700
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFF1F5F9), // Slate 100
  onInverseSurface: Color(0xFF1E293B), // Slate 800
  inversePrimary: Color(0xFF059669), // Emerald 600
  surfaceTint: Color(0xFF6EE7B7),
);

// =============================================================================
// ALTERNATIVA: Usar fromSeed e customizar apenas o necessário
// =============================================================================
// Se preferir a abordagem híbrida, descomente abaixo e comente acima:
//
// final ColorScheme lightColorScheme = ColorScheme.fromSeed(
//   seedColor: _seedColor,
//   brightness: Brightness.light,
// ).copyWith(
//   secondary: const Color(0xFF4F46E5),  // Customizar secondary
//   tertiary: const Color(0xFFD97706),   // Customizar tertiary
// );
//
// final ColorScheme darkColorScheme = ColorScheme.fromSeed(
//   seedColor: _seedColor,
//   brightness: Brightness.dark,
// ).copyWith(
//   secondary: const Color(0xFFA5B4FC),
//   tertiary: const Color(0xFFFCD34D),
// );
