/************************************************************************/
/*      Archivo:                rep_plaprocol_act.sp                    */
/*      Stored procedure:       sp_rep_plaprocol_act                    */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Jul. 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      Plazo promedio de colocacion de cartera activa a cierre de mes  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_plaprocol_act')
   drop proc sp_rep_plaprocol_act
go

create proc sp_rep_plaprocol_act
    @i_fecha_cie  datetime  = null  --Fecha de cierre de mes

as

declare @w_sp_name            varchar(32),
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
        @w_tot_oper           smallint

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
create table #rep_plaprocol_act
(
tmp_oficina         smallint    not null,
tmp_nombre_ofi      descripcion not null,
tmp_plazo_dias_n    smallint    not null,
tmp_plazo_meses_n   smallint    not null,
tmp_total_opera_n   smallint    not null,
tmp_plazo_dias_r    smallint    not null,
tmp_plazo_meses_r   smallint    not null,
tmp_total_opera_r   smallint    not null,
tmp_plazo_dias_t    smallint    not null,
tmp_plazo_meses_t   smallint    not null,
tmp_total_opera_t   smallint    not null
)


/* CURSOR PARA DETERMINAR TODAS LAS OPERACIONES ACTIVAS AL CIERRE DE MES */
declare
cursor_rep_plaprocol_act cursor
for select
      op_oficina,
      (select substring(of_nombre,1,20) from cobis..cl_oficina
                                        where of_oficina = op_oficina),
      case when tr_tipo_credito = 'N' then 'NUEVO' else 'RENOVADO' end,
      sum((op_plazo * td_factor)),
      sum((op_plazo * td_factor)/30),
      count(*)
from  cob_cartera..ca_operacion,
      cob_credito..cr_tramite,
      cob_cartera..ca_tdividendo
where op_estado     in (@w_est_vigente,@w_est_vencido,@w_est_castigado,@w_est_suspenso)
and   op_fecha_ult_proceso = @i_fecha_cie
and   tr_tramite    = op_tramite
and   td_tdividendo = op_tplazo
group by op_oficina, tr_tipo_credito
order by op_oficina, tr_tipo_credito

for read only

open  cursor_rep_plaprocol_act
fetch cursor_rep_plaprocol_act
into  @w_oficina,           @w_nombre_ofi,        @w_tipo_cred,
      @w_plazo_dias,        @w_plazo_meses,       @w_tot_oper

while   @@fetch_status = 0
begin
    if (@@fetch_status = -1)
       return 710004 --Cambiar de error
    if @w_tot_oper <>0
        begin
            select @w_plazo_dias = @w_plazo_dias / @w_tot_oper
            select @w_plazo_meses = @w_plazo_meses / @w_tot_oper 
    end else begin 
        select @w_plazo_dias = 0   
        select @w_plazo_meses = 0 
        
    end 
        
    if exists (select 1 from #rep_plaprocol_act
               where tmp_oficina = @w_oficina)
    begin
        update #rep_plaprocol_act --Actualiza los renovados por el order by colocado en el cursor
        set tmp_plazo_dias_r   = @w_plazo_dias,
            tmp_plazo_meses_r  = @w_plazo_meses,
            tmp_total_opera_r  = @w_tot_oper,
            tmp_plazo_dias_t   = (tmp_plazo_dias_t  + @w_plazo_dias)/2,   --Se divide por 2 por ser dos totales
            tmp_plazo_meses_t  = (tmp_plazo_meses_t + @w_plazo_meses)/2,  --Se divide por 2 por ser dos totales
            tmp_total_opera_t  = (tmp_total_opera_t + @w_tot_oper)
        where tmp_oficina = @w_oficina
    end
    else
    begin
        insert into #rep_plaprocol_act --Inserta primero los nuevos por el order by colocado en el cursor
                (tmp_oficina,         tmp_nombre_ofi,
                 tmp_plazo_dias_n,    tmp_plazo_meses_n,    tmp_total_opera_n,
                 tmp_plazo_dias_r,    tmp_plazo_meses_r,    tmp_total_opera_r,
                 tmp_plazo_dias_t,    tmp_plazo_meses_t,    tmp_total_opera_t)
        values  (@w_oficina,          @w_nombre_ofi,
                 @w_plazo_dias,       @w_plazo_meses,       @w_tot_oper,
                 0,                   0,                    0,
                 @w_plazo_dias,       @w_plazo_meses,       @w_tot_oper)
    end

    fetch cursor_rep_plaprocol_act
    into  @w_oficina,           @w_nombre_ofi,        @w_tipo_cred,
          @w_plazo_dias,        @w_plazo_meses,       @w_tot_oper

end --end while cursor rep_plaprocol_act
close cursor_rep_plaprocol_act
deallocate cursor_rep_plaprocol_act


/*PARA MOSTRAR LA INFORMACION DE LA CONSULTA EN GRILLA O PARA REPORTE */
select  'cod_ofi'                   = tmp_oficina,
        'nom_ofi'                   = tmp_nombre_ofi,
        'pla_dia_nue'               = tmp_plazo_dias_n,
        'pla_mes_nue'               = tmp_plazo_meses_n,
        'tot_ope_nue'               = tmp_total_opera_n,
        'pla_dia_ren'               = tmp_plazo_dias_r,
        'pla_mes_ren'               = tmp_plazo_meses_r,
        'tot_ope_ren'               = tmp_total_opera_r,
        'pla_dia_tot'               = tmp_plazo_dias_t,
        'pla_mes_tot'               = tmp_plazo_meses_t,
        'tot_ope_tot'               = tmp_total_opera_t
from #rep_plaprocol_act
order by tmp_oficina


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   
return @w_error
                        
go
