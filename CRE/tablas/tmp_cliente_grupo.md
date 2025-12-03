# tmp_cliente_grupo

## Descripción

Tabla temporal para el procesamiento de clientes y grupos en la base de datos cob_pac.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_cliente | Int | 4 | NOT NULL | Código de cliente | |
| tmp_grupo | Int | 4 | NULL | Código de grupo | |
| tmp_nombre | Varchar | 255 | NULL | Nombre del cliente | |
| tmp_estado | Char | 1 | NULL | Estado temporal | |

## Transacciones de Servicio

Utilizada en procesos de integración con PAC.

## Índices

- tmp_cliente_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
