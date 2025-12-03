/************************************************************************/
/*   Archivo:             imptabla_gru.sp                               */
/*   Stored procedure:    sp_imp_tabla_grupo                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:        Luis Ponce                                    */
/*   Fecha de escritura:    06/May./2017                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para imprimir la tabla de amortizacion del credito grupal */
/*                         MODIFICACIONES                               */
/*      FECHA           AUTOR      RAZON                                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_imp_tabla_grupo')
   drop proc sp_imp_tabla_grupo
go

create proc sp_imp_tabla_grupo (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_operacion         char(1)     = null,
   @i_banco             cuenta      = null,
   @i_formato_fecha     int         = null,
   @i_dividendo         int         = null
)
as
declare
   @w_sp_name                      varchar(32),
   @w_hora                         varchar(10), 
   @w_direccion_reunion            varchar(64),
   @w_fecha_imp                    varchar(10),
   @w_grupo                        int,
   @w_nombre_grupo                 varchar(30),
   @w_nombre_oficina               varchar(64),
   @w_fecha_solicitud              varchar(10),
   @w_banca                        varchar(30),
   @w_plazo_dias                   int,
   @w_toperacion                   varchar(30),
   @w_proxima_cuota                money,
   @w_prox_fecha_ven               varchar(10),
   @w_error                        int,
   @w_moneda                       tinyint,
   @w_moneda_desc                  varchar(30),
   @w_monto                        money,
   @w_plazo                        smallint,
   @w_tplazo                       varchar(30),
   @w_tipo_amortizacion            varchar(15),
   @w_tdividendo                   varchar(30),
   @w_periodo_cap                  smallint,
   @w_periodo_int                  smallint,
   @w_gracia                       smallint,
   @w_gracia_cap                   smallint,
   @w_gracia_int                   smallint,
   @w_tasa                         float,
   @w_mes_gracia                   tinyint,
   @w_fecha_fin                    varchar(10),
   @w_fecha_liq                    varchar(10),
   @w_fecha_des                    varchar(10),
   @w_num_dec                      tinyint,
   @w_oficina                      smallint,
   @w_nom_oficina                  varchar(64),
   @w_fecha                        datetime,
   @w_estado                       varchar(30),
   @w_toperacion_cod               varchar(10)

   
select @w_sp_name       = 'sp_imp_tabla_grupo',
       @i_formato_fecha = 103

select @w_moneda = op_moneda
from   ca_operacion
where  op_banco = @i_banco


-- DECIMALES
exec sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out



-- CABECERA DE LA IMPRESION
if @i_operacion = 'C'
begin
    select @w_fecha_imp        = convert(varchar(10), @s_date, @i_formato_fecha)
    select @w_hora             = convert(varchar,datepart(hh,getdate())) + ':' + convert(varchar,datepart(mi,getdate())) + ':' + convert(varchar,datepart(ss,getdate()))
    --select @s_user             = @s_user
    select @w_oficina          = of_oficina,
           @w_nombre_oficina   = substring(of_nombre,1,30)
    from cobis..cl_oficina
    where of_oficina = @s_ofi

    select @w_nombre_grupo = (select UPPER(isnull(en_nombre,''))+' ' + UPPER(isnull(p_s_nombre,''))+' '+
	                                         UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))
	                            from cobis..cl_ente where en_ente  = OP.op_cliente),
	       @w_toperacion_cod = op_toperacion,
		   @w_fecha_liq      = convert(varchar(10), op_fecha_fin, @i_formato_fecha),
		   @w_fecha_des      = convert(varchar(10), op_fecha_liq, @i_formato_fecha)
    from cob_cartera..ca_operacion OP WHERE op_banco = @i_banco
		
	if(@w_toperacion_cod = 'GRUPAL')
	begin
        select TOP 1 @w_nombre_grupo = (select gr_nombre from cobis..cl_grupo where gr_grupo  = TG.tg_grupo)
		from cob_credito..cr_tramite_grupal TG
		where tg_referencia_grupal =  @i_banco
	end

   select
   'FECHA_IMP'      = @w_fecha_imp,
   'HORA'           = @w_hora,
   'USUARIO'        = @s_user,
   'OFICINA_ID'     = @w_oficina,
   'OFICINA_NOMBRE' = @w_nombre_oficina,
   'GRUPO_ID'       = @w_grupo,
   'GRUPO_NOMBRE'   = @w_nombre_grupo,
   'DIR_REUNION'    = @w_direccion_reunion,
   'TIPO_OPERACION' = @w_toperacion_cod,
   'FECHA_DESEMBOLSO' = @w_fecha_des,
   'FECHA_LIQUIDACION' = @w_fecha_liq      
end -- C


-- DATOS DE LA OPERACION PARA LA IMPRESION
if @i_operacion = 'D'
begin
   
   --Llamado al sp que actualiza los datos del Prestamo Grupal sumando la informacion de las Operaciones Individuales
   exec @w_error = cob_cartera..sp_actualiza_grupal
   @i_banco     = @i_banco,
   @i_desde_cca = 'N' -- N = tablas definitivas
      
   if @w_error <> 0
   begin
      select @w_sp_name = 'sp_imp_tabla_grupo'
      goto ERROR
   end
   
   select
   @i_banco             = @i_banco,
   @w_moneda            = op_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_monto             = op_monto,
   @w_plazo             = op_plazo,
   @w_tplazo            = (select td_descripcion from cob_cartera..ca_tdividendo where td_tdividendo = OP.op_tplazo),
   @w_tipo_amortizacion = op_tipo_amortizacion,
   @w_tdividendo        = (select td_descripcion from cob_cartera..ca_tdividendo where td_tdividendo = OP.op_tdividendo),
   @w_banca             = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'cl_banca_cliente' and b.codigo = OP.op_sector),
   @w_estado            = (select es_descripcion from ca_estado where es_codigo = OP.op_estado),
   @w_fecha_liq         = convert(varchar(10),op_fecha_liq,@i_formato_fecha),
   @w_fecha_solicitud   = (select convert(varchar(10),tr_fecha_crea,@i_formato_fecha) from cob_credito..cr_tramite where tr_tramite = OP.op_tramite),
   @w_tasa              = (select isnull(sum(ro_porcentaje),0) from ca_rubro_op where ro_operacion = OP.op_operacion and ro_concepto = 'INT'),
   @w_plazo_dias        = (select OP.op_plazo * td_factor from cob_cartera..ca_tdividendo where td_tdividendo = OP.op_tplazo),
   @w_periodo_cap       = op_periodo_cap,
   @w_periodo_int       = op_periodo_int,
   @w_toperacion        = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'ca_toperacion' and b.codigo = OP.op_toperacion),
   @w_fecha_fin         = convert(varchar(10),op_fecha_fin,@i_formato_fecha),
   @w_mes_gracia        = op_mes_gracia,
   @w_gracia            = isnull(di_gracia,0),
   @w_gracia_cap        = op_gracia_cap,
   @w_gracia_int        = op_gracia_int,
   @w_proxima_cuota     = (select sum(am_cuota)
                           from ca_amortizacion
                           where am_operacion    = DI.di_operacion
                             and am_dividendo    = DI.di_dividendo),
   @w_prox_fecha_ven    = convert(varchar(10),di_fecha_ven,@i_formato_fecha), 
   @w_toperacion_cod    = op_toperacion
   from ca_operacion OP
   inner join cobis..cl_catalogo A on op_banco    = @i_banco and op_toperacion = A.codigo
   inner join cobis..cl_moneda     on op_moneda = mo_moneda
   left outer join ca_dividendo DI   on op_operacion = di_operacion and di_estado = 1
   
   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end
   
   select
   'BANCO'          = @i_banco             ,
   'MONEDA'         = @w_moneda            ,
   'MONEDA_DES'     = @w_moneda_desc       ,
   'MONTO'          = @w_monto             ,
   'PLAZO'          = @w_plazo             ,
   'PLAZO_DESC'     = @w_tplazo            ,
   'TIPO_AMORTIZA'  = @w_tipo_amortizacion ,
   'DIVIDENDO'      = @w_tdividendo        ,
   'BANCA'          = @w_banca             ,
   'ESTADO'         = @w_estado            ,
   'FECHA_LIQUID'   = @w_fecha_liq         ,
   'FECHA_SOLICITUD'= @w_fecha_solicitud   ,
   'TASA'           = @w_tasa              ,
   'PLAZO_DIAS'     = @w_plazo_dias        ,
   'PERIODO_CAP'    = @w_periodo_cap       ,
   'PERIODO_INT'    = @w_periodo_int       ,
   'OPERACION'      = @w_toperacion        ,
   'FECHA_FIN'      = @w_fecha_fin         ,
   'MES_GRACIA'     = @w_mes_gracia        ,
   'GRACIA'         = @w_gracia            ,
   'GRACIA_CAP'     = @w_gracia_cap        ,
   'GRACIA_INT'     = @w_gracia_int        ,
   'PROXIMA_CUOTA'  = @w_proxima_cuota     ,
   'FECHA_PROX_VEN' = @w_prox_fecha_ven    ,
   'OPERACION_COD'  = @w_toperacion_cod

end -- D


-- DETALLE DE LA TABLA DE AMORTIZACION
if @i_operacion = 'T'
begin
   select 'Dividendo'         = A.di_dividendo,
          'Fecha Vencimiento' = convert(varchar(10),A.di_fecha_ven,@i_formato_fecha),
          'Saldo Capital'     = (SELECT CASE WHEN A.di_dividendo = 1
                                             THEN O.op_monto
                                             WHEN A.di_dividendo > 1
                                             THEN (O.op_monto) - (select sum(am_cuota)
                                                                  from  ca_amortizacion
                                                                  where am_operacion = O.op_operacion
                                                                  and   am_dividendo <= (A.di_dividendo -1)---------------------
                                                                  and am_concepto  = 'CAP')
                                             END ),
          'Capital'           = (select sum(am_cuota)
                                 from ca_amortizacion
                                 where am_operacion = O.op_operacion
                                   and am_dividendo = A.di_dividendo
                                   and am_concepto  = 'CAP'),
          'Intereses'         = (select sum(am_cuota)
                                 from ca_amortizacion
                                 where am_operacion = O.op_operacion
                                  and am_dividendo  = A.di_dividendo
                                  and am_concepto   = 'INT'),       
          'Mora'              = (select sum(am_cuota)
                                 from ca_amortizacion
                                 where am_operacion = O.op_operacion
                                  and am_dividendo  = A.di_dividendo
                                  and am_concepto   = 'IMO'),       
          'Otros'             = (select sum(am_cuota)
                                 from ca_amortizacion
                                 where am_operacion = O.op_operacion
                                   and am_dividendo = A.di_dividendo
                                   and am_concepto  not in ('CAP','INT','IMO')),
          'Cuota'             = (select sum(am_cuota) 
                                 from ca_amortizacion
                                 where am_operacion = O.op_operacion
                                   and am_dividendo = A.di_dividendo
								   and am_concepto in ('CAP','INT','IVA_INT')),-- se suma segun lo que se piden en el reporte
          /*'IVA_Intereses'     = (select (sum(am_cuota)*(SELECT ro_porcentaje FROM ca_rubro_op 
		                                                WHERE ro_concepto = 'IVA_INT' 
														AND  ro_operacion = O.op_operacion)/100)
                                 from  ca_amortizacion
                                 where am_operacion = O.op_operacion
                                 and   am_dividendo  = A.di_dividendo
                                 and   am_concepto   = 'INT')	*/							   
          'IVA_Intereses'     = (select sum(am_cuota)
                                 from  ca_amortizacion
                                 where am_operacion = O.op_operacion
                                 and   am_dividendo  = A.di_dividendo
                                 and   am_concepto   = 'IVA_INT')
   from ca_dividendo A, ca_operacion O
   where O.op_banco     = @i_banco
     and A.di_operacion = O.op_operacion
   group by A.di_dividendo, A.di_fecha_ven, O.op_operacion, O.op_monto
   order by A.di_dividendo
end -- T


return 0

ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
go
