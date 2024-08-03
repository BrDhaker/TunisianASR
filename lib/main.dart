import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'dart:io';

import 'UI/buttons_UI.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  void _toggleTheme(bool value) {
    setState(() {
      _isDark = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: AudioTranscriptionScreen(
        isDark: _isDark,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

class AudioTranscriptionScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) toggleTheme;

  AudioTranscriptionScreen({required this.isDark, required this.toggleTheme});
  @override
  _AudioTranscriptionScreenState createState() =>
      _AudioTranscriptionScreenState();
}

class _AudioTranscriptionScreenState extends State<AudioTranscriptionScreen> {
  String _transcriptionText = '';
  bool _isRecording = false;
  String? _recordedFilePath;
  String? _uploadedFilePath;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _requestPermissions();
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  Future<void> _recordAudio() async {
    if (_recorder.isRecording) {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/temp_audio.aac';

      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedFilePath = tempPath;
        _uploadedFilePath = null;  // Clear the uploaded file path
        print('Recording stopped. File saved at: $tempPath');
      });
    } else {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/temp_audio.aac';

      await _recorder.startRecorder(
        toFile: tempPath,
        codec: Codec.aacADTS,
      );
      setState(() {
        _isRecording = true;
        _uploadedFilePath = null;  // Clear the uploaded file path
        print('Recording started...');
      });
    }
  }

  Future<void> _uploadAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null) {
      String? filePath = result.files.single.path;
      setState(() {
        _uploadedFilePath = filePath;
        _recordedFilePath = null;  // Clear the recorded file path
        print('File selected: $filePath');
      });
    } else {
      print('File selection canceled.');
    }
  }

  Future<String?> _transcribeAudio(String filePath) async {
    var apiUrl = "";
    var headers = {"Content-Type": "application/json"};

    // Read the contents of your local audio file
    var file = File(filePath);
    var fileBytes = await file.readAsBytes();
    var base64Audio = base64Encode(fileBytes);

    var body = jsonEncode({
      "data": [
        {"name": "audio.wav", "data": "data:audio/wav;base64,$base64Audio"},
        {"name": "audio.wav", "data": "data:audio/wav;base64,$base64Audio"}

      ]
    });

    try {
      var response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

      // Setting response encoding to UTF-8
      var utf8decoder = Utf8Decoder();
      var responseBody = utf8decoder.convert(response.bodyBytes);

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        var transcription = jsonDecode(responseBody)["data"][0];
        return transcription;
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      print('Error: $e');
      throw Exception("Error: $e");
    }
  }

  Future<void> _testTranscription() async {
    String? filePath;
    if (_uploadedFilePath != null) {
      filePath = _uploadedFilePath;
    } else if (_recordedFilePath != null) {
      filePath = _recordedFilePath;
    }

    if (filePath != null) {
      try {
        String? transcription = await _transcribeAudio(filePath);

        setState(() {
          _transcriptionText = transcription ?? 'Transcription failed.';
          print('Transcription: $_transcriptionText');
        });
      } catch (e) {
        setState(() {
          _transcriptionText = 'Transcription failed due to error: $e';
        });
      }
    } else {
      print('No audio file available for transcription.');
    }
  }

  Future<void> _playAudio() async {
    String? filePath = _uploadedFilePath ?? _recordedFilePath;
    if (filePath != null) {
      if (_player.isPlaying) {
        await _player.stopPlayer();
        setState(() {
          print('Playback stopped.');
        });
      } else {
        await _player.startPlayer(
          fromURI: filePath,
          codec: Codec.aacADTS,
          whenFinished: () {
            setState(() {
              print('Playback finished.');
            });
          },
        );
        setState(() {
          print('Playback started.');
        });
      }
    } else {
      print('No audio file available for playback.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          DayNightSwitcher(
            isDarkModeEnabled: widget.isDark,
            onStateChanged: widget.toggleTheme,
          ),
        ],
        title: Text('Audio Transcription'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextField(
              readOnly: true,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Transcription will appear here',
              ),
              controller: TextEditingController(text: _transcriptionText),
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                customButton(context, _recordAudio, _isRecording ? 'Recording...' : 'Record Audio', Icon(Icons.record_voice_over)),
                customButton(context, _uploadAudio, 'Upload Audio', Icon(Icons.upload_file_rounded)),
                customButton(context, _testTranscription, 'Test Transcription', Icon(Icons.textsms_rounded)),
                customButton(context, _playAudio, _player.isPlaying ? 'Stop Playback' : 'Play Audio', Icon(Icons.play_circle_fill_rounded)),
              ],
            ),

          ],
        ),
      ),
    );
  }


}
