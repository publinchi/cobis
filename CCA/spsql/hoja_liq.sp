/***********************************************************************/
/*	Archivo:			hoja_liq.sp                    */
/*	Stored procedure:		sp_hoja_liquidacion            */
/*	Base de Datos:			cob_cartera                    */
/*	Producto:			Cartera	                       */
/*	Disenado por:			LCA                            */
/*	Fecha de Documentacion: 	Mar. 05                        */
/***********************************************************************/
/*			IMPORTANTE		       		       */
/*	Este programa es parte de los paquetes bancarios propiedad de  */ 	
/*	"MACOSA",representantes exclusivos para el Ecuador de la       */
/*	AT&T							       */
/*	Su uso no autorizado queda expresamente prohibido asi como     */
/*	cualquier autorizacion o agregado hecho por alguno de sus      */
/*	usuario sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante	       */
/***********************************************************************/  
/*			PROPOSITO				       */
/*	Buscar operaciones para la Hoja de Liquidacion         	       */	
/***********************************************************************/
use cob_cartera
go
if exists(select * from sysobjects where name = 'sp_hoja_liquidacion_sa')
	drop proc sp_hoja_liquidacion_sa
go
create proc sp_hoja_liquidacion_sa (
	@i_banco		cuenta   = null,
--	@i_siguiente		int      = 0,
--        @i_formato_fecha        int      = null,
        @i_opcion               char(1)  = null,
--        @i_estado               char(1)  = null,
        @s_date                 datetime = null,
        @s_user                 varchar(20) = null
)
as
declare
 	@w_sp_name	    varchar(32),	
	@w_opcion	    int,
        @w_error            int,
        @w_estado           int,
        @w_concepto_segdes  varchar(10),
        @w_concepto_seghos  varchar(10),
        @w_concepto_solca   varchar(10),
        @w_concepto_asisadm varchar(10),
        @w_formato_fecha    int,
        @w_asistencia_adm   money,
        @w_seguro_desgrav   money,
        @w_intxcobrar       money,
        @w_fecha_liq        varchar(10),
        @w_monto_financiado money,
	@w_grupo            int,
        @w_nombre_grupo     varchar(30),
        @w_ciclos           int,
        @w_filial           varchar(30),
        @w_fecha            varchar(10),
        @w_oficina          int,
        @w_nombre_oficina   varchar(30),
        @w_monto_solicitado money,
        @w_tasa             money,
        @w_operacionca      int,
        @w_banco_emisor     varchar(30),
        @w_cuenta           varchar(30),
        @w_total            money,
        @w_fondo                varchar(10),
        @w_nombre_fondo         varchar(25),
        @w_toperacion           varchar(10),
        @w_desc_toperacion      varchar(30),
        @w_dia_reunion          tinyint,
        @w_frecuencia_reunion   smallint,
        @w_hora_reunion         varchar(5),
        @w_lugar_reunion        varchar(64),
        @w_grupal               char(1),
        @w_referencia_grupal    varchar(20),
        @w_tasa_iva             money,
        @w_concepto_asoc        varchar(10),
        @w_solca                money,
        @w_moneda               tinyint,
        @w_asumido              char(1),
        @w_cliente              int,
        @w_ruc_banco            varchar(15),
        @w_garantia             varchar(20),
        @w_nombre               varchar(40),
        @w_banco                varchar(15),
        @w_ced_ruc              varchar(15),
        @w_tramite              int,
        @w_ciudad               int,
        @w_desc_ciudad          varchar(30),
        @w_dd_hoy               tinyint,
        @w_mm_hoy               tinyint,
        @w_yy_hoy               smallint,
        @w_subsegmento          varchar(30),
        @w_sector               varchar(10),
        @w_direccion            varchar(45),
        @w_tir                  money,
        @w_tea                  money,
        @w_fecha_fin            varchar(30),
        @w_tasador              varchar(35),
        @w_p_apellido           varchar(25),
        @w_p_nombre             varchar(25),
        @w_tipo_cta             varchar(10),
        @w_dias_plazo           int,
        @w_desc_dias_plazo      varchar(20),
        @w_plazo                varchar(20),
        @w_periodicidad         varchar(20),
        @w_tasa_mora            money,
        @w_seguro_hospit        money,
        @w_tipo_amortizacion    varchar(10),
        @w_porcentaje_garantia  float

/*  Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_hoja_liquidacion',
       @w_formato_fecha = 103

   select @w_concepto_segdes = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'RSDG'

   select @w_concepto_solca = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'SOLCA'

   select @w_concepto_asisadm = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'RAAD'

   select @w_concepto_seghos = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'RSDH'

   select @w_grupal = 'N'

   select @w_grupal            = tg_grupal,
       @w_referencia_grupal = tg_referencia_grupal,
       @w_operacionca       = op_operacion,
       @w_toperacion        = op_toperacion,
       @w_moneda            = op_moneda,
       @w_fecha_fin         = convert(varchar(10),op_fecha_fin,103),
       @w_plazo             = convert(varchar(10),p.td_factor*op_plazo) + ' dias',
       @w_periodicidad      = (select substring(td_descripcion,1,25) from ca_tdividendo where td_factor = f.td_factor*o.op_periodo_int)
  from ca_operacion o , ca_tdividendo p, ca_tdividendo f, cob_credito..cr_tramite_grupal
 where op_banco = @i_banco
   --and op_banco = tg_prestamo  
   and op_banco = tg_referencia_grupal   
   and p.td_tdividendo = op_tplazo
   and f.td_tdividendo = op_tdividendo

if @@rowcount = 0 begin
   exec cobis..sp_cerror
       @t_debug  = 'N',
       @t_file   = null,
       @t_from   = @w_sp_name,   
       @i_num    = 701025
   return 701025
end

if @i_opcion = 'Q' begin
   if @w_grupal = 'S' begin
      select @w_fecha_liq        = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
             @w_monto_financiado = op_monto,
             @w_grupo            = gr_grupo,
             @w_nombre_grupo     = substring(gr_nombre,1,30),
             @w_ciclos           = gr_num_ciclo,
             @w_filial           = substring(fi_nombre,1,30),
             @w_fecha            = convert(varchar(10),@s_date,@w_formato_fecha),
             @w_oficina          = op_oficina,
             @w_nombre_oficina   = substring(of_nombre,1,30),
             @w_monto_solicitado = op_monto,
             @w_tasa             = round(ro_porcentaje,4),
             @w_operacionca      = op_operacion,
             @w_tipo_amortizacion= op_tipo_amortizacion           
        from ca_operacion, cobis..cl_grupo, cobis..cl_filial, cobis..cl_oficina, ca_rubro_op, cob_credito..cr_tramite_grupal
       where op_banco  = @i_banco
         and op_banco  = tg_referencia_grupal --tg_prestamo
         and tg_grupal = 'S'
         and tg_grupo  = gr_grupo
         and fi_filial = 1
         and of_oficina = op_oficina
         and ro_operacion = op_operacion
         and ro_concepto  = 'INT'

      select @w_tasa_mora = ro_porcentaje
        from ca_rubro_op
       where ro_operacion = @w_operacionca
         and ro_concepto  = 'IMO'

      if @w_tasa_mora = 1.1 select @w_tasa_mora = @w_tasa_mora * @w_tasa


   end else begin
      select @w_fecha_liq        = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
             @w_monto_financiado = op_monto,
             @w_grupo            = op_cliente,
             @w_nombre_grupo     = substring(op_nombre,1,30),
             @w_ciclos           = isnull(en_nro_ciclo,1),
             @w_filial           = substring(fi_nombre,1,30),
             @w_fecha            = convert(varchar(10),@s_date,@w_formato_fecha),
             @w_oficina          = op_oficina,
             @w_nombre_oficina   = substring(of_nombre,1,30),
             @w_monto_solicitado = op_monto,
             @w_tasa             = round(ro_porcentaje,4),
             @w_operacionca      = op_operacion,
             @w_tipo_amortizacion= op_tipo_amortizacion           
        from ca_operacion, cobis..cl_ente, cobis..cl_filial, cobis..cl_oficina, ca_rubro_op
       where op_banco  = @i_banco
         and en_ente   = op_cliente
         and fi_filial = 1
         and of_oficina = op_oficina
         and ro_operacion = op_operacion
         and ro_concepto  = 'INT'

      select @w_tasa_mora = ro_porcentaje
        from ca_rubro_op
       where ro_operacion = @w_operacionca
         and ro_concepto  = 'IMO'

      if @w_tasa_mora = 1.1 select @w_tasa_mora = @w_tasa_mora * @w_tasa

   end


      select @w_fecha_liq,
             @w_monto_financiado,
             @w_grupo,
             @w_nombre_grupo,
             @w_ciclos,
             @w_fecha,
             @w_oficina,
             @w_nombre_oficina,
             @w_tasa,
             @w_grupal,
             @w_fecha_fin,
             @w_plazo,   
             @w_periodicidad,
             @w_tasa_mora
             
end

if @i_opcion = 'S' begin

   select @w_porcentaje_garantia = pa_float
     from cobis..cl_parametro
    where pa_producto = 'CRE'
      and pa_nemonico = 'PAHO'

   --set rowcount 20
   /* RETORNAR DATOS A FRONT END */
   if @w_grupal = 'S' begin

      select 'Prestamo'                    = A.op_banco, 
             'Nombre del Cliente'          = (select UPPER(isnull(en_nombre,''))+' ' + UPPER(isnull(p_s_nombre,''))+' '+
	                                                 UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))
											    from cobis..cl_ente where en_ente  = A.op_cliente),								
             'Monto Aprobado'              = A.op_monto, 
             'Valores Descontar'           = (select isnull(sum(ro_valor),0)
                                              from cob_cartera..ca_rubro_op
                                              where ro_operacion = A.op_operacion
                                                and ro_concepto  = @w_concepto_solca
                                                and ro_fpago    in ('L','F')),
             'Ahorro'                      = isnull((tg_monto * @w_porcentaje_garantia/100),0),
             'Incentivo'                   = isnull((select isnull(dc_incentivos,0) from cob_cartera..ca_det_ciclo
                                               where dc_operacion = A.op_operacion),0),
             'Neto a Entregar'           = (select isnull(sum(C.dm_monto_mop),0) from cob_cartera..ca_desembolso C where C.dm_operacion = A.op_operacion and C.dm_estado in ('A','NA')),
             'Cheque'                      = (select min(C.dm_cuenta) from cob_cartera..ca_desembolso C where C.dm_operacion = A.op_operacion and C.dm_estado in ('A','NA')),
             'Operacion'                   = A.op_cliente
        from cob_cartera..ca_operacion A, cob_credito..cr_tramite_grupal
       where tg_referencia_grupal = @i_banco 
         and op_banco = tg_prestamo
		 and tg_monto > 0
       order by A.op_cliente
   end else begin
      select 'Prestamo'                    = A.op_banco, 
             'Nombre del Cliente'          = (select UPPER(isnull(en_nombre,''))+' ' + UPPER(isnull(p_s_nombre,''))+' '+
	                                                 UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))
											    from cobis..cl_ente where en_ente  = A.op_cliente),
             'Monto Aprobado'              = A.op_monto, 
             'Valores Descontar'           = isnull((select sum(ro_valor)
                                 from ca_rubro_op
                                where ro_operacion = A.op_operacion
                                  and ro_concepto  = @w_concepto_solca
                                  and ro_fpago    in ('L','F')),0),

             'Ahorro'                      = (select isnull(op_monto*@w_porcentaje_garantia/100,0)),
             'Incentivo'                   = 0,
             'Neto a Entregar'             = (select isnull(sum(C.dm_monto_mop),0) from ca_desembolso C where C.dm_operacion = A.op_operacion and C.dm_estado in ('A','NA')),
             'Cheque'                      = (select min(C.dm_cuenta) from ca_desembolso C where C.dm_operacion = A.op_operacion and C.dm_estado in ('A','NA')),
             'Operacion'                   = A.op_cliente
        from ca_operacion A
       where A.op_banco = @i_banco
   end
end

return 0

go

