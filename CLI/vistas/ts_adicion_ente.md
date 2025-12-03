# ts_adicion_ente

## Descripción
Vista de servicio para consulta de datos adicionales de entes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| de_ente | Int | 4 | NOT NULL | Código del ente | |
| de_dato_adicional | Int | 4 | NOT NULL | Código del dato adicional | |
| de_valor | Varchar | 254 | NULL | Valor del dato adicional | |
| da_nombre | Varchar | 64 | NULL | Nombre del campo adicional | |
| da_descripcion | descripcion | 254 | NULL | Descripción del campo | |
| da_tipo_dato | Char | 1 | NULL | Tipo de dato | C=Carácter<br>N=Numérico<br>F=Fecha<br>M=Monto<br>L=Lógico |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |

## Relaciones
- Vista basada en cl_dadicion_ente con joins a cl_dato_adicion y cl_ente

## Notas
Esta vista facilita la consulta de datos adicionales configurados para cada cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
