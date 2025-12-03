/******************************************************************/
/*  Archivo:          cadatpcr.sp                                 */
/*  Stored procedure: sp_datos_procredito                         */
/*  Base de datos:    cob_cartera                                 */
/*  Producto:         Cartera                                     */
/******************************************************************/
/*                         IMPORTANTE                             */
/* Este programa es parte de los paquetes bancarios propiedad de  */
/* MACOSA', representantes exclusivos para el Ecuador de la       */
/* 'NCR CORPORATION'.                                             */
/* Su uso no autorizado queda expresamente prohibido asi como     */
/* cualquier alteracion o agregado hecho por alguno de sus        */
/* usuarios sin el debido consentimiento por escrito de la        */
/* Presidencia Ejecutiva de MACOSA o su representante.            */
/******************************************************************/
/*                           PROPOSITO                            */
/*  Este Stored Procedure permite consultar datos procredito de   */
/*  un  cliente dado                                              */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA       AUTOR     RAZON                                   */
/*  21-May-08   A Correa  Emision Inicial                         */
/******************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where id = object_id('sp_datos_procredito'))
  drop procedure sp_datos_procredito
go


create proc sp_datos_procredito (
        @t_trn            smallint,
        @i_operacion      char(1),
        @i_cedruc         varchar(16)  = null,
        @i_formato_f      tinyint      = 101,
        @i_fecha_ini      datetime     = null,
        @i_fecha_fin      datetime     = null,
        @o_operacion      varchar(16)  = null out,
        @o_nombre         varchar(50)  = null out,
        @o_rol            varchar(10)  = null out,
        @o_vlrmora        money        = null out,
        @o_vlrdesb        money        = null out,
        @o_vlriva         money        = null out,
        @o_total          money        = null out,
        @o_idtitular      varchar(16)  = null out,
		@i_cliente        int          = null,
		@i_op_migrada	  varchar(24)  = null,
		@i_identificacion varchar(16)  = null,
		@i_opcion         smallint     = null

)as
declare @w_sp_name        varchar(20),
        @w_tipo           char(1),
        @w_monto          money,
        @w_tiva           float,
        @w_ndec           tinyint

select @w_sp_name = 'sp_datos_procredito'

if @i_operacion = 'Q'
begin
   if @t_trn <> 7187
   begin
      -- Codigo de transaccion errada
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129
      return 101129
   end
   
   if @i_cedruc is null
   begin
      -- Codigo de transaccion errada
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129,
           @i_msg   = 'Documento es obligatorio',
           @i_sev   = 0
      return 101129
   end
   
   select @o_operacion  = rc_numero_obligacion_cmm,
          @o_nombre     = rc_nombres + ' ' + rc_apellidos,
          @o_rol        = case rc_deudor_codeudor
                             when '1' then 'DEUDOR'
                             when '2' then 'CODEUDOR'
                             else 'INDEFINIDO'
                          end,
          @o_vlrmora    = rc_valor_mora,
          @o_idtitular  = rc_numero_titular
   from   cob_cartera..ca_reportar_cliente
   where  rc_numero_documento = @i_cedruc
   and    rc_estado           = 'V' -- Solo los registros vigentes
   
   if @@rowcount = 0
   begin
      -- No existen registros para identificacion ingresada
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129
      return 101129
   end
   
   select @w_tipo  = vd_tipovalor,
          @w_monto = vd_valor
   from   ca_valor_desbloqueo
   where  @o_vlrmora between vd_vlrinicial and vd_vlrfinal
   
   if @@rowcount = 0
   begin
      -- Valor mora no esta incluida en ningun rango
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129
      return 101129
   end
   
   select @w_tiva = pa_float
   from   cobis..cl_parametro
   where  pa_nemonico = 'PIVA'
   and    pa_producto = 'CTE'
   
   select @w_ndec = pa_tinyint
   from   cobis..cl_parametro
   where  pa_nemonico = 'DMNA'
   and    pa_producto = 'ATX'
   
   if @w_tipo = 'P'
      select @o_vlrdesb = round((@o_vlrmora * (@w_monto/100)), @w_ndec)
   else
      select @o_vlrdesb = round(@w_monto, @w_ndec)
   
   select @o_vlriva = round((@o_vlrdesb * (@w_tiva/100)), @w_ndec)
   
   select @o_total  = isnull(@o_vlrdesb,0) + isnull(@o_vlriva,0)
end

if @i_operacion = 'F' --Archivo FENALCO
begin
   if @t_trn <> 7188
   begin
      -- Codigo de transaccion errada
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101183
      return 101129
   end

   select 'No. Obligacion Corp.' = rc_numero_obligacion_cmm,
          'No. Obligacion Repo.' = rc_numero_obligacion_repor, 
          'ID. Deudor          ' = rc_numero_titular,
          'Apellidos Deudor    ' = rc_apellidos,
          'Nombres Deudor      ' = rc_nombres,
          'Vlr Mora            ' = rc_valor_mora,
          'Vlr Desbloqueo      ' = isnull(pc_valor_desbloqueo,0) + isnull(pc_valor_iva,0),
          'Fecha de desbloqueo ' = convert(varchar(10),pc_fecha_desbloqueo,@i_formato_f)
   from   cob_cartera..ca_pagos_procredito,
          cob_cartera..ca_reportar_cliente 
   where  pc_operacion        = rc_numero_obligacion_cmm
   and    pc_fecha_desbloqueo between  @i_fecha_ini and @i_fecha_fin
   and    pc_estado           = 'Z' -- CANCELADO
   
   if @@rowcount = 0
   begin
      -- No existen registros para los criterios de búsqueda
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 105506
      return 101129
   end
   return 0   
end

if @i_operacion = 'C' --Consulta de Cliente
begin
   if @t_trn <> 7272
   begin
      -- Codigo de transaccion errada
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101183
      return 101129
   end
    
   if @i_opcion  = 1
   begin
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente
	  and  op_cliente = @i_cliente	  
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end 
   
   if @i_opcion  = 2
   begin
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente	  
	  and  rc_numero_obligacion_cmm = @i_op_migrada	  
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end     

   if @i_opcion  = 3
   begin	  
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente
	  and  rc_numero_documento = @i_identificacion
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end 

   if @i_opcion  = 4
   begin
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente
	  and  op_cliente = @i_cliente
	  and  rc_numero_obligacion_cmm = @i_op_migrada	  
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end 

   if @i_opcion  = 5
   begin
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente
	  and  op_cliente = @i_cliente	  
	  and  rc_numero_documento = @i_identificacion
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end           

   if @i_opcion  = 6
   begin
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente	  
	  and  rc_numero_obligacion_cmm = @i_op_migrada
	  and  rc_numero_documento = @i_identificacion
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end       

   if @i_opcion  = 7
   begin
      select 'No. Obligacion Migra.' = rc_numero_obligacion_cmm,
			 'Identificacion'		 = rc_numero_documento,       
			 'Nombres Deudor'        = rc_nombres,       
			 'Apellidos Deudor'      = rc_apellidos,       
			 'Tipo Deudor'           = rc_deudor_codeudor,
			 'Estado'			     = rc_estado       
	  from   cob_cartera..ca_reportar_cliente, 
	         cob_cartera..ca_operacion,
		     cobis..cl_ente
	  where  rc_numero_documento = en_ced_ruc
	  and  en_ente = op_cliente	  
	  and  rc_numero_obligacion_cmm = @i_op_migrada
	  and  rc_numero_documento = @i_identificacion
	   
	   if @@rowcount = 0
	   begin
		  -- No existen registros para los criterios de búsqueda
		  exec cobis..sp_cerror
			   @t_from  = @w_sp_name,
			   @i_num   = 105506
		  return 101129
	   end
	   return 0
   end       

end


if @i_operacion = 'H' --PASO A HISTORICO
begin
   if @t_trn <> 7189
   begin
      -- Codigo de transaccion errada
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129
      return 101129
   end

   begin tran
   
   insert into cob_cartera_his..ca_reportar_cliente_his
   select * from cob_cartera..ca_reportar_cliente
   where  rc_fecha_desbloqueo between  @i_fecha_ini and @i_fecha_fin
   
   if @@error <> 0
   begin
      rollback
      -- Error pasando información a histórico
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129
      return 101129
   end
   
   delete cob_cartera..ca_reportar_cliente
   where  rc_fecha_desbloqueo between  @i_fecha_ini and @i_fecha_fin

   if @@error <> 0
   begin
      rollback
      -- Error pasando eliminando datos de tabla principal
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 101129
      return 101129
   end
   
   commit tran

end

return 0
go
