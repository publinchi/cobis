/************************************************************************/
/*      Archivo:                valormic.sp                             */
/*      Stored procedure:       sp_valor_microseg                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo cobro microseguro y seguro exequial                     */
/************************************************************************/  
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_valor_microseg')
   drop proc sp_valor_microseg
go

create proc sp_valor_microseg (
@s_date                 datetime,
@s_user                 login,
@i_tramite              int,
@i_plazo_meses          int,
@o_valor                money out
)

as
declare 
@w_sp_name              varchar(30),
@w_return               int,
@w_valor                money,
@w_microseg             int,
@w_clase                varchar(10),
@w_am_secuencial        int,
@w_am_plan              int,
@w_pl_valor_mes         money,
@w_am_tipo_aseg         varchar(10),
@w_error                int,
@w_msg                  varchar(200)


/* INICIALIZACION VARIABLES */
select  @w_sp_name        = 'sp_valor_microseg'

select *
into #microseguro
from cob_credito..cr_micro_seguro
where  ms_tramite = @i_tramite
and    ms_estado  = 'P'

select @w_microseg = 0
select @w_valor    = 0

--Leer Microseguros de Clase
while 1=1  
begin

   set rowcount 1

   select @w_microseg = ms_secuencial, @w_clase = ms_clase
   from #microseguro
   where ms_secuencial > @w_microseg
   order by ms_secuencial

   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end

   set rowcount 0

   select @w_am_secuencial = 0

   --Leer Asegurados
   while 1=1
   begin

      set rowcount 1

      select 
      @w_am_secuencial = am_secuencial,
      @w_am_plan       = am_plan,
      @w_am_tipo_aseg  = am_tipo_aseg
      from cob_credito..cr_aseg_microseguro
      where am_microseg   = @w_microseg
      and   am_secuencial > @w_am_secuencial
      order by am_microseg, am_secuencial

      if @@rowcount = 0
      begin
         set rowcount 0
         break
      end

      set rowcount 0

      select @w_pl_valor_mes = pl_valor_mes
      from cob_credito..cr_planes
      where pl_codigo = @w_am_plan

      if @w_clase = '1' --Formulacion Individual
      begin
         select @w_valor = @w_valor + @w_pl_valor_mes 

      end
  
      if @w_clase = '2' --Formulacion Primera Perdida
      begin

         if @w_am_tipo_aseg = '1'
         begin
            select @w_valor = @w_valor + @w_pl_valor_mes 
         end
      end

      --actualizar el valor del plan por cada asegurado (secuencial)
      update cob_credito..cr_aseg_microseguro with (rowlock) set
      am_valor_plan = @w_pl_valor_mes 
      where am_microseg   = @w_microseg
      and   am_secuencial = @w_am_secuencial

      if @@error <>  0
      begin
         select
         @w_error = 2103001,
         @w_msg   = 'ERROR AL ACTUALIZAR MICROSEGURO (ASEGURADO)'
         goto ERROR
      end

   end
end


select @w_valor = (@w_valor * @i_plazo_meses)

select @o_valor = @w_valor


--Actualiza Tabla de Microseguros CREDITO
update cob_credito..cr_micro_seguro with (rowlock) set
ms_fecha_ini    = op_fecha_liq,
ms_fecha_fin    = op_fecha_fin,
ms_fecha_mod    = @s_date,
ms_usuario_mod  = @s_user,
ms_plazo        = @i_plazo_meses,
ms_valor        = @o_valor
from ca_operacion
where op_tramite = @i_tramite
and   ms_tramite = op_tramite

if @@error <>  0
begin
   select
   @w_error = 2103001,
   @w_msg   = 'ERROR AL ACTUALIZAR MICROSEGURO'
   goto ERROR
end

return 0


ERROR:

exec cobis..sp_cerror
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error
go


