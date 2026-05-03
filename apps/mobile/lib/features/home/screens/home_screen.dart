import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/home_tab_bar.dart';
import '../widgets/club_card.dart';
import '../widgets/category_tag.dart';

/// Main home screen with "Welcome, [Username]", a search bar,
/// and three tabs: Discover / My club / Trending.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  static const List<Map<String, String>> _discoverClubs = [
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
    },
  ];

  static const List<Map<String, String>> _trendingClubs = [
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
    },
  ];

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

              // "Welcome, [Username]" serif heading
              _WelcomeHeading(),
              const SizedBox(height: AppSizes.paddingM),

              // Search bar row + "+" create-community button
              _SearchRow(onCreateTap: () => context.push('/create-community')),
              const SizedBox(height: AppSizes.paddingM),

              // Discover / My club / Trending tab row
              HomeTabBar(
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: AppSizes.paddingM),

              Expanded(
                child: _TabContent(
                  selectedTab: _selectedTab,
                  discoverClubs: _discoverClubs,
                  trendingClubs: _trendingClubs,
                  onClubTap: () => context.push('/chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _WelcomeHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.homeWelcome + AppStrings.homeUsername,
      style: AppTextStyles.title(color: AppColors.textDark),
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

class _TabContent extends StatelessWidget {
  final int selectedTab;
  final List<Map<String, String>> discoverClubs;
  final List<Map<String, String>> trendingClubs;
  final VoidCallback onClubTap;

  const _TabContent({
    required this.selectedTab,
    required this.discoverClubs,
    required this.trendingClubs,
    required this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 1:
        return _ClubList(clubs: discoverClubs, onTap: onClubTap);
      case 2:
        return _ClubList(clubs: trendingClubs, onTap: onClubTap);
      default:
        return _DiscoverTab(clubs: discoverClubs, onTap: onClubTap);
    }
  }
}

class _DiscoverTab extends StatelessWidget {
  final List<Map<String, String>> clubs;
  final VoidCallback onTap;

  const _DiscoverTab({required this.clubs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            CategoryTag(label: 'Badminton', color: AppColors.categoryGreen),
            CategoryTag(label: 'Coding',    color: AppColors.categoryBlue),
            CategoryTag(label: 'Games',     color: AppColors.categoryPurple),
          ],
        ),
        const SizedBox(height: AppSizes.paddingM),
        ..._buildClubCards(clubs, onTap),
      ],
    );
  }
}

class _ClubList extends StatelessWidget {
  final List<Map<String, String>> clubs;
  final VoidCallback onTap;

  const _ClubList({required this.clubs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(children: _buildClubCards(clubs, onTap));
  }
}

List<Widget> _buildClubCards(
  List<Map<String, String>> clubs,
  VoidCallback onTap,
) {
  return clubs
      .map((c) => ClubCard(
            name: c['name']!,
            description: c['desc']!,
            memberCount: c['members']!,
            onTap: onTap,
          ))
      .toList();
}
