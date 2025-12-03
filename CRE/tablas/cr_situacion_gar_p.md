# cr_situacion_gar_p

## Descripción

Almacena información sobre las garantías propuestas para el trámite.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sgp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| sgp_secuencial | Smallint | 2 | NOT NULL | Secuencial de la garantía propuesta | |
| sgp_garantia | Varchar | 64 | NULL | Código de garantía | |
| sgp_tipo_garantia | Varchar | 10 | NULL | Tipo de garantía | |
| sgp_descripcion | Varchar | 255 | NULL | Descripción de la garantía | |
| sgp_valor_comercial | Money | 8 | NULL | Valor comercial | |
| sgp_valor_avaluo | Money | 8 | NULL | Valor de avalúo | |
| sgp_porcentaje_cobertura | Float | 8 | NULL | Porcentaje de cobertura | |
| sgp_estado | Char | 1 | NULL | Estado de la garantía propuesta | |

## Transacciones de Servicio

21039, 21139, 21239

## Índices

- cr_situacion_gar_p_Key
- cr_situacion_gar_p_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
