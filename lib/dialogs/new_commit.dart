import 'package:flutter/material.dart';

AlertDialog newCommitDialog(
    BuildContext context, var newCommitFunction, String commitChanges) {
  TextEditingController commitMessage = TextEditingController();

  return AlertDialog(
    title: const Text('New Commit'),
    content: SizedBox(
      height: 200,
      child: Column(
        children: [
          TextField(
            controller: commitMessage,
            decoration: const InputDecoration(
              hintText: "Message",
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 30.0, bottom: 5.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text("Items to be committed:"),
            ),
          ),
          Container(
            width: 240,
            constraints: const BoxConstraints(
              maxHeight: 80,
            ),
            decoration: BoxDecoration(
                border: Border.all(
              color: Colors.black,
              width: 1,
            )),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    commitChanges,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel")),
      TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            newCommitFunction(commitMessage.text);
          },
          child: const Text("Apply")),
    ],
  );
}