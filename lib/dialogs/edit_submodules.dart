import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart'; // Flutter Material dependency.

class EditSubmodulesDialog extends StatefulWidget {
  final String location;
  final String current;
  final VoidCallback refresh;

  const EditSubmodulesDialog(this.location, this.current, this.refresh);

  @override
  State<EditSubmodulesDialog> createState() => _EditSubmodulesDialogState();
}

class _EditSubmodulesDialogState extends State<EditSubmodulesDialog> {
  List submodules = [];
  List submodulesUnsorted = [];
  List<String> submodulesFileOut = [];

  bool submoduleToBeAdded = false;
  bool submoduleBeingAdded = false;
  TextEditingController submodulesNewName = TextEditingController();
  final FocusNode submodulesNewNameFocus = FocusNode();
  TextEditingController submodulesNewPath = TextEditingController();
  TextEditingController submodulesNewUrl = TextEditingController();

  void _refreshSubmodules() {
    double submodulesCurrentEntry = -1;

    submodules = [];
    submodulesUnsorted = [];
    submodulesFileOut = [];

    if (File("${widget.location}/.gitmodules").existsSync()) {
      submodulesFileOut = const LineSplitter()
          .convert(File("${widget.location}/.gitmodules").readAsStringSync());

      for (var i = 0; i < submodulesFileOut.length; i++) {
        submodulesFileOut[i] = submodulesFileOut[i]
            .trim()
            .replaceAll("[", "")
            .replaceAll("]", "")
            .replaceAll('"', "");

        if (submodulesFileOut[i].startsWith("submodule")) {
          submodulesCurrentEntry++;
          submodulesUnsorted
              .add([submodulesFileOut[i].replaceAll("submodule ", "")]);
        }

        if (submodulesCurrentEntry >= 0 &&
            !submodulesFileOut[i].startsWith("submodule")) {
          submodulesUnsorted[submodulesCurrentEntry.toInt()]
              .add(submodulesFileOut[i]);
        }
      }

      for (var i = 0; i < submodulesUnsorted.length; i++) {
        submodules.add([submodulesUnsorted[i][0]]);

        for (var j = 0; j < submodulesUnsorted[i].length; j++) {
          if (submodulesUnsorted[i][j].startsWith("path")) {
            submodules[i]
                .add(submodulesUnsorted[i][j].replaceAll("path = ", ""));
          }
        }
        if (submodules[i].length < 2) {
          submodules[i].add("null");
        }

        for (var j = 0; j < submodulesUnsorted[i].length; j++) {
          if (submodulesUnsorted[i][j].startsWith("url")) {
            submodules[i]
                .add(submodulesUnsorted[i][j].replaceAll("url = ", ""));
          }
        }
        if (submodules[i].length < 3) {
          submodules[i].add("null");
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _refreshSubmodules();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Submodules'),
      insetPadding: const EdgeInsets.all(32),
      content: submodules.isNotEmpty
          ? SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Table(
                border: const TableBorder(
                  horizontalInside: BorderSide(width: 1.5, color: Colors.black),
                  verticalInside: BorderSide(width: 1.5, color: Colors.black),
                ),
                columnWidths: <int, TableColumnWidth>{
                  0: const IntrinsicColumnWidth(),
                  1: const IntrinsicColumnWidth(),
                  2: const FlexColumnWidth(),
                  3: FixedColumnWidth(submoduleToBeAdded ? 48 : 32),
                },
                children: [
                  TableRow(
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Name   ",
                              style: TextStyle(color: Colors.grey))),
                      const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Path   ",
                              style: TextStyle(color: Colors.grey))),
                      const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("URL    ",
                              style: TextStyle(color: Colors.grey))),
                      Container(),
                    ],
                  ),
                  for (var i = 0; i < submodules.length; i++) ...[
                    TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: SelectableText("${submodules[i][0]}   ",
                                style: TextStyle(
                                    color: submodules[i][0] != "null"
                                        ? Colors.black
                                        : Colors.grey))),
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: SelectableText("${submodules[i][1]}   ",
                                style: TextStyle(
                                    color: submodules[i][0] != "null"
                                        ? Colors.black
                                        : Colors.grey))),
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: SelectableText("${submodules[i][2]}  ",
                                style: TextStyle(
                                    color: submodules[i][0] != "null"
                                        ? Colors.black
                                        : Colors.grey))),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            padding: const EdgeInsets.only(top: 3),
                            icon: const Icon(Icons.delete, color: Colors.black),
                            onPressed: () async {
                              await Process.run(
                                  "git", ["rm", "-rf", submodules[i][1]],
                                  workingDirectory: widget.location);

                              await Directory(
                                      "${widget.location}/.git/modules/${submodules[i][0]}")
                                  .delete(recursive: true);

                              _refreshSubmodules();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (submoduleToBeAdded) ...[
                    TableRow(
                      children: [
                        TextField(
                          controller: submodulesNewName,
                          focusNode: submodulesNewNameFocus,
                          enabled: !submoduleBeingAdded,
                          decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                  left: 6, right: 6, top: 9, bottom: 9)),
                        ),
                        TextField(
                          controller: submodulesNewPath,
                          enabled: !submoduleBeingAdded,
                          decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                  left: 6, right: 6, top: 9, bottom: 9)),
                        ),
                        TextField(
                          controller: submodulesNewUrl,
                          enabled: !submoduleBeingAdded,
                          decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                  left: 6, right: 6, top: 9, bottom: 9)),
                        ),
                        Row(
                          children: [
                            if (!submoduleBeingAdded) ...[
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  padding:
                                      const EdgeInsets.only(top: 3, left: 2),
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.black),
                                  onPressed: () async {
                                    setState(() {
                                      submoduleBeingAdded = true;
                                    });

                                    await Process.run(
                                        "git",
                                        [
                                          "submodule",
                                          "add",
                                          "--name",
                                          submodulesNewName.text,
                                          submodulesNewUrl.text,
                                          submodulesNewPath.text
                                        ],
                                        workingDirectory: widget.location);

                                    _refreshSubmodules();
                                    setState(() {
                                      submoduleToBeAdded = false;
                                      submoduleBeingAdded = false;
                                      submodulesNewName.text = "";
                                      submodulesNewPath.text = "";
                                      submodulesNewUrl.text = "";
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  padding: const EdgeInsets.only(top: 3),
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      submodulesNewName.text = "";
                                      submodulesNewPath.text = "";
                                      submodulesNewUrl.text = "";
                                      submoduleToBeAdded = false;
                                    });
                                  },
                                ),
                              ),
                            ] else ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 14, top: 5),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ))
          : const Text("No submodules to be found!"),
      actions: [
        TextButton(
            onPressed: submoduleToBeAdded
                ? null
                : () {
                    setState(() {
                      submoduleToBeAdded = true;
                    });
                    submodulesNewNameFocus.requestFocus();
                  },
            child: const Text("Add Submodule")),
        TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              widget.refresh();
            },
            child: const Text("OK")),
      ],
    );
  }
}
