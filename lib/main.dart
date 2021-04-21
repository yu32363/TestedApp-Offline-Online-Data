import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dbsync_app/database_helper.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:provider/provider.dart';
import 'Providers/SendNameProvider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SendNameProvider(),
        ),
      ],
      child: MaterialApp(
        home: MyHome(),
        theme: ThemeData(
          primaryColor: Colors.indigo,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
            ),
          ),
        ),
      ),
    );
  }
}

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  // reference to our single class that manages the database
  final dbHelper = DatabaseHelper.instance;
  final _text = TextEditingController();
  List data = [];
  // homepage layout
  bool _connectionStatus;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _getAllData();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _query() async {
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach((row) => print(row));
  }

  Future<dynamic> _getUnSyncRecords() async {
    final allRows = await dbHelper.queryUnSyncRecords();
    print('query all un sync:');
    allRows.forEach((row) => print(row));
    return allRows;
  }

  Future<dynamic> queryAllRecords() async {
    final allData = await dbHelper.queryAllRecords();
    print('query all un sync:');
    return allData;
  }

  void _update(id, name) async {
    // row to update
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnName: name,
      DatabaseHelper.status: 1
    };
    final rowsAffected = await dbHelper.update(row);
    print('updated $rowsAffected row(s)');
  }

  void _delete() async {
    // Assuming that the number of rows is the id for the last row.
    final id = await dbHelper.queryRowCount();
    final rowsDeleted = await dbHelper.delete(id);
    print('deleted $rowsDeleted row(s): row $id');

    setState(() {
      _getAllData();
    });
  }

  _syncItNow(_connectionStatus) async {
    final nameProvider = Provider.of<SendNameProvider>(context, listen: false);
    if (_connectionStatus == true) {
      var allRows = await _getUnSyncRecords();
      allRows.forEach((row) async {
        await nameProvider.sync(row['name'], _connectionStatus);
        await _update(row['id'], row['name']);
      });
    }
  }

  void _getAllData() async {
    data.clear();
    var allRows = await queryAllRecords();
    allRows.forEach((row) async {
      data.add(row);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nameProvider = Provider.of<SendNameProvider>(context, listen: false);

    return Scaffold(
        appBar: AppBar(
          title: Text("SQLite Sync to Server"),
          actions: [
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _getAllData();
                  });
                })
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              OfflineBuilder(
                connectivityBuilder: (
                  BuildContext context,
                  ConnectivityResult connectivity,
                  Widget child,
                ) {
                  _connectionStatus = connectivity != ConnectivityResult.none;
                  if (_connectionStatus) {
                    _syncItNow(_connectionStatus);
                  }

                  return Stack(children: [child]);
                },
                builder: (BuildContext context) {
                  return SizedBox();
                },
              ),
              SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: MediaQuery.of(context).size.width * 1,
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            child: Text(
                              'Check Sync',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.green),
                            ),
                            onPressed: () {
                              _query();
                            },
                          ),
                          TextButton(
                            child: Text(
                              'Check Un Sync',
                              style: TextStyle(fontSize: 20, color: Colors.red),
                            ),
                            onPressed: () {
                              _getUnSyncRecords();
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 1,
                          height: MediaQuery.of(context).size.height * 0.1,
                          child: Row(
                            children: [
                              Expanded(
                                child: Card(
                                  child: TextField(
                                    controller: _text,
                                    decoration: InputDecoration(
                                        hintText: 'Enter the Value',
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.only(left: 10)),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    nameProvider
                                        .addName(_text.text, _connectionStatus)
                                        .then((value) {
                                      _text.clear();
                                      _getAllData();
                                    });
                                  });
                                },
                                child: Text(
                                  'Submit',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        child: Text(
                          'Delete',
                          style: TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          _delete();
                        },
                      ),
                      Container(
                          height: 400.0,
                          child: ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, i) {
                              return ListTile(
                                title: Text(data[i]['name']),
                                trailing: data[i]['status'] != 0
                                    ? Icon(Icons.check)
                                    : Icon(Icons.clear),
                              );
                            },
                          ))
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  // Button onPressed methods

}
