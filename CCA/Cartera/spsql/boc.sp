use cob_cartera
go

-- CREAR TABLAS DE TRABAJO
--GFP se comenta por erores de compilacion
/*
-- PERFIL
create table #perfil_boc
(
 pb_perfil     varchar(10) not null,
 pb_concepto   varchar(10) not null,
 pb_codigo     int         not null,
 pb_codvalor   int         not null,
 pb_parametro  catalogo    not null,
 pb_tparametro varchar(20) not null
)
go

-- CUENTAS
create table #cuentas_boc 
(
 parametro  varchar(10) not null,
 clave      varchar(40) not null,
 cuenta     varchar(40) not null,
 tercero    char(1)     not null,
 naturaleza char(1)     not null
)
go

-- DATOS RUBRO
create table #dato_rubro 
(
 dr_banco         varchar(24) not null,
 dr_toperacion    varchar(20) not null,
 dr_cliente       int         not null,
 dr_oficina       smallint    not null,
 dr_concepto      varchar(10) not null,
 dr_tgarantia     varchar(10) not null,
 dr_calificacion  varchar(10) not null,
 dr_clase_cartera varchar(10) not null,
 dr_parametro     varchar(40) not null,
 dr_clave         varchar(40) not null,
 dr_valor         money       not null
)
go
*/
if exists (select 1 from sysobjects where name = 'sp_boc')
   drop proc sp_boc
go

create procedure sp_boc
/************************************************************************/
/*   Nombre Fisico:        boc.sp                                       */
/*   Nombre Logico:        sp_boc                                       */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         FdlT                                         */
/*   Fecha de escritura:   Jul/2009                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*	 Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                               PROPOSITO                              */
/*   Balance Operativo Contable de Cartera                              */
/************************************************************************/
/*                               CAMBIOS                                */
/*   FECHA     AUTOR          CAMBIO                                    */
/*   Nov-2010  Elcira Pelaez  NR-0059 Parte del Diferido en transaccion */
/*                            de reestructuracion RES                   */
/*   Feb-2011  Elcira Pelaez  Inc-16421 Incluir seleccion Origen Fondos */
/*   Ago-2012  Luis C. Moreno Req 293 Incluye valores por Reconocimiento*/
/*   Sep-2017  Tania Baidal   Modificacion a vertical de estructura     */
/*                            sb_dato_operacion_rubro y programacion    */
/*                            de llenado en vertical de las tablas tmp  */
/*   Sep-2019  Luis Ponce     BOC Cartera Te Creemos                    */
/*   Mar-2020  Luis Ponce     Ajustes BOC Te Creemos por Visual Batch   */
/*   Sep-2020  Sandro Vallejo Boc en paralelismo                        */
/* 08-Mar-2022  Guisela Fernandez Generacion de clave para parametro    */
/*                               sp_ca09_pf                             */
/* 08-Jun-2023  Guisela Fernandez Generacion de clave para parametro    */
/*                               sp_ca10_pf                             */
/* 13-JUL-2023	Mateo Cordova	Modificacion de proceso de contabilización*/
/* 								automática de transacciones				*/
/************************************************************************/

(
    @i_debug         char(1) = 'N',
    @i_fecha         datetime, 
    @i_tipo          char(1) = 'E',  -- 'E'=TABLAS DE EXTRACTOR - 'S'=TABLAS CONTA SUPER 
    @i_hilo          tinyint         -- numero de hilos a generar o hilo que debe procesar
)
as

declare
@w_producto           int,
@w_sp_name            varchar(20),
@w_error              int,
@w_moneda_nacional    tinyint,
@w_num_dec            int,
@w_vlr_despreciable   float,
@w_detener_proceso    char(1),
@w_banco              varchar(24),
@w_commit             char(1),
@w_mensaje            varchar(100),
@w_oda_grupo_contable catalogo,
@w_sector             varchar(10),
@w_originacion        varchar(10),
@w_categoria_plazo    varchar(10)

-- INICIO DE VARIABLES DE TRABAJO 
select
@w_sp_name         = 'sp_boc',
@w_producto        = 7,
@w_commit          = 'N',
@w_detener_proceso = 'N'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

/* DECIMALES DE LA MONEDA NACIONAL */
exec @w_error   = sp_decimales
@i_moneda       = @w_moneda_nacional,
@o_decimales    = @w_num_dec out

select @w_vlr_despreciable = isnull(1.0 / power(10, @w_num_dec + 2),0)

-- LAZO DE TRANSACCIONES A CONTABILIZAR 
while @w_detener_proceso = 'N' 
begin 

   select @w_error = 0

   -- OPERACION A PROCESAR
   set rowcount 1 
 
   select @w_banco = banco
   from   ca_universo_boc
   where  hilo     = @i_hilo 
   and    intentos < 2 
   order by id 

   if @@rowcount = 0 
   begin 
      set rowcount 0 
      select @w_detener_proceso = 'S' 
      break 
   end 
 
   if @i_debug = 'S' print 'Operacion ' + @w_banco 
   
   set rowcount 0 
 
   -- ATOMICIDAD 
   BEGIN TRAN
      
   update ca_universo_boc set 
   intentos = intentos + 1, 
   hilo     = 100 -- significa Procesado o procesando 
   where  banco = @w_banco  
   and    hilo  = @i_hilo 
      
   COMMIT TRAN

   -- INICIALIZAR TABLA DE RUBROS POR OPERACION
   truncate table #dato_rubro
   
   --GFP Para generacion de clave
   select @w_oda_grupo_contable = oda_grupo_contable,
          @w_sector             = op_sector,
          @w_categoria_plazo    = oda_categoria_plazo
   from ca_operacion_datos_adicionales, ca_operacion
   where oda_operacion = op_operacion
   and   op_banco = @w_banco
   
   --GFP
   if exists (select 1 from ca_transaccion where tr_banco = @w_banco and tr_tran = 'RES' and tr_estado <> 'RV')
   begin
      select @w_originacion = 'E'
   end
   else
   begin
      /*select @w_originacion = case when tr_tipo in ('O','R')  then 'O' 
                                   when tr_tipo = 'F'         then 'R-F' end*/
		select @w_originacion = case when (tr_tipo = 'O' or (tr_tipo = 'R' and tr_subtipo = 'R')) then 'O'										   
								when tr_tipo = 'R' and tr_subtipo in ('N','F')   then 'R-F' end
								   
      from cob_credito..cr_tramite, ca_operacion with (nolock)
      where op_tramite = tr_tramite
      and op_banco = @w_banco
   end
   
   -- DETERMINAR LOS DATOS DE LA OPERACION
   if @i_tipo = 'E'
   begin
      insert into #dato_rubro
      select
      dr_banco         = bt_banco,
      dr_toperacion    = bt_toperacion,
      dr_cliente       = bt_cliente,
      dr_oficina       = bt_ofi_oper,
      dr_concepto      = dr_concepto,
      dr_tgarantia     = bt_gar_admisible,
      dr_calificacion  = bt_calificacion,
      dr_clase_cartera = bt_clase,
      dr_parametro     = pb_parametro,
      dr_clave         = case when pb_tparametro = 'sp_ca01_pf'   then rtrim(ltrim(bt_tipo_cartera)) +'.'+ rtrim(ltrim(bt_clase)) +'.'+ rtrim(ltrim(isnull(bt_subtipo_linea, '99'))) +'.'+ rtrim(ltrim(isnull(bt_toperacion, '')))
                              when pb_tparametro = 'sp_ca02_pf'   then convert(varchar,bt_moneda)
                              when pb_tparametro = 'sp_ca03_pf'   then rtrim(ltrim(bt_clase)) +'.'+ rtrim(ltrim(bt_tipo_cartera))
                              when pb_tparametro = 'sp_ca04_pf'   then rtrim(ltrim(dr_concepto))
							  when pb_tparametro = 'sp_ca09_pf'   then right('0'+rtrim(ltrim(isnull(@w_sector,''))),2) +'.'+ right('0'+rtrim(ltrim(isnull(@w_oda_grupo_contable, ''))),2) -- GFP 08-Mar-2022
                              when pb_tparametro = 'sp_ca10_pf'   then rtrim(ltrim(bt_clase)) +'.'+ rtrim(ltrim(@w_categoria_plazo))+'.'+ convert(varchar,dr_estado)+'.'+ rtrim(ltrim(@w_originacion))
                              when pb_tparametro = 'sp_tipo_oper' then rtrim(ltrim(isnull(bt_toperacion, ''))) end, --LPO TEC Sp de resolucion de parametros.
      dr_valor         = isnull(dr_valor,0)
      from  #perfil_boc, ca_boc_tmp, cob_externos..ex_dato_operacion_rubro 
      where bt_banco                = @w_banco
      and   bt_fecha                = @i_fecha
      and   bt_fecha                = dr_fecha
      and   dr_banco                = bt_banco
      and   dr_aplicativo           = @w_producto
      and   dr_codvalor             = pb_codvalor
      and   pb_perfil               = bt_perfil   
      and   abs(isnull(dr_valor,0)) > @w_vlr_despreciable
   end
   else
   begin
      insert into #dato_rubro
      select
      dr_banco         = bt_banco,
      dr_toperacion    = bt_toperacion,
      dr_cliente       = bt_cliente,
      dr_oficina       = bt_ofi_oper,
      dr_concepto      = dr_concepto,
      dr_tgarantia     = bt_gar_admisible,
      dr_calificacion  = bt_calificacion,
      dr_clase_cartera = bt_clase,
      dr_parametro     = pb_parametro,
      dr_clave         = case when pb_tparametro = 'sp_ca01_pf'   then rtrim(ltrim(bt_tipo_cartera)) +'.'+ rtrim(ltrim(bt_clase)) +'.'+ rtrim(ltrim(isnull(bt_subtipo_linea, '99'))) +'.'+ rtrim(ltrim(isnull(bt_toperacion, '')))
                              when pb_tparametro = 'sp_ca02_pf'   then convert(varchar,bt_moneda)
                              when pb_tparametro = 'sp_ca03_pf'   then rtrim(ltrim(bt_clase)) +'.'+ rtrim(ltrim(bt_tipo_cartera))
                              when pb_tparametro = 'sp_ca04_pf'   then rtrim(ltrim(dr_concepto))
							  when pb_tparametro = 'sp_ca09_pf'   then right('0'+rtrim(ltrim(isnull(@w_sector,''))),2) +'.'+ right('0'+rtrim(ltrim(isnull(@w_oda_grupo_contable, ''))),2) -- GFP 08-Mar-2022
                              when pb_tparametro = 'sp_ca10_pf'   then rtrim(ltrim(bt_clase)) +'.'+ rtrim(ltrim(@w_categoria_plazo))+'.'+ convert(varchar,dr_estado)+'.'+ rtrim(ltrim(@w_originacion))
							  when pb_tparametro = 'sp_tipo_oper' then rtrim(ltrim(isnull(bt_toperacion, ''))) end, --LPO TEC Sp de resolucion de parametros.
      dr_valor         = isnull(dr_valor,0)
      from  #perfil_boc, ca_boc_tmp, cob_conta_super..sb_dato_operacion_rubro 
      where bt_banco                = @w_banco
      and   bt_fecha                = @i_fecha
      and   bt_fecha                = dr_fecha
      and   dr_banco                = bt_banco
      and   dr_aplicativo           = @w_producto
      and   dr_codvalor             = pb_codvalor
      and   pb_perfil               = bt_perfil   
      and   abs(isnull(dr_valor,0)) > @w_vlr_despreciable
   end   

   -- INICIALIZAR TRANSACCIONALIDAD
   BEGIN TRAN 
   select @w_commit = 'S'
      
   -- INSERTAR DATOS DE LA OPERACION
   insert into cob_conta..cb_boc_det
   select @i_fecha,         cuenta,   
          dr_oficina,       case tercero when 'S' then dr_cliente else 0 end, 
          dr_banco,         dr_concepto,
          dr_tgarantia,     dr_calificacion,
          dr_clase_cartera, case naturaleza when 'D' then dr_valor else dr_valor * -1 end, 
          @w_producto
   from   #dato_rubro, #cuentas_boc
   where  dr_clave     = clave
   and    dr_parametro = parametro

   if @@error = 0
      goto SIGUIENTE 
   else   
   begin
      select 
      @w_mensaje = 'ERROR AL INSERTAR DETALLE EN cob_conta..cb_boc_det OP: ' + @w_banco,
      @w_error   = 710001
      goto ERROR1
   end
   
   ERROR1:
      
   if @w_commit = 'S' 
   begin
      rollback tran
      select @w_commit = 'N'
   end      

   if @i_debug = 'S' print '            ERROR1 --> ' + @w_mensaje

   exec sp_errorlog
   @i_fecha       = @i_fecha, 
   @i_error       = 7300, 
   @i_usuario     = 'OPERADOR',
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name, 
   @i_rollback    = 'N',
   @i_cuenta      = @w_banco, 
   @i_descripcion = @w_mensaje

   SIGUIENTE:

   if @w_commit = 'S' 
   begin 
      commit tran
      select @w_commit = 'N'
   end  
end  --while @w_detener_proceso = 'N' 

return 0

ERRORFIN:

exec cob_cartera..sp_errorlog
@i_fecha       = @i_fecha, 
@i_error       = 7300,
@i_usuario     = 'OPERADOR',
@i_tran        = 7000,
@i_tran_name   = @w_sp_name,
@i_rollback    = 'N',
@i_cuenta      = 'BOC',
@i_descripcion = @w_mensaje

return @w_error
go
