#!/usr/bin/env python
"""Bangun job WordCraft untuk laporan Minggu 10 (Integrasi Fitur AI).

Isi tiap langkah ada di ISI di bawah; build() menyalin template, mengisi tabel
wadah, lalu menulis job-laporan10.json yang dijalankan wordcraft-cli.
"""
import json
import os
import struct

MAXW_CM, MAXH_CM = 14.83, 12.5    # batas isi sel & tinggi (celah halaman maks 12,5 cm)


def _ratio(path):
    """rasio lebar/tinggi PNG tanpa PIL (baca IHDR)."""
    with open(path, "rb") as f:
        head = f.read(26)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return 0.75
    w, h = struct.unpack(">II", head[16:24])
    return w / h


def _w_pt(path):
    ar = _ratio(path)
    return min(MAXW_CM, MAXH_CM * ar) * 28.3465


WEEK = os.path.dirname(os.path.abspath(__file__))
DOCX = os.path.join(WEEK, "Laporan Jobsheet Minggu 10 - Adam Bahy Maulana.docx")
PDF = DOCX[:-5] + ".pdf"
JOB = os.path.join(WEEK, "job-laporan10.json")
TPL = r"C:/Kuliah/Template Laporan Jobsheet - Rapi.docx"
SHOT = os.path.join(WEEK, "screenshots")

SECTIONS = ["Praktikum Ke-1", "Praktikum Ke-2", "Praktikum Ke-3", "Soal Praktikum"]
TBL_BLOCK = {"Praktikum Ke-1": 3, "Praktikum Ke-2": 5,
             "Praktikum Ke-3": 7, "Soal Praktikum": 9}
HEAD_BLOCK = {"Praktikum Ke-1": 2, "Praktikum Ke-2": 4,
              "Praktikum Ke-3": 6, "Soal Praktikum": 8}
JUDUL = {
    "Praktikum Ke-1": "Praktikum Ke-1 : Konsep integrasi dan prompt design",
    "Praktikum Ke-2": "Praktikum Ke-2 : Chat interface dengan AI",
    "Praktikum Ke-3": "Praktikum Ke-3 : Penanganan error dan fallback",
    "Soal Praktikum": "Soal Praktikum : Mini project dan refleksi",
}

CUR = []


def put(text):
    CUR.append({"k": "p", "s": "Laporan Isi", "t": text})


def sub(text):
    CUR.append({"k": "p", "s": "Laporan Subsoal", "t": text})


def code(text):
    for line in text.strip("\n").split("\n"):
        CUR.append({"k": "p", "s": "Laporan Kode", "t": line if line.strip() else " "})


def img(name, caption):
    path = os.path.join(SHOT, name)
    CUR.append({"k": "img", "path": path, "cap": caption, "w": _w_pt(path)})


def tbl(title, header, rows):
    CUR.append({"k": "tbl", "title": title, "header": list(header),
                "rows": [[str(v) for v in r] for r in rows]})


# ---------------------------------------------------------------- Praktikum 1
def p1_1():
    put("Fitur AI diletakkan pada folder fitur sendiri dengan aturan lapisan "
        "Minggu 7, yaitu presentation bergantung pada domain dan domain tidak "
        "mengenal Flutter maupun paket jaringan. Penyedia AI hanya dikenal oleh "
        "lapisan data, sehingga mengganti penyedia tidak menyentuh widget.")
    code("""
lib/features/ai/
  domain/entities/chat_message.dart        ChatMessage, ChatRole
  domain/repositories/ai_assistant.dart    AiAssistant.ask()
  domain/usecases/ask_assistant.dart       kSystemPrompt + aturan masukan
  data/datasources/ai_key_store.dart       flutter_secure_storage
  data/repositories/inferhub_assistant.dart  http ke api.inferhub.dev
  presentation/providers/ai_providers.dart  Provider + NotifierProvider
  presentation/pages/assistant_page.dart    UI chat
""")
    tbl("Tabel 1. Lapisan fitur AI dan tanggung jawabnya",
        ["Lapisan", "Berkas", "Yang dijaga"],
        [["domain", "chat_message, ai_assistant, ask_assistant",
          "tanpa import package:flutter, package:http, atau secure storage"],
         ["data", "ai_key_store, inferhub_assistant",
          "bentuk badan permintaan, pemetaan kode status ke Failure"],
         ["presentation", "ai_providers, assistant_page",
          "hanya membaca state dan menampilkan pesan kegagalan"]])
    put("Pemisahan ini diuji dengan grep: tidak ada satu pun berkas domain yang "
        "mengimpor paket jaringan atau penyimpanan aman.")


def p1_2():
    put("Prompt sistem dipatok sebagai konstanta di lapisan domain, bukan di "
        "widget, agar persona dan batas privasi tidak dapat diubah diam-diam "
        "dari kode tampilan.")
    code("""
const kSystemPrompt =
    'Kamu asisten kampus Politeknik Negeri Malang. Jawab dalam Bahasa Indonesia, '
    'maksimal 3 kalimat, tanpa membahas data pribadi pengguna. '
    'Bila pertanyaan di luar topik kampus, tolak dengan sopan.';

user prompt (saat perancangan):
'Rancang satu fitur chat AI untuk aplikasi Flutter kampus: sebutkan lapisan
arsitektur, cara menyimpan API key, dan cara menekan biaya per permintaan.'
""")
    tbl("Tabel 2. Slot prompt dan batas yang dijaga",
        ["Slot", "Isi pada Minggu 10", "Batas yang dijaga"],
        [["System prompt", "asisten kampus Polinema, Bahasa Indonesia, 3 kalimat",
          "persona dan panjang jawaban tidak ditentukan widget"],
         ["User prompt", "pertanyaan pengguna setelah trim, maksimal 500 karakter",
          "permintaan kosong atau kepanjangan ditolak lokal, tanpa biaya"],
         ["Konteks", "tidak ada data pengguna yang disertakan",
          "NIK, nomor telepon, dan token tidak pernah masuk badan permintaan"],
         ["Batas keluaran", "max_tokens 400",
          "jawaban tidak melebar dan biaya per permintaan terbatas"]])
    put("Keluaran awal AI disimpan apa adanya di docs/output-awal-ai.txt, "
        "termasuk waktu dan token, sehingga angka pada laporan ini dapat "
        "diperiksa ulang dari berkas tersebut.")
    code("""
$ cat docs/output-awal-ai.txt
Arsitektur dapat dibagi menjadi lapisan UI/widget chat, state management,
repository/service, serta backend API gateway yang meneruskan permintaan ke
penyedia AI. API key jangan disimpan di aplikasi Flutter, melainkan di
server/secret manager dan diakses melalui backend kampus. Untuk menekan biaya,
gunakan caching jawaban umum, batasi token dan panjang konteks, terapkan rate
limit/kuota, pilih model lebih murah untuk pertanyaan sederhana, serta monitor
pemakaian per fitur.

30.11 detik, 126 token prompt, 234 token penyelesaian (117 token penalaran),
biaya 0.00001
""")


def p1_3():
    put("Usulan AI diperiksa satu per satu terhadap keadaan proyek, bukan "
        "diterima karena terdengar wajar. Hasilnya dua usulan diterima, dua "
        "ditolak dengan alasan, dua ditunda.")
    tbl("Tabel 3. Verifikasi usulan AI",
        ["Usulan AI", "Verifikasi", "Keputusan"],
        [["Pisahkan lapisan UI, state, repository, gateway",
          "cocok dengan aturan Minggu 7 yang sudah dipakai",
          "diterima sebagai features/ai/{domain,data,presentation}"],
         ["API key disimpan di server, bukan di aplikasi",
          "proyek belum punya backend kampus, lingkup jobsheet adalah klien",
          "ditolak, key di flutter_secure_storage, risiko dicatat"],
         ["Gateway meneruskan permintaan ke penyedia",
          "tidak dapat dipenuhi tanpa backend", "ditolak"],
         ["Batasi token dan panjang konteks",
          "diterapkan max_tokens 400 dan batas 500 karakter",
          "diterima"],
         ["Rate limit atau kuota",
          "diterapkan di klien: 20 permintaan per sesi",
          "diterima, batas ini masih dapat diakali pengguna"],
         ["Cache jawaban umum dan model lebih murah",
          "belum ada kebutuhan dan belum ada pembanding biaya", "ditunda"]])


# ---------------------------------------------------------------- Praktikum 2
def p2_1():
    put("Modul menyebut tiga langkah praktikum, yaitu dependensi, layanan AI, "
        "dan layar chat. Ketiganya dikerjakan berurutan dan diuji setelah tiap "
        "langkah, bukan sekaligus di akhir.")
    code("""
dependencies:
  http: ^1.2.0
  flutter_secure_storage: ^11.2.0
  flutter_riverpod: ^3.4.3
""")
    put("Versi flutter_secure_storage pada modul ditulis ^9.0.0, tetapi proyek "
        "Minggu 9 sudah memakai ^11.2.0. Versi proyek dipertahankan agar tidak "
        "menurunkan versi paket yang sudah lolos analisis.")
    code("""
class AiKeyStore {
  final FlutterSecureStorage _storage;
  static const _key = 'ai_api_key';

  Future<String?> read() => _storage.read(key: _key);
  Future<void> save(String value) =>
      _storage.write(key: _key, value: value.trim());

  /// Hanya sepuluh karakter pertama yang tampil, sisanya bintang.
  static String mask(String? key) {
    if (key == null || key.isEmpty) return '(belum diatur)';
    final head = key.length <= 10 ? key.substring(0, 4) : key.substring(0, 10);
    return '$head${'*' * 6}';
  }
}
""")
    tbl("Tabel 4. Berkas hasil langkah 1 sampai 3",
        ["Berkas", "Isi", "Bukti"],
        [["ai_key_store.dart", "baca, simpan, hapus kunci; mask untuk UI",
          "status kunci di layar tampil sk-airo-bR******"],
         ["inferhub_assistant.dart", "POST /v1/chat/completions, model combo/uu",
          "tujuh test data layer hijau"],
         ["assistant_page.dart", "daftar gelembung, input, penghitung, retry",
          "empat widget test hijau"]])


def p2_2():
    put("Layanan AI menerima prompt sistem dan pertanyaan, membaca kunci pada "
        "setiap panggilan, lalu memetakan setiap kegagalan ke tipe Failure. "
        "Lapisan tampilan tidak pernah melihat kode status HTTP.")
    code("""
final response = await _client.post(
  Uri.parse(endpoint),
  headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'},
  body: jsonEncode({
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': question},
    ],
    'max_tokens': 400,
  }),
).timeout(timeout);
""")
    tbl("Tabel 5. Pemetaan kegagalan ke Failure",
        ["Kejadian", "Failure", "Pesan yang tampil"],
        [["kunci belum diatur", "AuthFailure", "API key AI belum diatur. Buka menu kunci."],
         ["HTTP 401 atau 403", "AuthFailure", "API key ditolak penyedia layanan AI."],
         ["HTTP selain 200", "NetworkFailure", "Layanan AI membalas 502. Coba lagi nanti."],
         ["lebih dari 60 detik", "NetworkFailure", "Layanan AI terlalu lama menjawab."],
         ["SocketException", "NetworkFailure", "Tidak ada koneksi internet."],
         ["badan bukan JSON", "LocalFailure", "Balasan layanan AI tidak dapat dibaca."],
         ["konten kosong", "LocalFailure", "Model tidak mengembalikan teks."]])
    put("Batas waktu dipatok 60 detik setelah pengukuran nyata: permintaan ke "
        "model combo/uu memakan 30,11 detik, sehingga batas 30 detik pada versi "
        "pertama membuat panggilan gagal padahal layanan sehat.")


def p2_3():
    put("State percakapan dipegang satu notifier autoDispose. Penghitung "
        "permintaan ikut di state, sehingga pagar biaya kembali nol saat "
        "halaman ditutup.")
    code("""
class ChatNotifier extends AutoDisposeNotifier<ChatState> {
  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.sending) return;
    if (state.exhausted) { /* LocalFailure batas 20 permintaan */ }
    state = state.copyWith(messages: [...state.messages,
        ChatMessage(role: ChatRole.user, text: text)],
        sending: true, clearFailure: true, requests: state.requests + 1);
    final result = await ref.read(askAssistantProvider).call(text);
    ...
  }
  Future<void> retry() => send(_lastQuestion);
}
""")
    img("10-01-asisten-kosong.png",
        "Gambar 1. Halaman asisten sebelum ada pertanyaan, kunci tampil tersamar")
    tbl("Tabel 6. Kunci widget untuk pengujian",
        ["Kunci", "Widget", "Dipakai test"],
        [["ai-key-button", "tombol atur kunci", "membuka dialog kunci"],
         ["ai-key-status", "teks status kunci", "menampilkan kunci tersamar"],
         ["chat-input, chat-send", "field dan tombol kirim", "mengirim pertanyaan"],
         ["chat-message-n", "gelembung percakapan", "memeriksa urutan pesan"],
         ["chat-failure, chat-retry", "bilah gagal dan tombol coba lagi",
          "fallback saat API gagal"],
         ["ai-usage", "penghitung permintaan", "menampilkan 1/20"]])


def p2_4():
    put("Empat belas test baru ditulis untuk fitur ini: tujuh di lapisan data, "
        "tiga di use case, dan empat widget test. Seluruh suite berjumlah 37 test.")
    tbl("Tabel 7. Test fitur AI",
        ["Test", "Harapan", "Hasil"],
        [["balasan 200 dikembalikan sebagai teks", "teks dipakai apa adanya", "lulus"],
         ["tanpa key tidak ada request keluar", "AuthFailure tanpa panggilan HTTP", "lulus"],
         ["401 menjadi AuthFailure", "tipe kegagalan tepat, bukan Exception", "lulus"],
         ["502 menjadi NetworkFailure", "kode status muncul di pesan", "lulus"],
         ["konten kosong menjadi LocalFailure", "tidak ada gelembung hampa", "lulus"],
         ["badan bukan JSON menjadi LocalFailure", "FormatException ditangkap", "lulus"],
         ["SocketException menjadi NetworkFailure", "mode offline terdeteksi", "lulus"],
         ["pertanyaan kosong dan 500+ karakter ditolak", "tanpa biaya permintaan", "lulus"],
         ["kirim pertanyaan menampilkan jawaban", "dua gelembung berurutan", "lulus"],
         ["kegagalan menampilkan mode offline dan coba lagi", "bilah fallback tampil", "lulus"]])


# ---------------------------------------------------------------- Praktikum 3
def p3_1():
    put("Tabel risiko modul diisi dengan mitigasi yang benar-benar ada di kode, "
        "bukan rencana. Setiap baris menunjuk berkas yang dapat diperiksa.")
    tbl("Tabel 8. Risiko dan mitigasi yang diterapkan",
        ["Risiko", "Mitigasi di proyek", "Letak"],
        [["Bocor data pengguna", "tidak ada kolom data pribadi yang dikirim; "
          "batasnya ditulis di prompt sistem dan pada teks halaman",
          "ask_assistant.dart, assistant_page.dart"],
         ["Biaya melonjak", "maksimal 20 permintaan per sesi, max_tokens 400, "
          "permintaan kosong ditolak sebelum keluar",
          "ai_providers.dart, inferhub_assistant.dart"],
         ["API error atau down", "setiap kode status dan pengecualian dipetakan "
          "ke Failure bertipe, pengguna diberi tombol coba lagi",
          "inferhub_assistant.dart, assistant_page.dart"],
         ["Respons tidak relevan", "jawaban kosong dianggap gagal, bukan "
          "ditampilkan; pengumuman tetap dibuka dari cache lokal",
          "inferhub_assistant.dart"],
         ["Kunci API tersalin ke layar", "hanya sepuluh karakter pertama yang "
          "tampil, sisanya bintang", "ai_key_store.dart"]])


def p3_2():
    put("Fallback diuji di perangkat: WiFi dan data dimatikan, lalu satu "
        "pertanyaan dikirim. Bilah kegagalan muncul dengan pesan yang menyebut "
        "mode offline, sementara daftar pengumuman tetap dapat dibuka.")
    img("10-03-asisten-offline-fallback.png",
        "Gambar 2. Fallback saat koneksi dimatikan, jawaban lama tetap terbaca")
    code("""
$ adb shell svc wifi disable && adb shell svc data disable
$ adb shell input text "Apakah perpustakaan buka hari Sabtu?" && input keyevent 66
  -> SocketException -> NetworkFailure('Tidak ada koneksi internet.')
  -> bilah: "Mode offline: pengumuman tetap dapat dibuka." + tombol Coba lagi
""")
    put("Percobaan pertama modul ini justru gagal karena batas waktu 30 detik, "
        "bukan karena koneksi. Karena itu batas waktu dinaikkan ke 60 detik dan "
        "percobaan diulang, lalu fallback diuji ulang dengan koneksi dimatikan. "
        "Dua kegagalan berbeda tidak boleh memakai pesan yang sama.")


def p3_3():
    put("Bukti mesin dijalankan pada kode akhir, bukan pada draf. Hasilnya "
        "disimpan di docs/verifikasi-mesin.txt dan dicetak ulang di bawah.")
    code("""
$ dart format --output=none --set-exit-if-changed lib test
Formatted 42 files (0 changed) in 0.37 seconds.

$ flutter analyze
No issues found! (ran in 83.6s)

$ flutter test
00:15 +37: All tests passed!
""")
    img("10-02-asisten-jawaban.png",
        "Gambar 3. Jawaban nyata dari API Inferhub untuk pertanyaan jam layanan")
    put("Jawaban pada gambar berasal dari panggilan sungguhan ke model combo/uu, "
        "bukan data tiruan. Pertanyaan jam layanan mengembalikan tiga kalimat "
        "sesuai batas prompt sistem, dan penghitung naik ke 1/20.")


# ---------------------------------------------------------------- Soal
def s_1():
    put("Fitur yang diintegrasikan adalah chat asisten kampus karena fitur ini "
        "memakai siklus penuh yang diminta modul: prompt sistem, permintaan "
        "jaringan, penyimpanan kunci, penanganan kegagalan, dan batas biaya. "
        "OCR dan speech-to-text tidak dikerjakan karena tidak ada berkas uji "
        "yang dapat diverifikasi tanpa menambah izin kamera dan mikrofon.")
    tbl("Tabel 9. Daftar keluaran tugas",
        ["Keluaran", "Berkas", "Status"],
        [["prompt sistem, user prompt, output awal", "docs/ai-log.md, "
          "docs/output-awal-ai.txt, docs/permintaan-ai.json", "ada"],
         ["bukti mesin hijau", "docs/verifikasi-mesin.txt, README.md", "ada"],
         ["tabel risiko privasi dan biaya", "Tabel 8 laporan ini, README.md", "ada"],
         ["kode fitur", "lib/features/ai/", "ada"],
         ["screenshot", "screenshots/10-01, 10-02, 10-03", "ada"]])


def s_2():
    put("Ketiga gambar diambil dari perangkat Infinix 121512545B015596 dengan "
        "adb, lalu isinya dibaca ulang memakai OCR agar keterangan gambar tidak "
        "hanya bersandar pada nama berkas. Hasil OCR disimpan di "
        "docs/screenshots-ocr.txt.")
    tbl("Tabel 10. Gambar dan isi yang terbaca OCR",
        ["Gambar", "Isi terbaca"],
        [["10-01-asisten-kosong.png",
          "Asisten AI, Kunci: sk-airo-bR******, 0/20, teks ajakan bertanya"],
         ["10-02-asisten-jawaban.png",
          "pertanyaan jam layanan, jawaban tiga kalimat, 1/20"],
         ["10-03-asisten-offline-fallback.png",
          "Tidak ada koneksi internet. Mode offline, tombol Coba lagi, 2/20"]])


def s_3():
    sub("Fitur AI mana yang diintegrasikan dan mengapa?")
    put("Chat asisten kampus, karena satu fitur ini menyentuh seluruh rangkaian "
        "yang dinilai modul: kontrak domain, pemanggilan jaringan, penyimpanan "
        "kunci, kegagalan, dan biaya. Fitur yang lebih kecil, misalnya OCR satu "
        "gambar, tidak akan memaksa keputusan arsitektur apa pun.")
    sub("Bagaimana privasi pengguna dilindungi?")
    put("Tiga lapis: prompt sistem melarang membahas data pribadi, use case "
        "menolak pertanyaan kosong dan membatasi 500 karakter sebelum keluar, "
        "dan kunci hanya tersimpan di secure storage dengan tampilan tersamar. "
        "Yang tidak dikirim tetap dicatat sebagai risiko, karena aplikasi klien "
        "tidak dapat menjamin apa pun tentang perangkat pengguna.")
    sub("Fallback apa yang disediakan bila layanan AI error?")
    put("Setiap kegagalan menjadi Failure bertipe dengan pesan yang menyebut "
        "sebabnya, ditambah tombol Coba lagi yang mengulang pertanyaan terakhir. "
        "Fitur lain tidak ikut mati: pengumuman tetap dibuka dari cache lokal, "
        "dan hal itu terbukti pada Gambar 2.")
    sub("Satu hal yang dipelajari tentang UX fitur AI di mobile?")
    put("Waktu tunggu adalah bagian dari desain, bukan gangguan teknis. Model "
        "dengan token penalaran menjawab sekitar 30 detik, sehingga indikator "
        "proses harus terlihat sejak detik pertama dan pesan gagal harus "
        "menyebut penyebab yang dapat ditindaklanjuti. Pesan yang salah "
        "menyalahkan koneksi, padahal penyebabnya batas waktu, lebih buruk "
        "daripada tidak ada pesan sama sekali.")


ISI = {
    "Praktikum Ke-1": [("1 : Lapisan fitur AI", p1_1),
                       ("2 : Prompt sistem dan prompt pengguna", p1_2),
                       ("3 : Verifikasi usulan AI", p1_3)],
    "Praktikum Ke-2": [("1 : Dependensi dan penyimpanan kunci", p2_1),
                       ("2 : Layanan Inferhub dan pemetaan kegagalan", p2_2),
                       ("3 : Halaman chat dan state", p2_3),
                       ("4 : Empat belas test fitur baru", p2_4)],
    "Praktikum Ke-3": [("1 : Risiko dan mitigasi", p3_1),
                       ("2 : Fallback di perangkat", p3_2),
                       ("3 : Verifikasi mesin", p3_3)],
    "Soal Praktikum": [("Tugas 1 : Fitur yang dipilih", s_1),
                       ("Tugas 2 : Bukti perangkat dan OCR", s_2),
                       ("Refleksi", s_3)],
}

STYLE = {"Isi": "Laporan Isi", "Kode": "Laporan Kode", "Caption": "Laporan Caption",
         "Tabel Judul": "Laporan Tabel Judul", "Sel": "Laporan Sel",
         "SelHeader": "Laporan SelHeader"}


def pos(tb, row, cell, off=0):
    return {"story": "body", "path": [tb, row, cell, 0], "off": off}


def C(command, **params):
    return {"command": command, "params": params} if params else {"command": command}


def fill_table_ops(tb, row, ops_list):
    out = []
    paras = 1          # blok 0 = paragraf pertama sel
    for op in ops_list:
        k = op["k"]
        if k == "p":
            out.append(C("para.style", style=STYLE_ID[op["s"]]))
            out.append(C("text.insert", text=op["t"]))
            out.append(C("text.newParagraph"))
            paras += 1
        elif k == "img":
            out.append(C("para.style", style=STYLE["Sel"]))
            out.append(C("insert.picture", path=op["path"], width=op["w"]))
            out.append(C("text.newParagraph"))
            out.append(C("para.style", style=STYLE["Caption"]))
            out.append(C("text.insert", text=op["cap"]))
            out.append(C("text.newParagraph"))
            paras += 2
        else:
            # blok paras = judul, paras+1 = tabel, paras+2 = paragraf kosong
            # otomatis setelah tabel. DILARANG caret.set mundur ke judul:
            # insert.table di paragraf berisi teks menghasilkan tabel rusak.
            out.append(C("para.style", style=STYLE["Tabel Judul"]))
            out.append(C("text.insert", text=op["title"]))
            out.append(C("text.newParagraph"))
            ncol = len(op["header"])
            out.append(C("insert.table", rows=len(op["rows"]) + 1, cols=ncol))
            cells = [op["header"]] + op["rows"]
            total = sum(len(r) for r in cells)
            n = 0
            for ri, r in enumerate(cells):
                for v in r:
                    n += 1
                    out.append(C("text.insert", text=v))
                    out.append(C("select.paragraph"))
                    out.append(C("para.style",
                                 style=STYLE["SelHeader"] if ri == 0 else STYLE["Sel"]))
                    if n < total:
                        out.append(C("text.tab"))
            out.append(C("table.selectTable"))
            out.append(C("table.autofit", mode="fixed"))
            out.append(C("table.columnWidth", width=420.6 / ncol))
            out.append(C("table.borders", kind="all", width=0.5, color="808080"))
            out.append(C("caret.set",
                         pos={"story": "body", "path": [tb, row, 1, paras + 2],
                              "off": 0}))
            out.append(C("select.paragraph"))
            out.append(C("para.style", style=STYLE["Sel"]))
            paras += 2
    return out


STYLE_ID = {"Laporan Isi": "Laporan Isi", "Laporan Kode": "Laporan Kode",
            "Laporan Caption": "Laporan Caption",
            "Laporan Tabel Judul": "Laporan Tabel Judul",
            "Laporan Sel": "Laporan Sel", "Laporan SelHeader": "Laporan SelHeader",
            "Laporan Subsoal": "Laporan Subsoal"}


def build():
    data = {}
    for sec in SECTIONS:
        data[sec] = []
        for label, fn in ISI[sec]:
            del CUR[:]
            fn()
            data[sec].append({"label": label, "ops": list(CUR)})

    cmds = [C("file.setAuthor", name="Hermes via MCP"),
            # caption 10 pt: 9 pt terlalu kecil di cetak (lihat ATURAN-LAPORAN.md)
            C("styles.modify", style=STYLE["Caption"], chr={"size": 10}),
            C("caret.set", pos=pos(0, 0, 2)),
            C("select.paragraph"),
            C("text.insert", text="PEMOB"),
            C("caret.set", pos=pos(0, 6, 2)),
            C("select.paragraph"),
            C("text.insert", text="10")]

    for sec in SECTIONS:
        suffix = JUDUL[sec].split(" : ", 1)[1]
        cmds.append(C("caret.set", pos={"story": "body",
                                       "path": [HEAD_BLOCK[sec]],
                                       "off": len(sec)}))
        cmds.append(C("text.insert", text=" : " + suffix))

    for sec in SECTIONS:
        tb = TBL_BLOCK[sec]
        steps = data[sec]
        kurang = len(steps) + 1 - 4
        for _ in range(max(0, kurang)):
            cmds.append(C("caret.set", pos=pos(tb, 3, 0)))
            cmds.append(C("table.insertRowBelow"))
        for i, step in enumerate(steps, start=1):
            cmds.append(C("caret.set", pos=pos(tb, i, 0)))
            cmds.append(C("select.paragraph"))
            cmds.append(C("para.style", style=STYLE["Sel"]))
            cmds.append(C("text.insert", text=step["label"]))
            cmds.append(C("caret.set", pos=pos(tb, i, 1)))
            cmds.append(C("select.paragraph"))
            ops = fill_table_ops(tb, i, step["ops"])
            while ops and ops[-1]["command"] == "text.newParagraph":
                ops.pop()
            cmds.extend(ops)

    cmds.append(C("review.trackChanges", value=True))

    with open(TPL, "rb") as src, open(DOCX, "wb") as dst:
        dst.write(src.read())
    with open(JOB, "w", encoding="utf-8") as f:
        json.dump({"file": DOCX.replace("\\", "/"),
                   "commands": cmds, "save": [DOCX, PDF]}, f,
                  ensure_ascii=False, indent=1)
    print(f"perintah: {len(cmds)} -> {JOB}")


if __name__ == "__main__":
    build()