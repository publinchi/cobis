/*************************************************************************/
/*   Archivo:              almacenera.sp                                 */
/*   Stored procedure:     sp_almancenera                                */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_almacenera') IS NOT NULL
    DROP PROC dbo.sp_almacenera
GO

create proc dbo.sp_almacenera 
(
   @s_ssn                int          = null,
   @s_date               datetime     = null,
   @s_user               login        = null,
   @s_term               descripcion  = null,
   @s_corr               char(1)      = null,
   @s_ssn_corr           int          = null,
   @s_ofi                smallint     = null,
   @t_rty                char(1)      = null,
   @t_trn                smallint     = null,
   @t_debug              char(1)      = 'N',
   @t_file               varchar(14)  = null,
   @t_from               varchar(30)  = null,
   @i_operacion          char(1)      = null,
   @i_modo               smallint     = null,
   @i_almacenera         smallint     = null,
   @i_nombre             descripcion  = null,
   @i_direccion          descripcion  = null,
   @i_telefono           varchar( 20) = null,
   @i_estado             char(  1)    = null,
   @i_param1     	     descripcion  = '0' --null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_almacenera         smallint,
   @w_nombre             descripcion,
   @w_direccion          descripcion,
   @w_telefono           varchar(20),
   @w_estado             char( 1),
   @w_des_estado         descripcion,
   @w_error		         int

select @w_today   = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_almacenera'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19010 and @i_operacion = 'I') or
   (@t_trn <> 19011 and @i_operacion = 'U') or
   (@t_trn <> 19012 and @i_operacion = 'D') or
   (@t_trn <> 19013 and @i_operacion = 'V') or
   (@t_trn <> 19014 and @i_operacion = 'S') or
   (@t_trn <> 19015 and @i_operacion = 'Q') or
   (@t_trn <> 19016 and @i_operacion = 'A')
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
         @w_almacenera = al_almacenera,
         @w_nombre     = al_nombre,
         @w_direccion  = al_direccion,
         @w_telefono   = al_telefono,
         @w_estado     = al_estado
    from cob_custodia..cu_almacenera
    where 
         al_almacenera = @i_almacenera

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
         @i_almacenera = NULL or 
         @i_estado = NULL 
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

         insert into cu_almacenera(
              al_almacenera,
              al_nombre,
              al_direccion,
              al_telefono,
              al_estado)
         values (
              @i_almacenera,
              @i_nombre,
              @i_direccion,
              @i_telefono,
              @i_estado)

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

         insert into ts_almacenera
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_almacenera',
         @i_almacenera,
         @i_nombre,
         @i_direccion,
         @i_telefono,
         @i_estado)

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
         update cob_custodia..cu_almacenera
         set 
              al_nombre    = @i_nombre,
              al_direccion = @i_direccion,
              al_telefono  = @i_telefono,
              al_estado    = @i_estado
    where 
         al_almacenera = @i_almacenera

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

         insert into ts_almacenera
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_almacenera',
         @w_almacenera,
         @w_nombre,
         @w_direccion,
         @w_telefono,
         @w_estado)

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

         insert into ts_almacenera
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_almacenera',
         @i_almacenera,
         @i_nombre,
         @i_direccion,

         @i_telefono,
         @i_estado)

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
   if exists (select * from cu_custodia
               where cu_almacenera   = @i_almacenera)
   begin
      select @w_error = 1907012
      goto error
   end

    begin tran
         delete cob_custodia..cu_almacenera
    where 
         al_almacenera = @i_almacenera

                                      
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


         insert into ts_almacenera
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_almacenera',
         @w_almacenera,
         @w_nombre,
         @w_direccion,
         @w_telefono,
         @w_estado)

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
         select @w_des_estado = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla
             and B.tabla = 'cu_est_almacenera'
             and A.codigo = @w_estado 
         select 
              isnull(convert(varchar(10),@w_almacenera),''),
              @w_nombre,
              @w_direccion,
              @w_telefono,
              @w_estado,
              @w_des_estado
    end
    else
    begin
    /*Registro no existe 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005 */
    return 1 
    end  
return 0
end

if @i_operacion = 'A'
begin
      set rowcount 20
      if @i_almacenera is null
         select @i_almacenera = convert(smallint,@i_param1)
      if @i_modo = 0 
      begin
         select "CODIGO" = al_almacenera, "NOMBRE" = al_nombre 
           from cu_almacenera with(index(cu_almacenera_Key))
         order by al_almacenera --CSA Migracion Sybase
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
         select al_almacenera,al_nombre
         from cu_almacenera with(index(cu_almacenera_Key))
         where al_almacenera > @i_almacenera 
         order by al_almacenera --CSA Migracion Sybase
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
         select "CODIGO" = al_almacenera, "NOMBRE" = substring(al_nombre,1,30) ,
                "DIRECCION" = substring(al_direccion,1,30), "TELEFONO" = al_telefono,
                "ESTADO" = al_estado
           from cu_almacenera with(index(cu_almacenera_Key)) 
         where (al_nombre like @i_nombre or @i_nombre is null)
         order by al_almacenera --CSA Migracion Sybase
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
         select "CODIGO" = al_almacenera, "NOMBRE" = substring(al_nombre,1,30) ,
                "DIRECCION" = substring(al_direccion,1,30), "TELEFONO" = al_telefono,
                "ESTADO" = al_estado
         from cu_almacenera with(index(cu_almacenera_Key))
         where al_almacenera > @i_almacenera 
           and (al_nombre like @i_nombre or @i_nombre is null)
         order by al_almacenera --CSA Migracion Sybase
         if @@rowcount = 0
          /*begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004 
           return 2 
          end*/
          return 0
      end
end


if @i_operacion = 'V'
begin
          select al_nombre
            from cu_almacenera
            where al_almacenera = @i_almacenera
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
return 0
error:    /* Rutina que dispara sp_cerror dado el codigo de error */

             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1
go