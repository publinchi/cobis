use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_llenauniverso_boc')
   drop proc sp_llenauniverso_boc
go

create procedure sp_llenauniverso_boc
/*************************************************************************/
/*      Archivo:                sp_llenauniverso_boc.sp                  */
/*      Stored procedure:       sp_llenauniverso_boc                     */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Sandro Vallejo                           */
/*      Fecha de escritura:     Sep 2020                                 */
/*********************************************************************** */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      'MACOSA', representantes exclusivos para el Ecuador de la        */
/*      'NCR CORPORATION'.                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Llena la tabla de operaciones con las operaciones que tienen     */
/*      registros de saldos para el boc                                  */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*     Fecha        Autor          Razón                                 */
/*     16/07/2021   K. Rodríguez   Estandarización de parámetros         */
/*************************************************************************/
/*************************************************************************/
		@i_param1        datetime,            -- Fecha
		@i_param2        char(1)       = 'N', -- Debug
		@i_param3        char(1)       = 'E'  -- Tipo: 'E'=TABLAS DE EXTRACTOR - 'S'=TABLAS CONTA SUPER 
as

declare @w_sp_name       descripcion,
        @w_error         int,
        @w_cod_producto  tinyint,
        @w_bancamia      varchar(24),
        @w_mensaje       varchar(255),
		@i_debug         char(1),
        @i_fecha         datetime, 
        @i_tipo          char(1)

-- KDR 16/07/21 Paso de parámetros a variables locales.
select @i_fecha  =  @i_param1,        
       @i_debug  =  @i_param2,         
       @i_tipo   =  @i_param3   
	   
select @w_sp_name      = 'sp_llenauniverso_boc',
       @w_error        = 0,
       @w_cod_producto = 7

if @i_debug = 'S' 
   print '--> sp_llena_universoboc. Fecha ' + cast(@i_fecha as varchar)     

-- DETERMINAR CODIGO DE BANCAMIA PARA EMPLEADOS
select @w_bancamia  = convert(varchar(24),pa_int)
from   cobis..cl_parametro
where  pa_nemonico = 'CCBA'
and    pa_producto = 'CTE'

-- INICIALIZAR TABLAS DEL BOC
delete cob_conta..cb_boc with (rowlock)
where  bo_empresa  = 1
and    bo_producto = @w_cod_producto
and    bo_fecha    = @i_fecha --LPO TEC para procesar solo lo del día

if @@error <> 0 
begin
   select 
   @w_mensaje = 'ERROR AL BORRAR LA TABLA DEL BOC',
   @w_error   = 710003
   goto ERRORFIN
end

delete cob_conta..cb_boc_det with (rowlock)
where  bod_producto = @w_cod_producto
and    bod_fecha    = @i_fecha --LPO TEC para procesar solo lo del día  

if @@error <> 0 
begin
   select 
   @w_mensaje = 'ERROR AL BORRAR LA TABLA DE DETALLES DEL BOC',
   @w_error   = 710003
   goto ERRORFIN
end


-- INICIALIZA TABLA DE TRANSACCIONES CONTABLES 
truncate table ca_boc_tmp                 

-- CARGAR TRANSACCIONES A CONTABILIZAR
if @i_tipo = 'E'
begin
   insert into ca_boc_tmp    
   select bt_banco            = do_banco, 
          bt_ofi_oper         = do_oficina,       
          bt_toperacion       = ltrim(rtrim(do_toperacion)),    
          bt_fecha            = @i_fecha,
          bt_perfil           = case when do_naturaleza = 1 then 'BOC_ACT'
                                     when do_naturaleza = 2 then 'BOC_PAS'
                                     when do_naturaleza = 3 then 'BOC_ADM' end,
          bt_moneda           = do_moneda,
          bt_gar_admisible    = case when do_tipo_garantias in ('H','I','A','E') then 'I' else 'O' end,
          bt_calificacion     = isnull(op_calificacion, 'A'),
          bt_clase            = ltrim(rtrim(do_clase_cartera)),
          bt_cliente          = op_cliente,
          bt_tramite          = do_tramite,
          bt_entidad_convenio = case when do_entidad_convenio = @w_bancamia then '1' else '0' end,
          bt_tipo_cartera     = ltrim(rtrim(do_tipo_cartera)),
          bt_subtipo_linea    = ltrim(rtrim(do_subtipo_cartera))
   from   cob_externos..ex_dato_operacion, cob_cartera..ca_operacion, cob_cartera..ca_estado
   where  do_fecha      = @i_fecha
   and    do_banco      = op_banco
   and    do_aplicativo = 7
   and    do_estado     = es_codigo
   and    es_procesa    = 'S'
end
else
begin
   insert into ca_boc_tmp    
   select bt_banco            = do_banco, 
          bt_ofi_oper         = do_oficina,       
          bt_toperacion       = ltrim(rtrim(do_tipo_operacion)),    
          bt_fecha            = @i_fecha,
          bt_perfil           = case when do_naturaleza = 1 then 'BOC_ACT'
                                     when do_naturaleza = 2 then 'BOC_PAS'
                                     when do_naturaleza = 3 then 'BOC_ADM' end,
          bt_moneda           = do_moneda,
          bt_gar_admisible    = case when do_tipo_garantias in ('H','I','A','E') then 'I' else 'O' end,
          bt_calificacion     = isnull(do_calificacion, 'A'),
          bt_clase            = ltrim(rtrim(do_clase_cartera)),
          bt_cliente          = do_codigo_cliente,
          bt_tramite          = do_tramite,
          bt_entidad_convenio = case when do_entidad_convenio = @w_bancamia then '1' else '0' end,
          bt_tipo_cartera     = ltrim(rtrim(do_tipo_cartera)),
          bt_subtipo_linea    = ltrim(rtrim(do_subtipo_cartera))
   from   cob_conta_super..sb_dato_operacion
   where  do_fecha            = @i_fecha
   and    do_aplicativo       = @w_cod_producto
   and    do_estado_contable in (1,2,3)
end

update statistics ca_boc_tmp

--Inicializa tabla de universo a procesar
truncate table ca_universo_boc

--Carga universo de operaciones con operaciones con transacciones a contabilizar
insert into ca_universo_boc (banco, intentos, hilo)
select bt_banco,
       0,
       0
from   ca_boc_tmp 
update statistics ca_universo_boc

return 0

ERRORFIN:
exec sp_errorlog
@i_fecha       = @i_fecha, 
@i_error       = @w_error, 
@i_usuario     = 'consola',
@i_tran        = 7000, 
@i_tran_name   = @w_sp_name, 
@i_rollback    = 'N',
@i_cuenta      = 'BOC', 
@i_descripcion = @w_mensaje

return @w_error

go


