# cl_control_empresas_rfe

## Descripción
Contiene información de control de empresas relacionadas financieramente con el ente (RFE - Relación Financiera con el Ente).

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ce_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| ce_ente | Int | 4 | NOT NULL | Código del ente | |
| ce_empresa | Int | 4 | NOT NULL | Código de la empresa relacionada | |
| ce_tipo_relacion | catalogo | 10 | NOT NULL | Tipo de relación | AC=Accionista<br>DI=Director<br>RE=Representante<br>PR=Proveedor<br>CL=Cliente<br>OT=Otros |
| ce_porcentaje_participacion | Decimal | 5,2 | NULL | Porcentaje de participación | |
| ce_monto_operaciones | money | 8 | NULL | Monto de operaciones anuales | |
| ce_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio de la relación | |
| ce_fecha_fin | Datetime | 8 | NULL | Fecha de fin de la relación | |
| ce_cargo | descripcion | 64 | NULL | Cargo en la empresa | |
| ce_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| ce_usuario | login | 14 | NULL | Usuario que registró | |
| ce_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ce_estado | estado | 1 | NULL | Estado de la relación | V=Vigente<br>C=Cancelado |
| ce_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ce_ente y ce_empresa

## Notas
Esta tabla permite identificar relaciones financieras entre entes para análisis de riesgo y cumplimiento normativo.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
