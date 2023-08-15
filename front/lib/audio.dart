import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:html' as html;
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onRecordDone;

  const AudioRecorder({Key? key, required this.onRecordDone}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState(onRecordDone);
}

class _AudioRecorderState extends State<AudioRecorder> {
  final _audioRecorder = Record();
  final void Function(String path) onRecordDone;
  bool _isRecording = false;

  _AudioRecorderState(this.onRecordDone);

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 마이크 권한 요청 및 음성 크기 변경 감지
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermission();
    await _initializeSpeechRecognition();

  }

  // 마이크 권한 요청
  Future<void> _requestPermission() async {
    if (kIsWeb) {
      // 웹 환경에서 마이크 권한 요청
      await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
    } else {
      // 모바일 환경에서 마이크 권한 요청
      await Permission.microphone.request();
    }
  }

  Future<void> _initializeSpeechRecognition() async {
    var _speech = stt.SpeechToText();
    void _listen() async {
      await _speech.initialize();
      if (!_isRecording) {
        await _recordstart();
      }
      await _speech.listen(
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 2),
        cancelOnError: false,
        partialResults: true,
        onResult: (result) async {
          print(result);
          if (result.finalResult) {
            await _recordstop();
          }
        },
      );
    }
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!_speech.isListening) {
        _recordstop();
        _listen();
      }
    });
  }

  // 녹음 시작
  Future<void> _recordstart() async {
    await _audioRecorder.start();
    setState(() => _isRecording = true);
  }

  // 녹음 중지
  Future<void> _recordstop() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      onRecordDone(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // UI가 필요하지 않으므로 빈 컨테이너 반환
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<void> _postAudio(String path) async {
    print('Recorded file path: $path');
    /*
    var url = Uri.http('ec2-13-124-131-230.ap-northeast-2.compute.amazonaws.com:3033', '/audio2Text');
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('audio', path));
    var response = await request.send();
    print(response);
    */
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AudioRecorder(
          onRecordDone: (path) => _postAudio(path),
        ),
      ),
    );
  }
}