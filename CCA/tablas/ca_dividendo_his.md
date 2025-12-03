# ca_dividendo_his

## Descripción

Tabla histórica que almacena los cambios realizados en los dividendos. Registra todas las modificaciones de cuotas para mantener un historial de cambios.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dih_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| dih_dividendo | smallint | 2 | NOT NULL | Número de dividendo/cuota |
| dih_secuencial | int | 4 | NOT NULL | Secuencial del histórico |
| dih_fecha_ini | datetime | 8 | NOT NULL | Fecha de inicio del dividendo |
| dih_fecha_ven | datetime | 8 | NOT NULL | Fecha de vencimiento del dividendo |
| dih_estado | tinyint | 1 | NOT NULL | Estado del dividendo |
| dih_dias_cuota | smallint | 2 | NOT NULL | Días de la cuota |
| dih_cuota | money | 8 | NOT NULL | Monto total de la cuota |
| dih_gracia | char | 1 | NOT NULL | Indica si está en período de gracia |
| dih_fecha_can | datetime | 8 | NULL | Fecha de cancelación del dividendo |
| dih_fecha_ex | datetime | 8 | NULL | Fecha de exigibilidad |
| dih_monto_pag | money | 8 | NOT NULL | Monto pagado del dividendo |
| dih_fecha | datetime | 8 | NOT NULL | Fecha del registro histórico |
| dih_usuario | login | 14 | NOT NULL | Usuario que realizó el cambio |
| dih_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó el cambio |

## Índices

- **ca_dividendo_his_1** (NONCLUSTERED INDEX): dih_operacion, dih_dividendo, dih_secuencial

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
