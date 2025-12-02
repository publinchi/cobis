/*************************************************************************/
/*   Archivo:              part_seguro.sp                                */
/*   Stored procedure:     sp_part_seguro                                */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_part_seguro') IS NOT NULL
    DROP PROCEDURE dbo.sp_part_seguro
go
create proc dbo.sp_part_seguro(
   @s_ssn                   int = null,
   @s_user                  login = null,
   @s_sesn                  int = null,
   @s_term                  varchar(30) = null,
   @s_date                  datetime = null,
   
   @s_srv                   varchar(30) = null,
   @s_lsrv                  varchar(30) = null,
   @s_rol                   smallint = NULL,
   @s_ofi                   smallint = NULL,
   @s_org_err               char(1) = NULL,
   @s_error                 int = NULL,
   @s_sev                   tinyint = NULL,
   @s_msg                   descripcion = NULL,
   @s_org                   char(1) = NULL,
   @t_debug                 char(1) = 'N',
   @t_file                  varchar(10) = null,
   @t_from                  varchar(32) = null,
   @t_trn                   smallint = null,

   @i_operacion             char(1) = null,   
   @i_sec                   int = 0,                
   @i_aseguradora			catalogo = null,
   @i_tipo_seguro			catalogo = null,
   @i_tipo_vehiculo			catalogo = null,
   @i_tipo_persona			catalogo = null,
   @i_tasa					float = null,
   @i_estado				catalogo = null ,
   @i_user_ingreso			login  		= null,
   @i_user_ult_act			login  		= null
)
as
declare 
   @w_sp_name  varchar(25),
   @w_today    datetime
   

select @w_today = @s_date
select @w_sp_name = 'sp_part_seguro'


/***************     Codigos de Transacciones     ***************/
if @t_trn <> 19768
begin
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_num   = 2101006      --Tipo de transaccion no corresponde
   return 1 
end

/***************     Insert     ***************/
if @i_operacion = 'I'
begin
   
      /**********     Verificar si registro ya existe     **********/
      if exists(select 1 from cob_custodia..cu_part_seguro
      where ps_aseguradora    = @i_aseguradora
		and ps_tipo_seguro    = @i_tipo_seguro
		and	ps_tipo_vehiculo  = @i_tipo_vehiculo
		and ps_tipo_persona   = @i_tipo_persona
		and ps_estado = 'V'
			)
      begin
         exec cobis..sp_cerror 
         @t_debug= @t_debug,
         @t_file = @t_file,
         @t_from = @w_sp_name,
         @i_msg  = 'Registro VIGENTE ya existe',
         @i_num  = 2101002   --Registro ya existe
         rollback tran
         return 1
      end   
	  
	  begin tran
      /**********     Insertar los datos de entrada     **********/
      insert into cob_custodia..cu_part_seguro
	  (
	  ps_aseguradora,ps_tipo_seguro,ps_tipo_vehiculo,ps_tasa,ps_tipo_persona, ps_estado, ps_user_ingreso,ps_fecha_ingreso,ps_user_ult_act,ps_fecha_ult_act
	  )
      values 
	  (
	  @i_aseguradora, @i_tipo_seguro, @i_tipo_vehiculo, @i_tasa,@i_tipo_persona, @i_estado, @i_user_ingreso,   getdate(),  null,  null 
	  )
	  
      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 2103001     --Error en insercion de registro
         return 1
      end
   commit tran
   return 0
end

/***************     Update     ***************/
if @i_operacion = 'U'
begin
   /**********     Verificar si registro ya existe     **********/
    if NOT ( @i_estado <> 'V' and  exists(select 1 from cob_custodia..cu_part_seguro
      where ps_aseguradora    = @i_aseguradora
		and ps_tipo_seguro    = @i_tipo_seguro
		and	ps_tipo_vehiculo  = @i_tipo_vehiculo
		and ps_tipo_persona   = @i_tipo_persona
		and ps_estado         = @i_estado
			) )
			
    begin
	  
			  if  not exists(select 1 from cob_custodia..cu_part_seguro
			  where ps_aseguradora    = @i_aseguradora
				and ps_tipo_seguro    = @i_tipo_seguro
				and	ps_tipo_vehiculo  = @i_tipo_vehiculo
				and ps_tipo_persona   = @i_tipo_persona)
			 begin
				exec cobis..sp_cerror 
				 @t_debug= @t_debug,
				 @t_file = @t_file,
				 @t_from = @w_sp_name,
				 @i_msg  = 'Registro NO existe',
				 @i_num  = 2101005     --Registro no existe      
				return 1
			 end	
		
		 begin tran     
			 update cob_custodia..cu_part_seguro
					set 
					ps_tasa       	  = @i_tasa,
					--ps_user_ingreso	  = @i_user_ingreso,	
					--ps_fecha_ingreso  = getdate(),
					ps_user_ult_act	  = @i_user_ult_act,
					ps_estado 		  = @i_estado,
					ps_fecha_ult_act  = getdate()
					
			 where ps_aseguradora     = @i_aseguradora
				and ps_tipo_seguro    = @i_tipo_seguro
				and	ps_tipo_vehiculo  = @i_tipo_vehiculo
				and	ps_tipo_persona   = @i_tipo_persona
				
				 if @@error != 0
				 begin
					exec cobis..sp_cerror
					@t_debug    = @t_debug,
					@t_file     = @t_file,
					@t_from     = @w_sp_name,
					@i_num      = 2005001,
					@i_msg      = "Error en actualizacion"       
					return 1
				 end
			
		 commit tran
 		 return 0
	end
    else
    begin   
        exec cobis..sp_cerror 
         @t_debug= @t_debug,
         @t_file = @t_file,
         @t_from = @w_sp_name,
         @i_msg  = 'Registro VIGENTE ya existe',
         @i_num  = 2101002   --Registro ya existe  2101005     --Registro no existe      
        return 1
   end
end


/* Busqueda */
if @i_operacion = 'S' 
begin
   set rowcount 20
   
   select
        "Secuencia" 		 = ps_secuencial,           
	"Cod. Aseguradora"		 = ps_aseguradora		,
	"Nombre Aseguradora" = (select  valor from cobis..cl_tabla a, cobis..cl_catalogo b
		where a.tabla = 'cu_des_aseguradora' and b.tabla = a.codigo and b.codigo = c.ps_aseguradora),
	"Cod. Tipo seguro"		 = ps_tipo_seguro      ,
	"Nombre tipo de seguro" = (select  valor from cobis..cl_tabla a, cobis..cl_catalogo b
		where a.tabla = 'ca_tipo_seguro' and b.tabla = a.codigo and b.codigo = c.ps_tipo_seguro),
	"Cod. Tipo vehiculo" =  ps_tipo_vehiculo    ,
	"Nombre tipo vehiculo" =(select  valor from cobis..cl_tabla a, cobis..cl_catalogo b
		where a.tabla = 'cr_tipo_vehiculo' and b.tabla = a.codigo and b.codigo = c.ps_tipo_vehiculo),
	"Cod. Tipo persona" =  ps_tipo_persona ,
	"Nombre tipo persona" =(select  valor from cobis..cl_tabla a, cobis..cl_catalogo b
		where a.tabla = 'bv_tcliente_ach' and b.tabla = a.codigo and b.codigo = c.ps_tipo_persona  ),
	"Tasa"				 = ps_tasa				,
	"Cod. Estado" 			 = ps_estado			,
	"Nombre estado"  =(select  valor from cobis..cl_tabla a, cobis..cl_catalogo b
		where a.tabla = 'cu_est_almacenera' and b.tabla = a.codigo and b.codigo = c.ps_estado),
	"Usuario ingreso" 	 = ps_user_ingreso	,
	"Fecha de ingreso" 	 = ps_fecha_ingreso	,
	"Ultimo usuario actualiza" = ps_user_ult_act	,
	"Ultima fecha actualiza"   = ps_fecha_ult_act	
   FROM  cob_custodia..cu_part_seguro c
   where ps_secuencial > @i_sec
   order by ps_secuencial

   set rowcount 0
end
	
return 0
go