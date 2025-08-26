from django.contrib import admin
from . models import User, Produk, ReturPenjualan, DetailReturPenjualan, ReturPembelian, DetailReturPembelian, Pembelian, Penjualan, DetailPembelian, DetailPenjualan
# Register your models here.

class DetailReturPenjualanInline(admin.TabularInline):
    model = DetailReturPenjualan
    extra = 1
    readonly_fields = ['harga_jual']

class ReturPenjualanAdmin(admin.ModelAdmin):
    inlines = [DetailReturPenjualanInline]

class DetailReturPembelianInline(admin.TabularInline):
    model = DetailReturPembelian
    extra = 1
    readonly_fields = ['harga_beli']

class ReturPembelianAdmin(admin.ModelAdmin):
    inlines = [DetailReturPembelianInline]

admin.site.register(User)
admin.site.register(Produk)
admin.site.register(Pembelian)
admin.site.register(Penjualan)
admin.site.register(DetailPembelian)
admin.site.register(DetailPenjualan)
admin.site.register(ReturPenjualan, ReturPenjualanAdmin)
admin.site.register(ReturPembelian, ReturPembelianAdmin)