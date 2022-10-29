import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image/image.dart' as Img;
import 'package:image_to_text/texted_screen.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImageCropper',
      // theme: ThemeData.light().copyWith(primaryColor: Colors.indigoAccent),
      home: MyHomePage(
        title: 'ImageCropper',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({required this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum AppState {
  free,
  picked,
  cropped,
}

class _MyHomePageState extends State<MyHomePage> {
  late bool? isLoaded;
  late AppState state;
  File? imageFile;
  double? _maxHeight = 500;
  double? _maxWidth = 500;
  double _txtimgHeight = 1;
  double _txtimgWidth = 1;
  double _contrast = 130;
  bool _reverse = false;
  Img.Image? passImage;

  @override
  void initState() {
    super.initState();

    state = AppState.free;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: imageFile != null
              ? Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * .65,
                      width: double.infinity,
                      child: Image.file(
                        imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              Text('세로'),
                              Expanded(
                                child: Slider(
                                    activeColor: Colors.cyanAccent,
                                    value: _txtimgHeight,
                                    max: _maxHeight!,
                                    divisions: _maxHeight! ~/ 4,
                                    label: '${_txtimgHeight.round()}',
                                    onChanged: (double value) {
                                      setState(() {
                                        _txtimgHeight = value;
                                      });
                                    }),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              Text('가로'),
                              Expanded(
                                child: Slider(
                                    activeColor: Colors.cyanAccent,
                                    value: _txtimgWidth,
                                    max: _maxWidth!,
                                    divisions: _maxWidth! ~/ 4,
                                    label: '${_txtimgWidth.round()}',
                                    onChanged: (double value) {
                                      setState(() {
                                        _txtimgWidth = value;
                                      });
                                    }),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              Text('명암'),
                              Expanded(
                                child: Slider(
                                    activeColor: Colors.cyanAccent,
                                    value: _contrast,
                                    max: 255,
                                    divisions: 255,
                                    label: '${_contrast.round()}',
                                    onChanged: (double value) {
                                      setState(() {
                                        _contrast = value;
                                      });
                                    }),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("반전"),
                                    SizedBox(width: 10),
                                    Switch(
                                        activeColor: Colors.cyanAccent,
                                        value: _reverse,
                                        onChanged: (bool value) {
                                          setState(() {
                                            _reverse = value;
                                          });
                                        }),
                                  ],
                                ),
                              ),
                              Text(
                                  "예상 글자수:${(_txtimgHeight * _txtimgWidth) ~/ 8}"),
                              ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.cyanAccent)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => TextedImg(
                                              imageFile: imageFile,
                                              contrast: _contrast,
                                              reverse: _reverse,
                                              txtimgHeight: _txtimgHeight,
                                              txtimgWidth: _txtimgWidth)),
                                    );
                                  },
                                  child: Text(
                                    '텍스토로 변환',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  )),
                              SizedBox(
                                width: 1,
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                )
              : Container(child: Text("사진을 업로드 해주세요")),
        ),
      ),
      floatingActionButton: SpeedDial(
        marginBottom:
            imageFile != null ? MediaQuery.of(context).size.height * .35 : 16,
        icon: Icons.add,
        activeIcon: Icons.remove,
        backgroundColor: Colors.cyanAccent,
        overlayColor: Colors.black,
        overlayOpacity: 0,
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera),
            backgroundColor: Colors.cyanAccent,
            label: 'Camera',
            labelStyle: TextStyle(fontSize: 18.0),
            labelBackgroundColor: Colors.white,
            onTap: () => _pickImage(true),
          ),
          SpeedDialChild(
            child: Icon(Icons.image),
            backgroundColor: Colors.cyanAccent,
            label: 'Gallery',
            labelStyle: TextStyle(fontSize: 18.0),
            labelBackgroundColor: Colors.white,
            onTap: () => _pickImage(false),
          ),
        ],
      ),
    );
  }

  Future<Null> _pickImage(bool isCamera) async {
    final pickedImage = await ImagePicker()
        .getImage(source: isCamera ? ImageSource.camera : ImageSource.gallery);
    imageFile = pickedImage != null ? File(pickedImage.path) : null;
    if (imageFile != null) {
      _cropImage();
      setState(() {
        state = AppState.picked;
      });
    }
  }

  Future<Null> _cropImage() async {
    File? croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile!.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.cyanAccent,
            cropFrameColor: Colors.cyanAccent,
            activeControlsWidgetColor: Colors.cyanAccent,
            statusBarColor: Colors.cyanAccent,
            // color
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      setState(() {
        imageFile = croppedFile;
        _maxHeight =
            ImageSizeGetter.getSize(FileInput(imageFile!)).height.toDouble();
        _maxWidth =
            ImageSizeGetter.getSize(FileInput(imageFile!)).width.toDouble();
        _txtimgHeight = 1;
        _txtimgWidth = 1;
        if (_maxHeight! > 800) {
          _maxHeight = 800;
        }
        if (_maxWidth! > 800) {
          _maxWidth = 800;
        }
        if (_maxHeight! % 4 != 0) {
          print(_maxHeight);
          _maxHeight = _maxHeight! - (_maxHeight! % 4);
          print(_maxHeight);
        }
        if (_maxWidth! % 2 != 0) {
          _maxWidth = _maxWidth! - (_maxWidth! % 2);
        }
      });
    }
  }
}

void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      textColor: Colors.black,
      backgroundColor: Colors.cyanAccent,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP);
}
