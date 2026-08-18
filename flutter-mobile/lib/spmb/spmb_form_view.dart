import 'dart:io';
import 'package:flutter/material.dart';
import 'widgets/supporting_data_form.dart';
import 'widgets/student_form.dart';
import 'widgets/parents_form.dart';
import 'widgets/form_fields.dart';
import '../widgets/shared_header.dart';

class SpmbFormScreen extends StatefulWidget {
  const SpmbFormScreen({super.key});

  @override
  State<SpmbFormScreen> createState() => _SpmbFormScreenState();
}

class _SpmbFormScreenState extends State<SpmbFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // --- Controllers - Data Siswa & Periodik ---
  final _namaDepanController = TextEditingController();
  final _namaTengahController = TextEditingController();
  final _namaBelakangController = TextEditingController();
  final _nisnController = TextEditingController();
  final _nikAnakController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _anakKeController = TextEditingController();
  final _emailSiswaController = TextEditingController();
  final _noAktaLahirController = TextEditingController();
  final _asalSekolahController = TextEditingController();
  final _alamatAsalSekolahController = TextEditingController();
  final _alamatJalanController = TextEditingController();
  final _kotaController = TextEditingController();
  final _kodePosController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _lingkarKepalaController = TextEditingController();
  final _jarakKmController = TextEditingController();
  final _waktuTempuhController = TextEditingController();
  final _jumlahSaudaraController = TextEditingController();

  String? _jenisKelamin;
  String? _agama;
  String? _tempatTinggal;
  String? _kewarganegaraan;
  bool? _punyaKia;
  String? _modaTransportasi;
  String? _jenisPendaftaran;
  String? _provinsi;
  String? _negara;
  String? _jarakKategori;

  // --- Controllers - Data Ayah ---
  final _namaAyahController = TextEditingController();
  final _nikAyahController = TextEditingController();
  final _tanggalLahirAyahController = TextEditingController();
  final _hpAyahController = TextEditingController();
  final _emailAyahController = TextEditingController();
  String? _pendidikanAyah;
  String? _pekerjaanAyah;
  final _jabatanAyahController = TextEditingController();
  String? _penghasilanAyah;
  final _alamatKantorAyahController = TextEditingController();
  final _noKantorAyahController = TextEditingController();

  // --- Controllers - Data Ibu ---
  final _namaIbuController = TextEditingController();
  final _nikIbuController = TextEditingController();
  final _tanggalLahirIbuController = TextEditingController();
  final _hpIbuController = TextEditingController();
  final _emailIbuController = TextEditingController();
  String? _pendidikanIbu;
  String? _pekerjaanIbu;
  final _jabatanIbuController = TextEditingController();
  String? _penghasilanIbu;
  final _alamatKantorIbuController = TextEditingController();
  final _noKantorIbuController = TextEditingController();

  // Uploaded document files
  File? _pasFotoFile;
  File? _aktaKelahiranFile;
  File? _kartuKeluargaFile;
  File? _ktpOrangTuaFile;

  @override
  void dispose() {
    // Dispose all controllers
    _namaDepanController.dispose();
    _namaTengahController.dispose();
    _namaBelakangController.dispose();
    _nisnController.dispose();
    _nikAnakController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _anakKeController.dispose();
    _emailSiswaController.dispose();
    _noAktaLahirController.dispose();
    _asalSekolahController.dispose();
    _alamatAsalSekolahController.dispose();
    _alamatJalanController.dispose();
    _kotaController.dispose();
    _kodePosController.dispose();
    _tinggiBadanController.dispose();
    _beratBadanController.dispose();
    _lingkarKepalaController.dispose();
    _jarakKmController.dispose();
    _waktuTempuhController.dispose();
    _jumlahSaudaraController.dispose();
    
    _namaAyahController.dispose();
    _nikAyahController.dispose();
    _tanggalLahirAyahController.dispose();
    _hpAyahController.dispose();
    _emailAyahController.dispose();
    _jabatanAyahController.dispose();
    _alamatKantorAyahController.dispose();
    _noKantorAyahController.dispose();
    
    _namaIbuController.dispose();
    _nikIbuController.dispose();
    _tanggalLahirIbuController.dispose();
    _hpIbuController.dispose();
    _emailIbuController.dispose();
    _jabatanIbuController.dispose();
    _alamatKantorIbuController.dispose();
    _noKantorIbuController.dispose();
    super.dispose();
  }

  // Choose Date logic
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final monthStr = picked.month.toString().padLeft(2, '0');
        final dayStr = picked.day.toString().padLeft(2, '0');
        controller.text = "$monthStr/$dayStr/${picked.year}";
      });
    }
  }

  // Next / Submit action
  void _onNextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitForm();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap periksa kembali isian form Anda.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Back step
  void _onPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // Submit action
  void _submitForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.teal.shade600, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pendaftaran Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Data pendaftaran siswa baru berhasil disimpan ke sistem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepsTitle = ['Siswa & Periodik', 'Orang Tua', 'Data Pendukung'];
    final stepsIcon = [Icons.face_rounded, Icons.family_restroom_rounded, Icons.description_rounded];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SharedHeader(
        titleWidget: const Text(
          'PENDAFTARAN SISWA BARU',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Visual Custom Stepper
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = _currentStep == index;
                  final isCompleted = _currentStep > index;
                  return Expanded(
                    child: Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isCompleted ? Colors.teal : Colors.teal.shade50,
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            if (isCompleted || index <= _currentStep) {
                              setState(() {
                                _currentStep = index;
                              });
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? Colors.teal
                                      : (isCompleted ? Colors.teal.shade100 : Colors.teal.shade50),
                                  border: Border.all(
                                    color: isActive ? Colors.teal : Colors.teal.shade200,
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check : stepsIcon[index],
                                  color: isActive
                                      ? Colors.white
                                      : (isCompleted ? Colors.teal.shade700 : Colors.teal.shade300),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stepsTitle[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.teal : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < 2)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isCompleted || (_currentStep > index)
                                  ? Colors.teal
                                  : Colors.teal.shade50,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Form container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentFormStep(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _onPreviousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.teal.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Kembali',
                      style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _onNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  _currentStep == 2 ? 'Kirim Pendaftaran' : 'Lanjut',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFormStep() {
    switch (_currentStep) {
      case 0:
        return StudentFormWidget(
          namaDepanController: _namaDepanController,
          namaTengahController: _namaTengahController,
          namaBelakangController: _namaBelakangController,
          nisnController: _nisnController,
          nikAnakController: _nikAnakController,
          tempatLahirController: _tempatLahirController,
          tanggalLahirController: _tanggalLahirController,
          anakKeController: _anakKeController,
          emailSiswaController: _emailSiswaController,
          noAktaLahirController: _noAktaLahirController,
          asalSekolahController: _asalSekolahController,
          alamatAsalSekolahController: _alamatAsalSekolahController,
          alamatJalanController: _alamatJalanController,
          kotaController: _kotaController,
          kodePosController: _kodePosController,
          tinggiBadanController: _tinggiBadanController,
          beratBadanController: _beratBadanController,
          lingkarKepalaController: _lingkarKepalaController,
          jarakKmController: _jarakKmController,
          waktuTempuhController: _waktuTempuhController,
          jumlahSaudaraController: _jumlahSaudaraController,
          jenisKelaminValue: _jenisKelamin,
          agamaValue: _agama,
          tempatTinggalValue: _tempatTinggal,
          kewarganegaraanValue: _kewarganegaraan,
          punyaKiaValue: _punyaKia,
          modaTransportasiValue: _modaTransportasi,
          jenisPendaftaranValue: _jenisPendaftaran,
          provinsiValue: _provinsi,
          negaraValue: _negara,
          jarakKategoriValue: _jarakKategori,
          onSelectTanggalLahir: () => _selectDate(context, _tanggalLahirController),
          onJenisKelaminChanged: (val) => setState(() => _jenisKelamin = val),
          onAgamaChanged: (val) => setState(() => _agama = val),
          onTempatTinggalChanged: (val) => setState(() => _tempatTinggal = val),
          onKewarganegaraanChanged: (val) => setState(() => _kewarganegaraan = val),
          onPunyaKiaChanged: (val) => setState(() => _punyaKia = val),
          onModaTransportasiChanged: (val) => setState(() => _modaTransportasi = val),
          onJenisPendaftaranChanged: (val) => setState(() => _jenisPendaftaran = val),
          onProvinsiChanged: (val) => setState(() => _provinsi = val),
          onNegaraChanged: (val) => setState(() => _negara = val),
          onJarakKategoriChanged: (val) => setState(() => _jarakKategori = val),
        );
      case 1:
        return ParentsFormWidget(
          namaAyahController: _namaAyahController,
          nikAyahController: _nikAyahController,
          tanggalLahirAyahController: _tanggalLahirAyahController,
          hpAyahController: _hpAyahController,
          emailAyahController: _emailAyahController,
          jabatanAyahController: _jabatanAyahController,
          alamatKantorAyahController: _alamatKantorAyahController,
          noKantorAyahController: _noKantorAyahController,
          pendidikanAyahValue: _pendidikanAyah,
          pekerjaanAyahValue: _pekerjaanAyah,
          penghasilanAyahValue: _penghasilanAyah,
          namaIbuController: _namaIbuController,
          nikIbuController: _nikIbuController,
          tanggalLahirIbuController: _tanggalLahirIbuController,
          hpIbuController: _hpIbuController,
          emailIbuController: _emailIbuController,
          jabatanIbuController: _jabatanIbuController,
          alamatKantorIbuController: _alamatKantorIbuController,
          noKantorIbuController: _noKantorIbuController,
          pendidikanIbuValue: _pendidikanIbu,
          pekerjaanIbuValue: _pekerjaanIbu,
          penghasilanIbuValue: _penghasilanIbu,
          onSelectTanggalLahirAyah: () => _selectDate(context, _tanggalLahirAyahController),
          onSelectTanggalLahirIbu: () => _selectDate(context, _tanggalLahirIbuController),
          onPendidikanAyahChanged: (val) => setState(() => _pendidikanAyah = val),
          onPekerjaanAyahChanged: (val) => setState(() => _pekerjaanAyah = val),
          onPenghasilanAyahChanged: (val) => setState(() => _penghasilanAyah = val),
          onPendidikanIbuChanged: (val) => setState(() => _pendidikanIbu = val),
          onPekerjaanIbuChanged: (val) => setState(() => _pekerjaanIbu = val),
          onPenghasilanIbuChanged: (val) => setState(() => _penghasilanIbu = val),
        );
      case 2:
        return DocumentUploadWidget(
          pasFotoFile: _pasFotoFile,
          aktaKelahiranFile: _aktaKelahiranFile,
          kartuKeluargaFile: _kartuKeluargaFile,
          ktpOrangTuaFile: _ktpOrangTuaFile,
          onPasFotoSelected: (file) => setState(() => _pasFotoFile = file),
          onAktaKelahiranSelected: (file) => setState(() => _aktaKelahiranFile = file),
          onKartuKeluargaSelected: (file) => setState(() => _kartuKeluargaFile = file),
          onKtpOrangTuaSelected: (file) => setState(() => _ktpOrangTuaFile = file),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
