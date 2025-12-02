/************************************************************************/
/*       Nombre Fisico:         carepreest.sp                           */
/*       Nombre Logico:      	sp_rep_reestruc                         */
/*       Base de datos:         cob_cartera                             */
/*       Producto:              Cartera                                 */
/*       Disenado por:          Juan B. Quinche                         */
/*       Fecha de escritura:    Feb. 2009                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Generador de los datos de las operaciones reestructuras de acuerdo */
/*   diferentes condiciones de seleccion.                               */
/************************************************************************/
/*                         Modificaciones                               */
/*  24-mar-2009         JBQ               Version Inicial               */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calif_rees   	*/
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_reestruc')
   drop proc sp_rep_reestruc
go
create procedure sp_rep_reestruc
    @i_fecha_ini  datetime    = null,
    @i_fecha_fin  datetime    = null,
    @i_tipo_cond  char(1)     ='O',
    @i_codigo     int         = 1
as

set nocount on

declare  @w_sp_name           varchar(32),
         @w_return            int,
         @w_error             int,
         @w_msg               varchar(60),
         @w_fec_ult_reest     datetime,
         @w_fec_ant_reest     datetime,
         @w_oficina           int,
         @w_oficial           int,
         @w_fecha_mov         datetime,
         @w_nom_oficina       varchar(64),
         @w_operacion         int,
         @w_cliente           int,
         @w_banco             cuenta,
         @w_ope_ant           int,
         @w_num_ope           int,
         @w_ofi_ant           int,
         @w_capital           money,
         @w_intereses         money,
         @w_mora              money,
         @w_seguros           money,
         @w_mipyme            money,
         @w_comfng            money,
         @w_otros             money,
         @w_rees_capital      money,
         @w_rees_intereses    money,
         @w_rees_mora         money,
         @w_rees_seguros      money,
         @w_rees_mipyme       money,
         @w_rees_comfng       money,
         @w_rees_otros        money,
         @w_est_vigente       int,
         @w_est_vencido       int,
         @w_est_cancelado     int,
         @w_est_castigado     int,
         @w_est_suspenso      int,
         @w_calificacion      catalogo,
         @w_calif_rees        catalogo,
         @w_concepto          varchar(10),
         @w_secuencial        int,
         @w_tipo_id           char(2),
         @w_identif           numero,
         @w_nombre            varchar(254),
         @w_valor             money, 
         @w_cont              int


select
@w_sp_name        = 'sp_rep_reestruc',
@w_return         = 0

delete ca_estado_reestructuradas_tmp WHERE er_operacion >= 0

--create table #ca_estado_reestructuradas_tmp  (
--         er_oficina           int            null,
--         er_oficial           int            null,
--         er_operacion         int            null,
--         er_tipo_id           char(2)        null,
--         er_identif           numero         null,
--         er_nombre            varchar(64)    null,
--         er_fecha_mov         datetime       null,
--         er_nom_oficina       varchar(64)    null,
--         er_capital           money          null,
--         er_intereses         money          null,
--         er_mora              money          null,
--         er_seguros           money          null,
--         er_mipyme            money          null,
--         er_comfng            money          null,
--         er_otros             money          null,
--         er_rees_capital      money          null,
--         er_rees_intereses    money          null,
--         er_rees_mora         money          null,
--         er_rees_seguros      money          null,
--         er_rees_mipyme       money          null,
--         er_rees_comfng       money          null,
--         er_rees_otros        money          null,
--         er_calificacion      catalogo        null,
--         er_calif_rees        catalogo        null,
--         er_banco             cuenta         null
--         )


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

if @i_tipo_cond = 'O'     -- OFICINA
declare cur_ope cursor for
   select
   op_oficina,
   op_oficial,
   op_operacion,
   sum(am_cuota + am_gracia - am_pagado)
   from  cob_cartera..ca_operacion,
         cob_cartera..ca_dividendo,
         cob_cartera..ca_amortizacion
   where op_naturaleza  = 'A'  --Para procesar solo operaciones activas
   and   op_estado      in (@w_est_vigente,@w_est_vencido,@w_est_suspenso)
   --and   op_estado      in (1,2,9)
   and   di_operacion   = op_operacion
   and   di_fecha_ven   >= @i_fecha_ini
   and   di_fecha_ven   <= @i_fecha_fin
   and   am_operacion   = di_operacion
   and   am_dividendo   = di_dividendo
   and   op_numero_reest > 0
   and   op_oficina     = @i_codigo
   group by op_oficina, op_oficial, op_operacion
   order by op_oficina, op_oficial, op_operacion
for read only
if @i_tipo_cond = 'T' -- TERRITORIAL/CENTRO COSTO
declare cur_ope cursor for
   select
   op_oficina,
   op_oficial,
   op_operacion,
   sum(am_cuota + am_gracia - am_pagado)
   from  cob_cartera..ca_operacion,
         cob_cartera..ca_dividendo,
         cob_cartera..ca_amortizacion
   where op_naturaleza  = 'A'  --Para procesar solo operaciones activas
   and   op_estado      in (@w_est_vigente,@w_est_vencido,@w_est_suspenso)
   --and   op_estado      in (1,2,9)
   and   di_operacion   = op_operacion
   and   di_fecha_ven   >= @i_fecha_ini
   and   di_fecha_ven   <= @i_fecha_fin
   and   am_operacion   = di_operacion
   and   am_dividendo   = di_dividendo
   and   op_numero_reest > 0
   and   op_oficina     in (select of_oficina from cobis..cl_oficina where of_subtipo ='C')
   group by op_oficina, op_oficial, op_operacion
   order by op_oficina, op_oficial, op_operacion
for read only
if @i_tipo_cond = 'R'   -- REGIONAL
declare cur_ope cursor for
   select
   op_oficina,
   op_oficial,
   op_operacion,
   sum(am_cuota + am_gracia - am_pagado)
   from  cob_cartera..ca_operacion,
         cob_cartera..ca_dividendo,
         cob_cartera..ca_amortizacion
   where op_naturaleza  = 'A'  --Para procesar solo operaciones activas
   and   op_estado      in (@w_est_vigente,@w_est_vencido,@w_est_suspenso)
   --and   op_estado      in (1,2,9)
   and   di_operacion   = op_operacion
   and   di_fecha_ven   >= @i_fecha_ini
   and   di_fecha_ven   <= @i_fecha_fin
   and   am_operacion   = di_operacion
   and   am_dividendo   = di_dividendo
   and   op_numero_reest > 0
   and   op_oficina     in (select of_oficina from cobis..cl_oficina where of_subtipo ='R')
   group by op_oficina, op_oficial, op_operacion
   order by op_oficina, op_oficial, op_operacion
for read only
if @i_tipo_cond = 'E'    -- Ejecutivo
declare cur_ope cursor for
   select
   op_oficina,
   op_oficial,
   op_operacion,
   sum(am_cuota + am_gracia - am_pagado)
   from  cob_cartera..ca_operacion,
         cob_cartera..ca_dividendo,
         cob_cartera..ca_amortizacion
   where op_naturaleza  = 'A'  --Para procesar solo operaciones activas
   and   op_estado      in (@w_est_vigente,@w_est_vencido,@w_est_suspenso)
   --and   op_estado      in (1,2,9)
   and   di_operacion   = op_operacion
   and   di_fecha_ven   >= @i_fecha_ini
   and   di_fecha_ven   <= @i_fecha_fin
   and   am_operacion   = di_operacion
   and   am_dividendo   = di_dividendo
   and   op_numero_reest > 0
   and   op_oficial     = @i_codigo
   group by op_oficina, op_oficial, op_operacion
   order by op_oficina, op_oficial, op_operacion
for read only

select @w_cont = 1
open cur_ope
fetch cur_ope
into @w_oficina,     @w_oficial,    @w_operacion, 
     @w_valor

while @@fetch_status = 0 begin

   select  @w_banco = op_banco,
   @w_calif_rees    = isnull(op_calificacion_ant,''),
   @w_cliente       = op_cliente
   from ca_operacion
   where op_operacion=@w_operacion
   
   select
   @w_nombre  = en_nomlar,
   @w_identif = en_ced_ruc,
   @w_tipo_id = en_tipo_ced
   from cobis..cl_ente
   where en_ente =@w_cliente

  --- buscar la ultima reestructuracion por operacion,
   select @w_fec_ult_reest = max(tr_fecha_mov)
   from ca_transaccion
   where tr_operacion = @w_operacion
   and tr_tran ='RES'

   if @w_fec_ult_reest is not null begin

      --- obtencion de los demas campos

      select @w_calificacion = tr_calificacion,
             @w_secuencial   = tr_secuencial
      from ca_transaccion, ca_det_trn
      where tr_operacion    = @w_operacion
      and   dtr_operacion   = tr_operacion
      and   dtr_secuencial = tr_secuencial
      and   tr_tran = 'RES'
      --- buscar los datos del momento de la reestructuracion
      --- calcular los valores de saldo para los diferentes rubros
      select
      @w_capital     = sum(case when am_concepto = 'CAP'       then am_acumulado-am_pagado else 0 end),
      @w_intereses   = sum(case when am_concepto = 'INT'       then am_acumulado-am_pagado else 0 end),
      @w_mora        = sum(case when am_concepto = 'IMO'       then am_acumulado-am_pagado else 0 end),
      @w_seguros     = sum(case when am_concepto = 'CAP'       then am_acumulado-am_pagado else 0 end),
      @w_mipyme      = sum(case when am_concepto = 'MIPYME'    then am_acumulado-am_pagado else 0 end),
      @w_comfng      = sum(case when am_concepto = 'IVAMIPYME' then am_acumulado-am_pagado else 0 end),
      @w_otros       = sum(case when am_concepto not in ('CAP','INT','IMO','MIPYME', 'IVAMIPYME') then am_acumulado-am_pagado else 0 end)

      --@w_dias_mora
      --obtener calificacion al reestructurar
      from ca_dividendo,ca_amortizacion
      where am_operacion = @w_operacion
      and am_operacion = di_operacion
      and di_operacion = @w_operacion
      and di_fecha_ini >= @w_fec_ult_reest

      --- entre la ultima reestructuracion y la anterior a esa ( si la hubo)
      select @w_fec_ant_reest = max(tr_fecha_mov)
      from ca_transaccion
      where tr_operacion = @w_operacion
      and   tr_fecha_mov > @w_fec_ult_reest
      and   tr_tran = 'RES'

      -- obtener informacion antes de la reestructuracion
      
      --@w_dias_mora
      --obtener calificacion al reestructurar
      select
      @w_rees_capital     = sum(case when amh_concepto = 'CAP'     then amh_acumulado-amh_pagado   else 0 end),
      @w_rees_intereses   = sum(case when amh_concepto = 'INT'     then amh_acumulado-amh_pagado   else 0 end),
      @w_rees_mora        = sum(case when amh_concepto = 'IMO'     then amh_acumulado-amh_pagado   else 0 end),
      @w_rees_seguros     = sum(case when amh_concepto = 'CAP'     then amh_acumulado-amh_pagado   else 0 end),
      @w_rees_mipyme      = sum(case when amh_concepto = 'MIPYME'  then amh_acumulado-amh_pagado   else 0 end),
      @w_rees_comfng      = sum(case when amh_concepto = 'IVAMIPYME' then amh_acumulado-amh_pagado else 0 end),
      @w_rees_otros       = sum(case when amh_concepto not in ('CAP','INT','IMO','MIPYME', 'IVAMIPYME') then amh_acumulado-amh_pagado else 0 end)
      from ca_dividendo_his,ca_amortizacion_his
      where amh_operacion = @w_operacion
      and amh_operacion = dih_operacion
      and dih_operacion = @w_operacion
      and dih_fecha_ini >= @w_fec_ult_reest

      insert into ca_estado_reestructuradas_tmp
      values ( @w_oficina,          @w_oficial,         @w_operacion,
               @w_tipo_id,          @w_identif,         @w_nombre,
               @w_fec_ult_reest,    @w_nom_oficina,     @w_capital,
               @w_intereses,        @w_mora,            @w_seguros,
               @w_mipyme,           @w_otros,           @w_comfng,          @w_rees_capital,
               @w_rees_intereses,   @w_rees_mora,       @w_rees_seguros,
               @w_rees_mipyme,      @w_rees_comfng,     @w_rees_otros,      
               @w_calificacion,     @w_calif_rees,      @w_banco)

   end    -- @w_fec_ult_reest is not null
   fetch cur_ope
   into @w_oficina,     @w_oficial,    @w_operacion, 
        @w_valor
         
   select @w_cont = @w_cont +1      
end

select
     er_oficina,
     er_oficial,
     er_fecha_mov,
     er_tipo_id,
     er_identif,
     er_banco,
     er_fecha_mov,
     'nombre oficina'=( select of_nombre
                        from cobis..cl_oficina
                        where of_oficina=   er_oficina ),
     er_capital,
     er_intereses,
     er_mora,
     er_seguros,
     er_mipyme,
     er_comfng,
     er_otros,
     er_rees_capital,
     er_rees_intereses,
     er_rees_mora,
     er_rees_seguros,
     er_rees_mipyme,
     er_rees_comfng,
     er_rees_otros,
     er_calificacion,
     er_calif_rees,
     er_nombre,
     'er_funcionario'=( select fu_nombre
                        from cobis..cl_funcionario
                        where fu_funcionario = er_oficial),
     'cond_rep'=@i_tipo_cond                                    -- le informa al SQR que tipo de reporte es
     from ca_estado_reestructuradas_tmp
return 0
go

