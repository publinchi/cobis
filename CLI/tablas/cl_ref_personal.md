# cl_ref_personal

## Descripción
Contiene las referencias personales de los clientes registrados en el sistema.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| rp_ente | Int | 4 | NOT NULL | Código del ente | |
| rp_secuencial | Tinyint | 1 | NOT NULL | Secuencial de la referencia | |
| rp_nombre | descripcion | 64 | NULL | Nombre de la referencia | |
| rp_relacion | catalogo | 10 | NULL | Tipo de relación con el cliente | A=Amigo<br>F=Familiar<br>C=Conocido<br>O=Otros |
| rp_direccion | descripcion | 254 | NULL | Dirección de la referencia | |
| rp_ciudad | Int | 4 | NULL | Código de la ciudad | |
| rp_telefono | telefono | 16 | NULL | Teléfono de la referencia | |
| rp_celular | telefono | 16 | NULL | Teléfono celular | |
| rp_email | email | 64 | NULL | Correo electrónico | |
| rp_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| rp_usuario | login | 14 | NULL | Usuario que registró | |
| rp_terminal | descripcion | 64 | NULL | Terminal de registro | |
| rp_estado | estado | 1 | NULL | Estado de la referencia | V=Vigente<br>C=Cancelado |
| rp_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de rp_ente
- Relacionada con cl_ciudad a través de rp_ciudad

## Notas
Esta tabla almacena las referencias personales proporcionadas por los clientes para verificación y contacto.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
