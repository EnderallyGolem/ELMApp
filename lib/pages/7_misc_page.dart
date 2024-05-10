import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

dynamic importedFile;
String importedFileName = "egypt1";
const JsonEncoder jsonEncoder = JsonEncoder.withIndent('    ');

class Page_Misc extends StatefulWidget {
  @override
  _Page_MiscState createState() => _Page_MiscState();
}
class _Page_MiscState extends State<Page_Misc> {
  //String levelJson = 'hmm'; // Define levelJson as a state variable

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    dynamic levelCode = appState.levelCode;
    String levelJson = jsonEncoder.convert((levelCode['objects'])); //Obviously has to be changed in the future
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
                  _importFile(context: context, appState: appState);
                },
                child: Text('Import Level'),
              ),
              ElevatedButton(
                onPressed: () {
                  addLevelCodeToClipboard(context, levelJson);
                },
                child: Icon(Icons.copy),
              ),
              ElevatedButton(
                onPressed: () {
                  requestAndriodPermissions();
                  _exportFile(context, levelJson);
                },
                child: Text('Export Level'),
              ),
            ]
          ),
          Text(levelJson),
        ]
      )
    );
  }
}

void _importFile({dynamic context, dynamic appState}) async {
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
        print(importedFileName);
        print(importedFileDirectory);
        print(importedFile['objects'][0]['objdata']["ResourceGroupNames"]);
        appState.importLevelCode(importedCode: importedFile);
      } catch (e) {
        showAlertDialog(errorText: "Something went wrong! The file's json format might not be correct!", context: context, error: e);
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
      print('So i believe this is the output file path???:\n$outputFilePath');
      saveFileToCustomDirectory(directoryPath: outputFilePath, content: levelJson, context: context);

    }
  } catch (e) {
    showAlertDialog(errorText: "Something went wrong! Uh oh!", context: context, error: e);
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
    showAlertDialog(errorText: "Unable to create file.", context: context, error: e);
  }
}




void requestAndriodPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.manageExternalStorage,
    Permission.storage,
  ].request();
}

showAlertDialog({errorText = "An error occured!", required BuildContext context, error = ''}) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("Ok"),
    onPressed: () { Navigator.of(context).pop(); },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Error"),
    content: Text('$errorText\n\n($error)'),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

void addLevelCodeToClipboard(context, textToCopy){
  Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied level code to your clipboard!')));
});
}