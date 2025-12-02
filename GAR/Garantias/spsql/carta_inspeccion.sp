/*************************************************************************/
/*   Archivo:              carta_inspeccion.sp                           */
/*   Stored procedure:     sp_carta_inspeccion                           */
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
GO

IF OBJECT_ID('dbo.sp_carta_inspeccion') IS NOT NULL
   drop  PROC dbo.sp_carta_inspeccion
go

create proc dbo.sp_carta_inspeccion (
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
   @i_tipo               descripcion  = null,
   @i_custodia           int  = null,
   @i_status             char(  1)  = null,
   @i_fecha              datetime  = null,
   @i_formato_fecha      int   = null,
   @i_inspector		 tinyint   = null,
   @i_oficial            smallint  = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo               descripcion,
   @w_custodia           int,
   @w_status             char(  1),
   @w_fecha_ant          datetime,
   @w_inspector          tinyint,
   @w_estado_ant         catalogo,
   @w_inspector_asig     tinyint,
   @w_fecha              datetime,
   @w_principal          descripcion,
   @w_cargo              descripcion,
   @w_nombre             descripcion, 
   @w_mes_actual         tinyint, 
   @w_nro_contratos      tinyint, 
   @w_intervalo          tinyint,
   @w_estado             catalogo,
   @w_cta_inspector      ctacliente,
   @w_especialidad       descripcion,
   @w_direccion          descripcion,
   @w_telefono           char(15),
   @w_nombre_oficial     char(25),
   @w_cont               tinyint /* Flag para saber si existen prendas */



select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_carta_inspeccion'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19295 and @i_operacion = 'Q') 
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
if @i_operacion <> 'Q'
begin
    select 
         @w_inspector = is_inspector,
         @w_cta_inspector = is_cta_inspector,
         @w_nombre = is_nombre,
         @w_especialidad = is_especialidad,
         @w_direccion = is_direccion,
         @w_telefono = is_telefono,
         @w_principal = is_principal,
         @w_cargo = is_cargo
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
if @i_operacion = 'Q'
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

/* Consulta opcion QUERY */
/*************************/

    select distinct
         @w_inspector = is_inspector,
         @w_cta_inspector = is_cta_inspector,
         @w_nombre = is_nombre,
         @w_especialidad = is_especialidad,
         @w_direccion = is_direccion,
         @w_telefono = is_telefono,
         @w_principal = is_principal,
         @w_cargo = is_cargo
    from cob_custodia..cu_inspector,cu_por_inspeccionar
    where 
         is_inspector = @i_inspector
     and is_inspector = pi_inspector_asig

    if @@rowcount > 0
            select @w_existe = 1
    else
           select @w_existe = 0
    
if @w_existe = 1
    begin
       select @w_nro_contratos = 0
       select @w_nro_contratos = count(*)
         from cu_por_inspeccionar,cu_cliente_garantia
        where pi_inspector_asig = @i_inspector
          and pi_inspeccionado  = 'N'  -- (N)o inspeccionadas
          and cg_codigo_externo = pi_codigo_externo
          and (cg_oficial       = @i_oficial or @i_oficial is null)

       select @w_nombre_oficial = fu_nombre
         from cobis..cl_funcionario,cobis..cc_oficial
        where oc_oficial     = @i_oficial
          and oc_funcionario = fu_funcionario
 
          update cu_por_inspeccionar
          set    pi_fenvio_carta   = convert(varchar(10),@s_date,101)
          from   cu_cliente_garantia
          where  pi_inspector_asig = @i_inspector
            and  pi_inspeccionado  = 'N'
            and  cg_codigo_externo = pi_codigo_externo
            and  (cg_oficial       = @i_oficial or @i_oficial is null)

       if exists(select * from cu_control_inspector
                  where ci_inspector    = @i_inspector
                    and ci_frecep_reporte = null)
       begin
          update cu_control_inspector
          set    ci_fenvio_carta = convert(varchar(10),@s_date,101)
          where  ci_inspector = @i_inspector
            and  ci_frecep_reporte is null   -- Todavia no recibe reportes
       end
       else
       begin
          if exists (select * from cu_control_inspector
                      where ci_inspector = @i_inspector
                        and ci_fenvio_carta = convert(char(10),@s_date,101))
          begin
          /*Registro no existe */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1901002
            return 1 
          end
          else    
          begin 
             insert into cu_control_inspector (ci_inspector, ci_fenvio_carta)
                    values (@i_inspector, convert(varchar(10),@s_date,101))
          end
       end
       select 
          @w_inspector,
          @w_nombre,
          @w_principal,
          @w_cargo,
          @w_nro_contratos,
          convert(char(10),@s_date,101),
          @w_nombre_oficial 
    end

    else
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
go

