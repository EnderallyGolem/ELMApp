import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; 


Future loadJson({required String path}) async {
  String data = await rootBundle.loadString(path);
  var jsonResult = json.decode(data);
  debugPrint('Loaded json at $path: $jsonResult');
  return jsonResult;
}

///
/// Set value of a nested object/array/whatever.
/// Changes the value if it already exists, otherwise adds a new value.
/// 
/// [obj] : The object. Probably appState.elmModuleListArr[moduleIndex].value
/// 
/// [path] : Array with each item being the path. Eg: ['variables', 'aliases'] or ['test', 0]
/// 
/// [value] : Dynamic value to be set at that path
///
void setNestedProperty({required dynamic obj, required List<dynamic> path, required dynamic value}) {
  //debugPrint('setNestedProperty: obj $obj | path $path | value $value');
  dynamic current = obj;
  for (int i = 0; i < path.length; i++) {
    var key = path[i];
    if (i == path.length - 1) {
      // If it's the last key in the path, set the value
      if (current is Map<dynamic, dynamic>) {
        current[key] = value;
      } else if (current is List<dynamic> && key is int) {
        if (key >= 0 && key < current.length) {
          current[key] = value;
        } else {
          current.insert(key, value);  // Lists: Handle out-of-bounds index
        }
      } else {
        throw Exception('Invalid path or object type at the final step');
      }
    } else {
      // Traverse to the next key in the path
      if (current is Map<dynamic, dynamic>) {
        if (!current.containsKey(key)) {
          // Create a new map or list depending on the next key
          current[key] = path[i + 1] is int ? [] : {};
        }
        current = current[key];
      } else if (current is List<dynamic> && key is int) {
        if (key >= 0 && key < current.length) {
          current = current[key];
        } else {
          // Expand the list to accommodate the new index
          while (current.length <= key) {
            dynamic addItem = path[i + 1] is int ? [] : {};
            current.add(addItem);
          }
          current = current[key];
        }
      } else {
        throw Exception('Invalid path or object type during traversal');
      }
    }
  }
}



///
/// Get value of a nested object/array/whatever.
/// Returns the value if it exists, otherwise throws an exception.
/// 
/// [obj] : The object.
/// 
/// [path] : Array with each item being the path. Eg: ['variables', 'aliases'] or ['test', 0]
/// 
/// Returns the value at the specified path. Returns [invalidReturn] if path/object is invalid (null as default).
///
dynamic getNestedProperty({required dynamic obj, required List<dynamic> path, dynamic invalidReturn = null}) {
  dynamic current = obj;
  for (int i = 0; i < path.length; i++) {
    var key = path[i];
    if (current is Map<dynamic, dynamic> && current.containsKey(key)) {
      current = current[key];
    } else if (current is List<dynamic> && key is int && key >= 0 && key < current.length) {
      current = current[key];
    } else {
      return invalidReturn;
    }
  }
  return current;
}


///
/// Iterates through a nested list/map and runs a callback function on each individual value
/// 
/// [nestedItem] : The nested list or map
/// 
/// [function] : Function that is ran for every element with parameters [key] and [value].
/// [value] is modified to the value that is returned.
/// The item is deleted if [value] = null
///
void iterateAndModifyNested({required dynamic nestedItem, required dynamic Function(dynamic key, dynamic value) function}) {
  if (nestedItem is Map) {
    List keysToDelete = [];
    nestedItem.forEach((key, value) {
      if (value is Map) {
        iterateAndModifyNested(nestedItem: value, function: function);
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] is Map || value[i] is List) {
            iterateAndModifyNested(nestedItem: value[i], function: function);
          } else {
            var newValue = function(key, value[i]);
            if (newValue == null) {
              value.removeAt(i);
              i--; // Adjust index after removal
            } else {
              value[i] = newValue;
            }
          }
        }
      } else {
        var newValue = function(key, value);
        if (newValue == null) {
          keysToDelete.add(key);
        } else {
          nestedItem[key] = newValue;
        }
      }
    });
    // Delete keys outside of forEach to avoid concurrent modification
    keysToDelete.forEach((key) {
      nestedItem.remove(key);
    });
  } else if (nestedItem is List) {
    for (int i = 0; i < nestedItem.length; i++) {
      if (nestedItem[i] is Map || nestedItem[i] is List) {
        iterateAndModifyNested(nestedItem: nestedItem[i], function: function);
      } else {
        var newValue = function(null, nestedItem[i]);
        if (newValue == null) {
          nestedItem.removeAt(i);
          i--; // Adjust index after removal
        } else {
          nestedItem[i] = newValue;
        }
      }
    }
  }
}




///
/// Iterates through a nested list/map and runs a callback function on each individual value
/// This will always iterate across higher level lists before lower level lists.
///
/// [nestedItem] : The nested list or map
///
/// [function] : Function that is ran for every element with parameters [key], [value] and [path].
/// [value] is modified to the value that is returned.
/// The item is deleted if [value] = null
/// [path] is an array of keys and indexes of the value.
///
void iterateAndModifyNestedListOrdered({required dynamic nestedItem, List<dynamic> path = const [], required dynamic Function(dynamic key, dynamic value, List<dynamic> path) function}) {
  if (nestedItem is Map) {
    List keysToDelete = [];
    Map<dynamic, dynamic> itemsToRecurse = {};

    // First pass: apply function to top-level items
    nestedItem.forEach((key, value) {
      if (value is Map || value is List) {
        itemsToRecurse[key] = value; // Collect nested items for recursion
      } else {
        var newPath = List.from(path)..add(key);
        var newValue = function(key, value, newPath);
        if (newValue == null) {
          keysToDelete.add(key);
        } else {
          nestedItem[key] = newValue;
        }
      }
    });

    // Delete keys outside of forEach to avoid concurrent modification
    keysToDelete.forEach((key) {
      nestedItem.remove(key);
    });

    // Second pass: recurse into nested items
    itemsToRecurse.forEach((key, value) {
      iterateAndModifyNestedListOrdered(nestedItem: value, path: List.from(path)..add(key), function: function);
    });

  } else if (nestedItem is List) {
    List<int> indicesToDelete = [];
    List<MapEntry<int, dynamic>> itemsToRecurse = [];

    // First pass: apply function to top-level items
    for (int i = 0; i < nestedItem.length; i++) {
      if (nestedItem[i] is Map || nestedItem[i] is List) {
        itemsToRecurse.add(MapEntry(i, nestedItem[i])); // Collect nested items for recursion
      } else {
        var newPath = List.from(path)..add(i);
        var newValue = function(i, nestedItem[i], newPath); // key is the index for list items
        if (newValue == null) {
          indicesToDelete.add(i);
        } else {
          nestedItem[i] = newValue;
        }
      }
    }

    // Delete indices in reverse order to avoid index shifting issues
    for (int i = indicesToDelete.length - 1; i >= 0; i--) {
      nestedItem.removeAt(indicesToDelete[i]);
    }

    // Second pass: recurse into nested items
    for (var entry in itemsToRecurse) {
      iterateAndModifyNestedListOrdered(nestedItem: entry.value, path: List.from(path)..add(entry.key), function: function);
    }
  }
}

void main() {
  var nestedListOfRows = [
    {
      "Items": [
        "!L_textListgrid{item}"
      ],
      "Row": "!L_textListgrid{axis_row}",
    }
  ];

  iterateAndModifyNestedListOrdered(
    nestedItem: nestedListOfRows,
    function: (key, value, path) {
      print('Key: $key, Value: $value, Path: $path');
      // Example callback logic
      if (value is String && value.contains('axis_row')) {
        return null; // Example: delete this value
      }
      return value;
    },
  );

  print(nestedListOfRows);
}


///
/// Deep copies some map/list madness
/// [source] is the map/list/whatever
///
dynamic deepCopy(dynamic source) {
  if (source is Map) {
    return Map.fromEntries(source.entries.map(
      (entry) => MapEntry(entry.key, deepCopy(entry.value)),
    ));
  } else if (source is List) {
    return List.from(source.map((item) => deepCopy(item)));
  } else {
    return source;
  }
}

///
/// Check if 2 nested list/maps are equal.
/// [a] is the first one, [b] is the 2nd one.
/// 
/// Remember to deepcopy if you're comparing the same dynamic at different times!
///
bool deepEquals(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key) || !deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  } else if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  } else {
    return a == b;
  }
}