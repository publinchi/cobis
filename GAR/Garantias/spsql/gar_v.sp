/*************************************************************************/
/*   Archivo:              gar_v.sp                                      */
/*   Stored procedure:     sp_gar_v                                      */
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
/*   penalmente a los autores de cualquier infraccion.                   */
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
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_gar_v') IS NOT NULL
    DROP PROCEDURE dbo.sp_gar_v
go
create proc dbo.sp_gar_v (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_trn                smallint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo               catalogo  = null,
   @i_custodia           int = null
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


-- Seleccionar datos de la custodia para sp_conta		
   select @w_oficina_contabiliza = cu_oficina_contabiliza,
	  @w_moneda = cu_moneda,
	  @w_valor_actual = cu_valor_actual,
          @w_tipo   = cu_tipo,
          @w_codigo_externo = cu_codigo_externo
    from  cob_custodia..cu_custodia
    where cu_tipo     = @i_tipo
    and   cu_sucursal = @i_sucursal
    and   cu_custodia = @i_custodia

   --Actualizar el estado de la garnatia
   update cob_custodia..cu_custodia
      set cu_estado        = 'V',
          cu_oficina_contabiliza = @w_oficina_contabiliza
    where cu_tipo     = @i_tipo
    and   cu_sucursal = @i_sucursal
    and   cu_custodia = @i_custodia


   update cob_credito..cr_gar_propuesta
      set gp_est_garantia = "V"
    where gp_garantia     = @w_codigo_externo

   select @w_contabilizar = tc_contabilizar
     from cob_custodia..cu_tipo_custodia
    where tc_tipo = @w_tipo

   if @w_contabilizar = 'S'
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
go