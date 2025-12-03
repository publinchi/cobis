/************************************************************************/
/*   Archivo:                 pagoplanif.sp                             */
/*   Stored procedure:        sp_planificadores                         */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Elcira Pelaez                             */
/*   Fecha de Documentacion:  Abr-2007                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */ 
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Este spe s llamado desde los programas liquida y liquidades        */
/*   Para genrar el paso de datos a SIDAC para pagoa planificadores     */
/*                          MODIFICACIONES                              */
/*  FECHA            AUTOR             RAZON                            */
/*                                                                      */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from cob_cartera..sysobjects where name = 'sp_planificadores')
   drop proc sp_planificadores 
go

create proc sp_planificadores (
   @s_user                   login,
   @s_date                   datetime,
   @s_term                   varchar (30) = NULL,
   @i_debug                  char(1)
)
as

declare 
   @w_sp_name                 varchar(20),
   @w_error                   int,
   @w_ro_concepto             catalogo,
   @w_rp_cto_sidac            catalogo,
   @w_rp_porcentaje           float,
   @w_pp_forma_pago           catalogo,
   @w_pp_referencia           cuenta,
   @w_pp_ente_planificador    int,
   @w_ro_valor                money,
   @w_parametro_tasaiva       catalogo,
   @w_concepto_conta_iva      catalogo,
   @w_operacionca             int,
   @w_dm_secuencial           int,
   @w_tramite                 int,
   @w_op_oficina              int,
   @w_valor_60                float,
   @w_valor_40                float,
   @w_ppcobis                 tinyint,
   @w_fpago                   char(1),
   @w_exento                  char(1),
   @w_valor_iva               money,
   @w_neto                    money,
   @w_dm_oficina              int,
   @w_tasa_iva                float,
   @w_op_banco                cuenta,
   @w_ssn                     int,
   @w_srv                     catalogo,
   @w_rowcount                int
  

select @w_sp_name = 'sp_planificadores'

--LIMPIAR TABLA DE TRABAJO
truncate table  ca_pago_planificador_tmp

--CARGA DE DATOS PARA TRABAJAR SOBRE TEMPORAL
    select ro_operacion,
           ro_concepto,
           rp_porcentaje,
           ro_valor,
           rp_cto_sidac,
           pp_forma_pago, 
           pp_referencia,
           pp_ente_planificador,
           dm_secuencial,
           dm_oficina
 from ca_rubro_op,
      ca_rubro_planificador,
      ca_desembolso,
      ca_pago_planificador
   where  ro_concepto = rp_rubro  
   and ro_concepto = pp_concepto_cca 
   and ro_operacion = dm_operacion
   and dm_estado = 'A'
   and pp_operacion = dm_operacion
   and pp_operacion =  ro_operacion 
   and pp_secuencial_des = dm_secuencial
   and pp_estado = 'I'
   
select @w_parametro_tasaiva = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico  =  'TASIVA'
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
begin
 select @w_error = 721204
 goto ERROR_EXT
end



set rowcount 1
select @w_tasa_iva =  vd_valor_default
from   cob_cartera..ca_valor_det
where  vd_tipo        =  @w_parametro_tasaiva
set rowcount 0

if @w_tasa_iva is null

begin
 select @w_error = 721205
 goto ERROR_EXT
end

select @w_concepto_conta_iva = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico  =  'CONIVA' 
and  pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
begin
 select @w_error = 721203
 goto ERROR_EXT
end
  

select @w_ssn = se_numero
from cobis..ba_secuencial
   
if @w_ssn is null 
   select @w_ssn = 1
   

select @w_srv = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and pa_nemonico = 'SRVR'
set transaction isolation level read uncommitted

if @w_srv is null
   select @w_srv = 'NO DEFINDO'
   
declare  planificadores  cursor for
    select ro_operacion,
           ro_concepto,
           rp_porcentaje,
           ro_valor,
           rp_cto_sidac,
           pp_forma_pago, 
           pp_referencia,
           pp_ente_planificador,
           dm_secuencial,
           dm_oficina
 from ca_rubro_op,
      ca_rubro_planificador,
      ca_desembolso,
      ca_pago_planificador
   where  ro_concepto = rp_rubro  
   and ro_concepto = pp_concepto_cca 
   and ro_operacion = dm_operacion
   and dm_estado = 'A'
   and pp_operacion = dm_operacion
   and pp_operacion =  ro_operacion 
   and pp_secuencial_des = dm_secuencial
   and pp_estado = 'I'
   
   for read only
   
   open   planificadores
   fetch planificadores into
   
      @w_operacionca,           
      @w_ro_concepto,         
      @w_rp_porcentaje,          
      @w_ro_valor,            
      @w_rp_cto_sidac,        
      @w_pp_forma_pago,       
      @w_pp_referencia,       
      @w_pp_ente_planificador,
      @w_dm_secuencial,
      @w_dm_oficina
   
      --while @@fetch_status not in (-1,0)
      while @@fetch_status = 0
      begin

           select @w_op_oficina = op_oficina,
                  @w_tramite     = op_tramite,
                  @w_op_banco    = op_banco
           from ca_operacion
           where op_operacion = @w_operacionca


            --VALIDACION FORMA DE PAGO
            select @w_ppcobis = cp_pcobis
            from ca_producto
            where cp_producto = @w_pp_forma_pago
            
            if @w_ppcobis = 3
               select @w_fpago = 'C'
            
            if @w_ppcobis = 4
               select @w_fpago = 'A'
               
            if @w_fpago not in ('A','C')
             begin
                select @w_error =  721206  
                goto ERROR
             end 

   
            exec @w_error = cob_conta..sp_exenciu
                 @s_date            = @s_date,
                 @s_user            = @s_user,
                 @s_term            = @s_term,
                 @s_ofi             = @w_dm_oficina,
                 @t_trn             = 6251,
                 @t_debug           = 'N',
                 @i_operacion       = 'F',
                 @i_empresa         = 1,
                 @i_impuesto        = 'V',            
                 @i_concepto        = @w_concepto_conta_iva,
                 @i_debcred         = 'C',            
                 @i_ente            = @w_pp_ente_planificador,
                 @i_oforig_admin    = @w_dm_oficina,
                 @i_ofdest_admin    = @w_op_oficina,
                 @i_producto        = 7,
                 @o_exento          = @w_exento  out
                 
                 if @w_error <> 0 
                  begin
                     PRINT 'pagoplanif.sp saliendo de cob_conta..sp_exenciu  I ->'+ @w_error
                     select @w_error =  721202 
                     goto ERROR
                  end 

      
      
               if @w_rp_porcentaje <> 100
               begin
                  
                  select @w_valor_60 = 0,
                         @w_valor_40 = 0
                                     
                  select @w_valor_60 = round((@w_ro_valor * @w_rp_porcentaje)/100,0) --Valor que debe ser autorizado en SIDAC
                  select @w_valor_40 = round(@w_ro_valor - @w_valor_60,0)            --Valor que no debe ser autorizado en SIDAC
                  
                   insert into ca_pago_planificador_tmp 
                   values(  @s_user,       @w_operacionca, @w_dm_secuencial, @w_pp_ente_planificador,@w_valor_60,@w_pp_forma_pago,
                            @w_pp_referencia, @w_ro_concepto, 60,0,0)
                  
                  insert into ca_pago_planificador_tmp 
                  values ( @s_user,       @w_operacionca, @w_dm_secuencial, @w_pp_ente_planificador,@w_valor_40,@w_pp_forma_pago,
                          @w_pp_referencia, @w_ro_concepto, 40,0,0)
                  
               end
               ELSE
               begin
            
                   insert into ca_pago_planificador_tmp 
                   values(   @s_user,       @w_operacionca, @w_dm_secuencial, @w_pp_ente_planificador,@w_ro_valor,
                             @w_pp_forma_pago,   @w_pp_referencia, @w_ro_concepto, 100,0,0)
                  
               end
           
            if @i_debug = 'S'
               PRINT 'pagoplanif.sp  Datos que van: @w_op_banco , @w_rp_cto_sidac' + @w_op_banco + @w_rp_cto_sidac
               
            begin tran
                                           
            exec @w_error = sp_interfaz_planificador
                 @s_ssn                    =  @w_ssn,
                 @s_user                   =  @s_user,
                 @s_date                   =  @s_date,
                 @s_term                   =  @s_term,
                 @s_srv                    =  @w_srv, 
                 @s_ofi                    =  @w_dm_oficina,
                 @i_op_oficina             =  @w_op_oficina,
                 @i_tramite                =  @w_tramite,
                 @i_dm_secuencial          =  @w_dm_secuencial,
                 @i_operacionca            =  @w_operacionca,
                 @i_exento                 =  @w_exento,
                 @i_cto_sidac              =  @w_rp_cto_sidac,
                 @i_fpago                  =  @w_fpago,
                 @i_tasa_iva               =  @w_tasa_iva,
                 @i_debug                  =  @i_debug
            
                 if @w_error  != 0
                  begin
                     PRINT 'pagoplanif.sp ERRORRRRRR saliendo interfazplanif  I -> ' + @w_error
                     select @w_error =  721201 
                     rollback tran
                     goto ERROR
                  end 
                  
           commit tran

           goto SIGUIENTE
         
            ERROR:
            if @w_error <> 0
            begin
               exec sp_errorlog 
                    @i_fecha      = @s_date,
                    @i_error      = @w_error, 
                    @i_usuario    = @s_user,
                    @i_tran       = 7999,
                    @i_tran_name  = @w_sp_name,
                    @i_cuenta     = @w_op_banco,
                    @i_rollback   = 'S'
               
               while @@trancount > 0 rollback
            end
           
      SIGUIENTE:
      fetch planificadores into

      @w_operacionca,           
      @w_ro_concepto,         
      @w_rp_porcentaje,          
      @w_ro_valor,            
      @w_rp_cto_sidac,        
      @w_pp_forma_pago,       
      @w_pp_referencia,       
      @w_pp_ente_planificador,
      @w_dm_secuencial,
      @w_dm_oficina
   
end ---cursor
close planificadores
deallocate planificadores
  
  --actualizar la tabla de pagos con las cuentas o consecutivos de sidac
  --y el estado procesado
  
  update ca_pago_planificador
  set pp_cuenta_sidac      = ppt_cuenta_sidac,
      pp_cuenta_sidac_aux  = ppt_cuenta_sidac_aux,
      pp_estado            = 'P'
  from ca_pago_planificador_tmp
  where ppt_operacion = pp_operacion
  and   ppt_secuencial_des = pp_secuencial_des
  and   ppt_cuenta_sidac > 0
  

ERROR_EXT:
if @w_error <> 0
begin
   exec sp_errorlog 
        @i_fecha      = @s_date,
        @i_error      = @w_error, 
        @i_usuario    = @s_user,
        @i_tran       = 7999,
        @i_tran_name  = @w_sp_name,
        @i_cuenta     = '',
        @i_rollback   = 'N'
end 
  

return 0

go

