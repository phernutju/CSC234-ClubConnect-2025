import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/community_model.dart';
import '../../../providers/community_provider.dart';
import '../../community/widgets/club_card.dart';
import '../../community/widgets/community_info_modal.dart';
import '../../community/widgets/community_rules_modal.dart';
import '../widgets/home_tab_bar.dart';
import '../../community/widgets/category_tag.dart';

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

              Expanded(
                child: _selectedTab == 0
                    ? const _DiscoverTab()
                    : _selectedTab == 1
                        ? _MyClubTab(communities: myCommunities)
                        : const _EmptyTabContent(),
              ),
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
        // Search bar — transparent fill, warm-stroke border, pill shape
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: AppColors.rateCardBorder,
                width: AppSizes.fieldBorderWidth,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSizes.paddingM),
                const Icon(
                  Icons.search,
                  color: AppColors.rateCardBorder,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  AppStrings.homeSearchHint,
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w300,
                    color: AppColors.fieldPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSizes.paddingS),

        // Create community button — coral square pill
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

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  void _openJoinFlow(BuildContext context, CommunityModel community) {
    showDialog<void>(
      context: context,
      builder: (_) => CommunityInfoModal(
        community: community,
        onNext: () {
          showDialog<void>(
            context: context,
            builder: (_) => CommunityRulesModal(
              community: community,
              onJoined: () => context.push(
                '/chat',
                extra: ChatArgs(
                  communityName: community.name,
                  memberCount:
                      '${community.memberCount} ${AppStrings.communityMembersLabel}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communities = context.watch<CommunityProvider>().discoverCommunities;
    if (communities.isEmpty) {
      return Center(
        child: Text(
          AppStrings.myClubEmpty,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontSM,
            color: AppColors.textGray,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final c = communities[index];
        return ClubCard(
          name: c.name,
          description: c.description,
          memberCount: '${c.memberCount} ${AppStrings.communityMembersLabel}',
          coverImage: c.coverImage,
          onTap: () => _openJoinFlow(context, c),
        );
      },
    );
  }
}

/// My Club tab — shows created communities or an empty-state prompt.
class _MyClubTab extends StatelessWidget {
  final List<CommunityModel> communities;

  const _MyClubTab({required this.communities});

  @override
  Widget build(BuildContext context) {
    if (communities.isEmpty) {
      return Center(
        child: Text(
          AppStrings.myClubEmpty,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontSM,
            color: AppColors.textGray,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final c = communities[index];
        final memberLabel =
            '${c.memberCount} ${AppStrings.communityMembersLabel}';
        return ClubCard(
          name: c.name,
          description: c.description,
          memberCount: memberLabel,
          coverImage: c.coverImage,
          onTap: () => context.push(
            '/chat',
            extra: ChatArgs(
              communityName: c.name,
              memberCount: memberLabel,
            ),
          ),
        );
      },
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
