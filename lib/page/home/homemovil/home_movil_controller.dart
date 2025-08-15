import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/UserProfile/UserProfileScreen.dart';
import 'package:restaurapp/page/user/UserManagementScreen.dart';
import 'package:restaurapp/page/orders/crear/crear_orden.dart';
import 'package:restaurapp/page/orders/orders_page.dart';
import 'package:restaurapp/page/orders/pagedesktop/ordenes_page_desktop.dart';

class HomeMovilController extends GetxController {
  final RxBool forceUpdate = false.obs;
  final RxBool isSessionActive = false.obs;


  final List<Widget> pages = [
    OrderScreen(),
    OrdersDashboardScreen(),
    UserProfileScreen(),
  ];

  List<String> get titles => [
    
    'Orden',
    'Pedidos',
    'Perfil'
  ];

  List<IconData> get icons => [
   
    Icons.shopping_cart,
    Icons.inventory_2_outlined,
    Icons.person_outline,
  ];

  List<String?> get assetImages => [
    
   null,
    null,
    null,
  ];

  final RxInt selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }

  void resetForNewSession() {
    selectedIndex.value = 0;
    isSessionActive.value = true;
    forceUpdate.value = !forceUpdate.value;
  }

  Widget getTabIcon(int index, {double size = 24.0, Color? color}) {
    String? assetPath = assetImages[index];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.local_shipping,
            size: size,
            color: color,
          );
        },
      );
    } else {
      return Icon(
        icons[index],
        size: size,
        color: color,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    isSessionActive.value = true;
  }

  void endSession() {
    isSessionActive.value = false;
  }

  @override
  void onClose() {
    endSession();
    super.onClose();
  }
}