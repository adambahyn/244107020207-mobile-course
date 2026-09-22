1. Kapan setState cukup, kapan state harus naik ke Riverpod?
═══════════════════════════════════════════                                                             

Pakai setState kalau: state itu milik SATU widget, tidak dibaca widget lain, dan mati bersama widget itu. Contoh yang memang pas di project ini → test/widget_test.dart menguji dialog _AddTodoDialog; teks di dalam TextEditingController tidak perlu diketahui halaman mana pun, jadi tidak ada alasan menaruhnya di provider. Contoh baku lain: animasi, PageController, toggle "show password".
                                                                                                        
Naik ke Riverpod kalau salah satu ini benar:
                                                                                                        
- Dibaca minimal dua widget yang tidak punya hubungan parent-child. Di sini todoListProvider dibaca TodoPage (lewat filter) DAN StatsPage (lewat todoStatsProvider). Kalau state ini di setState, dua halaman itu tidak punya jalur komunikasi selain mengoper callback ke bawah — dan callback tidak bisa menembus StatefulShellRoute karena tiap cabang punya Navigator sendiri.
- State harus hidup melewati widget/halaman. StatsPage pakai StatefulShellRoute.indexedStack — Navigator-nya tetap hidup saat tab berpindah; kalau angkanya disimpan sebagai state lokal, pindah tab dua kali bisa menghapusnya.
- Butuh provider turunan. filteredTodoListProvider dan todoStatsProvider itu Provider murni dari dua sumber (todoListProvider + todoFilterProvider). Dengan setState tidak ada mekanisme "hitung ulang otomatis saat sumber berubah"; yang ada setState manual di tiap titik mutasi, dan satu titik yang terlupa = UI salah.
- Logikanya ingin diuji tanpa widget. test/todo_provider_test.dart memanggil notifier langsung lewat ProviderContainer — tidak ada pumpWidget. Ini tidak mungkin kalau state tersimpan di dalam State sebuah widget.
                                                                                                        
Aturan praktisnya: setState itu state EPHEMERAL (milik widget, sementara), Riverpod itu state APLIKASI (milik domain, dibagi). Kalau Anda meragukan satu state, tanya "siapa lagi yang harus tahu?" — kalau jawabannya "tidak ada", setState sudah benar. Jangan pindahkan TextEditingController dialog ke provider hanya demi konsistensi; itu menambah kode tanpa menyelesaikan masalah.
                                                                                                        
═══════════════════════════════════════════
2. Beda context.go dan context.push                                                                     
═══════════════════════════════════════════
                                                                                                        
- context.push('/stats') = MENUMPUK. Route baru didorong ke atas stack, AppBar dapat tombol back, context.pop() mengembalikan ke halaman sebelumnya. Stack tumbuh: / → /stats.
- context.go('/stats') = MENGGANTI lokasi. Stack dibangun ulang sesuai hierarki route, tidak ada yang ditumpuk, back button tidak muncul (kecuali route tujuan memang punya parent).
                                                                                                        
Yang dipakai di project ini justru go, dan itu tepat karena strukturnya StatefulShellRoute.indexedStack dengan dua branch sejajar (/ dan /stats):
                                                                                                        
- lib/pages/todo_page.dart:134 → StatsButton memanggil context.go('/stats').
- lib/pages/stats_page.dart:62 → "Kembali ke daftar" memanggil context.go('/').
- lib/main.dart:75 → navigationShell.goBranch(index, ...) = ekuivalen go di dalam branch, bukan push.
                                                                                                        
Hasilnya test/provider_reaction_test.dart ("NavigationBar berpindah dari / ke /stats dan sebaliknya") bisa berpindah dua arah tanpa menumpuk riwayat, dan selectedIndex NavigationBar tetap sinkron dengan navigationShell.currentIndex.
                                                                                                        
Kapan push yang benar: saat halaman tujuan adalah LAYER DI ATAS halaman sekarang dan user harus bisa kembali — form edit, halaman detail, dialog penuh (/todo/:id). Untuk app ini, kalau Anda menambah halaman detail tugas, rutenya jadi:

    GoRoute(path: '/todo/:id', builder: ...)   // anak dari route '/'
    onTap: (_, todo) => context.push('/todo/${todo.id}')
                                                                                                        
Catatan: push ke route yang sudah ada di stack akan menumpuk duplikat (/stats → /stats → /stats) — itulah kelas bug yang dihindari dengan go untuk tab. Sebaliknya go pada halaman detail membuat tombol back hilang dan user terlempar keluar halaman saat menekan back. Cocokkan jenis perpindahan dengan jenis hubungan halaman.

═══════════════════════════════════════════                                                             
3. Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?
═══════════════════════════════════════════                                                             
                                                                                                        
Tiga boolean (isLoading, isError, hasData) punya masalah mendasar: mereka bukan satu nilai, tapi tiga nilai yang harus Anda jaga konsisten. AsyncValue membuat keempat keadaan itu MUSTAHIL diwakili secara salah.
                                                                                                        
Konkretnya, empat bug yang hilang:
                                                                                                        
a) Kombinasi mustahil bisa terjadi. isLoading = true sambil isError = true sambil hasData = true bisa saja ditulis — tidak ada yang melarang. Satu bool per branch, tiga variabel = 2³ = 8 kombinasi, dan hanya 3–4 yang sah. AsyncValue adalah sealed type: AsyncData, AsyncError, AsyncLoading — tidak ada state keempat.
                                                                                                        
b) UI tidak bisa lupa cabang. statsAsync.when(loading:, error:, data:) di lib/widgets/stats_demo.dart:75 mewajibkan ketiganya diisi; lupa satu = tidak compile. Dengan tiga boolean, kalau Anda lupa cek isError, layar diam-diam menampilkan spinner selamanya dan tidak ada yang protes. Ini bug paling mahal dari keduanya karena tidak bersuara.
                                                                                                        
c) Tidak ada urutan penulisan yang bisa salah. Pola manualnya: setState(() { loading = true; error = null; data = null; }); — dan setiap kali Anda menambah satu field, semua tempat yang me-reset harus diperbarui; satu yang terlewat = data lama muncul bersama error baru. Di StatsNotifier.retry() (lib/widgets/stats_demo.dart:51) hanya ada satu baris ref.invalidateSelf(); peralihan ke loading dan penanganan hasil dikerjakan framework.
                                                                                                        
d) Error tidak bisa "hilang" tanpa jejak, dan stack trace ikut tersimpan. AsyncError membawa error + stackTrace sekaligus; dengan boolean Anda menyimpan String? errorMessage dan melempar stack trace-nya. Test stats_demo_test.dart ("error: build() yang melempar menjadi AsyncError") memeriksa hasError dan tipe error-nya langsung dari state.
                                                                                                        
e) Race condition teratasi oleh aturan framework, bukan kehati-hatian Anda. Kalau user menekan "Coba lagi" dua kali, dua future berjalan bersamaan; hasil yang datang terakhir menang, dan hasil lama yang datang belakangan tidak boleh menimpa yang baru. AsyncNotifier menangani urutan ini untuk Anda — dengan tiga boolean, hasil request lama tetap menulis data dan isLoading = false saat request baru masih berjalan.
                                                                                                        
f) isLoading vs hasValue jadi dua pertanyaan berbeda yang sah sekaligus. test/stats_demo_test.dart:83-86 justru memverifikasi ini: saat retry, isLoading == true DAN hasValue == true — pola stale-while-revalidate (spinner kecil di atas data lama). Dengan satu boolean isLoading, informasi "data lama masih ada" tidak punya tempat, jadi UI harus memilih: sembunyikan data (berkedip) atau tampilkan spinner palsu.      
                                                                                                        
g) Belum lagi: AsyncValue.guard() membungkus try/catch menjadi satu ekspresi, jadi tidak ada lagi catch (e) yang lupa memanggil setState.
                                                                                                        
═══════════════════════════════════════════                                                             
4. Bagian mana dari hasil AI yang diperbaiki, dan mengapa?
═══════════════════════════════════════════
                                                                                                        
Yang paling jelas: lib/pages/stats_page.dart (statistik dari provider) dan lib/widgets/stats_demo.dart (demo AsyncValue) SAMA-SAMA mendeklarasikan class StatsPage. Itu bentrok nama di package yang sama — hasil generate AI yang tidak tahu file lain yang sudah ada. Perbaikannya dua lapis, bukan sekadar menamai ulang:
                                                                                                        
- lib/widgets/stats_demo.dart:64 tetap StatsPage, tapi filenya DIKELUARKAN dari lib/pages/ ke lib/widgets/ dan TIDAK di-wire ke router (lihat komentar header baris 1–9). Route aplikasi tetap hanya / dan /stats.
- lib/pages/stats_page.dart masuk lewat main.dart:5 sebagai halaman resmi route /stats.
                                                                                                        
Konsekuensi teknisnya nyata, bukan kosmetik: kalau keduanya di-wire, import 'package:week3_todo/pages/stats_page.dart' di main.dart:5 dan test/provider_reaction_test.dart:14 akan menunjuk ke kelas yang salah, dan test navigasi yang mengecek find.byType(StatsPage) jadi ambigu.
