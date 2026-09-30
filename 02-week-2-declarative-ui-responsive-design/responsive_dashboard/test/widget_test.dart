import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Sesuaikan import ini dengan nama proyek/package Anda, 
// atau gunakan import relatif jika strukturnya sesuai:
// import '../lib/main.dart';
import 'package:responsive_dashboard/main.dart';

void main() {
  testWidgets('Dashboard menggunakan satu kolom di layar sempit (< 700px)', (tester) async {
    // 1. Override ukuran layar menjadi sempit (400x800)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    
    // Pastikan ukuran layar di-reset setelah test selesai agar tidak mengganggu test lain
    addTearDown(tester.view.reset);

    // 2. Build aplikasi
    await tester.pumpWidget(const AcademicOverviewApp());

    // 3. Ambil ukuran dari kartu pertama
    final cardSize = tester.getSize(find.byType(InfoCard).first);
    
    // Pada layar 400px dengan padding 16px di kiri dan kanan,
    // lebar 1 kartu harusnya sekitar 368px.
    expect(cardSize.width, greaterThan(350));
    expect(cardSize.width, lessThan(400));
  });

  testWidgets('Dashboard menggunakan dua kolom di layar lebar (>= 700px)', (tester) async {
    // 1. Override ukuran layar menjadi lebar (1200x800)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 2. Build aplikasi
    await tester.pumpWidget(const AcademicOverviewApp());

    // 3. Ambil ukuran dari kartu pertama
    final cardSize = tester.getSize(find.byType(InfoCard).first);
    
    // Pada layar 1200px dengan 2 kolom (termasuk padding luar 16px dan jarak antar kolom 16px),
    // lebar 1 kartu harusnya sekitar (1200 - 16 - 16 - 16) / 2 = 576px.
    expect(cardSize.width, greaterThan(500));
    expect(cardSize.width, lessThan(600));
  });
}