/*batch_obligaciones_msv_1.sp *******************************************/
/*   Archivo:             batch_obligaciones_msv_1.sp                   */
/*   Stored procedure:    sp_batch_obligaciones_msv_1                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Ricardo Reyes                                 */
/*   Fecha de escritura:  Feb. 2013                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Procedimiento que realiza la ejecucion del fin de dia de           */
/*   cartera.                                                           */
/*      FECHA              AUTOR             CAMBIOS                    */
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_batch_obligaciones_msv_1')
   drop proc sp_batch_obligaciones_msv_1
go

CREATE proc sp_batch_obligaciones_msv_1
   @s_ssn                  int         = null,
   @s_sesn                 int         = null,
   @s_date                 datetime    = null,
   @s_ofi                  smallint    = null,
   @s_user                 login       = null,
   @s_rol                  smallint    = null,
   @s_org                  char(1)     = null, 
   @s_term                 varchar(30) = null,
   @s_srv                  varchar(30) = null,
   @s_lsrv                 varchar(30) = null,
   @i_tramite              int         = null,
   @i_hijo                 varchar(2)  = null,
   @i_debug                char(1)     = 'N',
   @i_tipo_tr              char(1)     = null,
   @i_fecha_proceso        datetime    = null,
   @i_bloque               int         = null,
   @o_ciclo                char(1)     = null out,
   @o_id_carga             int         = null out,
   @o_id_Alianza           int         = null out,   
   @o_dato                 int         = null out
as declare
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_return                int,
   @w_operacion             int,
   @w_op_cliente            int,
   @w_op_moneda             smallint,
   @w_beneficiario          descripcion,
   @w_banco                 varchar(24),
   @w_op_anterior           varchar(24),
   @w_cta_bancaria          cuenta,
   @w_des_cta_afi           char(1),
   @w_concepto              catalogo,
   @w_commit                char(1), 
   @w_monto                 money,
   @w_dato                  int,
   @w_op_fecha_prox_segven  datetime,
   @w_rowcount              int,
   @w_detener_proceso       char(1),
   @w_formato_fecha         int,
   @w_contador              int,
   @w_num_dec               tinyint, 
   @w_moneda_uvr            tinyint,
   @w_moneda                tinyint,
   @w_estado                tinyint,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_novigente         tinyint,
   @w_est_cancelado         tinyint,
   @w_est_credito           tinyint,
   @w_est_suspenso          tinyint,
   @w_est_castigado         tinyint,
   @w_est_anulado           tinyint,
   @w_est_diferido          tinyint,
   @w_est_condonado         tinyint,
   @w_moneda_nacional       tinyint,
   @w_tipo_tramite          char(1),
   @w_toperacion            catalogo,
   @w_renovacion            char(1),
   @w_tasa                  float,
   @w_tramite               int,
   @w_mercado               catalogo,
   @w_mercado_obj           catalogo,
   @w_clase                 catalogo,
   @w_plazo                 smallint,
   @w_modalidad             char(1),
   @w_tipo_credito          char(1),
   @w_spread                float,
   @w_reaj_esp              char(1),
   @w_concepto_cap          catalogo,
   @w_concepto_int          catalogo,
   @w_cotizacion_hoy        float,
   @w_signo                 char(1),
   @w_referencial_r         catalogo,
   @w_tip_pun_ajust         char(1),
   @w_id_carga              int,
   @w_id_alianza            int,
   @w_descripcion           varchar(255),
   @w_ced_ruc               cuenta,
   @w_hora_msv              varchar(5),
   @w_hora_fin              tinyint,
   @w_min_fin               tinyint,
   @w_pendientes            int,
   @w_msg                   varchar(255),
   @w_alianza               int,
   @w_oficina               int,
   @w_error_ext             int,
   @w_retorno_ext           varchar(255),
   @w_mantiene_cond         char(1),
   @w_exec                  varchar(8),
   @w_hilo_wait             int,
   @w_cliente_al            int,
   @w_pendientes_1          int,
   @w_desasocia_cli         char(1),
   @w_tiene_reaj             char(1),
   @w_aux                   varchar(200) 



/* CARGADO DE VARIABLES DE TRABAJO */
select 
@w_sp_name          = 'sp_batch_obligaciones_msv_1',
@s_user             = isnull(@s_user, suser_name()),
@s_term             = isnull(@s_term, 'BATCH_CARTERA'),
@w_commit           = 'N',
@w_contador         = 0, 
@w_formato_fecha    = 101,
@w_detener_proceso  = 'N',
@w_cta_bancaria     = '111111111111',
@w_return           = 0,
@w_pendientes       = 0,
@w_desasocia_cli    = 'N'
select @s_date = fp_fecha from cobis..ba_fecha_proceso

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_condonado  = @w_est_condonado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 return @w_error

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

-- CODIGO DE LA MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'

/* DECIMALES DE LA MONEDA NACIONAL */
exec @w_error   = sp_decimales
@i_moneda       = @w_moneda_nacional,
@o_decimales    = @w_num_dec out

--select @w_aux = 'Entrooo ' +@i_tipo_tr 
--insert into cob_credito..seguim values ( 1, getdate(), @w_aux  )
--print '000.. bnatch_msv_1 @i_hijo '+@i_hijo

while @w_detener_proceso = 'N' begin

   /* Parametro General */
   select @w_hora_msv = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'HFINMS'
   and   pa_producto = 'MIS'

   select @w_hora_fin = convert(tinyint,substring(@w_hora_msv,1,2))
   select @w_min_fin  = convert(tinyint,substring(@w_hora_msv,4,2))   
   
   select @w_pendientes = count(1) from cob_cartera..ca_universo_operaciones  with (nolock)
   where ub_estado = @i_hijo 
   and   ub_tipo_tra = @i_tipo_tr
   and   ub_dato <> 9999999           

   if datepart(hh,getdate()) >  @w_hora_fin or 
     (datepart(hh,getdate()) =  @w_hora_fin and datepart(mi,getdate()) >= @w_min_fin)  
      begin
      set rowcount 0
      
      delete cob_cartera..ca_universo_operaciones
      where ub_estado   = @i_hijo
      and   ub_tipo_tra = @i_tipo_tr
      select @o_ciclo   = 'N'
      break
   end   
       
   if @w_pendientes = 0 begin
      select @w_detener_proceso = 'N'


      -- Proceso para esperar un tiempo diferente para que cada hilo genere su universo
      /*
      select @w_hilo_wait = convert(int, isnull(@i_hijo,'1')) * 3 -- para que exista concurrencia.
      if @w_hilo_wait  < 1 or  @w_hilo_wait > 59 or @w_hilo_wait is null 
         select @w_hilo_wait = 1
      if @w_hilo_wait >= 1 and @w_hilo_wait <= 9 
         select @w_exec = '00:00:0'+ convert(char(1), @w_hilo_wait ) 
      else select @w_exec = '00:00:'+ convert(char(2), @w_hilo_wait ) 
      waitfor delay @w_exec 
      */

      delete ca_universo_operaciones
      where ub_estado = 'P'
      and   ub_tipo_tra = @i_tipo_tr

      -- VALIDACION DE EXISTENCIA DE CEDULA Y TIPO DE ID , POR CLIENTE 
      if exists ( select '1' from cob_externos..ex_msv_novedades  with (nolock)
                  where mtn_estado  = 'E' 
                  and   (mtn_cedula + mtn_tipo_ced ) not in ( select en_ced_ruc  + en_tipo_ced from cobis..cl_ente  with (nolock) ) )
      begin 

         insert into cobis..ca_msv_error with (rowlock)   -- select * from cobis..ca_msv_error 
         select me_fecha            = getdate(),
                me_id_carga         = a.mtn_id_carga,                 
                me_id_alianza       = convert( int, a.mtn_id_Alianza),
                me_referencia       = a.mtn_cedula + '-' + a.mtn_tipo_ced,
                me_tipo_proceso     = 'E',
                me_procedimiento    = 'sp_batch_obligaciones_msv_1',
                me_codigo_interno   = 0,
                me_codigo_err       = 0,
                me_descripcion      = 'CLIENTE NO EXISTE EN MIS.'
         from  cob_externos..ex_msv_novedades a  with (nolock)
         where mtn_tipo_ced + mtn_cedula not in ( select en_tipo_ced + en_ced_ruc from cobis..cl_ente  with (nolock) ) 

         update cob_externos..ex_msv_novedades          
         set    mtn_estado  = 'P',
                mtn_fecha_estado = getdate()
         from   cobis..cl_ente e  with (nolock)
         where mtn_tipo_ced + mtn_cedula not in ( select en_tipo_ced + en_ced_ruc from cobis..cl_ente  with (nolock) ) 
         and    mtn_estado  = 'E'
      end
      
      set rowcount @i_bloque
      
      if @i_tipo_tr = 'D' begin -- PARA LA PRIMERA FASE DE ALIANZAS NO SE DESMBOLSAN TRAMITES ORIGINALES.
         
         insert into ca_universo_operaciones      
         select  tr_tramite, mp_id_carga, mp_id_Alianza, @i_hijo, 0, @i_tipo_tr
         from    cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_credito..cr_msv_proc with (nolock)
         where   tr_cliente = ac_ente
         and     tr_fecha_apr = @i_fecha_proceso
         and     tr_tramite in (select op_tramite from cob_cartera..ca_operacion  with (nolock) where op_estado = @w_est_novigente)
         and     tr_tipo in ('T', 'O')
         and     tr_tramite = mp_tramite
         and     tr_alianza = ac_alianza
         and     ac_estado  = 'V'
         order by tr_tramite
         select @w_pendientes = @@rowcount            
         set rowcount 0         

      end

      -- REAJUSTES
      -- generar universo con alianzas canceladas y tabla cargada ex_msv_novedades

      if @i_tipo_tr = 'E' begin 
      
         -- VALIDACION DE EXISTENCIA Y VIGENCIA DE DOCUMENTO DE IDENTIDAD DE ALIANZA 
         /* Esta validacion seria solamente para tramites de cancelacion de clientes y no para cuando se desasocia un cliente por el front end.
         if exists ( select '1' from cob_externos..ex_msv_novedades   
                     where mtn_estado  = 'E' 
                     and   (mtn_id_Alianza ) not in ( select en_ced_ruc 
                                                      from cobis..cl_alianza, cobis..cl_ente 
                                                      where al_ente = en_ente and al_estado = 'V' ) )
         begin 
            insert into cobis..ca_msv_error with (rowlock) 
            select  me_fecha      = getdate(),     me_id_carga      = a.mtn_id_carga,  me_id_alianza      = 0,             
                    me_referencia = 'Reajuste',    me_tipo_proceso  = 'E',             me_procedimiento   = 'Batch_obligacion_msn_1',
                    me_codigo_interno  = 0,        me_codigo_err    = 0,               me_descripcion     = 'ALIANZA NO EXISTE O NO ESTA VIGENTE  ' +'NIT: '+ isnull(a.mtn_id_Alianza,'') +' CED: ' + isnull(a.mtn_cedula,'') +' TIPO: ' + isnull(a.mtn_tipo_ced,'')
            from  cob_externos..ex_msv_novedades    a 
            where mtn_estado  = 'E'
            and   (mtn_id_Alianza ) not in ( select al_alianza from cobis..cl_alianza
                                             where al_estado = 'V' ) 

            update cob_externos..ex_msv_novedades
            set   mtn_estado  = 'P' 
            where mtn_estado  = 'E'
            and   (mtn_id_Alianza ) not in ( select al_alianza from cobis..cl_alianza
                                             where al_estado = 'V' )

         end 
         */


      -- Universo desde Carga de Archivo Plano
     insert into ca_universo_operaciones ( 
                ub_dato, ub_id_carga,  ub_id_alianza,  ub_estado, ub_intentos, ub_tipo_tra)
         select cli.en_ente, mtn_id_carga, al_alianza, @i_hijo,   0,           @i_tipo_tr
         from   cob_externos..ex_msv_novedades with (nolock),  cobis..cl_ente cli with (nolock), cobis..cl_ente al with (nolock), cobis..cl_alianza 
         where  mtn_cedula     = cli.en_ced_ruc
         and    mtn_tipo_ced   = cli.en_tipo_ced
         and    mtn_estado     = 'E'
         and    mtn_id_Alianza = al.en_ced_ruc 
         and    al.en_ente     = al_ente
         order by en_ente

         
         select @w_pendientes = @@rowcount     

         -- Universo desde Cancelacion de Alianza
         insert into ca_universo_operaciones
         select ac_ente , 9999999, al_alianza, @i_hijo, 0, @i_tipo_tr
         from   cobis..cl_alianza_cliente with (nolock), cobis..cl_alianza with (nolock)
         where  ac_alianza              = al_alianza
         and    al_estado               = 'C'    --> Cancelada
--         and    al_fecha_cancelacion    <= @i_fecha_proceso
         and    datediff(dd,al_fecha_cancelacion, @i_fecha_proceso ) >= 0
         and    ac_estado               = 'V'
         and    ac_ente                 not in ( select me_codigo_interno 
                                                 from cobis..ca_msv_error 
                                                 where me_fecha >= @i_fecha_proceso -- me_descripcion like '%1770328%'  order by me_fecha 
                                                 and   me_tipo_proceso = 'E' 
                                                 and   me_referencia   = 'Reajuste' ) 

-- delete cobis..ca_msv_error where me_tipo_proceso = 'E' and   me_referencia   = 'Reajuste' and   me_descripcion like '%NO SE RECHAZO TRAMITE. 2642859%'
                                                 
         select @w_pendientes = @w_pendientes + @@rowcount          

         set rowcount 0

         -- ACTUALIZAR    cob_externos..ex_msv_novedades
         update cob_externos..ex_msv_novedades with (rowlock)
         set mtn_estado       = 'P',
             mtn_fecha_estado = getdate()
         from ca_universo_operaciones  with (nolock), cobis..cl_ente cli with (nolock), cobis..cl_ente al with (nolock), cobis..cl_alianza
         where mtn_cedula     = cli.en_ced_ruc
         and   mtn_tipo_ced   = cli.en_tipo_ced
         and   mtn_id_Alianza = al.en_ced_ruc 
         and   al.en_ente     = al_ente
         and   ub_id_alianza  = al_alianza
         and   mtn_id_carga   = ub_id_carga
         and   mtn_estado     = 'E'
         and   ub_estado      = @i_hijo
         and   cli.en_ente    = ub_dato

      end 

      -- RENOVACIONES
      if @i_tipo_tr = 'R' begin 

         insert into ca_universo_operaciones
         select  tr_tramite, mp_id_carga, mp_id_Alianza, @i_hijo, 0, @i_tipo_tr
         from    cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_credito..cr_msv_proc a with (nolock)
         where   datediff(dd, tr_fecha_apr, @i_fecha_proceso ) >= 0  
         and     tr_tramite  in (select op_tramite from cob_cartera..ca_operacion  with (nolock) where op_estado = @w_est_novigente)
         and     tr_estado    = 'A' 
         and     tr_alianza   = ac_alianza
         and     tr_cliente   = ac_ente   
         and     tr_tramite   = mp_tramite
         and     tr_tipo      = 'U'       
         and     ac_estado    = 'V'
         and     tr_cliente not in ( select me_codigo_interno from cobis..ca_msv_error where me_id_carga = a.mp_id_carga  and me_id_alianza = a.mp_id_Alianza ) 
         and     tr_tramite not in ( select distinct ub_dato from ca_universo_operaciones where ub_dato  <> 9999999  ) 
         and     tr_tramite not in ( select mp_tramite from cob_cartera..ca_msv_proc c 
                                     where c.mp_id_carga = a.mp_id_Alianza and c.mp_id_alianza = a.mp_id_carga and mp_tramite is not null  ) 
         order by tr_tramite 

         select @w_pendientes = @@rowcount

         delete ca_universo_operaciones where ub_dato in ( select mp_tramite from cob_cartera..ca_msv_proc ) 

         select @w_pendientes_1 = @@rowcount
         select @w_pendientes = @w_pendientes - @w_pendientes_1

         set rowcount 0

      end

      select @o_ciclo = 'S'
      set rowcount 0

      -- SI NO HAY PENDIENTES, SE ESPERA 15 SEGUNDOS PARA NO HACER CONSULTAS A LA BD
      select @w_pendientes = isnull(@w_pendientes,0)
      if @w_pendientes = 0 
         break --waitfor delay '00:00:15'

   end --  if @w_pendientes = 0 begin

   select @w_pendientes = isnull(@w_pendientes,0)
   while @w_pendientes > 0 
   begin
      
      select @o_id_carga      = 0,
             @o_id_Alianza    = 0,
             @o_dato          = 0,
             @w_desasocia_cli = 'N' 
 
             
      set rowcount 1
      select @w_dato            = ub_dato,
             @w_id_carga        = ub_id_carga,
             @w_id_alianza      = ub_id_alianza,
             @w_detener_proceso = ub_estado,
             -- Variables de Salida en caso de error
             @o_id_carga        = ub_id_carga,
             @o_id_Alianza      = ub_id_alianza,   
             @o_dato            = ub_dato 
      from ca_universo_operaciones with (nolock)  -- select * from ca_universo_operaciones
      where ub_estado   = @i_hijo
      and   ub_intentos < 2
      and   ub_dato     <> 9999999
      and   ub_estado   <> 'P'      
      and   ub_tipo_tra = @i_tipo_tr
      
      set rowcount 0             
      select @w_error = 0   
      
      update ca_universo_operaciones with (rowlock) set  
      ub_intentos = ub_intentos + 1,
      ub_estado = 'P'
      where ub_dato       = @w_dato
      and   ub_estado     = @i_hijo
      and   ub_tipo_tra   = @i_tipo_tr
      and   ub_id_carga   = @w_id_carga
      and   ub_id_alianza = @w_id_alianza 
      
      ---------------------------------------------------------------------------------------
      -- INICIO. DESEMBOLSOS y RENOVACIONES (Utilizaciones)----------------------------------
      if @i_tipo_tr in ('D', 'R') begin 

         select             
         @w_banco                = op_banco,
         @w_op_anterior          = op_anterior,
         @w_operacion            = op_operacion,
         @w_op_moneda            = op_moneda,                  
         @w_monto                = op_monto,
         @w_beneficiario         = op_nombre,
         @w_op_cliente           = op_cliente,
         @w_tipo_tramite         = tr_tipo,
         @w_toperacion           = op_toperacion,
         @w_oficina              = tr_oficina                                 
         from ca_operacion with (nolock), cob_credito..cr_tramite with (nolock)
         where op_tramite = @w_dato
         and   op_estado  = @w_est_novigente
         and   op_tramite = tr_tramite
         and   tr_alianza = @w_id_alianza
      
         if @i_tipo_tr = 'R' begin 

            -- VALIDACION: FECHA DE PROC. DE OBLIGACION A RENOVAR NO ES IGUAL A FECHA DE PROCESO.
            if exists( select '1'
                       from cob_cartera..ca_operacion   with (nolock) 
                       where op_banco    = @w_op_anterior 
                       and   ( datediff(dd, op_fecha_ult_proceso, @i_fecha_proceso ) > 0     or 
                               datediff(dd, op_fecha_ult_proceso, @i_fecha_proceso ) < 0 ) )
            begin 
            
               select @w_ced_ruc = de_ced_ruc from cob_credito..cr_deudores  with (nolock)  where de_tramite = @w_dato and de_rol = 'D'
               select @w_descripcion = ' Error generacion masiva de Desembolso - Id: ' + isnull(@w_ced_ruc,'') + ' Tramite:' + convert(varchar(20),@w_dato) + ' Tipo Op:' +  isnull(@w_toperacion,'') + ' Monto:' + convert(varchar(20) ,isnull(@w_monto,0) )  

               select @w_descripcion = @w_descripcion + '. FECHA DE PROC. DE OBLIGACION A RENOVAR NO ES IGUAL A FECHA DE PROCESO. ' 
               exec cobis..sp_error_proc_masivos
                    @i_id_carga        = @w_id_carga,      
                    @i_id_alianza      = @w_id_alianza,      
                    @i_referencia      = @i_tipo_tr, 
                    @i_tipo_proceso    = 'C', 
                    @i_procedimiento   = 'sp_batch_obligaciones_msv_1',   
                    @i_codigo_interno  = @w_op_cliente,       
                    @i_codigo_err      = @w_error,      
                    @i_descripcion     = @w_descripcion

               select @w_banco  = null

            end

            select @w_renovacion = 'S'
         end else begin 
            select @w_renovacion = 'N'
         end
                 
         select @w_des_cta_afi = al_des_cta_afi,
                @w_concepto    = al_forma_des,
                @w_cliente_al  = al_ente
         from   cobis..cl_alianza  with (nolock), 
                cobis..cl_alianza_cliente
         where  al_alianza  = ac_alianza
         and    ac_ente     = @w_op_cliente
         and    al_estado   = 'V'
           
         if @w_des_cta_afi = 'S' -- DESEMBOLSO A CUENTA DE LA ALIANZA
         begin
            select @w_cta_bancaria = al_cuenta_bancaria,
                   @w_beneficiario = en_nomlar,
                   @w_ced_ruc      = en_ced_ruc
            from   cobis..cl_alianza  with (nolock), cobis..cl_ente  with (nolock)
            where  en_ente  = al_ente
            and    al_ente  = @w_cliente_al
         end
         else
         begin
            
            if @w_concepto = 'NCAH' -- DESEMBOLSO A CUENTA DEL CLIENTE
            begin 
               /*select @w_cta_bancaria = ah_cta_banco
               from  cob_ahorros..ah_cuenta  with (nolock)
               where ah_cliente = @w_op_cliente
               and   ah_moneda  = @w_op_moneda
               and   ah_estado  in ('A','G') 
               and   ah_cta_banco not in (select cc_cta_banco 
                                  from cob_remesas..re_cuenta_contractual  with (nolock)
                                  where cc_estado = 'A')
               and   ah_cta_banco > '0'
               order by ah_cta_banco*/
               exec cob_interface..sp_batch_obligacion_interfase
               @i_op_cliente   = @w_op_cliente,
               @i_op_moneda    = @w_op_moneda,
               @o_cta_bancaria = @w_cta_bancaria out
            end         
         end

         /*
         ('Carga REAJUSTES Universo @w_banco :' + convert(varchar(10),@w_banco) + 
                                    ' -@w_concepto :' + convert(varchar(10),@w_concepto) + 
                                    ' -@w_beneficiario    :' + convert(varchar(10),@w_beneficiario) +
                                    ' -@w_monto    :' + convert(varchar(10),@w_monto) +                                    
                                    ' -@w_op_moneda    :' + convert(varchar(10),@w_op_moneda) +
                                    ' -@w_formato_fecha    :' + convert(varchar(10),@w_formato_fecha) +
                                    ' -@w_renovacion    :' + convert(varchar(10),@w_renovacion) + 
                                    ' -@w_cta_bancaria :' + convert(varchar(20),@w_cta_bancaria)
          )
         */

         if @w_banco is not null begin

            exec @w_error = sp_liquidacion_rapida  -- sp_helpcode sp_liquidacion_rapida
            @s_ssn             = @s_sesn,        
            @s_sesn            = @s_sesn,          
            @s_srv             = @s_srv,
            @s_lsrv            = @s_lsrv,         
            @s_user            = @s_user,          
            @s_date            = @s_date,
            @s_ofi             = @w_oficina,      
            @s_rol             = @s_rol,           
            @s_org             = @s_org,
            @s_term            = @s_term,        
            @i_banco           = @w_banco,         
            @i_producto        = @w_concepto,             --> Parametro General
            @i_cuenta          = @w_cta_bancaria,    
            @i_beneficiario    = @w_beneficiario,  
            @i_monto_op        = @w_monto,
            @i_moneda_op       = @w_op_moneda,
            @i_formato_fecha   = @w_formato_fecha,
            @i_externo         = 'N', 
            @i_crea_ext        = 'S',
            @i_renovacion      = @w_renovacion,   ---   S
            @o_banco_generado  = @w_banco out,
            @o_msg             = @w_msg   out  

            if @w_error <> 0 begin  

               select @w_ced_ruc = de_ced_ruc from cob_credito..cr_deudores  with (nolock)  where de_tramite = @w_dato and de_rol = 'D'
               select @w_descripcion = isnull(@w_msg,'') + ' Error en generacion masiva de Desembolso - Id: ' + ltrim(rtrim(isnull(@w_ced_ruc,'0'))) + ' Tramite:' + convert(varchar(20),isnull(@w_dato,0)) + ' Tipo Op:' +  isnull(@w_toperacion,'') + ' Monto:' + convert(varchar(20) ,isnull(@w_monto,0)) 
               select @w_descripcion = @w_descripcion + ' ' + mensaje  from cobis..cl_errores  with (nolock) where numero = @w_error

               exec cobis..sp_error_proc_masivos
                    @i_id_carga        = @w_id_carga,      
                    @i_id_alianza      = @w_id_alianza,      
                    @i_referencia      = @i_tipo_tr, 
                    @i_tipo_proceso    = 'C', 
                    @i_procedimiento   = 'sp_batch_obligaciones_msv_1',   
                    @i_codigo_interno  = @w_op_cliente,       
                    @i_codigo_err      = @w_error,      
                    @i_descripcion     = @w_descripcion
            end 
            else begin

               select @w_tasa     = ts_porcentaje,
                      @w_estado   = op_estado,
                      @w_tramite  = op_tramite
               from ca_tasas with (nolock), ca_operacion  with (nolock)
               where ts_operacion = @w_operacion
               and  ts_operacion  = op_operacion
      
               select @w_descripcion = 'Operacion Desembolsada. TipoCed:' + isnull(en_tipo_ced,'') + ' Id:'+isnull(en_ced_ruc,'') from cobis..cl_ente  with (nolock) where en_ente = @w_cliente_al   -- @w_dato

               insert into ca_msv_proc ( 
                      mp_id_carga,   mp_id_alianza, mp_tipo_tr,    mp_tramite, mp_tipo,        mp_banco, 
                      mp_estado,     mp_monto,      mp_toperacion, mp_tasa,    mp_descripcion, mp_fecha_proc  )
               values(
                      @w_id_carga,   @w_id_alianza, @i_tipo_tr,    @w_dato,    @w_tipo_tramite, @w_banco,     
                      @w_estado,     @w_monto,      @w_toperacion, @w_tasa,    isnull(@w_descripcion,'')+'-h_1_'+isnull(@i_hijo,''),  getdate() )
            end         
         end
      end 

      -- FIN. DESEMBOLSOS y RENOVACIONES (Utilizaciones)----------------------------
      ------------------------------------------------------------------------------
      
      ------------------------------------------------------------------------------
      -- INICIO. REAJUSTES  --------------------------------------------------------
      if @i_tipo_tr = 'E' begin 

         select @w_mantiene_cond = isnull( al_mantiene_condiciones,'N')  --> Si no mantiene condiciones, coloca tasa sin beneficio de alianza.
         from cobis..cl_alianza  with (nolock)
         where al_alianza = @w_id_alianza

         if @w_mantiene_cond  = 'N' begin    -- N

            -- Operaciones Cliente
            select distinct 
                   tramite       = tr_tramite, 
                   tipo_credito  = tr_tipo_credito, 
                   mercado       = tr_mercado, 
                   mercado_obj   = tr_mercado_objetivo,
                   clase         = op_clase, 
                  toperacion    = op_toperacion,
                   monto         = op_monto,
                   plazo         = op_plazo,
                   modalidad     = ro_fpago,
                   concepto      = ro_concepto,
                   moneda        = op_moneda,
                   operacion     = op_operacion,
                   banco         = op_banco,
                   estado_proc   = 'I',
                   reaj_esp      = isnull(op_reajuste_especial, 'N'),
                   referencial_r = ro_referencial_reajuste,
                   tipo_puntos   = isnull(ro_tipo_puntos, 'e'),
                   alianza       = tr_alianza,
                   oficina       = op_oficina
            into   #datos_reajuste
            from cob_cartera..ca_operacion with (nolock), 
                 cob_cartera..ca_rubro_op  with (nolock), 
                 cob_credito..cr_tramite  with (nolock)
            where op_operacion  = ro_operacion 
            and   ro_tipo_rubro = 'I'
            and   op_tramite    = tr_tramite
            and   op_cliente    = @w_dato
            and   op_estado     in (1,2,4,9)
            and   ro_provisiona = 'S'
            and   tr_alianza    = @w_id_alianza

            select @w_tiene_reaj = 'S' 
            while 1 = 1 begin -- Todas las operaciones del cliente
               
               set rowcount 1
               select @w_error = 0
            
               select 
                  @w_tramite       = tramite, 
                  @w_tipo_credito  = tipo_credito, 
                  @w_mercado       = mercado, 
                  @w_mercado_obj   = mercado_obj,
                  @w_clase         = clase, 
                  @w_toperacion    = toperacion,
                  @w_monto         = monto,
                  @w_plazo         = plazo,
                  @w_modalidad     = modalidad,
                  @w_concepto      = concepto,
                  @w_moneda        = moneda,
                  @w_operacion     = operacion,
                  @w_banco         = banco,
                  @w_reaj_esp      = reaj_esp,
                  @w_referencial_r = referencial_r,
                  @w_tip_pun_ajust = tipo_puntos,
                  @w_alianza       = alianza,
                  @w_oficina       = oficina   
               from #datos_reajuste
               where estado_proc  = 'I'
               order by tramite
            
               if @@rowcount = 0 begin
                  set rowcount 0
                  select @w_tiene_reaj = 'N' 
                  break
               end
               if  isnull(@w_tramite,0) = 0 or isnull(@w_dato,0) = 0 begin
                  set rowcount 0
                  break
               end

               set rowcount 0

               -- Calcular Nueva tasas -- Acorde a la tasa a la fecha del reajuste.
               exec @w_error = cob_credito..sp_valida_matrices 
                    @i_ente               = @w_dato,
                    @i_tramite            = @w_tramite,
                    @i_tipo_credito       = @w_tipo_credito,
                    @i_mercado            = @w_mercado,
                    @i_mercado_objetivo   = @w_mercado_obj,
                    @i_clase_cca          = @w_clase,
                    @i_toperacion         = @w_toperacion,   
                    @i_monto_solicitado   = @w_monto,      
                    @i_plazo              = @w_plazo,   
                    @i_alianza            = 0,               -- No se envia Alianza. Debido a que se busca tasa sin tener en cuenta la asociada a la alianza.
	                @i_msv                = 'S',            --Viene de Proceso Masivo
                    @o_spread             = @w_spread out,
                    @o_signo              = @w_signo out
                    
           
               if @w_error <> 0 goto ERROR_CARTERA

               -- Insertar registros del Reajuste
               exec @w_error = sp_insertar_reajustes   -- sp_helpcode sp_insertar_reajustes
                   @s_date            = @i_fecha_proceso,
 	           @s_ofi             = @w_oficina,
 	           @s_user            = @s_user,
 	           @s_term            = @s_term,
 	           @i_banco           = @w_banco,
 	           @i_especial        = @w_reaj_esp,
 	           @i_fecha_reajuste  = @i_fecha_proceso,
 	           @i_concepto        = @w_concepto,
 	           @i_referencial     = @w_referencial_r,
 	           @i_signo           = @w_signo,
 	           @i_factor          = @w_spread,      
 	           @i_porcentaje      = 0,
 	           @i_desagio         = @w_tip_pun_ajust   
            
               if @w_error <> 0 goto ERROR_CARTERA
            
               -- OBTENER EL CONCEPTO DE CAPITAL
               select @w_concepto_cap = ro_concepto
               from   ca_rubro_op with (nolock)
               where  ro_operacion  = @w_operacion
               and    ro_tipo_rubro = 'C'
            
               -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
               if @w_op_moneda = @w_moneda_nacional begin
                  select @w_cotizacion_hoy = 1.0
               end else begin
                  exec sp_buscar_cotizacion
                  @i_moneda     = @w_op_moneda,
                  @i_fecha      = @i_fecha_proceso,
                  @o_cotizacion = @w_cotizacion_hoy output
               end
            
               exec @w_error = sp_reajuste
               @s_user          = @s_user,
               @s_term          = @s_term,
               @s_date          = @i_fecha_proceso,
               @s_ofi           = @w_oficina,
               @i_en_linea      = 'N',
               @i_fecha_proceso = @i_fecha_proceso,
               @i_operacionca   = @w_operacion,
               @i_modalidad     = @w_modalidad,
               @i_cotizacion    = @w_cotizacion_hoy,
               @i_num_dec       = @w_num_dec,
               @i_concepto_int  = @w_concepto_int,
               @i_concepto_cap  = @w_concepto_cap,
               @i_moneda_uvr    = @w_moneda_uvr,
               @i_moneda_local  = @w_moneda_nacional
            
               if @w_error <> 0 goto ERROR_CARTERA
            
               ERROR_CARTERA:
            
               if @w_error <> 0 begin  
            
                  select @w_descripcion = 'Error generacion MSV Reajuste - Id: ' + isnull(@w_ced_ruc,'') + ' Tramite:' + convert(varchar(20),isnull(@w_tramite,0)) + ' Tipo Op:' +  isnull(@w_toperacion,'') + ' Monto:' + convert(varchar(20) ,@w_monto) + ' Tasa:' + isnull(convert( varchar(30), @w_tasa),'') + ' NO desasocio cliente de Alianza.'
                  select @w_descripcion = @w_descripcion + ' ' + mensaje  from cobis..cl_errores  with (nolock) where numero = @w_error
                  exec cobis..sp_error_proc_masivos
                       @i_id_carga        = @w_id_carga,      
                       @i_id_alianza      = @w_id_alianza,      
                       @i_referencia      = @i_tipo_tr, 
                       @i_tipo_proceso    = 'C', 
                       @i_procedimiento   = 'sp_batch_obligaciones_msv_1',   
                       @i_codigo_interno  = @w_op_cliente,       
                       @i_codigo_err      = @w_error,      
                       @i_descripcion     = @w_descripcion

               end else begin

                  select @w_tasa     = ts_porcentaje,
                         @w_estado   = op_estado
                  from ca_tasas with (nolock), ca_operacion  with (nolock)
                  where ts_operacion = @w_operacion
                  and  ts_operacion  = op_operacion
            
                  select @w_descripcion = 'Operacion Reajustada. ' + isnull(en_tipo_ced,'') + isnull(en_ced_ruc,'') from cobis..cl_ente  with (nolock) where en_ente = @w_dato

                  insert into ca_msv_proc (  -- select * into ca_msv_proc_cp from ca_msv_proc 
                         mp_id_carga,  mp_id_alianza, mp_tipo_tr,    mp_tramite, mp_tipo,        mp_banco, 
                        mp_estado,     mp_monto,      mp_toperacion, mp_tasa,    mp_descripcion, mp_fecha_proc  )
                  values(
                         @w_id_carga,  @w_id_alianza, @i_tipo_tr,    0,          @w_tipo_tramite,                                   @w_banco,     
                         @w_estado,    @w_monto,      @w_toperacion, @w_tasa,    isnull(@w_descripcion,'')+'-h'+isnull(@i_hijo,''), getdate() )

                  select @w_desasocia_cli = 'S' 

               end
               
               update #datos_reajuste
               set estado_proc = 'P'
               where tramite = @w_tramite
            
            end -- while Reajustes
            
            drop table #datos_reajuste

         end else begin -- if @w_mantiene_cond  = 'N'

            select @w_descripcion = 'Novedad de cliente. ' + en_tipo_ced + en_ced_ruc from cobis..cl_ente  with (nolock) where en_ente = @w_dato

            insert into ca_msv_proc ( 
                   mp_id_carga,  mp_id_alianza, mp_tipo_tr,    mp_tramite, mp_tipo,        mp_banco, 
                   mp_estado,    mp_monto,      mp_toperacion, mp_tasa,    mp_descripcion, mp_fecha_proc  )
            values(
                   @w_id_carga,  @w_id_alianza, @i_tipo_tr,  @w_dato,    @w_tipo_tramite,                                   null,
                   null,         0,             null,          0,          isnull(@w_descripcion,'')+'-h'+isnull(@i_hijo,''), getdate()  )

            select @w_desasocia_cli = 'S' 

         end           -- if @w_mantiene_cond  = 'N' 

         if @w_tiene_reaj = 'N' 
         begin 

            select @w_descripcion = 'Cliente sin novedad de reajuste. ' + en_tipo_ced + en_ced_ruc from cobis..cl_ente  with (nolock) where en_ente = @w_dato

            insert into ca_msv_proc ( 
                   mp_id_carga,  mp_id_alianza, mp_tipo_tr,    mp_tramite, mp_tipo,        mp_banco, 
                   mp_estado,    mp_monto,      mp_toperacion, mp_tasa,    mp_descripcion, mp_fecha_proc  )
            values(
                   @w_id_carga,  @w_id_alianza, @i_tipo_tr,  @w_dato,    @w_tipo_tramite,                                   null,
                   null,         0,             null,          0,          isnull(@w_descripcion,'')+'-h'+isnull(@i_hijo,''), getdate()  )
                   
            select @w_desasocia_cli = 'S' 

         end
 

         -- Rechazo Datos Trámites.
         exec @w_error = cob_credito..sp_rechazo_aes
         @i_cliente = @w_dato
            
         if @w_error <> 0 begin  
           
            select @w_descripcion = 'Error generacion MSV Reajuste - Id: ' + isnull(@w_ced_ruc,'') + ' ClienteCobis:' + isnull(convert(varchar(20),@w_dato),'') + ' Rechazo tramites en vuelo de cliente. NO desasocio cliente de Alianza.' 
            select @w_descripcion = @w_descripcion + ' ' + mensaje  from cobis..cl_errores  with (nolock) where numero = @w_error  
            exec cobis..sp_error_proc_masivos
                 @i_id_carga        = @w_id_carga,      
                 @i_id_alianza      = @w_id_alianza,      
                 @i_referencia      = @i_tipo_tr, 
                 @i_tipo_proceso    = 'C', 
                 @i_procedimiento   = 'sp_batch_obligaciones_msv_1',   
                 @i_codigo_interno  = @w_op_cliente,
                 @i_codigo_err      = @w_error,      
                 @i_descripcion     = @w_descripcion
         end else begin 

            if @w_desasocia_cli = 'S' begin 

               -- Si no tiene tramites en vuelo asociado a la alianza se desasocia el cliente de la alianza.

               if not exists ( select '1'
                               from cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_cartera..ca_operacion with (nolock)
                               where tr_cliente = @w_dato
                               and   tr_estado  <> 'Z'
                               and   tr_alianza = ac_alianza
                               and   tr_cliente = ac_ente
                               and   op_tramite = tr_tramite
                               and   op_estado  in ( @w_est_novigente, @w_est_credito ) )
               begin
                  -- ACTUALIZAR cobis..cl_alianza_cliente a estado 'C'
                  update cobis..cl_alianza_cliente with (rowlock)  
                  set   ac_estado = 'C', ac_fecha_desasociacion = getdate()
                  where  ac_ente = @w_dato
               end
            end
         end
         select @w_desasocia_cli = 'N' 

      end -- Fin Reajustes
      
      SALIR:

      update ca_universo_operaciones with (rowlock)
      set ub_estado = 'P'
      where ub_dato            = @w_dato
      and   ub_id_carga        = @w_id_carga
      and   ub_id_alianza      = @w_id_alianza
      and   ub_tipo_tra        = @i_tipo_tr
      
      select @w_pendientes = @w_pendientes - 1

      select @w_desasocia_cli = 'N' 

      if @w_pendientes  <= 0 begin
         select @o_ciclo = 'S'
         break
      end

   end -- @w_pendientes > 0      


end

return 0
go

