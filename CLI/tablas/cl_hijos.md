# cl_hijos

## Descripción
Guarda información de los hijos de los clientes

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| hi_ente | Int | 4 | NOT NULL | Código del ente padre | |
| hi_secuencial | Tinyint | 1 | NOT NULL | Secuencial del hijo | |
| hi_nombre | descripcion | 64 | NULL | Nombre del hijo | |
| hi_fecha_nac | Datetime | 8 | NULL | Fecha de nacimiento | |
| hi_sexo | Char | 1 | NULL | Sexo del hijo | M=Masculino<br>F=Femenino |
| hi_cedula | numero | 30 | NULL | Número de cédula del hijo | |
| hi_edad | Tinyint | 1 | NULL | Edad del hijo | |

## Relaciones
- Relacionada con cl_ente a través de hi_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
