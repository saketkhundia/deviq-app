import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

/// Playground language catalog. Mirrors the web product.
class PlaygroundLanguage {
  const PlaygroundLanguage({
    required this.id,
    required this.label,
    required this.extension,
    required this.defaultFile,
    required this.template,
    this.highlightId,
  });

  final String id;
  final String label;
  final String extension;
  final String defaultFile;
  final String template;
  final String? highlightId;
}

class PlaygroundLanguages {
  const PlaygroundLanguages._();

  static const List<PlaygroundLanguage> all = [
    PlaygroundLanguage(
      id: 'javascript',
      label: 'JavaScript',
      extension: 'js',
      defaultFile: 'main.js',
      highlightId: 'javascript',
      template:
          '// Write JavaScript directly in DevIQ\n'
          'console.log("Hello from DevIQ Playground!");\n'
          '\n'
          'function fibonacci(n) {\n'
          '  if (n <= 1) return n;\n'
          '  return fibonacci(n - 1) + fibonacci(n - 2);\n'
          '}\n'
          '\n'
          'for (let i = 0; i < 8; i++) {\n'
          '  console.log(`fib(\${i}) = \${fibonacci(i)}`);\n'
          '}\n',
    ),
    PlaygroundLanguage(
      id: 'typescript',
      label: 'TypeScript',
      extension: 'ts',
      defaultFile: 'main.ts',
      highlightId: 'typescript',
      template:
          'function greet(name: string): void {\n'
          '  console.log(`Hello, \${name}!`);\n'
          '}\n\ngreet("DevIQ");\n',
    ),
    PlaygroundLanguage(
      id: 'python',
      label: 'Python',
      extension: 'py',
      defaultFile: 'main.py',
      highlightId: 'python',
      template:
          'def greet(name: str) -> None:\n'
          '    print(f"Hello, {name}!")\n\n'
          'greet("DevIQ")\n',
    ),
    PlaygroundLanguage(
      id: 'java',
      label: 'Java',
      extension: 'java',
      defaultFile: 'Main.java',
      highlightId: 'java',
      template:
          'public class Main {\n'
          '    public static void main(String[] args) {\n'
          '        System.out.println("Hello, DevIQ!");\n'
          '    }\n'
          '}\n',
    ),
    PlaygroundLanguage(
      id: 'c',
      label: 'C',
      extension: 'c',
      defaultFile: 'main.c',
      highlightId: 'c',
      template:
          '#include <stdio.h>\n\nint main(void) {\n'
          '    printf("Hello, DevIQ!\\n");\n'
          '    return 0;\n}\n',
    ),
    PlaygroundLanguage(
      id: 'cpp',
      label: 'C++',
      extension: 'cpp',
      defaultFile: 'main.cpp',
      highlightId: 'cpp',
      template:
          '#include <iostream>\n\nint main() {\n'
          '    std::cout << "Hello, DevIQ!" << std::endl;\n'
          '    return 0;\n}\n',
    ),
    PlaygroundLanguage(
      id: 'go',
      label: 'Go',
      extension: 'go',
      defaultFile: 'main.go',
      highlightId: 'go',
      template:
          'package main\n\nimport "fmt"\n\nfunc main() {\n'
          '    fmt.Println("Hello, DevIQ!")\n}\n',
    ),
    PlaygroundLanguage(
      id: 'rust',
      label: 'Rust',
      extension: 'rs',
      defaultFile: 'main.rs',
      highlightId: 'rust',
      template: 'fn main() {\n    println!("Hello, DevIQ!");\n}\n',
    ),
    PlaygroundLanguage(
      id: 'ruby',
      label: 'Ruby',
      extension: 'rb',
      defaultFile: 'main.rb',
      highlightId: 'ruby',
      template: 'puts "Hello, DevIQ!"\n',
    ),
    PlaygroundLanguage(
      id: 'csharp',
      label: 'C#',
      extension: 'cs',
      defaultFile: 'Program.cs',
      highlightId: 'csharp',
      template:
          'using System;\n\nclass Program {\n'
          '    static void Main() {\n'
          '        Console.WriteLine("Hello, DevIQ!");\n'
          '    }\n}\n',
    ),
    PlaygroundLanguage(
      id: 'kotlin',
      label: 'Kotlin',
      extension: 'kt',
      defaultFile: 'Main.kt',
      highlightId: 'kotlin',
      template: 'fun main() {\n    println("Hello, DevIQ!")\n}\n',
    ),
  ];

  static PlaygroundLanguage byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);
}

/// Interview-prep company catalog matching the web reference (28
/// companies, FAANG / Top / Mid tiers). Logos pair a Simple Icons brand
/// glyph with its brand tile color; companies without a bundled glyph
/// fall back to a letter tile in brand colors.
class PrepCompany {
  const PrepCompany({
    required this.slug,
    required this.name,
    required this.tier,
    this.icon,
    required this.tile,
    required this.onTile,
    this.letters = '',
  });

  final String slug;
  final String name;

  /// FAANG | Top | Mid (short captions used on cards).
  final String tier;

  /// Simple Icons glyph, or null for a letter tile.
  final IconData? icon;

  /// Logo tile background / glyph-or-letter foreground.
  final Color tile;
  final Color onTile;

  /// 1–2 letters when [icon] is null (or as fallback).
  final String letters;

  /// Bundled original logo asset (`assets/logos/<slug>.png`).
  String get logoAsset => 'assets/logos/$slug.png';
}

PrepCompany _prepCompany(
  String slug,
  String name,
  String tier, {
  IconData? icon,
  required Color tile,
  required Color onTile,
  String letters = '',
}) => PrepCompany(
  slug: slug,
  name: name,
  tier: tier,
  icon: icon,
  tile: tile,
  onTile: onTile,
  letters: letters.isEmpty ? name.substring(0, 1).toUpperCase() : letters,
);

class PrepCompanies {
  const PrepCompanies._();

  static final List<PrepCompany> all = [
    _prepCompany(
      'google',
      'Google',
      'FAANG',
      icon: SimpleIcons.google,
      tile: const Color(0xFFFFFFFF),
      onTile: const Color(0xFF4285F4),
      letters: 'G',
    ),
    _prepCompany(
      'amazon',
      'Amazon',
      'FAANG',
      tile: const Color(0xFFFF9900),
      onTile: const Color(0xFF000000),
      letters: 'a',
    ),
    _prepCompany(
      'meta',
      'Meta',
      'FAANG',
      icon: SimpleIcons.meta,
      tile: const Color(0xFF0467DF),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'apple',
      'Apple',
      'FAANG',
      icon: SimpleIcons.apple,
      tile: const Color(0xFF000000),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'netflix',
      'Netflix',
      'FAANG',
      icon: SimpleIcons.netflix,
      tile: const Color(0xFFE50914),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'microsoft',
      'Microsoft',
      'FAANG',
      tile: const Color(0xFF00A4EF),
      onTile: const Color(0xFFFFFFFF),
      letters: 'M',
    ),
    _prepCompany(
      'bloomberg',
      'Bloomberg',
      'Top',
      tile: const Color(0xFF2800D7),
      onTile: const Color(0xFFFFFFFF),
      letters: 'B',
    ),
    _prepCompany(
      'goldman-sachs',
      'Goldman Sachs',
      'Top',
      tile: const Color(0xFF2E5EAA),
      onTile: const Color(0xFFFFFFFF),
      letters: 'GS',
    ),
    _prepCompany(
      'uber',
      'Uber',
      'Top',
      icon: SimpleIcons.uber,
      tile: const Color(0xFF000000),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'linkedin',
      'LinkedIn',
      'Top',
      tile: const Color(0xFF0A66C2),
      onTile: const Color(0xFFFFFFFF),
      letters: 'in',
    ),
    _prepCompany(
      'adobe',
      'Adobe',
      'Top',
      tile: const Color(0xFFFA0F00),
      onTile: const Color(0xFFFFFFFF),
      letters: 'A',
    ),
    _prepCompany(
      'oracle',
      'Oracle',
      'Top',
      tile: const Color(0xFFC74634),
      onTile: const Color(0xFFFFFFFF),
      letters: 'O',
    ),
    _prepCompany(
      'salesforce',
      'Salesforce',
      'Top',
      tile: const Color(0xFF00A1E0),
      onTile: const Color(0xFFFFFFFF),
      letters: 'S',
    ),
    _prepCompany(
      'twitter',
      'Twitter',
      'Top',
      tile: const Color(0xFF1D9BF0),
      onTile: const Color(0xFFFFFFFF),
      letters: 'T',
    ),
    _prepCompany(
      'spotify',
      'Spotify',
      'Mid',
      icon: SimpleIcons.spotify,
      tile: const Color(0xFF1ED760),
      onTile: const Color(0xFF000000),
    ),
    _prepCompany(
      'stripe',
      'Stripe',
      'Mid',
      icon: SimpleIcons.stripe,
      tile: const Color(0xFF635BFF),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'airbnb',
      'Airbnb',
      'Mid',
      icon: SimpleIcons.airbnb,
      tile: const Color(0xFFFF5A5F),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'snap',
      'Snap',
      'Mid',
      icon: SimpleIcons.snapchat,
      tile: const Color(0xFFFFFC00),
      onTile: const Color(0xFF000000),
    ),
    _prepCompany(
      'tiktok',
      'TikTok',
      'Mid',
      icon: SimpleIcons.tiktok,
      tile: const Color(0xFF000000),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'nvidia',
      'Nvidia',
      'Mid',
      icon: SimpleIcons.nvidia,
      tile: const Color(0xFF76B900),
      onTile: const Color(0xFF000000),
    ),
    _prepCompany(
      'paypal',
      'PayPal',
      'Mid',
      icon: SimpleIcons.paypal,
      tile: const Color(0xFF002991),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'cisco',
      'Cisco',
      'Mid',
      icon: SimpleIcons.cisco,
      tile: const Color(0xFF1BA0D7),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'vmware',
      'VMware',
      'Mid',
      icon: SimpleIcons.vmware,
      tile: const Color(0xFF607078),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'walmart',
      'Walmart',
      'Mid',
      tile: const Color(0xFF0071CE),
      onTile: const Color(0xFFFFFFFF),
      letters: 'W',
    ),
    _prepCompany(
      'jpmorgan',
      'JPMorgan',
      'Mid',
      tile: const Color(0xFF126BC1),
      onTile: const Color(0xFFFFFFFF),
      letters: 'J',
    ),
    _prepCompany(
      'samsung',
      'Samsung',
      'Mid',
      icon: SimpleIcons.samsung,
      tile: const Color(0xFF1428A0),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'intuit',
      'Intuit',
      'Mid',
      icon: SimpleIcons.intuit,
      tile: const Color(0xFF236CFF),
      onTile: const Color(0xFFFFFFFF),
    ),
    _prepCompany(
      'yahoo',
      'Yahoo',
      'Mid',
      tile: const Color(0xFF6001D2),
      onTile: const Color(0xFFFFFFFF),
      letters: 'Y',
    ),
  ];

  static PrepCompany bySlug(String slug) =>
      all.firstWhere((e) => e.slug == slug, orElse: () => all.first);
}
