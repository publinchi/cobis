/************************************************************************/
/*   Archivo:             ca_queryCliprod.sp                            */
/*   Stored procedure:    sp_queryClientesProd                          */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Fecha de escritura:  SEP.2013                                      */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                           MODIFICACIONES                             */
/*                                                                      */
/************************************************************************/  

use cob_cartera
go

/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */

if exists (select 1 from sysobjects where name = 'ca_query_clientes_Plano')
drop table ca_query_clientes_Plano
go
create table ca_query_clientes_Plano (
COD_CLIENTE                  int null,
TIPO_IDENTIFICACION          catalogo null,
IDENTIFICACION               varchar(30) null,           
NOMBRE                       varchar(65) null,                           
P_APELLIDO                   varchar(30) null,
S_APELLIDO                  varchar(30) null,
COD_OFICINA                 int null, 
NOM_OFICINA                 varchar(64) null,
SEXO                        catalogo null,
PRODUCTO                    cuenta null,
CODIGO_PROD                 smallint null,
NOM_PRODUCTO                varchar(50) null,
FECHA_APERTURA              datetime null,              
EMF                         int  null,                          
DES_EMF               varchar(64) null,
FECHA_PAG_VENCIMIENTO       datetime null, 
TIPO_PRODUCTO               catalogo null,
EXENTO_GMF                 char(1) null,
MONTO                       money null,
CATEGORIA_AHO               catalogo null,
DES_CATEGORIA               varchar(30) null,
CIUDAD                      int null,
DES_CIUDAD                  varchar(64) null,
RUTAL_URBANO                catalogo null,
TEL_RESIDENCIA              varchar(30)null,
TEL_NEGOCIO                 varchar(30) null,    
NUM_REG                     int null,
MINIMA_FECHA                datetime null,
TIPO_CLIENTE                varchar(20) null

)
go
if exists (select 1 from sysobjects where name = 'sp_queryClientesProd')
   drop proc sp_queryClientesProd
go
---ORS 638 oct.24.2013
create proc sp_queryClientesProd
   @i_param1  varchar(10),  --fecha desde
   @i_param2  varchar(10)  --fecha hasta


as

declare 
@w_dias_mora      int,
@w_path           varchar(250),
@w_cmd            varchar(250),
@w_s_app          varchar(250),
@w_destino        varchar(250),
@w_comando        varchar(1000),
@w_error          int,
@w_errores        varchar(250),
@w_nombre_plano   varchar(500),
@w_nombre_titulo  varchar(500),
@w_col_id         int,
@w_columna        varchar(30),
@w_cabecera       varchar(2500),
@w_fecha_sistema  char(8),
@w_fecha_desde    datetime,
@w_fecha_hasta    datetime,
@w_dias           smallint


--PARAMETRO  DE ENTRADA
select 	
@w_fecha_desde = @i_param1, ----fecha parametro1
@w_fecha_hasta  = @i_param2 ----fecha parametro2

select @w_dias = datediff(dd,@w_fecha_desde,@w_fecha_hasta)

if  @w_dias > 31
begin
	PRINT ''
	
	PRINT 'Atencion !!!!!! Entre fecha desde y hasta debe haber unicamente una semana o maximo 31 dias'
	PRINT '                Dias A Procesar --->   ' + cast (@w_dias as varchar)
	PRINT '                No se genera plano por que es demasiado pesado para consultar'
	return 0
end
truncate table  ca_query_clientes_Plano


create table #carga (
COD_CLIENTE1                  int null,
TIPO_IDENTIFICACION1          catalogo null,
IDENTIFICACION1               varchar(30) null,           
NOMBRE1                       varchar(65) null,                           
P_APELLIDO1                   varchar(30) null,
S_APELLIDO1                  varchar(30) null,
COD_OFICINA1                 int null, 
SEXO1                        catalogo null,
PRODUCTO1                    cuenta null,
CODIGO_PROD1                 smallint null,
FECHa_APERTURA1              datetime null,              
EMF1                         int  null,                          
FECHA_PAG_VENCIMIENTO1       datetime null, 
TIPO_PRODUCTO1              catalogo null,
EXENTO_GMF1                 char(1) null,
MONTO1                       money null,
CATEGORIA_AHO1               catalogo null,
CIUDAD1                      int null,
RUTAL_URBANO1                catalogo null,
TEL_RESIDENCIA1              varchar(30)null,
TEL_NEGOCIO1                 varchar(30) null,    
NUM_REG1                     int null,
COD_CLIENTE21                int null,
MINIMA_FECHA1                datetime null,
COD_LCIENTE31                int  null,
TIPO_CLIENTE1                varchar(20) null
)


select @w_fecha_sistema = convert(char(8),fp_fecha,112)
from cobis..ba_fecha_proceso


----Inicio Seleccion de Datos
IF OBJECT_ID('[tempdb]..[#CLIENTES]') IS NOT NULL
DROP TABLE #CLIENTES

SELECT *
INTO #CLIENTES
FROM (
      select do_codigo_cliente
            , MIN(min_fecha) min_fecha
      from (
      select do_codigo_cliente
            , MIN(do_fecha) min_fecha
      FROM cob_conta_super..sb_dato_operacion
      WHERE do_aplicativo in (7 ,200)
            AND do_tipo_operacion not in ('ALT_FNG','BALIQCPAS','BAPROGRPAS','POSGRADO','PREGRADO','CALAMIDAD','FINAGROEMP','EMSV2','EMNV','CRESPFUNC','SEGPOLVEHI')    
            AND do_fecha_concesion = do_fecha
      group by do_codigo_cliente
      UNION
         SELECT  dp_cliente
            , MIN(dp_fecha_apertura) min_fecha 
            FROM cob_conta_super..sb_dato_pasivas
            WHERE dp_fecha_apertura = dp_fecha
      group by dp_cliente
      ) A
      GROUP BY do_codigo_cliente
) B
where CONVERT(VARCHAR(10),min_fecha,112) BETWEEN CONVERT(VARCHAR(10),@w_fecha_desde,112) AND CONVERT(VARCHAR(10),@w_fecha_hasta,112)   


IF OBJECT_ID('[tempdb]..[#tipo]') IS NOT NULL
DROP TABLE #tipo

select do_codigo_cliente
      , case when Activo = 1 and Pasivo = 1 THEN 'Mixto'
            when Activo = 1 and Pasivo = 0 THEN 'Excl_Activo'
            when Activo = 0 and Pasivo = 1 THEN 'Excl_Pasivo'
            else 'Ojo' END tipo_cliente
into #tipo            
from (
  select do_codigo_cliente
      , MAX(Activo) Activo
      , MAX(Pasivo) Pasivo
      from (
        select distinct do_codigo_cliente
            , 1 Activo
            , 0 Pasivo
        FROM cob_conta_super..sb_dato_operacion
        where do_fecha = @w_fecha_hasta
            and CONVERT(VARCHAR(10),do_fecha_concesion,112) BETWEEN CONVERT(VARCHAR(10),@w_fecha_desde,112) AND CONVERT(VARCHAR(10),@w_fecha_hasta,112)
            and do_aplicativo in (7 ,200)
            AND do_tipo_operacion not in ('ALT_FNG','BALIQCPAS','BAPROGRPAS','POSGRADO','PREGRADO','CALAMIDAD','FINAGROEMP','EMSV2','EMNV','CRESPFUNC','SEGPOLVEHI')    
            and do_estado_contable IN (1,2)
      union all
      select distinct dp_cliente
            , 1 Activo
            , 0 Pasivo
        FROM cob_conta_super..sb_dato_pasivas
            where dp_estado IN (1,2)
      ) C
      group by do_codigo_cliente
) D

---insert into ca_query_clientes_Plano
insert into #carga 
select *
from (
SELECT      CLI.dc_cliente,
            CLI.dc_tipo_ced,
            CLI.dc_ced_ruc,
            CLI.dc_nombre,
            CLI.dc_p_apellido,
            CLI.dc_s_apellido,
            CLI.dc_oficina,
            CLI.dc_sexo,
            PRO.ID_Producto,
            PRO.Producto,
            PRO.Fecha_Apertura,
            PRO.EMF,
            PRO.Fecha_pago_o_vencimiento,
            PRO.Tipo_Producto,
            PRO.Exento_de_GMF,
            PRO.monto,
            PRO.categoria_aho,
            CNE.dd_ciudad as 'ciudad',
            CNE.dd_rural_urb as 'rural_urbano',
            TRE.te_valor as 'telefono_Residencia',
            TNE.te_valor as 'telefono_Negocio',          
            ROW_NUMBER() OVER(PARTITION BY CLI.dc_cliente ORDER BY PRO.Fecha_Apertura DESC) NUM_REG
            
FROM  (
                  SELECT      DISTINCT dc_cliente,
                             dc_tipo_ced,
                             dc_ced_ruc,
                             dc_nombre,
                             dc_p_apellido,
                             dc_s_apellido,
                             dc_oficina,
                             dc_sexo
                  FROM cob_conta_super..sb_dato_cliente 
            )as CLI INNER JOIN
            (
                  SELECT      do_banco as 'ID_Producto',
                             do_aplicativo as 'Producto',
                             do_codigo_cliente as 'ID_Cliente',
                             do_fecha_concesion as 'Fecha_Apertura',
                             do_oficial as 'EMF',
                             do_fecha_prox_vto as 'Fecha_pago_o_vencimiento',
                             NULL as 'Tipo_Producto',
                             NULL as 'Exento_de_GMF',
                             do_monto as 'monto',
                             NULL as 'categoria_aho'
                  FROM cob_conta_super..sb_dato_operacion
                  WHERE do_aplicativo in (7 ,200)
                             AND do_tipo_operacion not in ('ALT_FNG','BALIQCPAS','BAPROGRPAS','POSGRADO','PREGRADO','CALAMIDAD','FINAGROEMP','EMSV2','EMNV','CRESPFUNC','SEGPOLVEHI')    
                             AND do_fecha = @w_fecha_hasta
                             AND CONVERT(VARCHAR(10),do_fecha_concesion,112) BETWEEN CONVERT(VARCHAR(10),@w_fecha_desde,112) AND CONVERT(VARCHAR(10),@w_fecha_hasta,112)
                  UNION
                  SELECT      dp_banco as 'ID_Producto',
                             dp_aplicativo as 'Producto',
                             dp_cliente as 'ID_Cliente',
                             dp_fecha_apertura as 'Fecha_Apertura',
                             NULL as 'EMF',
                             dp_fecha_vencimiento as 'Fecha_pago_o_vencimiento',
                             dp_categoria_producto as 'Tipo_Producto',
                             dp_exen_gmf as 'Exento_de_GMF',
                             case when dp_aplicativo = 14 then dp_monto
                                  when dp_aplicativo = 4 then dp_saldo_disponible
                                  else 0
                             end as 'monto',      
                             dp_toperacion as 'categoria_aho'
                  FROM cob_conta_super..sb_dato_pasivas
                  WHERE dp_fecha = @w_fecha_hasta
                        AND CONVERT(VARCHAR(10),dp_fecha_apertura,112) BETWEEN CONVERT(VARCHAR(10),@w_fecha_desde,112) AND CONVERT(VARCHAR(10),@w_fecha_hasta,112)
                
            ) as PRO on PRO.ID_Cliente = dc_cliente left join
                        (
                             --TELEFONO RESIDENCIA
                             SELECT      DISTINCT
                                         te_ente, (RTRIM(LTRIM(ISNULL(te_prefijo,'')))+ '' +RTRIM(LTRIM(te_valor)))as te_valor 
                             FROM cobis..cl_telefono
                             WHERE te_tipo_telefono = 'C'
                                         AND te_valor <> '0000000'
                        ) as TRE on CLI.dc_cliente  =TRE.te_ente left join
                        (
                             --TELEFONO NEGOCIO
                             SELECT      te_ente, (RTRIM(LTRIM(ISNULL(te_prefijo,'')))+ '' +RTRIM(LTRIM(te_valor)))as te_valor 
                             FROM cobis..cl_telefono
                             WHERE te_tipo_telefono = 'D'
                                         AND te_valor <> '0000000'
                        ) AS  TNE on CLI.dc_cliente = TNE.te_ente left join
                        (
                             --CIUDAD NEGOCIO
                             SELECT DISTINCT dd_cliente, dd_ciudad, dd_rural_urb
                             FROM cob_conta_super..sb_dato_direccion
                             WHERE dd_descripcion <> 'MIGRACION'
                                   AND dd_principal = 'S'
                                   AND dd_tipo in ('011','002','003')                                          
                        ) as CNE on CLI.dc_cliente = CNE.dd_cliente
                        
)E
INNER JOIN #CLIENTES
ON dc_cliente = do_codigo_cliente

INNER JOIN #tipo
ON dc_cliente = #tipo.do_codigo_cliente
WHERE NUM_REG = 1

/****/
---Fin de Seleccion de Datos
---PRINT 'CARGA INICALLL'
---select * from #carga 
PRINT ''
PRINT 'pasando el dato a la tabla ca_query_clientes_Plano'

insert into cob_cartera..ca_query_clientes_Plano
select COD_CLIENTE1   ,TIPO_IDENTIFICACION1  ,IDENTIFICACION1       ,NOMBRE1               ,P_APELLIDO1           ,
S_APELLIDO1           ,COD_OFICINA1,          NULL,                  SEXO1                 ,PRODUCTO1 ,CODIGO_PROD1,NULL,FECHa_APERTURA1       ,
EMF1,                  NULL,FECHA_PAG_VENCIMIENTO1,TIPO_PRODUCTO1        ,EXENTO_GMF1          ,MONTO1                ,CATEGORIA_AHO1, null,
CIUDAD1,               NULL,RUTAL_URBANO1         ,TEL_RESIDENCIA1       ,TEL_NEGOCIO1          ,NUM_REG1,
MINIMA_FECHA1         ,TIPO_CLIENTE1
from #carga 

PRINT ''
PRINT 'update a la tabla ca_query_clientes_Plano oficina'
---NOMBRE DE LA OFICINA
update cob_cartera..ca_query_clientes_Plano
set NOM_OFICINA = of_nombre
from cobis..cl_oficina
where COD_OFICINA = of_oficina

PRINT ''
PRINT 'update a la tabla ca_query_clientes_Plano producto'
---NOMRE DEL PRODUCTO
update cob_cartera..ca_query_clientes_Plano
set NOM_PRODUCTO = pd_descripcion
from cobis..cl_producto
where CODIGO_PROD = pd_producto
/*
PRINT ''
PRINT 'update a la tabla ca_query_clientes_Plano Ahorros prod_banc '
---NOMBRE CATEGORIA DE AHORROS

update cob_cartera..ca_query_clientes_Plano
set DES_CATEGORIA = pb_descripcion
from cob_remesas..pe_pro_bancario
where CATEGORIA_AHO = convert(char(10),pb_pro_bancario)
*/
exec cob_interface..sp_cliProd_interfase

PRINT ''
PRINT 'update a la tabla ca_query_clientes_Plano Ciudad '
---NOMBRE CIUDAD
update cob_cartera..ca_query_clientes_Plano
set DES_CIUDAD = ci_descripcion
from cobis..cl_ciudad
where CIUDAD = ci_ciudad


PRINT ''
PRINT 'update a la tabla ca_query_clientes_Plano EMF '
---NOMBRE EMF OFICIAL
update cob_cartera..ca_query_clientes_Plano
set DES_EMF = fu_nombre                                                                                                                                                                                                                                                                        
from cobis..cc_oficial,cobis..cl_funcionario
where EMF  = oc_oficial
 and oc_funcionario = fu_funcionario


----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------

select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and   pa_nemonico = 'S_APP'

select @w_path  = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_queryClientesProd'

select 
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(2000), '')

select 
@w_nombre_plano = @w_path + 'CLientes_Productos_' + @w_fecha_sistema +'.txt',
@w_nombre_titulo = @w_path + 'TITULO.txt'

while 1 = 1 begin
   set rowcount 1
   select @w_columna = c.name,
          @w_col_id  = c.colid
   from sysobjects o, syscolumns c
   where o.id    = c.id
   and   o.name  = 'ca_query_clientes_Plano'
   and   c.colid > @w_col_id
   order by c.colid

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '^!'
end
select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

--Escribir Cabecera

select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_titulo
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo de  cabecera'
   print @w_comando
   return 1
end
--- Generar Archivo Plano de Datos

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_query_clientes_Plano out '
select @w_destino = @w_path + 'CLientes_Productos_' + @w_fecha_sistema + '.txt ', @w_errores  = @w_path + 'Query_PEP.err'
select @w_comando = @w_cmd + @w_path + 'CLientes_Productos_' + @w_fecha_sistema + '.txt  -b5000 -c -e' + @w_errores + ' -t"!" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error   = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error generando Archivo Query CLientes Productos'
   print @w_comando
   return 1
end

----------------------------------------
--Union de archivos
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_titulo + ' + ' + @w_path + 'CLientes_Productos_' + @w_fecha_sistema +'.txt' + ' ' + @w_nombre_titulo
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo  con cabecera'
   print @w_comando
   return 1
end

select @w_comando = 'ERASE ' + @w_path + 'CLientes_Productos_' + @w_fecha_sistema +'.txt' 
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Borrando Nombre plano que sobra'
   print @w_comando
   return 1
end

select @w_comando = 'REN '  + @w_nombre_titulo + '  ' + 'CLientes_Productos_' + @w_fecha_sistema +'.txt' 
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Erroeeer Renombrando ARchivo plano '
   print @w_comando
   return 1
end


return 0
go

