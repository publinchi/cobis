/************************************************************************/
/*      Archivo:                ca_proyrec.sp                           */
/*      Stored procedure:       sp_proyrec                              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Paulina Galindo                         */
/*      Fecha de escritura:     22-Feb-2010                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Proyecci=n de recuperaci=n en n tiempo                          */
/*      Reporte mensual se debe generar después del cierre del último   */
/*      día de cada mes.                                                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre         Proposito                        */
/*      08-Mayo-2014    Luis Moreno    CCA 406 SEGDEUEM                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_proyrec')
   drop proc sp_proyrec
go

create proc sp_proyrec
@i_fecha      datetime = null,
@i_fecha_min  datetime = null,
@i_fecha_max  datetime = null,
@i_tipo       char(1)
   

as 
set ansi_warnings off
set ansi_nulls    off

declare
@w_error        int,
@w_tabla_cat    int,
@w_ini_anio     datetime,
@w_ini_mes      char(10),
@w_mes          char(20),
@w_dia          int,
@w_anio         char(4),
@w_fecha        char(20),
@w_fecha_desde  datetime,
@w_fecha_hasta  datetime,
@w_fecha_proc   datetime,
@w_path_s_app   varchar(250),
@w_path         varchar(250),
@w_file         varchar(250),
@w_s_app        varchar(250),
@w_sqr          varchar(250),
@w_cmd          varchar(250),
@w_bd           varchar(250),
@w_tabla        varchar(250),
@w_fecha_arch   varchar(10),
@w_comando      varchar(500),
@w_destino      varchar(250),
@w_errores      varchar(250)

select @w_fecha_proc = fp_fecha
from   cobis..ba_fecha_proceso

select @w_tabla_cat = codigo
from   cobis..cl_tabla
where  tabla = 'cr_clase_cartera'

if @i_tipo = 'M' /* REPORTE MENSUAL*/
begin
   select
   @w_sqr         = 'cob_cartera..sp_proyrec_mensual_ext',
   @w_file        = 'PROYRECM',
   @w_fecha_desde = dateadd(mm, 1, dateadd(dd, (-1*datepart(dd, @i_fecha))+1, @i_fecha)),
   @w_fecha_hasta = dateadd(dd, -1,  dateadd(mm, 1, @w_fecha_desde))

end
else
begin  /* REPORTE EVENTUAL */
   select @w_fecha_desde = @i_fecha_min
   select @w_fecha_hasta = @i_fecha_max
   select 
   @w_sqr         = 'cob_cartera..sp_proyrec_eventual_ext',
   @w_file        = 'PROYRECE'

end

/* CAMPOS DEL REPORTE
1. Fecha de pago: dd-mm-aaaa
2. Código de la oficina
3. Nombre de la oficina
4. Tipo de cartera (Comercial, Microcrédito, Vivienda o Consumo)
5. Suma de proyección de recuperación de capital
6. Suma de recuperación de intereses
7. Suma de recuperación de IVA mipymes
8. Suma de recuperación de pymes
9. Suma de recuperación de seguro de deudores
10. Suma de recuperación de cuota fng
11. Suma de otros conceptos
12. Suma de recuperación cuota total (Cuota total es igual a la sumatoria de los conceptos anteriores)
*/

/*OPERACIONES VIGENTES, VENCIDAS Y EN SUSPENSO*/
select op_banco,
op_operacion,
op_clase,
op_desc_clase = convert(varchar(30), ''),
op_oficina,
op_desc_oficina = convert(varchar(15), '')
into   #operaciones_op
from   ca_operacion ope, ca_dividendo
where  op_operacion = di_operacion
and    op_estado   in (1,2,9)
and    di_estado   in (1,2)
group  by op_banco, op_operacion, op_clase, op_oficina

update #operaciones_op set
op_desc_clase =  valor
from   cobis..cl_catalogo
where  tabla  = @w_tabla_cat
and    codigo = op_clase

update #operaciones_op set
op_desc_oficina = substring(of_nombre,1,15)
from   cobis..cl_oficina
where  of_oficina = op_oficina

truncate table ca_proyeccion_recuperacion

insert into ca_proyeccion_recuperacion(
pr_fecha_ven,     pr_oficina,       pr_desc_oficina,  
pr_clase,         pr_capital,       pr_interes,       
pr_mipymes,       pr_ivamipymes,    pr_segdeu,        
pr_fng,           pr_otros,         pr_recupera)   
values(           
'FECHA PAGO',      'CODIGO OFICINA',  'NOMBRE OFICINA',  
'TIPO CARTERA',    'CAP',             'INT',             
'MIPYMES',         'IVAMIPYMES',      'SEGDEUVEN.',      
'COMFNGANU',       'OTROS',           'TOTAL')          

insert into ca_proyeccion_recuperacion(
pr_fecha_ven,
pr_oficina,
pr_desc_oficina,
pr_clase,
pr_capital,
pr_interes,
pr_mipymes,
pr_ivamipymes,
pr_segdeu,
pr_fng,
pr_otros,
pr_recupera)
select
convert(varchar(10),di_fecha_ven,101), --1
convert(char(10),op_oficina),          --2
op_desc_oficina,                       --3
op_desc_clase,                         --4
convert(varchar, sum(case am_concepto when 'CAP'        then am_cuota + am_gracia - am_pagado else 0 end)), --5
convert(varchar, sum(case am_concepto when 'INT'        then am_cuota + am_gracia - am_pagado else 0 end)), --6
convert(varchar, sum(case am_concepto when 'MIPYMES'    then am_cuota + am_gracia - am_pagado else 0 end)), --7
convert(varchar, sum(case am_concepto when 'IVAMIPYMES' then am_cuota + am_gracia - am_pagado else 0 end)), --8
convert(varchar, sum(case when am_concepto in ('SEGDEUVEN','SEGDEUEM') then am_cuota + am_gracia - am_pagado else 0 end)),  --9
convert(varchar, sum(case am_concepto when 'COMFNGANU'  then am_cuota + am_gracia - am_pagado else 0 end)),  --10
convert(varchar, sum(case when am_concepto not in ('CAP', 'INT', 'MIPYMES', 'IVAMIPYMES', 'SEGDEUVEN', 'SEGDEUEM', 'COMFNGANU') then am_cuota + am_gracia - am_pagado else 0 end)), --11
convert(varchar, sum(am_cuota + am_gracia - am_pagado))   --12
from  #operaciones_op op, ca_dividendo with (rowlock), ca_amortizacion
where am_operacion  = op_operacion
and   am_operacion  = di_operacion
and   di_operacion  = op_operacion
and   am_dividendo  = di_dividendo
and   di_estado   <> 3
and   di_fecha_ven between @w_fecha_desde and @w_fecha_hasta
group by op_desc_clase, di_fecha_ven, op_oficina, op_desc_oficina

if @@error <> 0 begin
   print 'ERROR EN INSERCION DE REGISTRO DE PROYECCION RECUPERACION'
   goto ERROR
end

select @w_path_s_app = pa_char
from cobis..cl_parametro        
where pa_nemonico = 'S_APP'
                                
select
@w_s_app      = @w_path_s_app + 's_app',
@w_fecha_arch = convert(varchar, @w_fecha_proc, 112)

select @w_path = ba_path_destino
from   cobis..ba_batch
where  ba_arch_fuente = @w_sqr

select
@w_cmd      = @w_s_app + ' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'ca_proyeccion_recuperacion',
@w_destino  = @w_path + @w_file + '_' + @w_fecha_arch + '.txt',
@w_errores  = @w_path + @w_file + '_' + @w_fecha_arch + '.err'


select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino +
' -b5000 -c -e' + @w_errores + ' -t";" ' + '-config ' + @w_s_app + '.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0
begin
   print 'ERROR EN EJECUCION DE BCP'
   goto ERROR
end

return 0
ERROR:
return 0

go

