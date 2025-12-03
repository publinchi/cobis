# cu_errorlog

## Descripción

Guarda el manejo de errores en los procesos automáticos.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| er_fecha_proc | Datetime | 8 | NULL | Fecha de proceso. |
| er_error | Int | 4 | NULL | Numero de error |
| er_usuario | login | 64 | NULL | Código de usuario. |
| er_tran | Int | 4 | NULL | Código de la transacción. |
| er_cuenta | Varchar | 64 | NULL | Numero de cuenta |
| er_descripcion | Varchar | 255 | NULL | Descripción de la garantía. |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
