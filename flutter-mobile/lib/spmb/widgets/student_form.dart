import 'package:flutter/material.dart';
import 'form_fields.dart'; // Sesuaikan dengan lokasi file helper form Anda

class StudentFormWidget extends StatelessWidget {
  final TextEditingController namaDepanController;
  final TextEditingController namaTengahController;
  final TextEditingController namaBelakangController;
  final TextEditingController nisnController;
  final TextEditingController nikAnakController;
  final TextEditingController tempatLahirController;
  final TextEditingController tanggalLahirController;
  final TextEditingController anakKeController;
  final TextEditingController emailSiswaController;
  final TextEditingController noAktaLahirController;
  final TextEditingController asalSekolahController;
  final TextEditingController alamatAsalSekolahController;
  final TextEditingController alamatJalanController;
  final TextEditingController kotaController;
  final TextEditingController kodePosController;
  final TextEditingController tinggiBadanController;
  final TextEditingController beratBadanController;
  final TextEditingController lingkarKepalaController;
  final TextEditingController jarakKmController;
  final TextEditingController waktuTempuhController;
  final TextEditingController jumlahSaudaraController;

  final String? jenisKelaminValue;
  final String? agamaValue;
  final String? tempatTinggalValue;
  final String? kewarganegaraanValue;
  final bool? punyaKiaValue;
  final String? modaTransportasiValue;
  final String? jenisPendaftaranValue;
  final String? provinsiValue;
  final String? negaraValue;
  final String? jarakKategoriValue;

  final VoidCallback onSelectTanggalLahir;
  final ValueChanged<String?> onJenisKelaminChanged;
  final ValueChanged<String?> onAgamaChanged;
  final ValueChanged<String?> onTempatTinggalChanged;
  final ValueChanged<String?> onKewarganegaraanChanged;
  final ValueChanged<bool?> onPunyaKiaChanged;
  final ValueChanged<String?> onModaTransportasiChanged;
  final ValueChanged<String?> onJenisPendaftaranChanged;
  final ValueChanged<String?> onProvinsiChanged;
  final ValueChanged<String?> onNegaraChanged;
  final ValueChanged<String?> onJarakKategoriChanged;

  const StudentFormWidget({
    super.key,
    required this.namaDepanController,
    required this.namaTengahController,
    required this.namaBelakangController,
    required this.nisnController,
    required this.nikAnakController,
    required this.tempatLahirController,
    required this.tanggalLahirController,
    required this.anakKeController,
    required this.emailSiswaController,
    required this.noAktaLahirController,
    required this.asalSekolahController,
    required this.alamatAsalSekolahController,
    required this.alamatJalanController,
    required this.kotaController,
    required this.kodePosController,
    required this.tinggiBadanController,
    required this.beratBadanController,
    required this.lingkarKepalaController,
    required this.jarakKmController,
    required this.waktuTempuhController,
    required this.jumlahSaudaraController,
    required this.jenisKelaminValue,
    required this.agamaValue,
    required this.tempatTinggalValue,
    required this.kewarganegaraanValue,
    required this.punyaKiaValue,
    required this.modaTransportasiValue,
    required this.jenisPendaftaranValue,
    required this.provinsiValue,
    required this.negaraValue,
    required this.jarakKategoriValue,
    required this.onSelectTanggalLahir,
    required this.onJenisKelaminChanged,
    required this.onAgamaChanged,
    required this.onTempatTinggalChanged,
    required this.onKewarganegaraanChanged,
    required this.onPunyaKiaChanged,
    required this.onModaTransportasiChanged,
    required this.onJenisPendaftaranChanged,
    required this.onProvinsiChanged,
    required this.onNegaraChanged,
    required this.onJarakKategoriChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // BAGIAN 1: DATA PRIBADI SISWA
        // ==========================================
        SpmbFormFields.buildFormSection(
          title: 'Data Pribadi Siswa',
          icon: Icons.person_rounded,
          children: [
            SpmbFormFields.buildTextField(
              controller: namaDepanController,
              label: 'Nama Depan',
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? 'Nama depan wajib diisi' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: namaTengahController,
                    label: 'Nama Tengah',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: namaBelakangController,
                    label: 'Nama Belakang',
                    icon: Icons.person_outline,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildDropdownField(
                    label: 'Jenis Kelamin',
                    value: jenisKelaminValue,
                    hint: 'Pilih',
                    items: const ['Laki-laki', 'Perempuan'],
                    onChanged: onJenisKelaminChanged,
                    validator: (val) => val == null ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildDropdownField(
                    label: 'Agama',
                    value: agamaValue,
                    hint: 'Pilih',
                    items: const ['Islam', 'Kristen Protestan', 'Katolik', 'Hindu', 'Buddha', 'Khonghucu'],
                    onChanged: onAgamaChanged,
                    validator: (val) => val == null ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: tempatLahirController,
                    label: 'Tempat Lahir',
                    icon: Icons.home_work_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildDateField(
                    controller: tanggalLahirController,
                    label: 'Tanggal Lahir',
                    onTap: onSelectTanggalLahir,
                    validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            SpmbFormFields.buildTextField(
              controller: nikAnakController,
              label: 'NIK Anak',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              validator: (val) => val == null || val.isEmpty || val.length < 16 ? 'Masukkan 16 digit NIK' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: noAktaLahirController,
              label: 'No Akta Lahir',
              icon: Icons.assignment_outlined,
              validator: (val) => val == null || val.isEmpty ? 'No akta lahir wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: nisnController,
              label: 'NISN',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: anakKeController,
                    label: 'Anak Ke-',
                    icon: Icons.format_list_numbered,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: jumlahSaudaraController,
                    label: 'Jml Saudara',
                    icon: Icons.group_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Kewarganegaraan',
              value: kewarganegaraanValue,
              hint: '-- Pilih Kewarganegaraan --',
              items: const ['Warga Negara Indonesia (WNI)', 'Warga Negara Asing (WNA)'],
              onChanged: onKewarganegaraanChanged,
            ),
            SpmbFormFields.buildTextField(
              controller: emailSiswaController,
              label: 'Email Siswa',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            SpmbFormFields.buildRadioField(
              label: 'Apakah Punya KIA (Kartu Identitas Anak)?',
              value: punyaKiaValue,
              onChanged: onPunyaKiaChanged,
            ),
          ],
        ),
        
        const SizedBox(height: 20),

        // ==========================================
        // BAGIAN 2: DATA ALAMAT & SEKOLAH ASAL
        // ==========================================
        SpmbFormFields.buildFormSection(
          title: 'Alamat & Sekolah Asal',
          icon: Icons.map_outlined,
          children: [
            SpmbFormFields.buildDropdownField(
              label: 'Jenis Pendaftaran',
              value: jenisPendaftaranValue,
              hint: '-- Pilih Jenis Pendaftaran --',
              items: const ['Siswa Baru', 'Pindahan Ke Kelas', 'Kembali Bersekolah'],
              onChanged: onJenisPendaftaranChanged,
              validator: (val) => val == null ? 'Jenis pendaftaran wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: asalSekolahController,
              label: 'Asal Sekolah',
              icon: Icons.school_outlined,
            ),
            SpmbFormFields.buildTextField(
              controller: alamatAsalSekolahController,
              label: 'Alamat Asal Sekolah',
              icon: Icons.location_on_outlined,
            ),
            const Divider(height: 30),
            SpmbFormFields.buildTextField(
              controller: alamatJalanController,
              label: 'Alamat Tempat Tinggal Saat Ini',
              icon: Icons.home_outlined,
              validator: (val) => val == null || val.isEmpty ? 'Alamat jalan wajib diisi' : null,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Tempat Tinggal',
              value: tempatTinggalValue,
              hint: '-- Pilih Kepemilikan Tempat Tinggal --',
              items: const ['Bersama Orang Tua', 'Wali', 'Kos', 'Asrama', 'Panti Asuhan', 'Lainnya'],
              onChanged: onTempatTinggalChanged,
              validator: (val) => val == null ? 'Tempat tinggal wajib diisi' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildDropdownField(
                    label: 'Provinsi',
                    value: provinsiValue,
                    hint: 'Pilih Provinsi',
                    items: const ['DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'Banten', 'DI Yogyakarta', 'Bali'],
                    onChanged: onProvinsiChanged,
                    validator: (val) => val == null ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: kotaController,
                    label: 'Kota / Kab',
                    icon: Icons.location_city_outlined,
                    validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildDropdownField(
                    label: 'Negara',
                    value: negaraValue,
                    hint: 'Pilih Negara',
                    items: const ['Indonesia', 'Malaysia', 'Singapura', 'Lainnya'],
                    onChanged: onNegaraChanged,
                    validator: (val) => val == null ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: kodePosController,
                    label: 'Kode POS',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ==========================================
        // BAGIAN 3: DATA PERIODIK & TRANSPORTASI
        // ==========================================
        SpmbFormFields.buildFormSection(
          title: 'Data Periodik Fisik',
          icon: Icons.monitor_weight_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: tinggiBadanController,
                    label: 'Tinggi (cm)',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: beratBadanController,
                    label: 'Berat (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SpmbFormFields.buildTextField(
              controller: lingkarKepalaController,
              label: 'Lingkar Kepala (cm)',
              icon: Icons.face_retouching_natural_outlined,
              keyboardType: TextInputType.number,
            ),
            const Divider(height: 30),
            SpmbFormFields.buildDropdownField(
              label: 'Moda Transportasi ke Sekolah',
              value: modaTransportasiValue,
              hint: '-- Pilih Moda Transportasi --',
              items: const ['Jalan Kaki', 'Kendaraan Pribadi', 'Kendaraan Umum/Angkot', 'Jemputan Sekolah', 'Kereta Api', 'Ojek', 'Lainnya'],
              onChanged: onModaTransportasiChanged,
              validator: (val) => val == null ? 'Moda transportasi wajib diisi' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: SpmbFormFields.buildDropdownField(
                    label: 'Jarak ke Sekolah',
                    value: jarakKategoriValue,
                    hint: 'Pilih Jarak',
                    items: const ['Kurang dari 1 KM', 'Lebih dari 1 KM'],
                    onChanged: onJarakKategoriChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SpmbFormFields.buildTextField(
                    controller: jarakKmController,
                    label: 'Jarak (KM)',
                    icon: Icons.social_distance,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SpmbFormFields.buildTextField(
              controller: waktuTempuhController,
              label: 'Waktu Tempuh (Menit)',
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ],
    );
  }
}