import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'dart:io';
import 'package:image/image.dart' as Img;
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:async';

class TextedImg extends StatefulWidget {
  final File? imageFile;
  final double? txtimgHeight;
  final double? txtimgWidth;
  final double? contrast;
  final bool? reverse;

  TextedImg({
    @required this.imageFile,
    @required this.contrast,
    @required this.reverse,
    @required this.txtimgHeight,
    @required this.txtimgWidth,
  });

  @override
  _TextedImgState createState() => _TextedImgState();
}

class _TextedImgState extends State<TextedImg> {
  String? mainString;
  Img.Image? thumnail;
  List<int> lumilist = [];
  bool ready = false;
  @override
  void initState() {
    // TODO: implement initState

    changeToText();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (mainString != null) {
      return Scaffold(
          appBar: AppBar(
            title: Text("변환된 이미지"),
            backgroundColor: Colors.cyanAccent,
          ),
          body: ready
              ? SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: InteractiveViewer(
                            clipBehavior: Clip.none,
                            maxScale: 20,
                            minScale: 0.5,
                            child: Container(
                              margin: EdgeInsets.all(10),
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: SelectableText(
                                  mainString!,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            "글자수: ${mainString!.length}",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  showToast("글자수를 줄였습니다");
                                  reduceText();
                                },
                                icon: Icon(Icons.arrow_drop_down),
                                label: Text("글자수감소"),
                              ),
                              Spacer(),
                              TextButton.icon(
                                  onPressed: () {
                                    showToast("복사완료되었습니다");
                                    Clipboard.setData(
                                        ClipboardData(text: mainString));
                                  },
                                  icon: Icon(Icons.copy),
                                  label: Text("복사"))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : Container(child: Text("Error")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("정보를 불러오는데 실패했습니다"),
      ),
    );
  }

  Future<Null> reduceText() async {
    var stringlist = [];
    String reducedstr = "";
    if (mainString != null) {
      stringlist = mainString!.split("\n");
      for (String str in stringlist) {
        // print(str);
        // print(str.length);
        if (str.length != 0) {
          reducedstr += removeTrailing("⠀", str) + "\n";
        }
      }
    }
    print(reducedstr);
    setState(() {
      mainString = reducedstr;
    });
    // mainString = reducedstr;
  }

  String removeTrailing(String pattern, String from) {
    print(from.length);
    int i = from.length;
    while (from.startsWith(pattern, i - pattern.length) && i > 1)
      i -= pattern.length;
    return from.substring(0, i);
  }

  Future<Null> changeToText() async {
    String temp = "";
    if (widget.imageFile != null) {
      int width = widget.txtimgWidth!.toInt();
      int height = widget.txtimgHeight!.toInt();
      var reImage = Img.decodeImage(widget.imageFile!.readAsBytesSync());
      thumnail = Img.copyResize(reImage!, width: width, height: height);
      lumilist = await imgToGrayList(
          myimg: thumnail!,
          brightness: widget.contrast!.toInt(),
          reverse: widget.reverse!);
      temp = await toText(lumilist, width, height);
      // setState(() {
      //   mainString = temp;
      // });
      mainString = temp;
      setState(() {
        ready = true;
      });
    }
  }

  Future<String> toText(List<int> pixs, int width, int height) async {
    String str = "";

    int blockline = height ~/ 4; //4 is constant
    int cnt = 0;
    for (int i = 0; i < blockline; i++) {
      for (int n = 0; n < width; n += 2) {
        cnt = i * 4;
        int index1 = (cnt * width) + n;
        int index2 = ((cnt + 1) * width) + n;
        int index3 = ((cnt + 2) * width) + n;
        int index4 = (cnt * width) + n + 1;
        int index5 = (((cnt + 1) * width) + n) + 1;
        int index6 = (((cnt + 2) * width) + n) + 1;
        int index7 = ((cnt + 3) * width) + n;
        int index8 = (((cnt + 3) * width) + n) + 1;
        List<int> temp = [
          pixs[index1],
          pixs[index2],
          pixs[index3],
          pixs[index4],
          pixs[index5],
          pixs[index6],
          pixs[index7],
          pixs[index8],
        ];
        str += toBraill(temp);
      }
      str += "\n";
    }

    return str;
  }

  String toBraill(List<int> mlist) {
    var l = 10240;
    if (mlist[0] == 1) l += 1;
    if (mlist[1] == 1) l += 2;
    if (mlist[2] == 1) l += 4;
    if (mlist[3] == 1) l += 8;
    if (mlist[4] == 1) l += 16;
    if (mlist[5] == 1) l += 32;
    if (mlist[6] == 1) l += 64;
    if (mlist[7] == 1) l += 128;
    // if (l == 10240) return "  ";
    return String.fromCharCode(l);
  }

  Future<List<int>> imgToGrayList(
      {required Img.Image myimg,
      int brightness = 130,
      bool reverse = false}) async {
    List<int> graylist = [];
    Img.grayscale(myimg);
    Uint8List imgbyte = myimg.getBytes();

    for (int i = 0; i < imgbyte.length; i += 4) {
      if (imgbyte[i] < brightness) {
        graylist.add(reverse ? 0 : 1);
      } else {
        graylist.add(reverse ? 1 : 0);
      }
    }
    return graylist;
  }
}

void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      textColor: Colors.black,
      backgroundColor: Colors.cyanAccent,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP);
}

String getRewardedAdID() {
  if (Platform.isIOS) {
    return 'ca-app-pub-3940256099942544/4411468910';
  }
  return 'ca-app-pub-3940256099942544/5354046379';
}
