# ca_estados_man

## Descripción

Tabla de parametrización que define las reglas y validaciones para los cambios de estado manuales de los préstamos. Controla qué transiciones de estado son permitidas.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| em_estado_origen | tinyint | 1 | NOT NULL | Estado origen del cambio |
| em_estado_destino | tinyint | 1 | NOT NULL | Estado destino del cambio |
| em_permitido | char | 1 | NOT NULL | Si el cambio está permitido<br><br>S = Si<br><br>N = No |
| em_requiere_autorizacion | char | 1 | NOT NULL | Si requiere autorización<br><br>S = Si<br><br>N = No |
| em_nivel_autorizacion | tinyint | 1 | NULL | Nivel de autorización requerido |
| em_observacion_obligatoria | char | 1 | NOT NULL | Si requiere observación obligatoria<br><br>S = Si<br><br>N = No |
| em_genera_transaccion | char | 1 | NOT NULL | Si genera transacción contable<br><br>S = Si<br><br>N = No |
| em_tipo_transaccion | catalogo | 10 | NULL | Tipo de transacción a generar |

## Índices

- **ca_estados_man_1** (UNIQUE NONCLUSTERED INDEX): em_estado_origen, em_estado_destino

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
