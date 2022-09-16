// Import required built in libraries.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// Import required external libraries.
//import 'package:git/git.dart'; // Git manipulation for Dart. // TODO: Attempt to replace with own functions once at functional point.
import 'package:collection/collection.dart'; // List manipulation.
import 'package:file_picker/file_picker.dart'; // File picker.

void main() => runApp(const Main());

class _MainState extends State<Main> {
  String _location = 'null';

  late String _current = '';
  late List _currentData;
  late List _currentDataAndDeleted;
  late List _currentDataStaged;
  late List _currentDataUnstaged;
  List _currentDeleted = [];

  List _branches = [];

  String _sidebarContentState = "";

  void _currentUpdate(var deletedResult, var stagedResult, var unstagedResult) async {
    _currentData = [];

    List i = Directory("$_location$_current").listSync(
      recursive: false,
      followLinks: false,
    );

    setState(() {
      for (var j = 0; j < i.length; j++) {
        _currentData.add(i[j].toString());
        _currentData[j] = _currentData[j].replaceAll("File: '", "").replaceAll(
          "Directory: '", "");
        _currentData[j] =
          _currentData[j].substring(0, _currentData[j].length - 1);
      }

      _currentData.remove("$_location$_current/.git");
      if (_current != "") {
        _currentData.insert(0, "$_location$_current/..");
      }

      _currentData.sort();
    });

    await deletedResult.stdout
      .transform(utf8.decoder)
      .forEach((String out) => {
        _currentDeleted = const LineSplitter().convert(out),
      });

    await stagedResult.stdout
      .transform(utf8.decoder)
      .forEach((String out) => {
        _currentDataStaged = const LineSplitter().convert(out), // TODO: Include deleted files when staged.
      });

    await unstagedResult.stdout
      .transform(utf8.decoder)
      .forEach((String out) => {
        _currentDataUnstaged = const LineSplitter().convert(out),
      });

    setState(() {
      for (var i = _currentDeleted.length - 1; i >= 0; i--) {
        var j = _currentDeleted[i].split("/");
        j.remove(_currentDeleted[i]
          .split("/")
          .last);

        var k = _current.split("/");
        k.remove("");

        if (const ListEquality().equals(j, k)) {
          var l = _currentDeleted[i];
          _currentDeleted[i] = "$_location/$l";
        } else {
          _currentDeleted.removeAt(i);
        }
      }

      for (var i = 0; i < _currentDataStaged.length; i++) {
        var l = _currentDataStaged[i];
        _currentDataStaged[i] = "$_location/$l";
      }

      for (var i = 0; i < _currentDataUnstaged.length; i++) {
        var l = _currentDataUnstaged[i];
        _currentDataUnstaged[i] = "$_location/$l";
      }

      _currentDataAndDeleted = List.from(_currentData)..addAll(_currentDeleted);
      _currentDataAndDeleted.sort();
    });

    //print(_currentDataAndDeleted);
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Color deletedColor(String itemName) {
      if (_currentDeleted.contains(itemName)) {
        return Colors.grey;
      } else {
        return Colors.black;
      }
    }

    IconData stagingIcon(var itemName) {
      if (_currentDataStaged.contains(_currentDataAndDeleted[itemName])) {
        return Icons.add_circle;
      } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[itemName])) {
        return Icons.remove_circle;
      } else {
        return Icons.circle_outlined;
      }
    }

    Color stagingIconColor(var itemName) {
      if (_currentDataStaged.contains(_currentDataAndDeleted[itemName])) {
        return Colors.green;
      } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[itemName])) {
        return Colors.red;
      } else {
        return Colors.black;
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feta',
      home: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(_location.split("/").last),
          leading: GestureDetector(
            onTap: () async {
              // TODO: Find the directory for a new project.
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != 'null') {
                bool resultExists = await Directory(result!).exists();
                bool resultIsGit = await Directory("$result/.git").exists();
                //bool resultIsGit = await GitDir.isGitDir(result);
                if (resultExists) {
                  if (resultIsGit) {
                    var deletedResult = await Process.start(
                      "git", ["ls-files", "--deleted"],
                      workingDirectory: result);

                    var stagedResult = await Process.start(
                      "git", ["diff", "--name-only", "--staged"],
                      workingDirectory: result);

                    var unstagedResult = await Process.start(
                      "git", ["ls-files", "--exclude-standard", "--others", "-m"],
                      workingDirectory: result);

                    setState(() {
                      _location = result;
                      _current = '';
                    });

                    _currentUpdate(deletedResult, stagedResult, unstagedResult);
                  }
                }
              }
            },
            child: const Icon(Icons.add),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  // TODO: On click, launch a context menu for more options.
                },
                child: const Icon(Icons.more_horiz),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  _key.currentState!.openEndDrawer();
                  // TODO: Show the commit history on click.
                },
                child: const Icon(Icons.history),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () async {
                  var branchResult = await Process.start(
                    "git", ["branch", "-a"],
                    workingDirectory: _location);

                  branchResult.stdout
                    .transform(utf8.decoder)
                    .forEach((String out) => {
                      setState(() {
                        _branches = const LineSplitter().convert(out);
                      }),
                    });

                  setState(() {_sidebarContentState = "branches";});
                  _key.currentState!.openEndDrawer();
                  // DONE: Show the branch list on click.
                },
                child: const Icon(Icons.account_tree_outlined),
              ),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_location != 'null') ...[
                  for (var i = 0; i < _currentDataAndDeleted.length; i++)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(width: 1.5, color: Colors.black),
                          left: BorderSide(width: 1.5, color: Colors.black),
                          right: BorderSide(width: 1.5, color: Colors.black),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (_currentDataStaged.contains(_currentDataAndDeleted[i])) {
                                          await Process.run("git", ["reset", "--",
                                            _currentDataAndDeleted[i].replaceAll("$_location/", "")],
                                            workingDirectory: _location);
                                        } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[i])) {
                                          await Process.run("git", ["add",
                                            _currentDataAndDeleted[i].replaceAll("$_location/", "")],
                                            workingDirectory: _location);
                                        }

                                        var deletedResult = await Process.start(
                                          "git", ["ls-files", "--deleted"],
                                          workingDirectory: _location);

                                        var stagedResult = await Process.start(
                                          "git", ["diff", "--name-only", "--staged"],
                                          workingDirectory: _location);

                                        var unstagedResult = await Process.start(
                                          "git", ["ls-files", "--exclude-standard", "--others", "-m"],
                                          workingDirectory: _location);

                                        _currentUpdate(deletedResult, stagedResult, unstagedResult);
                                      },
                                      //onSecondaryTap: () {print("aeiou");},
                                      child: Icon(
                                        stagingIcon(i),
                                        color: stagingIconColor(i),
                                        size: 16.0),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      var deletedResult = await Process.start(
                                        "git", ["ls-files", "--deleted"],
                                        workingDirectory: _location);

                                      var stagedResult = await Process.start(
                                        "git", ["diff", "--name-only", "--staged"],
                                        workingDirectory: _location);

                                      var unstagedResult = await Process.start(
                                        "git", ["ls-files", "--exclude-standard", "--others", "-m"],
                                        workingDirectory: _location);

                                      if (await Directory(_currentData[i]).exists()) {
                                        Directory(_currentData[i]).listSync();

                                        setState(() {
                                          _current =
                                            _currentData[i].replaceAll(_location, "");

                                          if (_current.split("/").last == "..") {
                                            _current =
                                              _current.substring(0, _current.length - 3);
                                            _current = _current.replaceAll(_current
                                              .split("/").last, "");
                                            _current =
                                              _current.substring(0, _current.length - 1);
                                          }
                                        });

                                        _currentUpdate(deletedResult, stagedResult, unstagedResult);
                                      }
                                    },
                                    child: Text(_currentDataAndDeleted[i].split("/").last,
                                      style: TextStyle(
                                        color: deletedColor(_currentDataAndDeleted[i]),
                                        //color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Align(
                                alignment: Alignment.centerRight,
                                child: Text('*LAST COMMIT*') // TODO: Fill text with the file's last commit.
                            ),
                          ]
                      ),
                    ),
                  Container( // (Bottom border for decorations sake...)
                    height: 1.5,
                    decoration: const BoxDecoration(color: Colors.black),
                  ),
                ]
              ]
            ),
          ),
        ),
        endDrawer: Sidebar(_sidebarContentState, _branches, _location),
        onEndDrawerChanged: (isOpen) async {
          if (! isOpen) {
            var deletedResult = await Process.start(
              "git", ["ls-files", "--deleted"], // FIXME: Show file if staged but not committed.
              workingDirectory: _location);

            var stagedResult = await Process.start(
              "git", ["diff", "--name-only", "--staged"],
              workingDirectory: _location);

            var unstagedResult = await Process.start(
              "git", ["ls-files", "--exclude-standard", "--others", "-m"],
              workingDirectory: _location);

            _currentUpdate(deletedResult, stagedResult, unstagedResult);
          }
        },
      ),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    Color selectedColor(String i) {
      if (i[0] == '*') {
        return Colors.blue;
      } else {
        return Colors.black;
      }
    }

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.sidebarContent == "branches") ...[
              const Padding(
                padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 20.0, bottom: 15.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text("Branches"),
                ),
              ),
              for (var i = 0; i < widget.sidebarBranches.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        void checkoutBranch() async {
                          await Process.start(
                            "git", ["checkout",
                            widget.sidebarBranches[i]
                              .substring(2, widget.sidebarBranches[i].length)
                              .split(" -> ").last],
                              workingDirectory: widget.targetLocation); // TODO: Fix branching system.
                        }

                        checkoutBranch();
                        Navigator.pop(context);
                      },
                      child: Text(
                        widget.sidebarBranches[i]
                          .substring(2, widget.sidebarBranches[i].length)
                          .split(" -> ").last,

                        style: TextStyle(color: selectedColor(widget.sidebarBranches[i])),
                      ),
                    ),
                  ),
                ),
            ],
          ]
        ),
      ),
    ); // TODO: Extend sidebar for commit history.
  }
}

class Sidebar extends StatefulWidget {
  final String sidebarContent;
  final List sidebarBranches;
  final String targetLocation;
  const Sidebar(this.sidebarContent, this.sidebarBranches, this.targetLocation);

  @override
  State<Sidebar> createState() => _SidebarState();
}