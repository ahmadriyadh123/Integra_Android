import 'package:flutter/material.dart';

class CustomDropdownBelowField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;

  const CustomDropdownBelowField({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<CustomDropdownBelowField> createState() => _CustomDropdownBelowFieldState();
}

class _CustomDropdownBelowFieldState extends State<CustomDropdownBelowField> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<String> state) {
        
        // Memastikan internal state FormField sinkron dengan value dari Parent
        if (widget.value != state.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.didChange(widget.value);
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              controller: _menuController,
              // Mengatur posisi dan ukuran menu pop-up
              style: MenuStyle(
                // Memaksa lebar menu pop-up sama persis dengan lebar form
                minimumSize: WidgetStateProperty.all(Size(constraints.maxWidth, 0)),
                maximumSize: WidgetStateProperty.all(Size(constraints.maxWidth, 250)), // Max height agar bisa di-scroll
                backgroundColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(4),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              // Render Daftar Pilihan Dropdown
              menuChildren: widget.items.map((item) {
                final isSelected = item == widget.value;
                return MenuItemButton(
                  style: MenuItemButton.styleFrom(
                    backgroundColor: isSelected ? Colors.teal.shade50 : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    state.didChange(item); // Update validasi
                    widget.onChanged(item); // Update parent UI
                    _menuController.close();
                  },
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? Colors.teal : const Color(0xFF0F172A),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              
              // Render Form Tampilan Luar
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      // Tutup keyboard jika sedang aktif agar UI rapi
                      FocusScope.of(context).unfocus();
                      controller.open();
                    }
                  },
                  child: InputDecorator(
                    isEmpty: widget.value == null || widget.value!.isEmpty,
                    decoration: InputDecoration(
                      labelText: widget.label,
                      hintText: widget.hint ?? '-- Pilih --',
                      prefixIcon: widget.prefixIcon != null 
                          ? Icon(widget.prefixIcon, color: Colors.teal) 
                          : null,
                      suffixIcon: Icon(
                        controller.isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                      errorText: state.errorText, // Pesan error validasi form
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    child: Text(
                      widget.value ?? widget.hint ?? '-- Pilih --',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.value == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}