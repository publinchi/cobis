# cl_his_ejecutivo

## Descripción
Contiene el histórico de asignaciones de ejecutivos o funcionarios a los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| he_secuencial | Int | 4 | NOT NULL | Secuencial del histórico | |
| he_ente | Int | 4 | NOT NULL | Código del ente | |
| he_funcionario | Smallint | 2 | NOT NULL | Código del funcionario | |
| he_fecha_inicio | Datetime | 8 | NOT NULL | Fecha de inicio de asignación | |
| he_fecha_fin | Datetime | 8 | NULL | Fecha de fin de asignación | |
| he_estado | estado | 1 | NOT NULL | Estado del registro histórico | V=Vigente<br>C=Cancelado |
| he_oficial | Smallint | 2 | NULL | Código del oficial | |
| he_tipo_oficial | catalogo | 10 | NULL | Tipo de oficial | O=Oficial de Cuenta<br>N=Oficial de Negocio |
| he_usuario | login | 14 | NULL | Usuario que registró el cambio | |
| he_fecha_registro | Datetime | 8 | NULL | Fecha de registro del histórico | |
| he_terminal | descripcion | 64 | NULL | Terminal desde donde se registró | |

## Relaciones
- Relacionada con cl_ente a través de he_ente
- Relacionada con cc_funcionario a través de he_funcionario
- Relacionada con cl_ejecutivo (tabla actual)

## Notas
Esta tabla mantiene un registro histórico de todas las asignaciones de ejecutivos a clientes, permitiendo auditoría y seguimiento.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
