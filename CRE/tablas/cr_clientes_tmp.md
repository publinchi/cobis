# cr_clientes_tmp

## Descripción

Tabla temporal utilizada para el procesamiento de información de clientes en operaciones de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_cliente | Int | 4 | NOT NULL | Código de cliente | |
| tmp_nombre | Varchar | 255 | NULL | Nombre del cliente | |
| tmp_tipo_identificacion | Varchar | 10 | NULL | Tipo de identificación | |
| tmp_identificacion | Varchar | 30 | NULL | Número de identificación | |
| tmp_oficina | Smallint | 2 | NULL | Código de oficina | |

## Transacciones de Servicio

Utilizada en procesos batch y temporales.

## Índices

- tmp_cliente_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
