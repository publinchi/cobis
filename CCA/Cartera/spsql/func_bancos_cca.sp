/************************************************************************/
/*   NOMBRE LOGICO:      func_bancos_cca.sp                             */
/*   NOMBRE FISICO:      sp_func_bancos_cca                             */
/*   BASE DE DATOS:        cob_cartera                                  */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Diciembre 2021                                 */
/************************************************************************/
/*                           IMPORTANTE                                 */
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
/*                           PROPOSITO                                  */
/*   Este programa realiza funcionalidades varias de comunicación en-   */
/*   tre bancos y cartera.                                              */
/*   L:                                                                 */
/*     opcion1: Liquidación y/o entrega/pago de cheque (Emisión)        */
/*   M:                                                                 */
/*     opcion 1: Generar movimiento Bancario                            */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*  Autor             Fecha          Comentario                         */
/*  Kevin Rodríguez   15/DIC/2021    Emisión inicial del sp             */
/*  Kevin Rodríguez   23/JUN/2022    Ajustes liquidación (sp_liquida)   */
/*  Kevin Rodríguez   07/JUL/2022    Ajustes desembolso desde bancos    */
/*  Kevin Rodríguez   02/FEB/2023    S771317-Generar movimiento bancario*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_func_bancos_cca')
   drop proc sp_func_bancos_cca
go

create proc sp_func_bancos_cca
   @s_date                 datetime,
   @s_user                 login        = null,
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_ofi                  smallint     = null,
   @i_operacion            char(1),
   @i_opcion               tinyint,
   @i_banco                cuenta,
   @i_desembolso           tinyint      = null,
   @i_fecha_liq            datetime     = null,
   @i_cheque               int          = null,
   -- Parámetros Pago
   @i_secuencial_ing       int          = null,
   -- Parámetros Reverso
   @i_cod_banco            int          = null,
   @i_cuenta               cuenta       = null,
   @i_causal               varchar(14)  = null,
   @i_beneficiario         varchar(50)  = null,
   @i_monto                money        = null,
   @i_secuencial_inter     int          = null,
   @i_operacion_cca        int          = null


as declare
   @w_sp_name            varchar(30),
   @w_error              int,  
   @w_est_novigente      tinyint,
   @w_pagado             char(1),
   @w_estado_op          tinyint,
   @w_operacionca        int,
   @w_secuencial         int,
   @w_num_desembolso     tinyint,
   @w_ofi_desembolso     smallint,
   @w_fecha_liq          datetime,
   
   @w_concepto           catalogo,    
   @w_monto_inter        money,
   @w_cod_banco          catalogo,                   
   @w_cuenta             cuenta,
   @w_beneficiario       varchar(50),
   @w_moneda_pago        tinyint,
   @w_categoria          varchar(20),
   @w_causal             varchar(14),
   @w_corr               char(1),
   @w_sec_desde_bancos   int,
   @w_param_ibtran       int,
   @w_sec_banco          int



-- Variables iniciales
select   @w_sp_name  = 'sp_func_bancos_cca',
         @w_corr     = 'N'

-- Estados de Cartera
exec @w_error = cob_cartera..sp_estados_cca
     @o_est_novigente  = @w_est_novigente out
                
if @w_error <> 0 
    goto ERROR
    
-- Número Transacción Nota de crédito
select @w_param_ibtran = pa_int  
from cobis..cl_parametro
where pa_nemonico = 'IBTRAN'
and pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_fecha_liq   = op_fecha_liq,
       @w_operacionca = op_operacion
from  ca_operacion
where op_banco = @i_banco

-- Emisión (Liquidación/Entrega) de cheque
if @i_operacion = 'L'
begin
  
   if @i_opcion = 1
   begin
   
       select @w_pagado         = isnull(dm_pagado,'N'),
              @w_estado_op      = op_estado,
              @w_operacionca    = op_operacion,
              @w_secuencial     = dm_secuencial,
              @w_num_desembolso = dm_desembolso,
              @w_ofi_desembolso = dm_oficina
       from cob_cartera..ca_operacion, cob_cartera..ca_desembolso, cob_cartera..ca_producto
       where op_banco   = @i_banco
       and dm_operacion = op_operacion
       and dm_producto  = cp_producto
       and dm_desembolso = @i_desembolso
       and cp_categoria = 'CHBC' 
       
        if @@rowcount = 0 
        begin
            select @w_error = 725162 -- Error no existe forma de desembolso
            goto ERROR
        end
       
       -- KDR La emisión de cheques, se dede hacer desde la oficina de registro del desembolso.
       if @w_ofi_desembolso <> @s_ofi
       begin
         select @w_error = 725153 -- NO SE PUEDE LIQUIDAR EL PRÉSTAMO EN UNA OFICINA DISTINTA A ASIGNADA PARA EL DESEMBOLSO.
         goto ERROR
       end
       
       if @w_pagado = 'S'
       begin
           select @w_error = 725130 -- Error, la orden de desembolso ya ha sido pagada.
           goto ERROR
       end
       
       if  @w_estado_op = @w_est_novigente
       begin
       
           exec @w_error      = sp_pasotmp
            @s_term             = @s_term,
            @s_user             = @s_user,
            @i_banco            = @i_banco,
            @i_operacionca      = 'S',
            @i_dividendo        = 'S',
            @i_amortizacion     = 'S',
            @i_cuota_adicional  = 'S',
            @i_rubro_op         = 'S',
            @i_nomina           = 'S'   
            
           if @w_error <> 0  
               goto ERROR
       
           exec @w_error = sp_liquida
            @i_desde_bancos     = 'S',             --cuando se ejecuta desde bancos
            @i_banco_real       = @i_banco ,       --numero del prestamo
            @i_carga            = 0,               --por defecto para este proceso
            @i_fecha_liq        = @w_fecha_liq,    -- fecha liquidacion registrada en tabla maestra de préstamos
            @i_prenotificacion  = 0,               --por defecto para este proceso
            @i_renovacion       = 'N',             --por defecto para este proceso
            @i_externo          = 'N',
            @i_desde_cartera    = 'N',             -- KDR No es ejecutado desde Cartera[FRONT]
            @t_trn              = 7060,            --por defecto para este proceso
            @i_nom_producto     = 'CCA',           --por defecto
            @o_banco_generado   = '0',             --por defecto 
            @s_date             = @s_date,         --fecha actual del sistema (por validar)
            @s_ofi              = @s_ofi,          -- numero de la oficina
            @s_user             = @s_user,         --usuario que ejecuta
            @s_term             = @s_term,         --terminal desde donde se llama el proceso
            @s_ssn              = @s_ssn           --numero de la sesión
        
            if @w_error <> 0 
                goto ERROR
                
            exec @w_error = sp_borrar_tmp
             @s_sesn   = @s_ssn,
             @s_user   = @s_user,
             @s_term   = @s_term,
             @i_banco  = @i_banco
             
            if @w_error <> 0  
                goto ERROR
           
       end
       
       -- Marcar como pagado el desembolso
       exec @w_error = cob_cartera..sp_desembolso
       @i_operacion      = 'U',
       @i_opcion         = 1,
       @i_banco_real     = @i_banco,
       @i_banco_ficticio = @i_banco,
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
          
       -- Actualizar cheque de desembolso
       exec @w_error = cob_cartera..sp_desembolso
       @i_operacion      = 'U',
       @i_opcion         = 2,
       @i_banco_real     = @i_banco,
       @i_banco_ficticio = @i_banco,
       @i_secuencial     = @w_secuencial,
       @i_desembolso     = @w_num_desembolso,
       @i_desde_cre      = 'N',
       @i_externo        = 'N',
       @i_cheque         = @i_cheque,
       @s_ofi            = @s_ofi,
       @s_term           = @s_term,
       @s_user           = @s_user,
       @s_date           = @s_date
        
       if @w_error <> 0 
          goto ERROR
      
   end

end

if @i_operacion = 'M' -- GENERAR MOVIMIENTO BANCARIO
begin

   if @i_opcion = 1
   begin
   
      select @w_concepto      =  abd_concepto,
             @w_monto_inter   =  abd_monto_mpg,
             @w_cod_banco     =  abd_cod_banco,
             @w_cuenta        =  abd_cuenta,
             @w_beneficiario  =  abd_beneficiario,
             @w_moneda_pago   =  abd_moneda
      from  ca_abono, ca_abono_det
      where ab_operacion    = @w_operacionca
      and ab_operacion      = abd_operacion
      and ab_secuencial_ing = abd_secuencial_ing
      and ab_secuencial_ing = @i_secuencial_ing
      and abd_tipo          = 'PAG'
      
      select @w_categoria = cp_categoria 
      from cob_cartera..ca_producto
      where cp_producto = @w_concepto


      if(@w_categoria = 'BCOR' OR @w_categoria = 'MOEL')
      begin 
      
         select @w_causal = c.valor 
         from cobis..cl_tabla t, cobis..cl_catalogo c
         where t.tabla  = 'ca_fpago_causalbancos'
         and   t.codigo = c.tabla
         and   c.estado = 'V'
         and   c.codigo = @w_concepto
         
         if @@rowcount = 0 or @w_causal is null
         begin
            select @w_error = 725139 -- Error, no existe causal para la forma de pago actual, revisar catálogo ca_fpago_causalbancos
            goto ERROR
         end   
      

         if @w_moneda_pago not in (select cu_moneda 
                                   from cob_bancos..ba_cuenta
                                   where cu_banco   = @w_cod_banco 
                                   and cu_cta_banco = @w_cuenta)
         begin
            select @w_error = 725187 -- Error,la moneda de la cuenta bancaria no coincide con la moneda del desembolso o pago
            goto ERROR     
         end
               
         exec @w_error = cob_bancos..sp_tran_general
         @i_operacion      = 'I',
         @i_banco          = @w_cod_banco,
         @i_cta_banco      = @w_cuenta,
         @i_fecha          = @s_date,
         @i_fecha_contable = @s_date,
         @i_tipo_tran      = @w_param_ibtran,  -- NOTA DE CREDITO
         @i_causa          = @w_causal,        -- Causal de la forma de pago
         @i_documento      = @w_beneficiario , --NRO  DE REFERENCIA BANCARIA INGRESADA
         @i_concepto       = 'INTERFAZ DE PAGO DESDE COBIS CAR',
         @i_beneficiario   = @w_beneficiario,
         @i_valor          = @w_monto_inter,
         @i_cheques        = 0,
         @i_producto       = 7, 
         @i_desde_cca      = 'S',
         @i_ref_modulo     = @i_banco,
         @i_modulo         = 7,
         @i_ref_modulo2    = @s_ofi,
         @t_trn            = 171013,
         @s_corr           = @w_corr,
         @s_user           = @s_user,
         @s_ssn            = @s_ssn,
         @s_ofi            = @s_ofi,
         @o_secuencial     = @w_sec_desde_bancos out
              
         if @w_error <> 0 
            goto ERROR
                  
         update ca_abono_det 
         set abd_secuencial_interfaces = @w_sec_desde_bancos
         where abd_operacion      = @w_operacionca
         and   abd_secuencial_ing = @i_secuencial_ing
              
         if @@error != 0 
         begin
            select @w_error = 710002 -- Error en la actualizacion del registro
            goto ERROR
         end    
               
       end
       else
          goto SALIR
   end
end


if @i_operacion = 'R' --REVERSO EN MODULO DE BANCOS
begin
   select @w_corr = 'S'

   exec @w_error = cob_bancos..sp_tran_general
      @i_operacion      = 'I',
      @i_banco          = @i_cod_banco,
      @i_cta_banco      = @i_cuenta,
      @i_fecha          = @s_date,
      @i_fecha_contable = @s_date,
      @i_tipo_tran      = @w_param_ibtran,
      @i_causa          = @i_causal, 
      @i_documento      = @i_beneficiario,
      @i_concepto       = 'INTERFAZ DE PAGO DESDE COBIS CARTERA',
      @i_beneficiario   = @i_beneficiario,
      @i_valor          = @i_monto,
      @i_cheques        = 0,
      @i_producto       = 7, --CARTERA
      @i_desde_cca      = 'S',
      @i_ref_modulo     = @i_banco,
      @i_modulo         = 7, --CARTERA
      @i_ref_modulo2    = @s_ofi,
      @t_trn            = 171013,
      @s_corr           = @w_corr,
      @s_ssn_corr       = @i_secuencial_inter,
      @s_user           = @s_user,
      @s_ssn            = @s_ssn,
      @o_secuencial     = @w_sec_banco out
      
   if @w_error <> 0 begin
      goto ERROR
   end 
   
   update ca_abono_det 
   set abd_sec_reverso_bancos = @w_sec_banco
   where abd_operacion      = @i_operacion_cca
   and   abd_secuencial_ing = @i_secuencial_ing
   and   abd_tipo           = 'PAG'
   
   if @@error != 0
   begin         
      select @w_error = 725188 -- Error al actualizar el secuencial de reverso de transacción de Bancos.
      goto ERROR
   end
end

SALIR:
return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,      
@i_num     = @w_error
return @w_error

GO

    