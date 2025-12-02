/************************************************************************/
/* Archivo                :     renovac.sp                              */
/* Stored procedure       :     sp_renovacion                           */
/* Base de datos          :     cob_cartera                             */
/* Producto               :     Cartera                                 */
/* Disenado por           :     R.Garces                                */
/* Fecha de escritura     :     11/Mar/98                               */
/* **********************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/* **********************************************************************/
/*                             PROPOSITO                                */
/*  Aplicar los pagos para cancelar el(los) prestamo(s) a renovar       */
/*                            MODIFICACIONES                            */
/*  FECHA           AUTOR           RAZON                           */
/*  06/Dic/2016     I. Yupa         AJUSTES CONTABLES MEXICO        */
/*  20/Abr/2019   L. Gerardo Barron  Ajustes para proceso de renovacion de prestamo */
/*  11/Jun/2020      Luis Ponce      CDIG Multimoneda                   */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/*    24/Jun/2022     KDR              Nuevo par·metro sp_liquid        */
/* **********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_renovacion')
   drop proc sp_renovacion
go
CREATE proc sp_renovacion
   @s_ssn               int         = null,
   @s_sesn              int         = null,
   @s_date              datetime,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint    = null,
   @i_banco             cuenta      = null, -- OBLIGACION NUEVA
   @i_detalledes        char(1)     = 'S',
   @i_verificar         char(1)     = 'N',
   @i_valor_renovar     money       = null,
   @i_forma_pago        catalogo    = null,
   @i_cuenta_banco      cuenta      = null,
   @i_formato_fecha     int         = 101,
   @o_banco_generado    cuenta      = null out
as
declare
   @w_sp_name                    varchar(32),
   @w_forma_pago                 catalogo,
   @w_fecha_ult_proc             datetime,
   @w_error                      int,
   @w_operacionca                int,
   @w_moneda                     tinyint,
   @w_re_moneda_ant              tinyint, --LPO CDIG Multimoneda 
   @w_re_moneda_nueva            tinyint, --LPO CDIG Multimoneda 
   @w_codmn                      tinyint, --LPO CDIG Multimoneda -- Codigo de la moneda nacional   
   @w_cotizacion_mop             float,   --LPO CDIG Multimoneda 
   @w_tipo_mop                   char(1), --LPO CDIG Multimoneda 
   @w_monto_moneda_nueva         MONEY,   --LPO CDIG Multimoneda 
   @w_tramite_nueva              int,
   @w_banco_renovada             varchar(24),
   @w_est_cancelado              smallint,
   @w_est_suspenso               smallint,
   @w_est_castigado              smallint,
   @w_est_vencido                smallint,
   @w_est_vigente                smallint,   
   @w_estado_op_vieja            tinyint,
   @w_div_vigente                int,
   @w_estado_fin                     tinyint,
   @w_secuencial_ing             int,
   @w_fecha_ini_nueva            datetime,
   @w_num_renovaciones_ant       smallint,
   @w_commit                     char(1),
   @w_msg                        varchar(120),
   @w_monto_pago                 money,
   @w_datos_renovada             varchar(64),
   @w_clase                      varchar(10),
   @w_cliente                    int,
   @w_cod_comercial              varchar(10),
   @w_tipo_tramite               varchar(1),
   @w_oficial                    int,
   @w_secuencial                 int,
   @w_return                     int,
   @w_ult_tramite                int,         --Inc_7615
   @w_cl_cartera                 varchar(10), --Inc_7615
   @w_clase_nva                  varchar(10),  --Inc_7615   
   @w_estado_operacion           tinyint,
   @w_fecha_ult_proceso          datetime,
   @w_beneficiario               int,
   @w_nombre                     varchar(50),
   @w_op_fecha_ult_proceso       datetime,
   @w_cotizacion_hoy             float , -- = 0,
   @w_num_dec_mn                 tinyint,
   @w_monto_pagado               MONEY, -- = 0,
   @w_monto_renovar_mn           MONEY, -- = 0,
   @w_operacionca_n              int,
   @w_desembolso                 int,
   @w_plazo_no_vigente           tinyint,
   @w_min_fecha_vig              datetime
   ,@w_banco_fic                  cuenta  --LGBC
   
-- INICIALIZACION DE VARIABLES
select 
@w_sp_name           = 'sp_renovacion',
@w_commit            = 'N',
@w_cotizacion_hoy    = 0,
@w_monto_pagado      = 0,
@w_monto_renovar_mn  = 0


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_castigado  = @w_est_castigado out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_vigente    = @w_est_vigente   out

/* DETERMINAR LA FORMA DE PAGO DE RENOVACION */
select @w_forma_pago = 	pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FDESRE'


-- LPO CDIG Multimoneda --Codigo de moneda local
select @w_codmn = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'CMNAC'   


/* Clase Comercial */
select @w_cod_comercial = pa_char 
from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'CCOM'

if @@rowcount = 0 select @w_forma_pago = 'RENOVACION'

--- DATOS DE LA OPERACION NUEVA
select 
@w_tramite_nueva   = op_tramite,
@w_moneda          = op_moneda,
@w_fecha_ini_nueva = op_fecha_liq,
@w_banco_renovada  = op_anterior,
@w_cliente         = op_cliente,
@w_tipo_tramite    = tr_tipo,
@w_oficial         = tr_oficial,
@w_clase_nva       = op_clase, --Inc_7615
@w_estado_operacion = op_estado,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_operacionca_n     = op_operacion
from   ca_operacion, cob_credito..cr_tramite
where  op_banco   = @i_banco
and    op_tramite is not null
and    op_tramite = tr_tramite

if @@rowcount = 0 begin
   select @w_error = 710559, @w_msg = 'NO SE ENCUENTRA LA OPERACION: ' + @i_banco
   goto ERRORFIN
end

-- Validar si existen renovaciones pendientes
if not exists (select 1 
               from   ca_operacion,  cob_credito..cr_op_renovar
               where  op_banco   = or_num_operacion
               and    or_tramite = @w_tramite_nueva   
               and    or_finalizo_renovacion  = 'N'
              )
   return 0


if @@trancount = 0 begin
   begin tran
   select @w_commit = 'S'
end

--- SELECCION DEL NUMERO MAXIMO DEL TRAMITE
if exists(select 1 from   cob_credito..cr_tramite 
where  tr_numero_op_banco = @i_banco
and    tr_subtipo in ('N', 'S', 'T')    --REFINANCIACION, SUBROGACION, OTROS SI;   ANTES ESTABA 'E'
and    tr_estado = 'A')
begin

   update ca_operacion 
   set    op_num_renovacion = isnull(op_num_renovacion, 0) + 1 --NUMERO DE RENOVACION
   where  op_banco          = @i_banco
   and    op_tipo_renovacion = 'R'  --nuevo catalogo de tipos de renovacion, solo se cuenta cuando es renovacion
   
   if @@error <> 0 begin
      select @w_error = 710002, @w_msg = 'ERROR AL ACTUALIZAR EL NUMERO DE RENOVACIONES DEL PRESTAMO '   
      goto ERRORFIN          
   end
end

--ACTUALIZAR DIAS DE MORA
exec @w_error = sp_estado_renreest  
    @s_date             = @w_fecha_ult_proceso,          
    @i_operacion        = 'M',
    @i_tipo             = 'R',
    @i_banco_orig       = @i_banco

if @w_error <> 0 goto ERRORFIN  


exec @w_secuencial = sp_gen_sec
            @i_operacion  = @w_operacionca_n
            
/* LAZO PARA CANCELAR LAS OPERACIONES A RENOVAR */
declare renovacion cursor  for select 
op_banco,             op_operacion,          or_moneda_original,   or_moneda_abono,
op_fecha_ult_proceso, op_estado,             or_saldo_original,    op_cliente,
op_nombre
from   ca_operacion,  cob_credito..cr_op_renovar
where  op_banco   = or_num_operacion
and    or_tramite = @w_tramite_nueva
for read only
   
open renovacion
   
fetch renovacion into  
@w_banco_renovada,   @w_operacionca,       @w_re_moneda_ant, @w_re_moneda_nueva,
@w_fecha_ult_proc,   @w_estado_op_vieja,   @w_monto_pago,
@w_beneficiario,     @w_nombre
   
while @@fetch_status = 0   begin
   if @w_fecha_ini_nueva <> @w_fecha_ult_proc begin                         
      select 
      @w_error = 720303, 
      @w_msg = 'LA FECHA DE ULTIMO PROCESO DE LA OPERACION ' + @w_banco_renovada + ' NO ES IGUAL A LA FECHA DE INICIO DE LA OPERACION NUEVA'
      goto ERROR1          
   end  
      
   if @w_estado_op_vieja in (@w_est_cancelado, @w_est_castigado) begin
      select 
      @w_error = 720303, 
      @w_msg = 'EL ESTADO DE LA OPERACION ' + @w_banco_renovada + ' NO ADMITE RENOVACION'  
      goto ERROR1          
   end       
             
   update cob_credito..cr_op_renovar set   
   or_finalizo_renovacion  = 'S',
   or_sec_prn              = @w_secuencial_ing
   where  or_tramite       = @w_tramite_nueva
   and    or_num_operacion = @w_banco_renovada

   if @@error <> 0 begin
      select @w_error = 710002, @w_msg = 'ERROR AL MARCAR COMO FINALIZADA LA RENOVACION ' + @w_banco_renovada   
      goto ERROR1          
   end
   
/* LPO CDIG Multimoneda, Se comenta para aplicar Multimoneda INICIO
   select @w_monto_renovar_mn = @w_monto_pago
   select @w_monto_pagado = @w_monto_pagado + @w_monto_pago
   
   if @w_moneda <> 0
      begin
         exec sp_buscar_cotizacion
            @i_moneda     = @w_moneda,
            @i_fecha      = @w_op_fecha_ult_proceso,
            @o_cotizacion = @w_cotizacion_hoy out
            
         if @w_cotizacion_hoy is null 
            select @w_cotizacion_hoy = 1
               
         select @w_monto_renovar_mn = round(@w_monto_pago *  @w_cotizacion_hoy, @w_num_dec_mn)      
         select @w_monto_pagado = @w_monto_pagado + @w_monto_renovar_mn
      end
      else
      begin         
            select @w_cotizacion_hoy = 1
      end
*/
-- LPO CDIG Multimoneda, Se comenta para aplicar Multimoneda FIN
   
   
   --LPO CDIG Multimoneda INICIO       
--   IF @w_re_moneda_nueva <> @w_re_moneda_ant
--   BEGIN
         
      exec @w_error = cob_cartera..sp_consulta_divisas
      @s_user                = @s_user,
      @s_term                = @s_term,
      @t_debug               = 'N',  
      @t_file                = 'divisas',  
      @t_from                = 'N',    
      @s_date                = @s_date, --Fecha proceso  
      @s_ofi                 = @s_ofi, --oficina de conexion  
      @s_ssn                 = @s_ssn,  
      @t_trn                 = 77541, --7465,  
      @i_banco               = @w_banco_renovada,
      @i_modulo              = 'CCA',        
      @i_concepto            = 'DES',   -- 'PAG' -- Concepto de la negociaci=n.  Valor del catﬂlogo sb_divisas_modulos.  Se  
      @i_operacion           = 'C',     -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
      @i_cot_contable        = 'N',     -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       
      @i_moneda_origen       = @w_re_moneda_ant, -- Moneda en la cual esta expresado el monto a convertir                   
      @i_valor               = @w_monto_pago,          -- Monto a convertir                                                        
      @i_moneda_destino      = @w_re_moneda_nueva,      
      @o_cotizacion          = @w_cotizacion_mop out,  
      @o_valor_convertido    = @w_monto_moneda_nueva OUT, --@w_monto_renovar_mn out,
      @o_tipo_op             = @w_tipo_mop out
      
      if @@error <> 0 begin
          select @w_error = 710002, @w_msg = 'ERROR AL CONSULTAR LA COTIZACION EN LA RENOVACION ' + @w_banco_renovada   
          goto ERROR1          
      END      
--   END
--   ELSE
--   BEGIN
         exec @w_error = cob_cartera..sp_consulta_divisas
         @s_user                = @s_user,
         @s_term                = @s_term,
         @t_debug               = 'N',  
         @t_file                = 'divisas',  
         @t_from                = 'N',    
         @s_date                = @s_date, --Fecha proceso  
         @s_ofi                 = @s_ofi, --oficina de conexion  
         @s_ssn                 = @s_ssn,  
         @t_trn                 = 77541, --7465,  
         @i_banco               = @w_banco_renovada,
         @i_modulo              = 'CCA',        
         @i_concepto            = 'DES',   -- 'PAG' -- Concepto de la negociaci=n.  Valor del catﬂlogo sb_divisas_modulos.  Se  
         @i_operacion           = 'C',     -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
         @i_cot_contable        = 'N',     -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       
         @i_moneda_origen       = @w_re_moneda_ant, -- Moneda en la cual esta expresado el monto a convertir                   
         @i_valor               = @w_monto_pago,          -- Monto a convertir                                                        
         @i_moneda_destino      = @w_codmn,      
         @o_cotizacion          = @w_cotizacion_mop out,  
         @o_valor_convertido    = @w_monto_renovar_mn OUT, --@w_monto_moneda_nueva OUT, --@w_monto_renovar_mn out,
         @o_tipo_op             = @w_tipo_mop out
         
         if @@error <> 0 begin
             select @w_error = 710002, @w_msg = 'ERROR AL CONSULTAR LA COTIZACION EN LA RENOVACION ' + @w_banco_renovada   
             goto ERROR1          
         END
         
         --SELECT @w_monto_moneda_nueva = @w_monto_pago --Se conserva el mismo monto en la misma moneda de la operacion an
         
   --END
   
   select @w_monto_pagado = @w_monto_pagado + @w_monto_moneda_nueva --@w_monto_renovar_mn
   
/***   --IF @w_re_moneda_nueva <> @w_codmn
   --BEGIN
         exec @w_error = cob_cartera..sp_consulta_divisas
         @s_user                = @s_user,
         @s_term                = @s_term,
         @t_debug               = 'N',  
         @t_file                = 'divisas',  
         @t_from                = 'N',    
         @s_date                = @s_date, --Fecha proceso  
         @s_ofi                 = @s_ofi, --oficina de conexion  
         @s_ssn                 = @s_ssn,  
         @t_trn                 = 77541, --7465,  
         @i_banco               = @w_banco_renovada,
         @i_modulo              = 'CCA',        
         @i_concepto            = 'DES',   -- 'PAG' -- Concepto de la negociaci=n.  Valor del catﬂlogo sb_divisas_modulos.  Se  
         @i_operacion           = 'C',     -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
         @i_cot_contable        = 'N',     -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       
         @i_moneda_origen       = @w_re_moneda_nueva, -- Moneda en la cual esta expresado el monto a convertir                   
         @i_valor               = @w_monto_moneda_nueva,          -- Monto a convertir                                                        
         @i_moneda_destino      = @w_codmn,      
         @o_cotizacion          = @w_cotizacion_mop out,  
         @o_valor_convertido    = @w_monto_renovar_mn out,
         @o_tipo_op             = @w_tipo_mop out
      
      if @@error <> 0 begin
          select @w_error = 710002, @w_msg = 'ERROR AL CONSULTAR LA COTIZACION EN LA RENOVACION ' + @w_banco_renovada   
          goto ERROR1          
      END
***/
      
   --END
   --ELSE --El monto ya esta en moneda nacional
   --BEGIN
   --   SELECT @w_cotizacion_mop = 1.0
   --   SELECT @w_tipo_mop = 'N'
   --   SELECT @w_monto_renovar_mn = @w_monto_moneda_nueva --El monto ya esta en moneda nacional   
   --END
   --LPO CDIG Multimoneda FIN
   
   
   --- CALCULAR NUMERO DE LINEA
   select @w_desembolso = max(dm_desembolso) + 1
   from   ca_desembolso
   where  dm_secuencial = @w_secuencial
   and    dm_operacion  = @w_operacionca_n
   and    dm_estado     = 'NA'

   if @w_desembolso is null
      select @w_desembolso = 1
   
   --LPO CDIG Multimoneda
   SELECT @w_forma_pago = substring(@w_forma_pago, 1,4) + '-' + CAST(@w_re_moneda_nueva AS VARCHAR)
   
      	  
      insert into ca_desembolso
             (dm_secuencial,          dm_operacion,           dm_desembolso,
              dm_producto,            dm_cuenta,              dm_beneficiario,
              dm_oficina_chg,         dm_usuario,             dm_oficina,
              dm_terminal,            dm_dividendo,           dm_moneda,
              dm_monto_mds,           dm_monto_mop,           dm_monto_mn,
              dm_cotizacion_mds,      dm_cotizacion_mop,      dm_tcotizacion_mds,
              dm_tcotizacion_mop,     dm_estado,              dm_cod_banco,
              dm_cheque,              dm_fecha,               dm_prenotificacion,
              dm_carga,               dm_concepto,          
              dm_valor,               dm_ente_benef,          dm_idlote)
                                                                           
      values (@w_secuencial,          @w_operacionca_n,       @w_desembolso,
              @w_forma_pago,          @w_banco_renovada,      @w_nombre, 
              @s_ofi,                 @s_user,                @s_ofi,
              @s_term,                1,                      @w_re_moneda_nueva,
              @w_monto_moneda_nueva,  @w_monto_moneda_nueva,  isnull(@w_monto_renovar_mn,0),
              @w_cotizacion_mop,      @w_cotizacion_mop,      @w_tipo_mop, --'C',
              @w_tipo_mop,            'NA',                   0,
              '0',                    @s_date,                0,
              0,                      'REGISTRO DESEMBOLSO RENOVACION',
              0,                      @w_beneficiario,        0)
      
      if @@error <> 0
      begin
         close renovacion
         deallocate renovacion
      
         select @w_error = 711073
         goto ERRORFIN
      end

--SELECT * FROM ca_desembolso WHERE dm_operacion = @w_operacionca_n AND dm_producto = @w_forma_pago
   
   goto SIGUIENTE
   
   ERROR1:
   
   close renovacion
   deallocate renovacion   
      
   goto ERRORFIN
      
   SIGUIENTE:
   
   fetch renovacion into  
   @w_banco_renovada,   @w_operacionca,       @w_re_moneda_ant, @w_re_moneda_nueva,
   @w_fecha_ult_proc,   @w_estado_op_vieja,   @w_monto_pago,
   @w_beneficiario,     @w_nombre
   
end -- WHILE CURSOR

close renovacion
deallocate renovacion




if @i_valor_renovar > @w_monto_pagado
begin

--LPO CDIG Multimoneda se comenta para utilizar nuevo esquema Multimoneda INICIO
/*
   select @w_monto_pagado = @i_valor_renovar - @w_monto_pagado
   select @w_monto_renovar_mn = @w_monto_pagado
   if @w_moneda <> 0
      begin
         exec sp_buscar_cotizacion
            @i_moneda     = @w_moneda,
            @i_fecha      = @w_op_fecha_ult_proceso,
            @o_cotizacion = @w_cotizacion_hoy out
            
         if @w_cotizacion_hoy is null
            select @w_cotizacion_hoy = 1
               
         select @w_monto_renovar_mn = round(@w_monto_pago *  @w_cotizacion_hoy, @w_num_dec_mn)      
      end
*/
--LPO CDIG Multimoneda se comenta para utilizar nuevo esquema Multimoneda FIN


   --LPO CDIG Multimoneda INICIO
   select @w_monto_pagado = @i_valor_renovar - @w_monto_pagado
   select @w_monto_renovar_mn = @w_monto_pagado
   
   --IF @w_moneda <> @w_codmn
   --BEGIN      
      exec @w_error = cob_cartera..sp_consulta_divisas
      @s_user                = @s_user,
      @s_term                = @s_term,
      @t_debug               = 'N',  
      @t_file                = 'divisas',  
      @t_from                = 'N',    
      @s_date                = @s_date, --Fecha proceso  
      @s_ofi                 = @s_ofi, --oficina de conexion  
      @s_ssn                 = @s_ssn,  
      @t_trn                 = 77541, --7465,  
      @i_banco               = @w_banco_renovada,
      @i_modulo              = 'CCA',        
      @i_concepto            = 'DES',   -- 'PAG' -- Concepto de la negociaci=n.  Valor del catﬂlogo sb_divisas_modulos.  Se  
      @i_operacion           = 'C',     -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
      @i_cot_contable        = 'N',     -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       */  
      @i_moneda_origen       = @w_moneda, -- Moneda en la cual estﬂ expresado el monto a convertir                     */  
      @i_valor               = @w_monto_pagado,          -- Monto a convertir                                                         */  
      @i_moneda_destino      = @w_codmn,      
      @o_cotizacion          = @w_cotizacion_mop out,  
      @o_valor_convertido    = @w_monto_renovar_mn out,
      @o_tipo_op             = @w_tipo_mop out
   
      if @@error <> 0 begin
          select @w_error = 710002, @w_msg = 'ERROR AL CONSULTAR LA COTIZACION EN LA RENOVACION ' + @w_banco_renovada   
          goto ERROR1          
      END      
   --END
   --ELSE
   --BEGIN            
   --   SELECT @w_cotizacion_mop = 1
   --   SELECT @w_tipo_mop = 'N'
   --END
   --LPO CDIG Multimoneda FIN   
   
      
   --- CALCULAR NUMERO DE LINEA
   select @w_desembolso = max(dm_desembolso) + 1
   from   ca_desembolso
   where  dm_secuencial = @w_secuencial
   and    dm_operacion  = @w_operacionca_n
   and    dm_estado     = 'NA'

   if @w_desembolso is null
      select @w_desembolso = 1
      
   insert into ca_desembolso
             (dm_secuencial,      dm_operacion,         dm_desembolso,
              dm_producto,        dm_cuenta,            dm_beneficiario,
              dm_oficina_chg,     dm_usuario,           dm_oficina,
              dm_terminal,        dm_dividendo,         dm_moneda,
              dm_monto_mds,       dm_monto_mop,         dm_monto_mn,
              dm_cotizacion_mds,  dm_cotizacion_mop,    dm_tcotizacion_mds,
              dm_tcotizacion_mop, dm_estado,            dm_cod_banco,
              dm_cheque,          dm_fecha,             dm_prenotificacion,
              dm_carga,           dm_concepto,          dm_valor,
              dm_ente_benef,        dm_idlote)
      
   values    (@w_secuencial,                @w_operacionca_n,                     @w_desembolso,
              isnull(@i_forma_pago,'EFMN'), @i_cuenta_banco,                      @w_nombre, 
              @s_ofi,                       @s_user,                              @s_ofi,
              @s_term,                      1,                                    @w_moneda,
              @w_monto_pagado,              @w_monto_pagado,                      isnull(@w_monto_renovar_mn,0),
              @w_cotizacion_mop,            @w_cotizacion_mop,                    @w_tipo_mop, --'C',
              @w_tipo_mop,                  'NA',                                 0,
              '0',                          @s_date,                              0,
              0,                            'REGISTRO DESEMBOLSO VALOR ADICIONAL',0,
              @w_beneficiario,      0)
            
   if @@error <> 0
   begin
      select @w_error = 711073
      goto ERRORFIN
   end   
end

select @w_num_renovaciones_ant = isnull(max(op_num_renovacion),0)
from   ca_operacion,  cob_credito..cr_op_renovar
where  op_banco   = or_num_operacion
and    or_tramite = @w_tramite_nueva

update ca_operacion set    
op_num_renovacion  = case when op_tipo_renovacion = 'R' then @w_num_renovaciones_ant + 1 else op_num_renovacion end,
op_calificacion    = 'A',
op_oficial         = @w_oficial
--op_numero_reest    = case when op_reestructuracion = 'S' then isnull(op_numero_reest,0) + 1 else op_numero_reest end--La restructura se hace en otro programa CoreBase
where  op_tramite  = @w_tramite_nueva 

if @@error <> 0 begin
   select @w_error = 710002, @w_msg = 'ERROR AL ACTUALIZAR EL NUMERO DE RENOVACIONES '  
   goto ERRORFIN
end


--LIQUIDA   
   update ca_operacion_tmp set opt_estado = 0
   where opt_banco = @i_banco
   
   select @w_banco_fic =  convert(varchar,@w_operacionca_n) --LGBC
   
   exec @w_return         = sp_liquida
        @s_sesn           = @s_sesn,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @i_banco_ficticio = @w_banco_fic, --LGBC @i_banco,
        @i_banco_real     = @i_banco,
        @i_fecha_liq      = @s_date,--@w_fecha_ini,        
        @i_externo        = 'N',
		@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
		@i_es_renovacion  = 'S', --LGBC
        @o_banco_generado = @o_banco_generado out
        
if @w_return <> 0 begin
   select @w_error = @w_return, @w_msg = 'ERROR AL LIQUIDAR RENOVACION'  
   goto ERRORFIN
end


--VALIDACION ESTADOS DE CREACION
exec @w_error = sp_estado_renreest
   @s_date             = @w_fecha_ult_proceso,           
    @i_operacion        = 'E',
    @i_tipo             = 'R',
    @i_banco_orig       = @o_banco_generado,
    @o_estado           = @w_estado_fin out


if @w_error <> 0 goto ERRORFIN   

if @w_estado_fin <> @w_estado_operacion
begin
   exec @w_error = sp_cambio_estado_op
    @s_user           = @s_user,
    @s_term           = @s_term,
    @s_date           = @s_date,
    @s_ofi            = @s_ofi,
    @i_banco          = @o_banco_generado,
    @i_fecha_proceso  = @w_fecha_ult_proceso,
    @i_estado_ini     = @w_estado_operacion, 
    @i_estado_fin     = @w_estado_fin,
    @i_tipo_cambio    = 'M',
    @i_en_linea       = 'N'
    
    if @w_error <> 0 goto ERRORFIN  
end

if @w_commit = 'S' begin
   commit tran 
   select @w_commit = 'N'
end


return 0

ERRORFIN:

if @w_commit = 'S' begin
   rollback tran 
   select @w_commit = 'N'
end

return @w_error

GO

