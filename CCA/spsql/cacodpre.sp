/************************************************************************/
/*	Archivo:		cacodpre.sp				*/
/*	Stored procedure:	sp_codigos_prepago			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto:               Cobis CARTERA         			*/
/*	Disenado por:           Luis Alfonso Mayorga       		*/
/*	Fecha de escritura:     Dic. 2002 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este programa procesa las siguientes operaciones de los codigos */
/*      de los prepagos de las pasivas (ca_codigos_prepago)		*/
/*	I: Insercion de los diferentes codigos prepago 		        */
/*	U: Actualizacion del registro de codigos prepago 		*/
/*	D: Eliminacion del registro de codigos prepago	 	        */
/*	S: Busqueda de los registros de codigos prepago 		*/
/*	Q: Consulta del registro de codigos prepago 			*/
/*	H: Ayuda en el registro de codigos prepago 			*/
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_codigos_prepago')
   drop proc sp_codigos_prepago

go
create proc sp_codigos_prepago (
@t_trn                  int		= null,
@s_date			datetime	= null, 
@s_user			login           = null,
@s_term                 varchar(30)     = null,
@s_org                  char(1)         = null,
@s_ofi                  smallint        = null,
@i_operacion		char(1),
@i_modo			tinyint 	= null,
@i_codigo		char(10)        = null,
@i_codigo_tipo		char(10)        = null,
@i_descripcion		descripcion	= null,
@i_estado		char(1)		= null,
@i_capitaliza 		char(4)	= null
)
as
declare 
@w_sp_name		varchar(32),
@w_return		int,
@w_error		int,
@w_codigo               int,
@w_cp_codigo     	char(10),
@w_cp_descripcion	descripcion,
@w_cp_capitaliza 	char(4),
@w_cp_estado     	char(1),
@v_cp_codigo     	char(10),
@v_cp_descripcion	descripcion,
@v_cp_capitaliza 	char(4),
@v_cp_estado     	char(1)



/** INICIALIZACION DE VARIABLES **/
select @w_sp_name = 'sp_codigos_prepago'


/** INSERT **/

if @i_operacion = 'I' begin
   begin tran
   /* VERIFICAR LA NO EXISTENCIA DEL CODIGO PREPAGO */
   if exists (select 1 from cob_cartera..ca_codigos_prepago
   where cp_codigo = @i_codigo) begin
      select @w_error = 710434
      goto ERROR
   end
   
   /* INSERT a ca_codigos_prepago */
   insert into ca_codigos_prepago (
   cp_codigo, cp_descripcion,cp_capitaliza,cp_estado)
   values (@i_codigo,@i_descripcion,@i_capitaliza,@i_estado)
   if @@error != 0 begin
      select @w_error = 710433
      goto ERROR
   end

 
   /* Transaccion de servicio - Codigos Prepago*/
    insert into ca_codigos_prepago_ts (cps_fecha_proceso_ts, cps_fecha_ts, cps_usuario_ts, cps_oficina_ts,	
					cps_terminal_ts, cps_tipo_transaccion_ts, cps_origen_ts, cps_clase_ts,
					cps_codigo, cps_descripcion, cps_capitaliza, cps_estado)    		
                                values (@s_date, getdate(), @s_user, @s_ofi, 
                                        @s_term, @t_trn, @s_org, 'N', 
                                        @i_codigo,@i_descripcion,@i_capitaliza,@i_estado)

   if @@error != 0
   begin
      exec cobis..sp_cerror
              @t_from         = @w_sp_name,
              @i_num          = 710047	
      return 1
   end     
   
   commit tran
   return 0
end

/** UPDATE **/
if @i_operacion = 'U' begin

      select @w_cp_codigo      = cp_codigo,
   	     @w_cp_descripcion = cp_descripcion,
   	     @w_cp_capitaliza  = cp_capitaliza,
   	     @w_cp_estado      = cp_estado
        from cob_cartera..ca_codigos_prepago
       where cp_codigo = @i_codigo 
     if @@rowcount = 0
        begin
          exec cobis..sp_cerror
          @t_from               = @w_sp_name,
          @i_num                = 710047
          return 1
        end

   begin tran
   /* UPDATE DATOS DEL SUBTIPO DE LINEA DE CREDITO */
   update cob_cartera..ca_codigos_prepago set
   cp_codigo         = @i_codigo,
   cp_descripcion    = @i_descripcion,
   cp_capitaliza     = @i_capitaliza,
   cp_estado	     = @i_estado
   where cp_codigo = @i_codigo 
   if @@error != 0 begin
      select @w_error = 710432
      goto ERROR
   end


   /* Transaccion de servicio - Codigos Prepago --Registro Previo*/
    insert into ca_codigos_prepago_ts (cps_fecha_proceso_ts, cps_fecha_ts, cps_usuario_ts, cps_oficina_ts,	
					cps_terminal_ts, cps_tipo_transaccion_ts, cps_origen_ts, cps_clase_ts,
					cps_codigo, cps_descripcion, cps_capitaliza, cps_estado)    		
                                values (@s_date, getdate(), @s_user, @s_ofi, 
                                        @s_term, @t_trn, @s_org, 'P', 
                                        @w_cp_codigo,@w_cp_descripcion,@w_cp_capitaliza,@w_cp_estado)

   if @@error != 0
   begin
      exec cobis..sp_cerror
              @t_from         = @w_sp_name,
              @i_num          = 710047	
      return 1
   end   
   
   /* Transaccion de servicio - Codigos Prepago --Registro Actual*/
    insert into ca_codigos_prepago_ts (cps_fecha_proceso_ts, cps_fecha_ts, cps_usuario_ts, cps_oficina_ts,	
					cps_terminal_ts, cps_tipo_transaccion_ts, cps_origen_ts, cps_clase_ts,
					cps_codigo, cps_descripcion, cps_capitaliza, cps_estado)    		
                                values (@s_date, getdate(), @s_user, @s_ofi, 
                                        @s_term, @t_trn, @s_org, 'A', 
                                        @i_codigo,@i_descripcion,@i_capitaliza,@i_estado)

   if @@error != 0
   begin
      exec cobis..sp_cerror
              @t_from         = @w_sp_name,
              @i_num          = 710047	
      return 1
   end      
   

   commit tran
end

/** SEARCH **/
if @i_operacion = 'S' begin
   set rowcount 20
   if @i_modo = 0
      select 
      'Codigo Prepago' = cp_codigo,
      'Descripci¢n'    = substring(cp_descripcion,1,64),
      'Estado'	       = cp_estado,
      'Capitaliza'     = cp_capitaliza
      from cob_cartera..ca_codigos_prepago
      order by cp_codigo
      
   if @i_modo = 1
      select
      'Codigo Prepago' = cp_codigo,
      'Descripci¢n'    = substring(cp_descripcion,1,64),
      'Estado'         = cp_estado,
      'Capitaliza'     = cp_capitaliza
      from cob_cartera..ca_codigos_prepago
      where cp_codigo > @i_codigo
      order by cp_codigo
   set rowcount 0
end

/** QUERY **/        
if @i_operacion = 'Q' begin
   select  cp_codigo,cp_descripcion,cp_estado,
   cp_capitaliza
   from	cob_cartera..ca_codigos_prepago
   where cp_codigo  = @i_codigo
   if @@rowcount = 0 begin
      select @w_error = 710431
      goto ERROR
   end
end

if @i_operacion = 'V' begin
      select
      cp_codigo,
      substring(cp_descripcion,1,64),
      cp_capitaliza,
      cp_estado
      from ca_codigos_prepago
      where cp_codigo = @i_codigo
      if @@rowcount = 0 begin
         select @w_error = 710431
         goto ERROR
      end                             
end 

if @i_operacion = 'H' begin
   set rowcount 20
   if @i_modo = 0
      select
      'Codigo Prepago' = cp_codigo,
      'Descripci¢n'    = substring(cp_descripcion,1,64),
      'Estado'         = cp_estado,
      'Capitaliza'     = cp_capitaliza
      from cob_cartera..ca_codigos_prepago
      where cp_capitaliza = @i_capitaliza
      and cp_estado = 'V'
      order by cp_codigo
   if @i_modo = 1
      select
      'Codigo Prepago' = cp_codigo,
      'Descripci¢n'    = substring(cp_descripcion,1,64),
      'Estado'         = cp_estado,
      'Capitaliza'     = cp_capitaliza
      from cob_cartera..ca_codigos_prepago
      where cp_codigo > @i_codigo
      and cp_capitaliza = @i_capitaliza
      and cp_estado = 'V'
      order by cp_codigo
   set rowcount 0              
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',        @t_file = null,
@t_from =@w_sp_name, @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

