use cob_cartera
go

IF OBJECT_ID ('dbo.sp_envio_correo_garliquida') IS NOT NULL
	DROP PROCEDURE dbo.sp_envio_correo_garliquida
GO

create proc sp_envio_correo_garliquida (
   @s_ssn            int           = null,
   @s_ofi            smallint,
   @s_user           login,
   @s_date           datetime,
   @s_srv            varchar(30)   = null,
   @s_term           descripcion   = null,
   @s_rol            smallint      = null,
   @s_lsrv           varchar(30)   = null,
   @s_sesn           int           = null,
   @s_org            char(1)       = null,
   @s_org_err        int           = null,
   @s_error          int           = null,
   @s_sev            tinyint       = null,
   @s_msg            descripcion   = null,
   @t_rty            char(1)       = null,
   @t_trn            int           = null,
   @t_debug          char(1)       = 'N',
   @t_file           varchar(14)   = null,
   @t_from           varchar(30)   = null,
   @i_id_inst_proc   int,    --codigo de instancia del proceso
   @i_id_inst_act    int,
   @i_id_empresa     int,
   @i_reenvio        char(1)       = 'N',
   @o_id_resultado   smallint out
)
as
declare
@w_sp_name           varchar(30),
@w_estado		     char(1),
@w_tramite		     int,
@w_fecha_proceso     datetime,
@w_fecha_vencimiento datetime,
@w_error             int,
@w_fecha_bdd         datetime,
@w_fecha_proceso_hh  datetime,
@w_hora              varchar(8),
@w_gar_pendiente     char(1)

select @w_sp_name = 'sp_envio_correo_garliquida'
select @w_estado = 'P' --Pendiente

select @w_tramite = convert(int, io_campo_3)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

if @i_reenvio = 'S'
begin

   exec @w_error = sp_genera_xml_gar_liquida
   @i_tramite = @w_tramite,
   @i_opcion = 'Q',
   @o_gar_pendiente = @w_gar_pendiente out
   
   if @w_error <> 0 goto ERROR
   
   if @w_gar_pendiente is null
   begin
      select @w_error = 70133 --GARANTÍA LÍQUIDA NO TIENE PAGO O DEVOLUCIÓN PENDIENTE
      goto ERROR
   end

   --FECHA DE VENCIMIENTO DEL ÚLTIMO CORREO ENVIADO
   select top 1 @w_fecha_vencimiento = gl_fecha_vencimiento
   from cob_cartera..ca_garantia_liquida
   where gl_tramite = @w_tramite

   if @w_fecha_vencimiento is null
   begin
      select @w_error = 724605 --ERROR AL CONSULTAR DATOS DEL GRUPO
      goto ERROR
   end

   select @w_fecha_proceso = fc_fecha_cierre from cobis..ba_fecha_cierre where  fc_producto = 7
   select @w_fecha_bdd =  getdate()   
  

   if datediff(dd, @w_fecha_bdd , @w_fecha_proceso) = 0  
      select @w_fecha_proceso_hh =  getdate()
   else begin
      select @w_hora = DATEPART(HOUR, getdate())
      select @w_hora = CONCAT(@w_hora, ':', convert(varchar(2),DATEPART(MINUTE, getdate())))
      select @w_hora = CONCAT(@w_hora, ':', convert(varchar(2),DATEPART(SECOND, getdate())))      
      select @w_fecha_proceso_hh =  convert(varchar,@w_fecha_proceso,101)+' ' + @w_hora
   end   

   if  datediff(hh, @w_fecha_vencimiento , @w_fecha_proceso_hh ) < 1
   begin
      select @w_error = 70131 --CORREO ANTERIOR AÚN SE ENCUENTRA VIGENTE
      goto ERROR
   end
end


if not exists (select 1 from ca_ns_garantia_liquida where ngl_tramite = @w_tramite and ngl_estado = @w_estado)
begin
	insert into ca_ns_garantia_liquida
	select @w_tramite, @w_estado
end
else if @i_reenvio = 'S'
begin
   select @w_error = 70132 --Existe un correo pendiente de procesar
   goto ERROR
end

select @o_id_resultado = 1

return 0

ERROR:

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error

go


