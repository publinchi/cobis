/************************************************************************/
/*   Archivo:              codigo_postal.sp                             */
/*   Stored procedure:     sp_codigo_postal                             */
/*   Base de datos:        cobis                                        */
/*   Producto:             CLIENTES                                     */
/*   Disenado por:         RIGG                                         */
/*   Fecha de escritura:   30-Abr-2019                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Dado un codigo postal recuperar los codigos de los catalogos        */
/*  de municipio, estados y colonias                                    */
/************************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA          AUTOR              RAZON                            */
/*   30/Abr/2019    RIGG            Versión Inicial Te Creemos          */
/*   22/Jun/2020    FSAP            Estandarizacion de Clientes         */
/*   13/ago/2021    COB             Se agrega pais para consultar       */
/*                                  otros paises                        */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_codigo_postal')
   drop proc sp_codigo_postal 
go

create proc sp_codigo_postal (
       @s_ssn          int          = null,
       @t_debug        char (1)     = 'N',
       @t_file         varchar (14) = null,
       @t_trn          int          = null,
       @t_show_version bit          = 0,
       @i_codpostal    varchar(10)  = null,
       @i_operacion    char(1)      = null,
       @i_estado       int          = null,
       @i_colonia      int          = null,
       @i_municipio    int          = null,
       @i_pais         int          = null
)
as
declare @w_sp_name         varchar(30),
        @w_sp_msg          varchar(132),
        @w_estado          int,
        @w_municipio       int,
        @w_colonia         int,
        @w_pais            int,
        @w_codigo_postal   int
    
--Captura nombre de Stored Procedure
select @w_sp_name = 'sp_codigo_postal'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
  begin
    select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
    select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
    print  @w_sp_msg
    return 0
  end

if @i_pais is not null
begin
   select @w_pais = @i_pais
end
else
begin
   select @w_pais = pa_smallint
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and pa_nemonico= 'CP'
end

if (@i_operacion = 'S')
  begin
    if @t_trn <> 172095
      begin 
        /* C�digo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720070
        return 1
      end
    
    set rowcount 1
    select @w_estado    = cp_estado,
           @w_municipio = cp_municipio,
           @w_colonia   = cp_colonia
      from cl_codigo_postal
     where cp_codigo    = @i_codpostal
       and cp_pais      = @w_pais
    if(@@rowcount = 0)
      begin
        exec sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1720153 --NO EXISTE DATO SOLICITADO
        return 1
      end

    select 'Estado'    = @w_estado,   
           'Municipio' = @w_municipio,
           'Colonia'   = @w_colonia
  end

if (@i_operacion = 'Q')
  begin
    if (@t_trn <> 172096 and @i_operacion = 'Q')
      begin 
        /* C�digo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720070
        return 1
      end

    set rowcount 1
    select @w_codigo_postal    = cp_codigo
      from cl_codigo_postal
     where cp_colonia = @i_colonia
    
    if(@@rowcount = 0)
    begin
       exec sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 1720153 --NO EXISTE DATO SOLICITADO
       return 1
    end
    select 'CodigoPostal'    = @w_codigo_postal
  end
  
/* Consulta los Estados para un C�digo Postal */
if (@i_operacion = 'E')
  begin
    if @t_trn <> 172116
      begin 
         /* Tipo de transaccion no corresponde */ 
         exec cobis..sp_cerror 
              @t_debug = @t_debug, 
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1720070
         return 1
      end
    
    set rowcount 0
    select distinct
           cp_estado,
           pv_descripcion
      from cl_codigo_postal,
           cl_provincia
     where cp_codigo    = @i_codpostal
       and cp_pais      = @w_pais
       and cp_estado    = pv_provincia
    if (@@rowcount = 0)
      begin
        --NO EXISTEN ESTADOS PARA EL C�DIGO POSTAL
        exec sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1720367
        return 1
      end
  end

/* Consulta las Delegaciones o Municipios para un C�digo Postal */
if (@i_operacion = 'M')
  begin
    if @t_trn <> 172115
      begin 
         /* Tipo de transaccion no corresponde */ 
         exec cobis..sp_cerror 
              @t_debug = @t_debug, 
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1720070
         return 1
      end
    
    set rowcount 0
    select distinct
           cp_municipio,
           ci_descripcion
      from cl_codigo_postal,
           cl_ciudad
     where cp_codigo    = @i_codpostal
       and cp_pais      = @w_pais
       and cp_estado    = @i_estado
       and ci_provincia = @i_estado
       and cp_estado    = ci_provincia
       and cp_municipio = ci_ciudad
    if (@@rowcount = 0)
      begin
        --NO EXISTEN DELEGACIONES O MUNICIPIOS PARA EL C�DIGO POSTAL
        exec sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1720366
        return 1
      end
  end

/* Consulta las colonias para un c�digo postal */
if (@i_operacion = 'C')
  begin
    if @t_trn <> 172114
      begin 
         /* Tipo de transaccion no corresponde */ 
         exec cobis..sp_cerror 
              @t_debug = @t_debug, 
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1720070
         return 1
      end
    
    set rowcount 0
    select cp_colonia,
           pq_descripcion
      from cl_codigo_postal,
           cl_parroquia
     where cp_codigo    = @i_codpostal
       and cp_pais      = @w_pais
       and cp_municipio = @i_municipio
       and pq_ciudad    = @i_municipio
       and cp_colonia   = pq_parroquia
    if (@@rowcount = 0)
      begin
        --NO EXISTEN COLONIAS PARA EL C�DIGO POSTAL
        exec sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1720350
        return 1
      end
  end

return 0
  
go