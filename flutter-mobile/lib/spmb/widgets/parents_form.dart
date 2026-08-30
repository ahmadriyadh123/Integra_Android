import 'package:flutter/material.dart';
import 'form_fields.dart';

class ParentsFormWidget extends StatelessWidget {
  final TextEditingController namaAyahController;
  final TextEditingController nikAyahController;
  final TextEditingController tanggalLahirAyahController;
  final TextEditingController hpAyahController;
  final TextEditingController emailAyahController;
  final TextEditingController jabatanAyahController;
  final TextEditingController alamatKantorAyahController;
  final TextEditingController noKantorAyahController;
  
  final String? pendidikanAyahValue;
  final String? pekerjaanAyahValue;
  final String? penghasilanAyahValue;

  final TextEditingController namaIbuController;
  final TextEditingController nikIbuController;
  final TextEditingController tanggalLahirIbuController;
  final TextEditingController hpIbuController;
  final TextEditingController emailIbuController;
  final TextEditingController jabatanIbuController;
  final TextEditingController alamatKantorIbuController;
  final TextEditingController noKantorIbuController;
  
  final String? pendidikanIbuValue;
  final String? pekerjaanIbuValue;
  final String? penghasilanIbuValue;

  final VoidCallback onSelectTanggalLahirAyah;
  final VoidCallback onSelectTanggalLahirIbu;
  final ValueChanged<String?> onPendidikanAyahChanged;
  final ValueChanged<String?> onPekerjaanAyahChanged;
  final ValueChanged<String?> onPenghasilanAyahChanged;
  final ValueChanged<String?> onPendidikanIbuChanged;
  final ValueChanged<String?> onPekerjaanIbuChanged;
  final ValueChanged<String?> onPenghasilanIbuChanged;

  const ParentsFormWidget({
    super.key,
    required this.namaAyahController,
    required this.nikAyahController,
    required this.tanggalLahirAyahController,
    required this.hpAyahController,
    required this.emailAyahController,
    required this.jabatanAyahController,
    required this.alamatKantorAyahController,
    required this.noKantorAyahController,
    required this.pendidikanAyahValue,
    required this.pekerjaanAyahValue,
    required this.penghasilanAyahValue,
    required this.namaIbuController,
    required this.nikIbuController,
    required this.tanggalLahirIbuController,
    required this.hpIbuController,
    required this.emailIbuController,
    required this.jabatanIbuController,
    required this.alamatKantorIbuController,
    required this.noKantorIbuController,
    required this.pendidikanIbuValue,
    required this.pekerjaanIbuValue,
    required this.penghasilanIbuValue,
    required this.onSelectTanggalLahirAyah,
    required this.onSelectTanggalLahirIbu,
    required this.onPendidikanAyahChanged,
    required this.onPekerjaanAyahChanged,
    required this.onPenghasilanAyahChanged,
    required this.onPendidikanIbuChanged,
    required this.onPekerjaanIbuChanged,
    required this.onPenghasilanIbuChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- SEKSI 1: DATA AYAH ---
        SpmbFormFields.buildFormSection(
          title: 'Data Orang Tua',
          icon: Icons.family_restroom_rounded,
          children: [
            SpmbFormFields.buildSectionLabel('Data Ayah'),
            SpmbFormFields.buildTextField(
              controller: namaAyahController,
              label: 'Nama Lengkap Ayah',
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? 'Nama lengkap ayah wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: nikAyahController,
              label: 'NIK Ayah',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              validator: (val) => val == null || val.isEmpty || val.length < 16 ? 'Masukkan 16 digit NIK' : null,
            ),
            SpmbFormFields.buildDateField(
              controller: tanggalLahirAyahController,
              label: 'Tanggal Lahir Ayah',
              onTap: onSelectTanggalLahirAyah,
              validator: (val) => val == null || val.isEmpty ? 'Tanggal lahir wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: hpAyahController,
              label: 'No Handphone/WhatsApp Ayah',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.isEmpty || val.length < 9 ? 'No Handphone tidak valid' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: emailAyahController,
              label: 'Email Ayah',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Pendidikan Ayah',
              value: pendidikanAyahValue,
              hint: '-- Pilih Pendidikan --',
              items: const [
                'Tidak Sekolah',
                'Putus SD',
                'SD Sederajat',
                'SMP Sederajat',
                'SMA Sederajat',
                'D1',
                'D3',
                'S1',
                'S2',
                'S3'
              ],
              onChanged: onPendidikanAyahChanged,
              validator: (val) => val == null ? 'Pendidikan wajib diisi' : null,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Pekerjaan Ayah',
              value: pekerjaanAyahValue,
              hint: '-- Pilih Pekerjaan --',
              items: const [
                'Tidak Bekerja',
                'Nelayan',
                'Petani',
                'Peternak',
                'PNS/TNI/POLRI',
                'Karyawan Swasta',
                'Wiraswasta',
                'Wirausaha',
                'Buruh',
                'Pensiunan',
                'Lainnya'
              ],
              onChanged: onPekerjaanAyahChanged,
            ),
            SpmbFormFields.buildTextField(
              controller: jabatanAyahController,
              label: 'Jabatan Ayah',
              icon: Icons.work_outline,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Penghasilan Bulanan Ayah',
              value: penghasilanAyahValue,
              hint: '-- Pilih Penghasilan --',
              items: const [
                'Tidak Berpenghasilan',
                'Kurang dari Rp. 500.000',
                'Rp. 500.000 - Rp. 999.999',
                'Rp. 1.000.000 - Rp. 1.999.999',
                'Rp. 2.000.000 - Rp. 4.999.999',
                'Rp. 5.000.000 - Rp. 20.000.000',
                'Lebih dari Rp. 20.000.000'
              ],
              onChanged: onPenghasilanAyahChanged,
              validator: (val) => val == null ? 'Penghasilan wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: alamatKantorAyahController,
              label: 'Alamat Kantor / Perusahaan Ayah',
              icon: Icons.business,
            ),
            SpmbFormFields.buildTextField(
              controller: noKantorAyahController,
              label: 'No Kantor Ayah',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- SEKSI 2: DATA IBU ---
        SpmbFormFields.buildFormSection(
          title: 'Data Orang Tua (Ibu)',
          icon: Icons.family_restroom_rounded,
          children: [
            SpmbFormFields.buildSectionLabel('Data Ibu'),
            SpmbFormFields.buildTextField(
              controller: namaIbuController,
              label: 'Nama Lengkap Ibu',
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? 'Nama lengkap ibu wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: nikIbuController,
              label: 'NIK Ibu',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              validator: (val) => val == null || val.isEmpty || val.length < 16 ? 'Masukkan 16 digit NIK' : null,
            ),
            SpmbFormFields.buildDateField(
              controller: tanggalLahirIbuController,
              label: 'Tanggal Lahir Ibu',
              onTap: onSelectTanggalLahirIbu,
              validator: (val) => val == null || val.isEmpty ? 'Tanggal lahir wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: hpIbuController,
              label: 'No Handphone/WhatsApp Ibu',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.isEmpty || val.length < 9 ? 'No Handphone tidak valid' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: emailIbuController,
              label: 'Email Ibu',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Pendidikan Ibu',
              value: pendidikanIbuValue,
              hint: '-- Pilih Pendidikan --',
              items: const [
                'Tidak Sekolah',
                'Putus SD',
                'SD Sederajat',
                'SMP Sederajat',
                'SMA Sederajat',
                'D1',
                'D3',
                'S1',
                'S2',
                'S3'
              ],
              onChanged: onPendidikanIbuChanged,
              validator: (val) => val == null ? 'Pendidikan wajib diisi' : null,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Pekerjaan Ibu',
              value: pekerjaanIbuValue,
              hint: '-- Pilih Pekerjaan --',
              items: const [
                'Tidak Bekerja',
                'Nelayan',
                'Petani',
                'Peternak',
                'PNS/TNI/POLRI',
                'Karyawan Swasta',
                'Wiraswasta',
                'Wirausaha',
                'Buruh',
                'Pensiunan',
                'Lainnya'
              ],
              onChanged: onPekerjaanIbuChanged,
              validator: (val) => val == null ? 'Pekerjaan wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: jabatanIbuController,
              label: 'Jabatan Ibu (Opsional)',
              icon: Icons.work_outline,
            ),
            SpmbFormFields.buildDropdownField(
              label: 'Penghasilan Bulanan Ibu',
              value: penghasilanIbuValue,
              hint: '-- Pilih Penghasilan --',
              items: const [
                'Tidak Berpenghasilan',
                'Kurang dari Rp. 500.000',
                'Rp. 500.000 - Rp. 2.000.000',
                'Rp. 2.000.000 - Rp. 5.000.000',
                'Rp. 5.000.000 - Rp. 10.000.000',
                'Lebih dari Rp. 20.000.000'
              ],
              onChanged: onPenghasilanIbuChanged,
              validator: (val) => val == null ? 'Penghasilan wajib diisi' : null,
            ),
            SpmbFormFields.buildTextField(
              controller: alamatKantorIbuController,
              label: 'Alamat Kantor / Perusahaan Ibu',
              icon: Icons.business,
            ),
            SpmbFormFields.buildTextField(
              controller: noKantorIbuController,
              label: 'No Kantor Ibu',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ],
    );
  }
}