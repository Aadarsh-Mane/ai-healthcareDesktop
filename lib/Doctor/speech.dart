import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/speech/v1.dart' as speech;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class GoogleSpeechToTextService {
  // Service account credentials

//...
  speech.SpeechApi? _speechApi;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isInitialized = false;
  List<InputDevice> _availableDevices = [];

  // Enhanced Medical vocabulary phrases to improve recognition
  static const List<String> _medicalPhrases = [
    // Common medications
    'paracetamol', 'acetaminophen', 'azithromycin', 'amoxicillin', 'ibuprofen',
    'aspirin',
    'metformin', 'lisinopril', 'atorvastatin', 'omeprazole', 'furosemide',
    'warfarin',
    'insulin', 'prednisone', 'ciprofloxacin', 'hydrochlorothiazide',
    'levothyroxine',

    // Vital signs and measurements
    'blood pressure', 'heart rate', 'temperature', 'pulse', 'glucose',
    'oxygen saturation',
    'respiratory rate', 'body mass index', 'weight', 'height', 'systolic',
    'diastolic',

    // Dosage and instructions
    'milligrams', 'mg', 'tablets', 'capsules', 'milliliters', 'ml', 'units',
    'twice daily', 'three times daily', 'once daily', 'every eight hours',
    'after meals', 'before meals', 'with food', 'on empty stomach',
    'as needed', 'for pain', 'for fever', 'bedtime',

    // Medical terms
    'diagnosis', 'symptoms', 'fever', 'headache', 'nausea', 'vomiting', 'cough',
    'shortness of breath', 'chest pain', 'abdominal pain', 'dizziness',
    'respiratory', 'cardiovascular', 'hypertension', 'diabetes', 'pneumonia',
    'prescription', 'medication', 'dosage', 'admission', 'patient', 'allergy',
    'side effects', 'contraindication', 'chronic', 'acute', 'severe', 'mild',
    'moderate',

    // Medical specialties
    'cardiology', 'neurology', 'orthopedics', 'dermatology', 'gastroenterology',
    'pulmonology', 'endocrinology', 'nephrology', 'oncology', 'psychiatry',

    // Common conditions
    'hypertension', 'diabetes mellitus', 'coronary artery disease',
    'atrial fibrillation',
    'chronic obstructive pulmonary disease', 'asthma', 'pneumonia',
    'urinary tract infection',
    'gastroesophageal reflux disease', 'osteoarthritis', 'depression', 'anxiety'
  ];

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint(
          'Initializing Google Speech API for desktop with enhanced audio support...');

      // Get available audio input devices for better device selection
      try {
        _availableDevices = await _audioRecorder.listInputDevices();
        debugPrint('Available audio devices: ${_availableDevices.length}');
        for (final device in _availableDevices) {
          debugPrint('Device: ${device.label} (ID: ${device.id})');
        }
      } catch (e) {
        debugPrint('Could not list audio devices: $e');
      }

      // Initialize Google Speech API with service account
      final accountCredentials =
          ServiceAccountCredentials.fromJson('_serviceAccountCredentials');
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        [speech.SpeechApi.cloudPlatformScope],
      );

      _speechApi = speech.SpeechApi(authClient);
      _isInitialized = true;

      debugPrint('Google Speech-to-Text initialized successfully');

      // Validate service account permissions
      final isValid = await validateServiceAccount();
      if (!isValid) {
        debugPrint(
            'Warning: Service account validation failed, but continuing...');
      }

      return true;
    } catch (e) {
      debugPrint('Failed to initialize Google Speech-to-Text: $e');
      return false;
    }
  }

  Future<bool> startRecording({String? preferredDeviceId}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // Check if already recording
      if (await _audioRecorder.isRecording()) {
        debugPrint('Already recording, stopping previous recording...');
        await stopRecording();
      }

      // Check microphone permission (this will trigger OS permission dialog on desktop)
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone access denied by user');
        return false;
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${tempDir.path}/medical_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Configure recording with optimal settings for medical speech recognition
      final recordConfig = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // Google Speech optimal sample rate
        bitRate: 256000, // Higher bit rate for better quality
        numChannels: 1, // Mono for better recognition
        autoGain: true, // Automatic gain control for consistent volume
        echoCancel: true, // Echo cancellation for better audio quality
        noiseSuppress: true, // Noise suppression for cleaner audio
        // Use preferred device if specified and available
        device: preferredDeviceId != null
            ? _availableDevices.firstWhere(
                (device) => device.id == preferredDeviceId,
                orElse: () => _availableDevices.isNotEmpty
                    ? _availableDevices.first
                    : const InputDevice(id: '', label: ''),
              )
            : null,
      );

      // Start recording
      await _audioRecorder.start(recordConfig, path: _currentRecordingPath!);

      debugPrint('Recording started: $_currentRecordingPath');
      debugPrint('Using device: ${recordConfig.device?.label ?? "Default"}');

      return true;
    } catch (e) {
      debugPrint('Failed to start recording: $e');

      // Try fallback recording with minimal config if enhanced config fails
      if (e.toString().contains('device') || e.toString().contains('config')) {
        return await _startFallbackRecording();
      }

      return false;
    }
  }

  Future<bool> _startFallbackRecording() async {
    try {
      debugPrint('Attempting fallback recording with basic configuration...');

      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${tempDir.path}/medical_recording_fallback_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Basic configuration that should work on all platforms
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      debugPrint('Fallback recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Fallback recording also failed: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!await _audioRecorder.isRecording()) {
        debugPrint('Not currently recording');
        return null;
      }

      final recordingPath = await _audioRecorder.stop();
      debugPrint('Recording stopped: $recordingPath');

      if (recordingPath != null && _speechApi != null) {
        return await _transcribeAudio(recordingPath);
      }

      return null;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      return null;
    }
  }

  Future<String?> _transcribeAudio(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (!audioFile.existsSync()) {
        debugPrint('Audio file does not exist: $audioPath');
        return null;
      }

      // Read audio file as bytes
      final audioBytes = await audioFile.readAsBytes();
      debugPrint('Audio file size: ${audioBytes.length} bytes');

      // Check if audio file is too small (likely silence)
      if (audioBytes.length < 1000) {
        debugPrint('Audio file too small, likely silence');
        return 'No speech detected - audio too short';
      }

      // Enhanced configuration optimized for medical terminology
      final recognitionRequest = speech.RecognizeRequest()
        ..config = (speech.RecognitionConfig()
          ..encoding = 'LINEAR16'
          ..sampleRateHertz = 16000
          ..languageCode = 'en-US'
          // Try medical_dictation model first, fallback to latest_long
          ..model = 'medical_dictation'
          ..useEnhanced = true // Enhanced model for better accuracy
          ..enableAutomaticPunctuation = true
          ..enableWordTimeOffsets = false
          ..maxAlternatives = 3 // Get multiple alternatives
          ..profanityFilter = false
          ..enableWordConfidence = true // Get confidence per word
          // Enhanced speech contexts for medical terminology
          ..speechContexts = [
            speech.SpeechContext()
              ..phrases = _medicalPhrases
              ..boost = 20.0 // High boost for medical terms
          ]
          // Audio adaptation for better recognition
          ..adaptation = (speech.SpeechAdaptation()
            ..phraseSets = [
              speech.PhraseSet()
                ..phrases = _medicalPhrases
                    .map((phrase) => speech.Phrase()..value = phrase)
                    .toList()
                ..boost = 20.0
            ]))
        ..audio =
            (speech.RecognitionAudio()..content = base64Encode(audioBytes));

      debugPrint(
          'Sending enhanced transcription request to Google Speech API...');
      debugPrint(
          'Using medical_dictation model with ${_medicalPhrases.length} medical phrases');

      try {
        // Send recognition request
        final response = await _speechApi!.speech.recognize(recognitionRequest);
        return _processTranscriptionResponse(response, audioFile);
      } catch (e) {
        // If medical model fails, try with general model
        debugPrint('Medical model failed, trying general model: $e');
        return await _transcribeWithFallbackModel(audioBytes, audioFile);
      }
    } catch (e) {
      debugPrint('Transcription failed with error: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // Clean up temp file on error
      try {
        final audioFile = File(audioPath);
        if (audioFile.existsSync()) {
          await audioFile.delete();
        }
      } catch (cleanupError) {
        debugPrint('Failed to cleanup temp file: $cleanupError');
      }

      return 'Transcription error: ${e.toString()}';
    }
  }

  Future<String?> _transcribeWithFallbackModel(
      List<int> audioBytes, File audioFile) async {
    try {
      debugPrint('Attempting transcription with fallback model...');

      // Simplified configuration that works universally
      final fallbackRequest = speech.RecognizeRequest()
        ..config = (speech.RecognitionConfig()
          ..encoding = 'LINEAR16'
          ..sampleRateHertz = 16000
          ..languageCode = 'en-US'
          ..model = 'latest_long' // General model
          ..useEnhanced = false // Disable enhanced for compatibility
          ..enableAutomaticPunctuation = true
          ..maxAlternatives = 1
          ..profanityFilter = false
          // Reduced medical terms for compatibility
          ..speechContexts = [
            speech.SpeechContext()
              ..phrases = _medicalPhrases.take(20).toList()
              ..boost = 10.0
          ])
        ..audio =
            (speech.RecognitionAudio()..content = base64Encode(audioBytes));

      final response = await _speechApi!.speech.recognize(fallbackRequest);
      return _processTranscriptionResponse(response, audioFile);
    } catch (e) {
      debugPrint('Fallback transcription also failed: $e');

      // Final attempt with minimal configuration
      return await _transcribeWithMinimalConfig(audioBytes, audioFile);
    }
  }

  Future<String?> _transcribeWithMinimalConfig(
      List<int> audioBytes, File audioFile) async {
    try {
      debugPrint('Attempting transcription with minimal configuration...');

      // Minimal configuration for maximum compatibility
      final minimalRequest = speech.RecognizeRequest()
        ..config = (speech.RecognitionConfig()
          ..encoding = 'LINEAR16'
          ..sampleRateHertz = 16000
          ..languageCode = 'en-US')
        ..audio =
            (speech.RecognitionAudio()..content = base64Encode(audioBytes));

      final response = await _speechApi!.speech.recognize(minimalRequest);
      return _processTranscriptionResponse(response, audioFile);
    } catch (e) {
      debugPrint('Minimal transcription failed: $e');

      // Clean up temp file
      try {
        await audioFile.delete();
      } catch (cleanupError) {
        debugPrint('Failed to cleanup temp file: $cleanupError');
      }

      return 'All transcription attempts failed: $e';
    }
  }

  String? _processTranscriptionResponse(
      speech.RecognizeResponse response, File audioFile) {
    debugPrint('Processing transcription response...');
    debugPrint('Response results count: ${response.results?.length ?? 0}');

    // Process response
    if (response.results != null && response.results!.isNotEmpty) {
      final result = response.results!.first;
      debugPrint(
          'First result alternatives count: ${result.alternatives?.length ?? 0}');

      if (result.alternatives != null && result.alternatives!.isNotEmpty) {
        final alternatives = result.alternatives!;

        // Get the best alternative
        final bestAlternative = alternatives.first;
        final transcript = bestAlternative.transcript ?? '';
        final confidence = bestAlternative.confidence ?? 0.0;

        debugPrint('Transcription successful:');
        debugPrint('Text: "$transcript"');
        debugPrint('Confidence: ${(confidence * 100).toStringAsFixed(1)}%');

        // Log all alternatives for debugging
        for (int i = 0; i < alternatives.length; i++) {
          final alt = alternatives[i];
          debugPrint(
              'Alternative $i: "${alt.transcript}" (confidence: ${((alt.confidence ?? 0.0) * 100).toStringAsFixed(1)}%)');
        }

        // Clean up temporary audio file
        try {
          audioFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp audio file: $e');
        }

        // Return transcript if it's meaningful, otherwise indicate no speech
        return transcript.trim().isNotEmpty
            ? transcript.trim()
            : 'No clear speech detected';
      }
    }

    debugPrint('No transcription results received');

    // Clean up temp file
    try {
      audioFile.delete();
    } catch (e) {
      debugPrint('Failed to delete temp audio file: $e');
    }

    return 'No speech detected in audio';
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  Future<List<InputDevice>> getAvailableAudioDevices() async {
    try {
      _availableDevices = await _audioRecorder.listInputDevices();
      return _availableDevices;
    } catch (e) {
      debugPrint('Failed to get audio devices: $e');
      return [];
    }
  }

  Future<void> dispose() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
      await _audioRecorder.dispose();

      // Clean up temporary recording file if exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      _isInitialized = false;
      debugPrint('Google Speech-to-Text service disposed');
    } catch (e) {
      debugPrint('Error disposing Google Speech-to-Text service: $e');
    }
  }

  // Method to test with a simple configuration
  Future<String?> testTranscription(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (!audioFile.existsSync()) {
        debugPrint('Test audio file does not exist: $audioPath');
        return null;
      }

      final audioBytes = await audioFile.readAsBytes();
      debugPrint(
          'Test transcription - Audio file size: ${audioBytes.length} bytes');

      // Minimal configuration for testing
      final recognitionRequest = speech.RecognizeRequest()
        ..config = (speech.RecognitionConfig()
          ..encoding = 'LINEAR16'
          ..sampleRateHertz = 16000
          ..languageCode = 'en-US')
        ..audio =
            (speech.RecognitionAudio()..content = base64Encode(audioBytes));

      debugPrint('Sending test transcription request...');

      final response = await _speechApi!.speech.recognize(recognitionRequest);

      debugPrint('Test response received');
      debugPrint('Results: ${response.results?.length ?? 0}');

      if (response.results != null && response.results!.isNotEmpty) {
        final result = response.results!.first;
        if (result.alternatives != null && result.alternatives!.isNotEmpty) {
          final transcript = result.alternatives!.first.transcript ?? '';
          debugPrint('Test transcription result: "$transcript"');
          return transcript;
        }
      }

      return 'No results from test transcription';
    } catch (e) {
      debugPrint('Test transcription failed: $e');
      return 'Test failed: $e';
    }
  }

  // Method to add custom medical vocabulary dynamically
  Future<void> addMedicalVocabulary(List<String> medicalTerms) async {
    debugPrint('Adding custom medical vocabulary: $medicalTerms');
    // In a real implementation, you could extend the _medicalPhrases list
    // or create patient-specific phrase sets
  }

  // Method to get available models
  Future<List<String>> getAvailableModels() async {
    try {
      if (_speechApi == null) return [];

      // Return models that are known to work well for medical transcription
      return [
        'medical_dictation',
        'medical_conversation',
        'latest_long',
        'latest_short',
        'command_and_search',
        'phone_call',
        'video'
      ];
    } catch (e) {
      debugPrint('Failed to get available models: $e');
      return [];
    }
  }

  // Method to check if service account has proper permissions
  Future<bool> validateServiceAccount() async {
    try {
      if (_speechApi == null) {
        debugPrint('Speech API not initialized');
        return false;
      }

      // Create a minimal test audio file
      final tempDir = await getTemporaryDirectory();
      final testPath = '${tempDir.path}/test_validation.wav';

      // Create a minimal WAV file for testing (header + 1 second of silence)
      final testFile = File(testPath);
      final wavHeader = [
        // RIFF header
        0x52, 0x49, 0x46, 0x46, 0x24, 0x08, 0x00, 0x00,
        // WAVE format
        0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20,
        // Format chunk
        0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
        0x00, 0x3E, 0x00, 0x00, 0x00, 0x7C, 0x00, 0x00,
        0x02, 0x00, 0x10, 0x00, 0x64, 0x61, 0x74, 0x61,
        // Data chunk (1 second of silence at 16kHz)
        0x00, 0x08, 0x00, 0x00,
        // Silent audio data (16000 samples * 2 bytes = 32000 bytes of zeros)
        ...List.filled(32000, 0),
      ];

      await testFile.writeAsBytes(wavHeader);

      final result = await testTranscription(testPath);

      // Clean up test file
      try {
        await testFile.delete();
      } catch (e) {
        debugPrint('Failed to delete test file: $e');
      }

      final isValid = result != null &&
          !result.contains('failed') &&
          !result.contains('error');
      debugPrint(
          'Service account validation result: $result (valid: $isValid)');
      return isValid;
    } catch (e) {
      debugPrint('Service account validation failed: $e');
      return false;
    }
  }

  // Method to get recording statistics
  Map<String, dynamic> getRecordingStats() {
    return {
      'isInitialized': _isInitialized,
      'currentRecordingPath': _currentRecordingPath,
      'availableDevices': _availableDevices.length,
      'medicalPhrasesCount': _medicalPhrases.length,
    };
  }

  // Method to check audio device connectivity (useful for Bluetooth devices)
  Future<bool> isAudioDeviceConnected(String deviceId) async {
    try {
      final devices = await getAvailableAudioDevices();
      return devices.any((device) => device.id == deviceId);
    } catch (e) {
      debugPrint('Failed to check device connectivity: $e');
      return false;
    }
  }
}
