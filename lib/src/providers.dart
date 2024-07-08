import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MensajesArguments {
  final List<String> title;
  final List<String> body;

  MensajesArguments({required this.title, required this.body});
}

class PushNotProv {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<MensajesArguments> mensajesList = [];
  final _mensajeStreamControll =
      StreamController<List<MensajesArguments>>.broadcast();
  Stream<List<MensajesArguments>> get mensajes => _mensajeStreamControll.stream;
// TEST SOUND
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  PushNotProv() {
    _loadStoredMessages(); // Cargar mensajes almacenados al iniciar
    _initializeNotifications(); //TEST SOUND
  }

// TEST SOUND
  Future<void> _initializeNotifications() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS =
        const DarwinInitializationSettings(); // iOS initialization settings
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
//TEST SOUND FINISH

  Future<void> _loadStoredMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTitles = prefs.getStringList('m') ?? [];
    final storedBodies = prefs.getStringList('mb') ?? [];
    // Crear mensajes a partir de los datos almacenados
    mensajesList = storedTitles
        .asMap()
        .entries
        .map((entry) => MensajesArguments(
              title: [entry.value],
              body: [storedBodies[entry.key]],
            ))
        .toList();
    // Agregar los mensajes cargados al stream
    _mensajeStreamControll.add(mensajesList);
  }

  initNotifications() {
    messaging.requestPermission();
    messaging.getToken().then((token) async {
      print("TOKEN en providers:");
      print(token);
      final String tok = token!;

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tok', tok);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        // Almacena el último mensaje

        MensajesArguments newMessage = MensajesArguments(
          title: [message.notification?.title ?? "no-data"],
          body: [message.notification?.body ?? "no-data"],
        );
        // Añade el mensaje a la lista
        mensajesList.add(newMessage);

        // Añade el mensaje al stream
        _mensajeStreamControll.add(mensajesList);

        // Acumula los nuevos títulos y cuerpos
        List<String> accumulatedTitles = [];
        List<String> accumulatedBodies = [];
        for (var e in mensajesList) {
          accumulatedTitles.addAll(e.title);
          accumulatedBodies.addAll(e.body);
        }

        // Actualiza SharedPreferences con los nuevos títulos y cuerpos acumulados
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('m', accumulatedTitles);
        await prefs.setStringList('mb', accumulatedBodies);
        // Mostrar una notificación local con sonido
        _showNotification(message);
      }
    });

    // Manejar notificaciones cuando la aplicación está en segundo plano y el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.notification != null) {
        // Almacena el último mensaje

        MensajesArguments newMessage = MensajesArguments(
          title: [message.notification?.title ?? "no-data"],
          body: [message.notification?.body ?? "no-data"],
        );

        mensajesList.add(newMessage);

        // Añade el mensaje al stream
        _mensajeStreamControll.add(mensajesList);
        // Acumula los nuevos títulos y cuerpos
        List<String> accumulatedTitles = [];
        List<String> accumulatedBodies = [];
        for (var e in mensajesList) {
          accumulatedTitles.addAll(e.title);
          accumulatedBodies.addAll(e.body);
        }

        // Actualiza SharedPreferences con los nuevos títulos y cuerpos acumulados
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('m', accumulatedTitles);
        await prefs.setStringList('mb', accumulatedBodies);
      }
    });

    // Manejar notificaciones cuando la aplicación está completamente cerrada y el usuario toca la notificación
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (message.notification != null) {
      // Almacena el último mensaje

      MensajesArguments newMessage = MensajesArguments(
        title: [message.notification?.title ?? "no-data"],
        body: [message.notification?.body ?? "no-data"],
      );

      mensajesList.add(newMessage);

      // Añade el mensaje al stream
      _mensajeStreamControll.add(mensajesList);
      // Acumula los nuevos títulos y cuerpos
      List<String> accumulatedTitles = [];
      List<String> accumulatedBodies = [];
      for (var e in mensajesList) {
        accumulatedTitles.addAll(e.title);
        accumulatedBodies.addAll(e.body);
      }

      // Actualiza SharedPreferences con los nuevos títulos y cuerpos acumulados
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('m', accumulatedTitles);
      await prefs.setStringList('mb', accumulatedBodies);
    }
  }

  // SOUND TEST
  Future<void> _showNotification(RemoteMessage message) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'channel id 8', 'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification'));
    var iOSPlatformChannelSpecifics =
        const DarwinNotificationDetails(); // iOS notification details
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
        message.notification?.body, platformChannelSpecifics,
        payload: 'item x');
  }

  dispose() {
    _mensajeStreamControll.close();
  }
}
