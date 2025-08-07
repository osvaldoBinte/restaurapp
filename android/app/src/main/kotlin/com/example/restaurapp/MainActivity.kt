// Archivo: android/app/src/main/kotlin/com/example/restaurapp/MainActivity.kt

package com.example.restaurapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest
import java.io.IOException
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "bluetooth_printer_channel"
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothSocket: BluetoothSocket? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPairedDevices" -> {
                    getPairedDevices(result)
                }
                "connectToDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connectToDevice(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Address is null", null)
                    }
                }
                "printText" -> {
                    val text = call.argument<String>("text")
                    if (text != null) {
                        printText(text, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text is null", null)
                    }
                }
                "disconnect" -> {
                    disconnect(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getPairedDevices(result: MethodChannel.Result) {
        try {
            if (bluetoothAdapter == null) {
                result.error("NO_BLUETOOTH", "Bluetooth not available", null)
                return
            }

            if (!bluetoothAdapter!!.isEnabled) {
                result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled", null)
                return
            }

            // Verificar permisos
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) 
                != PackageManager.PERMISSION_GRANTED) {
                // Solicitar permisos si es necesario
                ActivityCompat.requestPermissions(this, 
                    arrayOf(Manifest.permission.BLUETOOTH_CONNECT), 
                    1001)
            }

            val pairedDevices: Set<BluetoothDevice> = bluetoothAdapter!!.bondedDevices
            val deviceList = mutableListOf<Map<String, String>>()

            for (device in pairedDevices) {
                val deviceInfo = mapOf(
                    "name" to (device.name ?: "Dispositivo desconocido"),
                    "address" to device.address
                )
                deviceList.add(deviceInfo)
            }

            result.success(deviceList)
        } catch (e: Exception) {
            result.error("ERROR", "Error getting paired devices: ${e.message}", null)
        }
    }

    private fun connectToDevice(address: String, result: MethodChannel.Result) {
        try {
            if (bluetoothAdapter == null) {
                result.error("NO_BLUETOOTH", "Bluetooth not available", null)
                return
            }

            val device = bluetoothAdapter!!.getRemoteDevice(address)
            
            // Usar UUID estándar para impresoras seriales
            val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
            
            bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid)
            bluetoothSocket?.connect()
            
            result.success(true)
        } catch (e: IOException) {
            result.error("CONNECTION_ERROR", "Failed to connect: ${e.message}", null)
        } catch (e: Exception) {
            result.error("ERROR", "Unexpected error: ${e.message}", null)
        }
    }

    private fun printText(text: String, result: MethodChannel.Result) {
        try {
            if (bluetoothSocket == null || !bluetoothSocket!!.isConnected) {
                result.error("NOT_CONNECTED", "No connected device", null)
                return
            }

            val outputStream = bluetoothSocket!!.outputStream
            
            // Enviar comandos ESC/POS básicos
            val escPos = byteArrayOf(27, 64) // Inicializar impresora
            outputStream.write(escPos)
            
            // Enviar texto
            outputStream.write(text.toByteArray(charset("UTF-8")))
            
            // Comandos de finalización
            val cutPaper = byteArrayOf(29, 86, 66, 0) // Cortar papel
            outputStream.write(cutPaper)
            
            outputStream.flush()
            result.success(true)
        } catch (e: IOException) {
            result.error("PRINT_ERROR", "Failed to print: ${e.message}", null)
        } catch (e: Exception) {
            result.error("ERROR", "Unexpected error: ${e.message}", null)
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        try {
            bluetoothSocket?.close()
            bluetoothSocket = null
            result.success(true)
        } catch (e: IOException) {
            result.error("DISCONNECT_ERROR", "Failed to disconnect: ${e.message}", null)
        } catch (e: Exception) {
            result.error("ERROR", "Unexpected error: ${e.message}", null)
        }
    }
}