import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/category_theme.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/core/widgets/app_search_field.dart';
import 'package:sync_daily/core/widgets/category_card.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  int currentIndex = 0;
  bool chipActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarLatar(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Galeri Komponen',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 24),
                const AppSearchField(hintText: 'Cari komponen...'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AppChip(
                      label: 'Semua',
                      isActive: chipActive,
                      onTap: () => setState(() => chipActive = !chipActive),
                    ),
                    const SizedBox(width: 8),
                    const AppChip(label: 'Tim', isActive: false),
                    const SizedBox(width: 8),
                    const AppChip(label: 'Proyek', isActive: false),
                  ],
                ),
                const SizedBox(height: 16),
                const CategoryCard(
                  category: TaskCategory.task,
                  title: 'Desain UI',
                  subtitle: 'Buat wireframe untuk halaman beranda',
                  label: 'Tugas',
                ),
                const SizedBox(height: 8),
                const CategoryCard(
                  category: TaskCategory.event,
                  title: 'Meeting Sprint',
                  subtitle: 'Diskusi backlog minggu ini',
                  label: 'Acara',
                ),
                const SizedBox(height: 8),
                const CategoryCard(
                  category: TaskCategory.reminder,
                  title: 'Ambil obat',
                  subtitle: 'Setiap pagi jam 07.00',
                  label: 'Pengingat',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: const EmptyState(
                    title: 'Belum ada data',
                    description: 'Tambahkan item untuk memulai',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Bottom Nav Preview'),
                const SizedBox(height: 12),
                AppBottomNav(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() => currentIndex = index);
                    if (index == 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tombol + ditekan')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
