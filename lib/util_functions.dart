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



class ReplaceNestedList {
  final dynamic value;
  ReplaceNestedList(this.value);
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
/// If you want to replace a list/map nest layer, return the replacement list/map bracketted around ReplaceNested()
/// This will replace the lowest level list that the value is in (and then iterate across it)
///
dynamic iterateAndModifyNestedListOrdered({
  required dynamic nestedItem,
  List<dynamic> path = const [],
  required dynamic Function(dynamic key, dynamic value, List<dynamic> path) function,
}) {
  if (nestedItem is List) {
    List<int> indicesToDelete = [];

    // Apply function to top-level items
    for (int i = 0; i < nestedItem.length; i++) {
      var newPath = List.from(path)..add(i);
      if (nestedItem[i] is Map || nestedItem[i] is List) {
        var result = iterateAndModifyNestedListOrdered(nestedItem: nestedItem[i], path: newPath, function: function);
        if (result is ReplaceNestedList) {
          //ReplaceNested found! Stop iterating and return this thing!
          return ReplaceNestedList(result.value);
        } else {
          nestedItem[i] = result;
        }
      } else {
        var newValue = function(i, nestedItem[i], newPath); // key is the index for list items
        if (newValue == null) {
          indicesToDelete.add(i);
        } else if (newValue is ReplaceNestedList) {
          //ReplaceNested found! Stop iterating and return this thing!
          return ReplaceNestedList(newValue.value);
        } else {
          nestedItem[i] = newValue;
        }
      }
    }

    // Delete indices in reverse order to avoid index shifting issues
    for (int i = indicesToDelete.length - 1; i >= 0; i--) {
      nestedItem.removeAt(indicesToDelete[i]);
    }

  } else if (nestedItem is Map) {
    List keysToDelete = [];
    dynamic stopForEachingAndReturnThisThingAlready = null;

    // Apply function to top-level items
    nestedItem.forEach((key, value) {
      var newPath = List.from(path)..add(key);
      if (value is Map || value is List) {
        var result = iterateAndModifyNestedListOrdered(nestedItem: value, path: newPath, function: function);
        if (result is ReplaceNestedList && value is Map) {
          //ReplaceNested found! Stop iterating and return this thing!
          // Signal to replace the current map in its parent container
          nestedItem[key] = result.value;
          stopForEachingAndReturnThisThingAlready = result.value;
        } else if (result is ReplaceNestedList) {
          //ReplaceNested found! This is for a List though, so don't return this one.
          //ReplaceNested will return up to this point!
          
          //After replacement, this requires an additional iteration.
          nestedItem[key] = iterateAndModifyNestedListOrdered(nestedItem: result.value, path: newPath, function: function);
        } else {
          nestedItem[key] = result;
        }
      } else {
        var newValue = function(key, value, newPath);
        if (newValue == null) {
          keysToDelete.add(key);
        } else if (newValue is ReplaceNestedList) {
          //ReplaceNested found! Stop iterating and return this thing!
          stopForEachingAndReturnThisThingAlready = newValue.value;
        } else {
          nestedItem[key] = newValue;
        }
      }
    });

    if(stopForEachingAndReturnThisThingAlready != null){
      return ReplaceNestedList(stopForEachingAndReturnThisThingAlready);
    }

    // Delete keys outside of forEach to avoid concurrent modification
    keysToDelete.forEach((key) {
      nestedItem.remove(key);
    });
  } else if (nestedItem is String) {
    // Run the callback function on the string
    nestedItem = function(null, nestedItem, path);
  }

  return nestedItem;
}


///
/// Iterates through a nested map and runs a callback function on each individual value
/// There can be lists inside the map, but anything inside a list will NOT be iterated and will be ignored.
/// THE EXCEPTION: If the top most layer is a list, it will iterate through them.
/// 
/// [nestedItem] : The nested list or map
/// 
/// [function] : Function that is ran for every element with parameters [key] and [value].
/// [value] is modified to the value that is returned.
/// The item is deleted if [value] = null
///
void iterateAndModifyNestedMapAndTopList({required dynamic nestedItem, required dynamic Function(dynamic key, dynamic value) function}) {
  if (nestedItem is Map) {
    List keysToDelete = [];
    nestedItem.forEach((key, value) {
      if (value is Map) {
        iterateAndModifyNestedMap(nestedItem: value, function: function);
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] is Map || value[i] is List) {
            iterateAndModifyNestedMap(nestedItem: value[i], function: function);
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
        iterateAndModifyNestedMap(nestedItem: nestedItem[i], function: function);
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
/// Iterates through a nested map and runs a callback function on each individual value
/// There can be lists inside the map, but anything inside a list will NOT be iterated and will be ignored.
/// 
/// [nestedItem] : The nested map
/// 
/// [function] : Function that is ran for every element with parameters [key] and [value].
/// [value] is modified to the value that is returned.
/// The item is deleted if [value] = null
///
void iterateAndModifyNestedMap({required dynamic nestedItem, required dynamic Function(dynamic key, dynamic value) function}) {
  if (nestedItem is Map) {
    List keysToDelete = [];
    nestedItem.forEach((key, value) {
      if (value is Map) {
        iterateAndModifyNestedMap(nestedItem: value, function: function);
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

///
/// Async function. Checks if asset exists, and returns true if it does and false if it doesn't
/// 
/// [assetPath] - Path to check
///
Future<bool> checkIfAssetExists(String assetPath) async {
  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (e) {
    return false;
  }
}