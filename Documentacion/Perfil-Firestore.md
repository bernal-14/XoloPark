# Perfil privado

Mi cuenta incluye Nombre o apodo y Guardar perfil.
Solo al pulsar Guardar perfil se escribe en profiles/{uid}.
Campos: displayName (1–80 caracteres), createdAt y updatedAt (fechas del servidor).
La creación usa una transacción; las actualizaciones conservan createdAt.
No se duplican correo, contraseñas, roles ni datos de pases en el perfil.
La lectura requiere conexión al servidor; el éxito del guardado se anuncia
solo después de que Firestore confirma la transacción.
Antes de acceder se renueva el token de autenticación para incluir email_verified.

## Prueba manual pendiente
1. Actualizar la app desde Xcode e iniciar sesión con correo verificado.
2. Mi cuenta: escribir un apodo y pulsar Guardar perfil.
3. Comprobar el mensaje de confirmación.
4. Salir de Mi cuenta y volver; verificar que se recupera el apodo.
5. Cerrar sesión e iniciar con otra cuenta: no debe mostrarse el perfil anterior.
6. Sin conexión: no debe informar un guardado exitoso.
7. Nombre vacío o mayor de 80 caracteres: no permite guardar.

La compilación no sustituye la prueba real de permisos y persistencia.
No se crearon perfiles ni se enviaron datos personales durante la implementación.
