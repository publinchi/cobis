/************************************************************************/
/*   Archivo:              notificacion_cuotas_vencidas.sp              */
/*   Stored procedure:     sp_notificacion_cuotas_vencidas              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   14/11/2022                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Envio de notificación de de cuotas vencidas con abono a capital     */
/* (más de dos cuotas)                                                  */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 14/11/2022     G. Fernandez       Versión inicial                    */
/* 30/12/2024     K. Rodriguez       R255575 No error al no existir regs*/
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_notificacion_cuotas_vencidas')
   drop proc sp_notificacion_cuotas_vencidas
go

create proc sp_notificacion_cuotas_vencidas(
   @i_param1                  datetime = null-- fecha de proceso
)
AS

DECLARE 
@w_sp_name               varchar (32),
@w_error                 int = 0,

@w_fecha_proceso     DATETIME,
@w_fecha_ini_semana  DATETIME,
@w_fecha_fin_semana  DATETIME,

@w_ofi_super         varchar(64),
@w_correo_ofi_super  varchar(64),
@w_nom_oficial       varchar(64),
@w_correo_oficial    varchar(64), 
@w_oficial           int,
@w_email_body_html   varchar(max),
@w_banco             cuenta,
@w_cliente           descripcion, 
@w_num_dividendo     int, 
@w_valor_cuota       money,
@w_id_plantilla      smallint,
@w_secuencial_op     int

--Creacion de tabla temporal 
CREATE TABLE #det_cuotas_vencidas (
cod_ofi_super     INT,
nom_ofi_super     VARCHAR (64),
correo_ofi_super  VARCHAR (64),
cod_oficial       INT,
nom_oficial       VARCHAR (64),
correo_oficial    VARCHAR (64),
banco             cuenta,
cliente           VARCHAR (64), 
num_dividendo     INT,
valor_cuota       money
)

select @w_sp_name = 'sp_notificacion_cuotas_vencidas'

--Obtenemos las fecha de inicio y fin de semana
select @w_fecha_proceso    = isnull(@i_param1, fp_fecha) 
from cobis..ba_fecha_proceso

--Obtenemos las operaciones que mas de dos cuotas vencidas con abono a capital
select 'num_operacion' = am_operacion, 'num_cuotas' = count(1)
into #operaciones_vencidas
from cob_cartera..ca_operacion,     cob_cartera..ca_amortizacion,     cob_cartera..ca_dividendo
where op_operacion = di_operacion
and   am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   op_estado NOT  IN  (0,3,99,6,4)
and   am_concepto  = 'CAP'
and   am_pagado   <> 0
and   di_estado    = 2
and   di_fecha_ven <= @w_fecha_proceso
group by am_operacion
having count(1) > 2

if @@rowcount = 0
   goto FIN
/*begin
   select @w_error = 77539 
   goto ERROR
end */
	   
--Se inserta las operaciones en estado vencido para la proxima semana con los codigos de oficial superior y oficial
insert into #det_cuotas_vencidas (cod_ofi_super, cod_oficial, banco, cliente, num_dividendo, valor_cuota)
select  oc_ofi_nsuperior,
        oc_oficial,
        op_banco, 
		op_nombre,
        di_dividendo,
        sum(am_cuota-am_pagado)
 
from cobis..cc_oficial,
     cob_cartera..ca_operacion,
     cob_cartera..ca_dividendo,
     cob_cartera..ca_amortizacion,
	 #operaciones_vencidas
where op_oficial   = oc_oficial
and   op_operacion = di_operacion
and   op_operacion = num_operacion
and   op_operacion = am_operacion
and   di_dividendo = am_dividendo
and   di_estado = 2
and   di_fecha_ven <=  @w_fecha_proceso
group by oc_ofi_nsuperior, oc_oficial, op_banco,op_nombre, di_dividendo

-- Se actualiza los datos de nombre y correo de oficial supervisor
UPDATE #det_cuotas_vencidas
SET nom_ofi_super    = fu_nombre,
    correo_ofi_super = fu_correo_electronico
FROM cobis..cl_funcionario,
     cobis..cc_oficial
WHERE oc_oficial     = cod_ofi_super
AND   oc_funcionario = fu_funcionario 

-- Se actualiza los datos de nombre y correo de oficial de credito
UPDATE #det_cuotas_vencidas
SET nom_oficial    = fu_nombre,
    correo_oficial = fu_correo_electronico
FROM cobis..cl_funcionario,
     cobis..cc_oficial
WHERE oc_oficial     = cod_oficial
AND   oc_funcionario = fu_funcionario

-- Obtenemos los oficiales a los cuales se enviara el correo
SELECT distinct cod_oficial 
into #num_notificaciones
FROM #det_cuotas_vencidas

--Inicio de cursor para completar datos
declare registros_notificaciones cursor for
select cod_oficial 
from #num_notificaciones

open registros_notificaciones

fetch next from registros_notificaciones into
@w_oficial

while (@@fetch_status = 0)
begin
	  --Se obtiene los datos del oficial supervisor y oficial de credito
      select @w_ofi_super  = nom_ofi_super,
      @w_correo_ofi_super  = correo_ofi_super,
      @w_nom_oficial       = nom_oficial,
      @w_correo_oficial    = correo_oficial	  
	  from #det_cuotas_vencidas
	  where cod_oficial = @w_oficial
	  
	  --Tabla temporal para optener las operaciones que se enviaran en la notificacion
	  select  banco, cliente, num_dividendo, valor_cuota 
	  into #num_operaciones
	  from #det_cuotas_vencidas
	  where cod_oficial = @w_oficial
	  
	  Alter Table #num_operaciones Add secuencial Int Identity(1, 1)
	  
      select @w_secuencial_op    = 0,
             @w_email_body_html  = '<?xml version="1.0" encoding="UTF-8"?><data><funcionario>'+@w_nom_oficial+'</funcionario>'
      
	  --Bucle para llenar las etiquetas de la plantilla con datos de las operaciones
	  while 1= 1
	  begin
	     --Se obtiene datos de las operaciones 
	     select top 1 @w_banco          = banco,
	                  @w_cliente        = cliente, 
	                  @w_num_dividendo  = num_dividendo, 
	                  @w_valor_cuota    = valor_cuota,
					  @w_secuencial_op  = secuencial
	     from #num_operaciones
	     where secuencial > @w_secuencial_op
	     order by secuencial asc
	     
	     if @@rowcount = 0
	        break
		 	
		 select @w_email_body_html  = @w_email_body_html + '<operacion><num>'+convert(varchar(24), @w_banco)+'</num><cli>'+convert(varchar(24), @w_cliente)+'</cli><div>'+convert(varchar(24), @w_num_dividendo)+'</div><cuo>'+convert(varchar(24), @w_valor_cuota)+'</cuo></operacion>'
	  
	  end
	  
	  select @w_email_body_html  = @w_email_body_html + '</data>'
	  
	  -- Registro de la pantilla
      select @w_id_plantilla =  te_id
      from cobis..ns_template
      where te_nombre = 'Vencimiento_cuotas.xslt'

      exec @w_error = cobis..sp_despacho_ins
      @i_cliente            = 0,
      @i_template			= @w_id_plantilla,
      @i_servicio           = 1, 
      @i_estado             = 'P', 
      @i_tipo               = 'MAIL', 
      @i_tipo_mensaje       = 'I', 
      @i_prioridad          = 1, 
      @i_to                 = @w_correo_oficial,
	  @i_cc                 = @w_correo_ofi_super,           
      @i_subject            = 'Notificación de vencimientos cuotas con abono a capital',
      @i_body               = @w_email_body_html,
      @i_content_manager    = 'HTML',
      @i_retry              = 'S',
      @i_max_tries          = 2
      
      if @w_error  <> 0 
      goto ERROR
      
	  --Se eliman la tabla de registro de las operacion a enviar en la notificacion
      drop table #num_operaciones
	  
   	  fetch next from registros_notificaciones into
	  @w_oficial
end

	  close registros_notificaciones
	  deallocate registros_notificaciones

FIN:
return 0

ERROR:           
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error 

go
