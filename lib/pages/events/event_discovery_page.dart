import 'package:flutter/material.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_category_chip.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import 'event_detail_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

const List<String> _categories = [
  'All','Adoption','Vaccination','Meetup','Training',
  'Competition','Outdoor','Awareness','Seminar','Fundraising','Other',
];
const List<String> _petTypes = ['All','Dog','Cat','Bird','Fish','Rabbit','Other'];

class EventDiscoveryPage extends StatefulWidget {
  const EventDiscoveryPage({super.key});

  @override
  State<EventDiscoveryPage> createState() => _EventDiscoveryPageState();
}

class _EventDiscoveryPageState extends State<EventDiscoveryPage> {
  List<EventModel> _events = [];
  bool _isLoading = false;
  bool _isGridView = false;

  String? _selCategory;
  String? _selPetType;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _locationFilter;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await ApiService.getEvents(
      category: _selCategory == 'All' ? null : _selCategory,
      petType: _selPetType == 'All' ? null : _selPetType,
      location: _locationFilter,
      dateFrom: _dateFrom?.toIso8601String(),
      dateTo: _dateTo?.toIso8601String(),
      limit: 40,
    );
    if (!mounted) return;
    List<EventModel> list = [];
    if (res['success'] == true && res['data'] is List) {
      list = (res['data'] as List).map((e) => EventModel.fromJson(e)).toList();
      if (_sortBy == 'popular') {
        list.sort((a, b) =>
            (b.goingCount + b.interestedCount).compareTo(a.goingCount + a.interestedCount));
      }
    }
    setState(() { _events = list; _isLoading = false; });
  }

  void _showFilterSheet() {
    String? tempCat = _selCategory;
    String? tempPet = _selPetType;
    DateTime? tempFrom = _dateFrom;
    DateTime? tempTo = _dateTo;
    final locCtrl = TextEditingController(text: _locationFilter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setModal) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              const Text('Filter Events', style: TextStyle(fontFamily: 'Outfit',
                  fontSize: 18, fontWeight: FontWeight.bold, color: _secondary)),
              const SizedBox(height: 20),
              const Text('Category', style: TextStyle(fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) =>
                EventCategoryChip(label: c, isSelected: tempCat == c,
                  onTap: () => setModal(() => tempCat = c))).toList()),
              const SizedBox(height: 20),
              const Text('Pet Type', style: TextStyle(fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _petTypes.map((p) =>
                EventCategoryChip(label: p, isSelected: tempPet == p,
                  onTap: () => setModal(() => tempPet = p))).toList()),
              const SizedBox(height: 20),
              const Text('Location', style: TextStyle(fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 8),
              TextField(controller: locCtrl,
                  decoration: InputDecoration(
                    hintText: 'City or area…',
                    hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: _brandColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _brandColor)),
                  )),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('From', style: TextStyle(fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600, color: _secondary)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(ctx: ctx,
                          initialDate: tempFrom ?? DateTime.now(),
                          firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                      if (d != null) setModal(() => tempFrom = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(tempFrom == null ? 'Any date' :
                          '${tempFrom!.day}/${tempFrom!.month}/${tempFrom!.year}',
                          style: TextStyle(fontFamily: 'Outfit',
                              color: tempFrom == null ? Colors.grey : _secondary)),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('To', style: TextStyle(fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600, color: _secondary)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(ctx: ctx,
                          initialDate: tempTo ?? DateTime.now(),
                          firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                      if (d != null) setModal(() => tempTo = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(tempTo == null ? 'Any date' :
                          '${tempTo!.day}/${tempTo!.month}/${tempTo!.year}',
                          style: TextStyle(fontFamily: 'Outfit',
                              color: tempTo == null ? Colors.grey : _secondary)),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    setModal(() { tempCat = null; tempPet = null; tempFrom = null; tempTo = null; locCtrl.clear(); });
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Clear All', style: TextStyle(fontFamily: 'Outfit',
                      color: _brandColor, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selCategory = tempCat; _selPetType = tempPet;
                      _dateFrom = tempFrom; _dateTo = tempTo;
                      _locationFilter = locCtrl.text.isEmpty ? null : locCtrl.text;
                    });
                    Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _brandColor, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Apply Filters', style: TextStyle(fontFamily: 'Outfit',
                      color: Colors.white, fontWeight: FontWeight.w600)),
                )),
              ]),
              const SizedBox(height: 8),
            ]),
          ),
        );
      }),
    );
  }

  bool get _hasActiveFilters =>
      _selCategory != null || _selPetType != null || _dateFrom != null ||
      _dateTo != null || (_locationFilter?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Discover Events', style: TextStyle(fontFamily: 'Outfit',
            fontSize: 20, fontWeight: FontWeight.bold, color: _brandColor)),
        actions: [
          IconButton(icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: _secondary),
              onPressed: () => setState(() => _isGridView = !_isGridView)),
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.tune, color: _secondary),
              if (_hasActiveFilters) Positioned(right: 0, top: 0,
                  child: Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: _brandColor, shape: BoxShape.circle))),
            ]),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(children: [
        // Active filter pills
        if (_hasActiveFilters)
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (_selCategory != null) _filterPill(_selCategory!, () => setState(() { _selCategory = null; _load(); })),
              if (_selPetType != null) _filterPill(_selPetType!, () => setState(() { _selPetType = null; _load(); })),
              if (_locationFilter != null) _filterPill('📍 $_locationFilter', () => setState(() { _locationFilter = null; _load(); })),
              if (_dateFrom != null) _filterPill('From ${_dateFrom!.day}/${_dateFrom!.month}', () => setState(() { _dateFrom = null; _load(); })),
            ],
          )),
        // Sort row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text('Sort by:', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _sortBy, underline: const SizedBox(),
              style: const TextStyle(fontFamily: 'Outfit', color: _secondary, fontSize: 13, fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'date', child: Text('Date (Soonest)')),
                DropdownMenuItem(value: 'popular', child: Text('Popularity')),
              ],
              onChanged: (v) { if (v != null) setState(() { _sortBy = v; _load(); }); },
            ),
            const Spacer(),
            Text('${_events.length} events', style: TextStyle(fontFamily: 'Outfit',
                color: Colors.grey.shade500, fontSize: 12)),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _brandColor))
              : _events.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: _brandColor, onRefresh: _load,
                      child: _isGridView ? _buildGrid() : _buildList(),
                    ),
        ),
      ]),
    );
  }

  Widget _filterPill(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: _brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _brandColor.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontFamily: 'Outfit', color: _brandColor,
            fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: _brandColor)),
      ]),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _events.length,
      itemBuilder: (ctx, i) => EventCard(event: _events[i], isSaved: false,
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: _events[i].id)))),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 0.75),
      itemCount: _events.length,
      itemBuilder: (ctx, i) => EventCard(event: _events[i], isSaved: false,
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: _events[i].id)))),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('No events found', style: TextStyle(fontFamily: 'Outfit',
          fontSize: 17, color: Colors.grey.shade500)),
      const SizedBox(height: 8),
      TextButton(onPressed: () { setState(() { _selCategory = null; _selPetType = null;
          _dateFrom = null; _dateTo = null; _locationFilter = null; }); _load(); },
        child: const Text('Clear filters', style: TextStyle(fontFamily: 'Outfit', color: _brandColor)),
      ),
    ]));
  }
}
