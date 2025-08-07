import 'dart:async';
import 'dart:io';

String convertMessageException({required dynamic error}) {
  switch (error) {
    case SocketException:
      return 'Servicio no disponible intente mas tarde';
    case TimeoutException:
      return 'La peticion tardo mas  de lo usual, intente de nuevo';
    default:
      return error.toString();
  }
}


String cleanExceptionMessage(dynamic e) {
  String message = e.toString();

  while (message.trim().startsWith("Exception:")) {
    message = message.trim().replaceFirst("Exception:", "").trim();
  }
  message = message.replaceAll("Exception:", "").trim();
message = message.replaceAll("Exception:", "").trim();
message = message.replaceAll("Error de conexión:", "").trim();

  return message;
}