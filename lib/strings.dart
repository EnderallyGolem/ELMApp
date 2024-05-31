import 'package:get/get.dart';

class ElmStrings extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': {
          'page_waves': 'Waves',
          'page_inital': 'Initial',
          'page_setting': 'Settings',
          'page_custom': 'Custom',
          'page_summary': 'Summary',
          'page_codename': 'Codenames',
          'page_misc': 'Misc',

          'generic_cancel': 'Cancel',
          'generic_yes': 'Yes',
          'generic_no': 'No',
          'generic_ok': 'Ok',
          'generic_confirm': 'Confirm',
          'generic_error': 'Error',
          'generic_error_desc': 'Something went wrong! Uh oh!',

          'util_moreactions': 'More actions',
          'util_addwave': 'Add Module',
          'util_deletewave_warning_title': 'Delete Module?',
          'util_deletewave_warning_desc': 'Are you sure you want to delete this module?',
          'util_default_module_dropdown': 'Select Module',
          'util_default_module_message': 'Select a module!',

          'waves_wave': 'Wave',
          'waves_addwave': 'Add Wave',
          'waves_deletewave_warning_title': 'Delete Wave?',
          'waves_deletewave_warning_desc': 'Are you sure you want to delete this wave?',

          
          'custom_addcode': 'Add Code',

          'misc_importlevel': 'Import Level',
          'misc_importlevel_dialog': 'Select a level to import:',
          'misc_importlevel_error_desc': "Something went wrong! The file's json format might not be correct!",
          'misc_exportlevel': 'Export Level',
          'misc_exportlevel_dialog': 'Please select an output file:',
          'misc_exportlevel_error_desc': 'Unable to create file.',
          'misc_copylevel': 'Copied level code to your clipboard!',
          'misc_resetlevel': 'Reset Level',
          'misc_resetlevel_warning_title': 'Reset Level?',
          'misc_resetlevel_warning_desc': "This will clear all data in the level.\nAre you sure about this?\nThere's no undo button!",
        },
      };
}