# cu_cliente_garantia

## Descripción

Almacena los clientes asociados a la garantía y su rol (propietarios y amparados).

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| cg_filial | Tinyint | 1 | NOT NULL | Código de filial. |
| cg_sucursal | Smallint | 2 | NOT NULL | Código de la oficina o sucursal. |
| cg_tipo_cust | descripcion | 64 | NOT NULL | Código del tipo de custodia. |
| cg_custodia | Int | 4 | NOT NULL | Código de la custodia. |
| cg_ente | Int | 4 | NOT NULL | Código del cliente. |
| cg_principal | Char | 1 | NULL | Indicador si es el cliente principal.<br><br>S= Principal<br>N= No es principal |
| cg_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía. |
| cg_oficial | int | 4 | NULL | Código del oficial. |
| cg_tipo_garante | catalogo | 10 | NULL | Columna en desuso |
| cg_nombre | descripcion | 64 | NULL | Nombre del cliente |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
