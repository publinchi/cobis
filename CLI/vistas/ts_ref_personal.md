# ts_ref_personal

## Descripción
Vista de servicio para consulta de referencias personales de clientes.

## Estructura de la vista

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
| rp_estado | estado | 1 | NULL | Estado de la referencia | V=Vigente<br>C=Cancelado |
| nombre_ciudad | descripcion | 64 | NULL | Nombre de la ciudad | |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |

## Relaciones
- Vista basada en cl_ref_personal con joins a cl_ente y cl_ciudad

## Notas
Esta vista facilita la consulta de referencias personales con información completa.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
