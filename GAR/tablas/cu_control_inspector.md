# cu_control_inspector

## Descripción

Tabla que almacena el control de inspectores y las fechas de envío de cartas relacionadas con las inspecciones.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ci_inspector | Tinyint | 1 | NOT NULL | Código del inspector |
| ci_fenvio_carta | Datetime | 8 | NOT NULL | Fecha de envío de carta |
| ci_codigo_externo | Varchar | 64 | NULL | Código externo para la garantía |
| ci_observaciones | Varchar | 255 | NULL | Observaciones del control |
| ci_estado | Char | 1 | NULL | Estado del control<br><br>P= Pendiente<br>E= Enviado<br>R= Recibido |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
