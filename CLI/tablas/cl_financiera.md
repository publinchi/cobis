# cl_financiera

## Descripción
Contiene información financiera detallada de los clientes, incluyendo ingresos, egresos y situación patrimonial.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| fi_ente | Int | 4 | NOT NULL | Código del ente | |
| fi_secuencial | Tinyint | 1 | NOT NULL | Secuencial del registro financiero | |
| fi_tipo_ingreso | catalogo | 10 | NULL | Tipo de ingreso | S=Salario<br>N=Negocio<br>A=Arriendo<br>O=Otros |
| fi_monto_ingreso | money | 8 | NULL | Monto del ingreso | |
| fi_frecuencia_ingreso | catalogo | 10 | NULL | Frecuencia del ingreso | M=Mensual<br>Q=Quincenal<br>S=Semanal<br>A=Anual |
| fi_tipo_egreso | catalogo | 10 | NULL | Tipo de egreso | V=Vivienda<br>A=Alimentación<br>E=Educación<br>S=Salud<br>O=Otros |
| fi_monto_egreso | money | 8 | NULL | Monto del egreso | |
| fi_frecuencia_egreso | catalogo | 10 | NULL | Frecuencia del egreso | M=Mensual<br>Q=Quincenal<br>S=Semanal<br>A=Anual |
| fi_activos_corrientes | money | 8 | NULL | Activos corrientes | |
| fi_activos_fijos | money | 8 | NULL | Activos fijos | |
| fi_pasivos_corrientes | money | 8 | NULL | Pasivos corrientes | |
| fi_pasivos_largo_plazo | money | 8 | NULL | Pasivos a largo plazo | |
| fi_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| fi_usuario | login | 14 | NULL | Usuario que registró | |
| fi_terminal | descripcion | 64 | NULL | Terminal de registro | |
| fi_fecha_actualizacion | Datetime | 8 | NULL | Fecha de actualización | |

## Relaciones
- Relacionada con cl_ente a través de fi_ente

## Notas
Esta tabla permite un análisis detallado de la situación financiera del cliente para evaluación crediticia.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
