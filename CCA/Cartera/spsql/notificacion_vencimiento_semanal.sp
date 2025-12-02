/************************************************************************/
/*   NOMBRE LOGICO:      notificacion_vencimiento_semanal.sp            */
/*   NOMBRE FISICO:      sp_notificacion_vencimiento_semanal            */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Guisela Fernandez                              */
/*   FECHA DE ESCRITURA: 14/11/2022                                     */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Envio de notificación de vencimientos semanales de cuotas           */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 14/11/2022     G. Fernandez       Versión inicial                    */
/* 03/04/2023     K. Rodríguez       S802939 Copia correo Jefe agencia  */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_notificacion_vencimiento_semanal')
   drop proc sp_notificacion_vencimiento_semanal
go

create proc sp_notificacion_vencimiento_semanal
(
   @i_param1                  datetime = null
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
@w_correo_jefe_agenc varchar(64),
@w_email_body_html   varchar(max),
@w_correos_cc        varchar(129),
@w_banco             cuenta,
@w_cliente           descripcion, 
@w_num_dividendo     int, 
@w_valor_cuota       money,
@w_id_plantilla      smallint,    
@w_fecha_ven         smalldatetime,  
@w_cod_cliente       int,
@w_cod_grupo         int,

@w_numop_lbl         varchar(35),
@w_div_lbl           varchar(16),
@w_fven_lbl          varchar(36),
@w_codcli_lbl        varchar(27),
@w_cli_lbl           varchar(171),
@w_codgru_lbl        varchar(27),
@w_cuo_lbl           varchar(31)


--Creacion de tabla temporal 
CREATE TABLE #det_op_prox_ven (
cod_ofi_super     INT,
nom_ofi_super     VARCHAR (64),
correo_ofi_super  VARCHAR (64),
cod_oficial       INT,
nom_oficial       VARCHAR (64),
correo_oficial    VARCHAR (64),
oficina_oficial   smallint,
cod_ofi_jefe_agen int,
correo_jefe_agenc varchar (64),
banco             cuenta,
cod_cliente       int,
cliente           VARCHAR (64), 
num_dividendo     INT,
valor_cuota       money,
fecha_ven         smalldatetime,
cod_grupo         int
)

select @w_sp_name = 'sp_notificacion_vencimiento_semanal'

select @w_fecha_proceso    = isnull(@i_param1, fp_fecha) 
from cobis..ba_fecha_proceso

--Obtenemos las fecha de inicio y fin de semana
select @w_fecha_ini_semana = dateadd(wk,datediff(wk,0,@w_fecha_proceso)+1,0),
       @w_fecha_fin_semana = dateadd(wk,datediff(wk,0,@w_fecha_proceso)+1,6)

--Se inserta las operaciones en estado vencido para la proxima semana con los codigos de oficial superior y oficial
insert into #det_op_prox_ven (cod_ofi_super, cod_oficial, banco, cod_cliente, cliente, cod_grupo, num_dividendo, valor_cuota, fecha_ven)
select  oc_ofi_nsuperior,
        oc_oficial,
        op_banco,
        op_cliente,
		op_nombre,
        isnull(op_grupo, 0),
        di_dividendo,
        sum(am_cuota),
        di_fecha_ven
from cobis..cc_oficial,
     cob_cartera..ca_operacion,
     cob_cartera..ca_dividendo,
     cob_cartera..ca_amortizacion
where op_oficial   = oc_oficial
and   op_operacion = di_operacion
and   op_operacion = am_operacion
and   di_dividendo = am_dividendo
and   op_estado NOT  IN  (0,3,99,6,4)
and   di_estado <> 3
and   di_fecha_ven >= @w_fecha_ini_semana
and   di_fecha_ven <= @w_fecha_fin_semana
group by oc_ofi_nsuperior, oc_oficial, op_banco,op_cliente, op_nombre, op_grupo, di_dividendo, di_fecha_ven

if @@rowcount = 0
begin
   select @w_error = 77539 -- No existe informacion para los criterios consultados
   goto ERROR
end 

-- Se actualiza los datos de nombre y correo de oficial supervisor
update #det_op_prox_ven
set nom_ofi_super     = fu_nombre,
    correo_ofi_super  = fu_correo_electronico,
	cod_ofi_jefe_agen = oc_ofi_nsuperior
from cobis..cl_funcionario,
     cobis..cc_oficial
where oc_oficial     = cod_ofi_super
AND   oc_funcionario = fu_funcionario 

-- Se actualiza los datos de nombre y correo de oficial de credito
update #det_op_prox_ven
set nom_oficial     = fu_nombre,
    correo_oficial  = fu_correo_electronico,
	oficina_oficial = fu_oficina
from cobis..cl_funcionario,
     cobis..cc_oficial
where oc_oficial     = cod_oficial
and   oc_funcionario = fu_funcionario

-- Se actualiza los datos de nombre y correo de jefe de agencia
update #det_op_prox_ven
set correo_jefe_agenc = fu_correo_electronico
from cobis..cl_funcionario,
     cobis..cc_oficial
where oc_oficial     = cod_ofi_jefe_agen
and   oc_funcionario = fu_funcionario

-- Obtenemos los oficiales a los cuales se enviara el correo
select distinct cod_oficial 
into #num_notificaciones
from #det_op_prox_ven

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
      @w_correo_oficial    = correo_oficial,
      @w_correo_jefe_agenc = correo_jefe_agenc	  
	  from #det_op_prox_ven
	  where cod_oficial = @w_oficial
	  
	  --Tabla temporal para optener las operaciones que se enviaran en la notificacion
	  select  banco, cliente, num_dividendo, valor_cuota, fecha_ven, cod_cliente, cod_grupo 
	  into #num_operaciones
	  from #det_op_prox_ven
	  where cod_oficial = @w_oficial
	  
      select @w_banco             = '',--Inicializacion de número de préstamo
             @w_email_body_html  = '<?xml version="1.0" encoding="UTF-8"?><data><funcionario>'+@w_nom_oficial+'</funcionario>'
      
	  --Bucle para llenar las etiquetas de la plantilla con datos de las operaciones
	  while 1= 1
	  begin
	     --Se obtiene datos de las operaciones 
	     select top 1 @w_banco          = banco,
		              @w_num_dividendo  = num_dividendo,
                      @w_fecha_ven      = fecha_ven,
		              @w_cod_cliente    = cod_cliente,
	                  @w_cliente        = cliente, 
					  @w_cod_grupo      = cod_grupo,
	                  @w_valor_cuota    = valor_cuota 
	     from #num_operaciones
	     where banco > @w_banco
	     order by banco asc
	     
	     if @@rowcount = 0
	        break
		 	
		 select @w_numop_lbl  = '<num>'+convert(varchar(24), @w_banco)+'</num>',
		        @w_div_lbl    = '<div>'+convert(varchar(24), @w_num_dividendo)+'</div>',
		        @w_fven_lbl   = '<fve>'+convert(varchar(24), convert(varchar(10), @w_fecha_ven, 103))+'</fve>',
		        @w_codcli_lbl = '<idc>'+convert(varchar(24), @w_cod_cliente)+'</idc>',
		        @w_cli_lbl    = '<cli>'+convert(varchar(24), @w_cliente)+'</cli>',
		        @w_codgru_lbl = '<gru>'+convert(varchar(24), @w_cod_grupo)+'</gru>',
		        @w_cuo_lbl    = '<cuo>'+convert(varchar(24), @w_valor_cuota)+'</cuo>'
				
		 select @w_email_body_html  = @w_email_body_html + '<operacion>'+ @w_numop_lbl + @w_div_lbl + @w_fven_lbl + @w_codcli_lbl + @w_cli_lbl + @w_codgru_lbl + @w_cuo_lbl + '</operacion>'
	  
	  end
	  
	  select @w_email_body_html  = @w_email_body_html + '</data>'
	  
	  -- Direcciones de correo copia

      if @w_correo_ofi_super is not null and @w_correo_jefe_agenc is not null
         select @w_correos_cc = @w_correo_ofi_super + ';' + @w_correo_jefe_agenc
      else 
      if @w_correo_ofi_super is not null and @w_correo_jefe_agenc is null
         select @w_correos_cc = @w_correo_ofi_super
      else
      if @w_correo_ofi_super is null and @w_correo_jefe_agenc is not null
         select @w_correos_cc = @w_correo_jefe_agenc

		 
	  -- Registro de la pantilla
      select @w_id_plantilla =  te_id
      from cobis..ns_template
      where te_nombre = 'Vencimiento_semanal.xslt'

      exec @w_error = cobis..sp_despacho_ins
      @i_cliente            = 0,
      @i_template			= @w_id_plantilla,
      @i_servicio           = 1, 
      @i_estado             = 'P', 
      @i_tipo               = 'MAIL', 
      @i_tipo_mensaje       = 'I', 
      @i_prioridad          = 1, 
      @i_to                 = @w_correo_oficial,
	  @i_cc                 = @w_correos_cc,           
      @i_subject            = 'Notificación de vencimientos semanales',
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

return 0

ERROR:           
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error 

go
