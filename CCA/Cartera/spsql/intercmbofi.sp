/******************************************************************/
/*  Archivo:            intercmbofi.sp                            */
/*  Stored procedure:   sp_cambio_oficial_srv                     */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Jonathan Tomala                           */
/*  Fecha de escritura: 23-Jul-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Validaciones de existencia del grupo y oficial             */
/*   - Cambio del oficial en las operacines y tramites            */
/*   - Cambio del oficial en los grupos                           */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  23/Jul/19     Jonathan Tomala  Creacion sp_cambio_oficial_srv */
/*  02/Ags/19     Jonathan Tomala  Saltar validaciones de cliente */
/*  12/Ags/19     Jonathan Tomala  Mejora en las validaciones     */
/*  14/ENE/2020   Armando Miramon  Actualiza el oficial al grupo  */
/*                              y a los creditos vigentes si tiene*/
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_cambio_oficial_srv')
   drop proc sp_cambio_oficial_srv
go

create proc sp_cambio_oficial_srv
   @s_user                  login        = null,
   @s_term                  varchar(30)  = null,
   @s_srv                   varchar(30)  = null,
   @s_date                  datetime     = null,
   @s_sesn                  int          = null,
   @s_ssn                   int          = null,
   @s_ofi                   smallint     = null,
   @s_rol                   smallint     = null,
   @t_trn                   int          = 77522,
   @i_interfaz              char(1)      = null,
   @i_promotor              int          = null,
   @i_grupo                 int          = null,
   @o_resultado             int          = 0    out,
   @o_mensaje               varchar(132) = null out
as declare
@w_sp_name                varchar(30),
@w_error                  int,
@w_banco                  varchar(30),
@w_operacion              int,
@w_estado                 varchar(10),
@w_oficial                int,
@w_fecha_modificacion     datetime,
@w_dir_reunion            varchar(125),
@w_dia_reunion            catalogo,
@w_hora_reunion           datetime,
@w_gr_tipo                char(1),
@w_gr_cta_grupal          VARCHAR(30),
@w_gr_sucursal            int,
@w_gr_titular1            int,
@w_gr_titular2            int,
@w_gr_lugar_reunion       char(10),
@w_gr_tiene_ctagr         char(1),
@w_gr_tiene_ctain         char(1),
@w_gr_gar_liquida         char(1)

--------------------------------------------------------------------------------------
select @w_sp_name   = 'sp_cambio_oficial_srv'
select @o_resultado = 0, @o_mensaje = null  -- POR DEFECTO

--------------------------VALIDACIONES------------------------------------------------
-- verificar que exista el grupo --
if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo and gr_estado = 'V')
begin
    select @w_error = 151029 -- NO EXISTE GRUPO
    goto ERROR
end

/*******	AMG - INICIO Consulta de código de oficial por código de funcionario	******/
select @w_oficial = oc_oficial 
from cobis..cl_funcionario inner join cobis..cc_oficial
	on oc_funcionario = fu_funcionario
where fu_funcionario = @i_promotor

if @w_oficial is null
begin
	select @w_error = 151091
	goto ERROR
end
/*******	AMG - FIN Consulta de código de oficial por código de funcionario	******/

--Se obtiene la información del grupo
select
   @w_estado              = gr_estado,
   @w_fecha_modificacion  = getdate(),
   @w_dir_reunion         = gr_dir_reunion,
   @w_dia_reunion         = gr_dia_reunion,
   @w_hora_reunion        = gr_hora_reunion,
   @w_gr_tipo             = gr_tipo,
   @w_gr_cta_grupal       = gr_cta_grupal,
   @w_gr_sucursal         = gr_sucursal,
   @w_gr_titular1         = gr_titular1,
   @w_gr_titular2         = gr_titular2,
   @w_gr_lugar_reunion    = gr_lugar_reunion,
   @w_gr_tiene_ctagr      = gr_tiene_ctagr,
   @w_gr_tiene_ctain      = gr_tiene_ctain,
   @w_gr_gar_liquida      = isnull(gr_gar_liquida,'S')
from   cobis..cl_grupo
where  gr_grupo = @i_grupo

--Actualizo el Grupo--
exec @w_error = cob_pac..sp_grupo_busin
  @s_ssn                 = @s_ssn,
  @s_user                = @s_user,
  @s_date                = @s_date,
  @s_srv                 = @s_srv,
  @s_ofi                 = @s_ofi,
  @s_rol                 = @s_rol,
  @t_trn                 = 800,
  @i_operacion           = 'U',
  @i_grupo               = @i_grupo,
  @i_oficial             = @w_oficial,
  @i_estado              = @w_estado,
  @i_fecha_modificacion  = @w_fecha_modificacion,
  @i_dir_reunion         = @w_dir_reunion,
  @i_dia_reunion         = @w_dia_reunion,
  @i_hora_reunion        = @w_hora_reunion,
  @i_gr_tipo             = @w_gr_tipo,
  @i_gr_cta_grupal       = @w_gr_cta_grupal,
  @i_gr_sucursal         = @w_gr_sucursal,
  @i_gr_titular1         = @w_gr_titular1,
  @i_gr_titular2         = @w_gr_titular2,
  @i_gr_lugar_reunion    = @w_gr_lugar_reunion,
  @i_gr_tiene_ctagr      = @w_gr_tiene_ctagr,
  @i_gr_tiene_ctain      = @w_gr_tiene_ctain,
  @i_gr_gar_liquida      = @w_gr_gar_liquida,
  @i_desde_fe            = 'S'              --JTO -02/08/2019 PARA SALTAR LAS VALIDACIONES DE CLIENTES

if @w_error > 0
begin
  goto ERROR
end

--------------------------OBTENER INFORMACION ADICIONAL---------------------------------------

--Se consulta si tiene un crédito vigente                    
Select @w_operacion = min(op_operacion)
from cob_cartera..ca_operacion 
where op_estado not in (0, 99, 3, 6) and op_grupo = @i_grupo
    and op_ref_grupal IS NULL

while @w_operacion is not null
begin
    --Se obtiene el número de crédito
    select @w_banco = op_banco
    from cob_cartera..ca_operacion 
    where op_operacion = @w_operacion
    
    BEGIN TRAN
    
    --------------------------ACTUALIZA OPERACIONES---------------------------------------
    --Actualizo operacion--
    update cob_cartera..ca_operacion
        set    op_oficial = @w_oficial
    where op_grupo = @i_grupo
        AND (op_banco = @w_banco OR op_ref_grupal = @w_banco)
    
    -- Si no se puede modificar, error --
    if @@rowcount = 0
    begin
        select @w_error = 725071  --ERROR EN ACTUALIZACION DE CREDITO
        goto ERROR
    end
   
    --Actualizo historial operacion--
    update cob_cartera..ca_operacion_his
        set    oph_oficial = @w_oficial
    where oph_grupo = @i_grupo
        AND (oph_banco = @w_banco OR oph_ref_grupal = @w_banco)

    --if @@rowcount = 0
    --begin
    --    select @w_error = 725072  --ERROR EN ACTUALIZACION DEL HISTORIAL DE CREDITO
    --    goto ERROR
    --end
    
    --------------------------ACTUALIZA TRAMITE---------------------------------------                        
    --Actualizo trámite--
    update cob_credito..cr_tramite
        set    tr_oficial = @w_oficial
    from cob_credito..cr_tramite inner join cob_cartera..ca_operacion
        on tr_tramite = op_tramite
    where op_grupo = @i_grupo
        AND (op_banco = @w_banco OR op_ref_grupal = @w_banco)
    
    if @@rowcount = 0
    begin
       select @w_error = 725073  --ERROR EN ACTUALIZACION DEL TRAMITE
       goto ERROR
    end
   
    COMMIT TRAN
    
    --Se verifica si no tiene otro crédito vigente
    Select @w_operacion = min(op_operacion)
    from cob_cartera..ca_operacion 
    where op_estado not in (0, 99, 3, 6) 
        and op_grupo = @i_grupo and op_ref_grupal IS NULL
        and op_operacion > @w_operacion
end

return 0

ERROR:
    SELECT @o_resultado = numero, @o_mensaje = mensaje FROM cobis..cl_errores WHERE numero = @w_error
    
    --Se verifica si existen transacciones abiertas
    while @@TRANCOUNT > 0
    begin
        ROLLBACK TRAN
    end
    
    return @w_error
go
