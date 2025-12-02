/************************************************************************/
/*   Archivo:              careplan.sp                                  */
/*   Stored procedure:     sp_reporte_planificador_d                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Milena Gonzalez                              */
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
/*   Genera Reporte de Planificadores segun NR244                       */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*      Fecha           Nombre        Proposito                         */
/*   03/Abr/2007       M.Gonzalez     Emision Inicial                   */
/************************************************************************/ 

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_reporte_planificador_d')
   drop proc sp_reporte_planificador_d
go

create proc sp_reporte_planificador_d
@i_fecha_proceso        datetime
as

declare 
   @w_error                int,
   @w_operacion            int, 
   @w_concepto             catalogo, 
   @w_fecha                datetime, 
   @w_referencia           cuenta,
   @w_planif               int,
   @w_pp_monto              money,
   @w_banco                cuenta,
   @w_cliente              int,
   @w_oficina              smallint,
   @w_nombre_cliente       varchar(100),
   @w_nombre_planif        varchar(100),
   @w_iden_planif          numero,
   @w_regional             smallint,
   @w_pp_cuenta_sidac      int,
   @w_nom_regional         varchar(100)


begin
  truncate table ca_rep_planif_diario

  declare cursor_planificador cursor for
  select dm_operacion,
         ro_concepto,
         dm_fecha,
         pp_referencia,
         pp_ente_planificador,
         pp_cuenta_sidac,
         pp_monto
  from   ca_rubro_op,
         ca_desembolso,
         ca_pago_planificador
  where  ro_concepto  = pp_concepto_cca
  and    ro_operacion = dm_operacion
  and    dm_estado    = 'A' 
  and    dm_fecha     >= @i_fecha_proceso
  and    pp_operacion = dm_operacion
  and    pp_operacion =  ro_operacion 
  and    pp_estado    = 'P'
  for read only

  open cursor_planificador

  fetch cursor_planificador 
  into @w_operacion, 
       @w_concepto, 
       @w_fecha, 
       @w_referencia, 
       @w_planif ,
       @w_pp_cuenta_sidac,
       @w_pp_monto

--  while   @@fetch_status not in (-1, 0 )
  while   @@fetch_status = 0
  begin
     
     select  @w_banco          = null
     select  @w_cliente        = null
     select  @w_oficina        = null
     select  @w_nombre_cliente = null
     select  @w_nombre_planif  = null


     select @w_banco   = op_banco,
            @w_cliente = op_cliente, 
            @w_oficina = op_oficina
     from ca_operacion
     where op_operacion =  @w_operacion

     select @w_nombre_cliente = en_nomlar
     from   cobis..cl_ente
     where  en_ente = @w_cliente

     select @w_nombre_planif = en_nomlar,
            @w_iden_planif = en_ced_ruc
     from   cobis..cl_ente
     where  en_ente = @w_planif


      select @w_regional     = convert(int,codigo_sib),
             @w_nom_regional = descripcion_sib 
      from cob_credito..cr_corresp_sib,
           cobis..cl_oficina
      where tabla = 'T21'
      and   convert(int,codigo) = of_regional
      and   of_oficina = @w_oficina


     insert into ca_rep_planif_diario 
     values (@w_regional,   @w_oficina,     @w_concepto, @w_iden_planif, @w_nombre_planif,
             @w_referencia, @w_pp_monto,    @w_banco,    @w_nombre_cliente,@w_nom_regional)
     if @@error <> 0
       print 'Error en Insercion'

   fetch cursor_planificador 
   into  @w_operacion, 
         @w_concepto, 
         @w_fecha, 
         @w_referencia, 
         @w_planif ,
         @w_pp_cuenta_sidac,
         @w_pp_monto
end
close cursor_planificador
deallocate cursor_planificador

end
return 0

go

