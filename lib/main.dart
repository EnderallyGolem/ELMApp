import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:event_bus/event_bus.dart';

import 'pages/1_wave_page.dart';
import 'pages/2_initial_page.dart';
import 'pages/3_setting_page.dart';
import 'pages/4_custom_page.dart';
import 'pages/5_summary_page.dart';
import 'pages/6_codename_page.dart';
import 'pages/7_misc_page.dart';
import '/strings.dart';
import '/util_functions.dart';
import '/util_classes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          //currentFocus.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ProviderMainState>(create: (_) => ProviderMainState()),
          ChangeNotifierProvider<ProviderWaveState>(create: (_) => ProviderWaveState()),
      
          ChangeNotifierProvider<ProviderCustomState>(create: (_) => ProviderCustomState()),
      
          ChangeNotifierProvider<ProviderMiscState>(create: (_) => ProviderMiscState())
        ],
        child: GetMaterialApp(
          title: 'ELM App',
          translations: ElmStrings(),
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', null),
          //Update locale: Get.updateLocale(Locale('en', 'US'))
          //Possible TO-DO: Dark/light mode swap?
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 58, 104, 183)),
            useMaterial3: true,
          ),
          home: const MyHomePage(),
        ),
      ),
    );
  }
}

//Create UndoStack
bool allowUpdateUndoStack = true;
UndoStack appUndoStack = UndoStack(
  maxStackSize: 300,
  addItemFunction: (item){
    //Do nothing
  },
  undoFunction: (item){
    undoRedoFunction(item);
  },
  redoFunction: (item){
    undoRedoFunction(item);
  }
);

void undoRedoFunction(item) {

  eventBus.fire(SetScrollEvent(page: item[0][0], scrollOffset: item[0][1]));
  //print('retrieved scrolldata: ${item[0]}');

  final getController = Get.put(GetController());

  switch (item[0][0]) {
    case 'wave':
      getController.currentIndex.value = 0;
      break;
    case 'initial':
      getController.currentIndex.value = 1;
      break;
    case 'setting':
      getController.currentIndex.value = 2;
      break;
    case 'custom':
      getController.currentIndex.value = 3;
      break;
    default:
  }

  ProviderMainState.waveCode = item[1];
  ProviderMainState.waveCode['importCheck'] = true;
  ProviderMainState.initialCode = item[2];
  ProviderMainState.initialCode['importCheck'] = true;
  ProviderMainState.settingCode = item[3];
  ProviderMainState.settingCode['importCheck'] = true;
  ProviderMainState.customCode = item[4];
  ProviderMainState.customCode['importCheck'] = true;
  eventBus.fire(CheckImportModuleCodeEvent(preventUpdateModule: true));

}
void appUndoStackDelayedEnable() async {
  await Future.delayed(const Duration(milliseconds: 300));
  allowUpdateUndoStack = true;
}

//Create an event bus instance
EventBus eventBus = EventBus();

//Import modules
class CheckImportModuleCodeEvent {
  bool preventUpdateModule;
  CheckImportModuleCodeEvent({this.preventUpdateModule = false}){}
}

//Update one specific page. Add ! for reloading all EXCEPT that page. Add something else (eg: All) for all pages.
class RebuildPageEvent {
  final String page;
  bool allExcept = false;
  final List<dynamic>? replaceModuleArr;
  RebuildPageEvent({required this.page, this.replaceModuleArr}){
    allExcept = page.startsWith('!');
  }
}

//Update one specific page's scroll.
class SetScrollEvent {
  final String page;
  final double scrollOffset;
  SetScrollEvent({required this.page, required this.scrollOffset}){}
}

//APPSTATE -------------------------------------------------
class ProviderMainState extends ChangeNotifier {

  //Values accessible anywhere!
  static dynamic global = {
    'isOpenWithImport': false,
    'nonElmImportWarn': [],

    'moduleJsons': {},
    'waveCount': 0, //TO-DO: stuff for this. Create function to update when importing level, and when editing relevant pages.
  };

  static dynamic levelCode = {
    //Everything inside is JSON
    'objects': [],
    'levelModules': [],
    'waveModules': [],
    'full': {},
  };
  static dynamic waveCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': false};
  static dynamic initialCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': false};
  static dynamic settingCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': false};
  static dynamic customCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': false};

  List waveModuleArr = [];

  dynamic levelInfo = {
    //Store information such as number of waves, flag interval, etc... here
  };

  /// Resets level code to empty.
  static Future<void> resetLevelCode() async {
    debugPrint('Resetting level code...');
    dynamic eventObj = await loadJson(path: 'assets/json/templatelevel.json', backspaceFix: true);
    importLevelCode(importedCode: eventObj);
    //Don't need updateLevelCode(); as it'll already update after importing
  }

  //Note: Importing the level code also updates the level code automatically.
  //The importing process has to update the level code in order to check if import was successful
  static void importLevelCode({importedCode = null}){

    debugPrint('Imported code: $importedCode');

    importedCode ??= {'objects': [], 'levelModules': [], 'waveModules': [],};

    levelCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'full': {}};
    waveCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': true};
    initialCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': true};
    settingCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': true};
    customCode = {'objects': [], 'levelModules': [], 'waveModules': [], 'importCheck': true};

    //Split the full object code into the individual pages, splitted into objects/levelModules/waveModules
    bool doneLevelDefinition = false;

    importedCode['objects'].forEach((item){

      //print('item: $item');

      if (item != null) { //Skip through nulls. Probably just empty {}
        String? objclass = item['objclass']; //String? as possible that item has no objclass (goes straight to custom!)
        if(objclass == 'LevelDefinition' && doneLevelDefinition == false){
          doneLevelDefinition = true;
          //Do special levelDefinition stuff. TO-DO.
        
          //For module w/o data, check if it's settings (preset list), then events (json). If neither, it's custom.
        } else {
          //Everything here should be leftover code that isn't ran directly by the level, and isn't grouped into some other module.
          //These should be in custom.
          customCode['objects'].add(item);
        }
      }
    });

    //Something went wrong and the code can't be imported. Abuse try/catch xd
    if(doneLevelDefinition == false){
      throw("misc_importlevel_error_missingleveldefinition".tr);
    }

    //Add events. This is ran now rather than when page is opened in order to check for errors when importing.
    eventBus.fire(CheckImportModuleCodeEvent());

    void doAsyncStuff() async {

      await Future.delayed(Duration(milliseconds: 500)); //Wait some time for firings to complete

      if(ProviderMainState.global['nonElmImportWarn'].length > 0){
        String errorMsg = ProviderMainState.global['nonElmImportWarn'].join(', ');
        Get.defaultDialog(title: 'misc_importlevel_warn_header'.tr, middleText: "${'misc_importlevel_warn_desc'.tr}\n\n$errorMsg\n\n${'misc_importlevel_warn_desc2'.tr}", textCancel: 'generic_ok'.tr);
        ProviderMainState.global['nonElmImportWarn'] = [];
      }

      eventBus.fire(RebuildPageEvent(page: '!misc'));
    }
    doAsyncStuff();
  }

  /// 
  /// Update level code. Called when code is updated in respective (and by respective I mean any) pages.
  /// Note: Level code is stored in main.dart parameters.
  /// When the respective pages is changed, the main code is set to the page code.
  /// 
  static void updateLevelCode({List<dynamic> scrollData = const ['page', 0.0]}){

    dynamic oldFullLevelCode = deepCopy(levelCode['full']);

    //TO-DO: levelDefinition dependent on levelModules, wave modules dependent on waveCode
    dynamic levelDefinition = {
      "objclass": "LevelDefinition",
      "objdata": {
        "StartingSun": 50,
        "Description": "Custom Level",
        "FirstRewardParam": "moneybag",
        "NormalPresentTable": "egypt_normal_01",
        "ShinyPresentTable": "egypt_shiny_01",
        "Loot": "RTID(DefaultLoot@LevelModules)",
        "ResourceGroupNames": [
            "DelayLoad_Background_Beach",
            "DelayLoad_Background_Beach_Compressed",
            "Tombstone_Dark_Special",
            "Tombstone_Dark_Effects"
        ],
        "Modules": [],
        "Name": "My Level",
        "StageModule": "RTID(ModernStage@LevelModules)"
      }
    };

    //Note: For future waves, *ADD* new elements of array on top of levelCode objs
    levelCode = {
      'objects': [levelDefinition, ...waveCode['objects'], ...initialCode['objects'], ...settingCode['objects'], ...customCode['objects']],
      'levelModules': [...waveCode['levelModules'], ...initialCode['levelModules'], ...settingCode['levelModules'], ...customCode['levelModules']],
      'waveModules': [...waveCode['objects'], ...initialCode['waveModules'], ...settingCode['waveModules'], ...customCode['waveModules']],
      'full': {},
    };

    levelCode['full'] = {
      '#comment': '',
      '#zombies': '',
      'objects': levelCode['objects']
    };

    ProviderMiscState.getCodeShown;
    eventBus.fire(RebuildPageEvent(page: 'misc'));

    //Store level code to UndoStack. Only occurs if new code is different + it has been some time since the previous one (to prevent dupe)
    if (allowUpdateUndoStack && !deepEquals(oldFullLevelCode, levelCode['full'])) {
      void doAsyncStuff() async {
        allowUpdateUndoStack = false;
        appUndoStack.add([scrollData, waveCode, initialCode, settingCode, customCode]);
        await Future.delayed(const Duration(milliseconds: 100)); //Wait some time for firings to complete
        allowUpdateUndoStack = true;
      }
      doAsyncStuff();
    }
  }

  static const List jsonFileNames = ['modules_events', "modules_custom"];   //All file names for the jsons that specify module information w/o the .json
  //Run this to update the jsons that specify module information
  static void reloadModuleJsons({List jsonFileNamesToUpdate = jsonFileNames}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for(String filename in jsonFileNamesToUpdate){
        dynamic eventObj = await loadJson(path: 'assets/json/default/${filename}.json');
      
        //Turn json into map
        eventObj.forEach((event, value) async {
          bool assetExists = await checkIfAssetExists('assets/icon/moduleassets/${value["icon"]}.png');
          if (assetExists){
            value["Image"] = Image.asset('assets/icon/moduleassets/${value["icon"]}.png', height: 20, width: 20,);
          } else {
            value["Image"] = Image.asset('assets/icon/moduleassets/misc_empty.png', height: 20, width: 20,);
          }
        });
        ProviderMainState.global['moduleJsons'][filename] = eventObj;
      
        //Turn ENABLED parts of json into map
        final filteredMap = Map.fromEntries(
          eventObj.entries.where((entry) => entry.value["enabled"] != false)
        );
        ProviderMainState.global['moduleJsons']['${filename}_enabled'] = filteredMap;
      }
    });
  }

  void updateMainState(){
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class GetController extends GetxController {
  var currentIndex = 0.obs;
}

class _MyHomePageState extends State<MyHomePage> {

  final getController = Get.put(GetController());

  @override
  void initState() {
    super.initState();
    _checkForFile();
    ProviderMainState.reloadModuleJsons(); //This is not for the json stuff lol

    //Run functions to load the first 4 pages in the background, then unload them.
    //This is to initialise classes.

  }

  //This is ran if the app starts.
  //If the app is ran by open-with, import that file!
  Future<void> _checkForFile() async {
    try {
      const platform = MethodChannel('com.example.elmapp/openfile');

      final String? fileContent = await platform.invokeMethod('getFileContent');
      if (fileContent == null) {
        //This means the app did NOT open with a json file.
        //If so, load the level template by running resetLevelCode.

        ProviderMainState.resetLevelCode();

      } else {
        //This means the app opened with a json file.

        //Correct the file path because it is wrong and stupid and L
        // if (Platform.isAndroid) {
        //   filePath = '/storage/emulated/0${filePath}'.replaceFirst("/document", "").replaceFirst("primary:", "");
        // } else if (Platform.isIOS) {
        //   filePath = filePath.replaceAll('/private', ''); //I didn't test this (probably won't have IOS support anyway)
        // }

        //Obtain that json file!
        debugPrint('Opened with Open-with! File content: $fileContent');

        ProviderMainState.global['isOpenWithImport'] = true;
        ProviderMiscState.importCodeWithOpen(fileContent: fileContent);

        //Set page to misc page
        getController.currentIndex.value = 6;
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get file path: '${e.message}'.");
    }
  }

  //Bottom Navigation bar stuff

  final List<Widget> _pages = [
    Page_Wave(),
    Page_Initial(),
    Page_Setting(),
    Page_Custom(),
    Page_Summary(),
    Page_Codename(),
    Page_Misc(),
  ];

  final List<String> _pageName = [
    'page_wave'.tr, 
    'page_inital'.tr, 
    'page_setting'.tr, 
    'page_custom'.tr, 
    'page_summary'.tr, 
    'page_codename'.tr, 
    'page_misc'.tr
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to quit the app!'),
        ), 
        child: Obx(() => IndexedStack(
          children: _pages,
          index: getController.currentIndex.value,
        )),
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: getController.currentIndex.value,
        onTap: (int index) {
          primaryFocus!.unfocus();
          getController.currentIndex.value = index;
        },
        selectedFontSize: 13,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            //Waves
            icon: Icon(Icons.flag, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pageName[0],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Initial
            icon: Icon(Icons.grid_view, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pageName[1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Settings
            icon: Icon(Icons.settings, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pageName[2],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Custom
            icon: Icon(Icons.star, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pageName[3],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Summary
            icon: Icon(Icons.auto_graph_sharp, color: Color.fromARGB(255, 255, 229, 169),),
            label: _pageName[4],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Codenames
            icon: Icon(Icons.table_rows_rounded, color: Color.fromARGB(255, 255, 229, 169),),
            label: _pageName[5],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Misc
            icon: Icon(Icons.download, color: Color.fromARGB(255, 255, 229, 169),),
            label: _pageName[6],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
        ],
      )),
    );
  }
}