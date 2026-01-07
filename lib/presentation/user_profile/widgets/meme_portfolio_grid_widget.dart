import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MemePortfolioGridWidget extends StatelessWidget {
  final List<dynamic> memes;

  const MemePortfolioGridWidget({super.key, required this.memes});

  @override
  Widget build(BuildContext context) {
    if (memes.isEmpty) {
      return Container(
        height: 30.h,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48.sp,
              color: AppTheme.textSecondaryDark.withAlpha(128),
            ),
            SizedBox(height: 2.h),
            Text(
              'No memes yet',
              style: TextStyle(
                color: AppTheme.textSecondaryDark,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 1.0,
      ),
      itemCount: memes.length,
      itemBuilder: (context, index) {
        final meme = memes[index];
        final imageUrl = meme['image_url'] ?? '';
        final thumbnailUrl = meme['thumbnail_url'] ?? imageUrl;
        final likeCount = meme['like_count'] ?? 0;
        final commentCount = meme['comment_count'] ?? 0;

        return GestureDetector(
          onTap: () {
            // Navigate to meme detail screen
            // Navigator.pushNamed(context, AppRoutes.memeDetail, arguments: meme);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withAlpha(26),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CustomImageWidget(
                    imageUrl: thumbnailUrl.isNotEmpty
                        ? thumbnailUrl
                        : imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(179)],
                  ),
                ),
              ),
              Positioned(
                bottom: 1.w,
                left: 1.w,
                right: 1.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: AppTheme.secondaryDark,
                          size: 12.sp,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          likeCount.toString(),
                          style: TextStyle(
                            color: AppTheme.textPrimaryDark,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          color: AppTheme.primaryDark,
                          size: 12.sp,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          commentCount.toString(),
                          style: TextStyle(
                            color: AppTheme.textPrimaryDark,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}