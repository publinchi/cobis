# ts_cia_liquidacion

## Descripción
Vista de servicio para consulta de compañías de liquidación o aseguradoras.

## Estructura de la vista

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
| nombre_ciudad | descripcion | 64 | NULL | Nombre de la ciudad | |

## Relaciones
- Vista basada en cl_com_liquidacion con join a cl_ciudad

## Notas
Esta vista facilita la consulta de compañías de liquidación y aseguradoras.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
