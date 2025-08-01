from django.urls import path
from . import views

urlpatterns = [
    path('users/', views.list_users),
    path('users/create/', views.create_user),
    path('users/delete/<int:user_id>/', views.delete_user),
    path('users/login/', views.login_user),

    # Produk
    path('produk/', views.list_produk, name='list_produk'),
    path('produk/create/', views.create_produk, name='create_produk'),
    path('produk/<int:pk>/', views.detail_produk, name='detail_produk'),

    # Pembelian
    path('pembelian/', views.list_pembelian, name='list_pembelian'),
    path('pembelian/create/', views.create_pembelian, name='create_pembelian'),
    path('pembelian/<int:pk>/', views.detail_pembelian, name='detail_pembelian'),

    # Penjualan
    path('penjualan/', views.list_penjualan, name='list_penjualan'),
    path('penjualan/create/', views.PenjualanCreateView.as_view(), name='create_penjualan'),
    #path('penjualan/create/', views.create_penjualan, name='create_penjualan'),
    path('penjualan/<int:pk>/', views.detail_penjualan, name='detail_penjualan'),
    path('penjualan/nomor_nota_baru/', views.get_nomor_nota_baru, name='nomor-nota-baru'),

    # Laporan Stok
    path('laporan-stok/', views.laporan_stok, name='laporan_stok'),
]

