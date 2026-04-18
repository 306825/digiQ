import 'package:flutter/material.dart';

class _DocumentTile extends StatelessWidget {
  final String title;
  final String? url;

  const _DocumentTile(this.title, this.url);

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return ListTile(
        title: Text(title),
        subtitle: const Text('Not uploaded'),
      );
    }

    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(
                "https://api.digiqueue.co.za/uploads/$url",
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
