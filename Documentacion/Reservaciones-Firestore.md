# Reservaciones académicas en Firestore

Estado: código implementado; reglas propuestas en firestore.rules, pendientes de publicación y pruebas de integración. No es un sistema de boletos oficial.

Un documento privado profiles/{uid}/reservations/xolos-atlas-demo-2026 por cuenta. La ocupación compartida se guarda sin datos personales en demoEvents/xolos-atlas-demo-2026/locks/{spaceID}.
Ambos se crean en una transacción. Las reglas exigen la creación atómica de ambos documentos y prohíben cambios/borrado desde clientes. Un reintento recupera la reserva existente. No se cobran pagos ni se habilita acceso real. Los tres cajones ocupados del prototipo siguen bloqueados.

## Activación
Comparar las reglas actuales con firestore.rules antes de publicar: conservar cualquier cambio ajeno. No usar modo de prueba ni allow read, write: if true. Publicar solo con autorización del propietario.

## Pruebas pendientes (dos cuentas de prueba verificadas)
1. Guardar el perfil y recargarlo para verificar el paso anterior.
2. Reservar A-02; comprobar confirmación con folio único y documento en servidor.
3. Cerrar y abrir la app: recuperar el mismo folio y cajón.
4. Dos cuentas intentan reservar A-03 a la vez: solo una obtiene ese cajón.
5. Repetir el envío de la primera cuenta: debe recuperar su reserva, no crear otra.
6. Sin conexión o sin reglas: no confirmar éxito; mostrar error y permitir actualizar.
7. Cambiar de cuenta durante una consulta: no mostrar datos de la cuenta anterior.
8. Probar reglas con emulador: denegar lectura de reserva ajena, usuario sin verificar, escrituras aisladas de reserva/bloqueo, campos adicionales, espacio inexistente, precio/pago real, cambio o borrado.

No se han ejecutado estas pruebas remotas ni se han creado reservaciones durante la implementación. El mapa es una consulta al servidor, no sensores en tiempo real; la transacción vuelve a comprobar disponibilidad al confirmar. No hay cancelaciones ni administración de eventos todavía.
