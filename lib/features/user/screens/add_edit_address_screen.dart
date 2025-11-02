import 'package:flutter/material.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/address_model.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address; 
  const AddEditAddressScreen({super.key, this.address});

  @override
  _AddEditAddressScreenState createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbService = DatabaseService();
  late TextEditingController _cityDistrictWardController;
  late TextEditingController _streetBuildingController;
  bool _isDefault = false;
  bool _isLoading = false;

   @override
  void initState() {
    super.initState();
    _cityDistrictWardController = TextEditingController(text: widget.address?.cityDistrictWard ?? '');
    _streetBuildingController = TextEditingController(text: widget.address?.streetBuilding ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _cityDistrictWardController.dispose();
    _streetBuildingController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
     if (_formKey.currentState!.validate()) {
        setState(() => _isLoading = true);
        final newAddressData = AddressModel(
          id: widget.address?.id ?? '', // Giữ ID cũ nếu là sửa
          cityDistrictWard: _cityDistrictWardController.text.trim(),
          streetBuilding: _streetBuildingController.text.trim(),
          isDefault: _isDefault,
        );

        try {
          if (widget.address == null) {
            // Thêm địa chỉ mới
            final newId = await dbService.addAddress(newAddressData);
            if (newId != null && _isDefault) {
              // Nếu đặt làm mặc định khi thêm mới
              await dbService.setDefaultAddress(newId);
            }
          } else {
            // Cập nhật địa chỉ cũ
            await dbService.updateAddress(newAddressData);
            if (_isDefault) {
              // Nếu đặt làm mặc định khi cập nhật
              await dbService.setDefaultAddress(newAddressData.id);
            }
          }
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu địa chỉ thành công!')));
           Navigator.pop(context, true); // Trả về true để báo hiệu cần load lại ds địa chỉ
        } catch (e) {
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
        } finally {
           if (mounted) setState(() => _isLoading = false);
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.address == null ? 'Thêm địa chỉ mới' : 'Cập nhật địa chỉ')),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(24.0),
         child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _cityDistrictWardController,
                  decoration: const InputDecoration(labelText: 'Quận/Huyện, Phường/Xã', border: OutlineInputBorder()),
                  validator: (value) => value!.trim().isEmpty ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  controller: _streetBuildingController,
                  decoration: const InputDecoration(labelText: 'Tên đường, Tòa nhà, Số nhà', border: OutlineInputBorder()),
                  validator: (value) => value!.trim().isEmpty ? 'Không được để trống' : null,
                ),
                 const SizedBox(height: 16),
                 SwitchListTile(
                    title: const Text('Đặt làm địa chỉ mặc định'),
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                    activeColor: Colors.blue,
                 ),
                 const SizedBox(height: 32),
                 ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.blue,
                     minimumSize: const Size(double.infinity, 50),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                   ),
                   onPressed: _isLoading ? null : _saveAddress,
                   child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu địa chỉ'),
                 )
              ],
            ),
         ),
      ),
    );
  }
}