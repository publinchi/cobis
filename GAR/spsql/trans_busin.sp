/****************************************************************/
/* ARCHIVO:              trans_busin.sp                         */
/* Stored procedure:	 sp_trans_busin	          	            */
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 29/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_trans_busin') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_trans_busin
    IF OBJECT_ID('dbo.sp_trans_busin') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_trans_busin >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_trans_busin >>>'
END
go
create proc sp_trans_busin (
   @s_ssn                int         = null,
   @s_date               datetime    = null,
   @s_user               login       = null,
   @s_term               varchar(30) = null,
   @s_corr               char(1)     = null,
   @s_ssn_corr           int         = null,
   @s_ofi                smallint    = null,
   @t_rty                char(1)     = null,
   @t_trn                smallint    = null,
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,
   @i_modo               smallint    = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_tipo_cust          descripcion = null,
   @i_custodia           int         = null,
   @i_transaccion        smallint    = null,
   @i_fecha_tran         datetime    = null,
   @i_debcred            char(1)     = null,
   @i_valor              money       = 0,
   @i_descripcion        descripcion = null,
   @i_fecha1             datetime    = null,
   @i_fecha2             datetime    = null,
   @i_formato_fecha      int         = null,
   @i_usuario 		 login       = null,
   @i_perfil 		 varchar(10) = null,
   @i_cancelacion 	 char(1)     = null,
   @i_estado      	 char(1)     = null,
   @i_estado_aux  	 char(1)     = null,
   @i_param1      	 varchar(64) = null,
   @i_ind_depre      	 int         = null
)
as

declare
   @w_return             int, 
   @w_sp_name            varchar(32),     
   @w_error              int

select @w_sp_name = 'sp_trans_busin',
       @w_return  = 0

if @i_operacion = 'Z'
begin
   select isnull(cu_valor_inicial,0)
   from   cu_custodia
   where  cu_filial   = @i_filial
   and    cu_sucursal = @i_sucursal
   and    cu_tipo     = @i_tipo_cust
   and    cu_custodia = @i_custodia
end

if @i_operacion = 'S'
begin
   set rowcount 20
   
   select "NRO."        = tr_transaccion,
          "FECHA"       = convert(char(10),tr_fecha_tran,@i_formato_fecha),
          "USUARIO"     = convert(char(30),tr_usuario),
          "TIPO TRAN"   = tr_debcred, 
          "VALOR"       = tr_valor,
          "DESCRIPCION" = tr_descripcion
   from   cu_transaccion 
   where  tr_filial    = @i_filial
   and    tr_sucursal  = @i_sucursal
   and    tr_tipo_cust = @i_tipo_cust
   and    tr_custodia  = @i_custodia 
   and    (tr_usuario like @i_usuario or @i_usuario is null)
   and    (tr_fecha_tran >= @i_fecha1 or @i_fecha1 is null)
   and    (tr_fecha_tran <= @i_fecha2 or @i_fecha2 is null)
   and    (tr_transaccion > @i_transaccion or @i_transaccion is null)
   order by tr_fecha_tran, tr_transaccion 
end

return @w_return
go
--EXEC sp_procxmode 'dbo.sp_trans_busin', 'unchained'
go
IF OBJECT_ID('dbo.sp_trans_busin') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_trans_busin >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_trans_busin >>>'
go
