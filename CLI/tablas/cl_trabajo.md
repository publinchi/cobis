# cl_trabajo

## Descripción
Contiene información laboral de los clientes (personas naturales).

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| tr_ente | Int | 4 | NOT NULL | Código del ente | |
| tr_secuencial | Tinyint | 1 | NOT NULL | Secuencial del trabajo | |
| tr_empresa | descripcion | 254 | NULL | Nombre de la empresa | |
| tr_cargo | descripcion | 64 | NULL | Cargo que desempeña | |
| tr_direccion | descripcion | 254 | NULL | Dirección de la empresa | |
| tr_ciudad | Int | 4 | NULL | Ciudad de la empresa | |
| tr_telefono | telefono | 16 | NULL | Teléfono de la empresa | |
| tr_extension | Smallint | 2 | NULL | Extensión telefónica | |
| tr_fecha_ingreso | Datetime | 8 | NULL | Fecha de ingreso a la empresa | |
| tr_fecha_salida | Datetime | 8 | NULL | Fecha de salida de la empresa | |
| tr_tipo_contrato | catalogo | 10 | NULL | Tipo de contrato | I=Indefinido<br>F=Fijo<br>T=Temporal<br>S=Servicios |
| tr_salario | money | 8 | NULL | Salario mensual | |
| tr_otros_ingresos | money | 8 | NULL | Otros ingresos | |
| tr_actividad_empresa | catalogo | 10 | NULL | Actividad económica de la empresa | |
| tr_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| tr_usuario | login | 14 | NULL | Usuario que registró | |
| tr_terminal | descripcion | 64 | NULL | Terminal de registro | |
| tr_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado<br>H=Histórico |
| tr_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de tr_ente
- Relacionada con cl_ciudad a través de tr_ciudad
- Relacionada con cl_actividad_ec a través de tr_actividad_empresa

## Notas
Esta tabla permite registrar el historial laboral del cliente, incluyendo trabajos actuales y anteriores.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
