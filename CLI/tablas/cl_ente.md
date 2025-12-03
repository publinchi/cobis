# cl_ente

## Descripción
Tabla principal que contiene la información básica de todos los entes (personas naturales y jurídicas) registrados en el sistema COBIS.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| en_ente | Int | 4 | NOT NULL | Código único del ente | |
| en_subtipo | Char | 1 | NOT NULL | Subtipo de ente | P=Persona Natural<br>C=Compañía |
| en_ced_ruc | numero | 30 | NOT NULL | Número de cédula o RUC | |
| en_tipo_ced | catalogo | 10 | NULL | Tipo de documento de identificación | |
| en_nomlar | descripcion | 254 | NULL | Nombre largo del ente | |
| en_nombre | descripcion | 64 | NULL | Primer nombre | |
| en_snombre | descripcion | 64 | NULL | Segundo nombre | |
| en_apellido | descripcion | 64 | NULL | Primer apellido | |
| en_sapelido | descripcion | 64 | NULL | Segundo apellido | |
| en_sexo | Char | 1 | NULL | Sexo | M=Masculino<br>F=Femenino |
| en_estado_civil | catalogo | 10 | NULL | Estado civil | |
| en_fecha_nac | Datetime | 8 | NULL | Fecha de nacimiento | |
| en_lugar_nac | Int | 4 | NULL | Lugar de nacimiento (código de ciudad) | |
| en_nacionalidad | catalogo | 10 | NULL | Nacionalidad | |
| en_profesion | catalogo | 10 | NULL | Profesión | |
| en_nivel_estudio | catalogo | 10 | NULL | Nivel de estudios | |
| en_actividad | catalogo | 10 | NULL | Actividad económica | |
| en_tipo_vivienda | catalogo | 10 | NULL | Tipo de vivienda | |
| en_oficina | Smallint | 2 | NULL | Oficina de registro | |
| en_oficial | Smallint | 2 | NULL | Oficial asignado | |
| en_fecha_crea | Datetime | 8 | NULL | Fecha de creación del registro | |
| en_fecha_mod | Datetime | 8 | NULL | Fecha de última modificación | |
| en_usuario | login | 14 | NULL | Usuario que creó el registro | |
| en_terminal | descripcion | 64 | NULL | Terminal desde donde se creó | |
| en_estado | estado | 1 | NULL | Estado del ente | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| en_tipo_dp | catalogo | 10 | NULL | Tipo de documento principal | |
| en_nro_dp | numero | 30 | NULL | Número de documento principal | |
| en_fecha_emi_dp | Datetime | 8 | NULL | Fecha de emisión del documento | |
| en_fecha_venc_dp | Datetime | 8 | NULL | Fecha de vencimiento del documento | |
| en_retencion | Char | 1 | NULL | Sujeto a retención | S=Sí<br>N=No |
| en_casilla | descripcion | 64 | NULL | Casilla postal | |
| en_email | email | 64 | NULL | Correo electrónico | |
| en_direccion_dv | descripcion | 254 | NULL | Dirección para documentos varios | |
| en_ciudad_dv | Int | 4 | NULL | Ciudad para documentos varios | |
| en_sector_dv | descripcion | 64 | NULL | Sector para documentos varios | |
| en_parroquia_dv | Int | 4 | NULL | Parroquia para documentos varios | |

## Relaciones
- Tabla central que se relaciona con múltiples tablas del sistema
- Relacionada con cl_ciudad a través de en_lugar_nac y en_ciudad_dv
- Relacionada con cl_parroquia a través de en_parroquia_dv
- Relacionada con cl_oficina a través de en_oficina

## Notas
Esta es la tabla más importante del módulo de Clientes. Almacena tanto personas naturales como jurídicas. El campo en_subtipo determina el tipo de ente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
