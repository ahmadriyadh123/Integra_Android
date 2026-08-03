import 'package:flutter/material.dart';

// Catatan: Impor file widget bersama jika diperlukan untuk kompatibilitas ke belakang
export '../../widgets/form_fields.dart';

/// Kumpulan Widget Pembantu Formulir SPMB yang Bersih & Modular
class SpmbFormFields {
  
  static Widget buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }

  static Widget buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal.shade700, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...children.expand((widget) => [widget, const SizedBox(height: 16)]),
          ],
        ),
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.teal.shade600, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static Widget buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'mm/dd/yyyy',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.calendar_month_outlined, color: Colors.teal.shade600, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildRadioField({
    required String label,
    required bool? value,
    required void Function(bool?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onChanged(true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: value == true ? Colors.teal.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value == true ? Colors.teal : Colors.grey.shade200,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        value == true ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: value == true ? Colors.teal : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ya',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: value == true ? FontWeight.bold : FontWeight.normal,
                          color: value == true ? Colors.teal.shade900 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => onChanged(false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == false ? Colors.teal.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value == false ? Colors.teal : Colors.grey.shade200,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        value == false ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: value == false ? Colors.teal : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tidak',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: value == false ? FontWeight.bold : FontWeight.normal,
                          color: value == false ? Colors.teal.shade900 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}