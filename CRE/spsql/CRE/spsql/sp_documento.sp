/********************************************************************/
/*   NOMBRE LOGICO:         sp_documento                            */
/*   NOMBRE FISICO:         sp_documento.sp                         */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          M. Davila                               */
/*   FECHA DE ESCRITURA:    15-Ago-1995                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Este stored procedure permite realizar las siguientes          */
/*   operaciones: Insert y Search en la tabla cr_documento,         */
/*   Impresion Original, Impresion Duplicado                        */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   15-Ago-1995        I. Ordonez.       Emision Inicial           */
/*   30-May-1997        M. Davila.        Correcciones              */
/*   16-Abr-2019        J. Escobar.       Versión TEC               */
/*   08-Jun-2023        P. Jarrin.        Impresion - S840140       */
/*   20-Jun-2023        P. Jarrin.        Ajuste Reporte CRE-S840140*/
/*   29-Sep-2023        P. Jarrin.        Ajuste B911626-R216372    */
/********************************************************************/

use cob_credito
go
if exists (select * from sysobjects where name = 'sp_documento')
    drop proc sp_documento
go
create proc sp_documento (
   @s_ssn                int      = null,
   @s_user               login    = null,
   @s_sesn               int    = null,
   @s_term               descripcion = null,
   @s_date               datetime = null,
   @s_srv                varchar(30) = null,
   @s_lsrv               varchar(30) = null,
   @s_rol                smallint = null,
   @s_ofi                smallint  = null,
   @s_org_err            char(1) = null,
   @s_error              int = null,
   @s_sev                tinyint = null,
   @s_msg                descripcion = null,
   @s_org                char(1) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_tramite            int = null,
   @i_modo               smallint = null,
   @i_documento          integer  = null
)
as
declare
   @w_today              datetime,     /* fecha del dia */
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_tramite            int,
   @w_documento          smallint,
   @w_numero             integer,
   @w_fecha_impresion    datetime,
   @w_usuario            login,
   @w_toperacion         VARCHAR(20),
   @w_credito            varchar(10)

select @w_today = @s_date
select @w_sp_name = 'sp_documento',
       @w_credito = ''
/* Debug */
/*********/
if @t_debug = 'S'
begin
    exec cobis..sp_begin_debug @t_file = @t_file
        select '/** Stored Procedure **/ ' = @w_sp_name,
        s_ssn             = @s_ssn,
        s_user            = @s_user,
        s_sesn            = @s_sesn,
        s_term            = @s_term,
        s_date            = @s_date,
        s_srv             = @s_srv,
        s_lsrv            = @s_lsrv,
        s_rol             = @s_rol,
        s_ofi             = @s_ofi,
        s_org_err         = @s_org_err,
        s_error           = @s_error,
        s_sev             = @s_sev,
        s_msg             = @s_msg,
        s_org             = @s_org,
        t_trn             = @t_trn,
        t_file            = @t_file,
        t_from            = @t_from,
        i_operacion       = @i_operacion,
        i_modo            = @i_modo,
        i_tramite         = @i_tramite,
        i_documento       = @i_documento
    exec cobis..sp_end_debug
end
/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 21034 and @i_operacion = 'I') or
   (@t_trn <> 21434 and @i_operacion = 'S') or
   (@t_trn <> 21334 and @i_operacion = 'Q')

begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1
end

if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
begin
    select @w_credito = 'GRUPAL_COB'
end
else
begin
    select @w_credito = 'INDIVI_COB'
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S'
begin
    select
         @w_tramite = do_tramite,
         @w_documento = do_documento,
         @w_numero = do_numero,
         @w_fecha_impresion = do_fecha_impresion,
         @w_usuario = do_usuario
    from cob_credito..cr_documento
    where
         do_tramite = @i_tramite and
         do_documento = @i_documento
    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end
/* Insert */
/**********/
if @i_operacion = 'I'
begin
   if @w_existe = 0
   begin
     begin tran
         insert into cr_documento(
              do_tramite,
              do_documento,
              do_numero,
              do_fecha_impresion,
              do_usuario)
         values (
              @i_tramite,
              @i_documento,
              1,
              @w_today,
              @s_user)
         if @@error <> 0
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103001
             return 1
         end
         /* Transaccion de Servicio */
         /***************************/
         insert into ts_documento
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cr_imp_documento',@s_lsrv,@s_srv,
         @i_tramite,
         @i_documento,
         1,
         @w_today,
         @s_user)
         if @@error <> 0
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1
         end
         commit tran
   end
   else
   if @w_existe = 1
   begin
     select @w_numero = @w_numero + 1
     begin tran
         update cr_documento
     set
          do_numero = @w_numero,
          do_usuario = @s_user,
          do_fecha_impresion = @w_today
     where
          do_tramite = @i_tramite and
          do_documento = @i_documento
         if @@error <> 0
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2105001
             return 1
         end
         /* Transaccion de Servicio */
         /***************************/
         insert into ts_documento
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cr_imp_documento',@s_lsrv,@s_srv,
         @w_tramite,
         @w_documento,
         @w_numero,
         @w_today,
         @s_user)
         if @@error <> 0
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1
         end
         /* Transaccion de Servicio */
         /***************************/
         insert into ts_documento
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cr_imp_documento',@s_lsrv,@s_srv,
         @i_tramite,
         @i_documento,
         @w_numero - 1,
         @w_today,
         @s_user)
         if @@error <> 0
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1
         end
     select @w_numero
         commit tran
   end
end
/* Search */
/**********/
if @i_operacion = 'S'
begin
    select @w_toperacion = tr_toperacion
    from   cob_credito..cr_tramite
    where  tr_tramite    = @i_tramite
    
    if (OBJECT_ID('tempdb.dbo.#tmp_doc','U')) is not null
    begin  
        drop table #tmp_doc
    end    
    create table #tmp_doc (
        id_mnemonico varchar(64)
    )

    insert into #tmp_doc 
    select id_mnemonico 
     from cob_credito..cr_imp_documento 
    where id_producto in ('CCA') 
      and id_mnemonico not in ('TAMORTINV', 'TAMORTCR')

    SELECT  "Documento" = do_documento,
        "Mnemonico" = id_mnemonico,
        "Descripcion" = id_descripcion,
        "Numero" = do_numero,
        "Impresion" = id_dato,
        'Plantilla' = id_template
    FROM
        cr_documento,
        cr_imp_documento
    WHERE id_documento  = do_documento
    and   do_tramite    = @i_tramite
    and   id_toperacion = @w_credito
    and   id_mnemonico not in (select id_mnemonico from #tmp_doc)
end
/* Query */
/**********/
if @i_operacion = 'Q'
begin
    select
        count(*)
    from cob_credito..cr_documento
    where
         do_tramite = @i_tramite

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

return 0
go
