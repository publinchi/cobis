/************************************************************************/
/*   NOMBRE LOGICO:      trascart.sp                                    */
/*   NOMBRE FISICO:      sp_traslada_cartera                            */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Julio Cesar Quintero D.                        */
/*   FECHA DE ESCRITURA: 17/Diciembre/2002                              */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                               CAMBIOS                                */
/*   FECHA     AUTOR          CAMBIO                                    */
/*   Nov-2010  Elcira Pelaez  NR-0059 traslado del valor de diferido    */
/*   Ene-2014  Luisa Bernal   REQ 00375 Traslado cupos cartera          */
/*   Oct-2021  Kevin Rodriguez Campos nuevos tabla traslados cartera    */
/*   Abr-2022  Guisela Fernandez Cambio de cierre de transaccion        */
/*   Abr-2023  Guisela Fernandez S807925 Ingreso de campo de            */
/*                               reestructuracion                       */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*   Dic-2023  Kevin Rodriguez R220437 Ajustes traslado para OP Padre   */
/************************************************************************/  

use cob_cartera
go 
if exists (select 1 from sysobjects where name = 'sp_traslada_cartera')
   drop proc sp_traslada_cartera
go
---Inc. 26929 Partiendo de la Ver. 22  jul-27-2011
create proc  sp_traslada_cartera(
   @s_user              login    = null,      
   @s_term              varchar(30)= null,
   @s_date              datetime = null,   
   @s_ofi               int      = null,
   @i_operacion         char(1)  = null,   
   @i_cliente           int      = null,   
   @i_banco             cuenta   = null,   
   @i_oficina_destino   smallint = null,
   @i_oficial_destino   smallint = null,
   @i_en_linea          char(1)  = 'S',
   @i_desde_batch       char(1)  = 'N'
)

as
declare
      @w_sp_name                varchar(32),
      @w_error                  int,
      @w_operacionca            int,
      @w_secuencial             int,
      @w_fecha_proceso          datetime,
      @w_toperacion             catalogo,
      @w_op_moneda              smallint, 
      @w_oficina_origen         int,
      @w_oficina_destino        int,
      @w_op_estado              tinyint,
      @w_cliente                int,
      @w_tipo                   char(1),
      @w_num_registros          int,
      @w_banco                  cuenta,
      @w_rowcount               int,
      @w_est_castigado          tinyint,
      @w_est_novigente          tinyint,
      @w_est_vigente            tinyint,
      @w_est_vencido            tinyint,
      @w_est_cancelado          tinyint,
      @w_est_credito            tinyint,
      @w_est_diferido           int,
      @w_est_anulado            tinyint,
      @w_oficial_origen         smallint,
      @w_oficial_destino        smallint,
      @w_saldo_cap              money,
      @w_fecha_ult_proceso      datetime,
      @w_calificacion           catalogo,
      @w_commit                 char(1),
      @w_estado_str             varchar(15),
      @w_msg                    varchar(100),
      @w_bloque                 varchar(20),
      @w_ciudad                 int,
      @w_concepto_cap           catalogo,
      @w_estacion               smallint,
      @w_op_tramite             int,   --REQ 00375 TRASLADO TRAMITES CUPO CARTERA
	  @w_reestructuracion       char(1),
	  @w_grupal                 char(1),
	  @w_ref_grupal             varchar(24),
	  @w_oper_padre             int,
	  @w_cli_op_padre           int,
	  @w_grupo                  int,
	  @w_observ_tran            char(62)

      
--- INICIAR VARIABLES DE TRABAJO 
select  
@w_sp_name       = 'sp_traslada_cartera',
@w_commit        = 'N'

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_credito    = @w_est_credito   out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_anulado    = @w_est_anulado  out

select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

---  INSERCION EN CA_TRASLADOS_CARTERA BOTON TRANSMITIR 
if @i_operacion = 'I' begin
    
   --- SELECCIONO LA CIUDAD A LA QUE PERTENECE LA OFICINA 
   select @w_ciudad = of_ciudad
   from   cobis..cl_oficina with (nolock)
   where  of_filial  = 1
   and    of_oficina = @i_oficina_destino
   
   if @@rowcount = 0  begin
      select @w_error = 710001, @w_msg = 'ERROR AL DETERMINAR LA CIUDAD A LA QUE PERTENECE LA OFICINA'
      goto ERRORFIN
   end
   
   
   declare operaciones cursor for select 
   op_operacion,                op_oficial,             op_toperacion,
   op_fecha_ult_proceso,        op_moneda,              op_banco,
   op_calificacion,             op_estado,              op_oficina,
   op_tramite,                  op_reestructuracion,    op_grupal,
   op_ref_grupal   
   from   ca_operacion  with (nolock)                                   
   where  op_cliente = @i_cliente  
   and    op_estado  <> @w_est_cancelado
   and   (op_banco   = @i_banco or @i_banco is null)
   for read only                                           
   
   open  operaciones  
                                        
   fetch operaciones into  
   @w_operacionca,               @w_oficial_origen,         @w_toperacion,
   @w_fecha_ult_proceso,         @w_op_moneda,              @w_banco,
   @w_calificacion,              @w_op_estado,              @w_oficina_origen,                                  
   @w_op_tramite,                @w_reestructuracion,       @w_grupal,
   @w_ref_grupal
   
   while @@fetch_status = 0  begin
   
      exec @w_secuencial =  sp_gen_sec
      @i_operacion       = @w_operacionca

      /* INICIO DE LA ATOMICIDAD DE LA TRANSACCION */
      if @@trancount = 0 begin
         select @w_commit = 'S'
         begin tran
      end	  
	  
      -- Definir si es cambio de Oficina 'F', o de Oficial 'O'
	  if (@w_oficina_origen <> @i_oficina_destino)
	     select @w_tipo = 'F'
	  else
	  if (@w_oficial_origen <> @i_oficial_destino)
	     select @w_tipo = 'O'
   
      --- ACTUALIZACION OFICINA TABLA BASICA 
      update ca_operacion with (rowlock) set 
      op_oficina  = @i_oficina_destino,
      op_oficial  = @i_oficial_destino
      --op_ciudad   = @w_ciudad
      where op_operacion = @w_operacionca
   
      if @@error <> 0 begin
         select @w_error = 710002, @w_msg = 'ERROR AL ACTUALIZAR LA OFICINA DE LA OPERACION EN CARTERA'
         goto ERRORFIN
      end
	  
	  -- Acciones para Operaciones grupales hija
	  if @w_grupal = 'S' and @w_ref_grupal is not null
	  begin
	  
	     -- Traslada OP Padre si esta aun no se ha trasladado
	     select @w_oper_padre   = trc_operacion,
		        @w_cli_op_padre = trc_cliente,
				@w_grupo        = op_grupo
         from ca_traslados_cartera with (nolock), 
              ca_operacion with (nolock)
         where op_banco        = @w_ref_grupal 
         and op_operacion      = trc_operacion
         and trc_estado        = 'I'
         and trc_fecha_proceso = @w_fecha_proceso
					
	     if @@rowcount > 0
         begin
		 
            --- ACTUALIZACION OFICINA, OFICIAL OPERACIÓN PADRE
            update ca_operacion with (rowlock) 
			set  op_oficina  = @i_oficina_destino,
                 op_oficial  = @i_oficial_destino,
                 op_ciudad   = @w_ciudad
            where op_operacion = @w_oper_padre
            
            if @@error <> 0 
			begin
               select @w_error = 710002, 
			          @w_msg = 'ERROR AL ACTUALIZAR LA OFICINA DE LA OPERACION PADRE EN CARTERA: '+@w_ref_grupal 
               goto ERRORFIN
            end
			
			-- Marcar como procesado el Traslado
            update ca_traslados_cartera with (rowlock) 
			set trc_estado = 'P'
	        where trc_operacion = @w_oper_padre
	        and trc_fecha_proceso = @w_fecha_proceso
			
            if @@error <> 0 
			begin
               select @w_error = 710002, 
			          @w_msg = 'ERROR AL ACTUALIZAR ESTADO DE TRASLADO OFI DE OPERACION PADRE: '+ @w_ref_grupal 
               goto ERRORFIN
            end
			
			-- Actualiza oficial de cliente de operacion Padre (Presidente grupo)
            update cobis..cl_ente with (rowlock)
            set en_oficial = @i_oficial_destino
            where en_ente = @w_cli_op_padre
            
            if @@error <> 0 
            begin
               select @w_error = 725309, -- Error en actualizacion de cliente
                      @w_msg = 'ERROR AL ACTUALIZAR OFICIAL DE CLIENTE: '+ @w_cli_op_padre + ' DEL PRÉSTAMO: ' +@w_ref_grupal
               goto ERRORFIN
            end
			
            -- Actualiza oficial de grupo de operacion grupal
            update cobis..cl_grupo with (rowlock)
            set gr_oficial = @i_oficial_destino
            where gr_grupo = @w_grupo
            
            if @@error <> 0 
            begin
               select @w_error = 725312, -- Error en actualizacion de grupo
                      @w_msg = 'ERROR AL ACTUALIZAR OFICIAL DE GRUPO: '+ @w_grupo + ' DEL PRÉSTAMO: ' +@w_ref_grupal
               goto ERRORFIN
            end
		 
		 end
		 
         /*-- Traslada OPs Hijas canceladas (Hermanas), relacionadas al mismo Padre grupal, si estas aun no se han trasladado
		 -- y actualiza oficial de los clientes.
	     if exists (select 1
                    from ca_traslados_cartera with (nolock), 
                         ca_operacion with (nolock)
                    where op_ref_grupal   = @w_ref_grupal 
					and op_estado         = @w_est_cancelado
                    and op_operacion      = trc_operacion
                    and trc_estado        = 'I'
                    and trc_fecha_proceso = @w_fecha_proceso)
         begin
		 
            --- ACTUALIZACION OFICINA, OFICIAL OPs Hijas canceladas (Hermanas), relacionadas al mismo Padre gruapal
            update ca_operacion with (rowlock) 
			set  op_oficina  = @i_oficina_destino,
                 op_oficial  = @i_oficial_destino,
                 op_ciudad   = @w_ciudad
		    from ca_traslados_cartera with (nolock)
            where op_ref_grupal   = @w_ref_grupal
			and op_estado         = @w_est_cancelado
			and op_operacion      = trc_operacion
            and trc_estado        = 'I'
            and trc_fecha_proceso = @w_fecha_proceso
            
            if @@error <> 0 
			begin
               select @w_error = 710002, 
			          @w_msg = 'ERROR AL ACTUALIZAR LA OFICINA DE OPERACIONES HIJAS CANCELADAS EN CARTERA DE OP PADRE: '+@w_ref_grupal 
               goto ERRORFIN
            end
		 
            update ca_traslados_cartera with (rowlock) 
            set trc_estado = 'P'			
            from ca_operacion with (nolock)
            where op_ref_grupal   = @w_ref_grupal
            and op_estado         = @w_est_cancelado			
            and op_operacion      = trc_operacion
            and trc_estado        = 'I'
            and trc_fecha_proceso = @w_fecha_proceso
			
            if @@error <> 0 
			begin
               select @w_error = 710002, 
			          @w_msg = 'ERROR AL ACTUALIZAR ESTADO DE TRASLADO OFI DE OPERACIONES HIJAS CANCELADAS DE OP PADRE: '+ @w_ref_grupal 
               goto ERRORFIN
            end
			
			if @w_tipo = 'O' VERIFICAR
			begin
               update cobis..cl_ente with (rowlock)
		       set en_oficial = @i_oficial_destino
		       from ca_traslados_cartera with (nolock), 
			        ca_operacion with (nolock)
               where op_ref_grupal   = @w_ref_grupal
               and op_cliente        = en_ente
			   and op_estado         = @w_est_cancelado
			   and op_operacion      = trc_operacion
               and trc_estado        = 'I'
               and trc_fecha_proceso = @w_fecha_proceso
		       
               if @@error <> 0 
               begin
                  select @w_error = 725309, -- Error en actualizacion de cliente
                         @w_msg = 'ERROR AL ACTUALIZAR OFICIAL DE CLIENTE: '+ @i_cliente + ' DEL PRÉSTAMO: ' +@w_banco 
                  goto ERRORFIN
               end
			   
			end
		 
		 end*/
	  
	  end
 
      /* TRASLADO DE OFICINA HAY CONTABILIDAD POR LO CUAL GENERA CABECERA Y DETALLE DE TRANSACCION */
	  /* TRASLADO DE OFICIAL NO HAY CONTABILIDAD POR LO CUAL GENERA SOLO CABECERA DE TRANSACCION */
      if  @w_tipo in ('F', 'O')
      and @w_op_estado in (@w_est_vigente, @w_est_vencido, @w_est_castigado)
      begin
	  
	     if @w_tipo = 'F'
		 begin
		    if @w_oficial_origen <> @i_oficial_destino
		       select @w_observ_tran = 'TRASLADO DE OFICINA Y OFICIAL'
			else
			   select @w_observ_tran = 'TRASLADO DE OFICINA'
		 end
         else
		    select @w_observ_tran = 'TRASLADO DE OFICIAL'
             
         insert into ca_transaccion(
         tr_secuencial,          tr_fecha_mov,                   tr_toperacion,
         tr_moneda,              tr_operacion,                   tr_tran,
         tr_en_linea,            tr_banco,                       tr_dias_calc,
         tr_ofi_oper,            tr_ofi_usu,                     tr_usuario,
         tr_terminal,            tr_fecha_ref,                   tr_secuencial_ref,
         tr_estado,              tr_observacion,                 tr_gerente,
         tr_gar_admisible,       tr_reestructuracion,            tr_calificacion,
         tr_fecha_cont,          tr_comprobante)  
         values(  
         @w_secuencial,          @w_fecha_proceso,               @w_toperacion,
         @w_op_moneda,           @w_operacionca,                 'TCO',
         @i_en_linea,            @w_banco,                       0,
         @w_oficina_origen,      @w_oficina_origen,              @s_user,
         @s_term,                @w_fecha_ult_proceso,           0,
         'ING',                  @w_observ_tran,                 @w_oficial_origen,
         '',                     @w_reestructuracion,            isnull(@w_calificacion,''),
         '',                     0)
     
         if @@error <> 0  begin
            select @w_error = 708165, @w_msg = 'ERROR AL REGISTRAR LA TRANSACCION DE TRASLADO DE LA OPERACION: ' + @w_banco
            goto ERRORFIN
         end
        
		 if @w_tipo = 'F' -- Solo traslado de oficina genera detalle de transacción
		 begin
		 
            --- REGISTRAR VALORES QUE SALEN DE LA OFICINA ORIGEN 
            insert into ca_det_trn(
            dtr_secuencial   ,                   dtr_operacion ,       dtr_dividendo    ,
            dtr_concepto     ,                   dtr_periodo   ,       dtr_estado       ,
            dtr_monto        ,                   dtr_monto_mn  ,       dtr_codvalor     ,
            dtr_moneda       ,                   dtr_cotizacion,       dtr_tcotizacion  ,
            dtr_cuenta       ,                   dtr_afectacion,       dtr_beneficiario ,
            dtr_monto_cont)
            select 
            @w_secuencial,                       @w_operacionca,       am_dividendo,
            am_concepto,                         0,                    case am_estado when @w_est_novigente then @w_op_estado else am_estado end,
            -1*sum(am_acumulado-am_pagado),      0,                    co_codigo * 1000 + case am_estado when @w_est_novigente then @w_op_estado else am_estado end * 10,
            @w_op_moneda,                        1,                    'N',
            convert(varchar,@w_oficina_origen),  'D',                  '',
            0
            from ca_amortizacion, ca_concepto 
            where am_operacion = @w_operacionca
            and   am_estado   <> @w_est_cancelado
            and   co_concepto  = am_concepto
            group by am_dividendo, 
                     am_concepto, 
                     case am_estado when @w_est_novigente then @w_op_estado else am_estado end,  
                     co_codigo * 1000 + case am_estado when @w_est_novigente then @w_op_estado else am_estado end * 10
            having sum(am_acumulado - am_pagado) > 0
		    
            if @@error <> 0  begin
               select @w_error = 708165, @w_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA: ' + @w_banco
               goto ERRORFIN
            end
   
            --- REGISTRAR VALORES QUE SALEN DE LA OFICINA ORIGEN 
            insert into ca_det_trn(
            dtr_secuencial   ,                dtr_operacion ,       dtr_dividendo    ,
            dtr_concepto     ,                dtr_periodo   ,       dtr_estado       ,
            dtr_monto        ,                dtr_monto_mn  ,       dtr_codvalor     ,
            dtr_moneda       ,                dtr_cotizacion,       dtr_tcotizacion  ,
            dtr_cuenta       ,                dtr_afectacion,       dtr_beneficiario ,
            dtr_monto_cont)
            select 
            @w_secuencial,                    @w_operacionca,       am_dividendo,
            am_concepto,                      0,                    case am_estado when @w_est_novigente then @w_op_estado else am_estado end,
            sum(am_acumulado-am_pagado),      0,                    co_codigo * 1000 + case am_estado when @w_est_novigente then @w_op_estado else am_estado end * 10,
            @w_op_moneda,                     1,                   'N',
            convert(varchar,@i_oficina_destino), 'D',              '',
            0
            from ca_amortizacion with (nolock) , ca_concepto 
            where am_operacion = @w_operacionca
            and   am_estado   <> @w_est_cancelado
            and   co_concepto  = am_concepto
            group by am_dividendo, 
                     am_concepto, 
                     case am_estado when @w_est_novigente then @w_op_estado else am_estado end,  
                     co_codigo * 1000 + case am_estado when @w_est_novigente then @w_op_estado else am_estado end * 10
            having sum(am_acumulado - am_pagado) > 0
		    
            if @@error <> 0  begin
               select @w_error = 708165, @w_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA: ' + @w_banco
               goto ERRORFIN
            end
			
		 end
		 
		 update ca_traslados_cartera with (rowlock) set
	     trc_secuencial_trn  = @w_secuencial
	     where trc_operacion = @w_operacionca
	     and trc_fecha_proceso = @w_fecha_proceso
		 
         if @@error <> 0 
         begin
            select @w_error = 710002, 
                   @w_msg = 'ERROR AL ACTUALIZAR SECUENCIAL DE TRASLADO OFI DE OPERACION: '+ @w_banco 
            goto ERRORFIN
         end
		 
	  end
	  
	  ACTUALIZA:
      --GFP 29-Abr-2022 Actualización de estado a procesado  
	  if (@i_desde_batch = 'S')
	  begin
	     update ca_traslados_cartera with (rowlock) set
	     trc_estado          = 'P'
	     where trc_operacion = @w_operacionca
	     and trc_fecha_proceso = @w_fecha_proceso
		 
         if @@error <> 0 
         begin
            select @w_error = 710002, 
                   @w_msg = 'ERROR AL ACTUALIZAR ESTADO DE TRASLADO OFI DE OPERACION: '+ @w_banco 
            goto ERRORFIN
         end
		 
		 update cobis..cl_ente with (rowlock)
		 set en_oficial = @i_oficial_destino
		 where en_ente = @i_cliente
		 
         if @@error <> 0 
         begin
            select @w_error = 725309, -- Error en actualizacion de cliente
                   @w_msg = 'ERROR AL ACTUALIZAR OFICIAL DE CLIENTE: '+ @i_cliente + ' DEL PRÉSTAMO: ' +@w_banco 
            goto ERRORFIN
         end
		 
	  end
	  else
	  begin
	     insert into ca_traslados_cartera (
	     trc_fecha_proceso,          trc_cliente,          trc_operacion,            trc_user,
	     trc_oficina_origen,         trc_oficina_destino,  trc_estado,               trc_garantias,
	     trc_credito,                trc_sidac,            trc_fecha_ingreso,        trc_secuencial_trn,
	     trc_oficial_origen,         trc_oficial_destino,  trc_saldo_capital,        trc_term,
	  	trc_fecha_real)
	     values(
	     @w_fecha_proceso,           @i_cliente,           @w_operacionca,           @s_user,
	     @w_oficina_origen,          @i_oficina_destino,   'P',                      'N',
	     'N',		                'N',                  getdate(),                @w_secuencial,
	     @w_oficial_origen,          @i_oficial_destino,   0,                        isnull(@s_term, ''),
	  	getdate())
	     
	     if @@error <> 0
	     begin
	       select @w_error = 710001, @w_msg = 'ERROR AL REGISTRAR TRASLADO DE OFICINA: ' + @w_banco
             goto ERRORFIN
	     end
	     
	  end
	  --GFP 29-Abr-2022 Cambio de cierre de transacción 
	  if @w_commit = 'S' begin
         commit tran
         select @w_commit = 'N'
      end
	
    SIGUIENTE:
	
	fetch operaciones  into  
	@w_operacionca,                   @w_oficial_origen,              @w_toperacion,
	@w_fecha_ult_proceso,             @w_op_moneda,                   @w_banco,
	@w_calificacion,                  @w_op_estado,                   @w_oficina_origen,
	@w_op_tramite,                    @w_reestructuracion,            @w_grupal,
    @w_ref_grupal
	
   end  -- WHILE CURSOR PRINCIPAL OPERACIONES 

   close operaciones          
   deallocate operaciones   
   
end --Operacion I

return 0

ERRORFIN:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

if @i_en_linea  = 'S' begin

   exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error,
   @i_msg    = @w_msg
   
end else begin

   exec sp_errorlog 
   @i_fecha     = @s_date,
   @i_error     = @w_error, 
   @i_usuario   = @s_user, 
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = 'GENERAL',
   @i_rollback  = 'N',
   @i_descripcion= @w_msg
   
end

return @w_error

go
