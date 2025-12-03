# cu_inspector

## Descripción

Almacena la información sobre mantenimiento de inspectores.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| is_inspector | Tinyint | 1 | NOT NULL | Código del inspector |
| is_cta_inspector | Varchar | 24 | NULL | Cuenta de depósito del inspector |
| is_nombre | descripcion | 64 | NULL | Nombre del inspector |
| is_especialidad | catalogo | 10 | NULL | Especialidad del inspector |
| is_direccion | descripcion | 64 | NULL | Dirección del inspector |
| is_telefono | Varchar | 20 | NULL | Teléfono del inspector |
| is_principal | descripcion | 64 | NULL | Dirección principal |
| is_cargo | descripcion | 64 | NULL | Cargo del inspector |
| is_cliente_inspec | Int | 4 | NULL | Código del inspector si es un cliente de la institución |
| is_tipo_cta | Varchar | 5 | NULL | Tipo de cuenta para depósito |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
