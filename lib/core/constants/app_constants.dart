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
      template: 'console.log("Hello, DevIQ!");\n',
    ),
    PlaygroundLanguage(
      id: 'typescript',
      label: 'TypeScript',
      extension: 'ts',
      defaultFile: 'main.ts',
      highlightId: 'typescript',
      template: 'function greet(name: string): void {\n'
          '  console.log(`Hello, \${name}!`);\n'
          '}\n\ngreet("DevIQ");\n',
    ),
    PlaygroundLanguage(
      id: 'python',
      label: 'Python',
      extension: 'py',
      defaultFile: 'main.py',
      highlightId: 'python',
      template: 'def greet(name: str) -> None:\n'
          '    print(f"Hello, {name}!")\n\n'
          'greet("DevIQ")\n',
    ),
    PlaygroundLanguage(
      id: 'java',
      label: 'Java',
      extension: 'java',
      defaultFile: 'Main.java',
      highlightId: 'java',
      template: 'public class Main {\n'
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
      template: '#include <stdio.h>\n\nint main(void) {\n'
          '    printf("Hello, DevIQ!\\n");\n'
          '    return 0;\n}\n',
    ),
    PlaygroundLanguage(
      id: 'cpp',
      label: 'C++',
      extension: 'cpp',
      defaultFile: 'main.cpp',
      highlightId: 'cpp',
      template: '#include <iostream>\n\nint main() {\n'
          '    std::cout << "Hello, DevIQ!" << std::endl;\n'
          '    return 0;\n}\n',
    ),
    PlaygroundLanguage(
      id: 'go',
      label: 'Go',
      extension: 'go',
      defaultFile: 'main.go',
      highlightId: 'go',
      template: 'package main\n\nimport "fmt"\n\nfunc main() {\n'
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
      template: 'using System;\n\nclass Program {\n'
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

  static PlaygroundLanguage byId(String id) => all.firstWhere(
        (e) => e.id == id,
        orElse: () => all.first,
      );
}

/// Interview-prep company catalog with tiers (mirrors web product).
class PrepCompany {
  const PrepCompany(
      {required this.slug, required this.name, required this.tier});
  final String slug;
  final String name;
  final String tier; // FAANG+ | Top Tier | Mid Tier
}

class PrepCompanies {
  const PrepCompanies._();
  static const List<PrepCompany> all = [
    PrepCompany(slug: 'google', name: 'Google', tier: 'FAANG+'),
    PrepCompany(slug: 'amazon', name: 'Amazon', tier: 'FAANG+'),
    PrepCompany(slug: 'meta', name: 'Meta', tier: 'FAANG+'),
    PrepCompany(slug: 'apple', name: 'Apple', tier: 'FAANG+'),
    PrepCompany(slug: 'netflix', name: 'Netflix', tier: 'FAANG+'),
    PrepCompany(slug: 'microsoft', name: 'Microsoft', tier: 'FAANG+'),
    PrepCompany(slug: 'openai', name: 'OpenAI', tier: 'Top Tier'),
    PrepCompany(slug: 'nvidia', name: 'Nvidia', tier: 'Top Tier'),
    PrepCompany(slug: 'stripe', name: 'Stripe', tier: 'Top Tier'),
    PrepCompany(slug: 'airbnb', name: 'Airbnb', tier: 'Top Tier'),
    PrepCompany(slug: 'uber', name: 'Uber', tier: 'Top Tier'),
    PrepCompany(slug: 'linkedin', name: 'LinkedIn', tier: 'Top Tier'),
    PrepCompany(slug: 'adobe', name: 'Adobe', tier: 'Top Tier'),
    PrepCompany(slug: 'salesforce', name: 'Salesforce', tier: 'Top Tier'),
    PrepCompany(slug: 'spotify', name: 'Spotify', tier: 'Top Tier'),
    PrepCompany(slug: 'tiktok', name: 'TikTok', tier: 'Top Tier'),
    PrepCompany(slug: 'snap', name: 'Snap', tier: 'Mid Tier'),
    PrepCompany(slug: 'twitter', name: 'Twitter/X', tier: 'Mid Tier'),
    PrepCompany(slug: 'oracle', name: 'Oracle', tier: 'Mid Tier'),
    PrepCompany(slug: 'cisco', name: 'Cisco', tier: 'Mid Tier'),
    PrepCompany(slug: 'vmware', name: 'VMware', tier: 'Mid Tier'),
    PrepCompany(slug: 'walmart', name: 'Walmart', tier: 'Mid Tier'),
    PrepCompany(slug: 'jpmorgan', name: 'JPMorgan', tier: 'Mid Tier'),
    PrepCompany(slug: 'samsung', name: 'Samsung', tier: 'Mid Tier'),
    PrepCompany(slug: 'intuit', name: 'Intuit', tier: 'Mid Tier'),
    PrepCompany(slug: 'yahoo', name: 'Yahoo', tier: 'Mid Tier'),
    PrepCompany(slug: 'bloomberg', name: 'Bloomberg', tier: 'Mid Tier'),
    PrepCompany(slug: 'goldman-sachs', name: 'Goldman Sachs', tier: 'Mid Tier'),
    PrepCompany(slug: 'paypal', name: 'PayPal', tier: 'Mid Tier'),
  ];
}
