# cu_tipo_custodia

## Descripción

Registra los tipos de garantías que se administrará en este módulo.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tc_tipo | Varchar | 64 | NOT NULL | Nemónico de tipo |
| tc_tipo_superior | Varchar | 64 | NULL | Nemónico de tipo superior |
| tc_descripcion | Varchar | 255 | NULL | Descripción del tipo de custodia |
| tc_periodicidad | Catalgo | 10 | NULL | Periodicidad del tipo de custodia. Campo en desuso, valor por defecto 1. |
| tc_contabilizar | Char | 1 | NULL | Indicador de contabilidad |
| tc_porcentaje | Float | 8 | NULL | Porcentaje de depreciación |
| tc_adecuada | Char | 1 | NULL | Campo no utilizado en esta versión. Valor por defecto "S". |
| tc_clase_garantia | Varchar | 10 | NULL | Campo no utilizado en esta version |
| tc_producto | Tinyint | 1 | NULL | Código de producto. Valor por defecto NULL. |
| tc_porcen_cobeertura | Float | 8 | NULL | Porcentaje de cobertura |
| tc_tipo_bien | Char | 1 | NULL | Campo no utilizado en esta versión. Valor por defecto NULL. |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
