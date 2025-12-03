/********************************************************************/
/*   NOMBRE LOGICO:         sp_liquidacion_con                      */
/*   NOMBRE FISICO:         comliqq.sp                              */
/*   BASE DE DATOS:         cobis                                   */
/*   PRODUCTO:              Clientes                                */
/*   DISENADO POR:          S. Ortiz                                */
/*   FECHA DE ESCRITURA:    12-May-1995                             */
/********************************************************************/
/*                            IMPORTANTE                                */
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
/*              PROPOSITO                                               */
/*  Este stored procedure procesa:                                      */
/*  Query de datos de companias en liquidacion                          */
/********************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*   12-May-1995    S. Ortiz.     Emision Inicial                   */
/*   22-Ene-2021    I. Yupa.      CLI-S412373-PRD- Malas Referencias*/
/*   08-Jun-2023    P. Jarrin.    Ajuste - B846229                  */
/********************************************************************/

use cobis
go
if exists (select * from sysobjects where name = 'sp_liquidacion_con')
   drop proc sp_liquidacion_con
go
create proc sp_liquidacion_con (
		@s_culture			varchar(10)   = 'NEUTRAL',
		@s_ssn          	int           = NULL,
		@s_user         	login         = NULL,
		@s_term         	varchar(30)   = NULL,
		@s_date         	datetime      = NULL,
		@s_srv          	varchar(30)   = NULL,
		@s_lsrv         	varchar(30)   = NULL,
		@s_ofi          	smallint      = NULL,
		@s_rol          	smallint 	  = NULL,
		@s_org_err      	char(1) 	  = NULL,
		@s_error        	int 		  = NULL,
		@s_sev          	tinyint 	  = NULL,
		@s_msg          	descripcion   = NULL,
		@s_org          	char(1) 	  = NULL,
		@t_show_version 	bit           = 0,     -- mostrar la version del programa
		@t_debug        	char(1)       = 'N',
		@t_file         	varchar(10)   = null,
		@t_from         	varchar(32)   = null,
		@t_trn          	int 		  = null,
		@i_operacion    	char(1),
		@i_modo				tinyint   	  = null,
		@i_tipo         	char(1)   	  = 'A',
		@i_codigo			int 		  = null,
		@i_ced_ruc			numero 		  = null,
		@i_nombre			descripcion   = null
)
as
declare @w_sp_name          varchar(32),
		@w_ced_ruc          char(13),
		@w_nombre           varchar(64),
		@w_sp_msg			varchar(132)
		
select @w_sp_name = 'sp_liquidacion_con',
	   @w_sp_msg  = ''
	   

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end


---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		
/* Search */
If @i_operacion = 'S' 
begin
	if @t_trn != 172147
	begin
		exec sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num        = 1720417,
		   @s_culture 	 = @s_culture
		   /*  'No corresponde codigo de transaccion' */
		return 1
	end
	set rowcount 20
	/*  Busqueda por Cedula o RUC  */
	if @i_tipo = 'C'
	begin
	  	if @i_modo = 0
			select   "2934" =  cl_codigo,
					 "5082" =  substring(cl_ced_ruc, 1, 13),
					 "2950" =  substring(cl_nombre, 1, 40),
					 "3072" =  cl_tipo,
					 "5083" =  cl_problema,
					 "5084" =  cl_referencia,
					 "3145" =  cl_fecha,
					 "descripcion_problema" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = "cl_problema") AND codigo = c.cl_problema),
					 "tipo" = cl_tipo_ref,
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = cl_tipo_ref)
			from  	cl_com_liquidacion AS c
			where	cl_ced_ruc  like @i_ced_ruc			
			order by cl_codigo
		else
			select   "2934" =  cl_codigo,
					 "5082" =  substring(cl_ced_ruc, 1, 13),
					 "2950" =  substring(cl_nombre, 1, 64),
					 "3072" =  cl_tipo,
					 "5083" =  cl_problema,
					 "5084" =  cl_referencia,
					 "3145" =  cl_fecha,
					 "descripcion_problema" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = "cl_problema") AND codigo = c.cl_problema),
					 "tipo" = cl_tipo_ref,
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = cl_tipo_ref)
			from  	cl_com_liquidacion AS c
			where 	cl_ced_ruc like @i_ced_ruc
			and	cl_codigo > @i_codigo
			order by cl_codigo
	end
	/*  Busqueda por nombre */
	else
	begin
	  	if @i_modo = 0
	        select   "2934" =  cl_codigo,
					 "5082" =  substring(cl_ced_ruc, 1,13),
					 "2950" =  substring(cl_nombre, 1, 64),
					 "3072" =  cl_tipo,
					 "5083" =  cl_problema,
					 "5084" =  cl_referencia,
					 "3145" =  cl_fecha,
					 "descripcion_problema" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = "cl_problema") AND codigo = c.cl_problema),
					 "tipo" = cl_tipo_ref,
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = cl_tipo_ref)
	         	from  	cl_com_liquidacion AS c
			where	cl_nombre like @i_nombre
			order by cl_codigo
		else
        	select   "2934" =  cl_codigo,
					 "5082" =  substring(cl_ced_ruc, 1, 13),
					 "2950" =  substring(cl_nombre, 1, 64),
					 "3072" =  cl_tipo,
					 "5083" =  cl_problema,
					 "5084" =  cl_referencia,
					 "3145" =  cl_fecha,
					 "descripcion_problema" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = "cl_problema") AND codigo = c.cl_problema),
					 "tipo" = cl_tipo_ref,
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = cl_tipo_ref)
         	from  	cl_com_liquidacion AS c
			where	cl_nombre like  @i_nombre
			and	cl_codigo > @i_codigo
			order by cl_codigo
	end
	set rowcount 0
	return 0
end
/** QUERY **/
If @i_operacion = 'Q' 
begin
     if @t_trn != 172148
     begin
		exec sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num        = 1720417,
		   @s_culture    = @s_culture
		   /*  'No corresponde codigo de transaccion' */
		return 1
     end
     else
       begin
			select 	"2934" =  cl_codigo,
					"2950" =  cl_nombre,
					"3072" =  cl_tipo,
					"5083" =  cl_problema,
					"2937" =  valor,
					"5084" =  cl_referencia,
					"5082" =  cl_ced_ruc,
					"3145" =  convert(char(12), cl_fecha, 103)
				from  	cl_com_liquidacion,
						cl_catalogo c,
						cl_tabla t
				where	cl_codigo = @i_codigo
				and	t.tabla = "cl_problema"
				and	c.tabla = t.codigo
				and	c.codigo = cl_problema
				return 0
       end
end
go
