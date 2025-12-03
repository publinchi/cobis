/*************************************************************************/
/*   Archivo:              cr_consparam.sp                               */
/*   Stored procedure:     sp_co ns_param                                */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Mayo 2019                                     */
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
/*    Mayo/2019          TEAM SENTINEL PRIME       emision inicial       */
/*                                                                       */
/*************************************************************************/

USE cob_credito
GO

IF OBJECT_ID('dbo.sp_cons_param') IS NOT NULL
   drop  PROC dbo.sp_cons_param
go

create proc sp_cons_param (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_ofi                smallint  = null,
   @s_srv		 varchar(30) = null,
   @s_lsrv	  	 varchar(30) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1) = null,
   @i_nemonico	         catalogo = null,
   @i_producto           catalogo  = null
)
as

declare
   @w_today              datetime,      /* fecha del dia */ 
   @w_return             int,           /* valor que retorna */
   @w_sp_name            varchar(32),   /* nombre stored proc*/
   @w_existe             tinyint,       /* existe el registro*/
   @w_char         	 varchar(30),
   @w_tinyint      	 tinyint,
   @w_smallint           smallint,
   @w_int                int,
   @w_money              money,
   @w_datetime           datetime,
   @w_float              float,
   @o_tipo               char(1)


select @w_today = @s_date
select @w_sp_name = "sp_cons_param"

/* Debug */
/*********/



/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 21325 and @i_operacion = 'V')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1 
end



/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'V'
begin
    if 
        @i_producto = NULL or
	@i_nemonico = NULL
   
  begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 1 
    end
end



/**** Value ****/
/***************/
if @i_operacion = 'V'
begin
	select 	@o_tipo = pa_tipo,
		@w_char = pa_char,
		@w_tinyint = pa_tinyint,
		@w_smallint = pa_smallint,
	        @w_int = pa_int,
		@w_money = pa_money,
		@w_datetime = pa_datetime,
		@w_float = pa_float
	from 	cobis..cl_parametro
	where	pa_producto = @i_producto
	and	pa_nemonico = @i_nemonico

	if @@rowcount <> 1 
		select @o_tipo, @w_char
	else
	begin
		if @o_tipo = "C"
			select @w_char, @o_tipo
		else if @o_tipo = "T"
			select @w_tinyint, @o_tipo
		else if @o_tipo = "S"
			select @w_smallint, @o_tipo
		else if @o_tipo = "I"
			select @w_int, @o_tipo
		else if @o_tipo = "M"
			select @w_money, @o_tipo
		else if @o_tipo = "D"
			select @w_datetime, @o_tipo
		else if @o_tipo = "F"
			select @w_float, @o_tipo
	end 

	return 0
end

           
/* ### DEFNCOPY: END OF DEFINITION */
go