/************************************************************************/
/*  Archivo:                datos_reportes_miembro.sp                   */
/*  Stored procedure:       sp_datos_reportes_miembro                   */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_datos_reportes_miembro')
    drop proc sp_datos_reportes_miembro
go

create proc sp_datos_reportes_miembro (
	@s_ssn       int         = null,
	@s_sesn      int         = null,
	@s_ofi       smallint    = null,
	@s_rol       smallint    = null,
	@s_user      login       = null,
	@s_date      datetime    = null,
	@s_term      descripcion = null,
	@t_debug     char(1)     = 'N',
	@t_file      varchar(10) = null,
	@t_from      varchar(32) = null,
	@s_srv       varchar(30) = null,
	@s_lsrv      varchar(30) = null,
	@i_modo      int         = null,
	@i_operacion char(2),
	@i_tramite   int         = null,
	@i_formato_fecha int     = null
)
as
declare
	@w_sp_name 				varchar(20),
   @w_operacion         int,
   @w_costo_anual_tot   money,
   @w_tasa_int_anual    money,
   @w_monto_credito     money,
   @w_monto_tot_pag     money,
   @w_lista_comisiones  varchar(300),
   @w_porcentaje_mora   float,
   @w_plazo_credito     varchar(50),
   @w_desc_plz_cred     varchar(100),
   @w_desc_moneda       varchar(100),
   @w_nombre_comision   varchar(64), 
   @w_valor_comis       float,
   @w_monto_max_fijo    money,
   @w_fecha_liq         datetime,
   @w_monto_letra		   varchar(254),
   @w_id_cliente        int,
   @w_nombres           varchar(254),
   @w_interes           float,
   @w_direccion         varchar(254),
   @w_id_tramite        int,
   -- ----------------------------
   @w_monto          money,
   -- ----------------------------
   @w_moneda				smallint,
   @w_return				int,
   @w_fecha_corte       datetime,
   @w_fecha_pago        datetime,
   @w_toperacion        varchar(10)
   
select @w_sp_name = 'sp_datos_reportes_miembro'

if @i_formato_fecha is null
begin
	select @i_formato_fecha=103
end

if not exists (select 1 from cr_tramite where tr_tramite=@i_tramite)
begin
	exec cobis..sp_cerror
		 @t_debug = @t_debug,
		 @t_file  = @t_file,
		 @t_from  = @w_sp_name,
		 @i_num   = 2110316 --"NO EXISTE TRAMITE"
	return 2110316
end

select @w_operacion       = tg_operacion,
       @w_monto_max_fijo  = tr_monto,
       @w_moneda          = tr_moneda
  from cr_tramite, cr_tramite_grupal
 where tr_tramite = tg_tramite 
   and tr_tramite = @i_tramite

if @w_operacion is null and @i_operacion = 'Q3'
begin
   select @w_operacion = op_operacion 
     from cob_cartera..ca_operacion 
    where op_tramite = @i_tramite  
end
   
if @i_operacion ='Q' --RPT Cargo Recurrente
begin
   
   select @w_toperacion = op_toperacion from cob_cartera..ca_operacion where op_tramite = @i_tramite 

   if(@w_toperacion = 'GRUPAL')
   begin
       select 'NOMBRE_CLI'         = (select UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))),
              'NUM_CTA_TARJ'       = ea_cta_banco,
              'MONTO_MAX'          = @w_monto_max_fijo,
              'PERIODICIDAD'       = td_descripcion,
              'FECH_VENC'          = di_fecha_ven,
              'NUM_CREDITO'        = op_banco,
	    	  'IMPORTE_SEM_APAGAR' = (SELECT sum(am_cuota) from cob_cartera..ca_amortizacion 
                                      WHERE am_dividendo = 1 AND am_operacion = OP.op_operacion),
              'FECHA_LIQUID'       = op_fecha_liq
         from cob_credito..cr_tramite_grupal,
              cob_cartera..ca_operacion OP,
              cobis..cl_ente,
              cobis..cl_ente_aux,
              cob_cartera..ca_dividendo,
              cob_cartera..ca_tdividendo
        where tg_tramite    = @i_tramite
          and tg_operacion  = op_operacion
          and tg_operacion  = di_operacion
          and tg_cliente    = en_ente
          and tg_cliente    = ea_ente
	      and tg_participa_ciclo = 'S'
	      and tg_monto_aprobado > 0
          and op_tdividendo = td_tdividendo
          and di_dividendo  = (select max(di_dividendo) 
                                 from cob_cartera..ca_dividendo di
                                where di.di_operacion = op_operacion)
        order by ea_ente   
   end
   else
   begin
     select @w_operacion = op_operacion 
       from cob_cartera..ca_operacion 
      where op_tramite = @i_tramite

     -- Se toma del sp cob_credito..sp_datos_credito operacion Q2
     select @w_monto_max_fijo = tr_monto
     from   cob_credito..cr_tramite,
            cob_credito..cr_deudores,
            cob_cartera..ca_operacion,
            cob_cartera..ca_default_toperacion
     where  tr_tramite    = @i_tramite
     and    tr_tramite    = de_tramite
     and    tr_tramite    = op_tramite
     and    dt_toperacion = op_toperacion
   
     select 'NOMBRE_CLI' = (select UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))),
            'NUM_CTA_TARJ' = ea_cta_banco,
            'MONTO_MAX'    = @w_monto_max_fijo,
            'PERIODICIDAD' = td_descripcion,
            'FECH_VENC'    = op_fecha_fin,
            'NUM_CREDITO'  = op_banco,
            'IMPORTE_SEM_APAGAR' = (SELECT sum(am_cuota) from cob_cartera..ca_amortizacion 
                                  WHERE am_dividendo = 1 AND am_operacion = OP.op_operacion),
            'FECHA_LIQUID' = op_fecha_liq								  
     from  cob_cartera..ca_operacion OP,
           cobis..cl_ente,
           cobis..cl_ente_aux,
           cob_cartera..ca_tdividendo
     where op_operacion  = @w_operacion
     and   en_ente = op_cliente
     and   en_ente    = ea_ente
     and   op_tdividendo = td_tdividendo
     order by ea_ente
   end   
   return 0
end --@i_operacion='Q' FIN

if @i_operacion ='Q1' --RPT Pagare
begin
   create table #cr_tmp_tramite_pagare(
   tp_id_cliente     int null,
   tp_nombres        varchar(254) null,
   tp_monto          money null,
   tp_monto_letra    varchar(254) null,
   tp_id_tramite     int null,
   tp_interes        float null,
   tp_direccion      varchar(254) null)

   declare c_tramite_pagare cursor for
    select tg_cliente, 
           en.en_nomlar, 
           tg_monto,  
           CAST(tg_monto AS VARCHAR(254)),  
           op_tramite, 
           ro.ro_porcentaje,
          (select ci_descripcion + ', ' + 
                  pq_descripcion + ' - ' + 
                  isnull(di_descripcion,'') + ' ' + 
                  isnull(di_calle,'') + ' ' + 
                  isnull(convert(varchar,di_nro),'' )
             from cobis..cl_direccion,cobis..cl_parroquia, cobis..cl_ciudad 
            where di_ente = tg.tg_cliente and di_tipo in ('RE','AE')
              and di_principal = 'S'
              and pq_parroquia = di_parroquia
              and ci_ciudad = di_ciudad)

     from cob_credito..cr_tramite_grupal tg,
          cobis..cl_ente en,
          cob_cartera..ca_rubro_op ro,
			 cob_cartera..ca_operacion 
    where tg.tg_cliente   = en.en_ente
      and ro.ro_operacion = tg.tg_operacion
      and ro_concepto     ='INT'
      and tg.tg_tramite   = @i_tramite
			and op_operacion = tg_operacion
         and tg_monto != 0
     for read only

    open c_tramite_pagare
   fetch c_tramite_pagare
    into @w_id_cliente , @w_nombres , @w_monto , @w_monto_letra,
         @w_id_tramite , @w_interes , @w_direccion
   while @@fetch_status = 0
   begin
      exec @w_return = cob_interface..sp_numeros_letras 
      @i_dinero = @w_monto,
      @i_moneda = @w_moneda,
      @i_idioma = 'E',
      @t_trn	 = 29322,
      @o_texto	 = @w_monto_letra out
      
      if(@w_return <> 0)
      begin 
         exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = @w_return
         return @w_return
      end
      
      insert into #cr_tmp_tramite_pagare
      values(@w_id_cliente, @w_nombres, @w_monto, @w_monto_letra, @w_id_tramite, @w_interes, @w_direccion)

	fetch c_tramite_pagare
    into @w_id_cliente , @w_nombres , @w_monto , @w_monto_letra,
         @w_id_tramite , @w_interes , @w_direccion   
   end
   close c_tramite_pagare
   deallocate c_tramite_pagare

   select 'ID_CLIENTE'  = tp_id_cliente,
          'NOMBRE_CLI'  = tp_nombres,
          'MONTO'       = tp_monto,
          'MONTO_LETRA' = tp_monto_letra,
          'ID_TRAMITE'  = tp_id_tramite,
          'INTERES'     = tp_interes,
          'DIRECCION'	= tp_direccion     
   from #cr_tmp_tramite_pagare
   return 0
end --@i_operacion='Q1' FIN

if @i_operacion = 'Q2' --RPT Caratula Credito Grupal
begin
   select @w_tasa_int_anual = ro_porcentaje--ro_porcentaje_efa 
     from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_operacion 
      and ro_concepto  = 'INT'

   select @w_monto_credito = tr_monto,
          @w_desc_moneda   = mo_descripcion
     from cr_tramite, cobis..cl_moneda
    where tr_tramite = @i_tramite
      and mo_moneda  = tr_moneda

   select @w_monto_tot_pag = sum(am_cuota) 
     from cob_cartera..ca_amortizacion 
    where am_operacion = @w_operacion 

   select @w_porcentaje_mora = (vd_valor_default / 12)
     from cob_cartera..ca_valor_det
    where vd_tipo   = 'TCMORA'
      and vd_sector = (select dt_clase_sector 
                         from cob_cartera..ca_default_toperacion 
                        where dt_toperacion = 'GRUPAL')

    select @w_lista_comisiones = ''

   declare c_comis_prest_grp cursor for
    select va_descripcion, vd_valor_default
      from cob_cartera..ca_valor_det, cob_cartera..ca_valor
     where vd_tipo   in ('TCMORA','TPREPAGO')
       and vd_sector = (select dt_clase_sector 
                         from cob_cartera..ca_default_toperacion 
                        where dt_toperacion = 'GRUPAL')
       and va_tipo = vd_tipo
       for read only

      open c_comis_prest_grp 
	  fetch c_comis_prest_grp 
      into @w_nombre_comision, @w_valor_comis
     while @@fetch_status = 0
     begin
           if(@w_lista_comisiones != '')
           begin
               select @w_lista_comisiones = @w_lista_comisiones + '; '
           end
           select @w_lista_comisiones = @w_lista_comisiones + @w_nombre_comision + ': ' + convert(varchar,@w_valor_comis) + '%'
           fetch c_comis_prest_grp into @w_nombre_comision, @w_valor_comis
     end --while @@fetch_status = 0
   close c_comis_prest_grp
	deallocate c_comis_prest_grp

   select @w_desc_plz_cred  = valor,
          @w_plazo_credito  = op_plazo,
          @w_fecha_liq      = op_fecha_liq,
          @w_costo_anual_tot= round(op_valor_cat,2,0)
     from cob_cartera..ca_operacion,
          cobis..cl_tabla t,
          cobis..cl_catalogo c
    where op_tramite = @i_tramite
      and op_tplazo  = c.codigo
      and c.tabla = t.codigo
      and t.tabla = 'cr_tplazo_ind'

   --Fecha limite de pago
   SELECT @w_fecha_pago = min(di_fecha_ven)
     FROM cob_cartera..ca_dividendo 
	WHERE di_operacion  = @w_operacion 
	 -- AND di_estado  = 0
	
	--Fecha de corte
	
	 SELECT @w_fecha_corte =op_fecha_liq
     FROM cob_cartera..ca_operacion 
	 WHERE op_operacion  = @w_operacion 
	
   /* SELECT @w_fecha_corte = fp_fecha 
	  FROM cobis..ba_fecha_proceso*/

   -- DESA: Parametro Pendiente @w_costo_anual_tot
    --select @w_costo_anual_tot  = convert(float,40.5) --aca hacer el cambio para consultar op_valor_cat  de la ca_operacion

   select 'COSTO_ANUAL_TOT'  = @w_costo_anual_tot,
          'TASA_INT_ANUAL'   = @w_tasa_int_anual,
          'MONTO_CREDITO'    = format(@w_monto_credito, 'C') ,
          'MONTO_TOT_PAG'    = format(@w_monto_tot_pag, 'C') ,
          'LISTA_COMISIONES' = @w_lista_comisiones,
          'PORCENTAJE_MORA'  = @w_porcentaje_mora,
          'PLAZO_CREDITO'    = @w_plazo_credito,
          'DESCRIP_MONEDA'   = @w_desc_moneda,
          'DESCRIP_PLAZO'    = @w_desc_plz_cred,
		  'FECHA_LIMITE_PAGO'=  convert(varchar(10), @w_fecha_pago, @i_formato_fecha),
		  'FECHA_CORTE'      = convert(varchar(10), @w_fecha_corte, @i_formato_fecha)
          --'FECHA_LIQUIDA'    = @w_fecha_liq
   return 0
end --@i_operacion='Q2' FIN

if @i_operacion = 'Q3' --RPT Caratula Credito Grupal - Lista de Pagos
begin
   select 'NUMERO'     = am_dividendo , 
       'MONTO'	     = sum(am_cuota),
          'FECHA_VENC' = di_fecha_ven
     from cob_cartera..ca_amortizacion,
          cob_cartera..ca_dividendo
    where am_operacion = @w_operacion
      and am_operacion = di_operacion
      and am_dividendo = di_dividendo
    group by am_dividendo,di_fecha_ven
 
   return 0
end --@i_operacion='Q3' FIN
GO

