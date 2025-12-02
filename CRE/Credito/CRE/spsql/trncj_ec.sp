/************************************************************************/
/*  Archivo:                trncj_ec.sp                                 */
/*  Stored procedure:       sp_trncj_ec                                 */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_trncj_ec' and type = 'P')
   drop proc sp_trncj_ec
go


create proc sp_trncj_ec (
      @t_trn             smallint    = null,
      @t_debug           char(1)     = 'N',
      @t_file            varchar(14) = null,
      @t_from            varchar(30) = null,
      @s_date            datetime    = null,
      @s_user            login       = null,
      @i_operacion       char(1)     = null,
      @i_tramite         int         = null,
      @i_fecha_proc      datetime    = null,
      /* campos cca 353 alianzas bancamia --AAMG*/
      @i_crea_ext        char(1)     = null,
      @o_msg_msv         varchar(255)= null out
)
as

declare 
   @w_error                int,
   @w_sp_name              varchar (50),
   @w_msg                  varchar(100),
   @w_commit               char(1),
   @w_num_orden            int,     --Numero Orden generada desde Cajas
   @w_return               int,     --Valor que retorna
   @w_parametro_apecr      catalogo,
   @w_ro_porcentaje        money,
   @w_orden                int,
   @w_migrado              varchar(16),
   @w_tipo                 catalogo,
   @w_cliente              int,
   @w_referencial          catalogo,
   @w_trn_cajas            char(1), --Variable para controlar el bloqueo del Cobro en FrontEnd
   @w_banca                varchar(10),
   @w_ruta                 tinyint,
   @w_etapa                tinyint,
   @w_porcentaje_apecr     float,
   @w_num_dec              tinyint,
   @w_moneda_local         tinyint,
   @w_num_dec_mn           tinyint,
   @w_moneda_n             tinyint
   
   
select @w_sp_name = 'sp_trncj_ec '
select @w_commit  = 'N'

-----------------------------
--Código de Transaccion
-----------------------------

if (@t_trn <> 22232)
begin
   if @i_crea_ext is null
   begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101006
      return 1
   end
   else
   begin
      select @o_msg_msv = 'Tipo de transaccion no corresponde, ' + @w_sp_name
      select @w_return  = 2101006
      return @w_return
   end
end

-----------------------------------------------------------------
--Lectura del Parametro General para Comision Estudio Crediticio
-----------------------------------------------------------------

select @w_parametro_apecr = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'APECR'

select @w_migrado = tr_migrado,
       @w_tipo    = tr_tipo,
       @w_cliente = tr_cliente,
       @w_banca   = tr_sector,
       @w_ruta    = tr_truta
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

select @w_etapa = pa_etapa
from cr_pasos, cr_etapa, cr_truta
where pa_truta = ru_truta
and   et_etapa = pa_etapa
and   et_tipo  = 'I'
and   ru_truta = @w_ruta


if @w_tipo in ('O','R')
   begin
     select @w_referencial = ro_referencial
     from cob_cartera..ca_operacion, cob_cartera..ca_rubro_op
     where ro_operacion = op_operacion
     and op_tramite     = @i_tramite
     and ro_concepto    = @w_parametro_apecr
  
     select @w_ro_porcentaje = convert (money,vd_valor_default )
           from cob_cartera..ca_valor_det
           where vd_tipo   = @w_referencial
    end
-----------------------------------------------------------------
--En cupos se lee el valor de la comision directamente de Cartera
-----------------------------------------------------------------
if @w_tipo = 'C'
begin
   select @w_ro_porcentaje = convert (money,vd_valor_default )
   from cob_cartera..ca_valor_det
   where vd_tipo   = @w_parametro_apecr
end

------------------------------------------------------------------
-- Si es un tramite de alianza se verifica si se tiene porcentaje 
-- de axoneracion de cobro de estudio de credito. Si tiene  
-- exoneracion de descuenta el porcentaje del valor inicial.
------------------------------------------------------------------
if @w_tipo in ( 'O', 'R', 'C' )
begin  
  
   -- Apertura de crédito por Alianza
   select @w_porcentaje_apecr = 0
   select @w_porcentaje_apecr = al_porcentaje_exonera
   from cobis..cl_alianza, cob_credito..cr_tramite 
   where al_exonera_estudio = 'S'
   and   al_alianza = tr_alianza
   and   tr_tramite = @i_tramite
      
   if isnull(@w_porcentaje_apecr,0) > 0 and isnull(@w_ro_porcentaje,0) > 0 
   begin
      -- Moneda local
      select @w_moneda_n = pa_tinyint
      from   cobis..cl_parametro
      where  pa_producto = 'ADM'
      and    pa_nemonico = 'MLO'
   
      ---MANEJO DE DECIMALES
      exec @w_return = cob_cartera..sp_decimales   -- 
      @i_moneda       = @w_moneda_n,
      @o_decimales    = @w_num_dec      out,
      @o_mon_nacional = @w_moneda_local out,
      @o_dec_nacional = @w_num_dec_mn   out

      if @w_return <> 0  
         return @w_return  
         
      select @w_ro_porcentaje = @w_ro_porcentaje - round((@w_ro_porcentaje * @w_porcentaje_apecr / 100), @w_num_dec ) 
   end
end

--------------------------------------------------------------------------------------------------
--Operacion 'I'--> Inserta la transaccion de Cobro por Estudio Crediticio al Cliente Causal 018
--------------------------------------------------------------------------------------------------

if @i_operacion = 'I'   
   begin  
      if @w_ro_porcentaje is null
         return 0
      if @w_tipo in ('O','R','C') and  @w_migrado is null          
         begin  
            select @w_trn_cajas = 'S'
            if exists (select 1 from cob_credito..cr_tramite_cajas where tc_tramite = @i_tramite and tc_causa = '018' and tc_estado in ('I','E') and tc_pago_cobro = 'C')
            begin
               if @i_crea_ext is null
                  select @w_trn_cajas
            end
            else
               begin 
                  
                  -- REQ 173 - VALIDAMOS EXISTENCIA DE VALIDACION POR RUTA, ETAPA, BANCA
                  if exists (select 1 from cob_credito..cr_regla 
                             where re_truta = @w_ruta and re_etapa = @w_etapa and re_banca = @w_banca and re_programa = 'SP_BANCA_TRNCJ_EC' )
                  begin
                     begin tran
                        select @w_commit  = 'S'
                        exec @w_return    = cob_remesas..sp_genera_orden
                             @s_date      = @i_fecha_proc,       --> Fecha de proceso
                             @s_user      = @s_user,             --> Usuario
                             @i_operacion = 'I',                 --> Operacion ('I' -> Insercion, 'A' Anulación)
                             @i_causa     = '018',               --> Causal de Egreso(cc_causa_oioe)
                             @i_ente      = @w_cliente,          --> Cod ente,
                             @i_valor     = @w_ro_porcentaje,    --> Valor,
                             @i_tipo      = 'C',                 --> 'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
                             @i_idorden   = null,                --> Cód Orden cuando operación 'A', 
                             @i_ref1      = @i_tramite ,         --> Ref. Númerica no oblicatoria
                             @i_ref2      = @w_cliente ,         --> Ref. Númerica no oblicatoria
                             @i_ref3      = '',                  --> Ref. AlfaNúmerica no oblicatoria
                             --@i_interfaz  ='N',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error
                             @i_interfaz  ='S',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error       
                             @o_idorden   = @w_num_orden out     --> Devuelve cód orden de pago/cobro generada - Operación 'I'
                                                                    
                       if @w_return <> 0
                          return @w_return
                       else                                      
                          begin 
                             insert into cob_credito..cr_tramite_cajas (tc_tramite, tc_num_orden, tc_valor,  tc_causa, tc_estado,tc_pago_cobro)
                                                                values (@i_tramite, @w_num_orden, @w_ro_porcentaje,  '018',    'I', 'C') --I:Ingresado C:Cobro
                             if @@error <> 0 
                                begin
                                   select                                                                                                                                                                                                                                                 
                                   @w_error = 2103001,                                                                                                                                                                                                                                         
                                   @w_msg   = 'ERROR AL INSERTAR EN cob_credito..cr_tramite_cajas'
                                   goto ERROR
                                end 
                          end     
                         
                       if @w_commit = 'S' 
                          begin
                             commit tran
                             select @w_commit = 'N'
                          end
                     if @i_crea_ext is null
                        select @w_trn_cajas       
                  end -- FIN VALIDACION
               end        
         end                                   
   end
   
-------------------------------------------------------------------------------------------------------------------------------------
--Operacion 'S'--> Buscar la transaccion de Cobro por Estudio Crediticio al Cliente Causal 018 para bloquear el campo en el FrontEnd
-------------------------------------------------------------------------------------------------------------------------------------
   
if @i_operacion = 'S'   
   begin  
      if @w_tipo in ('O','R','C') and  @w_migrado is null  
         begin  
            if exists (select 1 from cob_credito..cr_tramite_cajas where tc_tramite = @i_tramite and tc_causa = '018' and tc_estado in ('I','E') and tc_pago_cobro = 'C')
               select @w_trn_cajas = 'S'
               if @i_crea_ext is null
                  select @w_trn_cajas
         end       
            
   end
---------------------------------------------------------------------------------------------------------
--Operacion 'R  '--> Se rechaza el tramite entonces se anula la transaccion en Cajas y en cr_tramite_cajas
----------------------------------------------------------------------------------------------------------
if @i_operacion = 'R'   
begin
   if @w_ro_porcentaje is null
      return 0
   if @w_tipo in ('O','R','C') and  @w_migrado is null
   begin
      if exists (select 1 from cob_credito..cr_tramite_cajas where tc_tramite = @i_tramite and tc_causa = '018' and tc_estado = 'I' and tc_pago_cobro = 'C')
      begin 
         select @w_orden = tc_num_orden
         from cob_credito..cr_tramite_cajas 
         where tc_tramite    = @i_tramite  
           and tc_causa      = '018'
           and tc_pago_cobro = 'C'
           and tc_estado     = 'I'
          
         if exists(select 1 from  cob_remesas..re_orden_caja
         where oc_idorden  = @w_orden
         and   oc_estado  <> 'A')
         begin
                                        
            exec @w_return    = cob_remesas..sp_genera_orden
            @s_date           = @i_fecha_proc,       --> Fecha de proceso
            @s_user           = @s_user,             --> Usuario
            @i_operacion      = 'A',                 --> Operacion ('I' -> Insercion, 'A' Anulación)
            @i_causa          = '018',               --> Causal de Ingreso(cc_causa_oioe)
            @i_ente           = @w_cliente,          --> Cod ente,
            @i_valor          = @w_ro_porcentaje,    --> Valor,
            @i_tipo           = 'C',                 --> 'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
            @i_idorden        = @w_orden,            --> Cód Orden cuando operación 'A', 
            @i_ref1           = @i_tramite ,         --> Ref. Númerica no oblicatoria
            @i_ref2           = @w_cliente,          --> Ref. Númerica no oblicatoria
            @i_ref3           = '',                  --> Ref. AlfaNúmerica no oblicatoria
            --@i_interfaz       ='N',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error
            @i_interfaz       ='S',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error
            @o_idorden        = @w_num_orden out     --> Devuelve cód orden de pago/cobro generada - Operación 'I'
            
            if @w_return <> 0
               return @w_return
            else
            begin
               update cob_credito..cr_tramite_cajas
               set tc_estado       = 'A' --A: Anulado
               where tc_tramite    = @i_tramite 
               and tc_num_orden  = @w_orden 
               and tc_causa      = '018'
               and tc_pago_cobro = 'C' --C: Cobro
               and tc_estado     = 'I' --I: Ingresado 
               if @@error <>  0 
               begin
                  select                                                                                                                                                                                                                                                 
                  @w_error = 2103001,                                                                                                                                                                                                                                         
                  @w_msg   = 'ERROR AL ACTUALIZAR TABLA cr_tramite_cajas'
                  goto ERROR
               end
            end --EJECUCION ANULACION EN REMESAS
         end
         else
         begin --EXISTE TRANSACCION DE CAJA NO ANULADA
            update cob_credito..cr_tramite_cajas
            set tc_estado       = 'A' --A: Anulado
            where tc_tramite    = @i_tramite
            and   tc_num_orden  = @w_orden
            and   tc_causa      = '018'
            and   tc_pago_cobro = 'C' --C: Cobro
            and   tc_estado     = 'I' --I: Ingresado
            if @@error <>  0
            begin
               select
               @w_error = 2103001,
               @w_msg   = 'ERROR AL ACTUALIZAR TABLA cr_tramite_cajas'
               goto ERROR
            end               
         end         
      end --TRANSACCION EN CREDITO ESTA INGRESADA
   end --TIPO DE TRAMITE
end                                          
    
    
return 0   

ERROR:
if @w_commit = 'S' 
   begin
      rollback
      select @w_commit = 'N'
  end

if @w_msg is null 
begin
   select @w_msg = mensaje
   from   cobis..cl_errores
   where  numero = @w_error
end

if @i_crea_ext is null
begin
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg                                                                                                                                                                                                                                                           
   return @w_error
end
else
begin
   select @o_msg_msv = @w_msg + ', ' + @w_sp_name
   select @w_return  = @w_error
   return @w_return
end

GO
