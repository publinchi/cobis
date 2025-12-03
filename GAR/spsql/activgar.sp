/********************************************************************/
/*   NOMBRE LOGICO:         sp_activar_garantia                     */
/*   NOMBRE FISICO:         activgar.sp                             */
/*   BASE DE DATOS:         cob_custodia                            */
/*   PRODUCTO:              Garantias                               */
/*   DISENADO POR:          MVI                                     */
/*   FECHA DE ESCRITURA:    18-Ago-1999                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*    Este programa se encargara  insertar en las tablas utilizadas */
/*    para la contabilizacion                                       */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*  FECHA         AUTOR           RAZON                             */
/*  18-Ago-1999   X. Tapia.       Emision Inicial                   */
/*  18-Feb-2000   M. Gonzalez.    Adicion clase para contabilizacion*/
/*  07-Oct-2002   G. Solanilla.   Comentarios cob_comext banco      */
/*                                agrario                           */
/*  08-Ago-2019   L. Regalado.    Cancelar Garantia reversa DES Gr  */
/*  22-May-2020   L. Castellanos. CDIG Pignoracion y reversa de DPF */
/*  30-Oct-2020   EMP-JJEC        Pignoracion y reversa de Cuentas  */
/*  12-Jul-2023   P. Jarrin       S858697: Ajuste codigo de error   */
/********************************************************************/

use cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_activar_garantia')
    drop proc sp_activar_garantia
go

create proc sp_activar_garantia
(
   @s_date              datetime    = null,
   @s_ssn               int         = null,    --LRE 06Ago2019
   @s_sesn              int         = null,
   @s_user              varchar(14) = null,
   @s_ofi               smallint    = null,
   @s_rol               int         = null,
   @s_term              varchar(14) = null,
   @s_srv               varchar(20) = null,
   @s_lsrv              varchar(20) = null,
   @s_org               char(1)     = null,
   @t_debug             char(1)     = 'N',    
   @t_file              varchar(14) = null,
   @t_from              varchar(14) = null,
   @i_usuario           login       = null,
   @i_terminal          login       = null,
   @i_tramite           int         = null,
   @i_operacion         char(1)     = null,
   @i_filial            tinyint     = null,
   @i_sucursal          smallint    = null,
   @i_tipo_cust         varchar(64) = null,
   @i_custodia          int         = null,
   @i_modo              smallint    = null,
   @i_opcion            char(1)     = null,
   @i_codigo_externo    varchar(64) = null,
   @i_banderafe         char(1)     = 'S' ,
   @i_reconocimiento    char(1)     = null,
   @i_viene_modvalor    char(1)     = null,
   @i_bandera_be        char(1)     = null,
   @i_rev_des           char(1)     = null     --LRE 06Ago2019
)
as
declare
   @w_sp_name           varchar(32), 
   @w_error             int,
   @w_return            int,
   @w_filial            tinyint,
   @w_sucursal          smallint,
   @w_tramite           int,
   @w_abierta_cerrada   catalogo,
   @w_codigo_externo    varchar(64),
   @w_opcion            char(1),
   @w_agotada           char(1), 
   @w_estado            catalogo,
   @w_estado_gar        catalogo,
   @w_tipo              catalogo,
   @w_custodia          int,
   @w_nuevo_comercial   money,
   @w_clase             char(1), 
   @w_cu_agotada        char(1),
   @w_spid_si2          int,
   @w_bandera_ex        int,
   @w_operacionca       int,
   @w_saldo_cap_gar     money,
   @w_estado_fin        char(1),
   @w_cod_gar_fng       catalogo,
   @w_tran              catalogo,             -- PAQUETE 2: REQ 266 ANEXO GARANTIA - 14/JUL/2011 - GAL
   @w_ente              int,
   @w_grupo             int,
   @w_DPF               varchar(20),
   @w_banco_cartera     varchar(16),
   @w_cuenta_dpf        varchar(20), 
   @w_plazo_fijo        varchar(20),
   @w_gar_pfi           varchar(20),
   @w_valor_actual      money,
   @w_spread            float,
   @w_gar_cta           catalogo,
   @w_moneda            smallint,
   @w_op_banco          cuenta,
   @w_toperacion        catalogo,
   @w_mensaje_bloqueo   varchar(150),
   @w_secuencial        int,
   @w_id_bloqueo_cta    int

select  @w_sp_name  = 'sp_activar_garantia'
select  @w_spid_si2 = @@spid * 100

delete  cu_tmp_operaciones 
where   to_sesion = @w_spid_si2

delete  cu_tmp_garantia 
where   tg_sesion = @w_spid_si2


select @w_cod_gar_fng = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

-- PARAMETRO PARA GARANTIA TIPO PLAZO FIJO
select @w_gar_pfi = pa_char  --LCA CDIG Pignoracion y reversa de DPF
from cobis..cl_parametro 
where pa_producto = 'GAR'
and pa_nemonico = 'GARPFI'

-- PARAMETRO PARA GARANTIA TIPO CUENTA
select @w_gar_cta = pa_char
from cobis..cl_parametro 
where pa_producto = 'GAR'
and pa_nemonico = 'GARCTA'

if @i_tramite is not null
begin

   select  @w_operacionca   = op_operacion,
           @w_banco_cartera = op_banco  --LCA CDIG Pignoracion y reversa de DPF
   from    cob_cartera..ca_operacion
   where   op_tramite      = @i_tramite

   select @w_saldo_cap_gar = (sum(am_cuota + am_gracia - am_pagado))
   from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
   where  ro_operacion  = @w_operacionca
   and    ro_tipo_rubro = 'C'
   and    am_operacion  = @w_operacionca
   and    am_estado     <> 3
   and    am_concepto   = ro_concepto

   if @s_ssn is null
      select @s_ssn = @w_spid_si2 + @w_operacionca
   --SELECT @w_saldo_cap_gar = 0 --LCA para pruebas
   SELECT @w_saldo_cap_gar = ISNULL(@w_saldo_cap_gar,0)
    
   if @i_operacion = 'I'
   begin
      if exists(SELECT 1 
        FROM    cob_credito..cr_gar_propuesta,
                    cob_credito..cr_tramite,
                        cob_custodia..cu_custodia
                WHERE   gp_tramite      = @i_tramite
                and     tr_tramite      = gp_tramite
                and     gp_garantia     = cu_codigo_externo
                and     tr_tipo         in ('R','O', 'U', 'T')
                and     cu_estado   in('P','F','V','X','C'))  -- JAR REQ 266
      begin

         select @w_bandera_ex = 1
      end
      else
      begin
         return 0   
      end
         
      if @i_modo = 1
      begin
         declare cursor_garantia1 
         cursor  for 
         SELECT  gp_tramite,                       cu_estado,                cu_codigo_externo,
                 cu_abierta_cerrada,               cu_agotada,               cu_cuenta_dpf,      
         cu_plazo_fijo,                    cu_tipo,                  cu_valor_actual,
         cu_moneda,                        tr_numero_op_banco,       tr_toperacion,
         cu_id_bloqueo_cta
         FROM    cob_custodia..cu_custodia, 
                 cob_credito..cr_gar_propuesta,
                 cob_credito..cr_tramite
         WHERE   gp_tramite = @i_tramite
         and     gp_garantia    = cu_codigo_externo 
         and     cu_estado  in('P','F','V','X','C') -- JAR REQ 266
         and     tr_tramite     = gp_tramite
         and     tr_tipo    in ('R','O', 'U', 'T')
         for read only
         open cursor_garantia1
         
         fetch cursor_garantia1
         into  @w_tramite,      @w_estado_gar,  @w_codigo_externo,
               @w_abierta_cerrada,  @w_cu_agotada, @w_cuenta_dpf, @w_plazo_fijo, @w_tipo, @w_valor_actual, 
               @w_moneda,       @w_op_banco,  @w_toperacion, 
               @w_id_bloqueo_cta
        
         while @@fetch_status = 0
         begin
            if @i_opcion = 'L' and (@w_estado_gar in ('F','P'))
            begin
               -- INI - PAQUETE 2: REQ 266 - ANEXO GARANTIAS - 14/JUL/2011
               select @w_tran = null
               
               select @w_tran = ce_tran
               from cu_cambios_estado
               where ce_tipo       = 'A'
               and   ce_estado_ini = @w_estado_gar
               and   ce_estado_fin = 'V'
               
               if @w_tran is null
               begin
                  if @i_bandera_be = 'S'
                     return 1912116
                  else
                  begin
                     exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file, 
                     @t_from  = @w_sp_name,
                     @i_num   = 1912116
                     return 1
                  end
               end
               -- FIN - PAQUETE 2: REQ 266 - ANEXO GARANTIAS
            
               exec @w_return = cob_custodia..sp_cambios_estado
               @s_ssn              = @s_ssn,  
               @s_user             = @s_user,
               @s_date             = @s_date,
               @s_term             = @s_term,
               @s_ofi              = @s_ofi,
               @i_operacion        = 'I',
               @i_tipo_tran        = @w_tran,               -- PAQUETE 2: REQ 266 ANEXO GARANTIA - 14/JUL/2011 - GAL
               @i_estado_ini       = @w_estado_gar,
               @i_estado_fin       = 'V',
               @i_codigo_externo   = @w_codigo_externo,
               @i_banderafe        = 'S', 
               @i_banderabe        = @i_bandera_be
               
               if @w_return !=0 
               begin
                  close cursor_garantia1
                  deallocate cursor_garantia1
                  if @i_bandera_be = 'S'
                     return 1910002
                  else
                  begin
                     exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file, 
                     @t_from  = @w_sp_name,
                     @i_num   = 1910002
                     return 1910002
                  end
               end
               -- BLOQUEO PIGNORACION PLAZO FIJO
               if @w_tipo = @w_gar_pfi 
               begin
                  select @w_DPF = isnull(@w_cuenta_dpf, @w_plazo_fijo)
                  if not exists (select 1 from cob_pfijo..pf_operacion, cob_pfijo..pf_pignoracion 
                                 where pi_operacion = op_operacion and op_num_banco = @w_DPF
                                   and pi_cuenta  = @w_banco_cartera and pi_producto= 'CCA')
                  begin
                     exec @w_return = cob_pfijo..sp_pignoracion
                        @s_ssn         = @s_ssn,
                        @s_date        = @s_date,
                        @s_user        = @s_user,
                        @s_term        = @s_term,
                        @s_ofi         = @s_ofi,
                        @s_srv         = @s_srv,
                        @s_lsrv        = @s_lsrv,
                        @s_rol         = @s_rol,
                        @t_debug       = 'N',
                        @t_file        = @t_file,
                        @t_from        = @t_from,
                        @t_trn         = 14107,
                        @i_operacion   = 'I',
                        @i_num_banco   = @w_DPF,
                        @i_producto    = 'CCA',
                        @i_cuenta      = @w_banco_cartera,
                        @i_valor       = @w_valor_actual,
                        @i_tasa        = 0,
                        @i_spread      = 0,
                        @i_observacion = "Garantia por Credito",
                        @i_cuenta_gar  = null,
                        @i_motivo      = 'GAR'
                     if @w_return <> 0 
                     begin
                        /* Error en actualizacion de registro */
                        exec cobis..sp_cerror
                        @t_from  = "sp_vigen_gar",
                        @i_num   = @w_return
                        close cursor_garantia1
                        deallocate cursor_garantia1
                        return @w_return 
                     end
                  end
               end 
               -- FIN BLOQUEO PIGNORACION PLAZO FIJO
               
               
               -- BLOQUEO PIGNORACION CUENTAS
               if @w_tipo = @w_gar_cta 
               begin
                  if @w_cuenta_dpf is null or @w_cuenta_dpf = ''
                     select @w_cuenta_dpf = @w_plazo_fijo
                  select @w_mensaje_bloqueo = 'BLOQUEO POR OPERACION ' + @w_op_banco + ' - ' + @w_toperacion
               
                  exec @w_return = cob_ahorros..sp_tr_bloq_val_ah
                       @s_ssn          = @s_ssn,
                       @s_srv          = @s_srv,
                       @s_lsrv         = @s_lsrv,
                       @s_user         = @s_user,
                       @s_sesn         = @s_sesn,
                       @s_term         = @s_term,
                       @s_date         = @s_date,
                       @s_ofi          = @s_ofi,
                       @s_rol          = @s_rol,
                       @s_org          = @s_org,
                       @t_trn          = 217,
                       @i_cta          = @w_cuenta_dpf,    -- cta a bloquear
                       @i_mon          = @w_moneda,        -- moneda
                       @i_modulo       = 'CCA',            -- modulo desde donde se lo invoxa
                       @i_accion       = 'B',              -- B Bloquear L Levantar Bloqueo
                       @i_valor        = @w_valor_actual,  -- Valor a Bloquear
                       @i_sec          = 0,                -- Cero cuando se bloquea y el n·mero del secuencial cuando se levanta
                       @i_aut          = @s_user,          -- usuario que realiza el bloqueo
                       @i_solicit      = 'AUTOMATICO POR CARTERA',
                       @i_observacion  = @w_mensaje_bloqueo,
                       @i_valida_saldo = 'S',
                       @i_automatico   = 'S',
                       @o_siguiente   = @w_secuencial out

                  if @w_return <> 0 
                  begin
                     /* Error en actualizacion de registro */
                     exec cobis..sp_cerror
                     @t_from  = "sp_tr_bloq_val_ah 1",
                     @i_num   = @w_return
                     close cursor_garantia1
                     deallocate cursor_garantia1
                     return @w_return 
                  end
                       
                  -- ACTUALIZAR SECUENCIAL DE BLOQUEO PARA LEVANTAMIENTO
                  if @w_secuencial > 0
                  begin
                     update cob_custodia..cu_custodia
                        set cu_id_bloqueo_cta = @w_secuencial
                     where  cu_codigo_externo = @w_codigo_externo 
                  end
                  else
                  begin
                     /* Error en actualizacion de registro */
                     exec cobis..sp_cerror
                     @t_from  = "sp_tr_bloq_val_ah 1.1",
                     @i_num   = 1905001
                     close cursor_garantia1
                     deallocate cursor_garantia1
                     return @w_return 
                  end
               end 
               -- FIN BLOQUEO PIGNORACION CUENTAS

               select   @w_clase    = op_clase
               from     cob_cartera..ca_operacion
               where    op_tramite  = @i_tramite
               
               update   cob_custodia..cu_custodia
               set      cu_clase_cartera    = @w_clase
               where    cu_codigo_externo   = @w_codigo_externo
            end
            else
            begin
               if @i_opcion = 'L' and @w_estado_gar = 'C'--P
               begin
                  close cursor_garantia1
                  deallocate cursor_garantia1
                  --print  'Error, no se puede desembolsar una operacion con garantias canceladas'
                  return 725296  -- JAR REQ 266   
               end
            end
            
            if @i_opcion = 'R' and @w_estado_gar = 'V' 
            begin
               if exists(select 1 from  cob_credito..cr_tramite,  cob_credito..cr_gar_propuesta, 
                                        cob_cartera..ca_operacion
                         where  gp_tramite  = tr_tramite
                         and    op_tramite  = tr_tramite
                         and    op_estado   not in (99,0,5,6,3)
                         and    tr_tramite  <>@i_tramite
                         and    gp_garantia = @w_codigo_externo
                         and    tr_tipo     in ('R','O', 'U', 'T') )
               begin  
                  select   @w_bandera_ex = 1
               end 
               else
               begin
               
                  -- INI - PAQUETE 2: REQ 266 - ANEXO GARANTIAS - 14/JUL/2011
                  select @w_tran = null
                  
                  select @w_tran = ce_tran
                  from cu_cambios_estado
                  where ce_tipo       = 'A'
                  and   ce_estado_ini = @w_estado_gar
                  and   ce_estado_fin = 'F'
                  
                  if @w_tran is null
                  begin
                     if @i_bandera_be = 'S'
                        return 1912116
                     else
                     begin
                        close cursor_garantia1
                    deallocate cursor_garantia1

                        exec cobis..sp_cerror
                        @t_debug = @t_debug,
                        @t_file  = @t_file, 
                        @t_from  = @w_sp_name,
                        @i_num   = 1912116
                        return 1
                     end
                  end
                  -- FIN - PAQUETE 2: REQ 266 - ANEXO GARANTIAS
               
                  exec @w_return = cob_custodia..sp_cambios_estado
                  @s_ssn            = @s_ssn,
                  @s_user           = @s_user,
                  @s_date           = @s_date,
                  @s_term           = @s_term,
                  @s_ofi            = @s_ofi,
                  @i_operacion      = 'I',
                  @i_tipo_tran      = @w_tran,               -- PAQUETE 2: REQ 266 ANEXO GARANTIA - 14/JUL/2011 - GAL
                  @i_estado_ini     = @w_estado_gar,
                  @i_estado_fin     = 'P',--F
                  @i_codigo_externo = @w_codigo_externo,
                  @i_banderafe      = 'S', 
                  @i_banderabe      = @i_bandera_be
               
                  if @w_return !=0 
                  begin
                     close cursor_garantia1
                     deallocate cursor_garantia1
                     if @i_bandera_be = 'S'
                        return @w_return --1910003
                     else
                     begin
                         exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file, 
                         @t_from  = @w_sp_name,
                         @i_num   = @w_return --1910003
                         return @w_return --1910003
                     end
                  end

          -- REVERSA PIGNORACION PLAZO FIJO
          if @w_tipo = @w_gar_pfi 
          begin
             select @w_DPF = isnull(@w_cuenta_dpf, @w_plazo_fijo)
             if exists (select 1 from cob_pfijo..pf_operacion, cob_pfijo..pf_pignoracion 
              where pi_operacion = op_operacion and op_num_banco = @w_DPF
                and pi_cuenta  = @w_banco_cartera and pi_producto= 'CCA')
            begin
                select @w_spread = max(pi_spread)
                from cob_pfijo..pf_pignoracion, cob_pfijo..pf_operacion
                where pi_operacion = op_operacion and op_num_banco = @w_DPF
                and pi_cuenta  = @w_banco_cartera and pi_producto= 'CCA'

                exec @w_return = cob_pfijo..sp_pignoracion
                    @s_ssn         = @s_ssn,
                    @s_date        = @s_date,
                    @s_user        = @s_user,
                        @s_term        = @s_term,
                    @s_ofi         = @s_ofi,
                    @s_srv         = @s_srv,
                    @s_lsrv        = @s_lsrv,
                    @s_rol         = @s_rol,
                        @t_debug       = 'N',
                        @t_file        = @t_file,
                        @t_from        = @t_from,
                    @t_trn  = 14307,
                    @i_operacion   = 'D',
                    @i_num_banco   = @w_DPF,
                    @i_producto    = 'CCA',
                    @i_cuenta   = @w_banco_cartera,
                    @i_valor    = @w_valor_actual,
                    @i_tasa = 0,
                    @i_spread      = @w_spread,
                    @i_observacion = "Garantia por Credito",
                    @i_cuenta_gar  = null,
                    @i_motivo   = 'GAR'
                if @w_return <> 0 
                begin
                  /* Error en actualizacion de registro */
                  exec cobis..sp_cerror
                    @t_from  = "sp_vigen_gar",
                    @i_num   = @w_return
                    close cursor_garantia1
                        deallocate cursor_garantia1
                    return @w_return 
                end
             end
          end
          -- FIN REVERSA PIGNORACION PLAZO FIJO  

                  -- REVERSA PIGNORACION DE CUENTAS
                  if @w_tipo = @w_gar_cta 
                  begin
                     if @w_cuenta_dpf is null or @w_cuenta_dpf = ''
                     select @w_cuenta_dpf = @w_plazo_fijo

                     select @w_mensaje_bloqueo = 'DESBLOQUEO POR OPERACION ' + @w_op_banco + ' - ' + @w_toperacion
                  
                     exec @w_return = cob_ahorros..sp_tr_bloq_val_ah
                          @s_ssn          = @s_ssn,
                          @s_srv          = @s_srv,
                          @s_lsrv         = @s_lsrv,
                          @s_user         = @s_user,
                          @s_sesn         = @s_sesn,
                          @s_term         = @s_term,
                          @s_date         = @s_date,
                          @s_ofi          = @s_ofi,
                          @s_rol          = @s_rol,
                          @s_org          = @s_org,
                          @t_trn          = 218,
                          @i_cta          = @w_cuenta_dpf,    -- cta a desbloquear
                          @i_mon          = @w_moneda,        -- moneda
                          @i_modulo       = 'CCA',            -- modulo desde donde se lo invoca
                          @i_accion       = 'L',              -- B Bloquear L Levantar Bloqueo
                          @i_valor        = @w_valor_actual,  -- Valor a desbloquear
                          @i_sec          = @w_id_bloqueo_cta,-- Cero cuando se bloquea y el número del secuencial cuando se levanta
                          @i_aut          = @s_user,          -- usuario que realiza el desbloqueo
                          @i_solicit      = 'AUTOMATICO POR CARTERA',
                          @i_observacion  = @w_mensaje_bloqueo,
                          @i_valida_saldo = 'S',
                          @i_automatico   = 'S'
                  
             if @w_return <> 0 
                     begin
            /* Error en actualizacion de registro */
            exec cobis..sp_cerror
            @t_from  = "sp_tr_bloq_val_ah 2",
            @i_num   = @w_return
            close cursor_garantia1
            deallocate cursor_garantia1
            return @w_return 
                     end                  
                  end 
                  -- FIN PIGNORACION CUENTAS
               end
            end
            fetch cursor_garantia1
            into  @w_tramite,           @w_estado_gar,  @w_codigo_externo,
                  @w_abierta_cerrada,   @w_cu_agotada,  @w_cuenta_dpf,      @w_plazo_fijo, @w_tipo, @w_valor_actual, 
                  @w_moneda,            @w_op_banco,    @w_toperacion,
                  @w_id_bloqueo_cta
         end  
         close cursor_garantia1
         deallocate cursor_garantia1
      end

      if @i_modo = 2   
      begin 
         declare cursor_garantia1 
         cursor  for 
         SELECT  gp_tramite,
                 cu_estado,
                 cu_codigo_externo,
                 cu_abierta_cerrada,          
                 cu_agotada,
         cu_cuenta_dpf,      
         cu_plazo_fijo,                    cu_tipo,                  cu_valor_actual,
         cu_moneda,                        tr_numero_op_banco,       tr_toperacion,
         cu_id_bloqueo_cta
         FROM    cob_custodia..cu_custodia, 
                 cob_credito..cr_gar_propuesta,
                 cob_credito..cr_tramite
         WHERE   gp_tramite     = @i_tramite
         and     gp_garantia    = cu_codigo_externo 
         and     cu_estado      in('P','F','V','X','C') -- JAR REQ 266
         and     tr_tramite     = gp_tramite
         and     tr_tipo       in ('R','O', 'U', 'T')
         for read only
         open cursor_garantia1
         
         fetch cursor_garantia1
         into  @w_tramite,      @w_estado_gar,  @w_codigo_externo,
               @w_abierta_cerrada,  @w_cu_agotada, @w_cuenta_dpf,      @w_plazo_fijo, @w_tipo, @w_valor_actual, 
               @w_moneda,            @w_op_banco,    @w_toperacion,
               @w_id_bloqueo_cta
        
         while @@fetch_status = 0
         begin
            if @i_opcion in('P','C') and @w_saldo_cap_gar <> 0 and @i_rev_des is null 
            begin
               close cursor_garantia1
               deallocate cursor_garantia1
               return 0
            end
            if @i_opcion = 'D' and (@w_estado_gar ='X' or @w_estado_gar = 'F' or @w_estado_gar = 'C') -- JAR REQ 266
            begin
               -- INI - PAQUETE 2: REQ 266 - ANEXO GARANTIAS - 14/JUL/2011
               select @w_tran = null
               
               select @w_tran = ce_tran
               from cu_cambios_estado
               where ce_tipo       = 'A'
               and   ce_estado_ini = @w_estado_gar
               and   ce_estado_fin = 'V'
               
               if @w_tran is null
               begin
                  if @i_bandera_be = 'S'
                     return 1912116
                  else
                  begin
                     exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file, 
                     @t_from  = @w_sp_name,
                     @i_num   = 1912116
                     return 1
                  end
               end
               -- FIN - PAQUETE 2: REQ 266 - ANEXO GARANTIAS
               exec @w_return = cob_custodia..sp_cambios_estado
               @s_ssn            = @s_ssn,
               @s_user           = @s_user,
               @s_date           = @s_date,
               @s_term           = @s_term,
               @s_ofi            = @s_ofi,
               @i_operacion      = 'I',
               @i_tipo_tran      = @w_tran,               -- PAQUETE 2: REQ 266 ANEXO GARANTIA - 14/JUL/2011 - GAL
               @i_estado_ini     = @w_estado_gar,
               @i_estado_fin     = 'V',
               @i_codigo_externo = @w_codigo_externo,
               @i_banderafe      = 'S', 
               @i_banderabe      = @i_bandera_be
               
               if @w_return !=0 
               begin
                  close cursor_garantia1
                  deallocate cursor_garantia1
                  if @i_bandera_be = 'S'
                     return 1910002
                  else
                  begin
                     exec cobis..sp_cerror
                       @t_debug = @t_debug,
                       @t_file  = @t_file, 
                       @t_from  = @w_sp_name,
                       @i_num   = 1910002
                     return 1910002
                  end
               end
            
               select   @w_clase    = op_clase
               from     cob_cartera..ca_operacion
               where    op_tramite  = @i_tramite
               
               update   cob_custodia..cu_custodia
               set      cu_clase_cartera    = @w_clase
               where    cu_codigo_externo   = @w_codigo_externo
               

               -- LEVANTAMIENTO PIGNORACION PLAZO FIJO (Reverso PAGO, reverso cancelacion de garantias, las vuelve a poner Vigente)
               if @w_tipo = @w_gar_pfi 
               begin
          select @w_DPF = isnull(@w_cuenta_dpf, @w_plazo_fijo)
                  if not exists (select 1 from cob_pfijo..pf_operacion, cob_pfijo..pf_pignoracion 
                                 where pi_operacion = op_operacion and op_num_banco = @w_DPF
                                   and pi_cuenta  = @w_banco_cartera and pi_producto= 'CCA')
                  begin
                     select @w_valor_actual = isnull(cu_valor_actual,0)
                       from cob_custodia..cu_custodia
                      where cu_codigo_externo = @w_codigo_externo

                     exec @w_return = cob_pfijo..sp_pignoracion
                          @s_ssn         = @s_ssn,
                          @s_date        = @s_date,
                          @s_user        = @s_user,
                          @s_term        = @s_term,
                          @s_ofi         = @s_ofi,
                          @s_srv         = @s_srv,
                          @s_lsrv        = @s_lsrv,
                          @s_rol         = @s_rol,
                          @t_debug       = 'N',
                          @t_file        = @t_file,
                          @t_from        = @t_from,
                          @t_trn        =  14107,
                          @i_operacion   = 'I',
                          @i_num_banco   = @w_DPF,
                          @i_producto    = 'CCA',
                          @i_cuenta = @w_banco_cartera,
                          @i_valor  = @w_valor_actual,
                          @i_tasa   = 0,
                          @i_spread      = 0,
                          @i_observacion = "Garantia por Credito",
                          @i_cuenta_gar  = null,
                          @i_motivo = 'GAR'
                
                     if @w_return <> 0 
                     begin
                        /* Error en actualizacion de registro */
                        exec cobis..sp_cerror
                        @t_from  = "sp_vigen_gar",
                        @i_num   = @w_return
                        close cursor_garantia1
                        deallocate cursor_garantia1
                        return @w_return 
                     end
                  end
               end
               -- FIN LEVANTAMIENTO PIGNORACION PLAZO FIJO

               -- LEVANTAMIENTO DE PIGNORACION DE CUENTAS (Reverso PAGO, reverso cancelacion de garantias, las vuelve a poner Vigente)
               if @w_tipo = @w_gar_cta 
               begin
                  if @w_cuenta_dpf is null or @w_cuenta_dpf = ''
                     select @w_cuenta_dpf = @w_plazo_fijo
                  select @w_mensaje_bloqueo = 'BLOQUEO POR REVERSO TRN OPERACION ' + @w_op_banco + ' - ' + @w_toperacion
               
                  if @w_valor_actual = 0
                    select @w_valor_actual = cu_valor_inicial
                    from cob_custodia..cu_custodia
                    where cu_codigo_externo = @w_codigo_externo
               
                  exec @w_return = cob_ahorros..sp_tr_bloq_val_ah
                       @s_ssn          = @s_ssn,
                       @s_srv          = @s_srv,
                       @s_lsrv         = @s_lsrv,
                       @s_user         = @s_user,
                       @s_sesn         = @s_sesn,
                       @s_term         = @s_term,
                       @s_date         = @s_date,
                       @s_ofi          = @s_ofi,
                       @s_rol          = @s_rol,
                       @s_org          = @s_org,
                       @t_trn          = 217,
                       @i_cta          = @w_cuenta_dpf,    -- cta a desbloquear
                       @i_mon          = @w_moneda,        -- moneda
                       @i_modulo       = 'CCA',            -- modulo desde donde se lo invoca
                       @i_accion       = 'B',              -- B Bloquear L Levantar Bloqueo
                       @i_valor        = @w_valor_actual,  -- Valor a desbloquear
                       @i_sec          = 0,-- Cero cuando se bloquea y el número del secuencial cuando se levanta
                       @i_aut          = @s_user,          -- usuario que realiza el desbloqueo
                       @i_solicit      = 'AUTOMATICO POR CARTERA',
                       @i_observacion  = @w_mensaje_bloqueo,
                       @i_valida_saldo = 'S',
                       @i_automatico   = 'S',
                       @o_siguiente    = @w_secuencial out
               
          if @w_return <> 0 
                  begin
             /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_from  = "sp_tr_bloq_val_ah 3",
             @i_num   = @w_return
             close cursor_garantia1
             deallocate cursor_garantia1
             return @w_return 
                  end

                  -- ACTUALIZAR SECUENCIAL DE BLOQUEO PARA LEVANTAMIENTO
                  if @w_secuencial > 0
                  begin
                     update cob_custodia..cu_custodia
                        set cu_id_bloqueo_cta = @w_secuencial
                     where  cu_codigo_externo = @w_codigo_externo 
                  end
                  else
                  begin
                     /* Error en actualizacion de registro */
                     exec cobis..sp_cerror
                     @t_from  = "sp_tr_bloq_val_ah 3.1",
                     @i_num   = 1905001
                     close cursor_garantia1
                     deallocate cursor_garantia1
                     return @w_return 
                  end
               end 
               -- FIN LEVANTAMIETO PIGNORACION CUENTAS
            end
            
            if @i_opcion in('P','C') and @w_estado_gar = 'V' --Cancela Garantia
            begin
               if exists(select 1 from   cob_credito..cr_tramite,
                         cob_credito..cr_gar_propuesta,
                         cob_cartera..ca_operacion
                         where  gp_tramite  = tr_tramite
                           and  op_tramite  = tr_tramite
                           and  op_estado   not in (99,0,5,6,3)
                           and  tr_tramite  <>@i_tramite
                           and  gp_garantia = @w_codigo_externo
                           and  tr_tipo         in('R','O', 'U', 'T') )              
               begin 
                  select   @w_bandera_ex = 1
               end 
               else
               begin
                  if exists(select 1 from  cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia where cu_tipo = tc_tipo  and tc_tipo_superior = 'LIQ' and cu_codigo_externo = @w_codigo_externo)
                  begin
                     select   
                     @w_ente     = op_cliente,
                     @w_operacionca = op_operacion
                     from     cob_cartera..ca_operacion
                     where    op_tramite  = @i_tramite
                     
                     select 
                     @w_grupo = dc_grupo,
                     @w_tramite = ci_tramite
                     from cob_cartera..ca_ciclo,cob_cartera..ca_det_ciclo 
                     where ci_ciclo = dc_ciclo 
                     and ci_grupo = dc_grupo
                     and dc_operacion = @w_operacionca
                     and dc_cliente = @w_ente
                                                               
                     select @w_estado_fin  = 'C'
                  end
                  else
                  begin
                     --select @w_estado_fin  = 'X'
             select @w_estado_fin  = 'C'
                  end

                  -- INI - PAQUETE 2: REQ 266 - ANEXO GARANTIAS - 14/JUL/2011 - GAL
                  select @w_tran = null
                  
                  select @w_tran = ce_tran
                  from cu_cambios_estado
                  where ce_tipo       = 'A'
                  and   ce_estado_ini = @w_estado_gar
                  and   ce_estado_fin = @w_estado_fin
                  
                  if @w_tran is null
                  BEGIN
                     close cursor_garantia1
                     deallocate cursor_garantia1
                     if @i_bandera_be = 'S'
                        return 1912116
                     else
                     begin
                        exec cobis..sp_cerror
                        @t_debug = @t_debug,
                        @t_file  = @t_file, 
                        @t_from  = @w_sp_name,
                        @i_num   = 1912116
                        return 1
                     end
                  end
                  -- FIN - PAQUETE 2: REQ 266 - ANEXO GARANTIAS
                  exec @w_return = cob_custodia..sp_cambios_estado
                  @s_ssn            = @s_ssn,     --LRE 07Ago2019
                  @s_user           = @s_user,
                  @s_date           = @s_date,
                  @s_term           = @s_term,
                  @s_ofi            = @s_ofi,
                  @i_operacion      = 'I',
                  @i_tipo_tran      = @w_tran,               -- PAQUETE 2: REQ 266 ANEXO GARANTIA - 14/JUL/2011 - GAL
                  @i_estado_ini     = @w_estado_gar,
                  @i_estado_fin     = @w_estado_fin,
                  @i_codigo_externo = @w_codigo_externo,
                  @i_banderafe      = 'S', 
                  @i_banderabe      = @i_bandera_be
                  
                  if @w_return !=0 
                  begin
                     close cursor_garantia1
                     deallocate cursor_garantia1
                     if @i_bandera_be = 'S'
                        return @w_return --1910003
                     else
                     begin
                         exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file, 
                         @t_from  = @w_sp_name,
                         @i_num   = @w_return --1910003
                         return @w_return --1910003
                     end
                  end

          -- PIGNORACION PLAZO FIJO (Aplica Pago y cancelacion de garantias)
          if @w_tipo = @w_gar_pfi 
          begin
             select @w_DPF = isnull(@w_cuenta_dpf, @w_plazo_fijo)
             if exists (select 1 from cob_pfijo..pf_operacion, cob_pfijo..pf_pignoracion 
              where pi_operacion = op_operacion and op_num_banco = @w_DPF
                and pi_cuenta  = @w_banco_cartera and pi_producto= 'CCA')
                     begin
                        select @w_spread = max(pi_spread)
                        from cob_pfijo..pf_pignoracion, cob_pfijo..pf_operacion
                        where pi_operacion = op_operacion and op_num_banco = @w_DPF
                        and pi_cuenta  = @w_banco_cartera and pi_producto= 'CCA'

                        exec @w_return = cob_pfijo..sp_pignoracion
                        @s_ssn         = @s_ssn,
                        @s_date        = @s_date,
                        @s_user        = @s_user,
                        @s_term        = @s_term,
                        @s_ofi         = @s_ofi,
                        @s_srv         = @s_srv,
                        @s_lsrv        = @s_lsrv,
                        @s_rol         = @s_rol,
                        @t_debug       = 'N',
                        @t_file        = @t_file,
                        @t_from        = @t_from,
                        @t_trn         = 14307,
                        @i_operacion   = 'D',
                        @i_num_banco   = @w_DPF,
                        @i_producto    = 'CCA',
                        @i_cuenta      = @w_banco_cartera,
                        @i_valor       = @w_valor_actual,
                        @i_tasa        = 0,
                        @i_spread      = @w_spread,
                        @i_observacion = "Garantia por Credito",
                        @i_cuenta_gar  = null,
                        @i_motivo      = 'GAR'

                        if @w_return <> 0 
                        begin
                           /* Error en actualizacion de registro */
                           exec cobis..sp_cerror
                                @t_from  = "sp_vigen_gar",
                                @i_num   = @w_return 
                                close cursor_garantia1
                                deallocate cursor_garantia1
                                return @w_return 
                        end
                     end
          end
          -- FIN PIGNORACION PLAZO FIJO

                  -- LEVANTAMIENTO DE PIGNORACION DE CUENTAS (Reverso PAGO, reverso cancelacion de garantias, las vuelve a poner Vigente)
                  if @w_tipo = @w_gar_cta 
                  begin
                     if @w_cuenta_dpf is null or @w_cuenta_dpf = ''
                        select @w_cuenta_dpf = @w_plazo_fijo

                     select @w_mensaje_bloqueo = 'DESBLOQUEO POR OPERACION ' + @w_op_banco + ' - ' + @w_toperacion
                  
                     exec @w_return = cob_ahorros..sp_tr_bloq_val_ah
                          @s_ssn          = @s_ssn,
                          @s_srv          = @s_srv,
                          @s_lsrv         = @s_lsrv,
                          @s_user         = @s_user,
                          @s_sesn         = @s_sesn,
                          @s_term         = @s_term,
                          @s_date         = @s_date,
                          @s_ofi          = @s_ofi,
                          @s_rol          = @s_rol,
                          @s_org          = @s_org,
                          @t_trn          = 218,
                          @i_cta          = @w_cuenta_dpf,    -- cta a desbloquear
                          @i_mon          = @w_moneda,        -- moneda
                          @i_modulo       = 'CCA',            -- modulo desde donde se lo invoca
                          @i_accion       = 'L',              -- B Bloquear L Levantar Bloqueo
                          @i_valor        = @w_valor_actual,  -- Valor a desbloquear
                          @i_sec          = @w_id_bloqueo_cta,-- Cero cuando se bloquea y el número del secuencial cuando se levanta
                          @i_aut          = @s_user,          -- usuario que realiza el desbloqueo
                          @i_solicit      = 'AUTOMATICO POR CARTERA',
                          @i_observacion  = @w_mensaje_bloqueo,
                          @i_valida_saldo = 'S',
                          @i_automatico   = 'S'
                  
             if @w_return <> 0 
                     begin
                /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_from  = "sp_tr_bloq_val_ah 4",
                @i_num   = @w_return
                close cursor_garantia1
                deallocate cursor_garantia1
                return @w_return 
                     end                  
                  end 
                  -- FIN LEVANTAMIETO PIGNORACION CUENTAS         
               end
            end
            fetch cursor_garantia1
            into  @w_tramite,       @w_estado_gar,  @w_codigo_externo,
                  @w_abierta_cerrada,   @w_cu_agotada, @w_cuenta_dpf,      @w_plazo_fijo, @w_tipo, @w_valor_actual, 
                  @w_moneda,            @w_op_banco,    @w_toperacion,
                  @w_id_bloqueo_cta
         end -- FIN WHILE
         close cursor_garantia1
         deallocate cursor_garantia1
      end -- FIN MODO 2
   end  -- FIN @i_operacion = 'I'
end -- FIN @i_tramite is not null

return 0

GO

