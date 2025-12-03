# cr_deudores_tmp

## Descripción

Tabla temporal para almacenar información de deudores durante procesos de carga masiva o migración.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_cliente | Int | 4 | NOT NULL | Código de cliente | |
| tmp_rol | Catalogo | 10 | NOT NULL | Rol del cliente en el trámite | D: deudor<br>C: codeudor<br>G: grupo |
| tmp_ced_ruc | Varchar | 30 | NULL | Identificación del cliente | |
| tmp_nombre | Varchar | 255 | NULL | Nombre del cliente | |

## Transacciones de Servicio

Utilizada en procesos de migración y carga masiva.

## Índices

- tmp_tramite_cliente_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
