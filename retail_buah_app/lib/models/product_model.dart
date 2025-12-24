class Product {
  final String id;
  final String nama;
  final int harga;
  final int stok;
  final String? gambar; // Tambahan field gambar (bisa null)

  Product({
    required this.id, 
    required this.nama, 
    required this.harga, 
    required this.stok,
    this.gambar
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['_id'] ?? '',
      nama: json['nama'] ?? '',
      harga: json['harga'] ?? 0,
      stok: json['stok'] ?? 0,
      gambar: json['gambar'], // Ambil nama file gambar
    );
  }
}