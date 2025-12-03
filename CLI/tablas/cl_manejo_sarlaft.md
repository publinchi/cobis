# cl_manejo_sarlaft

## Descripción
Almacena información relacionada con el Sistema de Administración de Riesgo de Lavado de Activos y Financiación del Terrorismo (SARLAFT)

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ms_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| ms_ente | Int | 4 | NOT NULL | Código del ente | |
| ms_fecha_evaluacion | Datetime | 8 | NOT NULL | Fecha de evaluación | |
| ms_nivel_riesgo | catalogo | 10 | NOT NULL | Nivel de riesgo | A=Alto<br>M=Medio<br>B=Bajo |
| ms_puntaje | Decimal | 5,2 | NULL | Puntaje de riesgo | |
| ms_pep | Char | 1 | NULL | Persona Expuesta Políticamente | S=Sí<br>N=No |
| ms_origen_fondos | descripcion | 254 | NULL | Origen de los fondos | |
| ms_destino_fondos | descripcion | 254 | NULL | Destino de los fondos | |
| ms_monto_mensual_estimado | money | 8 | NULL | Monto mensual estimado de transacciones | |
| ms_observaciones | descripcion | 254 | NULL | Observaciones | |
| ms_usuario | login | 14 | NULL | Usuario que evaluó | |
| ms_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ms_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_ente a través de ms_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
