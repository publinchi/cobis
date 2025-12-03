# cu_mig_custodia

## Descripción

Tabla utilizada para procesos de migración de datos de garantías desde sistemas legados hacia COBIS. Almacena información temporal durante el proceso de migración.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| mc_garante | Int | 4 | NOT NULL | Código del garante en el sistema origen |
| mc_ente | Int | 4 | NOT NULL | Código del cliente/ente |
| mc_operacion | Int | 4 | NOT NULL | Código de la operación en el sistema origen |
| mc_codigo_externo | Varchar | 64 | NULL | Código externo asignado en COBIS |
| mc_tipo_custodia | Varchar | 64 | NULL | Tipo de custodia migrada |
| mc_valor | Money | 8 | NULL | Valor de la garantía migrada |
| mc_estado | Char | 1 | NULL | Estado de la migración<br><br>P= Pendiente<br>M= Migrado<br>E= Error |
| mc_fecha_migracion | Datetime | 8 | NULL | Fecha en que se realizó la migración |
| mc_observaciones | Varchar | 255 | NULL | Observaciones del proceso de migración |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
