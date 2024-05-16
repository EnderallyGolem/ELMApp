import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '/util_classes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

dynamic importedFile;
String importedFileName = "egypt1";
const JsonEncoder jsonEncoder = JsonEncoder.withIndent('    ');

class ProviderMiscState extends ChangeNotifier {
  static dynamic levelCode;
  static String levelJson = '';
  static bool updateCode = true;

  void updateMiscState(){
    getCodeShown();                                       //Gets the displayed code from main.dart
    notifyListeners();                                    //Updates the displayed misc UI state
  }

  static void getCodeShown(){
    levelCode = ProviderMainState.levelCode;
    levelJson = jsonEncoder.convert((levelCode['objects'])); //Obviously has to be changed in the future
  }
}

class Page_Misc extends StatefulWidget {
  @override
  _Page_MiscState createState() => _Page_MiscState();
}
class _Page_MiscState extends State<Page_Misc> {

  @override
  void initState() {
    ProviderMiscState.updateCode = true;
  }

  @override
  Widget build(BuildContext context) {
    var appMainState = context.watch<ProviderMainState>();
    var appMiscState = context.watch<ProviderMiscState>();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if(ProviderMiscState.updateCode){
        appMiscState.updateMiscState(); //Update state the first time it is loaded. Such a dumb workaround...
        ProviderMiscState.updateCode = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Misc'),
        backgroundColor: Color.fromARGB(255, 249, 218, 175),
        foregroundColor: Color.fromARGB(169, 105, 64, 3),
        actions: [],
      ),
      body: ListView(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  requestAndriodPermissions();
                  _importFile(context: context, appMainState: appMainState, appMiscState: appMiscState);
                  appMiscState.updateMiscState();
                },
                child: Text('Import Level'),
              ),
              ElevatedButton(
                onPressed: () {
                  addLevelCodeToClipboard(context, ProviderMiscState.levelJson);
                },
                child: Icon(Icons.copy),
              ),
              ElevatedButton(
                onPressed: () {
                  requestAndriodPermissions();
                  _exportFile(context, ProviderMiscState.levelJson);
                },
                child: Text('Export Level'),
              ),
            ]
          ),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(255, 180, 180, 1),
                ),
                onPressed: () {
                  Get.defaultDialog(title: 'Reset level?', middleText: 'This will clear all data in the level.\nAre you sure about this?', textCancel: 'Cancel', textConfirm: 'Reset level!', onConfirm: (){
                    Get.back();
                    Get.defaultDialog(title: 'Reset level?', middleText: "Are you absolutely sure?!\nThere's no undo button!", textCancel: 'Cancel', textConfirm: 'Reset it!!!!', 
                    onConfirm: (){
                      ProviderMainState.resetLevelCode();
                      appMiscState.updateMiscState();
                      Get.back();
                    },
                  );
                  });
                },
                child: Text('Reset Level'),
              ),
            ],
          ),
          Text(ProviderMiscState.levelJson),
        ]
      )
    );
  }
}

void _importFile({required dynamic context, required ProviderMainState appMainState, required ProviderMiscState appMiscState}) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json', 'txt'],
    allowMultiple: false,
    dialogTitle: 'Level File',
    withReadStream: false,
    withData: true,
  );
  if (result != null) {
    try{
        PlatformFile file = result.files.single;
        String fileContent = utf8.decode(file.bytes!);
        String importedFileDirectory = file.path!;
        dynamic importedFile = jsonDecode(fileContent);
        importedFileName = file.name;
        // print('Imported File name: $importedFileName');
        // print('Imported Directory: $importedFileDirectory');
        // print('importedFile["objects"][0]["objdata"]["ResourceGroupNames"] = ${importedFile["objects"][0]["objdata"]["ResourceGroupNames"]}');
        ProviderMainState.importLevelCode(importedCode: importedFile);
        appMiscState.updateMiscState();
      } catch (e) {
        Get.defaultDialog(title: "Error", middleText: "Something went wrong! The file's json format might not be correct!\n\n$e", textCancel: 'Ok');
        ProviderMainState.resetLevelCode(); //Clear level code to prevent errors
        appMiscState.updateMiscState();
    }
  }
} 

void _exportFile(BuildContext context, String levelJson) async {
  try{
    String? outputFilePath = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Please select an output file:',
      fileName: importedFileName,
      //initialDirectory: '',
      bytes: utf8.encode(''),
    );

    if (outputFilePath == null) {
      // User canceled the picker
    } else {
      saveFileToCustomDirectory(directoryPath: outputFilePath, content: levelJson, context: context);

    }
  } catch (e) {
    Get.defaultDialog(title: "Error", middleText: "Something went wrong! Uh oh!\n\n$e", textCancel: 'Ok');
  }
}


void saveFileToCustomDirectory({required String directoryPath, required String content, required BuildContext context}) async {
  // Create a File object with the custom directory path and the file name
  File file = File(directoryPath);
  
  try {
    // Write the content to the file
    await file.writeAsString(content);
    print('File saved successfully at: ${file.path}');
  } catch (e) {
    print('Unable to create file: $e');
    Get.defaultDialog(title: "Error", middleText: "Unable to create file.\n\n$e", textCancel: 'Ok');
  }
}




void requestAndriodPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.manageExternalStorage,
    Permission.storage,
  ].request();
}

void addLevelCodeToClipboard(context, textToCopy){
  Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
    Get.snackbar('Copied level code to your clipboard!', '', snackPosition: SnackPosition.BOTTOM, maxWidth: 300, barBlur: 0, isDismissible: true, backgroundColor: Color.fromARGB(255, 36, 36, 36), colorText: Color.fromARGB(255, 214, 214, 214));
  });
}