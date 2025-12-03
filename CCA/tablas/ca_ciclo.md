# ca_ciclo

## Descripción

Tabla que controla los ciclos de créditos solidarios o grupales. Permite llevar el seguimiento de los diferentes ciclos de préstamos que puede tener un grupo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ci_grupo | int | 4 | NOT NULL | Código del grupo |
| ci_ciclo | tinyint | 1 | NOT NULL | Número de ciclo |
| ci_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio del ciclo |
| ci_fecha_fin | datetime | 8 | NULL | Fecha de finalización del ciclo |
| ci_estado | char | 1 | NOT NULL | Estado del ciclo<br><br>V = Vigente<br><br>C = Cerrado<br><br>A = Anulado |
| ci_monto_total | money | 8 | NOT NULL | Monto total del ciclo |
| ci_observacion | varchar | 255 | NULL | Observaciones del ciclo |

## Índices

- **ca_ciclo_1** (UNIQUE NONCLUSTERED INDEX): ci_grupo, ci_ciclo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
