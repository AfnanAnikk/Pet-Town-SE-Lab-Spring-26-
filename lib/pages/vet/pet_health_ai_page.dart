import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pet_health_model.dart';
import '../../services/pet_health_ai_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ══════════════════════════════════════════════════════════════════════════════
const _kPrimary = Color(0xFF3293B3);
const _kPrimaryDk = Color(0xFF1A6B8A);
const _kPrimaryLt = Color(0xFF4DB8D4);
const _kEmergency = Color(0xFFEF4444);
const _kMonitor = Color(0xFF10B981);
const _kSchedule = Color(0xFFF59E0B);
const _kBg = Color(0xFFF0F9FF);

const _kGradientColors = [_kPrimaryDk, _kPrimary, _kPrimaryLt];

// ══════════════════════════════════════════════════════════════════════════════
// DATA
// ══════════════════════════════════════════════════════════════════════════════
const _kSpecies = [
  {'label': 'Dog', 'emoji': '🐕'},
  {'label': 'Cat', 'emoji': '🐈'},
  {'label': 'Rabbit', 'emoji': '🐇'},
  {'label': 'Horse', 'emoji': '🐴'},
  {'label': 'Cow', 'emoji': '🐄'},
  {'label': 'Sheep', 'emoji': '🐑'},
  {'label': 'Goat', 'emoji': '🐐'},
  {'label': 'Pig', 'emoji': '🐖'},
  {'label': 'Ferret', 'emoji': '🦡'},
];

const _kSymptomGroups = {
  '🫁 Respiratory': [
    'Coughing',
    'Sneezing',
    'Labored Breathing',
    'Nasal Discharge',
    'Eye Discharge',
  ],
  '🧬 Digestive': [
    'Vomiting',
    'Diarrhea',
    'Appetite Loss',
    'Increased Appetite',
    'Dehydration',
    'Digestive Issues',
    'Excessive Drooling',
  ],
  '🩺 Systemic': [
    'Fever',
    'Lethargy',
    'Weight Loss',
    'Swelling',
    'Swollen Joints',
    'Swollen Legs',
    'Skin Lesions',
    'Itching / Scratching',
    'Hair Loss',
    'Parasites',
    'Weakness / Stiffness',
  ],
  '👁️ Eye / Ear': [
    'Ear Infections',
  ],
  '🐾 Behavioral': [
    'Nesting Behavior',
    'Restless Behavior',
    'Aggressive Behavior',
    'Lameness',
  ],
  '🤰 Pregnancy & Urgent Signs': [
    'Clear Vaginal Discharge',
    'Bloody Vaginal Discharge',
    'Purulent Vaginal Discharge',
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
  final PageController _pc = PageController();
  final _tempCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _nlpCtrl = TextEditingController(); // Freestyle NLP input controller

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _step = 0;
  String _selectedSpecies = 'Dog';
  final Set<String> _selectedSymptoms = {};

  List<ClassifierResult> _results = [];
  bool _isLoading = false;
  bool _isParsingNlp = false; // NLP Loader state indicator
  String? _error;

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
    _nlpCtrl.dispose();
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

  // Parses freestyle strings using your Python server's vectorization pipeline
  Future<void> _processFreestyleNLP() async {
    if (_nlpCtrl.text.trim().isEmpty) return;

    setState(() => _isParsingNlp = true);

    try {
      final matched = await PetHealthAIService.extractSymptoms(_nlpCtrl.text);
      if (mounted && matched.isNotEmpty) {
        setState(() {
          _selectedSymptoms.addAll(matched);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ AI extracted and added ${matched.length} symptoms!',
            ),
            backgroundColor: _kMonitor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not match clear symptoms. Please select manually below.',
            ),
            backgroundColor: _kSchedule,
          ),
        );
      }
    } catch (_) {
      // Graceful fallback handled inside service block
    } finally {
      if (mounted) setState(() => _isParsingNlp = false);
    }
  }

  Future<void> _runAnalysis() async {
    _goTo(2);
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    final profile = PetProfile(
      animalType: _selectedSpecies,
      symptoms: _selectedSymptoms.toList(),
      temperature: double.tryParse(_tempCtrl.text),
      heartRate: double.tryParse(_hrCtrl.text),
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final r = await PetHealthAIService.predict(profile);
      if (mounted) {
        setState(() {
          _results = r;
        });
      }
    } on VitalsValidationException catch (e) {
      // Navigate back to step 1 and show a premium vitals error dialog.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = [];
          _error = null;
        });
        _goTo(0);
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) _showVitalsErrorDialog(e.toString());
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Premium bottom-sheet error dialog for unrealistic vitals.
  void _showVitalsErrorDialog(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 2),
              ),
              child: const Center(
                child: Text('⚠️', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unrealistic Vitals Detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A6B8A),
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: Colors.grey.shade700,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please re-check your measurement device and enter a valid reading, or leave the field blank to use the species baseline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.grey.shade500,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3293B3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Fix My Vitals',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
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
                onPressed: () =>
                    _step > 0 ? _goTo(_step - 1) : Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
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
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: active ? 34 : 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: (done || active)
                        ? Colors.white
                        : Colors.white.withOpacity(0.28),
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
                              color: active
                                  ? _kPrimary
                                  : Colors.white.withOpacity(0.55),
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
                        color: i < _step
                            ? Colors.white
                            : Colors.white.withOpacity(0.28),
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
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: _kSpecies
                  .map((s) => _speciesCard(s['label']!, s['emoji']!))
                  .toList(),
            ),
            const SizedBox(height: 28),
            _sectionLabel('🌡️ Vitals (Optional)'),
            const SizedBox(height: 4),
            Text(
              'Leave blank if unknown — AI will apply species baseline averages.',
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
                  child: _vitalField(
                    _tempCtrl,
                    'Temperature',
                    _tempHint(),
                    '°C',
                    Icons.thermostat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _vitalField(
                    _hrCtrl,
                    'Heart Rate',
                    _hrHint(),
                    'bpm',
                    Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Normal range reminder chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withOpacity(0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: _kPrimaryDk),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Normal for $_selectedSpecies — Temp: ${_tempRange()}, HR: ${_hrRange()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _kPrimaryDk,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
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

  Widget _vitalField(
    TextEditingController ctrl,
    String label,
    String hint,
    String unit,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── NEW: FREESTYLE NLP TEXT FIELD WORKSPACE CARD ─────────────────────
                // ── PREMIUM AI SYMPTOM PARSER CARD ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        _kBg.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _kPrimary.withOpacity(0.18), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimaryDk.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: _kPrimary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AI Smart Assistant',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _kPrimaryDk,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Type your pet\'s symptoms in plain English, and our AI will extract them automatically.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.4,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nlpCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Outfit',
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g., My dog is coughing a lot, throwing up his food, and seems very warm and tired...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: _kPrimary, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Quick Examples:',
                        style: TextStyle(
                          color: _kPrimaryDk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _suggestionChip('🐕 Coughing & runny nose'),
                          _suggestionChip('🐈 Vomiting & off food'),
                          _suggestionChip('🐴 Limping and fever'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: _kGradientColors,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.24),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isParsingNlp ? null : _processFreestyleNLP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isParsingNlp
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'Extract Symptoms with AI',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Outfit',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── MANUAL OVERRIDE SELECTION BLOCK ──────────────────────────────────
                Row(
                  children: [
                    _sectionLabel('Or refine selection manually'),
                    const Spacer(),
                    if (_selectedSymptoms.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedSymptoms.length} selected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                ..._kSymptomGroups.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 8),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kPrimaryDk,
                            fontSize: 13,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map((sym) {
                          final on = _selectedSymptoms.contains(sym);
                          return GestureDetector(
                            onTap: () => setState(() {
                              on
                                  ? _selectedSymptoms.remove(sym)
                                  : _selectedSymptoms.add(sym);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: on ? _kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: on ? _kPrimary : Colors.grey.shade300,
                                  width: on ? 0 : 1,
                                ),
                                boxShadow: on
                                    ? [
                                        BoxShadow(
                                          color: _kPrimary.withOpacity(0.28),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (on)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 5),
                                      child: Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  Text(
                                    sym,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Outfit',
                                      fontWeight: on
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: on
                                          ? Colors.white
                                          : Colors.grey.shade700,
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
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _outlineButton('← Back', () => _goTo(0))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _primaryButton('🔍 Analyze Now', _runAnalysis),
                ),
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
                  border: Border.all(
                    color: _kPrimary.withOpacity(0.35 + 0.3 * _pulseCtrl.value),
                    width: 2.5,
                  ),
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 50)),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Analyzing symptoms…',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _kPrimaryDk,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Checking ${_selectedSymptoms.length} symptom${_selectedSymptoms.length == 1 ? '' : 's'} for $_selectedSpecies',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontFamily: 'Outfit',
              fontSize: 13,
            ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                _primaryButton(
                  '🏥 Find a Vet Near You',
                  () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                _outlineButton('← Check Again', () {
                  setState(() {
                    _selectedSymptoms.clear();
                    _tempCtrl.clear();
                    _hrCtrl.clear();
                    _nlpCtrl
                        .clear(); // Clear workspace clean parameters execution
                    _results = [];
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
    final urgencyColor = r.urgency == 'Emergency'
        ? _kEmergency
        : r.urgency == 'Monitor'
        ? _kMonitor
        : _kSchedule;
    final urgencyEmoji = r.urgency == 'Emergency'
        ? '🔴'
        : r.urgency == 'Monitor'
        ? '🟢'
        : '🟡';

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: index == 0
              ? Border.all(color: _kPrimary.withOpacity(0.35), width: 1.5)
              : null,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Top Match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    r.disease,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _kPrimaryDk,
                      fontFamily: 'Outfit',
                    ),
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: urgencyColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: urgencyColor.withOpacity(0.45),
                          ),
                        ),
                        child: Text(
                          '$urgencyEmoji ${r.urgency}',
                          style: TextStyle(
                            color: urgencyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${r.confidence.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                          fontSize: 14,
                          fontFamily: 'Outfit',
                        ),
                      ),
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
              _infoRow(
                Icons.info_outline,
                'Description',
                r.description,
                _kPrimaryDk,
              ),
              const Divider(height: 20, thickness: 0.7),
              _infoRow(
                Icons.healing_outlined,
                'Treatment',
                r.treatment,
                _kMonitor,
              ),
              const Divider(height: 20, thickness: 0.7),
              _infoRow(
                Icons.shield_outlined,
                'Prevention',
                r.prevention,
                _kPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String text, Color color) {
    final cleanText = text.trim();
    final isNan = cleanText.toLowerCase() == 'nan' || cleanText.toLowerCase() == 'null' || cleanText.isEmpty;

    Widget contentWidget;
    if (isNan) {
      String fallback = '—';
      if (label == 'Description') {
        fallback = 'Clinical medical condition.';
      } else if (label == 'Treatment') {
        fallback = 'Consult a veterinarian for detailed treatment and diagnosis.';
      } else if (label == 'Prevention') {
        fallback = 'Maintain general hygiene and follow regular veterinary guidelines.';
      }
      contentWidget = Text(
        fallback,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          fontFamily: 'Outfit',
        ),
      );
    } else {
      final points = cleanText
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (points.length <= 1) {
        contentWidget = Text(
          points.isEmpty ? '—' : points.first,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            fontFamily: 'Outfit',
          ),
        );
      } else {
        contentWidget = Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((pt) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pt,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 2),
              contentWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool hadSymptoms = _selectedSymptoms.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hadSymptoms ? '⚠️' : '✅',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              hadSymptoms
                  ? 'No Pattern Match Found'
                  : 'No Conditions Detected',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPrimaryDk,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hadSymptoms
                  ? 'The AI could not confidently match your pet\'s symptoms to a known condition. This does NOT mean your pet is well — please consult a veterinarian for a proper examination.'
                  : 'The AI server found no anomalies matching known condition patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hadSymptoms ? _kEmergency : Colors.grey.shade600,
                fontFamily: 'Outfit',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _primaryButton(
              hadSymptoms ? '🏥 Find a Vet' : '← Try Again',
              () => hadSymptoms ? Navigator.pop(context) : _goTo(0),
            ),
            if (hadSymptoms) ...[
              const SizedBox(height: 10),
              _outlineButton('← Try Different Symptoms', () => _goTo(1)),
            ],
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
            const Text(
              'Analysis Unsuccessful',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected network error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 28),
            _primaryButton('🔄 Retry Connection', _runAnalysis),
          ],
        ),
      ),
    );
  }

  /// Tappable suggestion chip — autofills the NLP text box and fires
  /// the AI extraction immediately so the user gets one-tap symptom detection.
  Widget _suggestionChip(String text) {
    // Strip any leading emoji + space (e.g. '🐕 Coughing & runny nose' → 'Coughing & runny nose')
    final rawText = text.replaceFirst(RegExp(r'^\S+\s+'), '');
    return GestureDetector(
      onTap: () {
        _nlpCtrl.text = rawText;
        _processFreestyleNLP();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _kPrimary.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text.split(' ').first, // Emoji
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 5),
            Text(
              rawText,
              style: const TextStyle(
                fontSize: 11,
                color: _kPrimaryDk,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 9,
              color: _kPrimary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Species vitals reference data ─────────────────────────────────────────
  static const _kVitalsRef = {
    'Dog':    {'tempLo': 37.5, 'tempHi': 39.5, 'hrLo': 60,  'hrHi': 180, 'tempTyp': '38.5', 'hrTyp': '100'},
    'Cat':    {'tempLo': 38.0, 'tempHi': 39.5, 'hrLo': 120, 'hrHi': 240, 'tempTyp': '38.5', 'hrTyp': '160'},
    'Rabbit': {'tempLo': 38.5, 'tempHi': 40.0, 'hrLo': 120, 'hrHi': 325, 'tempTyp': '39.0', 'hrTyp': '200'},
    'Horse':  {'tempLo': 37.0, 'tempHi': 38.5, 'hrLo': 28,  'hrHi': 44,  'tempTyp': '37.8', 'hrTyp': '36'},
    'Cow':    {'tempLo': 38.0, 'tempHi': 39.5, 'hrLo': 40,  'hrHi': 80,  'tempTyp': '38.8', 'hrTyp': '60'},
    'Sheep':  {'tempLo': 38.5, 'tempHi': 40.0, 'hrLo': 60,  'hrHi': 120, 'tempTyp': '39.0', 'hrTyp': '80'},
    'Goat':   {'tempLo': 38.5, 'tempHi': 40.0, 'hrLo': 60,  'hrHi': 120, 'tempTyp': '39.0', 'hrTyp': '80'},
    'Pig':    {'tempLo': 38.0, 'tempHi': 40.0, 'hrLo': 55,  'hrHi': 100, 'tempTyp': '39.0', 'hrTyp': '75'},
    'Ferret': {'tempLo': 37.8, 'tempHi': 40.0, 'hrLo': 180, 'hrHi': 250, 'tempTyp': '38.8', 'hrTyp': '220'},
  };

  String _tempHint() => _kVitalsRef[_selectedSpecies]?['tempTyp'] as String? ?? '38.5';
  String _hrHint()   => _kVitalsRef[_selectedSpecies]?['hrTyp']   as String? ?? '90';

  String _tempRange() {
    final r = _kVitalsRef[_selectedSpecies];
    if (r == null) return '37–40 °C';
    return '${r["tempLo"]}–${r["tempHi"]} °C';
  }

  String _hrRange() {
    final r = _kVitalsRef[_selectedSpecies];
    if (r == null) return '40–200 bpm';
    return '${r["hrLo"]}–${r["hrHi"]} bpm';
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: _kPrimaryDk,
        fontFamily: 'Outfit',
      ),
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: _kPrimary.withOpacity(0.38),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}
