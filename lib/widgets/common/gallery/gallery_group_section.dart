import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class GalleryGroupSection extends StatelessWidget {
  final String judul;
  final String tanggal;
  final List<String> imageUrls; // bisa kosong, pakai placeholder
  final void Function(int index)? onFotoTap;

  const GalleryGroupSection({
    super.key,
    required this.judul,
    required this.tanggal,
    required this.imageUrls,
    this.onFotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Group Header ---
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  tanggal,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // --- Photo Grid ---
        if (imageUrls.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: const AspectRatio(
              aspectRatio: 2,
              child: _PlaceholderPhoto(label: 'Belum ada foto'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final url = imageUrls[index];
              return GestureDetector(
                onTap: onFotoTap == null ? null : () => onFotoTap!(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: url.isNotEmpty
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _PlaceholderPhoto(),
                        )
                      : _PlaceholderPhoto(),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PlaceholderPhoto extends StatelessWidget {
  final String? label;

  const _PlaceholderPhoto({this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 40, color: AppColors.primary),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(
              label!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
