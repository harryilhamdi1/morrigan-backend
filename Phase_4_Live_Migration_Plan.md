# Phase 4: Full-Stack Live Migration (Unified App)

## Objective
Gabungkan "ESS Retail Analysis" dan "Action Plan Monitoring" menjadi satu ekosistem Super App terintegrasi dengan arsitektur modern (Backend + Frontend terpisah).

## Proposed Architecture
1. **Supabase (Backend Administrator & Data Storage):** 
    - Autentikasi user terpusat (Login screen untuk Store Head, HoB, HCBP).
    - Database PostgreSQL utama untuk tabel operasional: `stores`, `action_plans`, `approvals`, dan `profiles`.
    - Tabel analitik: `kpi_scores` dan `wave_analysis` untuk menyimpan hasil agregasi raw data dari CSV.
    - *Catatan:* Data agregasi "Wave" dari `build.js` harus diimpor ke Supabase agar frontend bisa membaca data live tanpa mengandalkan file CSV lokal.
2. **Google Drive (Storage):**
    - Endpoint untuk menampung file Execution Proof (foto/dokumen) yang diupload oleh Store Heads. 
    - Kelebihan: Kuota storage besar, mudah diakses manajemen.
3. **Node.js (File Administration & API Gateway):**
    - Berfungsi sebagai "Middleman" atau Middleware API.
    - Menangani logika upload file berat dari Frontend ke Google Drive API dengan aman menggunakan Service Account.
    - Menjalankan cron jobs atau skrip agregasi otomatis secara berkala.
4. **Hostinger (Hosting & Frontend Logic):**
    - Tempat hosting Domain (e.g., eigerretail.com).
    - Menyimpan file Frontend (HTML/CSS/JS) dari Dashboard Analysis dan Action Plan.
    - Memproses antarmuka pengguna, chart rendering, dan memanggil API (Supabase & Node.js).

## Frontend Adaptation (The "Hub" Portal)
- **Hub Landing Page:** Buat halaman Login utama. Setelah berhasil login, user akan melihat "Hub Portal" berupa 2 buah Tiles raksasa: "Retail Analysis" dan "Action Plan Monitoring".  
- **Role-Based Access Control (RBAC):** Otomatis menyembunyikan atau mendisable Tile "Analysis" atau fitur-fitur tertentu di dalamnya jika Role/Profile login tidak memiliki hak akses.
- **Unassessed Store Protocol (Blank Stores):**
  - *Analysis Dashboard:* Jika toko baru/belum diaudit (misal: ada di master list tapi tidak ada di Wave CSV) dipilih, seluruh Gauge Chart/Skor menampilkan "N/A" atau "Pending Initial Audit" dan mengecualikannya dari rata-rata Regional/National.
  - *Action Plan Dashboard:* Meng-generate tugas *baseline* secara otomatis yang secara **ketat mengacu pada Master Scorecard**. Alih-alih membuat tugas *random*, sistem akan memunculkan 1 tugas perwakilan dari titik krusial Customer Journey (berdasarkan data `Scorecard.csv`), misalnya:
    1. **Journey: (Section) A. Tampilan Tampak Depan Outlet** -> *Tugas: Memastikan Signage, Fasad, dan Window Display dalam kondisi bersih, menyala (stand alone), dan bebas debu (Referensi: 759166 - 759171).*
    2. **Journey: (Section) B. Sambutan Hangat Ketika Masuk ke Dalam Outlet** -> *Tugas: Re-training SPG/SPB untuk melakukan Eye Contact, Senyum 1 Jari, Tangan Kanan di Dada Kiri, dan ucapan "Selamat Datang di EIGER" (Referensi: 759174 - 759177).*
    3. **Journey: (Section) C. Suasana & Kenyamanan Outlet** -> *Tugas: Audit kebersihan Store (Apparel rapi, suhu nyaman, lampu terang, TV Promo menyala, Banner up-to-date) (Referensi: 759181 - 759192).*
    4. **Journey: (Section) F. Pengalaman Mencoba Produk** -> *Tugas: Pengecekan standar Fitting Room (cermin tanpa cap tangan, bebas sampah, tidak ada sisa gantungan) (Referensi: 759223 - 759228).*
    5. **Journey: (Section) H. Pembelian Produk & Pembayaran di Kasir** -> *Tugas: Simulasi kelengkapan kasir (Salam, Konfirmasi barang, Tawar Member EAC, Stempel Garansi, Salam Penutup) (Referensi: 759247 - 759267).*
  - **Sistem ini akan memasukkan *Action Plan* terstandardisasi ini ke database supaya Store Head punya arahan audit internal yang akurat.**
- Update all "Approve/Reject" buttons to send UPDATE requests to the database, instantly reflecting changes on the frontend.
