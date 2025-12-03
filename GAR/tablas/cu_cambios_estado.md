# cu_cambios_estado

## Descripción

Registra los cambios de estado que tendrá una garantía.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ce_estado_ini | Char | 1 | NOT NULL | Código del estado inicial.<br><br>F= Vigente futuros créditos<br>V= Vigente con obligación<br>X= Vigente por cancelar<br>C= Cancelada<br>P= Propuesta<br>A= Anulada |
| ce_estado_fin | Char | 1 | NOT NULL | Código del estado final.<br><br>F= Vigente futuros créditos<br>V= Vigente con obligación<br>X= Vigente por cancelar<br>C= Cancelada<br>P= Propuesta<br>A= Anulada |
| ce_contabiliza | Char | 1 | NOT NULL | Si contabiliza el movimiento.<br><br>S= Se contabiliza<br>N= No se contabiliza |
| ce_tran | catalogo | 10 | NOT NULL | Código de la transacción |
| ce_tipo | Char | 1 | NULL | C= Contabilizada<br>I= Ingresada<br>R= Reversada |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
