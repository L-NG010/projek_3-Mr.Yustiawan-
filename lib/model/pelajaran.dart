import 'package:flutter/material.dart';

class Pelajaran {
  final String id;
  final String nama;
  final String jam;
  final Color warna;
  final String namaGuru;

  const Pelajaran({
    required this.id,
    required this.nama,
    required this.jam,
    required this.warna,
    required this.namaGuru,
  });
}
