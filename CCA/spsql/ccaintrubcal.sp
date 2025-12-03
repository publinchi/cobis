/************************************************************************/
/*   Archivo             :       ccaintrubcal.sp                        */
/*   Stored procedure    :       sp_cca_interfaz_rubros_calculados      */
/*   Base de datos       :       cob_externos                           */
/*   Producto            :       Externos                                */
/*   Disenado por        :       Kevin Rodríguez                        */
/*   Fecha de escritura  :       Diciembre 2021                         */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/
/*                                 PROPOSITO                            */
/*   Este programa realiza el cálculo del valor de rubros calculados    */
/*   (Fuente temporal, FINCA creará la lógica de este programa)         */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*  Autor             Fecha          Comentario                         */
/*  Kevin Rodríguez   21/Dic/2021    Emisión inicial                    */
/*  Kevin Rodríguez   11/Mar/2021    Se quita la validación de elimina- */
/*                                   ción del SP  ya que el manejo de   */
/*                                   este programa será por parte de    */
/*                                   FINCA Impact                       */
/************************************************************************/

use cob_externos
go

if exists (select 1 from sysobjects where name = 'sp_cca_interfaz_rubros_calculados ')
   print 'El Stored Procedure sp_cca_interfaz_rubros_calculados ya existe..!'

ELSE
begin
exec ('create proc sp_cca_interfaz_rubros_calculados 
   /*@s_date                 datetime    = null,
   @s_user                 login        = null,
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_ofi                  smallint     = null,*/
   
   @i_rubro                catalogo,
   @i_tramite              int,
   @i_dias_frecuencia      smallint,
   @i_plazo                smallint,
   @i_frecuencia_cuotas    catalogo,
   @i_tipo_amortizacion    varchar(10),
   @i_es_grupal            varchar(10),
   @i_monto_solicitado     money,
   @i_monto_autorizado     money,
   @i_monto_financiado     money,
   @i_producto             catalogo,
   @i_tasa                 float,
   @i_tasa_IVA             float,
   @i_oficina              smallint,
   @i_fecha_desembolso     datetime,
   @i_tipo_persona         char(1),
   @i_fecha_nac            datetime,
   @i_destino              catalogo,
   @i_clase_cartera        catalogo,
   @i_nro_deudores         smallint,
   @i_nro_codeudores       smallint,
   @i_nro_fiadores         smallint,
   @i_pertenece_linea      char(1),
   @i_aprobado_linea       money,
   @i_disponible_linea     money,
   @i_tipo_solicitud       char(1),
   @i_moneda               tinyint,
   @i_fecha_ven            datetime,
   @i_nro_integrantes      smallint,
   
   @o_valor_rubro          money       = 0 out              
   
as declare
   @w_sp_name            varchar(30),
   @w_error              int, 
   @w_banco              cuenta   
   
select @o_valor_rubro = 20

return 0')
end

GO

	