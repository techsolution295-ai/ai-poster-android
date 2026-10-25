import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/design_model.dart';
import '../../services/ad_service.dart';
import '../../services/design_history_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../editor/poster_editor_screen.dart';
import '../export/export_screen.dart';

/// "My Designs" — a searchable, local history of saved posters (Hive).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final _service = DesignHistoryService.instance;

  List<SavedDesign> _designs = [];
  bool _loading = true;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Called when the History tab is selected so IndexedStack stays fresh.
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final designs = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _designs = designs;
      _loading = false;
    });
  }

  Future<void> _delete(SavedDesign d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete design?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(d.id);
      _load();
    }
  }

  void _open(SavedDesign d) {
    AdService.instance.showSelectInterstitialThen(() async {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PosterEditorScreen(savedDesign: d)),
      );
      if (mounted) _load();
    });
  }

  void _export(SavedDesign d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportScreen(
          design: d.design,
          historyId: d.id,
          categoryId: d.categoryId,
          categoryName: d.categoryName,
          title: d.title,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        _banner(),
        _filterTabs(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 10),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: TextStyle(fontSize: 42 / 2, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text(
                  'Your recent designs and edits',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1364 / 291,
          child: Image.asset(AppConstants.historyBannerAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _filterTabs() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          _tab('all', Icons.grid_view_rounded, 'All'),
          _tab('recent', Icons.access_time_filled_rounded, 'Recent'),
          _tab('saved', Icons.bookmark_border_rounded, 'Saved'),
          _tab('downloaded', Icons.download_rounded, 'Downloaded'),
        ],
      ),
    );
  }

  Widget _tab(String key, IconData icon, String label) {
    final active = _activeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)])
                : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? Colors.transparent : AppColors.divider),
            boxShadow: active
                ? const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : AppColors.muted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    final list = _applyFilter(_designs);
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open,
        title: 'No saved designs yet',
        message:
            'Open a poster, tap the bookmark to save, or Export → Save. It will show up here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: _groupedSections(list),
      ),
    );
  }

  List<Widget> _groupedSections(List<SavedDesign> designs) {
    final now = DateTime.now();
    final today = <SavedDesign>[];
    final yesterday = <SavedDesign>[];
    final week = <SavedDesign>[];
    for (final d in designs) {
      final dt = d.updatedAt;
      final dayDiff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      if (dayDiff == 0) {
        today.add(d);
      } else if (dayDiff == 1) {
        yesterday.add(d);
      } else {
        week.add(d);
      }
    }

    final widgets = <Widget>[];
    if (today.isNotEmpty) {
      widgets.add(_sectionTitle('Today'));
      widgets.addAll(today.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _tile(e),
          )));
    }
    if (yesterday.isNotEmpty) {
      widgets.add(_sectionTitle('Yesterday'));
      widgets.addAll(yesterday.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _tile(e),
          )));
    }
    if (week.isNotEmpty) {
      widgets.add(_sectionTitle('Earlier'));
      widgets.addAll(week.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _tile(e),
          )));
    }
    return widgets;
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
        child: Text(text, style: const TextStyle(fontSize: 30 / 2, fontWeight: FontWeight.w700)),
      );

  List<SavedDesign> _applyFilter(List<SavedDesign> list) {
    switch (_activeFilter) {
      case 'recent':
        final now = DateTime.now();
        return list.where((d) => now.difference(d.updatedAt).inDays <= 2).toList();
      case 'downloaded':
        // Designs that have a local preview (saved via Save / Export).
        return list.where((d) => d.previewPath.isNotEmpty).toList();
      case 'saved':
      case 'all':
      default:
        return list;
    }
  }

  Widget _tile(SavedDesign d) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(d),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: d.previewPath.isNotEmpty && File(d.previewPath).existsSync()
                      ? Image.file(File(d.previewPath), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.image, color: AppColors.primary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title.isEmpty ? 'Untitled design' : d.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16 / 1.05),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _categoryColor(d.categoryName).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.categoryName.isEmpty ? 'Poster' : _shortCategory(d.categoryName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _categoryColor(d.categoryName),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(d.updatedAt),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
                  onSelected: (v) {
                    switch (v) {
                      case 'open':
                        _open(d);
                        break;
                      case 'export':
                        _export(d);
                        break;
                      case 'delete':
                        _delete(d);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'open', child: Text('Edit')),
                    PopupMenuItem(value: 'export', child: Text('Export')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime d) {
    final now = DateTime.now();
    final dayDiff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    final hh = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final mm = d.minute.toString().padLeft(2, '0');
    if (dayDiff == 0) return 'Today, $hh:$mm $amPm';
    if (dayDiff == 1) return 'Yesterday, $hh:$mm $amPm';
    return '${d.day}/${d.month}/${d.year}, $hh:$mm $amPm';
  }

  String _shortCategory(String name) {
    if (name.toLowerCase().contains('business')) return 'Business';
    if (name.toLowerCase().contains('travel')) return 'Travel';
    if (name.toLowerCase().contains('college')) return 'College';
    if (name.toLowerCase().contains('sale')) return 'Sale';
    if (name.toLowerCase().contains('social')) return 'Social';
    if (name.toLowerCase().contains('umrah')) return 'Umrah';
    return name;
  }

  Color _categoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('business')) return const Color(0xFF2563EB);
    if (n.contains('travel')) return const Color(0xFFD97706);
    if (n.contains('college')) return const Color(0xFF16A34A);
    if (n.contains('sale')) return const Color(0xFFEF4444);
    if (n.contains('social')) return const Color(0xFFEC4899);
    if (n.contains('umrah')) return const Color(0xFF7C3AED);
    return AppColors.primary;
  }
}
