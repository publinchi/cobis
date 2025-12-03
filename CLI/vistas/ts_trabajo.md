# ts_trabajo

## Descripción
Vista de servicio para consulta de información laboral de clientes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| tr_ente | Int | 4 | NOT NULL | Código del ente | |
| tr_secuencial | Tinyint | 1 | NOT NULL | Secuencial del trabajo | |
| tr_empresa | descripcion | 254 | NULL | Nombre de la empresa | |
| tr_cargo | descripcion | 64 | NULL | Cargo que desempeña | |
| tr_direccion | descripcion | 254 | NULL | Dirección de la empresa | |
| tr_ciudad | Int | 4 | NULL | Ciudad de la empresa | |
| tr_telefono | telefono | 16 | NULL | Teléfono de la empresa | |
| tr_fecha_ingreso | Datetime | 8 | NULL | Fecha de ingreso a la empresa | |
| tr_tipo_contrato | catalogo | 10 | NULL | Tipo de contrato | I=Indefinido<br>F=Fijo<br>T=Temporal<br>S=Servicios |
| tr_salario | money | 8 | NULL | Salario mensual | |
| tr_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado<br>H=Histórico |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |
| nombre_ciudad | descripcion | 64 | NULL | Nombre de la ciudad | |

## Relaciones
- Vista basada en cl_trabajo con joins a cl_ente y cl_ciudad

## Notas
Esta vista facilita la consulta de información laboral de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
