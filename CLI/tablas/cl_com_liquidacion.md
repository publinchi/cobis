# cl_com_liquidacion

## Descripción
Contiene información de compañías de liquidación o aseguradoras relacionadas con los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| cl_codigo | Int | 4 | NOT NULL | Código de la compañía | |
| cl_nombre | descripcion | 64 | NOT NULL | Nombre de la compañía | |
| cl_ruc | numero | 30 | NULL | RUC de la compañía | |
| cl_direccion | descripcion | 254 | NULL | Dirección de la compañía | |
| cl_ciudad | Int | 4 | NULL | Código de la ciudad | |
| cl_telefono | telefono | 16 | NULL | Teléfono de contacto | |
| cl_email | email | 64 | NULL | Correo electrónico | |
| cl_contacto | descripcion | 64 | NULL | Nombre del contacto | |
| cl_tipo | catalogo | 10 | NULL | Tipo de compañía | L=Liquidadora<br>A=Aseguradora<br>O=Otros |
| cl_estado | estado | 1 | NULL | Estado de la compañía | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| cl_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| cl_usuario | login | 14 | NULL | Usuario que registró | |
| cl_terminal | descripcion | 64 | NULL | Terminal de registro | |

## Relaciones
- Relacionada con cl_ciudad a través de cl_ciudad

## Notas
Esta tabla almacena información de compañías de liquidación y aseguradoras con las que trabaja la institución.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
