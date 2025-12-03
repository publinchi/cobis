# cl_beneficiario_seguro

## Descripción
Contiene información de los beneficiarios de seguros asociados a los productos de los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| bs_secuencial | Int | 4 | NOT NULL | Secuencial del beneficiario | |
| bs_ente | Int | 4 | NOT NULL | Código del ente titular | |
| bs_producto | Int | 4 | NULL | Código del producto asegurado | |
| bs_nombre | descripcion | 254 | NOT NULL | Nombre completo del beneficiario | |
| bs_identificacion | numero | 30 | NULL | Número de identificación | |
| bs_tipo_identificacion | catalogo | 10 | NULL | Tipo de identificación | |
| bs_parentesco | catalogo | 10 | NULL | Parentesco con el titular | CO=Cónyuge<br>HI=Hijo<br>PA=Padre<br>HE=Hermano<br>OT=Otros |
| bs_porcentaje | Decimal | 5,2 | NULL | Porcentaje de beneficio | |
| bs_fecha_nacimiento | Datetime | 8 | NULL | Fecha de nacimiento | |
| bs_direccion | descripcion | 254 | NULL | Dirección del beneficiario | |
| bs_telefono | telefono | 16 | NULL | Teléfono de contacto | |
| bs_email | email | 64 | NULL | Correo electrónico | |
| bs_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| bs_usuario | login | 14 | NULL | Usuario que registró | |
| bs_terminal | descripcion | 64 | NULL | Terminal de registro | |
| bs_estado | estado | 1 | NULL | Estado del beneficiario | V=Vigente<br>C=Cancelado |
| bs_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de bs_ente
- Relacionada con cl_det_producto a través de bs_producto

## Notas
Esta tabla gestiona los beneficiarios de seguros asociados a productos financieros de los clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
