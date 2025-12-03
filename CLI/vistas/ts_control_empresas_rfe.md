# ts_control_empresas_rfe

## Descripción
Vista de servicio para consulta de empresas relacionadas financieramente con el ente (RFE).

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ce_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| ce_ente | Int | 4 | NOT NULL | Código del ente | |
| ce_empresa | Int | 4 | NOT NULL | Código de la empresa relacionada | |
| ce_tipo_relacion | catalogo | 10 | NOT NULL | Tipo de relación | AC=Accionista<br>DI=Director<br>RE=Representante<br>PR=Proveedor<br>CL=Cliente<br>OT=Otros |
| ce_porcentaje_participacion | Decimal | 5,2 | NULL | Porcentaje de participación | |
| ce_monto_operaciones | money | 8 | NULL | Monto de operaciones anuales | |
| ce_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio de la relación | |
| ce_cargo | descripcion | 64 | NULL | Cargo en la empresa | |
| ce_estado | estado | 1 | NULL | Estado de la relación | V=Vigente<br>C=Cancelado |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |
| nombre_empresa | descripcion | 254 | NULL | Nombre de la empresa relacionada | |

## Relaciones
- Vista basada en cl_control_empresas_rfe con joins a cl_ente

## Notas
Esta vista facilita la consulta de relaciones financieras entre entes y empresas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
