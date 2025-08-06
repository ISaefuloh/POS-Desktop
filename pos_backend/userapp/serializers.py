from rest_framework import serializers
from .models import User, Produk, Pembelian, DetailPembelian, Penjualan, DetailPenjualan, KartuStok, ReturPembelian, ReturPenjualan, DetailReturPenjualan, DetailReturPembelian
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


class ProdukTransaksiReturSerializer(serializers.Serializer):
    produk_id = serializers.IntegerField()
    nama = serializers.CharField()
    jumlah_transaksi = serializers.IntegerField()
    jumlah_diretur = serializers.IntegerField()
    jumlah_bisa_diretur = serializers.IntegerField()
    harga = serializers.IntegerField()

class ReturPenjualanItemSerializer(serializers.Serializer):
    detail_penjualan_id = serializers.IntegerField()
    jumlah = serializers.IntegerField()
    keterangan = serializers.CharField(allow_blank=True, required=False)

class ReturPenjualanSerializer(serializers.Serializer):
    nomor_nota = serializers.CharField()
    items = ReturPenjualanItemSerializer(many=True)

    def validate(self, data):
        nomor_nota = data['nomor_nota']
        items = data['items']

        penjualan = Penjualan.objects.filter(nomor_nota=nomor_nota).first()
        if not penjualan:
            raise serializers.ValidationError("Nomor nota tidak ditemukan")

        for item in items:
            detail_id = item['detail_penjualan_id']
            jumlah = item['jumlah']

            detail = DetailPenjualan.objects.filter(penjualan=penjualan, id=detail_id).first()
            if not detail:
                raise serializers.ValidationError(
                    f"Detail Penjualan ID {detail_id} tidak ditemukan di nota {nomor_nota}"
                )

            # Hitung total retur untuk produk ini
            sudah_diretur = DetailReturPenjualan.objects.filter(
                retur__penjualan=penjualan,
                produk=detail.produk
            ).aggregate(total=Sum('jumlah'))['total'] or 0

            if jumlah + sudah_diretur > detail.jumlah:
                raise serializers.ValidationError(
                    f"Jumlah retur untuk Detail Penjualan ID {detail_id} melebihi jumlah di nota"
                )

        return data
    
    def create(self, validated_data):
        nomor_nota = validated_data['nomor_nota']
        items = validated_data['items']
    
        penjualan = Penjualan.objects.get(nomor_nota=nomor_nota)
        retur = ReturPenjualan.objects.create(penjualan=penjualan)
    
        for item in items:
            detail = DetailPenjualan.objects.get(id=item['detail_penjualan_id'])
            produk = detail.produk
            harga = detail.harga_jual
            jumlah = item['jumlah']
            keterangan = item.get('keterangan', '')
    
            if jumlah > 0:
                detail_retur = DetailReturPenjualan(
                    retur=retur,
                    produk=produk,
                    jumlah=jumlah,
                    harga_jual=harga,
                    keterangan=keterangan
                )
                detail_retur.save()  # ini akan picu save() dan buat kartu stok otomatis
    
        return {"success": True}



    #def create(self, validated_data):
    #    nomor_nota = validated_data['nomor_nota']
    #    items = validated_data['items']
#
    #    penjualan = Penjualan.objects.get(nomor_nota=nomor_nota)
    #    retur = ReturPenjualan.objects.create(penjualan=penjualan)
#
    #    detail_objects = []
    #    for item in items:
    #        detail = DetailPenjualan.objects.get(id=item['detail_penjualan_id'])
    #        produk = detail.produk
    #        harga = detail.harga_jual
    #        jumlah = item['jumlah']
#
    #        if jumlah > 0:
    #            detail_objects.append(DetailReturPenjualan(
    #                retur=retur,
    #                produk=produk,
    #                jumlah=jumlah,
    #                harga_jual=harga,
    #                keterangan=item.get('keterangan', '')
    #            ))
#
    #    # Simpan semua detail retur sekaligus
    #    DetailReturPenjualan.objects.bulk_create(detail_objects)
#
    #    return {"success": True, "jumlah_diretur": len(detail_objects)}



#class ReturPenjualanItemSerializer(serializers.Serializer):
#    produk_id = serializers.IntegerField()
#    jumlah = serializers.IntegerField()
#
#class ReturPenjualanSerializer(serializers.Serializer):
#    nomor_nota = serializers.CharField()
#    items = ReturPenjualanItemSerializer(many=True)
#    keterangan = serializers.CharField(allow_blank=True)
#
#    def validate(self, data):
#        from django.db.models import Sum
#        from .models import Penjualan, DetailPenjualan, ReturPenjualan, Produk
#
#        nomor_nota = data['nomor_nota']
#        items = data['items']
#        penjualan = Penjualan.objects.filter(nomor_nota=nomor_nota).first()
#
#        if not penjualan:
#            raise serializers.ValidationError("Nomor nota tidak ditemukan")
#
#        for item in items:
#            produk_id = item['produk_id']
#            jumlah = item['jumlah']
#
#            detail = DetailPenjualan.objects.filter(
#                penjualan=penjualan, produk_id=produk_id
#            ).first()
#            if not detail:
#                raise serializers.ValidationError(f"Produk ID {produk_id} tidak ada di nota {nomor_nota}")
#
#            sudah_diretur = ReturPenjualan.objects.filter(
#                penjualan=penjualan, produk_id=produk_id
#            ).aggregate(total=Sum('jumlah'))['total'] or 0
#
#            if jumlah + sudah_diretur > detail.jumlah:
#                raise serializers.ValidationError(
#                    f"Jumlah retur untuk produk ID {produk_id} melebihi jumlah di nota"
#                )
#
#        return data
#
#    def create(self, validated_data):
#        from .models import ReturPenjualan, Produk, Penjualan
#
#        penjualan = Penjualan.objects.get(nomor_nota=validated_data['nomor_nota'])
#        keterangan = validated_data.get('keterangan', '')
#
#        retur_objects = []
#        for item in validated_data['items']:
#            produk = Produk.objects.get(id=item['produk_id'])
#            jumlah = item['jumlah']
#
#            retur = ReturPenjualan(
#                penjualan=penjualan,
#                produk=produk,
#                jumlah=jumlah,
#                harga=DetailPenjualan.objects.get(penjualan=penjualan, produk=produk).harga_jual,
#                keterangan=keterangan
#            )
#            retur_objects.append(retur)
#
#        ReturPenjualan.objects.bulk_create(retur_objects)
#        return {"success": True, "jumlah_diretur": len(retur_objects)}

class ReturPembelianItemSerializer(serializers.Serializer):
    detail_pembelian_id = serializers.IntegerField()
    jumlah = serializers.IntegerField()
    keterangan = serializers.CharField(required=False, allow_blank=True)

class ReturPembelianSerializer(serializers.Serializer):
    nomor_btb = serializers.CharField()
    items = ReturPembelianItemSerializer(many=True)

    def validate(self, data):
        nomor_btb = data['nomor_btb']
        items = data['items']

        pembelian = Pembelian.objects.filter(nomor_btb=nomor_btb).first()
        if not pembelian:
            raise serializers.ValidationError("Nomor BTB tidak ditemukan")

        for item in items:
            detail_id = item['detail_pembelian_id']
            jumlah = item['jumlah']

            detail = DetailPembelian.objects.filter(pembelian=pembelian, id=detail_id).first()
            if not detail:
                raise serializers.ValidationError(
                    f"Detail Pembelian ID {detail_id} tidak ditemukan di BTB {nomor_btb}"
                )

            # Hitung total retur untuk produk ini
            sudah_diretur = DetailReturPembelian.objects.filter(
                retur__pembelian=pembelian,
                produk=detail.produk
            ).aggregate(total=Sum('jumlah'))['total'] or 0

            if jumlah + sudah_diretur > detail.jumlah:
                raise serializers.ValidationError(
                    f"Jumlah retur untuk Detail Pembelian ID {detail_id} melebihi jumlah di BTB"
                )

        return data

    def create(self, validated_data):
        nomor_btb = validated_data['nomor_btb']
        items = validated_data['items']

        pembelian = Pembelian.objects.get(nomor_btb=nomor_btb)
        retur = ReturPembelian.objects.create(pembelian=pembelian)

        for item in items:
            detail = DetailPembelian.objects.get(id=item['detail_pembelian_id'])
            produk = detail.produk
            harga = detail.harga_beli
            jumlah = item['jumlah']
            keterangan = item.get('keterangan', '')

            if jumlah > 0:
                detail_retur = DetailReturPembelian(
                    retur=retur,
                    produk=produk,
                    jumlah=jumlah,
                    harga_beli=harga,
                    keterangan=keterangan
                )
                detail_retur.save()  # picu validasi + kartu stok

        return {"success": True}



class DetailReturPenjualanSerializer(serializers.ModelSerializer):
    produk_nama = serializers.CharField(source='produk.nama', read_only=True)

    class Meta:
        model = DetailReturPenjualan
        fields = ['id', 'produk', 'produk_nama', 'jumlah', 'harga_jual', 'keterangan']

class DetailReturPembelianSerializer(serializers.ModelSerializer):
    produk_nama = serializers.CharField(source='produk.nama', read_only=True)

    class Meta:
        model = DetailReturPembelian
        fields = ['id', 'produk', 'produk_nama', 'jumlah', 'harga_beli', 'keterangan']


class ReturPenjualanListSerializer(serializers.ModelSerializer):
    nomor_nota = serializers.CharField(source='penjualan.nomor_nota', read_only=True)
    detail = DetailReturPenjualanSerializer(source='detail_retur_penjualan', many=True, read_only=True)

    class Meta:
        model = ReturPenjualan
        fields = ['id', 'tanggal', 'nomor_nota','detail']

#class ReturPenjualanListSerializer(serializers.ModelSerializer):
#    produk_nama = serializers.CharField(source='produk.nama', read_only=True)
#    nomor_nota = serializers.CharField(source='penjualan.nomor_nota', read_only=True)
#
#    class Meta:
#        model = ReturPenjualan
#        fields = ['id', 'tanggal', 'nomor_nota', 'produk_nama', 'jumlah', 'harga', 'keterangan']

class ReturPembelianListSerializer(serializers.ModelSerializer):
    nomor_btb = serializers.CharField(source='pembelian.nomor_btb', read_only=True)
    detail = DetailReturPembelianSerializer(source='detail_retur_pembelian', many=True, read_only=True)

    class Meta:
        model = ReturPembelian
        fields = ['id', 'tanggal', 'nomor_btb', 'detail']