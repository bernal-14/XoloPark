# XoloPark

Proyecto inicial para iPhone con Swift y SwiftUI. Abre XoloPark.xcodeproj en Xcode.

## Ubicación
El código está en iCloud Drive/PRINCIPAL/TEC/2026/INTERFAZ/XoloPark.
iCloud mantiene copias locales durante el uso: no es almacenamiento exclusivamente remoto ni un respaldo independiente.

## Almacenamiento
Mantén Derived Data en la ubicación predeterminada de Xcode, fuera de esta carpeta.
No guardes compilaciones, simuladores, credenciales ni cachés en iCloud.
Espera a que termine la sincronización antes de cambiar de equipo y no edites simultáneamente desde dos Macs.

## Primera ejecución en iPhone
En Xcode, selecciona el proyecto, el target XoloPark y Signing & Capabilities.
Conserva tu equipo de firma y el identificador com.robertobernal.xolopark.
El identificador debe coincidir con Firebase. Ejecutar desde Xcode actualiza la app
existente del iPhone; no hace falta desinstalarla para cada cambio.
Conecta tu iPhone y completa personalmente las solicitudes de confianza o de cuenta.
No es necesario contratar servicios de pago para editar el proyecto.

## Alcance de esta versión
Interfaz nativa SwiftUI basada en el Figma de XoloPark: inicio de sesión, inicio con
carrusel, detalles de partido, mapa esquemático, selección de cajón, pago simulado,
confirmación, acceso actual, menú lateral y Mi cuenta.
Se importaron del diseño original el fondo de acceso, emblema, imagen de encabezado
y cartel de Atlas. Las fuentes y algunos componentes se adaptaron a controles nativos.

La selección y el precio se conservan durante el recorrido. Los cajones ocupados no
se pueden seleccionar. Mi cuenta permite solicitar un cambio de correo verificado
y cambiar la contraseña tras comprobar la contraseña actual.

Las cuentas usan Firebase Authentication real. La sesión la conserva el SDK;
la app no guarda contraseñas en archivos ni en UserDefaults.
Reservaciones, pagos y pases siguen siendo datos de demostración en memoria.
No hay cobros, Apple Pay real ni validación de pases.
El escáner sí utiliza la cámara real con permiso del usuario en un iPhone compatible.
La lectura se procesa localmente; no guarda, abre ni envía el contenido del QR.
Hasta configurar el servidor, leer un QR no vincula un XoloPass.
Utiliza una contraseña exclusiva para XoloPark. No introduzcas tarjetas reales.

## Recorrido de prueba
1. Pulsa REGÍSTRATE, usa un correo tuyo y una contraseña exclusiva de al menos
   12 caracteres. Se creará una cuenta real y se enviará una verificación.
   Abre el enlace recibido y pulsa Ya verifiqué mi correo.
2. Abre el partido, selecciona un cajón disponible y continúa al pago.
3. Simula el pago y verifica que confirmación y Mi acceso muestran el mismo cajón.
4. Mi cuenta muestra el correo autenticado. Los cambios de correo y contraseña
   son REALES: prueba solo si deseas modificarlos y tienes acceso al correo.
5. En un iPhone compatible, abre Escanear QR, concede permiso y apunta a un QR de prueba.
   Debe indicar que lo leyó, pero que la vinculación en la nube aún está pendiente.
   Prueba también denegar el permiso y volver a habilitarlo en Ajustes.
6. Cierra sesión y vuelve a entrar con tus credenciales. Reinicia la app para
   comprobar que la sesión persiste. Los datos de reservas se borran al cambiar de usuario.
7. Prueba una contraseña incorrecta, modo sin conexión y recuperación de contraseña.
   La recuperación envía un correo real; la respuesta no revela si existe la cuenta.

## Cuentas y nube
Firebase Authentication está conectado para registro, acceso, cierre de sesión,
verificación de correo, recuperación y cambios de credenciales.
El proyecto Firebase xolopark-e0a4d ya está registrado para com.robertobernal.xolopark.
GoogleService-Info.plist está incluido y Firebase se inicializa al arrancar mediante
el delegado de aplicación de SwiftUI. Se enlazan FirebaseCore, FirebaseAuth y FirebaseFirestore.
El proveedor correo/contraseña está habilitado en la consola.
Firestore aún no tiene datos ni reglas configuradas para esta app.
El inicio con Apple requiere configurar su capacidad en Apple Developer y el proveedor
en Firebase, además de verificar la identidad en el servidor.
Un XoloPass oficial requiere integración autorizada con su emisor. Los pases académicos
deben tener sus propios identificadores y validación de propiedad en el servidor.

## Compilación
Se verificó la compilación para iPhone con Xcode 27 sin firma.
No se han creado cuentas ni enviado correos durante la verificación automática.
La prueba completa del flujo real debe hacerla el usuario con su propio correo.
Los archivos temporales de esta verificación están en /private/tmp/XoloPark-build-check,
fuera de iCloud. Para instalar en un iPhone real debes seleccionar tu Team.
