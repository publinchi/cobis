# ca_oficial_nomina

## Descripción

Tabla que almacena las nóminas de oficiales de crédito. Permite llevar el control de los oficiales asignados a diferentes oficinas y sus períodos de vigencia.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| on_oficial | smallint | 2 | NOT NULL | Código del oficial |
| on_oficina | smallint | 2 | NOT NULL | Código de la oficina |
| on_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio de la asignación |
| on_fecha_fin | datetime | 8 | NULL | Fecha de fin de la asignación |
| on_estado | char | 1 | NOT NULL | Estado de la asignación<br><br>V = Vigente<br><br>I = Inactivo |
| on_observacion | varchar | 255 | NULL | Observaciones de la asignación |

## Índices

- **ca_oficial_nomina_1** (UNIQUE NONCLUSTERED INDEX): on_oficial, on_oficina, on_fecha_inicio

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
