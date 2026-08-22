import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/localization/app_language.dart';
import 'package:mobile_app/core/localization/app_translations.dart';
import 'package:mobile_app/features/events/domain/event_model.dart';
import 'package:mobile_app/features/events/presentation/event_detail_screen.dart';
import 'package:mobile_app/features/events/presentation/events_provider.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isSearching = false;

  final List<String> _categories = [
    'all',
    'sammelan',
    'cultural',
    'religious',
    'general',
  ];

  // Hardcoded fallback featured events demonstrating UPCOMING, LIVE NOW, and COMPLETED states
  late final List<EventModel> _fallbackEvents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    final now = DateTime.now();

    _fallbackEvents = [
      EventModel(
        id: 101,
        title: '6th Sammelan, 2026 at Ayodhya',
        description:
            'Grand ABRP Community Sammelan at Ayodhya. Join us with family for devotional & cultural programs, family tree registrations, and youth networking.',
        imageUrl:
            'https://images.unsplash.com/photo-1541872703-74c5e44368f9?q=80&w=1200&auto=format&fit=crop',
        externalAlbumUrl: 'https://photos.google.com',
        eventDate: DateTime(2026, 11, 19, 9, 0),
        endDate: DateTime(2026, 11, 21, 18, 0),
        venue:
            'Asharfi Bhawan Chauraha Rd, Tulsi Nagar, Ayodhya, Uttar Pradesh 224123',
        category: 'sammelan',
        isActive: true,
      ),
      EventModel(
        id: 102,
        title: 'Annual Youth & Talent Excellence Awards 2026',
        description:
            'Felicitation of meritorious students, young entrepreneurs, and sports achievers across all zones of Rander Parivar Samaj.',
        imageUrl:
            'https://images.unsplash.com/photo-1511578314322-379afb476865?q=80&w=1200&auto=format&fit=crop',
        eventDate: now.subtract(const Duration(hours: 2)),
        endDate: now.add(const Duration(hours: 10)),
        venue: 'Surat Community Center, Majura Gate, Surat',
        category: 'cultural',
        isActive: true,
      ),
      EventModel(
        id: 103,
        title: 'Shree Krishna Bhajan Sandhya & Mahaprasad',
        description:
            'Evening of devotional bhajans, spiritual discourse, and mahaprasad gathering for all parivar members.',
        imageUrl: null,
        eventDate: DateTime(2025, 8, 28, 17, 30),
        venue: 'Rander Bhavan, Pal Gam, Surat',
        category: 'religious',
        isActive: true,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isEventUpcomingOrLive(EventModel event) {
    final now = DateTime.now();
    final start = event.eventDate;
    final end = event.endDate ?? event.eventDate.add(const Duration(hours: 12));
    return end.isAfter(now) || start.isAfter(now);
  }

  bool _isEventLiveNow(EventModel event) {
    final now = DateTime.now();
    final start = event.eventDate;
    final end = event.endDate ?? event.eventDate.add(const Duration(hours: 12));
    return now.isAfter(start) && now.isBefore(end);
  }

  List<EventModel> _filterEvents(List<EventModel> allEvents) {
    final listToFilter = allEvents.isEmpty ? _fallbackEvents : allEvents;

    return listToFilter.where((event) {
      // 1. Tab Filter (0: All, 1: Upcoming/Live, 2: Past)
      if (_tabController.index == 1 && !_isEventUpcomingOrLive(event)) {
        return false;
      }
      if (_tabController.index == 2 && _isEventUpcomingOrLive(event)) {
        return false;
      }

      // 2. Category Filter
      if (_selectedCategory != 'all' &&
          event.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // 3. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatches = event.title.toLowerCase().contains(query);
        final venueMatches = (event.venue ?? '').toLowerCase().contains(query);
        final descMatches = (event.description ?? '').toLowerCase().contains(query);
        final catMatches = event.category.toLowerCase().contains(query);

        if (!titleMatches && !venueMatches && !descMatches && !catMatches) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _getCategoryLabel(String cat, AppLanguage lang) {
    final isHindi = lang == AppLanguage.hi;
    switch (cat.toLowerCase()) {
      case 'all':
        return isHindi ? 'सभी' : 'All';
      case 'sammelan':
        return isHindi ? 'सम्मेलन' : 'Sammelan';
      case 'cultural':
        return isHindi ? 'सांस्कृतिक' : 'Cultural';
      case 'religious':
        return isHindi ? 'धार्मिक' : 'Religious';
      case 'general':
        return isHindi ? 'सामान्य' : 'General';
      default:
        return cat.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageStateProvider);
    final isHindi = lang == AppLanguage.hi;
    final primaryColor = theme.colorScheme.primary;
    final activeEventsAsync = ref.watch(activeEventsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: isHindi ? 'कार्यक्रम खोजें...' : 'Search events...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text(
                isHindi ? 'समाज के कार्यक्रम' : 'Community Events',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: primaryColor),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: () {
              ref.invalidate(activeEventsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              text: isHindi
                  ? 'सभी (${activeEventsAsync.value?.length ?? _fallbackEvents.length})'
                  : 'All Events (${activeEventsAsync.value?.length ?? _fallbackEvents.length})',
            ),
            Tab(text: isHindi ? 'आगामी / लाइव' : 'Upcoming & Live'),
            Tab(text: isHindi ? 'संपन्न' : 'Past Events'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── CATEGORY FILTER CHIPS ───────────────────────────────────────────
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(_getCategoryLabel(cat, lang)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  },
                  selectedColor: primaryColor,
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : theme.colorScheme.secondary.withValues(alpha: 0.15),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // ── EVENTS LIST FEED ───────────────────────────────────────────────
          Expanded(
            child: activeEventsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => _buildEventsList(
                events: _filterEvents(_fallbackEvents),
                theme: theme,
                lang: lang,
                isFallback: true,
              ),
              data: (serverEvents) {
                final filtered = _filterEvents(serverEvents);
                final isUsingFallback = serverEvents.isEmpty;
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(activeEventsProvider);
                  },
                  child: _buildEventsList(
                    events: filtered,
                    theme: theme,
                    lang: lang,
                    isFallback: isUsingFallback,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList({
    required List<EventModel> events,
    required ThemeData theme,
    required AppLanguage lang,
    bool isFallback = false,
  }) {
    if (events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  lang == AppLanguage.hi
                      ? 'कोई कार्यक्रम नहीं मिला'
                      : 'No events found',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang == AppLanguage.hi
                      ? 'कृपया खोज या फ़िल्टर बदलें'
                      : 'Try adjusting your search or category filter',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: events.length + (isFallback ? 1 : 0),
      itemBuilder: (context, index) {
        if (isFallback && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == AppLanguage.hi
                        ? 'विशेष रुप से प्रदर्शित समाज कार्यक्रम:'
                        : 'Featured Community Events:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final event = events[isFallback ? index - 1 : index];
        return _buildEventCard(event: event, theme: theme, lang: lang);
      },
    );
  }

  Widget _buildEventCard({
    required EventModel event,
    required ThemeData theme,
    required AppLanguage lang,
  }) {
    final primaryColor = theme.colorScheme.primary;
    final isLive = _isEventLiveNow(event);
    final isUpcoming = _isEventUpcomingOrLive(event);

    final String dateDisplay;
    if (event.endDate != null &&
        !(event.endDate!.year == event.eventDate.year &&
            event.endDate!.month == event.eventDate.month &&
            event.endDate!.day == event.eventDate.day)) {
      final startFmt = DateFormat('dd MMM').format(event.eventDate);
      final endFmt = DateFormat('dd MMM yyyy').format(event.endDate!);
      dateDisplay = '$startFmt - $endFmt';
    } else {
      dateDisplay = DateFormat('EEE, dd MMM yyyy • hh:mm a').format(event.eventDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── CARD HEADER IMAGE / GRADIENT FALLBACK ─────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                            event.imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildHeaderGradientFallback(primaryColor, event.category),
                          )
                        : _buildHeaderGradientFallback(primaryColor, event.category),
                  ),

                  // TOP-LEFT: Category Pill
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // TOP-RIGHT: Live / Upcoming / Muted Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (event.externalAlbumUrl != null &&
                            event.externalAlbumUrl!.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.photo_library, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'ALBUM',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLive
                                ? Colors.green.shade700
                                : (isUpcoming ? theme.colorScheme.secondary : Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLive
                                ? '● LIVE NOW'
                                : (isUpcoming ? 'UPCOMING' : 'COMPLETED'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── CARD CONTENT DETAILS ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Date Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Venue Row (if exists)
                    if (event.venue != null && event.venue!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              event.venue!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Footer Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang == AppLanguage.hi ? 'विवरण देखें' : 'View Full Details',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderGradientFallback(Color primaryColor, String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'sammelan':
        icon = Icons.temple_hindu_rounded;
        break;
      case 'cultural':
        icon = Icons.stars_rounded;
        break;
      case 'religious':
        icon = Icons.campaign_rounded;
        break;
      default:
        icon = Icons.event_rounded;
    }

    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB22B1D), Color(0xFFDAA520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 56),
      ),
    );
  }
}
