import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/1_wave_page.dart';
import 'pages/2_initial_page.dart';
import 'pages/3_setting_page.dart';
import 'pages/4_custom_page.dart';
import 'pages/5_summary_page.dart';
import 'pages/6_codename_page.dart';
import 'pages/7_misc_page.dart';

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

        ChangeNotifierProvider<ProviderMiscState>(create: (_) => ProviderMiscState())
      ],
      child: MaterialApp(
        title: 'ELM App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 58, 104, 183)),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'ELM App Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


//APPSTATE -------------------------------------------------
class ProviderMainState extends ChangeNotifier {

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

  void importLevelCode({importedCode=''}){
    print('Imported Level Code: $importedCode');
    //levelCode['objects'] = importedCode['objects'];
    levelCode = importedCode;
    //Need to extract levelmodules and wavemodules
    //And also just extract everything in general
    //waveModuleArr = [],

    print('imported level code objects: ${levelCode['objects']}');
    ProviderWaveState.importWaveCode(waveCodeToAdd: levelCode['objects']); //TO-DO CHANGE
    notifyListeners();
    print('did it go this far');
  }

  /// 
  /// Update level code.
  /// Note: Level code is stored in main.dart parameters.
  /// When the respective pages is changed, the main code is set to the page code.
  /// 
  void updateLevelCode(){

    print(waveCode);
    print(initialCode);
    //Note: For future waves, *ADD* new elements of array on top of levelCode objs
    levelCode = {
      'objects': [...waveCode['objects'], ...initialCode['objects'], ...settingCode['objects'], ...customCode['objects']],
      'levelModules': [...waveCode['levelModules'], ...initialCode['levelModules'], ...settingCode['levelModules'], ...customCode['levelModules']],
      'waveModules': [...waveCode['objects'], ...initialCode['waveModules'], ...settingCode['waveModules'], ...customCode['waveModules']],
    };

    print('Updating level: $levelCode');
    ProviderMiscState().updateMiscState();
    notifyListeners();
  }

  void updateMainState(){
    notifyListeners();
  }
}


class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<List<dynamic>> _pages = [
    [Page_Wave(), "Waves"],
    [Page_Initial(), "Initial"],
    [Page_Setting(), "Settings"],
    [Page_Custom(), "Custom"],
    [Page_Summary(), "Summary"],
    [Page_Codename(), "Codenames"],
    [Page_Misc(), "Misc"],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text('Bottom Tab Example'),
      ),
      body: _pages[_currentIndex][0],
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