# 🍎 Retail Buah App (Fruit Store Management)

Aplikasi Full-Stack untuk manajemen toko buah retail. Dirancang untuk mempermudah pengelolaan stok (Inventory) dan transaksi penjualan (Point of Sales) dengan pemisahan hak akses antara **Admin** dan **Staff**.

**Status:** ✅ Backend API Siap | ✅ Frontend Responsive | ✅ Database Clean (Supabase PostgreSQL)

---

## ✨ Fitur Utama

### 🛡️ Autentikasi (Auth)
* **Login & Register:** Menggunakan JWT (JSON Web Token) untuk keamanan.
* **Role-Based Access:** Navigasi berbeda untuk Admin dan Staff.
* **Password Security:** Bcrypt hashing untuk keamanan password.

### 👤 Admin Dashboard
* **Kelola Produk (CRUD):** Tambah, Edit, Hapus data buah.
* **Upload Gambar:** Upload foto buah ke Supabase Storage.
* **Laporan Penjualan:** Melihat riwayat transaksi dan total pendapatan.
* **Search & Filter:** Pencarian buah berdasarkan nama.

### 🛒 Staff Dashboard (Kasir)
* **Katalog Visual:** Melihat daftar buah beserta foto dan sisa stok.
* **Indikator Stok:** Peringatan warna merah jika stok menipis.
* **Transaksi Penjualan:** Input jumlah dan pengurangan stok otomatis.
* **Validasi Stok:** Mencegah penjualan jika stok tidak mencukupi.

### 📊 Analytics & Reporting
* **Riwayat Transaksi:** Pencatatan lengkap setiap transaksi.
* **Dashboard Analytics:** Visualisasi data penjualan.
* **Export Data:** Laporan dalam format JSON/CSV.

---

## 🛠️ Tech Stack

**Frontend:**
* **Framework:** Flutter (Dart)
* **HTTP Client:** Dio
* **Image Picker:** image_picker
* **Currency Format:** intl

**Backend:**
* **Runtime:** Node.js
* **Framework:** Express.js
* **Database:** Supabase (PostgreSQL)
* **Authentication:** JWT (JSON Web Token)
* **Security:** Bcryptjs

---

## 📋 Database Schema

### 🗄️ Tabel: `products`
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama VARCHAR(255) NOT NULL,
  harga INTEGER NOT NULL,
  stok INTEGER NOT NULL,
  image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 🗄️ Tabel: `transactions`
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id),
  product_name VARCHAR(255) NOT NULL,
  quantity INTEGER NOT NULL,
  price INTEGER NOT NULL,
  total_price INTEGER NOT NULL,
  tanggal TIMESTAMP DEFAULT NOW(),
  image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 🗄️ Tabel: `users`
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role VARCHAR(50) DEFAULT 'staff',
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🚀 Quick Start Guide

### Prerequisites
- **Node.js** v14+ (https://nodejs.org)
- **Flutter** v3.0+ (https://flutter.dev)
- **Supabase** Account (https://supabase.com)
- **Git** (https://git-scm.com)

### 1️⃣ Setup Supabase Database

1. Buka https://app.supabase.com dan login dengan akun Anda
2. Buat project baru atau gunakan yang sudah ada
3. Masuk ke **SQL Editor**
4. Copy-paste SQL schema dari bagian [Database Schema](#-database-schema) di atas
5. Klik **Run** untuk membuat tabel

### 2️⃣ Setup Backend (Node.js)

```bash
# 1. Masuk folder backend
cd retail-buah-backend

# 2. Instal dependency
npm install
```

#### 📝 Konfigurasi File `.env`

Buat file `.env` di root folder `retail-buah-backend/` dengan konten berikut:

```env
# ============================================================
# SUPABASE CONFIGURATION
# ============================================================
# Dapatkan dari: https://app.supabase.com → Settings → API

# URL project Supabase Anda
SUPABASE_URL=https://your-project-id.supabase.co

# Service Role Key (untuk server-side operations)
# ⚠️ JANGAN bagikan key ini ke publik!
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ============================================================
# SERVER CONFIGURATION
# ============================================================

# Port tempat server berjalan
PORT=3000

# Environment (development, production)
NODE_ENV=development

# ============================================================
# JWT CONFIGURATION
# ============================================================

# Secret key untuk JWT token (generate dengan string random)
JWT_SECRET=your-super-secret-jwt-key-here-min-32-characters

# JWT expiration time
JWT_EXPIRY=7d

# ============================================================
# CORS & SECURITY
# ============================================================

# Allowed origins untuk CORS (pisahkan dengan koma)
CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://10.0.2.2:3000

# ============================================================
# LOGGING & DEBUG
# ============================================================

# Log level (error, warn, info, debug)
LOG_LEVEL=debug

# Enable detailed logging
DEBUG=true
```

**🔑 Cara mendapatkan SUPABASE_URL dan SUPABASE_SERVICE_KEY:**

1. Buka https://app.supabase.com dan login
2. Pilih project Anda (atau buat project baru)
3. Masuk ke **Settings** → **API**
4. Copy informasi berikut:
   - **Project URL** → paste ke `SUPABASE_URL`
   - **Service Role Key** (jangan gunakan anon key) → paste ke `SUPABASE_SERVICE_KEY`

**⚠️ PENTING:**
- `.env` file **JANGAN** di-push ke GitHub (sudah ada di `.gitignore`)
- Service Key adalah secret, jangan bagikan ke siapa pun
- Berbeda dengan Anon Key yang bisa publik
- Untuk production, gunakan environment variables dari hosting (Vercel, Heroku, dll)

```bash
# 3. Jalankan server
npm start
# Output: ✅ Server running on http://localhost:3000
```

### 3️⃣ Setup Frontend (Flutter)

```bash
# 1. Masuk folder frontend
cd retail_buah_app

# 2. Download dependencies
flutter pub get

# 3. Konfigurasi API URL
# Edit lib/main.dart atau constant file untuk mengatur URL backend:
# const String API_URL = "http://localhost:3000";

# 4. Jalankan aplikasi
# Untuk Web:
flutter run -d chrome

# Untuk Android:
flutter run

# Untuk iOS:
flutter run -d ios
```

---

## 📡 API Endpoints Documentation

### 🔐 **Authentication**
| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| POST | `/api/auth/register` | `{email, password, role}` | `{token, user}` |
| POST | `/api/auth/login` | `{email, password}` | `{token, user}` |

### 📦 **Products (CRUD)**
| Method | Endpoint | Body | Auth Required |
|--------|----------|------|---|
| GET | `/api/products` | - | ❌ |
| GET | `/api/products/:id` | - | ❌ |
| POST | `/api/products` | `{nama, harga, stok, image_url}` | ✅ Admin |
| PUT | `/api/products/:id` | `{nama, harga, stok}` | ✅ Admin |
| DELETE | `/api/products/:id` | - | ✅ Admin |

### 💳 **Transactions**
| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| GET | `/api/transactions` | - | `[transactions]` |
| POST | `/api/transactions` | `{product_id, product_name, quantity, price, total_price}` | `{id, ...}` |

### 📊 **Analytics**
| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/analytics/summary` | `{total_revenue, total_transactions}` |
| GET | `/api/analytics/daily` | `[{date, total}]` |

---

## 📂 Struktur Folder

```
Retail-Mobile-Developments/
│
├── retail_buah_app/                 # Frontend Flutter
│   ├── lib/
│   │   ├── main.dart               # Entry point aplikasi
│   │   ├── models/
│   │   │   └── product_model.dart  # Data model produk
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── staff_dashboard.dart
│   │   │   ├── login.dart
│   │   │   ├── register.dart
│   │   │   ├── product_detail_screen.dart
│   │   │   ├── report_screen.dart
│   │   │   └── analytics_dashboard.dart
│   │   └── widgets/
│   │       └── theme_toggle_button.dart
│   └── pubspec.yaml
│
├── retail-buah-backend/             # Backend Node.js + Express
│   ├── server.js                    # Main API server
│   ├── models/
│   │   ├── Product.js
│   │   ├── User.js
│   ├── package.json
│   ├── .env                         # Environment variables (create this)
│   └── uploads/                     # Folder untuk penyimpanan gambar
│
└── README.md                        # File ini

---

## 🔧 Development Workflow

### Clone Repository
```bash
git clone <repository-url>
cd Retail-Mobile-Developments
```

### Create New Branch (untuk fitur baru)
```bash
git checkout -b feature/nama-fitur
# Kerjakan fitur
# Commit changes
git add .
git commit -m "feat: deskripsi fitur baru"
git push origin feature/nama-fitur
```

### Pull Latest Changes
```bash
git pull origin main
```

### Push ke GitHub
```bash
git add .
git commit -m "pesan commit"
git push origin branch-name
```

---

## 🚨 Troubleshooting

### ❌ Backend Error: Port 3000 sudah terpakai
**Solusi:**
```bash
# Cari proses yang menggunakan port 3000
lsof -i :3000           # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill proses
kill -9 <PID>           # macOS/Linux
taskkill /F /PID <PID> # Windows

# Atau gunakan port lain di .env
PORT=3001
```

### ❌ Error: "Could not connect to database"
**Solusi:**
1. Verifikasi `.env` sudah dibuat dengan benar
2. Check SUPABASE_URL dan SUPABASE_KEY di Supabase Dashboard
3. Pastikan koneksi internet aktif
4. Cek RLS policies di Supabase (harus allow select/insert)

### ❌ Flutter: "Certificate verification failed"
**Solusi (untuk localhost):**
```dart
// Di main.dart atau service API
HttpClient client = HttpClient();
client.badCertificateCallback = (cert, host, port) => true;
```

### ❌ Transaksi gagal dengan error "Column not found"
**Solusi:**
1. Pastikan tabel `transactions` sudah dibuat dengan schema yang benar
2. Check field names di POST body dan database harus match
3. Jalankan SQL schema ulang jika diperlukan

### ❌ Image upload gagal
**Solusi:**
1. Pastikan folder `uploads/` ada di backend directory
2. Check permission folder (harus writable)
3. Verifikasi storage rules di Supabase (jika menggunakan Supabase Storage)

---

## 📝 Important Notes

### ✅ Database Migrations Done
- ✅ Tabel `products` - READY
- ✅ Tabel `transactions` - FRESH TABLE (clean schema)
- ✅ Tabel `users` - READY
- ✅ All old migration code removed
- ✅ Supabase RLS policies configured

### 🔒 Security Checklist
- ✅ Password hashing dengan Bcrypt
- ✅ JWT authentication untuk protected routes
- ✅ Environment variables untuk sensitive data
- ✅ CORS configuration untuk API access
- ✅ Input validation di backend
- ✅ SQL injection protection (Supabase parametrized queries)

### 📱 Supported Platforms
- ✅ Web (Chrome, Edge, Firefox)
- ✅ Android (API 21+)
- ✅ iOS (iOS 11+)
- 🔄 Windows (experimental)

---

## 🚀 Deployment Guide

### Deploy Backend ke Vercel
```bash
# 1. Instal Vercel CLI
npm install -g vercel

# 2. Login
vercel login

# 3. Deploy
cd retail-buah-backend
vercel

# 4. Set environment variables di Vercel Dashboard
# SUPABASE_URL, SUPABASE_KEY, JWT_SECRET
```

### Deploy Frontend ke Firebase Hosting
```bash
# 1. Instal Firebase CLI
npm install -g firebase-tools

# 2. Login dan initialize
firebase login
firebase init

# 3. Build Flutter Web
flutter build web

# 4. Deploy
firebase deploy
```

### Update URL di Flutter setelah deploy
```dart
// Gunakan environment variables atau build flavors
const String API_URL = String.fromEnvironment('API_URL', 
  defaultValue: 'http://localhost:3000'
);

// Build dengan custom URL:
// flutter run --dart-define=API_URL=https://your-api.vercel.app
```

---

## 📚 Dokumentasi & Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Express.js Docs:** https://expressjs.com
- **Supabase Docs:** https://supabase.com/docs
- **Dio HTTP Client:** https://pub.dev/packages/dio
- **JWT Introduction:** https://jwt.io

---

## 👥 Contributing

1. Fork repository ini
2. Create branch baru (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📞 Support

Jika ada pertanyaan atau issue, silakan:
1. Create Issue di GitHub
2. Hubungi tim development
3. Check documentation di folder `/docs`

---

## 📄 License

Project ini dibuat untuk keperluan educational dan commercial use.

---

**Last Updated:** December 2024  
**Status:** ✅ Production Ready
