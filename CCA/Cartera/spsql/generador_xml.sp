/************************************************************************/
/*   Archivo:              generador_xml.sp								*/
/*   Stored procedure:     sp_generador_xml      						*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Pedro Rafael Montenegro Rosales              */
/*   Fecha de escritura:   Julio 2017                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza la Aplicacion de los Pagos a los Prestamos procesados en ar*/
/*   chivo de retiro para banco SANTANDER MX, con respuesta OK.         */
/*                              CAMBIOS                                 */
/*  FECHA           AUTOR         RAZON                                 */
/*20/04/2018       P. Ortiz      Cambio de base y devolucion de errores */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_generador_xml')
   drop proc sp_generador_xml
go

create proc sp_generador_xml
(
	@s_user         login       = null,
	@s_ofi          smallint    = null,
	@s_date         datetime    = null,
	@s_term			varchar(30) = null,

	@i_fecha		   datetime	 = null,
	@i_batch		   int,
	@i_param		   varchar(10),

    @o_valida_error char(1)      = 'S' out,
	@o_msg          varchar(255) = null out
)
as

declare
		@w_error			int,
        @w_valida_error     char(1),
		@w_mensaje          varchar(150),
		@w_sql				varchar(5000),
		@w_sql_bcp			varchar(5000),
		@w_fecha_proceso	datetime,
		@w_formato_fecha	int,
		@w_ruta_xml			varchar(255),
		@w_nombre_xml		varchar(30),
		@w_sp_name			varchar(30),
		@w_msg				varchar(255)

declare
		@w_fecha_respaldo  varchar(32)

SELECT
		@w_fecha_respaldo  = replace(
		convert(VARCHAR, getdate(),112) +'_' + 	substring(format(getdate(), 'yyyy-MM-ddTHH:mm:ss:ms'), 12,32)
		, ':', '')


select @w_sp_name = 'sp_generador_xml', @w_valida_error = 'S'

declare @resultadobcp table (linea varchar(max))

select	@w_formato_fecha = 111

select @w_ruta_xml = ba_path_destino
	from cobis..ba_batch
	where ba_batch = @i_batch

if (@@error != 0 or @@rowcount != 1 or isnull(@w_ruta_xml, '') = '')
begin
   select @w_error = 724636
	goto ERROR_PROCESO
end

select @w_nombre_xml = b.valor
	from cobis..cl_tabla a, cobis..cl_catalogo b
	where a.codigo = b.tabla
	and a.tabla = 'ca_param_notif'
	and b.codigo = @i_param + '_NXML'

if (@@error != 0 or @@rowcount != 1 or isnull(@w_nombre_xml, '') = '')
begin
   select @w_error = 724640
	goto ERROR_PROCESO
end

if (@i_fecha is null)
begin
	select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
end
else
begin
	select @w_fecha_proceso = @i_fecha
end

/* SACAR RESPALDO AL ARCHIVO Y PONERLO EN LA CARPETA HISTORICA */
SELECT @w_sql_bcp = 'copy ' + @w_ruta_xml + @w_nombre_xml + ' ' + @w_ruta_xml + 'history\' +
                    substring(@w_nombre_xml,1,charindex('.', @w_nombre_xml)-1) + '_' + @w_fecha_respaldo + '.xml'

PRINT ' SQL 1 ' + @w_sql_bcp

delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

/*  BORRAR EL ARCHIVO */
select	@w_sql_bcp = 'del ' + @w_ruta_xml + @w_nombre_xml
delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

PRINT ' SQL 2 ' + @w_sql_bcp

if (@i_param = 'PFPCO')
BEGIN

	if (not exists (select 1 from cob_cartera..ca_pago_en_corresponsal where pc_fecha_proceso = @w_fecha_proceso))
	BEGIN
		GOTO NO_DATOS
	END 
	select	@w_sql = 'SELECT pc_grupo_id as grupo_id, ' +
							'pc_fecha_proceso as fecha_proceso, ' +
							'isnull(pc_grupo_name, ' + char(39) + char(32) + char(39) + ') as grupo_name, ' +
							'pc_op_fecha_liq as fecha_liq, ' +
							'pc_op_moneda as moneda, ' +
							'of_nombre as oficina, ' +
							'pc_di_fecha_vig as fecha_vig, ' +
							'pc_di_dividendo as dividendo, ' +
							'pc_di_monto as monto, ' +
							'isnull(pc_institucion1, ' + char(39) + char(32) + char(39) + ') as institucion1, ' +
							'isnull(pc_dest_nombre1, ' + char(39) + char(32) + char(39) + ') as dest_nombre1, ' +
							'isnull(pc_dest_cargo1, ' + char(39) + char(32) + char(39) + ') as dest_cargo1, ' +
							'isnull(pc_dest_email1, ' + char(39) + char(32) + char(39) + ') as dest_email1, ' +
							'isnull(pc_dest_nombre2, ' + char(39) + char(32)+ char(39) + ') as dest_nombre2, ' +
							'isnull(pc_dest_cargo2, ' + char(39) + char(32) + char(39) + ') as dest_cargo2, ' +
							'isnull(pc_dest_email2, ' + char(39) + char(32) + char(39) + ') as dest_email2, ' +
							'isnull(pc_dest_nombre3, ' + char(39) + char(32) + char(39) + ') as dest_nombre3, ' +
							'isnull(pc_dest_cargo3, ' + char(39) + char(32) + char(39) + ') as dest_cargo3, ' +
							'isnull(pc_dest_email3 , ' + char(39) + char(32) + char(39) + ') as dest_email3 ' +
                            '(select isnull(grvd_referencia, ' + char(39) + char(32) + char(39) + ') as referencia, '+
                                    'isnull(grvd_institucion,' + char(39) + char(32) + char(39) + ') as institucion, '+
                                    'isnull(grvd_convenio,' + char(39) + char(32) + char(39) + ') as nro_convenio '+
                             'from cob_cartera..ca_gen_ref_cuota_vigente_det '+
                             'where grvd_fecha_proceso = grv_fecha_proceso '+
                             'and grvd_grupo_id = grv_grupo_id '+
							 'order by grvd_institucion asc '+
                             'FOR XML PATH(' + char(39) + 'Referencia'+ char (39) + '), TYPE )'+								
					 'FROM cob_cartera..ca_pago_en_corresponsal, cobis..cl_oficina ' +
					 'where pc_op_oficina = of_oficina ' +
					 'and convert(varchar, pc_fecha_proceso, ' +
						convert(varchar, @w_formato_fecha) + ') = ' + char(39) + convert(varchar, @w_fecha_proceso, @w_formato_fecha) + char(39) +
					 ' FOR XML PATH(' + char(39) + 'Grupo' + char (39) + '), ROOT(' + char(39) + 'PagoCorresponsal' + char (39) + '), ELEMENTS'
			--' FOR XML AUTO, ELEMENTS'
end
else if (@i_param = 'PFIAV')
begin
	if (not exists (select 1 from cob_cartera..ca_incumplimiento_aval where ia_fecha_con = @w_fecha_proceso))
	BEGIN
		GOTO NO_DATOS
	END 

	select	@w_sql = 'SELECT ia_fecha_con as fecha, ' +
							'ia_tramite as tramite, ' +
							'ia_banco as operacion, ' +
							'ia_dividendo as dividendo, ' +
							'ia_fecha_ven as fecha_ven, ' +
							'ia_simbolo as simbolo, ' +
							'ia_monto_deuda as monto_deuda, ' +
							'ia_nom_oficial as nombre_oficial, ' +
							'ia_car_oficial as cargo_oficial, ' +
							'ia_nom_oficina as nombre_oficina, ' +
							'ia_dir_oficina as direccion_oficina, ' +
							'ia_ciu_oficina as ciudad_oficina, ' +
							'ia_garante as garante, ' +
							'ia_nom_garante as nombre_garante, ' +
							'ia_mail_garante as mail_garante ' +
					 'FROM cob_cartera..ca_incumplimiento_aval ' +
					 'where convert(varchar, ia_fecha_con, ' +
						convert(varchar, @w_formato_fecha) + ') = ' + char(39) + convert(varchar, @w_fecha_proceso, @w_formato_fecha) + char(39) +
					 ' FOR XML PATH(' + char(39) + 'Incumplimiento' + char (39) + '), ROOT(' + char(39) + 'IncumplimientoAvalista' + char (39) + '), ELEMENTS'
end
else if (@i_param = 'PFPCV')
begin

	if (not exists (select 1 from cob_cartera..ca_gen_ref_cuota_vigente where grv_fecha_proceso = @w_fecha_proceso))
	BEGIN
		GOTO NO_DATOS
	END 

	select
      @w_sql = 'SELECT grv_grupo_id as grupo_id, ' +
      'isnull(grv_grupo_name, ' + char(39) + char(32) + char(39) + ') as nombre_grupo, ' +
      'grv_fecha_proceso as fecha_proceso, ' +
      'grv_op_fecha_liq as fecha_liq, ' +
      'isnull(grv_di_fecha_vig,'+char(39) + char(32) + char(39) + ') as fecha_venc,'+
      'grv_op_moneda as moneda, ' +
      'of_nombre as oficina, ' +
	  'grv_di_dividendo as num_pago, ' +
      'isnull(grv_di_fecha_vig,'+char(39) + char(32) + char(39) + ') as fecha_vig, ' +      
      'grv_di_monto as monto, ' +
      'isnull(grv_dest_nombre1, ' + char(39) + char(32) + char(39) + ') as dest_nombre1, ' +
      'isnull(grv_dest_cargo1, ' + char(39) + char(32) + char(39) + ') as dest_cargo1, ' +
      'isnull(grv_dest_email1, ' + char(39) + char(32) + char(39) + ') as dest_email1, ' +
      'isnull(grv_dest_nombre2, ' + char(39) + char(32)+ char(39) + ') as dest_nombre2, ' +
      'isnull(grv_dest_cargo2, ' + char(39) + char(32) + char(39) + ') as dest_cargo2, ' +
      'isnull(grv_dest_email2, ' + char(39) + char(32) + char(39) + ') as dest_email2, ' +
      'isnull(grv_dest_nombre3, ' + char(39) + char(32) + char(39) + ') as dest_nombre3, ' +
      'isnull(grv_dest_cargo3, ' + char(39) + char(32) + char(39) + ') as dest_cargo3, ' +
      'isnull(grv_dest_email3 , ' + char(39) + char(32) + char(39) + ') as dest_email3, ' +
      'isnull(grv_dest_nombre4, ' + char(39) + char(32) + char(39) + ') as dest_nombre4, ' +
      'isnull(grv_dest_cargo4, ' + char(39) + char(32) + char(39) + ') as dest_cargo4, ' +
      'isnull(grv_dest_email4 , ' + char(39) + char(32) + char(39) + ') as dest_email4, ' +
      '(select isnull(grvd_referencia, ' + char(39) + char(32) + char(39) + ') as referencia, '+
                 'isnull(grvd_institucion,' + char(39) + char(32) + char(39) + ') as institucion, '+
                 'isnull(grvd_convenio,' + char(39) + char(32) + char(39) + ') as nro_convenio '+
        'from cob_cartera..ca_gen_ref_cuota_vigente_det '+
        'where grvd_fecha_proceso = grv_fecha_proceso '+
        'and grvd_grupo_id = grv_grupo_id '+
        'order by grvd_institucion asc '+
        'FOR XML PATH(' + char(39) + 'Referencia'+ char (39) + '), TYPE )'+	
	'FROM cob_cartera..ca_gen_ref_cuota_vigente, cobis..cl_oficina ' +
	'where grv_op_oficina = of_oficina ' +
	'and convert(varchar, grv_fecha_proceso, ' +
	convert(varchar, @w_formato_fecha) + ') = ' + char(39) + convert(varchar, @w_fecha_proceso, @w_formato_fecha) + char(39) +
	' FOR XML PATH(' + char(39) + 'Grupo' + char (39) + '), ROOT(' + char(39) + 'PagoCorresponsal' + char (39) + '), ELEMENTS'

end
else
begin
	select @w_error = 724638
	goto ERROR_PROCESO
end

select	@w_sql_bcp = 'bcp "' + @w_sql + '" queryout "' + @w_ruta_xml + @w_nombre_xml + '" -w -r -t\t -T'

delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

select * from @resultadobcp

--SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR =
if @w_mensaje is null
    select top 1 @w_mensaje =  linea
         from @resultadobcp
         where upper(linea) LIKE upper('%Error %')

if @w_mensaje is not null
begin
	select @w_error = 724625
	goto ERROR_PROCESO
end

return 0

ERROR_PROCESO:
	select @w_msg = mensaje
		from cobis..cl_errores with (nolock)
		where numero = @w_error
		set transaction isolation level read uncommitted

   select @w_msg = isnull(@w_msg, @w_mensaje)

   select @o_msg = ltrim(rtrim(@w_msg)), @o_valida_error = @w_valida_error

   return @w_error

NO_DATOS:
		SELECT @w_sql_bcp = 'echo NO_DATA> ' + @w_ruta_xml + @w_nombre_xml

		delete from @resultadobcp
		insert into @resultadobcp
		EXEC xp_cmdshell @w_sql_bcp

		RETURN 0

go
