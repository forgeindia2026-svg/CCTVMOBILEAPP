import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audio_helper.dart';
import '../../tracking/screens/technician_tracking_screen.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/login_screen.dart';

class BookInstallationScreen extends StatefulWidget {
  final String? initialServiceType;

  const BookInstallationScreen({
    super.key,
    this.initialServiceType,
  });

  @override
  State<BookInstallationScreen> createState() => _BookInstallationScreenState();
}

class _BookInstallationScreenState extends State<BookInstallationScreen> {
  int _currentStep = 2; // Step 2 is Scheduling, Step 3 is Confirm
  late String _installationType;
  String _selectedTimeSlot = '02:00 PM';
  int _selectedDay = 14;
  bool _isSubmitting = false;

  final List<String> _timeSlots = ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM'];

  // Controllers for Step 3 Address & Problem Description
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _problemDescController = TextEditingController();

  // Address selection & form state (Matching User Mockups Image 1 & 2)
  List<Map<String, String>> _savedAddresses = [];
  int _selectedAddressIndex = 0;
  bool _isAddingNewAddress = false;

  final _addAddressFormKey = GlobalKey<FormState>();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityFormCtrl = TextEditingController();
  String _selectedState = 'Tamil Nadu';
  String _selectedAddressType = 'Home';

  final List<String> _indianStates = [
    'Tamil Nadu',
    'Karnataka',
    'Andhra Pradesh',
    'Kerala',
    'Telangana',
    'Maharashtra',
    'Delhi',
    'Puducherry',
    'Goa',
    'Gujarat',
    'Odisha',
    'West Bengal',
    'Rajasthan',
    'Uttar Pradesh',
  ];

  // Image upload
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _selectedImageBytes = [];
  final List<String> _selectedImagesBase64 = [];

  // Voice Note Recording State
  bool _isRecordingAudio = false;
  bool _hasRecordedAudio = false;
  String? _recordedVoiceBase64;
  bool _isPlayingAudio = false;
  int _recordingDurationSeconds = 0;
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  double _playbackProgress = 0.0;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _installationType = widget.initialServiceType ?? 'CCTV Repair & Maintenance';
    final now = DateTime.now();
    _selectedDay = (now.day <= 28) ? now.day : 14;
    _prefillUserData();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
      debugPrint('Speech enabled: $_speechEnabled');
    } catch (e) {
      debugPrint('Speech init catch: $e');
    }
  }

  String formatSpeechToTanglish(String input) {
    if (input.trim().isEmpty) return input;

    final Map<String, String> wordMap = {
      'சிசிடிவி': 'CCTV',
      'கேமரா': 'camera',
      'கேமராக்கள்': 'cameras',
      'டிவிஆர்': 'DVR',
      'என்விஆர்': 'NVR',
      'ஒர்க்': 'work',
      'வேலை': 'work',
      'ஆகல': 'aagala',
      'ஆகவில்லை': 'aagavillai',
      'வரல': 'varala',
      'வரவில்லை': 'varavillai',
      'பிரச்சனை': 'problem',
      'பிரச்சினை': 'problem',
      'பவர்': 'power',
      'இல்லை': 'illai',
      'டிஸ்ப்ளே': 'display',
      'லைன்': 'line',
      'கட்': 'cut',
      'கனெக்ஷன்': 'connection',
      'சிக்னல்': 'signal',
      'இமேஜ்': 'image',
      'தெரியல': 'theriyala',
      'தெரியவில்லை': 'theriyavillai',
      'ஆப்': 'off',
      'ஆன்': 'on',
      'கேபிள்': 'cable',
      'வயர்': 'wire',
      'அடாப்டர்': 'adapter',
      'ஹார்ட்': 'hard',
      'டிஸ்க்': 'disk',
      'ரெக்கார்டிங்': 'recording',
      'நிற்கிறது': 'nirkirathu',
      'பிளர்': 'blur',
      'நைட்': 'night',
      'விஷன்': 'vision',
    };

    String text = input;
    wordMap.forEach((tamilWord, tanglishWord) {
      text = text.replaceAll(tamilWord, tanglishWord);
    });

    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) {
      text = _transliterateTamilToTanglish(text);
    }

    return text;
  }

  String _transliterateTamilToTanglish(String tamilText) {
    final map = {
      'அ': 'a', 'ஆ': 'aa', 'இ': 'i', 'ஈ': 'ee', 'உ': 'u', 'ஊ': 'oo', 'எ': 'e', 'ஏ': 'ae', 'ஐ': 'ai', 'ஒ': 'o', 'ஓ': 'oa', 'ஔ': 'au',
      'க்': 'k', 'ங்': 'ng', 'ச்': 'ch', 'ஞ்': 'nj', 'ட்': 't', 'ண்': 'n', 'த்': 'th', 'ந்': 'n', 'ப்': 'p', 'ம்': 'm', 'ய்': 'y', 'ர்': 'r', 'ல்': 'l', 'வ்': 'v', 'ழ்': 'zh', 'ள்': 'l', 'ற்': 'r', 'ன்': 'n',
      'கா': 'kaa', 'கி': 'ki', 'கீ': 'kee', 'கு': 'ku', 'கூ': 'koo', 'கெ': 'ke', 'கே': 'kae', 'கை': 'kai', 'கொ': 'ko', 'கோ': 'koa', 'க': 'ka',
      'ஙா': 'ngaa', 'ஙி': 'ngi', 'ஙீ': 'ngee', 'ஙு': 'ngu', 'ஙூ': 'ngoo', 'ஙெ': 'nge', 'ஙே': 'ngae', 'ஙை': 'ngai', 'ஙொ': 'ngo', 'ஙோ': 'ngoa', 'ங': 'nga',
      'சா': 'chaa', 'சி': 'chi', 'சீ': 'chee', 'சு': 'chu', 'சூ': 'choo', 'செ': 'che', 'சே': 'chae', 'சை': 'chai', 'சொ': 'cho', 'சோ': 'choa', 'ச': 'cha',
      'ஞா': 'nyaa', 'ஞி': 'nyi', 'ஞீ': 'nyee', 'ஞு': 'nyu', 'ஞூ': 'nyoo', 'ஞெ': 'nye', 'ஞே': 'nyae', 'ஞை': 'nyai', 'ஞொ': 'nyo', 'ஞோ': 'nyoa', 'ஞ': 'nya',
      'டா': 'taa', 'டி': 'ti', 'டீ': 'tee', 'டு': 'tu', 'டூ': 'too', 'டெ': 'te', 'டே': 'tae', 'டை': 'tai', 'டொ': 'to', 'டோ': 'toa', 'ட': 'ta',
      'ணா': 'naa', 'ணி': 'ni', 'ணீ': 'nee', 'ணு': 'nu', 'ணூ': 'noo', 'ணெ': 'ne', 'ணே': 'nae', 'ணை': 'nai', 'ணொ': 'no', 'ணோ': 'noa', 'ண': 'na',
      'தா': 'thaa', 'தி': 'thi', 'தீ': 'thee', 'து': 'thu', 'தூ': 'thoo', 'தெ': 'the', 'தே': 'thae', 'தை': 'thai', 'தொ': 'tho', 'தோ': 'thoa', 'த': 'tha',
      'நா': 'naa', 'நி': 'ni', 'நீ': 'nee', 'நு': 'nu', 'நூ': 'noo', 'நெ': 'ne', 'நே': 'nae', 'நை': 'nai', 'நொ': 'no', 'நோ': 'noa', 'ந': 'na',
      'பா': 'paa', 'பி': 'pi', 'பீ': 'pee', 'பு': 'pu', 'பூ': 'poo', 'பெ': 'pe', 'பே': 'pae', 'பை': 'pai', 'பொ': 'po', 'போ': 'poa', 'ப': 'pa',
      'மா': 'maa', 'மி': 'mi', 'மீ': 'mee', 'மு': 'mu', 'மூ': 'moo', 'மெ': 'me', 'மே': 'mae', 'மை': 'mai', 'மொ': 'mo', 'மோ': 'moa', 'ம': 'ma',
      'யா': 'yaa', 'யி': 'yi', 'யீ': 'yee', 'யு': 'yu', 'யூ': 'yoo', 'யெ': 'ye', 'யே': 'yae', 'யை': 'yai', 'யொ': 'yo', 'யோ': 'yoa', 'ய': 'ya',
      'ரா': 'raa', 'ரி': 'ri', 'ரீ': 'ree', 'ரு': 'ru', 'ரூ': 'roo', 'ரெ': 're', 'ரே': 'rae', 'ரை': 'rai', 'ரொ': 'ro', 'ரோ': 'roa', 'ர': 'ra',
      'லா': 'laa', 'லி': 'li', 'லீ': 'lee', 'லு': 'lu', 'லூ': 'loo', 'லெ': 'le', 'லே': 'lae', 'லை': 'lai', 'லொ': 'lo', 'லோ': 'loa', 'ல': 'la',
      'வா': 'vaa', 'வி': 'vi', 'வீ': 'vee', 'வு': 'vu', 'வூ': 'voo', 'வெ': 've', 'வே': 'vae', 'வை': 'vai', 'வொ': 'vo', 'வோ': 'voa', 'வ': 'va',
      'ழா': 'zhaa', 'ழி': 'zhi', 'ழீ': 'zhee', 'ழு': 'zhu', 'ழூ': 'zhoo', 'ழெ': 'zhe', 'ழே': 'zhae', 'ழை': 'zhai', 'ழொ': 'zho', 'ழோ': 'zhoa', 'ழ': 'zha',
      'ளா': 'laa', 'ளி': 'li', 'ளீ': 'lee', 'ளு': 'lu', 'ளூ': 'loo', 'ளெ': 'le', 'ளே': 'lae', 'ளை': 'lai', 'ளொ': 'lo', 'ளோ': 'loa', 'ள': 'la',
      'றா': 'raa', 'றி': 'ri', 'றீ': 'ree', 'று': 'ru', 'றூ': 'roo', 'றெ': 're', 'றே': 'rae', 'றை': 'rai', 'றொ': 'ro', 'றோ': 'roa', 'ற': 'ra',
      'னா': 'naa', 'னி': 'ni', 'னீ': 'nee', 'னு': 'nu', 'னூ': 'noo', 'னெ': 'ne', 'னே': 'nae', 'னை': 'nai', 'னொ': 'no', 'னோ': 'noa', 'ன': 'na',
      'ஃ': 'h',
    };

    String res = tamilText;
    map.forEach((k, v) {
      res = res.replaceAll(k, v);
    });
    return res;
  }

  void _startVoiceRecording() async {
    AudioHelper.startMicRecording();
    setState(() {
      _isRecordingAudio = true;
      _recordingDurationSeconds = 0;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecordingAudio) {
        setState(() {
          _recordingDurationSeconds++;
        });
      }
    });
  }

  String _formatAudioDuration(int totalSecs) {
    if (totalSecs <= 0) return '00:00';
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _stopVoiceRecording() async {
    _recordingTimer?.cancel();
    final base64 = await AudioHelper.stopMicRecording();

    setState(() {
      _isRecordingAudio = false;
      if (base64 != null && base64.length > 300) {
        _recordedVoiceBase64 = base64;
        _hasRecordedAudio = true;
      } else {
        _hasRecordedAudio = _recordedVoiceBase64 != null && _recordedVoiceBase64!.length > 300;
      }
    });

    if (mounted && _hasRecordedAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Voice note recorded (${_formatAudioDuration(_recordingDurationSeconds)})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppColors.statusGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _playAudioSound() {
    AudioHelper.playVoicePlaybackSound('');
  }

  void _stopAudioSound() {
    AudioHelper.stopVoicePlaybackSound();
  }

  void _toggleAudioPlayback() {
    if (_isPlayingAudio) {
      _playbackTimer?.cancel();
      _stopAudioSound();
      setState(() {
        _isPlayingAudio = false;
        _playbackProgress = 0.0;
      });
    } else {
      setState(() {
        _isPlayingAudio = true;
        _playbackProgress = 0.0;
      });

      _playAudioSound();

      final totalTicks = _recordingDurationSeconds > 0 ? _recordingDurationSeconds * 10 : 30;
      int currentTick = 0;

      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted || !_isPlayingAudio) {
          timer.cancel();
          _stopAudioSound();
          return;
        }
        currentTick++;
        setState(() {
          _playbackProgress = (currentTick / totalTicks).clamp(0.0, 1.0);
        });

        if (currentTick >= totalTicks) {
          timer.cancel();
          _stopAudioSound();
          setState(() {
            _isPlayingAudio = false;
            _playbackProgress = 0.0;
          });
        }
      });
    }
  }

  void _deleteVoiceRecording() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _stopAudioSound();
    AudioHelper.deleteMicRecording();
    setState(() {
      _isRecordingAudio = false;
      _hasRecordedAudio = false;
      _recordedVoiceBase64 = null;
      _isPlayingAudio = false;
      _recordingDurationSeconds = 0;
      _playbackProgress = 0.0;
    });
  }

  Future<void> _prefillUserData() async {
    final name = await StorageService.getUserName() ?? '';
    final phone = await StorageService.getUserPhone() ?? '';
    final cachedAddr = await StorageService.getUserAddress();

    if (name.isNotEmpty) _receiverNameCtrl.text = name;
    if (phone.isNotEmpty) _receiverPhoneCtrl.text = phone;

    var addresses = await LocationService.getSavedAddresses();

    if (addresses.isEmpty && cachedAddr != null && cachedAddr.trim().isNotEmpty) {
      final Map<String, String> defaultProfile = {
        'name': name.isNotEmpty ? name : 'Customer',
        'phone': phone,
        'address': cachedAddr.trim(),
        'type': 'Home',
        'isDefault': 'true',
        'isPrimary': 'true',
      };
      await LocationService.addSavedAddress(defaultProfile);
      addresses = [defaultProfile];
    }

    if (mounted) {
      setState(() {
        _savedAddresses = addresses;
        _selectedAddressIndex = addresses.isNotEmpty ? 0 : -1;
        if (addresses.isNotEmpty) {
          _applySelectedAddress(0);
        } else if (cachedAddr != null && cachedAddr.isNotEmpty) {
          _addressController.text = cachedAddr;
        }
      });
    }
  }

  void _applySelectedAddress(int index) {
    if (index >= 0 && index < _savedAddresses.length) {
      final item = _savedAddresses[index];
      final fullAddr = item['address'] ?? '';
      _addressController.text = fullAddr;

      final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(fullAddr);
      if (pinMatch != null) {
        _postalCodeController.text = pinMatch.group(0)!;
      }

      final parts = fullAddr.split(',');
      if (parts.length >= 2) {
        _cityController.text = parts[parts.length - 2].replaceAll(RegExp(r'-\s*\d+'), '').trim();
      } else if (parts.isNotEmpty) {
        _cityController.text = parts.last.replaceAll(RegExp(r'-\s*\d+'), '').trim();
      }
    }
  }

  Future<void> _saveNewAddress() async {
    if (!_addAddressFormKey.currentState!.validate()) {
      return;
    }

    final street = _streetCtrl.text.trim();
    final locality = _localityCtrl.text.trim();
    final city = _cityFormCtrl.text.trim();
    final state = _selectedState;
    final pincode = _pincodeCtrl.text.trim();
    final name = _receiverNameCtrl.text.trim();
    final phone = _receiverPhoneCtrl.text.trim();

    final constructedAddress = '$street, $locality, $city, $state - $pincode';

    final newAddressMap = {
      'name': name.isNotEmpty ? name : 'Customer',
      'phone': phone,
      'address': constructedAddress,
      'type': _selectedAddressType,
      'isDefault': 'false',
    };

    await LocationService.addSavedAddress(newAddressMap);
    final updatedList = await LocationService.getSavedAddresses();

    if (mounted) {
      setState(() {
        _savedAddresses = updatedList;
        _selectedAddressIndex = 0;
        _isAddingNewAddress = false;
        _applySelectedAddress(0);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved and selected successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _problemDescController.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _pincodeCtrl.dispose();
    _localityCtrl.dispose();
    _streetCtrl.dispose();
    _cityFormCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedImageBytes.add(bytes);
          _selectedImagesBase64.add(base64Str);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach image: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImageBytes.removeAt(index);
      _selectedImagesBase64.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload CCTV Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take a photo or choose an existing picture of your CCTV setup or fault',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryRed),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture CCTV issue with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select image from device storage'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnlargedImage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _selectedImageBytes[index],
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    // 1. Form Validation
    if (_isAddingNewAddress) {
      if (!_addAddressFormKey.currentState!.validate()) {
        return;
      }
      await _saveNewAddress();
    } else if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add an installation address.')),
      );
      return;
    }

    // 2. Authentication Check
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to confirm your booking.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(returnToPrevious: true)),
      );
      if (success != true) return; // User canceled login
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 3. Retrieve user info from StorageService
      final email = await StorageService.getUserEmail() ?? 'customer@skvision.com';
      final name = await StorageService.getUserName() ?? 'Customer';
      final phone = await StorageService.getUserPhone() ?? '9876543210';

      final isServiceOrRepair = _installationType.toLowerCase().contains('service') || 
                                _installationType.toLowerCase().contains('repair') ||
                                _installationType.toLowerCase().contains('amc');

      final problemText = _problemDescController.text.trim();
      final fullDesc = problemText.isNotEmpty
          ? problemText
          : 'Service booking for $_installationType';

      final now = DateTime.now();
      final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';

      final fullAddress = _addressController.text.trim();

      String? recordedAudioBase64 = _recordedVoiceBase64;
      if (recordedAudioBase64 == null || recordedAudioBase64.length < 300) {
        recordedAudioBase64 = await AudioHelper.getRecordedAudioBase64();
        if (recordedAudioBase64 != null && recordedAudioBase64.length > 300) {
          _recordedVoiceBase64 = recordedAudioBase64;
        }
      }

      final bool hasAudio = (_recordedVoiceBase64 != null && _recordedVoiceBase64!.length > 300) ||
          (recordedAudioBase64 != null && recordedAudioBase64.length > 300);

      final audioDataStr = _recordedVoiceBase64 ?? recordedAudioBase64 ?? '';

      final durationStr = hasAudio
          ? _formatAudioDuration(_recordingDurationSeconds)
          : '';

      final effectiveAudioBase64 = hasAudio ? audioDataStr : '';

      debugPrint('🔊 Submitting Booking Payload Audio check:');
      debugPrint('  - hasAudio: $hasAudio');
      debugPrint('  - audioLength: ${effectiveAudioBase64.length}');

      // 4. Construct Request Payload (Formatted for Service Requests sync in Admin)
      final requestBody = {
        'title': '$_installationType Service Request',
        'category': isServiceOrRepair ? 'Service' : 'Installation',
        'serviceType': 'DELIVERY_INSTALLATION',
        'items': [
          {
            'title': _installationType,
            'productId': 'service-${isServiceOrRepair ? 'repair' : 'install'}',
            'price': 0,
            'quantity': 1,
          }
        ],
        'customerName': name,
        'customerPhone': phone,
        'customerEmail': email,
        'shippingAddress': fullAddress,
        'customerQuery': problemText,
        'problemDescription': problemText,
        'description': fullDesc,
        'scheduledDate': formattedDate,
        'scheduledTimeSlot': _selectedTimeSlot,
        'orderCategory': 'Delivery & Installation',
        'hasVoiceNote': hasAudio,
        'voiceNoteDuration': hasAudio ? durationStr : '',
        'voiceNoteUrl': hasAudio ? effectiveAudioBase64 : '',
        'voiceNoteBase64': hasAudio ? effectiveAudioBase64 : '',
        'voiceNote': hasAudio ? effectiveAudioBase64 : '',
        'audioUrl': hasAudio ? effectiveAudioBase64 : '',
        'siteImages': _selectedImagesBase64,
        'images': _selectedImagesBase64,
        'customer': {
          'name': name,
          'phone': phone,
          'email': email,
          'address': fullAddress,
          'city': _cityController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
        },
        'priority': (isServiceOrRepair || problemText.isNotEmpty) ? 'HIGH' : 'MEDIUM',
        'status': 'PENDING'
      };

      // 5. POST to backend API (Orders with serviceType syncs to Service Requests tab)
      dynamic res;
      try {
        res = await ApiService.post('orders', requestBody);
      } catch (_) {
        res = await ApiService.post('jobs', requestBody);
      }

      if (res != null && res['success'] == true) {
        if (!mounted) return;
        final orderData = (res['order'] is Map) ? res['order'] : ((res['data'] is Map) ? res['data'] : {});
        final assignedTech = orderData['technician']?['name'] ?? (orderData['technician'] is String ? orderData['technician'] : null);

        // 6. Show Success Dialogue
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Booking Success', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Your $_installationType has been successfully scheduled for $_selectedTimeSlot.\n\nOur team has received your request and will assign the nearest technician shortly.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous page / home
                },
                child: const Text('Back to Home', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TechnicianTrackingScreen(
                        orderNumber: orderData['orderNumber'] ?? 'SK-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        serviceTitle: _installationType,
                        scheduledDate: formattedDate,
                        scheduledTimeSlot: _selectedTimeSlot,
                        address: fullAddress,
                        technicianName: assignedTech,
                        status: orderData['status'] ?? 'Open',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Track Service', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        throw Exception(res?['message'] ?? 'Failed to register booking');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_installationType.contains('Repair') ? 'CCTV Repair & Service' : 'Book Installation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            if (_currentStep == 3) {
              setState(() {
                _currentStep = 2;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Wizard Indicator ((1) Details -> (2) Schedule -> (3) Confirm)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepBubble('1', 'Details', true),
                  _buildStepLine(true),
                  _buildStepBubble('2', 'Schedule', true),
                  _buildStepLine(_currentStep == 3),
                  _buildStepBubble('3', 'Confirm', _currentStep == 3),
                ],
              ),

              const SizedBox(height: 28),

              if (_currentStep == 2) ...[
                // Installation / Service Type Selection
                Text('Select Service Type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildServiceTypeChip('CCTV Repair & Maintenance', Icons.build_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Calendar Date Picker Mock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
                    const Text('This Month', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Sun', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Mon', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Tue', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Wed', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Thu', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Fri', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Sat', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: 31,
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isSelected = day == _selectedDay;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                              });
                            },
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Time Slot Selection
                Text('Select Time Slot', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots.map((slot) {
                    final isSelected = slot == _selectedTimeSlot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: AppColors.surfaceWhite,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedTimeSlot = slot;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 3;
                      });
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // STEP 3: CONFIRMATION, PROBLEM DETAILS, IMAGE UPLOAD & ADDRESS FORM
                Text('Confirm Installation Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                
                // Summary Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(Icons.settings_suggest_outlined, 'Service Type', _installationType),
                      const SizedBox(height: 10),
                      _buildSummaryRow(Icons.calendar_today_outlined, 'Scheduled Date', 'Day $_selectedDay'),
                      const SizedBox(height: 10),
                      _buildSummaryRow(Icons.access_time, 'Time Slot', _selectedTimeSlot),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Customer Problem / Issue Description Field
                Row(
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 20, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      'CCTV Problem / Issue Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explain what issue you are facing with your CCTV / DVR / system',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _problemDescController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Camera 2 display is black/flickering, DVR beeping, no video recording, wire damaged near main entrance...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Customer Voice Recording Card
                _buildVoiceRecorderCard(),

                const SizedBox(height: 24),

                // Customer Image Upload Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Photos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Text(
                      '${_selectedImageBytes.length}/5 Attached',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload photo of your camera, screen, DVR or faulty setup (helps technician diagnose)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Photo preview & add button row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Add Photo Button
                      if (_selectedImageBytes.length < 5)
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            width: 84,
                            height: 84,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primaryRed.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryRed, size: 20),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add Photo',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Image Thumbnails
                      ..._selectedImageBytes.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final bytes = entry.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _showEnlargedImage(idx),
                              child: Container(
                                width: 84,
                                height: 84,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderLight),
                                  image: DecorationImage(
                                    image: MemoryImage(bytes),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _removeImage(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Address Selection & Add Section (Matching User Mockups Image 1 & 2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddressHeader(),
                    _isAddingNewAddress ? _buildAddNewAddressView() : _buildSavedAddressesView(),
                  ],
                ),

                const SizedBox(height: 28),

                // Bottom Navigation Bar (Image 1 & 2 Style - Overflow Proof)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep = 2;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF64748B)),
                      label: const Text(
                        'BACK TO SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1F38), // Dark Navy Blue as in Image 1 & 2
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'CONFIRM BOOKING',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.check_circle_outline, size: 15),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceRecorderCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isRecordingAudio
            ? const Color(0xFFFEF2F2)
            : _hasRecordedAudio
                ? const Color(0xFFF0FDF4)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecordingAudio
              ? const Color(0xFFEF4444)
              : _hasRecordedAudio
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isRecordingAudio
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RECORDING VOICE NOTE... 00:${_recordingDurationSeconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(18, (i) {
                    final h = 8.0 + ((i * 7 + _recordingDurationSeconds * 5) % 20);
                    return Container(
                      width: 4,
                      height: h,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _stopVoiceRecording,
                  icon: const Icon(Icons.stop, size: 18, color: Colors.white),
                  label: const Text('Stop Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            )
          : _hasRecordedAudio
              ? Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleAudioPlayback,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              const Text(
                                'Voice Note Recorded',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '00:${_recordingDurationSeconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _isPlayingAudio ? _playbackProgress : 1.0,
                              backgroundColor: const Color(0xFFDCFCE7),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteVoiceRecording,
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Delete voice note',
                    ),
                  ],
                )
              : Row(
                  children: [
                    GestureDetector(
                      onTap: _startVoiceRecording,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: AppColors.primaryRed, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Record Voice Note',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap the mic to speak your problem aloud',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _startVoiceRecording,
                      icon: const Icon(Icons.mic_none, size: 16, color: Colors.white),
                      label: const Text('Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAddressHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1F38), // Dark Navy Blue matching Image 1 & 2
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yellow location pin avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107), // Vibrant Amber Yellow
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF0B1F38),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Service Location Address',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the location where the technician should visit',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Close Icon
          GestureDetector(
            onTap: () {
              if (_isAddingNewAddress) {
                setState(() => _isAddingNewAddress = false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: SELECT FROM SAVED ADDRESSES + Add New Address
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECT FROM SAVED ADDRESSES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isAddingNewAddress = true;
                  });
                },
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'Add New Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards list
          if (_savedAddresses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text(
                'No saved addresses found. Tap "+ Add New Address" above.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedAddresses.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 14),
              itemBuilder: (ctx, index) {
                final item = _savedAddresses[index];
                final isSelected = index == _selectedAddressIndex;
                final type = item['type'] ?? 'Home';
                final isWork = type.toLowerCase().contains('work');
                final isDefault = item['isDefault'] == 'true' || item['isPrimary'] == 'true';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAddressIndex = index;
                      _applySelectedAddress(index);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio button
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                              width: isSelected ? 6 : 2,
                            ),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    item['name'] ?? 'Customer',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  // Badge for type (WORK / HOME)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isWork ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isWork ? const Color(0xFFB45309) : const Color(0xFF0369A1),
                                      ),
                                    ),
                                  ),
                                  if (isDefault && !isWork)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PRIMARY PROFILE ADDRESS',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['address'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                  height: 1.4,
                                ),
                              ),
                              if ((item['phone'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Contact: ${item['phone']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAddNewAddressView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5), // Light warm cream tint as in Image 2
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _addAddressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RECEIVER NAME *
            _buildFieldLabel('RECEIVER NAME *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _receiverNameCtrl,
              decoration: _buildInputDecoration('Full Name / Receiver Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Receiver name is required' : null,
            ),
            const SizedBox(height: 14),

            // 10-DIGIT MOBILE NUMBER *
            _buildFieldLabel('10-DIGIT MOBILE NUMBER *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _receiverPhoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _buildInputDecoration('10-digit mobile number').copyWith(counterText: ''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                if (v.trim().length < 10) return 'Must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // PINCODE *
            _buildFieldLabel('PINCODE *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pincodeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _buildInputDecoration('6-Digit Pincode').copyWith(counterText: ''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Pincode is required';
                if (v.trim().length < 6) return 'Must be 6 digits';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // LOCALITY / SECTOR *
            _buildFieldLabel('LOCALITY / SECTOR *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _localityCtrl,
              decoration: _buildInputDecoration('Locality / Area'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Locality is required' : null,
            ),
            const SizedBox(height: 14),

            // FLAT / HOUSE NO / STREET ADDRESS *
            _buildFieldLabel('FLAT / HOUSE NO / STREET ADDRESS *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _streetCtrl,
              decoration: _buildInputDecoration('Building / House No, Street Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Address detail is required' : null,
            ),
            const SizedBox(height: 14),

            // CITY *
            _buildFieldLabel('CITY *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cityFormCtrl,
              decoration: _buildInputDecoration('City'),
              validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
            ),
            const SizedBox(height: 14),

            // STATE *
            _buildFieldLabel('STATE *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _indianStates.contains(_selectedState) ? _selectedState : _indianStates.first,
              decoration: _buildInputDecoration('Select State'),
              items: _indianStates.map((st) {
                return DropdownMenuItem(
                  value: st,
                  child: Text(st, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedState = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // SAVE ADDRESS AS *
            _buildFieldLabel('SAVE ADDRESS AS *'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAddressTypePill('Home'),
                const SizedBox(width: 10),
                _buildAddressTypePill('Work'),
                const SizedBox(width: 10),
                _buildAddressTypePill('Other'),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingNewAddress = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveNewAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800), // Yellow button matching Image 2
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save & Deliver Here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.4,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }

  Widget _buildAddressTypePill(String type) {
    final isSelected = _selectedAddressType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAddressType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFB800) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            type,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryRed),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceTypeChip(String title, IconData icon) {
    final isSelected = title == _installationType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _installationType = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRedLight : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryRed : AppColors.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(String step, String label, bool isActive) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.primaryRed : AppColors.surfaceSecondary,
          child: Text(step, style: TextStyle(color: isActive ? Colors.white : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isActive ? AppColors.primaryRed : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? AppColors.primaryRed : AppColors.borderLight,
    );
  }
}
