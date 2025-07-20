from django.db import models
from django.db import transaction
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.utils.timezone import now

class User(models.Model):
    ROLE_CHOICES = (
        ('admin', 'Admin'),
        ('kasir', 'Kasir'),
    )

    name = models.CharField(max_length=100)
    username = models.CharField(max_length=100, unique=True)
    password = models.CharField(max_length=256)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)

    def __str__(self):
        return self.username

class Produk(models.Model):
    kode = models.CharField(max_length=50, unique=True)
    nama = models.CharField(max_length=100)
    satuan = models.CharField(max_length=20)
    harga_jual = models.DecimalField(max_digits=12, decimal_places=2)

    def __str__(self):
        return f"{self.kode} - {self.nama}"

class Pembelian(models.Model):
    nomor_btb = models.CharField(max_length=100, unique=True, blank=True)
    tanggal = models.DateField(auto_now_add=True)
    supplier = models.CharField(max_length=100, blank=True, null=True)

    def __str__(self):
        return f"Nota {self.nomor_btb}"

    def save(self, *args, **kwargs):
        if not self.nomor_btb:
            today = now()
            tahun = today.strftime('%Y')
            bulan = today.strftime('%m')
            prefix = f"BTB/{tahun}/{bulan}"

            with transaction.atomic():
                # Kunci baris-baris yang relevan agar tidak diakses bersamaan
                last_btb = (
                    Pembelian.objects.select_for_update()
                    .filter(nomor_btb__startswith=prefix)
                    .order_by('-nomor_btb')
                    .first()
                )

                if last_btb:
                    last_number = int(last_btb.nomor_btb.split('/')[-1])
                    new_number = last_number + 1
                else:
                    new_number = 1

                self.nomor_btb = f"{prefix}/{new_number:04d}"

                # Simpan dalam atomic block untuk memastikan tidak bentrok
                super().save(*args, **kwargs)
        else:
            # Jika nomor_btb sudah ada, simpan seperti biasa
            super().save(*args, **kwargs)

class DetailPembelian(models.Model):
    pembelian = models.ForeignKey(Pembelian, on_delete=models.CASCADE, related_name='detail_pembelian')
    produk = models.ForeignKey(Produk, on_delete=models.CASCADE)
    jumlah = models.IntegerField()
    harga_beli = models.DecimalField(max_digits=12, decimal_places=2)

    def subtotal(self):
        return self.jumlah * self.harga_beli
    
    def save(self, *args, **kwargs):
        is_new = self._state.adding  # hanya tambahkan kartu stok kalau data baru
        super().save(*args, **kwargs)
        if is_new:
            KartuStok.objects.create(
                produk=self.produk,
                jenis='masuk',
                jumlah=self.jumlah,
                sumber=f"{self.pembelian.nomor_btb}",
                keterangan="Pembelian"
            )

class Penjualan(models.Model):
    nomor_nota = models.CharField(max_length=100, unique=True)
    tanggal = models.DateField(auto_now_add=True)
    total_harga = models.DecimalField(max_digits=15, decimal_places=2)
    pembayaran = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    kembalian = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"Penjualan {self.nomor_nota}"

class DetailPenjualan(models.Model):
    penjualan = models.ForeignKey(Penjualan, related_name='detail_penjualan', on_delete=models.CASCADE)
    produk = models.ForeignKey(Produk, on_delete=models.CASCADE)
    jumlah = models.PositiveIntegerField()
    harga_jual = models.DecimalField(max_digits=15, decimal_places=2, blank=True, null=True)

    def hitung_stok_awal(self):
        stok_masuk = KartuStok.objects.filter(produk=self.produk, jenis='masuk').aggregate(models.Sum('jumlah'))['jumlah__sum'] or 0
        stok_keluar = KartuStok.objects.filter(produk=self.produk, jenis='keluar').aggregate(models.Sum('jumlah'))['jumlah__sum'] or 0
        return stok_masuk - stok_keluar

    def save(self, *args, **kwargs):
        is_new = self._state.adding

        if not self.harga_jual:
            self.harga_jual = self.produk.harga_jual

        if is_new:
            stok_awal = self.hitung_stok_awal()
            if stok_awal < self.jumlah:
                raise ValidationError(f"Stok {self.produk.nama} tidak cukup untuk penjualan (tersedia: {stok_awal}, diminta: {self.jumlah})")

        with transaction.atomic():
            super().save(*args, **kwargs)

            if is_new:
                KartuStok.objects.create(
                    produk=self.produk,
                    jenis='keluar',
                    jumlah=self.jumlah,
                    sumber=f"{self.penjualan.nomor_nota}",
                    keterangan="Penjualan"
                )

    def __str__(self):
        return f"Detail Penjualan {self.penjualan.nomor_nota} - {self.produk.nama}"

class KartuStok(models.Model):
    JENIS_CHOICES = (
        ('masuk', 'Masuk'),
        ('keluar', 'Keluar'),
    )

    produk = models.ForeignKey(Produk, on_delete=models.CASCADE)
    tanggal = models.DateTimeField(auto_now_add=True)
    jenis = models.CharField(max_length=10, choices=JENIS_CHOICES)
    jumlah = models.IntegerField()
    sumber = models.CharField(max_length=100)
    keterangan = models.TextField(blank=True, null=True)
