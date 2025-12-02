/*************************************************************************/
/*   Archivo:              inspector.sp                                  */
/*   Stored procedure:     sp_inspector                                  */
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
/*    18-05-2020            Luis Castellanos        CDIG Ajustes Core Dig*/
/*************************************************************************/
USE cob_custodia
go

IF OBJECT_ID('dbo.sp_inspector') IS NOT NULL
    DROP PROCEDURE dbo.sp_inspector
go
create procedure sp_inspector (
    @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_inspector          tinyint  = null,
   @i_cta_inspector      ctacliente  = null,
   @i_nombre             descripcion  = null,
   @i_especialidad       catalogo  = null,
   @i_direccion          descripcion  = null,
   @i_telefono           varchar( 20)  = null,
   @i_principal          descripcion  = null,
   @i_cargo              descripcion  = null,
   @i_param1             descripcion  = null,
   @i_cliente_inspec     int = null,
   @i_tipo_cta           char(3) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_retorno            int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_inspector          tinyint,
   @w_cta_inspector      ctacliente,
   @w_nombre             descripcion,
   @w_especialidad       catalogo,
   @w_direccion          descripcion,
   @w_telefono           varchar( 20),
   @w_principal          descripcion,
   @w_cargo              descripcion,
   @w_des_especialidad   descripcion,
   @w_des_cuenta         descripcion,
   @w_error              int,
   @w_cliente_inspec     int,
   @w_tipo_cta           char(3)

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_inspector'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19080 and @i_operacion = 'I') or
   (@t_trn <> 19081 and @i_operacion = 'U') or
   (@t_trn <> 19082 and @i_operacion = 'D') or
   (@t_trn <> 19083 and @i_operacion = 'V') or
   (@t_trn <> 19084 and @i_operacion = 'S') or
   (@t_trn <> 19085 and @i_operacion = 'Q') or
   (@t_trn <> 19086 and @i_operacion = 'A') or
   (@t_trn <> 19087 and @i_operacion = 'B')

begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_inspector = is_inspector,
         @w_cta_inspector = is_cta_inspector,
         @w_nombre = is_nombre,
         @w_especialidad = is_especialidad,
         @w_direccion = is_direccion,
         @w_telefono = is_telefono,
         @w_principal = is_principal,
         @w_cargo = is_cargo,
         @w_cliente_inspec = is_cliente_inspec,
         @w_tipo_cta       = is_tipo_cta
    from cob_custodia..cu_inspector
    where 
         is_inspector = @i_inspector

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if 
         @i_inspector = NULL 
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @i_inspector = 0 begin
	   select @i_inspector = max(is_inspector) from cob_custodia..cu_inspector
	   if @i_inspector is null
	      select @i_inspector = 1
	   else
	      select @i_inspector = @i_inspector + 1
	end

    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror

        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end

    begin tran
         insert into cu_inspector(
              is_inspector,
              is_cta_inspector,
              is_nombre,
              is_especialidad,
              is_direccion,
              is_telefono,
              is_principal,
              is_cargo,
              is_cliente_inspec,
              is_tipo_cta)
         values (
              @i_inspector,
              @i_cta_inspector,
              @i_nombre,
              @i_especialidad,
              @i_direccion,
              @i_telefono,
              @i_principal,
              @i_cargo,
              @i_cliente_inspec,
              @i_tipo_cta)

         if @@error <> 0 
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_inspector
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_inspector',
         @i_inspector,
         @i_cta_inspector,
         @i_nombre,
         @i_especialidad,
         @i_direccion,
         @i_telefono,
         @i_principal,
         @i_cargo,
         @i_cliente_inspec,
         @i_tipo_cta)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,

             @i_num   = 1903003
             return 1 
         end
    commit tran 
    return 0
end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    begin tran
         update cob_custodia..cu_inspector
         set 
              is_cta_inspector = @i_cta_inspector,
              is_nombre = @i_nombre,
              is_especialidad = @i_especialidad,
              is_direccion = @i_direccion,
              is_telefono = @i_telefono,
              is_principal = @i_principal,
              is_cargo = @i_cargo,
              is_cliente_inspec = @i_cliente_inspec,
              is_tipo_cta = @i_tipo_cta
    where 
         is_inspector = @i_inspector

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_inspector
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_inspector',
         @w_inspector,
         @w_cta_inspector,
         @w_nombre,
         @w_especialidad,
         @w_direccion,
         @w_telefono,
         @w_principal,
         @w_cargo,
         @w_cliente_inspec,
         @w_tipo_cta)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_inspector
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_inspector',
         @i_inspector,
         @i_cta_inspector,
         @i_nombre,
         @i_especialidad,
         @i_direccion,
         @i_telefono,
         @i_principal,
         @i_cargo,
         @i_cliente_inspec,
         @i_tipo_cta)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end


/***** Integridad Referencial *****/
/*****                        *****/
   if exists (select * from cu_control_inspector
              where ci_inspector = @i_inspector)
   begin
      select @w_error = 1907013
      goto error
   end

   if exists (select * from cu_inspeccion
              where in_inspector = @i_inspector)
   begin
      select @w_error = 1907014
      goto error
   end

   if exists (select * from cu_por_inspeccionar
              where pi_inspector_asig = @i_inspector)
   begin
      select @w_error = 1907014
      goto error
   end



    begin tran
        delete cob_custodia..cu_inspector
		where is_inspector = @i_inspector

                                    
         if @@error <> 0
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end

            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_inspector
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_inspector',
         @w_inspector,
         @w_cta_inspector,
         @w_nombre,
         @w_especialidad,
         @w_direccion,
         @w_telefono,
         @w_principal,
         @w_cargo,
         @w_cliente_inspec,
         @w_tipo_cta)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin
         select @w_des_especialidad = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla
             and B.tabla = 'cu_esp_inspector'
             and A.codigo = @w_especialidad

      /*  if @w_cta_inspector <> null and @w_cliente_inspec <> null
        begin
           exec @w_retorno = sp_ente_custodia
              @i_operacion = 'C',
              @t_trn = 19142,
              @i_ente = @w_cliente_inspec,
              @i_cuenta = @w_cta_inspector,
              @o_tipo_cta = @w_tipo_cta out

           if @w_retorno <> 0
           begin
           /*  Error en consulta de registro */
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1909002
              return 1 
           end
        end */
         select
              @w_inspector,
              @w_cta_inspector,
              @w_nombre,
              @w_especialidad,
              @w_des_especialidad,
              @w_direccion,
              @w_telefono,
              @w_principal,
              @w_cargo,
              @w_cliente_inspec,
              @w_tipo_cta

         return 0
    end
    else
    /*begin
    Registro no existe 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005*/
    return 1 
end

 /* Todos los datos de la tabla */
 /*******************************/
if @i_operacion = 'A'
begin
      set rowcount 20
      if @i_inspector is null
         select @i_inspector = convert(tinyint,@i_param1)
      if @i_modo = 0 
      begin
         select 'CODIGO' = is_inspector, 'NOMBRE' = is_nombre ,'CUENTA' = is_cta_inspector
           from cu_inspector with(index(cu_inspector_Key))  

         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
         end
      end
      else 
      begin
         select is_inspector,is_nombre,is_cta_inspector 
         from cu_inspector with(index(cu_inspector_Key)) 
         where is_inspector > @i_inspector  
         order by is_inspector --CSA Migracion Sybase

         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004        
           return 1 
         end
      end
end

if @i_operacion = 'S'
begin
    set rowcount 20
    if @i_modo = 0 
    begin
        select  'CODIGO' = is_inspector, 
				'NOMBRE' = substring(is_nombre,1,30) ,
				'CUENTA' = is_cta_inspector, 
				'ESPECIALIDAD' = is_especialidad 
        from cu_inspector with(index(cu_inspector_Key))  
        where (is_nombre like @i_nombre or @i_nombre is null) 
		and (is_especialidad = @i_especialidad or @i_especialidad is null) 
        order by is_inspector
        if @@rowcount = 0
        begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1901003
            return 1 
        end
    end
    else 
    begin
        select  'CODIGO' = is_inspector, 
				'NOMBRE' = substring(is_nombre,1,30) ,
				'CUENTA' = is_cta_inspector, 
				'ESPECIALIDAD' = is_especialidad 
        from cu_inspector with(index(cu_inspector_Key)) 
        where is_inspector > @i_inspector  
        and (is_nombre like @i_nombre or @i_nombre is null)
        and (is_especialidad = @i_especialidad or @i_especialidad is null)
        order by is_inspector
        if @@rowcount = 0
			/*exec cobis..sp_cerror
			@t_debug = @t_debug,
			@t_file  = @t_file, 
			@t_from  = @w_sp_name,
			@i_num   = 1901004 */
			return 0 
		end
	end

/* Consulta opcion VALUE */
/*************************/

if @i_operacion = 'V'
begin
   select is_nombre,is_cta_inspector from cu_inspector 
    where is_inspector = @i_inspector
         if @@rowcount = 0 
         begin
         /* No existe el registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1901005
             return 1 
         end
end 
return 0
error:    /* Rutina que dispara sp_cerror dado el codigo de error */

             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1

GO


