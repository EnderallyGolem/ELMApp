import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

dynamic exportWaveCode(){
  dynamic levelCodeWaves = {
    'objects': [],
    'levelModules': [],
    'waveModules': [],
  };
  for (int i = 0; i < waveModuleArr.length; i++){
    levelCodeWaves['objects'].add(waveModuleArr[i].value);
  }
  return levelCodeWaves;
}
void importWaveCode({dynamic waveCode = ''}){
  waveModuleArr = [];
  for(int i = 0; i < waveCode.length; i++){
    dynamic waveModuleToInsert = WaveModule(value: waveCode[i].toString()); //TO STRING IS TEMPORARY!!!!!!!!!!!!!!!!!!!!
    waveModuleArr.insert(i, waveModuleToInsert);
  }
}

List waveModuleArr = [];
//Each wave is a WaveModule class
//Each WaveModule class contains a bunch of EventModule classes [WHICH I HAVE NOT MADE.]
///
/// Usage: WaveModule(value: [value])
/// [value] is the code in each wave. it is currently a string. well. that needs to be changed eventually.
///
class WaveModule {
  int waveIndex = 0;
  String value;
  String _display = "";
  TextEditingController _controllers = TextEditingController(
    text: '',
  );

  WaveModule({this.value = ''}) {
    //_display = 'Wave ${waveIndex + 1}';
    _controllers = TextEditingController(
      text: value,
  );
  }

  String get display => _display;
  set display(String value) => _display = value;

  TextEditingController get controllers => _controllers;
  set controllers(TextEditingController controllers) => _controllers = controllers;
}

class Page_Wave extends StatefulWidget {
  @override
  _Page_WaveState createState() => _Page_WaveState();
}
class _Page_WaveState extends State<Page_Wave>
{
  @override
  void initState() {
    //THINGS IN HERE RUN ONCE
    super.initState();

    //Add level import code here
    _updateAllModuleName();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Waves'),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            onPressed: () => _addModuleBelow(),
            child: Text('Add Wave'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: waveModuleArr.length,
        itemBuilder: (context, index) {
          return ModuleWidget(
            moduleText: waveModuleArr[index].display,
            controller: waveModuleArr[index].controllers,
            onChanged: (value) {
              _updateModule(index, value);
              appState.updateLevelCode();
            },
            onDelete: () {
              _deleteModule(index);
              appState.updateLevelCode();
            },
            onAddBelow: () {
              _addModuleBelow(index: index);
              appState.updateLevelCode();
            },
          );
        },
      ),
    );
  }

  void _addModuleBelow({int index = -1}) {
    setState(() {
      final newIndex = index + 1;
      dynamic waveModuleToInsert = WaveModule(value: '');
      waveModuleArr.insert(newIndex, waveModuleToInsert);
    });
    _updateAllModuleName(i: index);
  }

  void _deleteModule(int index) {
    setState(() {
      waveModuleArr.removeAt(index);
    });
    _updateAllModuleName(i: index);
  }

  void _updateAllModuleName({int i = 0}) {
    if (i < 0){ i=0; }
    for (i; i < waveModuleArr.length; i++) {
      setState(() {
        waveModuleArr[i].display = 'Wave ${i + 1}: ${waveModuleArr[i].value}';
      });
    }
  }

  void _updateModule(int index, dynamic value) {
    setState(() {
      waveModuleArr[index].value = value;
      waveModuleArr[index].display = 'Wave ${index + 1}: ${waveModuleArr[index].value}';
    });
  }
}


class ModuleWidget extends StatelessWidget {
  final String moduleText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback onDelete;
  final VoidCallback onAddBelow;

  const ModuleWidget({
    Key? key,
    required this.moduleText,
    required this.controller,
    required this.onChanged,
    required this.onDelete,
    required this.onAddBelow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: moduleText,
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            onDelete();
          },
          child: Text('Delete'),
        ),
        ElevatedButton(
          onPressed: () {
            onAddBelow();
          },
          child: Text('Add Wave'),
        ),
        Divider(),
      ],
    );
  }
}
