/************************************************************************/
/*  Archivo:                genera_estado_cta_xml.sp                    */
/*  Stored procedure:       sp_genera_estado_cta_xml                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           José Escobar                                */
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
/*  Generacion de archivo de los impuestos cobrados                     */
/*  (IVA_CMORA,IVA_COMPRE, IVA_INT ) de los prestamos                   */
/*  vigentes y sus respectivas comisiones.                              */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_genera_estado_cta_xml')
    drop proc sp_genera_estado_cta_xml
go


create proc sp_genera_estado_cta_xml (
	@t_show_version   bit 		= 	0,
	@i_param1 			datetime	=	null -- FECHA DE PROCESO
)as

--LPO CDIG Se comenta porque Cobis Language no soporta XML INICIO
/*
declare
   @w_sp_name         varchar(24),
   @w_parametro_tipo  varchar(50),     -- Parametro del tipo de direccion para factura
   @w_cod_cliente     int,
   @w_ruta_xml        varchar(255),
   @w_xml             xml,
   @w_sql             varchar(255),
   @w_sql_bcp         varchar(255),
   @w_comando         varchar(255),
   @w_error           int,
   -- -----------------------------
   @w_mes             varchar(2),
	@w_ano             varchar(4),
	@w_primer_dia_def_habil  datetime,
   @w_primer_dia_mes  varchar(2),
	@w_primer_dia      varchar(10),
   @w_ciudad_nacional int,
	@w_fecha_cierre	 datetime,
   @w_errores         varchar(1500),
   @w_path_bat        varchar(100),
   @w_riemisor        varchar(12),
   @w_file_name       VARCHAR(20),
   @w_count           INT
   -- ------------------------------

select @w_sp_name= 'sp_genera_estado_cta_xml'


--///////////////////////////////
-- validar si se procesa o no
DECLARE
@w_reporte          VARCHAR(10),
@w_return           int,
@w_existe_solicitud char (1) ,
@w_ini_mes          datetime ,
@w_fin_mes          datetime ,
@w_fin_mes_hab      datetime ,
@w_fin_mes_ant      datetime ,
@w_fin_mes_ant_hab  DATETIME ,
@w_msg              VARCHAR(255)

SELECT @w_reporte = 'ESTCTA'
EXEC @w_return = cob_conta..sp_calcula_ultima_fecha_habil
    @i_reporte          = @w_reporte,  -- buro mensual
    @i_fecha            = @i_param1,
    @o_existe_solicitud = @w_existe_solicitud  out,
    @o_ini_mes          = @w_ini_mes out,
    @o_fin_mes          = @w_fin_mes out,
    @o_fin_mes_hab      = @w_fin_mes_hab out,
    @o_fin_mes_ant      = @w_fin_mes_ant out,
    @o_fin_mes_ant_hab  = @w_fin_mes_ant_hab OUT

if @w_return != 0
begin
    select @w_error = @w_return
    select @w_msg   = 'Fallo ejecucion cob_conta..sp_calcula_ultima_fecha_habil'
    goto ERROR_PROCESO
end

if @w_existe_solicitud = 'N' goto SALIDA_PROCESO

-- SI SE EJECUTA EN OTRO DIA, TOMA LAS FECHA DEL MES ANTERIOR
if datepart(dd, @i_param1) > 1 -- procesar con mes anterior
begin
    select @w_ini_mes  = dateadd(mm,-1,dateadd(dd,1, @w_fin_mes_ant))
    select @w_fin_mes  = @w_fin_mes_ant
    select @i_param1   = dateadd(dd,1, @w_fin_mes_ant)
end
--///////////////////////////////

--Versionamiento del Programa --
if @t_show_version = 1
begin
  print 'Stored Procedure=' + @w_sp_name + ' Version=' + '4.0.0.0'
  return 0
end

select @w_path_bat = pp_path_fuente   --C:\Cobis\VBatch\Credito\Objetos\
from cobis..ba_path_pro
where pp_producto = 21

--Obtiene el parametro del codigo moneda local
select @w_parametro_tipo = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'RE'

select @w_ruta_xml = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 21

--CALCULO PARA DETERMINAR EL PRIMER DIA HABIL DEL MES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_riemisor = substring(pa_char,1,12)
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'RIEMIS'
and    pa_producto = 'CRE'

select @w_fecha_cierre   = @i_param1
select @w_primer_dia_mes = datepart(dd,dateadd(dd,1,dateadd(dd, datepart(dd,@w_fecha_cierre )*(-1),@w_fecha_cierre )))
select @w_mes 		       = datepart(mm, @w_fecha_cierre)
select @w_ano 		       = datepart(yy, @w_fecha_cierre)
select @w_primer_dia 	 = @w_mes + '/' + @w_primer_dia_mes + '/' + @w_ano
select @w_primer_dia_def_habil  = convert(datetime, @w_primer_dia)

-- ------------------------------------------------------------------------------------------
-- Limpiar la ruta en la que se generara el archivo.xml de estado de cuenta
select @w_comando = 'del /q /s ' + @w_ruta_xml + 'estcta\*.*'
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0
begin
   exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = 724675,
      @i_msg   = 'ERROR: SP_GENERA_ESTADO_CTA_XML'
   return 724675
end
select @w_error = 0
-- ------------------------------------------------------------------------------------------
while exists(select 1 from cobis..cl_dias_feriados
          where df_ciudad = @w_ciudad_nacional
          and   df_fecha  = @w_primer_dia_def_habil ) begin
   select @w_primer_dia_def_habil = dateadd(day,1,@w_primer_dia_def_habil)
end
SET @w_count = 0
--SI ES INICIO DE MES  SE EJECUTA
--if(@i_param1 = @w_primer_dia_def_habil)
begin

   truncate table cr_resultado_xml

   declare cur_clientes_op cursor for
   select distinct op.op_cliente
   from cob_cartera..ca_operacion op
   where op_estado not in (0, 3, 99,6)
   for read only
   -- open cur_clientes_op - INI
   open cur_clientes_op
   fetch cur_clientes_op into @w_cod_cliente
   while @@fetch_status <> -1
   begin
      if @@fetch_status = -2
      begin
        close cur_clientes_op
        deallocate cur_clientes_op
        --/ Error en recuperacion de datos del cursor /
        exec cobis..sp_cerror
          --@t_debug = @t_debug,
          --@t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_msg   = "NO EXISTEN CLIENTES CON PRESTAMOS VIGENTES",
          @i_num   = 107099
        return 1
      end

	  SET @w_count = @w_count + 1

      select @w_xml  = (select

         -- -------------------- Emisor - INI --------------------
         (SELECT '@RI' = @w_riemisor FOR XML PATH('Emisor'),type)
         -- -------------------- Emisor - FIN --------------------
   ,
         -- -------------------- Receptor - INI --------------------
         (select
            '@Ente' = en_ente,
            '@RFC' = isnull(convert(varchar(25), en_nit),''),
            '@IdExterno' = isnull(convert(varchar(25), en_ente),''),
            '@Nombre'   = isnull(convert(varchar(254), en_nomlar),''),
            '@Telefono' = convert(varchar(20), t.te_valor),
            '@Email' = isnull((select convert(varchar(25), d.di_descripcion)
                              from cobis..cl_direccion d
                              where d.di_ente = e.en_ente
                              and d.di_direccion = e.en_direccion
                              and d.di_tipo = 'CE'),''),
            '@cfdiUsoCFDI' = convert(varchar(3), 'P01'),
            '@ResidenciaFiscal' = convert(varchar(3), 'MEX'),
             -- -------------------- Domicilio --------------------
            (select
                 '@Ente' = en_ente,
                 '@calle' = isnull(convert(varchar(250), di_calle),''),
                 '@noExterior' = convert(varchar(200), di.di_nro),
                 '@noInterior' = convert(varchar(200), di.di_nro_interno),
                 '@Colonia-Parroquia' = isnull(convert(varchar(250), (select convert(varchar(40),pq_descripcion)
                                       from cobis..cl_parroquia p where p.pq_parroquia = di.di_parroquia)),''),
                 '@Localidad' = isnull(convert(varchar(250), (select convert(varchar(40),pq_descripcion)
                               from cobis..cl_parroquia p where p.pq_parroquia = di.di_parroquia)),''),
                 '@Municipio-Ciudad' = isnull(convert(varchar(100),(select convert(varchar(40),ci_descripcion)
                                    from cobis..cl_ciudad c where c.ci_ciudad = di.di_ciudad)),''),
                 '@Estado-Provincia' = isnull(convert(varchar(100),(select pv_descripcion
                                    from cobis..cl_provincia r where r.pv_provincia = di.di_provincia)),''),
                 '@CodPais' = convert(varchar(100), 'MEX'),
                 '@codigoPostal' = isnull(convert(varchar(80),di_codpostal),'')
            from cobis..cl_ente e left join cobis..cl_direccion di on di.di_ente = e.en_ente
            where di.di_direccion = e.en_direccion
            and en_ente = @w_cod_cliente
            and di_tipo = @w_parametro_tipo for xml path('Domicilio'), type)

         from cobis..cl_ente e
         left join cobis..cl_contacto c on c.co_ente = e.en_ente
         left join cobis..cl_telefono t on t.te_ente = e.en_ente
         where en_ente = @w_cod_cliente for xml path('Receptor'), type)
         -- -------------------- Receptor - FIN --------------------
      ,
         -- -------------------- Encabezado - INI --------------------
         (select --op_cliente ,
            '@TipoDocumento'   = convert(varchar(50), 'I'),
            '@FolioReferencia' = convert(varchar(100), ''), -- PendSant
            '@LugarExpedicion' = convert(varchar(100), ''), -- Pend, No tenemos este dato(VBRO -> Paul)
            '@Fecha' = (select format(fp_fecha, 'yyyy-MM-ddTHH:mm:ssZ') from cobis..ba_fecha_proceso),
            '@formaDePago' = convert(varchar(50), '03'),--PendSant = OK
            '@metodoDePago'= convert(varchar(50), 'PUE'),--PendSant = OK
            '@RegimenFiscalEmisor' = convert(varchar(3), '601'),
            '@Moneda' = convert(varchar(3), 'MXN'),
            '@SubTotal' = sum(case when am_concepto in ('COMMORA','COMPRECAN','INT')
                            then am_cuota else 0 end),
            '@Total' = sum(case when am_concepto in ('IVA_INT','IVA_CMORA','IVA_COMPRE')
                            then (- am_cuota) else am_cuota end),
            '@cfdiFormaPago' = convert(varchar(2), '99'),
            '@serie' = convert(varchar(10), FORMAT(@w_count,'0000000000') ), --PendSant = OK
            -- -------------------- Encabezado - Cuerpo - INI --------------------
            (select
               '@Renglon'   = row_number() over(order by cliente),
               '@Cantidad'  = convert(decimal(10), 1),
               '@U_x0020_de_x0020_M' = convert(varchar(100), 'ACT'),
               '@Concepto'  = convert(varchar(1000), concepto),
               '@PUnitario' = convert(money, punitario),
               '@Importe'   = convert(money, importe),
               '@cfdiClaveProdServ' = convert(varchar(10), '84141600'),
               '@cfdiClaveUnidad'   = convert(varchar(3), 'ACT'),
               '@Codigo'    = convert(varchar(100), codigo),
               -- -------------------- Encabezado - Cuerpo - Traslado - INI --------------------
               (select
                  '@CodigoMultiple' = convert(varchar(50), 'TrasladoConcepto'),
                  '@cfdiBase'       = sum(comisiones),
                  '@cfdiImpuesto'   = convert(varchar(3), '002'),
                  '@cfdiTipoFactor' = convert(varchar(10), 'Tasa'),
                  '@cfdiTasaOCuota' = convert(varchar(20), '16%'),
                  '@cfdiImporte'    = sum(impuestos )
               from (
                  select
                     am_concepto = (case
                                       when am_concepto = 'INT' then 'IVA_INT'
                                       when am_concepto = 'COMMORA' then 'IVA_CMORA'
                                       when am_concepto = 'COMPRECAN' then 'IVA_COMPRE'
                                       else am_concepto end),
                     comisiones = sum(case
                                       when am_concepto in ('INT','COMMORA','COMPRECAN')
                                       then am_cuota else 0 end),
                     impuestos  = sum(case when am_concepto in ('IVA_CMORA', 'IVA_INT', 'IVA_COMPRE') then am_cuota
                                           else 0 end),
                     operacion     = op_banco
                        from cob_cartera..ca_operacion op, cob_cartera..ca_amortizacion
                        where op_operacion = am_operacion
                        and am_concepto in ('INT','IVA_INT','COMMORA','IVA_CMORA','COMPRECAN','IVA_COMPRE')
                        and op_estado not in (0,3,99,6)
                        and op_cliente = @w_cod_cliente
                        and am_cuota is not null
                        --and op.op_operacion = op1.op_operacion
                        group by op_cliente ,op_banco, am_concepto
               )as ca_encab_cuerpo_tras
               where operacion = codigo
                 and concepto = am_concepto
               group by am_concepto for xml path('Traslado'), type)
               -- -------------------- Encabezado - Cuerpo - Traslado - FIN --------------------
            from (
               select cliente, concepto, sum(punitario) punitario, sum(importe) importe, codigo
               from (
                  select
                     cliente   = op_cliente ,
                     concepto  = (case when am_concepto = 'INT' then 'IVA_INT'
                                      when am_concepto = 'COMMORA' then 'IVA_CMORA'
                                      when am_concepto = 'COMPRECAN' then 'IVA_COMPRE'
                                      else am_concepto end) ,
                     punitario = sum(case when am_concepto in ('IVA_CMORA', 'IVA_INT', 'IVA_COMPRE') then am_cuota
                                          else 0 end),
                     importe   = sum(case when am_concepto in ('INT','COMMORA','COMPRECAN')
                                        then am_cuota else 0 end),
                     codigo = op_banco
                  from cob_cartera..ca_operacion op1,cob_cartera..ca_amortizacion
                  where op_operacion = am_operacion
                  and am_concepto in ('INT','IVA_INT','COMMORA','IVA_CMORA','COMPRECAN','IVA_COMPRE')
                  and op_estado not in (0,3,99,6)
                  and op_cliente = @w_cod_cliente
                  and am_cuota != 0
                  group by op_cliente ,op_banco, am_concepto
               ) as ca_detalle_impuesto
               group by cliente, concepto, codigo
            ) as ca_detalle_impuesto_main
            order by cliente for xml path('Cuerpo'), type),
            -- -------------------- Encabezado - Cuerpo - FIN --------------------

            -- -------------------- Encabezado - Impuestos - INI --------------------
            (select
               '@CodigoMultiple' = convert(varchar(50),'cfdiImpuestos'),
               '@totalImpuestosTrasladados' = sum(am_cuota),
               -- -------------------- Encabezado - Impuestos - Traslado - INI --------------------
               (select
                  '@CodigoMultiple' = convert(varchar(50), 'cfdiImpuestos'),
                  '@cfdiImpuesto'   = convert(varchar(3), '002'),
                  '@cfdiTipoFactor' = convert(varchar(10), 'Tasa'),
                  '@cfdiTasaOCuota' = convert(varchar(20), '16%'),
                  '@cfdiImporte'    = sum(am_cuota)
               from cob_cartera..ca_operacion ,cob_cartera..ca_amortizacion
               where op_operacion = am_operacion
               and am_concepto in ('IVA_INT','IVA_CMORA','IVA_COMPRE')
               and op_estado not in (0,3,99,6)
               and op_cliente = @w_cod_cliente
               and am_cuota is not null for xml path('Traslado'), type)
               -- -------------------- Encabezado - Impuestos - Traslado - FIN --------------------
            from cob_cartera..ca_operacion ,cob_cartera..ca_amortizacion
            where op_operacion = am_operacion
            and am_concepto in ('IVA_INT','IVA_CMORA','IVA_COMPRE')
            and op_estado not in (0,3,99,6)
            and op_cliente = @w_cod_cliente
            and am_cuota is not null for xml path('Impuestos'), type)
            -- -------------------- Encabezado - Impuestos - FIN --------------------

         from cob_cartera..ca_operacion ca1,cob_cartera..ca_amortizacion
         where op_operacion = am_operacion
         and am_concepto in ('INT','IVA_INT','COMMORA','IVA_CMORA','COMPRECAN','IVA_COMPRE')
         and op_estado not in (0,3,99,6)
         and am_cuota is not null
         and op_cliente = @w_cod_cliente
         group by op_cliente
         order by op_cliente for xml path('Encabezado'), type)







         FOR XML PATH('FacturaInterfactura'))
         -- -------------------- Encabezado - FIN --------------------

      SELECT  @w_file_name = (SELECT RIGHT('00000000'+ISNULL(en_banco,''),8) FROM cobis..cl_ente WHERE en_ente = @w_cod_cliente)+
								(select 'CCA-'+substring(convert(varchar(8),fp_fecha,112),3,8)
								from cobis..ba_fecha_proceso)


      insert into cr_resultado_xml (linea, file_name) values (@w_xml, @w_file_name)

      fetch cur_clientes_op into @w_cod_cliente
   end
   -- open cur_clientes_op - FIN
   close cur_clientes_op
   deallocate cur_clientes_op

   -- ------------------------------------------------------------------------------------
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
   end
   -- ------------------------------------------------------------------------------------
end


update cob_conta..cb_solicitud_reportes_reg
set   sr_status = 'P'
where sr_reporte = @w_reporte
and   sr_status = 'I'

if @@error != 0
begin
	select @w_error = 710002
	goto ERROR_PROCESO
end

SALIDA_PROCESO:
return 0

ERROR_PROCESO:
     select @w_msg = isnull(@w_msg, 'ERROR GENRAL DEL PROCESO')
     exec cob_conta_super..sp_errorlog
     @i_fecha_fin     = @i_param1,
     @i_fuente        = @w_sp_name,
     @i_origen_error  = @w_error,
     @i_descrp_error  = @w_msg
go
*/
--LPO CDIG Se comenta porque Cobis Language no soporta XML FIN
RETURN 0
GO
