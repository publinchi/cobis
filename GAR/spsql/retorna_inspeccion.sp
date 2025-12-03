/****************************************************************/
/* ARCHIVO:              retorna_inspeccion.sp                  */
/* Stored procedure:	 sp_retorna_inspeccion	          	    */
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

IF OBJECT_ID('dbo.sp_retorna_inspeccion') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_retorna_inspeccion
    IF OBJECT_ID('dbo.sp_retorna_inspeccion') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_retorna_inspeccion >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_retorna_inspeccion >>>'
END
go
create proc sp_retorna_inspeccion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint = null,
   @i_formato_fecha      int  = null,
   @i_custodia           int      = null,
   @i_tipo               descripcion = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint, 
   @w_sucursal           smallint,
   @w_tipo               descripcion,
   @w_custodia           int,
   @w_fultima_insp       datetime,
   @w_inspector          tinyint,
   @w_estado             descripcion,
   @w_codigo_externo     descripcion,
   @w_riesgos            money,
   @w_ciudad             descripcion

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_retorna_inspeccion'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19175 and @i_operacion = 'Q')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,

    @i_num   = 1901006
    return 1 
end

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    select @w_riesgos = 0  
    -- CODIGO EXTERNO
         /*        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
*/

    /*exec @w_return         = sp_riesgos
         @s_date           = @s_date, 
         @t_trn            = 19445,
         @i_operacion      = 'Q',
         @i_codigo_externo = @w_codigo_externo,
         @o_riesgos        = @w_riesgos out*/

      if @w_return  <> 0
      begin
      /*  Error en consulta de registro */
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909002
           return 1 
      end

    select @w_ciudad = cu_ciudad_prenda
      from cu_custodia
     where cu_codigo_externo = @w_codigo_externo 

    select 
        @w_filial       = in_filial, 
        @w_sucursal     = in_sucursal,
        @w_custodia     = in_custodia,
        @w_tipo         = in_tipo_cust,   
        @w_fultima_insp = in_fecha_insp,
        @w_inspector    = in_inspector,
        @w_estado       = in_estado
    from cob_custodia..cu_inspeccion,cu_custodia
    where
          in_filial    = @i_filial and
          in_sucursal  = @i_sucursal and
          in_tipo_cust = @i_tipo and
          in_custodia  = @i_custodia and 
          in_fecha_insp in (select max(in_fecha_insp) 
                 from cu_inspeccion
                 where in_filial    = @i_filial and
                       in_sucursal  = @i_sucursal and
                       in_tipo_cust = @i_tipo and
                       in_custodia  = @i_custodia and 
		       datepart(year,getdate()) = datepart(year,in_fecha_insp))

    if @@rowcount > 0
       select @w_existe = 1
    else
       select @w_existe = 0

    if @w_existe = 1
    begin
         select 
              @w_custodia,
              @w_tipo,
              convert(char(10),@w_fultima_insp,@i_formato_fecha),
              @w_ciudad,
              isnull(convert(char(10),@w_inspector),''),
              @w_estado,
              isnull(@w_riesgos,0)
    end
    else
    begin
         select 
              @i_custodia,@i_tipo,'',@w_ciudad,'','',isnull(@w_riesgos,0)
    end
return 0
end
go
--EXEC sp_procxmode 'dbo.sp_retorna_inspeccion', 'unchained'
go
IF OBJECT_ID('dbo.sp_retorna_inspeccion') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_retorna_inspeccion >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_retorna_inspeccion >>>'
go