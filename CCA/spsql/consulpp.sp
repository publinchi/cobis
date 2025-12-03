/***********************************************************************/
/*	Archivo                 :			consulpp.sp                        */
/*	Stored procedure        :		   sp_consulta_ppasivas               */
/*	Base de Datos           :			cob_cartera                        */
/*	Producto                :			Cartera	                          */
/*	Disenado por            :			Elcira Pelaez                      */
/*	Fecha de Documentacion  :        Nov-2004                           */
/***********************************************************************/
/*			                   IMPORTANTE		       		                 */
/*	Este programa es parte de los paquetes bancarios propiedad de       */ 	
/*	"MACOSA".						                                         */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier autorizacion o agregado hecho por alguno de sus           */
/*	usuario sin el debido consentimiento por escrito de la              */
/*	Presidencia Ejecutiva de MACOSA o su representante	                 */
/***********************************************************************/  
/*			                     PROPOSITO				                    */
/*	Este sp permite consultar los prepagos pasivos dependiendo          */
/*      del codigo enviado por pantalla FCONSPP.FRM                    */
/***********************************************************************/  
/*                         MODIFICACIONES                              */
/*  FECHA            AUTOR       		RAZON                           */
/*  DIC/29/2005     Elcira Pelaez            Def 5493                  */
/***********************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_consulta_ppasivas')
	drop proc sp_consulta_ppasivas
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_consulta_ppasivas
@s_user            	     login    = null,
@s_date            	     datetime = null,
@t_trn			           int,
@i_fecha_proceso  	     datetime = null,
@i_codigo_prepago	        catalogo = null,
@i_fecha	      	        datetime = null,  
@i_rechazos               char(1)  = null,
@i_pagados                char(1)  = null,
@i_ingresados            char(1)   = null,
@i_formato_fecha    	     int      = 101,
@i_secuencial             int      = 0,
@i_banco_seg_piso         catalogo,
@i_opcion                 char(1)  = null,
@i_operacion              char(1)  = null,
@i_banco                  cuenta   = null,
@i_llave_redes            cuenta   = null,
@i_cedula                 numero   = null,
@i_reversados             char(1)  = null

  
as declare 
@w_error          		int,
@w_return         		int,
@w_sp_name        		descripcion,
@w_est_aplicar          char(1),
@w_est_registro         char(1),
@w_estado_aplicar       char(1),
@w_codigo_todas         catalogo
  
select @w_sp_name = 'sp_consulta_ppasivas'

if @i_rechazos  = 'S'
   select @w_est_aplicar = 'P',
          @w_est_registro = 'I'
   
if @i_pagados  = 'S'
   select @w_est_aplicar = 'S',
          @w_est_registro = 'P'
          
if @i_ingresados  = 'S'
   select @w_est_aplicar = 'N',
          @w_est_registro = 'I'

if @i_reversados  = 'S'
   select @w_est_aplicar = 'P',
          @w_est_registro = 'R'



select @w_codigo_todas = pa_char
from cobis..cl_parametro
where pa_nemonico = 'TODCAU'
and pa_producto = 'CCA'
set transaction isolation level read uncommitted

if @i_codigo_prepago = @w_codigo_todas
   select @i_codigo_prepago = null
   
  
if @i_operacion = 'C'
begin
   delete ca_consultas_prepagos
   where rpp_user = @s_user

   insert into ca_consultas_prepagos
    select 
      @s_user,
      pp_secuencial,
      pp_oficina,
      pp_llave_redescuento,
      pp_banco,
      pp_nombre,
      pp_identificacion,
      pp_saldo_capital,
      pp_fecha_int_desde,
      pp_fecha_int_hasta,
      pp_dias_de_interes,
      pp_formula_tasa,
      pp_tasa,
      pp_valor_prepago,
      pp_saldo_intereses,
      (pp_saldo_intereses + pp_valor_prepago),
      pp_codigo_prepago,
      pp_fecha_generacion,
      substring(pp_linea,1,3),
      pp_estado_aplicar,
      pp_estado_registro,
      pp_comentario,
      pp_causal_rechazo
      
      from ca_prepagos_pasivas
         where  pp_fecha_generacion = @i_fecha
         and    ( pp_codigo_prepago  = @i_codigo_prepago  or   @i_codigo_prepago is null)
         and    pp_secuencial > 0
         and    pp_estado_aplicar =  @w_est_aplicar   
         and    pp_estado_registro = @w_est_registro
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
end

if @i_operacion = 'B'
begin
 
      if @i_opcion = '0' 
      begin
          set rowcount 10
          select 
               'Oficina'             = rpp_oficina,
               'Llave Redesuento'    = rpp_llave_redescuento,
               'No. Obligacion'      = rpp_banco,
               'Beneficiario'        = rpp_nombre,
               'Identificacion'      = rpp_identificacion,
               'Saldo Capital'       = rpp_saldo_capital,
               'Fecha Interes desde' = convert (varchar(10), rpp_fecha_int_desde,@i_formato_fecha),
               'Fecha Interes hasta' = convert (varchar(10), rpp_fecha_int_hasta,@i_formato_fecha),
               'Dias'                = rpp_dias_de_interes,
               'Formula Tasa'		    = substring(rpp_formula_tasa,1,15),
               'Tasa'                = rpp_tasa,
               'Valor Capital'       = rpp_valor_prepago,
               'Valor Interes'       = rpp_saldo_intereses,
               'Valor Pago'          = rpp_valor_pagado,
               'Causal Prepago'      = rpp_codigo_prepago, 
               'Comentario'          = rpp_comentario,                    
               'Sec'                 = rpp_secuencial,
               'Causal Rechazo'      = rpp_causal_rechazo
         from ca_consultas_prepagos
         where  rpp_user             = @s_user
         and    (rpp_codigo_prepago   = @i_codigo_prepago  or   @i_codigo_prepago is null)        
         and    rpp_fecha_generacion = @i_fecha
         and    rpp_banco_segundo_piso = @i_banco_seg_piso         
         and    rpp_estado_aplicar =  @w_est_aplicar   
         and    rpp_estado_registro = @w_est_registro
         order by rpp_secuencial
         set rowcount 0
     end 
     else
     if @i_opcion = '1'
     begin
      set rowcount 10
          select 
               'Oficina'             = rpp_oficina,
               'Llave Redesuento'    = rpp_llave_redescuento,
               'No. Obligacion'      = rpp_banco,
               'Beneficiario'        = rpp_nombre,
               'Identificacion'      = rpp_identificacion,
               'Saldo Capital'       = rpp_saldo_capital,
               'Fecha Interes desde' = convert (varchar(10), rpp_fecha_int_desde,@i_formato_fecha),
               'Fecha Interes hasta' = convert (varchar(10), rpp_fecha_int_hasta,@i_formato_fecha),
               'Dias'                = rpp_dias_de_interes,
               'Formula Tasa'		    = substring(rpp_formula_tasa,1,15),
               'Tasa'                = rpp_tasa,
               'Valor Capital'       = rpp_valor_prepago,
               'Valor Interes'       = rpp_saldo_intereses,
               'Valor Pago'          = rpp_valor_pagado,
               'Causal Prepago'      = rpp_codigo_prepago,          
               'Comentario'          = rpp_comentario,                                   
               'Sec'                 = rpp_secuencial,
               'Causal Rechazo'      = rpp_causal_rechazo               
         from ca_consultas_prepagos
         where  rpp_user               = @s_user
         and   ( rpp_codigo_prepago     = @i_codigo_prepago  or   @i_codigo_prepago is null)
         and    rpp_fecha_generacion   = @i_fecha
         and    rpp_banco_segundo_piso = @i_banco_seg_piso         
         and    rpp_estado_aplicar     =  @w_est_aplicar   
         and    rpp_estado_registro    = @w_est_registro
         and    rpp_secuencial         >  @i_secuencial
         order by rpp_secuencial
         set rowcount 0
      
     end  --opcion 1
 end --operacion B   

--VALIDACION DE LA OPCION DE BUSQUEDA PARA RECHAZOS
if @i_operacion = 'Q'
begin
   
   if @i_cedula  is not null
   begin
     select @w_estado_aplicar = pp_estado_aplicar
     from ca_prepagos_pasivas
         where  pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago   = @i_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
         and    pp_identificacion = @i_cedula
      if @@rowcount = 0
      begin
         select @w_error = 710546
         goto ERROR
      end         
               
   end

 if @i_banco is not null
 begin
   select @w_estado_aplicar = pp_estado_aplicar
   from ca_prepagos_pasivas
   where  pp_fecha_generacion = @i_fecha
   and    pp_codigo_prepago   = @i_codigo_prepago
   and    substring(pp_linea,1,3) = @i_banco_seg_piso
   and    pp_banco = @i_banco
   if @@rowcount = 0
   begin
      select @w_error = 710546
      goto ERROR
   end

 end
 
 if @i_llave_redes is not null
 begin
   select @w_estado_aplicar = pp_estado_aplicar
   from ca_prepagos_pasivas
   where  pp_fecha_generacion = @i_fecha
   and    pp_codigo_prepago   = @i_codigo_prepago
   and    substring(pp_linea,1,3) = @i_banco_seg_piso
   and    pp_llave_redescuento = @i_llave_redes
   if @@rowcount = 0
   begin
      select @w_error = 710546
      goto ERROR
   end

 end
 
   if @w_estado_aplicar = 'S'
   begin
      select @w_error = 710547
      goto ERROR
   end
 
end
--Resultado de Operacion para rechazar SOLO UNA SEGUN EL CRITERIO DE BUSQUEDA

if @i_operacion = 'R'
begin
      select 
       'Oficina'             =  pp_oficina,
       'Llave Redesuento'    =  pp_llave_redescuento,
       'No. Obligacion'      =  pp_banco,
       'Beneficiario'        =  pp_nombre,
       'Identificacion'      =  pp_identificacion,
       'Saldo Capital'       =  pp_saldo_capital,
       'Fecha Interes desde' = convert (varchar(10), pp_fecha_int_desde,@i_formato_fecha),
       'Fecha Interes hasta' = convert (varchar(10), pp_fecha_int_hasta,@i_formato_fecha),
       'Dias'                =  pp_dias_de_interes,
       'Formula Tasa'		  = substring(pp_formula_tasa,1,15),
       'Tasa'                =  pp_tasa,
       'Valor Capital'       =  pp_valor_prepago,
       'Valor Interes'       =  pp_saldo_intereses,
       'Valor Pago'          =  (pp_saldo_intereses + pp_valor_prepago),
       'Causal'              =  pp_codigo_prepago,
       'Comentario'          =  pp_comentario,
       'EstadoPrepago'       =  case  pp_estado_aplicar 
	                                  when 'N'  then  'No Aprobado' 
                                      when 'P'  then  'Rechazado' 
                                      when 'S'  then  'Aprobado'   
                                end,      
       'Estado Registro'     =  case pp_estado_registro 
	                                  when 'I'  then  'Ingresado' 
                                      when 'P'  then  'Procesado' 
                                end,
       'Sec'                 =  pp_secuencial,
       'Causal Rechazo'      =  pp_causal_rechazo
       
       
      from ca_prepagos_pasivas
         where  pp_fecha_generacion = @i_fecha
         and    (pp_codigo_prepago  = @i_codigo_prepago or @i_codigo_prepago is null)
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
         and    (pp_banco  = @i_banco or pp_identificacion = @i_cedula or  pp_llave_redescuento = @i_llave_redes)
   
end

if @i_operacion = 'H'
begin
   
    if @i_banco  is not null
    begin
      if not exists (select 1 from ca_prepagos_pasivas
      where pp_banco =  @i_banco
      and   pp_fecha_generacion = @i_fecha
      and    pp_codigo_prepago   = @i_codigo_prepago
      and    substring(pp_linea,1,3) = @i_banco_seg_piso)
   
      begin 
         select @w_error =  710546
         goto ERROR
      end
   end
   
   if @i_cedula  is not null   
   begin
            if not exists (select 1 from ca_prepagos_pasivas
      where pp_identificacion =  @i_cedula
      and   pp_fecha_generacion = @i_fecha
      and    pp_codigo_prepago   = @i_codigo_prepago
      and    substring(pp_linea,1,3) = @i_banco_seg_piso)
   
      begin 
         select @w_error =  710546
         goto ERROR
      end
   end

  if @i_llave_redes  is not null   
   begin
            if not exists (select 1 from ca_prepagos_pasivas
      where pp_llave_redescuento =  @i_llave_redes
      and   pp_fecha_generacion = @i_fecha
      and    pp_codigo_prepago   = @i_codigo_prepago
      and    substring(pp_linea,1,3) = @i_banco_seg_piso)
   
      begin 
         select @w_error =  710546
         goto ERROR
      end
   end   
   
end

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug  = 'N',    
   @t_file   =  null,
   @t_from   =  @w_sp_name,
   @i_num    =  @w_error
   return   @w_error
go




