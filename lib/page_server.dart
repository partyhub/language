import 'dart:html' as html;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lan_tools/table_1.dart';

import 'Toast.dart';

class PageServer extends StatefulWidget{

  PageServer({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PageServerState();
  }

}

class PageServerState extends State<PageServer>{

  bool _imported = false;

  bool _isLoading = true;


  Archive archive;

  List<ArchiveFile> archiveFiles;


  @override
  void initState() {
    super.initState();
    archiveFiles = [];
  }

  @override
  Widget build(BuildContext context) {
    if(!_imported){
      return _buildImport();
    }
    return _isLoading?Center(child: CircularProgressIndicator()): LanServerTable(archiveFiles, _onLanSaveCallback);
  }

  Widget _buildImport() {
    return Center(
      child: FlatButton.icon(
          icon: Icon(Icons.cloud_upload,size: 48,),
          label: Text('导入zip文件',style: TextStyle(fontSize: 20),),
          onPressed: (){
            setState(() {
              _startFilePicker();
            });
          }
      ),
    );
  }

  _startFilePicker() async {
    _isLoading = true;
    _imported = true;
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files.length == 1) {
        final file = files[0];
        html.FileReader reader =  html.FileReader();
        reader.onLoadEnd.listen((e) {
          setState(() {
            print("loaded: ${file.name}");
            print("type: ${reader.result.runtimeType}");
            unzip(reader.result);
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            Toast.show("Some Error occured while reading the file", context);
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  void unzip(Uint8List uploadFile) {
    archive = ZipDecoder().decodeBytes(uploadFile);
    for (ArchiveFile archiveFile in archive) {
       if(archiveFile.isFile){
         archiveFiles.add(archiveFile);
       }
    }
    _isLoading = false;
  }



  _onLanSaveCallback(String key, List<ArchiveFile> files) {
    archiveFiles = files;
    print("_onLanSaveCallback- key-> $key");
    print("_onLanSaveCallback- files-> ${files.toString()}");
    for(int i=0;i<archive.length;i++){
      ArchiveFile archiveFile = archive[i];
      for(ArchiveFile af in files){
        if(af.name == archiveFile.name){
          archive.files[i] = af;
        }
      }
    }
  }

  void save(){
    List<int> encodeZip = ZipEncoder().encode(archive);
    final blob = html.Blob([encodeZip]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    DateTime now = DateTime.now();
    String nowTime = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";

    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'trans_server_$nowTime.zip';
    html.document.body.children.add(anchor);
    anchor.click();
  }
}