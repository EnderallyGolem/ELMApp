import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
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

  static void importCodeWithOpen({required String fileContent}){
    requestAndriodPermissions();
    _importFileWithOpen(fileContent: fileContent);
  }
}

class Page_Misc extends StatefulWidget {
  @override
  _Page_MiscState createState() => _Page_MiscState();
}
class _Page_MiscState extends State<Page_Misc> {

  @override
  void initState() {
    super.initState();
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
        title: Text('page_misc'.tr),
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
                child: Text('misc_importlevel'.tr),
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
                child: Text('misc_exportlevel'.tr),
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
                  Get.defaultDialog(title: 'misc_resetlevel_warning_title'.tr, middleText: 'misc_resetlevel_warning_desc'.tr, textCancel: 'Cancel'.tr, textConfirm: 'Confirm'.tr,
                  onConfirm: (){
                    ProviderMainState.resetLevelCode();
                    appMiscState.updateMiscState();
                    Get.back();
                  });
                },
                child: Text('misc_resetlevel'.tr),
              ),
              //Button for saving. Only shows if used open-with
              ProviderMainState.global['isOpenWithImport'] == true ? 
              ElevatedButton(
                onPressed: () {
                  requestAndriodPermissions();
                  _exportFileWithOpen(context: context, levelJson: ProviderMiscState.levelJson);
                },
                child: Text('misc_savelevel'.tr),
              ) : SizedBox.shrink()
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
    dialogTitle: 'misc_importlevel_dialog'.tr,
    withReadStream: false,
    withData: true,
  );
  ProviderMainState.global['isOpenWithImport'] = false;
  if (result != null) {
    try{
        PlatformFile file = result.files.single;
        String fileContent = utf8.decode(file.bytes!);
        //String importedFileDirectory = file.path!;
        dynamic importedFile = jsonDecode(fileContent);
        importedFileName = file.name;
        // print('Imported File name: $importedFileName');
        // print('Imported Directory: $importedFileDirectory');
        // print('importedFile["objects"][0]["objdata"]["ResourceGroupNames"] = ${importedFile["objects"][0]["objdata"]["ResourceGroupNames"]}');
        ProviderMainState.importLevelCode(importedCode: importedFile);
        appMiscState.updateMiscState();
        ProviderMainState.global['isOpenWithImport'] == false;
      } catch (e) {
        Get.defaultDialog(title: 'generic_error'.tr, middleText: "${'misc_importlevel_error_desc'.tr}\n\n$e", textCancel: 'generic_ok'.tr);
        ProviderMainState.resetLevelCode(); //Clear level code to prevent errors
        appMiscState.updateMiscState();
    }
  }
}

void _importFileWithOpen({required String fileContent}) async {
  try{
    dynamic importedFile = jsonDecode(fileContent);

    ProviderMainState.importLevelCode(importedCode: importedFile);
    //appMiscState.updateMiscState();
  } catch (e) {
    Get.defaultDialog(title: 'generic_error'.tr, middleText: "${'misc_importlevel_error_desc'.tr}\n\n$e", textCancel: 'generic_ok'.tr);
    ProviderMainState.resetLevelCode(); //Clear level code to prevent errors
    //appMiscState.updateMiscState();
  }
} 

void _exportFile(BuildContext context, String levelJson) async {
  try{
    String? outputFilePath = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'misc_exportlevel_dialog'.tr,
      fileName: importedFileName,
      //initialDirectory: '',
      bytes: utf8.encode(''),
    );

    if (outputFilePath == null) {
      // User canceled the picker
    } else {
      saveFileToCustomDirectory(directoryPath: outputFilePath, content: levelJson, context: context);
      Get.snackbar('misc_exportlevel_success'.tr, '', snackPosition: SnackPosition.BOTTOM, maxWidth: 300, barBlur: 0, isDismissible: true, backgroundColor: Color.fromARGB(255, 36, 36, 36), colorText: Color.fromARGB(255, 214, 214, 214));
    }
  } catch (e) {
    Get.defaultDialog(title: 'generic_error'.tr, middleText: "${'generic_error_desc'.tr}\n\n$e", textCancel: 'generic_ok'.tr);
  }
}

Future<void> _exportFileWithOpen({required BuildContext context, required String levelJson}) async {
  try {
    const platform = MethodChannel('com.example.elmapp/openfile');
    final bool? success = await platform.invokeMethod('saveFileContent', {'content': levelJson});
    if (success == true) {
      Get.snackbar('misc_savelevel_success'.tr, '', snackPosition: SnackPosition.BOTTOM, maxWidth: 300, barBlur: 0, isDismissible: true, backgroundColor: Color.fromARGB(255, 36, 36, 36), colorText: Color.fromARGB(255, 214, 214, 214));
    } else {
      Get.defaultDialog(title: 'generic_error'.tr, middleText: "${'misc_savelevel_error_desc'.tr}", textCancel: 'generic_cancel'.tr);
    }
  } on PlatformException catch (e) {
    Get.defaultDialog(title: 'generic_error'.tr, middleText: "${'misc_savelevel_error_desc'.tr}\n\n$e", textCancel: 'generic_cancel'.tr);
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
    Get.defaultDialog(title: 'generic_error'.tr, middleText: "${'misc_exportlevel_error_desc'.tr}\n\n$e", textCancel: 'generic_cancel'.tr);
  }
}




void requestAndriodPermissions() async {
  await [
    Permission.manageExternalStorage,
    Permission.storage,
  ].request();
}

void addLevelCodeToClipboard(context, textToCopy){
  Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
    Get.snackbar('misc_copylevel'.tr, '', snackPosition: SnackPosition.BOTTOM, maxWidth: 300, barBlur: 0, isDismissible: true, backgroundColor: Color.fromARGB(255, 36, 36, 36), colorText: Color.fromARGB(255, 214, 214, 214));
  });
}