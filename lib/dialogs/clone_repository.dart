import 'package:flutter/material.dart'; // Flutter Material dependency.
import 'package:file_picker/file_picker.dart'; // File picker for clone location.
import 'package:gitbang/dialogs/error.dart'; // Error dialog worst-case.

AlertDialog cloneRepositoryDialog(BuildContext context, var cloneRepoFunction) {
  TextEditingController repositoryToClone = TextEditingController();
  TextEditingController locationToCloneTo = TextEditingController();

  bool cloneRecursively = true;

  return AlertDialog(
    title: const Text('Clone Repository'),
    content: SizedBox(
      height: 100,
      child: Column(
        children: [
          TextField(
            controller: repositoryToClone,
            decoration: const InputDecoration(
              hintText: "Repository",
            ),
          ),
          TextField(
            controller: locationToCloneTo,
            decoration: InputDecoration(
              hintText: "Location",
              suffixIcon: IconButton(
                icon: const Icon(Icons.create_new_folder),
                onPressed: () async {
                  locationToCloneTo.text =
                      (await FilePicker.platform.getDirectoryPath())!;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Checkbox(
                  value: cloneRecursively,
                  onChanged: (bool? i) {},
                ),
                const Text("Clone submodules? (recursive)"),
              ],
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
          onPressed: () {
            Navigator.of(context).pop();
            late BuildContext loadingContext;

            void pop() {
              Navigator.of(loadingContext).pop();
            }

            void work() async {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    loadingContext = context;
                    return const Center(child: CircularProgressIndicator());
                  });

              try {
                await cloneRepoFunction(
                    repositoryToClone.text, locationToCloneTo.text, cloneRecursively);
              } catch (e) {
                Future.delayed(
                    const Duration(seconds: 0),
                    () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return errorMessageDialog(
                              context, "Unable to clone repository.");
                        }));
                pop();
              }

              pop();
            }

            work();
          },
          child: const Text("Clone")),
    ],
  );
}
