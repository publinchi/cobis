# ca_dividendo_tmp

## Descripción

Tabla temporal que almacena la información de dividendos durante procesos de simulación o modificación de la tabla de amortización, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dit_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| dit_dividendo | smallint | 2 | NOT NULL | Número de dividendo/cuota |
| dit_fecha_ini | datetime | 8 | NOT NULL | Fecha de inicio del dividendo |
| dit_fecha_ven | datetime | 8 | NOT NULL | Fecha de vencimiento del dividendo |
| dit_estado | tinyint | 1 | NOT NULL | Estado del dividendo |
| dit_dias_cuota | smallint | 2 | NOT NULL | Días de la cuota |
| dit_cuota | money | 8 | NOT NULL | Monto total de la cuota |
| dit_gracia | char | 1 | NOT NULL | Indica si está en período de gracia<br><br>S = Si<br><br>N = No |
| dit_fecha_can | datetime | 8 | NULL | Fecha de cancelación del dividendo |
| dit_fecha_ex | datetime | 8 | NULL | Fecha de exigibilidad |
| dit_monto_pag | money | 8 | NOT NULL | Monto pagado del dividendo |

## Índices

- **ca_dividendo_tmp_1** (CLUSTERED INDEX): dit_operacion, dit_dividendo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
