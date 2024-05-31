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
  dynamic current = obj;
  for (int i = 0; i < path.length; i++) {
    var key = path[i];
    if (i == path.length - 1) {
      // If it's the last key in the path, set the value
      if (current is Map<String, dynamic>) {
        current[key] = value;
      } else if (current is List<dynamic> && key is int) {
        if (key >= 0 && key < current.length) {
          current[key] = value;
        } else {
          current.insert(key, value);  // Optionally handle out-of-bounds index
        }
      } else {
        throw Exception('Invalid path or object type');
      }
    } else {
      // Traverse to the next key in the path
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else if (current is List<dynamic> && key is int && key >= 0 && key < current.length) {
        current = current[key];
      } else {
        throw Exception('Invalid path or object type');
      }
    }
  }
}

///
/// Iterates through a nested list/map and runs a callback function on each individual value
/// 
/// [nestedItem] : The nested list or map
/// 
/// [function] : Function that is ran for every element with parameters [key] and [value].
/// [value] is modified to the value that is returned.
///
void iterateAndModifyNested({required dynamic nestedItem, required dynamic Function(dynamic key, dynamic value) function}) {
  if (nestedItem is Map) {
    nestedItem.forEach((key, value) {
      if (value is Map) {
        iterateAndModifyNested(nestedItem: value, function: function);
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] is Map || value[i] is List) {
            iterateAndModifyNested(nestedItem: value[i], function: function);
          } else {
            value[i] = function(key, value[i]);
          }
        }
      } else {
        nestedItem[key] = function(key, value);
      }
    });
  } else if (nestedItem is List) {
    for (int i = 0; i < nestedItem.length; i++) {
      if (nestedItem[i] is Map || nestedItem[i] is List) {
        iterateAndModifyNested(nestedItem: nestedItem[i], function: function);
      } else {
        nestedItem[i] = function(null, nestedItem[i]);
      }
    }
  }
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