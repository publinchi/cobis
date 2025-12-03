/******************************************************************/
/*  Archivo:                distribucion_linea_int.sp             */
/*  Stored procedure:       sp_distribucion_linea_int             */
/*  Base de Datos:          cob_interface                         */
/*  Producto:               Crédito                               */
/*  Disenado por:           Jose Mieles                           */
/*  Fecha de Documentacion: 15/09/2021                            */
/******************************************************************/
/*                          IMPORTANTE                            */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  COBISCORP                                                     */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier autorizacion o agregado hecho por alguno de sus     */
/*  usuario sin el debido consentimiento por escrito de la        */
/*  Presidencia Ejecutiva de COBISCORP o su representante.        */
/******************************************************************/
/*                           PROPOSITO                            */
/*  Verificar los datos de la distribución de línea de crédito    */
/******************************************************************/
/*                         MODIFICACIONES                         */
/*     FECHA             AUTOR            RAZON                   */
/*  15/09/2021       jmieles        Emision Inicial               */
/*  22/09/2021       pmora          Ajustes para servicio REST    */
/* ****************************************************************/
use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_distribucion_linea_int')
   drop procedure sp_distribucion_linea_int
go

create proc sp_distribucion_linea_int
(
       @s_ssn                     int              = null,
       @s_user                    login            = null,
       @s_sesn                    int              = null,
       @s_term                    descripcion      = null,         
       @s_date                    datetime         = null,
       @s_srv                     varchar(30)      = null,
       @s_lsrv                    varchar(30)      = null,
       @s_rol                     smallint         = null,
       @s_ofi                     smallint         = null,
       @s_org_err                 char(1)          = null,
       @s_error                   int              = null,
       @s_sev                     tinyint          = null,
       @s_msg                     descripcion      = null,
       @s_org                     char(1)          = null,
       @t_rty                     char(1)          = null,
       @t_trn                     int              = null,
       @t_debug                   char(1)          = 'N',
       @t_file                    varchar(14)      = null,
       @t_from                    varchar(30)      = null,
       @t_show_version            bit              = 0,          
       @s_culture                 varchar(10)      = 'NEUTRAL',
       @i_tramite                 int              = null,
       @i_operacion               char(1)          = null,
       @i_linea                   int              = null,
       @i_toperacion              catalogo         = null,
       @i_producto                catalogo         = null,
       @i_moneda                  tinyint          = null,
       @i_monto                   decimal(35,10)   = null, 
       @i_condicion_especial      varchar(255)     = null
)
as
declare
       @w_error                   int,
       @w_sp_name1                varchar(100),
       @w_sum_operacion           money,
       @w_msg                     varchar(255)

select @w_sp_name1 = 'cob_credito..sp_lin_ope_moneda',
       @w_error    = 0

if @i_tramite = 0 or @i_tramite is null
 begin 
    select
    @w_error = 2110179
    goto ERROR
 end

if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
 begin
    select
    @w_error = 2110182
    goto ERROR
 end

if not exists(select 1 
                from cob_credito..cr_tramite 
               where tr_tramite = @i_tramite 
                 and tr_estado = 'N' )
 begin
    select
    @w_error = 2110183
    goto ERROR
 end

if not exists(select 1 
                from cob_credito..cr_tramite 
               where tr_tramite = @i_tramite 
                 and tr_estado  = 'N' 
                 and tr_tipo    = 'L')
 begin
    select
    @w_error = 2110192
    goto ERROR
 end

-- Se obtiene la linea
select @i_linea   = li_numero
  from cob_credito..cr_linea
 where li_tramite = @i_tramite

if not exists(select 1 
                from cob_credito..cr_productos_linea 
               where pl_producto = @i_toperacion)
 begin
    select
    @w_error = 2110195
    goto ERROR
 end
    
if (@i_producto <> 'CCA')
 begin
    select
    @w_error = 2110193
    goto ERROR
 end 

if not exists(select 1 from cob_credito..cr_datos_linea where dl_moneda = @i_moneda)
 begin
    select
    @w_error = 2110155
    goto ERROR
 end
    
if not exists(select 1 
                from cob_credito..cr_datos_linea 
               where dl_moneda = @i_moneda 
                 and dl_toperacion = (select tr_toperacion 
                                        from cob_credito..cr_tramite 
                                       where tr_tramite = @i_tramite))
 begin
    select
    @w_error = 2110196
    goto ERROR
 end
                
if (@i_operacion <> 'I' and @i_operacion <> 'D' and @i_operacion <> 'U')
 begin
    select
    @w_error = 2110173
    goto ERROR
 end

-- Insert
if @i_operacion = 'I'
 begin   
   exec @w_error                   = @w_sp_name1
        @s_ssn                     = @s_ssn,
        @s_user                    = @s_user,
        @s_sesn                    = @s_sesn,
        @s_term                    = @s_term,
        @s_date                    = @s_date,
        @s_srv                     = @s_srv,
        @s_lsrv                    = @s_lsrv,
        @s_rol                     = @s_rol,
        @s_ofi                     = @s_ofi,
        @t_trn                     = 21023,
        @i_linea                   = @i_linea,
        @i_toperacion              = @i_toperacion,
        @i_producto                = @i_producto,
        @i_moneda                  = @i_moneda,
        @i_monto                   = @i_monto,
        @i_condicion_especial      = @i_condicion_especial,
        @i_operacion               ='I'
            
   if @w_error != 0
    begin
      goto ERROR
    end
 end

-- Update
if @i_operacion = 'U'
 begin

   if exists(select 1 from cob_credito..cr_linea where li_estado = 'V' and li_numero = @i_linea)
    begin
        select
        @w_error = 2110194
        goto ERROR
    end
 
   exec @w_error                   = @w_sp_name1
        @s_ssn                     = @s_ssn,
        @s_user                    = @s_user,
        @s_sesn                    = @s_sesn,
        @s_term                    = @s_term,
        @s_date                    = @s_date,
        @s_srv                     = @s_srv,
        @s_lsrv                    = @s_lsrv,
        @s_rol                     = @s_rol,
        @s_ofi                     = @s_ofi,
        @t_trn                     = 21123,
        @i_linea                   = @i_linea,
        @i_toperacion              = @i_toperacion,
        @i_producto                = @i_producto,
        @i_moneda                  = @i_moneda,
        @i_monto                   = @i_monto,
        @i_condicion_especial      = @i_condicion_especial,
        @i_operacion               ='U'
                    
   if @w_error != 0
    begin
      goto ERROR
    end
 end

-- Delete
if @i_operacion = 'D'
 begin   
   exec @w_error                   = @w_sp_name1
        @s_ssn                     = @s_ssn,
        @s_user                    = @s_user,
        @s_sesn                    = @s_sesn,
        @s_term                    = @s_term,
        @s_date                    = @s_date,
        @s_srv                     = @s_srv,
        @s_lsrv                    = @s_lsrv,
        @s_rol                     = @s_rol,
        @s_ofi                     = @s_ofi,
        @t_trn                     = 21223,
        @i_linea                   = @i_linea,
        @i_toperacion              = @i_toperacion,
        @i_producto                = @i_producto,
        @i_moneda                  = @i_moneda,
        @i_operacion               ='D'
            
   if @w_error != 0
    begin
      goto ERROR
    end
 end
 
return 0

ERROR:
--Devolver mensaje de Error
exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name1,
       @i_num   = @w_error
return @w_error

go
