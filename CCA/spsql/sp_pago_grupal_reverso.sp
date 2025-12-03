/************************************************************************/
/*  NOMBRE LOGICO:        sp_pago_grupal_reverso.sp                     */
/*  NOMBRE FISICO:        sp_pago_grupal_reverso                        */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Juan Carlos Guzman                            */
/*  FECHA DE ESCRITURA:   06/Feb/2023                                   */
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
/*                        PROPOSITO                                     */
/*  Este programa realiza los reversos de los pagos de operaciones hijas*/
/*  y grupal en prestamos grupales                                      */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR              RAZON                              */
/*  06/Feb/2023   Juan Guzman        Emisi�n Inicial                    */
/*  25/Abr/2023   Guisela Fernandez  S785497 Correcci�n por validacion  */
/*                                   de reversos de pagos grupales      */
/*  07/06/2023    Kevin Rodr�guez    S787160 Tanqueo Factura Electr�nica*/
/*  12/07/2023    Guisela Fernandez  B864019 Se elimina parametro de atx*/
/*  28/07/2023    Guisela Fernandez  S857741 Parametros de licitud      */
/*  07/11/2023    Kevin Rodriguez    Suprimir val. de préstamos cancelad*/
/*  17/11/2023    Kevin Rodríguez    R217688 Ajuste Valid. tanqueo fact */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_pago_grupal_reverso')
   drop proc sp_pago_grupal_reverso
go

create procedure sp_pago_grupal_reverso
(
   @s_srv                          varchar(30)  = null,
   @s_user                         login        = null,
   @s_term                         descripcion  = null,
   @s_ofi                          smallint     = null,
   @s_rol                          smallint     = null,
   @s_ssn                          int          = null,
   @s_lsrv                         varchar(30)  = null,
   @s_date                         datetime     = null,
   @s_sesn                         int          = null,
   @s_org                          char(1)      = null,
   @s_culture                      varchar(10)  = 'NEUTRAL',
   @t_debug                        char(1)      = 'N',
   @t_file                         varchar(14)  = null,
   @t_trn                          int          = null,
   @i_operacion                    char(1)      = 'R',
   @i_canal                        int          = null,         -- 1: CARTERA, 2: BATCH, 3: SERVICIO WEB(BCOR), 4: ATX
   @i_banco_grupal                 cuenta       = null, 
   @i_secuencial_ing_abono_grupal  int          = null,
   @i_externo                      char(1)      = 'N',
   @i_en_linea                     char(1)      = 'S',
   @i_observacion                  descripcion  = null,
   @i_aplica_licitud               char         = 'N', --GFP Aplica licitud de fondos,
   -- Par�metros salida factura electr�nica
   @o_guid                         varchar(36)  = null out,
   @o_fecha_registro               varchar(10)  = null out,
   @o_ssn                          int          = null out,
   @o_orquestador_fact             char(1)      = null out
)
as

declare @w_sp_name            descripcion,
        @w_error              int,
        @w_max_registros      int,
        @w_count              int,
        @w_secuencial_pag     int,
        @w_secuencial_ing     int,
        @w_tipo_ope           char(1),
        @w_estado_abono       char(3),
        @w_banco              cuenta,
        @w_operacion_cca      int,
        @w_categoria          catalogo,
        @w_concepto           catalogo,
        @w_monto_inter        money,          
        @w_secuencial_inter   int,
        @w_causal             varchar(14),
        @w_fecha_valor        datetime,
        @w_cod_banco          int,
        @w_numero_cuenta      cuenta,
        @w_referencial        varchar(50),
        @w_secuencial_atx     int,
		@w_tr_fecha_mov       datetime,
		@w_ssn                int,
		@w_guid_dte           varchar(36)


select @w_sp_name     = 'sp_pago_grupal_reverso',
       @i_observacion = isnull(@i_observacion, 'REVERSO PROCESO DE PAGO GRUPAL')
       
-- Tabla temporal de informaci�n de abonos de operaciones hijas y operaci�n padre
if exists (select 1 from sysobjects where name = '#ca_abonos_grupal_rev')
   drop table #ca_abonos_grupal_rev
   
if @@error != 0
begin
   /* Error al eliminar tabla temporal #ca_abonos_grupal_rev */
   select @w_error = 725262
   
   goto ERROR
end

create table #ca_abonos_grupal_rev(
   ar_id              int      identity(1,1),
   ar_estado          char(3)  not null,
   ar_secuencial_pag  int      not null,
   ar_secuencial_ing  int      not null,
   ar_tipo_ope        char(1)  not null,
   ar_operacion       int         not null,
   ar_ssn             int         null,
   ar_guid_dte        varchar(36) null
)

if @@error != 0
begin
   /* Error al crear tabla temporal #ca_abonos_grupal_rev */
   select @w_error = 725263
   
   goto ERROR
end


if @i_operacion = 'R'
begin

   /* Cuando el canal es 4 (ATX) el par�metro @i_secuencial_ing_abono_grupal tendr� el secuencial
      de ATX y se debe obtener el secuencial de CCA correspondiente */
   if @i_canal = 4
   begin
      select @w_secuencial_atx = @i_secuencial_ing_abono_grupal
   
      select @i_secuencial_ing_abono_grupal = sa_secuencial_cca
      from ca_secuencial_atx
      where sa_ssn_corr  = @w_secuencial_atx
      and sa_fecha_ing = @s_date
      and sa_oficina  = isnull(@s_ofi,0)
      and sa_operacion = @i_banco_grupal
      and sa_estado    = 'A'

      if @@error != 0 or @@rowcount = 0
      begin
         /* Error al seleccionar secuencial de cartera para reverso de pago grupal desde ATX */
         select @w_error  = 725268
         
         goto ERROR
      end
   end
   
   /* Si las fechas de ult. proceso de las operaciones hijas no son iguales a excepcion de las canceladas que congelan su fecha ult proceso  */
   select @w_fecha_valor = op_fecha_ult_proceso  
   from ca_operacion,
        ca_abono
   where op_grupal             = 'S'
   and op_ref_grupal           = @i_banco_grupal
   and op_operacion              = ab_operacion
   and op_estado                 <> 3
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
   group by op_fecha_ult_proceso
   
   if (@@rowcount > 1)
   begin
      /* Error, No todas las operaciones del pago grupal tienen la misma fecha valor */
      select @w_error = 725265 
      goto ERROR
   end
   
   /* Si existe por lo menos un abono de una operaci�n hija en estado distinto de aplicado */
   if exists(select 1 
             from ca_operacion,
                  ca_abono
             where op_grupal                = 'S'
			 and op_ref_grupal              = @i_banco_grupal
             and op_operacion               = ab_operacion
             and ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
             and ab_estado                      <> 'A')
   begin
      /* Error, Existen abonos del pago grupal en estado distinto de aplicado */
      select @w_error = 725266 
      goto ERROR
   end
   
   select @w_tr_fecha_mov = isnull(max(tr_fecha_mov), '01/01/1900')
   from ca_operacion with (nolock), 
        ca_abono with (nolock), 
		ca_transaccion
   where op_grupal                    = 'S'
   and op_ref_grupal                  = @i_banco_grupal
   and op_operacion                   = ab_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
   and ab_operacion                   = tr_operacion
   and ab_secuencial_pag              = tr_secuencial
   and tr_tran                        = 'PAG'
   and tr_estado                      <> 'RV'


   if @i_externo = 'S'
      begin tran
   
   /* Inserci�n de registros de abonos para operaciones hijas */
   insert into #ca_abonos_grupal_rev
   select ab_estado,
          ab_secuencial_pag,
          ab_secuencial_ing,
          'H',
          ab_operacion,
		  ab_ssn,
		  ab_guid_dte
   from ca_operacion,
        ca_abono
   where op_grupal               = 'S'
   and op_ref_grupal             = @i_banco_grupal
   and op_operacion              = ab_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
   union all
   /* Inserci�n de registro de abono de operaci�n padre */
   select ab_estado,
          ab_secuencial_pag,
          ab_secuencial_ing,
          'P',
          ab_operacion,
		  ab_ssn,
		  ab_guid_dte
   from ca_operacion,
        ca_abono
   where op_banco        = @i_banco_grupal
   and op_operacion = ab_operacion
   and ab_secuencial_ing = @i_secuencial_ing_abono_grupal
   
   if @@error != 0
   begin
      /* Error en insercion tabla #ca_abonos_grupal_rev */
      select @w_error  = 703137
      
      goto ERROR
   end
   
   select @w_max_registros = count(1)
   from #ca_abonos_grupal_rev
   
   select @w_count = 1
   
   while @w_count <= @w_max_registros
   begin
      select @w_secuencial_ing = ar_secuencial_ing,
             @w_secuencial_pag = ar_secuencial_pag,
             @w_tipo_ope       = ar_tipo_ope,
             @w_estado_abono   = ar_estado,
             @w_operacion_cca  = ar_operacion,
			 @w_ssn            = ar_ssn,
			 @w_guid_dte       = ar_guid_dte
      from #ca_abonos_grupal_rev
      where ar_id = @w_count
      
      
      /* Validaciones de estados de abonos para operaciones Hijas */
      if @w_tipo_ope = 'H'
      begin
         select @w_banco = op_banco
         from ca_operacion
         where op_operacion= @w_operacion_cca
      
         if @w_estado_abono = 'A'
         begin
            exec @w_error  = cob_cartera..sp_fecha_valor
               @s_srv                  = @s_srv,
               @s_user                 = @s_user,
               @s_term                 = @s_term,
               @s_ofi                  = @s_ofi,
               @s_rol                  = @s_rol,
               @s_ssn                  = @s_ssn,
               @s_lsrv                 = @s_lsrv,
               @s_date                 = @s_date,
               @s_sesn                 = @s_sesn,
               @s_org                  = @s_org,
               @t_trn                  = 7049,
               @t_debug                = @t_debug,
               @t_file                 = @t_file,
               @i_banco                = @w_banco,
               @i_secuencial           = @w_secuencial_pag,
               @i_operacion            = 'R',
               @i_observacion          = @i_observacion,
               @i_rev_pago_grupal_hijo = 'S',
               @i_en_linea             = @i_en_linea,
			   @i_aplica_licitud       = @i_aplica_licitud 
               
            if @w_error <> 0
            begin
               goto ERROR
            end
         end
         
         if @w_estado_abono in ('ING', 'NA')
         begin
            exec @w_error = sp_eliminar_pagos
               @t_trn            = 7036,
               @i_banco          = @w_banco,
               @i_operacion      = 'D',
               @i_secuencial_ing = @w_secuencial_ing,
               @i_en_linea       = @i_en_linea
            
            if @w_error <> 0
            begin
               goto ERROR
            end
         end
      end  --end @w_tipo_ope = 'H'
      
      
      /* Validaciones de estados de abonos para operacion Padre */
      if @w_tipo_ope = 'P'
      begin
         select @w_cod_banco        = abd_cod_banco,
                @w_numero_cuenta    = abd_cuenta,
                @w_referencial      = abd_beneficiario,
                @w_monto_inter      = abd_monto_mpg,
                @w_secuencial_inter = abd_secuencial_interfaces,
                @w_concepto         = abd_concepto
         from ca_abono_det
         where abd_secuencial_ing = @w_secuencial_ing
         and abd_operacion = @w_operacion_cca
         and abd_tipo = 'PAG'
         
         select @w_categoria = cp_categoria 
         from ca_producto
         where cp_producto = @w_concepto
    
         
         if @w_estado_abono = 'A' 
         begin
		    if (@w_categoria = 'BCOR' OR @w_categoria = 'MOEL')
			begin
               select @w_causal = c.valor 
               from cobis..cl_tabla t, 
                    cobis..cl_catalogo c
               where t.tabla  = 'ca_fpago_causalbancos'
               and   t.codigo = c.tabla
               and   c.estado = 'V'
               and   c.codigo = @w_concepto
               
               if @@rowcount = 0 or @w_causal is null
               begin
                  select @w_error = 725139 -- Error, no existe causal para la forma de pago actual, revisar cat�logo ca_fpago_causalbancos
                  goto ERROR
               end
               
               exec @w_error = sp_func_bancos_cca
                  @s_date             = @s_date,
                  @s_ofi              = @s_ofi,
                  @s_user             = @s_user,
                  @s_ssn              = @s_ssn,
                  @i_operacion        = 'R',
                  @i_opcion           = 0,
                  @i_cod_banco        = @w_cod_banco,
                  @i_cuenta           = @w_numero_cuenta,
                  @i_causal           = @w_causal,
                  @i_beneficiario     = @w_referencial,
                  @i_monto            = @w_monto_inter,
                  @i_banco            = @i_banco_grupal,
                  @i_secuencial_inter = @w_secuencial_inter,
                  @i_secuencial_ing   = @w_secuencial_ing,
                  @i_operacion_cca    = @w_operacion_cca
                  
               if @w_error <> 0 begin
                  goto ERROR
               end
            end
			
            update ca_abono
            set ab_estado = 'RV'
            where ab_operacion      = @w_operacion_cca
            and   ab_secuencial_ing = @w_secuencial_ing
            
            if @@error != 0 
            begin
               /* Error en actualizacion en tabla ca_abono */
               select @w_error = 705081
               
               goto ERROR
            end
               
         end
      
      
         if @w_estado_abono in ('REG', 'ING')
         begin
            update ca_abono
            set ab_estado = 'E'
            where ab_operacion      = @w_operacion_cca
            and   ab_secuencial_ing = @w_secuencial_ing
            
            if @@error != 0 
            begin
               /* Error en actualizacion en tabla ca_abono */
               select @w_error = 705081
               
               goto ERROR
            end
         end
		 
         -- Reverso Facturaci�n electr�nica
         if @w_ssn is not null and @w_guid_dte is not null
         begin

            exec @w_error = sp_tanqueo_fact_cartera
            @s_user             = @s_user,
            @s_date             = @s_date,
            @s_rol              = @s_rol,
            @s_term             = @s_term,
            @s_ofi              = @s_ofi,
            @s_ssn              = @s_ssn,
            @t_corr             = 'S',
            @t_ssn_corr         = @w_ssn,
            @t_fecha_ssn_corr   = @w_tr_fecha_mov,
            @i_ope_banco        = @i_banco_grupal,
            @i_externo          = 'N',
            @i_tipo_tran        = 'PAG',
            @i_operacion        = 'R',
            @o_guid             = @o_guid             out,
            @o_fecha_registro   = @o_fecha_registro   out,
            @o_ssn              = @o_ssn              out,
            @o_orquestador_fact = @o_orquestador_fact out
			
            if @w_error <> 0
		    begin
		       if @w_error <> 1720647 -- IGNORA ERROR TANQUEO, YA QUE ESTE ERROR REPRESENTA RV A NIVEL DE COBIS  
                  goto ERROR
            end
         end
	  
      end --end @w_tipo_ope = 'P'
      
      select @w_count = @w_count + 1
   end --END WHILE
   
   /* Si el @i_canal = 4 (ATX) y el reverso termina bien, se reversa el registro en la tabla
      ca_secuencial_atx */
   if @i_canal = 4
   begin
      update ca_secuencial_atx
      set    sa_estado          = 'R'
      where  sa_operacion       = @i_banco_grupal
      and    sa_secuencial_cca  = @i_secuencial_ing_abono_grupal
      and    sa_ssn_corr        = @w_secuencial_atx
      and    sa_fecha_ing       = @s_date
      and    sa_oficina         = isnull(@s_ofi,0)
      
      if @@error != 0 
      begin
         /* Error en actualizacion en tabla ca_secuencial_atx */
         select @w_error = 705082
         
         goto ERROR
      end
   end
   
   if @i_externo = 'S'
      commit tran
end


return 0


ERROR:
if @i_externo = 'S' begin
while @@TRANCOUNT > 0 rollback tran

exec cobis..sp_cerror
@t_debug = 'N',
@t_file = '',
@t_from = @w_sp_name,
@i_num = @w_error

   return @w_error
end
else
return @w_error

go
