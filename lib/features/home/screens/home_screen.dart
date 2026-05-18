import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/community_model.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../community/widgets/event_card.dart';
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
        final cp = context.read<CommunityProvider>();
        cp.loadMyCommunities();
        cp.loadTrendingCommunities();
        cp.loadDiscoverFirstPage();
        context.read<ProfileProvider>().loadProfile(auth.user!.uid);
        context.read<EventProvider>().loadPublishedEvents();
      }
    });
  }

  void _selectCategory(String category) {
    final provider = context.read<CommunityProvider>();
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        provider.loadDiscoverFirstPage();
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
            c.description.toLowerCase().contains(q) ||
            c.tags.any((t) => t.name.toLowerCase().contains(q)))
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
    final userInterests = (pp.profile?.interests ?? []).toList()
      ..sort((a, b) => a.compareTo(b));
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / search / tabs — keep 24px horizontal padding
            Padding(
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
                      if (i != 3) {
                        final provider = context.read<CommunityProvider>();
                        if (i == 1) {
                          provider.loadMyCommunities();
                        } else if (i == 0) {
                          provider.loadDiscoverFirstPage();
                        } else {
                          provider.loadCommunities();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                ],
              ),
            ),

            // Tab content — no outer horizontal padding; each tab owns its own
            Expanded(
              child: _selectedTab != 3 && cp.isLoading && cp.communities.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _TabContent(
                      selectedTab: _selectedTab,
                      communities: _filtered(_selectedTab == 1 ? cp.myCommunities : cp.communities),
                      myCommunities: _filtered(cp.myCommunities),
                      trendingCommunities: _filtered(cp.trendingCommunities),
                      isTrendingLoading: cp.isTrendingLoading,
                      trendingError: cp.trendingError,
                      onRetryTrending: () => context.read<CommunityProvider>().loadTrendingCommunities(),
                      onJoinTap: _showJoinFlow,
                      onDirectTap: _goToChat,
                      userInterests: userInterests,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: _selectCategory,
                      searchQuery: _searchQuery,
                    ),
            ),
          ],
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



class _TabContent extends StatelessWidget {
  final int selectedTab;
  final List<CommunityModel> communities;
  final List<CommunityModel> myCommunities;
  final List<CommunityModel> trendingCommunities;
  final bool isTrendingLoading;
  final String? trendingError;
  final VoidCallback onRetryTrending;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final void Function(CommunityModel) onJoinTap;
  final void Function(CommunityModel) onDirectTap;
  final List<String> userInterests;
  final String searchQuery;

  const _TabContent({
    required this.selectedTab,
    required this.communities,
    required this.myCommunities,
    required this.trendingCommunities,
    required this.isTrendingLoading,
    required this.onRetryTrending,
    required this.onJoinTap,
    required this.onDirectTap,
    required this.userInterests,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.searchQuery,
    this.trendingError,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 1:
        return _MyClubList(communities: myCommunities, onTap: onDirectTap);
      case 2:
        return _TrendingTab(
          communities: trendingCommunities,
          isLoading: isTrendingLoading,
          error: trendingError,
          onTap: onJoinTap,
          onRetry: onRetryTrending,
        );
      case 3:
        return _GlobalEventsTab(searchQuery: searchQuery);
      default:
        return _DiscoverTab(
          communities: communities,
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
          onCategoryChanged: onCategoryChanged,
          onTap: onJoinTap,
          userInterests: userInterests,
        );
    }
  }
}

enum _EventFilter { all, myClubs, otherClubs }

enum _DiscoverSort { newestFirst, oldestFirst, mostMembers, leastMembers }

/// Inline Events tab: loads and shows published events within the Home screen.
class _GlobalEventsTab extends StatefulWidget {
  final String searchQuery;
  const _GlobalEventsTab({this.searchQuery = ''});

  @override
  State<_GlobalEventsTab> createState() => _GlobalEventsTabState();
}

class _GlobalEventsTabState extends State<_GlobalEventsTab> {
  _EventFilter _filter = _EventFilter.all;
  DateTime? _filterDate;
  final Map<String, String> _communityNames = {};
  final Set<String> _fetchingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EventProvider>().loadPublishedEvents();
        _fetchMissingNames();
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    context.read<EventProvider>().reassemble();
  }

  void _fetchMissingNames() {
    final ep = context.read<EventProvider>();
    final pp = context.read<ProfileProvider>();
    for (final e in ep.publishedEvents) {
      final id = e.communityId;
      if (id.isEmpty || _communityNames.containsKey(id) || _fetchingIds.contains(id)) continue;
      _fetchingIds.add(id);
      pp.fetchCommunityName(id).then((name) {
        if (mounted) {
          setState(() {
            _communityNames[id] = name ?? '';
            _fetchingIds.remove(id);
          });
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.cardWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _filterDate = picked);
  }

  List<EventModel> _applySearch(List<EventModel> events) {
    var result = events;
    final q = widget.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q) ||
        (_communityNames[e.communityId] ?? '').toLowerCase().contains(q),
      ).toList();
    }
    if (_filterDate != null) {
      final d = _filterDate!;
      final dayStart = DateTime(d.year, d.month, d.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      result = result.where((e) {
        final start = e.startDate.toDate();
        final end = e.endDate.toDate();
        return start.isBefore(dayEnd) && end.isAfter(dayStart);
      }).toList();
    }
    return result;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchMissingNames();
    });

    final myIds = context
        .watch<CommunityProvider>()
        .myCommunities
        .map((c) => c.id)
        .toSet();

    final publicEvents = ep.publishedEvents.where((e) => e.isPublished).toList();

    final byFilter = switch (_filter) {
      _EventFilter.all => publicEvents,
      _EventFilter.myClubs =>
        publicEvents.where((e) => myIds.contains(e.communityId)).toList(),
      _EventFilter.otherClubs =>
        publicEvents.where((e) => !myIds.contains(e.communityId)).toList(),
    };

    final filtered = _applySearch(byFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingM,
            AppSizes.paddingS,
            AppSizes.paddingM,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingS,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _filterDate != null
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    border: Border.all(
                      color: _filterDate != null
                          ? AppColors.primary
                          : AppColors.inputBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: _filterDate != null
                              ? AppColors.primary
                              : AppColors.textGray),
                      const SizedBox(width: 4),
                      Text(
                        _filterDate != null
                            ? DateFormat('d MMM').format(_filterDate!)
                            : 'Date',
                        style: AppTextStyles.poppins(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w600,
                          color: _filterDate != null
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),
                      ),
                      if (_filterDate != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _filterDate = null),
                          child: const Icon(Icons.close,
                              size: 14, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),
              _EventFilterDropdown(
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy,
                          size: 64,
                          color: AppColors.textGray.withValues(alpha: 0.35)),
                      const SizedBox(height: AppSizes.paddingM),
                      Text(
                        widget.searchQuery.isNotEmpty
                            ? 'No events match "${widget.searchQuery}"'
                            : 'No published events yet',
                        style: AppTextStyles.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingM),
                  itemBuilder: (_, i) => EventCard(
                    event: filtered[i],
                    communityId: filtered[i].communityId,
                  ),
                ),
        ),
      ],
    );
  }
}

class _EventFilterDropdown extends StatelessWidget {
  final _EventFilter value;
  final ValueChanged<_EventFilter> onChanged;

  const _EventFilterDropdown({required this.value, required this.onChanged});

  String _label(_EventFilter f) => switch (f) {
        _EventFilter.all => 'All Events',
        _EventFilter.myClubs => 'My Clubs',
        _EventFilter.otherClubs => 'Other Clubs',
      };

  @override
  Widget build(BuildContext context) {
    final itemStyle = AppTextStyles.poppins(
      fontSize: AppSizes.fontXS,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.cardWhite,
          textStyle: itemStyle,
        ),
      ),
      child: PopupMenuButton<_EventFilter>(
        offset: const Offset(0, 36),
        onSelected: onChanged,
        itemBuilder: (_) => _EventFilter.values
            .map((f) => PopupMenuItem<_EventFilter>(
                  value: f,
                  child: Text(_label(f)),
                ))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingS,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_label(value), style: itemStyle),
              const SizedBox(width: AppSizes.paddingXS),
              const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverSortDropdown extends StatelessWidget {
  final _DiscoverSort value;
  final ValueChanged<_DiscoverSort> onChanged;

  const _DiscoverSortDropdown({required this.value, required this.onChanged});

  String _label(_DiscoverSort s) => switch (s) {
        _DiscoverSort.newestFirst  => 'Newest first',
        _DiscoverSort.oldestFirst  => 'Oldest first',
        _DiscoverSort.mostMembers  => 'Most members',
        _DiscoverSort.leastMembers => 'Least members',
      };

  @override
  Widget build(BuildContext context) {
    final itemStyle = AppTextStyles.poppins(
      fontSize: AppSizes.fontXS,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.cardWhite,
          textStyle: itemStyle,
        ),
      ),
      child: PopupMenuButton<_DiscoverSort>(
        offset: const Offset(0, 36),
        onSelected: onChanged,
        itemBuilder: (_) => _DiscoverSort.values
            .map((s) => PopupMenuItem<_DiscoverSort>(
                  value: s,
                  child: Text(_label(s)),
                ))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingS,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_label(value), style: itemStyle),
              const SizedBox(width: AppSizes.paddingXS),
              const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyClubList extends StatelessWidget {
  final List<CommunityModel> communities;
  final void Function(CommunityModel) onTap;

  const _MyClubList({required this.communities, required this.onTap});

  List<CommunityModel> get _sorted {
    final list = List<CommunityModel>.from(communities);
    list.sort((a, b) {
      final aTs = a.lastMessageAt ?? a.createdAt;
      final bTs = b.lastMessageAt ?? b.createdAt;
      return bTs.compareTo(aTs);
    });
    return list.take(10).toList();
  }

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
    final sorted = _sorted;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _UnreadAwareClubCard(
              community: sorted[i],
              onTap: () => onTap(sorted[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnreadAwareClubCard extends StatefulWidget {
  final CommunityModel community;
  final VoidCallback onTap;

  const _UnreadAwareClubCard({required this.community, required this.onTap});

  @override
  State<_UnreadAwareClubCard> createState() => _UnreadAwareClubCardState();
}

class _UnreadAwareClubCardState extends State<_UnreadAwareClubCard> {
  late Stream<bool> _unreadStream;

  @override
  void initState() {
    super.initState();
    _unreadStream = context.read<CommunityProvider>().hasUnreadStream(widget.community.id);
  }

  @override
  void didUpdateWidget(_UnreadAwareClubCard old) {
    super.didUpdateWidget(old);
    if (old.community.id != widget.community.id) {
      _unreadStream = context.read<CommunityProvider>().hasUnreadStream(widget.community.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.community;
    return StreamBuilder<bool>(
      stream: _unreadStream,
      builder: (context, snap) => ClubCard(
        name: c.communityName,
        description: c.description.isEmpty
            ? c.tags.map((t) => t.name).join(', ')
            : c.description,
        category: c.tags.isNotEmpty ? c.tags.first.name : '',
        memberCount: '${c.memberCount} member${c.memberCount == 1 ? '' : 's'}',
        coverImageUrl: c.coverImageURL.isEmpty ? null : c.coverImageURL,
        hasUnread: snap.data ?? false,
        onTap: widget.onTap,
      ),
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

class _DiscoverTab extends StatefulWidget {
  /// Pre-filtered community list (search + category) from the parent.
  /// Used when search or category filter is active (non-paginated view).
  final List<CommunityModel> communities;
  final String searchQuery;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final void Function(CommunityModel) onTap;
  final List<String> userInterests;

  const _DiscoverTab({
    required this.communities,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onTap,
    required this.userInterests,
  });

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  _DiscoverSort _sort = _DiscoverSort.newestFirst;

  static (String, bool) _sortParams(_DiscoverSort sort) => switch (sort) {
        _DiscoverSort.newestFirst  => ('createdAt',   true),
        _DiscoverSort.oldestFirst  => ('createdAt',   false),
        _DiscoverSort.mostMembers  => ('memberCount', true),
        _DiscoverSort.leastMembers => ('memberCount', false),
      };

  void _onSortChanged(_DiscoverSort sort) {
    setState(() => _sort = sort);
    final (field, desc) = _sortParams(sort);
    context.read<CommunityProvider>().loadDiscoverFirstPage(
      orderField: field,
      descending: desc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();

    // Use server-side pagination only when no search or category filter is active.
    final isPaginated = widget.searchQuery.isEmpty && widget.selectedCategory == null;
    final displayList = isPaginated ? cp.discoverPage : widget.communities;

    const categoryColors = [
      AppColors.categoryGreen,
      AppColors.categoryBlue,
      AppColors.categoryPurple,
    ];

    final showPagination = isPaginated && cp.discoverTotalPages > 1;

    Widget listContent;
    if (isPaginated && cp.isDiscoverLoading) {
      listContent = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (displayList.isEmpty) {
      listContent = Center(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSizes.paddingXL),
          child: Text(
            'No communities found',
            style: AppTextStyles.body(color: AppColors.textGray),
          ),
        ),
      );
    } else {
      // Pagination bar lives inside the ListView so it scrolls with the cards.
      listContent = ListView(
        key: ValueKey(isPaginated ? cp.discoverCurrentPage : -1),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        children: [
          ..._buildCommunityCards(displayList, widget.onTap),
          if (showPagination)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, AppSizes.paddingM, 0, AppSizes.paddingM),
              child: Center(
                child: _PaginationBar(
                  currentPage: cp.discoverCurrentPage,
                  totalPages: cp.discoverTotalPages,
                  knownPages: cp.discoverKnownPages,
                  onPageChanged: (page) =>
                      context.read<CommunityProvider>().goToDiscoverPage(page),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interests row — full width
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < widget.userInterests.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSizes.paddingS),
                  _SelectableCategory(
                    label: widget.userInterests[i],
                    color: categoryColors[i % categoryColors.length],
                    isSelected: widget.selectedCategory == widget.userInterests[i],
                    onTap: () => widget.onCategoryChanged(widget.userInterests[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Sort dropdown — right-aligned below interests
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingL,
            AppSizes.paddingS,
            AppSizes.paddingL,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _DiscoverSortDropdown(
                value: _sort,
                onChanged: _onSortChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingM),

        // Community list (pagination bar is the last item inside)
        Expanded(child: listContent),
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

Future<void> _confirmDeleteCommunity(BuildContext context, String communityId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Community'),
      content: const Text(
        'Are you sure? This will permanently delete the community and all its messages. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await context.read<CommunityProvider>().deleteCommunity(communityId);
}


List<Widget> _buildCommunityCards(
  List<CommunityModel> communities,
  void Function(CommunityModel) onTap,
) {
  return communities.map((c) => ClubCard(
    name: c.communityName,
    description: c.description.isEmpty ? c.tags.map((t) => t.name).join(', ') : c.description,
    category: c.tags.isNotEmpty ? c.tags.first.name : '',
    memberCount: '${c.memberCount} member${c.memberCount == 1 ? '' : 's'}',
    coverImageUrl: c.coverImageURL.isEmpty ? null : c.coverImageURL,
    onTap: () => onTap(c),
  )).toList();
}

// ── Trending tab ───────────────────────────────────────────────────────────────

class _TrendingTab extends StatelessWidget {
  final List<CommunityModel> communities;
  final bool isLoading;
  final String? error;
  final void Function(CommunityModel) onTap;
  final VoidCallback onRetry;

  const _TrendingTab({
    required this.communities,
    required this.isLoading,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && communities.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null && communities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load trending communities',
              style: AppTextStyles.body(color: AppColors.textGray),
            ),
            const SizedBox(height: AppSizes.paddingM),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (communities.isEmpty) {
      return Center(
        child: Text(
          'No trending communities yet.\nStart chatting to boost activity!',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(color: AppColors.textGray),
        ),
      );
    }

    return ListView.builder(
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final c = communities[index];
        return _RankedCard(
          community: c,
          rank: index + 1,
          onTap: () => onTap(c),
        );
      },
    );
  }
}

class _RankedCard extends StatelessWidget {
  final CommunityModel community;
  final int rank;
  final VoidCallback onTap;

  const _RankedCard({
    required this.community,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = community;
    // Show trending score if non-zero, otherwise fall back to member count.
    final scoreLabel = c.stats.trendingScore > 0
        ? 'Score ${c.stats.trendingScore.toStringAsFixed(0)}'
        : '${c.memberCount} member${c.memberCount == 1 ? '' : 's'}';

    return Stack(
      children: [
        ClubCard(
          name: c.communityName,
          description: c.description.isEmpty
              ? c.tags.map((t) => t.name).join(', ')
              : c.description,
          category: c.tags.isNotEmpty ? c.tags.first.name : '',
          memberCount: scoreLabel,
          coverImageUrl: c.coverImageURL.isEmpty ? null : c.coverImageURL,
          onTap: onTap,
        ),
        Positioned(
          top: AppSizes.paddingS,
          left: AppSizes.paddingS,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: rank <= 3 ? AppColors.primary : AppColors.textGray,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rank <= 3)
                  const Icon(
                    Icons.local_fire_department,
                    size: 10,
                    color: AppColors.cardWhite,
                  ),
                if (rank <= 3) const SizedBox(width: 2),
                Text(
                  '#$rank',
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pagination bar ─────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  /// Pages whose start-cursor is cached — only these are directly navigable.
  final int knownPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.knownPages,
    required this.onPageChanged,
  });

  /// Builds the list of items to render. Returns ints (page indices) and the
  /// string '...' for ellipsis slots.
  List<Object> _items() {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i);
    final items = <Object>[];
    items.add(0);
    final start = (currentPage - 1).clamp(1, totalPages - 2);
    final end = (currentPage + 1).clamp(1, totalPages - 2);
    if (start > 1) items.add('...');
    for (int i = start; i <= end; i++) { items.add(i); }
    if (end < totalPages - 2) items.add('...');
    items.add(totalPages - 1);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final canPrev = currentPage > 0;
    final canNext = currentPage < totalPages - 1 && (currentPage + 1) < knownPages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavChevron(
          label: '‹',
          enabled: canPrev,
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
        ),
        const SizedBox(width: 2),
        for (final item in items)
          if (item is String)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                '…',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: AppSizes.fontXS,
                ),
              ),
            )
          else
            _PageChip(
              page: item as int,
              isActive: item == currentPage,
              isEnabled: item < knownPages,
              onTap: item < knownPages ? () => onPageChanged(item) : null,
            ),
        const SizedBox(width: 2),
        _NavChevron(
          label: '›',
          enabled: canNext,
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    );
  }
}

class _PageChip extends StatelessWidget {
  final int page;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _PageChip({
    required this.page,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: isActive
              ? null
              : Border.all(
                  color: isEnabled
                      ? AppColors.textGray.withValues(alpha: 0.45)
                      : AppColors.textGray.withValues(alpha: 0.2),
                  width: 1.5,
                ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${page + 1}',
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontML,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? AppColors.cardWhite
                : isEnabled
                    ? AppColors.textDark
                    : AppColors.textGray.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavChevron({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? AppColors.textGray
                  : AppColors.textGray.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
