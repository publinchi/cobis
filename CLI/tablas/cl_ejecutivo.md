# cl_ejecutivo

## Descripción
Contiene la información de los ejecutivos o funcionarios asignados a los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ec_ente | Int | 4 | NOT NULL | Código del ente (cliente) | |
| ec_funcionario | Smallint | 2 | NOT NULL | Código del funcionario asignado | |
| ec_fecha_inicio | Datetime | 8 | NOT NULL | Fecha de inicio de la asignación | |
| ec_fecha_fin | Datetime | 8 | NULL | Fecha de fin de la asignación | |
| ec_estado | estado | 1 | NOT NULL | Estado de la asignación | V=Vigente<br>C=Cancelado |
| ec_oficial | Smallint | 2 | NULL | Código del oficial | |
| ec_tipo_oficial | catalogo | 10 | NULL | Tipo de oficial | O=Oficial de Cuenta<br>N=Oficial de Negocio |

## Relaciones
- Relacionada con cl_ente a través de ec_ente
- Relacionada con cc_funcionario (tabla de administración) a través de ec_funcionario

## Notas
Esta tabla permite gestionar la asignación de ejecutivos o funcionarios responsables de la atención de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
