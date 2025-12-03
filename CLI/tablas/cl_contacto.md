# cl_contacto

## Descripción
Guarda la información de contactos del cliente

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| co_ente | Int | 4 | NOT NULL | Código del ente | |
| co_secuencial | Tinyint | 1 | NOT NULL | Secuencial del contacto | |
| co_nombre | descripcion | 64 | NULL | Nombre del contacto | |
| co_cargo | descripcion | 64 | NULL | Cargo del contacto | |
| co_telefono | telefono | 16 | NULL | Teléfono del contacto | |
| co_extension | Smallint | 2 | NULL | Extensión telefónica | |
| co_fax | telefono | 16 | NULL | Número de fax | |
| co_email | email | 64 | NULL | Correo electrónico | |

## Relaciones
- Relacionada con cl_ente a través de co_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
