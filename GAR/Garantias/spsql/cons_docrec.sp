/*************************************************************************/
/*   Archivo:              cons_docrec.sp                                */
/*   Stored procedure:     sp_cons_docrec                                */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_cons_docrec') IS NOT NULL
    DROP PROCEDURE dbo.sp_cons_docrec
go

create proc dbo.sp_cons_docrec (
        @t_trn              int = null,
	@t_debug    	    char(1) = 'N',
	@t_file     	    varchar(10) = null,
        @t_from             varchar(30) = null,
        @s_date             datetime = null,
        @s_user             login    = null,
        @s_term             descripcion = null,
        @s_ofi              smallint  = null,
        @i_operacion        char(1) = null, 
        @i_modo             tinyint = null,
        @i_cliente          int = null,
        @i_deudor           int = null,
        @i_banco            catalogo = null,
        @i_sector           catalogo = null,
        @i_garantia         varchar(64) = null,
        @i_estado           catalogo = null,
        @i_vencimiento      smallint = null,
        @i_documento        varchar(20) = null,
        @i_formato_fecha    tinyint = null
        
)
as
declare @w_sp_name         varchar(32),    
        @w_error           int,
        @w_tabla_banco     smallint,
        @w_tabla_estados   smallint,
        @w_cambio_formato  datetime
        
         
-- INICIALIZACION DE VARIABLES
select @w_sp_name = 'sp_cons_docrec'

------------
---CONSULTAS
------------
if @i_operacion = 'Q'
begin

  --II 12/14/2009
  select @w_cambio_formato = pa_char
    from cobis..cl_parametro
   where pa_producto = 'CRE'
     and pa_nemonico = 'NFFACT'
  --FI 12/14/2009   

  /*select @w_tabla_banco = codigo
    from cobis..cl_tabla
   where tabla = 'cl_banco_rem' */--JH

  select @w_tabla_estados = codigo
    from cobis..cl_tabla
   where tabla = 'cu_estado_docum' 

  if @i_modo = 0 ---Consulta x Varios Criterios
  begin

    set rowcount 20
    select 'TIPO DOC' = tc_descripcion,
           'DOCUMENTO' = ve_num_factura,
           'DEUDOR' = ve_deudor,
           'NOMBRE DEUDOR' = substring(ve_beneficiario,1,30),   
           --II LRC 12/14/2009
           --'VALOR' = ve_valor, 
           'TOT.FACT.' = case when (select cu_fecha_ingreso 
	                              from cob_custodia..cu_custodia
	                             where cu_codigo_externo = C.ve_codigo_externo
                                   ) < @w_cambio_formato
                              then ve_valor
                              else ve_valor + ve_iva
                         end,
           --FI LRC 12/14/2009
           "VALOR RECUPERADO" = (select isnull(sum(re_valor) + sum(re_ret_iva) + sum(re_ret_fte),0)
                                   from cu_recuperacion
                                  where re_codigo_externo = C.ve_codigo_externo
                                    and re_vencimiento = C.ve_vencimiento),                 
           "VALOR A RECUPERAR" = ve_valor - (select isnull(sum(re_valor+re_ret_iva + re_ret_fte),0)
                                               from cu_recuperacion
                                              where re_codigo_externo = C.ve_codigo_externo
                                                and re_vencimiento = C.ve_vencimiento),                 
           'F.VENCIMIENTO' = convert(varchar(10),ve_fecha,@i_formato_fecha),
           'TOLERANCIA' = isnull(ve_tolerancia,0),
           'F.TOLERANCIA' = convert(varchar(10),ve_fecha_tolerancia,@i_formato_fecha),
           'CLIENTE' = cg_ente,
           'NOMBRE CLIENTE' = substring(cg_nombre,1,30),      
           'ESTADO' = (select substring(valor,1,30)
                            from cobis..cl_catalogo 
                            where tabla = @w_tabla_estados
                              and codigo = C.ve_estado),
           'GAR' = ve_codigo_externo,
           'VENC' = ve_vencimiento
      from cu_cliente_garantia, cu_vencimiento C,
           cobis..cl_ente, cu_tipo_custodia 
     where cg_codigo_externo = ve_codigo_externo
       and (cg_ente = @i_cliente or @i_cliente = null)
       and cg_principal = 'S'
       and ve_tipo_cust = tc_tipo
       and (ve_deudor = @i_deudor or @i_deudor = null)
       and (ve_banco = @i_banco or @i_banco = null)
       and (ve_estado = @i_estado or @i_estado = null)
       and ve_deudor = en_ente
       -- Se comenta porque no existe columna and (en_sector_conta = @i_sector or @i_sector = null)
       and (
            (ve_codigo_externo =  @i_garantia and (ve_vencimiento > @i_vencimiento or @i_vencimiento = null)) or
            (ve_codigo_externo > @i_garantia or @i_garantia = null)
           )
     order by ve_codigo_externo, ve_vencimiento
     set rowcount 0
  end
 

  if @i_modo = 1 ---Consulta desde Postergamientos
  begin
    
    set rowcount 20
    select 'TIPO DOC' = tc_descripcion,
           'DOCUMENTO' = ve_num_factura,
           --II LRC 12/14/2009
           --'VALOR' = ve_valor,
           'TOT.FACT.' = case when (select cu_fecha_ingreso 
	                              from cob_custodia..cu_custodia
	                             where cu_codigo_externo = C.ve_codigo_externo
                                   ) < @w_cambio_formato
                              then ve_valor
                              else ve_valor + ve_iva
                         end,
           --FI LRC 12/14/2009
           'F.EMISION' = convert(varchar(10),ve_fecha_emision,@i_formato_fecha),
           'F.VENCIMIENTO' = convert(varchar(10),ve_fecha,@i_formato_fecha),
           'F.EFECTIVA' = convert(varchar(10),ve_fecha_tolerancia,@i_formato_fecha),           
           'DEUDOR' = ve_beneficiario,   
           'CLIENTE' = cg_nombre,             
           'ESTADO' = (select substring(valor,1,30)
                            from cobis..cl_catalogo 
                            where tabla = @w_tabla_estados
                              and codigo = C.ve_estado),
           'GAR' = ve_codigo_externo,
           'VENC' = ve_vencimiento
      from cu_cliente_garantia, cu_vencimiento C,
           cu_tipo_custodia 
     where cg_codigo_externo = ve_codigo_externo
       and (cg_ente = @i_cliente or @i_cliente is null)
       and cg_principal = 'S'
       and (ve_deudor = @i_deudor or @i_deudor is null)
       and (ve_num_factura = @i_documento or @i_documento is null)
       and ve_tipo_cust = tc_tipo
       and ve_fecha_tolerancia >= @s_date   --DAR 08NOV2013
       and ve_estado not in ('V','P','D')
       and (
            (ve_codigo_externo =  @i_garantia and (ve_vencimiento > @i_vencimiento or @i_vencimiento is null)) or
            (ve_codigo_externo > @i_garantia or @i_garantia is null)
           )
     order by ve_codigo_externo, ve_vencimiento
     set rowcount 0
  end
 

end  ---@i_operacion = 'Q'
  
return 0


ERROR:
   exec cobis..sp_cerror 
   @t_debug='N',
   @t_file='',  
   @t_from=@w_sp_name,
   @i_num = @w_error,
   @i_sev = 1
   return @w_error
go