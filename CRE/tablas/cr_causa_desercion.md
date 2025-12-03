# cr_causa_desercion

## Descripción

Catálogo de causas de deserción de clientes.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cd_codigo | Varchar | 10 | NOT NULL | Código de causa de deserción | |
| cd_descripcion | Varchar | 255 | NOT NULL | Descripción de la causa | |
| cd_tipo | Varchar | 10 | NULL | Tipo de deserción | |
| cd_estado | Char | 1 | NOT NULL | Estado | V: Vigente<br>I: Inactivo |

## Transacciones de Servicio

Tabla de catálogo.

## Índices

- cr_causa_desercion_Key

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
