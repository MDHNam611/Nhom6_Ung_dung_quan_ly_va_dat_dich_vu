import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/category_model.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/features/user/widgets/service_list_item.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String? _selectedCategoryId;
  String _searchQuery = '';
  String _sortBy = 'name_asc';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text && mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _searchHistory = prefs.getStringList('search_history') ?? [];
      });
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    _searchHistory.remove(trimmedQuery);
    _searchHistory.insert(0, trimmedQuery);
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    if (mounted) setState(() {});
  }

  Future<void> _removeSearchHistoryItem(String query) async {
    _searchHistory.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    if (mounted) setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    if (mounted) {
      setState(() {
        _searchHistory = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildHeaderAndSearch(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromoBanner(),
                _buildVoucherBanner(context), // Banner Voucher
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Danh mục Dịch vụ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildCategoryList(),
                if (_searchFocusNode.hasFocus) _buildSearchHistoryView(), 
                if (!_searchFocusNode.hasFocus) 
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Text('Dịch vụ cho bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          _buildServiceList(),
        ],
      ),
    );
  }

  Widget _buildHeaderAndSearch() {
    final user = FirebaseAuth.instance.currentUser;
    return SliverAppBar(
      backgroundColor: Colors.blue,
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight, left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${user?.displayName ?? 'bạn'}!',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn đang tìm kiếm dịch vụ gì?',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        title: SizedBox(
          height: 40, 
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Sửa điện, dọn nhà...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0.0), // Căn giữa nội dung
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: _saveSearchHistory,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Image.network(
              'https://images.pexels.com/photos/4239031/pexels-photo-4239031.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                'Giảm giá 20%\nDọn dẹp nhà cửa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherBanner(BuildContext context) {
    final dbService = DatabaseService();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
          try {
            final voucher = await dbService.claimRandomVoucher();
            if (!context.mounted) return;
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('🎉 Chúc mừng! 🎉'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text('Bạn đã nhận được mã giảm giá:'),
                     const SizedBox(height: 8),
                     Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     Text('Giảm ${voucher.discountPercentage}% cho dịch vụ.'),
                     Text('HSD: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(voucher.expiryAt))}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tuyệt vời!'))],
              ),
            );
          } catch (e) {
             if (!context.mounted) return;
             Navigator.of(context).pop();
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100)
          ),
          child: const Row(
            children: [
              Icon(Icons.local_offer, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(child: Text('Săn mã giảm giá mỗi ngày!', style: TextStyle(fontWeight: FontWeight.bold))),
              Text('Nhận ngay >', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryList() {
    return StreamBuilder<DatabaseEvent>(
      stream: _dbService.getCategoriesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SizedBox(height: 50);
        }
        final categories = <CategoryModel>[];
        final data = snapshot.data!.snapshot.value as Map;
        data.forEach((key, value) {
          categories.add(CategoryModel.fromMap(key, value));
        });

        return Container(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ChoiceChip(
                  label: const Text('Tất cả'),
                  selectedColor: Colors.blue.shade100,
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) => setState(() => _selectedCategoryId = null),
                );
              }
              final category = categories[index - 1];
              return ChoiceChip(
                label: Text(category.name),
                selectedColor: Colors.blue.shade100,
                selected: _selectedCategoryId == category.id,
                onSelected: (selected) => setState(() => _selectedCategoryId = selected ? category.id : null),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildSearchHistoryView() {
    if (_searchFocusNode.hasFocus && _searchQuery.isEmpty && _searchHistory.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tìm kiếm gần đây', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _searchHistory.map((history) {
                return Chip(
                  label: Text(history),
                  backgroundColor: Colors.grey[200],
                  onDeleted: () => _removeSearchHistoryItem(history),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).map((chip) {
                final label = (chip.label as Text).data!;
                return GestureDetector(
                  onTap: () {
                    _searchController.text = label;
                    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                    _saveSearchHistory(label);
                    _searchFocusNode.unfocus();
                  },
                  child: chip,
                );
              }).toList(),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildServiceList() {
    return StreamBuilder<DatabaseEvent>(
      stream: _dbService.getServicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SliverFillRemaining(child: Center(child: Text("Không có dịch vụ nào.")));
        }

        final services = <ServiceModel>[];
        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          services.add(ServiceModel.fromMap(key, value));
        });

        final displayedServices = services.where((s) {
          final matchCategory = _selectedCategoryId == null || s.categoryId == _selectedCategoryId;
          final matchSearch = _searchQuery.isEmpty || s.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchCategory && matchSearch;
        }).toList();

        displayedServices.sort((a, b) {
          switch (_sortBy) {
            case 'price_asc':
              return a.price.compareTo(b.price);
            case 'price_desc':
              return b.price.compareTo(a.price);
            case 'name_asc':
            default:
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
        });

        if (displayedServices.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text("Không tìm thấy dịch vụ phù hợp.")));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return ServiceListItem(service: displayedServices[index]);
            },
            childCount: displayedServices.length,
          ),
        );
      },
    );
  }
}