from rest_framework import serializers
from .models import User, Produk, Pembelian, DetailPembelian, Penjualan, DetailPenjualan, KartuStok
from django.db import transaction
from django.core.exceptions import ValidationError
from django.db.models import Sum

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'username', 'password', 'role'] 
        extra_kwargs = {
            'password': {'write_only': True}  # agar tidak muncul saat GET user
        }

from rest_framework import serializers
from .models import Produk, Pembelian, DetailPembelian

class ProdukSerializer(serializers.ModelSerializer):
    stok_tersedia = serializers.SerializerMethodField()

    class Meta:
        model = Produk
        fields = '__all__'
        read_only_fields = ['stok_tersedia']
    
    def get_stok_tersedia(self, obj):
        masuk = KartuStok.objects.filter(produk=obj, jenis='masuk').aggregate(Sum('jumlah'))['jumlah__sum'] or 0
        keluar = KartuStok.objects.filter(produk=obj, jenis='keluar').aggregate(Sum('jumlah'))['jumlah__sum'] or 0
        return masuk - keluar

class DetailPembelianSerializer(serializers.ModelSerializer):
    produk_nama = serializers.CharField(source='produk.nama', read_only=True)
    produk_kode = serializers.CharField(source='produk.kode', read_only=True)

    class Meta:
        model = DetailPembelian
        fields = ['id', 'produk','produk_kode', 'produk_nama', 'jumlah', 'harga_beli', 'subtotal']

class PembelianSerializer(serializers.ModelSerializer):
    detail_pembelian = DetailPembelianSerializer(many=True)
    nomor_btb = serializers.CharField(read_only=True)  # << penting

    class Meta:
        model = Pembelian
        fields = ['id', 'nomor_btb', 'tanggal', 'supplier', 'detail_pembelian']

    def create(self, validated_data):
        detail_data = validated_data.pop('detail_pembelian')
        pembelian = Pembelian.objects.create(**validated_data)
        for item in detail_data:
            DetailPembelian.objects.create(pembelian=pembelian, **item)
        return pembelian

class DetailPenjualanSerializer(serializers.ModelSerializer):
    produk_nama = serializers.CharField(source='produk.nama', read_only=True)
    produk_kode = serializers.CharField(source='produk.kode', read_only=True)

    class Meta:
        model = DetailPenjualan
        fields = ['id', 'produk', 'produk_kode', 'produk_nama', 'jumlah', 'harga_jual']

class PenjualanSerializer(serializers.ModelSerializer):
    detail_penjualan = DetailPenjualanSerializer(many=True)

    class Meta:
        model = Penjualan
        fields = ['id', 'nomor_nota', 'tanggal', 'total_harga', 'pembayaran', 'kembalian', 'detail_penjualan']

    def validate(self, data):
        # Validasi stok cukup sebelum create
        for item in data['detail_penjualan']:
            produk = item['produk']
            jumlah = item['jumlah']
            stok_masuk = KartuStok.objects.filter(produk=produk, jenis='masuk').aggregate(Sum('jumlah'))['jumlah__sum'] or 0
            stok_keluar = KartuStok.objects.filter(produk=produk, jenis='keluar').aggregate(Sum('jumlah'))['jumlah__sum'] or 0

            stok_tersedia = stok_masuk - stok_keluar

            if stok_tersedia < jumlah:
                raise serializers.ValidationError(f"Stok produk '{produk.nama}' tidak cukup (tersedia: {stok_tersedia}, diminta: {jumlah})")
        return data

    def create(self, validated_data):
        detail_penjualan_data = validated_data.pop('detail_penjualan')
        penjualan = Penjualan.objects.create(**validated_data)
        for detail_data in detail_penjualan_data:
            DetailPenjualan.objects.create(penjualan=penjualan, **detail_data)
        return penjualan

class KartuStokSerializer(serializers.ModelSerializer):
    produk_kode = serializers.CharField(source='produk.kode', read_only=True)
    produk_nama = serializers.CharField(source='produk.nama', read_only=True)

    class Meta:
        model = KartuStok
        fields = ['id', 'produk', 'produk_kode', 'produk_nama', 'tanggal', 'jenis', 'jumlah', 'sumber', 'keterangan']