import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/home_tab_bar.dart';
import '../widgets/category_tag.dart';

class HomeScreen extends StatefulWidget {
  final String? displayName;
  final List<String> interests;

  const HomeScreen({super.key, this.displayName, this.interests = const []});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  String get _welcomeText {
    final name = widget.displayName;
    if (name != null && name.isNotEmpty) {
      return '${AppStrings.homeWelcome}$name';
    }
    return 'Welcome!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingL),

              Text(
                _welcomeText,
                style: AppTextStyles.title(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              _SearchRow(onCreateTap: () => context.push('/create-community')),
              const SizedBox(height: AppSizes.paddingM),

              if (widget.interests.isNotEmpty) ...[
                _CategoryRow(interests: widget.interests),
                const SizedBox(height: AppSizes.paddingM),
              ],

              HomeTabBar(
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: AppSizes.paddingM),

              const Expanded(child: _EmptyTabContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _SearchRow({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSizes.paddingM),
                const Icon(Icons.search, color: AppColors.textGray, size: 18),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  AppStrings.homeSearchHint,
                  style: AppTextStyles.body(
                    color: AppColors.textGray,
                    fontSize: AppSizes.fontM,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSizes.paddingS),

        GestureDetector(
          onTap: onCreateTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.cardWhite,
              size: AppSizes.iconSize,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  const _EmptyTabContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No clubs yet',
        style: AppTextStyles.body(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textGray,
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<String> interests;

  static const List<Color> _colors = [
    AppColors.categoryGreen,
    AppColors.categoryBlue,
    AppColors.categoryPurple,
  ];

  const _CategoryRow({required this.interests});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < interests.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.paddingS),
            CategoryTag(
              label: interests[i],
              color: _colors[i % _colors.length],
            ),
          ],
        ],
      ),
    );
  }
}
