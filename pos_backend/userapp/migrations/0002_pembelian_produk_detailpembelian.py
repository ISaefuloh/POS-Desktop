# Generated by Django 5.2 on 2025-04-06 08:14

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('userapp', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Pembelian',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nomor_btb', models.CharField(max_length=100, unique=True)),
                ('tanggal', models.DateField(auto_now_add=True)),
                ('supplier', models.CharField(blank=True, max_length=100, null=True)),
            ],
        ),
        migrations.CreateModel(
            name='Produk',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('kode', models.CharField(max_length=50, unique=True)),
                ('nama', models.CharField(max_length=100)),
                ('satuan', models.CharField(max_length=20)),
                ('harga_jual', models.DecimalField(decimal_places=2, max_digits=12)),
            ],
        ),
        migrations.CreateModel(
            name='DetailPembelian',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('jumlah', models.IntegerField()),
                ('harga_beli', models.DecimalField(decimal_places=2, max_digits=12)),
                ('pembelian', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='detail_pembelian', to='userapp.pembelian')),
                ('produk', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='userapp.produk')),
            ],
        ),
    ]
