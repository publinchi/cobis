# cr_clientes_credautomatico

## Descripción

Almacena información de clientes elegibles para crédito automático.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cca_cliente | Int | 4 | NOT NULL | Código de cliente | |
| cca_monto_aprobado | Money | 8 | NULL | Monto aprobado automáticamente | |
| cca_plazo_maximo | Smallint | 2 | NULL | Plazo máximo permitido | |
| cca_tasa | Float | 8 | NULL | Tasa de interés | |
| cca_fecha_aprobacion | Datetime | 8 | NULL | Fecha de aprobación | |
| cca_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento de la aprobación | |
| cca_estado | Char | 1 | NOT NULL | Estado | V: Vigente<br>I: Inactivo<br>U: Utilizado |
| cca_observacion | Varchar | 255 | NULL | Observaciones | |

## Transacciones de Servicio

21048, 21148

## Índices

- cr_clientes_credautomatico_Key
- cr_clientes_credautomatico_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
