/********************************************************************/
/*   NOMBRE LOGICO:         sp_email_notificacion_reverso           */
/*   NOMBRE FISICO:         email_notificacion_reverso.sp           */
/*   BASE DE DATOS:         cob_cartera                             */
/*   PRODUCTO:              Cartera                                 */
/*   DISENADO POR:          G. Fernandez                            */
/*   FECHA DE ESCRITURA:    01-Oct-2021                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Envio de notificación al reversar transacciones de cartera     */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   01-Oct-2021        G. Fernandez.      Emision Inicial          */
/*   06-Jul-2023        P. Jarrin         Correccion para envio de  */
/*                                   todos los correos del catalogo */
/********************************************************************/

USE cob_cartera
GO

if exists(select 1 from sysobjects where name ='sp_email_notificacion_reverso')
   drop proc sp_email_notificacion_reverso

go

CREATE PROC sp_email_notificacion_reverso
(
@s_ofi                   smallint     = null, 
@i_banco                 cuenta,
@i_secuencial            int          = NULL,
@i_observacion           varchar(255) = ''
)
as 

declare
@w_sp_name               varchar (32),
@w_error                 INT = 0,
@w_email_body            varchar(1000),
@w_tran                  varchar(10),
@w_tran_desc             descripcion,
@w_subject               nvarchar(255),
@w_of_nombre             varchar(160),
@w_nombreCliente         varchar(254),
@w_monto                 money,
@w_ente                  int,
@w_id_plantilla          smallint,
@w_desc_monto            varchar(64),
@w_destinatarios         varchar(255),
@w_monto_etiqueta        varchar(64),
@w_fecha_hora            varchar (24),
@w_codigo                int


select  @w_sp_name       = 'sp_email_notificacion_reverso'

--Datos de la Transaccion
SELECT @w_tran      = tr_tran,
       @w_tran_desc = tt_descripcion
FROM  ca_transaccion, ca_tipo_trn
where  tr_banco       = @i_banco
AND    tr_secuencial  = @i_secuencial 
and    tr_tran        = tt_codigo

if @@rowcount = 0 
begin
   select @w_error = 725104 --No puede identificar la transacción
   goto ERROR
end

select @w_subject = 'REVERSO - ' + @w_tran_desc

--Obtencion del monto
select @w_monto = isnull(sum(dtr_monto), 0)
from  ca_transaccion, ca_det_trn 
where tr_operacion   = dtr_operacion
AND   tr_secuencial  = @i_secuencial
and   tr_tran        = @w_tran
and   dtr_operacion  = tr_operacion 
and   dtr_secuencial = tr_secuencial
and   dtr_afectacion = 'C'
and   tr_banco       = @i_banco


--Datos de oficina
select @w_of_nombre = of_nombre
from cobis..cl_oficina
where of_oficina = @s_ofi

if @@rowcount = 0 
begin
   select @w_error = 725105 --No puede identificar la oficina
   goto ERROR
end

--Datos del cliente
select @w_nombreCliente = en_nomlar,
       @w_ente          = en_ente
from   ca_operacion, cobis..cl_ente
where  op_cliente  = en_ente
and    op_banco    = @i_banco 

if @@rowcount = 0 
begin
   select @w_error = 720602 --El cliente no existe en la base de clientes
   goto ERROR
end

--Validacion para mostrar el monto de la operacion
if @w_tran in ('PAG', 'DES')
begin
    select @w_monto_etiqueta = 'Monto: ',
           @w_desc_monto     = convert(VARCHAR(24),@w_monto)
end
else
begin
    select @w_monto_etiqueta = ' ',
           @w_desc_monto     = ' '
end

--Fecha y hora
select @w_fecha_hora = convert(VARCHAR(24),getdate())

--Contenido del mensaje
select @w_email_body     = '<?xml version="1.0" encoding="UTF-8"?><data><transaccion>'+ @w_tran_desc+'</transaccion><numPrestamo>'+@i_banco+'</numPrestamo><cliente>'+@w_nombreCliente+'</cliente><codigoTransaccion>'+rtrim(ltrim(@w_tran)) + '-'+ @w_tran_desc+'</codigoTransaccion><montoEtiqueta>'+@w_monto_etiqueta+'</montoEtiqueta><monto>'+@w_desc_monto+'</monto><fechaHora>'+@w_fecha_hora+'</fechaHora><oficina>'+@w_of_nombre+'</oficina><secuencial>'+convert(VARCHAR(24),@i_secuencial)+'</secuencial><comentario>'+@i_observacion+'</comentario></data>'

--Correos destinatarios
if not exists (select 1 from cobis..cl_catalogo A, cobis..cl_tabla B
                where B.codigo = A.tabla
                  and B.tabla  = 'ca_emails_notificacion_reverso' 
                  and A.estado = 'V')
begin
   select @w_error = 725106 --No existen correos en el catálogo
   goto ERROR
end
    
-- Registro de la pantilla
select @w_id_plantilla =  te_id
from cobis..ns_template
where te_nombre = 'Notificaciones_Reversos.xslt'

if @@rowcount = 0 
begin
   select @w_error = 725107 --No existe la plantilla para el envió de notificación
   goto ERROR
end

--Tabla Temporal
IF OBJECT_ID('tempdb..#tmp_email_notifica') IS NOT NULL
 drop table #tmp_email_notifica
   
create table #tmp_email_notifica
(
  codigo        int identity,
  destinatario  varchar(255)
)

insert into #tmp_email_notifica
select ltrim(rtrim(valor)) from cobis..cl_catalogo A, cobis..cl_tabla B
         where B.codigo = A.tabla
           and B.tabla  = 'ca_emails_notificacion_reverso' 
           and A.estado = 'V'
		   
select @w_codigo = 0

while 1 = 1
begin
    select top 1 @w_codigo        = codigo, 
                 @w_destinatarios = destinatario
      from #tmp_email_notifica
     where codigo > @w_codigo
     order by codigo asc     

    if @@rowcount = 0
        break

    exec @w_error = cobis..sp_despacho_ins
    @i_cliente            = @w_ente,
    @i_template           = @w_id_plantilla,
    @i_servicio           = 1, 
    @i_estado             = 'P', 
    @i_tipo               = 'MAIL', 
    @i_tipo_mensaje       = 'I', 
    @i_prioridad          = 1, 
    @i_to                 = @w_destinatarios,
    @i_subject            = @w_subject,
    @i_body               = @w_email_body,
    @i_content_manager    = 'HTML',
    @i_retry              = 'S',
    @i_max_tries          = 2
	
end

if @w_error  <> 0 
    goto ERROR 

return 0

ERROR:           
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error 


GO
