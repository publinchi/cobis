/************************************************************************/
/*      Nombre Fisico:          estrubro.sp                             */
/*      Nombre Logico:          sp_estados_rubro                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pealez B.                        */
/*      Fecha de escritura:     FEb 2004                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios que son       	*/
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
/*            PROPOSITO                                                 */
/*  Da mantenimiento a los rubros que dependen de una garantia          */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion	*/
/*									  de char(1) a catalogo				*/
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_estados_rubro')
    drop proc sp_estados_rubro
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


create proc sp_estados_rubro (
   @s_date               datetime     = null,
   @s_user               login        = null,
   @s_term               descripcion  = null,
   @s_ofi                smallint     = null,
  	@t_file   			    varchar(14)  = null,
	@t_from  			    varchar(30)  = null,
   @t_debug 			    char(1)      = 'N',
   @i_operacion          char(1),
   @i_banco              cuenta,
   @i_tipo               char(1)      = null,
   @i_concepto           catalogo     = null

)
as

declare
   @w_error              int,
   @w_sp_name            varchar(32),  
   @w_cliente            int,
   @w_operacion          int,
   @w_secuencial         int,
   @w_calificacion       catalogo,
   @w_gar_adminsible     char(1),
   @w_oficial            int,
   @w_oficina_op         smallint,
   @w_toperacion         catalogo,
   @w_reestructuracion   char(1),
   @w_observacion        char(62)
   

   
   
select @w_sp_name = 'sp_estados_rubro',
       @w_observacion = 'MANTENIMIENTO DE RUBROS EN OPERACION DESEMBOLSADA'


select  @w_cliente          = op_cliente,
        @w_operacion        = op_operacion,
        @w_calificacion     = op_calificacion,
        @w_gar_adminsible   = op_gar_admisible,
        @w_oficial          = op_oficial,
        @w_oficina_op       = op_oficina,
        @w_toperacion       = op_toperacion,
        @w_reestructuracion = op_reestructuracion

from ca_operacion        
where op_banco = @i_banco


--VALIDACION DEL RUBRO
if @i_concepto is not null
begin
   if exists  (select 1 from ca_rubro
               where ru_concepto = @i_concepto
               and ru_tipo_garantia is not null)
   begin
      select @w_error = 0
   end
   ELSE
   begin
      select @w_error = 710503
      goto ERROR
   end
end            

---PRINT 'estrubro.sp operacion que va %1!',@i_operacion
       
-- PASO DE LA OPERACION A TEMPORALES
if @i_operacion = 'T' 
begin
   exec @w_error     = sp_pasotmp
   @s_user            = @s_user,
   @s_term            = @s_term,
   @i_banco           = @i_banco,
   @i_operacionca     = 'S',
   @i_dividendo       = 'N',   
   @i_amortizacion    = 'N',   
   @i_cuota_adicional = 'N',
   @i_rubro_op        = 'S',
   @i_valores         = 'N', 
   @i_acciones        = 'N'  
   
   if @w_error != 0 
      goto ERROR
end


/*
--Insercion del registro 
if @i_operacion = 'I' 
begin

end


-- Actualizacion del registro 
if @i_operacion = 'U' 
begin

if exists (select 1 from ca_rubro_op
           where ro_roperacion = @w_operacion
           and   ro_cocepto    = @i_concepto)
begin
   select  @w_error = 
      goto ERROR
end
   
delete ca_rubro_op_tmp
where rot_operacion = @w_operacion
and   rot_cocnepto  = @i_concepto

end

*/

if @i_operacion = 'H' 
begin
  if @i_tipo = 'G'
  begin
      select
      'Rubro'                 = co_concepto,
      'Descripcion'           = substring(co_descripcion,1,20)
      from  ca_concepto
      where co_categoria in ('S','A','O')
      order by co_concepto                                            

  end 
  if @i_tipo = 'V'
  begin
      select
      substring(co_descripcion,1,20)
      from  ca_concepto
      where co_concepto = @i_concepto
      and co_categoria  ='S' --Seguros 
      if @@rowcount = 0
         return 701003
  end 
end --H
   
--Consulta opcion QUERY 
if @i_operacion = 'S' 
begin

   select
   'Rubro'                 = rot_concepto,
   'Descripcion'           = substring(co_descripcion,1,20),
   'Tasa Calculo'          = rot_porcentaje, 
   'Tasa a Aplicar'        = rot_referencial,
   'Valor Rubro'           = convert(float, rot_valor),
   'Base de Calculo'       = rot_base_calculo,
   'Tipo Garantia'         = rot_tipo_garantia,
   'Nro. Garantia'         = rot_nro_garantia,
   'Concepto Asociado'     = rot_concepto_asociado,
   'Otras Tasas'           = rot_tabla
   
   from ca_rubro_op_tmp,
        ca_concepto
   where rot_operacion  = @w_operacion
   and   co_concepto = rot_concepto
   and   co_categoria in ('S','A','O')
   order by rot_concepto                                            

   select 
   'No. Tramite'    = dg_tramite,
   'Tipo'           =substring(cu_tipo,1,10),
   'Descripcion'    = substring(tc_descripcion,1,30),
   'No.Garantia'    = substring(cu_codigo_externo,1,20),
   'Valor Incial'   = cu_valor_inicial,
   'Valor Respaldo' = dg_valor_resp_garantia,
   'Clase Vehiculo' = cu_clase_vehiculo   
   from cob_custodia..cu_distr_garantia,
   cob_custodia..cu_custodia,
   cob_custodia..cu_tipo_custodia,
   cob_cartera..ca_operacion
   where  dg_tramite = op_tramite
   and    op_cliente = @w_cliente
   and cu_codigo_externo = dg_garantia
   and cu_clase_custodia <> 'O' --- Otras garantias  I Idoneas
   and (cu_aseguradora     = '3' or cu_aseguradora is null )---@w_codigo_seg
   and cu_tipo = tc_tipo
order by cu_tipo
end


/*

if @i_operacion = 'D' begin

  

end
*/

-- PASO A DEFINITIVAS
/*if @i_operacion = 'T' 
begin
   exec @w_secuencial = sp_gen_sec
        @i_operacion  = @w_operacion
   
   -- OBTENER RESPALDO 
   exec @w_error  = sp_historial
        @i_operacionca  = @w_operacion,
        @i_secuencial   = @w_secuencial


   insert into ca_transaccion
         (tr_secuencial,     tr_fecha_mov,        tr_toperacion,
          tr_moneda,         tr_operacion,        tr_tran,
          tr_en_linea,       tr_banco,            tr_dias_calc,
          tr_ofi_oper,       tr_ofi_usu,          tr_usuario,
          tr_terminal,       tr_fecha_ref,        tr_secuencial_ref,
          tr_estado,         tr_observacion,      tr_gerente,      
          tr_gar_admisible,  tr_reestructuracion,      
          tr_calificacion,    tr_fecha_cont,       tr_comprobante)
   values(@w_secuencial,     @s_date,             @w_toperacion,
          @w_moneda_op,      @w_operacion,        'MRU',
          'S',               @i_banco,            1,
          @w_oficina_op,     @s_ofi,              @s_user,
          @s_term,           @i_fecha_proceso,    0,
          'ING',             @w_observacion,     @w_oficial,
          @w_gar_adminsible,  @w_reestructuracion,      
          @w_calificacion,   @s_date,             0)   
   
   if @@error != 0
      return 708165

  

end
*/


return 0

ERROR:
exec cobis..sp_cerror
@t_debug = @t_debug,
@t_file  = @t_file,
@t_from  = @w_sp_name,
@i_num   = @w_error
return @w_error

go
