# cr_gar_anteriores

## Descripción

Almacena información histórica de garantías asociadas a operaciones anteriores del cliente.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ga_tramite | Int | 4 | NOT NULL | Número de trámite | |
| ga_garantia | Varchar | 64 | NOT NULL | Código compuesto de garantía | |
| ga_operacion | Int | 4 | NULL | Número de operación anterior | |
| ga_monto_garantia | Money | 8 | NULL | Monto de la garantía | |
| ga_tipo_garantia | Varchar | 10 | NULL | Tipo de garantía | |
| ga_estado | Char | 1 | NULL | Estado de la garantía | |

## Transacciones de Servicio

Utilizada en procesos de consulta histórica.

## Índices

- cr_gar_anteriores_Key
- cr_gar_anteriores_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
