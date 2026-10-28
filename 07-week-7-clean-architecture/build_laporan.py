#!/usr/bin/env python
"""Bangun Laporan Jobsheet Minggu 7 (Clean Architecture) dari Template Rapi.

Angka berasal dari docs/verifikasi-grep.txt, hasil flutter analyze/test, dan
screenshot device di screenshots/.
"""
import os
import re

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
TPL = r"C:/Kuliah/Template Laporan Jobsheet - Rapi.docx"
OUT = os.path.join(HERE, "Laporan Jobsheet Minggu 7 - Adam Bahy Maulana.docx")
SHOTS = os.path.join(HERE, "screenshots")
FIGS = os.path.join(SHOTS, "fig")

ID_ROWS = {
    "Mata Kuliah": "PEMOB",
    "Program Studi": "D4 \u2013 Teknik Informatika",
    "Semester": "5",
    "Kelas": "TI - 3E",
    "NIM": "244107020207",
    "Nama": "Adam Bahy Maulana",
    "Jobsheet Ke-": "7",
}

JUDUL = {
    "Praktikum Ke-1": "Praktikum Ke-1 : Audit Layer Project Lama",
    "Praktikum Ke-2": "Praktikum Ke-2 : Domain dan Data per Fitur",
    "Praktikum Ke-3": (
        "Praktikum Ke-3 : Presentation, Dependency Injection, dan Verifikasi"
    ),
    "Soal Praktikum": (
        "Soal Praktikum : Refactor Menyeluruh, AI Challenge, dan Refleksi"
    ),
}


def add_borders(t):
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        e = OxmlElement("w:" + edge)
        e.set(qn("w:val"), "single")
        e.set(qn("w:sz"), "4")
        e.set(qn("w:space"), "0")
        e.set(qn("w:color"), "808080")
        borders.append(e)
    t._tbl.tblPr.append(borders)


def clear_cell(cell):
    for p in list(cell.paragraphs)[1:]:
        p._p.getparent().remove(p._p)
    cell.paragraphs[0].text = ""


def _num(text, style):
    return text if style == "Laporan Kode" else re.sub(r"(?<=\d),(?=\d)", ".", text)


def put(cell, text, style="Laporan Isi"):
    first = cell.paragraphs[0]
    p = (
        first
        if (not first.text and len(cell.paragraphs) == 1 and not first.runs)
        else cell.add_paragraph()
    )
    p.style = cell.part.document.styles[style]
    p.add_run(_num(text, style))
    return p


def para(cell, text, style="Laporan Isi"):
    p = cell.add_paragraph(style=style)
    p.add_run(_num(text, style))
    return p


def code(cell, text):
    for line in text.strip("\n").split("\n"):
        para(cell, line if line.strip() else " ", "Laporan Kode")


def img(cell, path, caption, width=14.6):
    p = cell.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(path, width=Cm(width))
    para(cell, caption, "Laporan Caption")


def fit_width(t, total=8412):
    cols = t._tbl.find(qn("w:tblGrid")).findall(qn("w:gridCol"))
    per = total // len(cols)
    for c in cols:
        c.set(qn("w:w"), str(per))
    tblPr = t._tbl.tblPr
    w = tblPr.find(qn("w:tblW"))
    if w is None:
        w = OxmlElement("w:tblW")
        tblPr.append(w)
    w.set(qn("w:type"), "dxa")
    w.set(qn("w:w"), str(per * len(cols)))


def tbl(cell, title, header, rows):
    para(cell, title, "Laporan Tabel Judul")
    t = cell.add_table(rows=1 + len(rows), cols=len(header))
    add_borders(t)
    fit_width(t)
    t.rows[0]._tr.get_or_add_trPr().append(OxmlElement("w:tblHeader"))
    for j, h in enumerate(header):
        c = t.rows[0].cells[j]
        c.text = ""
        c.paragraphs[0].style = cell.part.document.styles["Laporan SelHeader"]
        c.paragraphs[0].add_run(h)
    for i, r in enumerate(rows, start=1):
        for j, v in enumerate(r):
            c = t.rows[i].cells[j]
            c.text = ""
            c.paragraphs[0].style = cell.part.document.styles["Laporan Sel"]
            c.paragraphs[0].add_run(str(v))
    return t


def pair(name, left, right):
    """Dua screenshot potret digabung berdampingan."""
    a = Image.open(os.path.join(SHOTS, left)).convert("RGB")
    b = Image.open(os.path.join(SHOTS, right)).convert("RGB")
    h = min(a.height, b.height)
    a = a.resize((int(a.width * h / a.height), h))
    b = b.resize((int(b.width * h / b.height), h))
    bar = 46
    out = Image.new("RGB", (a.width + b.width + 24, h + bar), "white")
    out.paste(a, (0, bar))
    out.paste(b, (a.width + 24, bar))
    d = ImageDraw.Draw(out)
    d.text((8, 14), "APK Minggu 6", fill="black")
    d.text((a.width + 32, 14), "APK hasil refactor", fill="black")
    path = os.path.join(FIGS, name)
    out.save(path)
    return path


def build_figures():
    os.makedirs(FIGS, exist_ok=True)
    specs = [
        ("figura-01-login.png", "before-01-login.png", "after-01-login.png"),
        ("figura-02-home.png", "before-02-home.png", "after-02-home.png"),
        ("figura-03-detail.png", "before-03-detail.png", "after-03-detail.png"),
        ("figura-04-401.png", "before-04-401.png", "after-04-401.png"),
        ("figura-05-logout.png", "before-05-logout.png", "after-05-logout.png"),
    ]
    return [pair(*s) for s in specs]


def p1_1(cell):
    put(
        cell,
        "Project yang diaudit adalah campus_notify milik Minggu 6 (autentikasi, "
        "penyimpanan token, dan FCM). Susunan awalnya memakai empat folder "
        "mendatar, yaitu data, providers, pages, dan messaging, ditambah router "
        "serta routes di akar lib.",
    )
    tbl(
        cell,
        "Tabel 1. Pemetaan berkas lama ke layer",
        ["Berkas", "Layer saat ini", "Masalah"],
        [
            [
                "pages/home_page.dart",
                "presentation",
                "mengimpor data/token_store.dart dan memakai TokenStore.mask "
                "langsung",
            ],
            [
                "pages/login_page.dart",
                "presentation",
                "mengimpor data/api_errors.dart untuk menerjemahkan galat",
            ],
            [
                "providers/auth_provider.dart",
                "presentation (state)",
                "membuat AuthRepository() di dalam provider; kontrak dan "
                "implementasi belum dipisah",
            ],
            [
                "data/auth_repository.dart",
                "data",
                "entity Session, kontrak, dan implementasi menumpuk dalam satu "
                "berkas",
            ],
            [
                "data/token_store.dart",
                "data",
                "aman, tetapi dibaca langsung oleh halaman",
            ],
            [
                "messaging/deeplink.dart",
                "infrastruktur",
                "fungsi murni tersimpan di folder messaging sehingga helper "
                "murni tersebar",
            ],
        ],
    )


def p1_2(cell):
    put(
        cell,
        "Tiga pencarian dijalankan pada project Minggu 6. Dua pencarian pertama "
        "tidak menghasilkan apa pun karena Minggu 6 sudah menyembunyikan Dio di "
        "balik provider, sehingga widget tidak memanggil jaringan secara literal.",
    )
    code(
        cell,
        "$ rg -n \"Dio\\(|http\\.|openDatabase|SharedPreferences\\.getInstance"
        "|FlutterSecureStorage\" lib/pages lib/providers\n"
        "(nol hasil)\n"
        "$ rg -n \"DateFormat|jsonDecode|\\.toIso8601String\" lib/pages "
        "lib/providers\n"
        "(nol hasil)\n"
        "$ rg -n \"Repository\\(|Dio\\(BaseOptions\" lib/pages lib/providers\n"
        "lib/providers\\auth_provider.dart:10:  (ref) => AuthRepository(),\n"
        "$ rg -n \"import '\\.\\./data\" lib/pages\n"
        "lib/pages\\login_page.dart:4:import '../data/api_errors.dart';\n"
        "lib/pages\\home_page.dart:5:import '../data/token_store.dart';",
    )
    put(
        cell,
        "Item refactor yang dihasilkan berjumlah tiga: instansiasi repository di "
        "luar batas layer, dua impor modul data oleh halaman, dan tidak adanya "
        "kontrak domain untuk sesi maupun pengumuman. Kondisi ini menyimpang dari "
        "dugaan modul yang menyebut widget memanggil Dio langsung; kebocoran yang "
        "sebenarnya terjadi adalah impor modul data oleh halaman, bukan pemanggilan "
        "objek Dio.",
    )


def p1_3(cell):
    code(
        cell,
        "lib/\n"
        "+-- core/failures.dart            Failure murni Dart\n"
        "+-- core/format.dart              tanggal, token, rute, pesan\n"
        "+-- features/auth/\n"
        "|   +-- domain/        entities/session.dart,\n"
        "|   |                  repositories/auth_repository.dart\n"
        "|   +-- data/          datasources/{token_store,api_client,"
        "api_errors}.dart,\n"
        "|   |                  repositories/auth_repository_impl.dart\n"
        "|   +-- presentation/  providers/auth_providers.dart,\n"
        "|                      pages/login_page.dart\n"
        "+-- features/announcements/\n"
        "|   +-- domain/        entities/announcement.dart,\n"
        "|   |                  repositories/announcement_repository.dart,\n"
        "|   |                  usecases/get_announcements.dart\n"
        "|   +-- data/          models/announcement_model.dart,\n"
        "|   |                  datasources/announcement_local_source.dart,\n"
        "|   |                  repositories/announcement_repository_impl.dart\n"
        "|   +-- presentation/  providers/announcement_providers.dart,\n"
        "|                      pages/{home_page,announcement_page}.dart\n"
        "+-- messaging/push_service.dart   infrastruktur FCM\n"
        "+-- router.dart, routes.dart",
    )
    put(
        cell,
        "Snapshot sebelum refactor disimpan sebagai commit 492c6d1 dengan pesan "
        "chore: snapshot sebelum refactor Clean Architecture (week 7), sehingga "
        "struktur lama tetap dapat dibandingkan dan di-rollback.",
    )


def p2_1(cell):
    put(
        cell,
        "Dua entity dibuat tanpa impor Flutter dan tanpa fungsi pemetaan: Session "
        "untuk kredensial sesi dan Announcement untuk data pengumuman.",
    )
    code(
        cell,
        "// lib/features/announcements/domain/entities/announcement.dart\n"
        "class Announcement {\n"
        "  const Announcement({\n"
        "    required this.id,\n"
        "    required this.title,\n"
        "    required this.summary,\n"
        "    required this.body,\n"
        "    required this.updatedAt,\n"
        "  });\n"
        "\n"
        "  final String id;\n"
        "  final String title;\n"
        "  final String summary;\n"
        "  final String body;\n"
        "  final DateTime updatedAt;\n"
        "}",
    )


def p2_2(cell):
    put(
        cell,
        "Failure ditempatkan di lib/core karena dipakai semua fitur, sedangkan "
        "kontrak repository ditempatkan di domain masing-masing fitur. Status "
        "sukses dan gagal dikembalikan sebagai record Dart sehingga tidak ada "
        "exception yang bocor ke presentation.",
    )
    code(
        cell,
        "// lib/core/failures.dart\n"
        "sealed class Failure {\n"
        "  const Failure(this.message);\n"
        "  final String message;\n"
        "}\n"
        "class LocalFailure extends Failure { const LocalFailure(super.message); }\n"
        "class NetworkFailure extends Failure {\n"
        "  const NetworkFailure(super.message);\n"
        "}\n"
        "class AuthFailure extends Failure { const AuthFailure(super.message); }\n"
        "\n"
        "// lib/features/announcements/domain/repositories/"
        "announcement_repository.dart\n"
        "abstract class AnnouncementRepository {\n"
        "  Future<({List<Announcement> items, Failure? failure})>\n"
        "      fetchAnnouncements();\n"
        "}\n"
        "\n"
        "// lib/features/auth/domain/repositories/auth_repository.dart\n"
        "abstract class AuthRepository {\n"
        "  Future<bool> hasSession();\n"
        "  Future<String?> accessToken();\n"
        "  Future<({Session? session, Failure? failure})> login({\n"
        "    required String email, required String password});\n"
        "  Future<({String? access, Failure? failure})> refresh(\n"
        "      String refreshToken);\n"
        "  Future<void> logout();\n"
        "}",
    )


def p2_3(cell):
    put(
        cell,
        "Pemetaan bentuk luar hanya ada di model. Implementasi repository membaca "
        "sumber data contoh berbentuk JSON; komponen itulah yang kelak ditukar "
        "dengan Dio atau SQLite tanpa menyentuh domain maupun presentation.",
    )
    code(
        cell,
        "// lib/features/announcements/data/models/announcement_model.dart\n"
        "factory AnnouncementModel.fromJson(Map<String, Object?> json) {\n"
        "  return AnnouncementModel(\n"
        "    id: json['id']! as String,\n"
        "    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')\n"
        "        ?? DateTime.fromMillisecondsSinceEpoch(0), ...);\n"
        "}\n"
        "\n"
        "// lib/features/announcements/data/repositories/"
        "announcement_repository_impl.dart\n"
        "try {\n"
        "  final rows = await source.readAll();\n"
        "  final items = rows\n"
        "      .map((row) => AnnouncementModel.fromJson(row).toEntity())\n"
        "      .toList();\n"
        "  return (items: items, failure: null);\n"
        "} on Object catch (e) {\n"
        "  return (items: const <Announcement>[],\n"
        "          failure: LocalFailure('Gagal memuat pengumuman: $e'));\n"
        "}",
    )
    put(
        cell,
        "Sesi autentikasi mengikuti pola yang sama. AuthRepositoryImpl menjadi "
        "satu-satunya pemegang TokenStore, dan halaman tidak lagi membaca token "
        "mentah karena kontrak domain menyediakan metode accessToken().",
    )


def p2_4(cell):
    code(
        cell,
        "// lib/features/announcements/domain/usecases/get_announcements.dart\n"
        "class GetAnnouncements {\n"
        "  const GetAnnouncements(this._repository);\n"
        "  final AnnouncementRepository _repository;\n"
        "\n"
        "  Future<({List<Announcement> items, Failure? failure})> call() =>\n"
        "      _repository.fetchAnnouncements();\n"
        "}",
    )
    put(
        cell,
        "Satu use case dipakai untuk daftar pengumuman karena operasi inilah yang "
        "berpotensi bertambah aturan, misalnya urutan, penyaringan, dan cache. "
        "Login, logout, serta perpanjangan token tidak diberi use case karena "
        "hanya meneruskan panggilan; alasannya ditulis pada docs/ai-challenge.md.",
    )


def p3_1(cell):
    put(
        cell,
        "Berkas provider menjadi satu-satunya tempat penyambungan lapisan. Widget "
        "hanya melihat provider dan tidak membuat repository sendiri.",
    )
    code(
        cell,
        "// lib/features/auth/presentation/providers/auth_providers.dart\n"
        "final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());\n"
        "\n"
        "final authRepositoryProvider = Provider<AuthRepository>(\n"
        "  (ref) => AuthRepositoryImpl(ref.watch(tokenStoreProvider)),\n"
        ");\n"
        "\n"
        "final apiClientProvider = Provider((ref) => buildApiClient(\n"
        "  ref.watch(tokenStoreProvider),\n"
        "  ref.watch(authRepositoryProvider)));\n"
        "\n"
        "final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(\n"
        "  AuthNotifier.new);\n"
        "\n"
        "// lib/features/announcements/presentation/providers/"
        "announcement_providers.dart\n"
        "final announcementRepositoryProvider = Provider<AnnouncementRepository>(\n"
        "  (ref) => const AnnouncementRepositoryImpl(\n"
        "      source: AnnouncementLocalSource()));\n"
        "\n"
        "final getAnnouncementsProvider = Provider<GetAnnouncements>(\n"
        "  (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)));\n"
        "\n"
        "final announcementsProvider = FutureProvider<List<Announcement>>(\n"
        "  (ref) async { ... });",
    )


def p3_2(cell):
    code(
        cell,
        "// lib/features/announcements/presentation/pages/home_page.dart\n"
        "final announcements = ref.watch(announcementsProvider);\n"
        "...announcements.when(\n"
        "  loading: () => const [Center(child: CircularProgressIndicator())],\n"
        "  error: (e, _) => [Text(messageOf(e))],\n"
        "  data: (items) => [for (final item in items) _announcementCard(item)],\n"
        "),",
    )
    put(
        cell,
        "Kartu pengumuman tidak lagi diketik di dalam widget. Daftar dibaca dari "
        "provider, lalu halaman detail mengambil satu entri berdasarkan id dari "
        "state yang sama. Seluruh teks antarmuka dipertahankan sehingga "
        "perbandingan sebelum dan sesudah hanya menyangkut isi state.",
    )


def p3_3(cell):
    put(
        cell,
        "Tiga pemeriksaan dijalankan pada project hasil refactor dan keluaran "
        "lengkapnya disimpan di docs/verifikasi-grep.txt.",
    )
    tbl(
        cell,
        "Tabel 2. Hasil pemeriksaan sterilitas",
        ["Pemeriksaan", "Sasaran", "Hasil"],
        [
            [
                "pola Dio, openDatabase, FlutterSecureStorage, SharedPreferences, "
                "jsonDecode",
                "lib/features/*/presentation",
                "nol hasil",
            ],
            [
                "impor package:flutter, dio, sqflite, firebase",
                "lib/features/*/domain dan lib/core",
                "nol hasil",
            ],
            [
                "pola RepositoryImpl( dan Dio(BaseOptions",
                "lib/features/*/presentation/pages",
                "nol hasil",
            ],
            [
                "pola yang sama di seluruh presentation",
                "hanya berkas providers",
                "dua hasil, keduanya titik wiring DI",
            ],
        ],
    )
    code(
        cell,
        "$ flutter analyze\n"
        "No issues found! (ran in 18.7s)\n"
        "\n"
        "$ flutter test\n"
        "00:00 +8: test/core_format_test.dart: messageOf memakai pesan Failure\n"
        "00:00 +9: test/get_announcements_test.dart: GetAnnouncements meneruskan "
        "daftar dari repository\n"
        "00:00 +10: test/get_announcements_test.dart: GetAnnouncements meneruskan "
        "failure tanpa melempar\n"
        "00:00 +10: All tests passed!",
    )
    put(
        cell,
        "Sepuluh test lulus, termasuk dua test use case dengan repository palsu "
        "yang tidak menyentuh basis data maupun jaringan. Build rilis menghasilkan "
        "app-release.apk berukuran 53.087.187 byte dan dipasang pada perangkat "
        "Infinix resolusi 1080x2436.",
    )


def p3_4(cell, figs):
    put(
        cell,
        "Uji manual dilakukan pada lima alur, yaitu login, beranda, detail "
        "pengumuman, simulasi 401, dan logout. Setiap alur direkam dua kali: APK "
        "Minggu 6 sebagai gambar kiri dan APK hasil refactor sebagai gambar kanan.",
    )
    put(
        cell,
        "Kedua tangkapan berukuran sama, 1080 x 2436 piksel, dan selisih piksel "
        "pada setiap alur di bawah satu persen: 0,21 % login, 0,34 % beranda, "
        "0,92 % detail, 0,34 % simulasi 401, dan 0,22 % logout. Selisih itu "
        "berasal dari jam pada status bar dan cap waktu kartu, bukan dari "
        "susunan widget.",
    )
    for path, caption in [
        (
            figs[0],
            "Gambar 1. Halaman login sebelum dan sesudah refactor; susunan "
            "widget, teks isian, dan tombol tidak berubah.",
        ),
        (
            figs[1],
            "Gambar 2. Beranda dengan kartu pengumuman yang kini dibaca dari "
            "announcementsProvider; kolom status perangkat tetap menampilkan "
            "token terpotong.",
        ),
        (
            figs[2],
            "Gambar 3. Halaman detail pengumuman dengan baris tanggal hasil "
            "formatTanggal pada core/format.dart.",
        ),
        (
            figs[3],
            "Gambar 4. Simulasi 401: interceptor menolak perulangan request dan "
            "membersihkan sesi ketika refresh ikut gagal.",
        ),
        (
            figs[4],
            "Gambar 5. Logout mengembalikan aplikasi ke halaman login melalui "
            "redirect GoRouter.",
        ),
    ]:
        img(cell, path, caption)


def s1(cell):
    put(
        cell,
        "Fitur auth dipisah menjadi entity Session, kontrak AuthRepository, "
        "AuthRepositoryImpl, dan satu berkas provider. Notifikasi FCM dibiarkan "
        "menjadi infrastruktur pada lib/messaging karena isinya hanya pemanggilan "
        "SDK Firebase tanpa aturan bisnis.",
    )
    tbl(
        cell,
        "Tabel 3. Tujuan baru tiap berkas lama",
        ["Berkas lama", "Perlakuan", "Berkas baru"],
        [
            [
                "data/token_store.dart",
                "pindah",
                "features/auth/data/datasources/token_store.dart",
            ],
            [
                "data/api_client.dart",
                "pindah",
                "features/auth/data/datasources/api_client.dart",
            ],
            [
                "data/api_errors.dart",
                "pecah",
                "api_errors.dart untuk peta DioException ke Failure, dan "
                "core/format.dart untuk messageOf",
            ],
            [
                "data/auth_repository.dart",
                "pecah",
                "auth/domain/entities/session.dart, auth/domain/repositories/"
                "auth_repository.dart, auth/data/repositories/"
                "auth_repository_impl.dart",
            ],
            [
                "providers/auth_provider.dart",
                "pindah",
                "auth/presentation/providers/auth_providers.dart",
            ],
            [
                "pages/login_page.dart",
                "pindah",
                "auth/presentation/pages/login_page.dart",
            ],
            [
                "pages/home_page.dart dan pages/announcement_page.dart",
                "pindah, isi diganti state",
                "announcements/presentation/pages/",
            ],
            [
                "messaging/deeplink.dart",
                "hapus dan lebur",
                "core/format.dart pada fungsi routeFromMessage",
            ],
        ],
    )


def s2(cell):
    put(
        cell,
        "Empat fungsi murni dipusatkan di lib/core/format.dart agar dapat diuji "
        "tanpa widget.",
    )
    code(
        cell,
        "String formatTanggal(DateTime waktu) =>\n"
        "    '${waktu.day} ${_bulan[waktu.month - 1]} ${waktu.year}';\n"
        "String maskToken(String? token) { /* 12 karakter pertama */ }\n"
        "String routeFromMessage(Map<String, dynamic> data) { /* tambah '/' */ }\n"
        "String messageOf(Object error) =>\n"
        "    error is Failure ? error.message : /* potong prefix teknis */;",
    )
    put(
        cell,
        "Fungsi tersebut diuji pada test/core_format_test.dart yang berisi delapan "
        "test, antara lain formatTanggal(DateTime(2026, 9, 27)) menghasilkan 27 "
        "September 2026 dan maskToken pada token 37 karakter menghasilkan "
        "mock-access- dengan elipsis.",
    )


def s3(cell):
    put(
        cell,
        "DioException diubah menjadi NetworkFailure atau AuthFailure pada "
        "features/auth/data/datasources/api_errors.dart, sedangkan kegagalan "
        "penyimpanan token diubah menjadi LocalFailure di dalam implementasi "
        "repository. Halaman hanya menerima teks melalui messageOf sehingga tipe "
        "Dio tidak pernah muncul di presentation.",
    )
    code(
        cell,
        "// features/auth/data/datasources/api_errors.dart\n"
        "case DioExceptionType.badResponse:\n"
        "  final code = error.response?.statusCode;\n"
        "  if (code == 401) return const AuthFailure(\n"
        "      'Sesi berakhir. Silakan login ulang.');\n"
        "  if (code != null && code >= 500) return const NetworkFailure(\n"
        "      'Server sedang bermasalah.');",
    )


def s4(cell):
    put(
        cell,
        "Prompt, usulan awal, dan keputusan final AI Challenge dicatat pada "
        "docs/ai-challenge.md. Butir yang diubah atau ditolak dirangkum pada "
        "Tabel 4.",
    )
    tbl(
        cell,
        "Tabel 4. Usulan AI dan keputusan final",
        ["Usulan AI", "Keputusan", "Alasan teknis"],
        [
            [
                "use case untuk login, logout, refresh, tambah, dan hapus",
                "ditolak",
                "operasi satu baris; tiga lapisan tambahan tidak menambah nilai "
                "uji",
            ],
            [
                "Either<Failure, T> dengan package fpdart",
                "ditolak",
                "record Dart sudah memberi status sukses dan gagal eksplisit "
                "tanpa dependensi baru",
            ],
            [
                "get_it dan injectable untuk DI",
                "ditolak",
                "Riverpod sudah dipakai state aplikasi; dua wadah DI membuat "
                "siklus hidup objek tidak jelas",
            ],
            [
                "satu AppRepository gabungan",
                "ditolak",
                "melanggar Interface Segregation karena pengumuman ikut "
                "bergantung pada token auth",
            ],
            [
                "push service dibungkus domain dan use case",
                "ditolak",
                "tidak memuat aturan bisnis; parsing rute murni dipindah ke "
                "core/format.dart agar teruji",
            ],
            [
                "interface di domain dan implementasi di data",
                "diterima",
                "domain tetap murni Dart sehingga use case diuji tanpa perangkat",
            ],
        ],
    )


def s5(cell):
    put(
        cell,
        "Jumlah berkas lapisan lib berubah dari 14 menjadi 22. Kenaikan delapan "
        "berkas berasal dari lapisan domain (lima berkas) dan core (dua berkas) "
        "yang sebelumnya tidak ada, ditambah satu pemisah sumber data. Tidak ada "
        "fitur baru yang dibuat selama refactor.",
    )
    put(
        cell,
        "Arah dependensi terverifikasi: presentation mengimpor domain dan "
        "provider, data mengimpor domain, sedangkan domain hanya mengimpor domain "
        "dan core. Dua baris pertama Tabel 2 menjadi bukti tidak ada panah yang "
        "membalik, dan baris keempat memastikan pembuatan objek hanya terjadi di "
        "titik wiring.",
    )


def s6(cell):
    put(
        cell,
        "Mengapa interface repository harus tinggal di domain, bukan di data? "
        "Domain menetapkan kebutuhan dan data memenuhinya. Bila kontrak ditaruh "
        "di data, use case harus mengimpor modul yang membawa Dio atau secure "
        "storage, sehingga unit test domain ikut memerlukan perangkat dan "
        "jaringan.",
    )
    put(
        cell,
        "Kapan use case benar-benar dibutuhkan? Ketika satu operasi menggabungkan "
        "lebih dari satu sumber data atau memuat aturan bisnis berupa validasi, "
        "urutan, dan sinkronisasi. Untuk CRUD satu baris, repository langsung ke "
        "notifier sudah cukup dan lebih murah.",
    )
    put(
        cell,
        "Apa biaya over-engineering bagi tim kecil? Setiap lapisan tambahan "
        "menambah berkas yang harus dibuka saat membaca satu alur, memperbesar "
        "potensi konflik perubahan, dan memperlambat suntingan kecil. Biayanya "
        "sepadan ketika jumlah fitur bertambah hingga aturan bisnis tersebar, "
        "misalnya saat pengumuman memerlukan sinkronisasi luring.",
    )
    put(
        cell,
        "Bagian mana dari usulan AI yang ditolak? Lima butir pada Tabel 4, yaitu "
        "use case untuk setiap operasi tunggal, fpdart, get_it, AppRepository "
        "gabungan, dan pembungkusan push service. Penyederhanaan itu menjaga "
        "project dua fitur tetap terbaca.",
    )


ISI = {
    "Praktikum Ke-1": [
        ("1 : Petakan berkas ke layer", p1_1),
        ("2 : Tandai tiga pelanggaran klasik", p1_2),
        ("3 : Gambar struktur target", p1_3),
    ],
    "Praktikum Ke-2": [
        ("1 : Entity murni di domain", p2_1),
        ("2 : Failure dan kontrak repository", p2_2),
        ("3 : Model dan implementasi di data", p2_3),
        ("4 : Use case satu operasi bisnis", p2_4),
    ],
    "Praktikum Ke-3": [
        ("1 : Dependency injection dengan Riverpod", p3_1),
        ("2 : Halaman hanya membaca state", p3_2),
        ("3 : Verifikasi dependency rule", p3_3),
        ("4 : Perbandingan tampilan", p3_4),
    ],
    "Soal Praktikum": [
        ("1 : Refactor fitur kedua, auth", s1),
        ("2 : Fungsi murni di core/format.dart", s2),
        ("3 : Failure sebelum mencapai UI", s3),
        ("4 : AI Challenge", s4),
        ("5 : Dependency rule terbukti", s5),
        ("6 : Refleksi", s6),
    ],
}


def isi_tabel(table, langkah, figs):
    while len(table.rows) - 1 < len(langkah):
        table.add_row()
    while len(table.rows) - 1 > len(langkah):
        table._tbl.remove(table.rows[-1]._tr)
    for row, (label, fn) in zip(table.rows[1:], langkah):
        clear_cell(row.cells[0])
        put(row.cells[0], label)
        clear_cell(row.cells[1])
        if fn is p3_4:
            fn(row.cells[1], figs)
        else:
            fn(row.cells[1])


def main():
    figs = build_figures()
    doc = Document(TPL)

    for row in doc.tables[0].rows:
        key = row.cells[0].text.strip()
        if key in ID_ROWS:
            clear_cell(row.cells[2])
            put(row.cells[2], ID_ROWS[key])

    for p in doc.paragraphs:
        teks = p.text.strip()
        if teks in JUDUL:
            for r in p.runs:
                r.text = ""
            p.runs[0].text = JUDUL[teks]

    order = ["Praktikum Ke-1", "Praktikum Ke-2", "Praktikum Ke-3", "Soal Praktikum"]
    for name, table in zip(order, doc.tables[1:]):
        isi_tabel(table, ISI[name], figs)

    doc.save(OUT)
    print("simpan:", OUT)


if __name__ == "__main__":
    main()