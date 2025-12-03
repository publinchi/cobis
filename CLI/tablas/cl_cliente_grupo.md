# cl_cliente_grupo

## Descripción
Contiene la información de los clientes que pertenecen a un grupo determinado creado en COBIS.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| cg_ente | Int | 4 | NOT NULL | Código del ente. | |
| cg_grupo | Int | 4 | NOT NULL | Código del grupo económico al cual pertenece el ente. | |
| cg_usuario | login | 14 | NOT NULL | Login del usuario que crea el registro. | |
| cg_terminal | Varchar | 32 | NOT NULL | Nombre de la terminal desde la cual se crea el registro. | |
| cg_oficial | Smallint | 2 | NULL | Código del oficial asignado al ente. | |
| cg_fecha_reg | Datetime | 8 | NOT NULL | Fecha de registro | |
| cg_rol | catalogo | 10 | NULL | Rol que desempeña el miembro | P: Presidente<br>A: Ahorrador<br>S: Secretario<br>T: Tesorero<br>D: Desertor<br>M: Integrante<br>(cl_rol_grupo) |
| cg_estado | catalogo | 10 | NULL | Estado del grupo | V: Vigente<br>C: Cancelado |
| cg_calif_interna | catalogo | 10 | NULL | No Aplica en esta versión, sirve para calificar al grupo. | |
| cg_fecha_desasociacion | datetime | 8 | NULL | Fecha en la que se desasocia el miembro del grupo. No aplica | |
| cg_tipo_relacion | catalogo | 10 | NULL | No Aplica | |
| cg_ahorro_voluntario | money | 8 | NULL | No Aplica en esta versión | |
| cg_lugar_reunion | varchar | 10 | NULL | No Aplica en esta versión | |
| cg_nro_ciclo | int | 4 | NULL | Nro del ciclo del integrante en el grupo. | |

## Relaciones
- Relacionada con cl_ente a través de cg_ente
- Relacionada con cl_grupo a través de cg_grupo

## Notas
Esta tabla gestiona la membresía de clientes en grupos económicos o solidarios.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
