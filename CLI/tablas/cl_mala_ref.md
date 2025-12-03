# cl_mala_ref

## Descripción
Contiene información de referencias negativas o malas referencias de clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| mr_secuencial | Int | 4 | NOT NULL | Secuencial de la mala referencia | |
| mr_ente | Int | 4 | NOT NULL | Código del ente | |
| mr_tipo | catalogo | 10 | NULL | Tipo de mala referencia | B=Bancaria<br>C=Comercial<br>P=Personal |
| mr_institucion | descripcion | 64 | NULL | Institución que reporta | |
| mr_motivo | descripcion | 254 | NULL | Motivo de la mala referencia | |
| mr_monto | money | 8 | NULL | Monto involucrado | |
| mr_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| mr_fecha_ocurrencia | Datetime | 8 | NULL | Fecha de ocurrencia del evento | |
| mr_usuario | login | 14 | NULL | Usuario que registró | |
| mr_terminal | descripcion | 64 | NULL | Terminal de registro | |
| mr_estado | estado | 1 | NULL | Estado de la referencia | V=Vigente<br>C=Cancelado<br>R=Resuelta |
| mr_observacion | descripcion | 254 | NULL | Observaciones adicionales | |

## Relaciones
- Relacionada con cl_ente a través de mr_ente

## Notas
Esta tabla registra referencias negativas que pueden afectar la evaluación crediticia del cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
