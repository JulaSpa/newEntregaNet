import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:entreganet/album/album.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';
/* import 'package:firebase_core/firebase_core.dart'; */
import 'package:entreganet/src/providers.dart';
import 'package:entreganet/pages/custom.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _Inicio();
}

class _Inicio extends State<Inicio> with SingleTickerProviderStateMixin {
  var myController = TextEditingController();
  var nroCel = TextEditingController();
  late Future<List<Album>> futureAlbum;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late PushNotProv pushNotProv;
  bool firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    loadAlbumData();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_animationController.value *
              _scrollController.position.maxScrollExtent);
        }
      });
    _animationController.repeat();

    /*  WidgetsFlutterBinding.ensureInitialized();
    // Inicializa Firebase de manera asíncrona y espera a que esté listo
    Firebase.initializeApp().then((_) async {
      // La inicialización de Firebase se ha completado
      pushNotProv = PushNotProv();
      // ENVIA TOKEN A FIREBASE
      pushNotProv.initNotifications(); // Utiliza la instancia existente
      setState(() {
        firebaseInitialized = true; // Marca que Firebase se ha inicializado
      });
    }).catchError((error) {
      print("Error al inicializar Firebase: $error");
    }); */
  }

  void loadAlbumData() {
    futureAlbum = fetchAlbum().then((result) {
      return result;
    }).catchError((error) {
      print("Error fetching album: $error");
      return <Album>[]; // Devuelve una lista vacía en caso de error.
    });
  }

  Future<List<Album>> fetchAlbum() async {
    try {
      // Construye la URL con los parámetros de consulta
      final Uri url = Uri.parse(
        'http://sw.entreganet.com/puertosactivos.aspx?clave=1x49492A00E6BA0000F96B95',
      );

      print('Request URL: $url');

      // Realiza la solicitud HTTP POST
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods":
              "POST, GET, OPTIONS, PUT, DELETE, HEAD",
        },
        body: jsonEncode({}),
      );

      // Imprime el cuerpo de la respuesta}

      /* print('Response status: ${response.statusCode}');
      print('Response body DE INICIO: ${response.body}'); */

      // Manejo de la respuesta
      final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
      final jsonContent = response.body.replaceAll(exp, '');

      try {
        final Map<String, dynamic> responseJson = jsonDecode(jsonContent);
        // Extraer la lista de elementos desde la clave "Table" del mapa
        final List<dynamic> table = responseJson['Table'];

// Mapear cada elemento de la lista a un objeto Album usando Album.fromJson
        final List<Album> albums =
            table.map((albumJson) => Album.fromJson(albumJson)).toList();
        /* print("albums dep:");
        print(albums); */

        return albums;
      } catch (e) {
        print("Error decoding JSON: $e");
        throw Exception('Failed to decode JSON');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error during fetchAlbum: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/images/fondo.jpg"), // <-- BACKGROUND IMAGE
            fit: BoxFit.cover,
          ),
        ),
      ),
      CustomScaffold(
        appBar: AppBar(
          title: Image.asset("lib/images/entreganet-icon3.png"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 130,
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 130),
                constraints: const BoxConstraints(
                  minWidth: 0, // Ajusta la altura mínima según tus necesidades
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "ENTREGANET",
                      style: TextStyle(
                        color: Color.fromARGB(255, 252, 250, 250),
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),

              FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      prefixIcon: Icon(
                        Icons.car_rental_outlined,
                        color: Colors.white,
                      ),
                      labelText: "Patente o CUIT chofer",
                      labelStyle: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    //CONTROLADOR USUARIO
                    controller: myController,
                  ),
                ),
              ),

              const SizedBox(height: 35),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      prefixIcon: Icon(
                        Icons.phone_android_outlined,
                        color: Colors.white,
                      ),
                      labelText: "Número de teléfono (opcional)",
                      labelStyle: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    controller: nroCel,
                  ),
                ),
              ),
              FractionallySizedBox(
                child: Container(
                  padding: const EdgeInsets.only(top: 50, bottom: 15),
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: ElevatedButton(
                      //STATUS SIEMPRE 200

                      onPressed: () async {
                        if (myController.text.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const AlertDialog(
                                content:
                                    Text("Debes ingresar una patente o CUIT"),
                              );
                            },
                          );
                        } else {
                          final String patenteCUIT = myController.text;
                          final String nroCell = nroCel.text;
                          // Guardar en SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('patenteCUIT', patenteCUIT);
                          await prefs.setString('nroCell', nroCell);
                          Navigator.pushNamed(
                            context,
                            "/home",
                          );
                        }
                      },
                      child: const Text("Buscar"),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.only(top: 0, bottom: 10, left: 10),
                    child: const Text(
                      "Estamos en:",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ),

              // Expanded para mostrar la lista de puertos
              Container(
                padding: const EdgeInsets.only(top: 0, bottom: 20, left: 0),
                child: FutureBuilder<List<Album>>(
                  future: futureAlbum,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No data found'));
                    } else {
                      final albums = snapshot.data!;
                      return SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: albums.map((album) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                              ),
                              child: Text(
                                album.puerto,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
