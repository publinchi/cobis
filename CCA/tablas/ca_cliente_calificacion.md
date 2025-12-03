# ca_cliente_calificacion

## Descripción

Tabla que almacena la calificación crediticia del cliente. Registra el historial de calificaciones asignadas a cada cliente para análisis de riesgo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| cc_cliente | int | 4 | NOT NULL | Código del cliente |
| cc_fecha | datetime | 8 | NOT NULL | Fecha de la calificación |
| cc_calificacion | char | 1 | NOT NULL | Calificación asignada<br><br>A = Normal<br><br>B = Con problemas potenciales<br><br>C = Deficiente<br><br>D = Dudoso recaudo<br><br>E = Irrecuperable |
| cc_tipo | char | 1 | NOT NULL | Tipo de calificación<br><br>I = Interna<br><br>E = Externa |
| cc_observacion | varchar | 255 | NULL | Observaciones de la calificación |
| cc_usuario | login | 14 | NOT NULL | Usuario que registró la calificación |
| cc_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro de la calificación |

## Índices

- **ca_cliente_calificacion_1** (NONCLUSTERED INDEX): cc_cliente, cc_fecha

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
