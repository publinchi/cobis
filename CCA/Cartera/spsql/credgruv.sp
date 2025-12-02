/************************************************************************/
/*   Archivo:                 credgruv.sp                               */
/*   Stored procedure:        sp_creditos_grupales_vencidos             */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            DFu                                       */
/*   Fecha de Documentacion:  Jun. 2017                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Generar lista de grupos con cuotas grupales vencidas para envio    */
/*   de correo electronico a gerents y coordinadores                    */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  28/jun/2017  DFu               Emision inicial                      */
/*  25/ene/2018  D. Cumbal         Cambio 93833                         */
/************************************************************************/

use cob_cartera
go

if exists(select * from sysobjects where name = 'sp_creditos_grupales_vencidos')
   drop proc sp_creditos_grupales_vencidos
go

create proc sp_creditos_grupales_vencidos (
    @i_param1      int = 9999, --Sarta
    @i_param2      int = 7075  --Batch
)
as

declare
@w_error          int,
@w_valida_error   char(1),
@w_sp_name        varchar(30),
@w_est_vigente    smallint,
@w_est_vencido    smallint,
@w_cmd            varchar(1000),
@w_mensaje        varchar(255),
@w_fecha_proce    datetime,
@w_path_out       varchar(255),
@w_path_in        varchar(255),
@w_archivoSql     varchar(255),
@w_archivoXml     varchar(255)

select @w_sp_name = 'sp_creditos_grupales_vencidos', @w_valida_error = 'S'

--Obtener el path fuente y destino del archivo
Select 
@w_path_out = ba_path_destino,
@w_path_in  = ba_path_fuente
from  cobis..ba_batch
where ba_batch = @i_param2

if (isnull(@w_path_out, '') = '' or isnull(@w_path_in, '') = '') 
begin
    select @w_error = 1
    select @w_mensaje = 'No existen rutas para generar el archivo xml'
    goto ERROR
end

select @w_fecha_proce = fp_fecha from cobis..ba_fecha_proceso

exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out

if @w_error <> 0 goto ERROR

truncate table ca_grupos_vencidos

insert into ca_grupos_vencidos
select distinct
gv_asesor_id       = convert(int,0),
gv_asesor_name     = convert(varchar(60),''),
gv_coord_id        = convert(int,0),
gv_coord_name      = convert(varchar(60),''),
gv_coord_email     = convert(varchar(60),''),
gv_gerente_id      = convert(int,0),
gv_gerente_name    = convert(varchar(60),''),
gv_gerente_email   = convert(varchar(60),''),
gv_grupo_id        = tg_grupo,
gv_grupo_name      = convert(varchar(60),''),
gv_referencia      = tg_referencia_grupal,
gv_vencido_desde   = min(di_dividendo),
gv_vencido_hasta   = max(di_dividendo),
gv_cuotas_vencidas = max(di_dividendo) -min(di_dividendo) +1,
gv_saldo_exigible  = convert(money,0),
gv_cuota_actual    = convert(money,0),
NULL, NULL, NULL                            --LRE 22Ago2019
from   cob_credito..cr_tramite_grupal, ca_operacion, ca_dividendo 
where  tg_operacion  = op_operacion
and    op_operacion  = di_operacion 
and    di_estado     = @w_est_vencido 
and    op_estado    in (@w_est_vigente, @w_est_vencido)
group by tg_grupo,tg_referencia_grupal

if (@@error != 0)
begin
    select @w_error = @@error,
           @w_mensaje = 'Ocurrió un error al insertar en la temporal de cartera grupal vencida'
    goto ERROR
end

select @w_mensaje = 'Ocurrió un error al actualizar en la temporal de cartera grupal vencida'

/*Actualizar id del asesor y nombre del grupo*/
update ca_grupos_vencidos set
gv_asesor_id  = gr_oficial,
gv_grupo_name = cob_conta_super.dbo.fn_formatea_ascii_ext(gr_nombre, 'AN')
from cobis..cl_grupo
where gv_grupo_id  = gr_grupo

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

/*Actualizar nombre del asesor y id del coordinador*/
update ca_grupos_vencidos set
gv_asesor_name = cob_conta_super.dbo.fn_formatea_ascii_ext(fu_nombre, 'AN'),
gv_coord_id    = oc_ofi_nsuperior
from cobis..cc_oficial, cobis..cl_funcionario
where gv_asesor_id   = oc_oficial
and   oc_funcionario = fu_funcionario

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

/*Actualizar nombre del coordinador y id gerente*/
update ca_grupos_vencidos set
gv_coord_name = cob_conta_super.dbo.fn_formatea_ascii_ext(fu_nombre, 'AN'),
gv_gerente_id = isnull(oc_ofi_nsuperior,0)
from cobis..cc_oficial, cobis..cl_funcionario
where gv_coord_id    = oc_oficial
AND   oc_funcionario = fu_funcionario

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

update ca_grupos_vencidos set
gv_gerente_name = cob_conta_super.dbo.fn_formatea_ascii_ext(fu_nombre, 'AN')
from cobis..cl_funcionario
where gv_gerente_id  = fu_funcionario

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

/*INI AGI. 22ABR19.  Se comenta porque no se encuentra el campo oc_mail en la tabla cc_oficial
--Actualizar emails
update ca_grupos_vencidos set 
gv_coord_email = isnull(oc_mail,'')
from  cobis..cc_oficial 
where gv_coord_id = oc_funcionario

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end


update ca_grupos_vencidos set 
gv_gerente_email = isnull(oc_mail,'')
from  cobis..cc_oficial 
where gv_gerente_id = oc_funcionario

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end
*/
--FIN AGI


/*Actualizar saldo exigible*/
select 
grupo      = gv_grupo_id,
ref_grupal = gv_referencia,
sum((am_cuota + am_gracia) - am_pagado) saldo
into #saldos_exigible
from ca_grupos_vencidos, cob_credito..cr_tramite_grupal,ca_amortizacion,ca_dividendo 
where gv_referencia    = tg_referencia_grupal
and   tg_operacion  = am_operacion 
and   tg_operacion  = di_operacion
and   am_dividendo  = di_dividendo
and   am_dividendo between gv_vencido_desde and gv_vencido_hasta
and   di_estado = @w_est_vencido
group by gv_grupo_id, gv_referencia

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

update ca_grupos_vencidos set
gv_saldo_exigible = saldo
from #saldos_exigible
where gv_grupo_id   = grupo
and   gv_referencia = ref_grupal

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

/*Actualizar cuota actual*/
select 
grupo      = gv_grupo_id,
ref_grupal = gv_referencia,
sum(am_cuota + am_gracia) saldo
into  #cuotas_actual
from  ca_grupos_vencidos, cob_credito..cr_tramite_grupal,ca_amortizacion,ca_dividendo 
where gv_referencia = tg_referencia_grupal
and   tg_operacion  = am_operacion 
and   tg_operacion  = di_operacion
and   am_dividendo  = di_dividendo
and   am_dividendo  = gv_vencido_hasta
and   di_estado     = @w_est_vencido
group by gv_grupo_id, gv_referencia

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

update ca_grupos_vencidos set
gv_cuota_actual = saldo
from #cuotas_actual
where gv_grupo_id   = grupo
and   gv_referencia = ref_grupal

if (@@error != 0) 
begin 
    select @w_error = @@error
    goto ERROR
end

-- LGU este control pasa al generador de xml ahi
-- se controla el borrado y paso a historicos
--if (exists (select 1 from ca_grupos_vencidos))
begin

    exec @w_error = cob_cartera..sp_grupos_vencidos_xml 
        @i_tipo_rep = 'PFGVC' 

    if @w_error != 0 
    begin
        select @w_mensaje = 'Error al generar archivo xml'
        goto ERROR
    end

    exec @w_error = cob_cartera..sp_grupos_vencidos_xml 
        @i_tipo_rep = 'PFGVG' 

    if @w_error != 0 
    begin
        select @w_mensaje = 'Error al generar archivo xml'
        goto ERROR
    end
end
/*else 
begin
    select @w_error = 724637, @w_valida_error = 'N'
    select @w_mensaje = 'Error: No existe datos en el proceso'
    goto ERROR
end*/

return 0

ERROR:
/*
exec cobis..sp_cerror
    @t_debug = 'N',
    @t_file  = null,
    @t_from  = 'sp_creditos_grupales_vencidos',
    @i_num   = @w_error*/
exec sp_errorlog
   @i_fecha     = @w_fecha_proce,
   @i_error     = @w_error, 
   @i_usuario   = 'sa', 
   @i_tran      = @i_param2,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = null,
   @i_anexo     = @w_mensaje,
   @i_rollback  = 'N'

if (@w_valida_error = 'S')
begin
   return @w_error
end
else
begin
   return 0
end
GO
