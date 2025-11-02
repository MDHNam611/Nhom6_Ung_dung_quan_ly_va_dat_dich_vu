import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/user_model.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Người dùng')),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getUsersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Không có người dùng nào."));
          }
          final usersMap = snapshot.data!.snapshot.value as Map;
          final users = usersMap.entries.map((e) {
            return UserModel.fromMap(e.key, e.value);
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Chip(
                    label: Text(
                      user.role,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: user.role == 'admin' ? Colors.redAccent : Colors.green,
                  ),
                  onLongPress: () { // Giữ lâu để đổi vai trò
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Đổi vai trò'),
                        content: Text('Bạn có muốn đổi vai trò cho ${user.name}?'),
                        actions: [
                          TextButton(
                            child: const Text('Huỷ'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: Text('Đặt làm ${user.role == 'admin' ? 'User' : 'Admin'}'),
                            onPressed: () {
                              final newRole = user.role == 'admin' ? 'user' : 'admin';
                              dbService.updateUserRole(user.uid, newRole);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}