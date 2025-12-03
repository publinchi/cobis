/****************************************************************/
/* ARCHIVO:              vigen_gar.sp                           */
/* Stored procedure:	 sp_vigen_gar	          	            */
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
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/


USE cob_custodia
go

IF OBJECT_ID('dbo.sp_vigen_gar') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_vigen_gar
END
GO

create proc sp_vigen_gar (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_trn                smallint  = null,
   @i_tramite_car	 int,
   @i_oficina_des        smallint  = null
)
as
declare
   @w_today                datetime,     
   @w_sucursal             smallint,
   @w_tipo                 varchar(64),
   @w_error		   int,
   @w_contabilizar         char(1),
   @w_moneda               tinyint,
   @w_codigo_externo       varchar(64),
   @w_oficina              tinyint,
   @w_oficina_contabiliza  smallint,
   @w_des_oficina          varchar(64),
   @w_valor_actual         money,
   @w_return		   int

select @w_today = getdate()

/*declare cursor_custo insensitive cursor for / HHO Mayo/2012    Migracion SYBASE 15 /
 select  gp_garantia
   from cob_credito..cr_gar_propuesta 
  where gp_tramite= @i_tramite_car
    and gp_est_garantia = "P"
  order by gp_garantia

open cursor_custo
fetch cursor_custo into   @w_codigo_externo
while @@sqlstatus != 2
begin*/

-- Seleccionar datos de la custodia para sp_conta		
   select @w_oficina_contabiliza = isnull(@i_oficina_des, cu_oficina_contabiliza),
	  @w_moneda = cu_moneda,
	  @w_valor_actual = cu_valor_actual,
          @w_tipo   = cu_tipo
     from cob_custodia..cu_custodia
    where cu_codigo_externo = @w_codigo_externo

   --Actualizar el estado de la garnatia
   update cob_custodia..cu_custodia
      set cu_estado        = 'V',
          cu_fecha_ingreso = @w_today,
          cu_oficina_contabiliza = @w_oficina_contabiliza
    where cu_codigo_externo = @w_codigo_externo

   /*update cob_credito..cr_gar_propuesta
      set gp_est_garantia = "V"
    where gp_garantia     = @w_codigo_externo*/

   select @w_contabilizar = tc_contabilizar
     from cob_custodia..cu_tipo_custodia
    where tc_tipo = @w_tipo

/*if @w_contabilizar = 'S'
   begin  --TRANSACCION CONTABLE 
    exec @w_return = cob_custodia..sp_conta
	@s_date = @s_date,	--fecha de proceso
	@t_trn = 19300,
	@i_operacion = 'I',
	@i_filial = 1,
	@i_oficina_orig = @w_oficina_contabiliza,
	@i_oficina_dest = @w_oficina_contabiliza,
	@i_tipo = @w_tipo,
	@i_moneda = @w_moneda,
	@i_valor = @w_valor_actual,
	@i_operac = 'I',
	@i_signo = 1,
	@i_codigo_externo = @w_codigo_externo
   end 

   fetch cursor_custo into   @w_codigo_externo
end
go*/
--EXEC sp_procxmode 'dbo.sp_vigen_gar', 'unchained'
go
