import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';

// Model đơn giản để chứa câu hỏi/trả lời
class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});

  factory FaqItem.fromMap(Map<dynamic, dynamic> map) {
    return FaqItem(
      question: map['question'] ?? 'Không có câu hỏi',
      answer: map['answer'] ?? 'Không có câu trả lời',
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm Trợ giúp'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getFaqsStream(), // Gọi hàm đã tạo ở Bước 2
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                'Chưa có câu hỏi thường gặp nào.',
                 style: TextStyle(color: Colors.grey, fontSize: 16),
              )
            );
          }

          final faqsMap = snapshot.data!.snapshot.value as Map;
          final faqs = faqsMap.entries.map((e) {
            // Đảm bảo chỉ parse nếu là Map
            if (e.value is Map) {
               return FaqItem.fromMap(e.value);
            }
            return null;
          }).whereType<FaqItem>().toList(); // Lọc bỏ các giá trị null

          if (faqs.isEmpty) {
            return const Center(child: Text("Không có câu hỏi nào."));
          }

          // Sử dụng ExpansionTile để tạo danh sách có thể mở rộng
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bỏ viền khi mở
                  title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: Icon(Icons.help_outline, color: Colors.blue[700]),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black54),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}