import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/address_model.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/add_edit_address_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  final bool isSelecting; // Cờ để biết có đang chọn địa chỉ hay không
  const AddressManagementScreen({super.key, this.isSelecting = false});

  @override
  _AddressManagementScreenState createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final dbService = DatabaseService();

  Future<void> _setDefault(String id) async {
    try {
      await dbService.setDefaultAddress(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đặt làm địa chỉ mặc định')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteAddress(String id) async {
     // Hiển thị dialog xác nhận
     final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           title: const Text('Xác nhận xóa'),
           content: const Text('Bạn có chắc muốn xóa địa chỉ này?'),
           actions: [
             TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
             TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
           ],
        ),
     );
     if (confirm == true) {
        try {
          await dbService.deleteAddress(id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa địa chỉ')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Chọn địa chỉ' : 'Sổ địa chỉ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getUserAddressesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Bạn chưa có địa chỉ nào.'));
          }
          final addressesMap = snapshot.data!.snapshot.value as Map;
          final addresses = addressesMap.entries.map((e) {
            return AddressModel.fromMap(e.key, e.value);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: address.isDefault ? 3 : 1, // Nổi bật địa chỉ mặc định
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: address.isDefault ? Colors.blue : Colors.grey.shade300)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(address.streetBuilding, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(address.cityDistrictWard),
                  leading: Icon(
                    address.isDefault ? Icons.star_rounded : Icons.star_border_rounded,
                    color: address.isDefault ? Colors.orangeAccent : Colors.grey,
                    size: 28,
                  ),
                  trailing: PopupMenuButton<String>( // Nút 3 chấm
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)));
                      } else if (value == 'delete') {
                         _deleteAddress(address.id);
                      } else if (value == 'setDefault') {
                         _setDefault(address.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      if (!address.isDefault) // Chỉ hiện nếu chưa phải mặc định
                        const PopupMenuItem<String>(
                          value: 'setDefault',
                          child: ListTile(leading: Icon(Icons.star_outline), title: Text('Đặt làm mặc định')),
                        ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Chỉnh sửa')),
                      ),
                       PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Xóa', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () {
                     if (widget.isSelecting) {
                        // Nếu đang chọn, trả về địa chỉ đã chọn
                        Navigator.pop(context, address);
                     } else {
                        // Nếu không phải đang chọn, đặt làm mặc định
                        if (!address.isDefault) {
                           _setDefault(address.id);
                        }
                     }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Điều hướng đến trang thêm địa chỉ mới
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAddressScreen()));
        },
        label: const Text('Thêm địa chỉ mới'),
        icon: const Icon(Icons.add_location_alt_outlined),
        backgroundColor: Colors.blue,
      ),
    );
  }
}