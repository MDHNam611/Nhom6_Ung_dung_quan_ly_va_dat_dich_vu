import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart'; // Import DatabaseService nếu cần lấy địa chỉ
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/models/address_model.dart'; // Import AddressModel
import 'package:do_an_lap_trinh_android/features/user/screens/payment_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/address_management_screen.dart'; // Import màn hình quản lý địa chỉ

class BookingScreen extends StatefulWidget {
  final ServiceModel service;
  const BookingScreen({super.key, required this.service});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
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
        // Có thể hiển thị SnackBar báo lỗi nếu cần
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
     // Điều hướng đến màn hình quản lý địa chỉ ở chế độ chọn (isSelecting: true)
     final selectedAddress = await Navigator.push<AddressModel>(
          context,
          // Truyền cờ isSelecting = true
          MaterialPageRoute(builder: (_) => const AddressManagementScreen(isSelecting: true)),
       );
     // Nếu người dùng chọn một địa chỉ và quay lại
     if (selectedAddress != null && mounted) {
        setState(() {
           // Cập nhật text controller với địa chỉ đã chọn
           _addressController.text = "${selectedAddress.streetBuilding}, ${selectedAddress.cityDistrictWard}";
        });
     }
  }

  // Hàm xử lý khi nhấn nút "Tiếp tục"
  void _proceedToPayment() {
    // 1. Kiểm tra xem form có hợp lệ không (bao gồm cả validator của TextFormField địa chỉ)
    if (_formKey.currentState!.validate()) {
      // 2. Kiểm tra xem người dùng đã chọn ngày giờ chưa
      if (_selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ngày giờ hẹn')),
        );
        return;
      }

      // 3. Nếu mọi thứ hợp lệ, điều hướng đến trang thanh toán
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            services: [widget.service], // Truyền dịch vụ trong một danh sách
            address: _addressController.text.trim(), // Lấy địa chỉ từ controller
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
      appBar: AppBar(title: const Text('Thông tin Đặt lịch')),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(16.0),
         child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dịch vụ đã chọn:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    title: Text(widget.service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${currencyFormatter.format(widget.service.price)} VNĐ'),
                    trailing: Text('${widget.service.estimatedDuration} phút'),
                  ),
                ),
                const SizedBox(height: 24),

                // Ô nhập/hiển thị địa chỉ
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
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


                  textAlignVertical: TextAlignVertical.center,
                  // Validator kiểm tra ô không được trống
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập hoặc chọn địa chỉ' : null,
                  maxLines: 2, // Cho phép hiển thị địa chỉ dài
                  // Bạn có thể đặt readOnly: true nếu muốn người dùng bắt buộc phải chọn từ danh sách
                  // readOnly: true,
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
                      color: _selectedDateTime == null ? Colors.grey : Colors.blue, // Đổi màu khi đã chọn
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
      // Nút điều hướng đến trang thanh toán
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal, // Màu nút
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _proceedToPayment,
            child: const Text('Tiếp tục đến Thanh toán'),
          ),
        ),
      ),
    );
  }
}