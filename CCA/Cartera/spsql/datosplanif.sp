/************************************************************************/
/*   Archivo:                 datosplanif.sp                            */
/*   Stored procedure:        sp_datos_planificador                     */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Elcira Pelaez                             */
/*   Fecha de Documentacion:  Mar-2007                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */ 
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                 PROPOSITO                            */
/*   Dar mantenimiento a la tabla ca_pago_planificador   forma          */
/*   FDESEMBO.FRM                                                       */
/*                               MODIFICACIONES                         */
/*  FECHA            AUTOR             RAZON                            */
/*                                                                      */
/************************************************************************/

use cob_cartera

go

if exists (select 1 from cob_cartera..sysobjects where name = 'sp_datos_planificador')
   drop proc sp_datos_planificador 
go

create proc sp_datos_planificador (
   @s_user                   login,
   @s_date                   datetime,
   @t_trn                    int          = 0,
   @s_sesn                   int          = 0,
   @s_term                   varchar (30) = NULL,
   @s_ssn                    int          = 0,
   @s_srv                    varchar (30) = null,
   @s_lsrv                   varchar (30) = null,
   @i_operacion              char(1),
   @i_rubro                  catalogo     = null,
   @i_porcentaje_cobrar      float        = null,
   @i_concepto_sidac         catalogo     = null,
   @i_secuencial             int          = null,
   @i_banco_real             cuenta       = null,
   @i_CodPlanif              int          = null,          
   @i_TiopPlanif             char(1)      = null,
   @i_FPagoPanif             catalogo     = null,
   @i_RefePlanif             cuenta       = null,
   @i_RubroPlanif            catalogo     = null,
   @i_valor                  money        = null

)
as

declare 
   @w_sp_name                 varchar(20),
   @w_sec                     int,
   @w_error                   int,
   @w_operacion               int,
   @w_cp_pcobis               tinyint,
   @w_existe                  int

select @w_sp_name = 'sp_datos_planificador',
       @w_sec = 0


select @w_operacion = op_operacion
from ca_operacion
where op_banco = @i_banco_real


if @i_operacion in ('I','D','U')
begin
      insert into  ca_pago_planificador_ts
      (
      pps_operacion,    pps_secuencial_des,   pps_tipo_planificador,   pps_ente_planificador,   pps_monto,
      pps_forma_pago,   pps_referencia,       pps_concepto_cca,        pps_estado,              pps_usuario,
      pps_terminal,     pps_fecha,            pps_cuenta_sidac,        pps_cuenta_sidac_aux,    pps_accion
      )
   values
      (
      @w_operacion,    0,                   @i_TiopPlanif,             @i_CodPlanif,  @i_valor,
      @i_FPagoPanif,  @i_RefePlanif  ,      @i_RubroPlanif  ,         'I' ,           @s_user,
      @s_term,        getdate(),            0,                        0,              @i_operacion
      )
end
   

if @i_operacion = 'H' 
begin
  
    select 'Rubro' = ro_concepto,
        	  'Descripcion' = substring(co_descripcion,1,30)
    from	cob_cartera..ca_rubro_op,
           cob_cartera..ca_concepto,
           cob_cartera..ca_rubro_planificador
    where ro_operacion = @w_operacion
    and   ro_concepto = co_concepto
    and   ro_concepto = rp_rubro
    and   co_concepto = rp_rubro   
end 
 

if @i_operacion = 'I' 
begin
   
   if exists (select 1 from ca_pago_planificador
              where pp_operacion = @w_operacion
              and   pp_estado = 'I'
              )
      begin
         select @w_error = 720902 
         goto ERROR
      end                    
              

   insert into  ca_pago_planificador
      (
      pp_operacion,   pp_secuencial_des,   pp_tipo_planificador,   pp_ente_planificador,   pp_monto,
      pp_forma_pago,   pp_referencia,   pp_concepto_cca,           pp_cuenta_sidac,        pp_cuenta_sidac_aux,
      pp_estado
      )
   values
      (
      @w_operacion,    0,                  @i_TiopPlanif,             @i_CodPlanif,  @i_valor,
      @i_FPagoPanif,  @i_RefePlanif  ,   @i_RubroPlanif  ,            0,            0, 
      'I'
      )

     if @@error <> 0
      begin
         select @w_error = 720901 
         goto ERROR
      end            

end  

if @i_operacion = 'D' 
begin
   
 delete ca_pago_planificador
 where pp_operacion = @w_operacion

  if @@error <> 0
     begin
        select @w_error = 720903
        goto ERROR
     end            

end  


if @i_operacion = 'U' 
begin
   if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   begin --inicio  existe validacion con cobis-ahorros
    --Validar cuenta con planificador
      select @w_cp_pcobis = cp_pcobis
      from ca_producto
      where cp_producto = @i_FPagoPanif
      

      
      if @w_cp_pcobis = 4
      begin
         if not exists (select 1 from cob_ahorros..ah_cuenta
                         where ah_cta_banco = @i_RefePlanif
         and   ah_cliente   = @i_CodPlanif)
        exec @w_error = cob_interface..sp_verifica_cuenta_aho
                  @i_operacion = 'VAHO2',
                  @i_cuenta    = @i_RefePlanif,
                  @i_cliente   = @i_CodPlanif,
                  @o_existe    = @w_existe out
        if not exists(select @w_existe)
        begin
           select @w_error = 720905
           goto ERROR
        end            
      end

      if @w_cp_pcobis = 3
      begin
         /*if not exists (select 1 from cob_cuentas..cc_ctacte
                         where cc_cta_banco = @i_RefePlanif
         and   cc_cliente   = @i_CodPlanif)*/
         exec @w_error = cob_interface..sp_verifica_cuenta_cte
                  @i_operacion = 'VCTE2',
                  @i_cuenta    = @i_RefePlanif,
                  @i_cliente   = @i_CodPlanif,
                  @o_existe    = @w_existe out
        if not exists(select @w_existe)
        begin
           select @w_error = 720906
           goto ERROR
        end            
      end
   end   --fin  existe validacion con cobis-ahorros
   
 update ca_pago_planificador
 set
    pp_tipo_planificador = @i_TiopPlanif,   
    pp_ente_planificador = @i_CodPlanif,
    pp_monto             = @i_valor,
    pp_forma_pago        = @i_FPagoPanif,
    pp_referencia        = @i_RefePlanif,
    pp_concepto_cca      = @i_RubroPlanif

 where pp_operacion = @w_operacion

 if @@error <> 0
     begin
        select @w_error = 720904
        goto ERROR
     end            

end  
  
 
if @i_operacion = 'S' 
begin


  select 
      'Sec.'              = pp_secuencial_des,   
      'Tipo Planificador' = pp_tipo_planificador, 
      'Des. Tipo Planificador' = a.valor,  
      'Cod.Cliente'       = pp_ente_planificador,   
      'Nombre'            = en_nomlar,
      'Valor'             = pp_monto,
      'Forma Pago'        = pp_forma_pago,   
      'Des.Forma Pago'    = cp_descripcion,
      'Cuenta'            = pp_referencia,   
      'Rubro'             = pp_concepto_cca,   
      'Est.REgistro'      = pp_estado
  from  ca_pago_planificador,
        cobis..cl_ente,
        cobis..cl_catalogo a,
        ca_producto
  where pp_operacion = @w_operacion
  and   en_ente = pp_ente_planificador
  and   a.tabla   =  (select codigo 
                    from cobis..cl_tabla
                    where tabla = 'ca_beneficiario_cxp')
  and a.codigo = 'A'
  and cp_producto = pp_forma_pago
  and pp_estado  = 'I'

   
end 


return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug  = 'N',    
   @t_file   =  null,
   @t_from   =  @w_sp_name,
   @i_num    =  @w_error
   return     @w_error
go

