import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:rhino_flutter/rhino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Tensorflow'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    _initPicovoice();
    super.initState();
  }

  String text = 'Say:"Listen" to enable mic';
  bool enable = false;
  late String asset;
  final String accessKey =
      "dTtwP20arB2VUWU36g5ukw0aaxVXaeV1Wj+7jsNYREJo8OuoC3PgtQ=="; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)
  PicovoiceManager? _picovoiceManager;

  bool _isError = false;
  String _errorMessage = "";
  bool _listeningForCommand = false;
  void _initPicovoice() async {
    String platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : throw PicovoiceRuntimeException(
                "This demo supports iOS and Android only.");
    String keywordAsset = "assets/$platform/Listen_en_android_v2_1_0.ppn";
    String contextAsset = "assets/$platform/MySpeech_en_android_v2_1_0.rhn";

    try {
      _picovoiceManager = await PicovoiceManager.create(accessKey, keywordAsset,
          _wakeWordCallback, contextAsset, _inferenceCallback,
          processErrorCallback: _errorCallback);
      await _picovoiceManager?.start();
    } on PicovoiceInvalidArgumentException catch (ex) {
      _errorCallback(PicovoiceInvalidArgumentException(
          "${ex.message}\nEnsure your accessKey '$accessKey' is a valid access key."));
    } on PicovoiceActivationException {
      _errorCallback(
          PicovoiceActivationException("AccessKey activation error."));
    } on PicovoiceActivationLimitException {
      _errorCallback(PicovoiceActivationLimitException(
          "AccessKey reached its device limit."));
    } on PicovoiceActivationRefusedException {
      _errorCallback(PicovoiceActivationRefusedException("AccessKey refused."));
    } on PicovoiceActivationThrottledException {
      _errorCallback(PicovoiceActivationThrottledException(
          "AccessKey has been throttled."));
    } on PicovoiceException catch (ex) {
      _errorCallback(ex);
    }
  }

  void _errorCallback(PicovoiceException error) {
    setState(() {
      _isError = true;
      _errorMessage = error.message!;
    });
  }

  void _wakeWordCallback() {
    setState(() {
      _listeningForCommand = true;
    });
  }

  void _inferenceCallback(RhinoInference inference) {
    if (inference.isUnderstood!) {
      if (inference.intent == 'Hello') {
        setState(() {
          asset = 'assets/picture/fine.jpg';
          enable = true;
          _listeningForCommand = false;
        });
      } else if (inference.intent == 'name') {
        asset = 'assets/picture/robot.jpg';
        enable = true;
        _listeningForCommand = false;
        setState(() {});
      } else if (inference.intent == 'Bye') {
        setState(() {
          asset = 'assets/picture/Bye.jpg';
          enable = true;
          _listeningForCommand = false;
        });
      }
    } else {
      setState(() {
        _listeningForCommand = false;
        enable = false;
        text = 'I am not train for this';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            enable
                ? SizedBox(
                    height: 200,
                    width: 300,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.fill,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(fontSize: 20),
                  ),
            const SizedBox(
              height: 50,
            ),
            CircleAvatar(
              backgroundColor: Colors.cyan,
              radius: 50,
              child: Icon(
                Icons.mic,
                color: _listeningForCommand ? Colors.green : Colors.red,
                size: 40,
              ),
            )
          ],
        ),
      ),
    );
  }
}
