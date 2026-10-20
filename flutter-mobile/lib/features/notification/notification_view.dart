import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/widgets/app_refresh_indicator.dart';
import 'package:provider/provider.dart';

import 'models/notification_model.dart';
import 'viewmodel/notification_viewmodel.dart';
import '../widgets/shared_header.dart';
import '../auth/viewmodel/auth_viewmodel.dart';
import '../e-rapor/rapor_list_view.dart';
import '../kurikulum/weekly_plan/weekly_plan_view.dart';
import '../kurikulum/assignments/assignment_list_view.dart';
import '../kehadiran/view/attendance_view.dart';
import '../kurikulum/buku-komunikasi/buku_komunikasi_view.dart';
import '../kurikulum/cbt/cbt_list_view.dart';
import '../tagihan/tagihan_view.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color primaryTeal   = Color(0xFF059669);
  static const Color darkSlate     = Color(0xFF0F172A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color textSlate     = Color(0xFF475569);
  static const Color borderSlate   = Color(0xFFE2E8F0);
  static const Color mutedSlate    = Color(0xFF94A3B8);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<NotificationViewModel>();
      await vm.loadFromStorage();
      if (!mounted) return;
      final token = context.read<AuthViewModel>().token;
      if (token.isNotEmpty) {
        await vm.fetchFromApi(token, forceFullSync: true);
        _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) {
          if (!mounted) return;
          final currentToken = context.read<AuthViewModel>().token;
          if (currentToken.isNotEmpty) vm.fetchFromApi(currentToken);
        });
        if (mounted && vm.lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat: ${vm.lastError}')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'NOTIFIKASI',
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderSlate, height: 1),
        ),
      ),
      body: AppRefreshIndicator(
        color: primaryTeal,
        onRefresh: () async {
          final token = context.read<AuthViewModel>().token;
          if (token.isNotEmpty) {
            await vm.fetchFromApi(token, forceFullSync: true);
          }
        },
        child: vm.isLoading && vm.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: primaryTeal))
            : vm.notifications.isEmpty
                ? _buildEmpty()
                : _buildList(vm),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────────

  Widget _buildList(NotificationViewModel vm) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: vm.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final notif = vm.notifications[i];
        return Dismissible(
          key: ValueKey(notif.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => vm.deleteNotification(notif.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 24),
          ),
          child: _buildTile(notif, vm),
        );
      },
    );
  }

  Widget _buildTile(AppNotification notif, NotificationViewModel vm) {
    final accent = _accentColor(notif.type);
    final icon = _iconForType(notif.type);

    return Material(
      color: notif.isRead ? Colors.white : accent.withOpacity(0.03),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (!notif.isRead) vm.markAsRead(notif.id);
          _openTarget(context, notif);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? borderSlate : accent.withOpacity(0.3),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Ikon aksen
                Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                    border: Border(
                      left: BorderSide(color: accent, width: notif.isRead ? 2 : 4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 22),
                ),
                // Konten
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge tipe + waktu
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                notif.type.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _relativeTime(notif.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: mutedSlate,
                                ),
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: primaryTeal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: darkSlate,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notif.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSlate,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty ────────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 56, color: mutedSlate),
            SizedBox(height: 16),
            Text(
              'Tidak Ada Notifikasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkSlate,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Notifikasi akan muncul di sini ketika tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSlate),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  // ── Navigasi ke halaman tujuan ──────────────────────────────────────────────

  /// Buka halaman tujuan sesuai kategori notifikasi.
  /// Dipush ke nested navigator yang sama dengan NotificationPage sehingga
  /// bottom nav tetap tampil dan tombol kembali kembali ke daftar notifikasi.
  void _openTarget(BuildContext context, AppNotification notif) {
    final token = context.read<AuthViewModel>().token;
    final destination = _destinationFor(notif.type, token);
    if (destination == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  /// Mapping kategori notifikasi -> halaman tujuan.
  /// `general` tidak punya tujuan (hanya ditandai sudah dibaca).
  Widget? _destinationFor(NotificationType type, String token) => switch (type) {
        NotificationType.rapor          => RaporListViewPage(authToken: token),
        NotificationType.weeklyPlan    => WeeklyPlanScreen(authToken: token),
        NotificationType.assignment    => AssignmentListView(authToken: token),
        NotificationType.attendance    => AttendanceView(authToken: token),
        NotificationType.bukuKomunikasi => const BukuKomunikasiPage(),
        NotificationType.cbt          => const CbtListView(),
        NotificationType.tagihan       => TagihanPage(authToken: token),
        NotificationType.general      => null,
      };

  Color _accentColor(NotificationType type) => switch (type) {
        NotificationType.rapor          => const Color(0xFF0EA5E9),
        NotificationType.weeklyPlan    => const Color(0xFF8B5CF6),
        NotificationType.assignment    => const Color(0xFFF59E0B),
        NotificationType.attendance    => const Color(0xFFEF4444),
        NotificationType.bukuKomunikasi => primaryTeal,
        NotificationType.cbt          => const Color(0xFFEC4899),
        NotificationType.tagihan      => const Color(0xFF14B8A6),
        NotificationType.general      => primaryTeal,
      };

  IconData _iconForType(NotificationType type) => switch (type) {
        NotificationType.rapor          => Icons.assignment_outlined,
        NotificationType.weeklyPlan    => Icons.calendar_view_week_rounded,
        NotificationType.assignment    => Icons.task_outlined,
        NotificationType.attendance    => Icons.fact_check_outlined,
        NotificationType.bukuKomunikasi => Icons.menu_book_outlined,
        NotificationType.cbt          => Icons.quiz_outlined,
        NotificationType.tagihan      => Icons.receipt_outlined,
        NotificationType.general      => Icons.info_outline_rounded,
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
