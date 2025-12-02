/************************************************************************/
/*   Archivo:              actllared.sp                                 */
/*   Stored procedure:     sp_actualiza_llave_redes                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez B.                             */
/*   Fecha de escritura:   Sep. 2002                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Disparar el proceso  interno para la actualizacion de la           */
/*      llave de redescuento                                            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_llave_redes')
   drop proc sp_actualiza_llave_redes
go

create proc sp_actualiza_llave_redes
   @s_user       login       = Null,
   @s_term       varchar(30) = Null,
   @s_date       datetime   = Null,
   @s_ofi       smallint   = Null,
   @i_operacion     char(1),
   @i_opcion        char(1)     = Null,
   @i_operacionca   int         = Null,
   @i_oper_enviada   cuenta     = null,
   @i_llave_actual  cuenta      = null,
   @i_llave_nueva   cuenta      = null

as declare 
   @w_return            int,
   @w_error             int,
   @w_sp_name           varchar(30),
   @w_llave             cuenta,
   @w_tramite           int

select @w_sp_name = 'sp_actualiza_llave_redes'

if @i_operacion = 'H'
begin



   select @w_tramite  = op_tramite
   from   ca_operacion
   where  op_banco = @i_oper_enviada
   and    op_tipo in ('R','C')
   
   if @@rowcount = 0
   begin
      select @w_error = 701049
      goto ERROR
   end



   select @w_llave = tr_llave_redes
   from   cob_credito..cr_tramite
   where  tr_tramite = @w_tramite  
   
   if @@rowcount = 0
   begin
      select @w_error = 701049
      goto ERROR
   end
   
   if @w_llave is null 
      select  @w_llave = 'NO EXISTE'
   
   select  @w_llave
end

if @i_operacion = 'Q'
begin
   if @i_opcion = '0'
   begin

      select 'OPER.         ' = op_operacion,
             'No.LLAVE RED. ' = op_codigo_externo,
             'No. OPERACION ACT/PAS. ' = op_banco,
             'CLIENTE       ' = op_cliente,
             'NOMBRE        ' = op_nombre,
             'No. TRAMITE   ' = op_tramite,
             'MONTO         ' = op_monto,
             'LINEA CREDITO ' = op_toperacion,
             'FECHA PROCESO ' = convert(char(12), op_fecha_ult_proceso, 101),
             'ESTADO OPER.  ' = es_descripcion
      from   ca_operacion, ca_estado, cob_credito..cr_tramite
      where  op_tramite = tr_tramite
      and    tr_llave_redes = @i_llave_actual
      and    op_estado <> 99
      and    op_estado  = es_codigo
   end
   
   if @i_opcion = '1'
   begin
      select 'OPER.         ' = op_operacion,
             'No.LLAVE RED. ' = op_codigo_externo, 
             'No. OPERACION ACT/PAS. ' = op_banco,
             'CLIENTE       ' = op_cliente,
             'NOMBRE        ' = op_nombre,
             'No. TRAMITE   ' = op_tramite,
             'MONTO         ' = op_monto,
             'LINEA CREDITO ' = op_toperacion, 
             'FECHA PROCESO ' = convert(char(12), op_fecha_ult_proceso, 101),
             'ESTADO OPER.  ' = es_descripcion
      from   ca_operacion,ca_estado, cob_credito..cr_tramite
      where  tr_llave_redes = @i_llave_nueva
      and    tr_tramite     = op_tramite
      and    op_estado      = es_codigo
   end
end

if @i_operacion = 'U'
begin
--   PRINT 'actllared.sp  operacion Original --->  Nueva llave  ' + cast(@i_operacionca as varchar) + cast(@i_llave_actual as varchar)
   
   select @w_tramite = op_tramite
   from   ca_operacion
   where  op_operacion = @i_operacionca
   
   ---ACTUALIZACIONES EN CREDITO
   update cob_credito..cr_tramite
   set    tr_llave_redes = @i_llave_nueva
   where  tr_tramite = @w_tramite
   
   update cob_credito..cr_archivo_redescuento
   set    re_llave_redescuento = @i_llave_nueva
   where  re_tramite = @w_tramite
   
   ---ACTUALIZACIONES EN CARTERA
   
   update ca_operacion
   set    op_codigo_externo = @i_llave_nueva
   where  op_operacion = @i_operacionca
   and    op_tramite = @w_tramite
   
   ---ACTUALIZACION DE HISTORICOS
   update ca_operacion_his
   set    oph_codigo_externo = @i_llave_nueva
   where  oph_operacion = @i_operacionca
   

   update cob_cartera_his..ca_operacion_his
   set    oph_codigo_externo = @i_llave_nueva
   where  oph_operacion = @i_operacionca
      
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   =  null,
        @t_from   =  @w_sp_name,
        @i_num    =  @w_error
        
   return  @w_error
   
go
