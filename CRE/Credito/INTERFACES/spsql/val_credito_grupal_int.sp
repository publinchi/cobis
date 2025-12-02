/************************************************************************/
/*  Archivo:                val_credito_grupal_int.sp                   */
/*  Stored procedure:       sp_val_credito_grupal_int                   */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Crédito                                     */
/*  Disenado por:           Patricio Mora                               */
/*  Fecha de Documentacion: 02/Sep/2021                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Verificar los datos enviados mediante el servicio REST de creación  */
/*  o actualización de crédito grupal GFI.                              */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*     FECHA        AUTOR            RAZON                              */
/*  02/09/2021      pmora        Emision Inicial                        */
/*  10/09/2021      wlo          Ajuste ORI-S526469-GFI                 */
/*  24/03/2022      pmoreno      Validacion fecha proceso,ciudad        */
/*  31/08/2022      bduenas      Se corrige validacion del oficial      */
/************************************************************************/
use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_val_credito_grupal_int')
    drop proc sp_val_credito_grupal_int
go

create procedure sp_val_credito_grupal_int
(
       @s_ssn                    int            = null,
       @s_user                   varchar(30)    = null,
       @s_sesn                   int            = null,
       @s_term                   varchar(30)    = null,
       @s_date                   datetime       = null,
       @s_srv                    varchar(30)    = null,
       @s_lsrv                   varchar(30)    = null,
       @s_rol                    smallint       = null,
       @s_ofi                    smallint       = null,
       @s_org_err                char(1)        = null,
       @s_error                  int            = null,
       @s_sev                    tinyint        = null,
       @s_msg                    descripcion    = null,
       @s_org                    char(1)        = null,
       @t_rty                    char(1)        = null,
       @t_trn                    int            = null,
       @t_debug                  char(1)        = 'N',
       @t_file                   varchar(14)    = null,
       @t_from                   varchar(30)    = null,
       @i_canal                  tinyint        = 0,      -- Canal: 0=Frontend  1=Batch   2=Workflow
       @i_tipo                   varchar(1)     = 'O',
       @i_sector                 catalogo       = null,
       @i_fecha_ini              datetime       = null,
       @i_ciudad                 int,
       @i_ciudad_destino         int,
       @i_cliente                int,
       @i_codeudor               int,
       @i_comentario             varchar(255),
       @i_destino                catalogo,
       @i_formato_fecha          int,
       @i_grupal                 char(1),
       @i_moneda                 tinyint,
       @i_monto                  money,
       @i_monto_aprobado         money,
       @i_origen_fondos          catalogo, 
       @i_nombre                 descripcion,
       @i_num_renovacion         int,
       @i_numero_reest           int,
       @i_oficial                smallint,
       @i_oficina                smallint,
       @i_periodo_cap            int,
       @i_periodo_int            int,
       @i_plazo                  int,
       @i_toperacion             catalogo,
       @i_tplazo                 catalogo,
       @i_tramite                int
)
as
declare
       @w_error                  int,
       @w_sp_name                varchar(32),
       @w_sector                 catalogo,
       @w_destino                catalogo,
       @w_origen                 catalogo,
       @w_moneda                 tinyint,
       @w_gr_grupo               int,
       @w_fecha                  datetime,
       @w_requerido_sector       varchar(30)

select @w_sp_name = 'sp_val_credito_grupal_int',
       @w_error   = 0,
       @w_requerido_sector = null

select @w_fecha = fp_fecha from cobis..ba_fecha_proceso

select @w_requerido_sector = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'OCISG'
and    pa_tipo     = 'C'

-- Oficina
if not exists (select 1 
               from   cobis..cl_oficina 
               where  of_oficina = @i_oficina)
begin
   select @w_error = 2110151
   goto SALIR
end

-- Sector
if (@i_sector is not null and @w_requerido_sector = 'N')
begin
   select @w_sector = c.valor
     from cobis..cl_tabla t,
          cobis..cl_catalogo c
    where t.tabla  = 'cc_sector'
      and t.codigo = c.tabla
      and c.codigo = @i_sector
   if @@rowcount = 0
   begin 
      select @w_error = 2110126
      goto SALIR
   end
end

-- Destino geográfico
select @w_destino = c.valor
  from cobis..cl_tabla t,
       cobis..cl_catalogo c
 where t.tabla  = 'cl_ciudad'
   and t.codigo = c.tabla
   and c.codigo = @i_ciudad
if @@rowcount = 0
begin 
   select @w_error = 2110149
   goto SALIR
END

-- Ciudad
if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_ciudad')and codigo = @i_ciudad)
begin
   select
      @w_error = 2110150
        --@w_msg    = 'No existe Ciudad.'
        goto SALIR
end   

if not exists( select 1 from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_ciudad')and codigo = @i_ciudad_destino)
begin
   select
      @w_error = 2110150
        --@w_msg    = 'No existe Ciudad Destino.'
        goto SALIR
end   

-- Origen de fondos
select @w_origen = c.valor
  from cobis..cl_tabla t,
       cobis..cl_catalogo c
 where t.tabla  = 'cr_origen_fondo'
   and t.codigo = c.tabla
   and c.codigo = @i_origen_fondos
if @@rowcount = 0
begin 
   select @w_error = 2110143
   goto SALIR
end

-- Oficial
if not exists(select 1
              from cobis..cl_funcionario, cobis..cc_oficial, cobis..ad_usuario
              where fu_funcionario = oc_funcionario
              and oc_oficial = @i_oficial
              and us_oficina = @i_oficina
              and us_login   = fu_login)
begin
   select @w_error = 2110145
   goto SALIR
end    

-- Moneda
select @w_moneda = dt_moneda
from   cob_cartera..ca_default_toperacion
where  dt_toperacion = @i_toperacion
and    dt_moneda     = @i_moneda
if @@rowcount = 0
begin 
   select @w_error = 2110147
   goto SALIR
end

-- Grupo
select @w_gr_grupo = gr_grupo
from   cobis..cl_grupo
where  gr_grupo = @i_cliente
if @@rowcount = 0
begin 
   select @w_error = 2110130
   goto SALIR
end

-- Fecha
if @i_fecha_ini = null
begin
   select @i_fecha_ini = @w_fecha
end

if (@i_fecha_ini < @w_fecha)
begin
   select @w_error = 708142
    goto SALIR
end

-- Plazo
if not exists(select 1 
             from    cob_cartera..ca_tdividendo 
             where   td_tdividendo = @i_tplazo)
begin
   select @w_error = 2110146
   goto SALIR
end

-- Destino financiero
select @w_destino = c.valor
  from cobis..cl_tabla t,
       cobis..cl_catalogo c
 where t.tabla  = 'cr_objeto'
   and t.codigo = c.tabla
   and c.codigo = @i_destino
if @@rowcount = 0
begin 
   select @w_error = 2110141
   goto SALIR
end

SALIR:
return @w_error
GO
