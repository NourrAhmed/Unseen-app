import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/SplashScreen.dart';
import 'screens/HomePage.dart';
import 'screens/SignUpPage.dart';
import 'screens/main_navigation.dart';
import 'screens/LoginPage.dart';
import 'screens/Settings.dart';
import 'screens/profile.dart'; 
import 'screens/Saved_UnSeen.dart';
// ViewModels
import 'viewmodels/user_vm.dart';
import 'viewmodels/unseen_vm.dart';
import 'viewmodels/search_vm.dart';
import 'viewmodels/category_vm.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // DEV: optional logout on app start
  await FirebaseAuth.instance.signOut();

  runApp(const UnseenApp());
}

class UnseenApp extends StatelessWidget {
  const UnseenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => UnSeenViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
      ],
      child: MaterialApp(
        title: 'Unseen App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/main': (context) => const MainNavigation(),
          '/home': (context) => const HomePage(),
          '/signup': (context) => const SignupPage(),
          '/login': (context) => const LoginPage(),
          '/settings': (context) => const Settings(),
          '/profile': (context) => const Profile(),
          '/saved': (context) => const Saved(),
        },
      ),
    );
  }
}
