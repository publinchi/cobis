USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_genera_xml_precancela_refer') IS NOT NULL
	DROP PROCEDURE dbo.sp_genera_xml_precancela_refer
GO

/*************************************************************************/
/*   Archivo:            sp_genera_xml_precancela_refer.sp               */
/*   Stored procedure:   sp_genera_xml_precancela_refer                  */
/*   Base de datos:      cob_cartera                                     */
/*   Producto:           cobis                                           */
/*   Disenado por:       Paul Ortiz                                      */
/*   Fecha de escritura: 14/12/2017                                      */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   "MACOSA", representantes exclusivos para el Ecuador de NCR          */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier acion o agregado hecho por alguno de sus                  */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante.                 */
/*************************************************************************/
/*                                  PROPOSITO                            */
/*   Genera archivo xml con informacion para el envio del correo de      */
/*   Precancelacion                                                      */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA               AUTOR                       RAZON               */
/* 14-12-2017          Paul Ortiz                Emision Inicial         */
/* 24-04-2018          Paul Ortiz                Generacion por select   */
/* 21-11-2018          Sonia Rojas               Referencias numéricas   */
/*************************************************************************/
create procedure sp_genera_xml_precancela_refer
(
    @i_codigo         int, --Codigo (desde tabla de Precancelacion)
    @i_operacion      int, --Operacion
    @i_opcion         char(1) = null
)
as
declare 
@w_ruta_xml             varchar(255),
@w_error                int,
@w_sql_bcp              varchar(5000),
@w_sql                  varchar(5000),
@w_mensaje_bcp          varchar(150),
@w_sp_name              varchar(30)

declare @resultadobcp table (linea varchar(max))

select @w_sp_name = 'sp_genera_xml_precancela_refer'

select @w_ruta_xml = ba_path_destino
      from cobis..ba_batch 
     where ba_batch = 7076

    --Generar el xml de la temporal
if @i_opcion = 'G'
begin
    
    select 
    pr_cliente,
    [pr_fecha_liq] = convert(varchar(10),pr_fecha_liq,103),  
    pr_nombre_cl,
    [pr_fecha_ven] = convert(varchar(10),pr_fecha_ven,103), 
    [pr_monto_pre] = convert(varchar(10),pr_monto_pre),
    pr_nombre_of,
    pr_mail
    from cob_cartera..ca_precancela_refer  
    where pr_secuencial =   convert(varchar, @i_codigo)
    and   pr_operacion  =   convert(varchar, @i_operacion) 
 
    select 
    institucion    = prd_institucion, 
    referencia     = prd_referencia, 
    convenio       = prd_convenio, 
    cliente        = prd_cliente
    from cob_cartera..ca_precancela_refer_det
    where prd_secuencial =   convert(varchar, @i_codigo)
    and   prd_operacion  =   convert(varchar, @i_operacion) 
    
end

return 0

ERROR:
    --select @o_msg = mensaje
    --  from cobis..cl_errores with (nolock)
    -- where numero = @w_error

    set transaction isolation level read uncommitted

    --select @o_msg = isnull(@o_msg,'')
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error

GO
