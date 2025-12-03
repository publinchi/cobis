# cu_poliza

## Descripción

Registra las pólizas de seguro que amparan los bienes registrados como garantías.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| po_poliza | Varchar | 40 | NULL | Código de la póliza |
| po_aseguradora | Varchar | 10 | NOT NULL | Código aseguradora |
| po_corredor | Smallint | 2 | NULL | Código del corredor |
| po_fvigencia_inicio | Datetime | 8 | NULL | Fecha de vigencia Inicio |
| po_fvigencia_fin | Datetime | 8 | NULL | Fecha de vigencia Fin |
| po_moneda | Tinyint | 1 | NULL | Código de la moneda |
| po_fendoso_fin | Datetime | 8 | NULL | Fecha de endoso final |
| po_monto_endoso | Money | 8 | NULL | Monto de endoso |
| po_monto_poliza | Money | 8 | NOT NULL | Monto de la póliza |
| po_estado_poliza | Varchar | 10 | NULL | Estado de la póliza<br><br>V= Vigente<br>E= Excepcional<br>C= Cerrada |
| po_descripcion | Varchar | 120 | NULL | Descripción de la póliza |
| po_codigo_externo | Varchar | 64 | NULL | Código compuesto de la garantía |
| po_fecha_endozo | Datetime | 8 | NULL | Fecha en la que se realiza el endoso |
| po_cobertura | Catalogo | 10 | NULL | Cobertura de la póliza |
| po_fendozo_fin | DateTime | 8 | NULL | Fecha final del endoso |
| po_secuencial_pag | int | 4 | NULL | Secuencial de Pago |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
