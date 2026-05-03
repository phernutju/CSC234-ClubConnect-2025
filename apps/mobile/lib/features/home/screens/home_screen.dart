import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/community_model.dart';
import '../../../providers/community_provider.dart';
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
      'count': '10',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
      'count': '10',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
      'count': '10',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '10 members',
      'count': '10',
    },
  ];

  static const List<Map<String, String>> _trendingClubs = [
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
      'count': '500',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
      'count': '500',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
      'count': '500',
    },
    {
      'name': 'Badminton Thonburi',
      'desc': 'Welcome everyone who love to play badminton come and join our ....',
      'members': '500 members',
      'count': '500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final myCommunities = context.watch<CommunityProvider>().communities;

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
                  myCommunities: myCommunities,
                  onClubTap: (args) => context.push('/chat', extra: args),
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
  final List<CommunityModel> myCommunities;
  final void Function(ChatArgs) onClubTap;

  const _TabContent({
    required this.selectedTab,
    required this.discoverClubs,
    required this.trendingClubs,
    required this.myCommunities,
    required this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 1:
        return _MyClubList(communities: myCommunities, onTap: onClubTap);
      case 2:
        return _ClubList(clubs: trendingClubs, onTap: onClubTap);
      default:
        return _DiscoverTab(clubs: discoverClubs, onTap: onClubTap);
    }
  }
}

class _MyClubList extends StatelessWidget {
  final List<CommunityModel> communities;
  final void Function(ChatArgs) onTap;

  const _MyClubList({required this.communities, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (communities.isEmpty) {
      return Center(
        child: Text(
          AppStrings.myClubEmpty,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(color: AppColors.textGray),
        ),
      );
    }
    return ListView(
      children: communities
          .map((c) => ClubCard(
                name: c.name,
                description: c.description.isEmpty ? c.category : c.description,
                memberCount: AppStrings.communityMemberDefault,
                coverImage: c.coverImage,
                onTap: () => onTap(ChatArgs(
                  communityName: c.name,
                  memberCount: AppStrings.communityMemberCountDefault,
                )),
              ))
          .toList(),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  final List<Map<String, String>> clubs;
  final void Function(ChatArgs) onTap;

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
  final void Function(ChatArgs) onTap;

  const _ClubList({required this.clubs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(children: _buildClubCards(clubs, onTap));
  }
}

List<Widget> _buildClubCards(
  List<Map<String, String>> clubs,
  void Function(ChatArgs) onTap,
) {
  return clubs
      .map((c) => ClubCard(
            name: c['name']!,
            description: c['desc']!,
            memberCount: c['members']!,
            onTap: () => onTap(ChatArgs(
              communityName: c['name']!,
              memberCount: c['count']!,
            )),
          ))
      .toList();
}
