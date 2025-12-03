# ca_reajuste

## Descripción

Tabla que almacena la información de los reajustes de tasas de interés realizados a las operaciones de cartera. Registra la cabecera de cada proceso de reajuste.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| re_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| re_secuencial | int | 4 | NOT NULL | Secuencial del reajuste |
| re_fecha_reajuste | datetime | 8 | NOT NULL | Fecha del reajuste |
| re_tasa_anterior | float | 8 | NOT NULL | Tasa de interés anterior |
| re_tasa_nueva | float | 8 | NOT NULL | Tasa de interés nueva |
| re_tipo_reajuste | char | 1 | NOT NULL | Tipo de reajuste<br><br>A = Automático<br><br>M = Manual |
| re_motivo | varchar | 255 | NULL | Motivo del reajuste |
| re_estado | char | 1 | NOT NULL | Estado del reajuste<br><br>V = Vigente<br><br>R = Reversado |
| re_usuario | login | 14 | NOT NULL | Usuario que realizó el reajuste |
| re_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| re_oficina | smallint | 2 | NOT NULL | Oficina donde se realizó el reajuste |
| re_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó |

## Índices

- **ca_reajuste_1** (UNIQUE NONCLUSTERED INDEX): re_operacion, re_secuencial
- **ca_reajuste_2** (NONCLUSTERED INDEX): re_fecha_reajuste

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
