# Primer pase de prueba

Implementado: lectura local QR → SHA-256 con prefijo XoloPark-test-pass-v1: → confirmación explícita → transacción en Firestore. El contenido original no se persiste, registra en logs ni abre como URL. La huella es un identificador seudónimo, no cifrado ni garantía de autenticidad.

El alias XP-PRUEBA-001 identifica el primer pase en cada cuenta, no un número oficial global. La exclusividad global depende de la huella del QR. Solo hay un pase por cuenta; los otros dos pases y la integración física quedan pendientes. Cualquier QR puede inscribirse en esta demostración: no existe lista de emisores autorizados ni validación de pases oficiales.

Se guarda un documento privado profiles/{uid}/testPasses/current y un bloqueo testPassClaims/{hash} que solo contiene linked:true. Ambos se crean/eliminan atómicamente. No se permiten listados de huellas, modificaciones ni lectura de vínculos ajenos. Un usuario verificado que conoce una huella puede consultar si está vinculada, pero no su propietario.

Pendiente: publicar las reglas ampliadas con autorización y probar en dispositivo. Ningún pase físico ha sido registrado todavía.

Pruebas: escanear sin confirmar no escribe; confirmar persiste tras reiniciar; segunda cuenta con mismo QR no puede vincular; QR diferente con vínculo existente se rechaza; desvincular elimina ambos documentos; modo avión nunca confirma éxito; cambiar de cuenta no conserva el vínculo anterior. Probar además las reglas con escrituras aisladas, uid ajeno, usuario no verificado y hash malformado. No se hicieron estas pruebas remotas durante la implementación.
