import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart'; // Import DatabaseService
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/models/address_model.dart'; // Import AddressModel
import 'package:do_an_lap_trinh_android/features/user/screens/payment_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/address_management_screen.dart'; // Import màn hình quản lý địa chỉ

class CartBookingScreen extends StatefulWidget {
  final List<ServiceModel> services;
  final double totalPrice;

  const CartBookingScreen({
    super.key,
    required this.services,
    required this.totalPrice,
  });

  @override
  _CartBookingScreenState createState() => _CartBookingScreenState();
}

class _CartBookingScreenState extends State<CartBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  DateTime? _selectedDateTime;
  final dbService = DatabaseService(); // Khởi tạo DatabaseService

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress(); // Tải địa chỉ mặc định khi màn hình khởi tạo
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Hàm tải địa chỉ mặc định
  Future<void> _loadDefaultAddress() async {
     try {
       // Gọi hàm lấy địa chỉ mặc định từ DatabaseService
       final defaultAddress = await dbService.getDefaultAddress();
       if (defaultAddress != null && mounted) {
         setState(() {
           // Cập nhật text controller với địa chỉ đầy đủ
           _addressController.text = "${defaultAddress.streetBuilding}, ${defaultAddress.cityDistrictWard}";
         });
       }
     } catch(e) {
        print("Lỗi tải địa chỉ mặc định: $e");
     }
  }

  // Hàm chọn ngày giờ
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );
    if (time == null || !context.mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  // Hàm mở màn hình chọn địa chỉ
  void _selectAddress() async {
     final selectedAddress = await Navigator.push<AddressModel>(
          context,
          MaterialPageRoute(builder: (_) => const AddressManagementScreen(isSelecting: true)),
       );
     if (selectedAddress != null && mounted) {
        setState(() {
           _addressController.text = "${selectedAddress.streetBuilding}, ${selectedAddress.cityDistrictWard}";
        });
     }
  }

  // Hàm xử lý khi nhấn nút "Tiếp tục"
  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ngày giờ hẹn')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            services: widget.services, // Truyền danh sách dịch vụ từ giỏ hàng
            address: _addressController.text.trim(),
            selectedDateTime: _selectedDateTime!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận Đặt lịch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Các dịch vụ trong giỏ hàng:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              // Hiển thị danh sách dịch vụ đã chọn
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.services.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final service = widget.services[index];
                    return ListTile(
                      title: Text(service.name),
                      trailing: Text('${currencyFormatter.format(service.price)} VNĐ'),
                    );
                  },
                ),
              ),
              const Divider(height: 32),

              // Ô nhập/hiển thị địa chỉ
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ nhận dịch vụ',
                  hintText: 'Chọn hoặc nhập địa chỉ của bạn',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  // Nút để chọn địa chỉ khác
                  suffixIcon: IconButton(
                     tooltip: 'Chọn địa chỉ đã lưu',
                     icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                     onPressed: _selectAddress, // Mở danh sách chọn
                  )
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập hoặc chọn địa chỉ' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Ô chọn ngày giờ
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Chọn ngày giờ hẹn'),
                subtitle: Text(
                  _selectedDateTime == null
                      ? 'Chưa chọn'
                      : DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDateTime!),
                   style: TextStyle(
                    color: _selectedDateTime == null ? Colors.grey : Colors.blue,
                    fontWeight: FontWeight.bold
                  ),
                ),
                onTap: _pickDateTime,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _proceedToPayment,
            // Hiển thị tổng giá gốc trên nút
            child: Text('Tiếp tục - ${currencyFormatter.format(widget.totalPrice)} VNĐ'),
          ),
        ),
      ),
    );
  }
}