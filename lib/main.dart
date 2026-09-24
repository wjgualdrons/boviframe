import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../firebase_options.dart';
import '../models/evaluacion_model.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/main_menu.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/settings_screen.dart';
import '../screens/epmuras/datos_productor.dart';
import '../screens/epmuras/epmuras_screen.dart';
import '../screens/epmuras/new_session_screen.dart';
import '../screens/epmuras/session_details_screen.dart';
import '../screens/epmuras/session_summary_screen.dart';
import '../screens/providers/session_provider.dart';
import '../screens/providers/theme_provider.dart';
import '../screens/consulta_animal_screen.dart';
import '../screens/consulta_screen.dart';
import '../screens/providers/auth_provider.dart' as my_auth;
import '../screens/consulta_finca_screen.dart';
import '../screens/editar_finca_screen.dart';
import 'package:boviframe/screens/epmuras/animal_evaluation_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../screens/epmuras/edit_session_screen.dart';
import '../screens/epmuras/edit_producer.dart';
import '../screens/dashboard_screen.dart';
import '../screens/indice_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../screens/epmuras/edit_session_selector.dart';
import '../screens/animal_detail_screen.dart';
import '../screens/providers/user_provider.dart';
import '../screens/providers/settings_provider.dart';
import '../screens/new_public_screen.dart';
import '../screens/new_detail_screen.dart';
import '../screens/new_admin_create_screen.dart';
import '../screens/new_admin_screen.dart';
import '../screens/bases_teoricas.dart';
import '../services/connectivity_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  await Hive.initFlutter();
  Hive.registerAdapter(EvaluacionAnimalAdapter());
  tz.initializeTimeZones();

  // Iniciar escucha de conectividad para sincronizaciÃ³n offline
  iniciarEscuchaInternet();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => my_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        final snackBar = SnackBar(
          content: Text('${notification.title}: ${notification.body}'),
          duration: const Duration(seconds: 3),
        );

        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    });

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'BOVIFrame',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          locale: const Locale('es', ''), // â¬…ï¸ EspaÃ±ol
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', ''), // â¬…ï¸ EspaÃ±ol
          ],
          routes: {
            '/login': (_) => LoginScreen(),
            '/register': (_) => RegisterScreen(),
            '/forgot_password': (_) => ForgotPasswordScreen(),
            '/main': (_) => MainMenu(),
            '/news_public': (_) => const NewsPublicScreen(),
            '/news_create': (_) => NewsAdminCreateScreen(),
            '/news_admin': (_) => NewsAdminScreen(),
            '/main_menu': (_) => MainMenu(),
            '/epmuras': (_) => EpmurasScreen(),
            '/settings': (_) => SettingsScreen(),
            '/session_details': (_) => SessionDetailsScreen(),
            '/consulta': (_) => ConsultaScreen(),
            '/index': (_) => IndiceScreen(),
            '/stats': (_) => DashboardScreen(),
            '/consulta_animal': (_) => ConsultaAnimalScreen(),
            '/consulta_finca': (_) => ConsultaFincaScreen(),
            '/animal_evaluation': (_) => AnimalEvaluationScreen(),
            '/theory': (_) => const EpmurasInfographic(),
            '/editar_finca': (_) => EditarFincaScreen(),
            '/edit_session_selector': (_) => EditSessionSelectorScreen(),
            '/edit_producer': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return EditProducerScreen(
                sessionId: args['sessionId'],
                initialData: args['producerData'],
              );
            },
            '/edit_evaluation': (ctx) {
              final args =
                  ModalRoute.of(ctx)!.settings.arguments
                      as Map<String, dynamic>;
              return AnimalEvaluationScreen.edit(
                docId: args['docId'],
                initialData: args['initialData'],
              );
            },
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/new_session':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder:
                      (_) => NewSessionScreen(
                        sessionId: args?['sessionId'],
                        numeroSesion: args?['numeroSesion'],
                      ),
                );

              case '/datos_productor':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder:
                      (_) => DatosProductorScreen(sessionId: args['sessionId']),
                );
              case '/session_summary':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder:
                      (_) => SessionSummaryScreen(
                        sessionId: args['session_id'] as String,
                        sessionData: args['session_data'],
                      ),
                );
              case '/edit_session':
                final sessionId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => EditSessionScreen(sessionId: sessionId),
                );
              case '/animal_detail':
                final data = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => AnimalDetailScreen(animalData: data),
                );
              case '/news_detail':
                final docId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(documentId: docId),
                );
              default:
                return null;
            }
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}



