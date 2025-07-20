from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import User, Produk, Pembelian, DetailPembelian, Penjualan, DetailPenjualan, KartuStok
from .serializers import UserSerializer, ProdukSerializer, PembelianSerializer, PenjualanSerializer, DetailPenjualanSerializer
from django.shortcuts import get_object_or_404
import hashlib
from rest_framework import generics
from django.db.models import Sum, Q, F, Value as V
from django.utils.dateparse import parse_date
from django.db.models import Max
from datetime import datetime
import json
from django.http import JsonResponse
from django.db.models.functions import Coalesce
from collections import defaultdict


@api_view(['GET'])
def list_users(request):
    users = User.objects.all()
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_user(request):
    data = request.data.copy()  # ⬅️ PENTING: buat salinan agar bisa diubah

    if 'password' not in data or not data['password']:
        return Response({'error': 'Password wajib diisi'}, status=status.HTTP_400_BAD_REQUEST)

    data['password'] = hashlib.sha256(data['password'].encode()).hexdigest()

    if User.objects.filter(username=data['username']).exists():
        return Response({'error': 'Username sudah digunakan'}, status=status.HTTP_400_BAD_REQUEST)

    serializer = UserSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_user(request, user_id):
    try:
        user = User.objects.get(id=user_id)
        user.delete()
        return Response({'message': 'User berhasil dihapus'}, status=status.HTTP_204_NO_CONTENT)
    except User.DoesNotExist:
        return Response({'error': 'User tidak ditemukan'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
def login_user(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': 'Username dan password wajib diisi'}, status=status.HTTP_400_BAD_REQUEST)

    hashed_password = hashlib.sha256(password.encode()).hexdigest()

     # ⬇️ DEBUG:
    print("Username:", username)
    print("Password hash:", hashed_password)

    try:
        user = User.objects.get(username=username, password=hashed_password)
        serializer = UserSerializer(user)
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response({'error': 'Username atau password salah'}, status=status.HTTP_401_UNAUTHORIZED)

# --- Produk Views ---

@api_view(['GET'])
def list_produk(request):
    produk = Produk.objects.all()
    serializer = ProdukSerializer(produk, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_produk(request):
    serializer = ProdukSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PUT', 'DELETE'])
def detail_produk(request, pk):
    produk = get_object_or_404(Produk, pk=pk)

    if request.method == 'GET':
        serializer = ProdukSerializer(produk)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = ProdukSerializer(produk, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        produk.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# --- Pembelian Views ---

@api_view(['GET'])
def list_pembelian(request):
    pembelian = Pembelian.objects.all()
    serializer = PembelianSerializer(pembelian, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_pembelian(request):
    try:
        data = json.loads(request.body)
        print("DATA DITERIMA:", data)  # <-- ini bantu debug

        serializer = PembelianSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        print("ERROR:", str(e))
        return JsonResponse({'error': str(e)}, status=400)

@api_view(['GET'])
def detail_pembelian(request, pk):
    pembelian = get_object_or_404(Pembelian, pk=pk)
    serializer = PembelianSerializer(pembelian)
    return Response(serializer.data)

# Penjualan Views

@api_view(['GET'])
def list_penjualan(request):
    tanggal_mulai = request.GET.get('tanggal_mulai')
    tanggal_akhir = request.GET.get('tanggal_akhir')

    if tanggal_mulai and tanggal_akhir:
        try:
            tanggal_mulai = datetime.strptime(tanggal_mulai, '%Y-%m-%d')
            tanggal_akhir = datetime.strptime(tanggal_akhir, '%Y-%m-%d')
            # tambahkan waktu maksimal di akhir hari
            tanggal_akhir = datetime.combine(tanggal_akhir, datetime.max.time())
            penjualan = Penjualan.objects.filter(tanggal__range=[tanggal_mulai, tanggal_akhir])
        except ValueError:
            return Response({'error': 'Format tanggal tidak valid. Gunakan format YYYY-MM-DD.'}, status=400)
    else:
        penjualan = Penjualan.objects.all()

    serializer = PenjualanSerializer(penjualan, many=True)
    return Response(serializer.data)

class PenjualanCreateView(generics.CreateAPIView):
    queryset = Penjualan.objects.all()
    serializer_class = PenjualanSerializer

@api_view(['GET'])
def detail_penjualan(request, pk):
    penjualan = get_object_or_404(Penjualan, pk=pk)
    serializer = PenjualanSerializer(penjualan)
    return Response(serializer.data)


#@api_view(['GET'])
def get_nomor_nota_baru(request):
    if request.method == 'GET':
        now = datetime.now()
        tahun = now.strftime("%Y")
        bulan = now.strftime("%m")
        prefix = f"NP/{tahun}/{bulan}/"

        last_nota = Penjualan.objects.filter(nomor_nota__startswith=prefix).aggregate(Max('nomor_nota'))['nomor_nota__max']

        if last_nota:
            last_number_str = last_nota.split('/')[-1]
            try:
                last_number = int(last_number_str)
                next_number = last_number + 1
                nomor_nota_baru = f"{prefix}{next_number:04d}"
            except ValueError:
                nomor_nota_baru = f"{prefix}0001"
        else:
            nomor_nota_baru = f"{prefix}0001"

        return JsonResponse({'nomor_nota': nomor_nota_baru})
    else:
        return JsonResponse({'error': 'Metode tidak diizinkan'}, status=405)

def get_stok_awal(produk, start_date):
    masuk = DetailPembelian.objects.filter(
        produk=produk,
        pembelian__tanggal__lt=start_date
    ).aggregate(total=Sum('jumlah'))['total'] or 0

    keluar = DetailPenjualan.objects.filter(
        produk=produk,
        penjualan__tanggal__lt=start_date
    ).aggregate(total=Sum('jumlah'))['total'] or 0

    return masuk - keluar

def get_stok_masuk(produk, start, end):
    return DetailPembelian.objects.filter(
        produk=produk,
        pembelian__tanggal__range=(start, end)
    ).aggregate(total=Sum('jumlah'))['total'] or 0

def get_stok_keluar(produk, start, end):
    return DetailPenjualan.objects.filter(
        produk=produk,
        penjualan__tanggal__range=(start, end)
    ).aggregate(total=Sum('jumlah'))['total'] or 0

@api_view(['GET'])
def laporan_stok(request):
    start = request.GET.get('start')
    end = request.GET.get('end')

    try:
        start_date = datetime.strptime(start, "%Y-%m-%d").date()
        end_date = datetime.strptime(end, "%Y-%m-%d").date()
    except:
        return Response({"error": "Format tanggal salah. Gunakan YYYY-MM-DD"}, status=400)

    # Ambil seluruh pembelian dan penjualan dalam range yang dibutuhkan
    pembelian_qs = DetailPembelian.objects.select_related('produk', 'pembelian').all()
    penjualan_qs = DetailPenjualan.objects.select_related('produk', 'penjualan').all()

    # Buat struktur data untuk stok awal, masuk, dan keluar
    stok_awal = defaultdict(int)
    stok_masuk = defaultdict(int)
    stok_keluar = defaultdict(int)

    for item in pembelian_qs:
        tanggal = item.pembelian.tanggal
        pid = item.produk.id
        if tanggal < start_date:
            stok_awal[pid] += item.jumlah
        elif start_date <= tanggal <= end_date:
            stok_masuk[pid] += item.jumlah

    for item in penjualan_qs:
        tanggal = item.penjualan.tanggal
        pid = item.produk.id
        if tanggal < start_date:
            stok_awal[pid] -= item.jumlah
        elif start_date <= tanggal <= end_date:
            stok_keluar[pid] += item.jumlah

    # Ambil semua produk yang terlibat
    produk_list = Produk.objects.all()
    laporan = []

    for produk in produk_list:
        pid = produk.id
        awal = stok_awal[pid]
        masuk = stok_masuk[pid]
        keluar = stok_keluar[pid]
        akhir = awal + masuk - keluar

        if akhir >= 0:  # Bisa diubah sesuai kebutuhan
            laporan.append({
                "kode": produk.kode,
                "nama": produk.nama,
                "stok_awal": awal,
                "stok_masuk": masuk,
                "stok_keluar": keluar,
                "stok_akhir": akhir,
            })

    return Response(laporan)

#@api_view(['GET'])
#def laporan_stok(request):
#    start = request.GET.get('start')
#    end = request.GET.get('end')
#
#    try:
#        start_date = datetime.strptime(start, "%Y-%m-%d").date()
#        end_date = datetime.strptime(end, "%Y-%m-%d").date()
#    except:
#        return Response({"error": "Format tanggal salah. Gunakan YYYY-MM-DD"}, status=400)
#
#    laporan = []
#    produk_list = Produk.objects.all()
#
#    for produk in produk_list:
#        stok_awal = get_stok_awal(produk, start_date)
#        stok_masuk = get_stok_masuk(produk, start_date, end_date)
#        stok_keluar = get_stok_keluar(produk, start_date, end_date)
#        stok_akhir = stok_awal + stok_masuk - stok_keluar
#
#        # Tampilkan hanya produk dengan stok akhir > 0
#        if stok_akhir >= 0:
#            laporan.append({
#                "kode": produk.kode,
#                "nama": produk.nama,
#                "stok_awal": stok_awal,
#                "stok_masuk": stok_masuk,
#                "stok_keluar": stok_keluar,
#                "stok_akhir": stok_akhir,
#            })
#
#    return Response(laporan)