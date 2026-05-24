import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class CreatePostFlow extends StatefulWidget {
  const CreatePostFlow({super.key});

  @override
  State<CreatePostFlow> createState() => _CreatePostFlowState();
}

class _CreatePostFlowState extends State<CreatePostFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  File? _imageFile;
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();

  final _cropController = CropController();
  Uint8List? _croppedImageData;
  bool _isCropping = false;

  // Named filters for display in UI
  final List<String> _filterNames = ['Normal', 'B&W', 'Warm', 'Cool', 'Fade', 'Vivid'];

  // Proper ColorFilter matrices — each is a 4x5 RGBA matrix
  final List<List<double>> _rawMatrices = [
    // Normal — identity
    <double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
    // B&W (grayscale)
    <double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ],
    // Warm — boost red/green, reduce blue
    <double>[
      1.2, 0,   0,    0, 10,
      0,   1.1, 0,    0, 5,
      0,   0,   0.8,  0, -10,
      0,   0,   0,    1, 0,
    ],
    // Cool — boost blue, reduce red
    <double>[
      0.8, 0,   0,   0, -10,
      0,   1.0, 0,   0, 0,
      0,   0,   1.3, 0, 15,
      0,   0,   0,   1, 0,
    ],
    // Fade — reduce contrast
    <double>[
      0.7, 0,   0,   0, 40,
      0,   0.7, 0,   0, 40,
      0,   0,   0.7, 0, 40,
      0,   0,   0,   1, 0,
    ],
    // Vivid — saturate
    <double>[
      1.5, -0.3, -0.2, 0, 0,
      -0.2, 1.5, -0.3, 0, 0,
      -0.3, -0.2, 1.5, 0, 0,
      0,    0,    0,   1, 0,
    ],
  ];

  late final List<ColorFilter> _filters = _rawMatrices.map((m) => ColorFilter.matrix(m)).toList();

  int _selectedFilterIndex = 0;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      _nextStep();
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    final userId = await AuthService.getUserId();
    if (userId == null) return;

    String authorName = 'Pet Town User';
    final profileRes = await AuthService.getProfile(userId);
    if (profileRes['success']) {
      final user = profileRes['data']['user'];
      authorName = user['display_name'] ?? user['username'] ?? 'Pet Town User';
    }

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    // Upload image first if one is selected
    String imagePath = 'assets/images/p1.png';
    if (_imageFile != null || _croppedImageData != null) {
      Uint8List finalImageBytes = _croppedImageData ?? _imageFile!.readAsBytesSync();
      
      if (_selectedFilterIndex != 0) {
        final img.Image? decodedImg = img.decodeImage(finalImageBytes);
        if (decodedImg != null) {
          final m = _rawMatrices[_selectedFilterIndex];
          for (final pixel in decodedImg) {
            final num r = pixel.r;
            final num g = pixel.g;
            final num b = pixel.b;
            final num a = pixel.a;

            num newR = (r * m[0] + g * m[1] + b * m[2] + a * m[3] + m[4]).clamp(0, 255);
            num newG = (r * m[5] + g * m[6] + b * m[7] + a * m[8] + m[9]).clamp(0, 255);
            num newB = (r * m[10] + g * m[11] + b * m[12] + a * m[13] + m[14]).clamp(0, 255);
            num newA = (r * m[15] + g * m[16] + b * m[17] + a * m[18] + m[19]).clamp(0, 255);

            pixel.r = newR;
            pixel.g = newG;
            pixel.b = newB;
            pixel.a = newA;
          }
          finalImageBytes = Uint8List.fromList(img.encodeJpg(decodedImg, quality: 90));
        }
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(finalImageBytes);

      final uploadRes = await ApiService.uploadImage(tempFile.path);
      if (uploadRes['success']) {
        imagePath = uploadRes['data']['url'];
      } else {
        if (mounted) {
          Navigator.pop(context); // close loader
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadRes['message'] ?? 'Image upload failed')));
        }
        return;
      }
    }

    final res = await ApiService.createPost({
      'user_id': userId,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'author_name': authorName,
      'image_path': imagePath,
      'placeholder_color': '#E0E0E0',
      'placeholder_height': 300.0,
      'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    });

    if (mounted) {
      Navigator.pop(context); // close loader
    }

    if (res['success']) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1Pick(),
            _buildStep2Crop(),
            _buildStep3Edit(),
            _buildStep4Final(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildStep1Pick() {
    return Column(
      children: [
        _buildAppBar(title: 'New Post', rightAction: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.black), onPressed: _pickImage)),
        Expanded(
          child: Container(
            color: Colors.grey.shade200,
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 80, color: Colors.grey.shade600),
                    const SizedBox(height: 16),
                    Text('Choose a photo or\nvideo', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Crop() {
    return Column(
      children: [
        _buildAppBar(title: 'Crop', actionText: 'Next', onAction: () {
          setState(() => _isCropping = true);
          _cropController.crop();
        }),
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: _imageFile == null
                ? const SizedBox()
                : Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.width * 0.85,
                      child: Stack(
                        children: [
                          Crop(
                            image: _imageFile!.readAsBytesSync(),
                            controller: _cropController,
                            aspectRatio: 1,
                            onCropped: (result) {
                              if (result is CropSuccess) {
                                setState(() {
                                  _croppedImageData = result.croppedImage;
                                  _isCropping = false;
                                });
                                _nextStep();
                              } else {
                                setState(() => _isCropping = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to crop image')),
                                  );
                                }
                              }
                            },
                          ),
                          if (_isCropping)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Edit() {
    return Column(
      children: [
        _buildAppBar(title: 'Edit', actionText: 'Next', onAction: _nextStep),
        Expanded(
          flex: 2,
          child: _croppedImageData == null
              ? const SizedBox()
              : ColorFiltered(
                  colorFilter: _filters[_selectedFilterIndex],
                  child: Image.memory(_croppedImageData!, fit: BoxFit.cover, width: double.infinity),
                ),
        ),
        Container(
          color: Colors.black,
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilterIndex = index),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3293B3) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ColorFiltered(
                            colorFilter: _filters[index],
                            child: _croppedImageData != null 
                                ? Image.memory(_croppedImageData!, fit: BoxFit.cover)
                                : const SizedBox(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filterNames[index],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF3293B3) : Colors.white,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Final() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(title: 'Create Post', showBack: true),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: _croppedImageData == null
                          ? Container(color: Colors.grey)
                          : ColorFiltered(
                              colorFilter: _filters[_selectedFilterIndex],
                              child: Image.memory(_croppedImageData!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Title', style: TextStyle(fontSize: 16, color: Color(0xFF374957))),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Add a title',
                    filled: true,
                    fillColor: const Color(0xFFE2E8E8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontSize: 16, color: Color(0xFF374957))),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLength: 800,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a detailed caption',
                    filled: true,
                    fillColor: const Color(0xFFE2E8E8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tags', style: TextStyle(fontSize: 16, color: Color(0xFF374957))),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'Include relevant tags (comma separated)',
                    filled: true,
                    fillColor: const Color(0xFFE2E8E8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374957),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Post', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar({required String title, String? actionText, VoidCallback? onAction, bool showBack = true, Widget? rightAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
              onPressed: _prevStep,
            )
          else
            const SizedBox(width: 48),
          
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0047AB))),
            )
          else if (rightAction != null)
            rightAction
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
