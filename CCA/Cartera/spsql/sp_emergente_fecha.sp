use cob_cartera
go
/************************************************************************/
/*      Archivo:                sp_emergente_fecha.sp                   */
/*      Stored procedure:       sp_emergente_fecha                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LGU                                     */
/*      Fecha de escritura:     Abr. 2017                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Determinar el plazo y fecha de primer vencimiento de un         */
/*      prestamo emergente                                              */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR             RAZON                         */
/* 19-Abr-2017          LGU          Emision inicial                    */
/* 26-Abr-2019          AGI          Adaptacion TECREEMOS               */
/* 01-Jun-2019          GFP          Se comenta prints                  */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_emergente_fecha')
    drop proc sp_emergente_fecha
go

create proc sp_emergente_fecha
   @i_toperacion     varchar(10),
   @i_cliente        int,
   @i_fecha_ini      datetime,
   @i_plazo          int = null,
   @i_fecha_pri_cuot datetime = null,
   @o_plazo          int      = null output,
   @o_fecha_pri_cuot datetime = null output,
   @o_operacionca    int      = null output
as
declare
  @w_grupo_id          int,
  @w_div_vig_grp       int,
   @w_fecha_pri_cuot    datetime,
   @w_max_tramite       int,
   @w_operacionca_grp   int,
   @w_cnt_div           smallint,
   @w_return            int


if exists(select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_interciclo' and t.codigo = c.tabla and c.codigo = @i_toperacion)
begin
   -- buscar el tramite, operacion y banco GRUPAL
  select @w_grupo_id = cg_grupo
  from   cobis..cl_cliente_grupo
  where  cg_ente = @i_cliente

   select @w_max_tramite = max(tg_tramite)
   from cob_credito..cr_tramite_grupal
   where tg_grupo = @w_grupo_id

   select @w_operacionca_grp = max(op_operacion)
   from cob_cartera..ca_operacion
   where op_grupo = @w_grupo_id
     and op_grupal = 'S'
     

   select
      @w_div_vig_grp    = max(di_dividendo),
      @w_fecha_pri_cuot = max(di_fecha_ven)
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacionca_grp
   and @i_fecha_ini >= di_fecha_ini
   and @i_fecha_ini <= di_fecha_ven

   select @w_cnt_div = count(1)
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacionca_grp
   and di_dividendo >= @w_div_vig_grp

   if @w_cnt_div < 1
   begin
      --GFP se suprime print
      --print '--> no existen dividendos para crear el credito emergente'
      return 705022
   end

   select @o_fecha_pri_cuot = @w_fecha_pri_cuot
   select @o_plazo          = @w_cnt_div
   select @o_operacionca    = @w_operacionca_grp

   --print 'IF:      @i_cliente   ' + convert (varchar,@i_cliente)
   --print 'IF:      @w_grupo_id   ' + convert (varchar,@w_grupo_id)  +  '  @w_max_tramite  ' + convert(varchar, @w_max_tramite ) + ' OP ' + convert(varchar, @w_operacionca_grp )
   --print 'IF:      @o_fecha_pri_cuot   ' + convert (varchar,@o_fecha_pri_cuot , 101)  +  '  plazo ' + convert(varchar, @o_plazo )
end
else
begin
   select @o_fecha_pri_cuot = @i_fecha_pri_cuot
   select @o_plazo          = @i_plazo
end

return 0

go


