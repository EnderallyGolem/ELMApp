import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/1_wave_page.dart';
import 'pages/2_initial_page.dart';
import 'pages/3_setting_page.dart';
import 'pages/4_custom_page.dart';
import 'pages/5_summary_page.dart';
import 'pages/6_codename_page.dart';
import 'pages/7_misc_page.dart';
import '/strings.dart';
import 'package:get/get.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import '/util_classes.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
    );
  }
}


//APPSTATE -------------------------------------------------
class ProviderMainState extends ChangeNotifier {

  //Values accessible anywhere!
  static dynamic global = {
    'modulesEventJson': {},
    'modulesEventJsonEnabled': {},
    'waveCount': 0, //TO-DO: stuff for this. Create function to update when importing level, and when editing relevant pages.
  };

  static dynamic levelCode = {
    //Everything inside is JSON
    'objects': [],
    'levelModules': [],
    'waveModules': [],
  };
  static dynamic waveCode = {'objects': [], 'levelModules': [], 'waveModules': []};
  static dynamic initialCode = {'objects': [], 'levelModules': [], 'waveModules': []};
  static dynamic settingCode = {'objects': [], 'levelModules': [], 'waveModules': []};
  static dynamic customCode = {'objects': [], 'levelModules': [], 'waveModules': []};

  List waveModuleArr = [];

  dynamic levelInfo = {
    //Store information such as number of waves, flag interval, etc... here
  };

  /// Resets level code to empty.
  static void resetLevelCode(){
    print('Resetting level code...');
    levelCode = {'objects': [], 'levelModules': [], 'waveModules': [],};
    waveCode = {'objects': [], 'levelModules': [], 'waveModules': []};
    initialCode = {'objects': [], 'levelModules': [], 'waveModules': []};
    settingCode = {'objects': [], 'levelModules': [], 'waveModules': []};
    customCode = {'objects': [], 'levelModules': [], 'waveModules': []};
    updateLevelCode();
    importLevelCode();
  }

  static void importLevelCode({importedCode=null}){
    importedCode ??= {'objects': [], 'levelModules': [], 'waveModules': [],};
    print('Imported Level Code: $importedCode');
    //levelCode['objects'] = importedCode['objects'];
    levelCode = importedCode;
    //Need to extract levelmodules and wavemodules
    //And also just extract everything in general
    //waveModuleArr = [],

    print('imported level code objects: ${levelCode['objects']}');
    ProviderWaveState.importWaveCode(waveCodeToAdd: levelCode['objects']); //TO-DO CHANGE
  }

  /// 
  /// Update level code. Called when code is updated in respective (and by respective I mean any) pages.
  /// Note: Level code is stored in main.dart parameters.
  /// When the respective pages is changed, the main code is set to the page code.
  /// 
  static void updateLevelCode(){

    //Note: For future waves, *ADD* new elements of array on top of levelCode objs
    levelCode = {
      'objects': [...waveCode['objects'], ...initialCode['objects'], ...settingCode['objects'], ...customCode['objects']],
      'levelModules': [...waveCode['levelModules'], ...initialCode['levelModules'], ...settingCode['levelModules'], ...customCode['levelModules']],
      'waveModules': [...waveCode['objects'], ...initialCode['waveModules'], ...settingCode['waveModules'], ...customCode['waveModules']],
    };

    debugPrint('main | updateLevelCode: Updating level to new code: $levelCode');
    ProviderMiscState.getCodeShown;
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

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<List<dynamic>> _pages = [
    [Page_Wave(), 'page_waves'.tr],
    [Page_Initial(), 'page_inital'.tr],
    [Page_Setting(), 'page_setting'.tr],
    [Page_Custom(), 'page_custom'.tr],
    [Page_Summary(), 'page_summary'.tr],
    [Page_Codename(), 'page_codename'.tr],
    [Page_Misc(), 'page_misc'.tr],
  ];

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dynamic eventObj = await loadJson(path: 'assets/json/default/modules_events.json');

      //Turn modules_events.json into map
      eventObj.forEach((event, value) {
        value["Image"] = Image.asset('assets/icon/moduleassets/${value["icon"]}.png', height: 20, width: 20,);
      });
      ProviderMainState.global['modulesEventJson'] = eventObj;

      //Turn ENABLED parts of modules_events.json into map
      final filteredMap = Map.fromEntries(
        eventObj.entries.where((entry) => entry.value["enabled"] != false)
      );
      ProviderMainState.global['modulesEventJsonEnabled'] = filteredMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to quit the app!'),
        ), 
        child: _pages[_currentIndex][0]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedFontSize: 13,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            //Waves
            icon: Icon(Icons.flag, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pages[0][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Initial
            icon: Icon(Icons.grid_view, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pages[1][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Settings
            icon: Icon(Icons.settings, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pages[2][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Custom
            icon: Icon(Icons.star, color: Color.fromARGB(255, 169, 202, 255),),
            label: _pages[3][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Summary
            icon: Icon(Icons.auto_graph_sharp, color: Color.fromARGB(255, 255, 229, 169),),
            label: _pages[4][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Codenames
            icon: Icon(Icons.table_rows_rounded, color: Color.fromARGB(255, 255, 229, 169),),
            label: _pages[5][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
          BottomNavigationBarItem(
            //Misc
            icon: Icon(Icons.download, color: Color.fromARGB(255, 255, 229, 169),),
            label: _pages[6][1],
            backgroundColor: Color.fromARGB(255, 23, 31, 46),
          ),
        ],
      ),
    );
  }
}