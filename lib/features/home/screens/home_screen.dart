import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/community_model.dart';
import '../../../providers/community_provider.dart';
import '../widgets/club_card.dart';
import '../widgets/community_info_modal.dart';
import '../widgets/community_rules_modal.dart';
import '../widgets/home_tab_bar.dart';

class HomeScreen extends StatefulWidget {
  final String? displayName;

  const HomeScreen({super.key, this.displayName});

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
              communityId: c.id,
              communityRules: c.rules.map((r) => r.title).join('\n'),
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

// ── Discover tab ───────────────────────────────────────────────────────────────

/// Shows category filter chips and a live-filtered list of discoverable
/// communities. Tapping a card opens [CommunityInfoModal] → [CommunityRulesModal].
class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  String _selectedCategory = AppStrings.discoverFilterAll;

  void _onCardTap(CommunityModel community) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      barrierDismissible: true,
      builder: (_) => CommunityInfoModal(
        community: community,
        onNext: () => _openRulesModal(community),
      ),
    );
  }

  void _openRulesModal(CommunityModel community) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      barrierDismissible: true,
      builder: (_) => CommunityRulesModal(
        community: community,
        onJoined: () {
          context.push(
            '/chat',
            extra: ChatArgs(
              communityName: community.name,
              communityId: community.id,
              communityRules: community.rules.map((r) => r.title).join('\n'),
              memberCount:
                  '${community.memberCount + 1} ${AppStrings.communityMembersLabel}',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<CommunityProvider>().discoverCommunities;
    final filtered = _selectedCategory == AppStrings.discoverFilterAll
        ? all
        : all.where((c) => c.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TESTING ONLY - filter UI hidden until design is finalized
        // SingleChildScrollView(
        //   scrollDirection: Axis.horizontal,
        //   child: Row(
        //     children: AppStrings.discoverCategories.map((cat) { ... }).toList(),
        //   ),
        // ),
        // const SizedBox(height: AppSizes.paddingM),

        // ── Community card list ────────────────────────────────────────
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No communities found',
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontSM,
                  color: AppColors.textGray,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final c = filtered[index];
                return ClubCard(
                  name: c.name,
                  description: c.description,
                  memberCount:
                      '${c.memberCount} ${AppStrings.communityMembersLabel}',
                  coverImage: c.coverImage,
                  onTap: () => _onCardTap(c),
                );
              },
            ),
          ),
      ],
    );
  }
}
