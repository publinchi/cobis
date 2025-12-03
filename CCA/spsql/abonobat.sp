/************************************************************************/
/*   NOMBRE LOGICO:      abonobat.sp                                    */
/*   NOMBRE FISICO:      sp_abonos_batch                                */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Credito y Cartera                              */
/*   DISENADO POR:       Fabian de la Torre                             */
/*   FECHA DE ESCRITURA: Ene. 98.                                       */
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
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/  
/*                      PROPOSITO                                       */
/*  Procedimiento que realiza la Aplicacion de Abonos Automaticos       */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA        AUTOR           RAZON                              */
/*      24/07/2019   Sandro Vallejo  Pago Grupal e Interciclos          */
/*      26/07/2019   Luis Ponce      Modificacion Pago Grupal           */
/*      16/12/2019   Luis Ponce      Control Fondos Insuficientes       */
/*      01/06/2022   Guisela Fernandez  Se comenta prints               */
/*      15/08/2023   Kevin Rodríguez R214639 No aplicar pagos anteriores*/
/*                                   a la Migración                     */
/*      13/09/2023   Guisela Fernandez R215286 Cambia validación de Mig.*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abonos_batch')
    drop proc sp_abonos_batch
go
----Inc.39517 partiendo de la version 7 dic.11.2011
create proc sp_abonos_batch
   @s_sesn                  int      = NULL,   
   @s_user      	        login    = NULL,
   @s_term      	        varchar(30),
   @s_date      	        datetime,
   @s_ofi       	        smallint,
   @i_en_linea              char(1),
   @i_fecha_proceso         datetime,
   @i_operacionca           int,
   @i_banco                 cuenta,
   @i_pry_pago              char(1)  = 'N',
   @i_cotizacion            money,
   @i_secuencial_ing        int = 0

as declare 
   @w_error                 int,
   @w_return                int,
   @w_sp_name               descripcion,
   @w_ab_secuencial_ing     int,
   @w_ab_dias_retencion     int,
   @w_ab_estado             catalogo,
   @w_commit                char(1),
   @w_fecha_pag             datetime,
   @w_categoria             catalogo,
   @w_op_estado_cobranza    catalogo,    -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_toperacion            catalogo,    -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_moneda_op             tinyint,     -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_abd_monto_mop         money,       -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_abd_tipo              catalogo,    -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_est_cobro_juridico    catalogo,    -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_est_cobro_prejuridico catalogo,    -- 14/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
   @w_tipo_grupal           char(1),
   @w_cuota_completa        char(1),
   @w_monto_pago            money,
   @w_abd_concepto          catalogo,
   @w_cp_categoria          catalogo,
   @w_abd_cuenta            cuenta,
   @w_pcobis                tinyint,
   @w_saldo_disponible      MONEY,
   @w_saldo_contable        MONEY,
   @w_ah_cuenta             INT,
   @w_tran_mig              int,
   @s_ssn                   INT
   
/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name = 'sp_abonos_batch',
@w_commit  = 'N'   

select @w_est_cobro_juridico = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ESTJUR'
and   pa_producto = 'CRE'

select @w_est_cobro_prejuridico = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ESTCPR'
and   pa_producto = 'CRE'  


/* DETERMINAR SI LA OPERACION CORRESPONDE A INTERCICLO - GRUPAL - INDIVIDUAL */
exec @w_error = sp_tipo_operacion
     @i_banco = @i_banco,
     @o_tipo  = @w_tipo_grupal out

if @w_error <> 0 goto ERROR

/* SI LA OPERACION ES INTERCICLO _ FINALIZAR */
if @w_tipo_grupal = 'I' --LPO TEC Pagos Grupales
   return 0

-- Secuencial de transacción de Migración
select @w_tran_mig = tr_secuencial 
from ca_transaccion with (nolock)
where tr_operacion = @i_operacionca
and tr_tran = 'MIG'
and tr_estado <> 'RV'

if @i_secuencial_ing  = 0
begin
	declare  cursor_abonos cursor for
	select ab_secuencial_ing, ab_dias_retencion, ab_estado, ab_cuota_completa
	from   ca_abono with (nolock)
	where  ab_operacion  = @i_operacionca
	and    ab_fecha_pag = @i_fecha_proceso
	and    ab_estado   in ('ING','P', 'NA')
	order by ab_fecha_ing, ab_secuencial_ing
	for read only
end
ELSE ---Los pagos masivos son puntuales yenvian su secuencial
begin
	declare  cursor_abonos cursor for
	select ab_secuencial_ing, ab_dias_retencion, ab_estado, ab_cuota_completa
	from   ca_abono with (nolock)
	where  ab_operacion  = @i_operacionca
	and    ab_secuencial_ing = @i_secuencial_ing
	and    ab_estado   in ('ING','P', 'NA')
	for read only
end
open    cursor_abonos

fetch   cursor_abonos into
@w_ab_secuencial_ing, @w_ab_dias_retencion, @w_ab_estado, @w_cuota_completa

while   @@fetch_status = 0 begin /*WHILE CURSOR PRINCIPAL*/

   if (@@fetch_status = -1) begin
      select @w_error = 708999
      goto ERROR
   end

   select @w_error = 0
   
   if @w_ab_secuencial_ing < @w_tran_mig -- KDR Pagos No aplicados antes de la Migración no se aplican
   goto SIGUIENTE

   if @i_pry_pago = 'N' and @@trancount = 0 begin
      begin tran --atomicidad por abono
      select @w_commit = 'S'
   END
   
   --LPO TEC PAGO DE OP.GRUPAL Y SUS INTERCICLOS
   /* SI LA OPERACION ES GRUPAL - DETERMINAR SALDO Y APLICAR PAGO */
   if @w_tipo_grupal = 'G' and @w_cuota_completa = 'S'
   BEGIN      
      
      /* DETERMINAR EL DETALLE DEL ABONO */
      select @w_abd_concepto = abd_concepto,
             @w_abd_cuenta   = isnull(abd_cuenta,'')
      from   ca_abono_det
      where  abd_secuencial_ing = @w_ab_secuencial_ing --@i_secuencial_ing --LPO TEC
      and    abd_operacion      = @i_operacionca
      and   (abd_tipo = 'PAG' or abd_tipo = 'CON')

      if @@rowcount = 0 
      begin
         select @w_error = 701119
         goto ERROR
      end
      
      /* DETERMINAR SI LA FORMA DE PAGO ES AUTOMATICA */
      if not exists (select 1 from ca_concepto where co_concepto = @w_abd_concepto)
      begin
         select @w_cp_categoria = cp_categoria,
                @w_pcobis       = isnull(cp_pcobis,0)
         from   ca_producto
         where  cp_producto = @w_abd_concepto 

         if @@rowcount = 0 
         begin
            select @w_error = 701119
            goto ERROR
         end
      end
      
      /* SI CORRESPONDE A DEBITOS AUTOMATICOS */
      if @w_cp_categoria in ('NDAH','NDCC')  
      begin 
         select @w_saldo_disponible = 0
         
         /* DETERMINAR EL SALDO DE DEUDA */
         exec @w_error       = sp_montos_pago_grupal
         @i_banco            = @i_banco,
         @i_batch            = 'S',
         @o_monto_cuota      = @w_monto_pago OUT
                  
         if @w_error <> 0
         begin 
            goto ERROR
         end 
                 
         /* SI NO HAY SALDO POR PAGAR - SALIR */
         if @w_monto_pago <= 0
         begin
            if @w_commit = 'S' commit TRAN
            close cursor_abonos
            deallocate cursor_abonos                        
            return 0
         end
            
         /* DETERMINAR EL SALDO EN LA CUENTA */
         /* SI ES CTA CORRIENTE */
         if @w_pcobis = 3
         begin
            exec @w_error  = cob_interface..sp_calcula_sin_impuesto
            @s_ofi         = @s_ofi,                  ---OFICINA QUE EJECUTA LA CONSULTA
            @i_pit         = 'S',                     ---INDICADOR PARA NO REALIZAR ROLLBACK
            @i_cta_banco   = @w_abd_cuenta,           ---NUMERO DE CUENTA
            @i_tipo_cta    = 3,                       ---PRODUCTO DE LA CUENTA
            @i_fecha       = @s_date,                 ---FECHA DE LA CONSULTA
            @i_causa       = '310',                   ---CAUSA DE DEBITO (para verificar si cobra IVA)
            @o_valor       = @w_saldo_disponible out  ---VALOR PARA REALIZAR LA ND

            if @w_error <> 0 
            begin 
               goto ERROR
            end   
         end
         
         /* SI ES CTA DE AHORROS */
         if @w_pcobis = 4
         BEGIN
            select @w_ah_cuenta = ah_cuenta --LPO TEC
            from cob_ahorros..ah_cuenta
            where ah_cta_banco = @w_abd_cuenta
            
            exec @w_error       = cob_interface..sp_ahcalcula_saldo
            @i_cuenta           = @w_ah_cuenta,  --@w_abd_cuenta, --LPO TEC
            @i_fecha            = @s_date,
            @o_saldo_para_girar = @w_saldo_disponible OUT,
            @o_saldo_contable   = @w_saldo_contable   OUT --LPO TEC
                       
            if @w_error <> 0 
            begin 
               IF @w_error <> 251033 --LPO TEC Fondos Insuficientes, Ahorros devuelve como error cuando la cuenta no tiene saldo disponible, se controla que
                  goto ERROR         --cuando se trate de este caso no se lo tome como un error ya que en Ahorros cambiar el sp podria generar impacto en varias funcionalidades.
            end
         end
          
         /* SI NO HAY DISPONIBLE EN LA CUENTA - SALIR */ --LPO TEC
         if @w_saldo_disponible <= 0
         begin
            if @w_commit = 'S' commit tran
            close cursor_abonos
            deallocate cursor_abonos            
            return 0
         end
         
         /* SI EL SALDO EN LA CUENTA ES MENOR A LA DEUDA APLICAR LO DISPONIBLE EN LA CUENTA */
         if @w_saldo_disponible < @w_monto_pago
            select @w_monto_pago = @w_saldo_disponible
                  
         /* PROCESAR EL PAGO */
         select @w_moneda_op = op_moneda
         from   ca_operacion
         where  op_operacion = @i_operacionca
         
         
         /* LPO TEC PAGOS GRUPALES, BORRAR EL ABONO CREADO PREVIAMENTE EN sp_genera_afect_productos PORQUE EL PROCESO DE PAGOS GRUPALES*/
         /* VA A CREAR SU PROPIO ABONO EN EL sp_pago_cartera */
         
         delete ca_abono_det
         from   ca_abono
         where  abd_operacion     = @i_operacionca
         and    ab_operacion      = abd_operacion
         and    ab_secuencial_ing = abd_secuencial_ing
         and    ab_fecha_pag      = @i_fecha_proceso
         and    ab_estado         in ('ING','P', 'NA')
         and    ab_secuencial_rpa = 0
         and    ab_secuencial_pag = 0
         and    ab_cuota_completa = 'S'
         
         if @@error <> 0 begin
            select @w_error = 710002
            goto ERROR
         end

         delete ca_abono
         where  ab_operacion      = @i_operacionca
         and    ab_fecha_pag      = @i_fecha_proceso
         and    ab_estado         in ('ING','P', 'NA')
         and    ab_secuencial_rpa = 0
         and    ab_secuencial_pag = 0
         and    ab_cuota_completa = 'S'
         
         if @@error <> 0 begin
            select @w_error = 710002
            goto ERROR
         end
         
         exec @s_ssn = ADMIN...rp_ssn   --LPO TEC sp_prorratea_pago_grupal necesita el @s_ssn
                  
         exec @w_error   = sp_prorratea_pago_grupal
         @s_ssn          = @s_ssn, --LPO TEC
         @s_user         = @s_user,
         @s_term         = @s_term,
         @s_date         = @s_date,
         @s_sesn         = @s_sesn,
         @s_ofi          = @s_ofi,
         @i_banco        = @i_banco,
         @i_monto_pago   = @w_monto_pago,
         @i_forma_pago   = @w_abd_concepto,
         @i_referencia   = @w_abd_cuenta,
         @i_moneda_pago  = @w_moneda_op,
         @i_fecha_pago   = @i_fecha_proceso,
         @i_beneficiario = 'DEBITO AUTOMATICO PAGO GRUPAL'

         if @w_error <> 0 
         begin
            goto ERROR
         end
         
         /* ATOMICIDAD DE LA TRANSACCION */
         if @w_commit = 'S' 
            commit tran
         
         /* FINALIZAR */
         close cursor_abonos
         deallocate cursor_abonos
         return 0
      end
   end
   --LPO TEC FIN PAGO DE OP.GRUPAL Y SUS INTERCICLOS
   
   if @w_ab_estado in ('ING','P') begin
      
      exec @w_return =  sp_registro_abono
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_ofi             = @s_ofi,
      @i_secuencial_ing  = @w_ab_secuencial_ing,
      @i_en_linea        = @i_en_linea,
      @i_operacionca     = @i_operacionca,
      @i_fecha_proceso   = @i_fecha_proceso,
      @i_cotizacion      = @i_cotizacion

      if @w_return <> 0 begin
         select @w_error = @w_return
         goto ERROR
      end

   end
   
   if @w_ab_estado = 'NA' begin   
      select       
      @w_op_estado_cobranza = op_estado_cobranza,
      @w_toperacion         = op_toperacion,
      @w_moneda_op          = op_moneda
      from ca_operacion
      where op_operacion = @i_operacionca
      
      -- LECTURA DETALLE DE ABONO
      select
      @w_abd_monto_mop = abd_monto_mop,
      @w_abd_tipo      = abd_tipo
      from ca_abono_det
      where abd_secuencial_ing = @w_ab_secuencial_ing
      and   abd_operacion      = @i_operacionca
      and   (abd_tipo = 'PAG' or abd_tipo = 'CON')
      order by abd_tipo
      
      /* VERIFICA SI DEBE COBRAR HONORARIOS DE ABOGADO - OTROS CARGOS */
      if  @w_op_estado_cobranza in (@w_est_cobro_juridico, @w_est_cobro_prejuridico) and @w_abd_tipo <> 'CON'
      begin
         exec @w_return = sp_calculo_honabo
         @s_user            = @s_user,           --Usuario de conexion
         @s_ofi             = @s_ofi,            --Oficina del pago (si es por front es la de conexion)
         @s_term            = @s_term,           --Terminal de operacion
         @s_date            = @s_date,           --ba_fecha_proceso
         @i_operacionca     = @i_operacionca,    --op_operacion de la operacion
         @i_toperacion      = @w_toperacion,     --op_toperacion de la operacion
         @i_moneda          = @w_moneda_op,      --op_moneda de la operacion
         @i_monto_mpg       = @w_abd_monto_mop   --Monto del pago que sera utilizado para el calculo de honabo
         
         if @w_return ! = 0 
         begin 
            close cursor_abonos
            deallocate cursor_abonos                              
            return @w_return
         end   
      end     
   end   
   
   if @w_ab_dias_retencion > 0 begin

      update ca_abono with (rowlock) set
      ab_dias_retencion = ab_dias_retencion - 1
      where ab_secuencial_ing = @w_ab_secuencial_ing
      and   ab_operacion      = @i_operacionca  --MPO06/10/2001

      if @@error <> 0 begin
         select @w_error = 710002
         goto ERROR
      end

   end

   /* APLICACION DEL PAGO */
   if @w_ab_dias_retencion <= 0
   begin

      exec @w_return = sp_cartera_abono
      @s_sesn           = @s_sesn,
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @i_secuencial_ing = @w_ab_secuencial_ing,
      @i_en_linea       = @i_en_linea,
      @i_operacionca    = @i_operacionca,
      @i_fecha_proceso  = @i_fecha_proceso,
      @i_cotizacion      = @i_cotizacion

      if @w_return <> 0 begin
         select @w_error = @w_return
         goto ERROR
      end 

   end

   if @w_commit = 'S' begin 
      commit tran
      select @w_commit = 'N'
   end
   
   goto SIGUIENTE    

   ERROR:
   if @w_commit = 'S' begin
      rollback tran
      select @w_commit = 'N'
   end
   
   if @i_en_linea = 'S' 
      exec cobis..sp_cerror 
      @t_debug='N',
      @t_file=null,
      @t_from=@w_sp_name,  
      @i_num = @w_error
      
   else begin

      exec sp_errorlog 
      @i_fecha     = @s_date,
      @i_error     = @w_error,
      @i_usuario   = @s_user,
      @i_tran      = @w_ab_secuencial_ing,
      @i_tran_name = @w_sp_name,
      @i_cuenta    = @i_banco,
      @i_rollback  = 'S'
      
   end

   SIGUIENTE:

   fetch   cursor_abonos into
   @w_ab_secuencial_ing, @w_ab_dias_retencion, @w_ab_estado, @w_cuota_completa

end /*WHILE CURSOR RUBROS*/

close cursor_abonos
deallocate cursor_abonos

return 0

go
