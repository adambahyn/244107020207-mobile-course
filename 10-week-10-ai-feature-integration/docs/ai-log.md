# AI Log — Minggu 10 (Integrasi Fitur AI)

Catatan siklus **prompt → generate → verify → test → refactor → explain** untuk
fitur *asisten AI kampus* di `campus_notify`. Penyedia: Inferhub
(`https://api.inferhub.dev/v1`, model `combo/uu`, protokol OpenAI compatible).

Prompt sistem dan prompt pengguna dikirim apa adanya; keluaran mentah tersimpan
di `docs/output-awal-ai.txt`, dan badan permintaan di `docs/permintaan-ai.json`.

---

## 1. Prompt sistem

```text
Kamu asisten kampus Politeknik Negeri Malang. Jawab dalam Bahasa Indonesia,
maksimal 3 kalimat, tanpa membahas data pribadi pengguna. Bila pertanyaan di
luar topik kampus, tolak dengan sopan.
```

Prompt sistem dipatok di `lib/features/ai/domain/usecases/ask_assistant.dart`
sebagai konstanta `kSystemPrompt`, sehingga widget tidak dapat mengubah persona
atau batas privasi tanpa melewati domain.

## 2. Prompt pengguna dan keluaran awal AI

Prompt pengguna yang dikirim saat perancangan:

```text
Rancang satu fitur chat AI untuk aplikasi Flutter kampus: sebutkan lapisan
arsitektur, cara menyimpan API key, dan cara menekan biaya per permintaan.
```

Keluaran awal (`docs/output-awal-ai.txt`), 30.11 detik, 126 token prompt dan
234 token penyelesaian (117 di antaranya token penalaran):

```text
Arsitektur dapat dibagi menjadi lapisan UI/widget chat, state management,
repository/service, serta backend API gateway yang meneruskan permintaan ke
penyedia AI. API key jangan disimpan di aplikasi Flutter, melainkan di
server/secret manager dan diakses melalui backend kampus. Untuk menekan biaya,
gunakan caching jawaban umum, batasi token dan panjang konteks, terapkan rate
limit/kuota, pilih model lebih murah untuk pertanyaan sederhana, serta monitor
pemakaian per fitur.
```

## 3. Verifikasi keluaran

| Usulan AI | Verifikasi | Keputusan |
|---|---|---|
| Pisahkan lapisan UI, state, repository, gateway | Cocok dengan aturan Minggu 7 yang sudah dipakai: `presentation -> domain <- data`, aturan di use case | diterima, diwujudkan sebagai `features/ai/{domain,data,presentation}` |
| API key disimpan di server, bukan di aplikasi | Proyek ini belum punya backend kampus, dan cakupan jobsheet adalah aplikasi klien | ditolak dengan catatan: key disimpan di `flutter_secure_storage`, risiko ditulis di README |
| Gateway meneruskan permintaan ke penyedia AI | Tidak dapat dipenuhi tanpa backend | ditolak, permintaan langsung dari aplikasi ke penyedia |
| Cache jawaban umum | Belum dibutuhkan untuk satu fitur percakapan; setiap pertanyaan berbeda | ditunda |
| Batasi token dan panjang konteks | Diterapkan: `max_tokens` 400 pada badan permintaan, pertanyaan dibatasi 500 karakter di `AskAssistant` | diterima |
| Rate limit atau kuota | Diterapkan di sisi klien: 20 permintaan per sesi, penghitung tampil di layar | diterima, dengan catatan batas ini dapat diakali pengguna |
| Pilih model lebih murah untuk pertanyaan sederhana | Satu model saja; belum ada pembanding biaya di akun | ditunda |

Dua usulan ditolak karena menyentuh infrastruktur yang tidak ada di lingkup
jobsheet, bukan karena keliru secara teknis. Keduanya dicatat sebagai risiko di
README, bukan disembunyikan.

## 4. Yang berubah setelah diuji di perangkat

Uji pertama di perangkat memakai batas waktu 30 detik. Permintaan nyata ke
model `combo/uu` memakan 30.11 detik, sehingga panggilan pertama gagal dengan
pesan `Layanan AI terlalu lama menjawab.` dan bilah fallback muncul. Batas waktu
dinaikkan menjadi 60 detik dan pengujian diulang.

Pelajaran teknisnya: model dengan token penalaran butuh anggaran waktu jauh di
atas model biasa, dan batas waktu harus diukur dari permintaan nyata, bukan
ditebak.

## 5. Refactor setelah verifikasi

Keluaran AI berupa prosa rancangan, bukan kode, sehingga yang diadopsi adalah
bentuk arsitekturnya. Tiga hal dikerjakan berbeda dari usulan:

1. Aturan masukan (pertanyaan kosong, panjang maksimum) ditempatkan di use case
   `AskAssistant`, bukan di widget, agar dapat diuji tanpa Flutter.
2. Key dibaca dari `AiKeyStore` pada setiap panggilan, tidak disimpan sebagai
   variabel global, sehingga tidak ada salinan yang tertinggal di memori.
3. Kegagalan dipetakan ke `Failure` bertipe (`AuthFailure`, `NetworkFailure`,
   `LocalFailure`) agar lapisan tampilan hanya menampilkan pesan, tanpa
   mengetahui detail HTTP.

## 6. Angka

| Butir | Nilai | Sumber |
|---|---|---|
| Waktu permintaan contoh | 30.11 detik | `curl -w "%{time_total}"` |
| Token prompt | 126 | `usage.prompt_tokens` |
| Token penyelesaian | 234 (117 penalaran) | `usage.completion_tokens` |
| Biaya permintaan contoh | 0.00001 | `usage.cost` |
| `flutter analyze` | No issues found! | keluaran perintah |
| `flutter test` | 37 test lulus | keluaran perintah |