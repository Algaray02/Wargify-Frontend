import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class GalleryGroupSection extends StatelessWidget {
  final String judul;
  final String tanggal;
  final List<String> imageUrls; // bisa kosong, pakai placeholder
  final VoidCallback? onFotoTap;

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
              onTap: onFotoTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderPhoto(),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}