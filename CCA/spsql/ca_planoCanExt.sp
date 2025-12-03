/***********************************************************************/
/*      Producto:                       Cartera                        */
/*      Disenado por:                   Elcira Pelaez                  */
/*      Fecha de Documentacion:         Feb-2013                       */
/*      Procedimiento                   ca_planoCanExt.sp              */
/***********************************************************************/
/*                      IMPORTANTE                                     */
/*      Este programa es parte de los paquetes bancarios propiedad de  */
/*      'MACOSA',representantes exclusivos para el Ecuador de la       */
/*      AT&T                                                           */
/*      Su uso no autorizado queda expresamente prohibido asi como     */
/*      cualquier autorizacion o agregado hecho por alguno de sus      */
/*      usuario sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*      Este stored procedure geenra un plano para la oficina de       */
/*      entrada como parametro Solicitado en BAncamia Por ORS 555      */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/***********************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_planoCanceladas_Ext')
   drop proc sp_planoCanceladas_Ext
go

create proc sp_planoCanceladas_Ext (
    @i_param1  varchar(10)  , --Fecha inicial de consulta
    @i_param2  varchar(10)  --Fecha final de consulta

)
as

declare
@w_error              int,
@w_fecha_ini          datetime,
@w_fecha_fin          datetime,
@w_oficina            int

select @w_fecha_ini = @i_param1,
       @w_fecha_fin = @i_param2
      

truncate table ca_canceladas_Ext_tmp

insert into ca_canceladas_Ext_tmp
select
op_oficina,
of_nombre,
op_banco,
en_ced_ruc,
en_nomlar
from ca_operacion with (nolock),
     cobis..cl_oficina with (nolock),
     cobis..cl_ente  with(nolock)
where op_cliente = en_ente
and op_estado = 3
and op_oficina = of_oficina
and op_fecha_ult_proceso >= @w_fecha_ini
and op_fecha_ult_proceso <= @w_fecha_fin

select distinct oficina
into #oficinas
from ca_canceladas_Ext_tmp

select @w_oficina  = 0
while 1 = 1 begin

      set rowcount 1

      select @w_oficina = oficina 
      from #oficinas
      where oficina > @w_oficina
      order by oficina

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      exec @w_error =  sp_planoCanceladasXofi
      @i_oficina    = @w_oficina
      if @w_error <> 0
      begin
         PRINT 'Revisar Error en ejecucion de sp_planoCanceladasXofi OFICINA:  ' + cast (@w_oficina as varchar)
      end
      

end

return 0
   
go