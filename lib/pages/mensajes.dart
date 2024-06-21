import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Mensajes extends StatefulWidget {
  const Mensajes({super.key});

  @override
  State<Mensajes> createState() => _Mensajes();
}

class _Mensajes extends State<Mensajes> {
  bool? msjC;
  List? title;
  List? text;
  @override
  void initState() {
    super.initState();
    // Imprimir los argumentos al inicializar la página
    /* print("Arguments in Mensajes: ${widget.arguments}"); */
    getStoredUserData();
  }

  Future<void> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      msjC = prefs.getBool("msjC") ?? false;
      title = prefs.getStringList("m");
      text = prefs.getStringList("mb");
    });
    print("/mensajes title y text");
    print(title);
    print(text);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/images/fondo.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Image.asset("lib/images/entreganet-icon4.png"),
            backgroundColor: Colors.blue,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 60,
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && text != null)
                  for (int i = 0; i < title!.length; i++)
                    IntrinsicWidth(
                      child: Card(
                        margin: const EdgeInsets.only(
                            bottom: 10, top: 10, left: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.message,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    title![i],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                text![i],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                if (title == null ||
                    text == null ||
                    title!.isEmpty ||
                    text!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 10, left: 20),
                    child: Text(
                      'No tienes mensajes.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Mostrar el cuadro de diálogo de confirmación
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirmación"),
                    content: const Text(
                        "¿Estás seguro de que deseas eliminar los mensajes?"),
                    actions: [
                      // Botón para cancelar
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancelar"),
                      ),
                      // Botón para confirmar y eliminar mensajes
                      TextButton(
                        onPressed: () async {
                          // Acción que se realiza al confirmar
                          Navigator.of(context)
                              .pop(); // Cerrar el cuadro de diálogo

                          // Eliminar títulos y textos de SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove("m");
                          await prefs.remove("mb");

                          // Actualizar la interfaz de usuario para reflejar el cambio
                          setState(() {
                            title = null;
                            text = null;
                          });
                          Navigator.pushNamed(context, "/inicio");
                        },
                        child: const Text("Confirmar"),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.delete),
            backgroundColor: Colors.red,
          ),
        )
      ],
    );
  }
}
