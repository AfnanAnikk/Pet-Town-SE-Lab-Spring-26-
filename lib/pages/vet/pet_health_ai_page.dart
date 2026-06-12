import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pet_health_model.dart';
import '../../services/pet_health_ai_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ══════════════════════════════════════════════════════════════════════════
const _kPrimary   = Color(0xFF3293B3);
const _kPrimaryDk = Color(0xFF1A6B8A);
const _kPrimaryLt = Color(0xFF4DB8D4);
const _kEmergency = Color(0xFFEF4444);
const _kMonitor   = Color(0xFF10B981);
const _kSchedule  = Color(0xFFF59E0B);
const _kBg        = Color(0xFFF0F9FF);

const _kGradientColors = [_kPrimaryDk, _kPrimary, _kPrimaryLt];

// ══════════════════════════════════════════════════════════════════════════════
// DATA
// ══════════════════════════════════════════════════════════════════════════════
const _kSpecies = [
  {'label': 'Dog',    'emoji': '🐕'},
  {'label': 'Cat',    'emoji': '🐈'},
  {'label': 'Rabbit', 'emoji': '🐇'},
  {'label': 'Horse',  'emoji': '🐴'},
  {'label': 'Cow',    'emoji': '🐄'},
  {'label': 'Sheep',  'emoji': '🐑'},
  {'label': 'Goat',   'emoji': '🐐'},
  {'label': 'Pig',    'emoji': '🐖'},
];

const _kSymptomGroups = {
  '🫁 Respiratory': [
    'Coughing', 'Sneezing', 'Labored Breathing', 'Nasal Discharge',
  ],
  '🧬 Digestive': [
    'Vomiting', 'Diarrhea', 'Appetite Loss', 'Increased Appetite', 'Dehydration',
  ],
  '🩺 Systemic': [
    'Fever', 'Lethargy', 'Weight Loss', 'Swelling',
    'Swollen Joints', 'Swollen Legs', 'Skin Lesions',
  ],
  '👁️ Eye / Ear': ['Eye Discharge'],
  '🐾 Behavioral': [
    'Nesting Behavior', 'Restless Behavior', 'Aggressive Behavior', 'Lameness',
  ],
  '🤰 Pregnancy Signs': [
    'Clear Vaginal Discharge', 'Bloody Vaginal Discharge',
    'Fetal Heart Sound Detected',
  ],
  '🐄 Livestock': ['Decreased Milk Yield', 'Reduced Wool Production'],
};

class PetHealthAiPage extends StatefulWidget {
  const PetHealthAiPage({super.key});

  @override
  State<PetHealthAiPage> createState() => _PetHealthAiPageState();
}

class _PetHealthAiPageState extends State<PetHealthAiPage>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  final PageController _pc      = PageController();
  final _tempCtrl               = TextEditingController();
  final _hrCtrl                 = TextEditingController();

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  // ── State ────────────────────────────────────────────────────────────────
  int               _step            = 0;
  String            _selectedSpecies = 'Dog';
  final Set<String> _selectedSymptoms = {};

  List<ClassifierResult> _results   = [];
  bool                   _isOffline = false;
  bool                   _isLoading = false;
  String?                _error;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _tempCtrl.dispose();
    _hrCtrl.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    _fadeCtrl.reset();
    setState(() => _step = step);
    _pc.animateToPage(
      step,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInOutCubic,
    );
    _fadeCtrl.forward();
  }

  Future<void> _runAnalysis() async {
    _goTo(2);
    setState(() {
      _isLoading = true;
      _error     = null;
      _results   = [];
    });

    final profile = PetProfile(
      animalType:  _selectedSpecies,
      symptoms:    _selectedSymptoms.toList(),
      temperature: double.tryParse(_tempCtrl.text),
      heartRate:   double.tryParse(_hrCtrl.text),
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final r = await PetHealthAIService.predict(profile);
      if (mounted) {
        setState(() {
          _results   = r.results;
          _isOffline = r.isOffline;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } final {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pc,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const steps = ['Species & Vitals', 'Select Symptoms', 'AI Analysis'];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _kGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_step > 0) {
                    _goTo(_step - 1);
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🐾', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Health Checker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Text(
                    steps[_step],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _kGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: List.generate(3, (i) {
          final done   = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: active ? 34 : 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: (done || active) ? Colors.white : Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 14, color: _kPrimary)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: active ? _kPrimary : Colors.white.withOpacity(0.55),
                            ),
                          ),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i < _step ? Colors.white : Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('🐾 Select Your Pet Species'),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: _kSpecies
                  .map((s) => _speciesCard(s['label']!, s['emoji']!))
                  .toList(),
            ),
            const SizedBox(height: 28),
            _sectionLabel('🌡️ Vitals (Optional)'),
            const SizedBox(height: 4),
            Text(
              'Leave blank if unknown — server AI models will apply baseline averages.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _vitalField(_tempCtrl, 'Temperature', '38.5', '°C', Icons.thermostat),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _vitalField(_hrCtrl, 'Heart Rate', '90', 'bpm', Icons.favorite_border),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _primaryButton('Next: Select Symptoms →', () => _goTo(1)),
          ],
        ),
      ),
    );
  }

  Widget _speciesCard(String label, String emoji) {
    final selected = _selectedSpecies == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSpecies = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(selected ? 1.06 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kPrimary.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kPrimary : Colors.grey.shade200,
            width: selected ? 2.2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _kPrimary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
                color: selected ? _kPrimary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalField(TextEditingController ctrl, String label, String hint, String unit, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Strict floating points parsing block
      ],
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
        hintText: hint,
        suffixText: unit,
        prefixIcon: Icon(icon, color: _kPrimary, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _buildStep2() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              children: [
                _sectionLabel('Check all symptoms present'),
                const Spacer(),
                if (_selectedSymptoms.isNotEmpty)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${_selectedSymptoms.length} selected',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _kSymptomGroups.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimaryDk, fontSize: 13, fontFamily: 'Outfit'),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((sym) {
                        final on = _selectedSymptoms.contains(sym);
                        return GestureDetector(
                          onTap: () => setState(() {
                            on ? _selectedSymptoms.remove(sym) : _selectedSymptoms.add(sym);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: on ? _kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: on ? _kPrimary : Colors.grey.shade300, width: on ? 0 : 1),
                              boxShadow: on ? [BoxShadow(color: _kPrimary.withOpacity(0.28), blurRadius: 6, offset: const Offset(0, 2))] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (on) const Padding(padding: EdgeInsets.only(right: 5), child: Icon(Icons.check, size: 13, color: Colors.white)),
                                Text(
                                  sym,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Outfit',
                                    fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                                    color: on ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Row(
              children: [
                Expanded(child: _outlineButton('← Back', () => _goTo(0))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _primaryButton('🔍 Analyze Now', _runAnalysis)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    if (_isLoading) return _buildScanAnimation();
    if (_error != null) return _buildErrorState();
    if (_results.isEmpty) return _buildEmptyState();
    return _buildResultsList();
  }

  Widget _buildScanAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final size = 110.0 + 22.0 * _pulseCtrl.value;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary.withOpacity(0.07 + 0.06 * _pulseCtrl.value),
                  border: Border.all(color: _kPrimary.withOpacity(0.35 + 0.3 * _pulseCtrl.value), width: 2.5),
                ),
                child: const Center(child: Text('🐾', style: TextStyle(fontSize: 50))),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Analyzing symptoms…',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _kPrimaryDk, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          Text(
            'Checking ${_selectedSymptoms.length} symptom${_selectedSymptoms.length == 1 ? '' : 's'} for $_selectedSpecies',
            style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Outfit', fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(_kPrimary),
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
              child: Row(
                children: [
                  const Text('📴', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode Active',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontFamily: 'Outfit'),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: _results.length,
              itemBuilder: (_, i) => _resultCard(_results[i], i),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Column(
              children: [
                _primaryButton('🏥 Find a Vet Near You', () => Navigator.pop(context)),
                const SizedBox(height: 10),
                _outlineButton('← Check Again', () {
                  setState(() {
                    _selectedSymptoms.clear();
                    _tempCtrl.clear(); // Pristine environment purge execution
                    _hrCtrl.clear();
                    _results   = [];
                    _isOffline = false;
                  });
                  _goTo(0);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(ClassifierResult r, int index) {
    final urgencyColor = r.urgency == 'Emergency' ? _kEmergency : r.urgency == 'Monitor' ? _kMonitor : _kSchedule;
    final urgencyEmoji = r.urgency == 'Emergency' ? '🔴' : r.urgency == 'Monitor' ? '🟢' : '🟡';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 420 + index * 140),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 28 * (1 - v)),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
          border: index == 0 ? Border.all(color: _kPrimary.withOpacity(0.35), width: 1.5) : null,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Row(
              children: [
                if (index == 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Top Match', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                  ),
                ],
                Expanded(
                  child: Text(r.disease, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kPrimaryDk, fontFamily: 'Outfit')),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: urgencyColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: urgencyColor.withOpacity(0.45)),
                        ),
                        child: Text('$urgencyEmoji ${r.urgency}', style: TextStyle(color: urgencyColor, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                      ),
                      const Spacer(),
                      Text('${r.confidence.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary, fontSize: 14, fontFamily: 'Outfit')),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: r.confidence / 100),
                      duration: Duration(milliseconds: 900 + index * 200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(urgencyColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              _infoRow(Icons.info_outline, 'Description', r.description, _kPrimaryDk),
              const Divider(height: 20, thickness: 0.7),
              _infoRow(Icons.healing_outlined, 'Treatment', r.treatment, _kMonitor),
              const Divider(height: 20, thickness: 0.7),
              _infoRow(Icons.shield_outlined, 'Prevention', r.prevention, _kPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color, fontFamily: 'Outfit')),
              const SizedBox(height: 2),
              Text(text.isEmpty ? '—' : text, style: const TextStyle(fontSize: 13, height: 1.45, fontFamily: 'Outfit')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('No Conditions Detected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kPrimaryDk, fontFamily: 'Outfit')),
            const SizedBox(height: 10),
            Text(
              'The AI found no symptom patterns that match known conditions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Outfit', height: 1.5),
            ),
            const SizedBox(height: 28),
            _primaryButton('← Try Again', () => _goTo(0)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Analysis Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.red, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 28),
            _primaryButton('🔄 Retry Analysis', _runAnalysis),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kPrimaryDk, fontFamily: 'Outfit'));
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: _kPrimary.withOpacity(0.38),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kPrimary, width: 1.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: const TextStyle(color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
      ),
    );
  }
}