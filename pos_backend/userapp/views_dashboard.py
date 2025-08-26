from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils.timezone import now
from django.db.models import Sum, F
from .models import Penjualan, DetailPenjualan, ReturPenjualan, DetailReturPenjualan

@api_view(['GET'])
def dashboard_summary(request):
    today = now().date()

    # Total penjualan hari ini
    penjualan_today = Penjualan.objects.filter(tanggal=today).aggregate(
        total=Sum('total_harga')
    )['total'] or 0

    # Total retur penjualan hari ini (jumlah * harga_jual di detail retur)
    retur_penjualan_today = (
        DetailReturPenjualan.objects.filter(retur__tanggal=today)
        .aggregate(total=Sum(F('jumlah') * F('harga_jual')))['total'] or 0
    )

    # Omzet hari ini = penjualan - retur penjualan
    omzet_today = penjualan_today - retur_penjualan_today

    # Jumlah transaksi hari ini
    transaksi_today = Penjualan.objects.filter(tanggal=today).count()

    # Jumlah retur penjualan hari ini (jumlah transaksi retur, bukan nominal)
    retur_today = ReturPenjualan.objects.filter(tanggal=today).count()

    # Produk terjual hari ini
    produk_terjual = (
        DetailPenjualan.objects.filter(
            penjualan__tanggal=today
        )
        .values('produk__nama')
        .annotate(total_terjual=Sum('jumlah'))
        .order_by('-total_terjual')[:5]
    )

    return Response({
        "penjualan_today": penjualan_today,
        "retur_penjualan_today": retur_penjualan_today,
        "omzet_today": omzet_today,
        "transaksi_today": transaksi_today,
        "retur_today": retur_today,
        "produk_terjual": list(produk_terjual),
    })
