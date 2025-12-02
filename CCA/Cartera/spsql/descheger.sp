/************************************************************************/
/*      Archivo:                descheger.sp                            */
/*      Stored procedure:       sp_desembolso_cheger                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Aplicacion y reversa desembolsos con cheque de gerencia         */
/*      para control en servicios bancarios                             */
/************************************************************************/  
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_desembolso_cheger')
   drop proc sp_desembolso_cheger
go

create proc sp_desembolso_cheger
    @s_ssn              int          = null,
    @s_sesn             int          = null,
    @s_rol              tinyint      = null,
    @s_org              char(1)      = null,
    @s_date             datetime     = null,
    @s_user             login        = null,
    @s_term             varchar (30) = null,
    @s_ofi              int          = null,
    @s_lsrv             varchar (30) = null,
    @s_srv              varchar (30) = null,
    @i_operacion        char(1)      = null,
    @i_operacionca      int          = null,
    @i_instrumento      int          = null,
    @i_subtipo          int          = null

as
declare
    @w_sp_name            varchar(30),
    @w_return             int,
    @w_error              int,
    @w_rowcount           int,
    @w_banco              cuenta,
    @w_referencia         int,
    @w_pa_area_cartera    smallint,
    @w_tipo_benef         catalogo,
    @w_moneda_des         tinyint,
    @w_moneda_nac         tinyint,
    @w_cliente            int,
    @w_ente_benefic       int,
    @w_producto           char(1),
    @w_instrumento        char(1),
    @w_sub_tipo           char(1),
    @w_serie_desde        int,
    @w_serie_hasta        int,
    @w_funcionario        login,
    @w_motivo_reverso     char(21),
    @w_causa_rev          char(1),
    @w_area_origen        smallint,
    @i_referencia         cuenta,
    @w_oficina_origen     smallint,
    @w_ofi_destino        smallint,
    @w_fecha_solicitud    datetime,
    @w_valor              money,
    @w_beneficiario       descripcion,
    @w_campo1             varchar(254),
    @w_campo2             varchar(254),
    @w_campo3             varchar(254),
    @w_campo4             varchar(254),
    @w_campo40            char(1),
    @w_grupo1             varchar(254),    
    @w_pa_cdc             varchar(30),
    @w_nom_cdc            descripcion
  
/* INICIALIZACION VARIABLES */
select 
    @w_sp_name        = 'sp_desembolso_cheger',
    @w_producto       = '4',
    @w_funcionario    = ' ',
    @w_motivo_reverso = 'REVERSO DE DESEMBOLSO',
    @w_causa_rev      = 'T'

/* LECTURA DEL PARAMETRO CAUSA EMISION CHEQUE DE GERENCIA */
select @w_pa_cdc = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CTE'
and    pa_nemonico    = 'CDC'

select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

/* LECTURA DE LA DESCRIPCION DEL PARAMETRO CAUSA EMISION CHEQUE DE GERENCIA */
select @w_nom_cdc = c.valor
from cobis..cl_tabla t,
     cobis..cl_catalogo c
where t.tabla = 'cc_concepto_emision'
and   c.tabla = t.codigo
and   c.codigo = @w_pa_cdc

select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

/* LECTURA DEL PARAMETRO MONEDA LOCAL */
select @w_moneda_nac   = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 701069 --No existe moneda
   goto ERROR
end

/* LECTURA DEL PARAMETRO AREA ORIGEN DE CARTERA */
select @w_area_origen = pa_smallint
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'ARC'
select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 708176 --No existe area contable para cartera
   goto ERROR
end

/*OBTENER DATOS DE LA OPERACION */
select @w_banco   = op_banco,
       @w_cliente = op_cliente
from   ca_operacion
where  op_operacion	 = @i_operacionca

/*OBTENER DATOS DEL DESEMBOLSO */
select @w_oficina_origen   = dm_oficina,
       @w_ofi_destino      = dm_oficina,
       @w_fecha_solicitud  = dm_fecha,
       @w_valor            = dm_monto_mn,
       @w_beneficiario     = dm_beneficiario,
       @w_ente_benefic     = dm_ente_benef,
       @w_moneda_des       = dm_moneda,
       @w_funcionario      = dm_usuario,
       @w_serie_desde      = dm_cheque,
       @w_serie_hasta      = dm_cheque
from   ca_desembolso
where  dm_operacion	= @i_operacionca

/*OBTENER DATOS DEL TITULAR DEL CREDITO */
select @w_campo3        = en_tipo_ced + '-' + cast(en_ced_ruc as varchar),
       @w_campo4        = en_nomlar
from   cobis..cl_ente
where  en_ente          = @w_cliente

/*OBTENER DATOS DEL BENEFICIARIO DEL DESEMBOLSO*/
select @w_campo1        = en_tipo_ced + '-' + cast(en_ced_ruc as varchar),
       @w_campo2        = en_nomlar,
       @w_tipo_benef    = c_tipo_compania
from   cobis..cl_ente
where  en_ente          = @w_ente_benefic

/*DETERMINAR IDIOMA PARA IMPRESION DEL CHEQUE */
if @w_moneda_des = @w_moneda_nac
    select @w_campo40 = 'E'
else
    select @w_campo40 = 'I'


/*OPCIONES DE PROCESO */
if @i_operacion = 'A'
begin
    print 'descheger.sp Ejecuta cob_interface..sp_imprimir_lotes'
    exec @w_return           = cob_interface..sp_imprimir_lotes
         @t_trn              = 29334,
         @s_ssn              = @s_ssn,
         @s_date             = @s_date,
         @s_user             = @s_user,
         @s_term             = @s_term,
         @s_ofi              = @s_ofi,
         @s_lsrv             = @s_lsrv,
         @s_srv              = @s_srv,
         @i_estado           = 'D',
         @i_oficina_origen   = @w_oficina_origen,
         @i_ofi_destino      = @w_ofi_destino,
         @i_area_origen      = @w_area_origen,
         @i_fecha_solicitud  = @w_fecha_solicitud,
         @i_producto         = 4,
         @i_instrumento      = @i_instrumento,
         @i_subtipo          = @i_subtipo,
         @i_valor            = @w_valor,
         @i_beneficiario     = @w_beneficiario,
         @i_referencia       = @i_operacionca,
         @i_tipo_benef       = @w_tipo_benef,
         @i_campo1           = @w_campo1,
         @i_campo2           = @w_campo2,
         @i_campo3           = @w_campo3,
         @i_campo4           = @w_campo4,
         @i_campo5           = @w_banco,
         @i_campo6           = @w_pa_cdc,
         @i_campo7           = @w_nom_cdc,
         @i_campo40          = @w_campo40,
         @o_idlote           = 0 --@o_idlote out --Código de lote	(Lo devuelve el sp y se debe grabar en ca_desembolso)

end
if @i_operacion = 'R'
begin
    select @w_grupo1 = @w_producto + '@' + cast(@i_instrumento as varchar) + '@' + cast(@i_subtipo as varchar) + '@' + cast(@w_serie_desde as varchar) + '@' + cast(@w_serie_hasta as varchar) + '@' + @w_funcionario + '@' + @w_motivo_reverso + '@' + @w_causa_rev

    exec @w_return = cob_interface..sp_modificar_suspencion
         @t_trn              = 29315,
         @s_date             = @s_date,
         @s_user             = @s_user,
         @s_sesn             = @s_sesn,
         @s_ssn              = @s_ssn,
         @s_rol              = @s_rol,
         @s_term             = @s_term,
         @s_srv              = @s_srv,
         @s_lsrv             = @s_lsrv,
         @s_ofi              = @s_ofi,
         @s_org              = @s_org,
         @i_localizacion     = 'L',
         @i_final            = 'S',
         @i_grupo1           = @w_grupo1
end

/*
PRINT 'MRoa: DESCHEGER: @w_oficina_origen  ' + CAST(@w_oficina_origen AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_ofi_destino     ' + CAST(@w_ofi_destino AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_area_origen     ' + CAST(@w_area_origen AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_fecha_solicitud ' + CAST(@w_fecha_solicitud AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_valor           ' + CAST(@w_valor AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_beneficiario    ' + CAST(@w_beneficiario AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_referencia      ' + CAST(@w_referencia AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_tipo_benef      ' + CAST(@w_tipo_benef AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_campo1          ' + CAST(@w_campo1 AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_campo2          ' + CAST(@w_campo2 AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_campo3          ' + CAST(@w_campo3 AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_campo4          ' + CAST(@w_campo4 AS VARCHAR)
PRINT 'MRoa: DESCHEGER: @w_campo40         ' + CAST(@w_campo40 AS VARCHAR)

*/



return 0

ERROR:
   exec cobis..sp_cerror 
        @t_debug = 'N',
        @t_file  = '',  
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error
go