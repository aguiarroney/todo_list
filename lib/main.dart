import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  List _toDoListBackup = [];
  TextEditingController _toDoController = TextEditingController();
  Map<String, dynamic> _ultimoRemovido;
  int _ultimoPos;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _readData().then((dados) {
      setState(() {
        if (dados != null) {
          _toDoList = json.decode(dados);
        }
      });
    });
  }

  void addToDo() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      if (_toDoController.text != "") {
        novaTarefa["title"] = _toDoController.text;
        _toDoController.text = ""; // limpa o controlador
        novaTarefa["ok"] = false;
        _toDoList.add(novaTarefa);
        _saveData();
      } else {
        print("Tarefa invalida");
      }
    });
  }

  Future<File> _getFile() async {
    final diretorio = await getApplicationDocumentsDirectory();
    print("Diretorio : ${diretorio.path}/dados.json");
    return File("${diretorio.path}/dados.json");
  }

  Future<File> _saveData() async {
    String dados = json.encode(_toDoList);
    final arquivo = await _getFile();
    return arquivo.writeAsString(dados);
  }

  Future<String> _readData() async {
    try {
      final arquivo = await _getFile();
      return arquivo.readAsString();
    } catch (erro) {
      return null;
    }
  }

  void _doNothing (){
    print("dummy");
  }

   void _delete() async {
    final arquivo = await _getFile();
    setState(() {
      arquivo.deleteSync();
      _toDoListBackup.addAll(_toDoList);
      print("lista de back up antes : ${_toDoListBackup}");
      _toDoList.removeRange(0, _toDoList.length);
      _saveData();

      final snack = SnackBar(
        content: Text("Tarefas deletadas"),
        action: SnackBarAction(
          label: "Desfazer",
          onPressed: (){
            setState(() {
              print("lista de back up onPressed: ${_toDoListBackup}");
              _toDoList.addAll(_toDoListBackup);
              _toDoListBackup.removeRange(0, _toDoListBackup.length);
              _saveData();
            });
          },
        ),
        duration: Duration(seconds: 3),
      );

      _scaffoldKey.currentState.removeCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(snack);
    });
  }

  Future<Null> _refresh() async {
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

      _saveData();
    });
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.redAccent,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          backgroundColor: _toDoList[index]["ok"] ? Colors.greenAccent : Colors.amberAccent,
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error,
            color: Colors.white,
          ),
        ),
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _ultimoRemovido = Map.from(_toDoList[index]);
          _ultimoPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_ultimoRemovido["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_ultimoPos, _ultimoRemovido);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _toDoList.length > 0? _delete : _doNothing,
          )
        ],
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: Text(
          "Lista de tarefas",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.deepPurple)),
                  ),
                ),
                RaisedButton(
                  color: Colors.deepPurple,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }
}
