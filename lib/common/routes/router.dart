
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/settings/routes_names.dart';
import 'package:restaurapp/page/SplashScreen/SplashScreen.dart';
import 'package:restaurapp/page/SplashScreen/Splash_controller.dart';
import 'package:restaurapp/page/categoria/categoria.dart';
import 'package:restaurapp/page/categoria/listarcategoria/listas_categoria.dart';
import 'package:restaurapp/page/home/HomeWrapper/home_wrapper.dart';
import 'package:restaurapp/page/home/home_pc_page.dart';
import 'package:restaurapp/page/home/homemovil/home_movil_page.dart';
import 'package:restaurapp/page/login/login_page.dart';
import 'package:restaurapp/page/menu/menu.dart';
import 'package:restaurapp/page/orders/crear/crear_orden.dart';
import 'package:restaurapp/page/orders/orders_page.dart';
import 'package:restaurapp/page/table/table_page.dart';
import 'package:restaurapp/pagewaring/tomarorden.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: RoutesNames.splashPage,
      page: () => SplashScreen(),
    ),
   GetPage(name: RoutesNames.loginPage, page: ()=>LoginPage()),
   GetPage(name: RoutesNames.homePage, page: ()=>HomeWrapper())
  ];

  static final unknownRoute = GetPage(
    name: '/not-found',
    page: () => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada'),
      ),
    ),
  );
}