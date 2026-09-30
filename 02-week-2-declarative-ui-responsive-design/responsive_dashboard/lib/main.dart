import 'package:flutter/material.dart';

// Menambahkan konstanta breakpoint agar tidak hardcode
const double kWideBreakpoint = 700;

void main() => runApp(const AcademicOverviewApp());

class AcademicOverviewApp extends StatefulWidget {
  const AcademicOverviewApp({super.key});

  @override
  State createState() => _AcademicOverviewAppState();
}

class _AcademicOverviewAppState extends State {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: AcademicOverviewPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key
  });

  final bool isDark;
  final ValueChanged onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 4),
              Semantics(
                label: isDark ? 'Beralih ke tema terang' : 'Beralih ke tema gelap',
                child: Switch.adaptive(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profil menggunakan Theme.of(context)
          Semantics(
            label: 'Profil Mahasiswa: Adam Bahy Maulana, Jurusan Teknik Informatika',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle, 
                    size: 50, 
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adam Bahy Maulana', 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Teknik Informatika',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Layout Responsif (Kartu Informasi)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Menggunakan konstanta kWideBreakpoint
                final columns = constraints.maxWidth >= kWideBreakpoint ? 2 : 1; 
                return GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: const [
                    InfoCard(title: 'GPA / IPK', value: '3.8'),
                    InfoCard(title: 'Total SKS', value: '112'),
                    InfoCard(title: 'Kehadiran', value: '95%'),
                    InfoCard(title: 'Mata Kuliah Aktif', value: '6'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Ekstraksi Widget Kartu Informasi yang Reusable
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});
  
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        // Perbaikan format interpolasi string untuk Semantics
        label: '\(title:\)value',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(
              child: Text(
                title, 
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value, 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}