# cr_tipo_tramite

## Descripción

Catálogo de tipos de trámite disponibles en el sistema.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tt_codigo | Varchar | 10 | NOT NULL | Código del tipo de trámite | |
| tt_descripcion | Varchar | 64 | NOT NULL | Descripción del tipo de trámite | |
| tt_tipo | Char | 1 | NOT NULL | Tipo | O: Original<br>L: Línea<br>G: Modificatorio garantía<br>E: Reestructuración<br>R: Renovación |
| tt_estado | Char | 1 | NOT NULL | Estado del tipo de trámite | V: Vigente<br>I: Inactivo |
| tt_requiere_garantia | Char | 1 | NULL | Indica si requiere garantía | S: Sí<br>N: No |
| tt_permite_grupo | Char | 1 | NULL | Indica si permite trámite grupal | S: Sí<br>N: No |

## Transacciones de Servicio

21044, 21144

## Índices

- cr_tipo_tramite_Key

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
