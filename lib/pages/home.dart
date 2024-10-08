import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:entreganet/album/album.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';
/* import 'package:firebase_core/firebase_core.dart'; */
import 'package:entreganet/src/providers.dart';
import 'package:platform_device_id_v3/platform_device_id.dart';
import 'package:entreganet/pages/custom.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? patente;
  String? celu;
  late Future<List<Album>> futureAlbum;
  bool isLoading = true;
  bool isRefreshing = false;
  late PushNotProv pushNotProv;
  bool firebaseInitialized = false;
  List<MensajesArguments>? lastMessage;
  List<MensajesArguments>? lastm;
  String? tok;
  bool? _dataSent; //DATA SENT TODAVÍA SIN USO POR NO TENER API DE FIREBASE
  String? deviceId;
  @override
  void initState() {
    super.initState();
    _getStoredUserData();
    _getDeviceId();
  }

  Future<void> _getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPatente = prefs.getString('patenteCUIT');
    final storedCelu = prefs.getString('nroCell');
    final storedTok = prefs.getString("tok");

    final dataSentValue = prefs.getBool('_dataSent') ?? false;

    setState(() {
      patente = storedPatente;
      celu = storedCelu;
      tok = storedTok;
      _dataSent = dataSentValue;
    });
    print("PATENTE Y CELU");
    print(patente);
    print(celu);
    print("token");
    print(tok);
    print("datasent?");
    print(_dataSent);
    _loadAlbumData();
  }

  Future<void> _getDeviceId() async {
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
      _loadAlbumData();
    } catch (e) {
      print("Error al obtener el identificador del dispositivo: $e");
      deviceId = null;
    }
  }

  void _loadAlbumData() async {
    if (patente != null && celu != null && tok != null) {
      futureAlbum = fetchAlbum(patente!, celu!, tok!).then((result) {
        return result;
      }).catchError((error) {
        print("Error fetching album: $error");
        return <Album>[]; // Devuelve una lista vacía en caso de error.
      }).whenComplete(() {
        setState(() {
          // Cuando se complete la operación, establece isLoading en falso.
          isLoading = false;
        });
      });
    } else {
      print("Patente o celu son nulos");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Album>> fetchAlbum(
      String patente, String celu, String tok) async {
    try {
      // Construye la URL con los parámetros de consulta
      final Uri url = Uri.parse(
        'http://sw.entreganet.com/camiones.aspx?busca=$patente&numcel=$celu&token=$tok&clave=1x49492A00E6BA0000F96B95',
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
      print('Response body: ${response.body}'); */

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
          title: Row(
            children: [
              Image.asset("lib/images/entreganet-icon4.png"),
              const SizedBox(width: 10),
              const Text(
                'ENTREGANET',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          automaticallyImplyLeading: true,
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : FutureBuilder<List<Album>>(
                    future: futureAlbum,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No data found'),
                        );
                      } else {
                        final albums = snapshot.data!;
                        return ListView.builder(
                          itemCount: albums.length,
                          itemBuilder: (context, index) {
                            final album = albums[index];
                            final situacionLowercase =
                                album.situacion.toLowerCase();
                            Color backgroundColor =
                                Color.fromARGB(255, 20, 81, 151);
                            if (situacionLowercase == 'rechazo' ||
                                situacionLowercase == 'desviado' ||
                                situacionLowercase == 'demorado') {
                              backgroundColor = Colors.red;
                            } else if (situacionLowercase == 'autorizado' ||
                                situacionLowercase == 'aceptado' ||
                                situacionLowercase == 'descargado') {
                              backgroundColor = Colors.green;
                            }
                            return Card(
                              color: Colors.black.withOpacity(0.5),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              child: Column(
                                children: [
                                  album.logourl.isNotEmpty
                                      ? SizedBox(
                                          width: double.infinity,
                                          child: Image.network(
                                            album.logourl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Text(
                                                album.entregador,
                                                style: const TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Text(
                                          album.entregador,
                                          style: const TextStyle(
                                            fontSize: 25,
                                            color: Colors.white,
                                          ),
                                        ),
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Número CP:",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    album.nrocp,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Turno:",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    album.turno,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Puerto:",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    album.puerto,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Titular:",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    album.titular,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Chasis:",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    album.chasis,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Producto:",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    album.producto,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Container(
                                          color: backgroundColor,
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                "Situación:",
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                album.situacion,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Información actual:",
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              album.analisis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
        ),
      )
    ]);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true; // Indica que se está realizando una actualización
    });

    try {
      await _getStoredUserData(); // Actualiza los datos almacenados si es necesario
      _loadAlbumData(); // Vuelve a cargar los datos del álbum

      setState(() {
        isRefreshing = false; // Completa la actualización
      });
    } catch (error) {
      setState(() {
        isRefreshing = false; // Manejo de errores
      });
      print("Error al actualizar: $error");
      // Puedes mostrar un mensaje de error o manejarlo según sea necesario
    }
  }
}
