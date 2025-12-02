use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aho_cta_grupal')
  drop procedure sp_aho_cta_grupal
go

/************************************************************/
/*   ARCHIVO:         	ahoctagru.sp       			    	*/
/*   NOMBRE LOGICO:   	sp_aho_cta_grupal                 	*/
/*   PRODUCTO:        		CARTERA                        	*/
/************************************************************/
/*                     IMPORTANTE                          	*/
/*   Esta aplicacion es parte de los  paquetes bancarios   	*/
/*   propiedad de MACOSA S.A.                              	*/
/*   Su uso no autorizado queda  expresamente  prohibido   	*/
/*   asi como cualquier alteracion o agregado hecho  por   	*/
/*   alguno de sus usuarios sin el debido consentimiento   	*/
/*   por escrito de MACOSA.                                	*/
/*   Este programa esta protegido por la ley de derechos   	*/
/*   de autor y por las convenciones  internacionales de   	*/
/*   propiedad intelectual.  Su uso  no  autorizado dara   	*/
/*   derecho a MACOSA para obtener ordenes  de secuestro   	*/
/*   o  retencion  y  para  perseguir  penalmente a  los   	*/
/*   autores de cualquier infraccion.                      	*/
/************************************************************/
/*                     PROPOSITO                           	*/
/*   Este procedimiento permite ejecutar una regla en      	*/
/*   particular basado en las variables que tiene		   	*/
/*   asignado				      							*/
/************************************************************/
/*                     MODIFICACIONES                    	*/
/*   FECHA         AUTOR               RAZON                */
/*   29-Mar-2017   Tania Baidal        Emision Inicial.     */
/************************************************************/

create proc sp_aho_cta_grupal(
	@i_grupo     int
)
as
declare	
		@w_sp_name            varchar(32),
		@w_operacion_gr       int,
		@w_cta_grp            cuenta,
		@w_plazo              smallint,
		@w_disponible         money,
		@w_porcentaje_aho     float,
		@w_dias_semana        smallint,
		@w_numero_dias        smallint,
		@w_rendimiento        float,
		@w_monto_prestamo_tot money,
		@w_grupo              int,
		@w_operacion          int,
		@w_cliente            int,
		@w_monto_rendimiento  money,
		@w_tplazo             catalogo,
		@w_ciclo              int,
		@w_tramite            int

if 'S' <> (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   return 0

--OBTENER EL GRUPO
select @w_ciclo = max(ci_ciclo)
from  cob_cartera..ca_ciclo
where ci_grupo = @i_grupo

--OBTENER LA OPERACION
select
@w_operacion_gr = ci_operacion,
@w_tramite = ci_tramite
from cob_cartera..ca_ciclo
where ci_grupo = @i_grupo
and ci_ciclo = @w_ciclo

select
@w_cta_grp    = op_cuenta,
@w_plazo      = op_plazo,
@w_tplazo     = op_tplazo
from ca_operacion
where op_operacion = @w_operacion_gr

--OBTENER SALDO DE LA CUENTA

select @w_disponible = ah_disponible 
from cob_ahorros..ah_cuenta
where ah_cta_banco = @w_cta_grp

--OBTENER PARAMETRO DE PORCENTAJE DE RENDIMIENTO DE AHORRO DE CUENTA GRUPAL
select @w_porcentaje_aho = pa_float 
from cobis..cl_parametro
where pa_nemonico = 'RAHOGR'

--VARIABLE PARA DIAS DE LA SEMANA
--if @w_tplazo ='W'
    select @w_dias_semana = 7
--else
  --  select @w_dias_semana = 0
	
	
--CALCULAR NUMERO DE DIAS
select @w_numero_dias = @w_plazo * @w_dias_semana

--CALCULAR EL 5% de LA CUENTA
select @w_rendimiento = ((@w_disponible * @w_porcentaje_aho) / 360) * @w_numero_dias


--SELECCIONAR MONTO TOTAL DEL PRESTAMO
select @w_monto_prestamo_tot = sum(tg_monto)
from cob_credito..cr_tramite_grupal
where tg_tramite = @w_tramite

--INSERCION DE DATOS DEL AHORRO INDIVIDUAL EN ESTRUCTURA TEMPORAL
create table #ahorro_individual(
   operacion         int   not null,
   cliente           int   not null,
   monto_prestamo    money,
   monto_rendimiento money,
   procesado         char
)

insert into #ahorro_individual(operacion, cliente, monto_prestamo)
select tg_operacion,tg_cliente, tg_monto
from cob_credito..cr_tramite_grupal
where tg_tramite = @w_tramite

if isnull(@w_monto_prestamo_tot,0) = 0
	begin
	    exec cobis..sp_cerror
		--@t_from  = @w_sp_name,
        @i_num   = 710129
        return 1
	end
--RENDIMIENTO INDIVIDUAL = RENDIMIENTO TOTAL * PROPORCION DE PARTICIPACION INDIVIDUAL
if @w_monto_prestamo_tot>0
    update #ahorro_individual
    set monto_rendimiento = @w_rendimiento * (monto_prestamo/@w_monto_prestamo_tot),
    procesado ='N'

--ACTUALIZAR AHORRO INDIVIDUAL
while exists (select 1 from #ahorro_individual where procesado = 'N')
begin
    select top 1
	@w_operacion         = operacion,
	@w_cliente           = cliente,
	@w_monto_rendimiento = monto_rendimiento
	from #ahorro_individual
	where procesado = 'N'
	
    if exists(select 1 from cob_ahorros..ah_ahorro_individual where ai_operacion = @w_operacion and ai_cliente = @w_cliente)
    begin
	
		update cob_ahorros..ah_ahorro_individual
        set ai_ganancia = isnull(ai_ganancia,0) + @w_monto_rendimiento
        from #ahorro_individual, cob_ahorros..ah_ahorro_individual
        where ai_cliente   = @w_cliente
          and ai_operacion = @w_operacion
		  and cliente = ai_cliente
		  and operacion = ai_operacion
		  
    end
    else
    begin
        insert into cob_ahorros..ah_ahorro_individual (ai_cta_grupal,ai_operacion,ai_cliente,ai_saldo_individual,ai_incentivo,ai_ganancia) 
        values(@w_cta_grp, @w_operacion, @w_cliente, 0, 0, @w_monto_rendimiento)
    end
	
	update #ahorro_individual
	set procesado = 'S'
	where operacion = @w_operacion
	and cliente = @w_cliente
end  
return 0
go
