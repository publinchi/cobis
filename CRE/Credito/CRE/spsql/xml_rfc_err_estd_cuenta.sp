/************************************************************************/
/*  Archivo:                xml_rfc_err_estd_cuenta.sp                  */
/*  Stored procedure:       sp_xml_rfc_err_estd_cuenta                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_xml_rfc_err_estd_cuenta' and type = 'P')
   drop proc sp_xml_rfc_err_estd_cuenta
go


create proc sp_xml_rfc_err_estd_cuenta (
    @i_operacion      CHAR(1)    =   null -- operacion
)as

--LPO CDIG Se comenta porque Cobis Language no soporta XML INICIO
/*
DECLARE
   @w_fecha_proceso                  DATETIME,
   @w_primer_dia_mes                 DATETIME,
   @w_fecha_generacion_estado_cuenta DATETIME,
   @w_sp_name                        varchar(24),
   @w_parametro_tipo                 varchar(50),     -- Parametro del tipo de direccion para factura
   @w_cod_cliente                    int,
   @w_ruta_xml                       varchar(255),
   @w_xml                            xml,
   @w_sql                            varchar(255),
   @w_sql_bcp                        varchar(255),
   @w_comando                        varchar(255),
   @w_error                          int,
   @w_primer_dia_def_habil           datetime,
   @w_ciudad_nacional                int,
   @w_errores                        varchar(1500),
   @w_path_bat                       varchar(100),
   @w_riemisor                       varchar(12),
   @w_file_name                      VARCHAR(20),   
   @w_count                          INT,
   @w_folio_referencia               VARCHAR(80),
   @w_codigo_postal                  VARCHAR(30),
   @w_metodo_pago                    VARCHAR(10),
   @w_forma_pago                     VARCHAR(10),
   @w_porcentaje_iva                 NUMERIC(10,6),
   @w_msg                            VARCHAR(255),
   @w_primer_dia_mes_anterior        DATETIME,
   @w_correo_rfc_error               VARCHAR(64)

SELECT @w_fecha_proceso=fp_fecha FROM cobis..ba_fecha_proceso

SELECT @w_fecha_proceso

select @w_primer_dia_mes = dateadd(dd, 1-datepart(dd, @w_fecha_proceso  ), @w_fecha_proceso )

SELECT @w_primer_dia_mes

select @w_fecha_generacion_estado_cuenta=max(do_fecha) FROM  cob_conta_super..sb_dato_operacion WHERE  do_fecha < @w_primer_dia_mes 

SELECT @w_fecha_generacion_estado_cuenta

select @w_primer_dia_mes_anterior = dateadd(dd, 1-datepart(dd, @w_fecha_generacion_estado_cuenta  ), @w_fecha_generacion_estado_cuenta )

--SELECT @w_primer_dia_mes_anterior='06/01/2019'
--SELECT @w_fecha_generacion_estado_cuenta='06/28/2019'

 SELECT @w_metodo_pago = 'PUE'
 
 SELECT @w_forma_pago = '03'
 SET @w_count=1
 
 select @w_codigo_postal = pa_char
from cobis..cl_parametro
where pa_producto = 'REC'
and pa_nemonico = 'CPOSTA'
--cambiar solo para prueba
SELECT @w_folio_referencia='00000000000'

select @w_porcentaje_iva = (pa_float/100)
from   cobis..cl_parametro
where pa_nemonico = 'PIVA'

--/SELECT @w_correo_rfc_error = pa_char
--from   cobis..cl_parametro
--where pa_nemonico = 'CIRFCR'
--AND pa_producto='CRE' --/

SELECT TOP 1 @w_correo_rfc_error   = valor  
        FROM cobis..cl_catalogo WHERE tabla = (SELECT codigo 
                        FROM cobis..cl_tabla WHERE tabla = 'cr_correo_rfc_Global')


CREATE table #amortizacion_err_rfc_def(
    
    dc_cuota_amor_det       Money,
    dc_iva_amor_det         Money,
    dc_concepto_amor_det    VARCHAR(30)
    )
if @i_operacion = 'I'    
	
BEGIN

 IF EXISTS(SELECT 1 FROM cob_credito..cr_rfc_int_error )
   BEGIN
   --INT
     truncate table cob_credito..cr_resultado_xml
     INSERT INTO #amortizacion_err_rfc_def
     SELECT  sum(dc_int_acum),
             sum(dc_iva_int_acum),
             'INT'
         FROM  cob_conta_super..sb_dato_cuota_pry ,cob_conta_super..sb_dato_operacion,cobis..cl_ente 
         WHERE  do_fecha = @w_fecha_generacion_estado_cuenta
         AND    dc_fecha = do_fecha
         AND dc_aplicativo = 7 
         AND do_aplicativo = 7 
         AND do_banco = dc_banco
         AND dc_fecha_vto BETWEEN @w_primer_dia_mes_anterior  AND  @w_fecha_generacion_estado_cuenta
         AND en_ente=do_codigo_cliente
		 AND dc_estado<>0
         AND en_rfc IN (SELECT rfc_int_error FROM cob_credito..cr_rfc_int_error)
		-- AND IN ('R?DA70060311A','PIPV7201019D7','HEHM800101RF9','PIPC800101BN1','SESC800101EN1')
         
     --COMMORA   
     INSERT INTO #amortizacion_err_rfc_def 
         SELECT sum(dc_imo_cuota),
                sum(dc_iva_imo_cuota),
                'COMMORA'
         FROM  cob_conta_super..sb_dato_cuota_pry ,cob_conta_super..sb_dato_operacion ,cobis..cl_ente
         WHERE  do_fecha = @w_fecha_generacion_estado_cuenta
         AND    dc_fecha = @w_fecha_generacion_estado_cuenta
         AND dc_aplicativo = 7 
         AND do_aplicativo = 7 
         AND do_banco = dc_banco
         AND dc_fecha_vto BETWEEN  @w_primer_dia_mes_anterior AND  @w_fecha_generacion_estado_cuenta
         AND en_ente=do_codigo_cliente
         AND en_rfc IN (SELECT rfc_int_error FROM cob_credito..cr_rfc_int_error)
		-- AND IN ('R?DA70060311A','PIPV7201019D7','HEHM800101RF9','PIPC800101BN1','SESC800101EN1')
         
      --COMPRECAN   
     INSERT INTO #amortizacion_err_rfc_def 
       SELECT sum(dc_pre_cuota),
              sum(dc_iva_pre_cuota),
             'COMPRECAN'
         FROM  cob_conta_super..sb_dato_cuota_pry ,cob_conta_super..sb_dato_operacion,cobis..cl_ente
         WHERE  do_fecha = @w_fecha_generacion_estado_cuenta
         AND    dc_fecha = @w_fecha_generacion_estado_cuenta
         AND dc_aplicativo = 7 
         AND do_aplicativo = 7 
         AND do_banco = dc_banco
         AND dc_fecha_vto BETWEEN  @w_primer_dia_mes_anterior AND  @w_fecha_generacion_estado_cuenta
         AND en_ente=do_codigo_cliente
         AND en_rfc IN (SELECT rfc_int_error FROM cob_credito..cr_rfc_int_error)
		-- AND IN ('R?DA70060311A','PIPV7201019D7','HEHM800101RF9','PIPC800101BN1','SESC800101EN1')
         
         SELECT * FROM #amortizacion_err_rfc_def
       
        select @w_riemisor = substring(pa_char,1,12)
        from   cobis..cl_parametro with (nolock)
        where  pa_nemonico = 'RIEMIS'
        and    pa_producto = 'CRE'   
     
     
         
     select @w_xml  = (
                 select
                     -- -------------------- Emisor - INI --------------------
                     (SELECT '@RI' = @w_riemisor FOR XML PATH('Emisor'),type) 
                     -- -------------------- Emisor - FIN --------------------
                     ,
                     -- -------------------- Receptor - INI --------------------
                     (SELECT 
                         '@Ente'             = 0,
                         '@RFC'              = 'XAXX010101000',
                         '@IdExterno'        = 0,
                         '@Nombre'           = 'PUBLICO EN GENERAL',
                         '@Telefono'         = '0',
                         '@Email'            = @w_correo_rfc_error,  -- CORREO ELECTRONICO
                         '@cfdiUsoCFDI'      = convert(varchar(3), 'P01'),
                         '@ResidenciaFiscal' = convert(varchar(3), 'MEX'),
                          -- -------------------- Domicilio - INI --------------------
                         (SELECT 
                             '@Ente'              = 0,
                             '@calle'             = '-',
                             '@noExterior'        ='0',
                             '@noInterior'        = ' ',
                             '@Colonia-Parroquia' = '-',
                             '@Localidad'         = ' ',
                             '@Municipio-Ciudad'  = ' ',
                             '@Estado-Provincia'  = 'CIUDAD DE MEXICO',
                             '@codigoPostal'      = '11700'
                              for xml path('Domicilio'), type)
                          -- -------------------- Domicilio - FIN --------------------
                             for xml path('Receptor'), type)
                     -- -------------------- Receptor - FIN --------------------
                     ,
                     -- -------------------- Encabezado - INI --------------------
                     (select --op_cliente ,
                         '@TipoDocumento'       = convert(varchar( 50), 'I'),
                         '@FolioReferencia'     = convert(varchar(100),@w_folio_referencia ), -- PendSant OK -cambiar
                         '@LugarExpedicion'     = convert(varchar(100), @w_codigo_postal),    -- Pend, No tenemos este dato(VBRO -> Paul)
     -- STD ponemos fecha de fin de mes para enganchar respuesta de interfactura con el consolidador
     -- quitamos la Z del formato para que cambia cuando regrese
                         '@Fecha'               = format(@w_fecha_generacion_estado_cuenta, 'yyyy-MM-ddTHH:mm:ss'),
     -- STD dice que no va
     --                  '@formaDePago'         = convert(varchar( 50), @w_forma_pago),       -- PendSant = OK
     -- STD dice que esto hay que renombrar
     --                  '@metodoDePago'        = convert(varchar( 50), @w_metodo_pago),      -- PendSant = OK
                         '@cfdiMetodoPago'      = convert(varchar( 50), @w_metodo_pago),      -- PendSant = OK
                         '@RegimenFiscalEmisor' = convert(varchar(  3), '601'),
                         '@Moneda'              = convert(varchar(  3), 'MXN'),
                         '@SubTotal'            = sum(case when dc_concepto_amor_det in ('COMMORA','COMPRECAN','INT') then dc_cuota_amor_det else 0 end),
                         '@Total'               = (sum(case when dc_concepto_amor_det in ('COMMORA','COMPRECAN','INT') then dc_cuota_amor_det else 0 end) 
     					                         + ceiling((sum(case when dc_concepto_amor_det in ('COMMORA','COMPRECAN','INT') then dc_cuota_amor_det else 0 end)) * @w_porcentaje_iva * 100)/100),
                         '@cfdiFormaPago'       = convert(varchar(2), @w_forma_pago),
                         '@serie'               = convert(varchar(10), FORMAT(@w_count,'0000000000') ), --PendSant = OK
                         -- -------------------- Encabezado - Cuerpo - INI --------------------
                         (select
                             '@Renglon'            = row_number() over(order by dc_concepto_amor_det),
                             '@Cantidad'           = convert(decimal(10), 1),
                             '@U_x0020_de_x0020_M' = convert(varchar(100), 'ACT'),
                             '@Concepto'           = convert(varchar(1000), dc_concepto_amor_det), --**********52 base
                             '@PUnitario'          = convert(numeric(20,2), dc_cuota_amor_det),        --**********53 base
                             '@Importe'            = convert(numeric(20,2), dc_cuota_amor_det),          --**********54 base
                             '@cfdiClaveProdServ'  = convert(varchar(10), '84141600'),
                             '@cfdiClaveUnidad'    = convert(varchar(3), 'ACT'),
                             '@Codigo'             = convert(varchar(100), '000000000000'),
                             -- -------------------- Encabezado - Cuerpo - Traslado - INI --------------------
                             (SELECT 
                                 '@CodigoMultiple' = convert(varchar(50), 'TrasladoConcepto'), 
                                 '@cfdiBase'       = isnull(convert(numeric(20,2),dc_cuota_amor_det),0),     --**********62  comi + int
                                 '@cfdiImpuesto'   = convert(varchar(3),  '002'),
                                 '@cfdiTipoFactor' = convert(varchar(10), 'Tasa'),
                                 '@cfdiTasaOCuota' = convert(varchar(20), '0.160000'),
                                 '@cfdiImporte'    = isnull((isnull(dc_cuota_amor_det*@w_porcentaje_iva,0) ),0)
                                 from #amortizacion_err_rfc_def tmp
                                 WHERE tmp.dc_concepto_amor_det=def.dc_concepto_amor_det
                                 
       
                              for xml path('Traslado'), type)
                             -- -------------------- Encabezado - Cuerpo - Traslado - FIN --------------------
                         from #amortizacion_err_rfc_def def
                         WHERE     dc_cuota_amor_det>0
                         for xml path('Cuerpo'), type),
                         -- -------------------- Encabezado - Cuerpo - FIN --------------------
                 
                         -- -------------------- Encabezado - Impuestos - INI --------------------
                         (select
                             '@CodigoMultiple'            = convert(varchar(50),'cfdiImpuestos'),
                             '@totalImpuestosTrasladados' = isnull(ceiling(sum(isnull(dc_cuota_amor_det,0)) * @w_porcentaje_iva * 100)/100,0),
                             -- -------------------- Encabezado - Impuestos - Traslado - INI --------------------
                             (select
                                 '@CodigoMultiple' = convert(varchar(50), 'cfdiImpuestos'),
                                 '@cfdiImpuesto'   = convert(varchar(3), '002'),
                                 '@cfdiTipoFactor' = convert(varchar(10), 'Tasa'),
                                 '@cfdiTasaOCuota' = convert(varchar(20), 0.16),
                                 '@cfdiImporte'    = isnull(ceiling(sum(isnull(dc_cuota_amor_det,0)) * @w_porcentaje_iva * 100)/100,0)
                            from #amortizacion_err_rfc_def
                             for xml path('Traslado'), type)
                            -- -------------------- Encabezado - Impuestos - Traslado - FIN --------------------
                         from #amortizacion_err_rfc_def for xml path('Impuestos'), type)
                         -- -------------------- Encabezado - Impuestos - FIN --------------------
                     from #amortizacion_err_rfc_def
                     for xml path('Encabezado'), type)
                     FOR XML PATH('FacturaInterfactura'))
                     -- -------------------- Encabezado - FIN --------------------    
     
           SELECT  @w_file_name = @w_folio_referencia + substring(convert(varchar(8),@w_fecha_generacion_estado_cuenta,112),3,8)
     
           SELECT  @w_file_name = 'XAXX010101000' + '-' + substring(convert(varchar(8),@w_fecha_generacion_estado_cuenta,112),3,8)
     --    SELECT  'archivo' = @w_file_name , 'xml' = @w_xml, 'Cl' = @w_cod_cliente, 'OP' = @w_banco, 'Folio' = @w_folio_referencia
     
           insert into cob_credito..cr_resultado_xml (linea, file_name) values (@w_xml, @w_file_name)
           
        select * from cob_credito..cr_resultado_xml
        
        -- ------------------------------------------------------------------------------------
     select @w_path_bat = pp_path_fuente   --C:\Cobis\VBatch\Credito\Objetos\
     from cobis..ba_path_pro
     where pp_producto = 21
     
     select @w_ruta_xml = pp_path_destino
     from cobis..ba_path_pro
     where pp_producto = 21


   select @w_comando = @w_path_bat + 'cr_genestctaxml.bat ' +
                       @w_ruta_xml + 'estcta\ ' +
                       @w_path_bat + 'estcta\'

   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0
   begin
      exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 724625,
         @i_msg   = 'ERROR: en la generacion del archivo XML Estado de Cuenta'
      return 724625
   END
   
   DELETE FROM cob_credito..cr_rfc_int_error_hist WHERE fecha_gen_estado_cuenta=@w_fecha_generacion_estado_cuenta 
   INSERT INTO cob_credito..cr_rfc_int_error_hist--Inserta en la tabla de historicos de rfc 
   SELECT 
   rfc_int_error,
   @w_fecha_generacion_estado_cuenta
   FROM cob_credito..cr_rfc_int_error   
   -- ------------------------------------------------------------------------------------
 truncate table cob_credito..cr_rfc_int_error--BORRO LOS DATOS DE LA TABLA CON RFC QUE TIENE ERROR
 end--fin if
END --fin operacion
return 0

ERROR_PROCESO:
     select @w_msg = isnull(@w_msg, 'ERROR GENRAL DEL PROCESO')
     exec cob_conta_super..sp_errorlog
     @i_fecha_fin     = @w_fecha_proceso,
     @i_fuente        = @w_sp_name,
     @i_origen_error  = @w_error,
     @i_descrp_error  = @w_msg
*/
--LPO CDIG Se comenta porque Cobis Language no soporta XML FIN

RETURN 0
GO
