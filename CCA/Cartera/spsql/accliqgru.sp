/**************************************************************************/
/*   NOMBRE LOGICO:      accliqgru.sp                                     */
/*   NOMBRE FISICO:      sp_acciones_liquidacion_grupal                   */
/*   BASE DE DATOS:      cob_cartera                                      */
/*   PRODUCTO:           Cartera                                          */
/*   DISENADO POR:       Guisela Fernandez, Juan Carlos Guzman            */
/*   FECHA DE ESCRITURA: Feb. 2023                                        */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.                 */
/**************************************************************************/
/*                     PROPOSITO                                          */
/*   Acciones a realizar la consulta, liquidación y reversos de           */
/*   operaciones grupales                                                 */
/**************************************************************************/
/*                     MODIFICACIONES                                     */
/*   FECHA              AUTOR              RAZON                          */
/*   13-Feb-2023       G. Fernandez      Emision Inicial                  */
/*   24-Feb-2023       G. Fernandez      Se ingresa parametro             */
/*                                       @i_liq_grupal para la liq.       */
/*   27-Feb-2023       G. Fernandez      S787839 Parametro para reversos  */
/*                                       desembolso de prestamos grupales */
/*   19-Mar-2023       G. Fernandez      B797169 Validacion de existencia */
/*                                       de operaciones individuales      */
/*   04-Jul-2023       G. Fernandez      Se aumenta parametro t_timeout   */
/*   21-Ago-2023       K. Rodríguez      S873644 Se cambia consulta de op.*/
/*                                 pendiente de desembolso para renovacion*/
/*   25-Ago-2023       G. Fernandez      R213766 Act. consulta por renov. */
/*   29-Ago-2023       G. Fernandez      R213766 Se elimina act. de pagado*/
/*                                       en el reverso                    */
/*   06/Dic/2023       K. Rodríguez      R220933 No considerar estado Anu-*/
/*                                       lado en reverso de desembolso grp*/
/**************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_acciones_liquidacion_grupal')
    drop proc sp_acciones_liquidacion_grupal
go

create proc sp_acciones_liquidacion_grupal
   @s_ssn                   int         = null,
   @s_user                  login,
   @s_rol                   tinyint     = 3,
   @s_term                  varchar(30),
   @s_date                  datetime,
   @s_sesn                  int         = null,
   @s_ofi                   smallint,
   @s_srv                   varchar(30) = null,
   @t_trn                   INT         = null, 
   @t_timeout               INT         = null,
   @i_operacion             char(1)     = null,
   @i_banco                 cuenta      = null,
   @i_observacion           descripcion = null,
   @i_externo               char(1)     = 'N'
as

declare @w_sp_name          descripcion,
        @w_operacionca      int,
        @w_banco            cuenta,
        @w_error            int,
        @w_fecha_ini        datetime,
		@w_fecha_liq        datetime,
        @w_max_registros    int,
        @w_count            int,
        @w_secuencial       int,
		@w_est_novigente    tinyint,
		@w_estado           tinyint,
		@w_num_desembolso   int,
		@w_secuencial_act   int


select @w_sp_name = 'sp_acciones_liquidacion_grupal'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out

if @w_error <> 0 
	goto ERROR


/** BUSQUEDA DE OPERACIONES HIJAS**/
if @i_operacion = 'S' begin
   
   --Validacion si la operacion ya fue cancelada
   if exists (select 1 from ca_operacion where op_banco = @i_banco and op_estado <> 3)
   begin 
      select op_banco,
      op_toperacion,
      op_cliente,
      op_nombre,
      op_monto,
      op_fecha_ini, 
      op_fecha_fin, 
      (select es_descripcion from ca_estado where es_codigo = op_estado)
      from cob_cartera..ca_operacion
      where op_grupal = 'S'
      and op_ref_grupal = @i_banco
      and op_estado = 0
       
      if @@rowcount = 0
      begin
         /* Error, la operación padre no tiene operaciones hijas asociadas*/
         select @w_error  = 711095
         goto ERROR
      end
   end
   else
   begin
      select op_banco,
      op_toperacion,
      op_cliente,
      op_nombre,
      op_monto,
      op_fecha_ini, 
      op_fecha_fin, 
      (select es_descripcion from ca_estado where es_codigo = op_estado)
      from cob_cartera..ca_operacion
      where op_grupal = 'S'
      and op_ref_grupal = @i_banco
	  and op_estado = 1
       
      if @@rowcount = 0
      begin
         /* Error, la operación padre no tiene operaciones hijas asociadas*/
         select @w_error  = 711095
         goto ERROR
      end
   end

end


/**  Liquidación de operaciones Hijas  **/
if @i_operacion = 'I' begin
   
   if @i_externo = 'S'
      begin tran

   /**  Bucle para liquidar cada una de los operaciones hijas **/  
   select op_operacion, op_banco, op_estado, op_fecha_liq, ca_desembolso.* 
   into #op_hijas_desembolso 
   from ca_operacion, ca_desembolso
   where op_grupal = 'S'
   and op_ref_grupal = @i_banco
   and op_operacion = dm_operacion
   and op_estado = 0
      
   select @w_operacionca = min(op_operacion)
   from #op_hijas_desembolso

    while @w_operacionca is not null 
    begin
       /**  Se valida que la operación hija tenga registrado una forma de desembolso **/
	   if not exists (select 1 from ca_desembolso where dm_operacion = @w_operacionca)
	   begin
	      select @w_error = 725272
		  goto ERROR
	   end
       
       select @w_banco          = op_banco,
              @w_fecha_ini      = op_fecha_liq,
			  @w_estado         = op_estado,
              @w_secuencial     = dm_secuencial
       from #op_hijas_desembolso
       where op_operacion = @w_operacionca
	   group by op_banco, op_fecha_liq, op_estado, dm_secuencial
	   
	   
	   if @w_estado = @w_est_novigente
	   begin
	   
	      -- se borran tablas temporales
          exec @w_error = sp_borrar_tmp
               @s_user       = @s_user,
               @s_sesn       = @s_sesn,
               @s_term       = @s_term,
               @i_desde_cre  = 'N',
               @i_banco      = @w_banco
          
          if @w_error <> 0
          begin
             goto ERROR
          end
	     
	      /**  Se realiza el paso a temporales de la operacion Hija **/
	      exec @w_error = sp_pasotmp
               @s_user            = @s_user,
               @s_term            = @s_term,
               @i_banco           = @w_banco,
               @i_operacionca     = 'S',
               @i_dividendo       = 'S',
               @i_amortizacion    = 'S',
               @i_cuota_adicional = 'S',
               @i_rubro_op        = 'S',
               @i_valores         = 'S', 
               @i_acciones        = 'S'
          if @w_error <> 0
          begin
             goto ERROR
          end

          /**  Liquidación de operacion hija  **/  
          exec @w_error = cob_cartera..sp_liquida
          @i_banco_ficticio    = @w_operacionca, 
          @i_banco_real        = @w_banco,
          @i_carga             = 0,
          @i_fecha_liq         = @w_fecha_ini, 
          @i_prenotificacion   = 0,
          @i_renovacion        = 'N',
          @t_trn               = 7060,
          @i_nom_producto      = 'CCA',
          @i_externo           = 'N',          
          @i_desde_cartera     = 'S',         
          @o_banco_generado    = '0',
          @s_date              = @s_date,
          @s_ofi               = @s_ofi,
          @s_user              = @s_user,
          @s_term              = @s_term,
          @s_ssn               = @s_ssn,
	      @i_liq_grupal        = 'S' -- Para liquidación de cada una de la operaciones hijas
           
          if @w_error <> 0 
          begin
             goto ERROR
          end
		  
          -- se borran tablas temporales
          exec @w_error = sp_borrar_tmp
               @s_user       = @s_user,
               @s_sesn       = @s_sesn,
               @s_term       = @s_term,
               @i_desde_cre  = 'N',
               @i_banco      = @w_banco
          
          if @w_error <> 0
          begin
             goto ERROR
          end
		  
      end
	  
	  --Comprobacion de si existen desembolsos pendientes de productos de transacciones contables
	  if exists ( select 1 from cob_cartera..ca_desembolso, cob_cartera..ca_producto
                           where dm_operacion = @w_operacionca
                           and dm_producto = cp_producto
                           and cp_categoria = 'TCON'
                           and dm_pagado    = 'N')
      begin
	  
	     select  @w_num_desembolso = min(dm_desembolso)
		 from cob_cartera..ca_desembolso, cob_cartera..ca_producto
         where dm_operacion = @w_operacionca
         and dm_producto = cp_producto
         and cp_categoria = 'TCON'
         and dm_pagado    = 'N'

          while @w_num_desembolso is not null 
          begin
	  
             -- Marcar como pagado el desembolso
             exec @w_error = cob_cartera..sp_desembolso
             @i_operacion      = 'U',
             @i_opcion         = 1,
             @i_banco_real     = @w_banco,
             @i_banco_ficticio = @w_banco,
             @i_secuencial     = @w_secuencial,
	         @i_desembolso     = @w_num_desembolso,
             @i_desde_cre      = 'N',
             @i_externo        = 'N',
             @i_pagado         = 'S',
             @s_ofi            = @s_ofi,
             @s_term           = @s_term,
             @s_user           = @s_user,
             @s_date           = @s_date
             
             if @w_error <> 0 
                goto ERROR
				
		     --Recorre a la siguiente desembolso
             select @w_num_desembolso = min(dm_desembolso)
		     from cob_cartera..ca_desembolso, cob_cartera..ca_producto
             where dm_operacion = @w_operacionca
             and dm_producto = cp_producto
             and cp_categoria = 'TCON'
             and dm_pagado    = 'N'
		     and dm_desembolso > @w_num_desembolso
		  
          end
		 
      end

      --Recorre a la siguiente operacion hija 
      select @w_operacionca = min(op_operacion)
      from #op_hijas_desembolso
      where op_operacion > @w_operacionca

    end
	
	if @i_externo = 'S'
      commit tran
end


/** REVERSO DE DESEMBOLSOS DE OPERACION GRUPAL **/
if @i_operacion = 'R' 
begin
   if exists(select 1
             from ca_operacion
             where op_grupal     = 'S'
             and   op_ref_grupal = @i_banco
             and   op_estado in (0,3,99))
   begin
      /* Error, no todos los prestamos integrantes del grupo se encuentran activos */
      select @w_error = 725269 
      goto ERROR
   end
   
   -- Tabla temporal de información de desembolsos de operaciones hijas
   if exists (select 1 from sysobjects where name = '#ca_desembolsos_grupal_rev')
      drop table #ca_desembolsos_grupal_rev
      
   if @@error != 0
   begin
      /* Error al eliminar tabla temporal #ca_desembolsos_grupal_rev */
      select @w_error = 725270
      
      goto ERROR
   end
   
   create table #ca_desembolsos_grupal_rev(
      dgr_id           int      identity(1,1),
      dgr_operacion    int      not null,
      dgr_banco        cuenta   not null,
      dgr_secuencial   int      not null
   )
   
   if @@error != 0
   begin
      /* Error al crear tabla temporal #ca_desembolsos_grupal_rev */
      select @w_error = 725271
      
      goto ERROR
   end
   
   if @i_externo = 'S'
      begin tran
      
   -- Se llena tabla temporal con información de desembolsos
   insert into #ca_desembolsos_grupal_rev
   select tr_operacion, 
          tr_banco, 
          tr_secuencial 
   from ca_operacion,
        ca_transaccion
   where tr_banco      = op_banco
   and   tr_operacion  = op_operacion
   and   op_ref_grupal = @i_banco
   and   op_grupal     = 'S'
   and   tr_tran       = 'DES'
   and   tr_estado in ('ING', 'CON')
   
   if @@error != 0
   begin
      /* Error en insercion tabla #ca_desembolsos_grupal_rev */
      select @w_error  = 703138
      
      goto ERROR
   end
   
   select @w_max_registros = count(1)
   from #ca_desembolsos_grupal_rev
   
   select @w_count = 1
      
   while @w_count <= @w_max_registros
   begin
      select @w_operacionca   = dgr_operacion,
             @w_banco         = dgr_banco,
             @w_secuencial    = dgr_secuencial
      from #ca_desembolsos_grupal_rev
      where dgr_id = @w_count
      
      /* APLICAR PROCESO DE REVERSA */
      exec @w_error          = sp_fecha_valor
           @s_date           = @s_date,
           @s_ofi            = @s_ofi,
           @s_sesn           = @s_sesn,
           @s_ssn            = @s_ssn,
           @s_srv            = @s_srv,
           @s_term           = @s_term,
           @s_user           = @s_user,
           @t_trn            = 7049,
           @i_operacion      = 'R',
           @i_banco          = @w_banco,
           @i_secuencial     = @w_secuencial,
           @i_control_pinter = 'N',
           @i_observacion    = @i_observacion,
		   @i_rev_liq_grupal = 'S', --Para el reverso cada una de las operaciones hijas
		   @o_secuencial_act = @w_secuencial_act out
      
      if @w_error <> 0 
         goto ERROR
      
      select @w_count = @w_count + 1
   end -- End while
   
   if @i_externo = 'S'
      commit tran
end

return 0

ERROR:
   while @@TRANCOUNT > 0
   rollback tran

   exec cobis..sp_cerror 
   @t_debug  = 'N',    
   @t_file   = null,  
   @t_from   = @w_sp_name,   
   @i_num    = @w_error
   
   return @w_error
go
