# cl_actualiza

## Descripción
Guarda la información de datos que han sido modificados en el módulo

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ac_ente | Int | 4 | NOT NULL | Código del ente | |
| ac_fecha | Datetime | 8 | NOT NULL | Fecha de actualización | |
| ac_tabla | descripcion | 64 | NULL | Tabla que se modificó | |
| ac_campo | descripcion | 64 | NULL | Campo que se modificó | |
| ac_valor_ant | descripcion | 64 | NULL | Valor anterior a la modificación | |
| ac_valor_nue | descripcion | 64 | NULL | Valor nuevo del campo | |
| ac_transaccion | Char | 1 | NULL | Operación que se realizó sobre el registro | |
| ac_secuencial1 | Tinyint | 1 | NULL | No aplica | |
| ac_secuencial2 | Tinyint | 1 | NULL | No aplica | |
| ac_hora | Datetime | 8 | NULL | Hora de modificación | |
| ac_user | Login | 14 | NULL | Usuario que modifico | |
| ac_term | descripcion | 64 | NULL | Terminal de donde se modifico | |

## Relaciones
- Relacionada con cl_ente a través de ac_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
