# cr_deud1_tmp

## Descripción

Tabla temporal utilizada para el procesamiento de información de deudores durante operaciones batch o masivas.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_cliente | Int | 4 | NOT NULL | Código de cliente | |
| tmp_rol | Catalogo | 10 | NOT NULL | Rol del cliente | D: deudor<br>C: codeudor |
| tmp_identificacion | Varchar | 30 | NULL | Identificación del cliente | |

## Transacciones de Servicio

Utilizada en procesos batch.

## Índices

- tmp_tramite_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
