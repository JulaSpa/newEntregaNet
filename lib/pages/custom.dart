import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:entreganet/src/providers.dart';

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final String? lastMessage;
  final PreferredSizeWidget? appBar;
  final bool showFloatingButton;

  const CustomScaffold({
    Key? key,
    required this.body,
    this.lastMessage,
    this.appBar,
    this.showFloatingButton = true,
  }) : super(key: key);

  @override
  _CustomScaffoldState createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  late PushNotProv pushNotProv;
  bool firebaseInitialized = false;
  List<MensajesArguments>? lastMessage;
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    // Inicializa Firebase de manera asíncrona y espera a que esté listo
    Firebase.initializeApp().then((_) async {
      // La inicialización de Firebase se ha completado
      pushNotProv = PushNotProv();
      // ENVIA TOKEN A FIREBASE
      pushNotProv.initNotifications(); // Utiliza la instancia existente
      setState(() {
        firebaseInitialized = true; // Marca que Firebase se ha inicializado
      });
      pushNotProv.mensajes.listen((List<MensajesArguments> messages) async {
        setState(() {
          lastMessage = messages;
        });
      });
    }).catchError((error) {
      print("Error al inicializar Firebase: $error");
    });
    print("last message");
    print(lastMessage?.length);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      appBar: widget.appBar,
      body: widget.body,
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                "/mensajes",
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.message),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lastMessage != null && lastMessage!.isNotEmpty
                    ? Colors.red
                    : Colors.transparent,
              ),
              child: Text(
                lastMessage != null && lastMessage!.isNotEmpty
                    ? "${lastMessage!.length}" // Muestra el número de mensajes no leídos
                    : "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
