/************************************************************************/
/*   Archivo:              careplan_m.sp                                */
/*   Stored procedure:     sp_reporte_planificador_m                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Abril 2007                                   */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Genera Reporte de Planificadores  mensualsegun NR244               */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*      Fecha           Nombre        Proposito                         */
/*   13/Abr/2007       E.Pelaez       Emision Inicial                   */
/************************************************************************/ 

use cob_cartera
go



if exists (select 1 from sysobjects where name = 'sp_reporte_planificador_m')
   drop proc sp_reporte_planificador_m
go

create proc sp_reporte_planificador_m
@i_fecha_proceso        datetime
as

declare 
   @w_error                int,
   @w_operacion            int, 
   @w_concepto             catalogo, 
   @w_referencia           cuenta,
   @w_planif               int,
   @w_banco                cuenta,
   @w_cliente              int,
   @w_oficina              smallint,
   @w_nombre_cliente       varchar(100),
   @w_nombre_planif        varchar(100),
   @w_iden_planif          numero,
   @w_saldo_cxp            money,
   @w_regional             smallint,
   @w_pp_cuenta_sidac      int,
   @w_pp_monto             money,
   @w_nom_oficina          varchar(50),
   @w_pp_cuenta_sidac_aux  int,
   @w_saldo_cxp_a          money,
   @w_saldo_cxp_aux        money 


begin
  truncate table ca_rep_planif_mensual
  --Todos los pagos a planificadores que esten pendoentes de cobro
  declare cursor_planificador cursor for
  select op_operacion,
         ro_concepto,
         pp_referencia,
         pp_ente_planificador,
         pp_cuenta_sidac,
         pp_monto,
         op_banco,
         op_cliente,
         op_oficina,
         pp_cuenta_sidac_aux
  from   ca_rubro_op,
         ca_pago_planificador,
         ca_operacion,
         ca_estado
  where  ro_operacion = op_operacion
  and    pp_operacion  = op_operacion
  and    pp_operacion =  ro_operacion 
  and    pp_concepto_cca = ro_concepto
  and    pp_estado = 'P'
  and    op_estado   = es_codigo
  and    es_procesa  = 'S'
  for read only

  open cursor_planificador

  fetch cursor_planificador 
  into @w_operacion, 
       @w_concepto, 
       @w_referencia, 
       @w_planif ,
       @w_pp_cuenta_sidac,
       @w_pp_monto,
       @w_banco,
       @w_cliente,
       @w_oficina,
       @w_pp_cuenta_sidac_aux

  --while   @@fetch_status not in (-1,0) 
  while   @@fetch_status = 0
  begin

     select  @w_nombre_cliente = null
     select  @w_nombre_planif  = null


     --Sacar el saldo de la cuenta xp 
    /*select @w_saldo_cxp_a  = sum(isnull(rp_saldo,0))
    from cob_sidac..sid_registros_padre 
    where rp_consecutivo  =  @w_pp_cuenta_sidac
    and rp_submodulo = 'CP'                
    
    select @w_saldo_cxp_aux  = sum(isnull(rp_saldo,0))
    from cob_sidac..sid_registros_padre 
    where rp_consecutivo  =  @w_pp_cuenta_sidac_aux
    and rp_submodulo = 'CP'         */
    exec cob_interface..sp_planificador_interfase
    @i_pp_cuenta_sidac        =   @w_pp_cuenta_sidac,
    @i_pp_cuenta_sidac_aux    =   @w_pp_cuenta_sidac_aux,
    @o_saldo_cxp_a            =   @w_saldo_cxp_a out,
    @o_saldo_cxp_aux          =   @w_saldo_cxp_aux out
    
   --PRINT 'careplam_m.sp @w_saldo_cxp_a %1! @w_saldo_cxp_aux %2! @w_banco %3!',@w_saldo_cxp_a,@w_saldo_cxp_aux,@w_banco
   
   
   select @w_saldo_cxp =  ( isnull(@w_saldo_cxp_a,0) + isnull(@w_saldo_cxp_aux,0))
   
    --unicamente  para elreporte todos los que  tienen saldo mayor a 0
    if @w_saldo_cxp > 0 
    begin
        select @w_nombre_cliente = en_nomlar
        from   cobis..cl_ente
        where  en_ente = @w_cliente
   
        select @w_nombre_planif = en_nomlar,
               @w_iden_planif = en_ced_ruc
        from   cobis..cl_ente
        where  en_ente = @w_planif
   
        select @w_nom_oficina = of_nombre
        from cobis..cl_oficina
        where  of_oficina = @w_oficina
   
   
        insert into ca_rep_planif_mensual values (@w_oficina,@w_concepto,@w_iden_planif,@w_nombre_planif,
                                                    @w_referencia, @w_pp_monto, @w_saldo_cxp,
                                                    @w_banco, @w_nombre_cliente,@w_nom_oficina)
        if @@error <> 0
          print 'Error en Insercion'
    end
   fetch cursor_planificador 
   into  @w_operacion, 
         @w_concepto, 
         @w_referencia, 
         @w_planif ,
         @w_pp_cuenta_sidac,
         @w_pp_monto,
         @w_banco,
         @w_cliente,
         @w_oficina,
         @w_pp_cuenta_sidac_aux
         
end
close cursor_planificador
deallocate cursor_planificador

end
return 0

go

