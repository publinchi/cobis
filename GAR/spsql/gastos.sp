/*************************************************************************/
/*   Archivo:              gastos.sp                                     */
/*   Stored procedure:     sp_gastos                                     */
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
/*    09/Abril/2021          G. Fernandez         Coreccion de variables */
/*                                                @i_tipo_cust a @i_tipo */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_gastos') IS NOT NULL
    DROP PROCEDURE dbo.sp_gastos
go
create proc sp_gastos (
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
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo_cust          descripcion  = null,
   @i_custodia           int  = null,
   @i_gasto_adm          smallint  = null,
   @i_fecha              datetime  = null,
   @i_monto              money  = null,
   @i_descripcion        varchar(64)  = null,
   @i_formato_fecha      int     = null,
   @i_registrado         char(1)     = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_gasto_adm          smallint,
   @w_fecha              datetime,
   @w_monto              money,
   @w_descripcion        varchar(64),
   @w_des_gasto          varchar(64),
   @w_error              int,
   @w_ultimo             int,
   @w_des_tipo           varchar(255),
   @w_codigo_externo     varchar(64),
   @w_registrado         char(1)

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_gastos'

/***********************************************************/
/* Codigos de Transacciones                                */


if (@t_trn <> 19640 and @i_operacion = 'I') or
   (@t_trn <> 19641 and @i_operacion = 'U') or
   (@t_trn <> 19642 and @i_operacion = 'D') or
   (@t_trn <> 19644 and @i_operacion = 'S') or
   (@t_trn <> 19645 and @i_operacion = 'Q') 
   
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
if @i_operacion <> 'S' --and @i_operacion <> 'A'
begin
    select 
         @w_filial = ga_filial,
         @w_sucursal = ga_sucursal,
         @w_tipo_cust = ga_tipo_cust,
         @w_custodia = ga_custodia,
         @w_gasto_adm = ga_gastos,
         @w_descripcion = ga_descripcion,
         @w_fecha = ga_fecha,
         @w_monto = ga_monto,
         @w_codigo_externo = ga_codigo_externo,
         @w_registrado     = ga_registrado
    from cob_custodia..cu_gastos
    where 
         ga_filial = @i_filial and
         ga_sucursal = @i_sucursal and
         ga_tipo_cust = @i_tipo_cust and
         ga_custodia = @i_custodia and
         ga_gastos = @i_gasto_adm

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
         @i_filial = NULL or 
         @i_sucursal = NULL or 
         @i_tipo_cust = NULL or 
         @i_custodia = NULL 

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
         select @w_ultimo = isnull(max(ga_gastos),0)+1
           from cob_custodia..cu_gastos
          where ga_filial    = @i_filial 
            and ga_sucursal  = @i_sucursal
            and ga_tipo_cust = @i_tipo_cust
            and ga_custodia  = @i_custodia

         -- CODIGO EXTERNO
         exec sp_externo 
         @i_filial = @i_filial,
         @i_sucursal = @i_sucursal,
         @i_tipo = @i_tipo_cust, --GFP Coreccion de variable @i_tipo_cust a @i_tipo
         @i_custodia  = @i_custodia,
         @o_compuesto = @w_codigo_externo OUT
         

         insert into cu_gastos(
              ga_filial,
              ga_sucursal,
              ga_tipo_cust,
              ga_custodia,
              ga_gastos,
              ga_descripcion,
              ga_monto,
              ga_fecha,
              ga_codigo_externo,
              ga_registrado)
         values (
              @i_filial,
              @i_sucursal,
              @i_tipo_cust,
              @i_custodia,
              @w_ultimo,
              @i_descripcion,
              @i_monto,
              @i_fecha,
              @w_codigo_externo,
              'N')

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

         select @w_ultimo
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
         update cob_custodia..cu_gastos
         set 
             ga_fecha = @i_fecha,
             ga_descripcion = @i_descripcion,
             ga_monto = @i_monto
         where 
             ga_filial = @i_filial and
             ga_sucursal = @i_sucursal and
             ga_tipo_cust = @i_tipo_cust and
             ga_custodia = @i_custodia and
             ga_gastos = @i_gasto_adm

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
    else
    begin tran
         delete cob_custodia..cu_gastos
         where 
             ga_filial = @i_filial and
             ga_sucursal = @i_sucursal and
             ga_tipo_cust = @i_tipo_cust and
             ga_custodia = @i_custodia and
             ga_gastos = @i_gasto_adm 
                                        
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
    commit tran
    return 0
end

/* Consulta opcion QUERY */
/*************************/


if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin 
         select @w_des_tipo = tc_descripcion
           from cu_tipo_custodia
          where tc_tipo = @w_tipo_cust

         select @w_des_gasto = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla and
               B.tabla = 'cu_gastos_adm' and
               A.codigo = @w_descripcion

         select 
              @w_filial,
              @w_sucursal,
              @w_tipo_cust,
              @w_custodia,
              @w_gasto_adm,
              convert(char(10),@w_fecha,@i_formato_fecha),
              @w_monto,
              @w_descripcion,
              @w_des_gasto,
              @w_des_tipo,
              @w_codigo_externo,
              @w_registrado
    end else
    begin
    /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005
        return 1 
    end
    return 0
end

if @i_operacion = 'S'
begin
     -- CODIGO EXTERNO
     exec sp_externo 
         @i_filial = @i_filial,
         @i_sucursal = @i_sucursal,
         @i_tipo = @i_tipo_cust, --GFP Coreccion de variable @i_tipo_cust a @i_tipo
         @i_custodia  = @i_custodia,
         @o_compuesto = @w_codigo_externo OUT
     
     set rowcount 20
     select "GASTO" = ga_gastos,
            "FECHA" = convert(char(10),ga_fecha,@i_formato_fecha),
            "DESCRIPCION" = B.valor,
            "VALOR" = ga_monto
            --,"EJECUTADO" = ga_registrado  --Comentado LCA Inst.Operat.
     from cob_custodia..cu_gastos,cobis..cl_tabla A,cobis..cl_catalogo B
     where ga_codigo_externo  = @w_codigo_externo
       and A.tabla            = 'cu_gastos_adm'
       and A.codigo           = B.tabla
       and ga_descripcion     = B.codigo
       and (ga_gastos > @i_gasto_adm or @i_gasto_adm is null)
       order by ga_gastos,ga_fecha
        
         if @@rowcount = 0
         begin
            if @i_gasto_adm is null  
            begin
               select @w_error  = 1901003
            end

            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1
         end 
         else
           select isnull(sum(ga_monto),0)
             from cu_gastos
            where ga_codigo_externo = @w_codigo_externo
           select isnull(sum(ga_monto),0)
             from cu_gastos
            where ga_codigo_externo = @w_codigo_externo
              and ga_registrado     = 'N' 
     return 0
end
GO
