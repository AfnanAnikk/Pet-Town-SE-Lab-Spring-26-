import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../widgets/event_category_chip.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

const _categories = ['Adoption','Vaccination','Meetup','Training',
    'Competition','Outdoor','Awareness','Seminar','Fundraising','Other'];
const _petTypes = ['All','Dog','Cat','Bird','Fish','Rabbit','Other'];
const _visibilities = ['public','private','invite_only'];
const _visibilityLabels = {'public':'Public 🌍','private':'Private 🔒','invite_only':'Invite Only 💌'};

class EditEventPage extends StatefulWidget {
  final EventModel event;
  const EditEventPage({super.key, required this.event});
  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _pageController = PageController();
  int _step = 0;
  bool _isLoading = false;

  XFile? _newCoverImage;
  late final TextEditingController _titleCtrl;
  late String _category;
  late String _petType;
  late String _visibility;
  late DateTime? _startDt;
  late DateTime? _endDt;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _contactCtrl;
  late bool _requiresReg;

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _titleCtrl = TextEditingController(text: ev.title);
    _category = ev.category;
    _petType = ev.petType;
    _visibility = ev.visibility;
    _startDt = ev.startDatetime;
    _endDt = ev.endDatetime;
    _locationCtrl = TextEditingController(text: ev.location);
    _descCtrl = TextEditingController(text: ev.description);
    _maxCtrl = TextEditingController(text: ev.maxParticipants > 0 ? ev.maxParticipants.toString() : '');
    _contactCtrl = TextEditingController(text: ev.contactInfo ?? '');
    _requiresReg = ev.requiresRegistration;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose(); _locationCtrl.dispose();
    _descCtrl.dispose(); _maxCtrl.dispose(); _contactCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 0 && _titleCtrl.text.trim().isEmpty) { _snack('Please enter a title'); return false; }
    if (_step == 1) {
      if (_startDt == null) { _snack('Please pick a start date & time'); return false; }
      if (_locationCtrl.text.trim().isEmpty) { _snack('Please enter a location'); return false; }
      if (_endDt != null && _endDt!.isBefore(_startDt!)) { _snack('End time must be after start'); return false; }
    }
    if (_step == 2 && _descCtrl.text.trim().isEmpty) { _snack('Please enter a description'); return false; }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final uid = await AuthService.getUserId();
      if (uid == null) { _snack('Please log in'); setState(() => _isLoading = false); return; }

      String? coverUrl = widget.event.coverImageUrl;
      if (_newCoverImage != null) {
        final upRes = await ApiService.uploadImage(_newCoverImage!.path);
        if (upRes['success'] == true) coverUrl = upRes['data']?['url'] as String?;
      }

      final payload = {
        'userId': uid,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'pet_type': _petType,
        'visibility': _visibility,
        'location': _locationCtrl.text.trim(),
        'start_datetime': _startDt!.toIso8601String(),
        if (_endDt != null) 'end_datetime': _endDt!.toIso8601String(),
        if (coverUrl != null) 'cover_image_url': coverUrl,
        'max_participants': int.tryParse(_maxCtrl.text) ?? 0,
        'contact_info': _contactCtrl.text.trim(),
        'requires_registration': _requiresReg,
      };

      final res = await ApiService.updateEvent(widget.event.id, payload);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated! ✅'),
              backgroundColor: Color(0xFF27AE60)));
        Navigator.pop(context, true);
      } else {
        _snack(res['message'] ?? 'Update failed');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Outfit'))));

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null && mounted) setState(() => _newCoverImage = img);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = (isStart ? _startDt : _endDt) ?? DateTime.now();
    final date = await showDatePicker(context: context, initialDate: initial,
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)),
        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _brandColor)), child: child!));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _brandColor)), child: child!));
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() { if (isStart) _startDt = dt; else _endDt = dt; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: _back),
        title: const Text('Edit Event', style: TextStyle(fontFamily: 'Outfit',
            fontSize: 20, fontWeight: FontWeight.bold, color: _brandColor)),
        centerTitle: true,
      ),
      body: Column(children: [
        _buildProgressBar(),
        Expanded(child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildStep1(), _buildStep2(), _buildStep3()],
        )),
        _buildNavButtons(),
      ]),
    );
  }

  Widget _buildProgressBar() {
    final labels = ['Basics','When & Where','Details'];
    return Padding(padding: const EdgeInsets.fromLTRB(24,12,24,0),
      child: Row(children: List.generate(3, (i) {
        final active = i == _step; final done = i < _step;
        return Expanded(child: Row(children: [
          Expanded(child: Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 250), height: 4,
                decoration: BoxDecoration(color: (done||active)?_brandColor:Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(fontFamily:'Outfit', fontSize:10,
                fontWeight: active?FontWeight.bold:FontWeight.normal,
                color: active?_brandColor:Colors.grey.shade400)),
          ])),
          if (i<2) const SizedBox(width:6),
        ]));
      })),
    );
  }

  Widget _buildStep1() {
    final existingCover = widget.event.coverImageUrl;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        GestureDetector(onTap: _pickImage, child: AspectRatio(aspectRatio: 16/9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _brandColor.withValues(alpha: 0.4), width: 2),
              image: _newCoverImage != null
                  ? DecorationImage(image: FileImage(File(_newCoverImage!.path)), fit: BoxFit.cover)
                  : (existingCover != null && existingCover.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(existingCover), fit: BoxFit.cover)
                      : null,
            ),
            child: (_newCoverImage == null && (existingCover == null || existingCover.isEmpty))
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size:48, color:_brandColor.withValues(alpha:0.6)),
                    const SizedBox(height:8),
                    Text('Add Cover Photo', style: TextStyle(fontFamily:'Outfit',
                        color:_brandColor.withValues(alpha:0.8), fontWeight:FontWeight.w600)),
                  ])
                : Align(alignment: Alignment.topRight,
                    child: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.edit, color: Colors.white, size:18))),
          ),
        )),
        const SizedBox(height:20),
        _label('Event Title *'), _textField(_titleCtrl, 'e.g. Dog Park Meetup', maxLength:255),
        const SizedBox(height:20), _label('Category'), const SizedBox(height:8),
        Wrap(spacing:8, runSpacing:8, children: _categories.map((c) =>
          EventCategoryChip(label:c, isSelected:_category==c, onTap:()=>setState(()=>_category=c))).toList()),
        const SizedBox(height:20), _label('Pet Type'), const SizedBox(height:8),
        Wrap(spacing:8, runSpacing:8, children: _petTypes.map((p) =>
          EventCategoryChip(label:p, isSelected:_petType==p, onTap:()=>setState(()=>_petType=p))).toList()),
        const SizedBox(height:20), _label('Visibility'), const SizedBox(height:8),
        Row(children: _visibilities.map((v) {
          final active = _visibility==v;
          return Expanded(child: Padding(padding: const EdgeInsets.only(right:6),
            child: GestureDetector(onTap:()=>setState(()=>_visibility=v),
              child: AnimatedContainer(duration: const Duration(milliseconds:200),
                padding: const EdgeInsets.symmetric(vertical:10),
                decoration: BoxDecoration(color: active?_brandColor:Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active?_brandColor:Colors.grey.shade300)),
                child: Text(_visibilityLabels[v]??v, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily:'Outfit', fontSize:12, fontWeight:FontWeight.w600,
                        color: active?Colors.white:Colors.grey.shade600))))));
        }).toList()),
        const SizedBox(height:20),
      ]),
    );
  }

  Widget _buildStep2() {
    final fmt = DateFormat('EEE, d MMM yyyy • h:mm a');
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height:8),
        _label('Start Date & Time *'), const SizedBox(height:8),
        _dateTile(_startDt==null?'Select start date & time':fmt.format(_startDt!), ()=>_pickDateTime(isStart:true)),
        const SizedBox(height:16), _label('End Date & Time (optional)'), const SizedBox(height:8),
        _dateTile(_endDt==null?'Select end date & time':fmt.format(_endDt!), ()=>_pickDateTime(isStart:false)),
        if (_endDt!=null) TextButton(onPressed:()=>setState(()=>_endDt=null),
            child: const Text('Clear end time', style: TextStyle(color:Colors.red, fontFamily:'Outfit'))),
        const SizedBox(height:20),
        _label('Location *'), _textField(_locationCtrl, 'City, address or venue name', prefixIcon:Icons.location_on_outlined),
        const SizedBox(height:20),
      ]),
    );
  }

  Widget _buildStep3() => SingleChildScrollView(padding: const EdgeInsets.all(20), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height:8), _label('Description *'), const SizedBox(height:8),
      TextField(controller:_descCtrl, maxLines:6, style: const TextStyle(fontFamily:'Outfit'),
          decoration: InputDecoration(hintText:'Tell people what this event is about…',
            hintStyle: TextStyle(fontFamily:'Outfit', color:Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color:_brandColor, width:2)))),
      const SizedBox(height:20), _label('Maximum Participants (0 = unlimited)'),
      _textField(_maxCtrl, 'e.g. 50', keyboardType:TextInputType.number),
      const SizedBox(height:20), _label('Contact Information'),
      _textField(_contactCtrl, 'Phone number or email', prefixIcon:Icons.phone_outlined),
      const SizedBox(height:16),
      SwitchListTile.adaptive(contentPadding:EdgeInsets.zero, activeColor:_brandColor,
          title: const Text('Require Registration', style: TextStyle(fontFamily:'Outfit',
              fontWeight:FontWeight.w600, color:_secondary)),
          subtitle: Text('Participants must be approved', style: TextStyle(fontFamily:'Outfit',
              fontSize:12, color:Colors.grey.shade500)),
          value:_requiresReg, onChanged:(v)=>setState(()=>_requiresReg=v)),
      const SizedBox(height:20),
    ]),
  );

  Widget _buildNavButtons() => Container(
    padding: const EdgeInsets.fromLTRB(20,12,20,28),
    decoration: BoxDecoration(color:Colors.white, boxShadow:[BoxShadow(
        color:Colors.black.withValues(alpha:0.06), blurRadius:10, offset:const Offset(0,-3))]),
    child: Row(children:[
      if (_step>0)...[
        Expanded(child: OutlinedButton(onPressed:_isLoading?null:_back,
          style: OutlinedButton.styleFrom(side:const BorderSide(color:_brandColor),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
              padding:const EdgeInsets.symmetric(vertical:15)),
          child: const Text('Back', style:TextStyle(fontFamily:'Outfit',color:_brandColor,fontWeight:FontWeight.w600,fontSize:15)))),
        const SizedBox(width:12),
      ],
      Expanded(child: ElevatedButton(onPressed:_isLoading?null:_next,
        style: ElevatedButton.styleFrom(backgroundColor:_brandColor, elevation:0,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
            padding:const EdgeInsets.symmetric(vertical:15)),
        child: _isLoading
            ? const SizedBox(width:22,height:22,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2))
            : Text(_step==2?'Save Changes ✅':'Next',
                style:const TextStyle(fontFamily:'Outfit',color:Colors.white,fontWeight:FontWeight.bold,fontSize:15)))),
    ]),
  );

  Widget _label(String t) => Text(t, style:const TextStyle(fontFamily:'Outfit',fontWeight:FontWeight.w600,fontSize:14,color:_secondary));

  Widget _textField(TextEditingController ctrl, String hint, {int? maxLength, IconData? prefixIcon, TextInputType? keyboardType}) =>
    TextField(controller:ctrl, maxLength:maxLength, keyboardType:keyboardType,
      style:const TextStyle(fontFamily:'Outfit'),
      decoration: InputDecoration(hintText:hint, counterText:'',
        hintStyle:TextStyle(fontFamily:'Outfit', color:Colors.grey.shade400),
        prefixIcon: prefixIcon!=null?Icon(prefixIcon, color:_brandColor, size:20):null,
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),
            borderSide:const BorderSide(color:_brandColor,width:2)),
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14)));

  Widget _dateTile(String label, VoidCallback onTap) => GestureDetector(onTap:onTap,
    child: Container(padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(border:Border.all(color:Colors.grey.shade300), borderRadius:BorderRadius.circular(12)),
      child:Row(children:[const Icon(Icons.calendar_today_outlined,color:_brandColor,size:20),
        const SizedBox(width:12),
        Text(label, style:TextStyle(fontFamily:'Outfit',
            color:label.startsWith('Select')?Colors.grey.shade400:_secondary))])));
}
