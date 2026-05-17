import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/community_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/profile_provider.dart';
import '../widgets/home_tab_bar.dart';
import '../widgets/club_card.dart';
import '../widgets/category_tag.dart';
import '../widgets/community_info_modal.dart';
import '../widgets/community_rules_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      if (auth.user != null) {
        context.read<CommunityProvider>().loadMyCommunities();
        context.read<ProfileProvider>().loadProfile(auth.user!.uid);
      }
    });
  }

  void _selectCategory(String category) {
    final provider = context.read<CommunityProvider>();
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        provider.loadCommunities();
      } else {
        _selectedCategory = category;
        provider.loadCommunitiesByCategory(category);
      }
    });
  }

  void _showJoinFlow(CommunityModel community) async {
    final cp = context.read<CommunityProvider>();
    // Fast path: cached list
    if (cp.myCommunities.any((c) => c.id == community.id)) {
      _goToChat(community);
      return;
    }
    // Authoritative check — myCommunities may not have emitted yet
    final isMember = await cp.checkIsMember(community.id);
    if (!mounted) return;
    if (isMember) {
      _goToChat(community);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => CommunityInfoModal(
        community: community,
        onNext: () => showDialog(
          context: context,
          builder: (_) => CommunityRulesModal(
            community: community,
            onJoined: () => context.go(
              '/chat',
              extra: ChatArgs(
                communityId: community.id,
                communityName: community.communityName,
                memberCount: community.memberCount.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<CommunityModel> _filtered(List<CommunityModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((c) =>
            c.communityName.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }

  void _goToChat(CommunityModel community) {
    context.go(
      '/chat',
      extra: ChatArgs(
        communityId: community.id,
        communityName: community.communityName,
        memberCount: community.memberCount.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();
    final pp = context.watch<ProfileProvider>();
    final userInterests = pp.profile?.interests ?? [];
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingL),
              _WelcomeHeading(),
              const SizedBox(height: AppSizes.paddingM),
              _SearchRow(
                onCreateTap: () => context.push('/create-community'),
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
              const SizedBox(height: AppSizes.paddingM),
              HomeTabBar(
                selectedIndex: _selectedTab,
                onTabChanged: (i) {
                  setState(() => _selectedTab = i);
                  final provider = context.read<CommunityProvider>();
                  if (i == 1) {
                    provider.loadMyCommunities();
                  } else {
                    provider.loadCommunities();
                  }
                },
              ),
              const SizedBox(height: AppSizes.paddingM),
              Expanded(
                child: cp.isLoading && cp.communities.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _TabContent(
                        selectedTab: _selectedTab,
                        communities: _filtered(_selectedTab == 1 ? cp.myCommunities : cp.communities),
                        myCommunities: _filtered(cp.myCommunities),
                        selectedCategory: _selectedCategory,
                        onCategoryChanged: _selectCategory,
                        onJoinTap: _showJoinFlow,
                        onDirectTap: _goToChat,
                        userInterests: userInterests,
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
    final firestoreName = context.watch<ProfileProvider>().profile?.displayName ?? '';
    final authName = context.watch<AppAuthProvider>().user?.displayName ?? '';
    final name = firestoreName.isNotEmpty ? firestoreName
        : authName.isNotEmpty ? authName
        : 'there';
    return Text(
      '${AppStrings.homeWelcome}$name',
      style: AppTextStyles.title(color: AppColors.textDark),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final VoidCallback onCreateTap;
  final ValueChanged<String> onChanged;

  const _SearchRow({required this.onCreateTap, required this.onChanged});

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
                Expanded(
                  child: TextField(
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: AppStrings.homeSearchHint,
                      hintStyle: AppTextStyles.body(
                        color: AppColors.textGray,
                        fontSize: AppSizes.fontM,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.body(fontSize: AppSizes.fontM),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingS),
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

/// Horizontal scrollable row showing the user's interests from sign-up.
class _TabContent extends StatelessWidget {
  final int selectedTab;
  final List<CommunityModel> communities;
  final List<CommunityModel> myCommunities;

  final String? selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final void Function(CommunityModel) onJoinTap;
  final void Function(CommunityModel) onDirectTap;
  final List<String> userInterests;

  const _TabContent({
    required this.selectedTab,
    required this.communities,
    required this.myCommunities,
    required this.onJoinTap,
    required this.onDirectTap,
    required this.userInterests,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 1:
        return _MyClubList(communities: myCommunities, onTap: onDirectTap);
      case 2:
        final trending = [...communities]
          ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
        return _CommunityList(communities: trending, onTap: onJoinTap);
      default:
        return _DiscoverTab(
          communities: communities,
          selectedCategory: selectedCategory,
          onCategoryChanged: onCategoryChanged,
          onTap: onJoinTap,
          userInterests: userInterests,
        );
    }
  }
}

class _MyClubList extends StatelessWidget {
  final List<CommunityModel> communities;
  final void Function(CommunityModel) onTap;

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
                name: c.communityName,
                description: c.description.isEmpty
                    ? c.tags.map((t) => t.name).join(', ')
                    : c.description,
                memberCount:
                    '${c.memberCount} member${c.memberCount == 1 ? '' : 's'}',
                coverImageUrl: c.coverImageURL.isEmpty ? null : c.coverImageURL,
                onTap: () => onTap(c),
              ))
          .toList(),
    );
  }
}

class _SelectableCategory extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableCategory({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isSelected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusM + 3),
              border: Border.all(color: AppColors.primary, width: 3),
            )
          : null,
      child: CategoryTag(label: label, color: color, onTap: onTap),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  final List<CommunityModel> communities;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final void Function(CommunityModel) onTap;
  final List<String> userInterests;

  const _DiscoverTab({
    required this.communities,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onTap,
    required this.userInterests,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == null
        ? communities
        : communities
            .where((c) => c.tags.any((t) => t.name == selectedCategory))
            .toList();

    const categoryColors = [
      AppColors.categoryGreen,
      AppColors.categoryBlue,
      AppColors.categoryPurple,
    ];

    return ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (int i = 0; i < userInterests.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSizes.paddingS),
                _SelectableCategory(
                  label: userInterests[i],
                  color: categoryColors[i % categoryColors.length],
                  isSelected: selectedCategory == userInterests[i],
                  onTap: () => onCategoryChanged(userInterests[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingM),
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSizes.paddingXL),
              child: Text(
                'No communities found',
                style: AppTextStyles.body(color: AppColors.textGray),
              ),
            ),
          )
        else
          ..._buildCommunityCards(filtered, onTap),
      ],
    );
  }
}

class _CommunityList extends StatelessWidget {
  final List<CommunityModel> communities;
  final void Function(CommunityModel) onTap;

  const _CommunityList({required this.communities, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (communities.isEmpty) {
      return Center(
        child: Text(
          'No communities yet',
          style: AppTextStyles.body(color: AppColors.textGray),
        ),
      );
    }
    return ListView(children: _buildCommunityCards(communities, onTap));
  }
}

List<Widget> _buildCommunityCards(
  List<CommunityModel> communities,
  void Function(CommunityModel) onTap,
) {
  return communities
      .map((c) => ClubCard(
            name: c.communityName,
            description:
                c.description.isEmpty ? c.tags.map((t) => t.name).join(', ') : c.description,
            memberCount:
                '${c.memberCount} member${c.memberCount == 1 ? '' : 's'}',
            coverImageUrl: c.coverImageURL.isEmpty ? null : c.coverImageURL,
            onTap: () => onTap(c),
          ))
      .toList();
}
