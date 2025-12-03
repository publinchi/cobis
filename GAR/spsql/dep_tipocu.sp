/*************************************************************************/
/*   Archivo:              dep_tipocu.sp                                 */
/*   Stored procedure:     sp_dep_tipocust                               */
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
/*   penalmente a los autores de cualquier infraccion.                   */
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
IF OBJECT_ID('sp_dep_tipocust') IS NOT NULL
    DROP PROCEDURE sp_dep_tipocust
go
create proc sp_dep_tipocust (
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
   @i_tipo               descripcion  = null,
   @i_periodicidad       int  = null,
   @i_porcentaje         money = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_tipo               descripcion,
   @w_tipo_superior      descripcion,
   @w_descripcion        varchar(255),
   @w_periodicidad       int,
   @w_des_tiposup        descripcion,
   @w_des_periodicidad   descripcion,
   @w_contabilizar       char(1),
   @w_porcentaje         float,
   @w_valor              tinyint,
   @w_adecuada           char(1) 

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_dep_tipocust'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19752 and @i_operacion = 'I') or
   (@t_trn <> 19753 and @i_operacion = 'U') or
   (@t_trn <> 19754 and @i_operacion = 'D') or
   (@t_trn <> 19755 and @i_operacion = 'V') or
   (@t_trn <> 19756 and @i_operacion = 'S') or
   (@t_trn <> 19757 and @i_operacion = 'Q') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,

    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1901006 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A' and @i_operacion <> 'H'
begin
    select 
         @w_tipo          = dtc_tipo,
         @w_periodicidad  = dtc_anio,
         @w_porcentaje    = dtc_porcentaje
    from cob_custodia..cu_dtipo_custodia
    where dtc_tipo = @i_tipo
    and   dtc_anio  = @i_periodicidad

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_tipo = NULL 
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1901006
    end


end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1901002 
    end


    begin tran
         insert into cu_dtipo_custodia(
              dtc_tipo,
              dtc_anio,
              dtc_porcentaje
               )
         values (
              @i_tipo,
              @i_periodicidad,
              @i_porcentaje)

         if @@error <> 0 
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1903001 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_dtipo_custodia
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_dtipo_custodia',
         @i_tipo,
         @i_periodicidad,
         @i_porcentaje)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1903003
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
        return 1905002 
    end

    begin tran
         update cob_custodia..cu_dtipo_custodia
         set  dtc_porcentaje    = @i_porcentaje
    where 
         dtc_tipo          = @i_tipo
    and  dtc_anio  = @i_periodicidad

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1905001
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_dtipo_custodia
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_dtipo_custodia',
         @w_tipo,
         @w_periodicidad,
         @w_porcentaje)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1903003
         end

            

         /* Transaccion de Servicio */

         /***************************/

         insert into ts_dtipo_custodia
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_dtipo_custodia',
         @i_tipo,
         @i_periodicidad,
         @i_porcentaje)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1903003
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
        return 1907002
    end

  if exists(select 1 from cob_custodia..cu_dtipo_custodia where dtc_tipo = @i_tipo
             and  dtc_anio >  @i_periodicidad  )
         begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002,
        @i_msg   = "No se puede eliminar registro intermedio "
        return 1907002
    end


/***** Integridad Referencial *****/
/*****                        *****/

    
    begin tran
         delete cob_custodia..cu_dtipo_custodia
    where 
         dtc_tipo = @i_tipo
    and  dtc_anio = @i_periodicidad

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_dtipo_custodia
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_dtipo_custodia',
         @w_tipo,
         @w_periodicidad,
         @w_porcentaje)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1903003
         end
    commit tran
    return 0
end

/* Consulta opcion VALUE */
/*************************/

if @i_operacion = 'V'
begin
   select dtc_anio,dtc_porcentaje from cu_dtipo_custodia where dtc_tipo = @i_tipo -----and dtc_anio = @i_periodicidad
         if @@rowcount = 0 
         begin
         /* No existe el registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1901005
             return 1901005 
         end
end 

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin    
         select
              @w_tipo,
              @w_periodicidad,
              @w_porcentaje
         return 0
    end    
    else
      return 1 
end
go