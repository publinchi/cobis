/************************************************************************/
/*      Archivo:                rep_plaprocol_ven.sp                    */
/*      Stored procedure:       sp_rep_plaprocol_ven                    */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Jul. 2008                               */
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
/*      Genera datos para el reporte                                    */
/*      PLAZO PROMEDIO DE VENCIMIENTOS DE LA CARTERA VIGENTE            */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA      AUTOR           RAZON                                     */
/* 25/MAY/09	Fdo Carvajal		Cambios GAP NB-GAP-RE-CCA-PCC-MOD.doc			*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_plaprocol_ven')
   drop proc sp_rep_plaprocol_ven
go

create proc sp_rep_plaprocol_ven
@i_fecha_cie  datetime  = null  --Fecha de cierre de mes
as

declare 
@w_sp_name            varchar(32),
@w_return             int,
@w_error              int,
@w_est_vigente        tinyint,
@w_est_vencido        tinyint,
@w_est_cancelado      tinyint,
@w_est_castigado      tinyint,
@w_est_suspenso       tinyint,
@w_oficina            smallint,
@w_nombre_ofi         descripcion,
@w_tipo_cred          char(20),
@w_plazo_dias         smallint,
@w_plazo_meses        smallint,
@w_tot_oper           smallint,
@w_operacion          int,
@w_pend_vencer        int,
@w_fecha_ven          datetime,
@w_dias_vencido       int,
@w_fecha_ult_proceso  datetime,
@w_meses_vencidos     float

/* ESTADO DE LAS OPERACIONES */
select @w_est_vigente = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'

select @w_est_castigado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CASTIGADO'

select @w_est_suspenso = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'SUSPENSO'

/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */
create table #rep_plaprocol_ven(
tmp_oficina      smallint    not null,
tmp_nombre_ofi   descripcion not null,
tmp_venc_dias    int         not null,
tmp_venc_meses   float       not null,
tmp_total_opera  int         not null)

/* CURSOR PARA DETERMINAR TODAS LAS OPERACIONES ACTIVAS */
declare
cursor_rep_plaprocol_ven cursor for select
op_oficina,
(select substring(of_nombre,1,25) from cobis..cl_oficina where of_oficina = op_oficina),
op_operacion,
datediff(day, @i_fecha_cie ,op_fecha_fin) 
from  cob_cartera..ca_operacion
where op_estado in (@w_est_vigente, @w_est_vencido, @w_est_suspenso)
order by op_oficina
for read only

open  cursor_rep_plaprocol_ven
fetch cursor_rep_plaprocol_ven
into  @w_oficina,           @w_nombre_ofi,      @w_operacion,      @w_pend_vencer

while   @@fetch_status = 0
begin
   --- DIAS DE VENCIMIENTO
   select @w_dias_vencido = 0, @w_fecha_ven = null
   select @w_fecha_ven = min(di_fecha_ven)
   from   ca_dividendo
   where  di_operacion = @w_operacion
   and    di_estado    = @w_est_vencido
   
   if @w_fecha_ven is not null
   begin
        select @w_dias_vencido = datediff(day,min(di_fecha_ven), @i_fecha_cie )
        from   ca_dividendo
        where  di_operacion = @w_operacion
        and    di_estado    = @w_est_vencido

        select @w_dias_vencido = isnull(@w_dias_vencido,0)
   end else begin
      select @w_dias_vencido= 0
   end
   --si hay dividendo vencido
   
   if @w_pend_vencer < 0 set @w_pend_vencer = 0
   select @w_dias_vencido = isnull(@w_dias_vencido,0) + @w_pend_vencer
   select @w_meses_vencidos = @w_dias_vencido/30.00
   

   if exists (select 1 from #rep_plaprocol_ven where tmp_oficina = @w_oficina)
   begin
      update #rep_plaprocol_ven set 
      tmp_total_opera  = tmp_total_opera +1,
      tmp_venc_dias    = tmp_venc_dias  + @w_dias_vencido,
      tmp_venc_meses   = tmp_venc_meses  + @w_meses_vencidos
      where tmp_oficina = @w_oficina   
   end
   else 
   begin
      insert into #rep_plaprocol_ven --Inserta primero los nuevos por el order by colocado en el cursor                
      (tmp_oficina,     tmp_nombre_ofi,
      tmp_venc_dias,    tmp_venc_meses,    tmp_total_opera)
      values  (
      @w_oficina,       @w_nombre_ofi,
      @w_dias_vencido,  @w_meses_vencidos,   1)
   end

   fetch cursor_rep_plaprocol_ven
   into  @w_oficina,           @w_nombre_ofi,      @w_operacion,   @w_pend_vencer

end --end while cursor rep_plaprocol_ven
close cursor_rep_plaprocol_ven
deallocate cursor_rep_plaprocol_ven


/*PARA MOSTRAR LA INFORMACION DE LA CONSULTA EN GRILLA O PARA REPORTE */
select  
'cod_ofi'          = tmp_oficina,
'nom_ofi'          = tmp_nombre_ofi,
'prom_venc_dias'   = (case tmp_total_opera when 0 then 0 else tmp_venc_dias/(tmp_total_opera*1.00) end), 
'prom_venc_meses'  = (case tmp_total_opera when 0 then 0 else tmp_venc_meses/(tmp_total_opera*1.00) end),
'tot_ope'          = tmp_total_opera
from #rep_plaprocol_ven
order by tmp_oficina


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error

return @w_error

go
