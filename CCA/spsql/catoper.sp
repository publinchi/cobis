USE cobis
GO

IF OBJECT_ID ('dbo.sp_tipo_oper') IS NOT NULL
	DROP PROCEDURE dbo.sp_tipo_oper
GO



create proc sp_tipo_oper(
@i_modo   tinyint     = NULL,
@t_trn    INT         = NULL,
@s_srv                      varchar(30) = null,
@s_user                     login       = null,
@s_term                     descripcion = null, --MTA
@s_rol                      smallint    = NULL,
@s_ofi                      smallint    = NULL,
@s_ssn_branch               int         = null,
@s_ssn                      int         = null,
@s_lsrv                     varchar(30) = null,
@s_sesn                     int         = null,
@s_date                     datetime    = null,
@s_org                      char(1)     = NULL)


as

declare
@w_return         int,
@w_sp_name        varchar(32),
@w_tabla          smallint,
@w_codigo         varchar(30),
@w_criterio       tinyint

select @w_sp_name = 'sp_tipo_oper'


select b.codigo, b.valor
from cobis..cl_tabla a, cobis..cl_catalogo b
where a.codigo = b.tabla
  and a.tabla = 'ca_toperacion'
  AND b.estado = 'V'


RETURN 0
GO
