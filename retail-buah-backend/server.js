const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// 1. MIDDLEWARE
app.use(cors());
app.use(express.json());

// 4. KONFIGURASI SUPABASE
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// Test koneksi
supabase.from('users').select('count()', { count: 'exact' })
  .then(() => console.log('✅ Terhubung ke Supabase'))
  .catch((err) => console.error('❌ Gagal Koneksi Supabase:', err.message));

const JWT_SECRET = 'rahasia_toko_buah_super_aman';

// ================= ROUTES =================

// --- AUTH ---
app.post('/api/register', async (req, res) => {
  try {
    console.log('📝 Register attempt:', req.body.username);
    const { username, password, role } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const { error } = await supabase
      .from('users')
      .insert([{ username, password: hashedPassword, role: role || 'staff' }]);
    
    if (error) throw error;
    console.log('✅ User registered:', username, 'as', role);
    res.status(201).json({ message: "User berhasil dibuat" });
  } catch (err) {
    console.log('❌ Register error:', err.message);
    res.status(400).json({ message: "Username sudah ada atau error lainnya" });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    console.log('🔐 Login attempt:', req.body.username);
    const { data: users, error } = await supabase
      .from('users')
      .select('*')
      .eq('username', req.body.username);
    
    if (error || !users || users.length === 0) {
      console.log('❌ User not found:', req.body.username);
      return res.status(401).json({ message: "Username/Password Salah" });
    }
    
    const user = users[0];
    const passwordMatch = await bcrypt.compare(req.body.password, user.password);
    if (!passwordMatch) {
      console.log('❌ Password incorrect for:', req.body.username);
      return res.status(401).json({ message: "Username/Password Salah" });
    }
    
    const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    console.log('✅ Login berhasil:', user.username);
    res.json({ token, role: user.role, userId: user.id });
  } catch (err) {
    console.log('❌ Login error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

// --- PRODUCTS ---
app.get('/api/products', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    console.log('📦 Products fetched:', data.length);
    res.json(data);
  } catch (err) {
    console.log('❌ Error fetching products:', err.message);
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', req.params.id)
      .single();
    
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    const { nama, harga, stok, image_url } = req.body;
    
    const { data, error } = await supabase
      .from('products')
      .insert([{ nama, harga: parseInt(harga), stok: parseInt(stok), image_url }])
      .select();
    
    if (error) throw error;
    console.log('✅ Product added:', nama);
    res.status(201).json(data[0]);
  } catch (err) {
    console.log('❌ Error adding product:', err.message);
    res.status(500).json({ message: err.message });
  }
});

app.put('/api/products/:id', async (req, res) => {
  try {
    const { nama, harga, stok, image_url } = req.body;
    const updateData = { nama, harga: parseInt(harga), stok: parseInt(stok), image_url, updated_at: new Date() };
    
    const { data, error } = await supabase
      .from('products')
      .update(updateData)
      .eq('id', req.params.id)
      .select();
    
    if (error) throw error;
    console.log('✏️ Product updated:', nama);
    res.json(data[0]);
  } catch (err) {
    console.log('❌ Error updating product:', err.message);
    res.status(500).json({ message: err.message });
  }
});

app.delete('/api/products/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', req.params.id);
    
    if (error) throw error;
    console.log('🗑️ Product deleted');
    res.json({ message: "Produk berhasil dihapus" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- TRANSACTIONS ---
app.get('/api/transactions', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('transactions')
      .select('*')
      .order('tanggal', { ascending: false });
    
    if (error) throw error;
    console.log('💳 Transactions fetched:', data.length);
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.post('/api/transactions', async (req, res) => {
  try {
    const { product_id, product_name, quantity, price, total_price } = req.body;
    
    const { data, error } = await supabase
      .from('transactions')
      .insert([{ 
        product_id, 
        product_name, 
        quantity, 
        price,
        total_price,
        tanggal: new Date().toISOString()
      }])
      .select();
    
    if (error) throw error;
    console.log('✅ Transaction added:', product_name);
    res.status(201).json(data[0]);
  } catch (err) {
    console.log('❌ Error adding transaction:', err.message);
    res.status(500).json({ message: err.message });
  }
});

// --- STOCK MANAGEMENT ---
app.put('/api/products/:id/reduce-stock', async (req, res) => {
  try {
    const { quantity } = req.body;
    const productId = req.params.id;
    
    if (!quantity || quantity <= 0) {
      return res.status(400).json({ message: "Quantity harus lebih dari 0" });
    }
    
    console.log(`📉 Trying to reduce stock for product ${productId} by ${quantity}`);
    
    // Get current product
    const { data: product, error: fetchErr } = await supabase
      .from('products')
      .select('stok, nama')
      .eq('id', productId)
      .single();
    
    if (fetchErr) {
      console.error('❌ Error fetching product:', fetchErr);
      throw fetchErr;
    }
    
    if (!product) {
      console.error('❌ Product not found:', productId);
      return res.status(404).json({ message: "Produk tidak ditemukan" });
    }
    
    console.log(`📦 Current stock for ${product.nama}: ${product.stok}`);
    
    const newStok = Math.max(0, product.stok - quantity); // Tidak boleh negatif
    
    console.log(`📝 Updating stock to: ${newStok}`);
    
    const { data, error } = await supabase
      .from('products')
      .update({ stok: newStok, updated_at: new Date().toISOString() })
      .eq('id', productId)
      .select();
    
    if (error) {
      console.error('❌ Error updating stock:', error);
      throw error;
    }
    
    console.log(`✅ Stock reduced successfully. New stock: ${data[0].stok}`);
    res.json(data[0]);
  } catch (err) {
    console.error('❌ Stock reduction error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

// --- USERS MANAGEMENT ---
app.get('/api/users', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, username, role, created_at');
    
    if (error) throw error;
    console.log('👥 Users fetched:', data.length);
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/users/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, username, role, created_at')
      .eq('id', req.params.id)
      .single();
    
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put('/api/users/:id', async (req, res) => {
  try {
    const { role } = req.body;
    
    const { data, error } = await supabase
      .from('users')
      .update({ role })
      .eq('id', req.params.id)
      .select('id, username, role, created_at');
    
    if (error) throw error;
    console.log('✏️ User updated:', req.params.id);
    res.json(data[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.delete('/api/users/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', req.params.id);
    
    if (error) throw error;
    console.log('🗑️ User deleted');
    res.json({ message: "User berhasil dihapus" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- ANALYTICS ---
app.get('/api/analytics/summary', async (req, res) => {
  try {
    const { data: transactions, error: txError } = await supabase
      .from('transactions')
      .select('*');
    
    if (txError) throw txError;
    
    // Total penjualan
    const totalSales = transactions.reduce((sum, tx) => sum + (tx.total_price || 0), 0);
    
    // Penjualan hari ini
    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);
    
    const todaySales = transactions
      .filter(tx => {
        const txDate = new Date(tx.tanggal);
        return txDate >= todayStart && txDate < todayEnd;
      })
      .reduce((sum, tx) => sum + (tx.total_price || 0), 0);
    
    // Total transaksi
    const totalTransactions = transactions.length;
    
    console.log('📊 Analytics summary fetched');
    res.json({
      totalSales,
      todaySales,
      totalTransactions,
    });
  } catch (err) {
    console.error('❌ Analytics error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/analytics/best-selling', async (req, res) => {
  try {
    const { data: transactions, error: txError } = await supabase
      .from('transactions')
      .select('*');
    
    if (txError) throw txError;
    
    // Group by product_name
    const productMap = {};
    transactions.forEach(tx => {
      const name = tx.product_name || 'Unknown';
      if (!productMap[name]) {
        productMap[name] = {
          product_name: name,
          totalQuantity: 0,
          totalRevenue: 0,
        };
      }
      productMap[name].totalQuantity += tx.quantity || 0;
      productMap[name].totalRevenue += tx.total_price || 0;
    });
    
    // Sort by quantity
    const sorted = Object.values(productMap).sort((a, b) => b.totalQuantity - a.totalQuantity);
    
    console.log('⭐ Best selling products fetched');
    res.json(sorted);
  } catch (err) {
    console.error('❌ Best selling error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/analytics/daily-sales', async (req, res) => {
  try {
    const { data: transactions, error: txError } = await supabase
      .from('transactions')
      .select('*');
    
    if (txError) throw txError;
    
    // Get last 7 days
    const dailyMap = {};
    const now = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD
      dailyMap[dateKey] = 0;
    }
    
    // Sum sales per day
    transactions.forEach(tx => {
      const txDate = new Date(tx.tanggal);
      const dateKey = txDate.toISOString().split('T')[0];
      if (dailyMap.hasOwnProperty(dateKey)) {
        dailyMap[dateKey] += tx.total_price || 0;
      }
    });
    
    const result = Object.entries(dailyMap).map(([date, sales]) => ({
      date,
      sales,
    }));
    
    console.log('📈 Daily sales fetched');
    res.json(result);
  } catch (err) {
    console.error('❌ Daily sales error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

// ================= MIGRATION ENDPOINT =================

// Endpoint untuk add missing columns
app.post('/api/migrate/add-columns', async (req, res) => {
  try {
    console.log('🔧 Adding missing columns...');

    // Try to add columns - will fail gracefully if they already exist
    const columnsToAdd = [
      { name: 'product_name', type: 'VARCHAR(255)' },
      { name: 'quantity', type: 'INTEGER' },
      { name: 'price', type: 'INTEGER' },
      { name: 'total_price', type: 'INTEGER' },
      { name: 'image_url', type: 'TEXT' }
    ];

    const results = [];
    
    for (const col of columnsToAdd) {
      try {
        // Note: SQL execution via SDK is limited, we'll just report status
        results.push({
          column: col.name,
          status: 'pending - needs manual SQL execution'
        });
      } catch (err) {
        results.push({
          column: col.name,
          status: 'error',
          message: err.message
        });
      }
    }

    console.log('⚠️  Columns need manual SQL execution in Supabase console');
    res.json({
      status: 'partial',
      message: 'Please run 002_add_new_columns.sql in Supabase console',
      sqlFile: 'migrations/002_add_new_columns.sql',
      columns: results
    });

  } catch (err) {
    console.error('❌ Error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

// Endpoint untuk update data - convert field lama ke baru
app.post('/api/migrate/update-data', async (req, res) => {
  try {
    console.log('📝 Updating transaction data...');

    // Get all transactions
    const { data: allData, error: fetchError } = await supabase
      .from('transactions')
      .select('*');

    if (fetchError) throw fetchError;

    if (!allData || allData.length === 0) {
      return res.json({
        status: 'success',
        message: 'No data to update',
        recordsUpdated: 0
      });
    }

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    // Update each record
    for (const record of allData) {
      try {
        const updateData = {};

        // Map old field names to new ones if they exist
        if ('nama_buah' in record && record.nama_buah) {
          updateData.product_name = record.nama_buah;
        }
        if ('jumlah' in record && record.jumlah) {
          updateData.quantity = record.jumlah;
        }
        if ('total_harga' in record && record.total_harga) {
          updateData.total_price = record.total_harga;
        }

        // If record already has new fields, use them
        if ('product_name' in record && record.product_name) {
          updateData.product_name = record.product_name;
        }
        if ('quantity' in record && record.quantity) {
          updateData.quantity = record.quantity;
        }
        if ('total_price' in record && record.total_price) {
          updateData.total_price = record.total_price;
        }

        // Only update if there's data to update
        if (Object.keys(updateData).length > 0) {
          const { error: updateError } = await supabase
            .from('transactions')
            .update(updateData)
            .eq('id', record.id);

          if (updateError) {
            errors.push({
              id: record.id,
              error: updateError.message
            });
            errorCount++;
          } else {
            successCount++;
          }
        }
      } catch (err) {
        errors.push({
          id: record.id,
          error: err.message
        });
        errorCount++;
      }
    }

    console.log(`✅ Updated ${successCount}/${allData.length} records`);

    res.json({
      status: 'success',
      message: `Updated ${successCount} records, ${errorCount} errors`,
      recordsUpdated: successCount,
      totalRecords: allData.length,
      errors: errors.length > 0 ? errors.slice(0, 5) : undefined
    });

  } catch (err) {
    console.error('❌ Update error:', err.message);
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
});

// Endpoint untuk migrasi struktur tabel transaksi dari field lama ke baru
app.post('/api/migrate/transactions', async (req, res) => {
  try {
    console.log('🔄 Migration endpoint called');
    
    // STEP 1: Cek apakah tabel lama masih ada (dengan field lama)
    const { data: oldData } = await supabase
      .from('transactions')
      .select('*')
      .limit(1);

    if (!oldData || oldData.length === 0) {
      console.log('✅ Tabel sudah kosong atau tidak ada data lama');
      return res.json({ 
        status: 'success',
        message: 'Tidak ada data lama untuk dimigrasikan',
        recordsMigrated: 0
      });
    }

    // CEK STRUKTUR - apakah masih punya field lama?
    const firstRecord = oldData[0];
    const hasOldFields = 'nama_buah' in firstRecord || 'jumlah' in firstRecord || 'total_harga' in firstRecord;
    const hasNewFields = 'product_name' in firstRecord && 'quantity' in firstRecord && 'total_price' in firstRecord;

    if (!hasOldFields && hasNewFields) {
      console.log('✅ Struktur tabel sudah benar (field baru)');
      return res.json({
        status: 'success',
        message: 'Tabel sudah menggunakan struktur baru',
        recordsMigrated: 0
      });
    }

    console.log(`📋 Found ${oldData.length} records with old fields`);

    // STEP 2: Migrasi data - update field lama ke baru
    let migratedCount = 0;
    const errors = [];

    for (const record of oldData) {
      try {
        // Jika masih punya product_id dan field basic
        if (record.product_id && (record.nama_buah || record.product_name)) {
          const { error } = await supabase
            .from('transactions')
            .update({
              product_name: record.product_name || record.nama_buah,
              quantity: record.quantity || record.jumlah || 0,
              total_price: record.total_price || record.total_harga || 0,
              price: record.price || 0,
              image_url: record.image_url || null,
            })
            .eq('id', record.id);

          if (error) {
            errors.push({ id: record.id, error: error.message });
          } else {
            migratedCount++;
          }
        }
      } catch (err) {
        errors.push({ id: record.id, error: err.message });
      }
    }

    console.log(`✅ Migration complete: ${migratedCount}/${oldData.length} records updated`);

    if (errors.length > 0) {
      console.log(`⚠️  Errors during migration:`, errors);
    }

    res.json({
      status: 'success',
      message: `Migrasi selesai: ${migratedCount} records diupdate`,
      recordsMigrated: migratedCount,
      totalRecords: oldData.length,
      errors: errors.length > 0 ? errors : undefined
    });

  } catch (err) {
    console.error('❌ Migration error:', err.message);
    res.status(500).json({
      status: 'error',
      message: err.message,
      instruction: 'Jalankan: curl -X POST http://localhost:3000/api/migrate/transactions'
    });
  }
});

// ================= VERIFICATION ENDPOINT =================
// Endpoint untuk verify struktur tabel
app.get('/api/migrate/verify', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('transactions')
      .select('*')
      .limit(1);

    if (error) {
      return res.json({
        status: 'error',
        message: 'Tabel tidak ditemukan',
        error: error.message
      });
    }

    if (!data || data.length === 0) {
      return res.json({
        status: 'ok',
        message: 'Tabel kosong',
        hasData: false
      });
    }

    const record = data[0];
    const hasOldFields = 'nama_buah' in record || 'jumlah' in record || 'total_harga' in record;
    const hasNewFields = 'product_name' in record && 'quantity' in record && 'total_price' in record;
    const hasAllRequiredFields = 'product_id' in record && 'tanggal' in record;

    res.json({
      status: hasNewFields && hasAllRequiredFields ? 'ok' : 'warning',
      message: hasNewFields ? 'Struktur OK' : 'Ada field lama',
      structure: {
        hasOldFields,
        hasNewFields,
        hasAllRequiredFields,
        fields: Object.keys(record)
      },
      sampleRecord: record
    });

  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
});

// 6. JALANKAN SERVER
const PORT = process.env.PORT || 3000;

// Untuk local development
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => console.log(`🚀 Server jalan di http://localhost:${PORT}`));
}

// Export untuk Vercel serverless
module.exports = app;
