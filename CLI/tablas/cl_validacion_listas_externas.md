# cl_validacion_listas_externas

## Descripción
Registra las validaciones realizadas contra listas externas de control (OFAC, ONU, listas restrictivas, etc.).

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| vl_secuencial | Int | 4 | NOT NULL | Secuencial de la validación | |
| vl_ente | Int | 4 | NOT NULL | Código del ente validado | |
| vl_tipo_lista | catalogo | 10 | NOT NULL | Tipo de lista consultada | OFAC=OFAC<br>ONU=ONU<br>INTER=Interpol<br>NAC=Nacional<br>OTRO=Otros |
| vl_fecha_consulta | Datetime | 8 | NOT NULL | Fecha de la consulta | |
| vl_resultado | Char | 1 | NOT NULL | Resultado de la validación | A=Aprobado<br>R=Rechazado<br>P=Pendiente |
| vl_coincidencia | Char | 1 | NULL | Indica si hubo coincidencia | S=Sí<br>N=No |
| vl_porcentaje_match | Decimal | 5,2 | NULL | Porcentaje de coincidencia | |
| vl_detalle_match | descripcion | 254 | NULL | Detalle de la coincidencia | |
| vl_usuario | login | 14 | NULL | Usuario que realizó la consulta | |
| vl_terminal | descripcion | 64 | NULL | Terminal de consulta | |
| vl_estado | estado | 1 | NULL | Estado de la validación | V=Vigente<br>C=Cancelado |
| vl_observacion | descripcion | 254 | NULL | Observaciones | |
| vl_aprobado_por | login | 14 | NULL | Usuario que aprobó en caso de coincidencia | |
| vl_fecha_aprobacion | Datetime | 8 | NULL | Fecha de aprobación | |

## Relaciones
- Relacionada con cl_ente a través de vl_ente

## Notas
Esta tabla es crítica para cumplimiento normativo de prevención de lavado de activos y financiamiento del terrorismo.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
