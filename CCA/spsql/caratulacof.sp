/************************************************************************/
/*   Archivo:                 caratulacof.sp                            */
/*   Stored procedure:        sp_reporte_caratula_cof                   */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Septiembre. 2019                          */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Carátula de información financiera (COF) para banca grupal         */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   09/Sep/2019   Edison Cajas.   Emision Inicial                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_caratula_cof')
    drop proc sp_reporte_caratula_cof
go

create proc sp_reporte_caratula_cof
(
   @t_trn              int          = 77538,
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco            varchar(15),
   @i_nemonico         varchar(10),
   @i_formato_fecha    int          = 103
)
as 

declare
    @w_sp_name              varchar(30)      ,@w_error                   int             ,@w_tipo_operacion        catalogo
   ,@w_moneda               int              ,@w_tipo_tramite            catalogo        ,@w_msg                   varchar(1000)
   ,@w_operationType        varchar(100)     ,@w_cat                     varchar(30)     ,@w_ordinaryRate          varchar(30)
   ,@w_moratoriumRate       varchar(30)      ,@w_creditAmount            varchar(30)     ,@w_totalAmount           varchar(30)
   ,@w_paymentDate          varchar(30)      ,@w_clarificationsAddress   varchar(100)    ,@w_clarificationsPhone   varchar(20)
   ,@w_email                varchar(100)     ,@w_internetPage            varchar(100)    ,@w_reca                  varchar(50)
   ,@w_firm                 varchar(30)      ,@w_numero_cliente          int             ,@w_cod_clte_bco          int
   ,@w_cod_direc            int              ,@w_numero_operacion        int             ,@w_rINT                  varchar(30)
   ,@w_rIMO                 varchar(30)      ,@w_filial                  tinyint         ,@w_gasto_cobranza        varchar(30)
   ,@w_gasto_apertura       varchar(30)      ,@w_gas_cob_sem             money           ,@w_gas_cob_cat           money
   ,@w_tdividendo           varchar(10)      ,@w_gas_apert               money           ,@w_mnc_gas_apert         varchar(32)
   ,@w_plazo_credito        int              ,@w_frecuencia_credito      varchar(20)     ,@w_tipo_plazo_credito    char(1)
   ,@w_creditFrequency      varchar(30)      ,@w_clausula                varchar(30) 
   
select @w_sp_name = 'sp_reporte_caratula_cof'

if @t_trn <> 77538
begin
    select @w_error = 151051		
    goto ERROR
end

   select 
      @w_numero_operacion    = op_operacion    
	 ,@w_tipo_operacion      = op.op_toperacion
	 ,@w_tipo_tramite        = isnull((select tr_tipo from cob_credito..cr_tramite where tr_tramite = op.op_tramite), 'NA')
	 ,@w_moneda              = isnull(op.op_moneda, 0)
	 ,@w_operationType       = (select cat.valor 
	                          from cobis..cl_tabla tab, 
							       cobis..cl_catalogo cat
                             where tab.tabla =  'ca_toperacion'
                                 and   tab.codigo = cat.tabla 
                                 and   cat.codigo = op.op_toperacion)
     ,@w_cat                 = isnull(round(op.op_valor_cat,2),'0.00')
	 ,@w_creditAmount        = ISNULL(op.op_monto,'0.00')
	 ,@w_totalAmount         = isnull((select sum(am_cuota + am_gracia - am_pagado) from cob_cartera..ca_amortizacion where am_operacion = op.op_operacion), 0)
	 ,@w_paymentDate         = isnull(convert(varchar(10),op_fecha_fin,@i_formato_fecha),' /  / ')
	 ,@w_numero_cliente      = op_cliente
	 ,@w_tdividendo          = op_tdividendo
	 ,@w_plazo_credito       = op_plazo
	 ,@w_tipo_plazo_credito  = op_tplazo
   from ca_operacion op  
  where op_banco = @i_banco


   select @w_cod_clte_bco = pa_int
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'CCFILI'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero CCFILI'
      goto ERROR
   end

   select @w_rINT = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'RUINT'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero RUINT'
      goto ERROR
   end

   select @w_rIMO = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'IMO'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero IMO'
      goto ERROR
   end

  select @w_filial = pa_tinyint
  from   cobis..cl_parametro
  where  pa_nemonico = 'FILIAL'
  if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero FILIAL'
      goto ERROR
   end

  select @w_gas_cob_sem = pa_money 
  from   cobis..cl_parametro 
  where  pa_producto = 'CCA' 
  and    pa_nemonico = 'GASCOS'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero GASCOS'
      goto ERROR
   end

   select @w_gas_cob_cat = pa_money 
   from   cobis..cl_parametro 
   where  pa_producto = 'CCA' 
   and    pa_nemonico = 'GASCOC'	
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero GASCOC'
      goto ERROR
   end

   select @w_mnc_gas_apert   = pa_char 
   from   cobis..cl_parametro 
   where  pa_producto = 'CCA' 
   and    pa_nemonico = 'RUCGCO'
   if @@rowcount = 0
   begin
      select @w_error =  141140,
             @w_msg   = 'No existe Paramtero RUCGCO'
      goto ERROR
   end

   select @w_ordinaryRate = round(convert(decimal(18,2), sum(case when ro_concepto = @w_rINT then ro_porcentaje else 0.0 end)) , 2)
         ,@w_moratoriumRate = round(convert(decimal(18,2), ((sum(case when ro_concepto = @w_rIMO then ro_porcentaje else 0.0 end))*2)), 2)
   from  cob_cartera..ca_rubro_op 
   where ro_operacion = @w_numero_operacion

   -------------------------------------
   --DIRECCION
   -------------------------------------
   select @w_clarificationsAddress  = isnull(di_descripcion,' ')
         ,@w_cod_direc  = di_direccion
   from  cobis..cl_direccion, cobis..cl_ciudad, cobis..cl_provincia
   where di_ente = @w_cod_clte_bco
   and   di_tipo = 'AE'
   and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'AE')
   and   di_ciudad = ci_ciudad
   and   ci_provincia = pv_provincia


   -------------------------------------
   --TELEFONO
   -------------------------------------
   select @w_clarificationsPhone  = te_valor
   from   cobis..cl_telefono
   where  te_ente = @w_cod_clte_bco 
   and    te_direccion = @w_cod_direc
   and    te_secuencial = (select max(te_secuencial) from cobis..cl_telefono
                       where te_ente = @w_cod_clte_bco  
                       and te_direccion = @w_cod_direc)

   -------------------------------------
   --EMAIL
   -------------------------------------					   
   select @w_email = isnull(di_descripcion,' ')
   from cobis..cl_direccion
   where di_ente = @w_cod_clte_bco
   and   di_tipo = 'CE'
   and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'CE') 

   -------------------------------------
   --EMAIL
   -------------------------------------
   select @w_internetPage = isnull(di_descripcion,' ')
   from cobis..cl_direccion
   where di_ente = @w_cod_clte_bco
   and   di_tipo = 'PE'
   and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'PE') 

   -------------------------------------
   --RECA
   -------------------------------------
	select top 1 @w_reca = isnull(id_dato,' ')
    from   cob_credito..cr_imp_documento
    where  id_toperacion   = @w_tipo_operacion
    and    id_moneda       = @w_moneda
    and    id_mnemonico    = @i_nemonico
    and    id_tipo_tramite = @w_tipo_tramite


	select @w_firm = fi_nombre 
	  from cobis..cl_filial 
	 where fi_filial = @w_filial

	 select @w_gasto_cobranza = '0'

	 if @w_tdividendo = 'W'
	 begin 
	    select @w_gasto_cobranza = 'Semanal: $ ' + convert(varchar, isnull(@w_gas_cob_sem,0)) + 'M.N. + IVA'
	 end

	 if @w_tdividendo = 'Q'
	 begin 
	    select @w_gasto_cobranza = 'Catorcenal: $ ' + convert(varchar, isnull(@w_gas_cob_cat,0)) + 'M.N. + IVA'
	 end

	 select @w_gas_apert = ro_porcentaje
     from   ca_rubro_op
     where  ro_concepto    = @w_mnc_gas_apert
     and    ro_operacion   = @w_numero_operacion

	 select @w_gas_apert = ISNULL(@w_gas_apert,-1)

	 if @w_gas_apert = -1
	 begin 
	    select @w_gasto_apertura = '--- %'
	 end else begin
	    select @w_gasto_apertura = convert(varchar,@w_gas_apert) + ' %'
	 end

	 --Se obtiene la descripcion de la frecuencia de pago
    select @w_frecuencia_credito = td_descripcion
    from cob_cartera..ca_tdividendo
    where td_tdividendo = @w_tipo_plazo_credito and td_estado = 'V'

	select @w_creditFrequency = cast(@w_plazo_credito as varchar) + ' ' + @w_frecuencia_credito
	
	-------------------------------------
    --CLAUSULA  -- CAINFINCOF= Décino Tercera  CAINICOF52 = Décimo Cuarta
    -------------------------------------
	
	IF @i_nemonico = 'CAINFINCOF'
	begin
	   set @w_clausula = 'Décimo Tercera' 
	end else begin
	   set @w_clausula = 'Décimo Cuarta'
	end 


   select 
       @w_operationType
      ,@w_cat
	  ,@w_ordinaryRate
	  ,@w_moratoriumRate
	  ,@w_creditAmount
	  ,@w_totalAmount
	  ,@w_paymentDate
	  ,isnull(@w_clarificationsAddress,'SIN DIRECCION') as direccion
	  ,isnull(@w_clarificationsPhone,'SIN TELEFONO') as telefono
	  ,isnull(@w_email,'SIN EMAIL') as email
	  ,isnull(@w_internetPage,'SIN PAGINA WEB') as pageweb
	  ,isnull(@w_reca,'')
	  ,@w_firm
	  ,@w_gasto_cobranza
	  ,@w_gasto_apertura
	  ,@w_creditFrequency
	  ,@w_clausula

return 0

ERROR:

   exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
   
return @w_error