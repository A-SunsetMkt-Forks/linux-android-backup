import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import "dart:io";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linux Android Backup',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      themeMode: ThemeMode.system,
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  Future<void> backup(BuildContext context) async {
    // Requests contacts & internal storage permissions
    if (await FlutterContacts.requestPermission() &&
        (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted)) {
      // Get all contacts
      List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true, withGroups: true);

      // Recreate the temp directory if it already exists.
      var directory =
          Directory("/storage/emulated/0/linux-android-backup-temp");
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
      }

      // Loop over the contacts and save them as a vCard.
      for (var i = 0; i < contacts.length; i++) {
        String vCard = contacts[i].toVCard(withPhoto: true);
        File file = File(
            "/storage/emulated/0/linux-android-backup-temp/linux-android-backup-contact-$i.vcf");
        file.writeAsString(vCard);
      }

      // Show a snackbar if the export is complete
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "Data exported - please continue the backup process on your computer."),
        duration: Duration(seconds: 60),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Storage and/or contacts permissions have not been granted."),
        duration: Duration(seconds: 5),
      ));

      await openAppSettings();
    }
  }

  Future<void> autoRestoreContacts(BuildContext context) async {
    // Requests contacts & internal storage permissions
    if (await FlutterContacts.requestPermission() &&
        (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted)) {
      final contactsDir = Directory("/storage/emulated/0/Contacts_Backup");
      if (await contactsDir.exists()) {
        // List directory contents
        final List<FileSystemEntity> files = await contactsDir.list().toList();

        // Loop over the contents
        for (var i = 0; i < files.length; i++) {
          if (files[i] is File) {
            // If the entity is a file, read its contents as a vCard and insert it into Android's contact database
            final vcard = await (files[i] as File).readAsString();
            final contact = Contact.fromVCard(vcard);
            await contact.insert();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("The contact backup directory couldn't be found."),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Storage and/or contacts permissions have not been granted."),
      ));

      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linux Android Backup Companion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            const Text(
              "The Linux Android Backup companion app allows for backups of your contacts, with more to come. It doesn't upload your data to a remote server: data is saved to the internal storage and then read by the script running on your computer.",
            ),
            ElevatedButton(
              onPressed: () {
                backup(context);
              },
              child: const Text("Export Data"),
            ),
            const Text(
              "Upon restoring a backup, press the button below to automatically import all contacts.",
            ),
            ElevatedButton(
              onPressed: () {
                autoRestoreContacts(context);
              },
              child: const Text("Auto-restore contacts"),
            )
          ],
        ),
      ),
    );
  }
}