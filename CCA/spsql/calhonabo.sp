/************************************************************************/
/*      Archivo:                calhonabo.sp                            */
/*      Stored procedure:       sp_calculo_honabo                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo honorario de abogado como otros cargos generado por cada*/
/*      pago del cliente en estado juridico                             */
/*                              CAMBIOS                                 */
/*      03/Jul/2020     Luis Ponce        CDIG Ajustes Migracion a Java*/
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_honabo')
   drop proc sp_calculo_honabo
go

create proc sp_calculo_honabo
@s_user                 login       = null,
@s_ofi                  smallint    = null,
@s_term                 varchar(30) = null,
@s_date                 datetime    = null,
@i_operacionca          int         = null,
@i_toperacion           varchar(10) = null,
@i_moneda               int         = null,
@i_monto_mpg            money       = null,
@i_consulta             char(1)     = 'N',            -- 13/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
@i_banco                cuenta      = null,           -- 13/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
@i_en_linea             char(1)     = 'N',
@o_saldo_hon            money       = null out,       -- 13/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
@o_saldo_iva            money       = null out        -- 13/ENE/2011 - REQ 089 - ACUERDOS DE PAGO

as
declare
@w_banco                cuenta,       --Viene de @i_banco       
@w_concepto             varchar(10),  --pa_char del parametro HONABO
@w_monto_mpg            money,        --Monto del pago efectuado por el cliente (Base de calculo de HONABO)
@w_monto_honabo         money,        --Monto a ingresar como otro cargo por concepto HONABO
@w_dividendo            int,          --Dividendo en donde se insertara el cargo (Se calcula en este sp)                           
@w_comentario           varchar(64),  --Valor que se incluira en este sp como comentario fijo para este tipo de cargos       
@w_sp_name              varchar(30),  --Nombre de este sp 'sp_calculo_honabo'              
@w_est_vigente          tinyint,      --Parametro codigo estado vigente
@w_est_novigente        tinyint,      --Parametro codigo estado novigente
@w_est_vencido          tinyint,      --Parametro codigo estado vencido
@w_honabo               varchar(30),  --Parametro rubro honorario de abogado       
@w_return               int,          --Para envio de numeros de error
@w_error                int,          --Para envio de numeros de error al frontend
@w_num_dec              smallint,     --Numero de decimales para redondeo de cifras
@w_porc_juridico        smallint,
@w_porc_prejuridico     smallint,
@w_regimen              char(1),      --Identifica al cliente si es de regimen comun o simplificado
@w_estado_juridico      varchar(5),
@w_estado_prejuridico   varchar(5),
@w_estado               varchar(5),
@w_iva                  float,
@w_monto_iva            money,
@w_total_porc           money,
@w_total_iva            money,
@w_monto_base           money,
@w_total_honabo         money,
@w_iva_honorario        catalogo,
@w_op_estado            int,
@w_op_moneda            smallint,
@w_tasa                 float,
@w_di_estado            int,
@w_op_toperacion        catalogo,
@w_op_estado_cobranza   char(2),
@w_saldo_cancelacion    money,
-- INI JAR REQ 230
@w_abogado              catalogo,
@w_porc_honorarios      float,
@w_porc_tarifa          money,
@w_factor               float
       
/** INICIALIZACION VARIABLES **/
select @w_sp_name        = 'sp_calculo_honabo',
       @w_comentario     = 'INGRESO AUTOMATICO HONORARIOS DE ABOGADO POR PAGO DEL CLIENTE'

/* ESTADOS DE LOS DIVIDENDOS */
select @w_est_vigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

/* ESTADOS DE LOS DIVIDENDOS */
select @w_est_novigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'NO VIGENTE'


/* ESTADOS DE LOS DIVIDENDOS */
select @w_est_vencido = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'

   
/* PARAMETRO COBRO HONORARIO ABOGADO */
select @w_honabo = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'HONABO'

if @@rowcount = 0 -- No existe parametro para cobro honorarios de abogado
if @i_en_linea = 'S'
begin
        select @w_error = 701015
        goto ERROR
end        
else
        return 701015

-- INI JAR REQ 230
/* Clase de regimen del Abogado */      
select @w_regimen = rf_autorretenedor,     
       @w_abogado = ab_abogado
  from cobis..cl_ente,
       cob_cartera..ca_operacion,
       cob_conta..cb_regimen_fiscal,
       cob_credito..cr_abogado,
       cob_credito..cr_operacion_cobranza,
       cob_credito..cr_cobranza
 where op_operacion     = @i_operacionca 
   and ab_abogado       = en_ente
   and en_asosciada     = rf_codigo
   and oc_num_operacion = op_banco
   and co_cobranza      = oc_cobranza
   and (ab_abogado      = co_ab_interno or ab_abogado = co_abogado) 
   
if @@rowcount = 0 
   select @w_regimen = 'S'

-- FIN JAR REQ 230
   
/* PARAMETRO COBRO HONORARIO ABOGADO */
select @w_iva_honorario = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'IVAHOB'  

/* Parametros del estado de la operacion en Cobranzas */
select @w_estado_prejuridico = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'ESTCPR'
and pa_producto = 'CRE'  

select @w_estado_juridico = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'ESTJUR'
and pa_producto = 'CRE'  

/*Parametro del iva*/
select @w_iva = pa_float
from  cobis..cl_parametro
where pa_nemonico = 'PIVA'
and pa_producto = 'CTE'

if @i_consulta = 'S'                                  -- 13/ENE/2011 - REQ 089: ACUERDOS DE PAGO
begin   
   /* LECTURA DEL BANCO DE LA OPERACION */
   select 
   @i_operacionca        = op_operacion,
   @w_banco              = op_banco,
   @w_op_estado          = op_estado,
   @i_moneda             = op_moneda,
   @w_op_moneda          = op_moneda,
   @w_op_toperacion      = op_toperacion,
   @w_op_estado_cobranza = op_estado_cobranza
   from ca_operacion
   where op_banco = @i_banco
   
   if @@rowcount = 0 -- No existe operacion activa en cartera
   if @i_en_linea = 'S'
   begin
        select @w_error = 701013
        goto ERROR
   end        
   else
        return 701013
end
else
begin   
   /* LECTURA DEL BANCO DE LA OPERACION */
   select 
   @w_banco              = op_banco,
   @w_op_estado          = op_estado,
   @w_op_moneda          = op_moneda,
   @w_op_toperacion      = op_toperacion,
   @w_op_estado_cobranza = op_estado_cobranza
   from ca_operacion
   where op_operacion = @i_operacionca
   
   if @@rowcount = 0 -- No existe operacion activa en cartera
   if @i_en_linea = 'S'
   begin
        select @w_error = 701013
        goto ERROR
   end        
   else
      return 701013
end

/* NUMERO DE DECIMALES */
exec @w_return     = sp_decimales
     @i_moneda     = @i_moneda,
     @o_decimales  = @w_num_dec out

if @w_return <> 0
if @i_en_linea = 'S'
begin
        select @w_error = @w_return
        goto ERROR
end        
else
       return  @w_return

/* JAR REQ 230 - INCLUIR CALCULO DE SALDO DE HONORARIOS */ 
if exists (select 1 from cob_credito..cr_hono_mora   -- INI JAR REQ 230
            where hm_estado_cobranza = @w_op_estado_cobranza)
begin

   /* INCLUIR CALCULO DE SALDO DE HONORARIOS */
   exec @w_return    = sp_saldo_honorarios
   @i_banco          = @w_banco,
   @i_num_dec        = @w_num_dec,
   @o_saldo_tot      = @w_saldo_cancelacion out
  
   if @w_return <> 0 
   if @i_en_linea = 'S'
   begin
        select @w_error = @w_return
        goto ERROR
   end        
   else
        return  @w_return
   
end 
else
begin

   /** SALDO TOTAL DE LA OPERACION   **/
   exec @w_return      = sp_calcula_saldo
        @i_operacion   = @i_operacionca,
        @i_tipo_pago   = 'A', --@w_anticipado_int,
        @o_saldo       = @w_saldo_cancelacion out
    
   if @w_return <> 0 
   if @i_en_linea = 'S'
   begin
        select @w_error = @w_return
        goto ERROR
   end        
   else
        return  @w_return
   
end
   
select @w_saldo_cancelacion = isnull(@w_saldo_cancelacion,0)
           
/* OBTIENE EL MINIMO DIVIDENDO VIGENTE O VENCIDO DONDE SE INSERTARA EL CARGO */
select @w_dividendo = min(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado    in (@w_est_vencido, @w_est_vigente)

if @@rowcount = 0 -- No existe dividendo vigente o vencido en la operacion
if @i_en_linea = 'S'
begin
        select @w_error = 708163
        goto ERROR
end        
else
        return 708163

/*Clase de regimen del Abogado */      
select @w_regimen = rf_autorretenedor       
  from cobis..cl_ente,
       cob_cartera..ca_operacion,
       cob_conta..cb_regimen_fiscal,
       cob_credito..cr_abogado,
       cob_credito..cr_operacion_cobranza,
       cob_credito..cr_cobranza
 where op_operacion     = @i_operacionca 
   and ab_abogado       = en_ente
   and en_asosciada     = rf_codigo
   and oc_num_operacion = op_banco
   and co_cobranza      = oc_cobranza
   and (ab_abogado      = co_ab_interno or ab_abogado = co_abogado) 

if @@rowcount = 0 
   --return 101196
   select @w_regimen = 'S'

         
/*el estado de la operacion en la cobranza*/   
select @w_estado = co_estado
from cob_cartera..ca_operacion,
     cob_credito..cr_operacion_cobranza,
     cob_credito..cr_cobranza
where op_operacion     = @i_operacionca
and   oc_num_operacion = op_banco
and   co_cobranza      = oc_cobranza
if @@rowcount = 0 
   select @w_estado = @w_op_estado_cobranza

-- INI JAR REQ 230
/* LECTURA DEL PORCENTAJE DE HONORARIOS */
exec @w_return = sp_hon_abo
   @i_banco      = @w_banco,
   @i_abogado    = @w_abogado,
   @i_estado_cob = @w_op_estado_cobranza,
   @o_porcentaje = @w_porc_honorarios   out,
   @o_tarifa     = @w_porc_tarifa       out  
  
   if @w_return <> 0 
   if @i_en_linea = 'S'
   begin
           select @w_error = @w_return
           goto ERROR
   end        
   else
           return @w_return

if @w_porc_honorarios is not null begin

   select @w_factor = ((@w_porc_honorarios*0.01) * (@w_iva * 0.01))
   select @w_factor = (@w_factor + (@w_porc_honorarios*0.01)) + 1




   --select @w_monto_base = case when @i_monto_mpg < @w_saldo_cancelacion then @i_monto_mpg else @w_saldo_cancelacion end   --LPO CDIG Cambio de case por ir por Migracion a Java
   --LPO CDIG Cambio de case por ir por Migracion a Java INICIO
   IF @i_monto_mpg < @w_saldo_cancelacion 
      select @w_monto_base = @i_monto_mpg
   ELSE
      select @w_monto_base = @w_saldo_cancelacion               
   --LPO CDIG Cambio de case por ir por Migracion a Java FIN
   
      
   select @w_monto_base = @w_monto_base / @w_factor
   select @w_monto_honabo = round((@w_monto_base*@w_porc_honorarios/100),@w_num_dec)
end

select @w_tasa = 0   
select @w_tasa = isnull(@w_porc_honorarios,0)/100

if @w_porc_tarifa is not null 
   select @w_monto_honabo = @w_porc_tarifa

if @w_regimen = 'S' 
   select @w_monto_iva = round((@w_monto_honabo*@w_iva/100),@w_num_dec)
else
   select @w_monto_iva = 0

select @w_total_honabo = sum(@w_monto_honabo + @w_monto_iva)

-- FIN JAR REQ 230


/* VERIFICA DATOS QUE SE ENVIARAN AL SP_OTROS_CARGOS 
PRINT 'REGABONO: @s_user '           + CAST(@s_user AS VARCHAR)
PRINT 'REGABONO: @s_ofi '            + CAST(@s_ofi AS VARCHAR)
PRINT 'REGABONO: @s_term '           + CAST(@s_term AS VARCHAR)
PRINT 'REGABONO: @s_date '           + CAST(@s_date AS VARCHAR)
PRINT 'REGABONO: @i_operacionca '    + CAST(@i_operacionca AS VARCHAR)
PRINT 'REGABONO: @i_toperacion '     + CAST(@i_toperacion AS VARCHAR)
PRINT 'REGABONO: @i_moneda '         + CAST(@i_moneda AS VARCHAR)
PRINT 'REGABONO: @w_honabo '         + CAST(@w_honabo AS VARCHAR)
PRINT 'REGABONO: @i_monto_mpg '      + CAST(@i_monto_mpg AS VARCHAR)
PRINT 'REGABONO: @w_monto_honabo '   + CAST(@w_monto_honabo AS VARCHAR)
PRINT 'REGABONO: @w_dividendo '      + CAST(@w_dividendo AS VARCHAR)
*/

/*HONORARIO DE HABOGADOS*/
if @w_monto_honabo > 0 
begin
   select @w_di_estado = di_estado
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   and    di_dividendo  = @w_dividendo
   
   if @w_op_estado = 4
      select @w_di_estado  = 4  ---44
   else
   begin
       if @w_di_estado <> @w_est_novigente
          select @w_di_estado = @w_est_vigente
   end

  
   if exists (select 1
           from   ca_amortizacion
           where  am_operacion   = @i_operacionca
           and    am_dividendo   = @w_dividendo
           and    am_concepto    = @w_honabo)    
   begin
    
      update ca_amortizacion
      set    am_cuota     = am_pagado + @w_monto_honabo,
             am_acumulado = am_pagado + @w_monto_honabo,
             am_estado    = @w_di_estado
      from   ca_amortizacion
      where  am_operacion   = @i_operacionca
      and    am_dividendo   = @w_dividendo
      and    am_concepto    = @w_honabo
      
      if @@rowcount = 0      
           if @i_en_linea = 'S'
           begin
                    select @w_error = 710002
                    goto ERROR
           end        
           else
                    return  710002      
   end
   else 
   begin
       insert into ca_amortizacion
             (am_operacion,   am_dividendo,  am_concepto,
              am_estado,      am_periodo,    am_cuota,
              am_gracia,      am_pagado,     am_acumulado,
              am_secuencia)
       values(@i_operacionca, @w_dividendo,  @w_honabo,
              @w_di_estado,   0,             @w_monto_honabo,
              0,              0,             @w_monto_honabo,
              1)
    
       if @@rowcount = 0       
            if @i_en_linea = 'S'
            begin
                     select @w_error = 710001
                     goto ERROR
            end        
            else
                     return 710001      
   end

   
   if exists (select 1
              from   ca_rubro_op
              where  ro_operacion = @i_operacionca
              and    ro_concepto  = @w_honabo)
   begin

       update ca_rubro_op
       set    ro_valor           = @w_monto_honabo,
              ro_saldo_op        = 0,
              ro_saldo_por_desem = 0,
              ro_base_calculo    = @w_monto_base,
              ro_porcentaje      = @w_tasa,
              ro_porcentaje_aux  = @w_tasa
       where  ro_operacion = @i_operacionca
       and    ro_concepto  = @w_honabo
      
       if @@rowcount = 0 
            if @i_en_linea = 'S'
            begin              
                 select @w_error = 710002
                 goto ERROR
            end        
            else
                 return 701002                    
   end
   ELSE
   begin
       insert into ca_rubro_op
             (ro_operacion,            ro_concepto,        ro_tipo_rubro,
              ro_fpago,                ro_prioridad,       ro_paga_mora,
              ro_provisiona,           ro_signo,           ro_factor,
              ro_referencial,          ro_signo_reajuste,  ro_factor_reajuste,
              ro_referencial_reajuste, ro_valor,           ro_porcentaje,
              ro_porcentaje_aux,       ro_gracia,          ro_concepto_asociado,
              ro_principal,            ro_porcentaje_efa,  ro_garantia,
              ro_saldo_op,             ro_saldo_por_desem, ro_base_calculo,
              ro_num_dec)
       select @i_operacionca,          @w_honabo,          'V',
              ru_fpago,                ru_prioridad,       ru_paga_mora,
              ru_provisiona,           '+',                0,
              ru_referencial,          '+',                0,
              null,                    @w_monto_honabo,    @w_tasa,
              @w_tasa,                 0,                  null,
              ru_principal,            0,                  0,
              0,                       0,                  @w_monto_base,
              2
       from   ca_rubro       
       where  ru_toperacion  = @w_op_toperacion
       and    ru_moneda      = @w_op_moneda
       and    ru_concepto    = @w_honabo
   
       if @@rowcount = 0       
            if @i_en_linea = 'S'
            begin            
                     select @w_error = 710001
                     goto ERROR
            end        
            else
                     return 710001       
   end
end 


/*IVA HONORARIO */
if @w_monto_iva > 0 
begin
   if exists (select 1
           from   ca_amortizacion
           where  am_operacion   = @i_operacionca
           and    am_dividendo   = @w_dividendo
           and    am_concepto    = @w_iva_honorario)    
   begin
      update ca_amortizacion
      set    am_cuota     = am_pagado + @w_monto_iva,
             am_acumulado = am_pagado + @w_monto_iva,
             am_estado    = @w_di_estado
      from   ca_amortizacion
      where  am_operacion   = @i_operacionca
      and    am_dividendo   = @w_dividendo
      and    am_concepto    = @w_iva_honorario
      
      if @@rowcount = 0      
           if @i_en_linea = 'S'
           begin            
                    select @w_error = 710002
                    goto ERROR
           end        
           else
                    return 710002      
   end
   else 
   begin
       insert into ca_amortizacion
             (am_operacion,   am_dividendo,  am_concepto,
              am_estado,      am_periodo,    am_cuota,
              am_gracia,      am_pagado,     am_acumulado,
              am_secuencia)
       values(@i_operacionca, @w_dividendo,  @w_iva_honorario,
              @w_di_estado,   0,             @w_monto_iva,
              0,              0,             @w_monto_iva,
              1)
    
       if @@rowcount = 0       
            if @i_en_linea = 'S'
            begin             
                     select @w_error = 710001
                     goto ERROR
            end        
            else
                     return 710001       
   end

   
   if exists (select 1
              from   ca_rubro_op
              where  ro_operacion = @i_operacionca
              and    ro_concepto  = @w_iva_honorario)
   begin
       update ca_rubro_op
       set    ro_valor           = @w_monto_iva,
              ro_saldo_op        = 0,
              ro_saldo_por_desem = 0,
              ro_base_calculo    = @w_monto_honabo,
              ro_porcentaje      = @w_iva,
              ro_porcentaje_aux  = @w_iva
       where  ro_operacion = @i_operacionca
       and    ro_concepto  = @w_iva_honorario
     
       if @@rowcount = 0       
            if @i_en_linea = 'S'
            begin        
                     select @w_error = 710002
                     goto ERROR
            end        
            else
                     return 710002       
   end
   ELSE
   begin
       insert into ca_rubro_op
             (ro_operacion,            ro_concepto,        ro_tipo_rubro,
              ro_fpago,                ro_prioridad,       ro_paga_mora,
              ro_provisiona,           ro_signo,           ro_factor,
              ro_referencial,          ro_signo_reajuste,  ro_factor_reajuste,
              ro_referencial_reajuste, ro_valor,           ro_porcentaje,
              ro_porcentaje_aux,       ro_gracia,          ro_concepto_asociado,
              ro_principal,            ro_porcentaje_efa,  ro_garantia,
              ro_saldo_op,             ro_saldo_por_desem, ro_base_calculo,
              ro_num_dec)
       select @i_operacionca,          @w_iva_honorario,   'V',
              ru_fpago,                ru_prioridad,       ru_paga_mora,
              ru_provisiona,           '+',                0,
              ru_referencial,          '+',                0,
              null,                    @w_monto_iva,       @w_iva,
              @w_iva,                  0,                  null,
              ru_principal,            0,                  0,
              0,                       0,                  @w_monto_honabo,
              2
       from   ca_rubro       
       where  ru_toperacion  = @w_op_toperacion
       and    ru_moneda      = @w_op_moneda
       and    ru_concepto    = @w_iva_honorario
     
       if @@rowcount = 0       
            if @i_en_linea = 'S'
            begin            
                     select @w_error = 710001
                     goto ERROR
            end        
            else
                     return 710001       
   end
end 

select 
@o_saldo_hon = isnull(@w_monto_honabo, 0),
@o_saldo_iva = isnull(@w_monto_iva, 0)

/* FIN RUTINA ADICIONA A REGABONO */
return 0

ERROR:

   exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error

FIN:
  
go
