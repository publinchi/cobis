# cr_situacion_gar

## Descripción

Almacena información sobre las garantías existentes del cliente.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sg_tramite | Int | 4 | NOT NULL | Número de trámite | |
| sg_secuencial | Smallint | 2 | NOT NULL | Secuencial de la garantía | |
| sg_garantia | Varchar | 64 | NULL | Código de garantía | |
| sg_tipo_garantia | Varchar | 10 | NULL | Tipo de garantía | |
| sg_descripcion | Varchar | 255 | NULL | Descripción de la garantía | |
| sg_valor_comercial | Money | 8 | NULL | Valor comercial | |
| sg_valor_avaluo | Money | 8 | NULL | Valor de avalúo | |
| sg_porcentaje_cobertura | Float | 8 | NULL | Porcentaje de cobertura | |
| sg_estado | Char | 1 | NULL | Estado de la garantía | |

## Transacciones de Servicio

21038, 21138, 21238

## Índices

- cr_situacion_gar_Key
- cr_situacion_gar_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
