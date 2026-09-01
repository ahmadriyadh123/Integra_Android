import 'package:flutter/material.dart';

class VideoDiscussionTab extends StatefulWidget {
  final void Function(String) onToastMessage;

  const VideoDiscussionTab({super.key, required this.onToastMessage});

  @override
  State<VideoDiscussionTab> createState() => _VideoDiscussionTabState();
}

class _VideoDiscussionTabState extends State<VideoDiscussionTab> {
  final TextEditingController _commentController = TextEditingController();
  
  final List<Map<String, String>> _comments = [
    {
      'name': 'Siti Nurhaliza',
      'time': '10 Menit lalu',
      'text': 'Pak, untuk segitiga tumpul apakah aturan sinus ini tetap berlaku sama?',
      'isTeacher': 'false',
    },
    {
      'name': 'Bpk. Hendra, S.Pd (Guru)',
      'time': '5 Menit lalu',
      'text': 'Ya Siti, aturan sinus berlaku untuk semua jenis segitiga, termasuk segitiga tumpul.',
      'isTeacher': 'true',
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);
    const Color primaryLightColor = Color(0xFFECFDF5);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final isTeacher = comment['isTeacher'] == 'true';
              
              return Container(
                margin: EdgeInsets.only(left: isTeacher ? 20 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTeacher ? primaryLightColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTeacher ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment['name']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isTeacher ? primaryColor : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          comment['time']!,
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['text']!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Tanyakan materi ini ke guru...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_commentController.text.trim().isNotEmpty) {
                    setState(() {
                      _comments.add({
                        'name': 'Budi Santoso (Siswa)',
                        'time': 'Baru saja',
                        'text': _commentController.text,
                        'isTeacher': 'false',
                      });
                      _commentController.clear();
                    });
                    widget.onToastMessage('Pertanyaan berhasil dikirim!');
                  }
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}