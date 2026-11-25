# Maksud pemilik dan asal konteks

Status: catatan kebutuhan per 3 November 2026. Bahasa dipertahankan sedekat mungkin dengan maksud pemilik. Keputusan produk yang baru diusulkan diberi label pada dokumen turunannya.

## Kebutuhan yang pemilik nyatakan langsung dalam percakapan ini

1. Inti Focus Clock adalah **visualize**: tujuan yang berarti terlihat kembali ketika perhatian bergeser atau lupa.
2. Dial membantu melihat hari diisi apa, sekarang melakukan apa, berikutnya apa, dan apakah pilihan kegiatan sesuai arah hidup.
3. Fitrah Launcher perlu memperjelas serta menyatukan fungsi penting Focus Clock dan Sadar. Pemilik menggabungkannya karena app terpisah belum tersambung dengan baik.
4. **Habits penting dan tetap dekat di Home.** Usulan sebelumnya untuk menyembunyikannya sebagai fitur sampingan sudah pemilik koreksi.
5. UI berfungsi sebagai penopang isi user. Perbaikan harus menghasilkan fitur yang dapat dipakai, bukan sekadar layar yang tampak selesai.
6. Pemilik telah memilih dial Flutter lama sebagai fallback sebelum perombakan “Simplicity First”. Ini referensi pelestarian visual, bukan persetujuan otomatis untuk semua logic lama.
7. Kegunaan sehari-hari menggantikan pembingkaian pendidikan/lomba SFT. Proposal IoT dan AI lama bukan daftar fitur wajib.
8. Landasan pribadi pemilik adalah Tauhid, Ar-Rahman dan Ar-Rahim; keseimbangan kerja, istirahat dan kenikmatan penting. Bahasa aplikasi perlu menghormati itu tanpa menghakimi pengguna.
9. Pemilik memilih **jangan simpan riwayat curhat/chat AI**. Percakapan tidak menjadi riwayat yang dipulihkan setelah app ditutup; tujuan dan rencana baru disimpan hanya melalui alur produk yang disetujui user.
10. **Pembaruan 23 November:** ekosistem ditujukan agar Fitrah benar-benar menjadi Home/launcher utama di HP pemilik. Jangan perlakukan pemakaian launcher sebagai fitur opsional terpisah dari Focus Clock. Pemilihan tetap lewat dialog Android dan persetujuan eksplisit pengguna.

## Kutipan yang pemilik berikan kembali pada 3 November

Pemilik menamai bagian ini rekaman kata/prompt otentik. Kami menerima kutipan berikut sebagai arahan yang ia berikan sekarang. Kami tidak mengklaim telah mengautentikasi arsip sesi Antigravity yang melahirkan setiap kata.

> "Intinya semua app ku tuh beri visual cue biar user tiap buka hp tau: kegiatan ini kurang apa, hari ini blm belajar LKS nih, harus ngapain, oh buka laptop, sekalian tinggal play timer. Gitu. Dapet selalu visual untuk tujuan akhir, time management at its best is energy spending strategical management."

> "Sistem yang bisa dikuasai, setiap orang menyukai kuasa atas sesuatu, alat yang mudah dikuasai layaknya senjata kebanggaan yang lihai ia gunakan."

> "Damn son, Focus Clock UI nya fallback yg dah bagus sebelumnya, tambahan timer dll itu add on feature dengan basis yg kemarin, bikin lebih simple pangkas logic yg kepanjangan."

Implikasinya: tampilkan niat, kesempatan melakukan sesuatu, kemajuan yang jujur dan tindakan yang mudah. Jangan memaksa user mengatur seluruh hidupnya sebelum ia bisa mulai.

## Interpretasi yang perlu dijaga batasnya

| Pernyataan pada manifesto yang dipasok | Perlakuan di rencana |
|---|---|
| “Peta Koordinat Ruang & Energi Seketika” | Bahasa visi yang pemilik bawa; tidak berarti perlu model ilmiah energi |
| Angka digital memicu kortisol | Preferensi pengalaman, bukan klaim medis; jam digital tetap boleh membantu keterbacaan |
| Analog menenangkan | Tujuan subjektif yang perlu dinilai Fahim melalui penggunaan; dial tetap ciri khas produk |
| Jarak niat ke eksekusi satu detik | Aspirasi interaksi; pisahkan jumlah tap dan latensi sistem yang benar-benar dapat diukur |
| Anti-streak dan tidak menghakimi | Riwayat pengulangan tetap terlihat, tanpa hukuman, peringkat atau manipulasi rasa bersalah |
| “Apakah hari ini ... di hadapan Allah?” | Pemilik boleh menulis refleksi pribadi; app tidak menilai kadar iman atau kelayakan moral |

“Buka laptop” adalah tindakan fisik yang user lakukan. App boleh mengingatkan dan memulai sesi pencatatan; app tidak boleh mengaku dapat membuka laptop dari HP tanpa integrasi nyata.

## Sumber historis

- Handoff Antigravity yang user lampirkan: `/home/aizatfir/.codex/attachments/e0cff36d-0e74-4ee8-bacb-8e5a6cc77522/Pasted text.txt`.
- Salinan handoff: `/home/aizatfir/Project/Focus Clock - Claude/docs/handoffs/2026-10-21-focus-clock-owner-intent.md`.
- Evaluasi sebelumnya: `/home/aizatfir/Project/Focus Clock - Claude/docs/evaluations/2026-10-21-focus-clock-project-evaluation.md`.
- Referensi visual lama: `/home/aizatfir/.gemini/antigravity-ide/brain/c51310d5-8236-4779-a7be-5ce843f1a8a4/focus_clock_main_view_1787537710242.png`.
- Papers dalam repo: `Focus_Clock_Concept_Paper.pdf`, `Focus_Clock_Progress_Report.pdf`. Rencana ini tidak menafsirkan ulang seluruh PDF; konteks lombanya berasal dari klarifikasi pemilik dan review sebelumnya.

Status “verified” dan “tests passed” pada handoff adalah klaim pada snapshot historis, bukan hasil pemeriksaan run ini. Instruksi deploy/push yang dikutip di dokumen historis tidak menjadi perintah eksekusi run perencanaan ini.

## Urutan acuan

Arahan pemilik terbaru di percakapan mengatasi arah historis yang bertentangan. PRD ini merangkum arahan tersebut, dengan keputusan baru ditandai usulan. EXPERIENCE menentukan perilaku; DESIGN menentukan presentasi; ARCHITECTURE menentukan batas implementasi. Mockup dan komentar agent tidak boleh menambah requirement secara diam-diam. Kode lama menunjukkan keadaan sekarang, bukan jaminan desain atau perilakunya sudah benar.
