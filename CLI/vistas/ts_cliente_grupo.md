# ts_cliente_grupo

## Descripción
Vista de servicio para consulta de clientes que pertenecen a grupos.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| cg_ente | Int | 4 | NOT NULL | Código del ente | |
| cg_grupo | Int | 4 | NOT NULL | Código del grupo | |
| cg_fecha_reg | Datetime | 8 | NOT NULL | Fecha de registro | |
| cg_rol | catalogo | 10 | NULL | Rol que desempeña el miembro | P=Presidente<br>A=Ahorrador<br>S=Secretario<br>T=Tesorero<br>M=Integrante |
| cg_estado | catalogo | 10 | NULL | Estado del grupo | V=Vigente<br>C=Cancelado |
| cg_nro_ciclo | int | 4 | NULL | Nro del ciclo del integrante en el grupo | |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |
| nombre_grupo | descripcion | 64 | NULL | Nombre del grupo | |

## Relaciones
- Vista basada en cl_cliente_grupo con joins a cl_ente y cl_grupo

## Notas
Esta vista facilita la consulta de membresía de clientes en grupos.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
