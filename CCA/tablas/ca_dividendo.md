# ca_dividendo

## Descripción

Tabla que contiene la información de cada dividendo o cuota del préstamo. Almacena las fechas de vencimiento, montos y estados de cada cuota de la tabla de amortización.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| di_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| di_dividendo | smallint | 2 | NOT NULL | Número de dividendo/cuota |
| di_fecha_ini | datetime | 8 | NOT NULL | Fecha de inicio del dividendo |
| di_fecha_ven | datetime | 8 | NOT NULL | Fecha de vencimiento del dividendo |
| di_estado | tinyint | 1 | NOT NULL | Estado del dividendo<br><br>0 = Vigente<br><br>1 = Cancelado<br><br>2 = Vencido<br><br>3 = Castigado |
| di_dias_cuota | smallint | 2 | NOT NULL | Días de la cuota |
| di_cuota | money | 8 | NOT NULL | Monto total de la cuota |
| di_gracia | char | 1 | NOT NULL | Indica si está en período de gracia<br><br>S = Si<br><br>N = No |
| di_fecha_can | datetime | 8 | NULL | Fecha de cancelación del dividendo |
| di_fecha_ex | datetime | 8 | NULL | Fecha de exigibilidad |
| di_monto_pag | money | 8 | NOT NULL | Monto pagado del dividendo |

## Índices

- **ca_dividendo_1** (CLUSTERED INDEX): di_operacion, di_dividendo
- **ca_dividendo_2** (NONCLUSTERED INDEX): di_estado
- **ca_dividendo_3** (NONCLUSTERED INDEX): di_fecha_ven

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
