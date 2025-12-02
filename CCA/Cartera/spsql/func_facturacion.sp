/********************************************************************/
/*   NOMBRE LOGICO:      func_facturacion.sp                        */
/*   NOMBRE FISICO:      sp_func_facturacion                        */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Septiembre 2023                            */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                           PROPOSITO                              */
/* Programa que realiza funciones varias relacionadas a facturación */
/* D: Identificar tipo documento tributario                         */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA          AUTOR            RAZON                           */
/*  28-Sep-2023    K. Rodriguez     Emision Inicial                 */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_func_facturacion')
   drop proc sp_func_facturacion
go

create proc sp_func_facturacion
@i_operacion           char(1),
@i_opcion              tinyint,
@i_tramite             int,
@o_tipo_doc_fiscal     varchar(3) = null out

as
declare 
@w_sp_name            descripcion,
@w_error              int,
@w_cliente            int, 
@w_operacionca        int,
@w_tramite            int,
@w_dato_adicion_nrc   smallint,
@w_dato_adicion_nrc_n smallint,
@w_dato_adicion_nrc_j smallint,
@w_emi_nrc            varchar(160),
@w_cod_act_cli        varchar(10),
@w_tipo_persona       char(1),
@w_cod_act_tr_padre   varchar(10),
@w_tiene_rubs_iva     char(1)

-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_func_facturacion',
       @w_error     = 0

select 
@w_operacionca = op_operacion,
@w_tramite     = op_tramite,
@w_cliente     = op_cliente
from  ca_operacion
where op_tramite = @i_tramite

-- Identificar tipo documento tributario (Facturacion Electrónica)
if @i_operacion = 'D'
begin

   if @i_opcion  = 0
   begin
      -- Párametro que define el número de dato adicional que contiene el NRC del cliente (Persona Natural)
      select @w_dato_adicion_nrc_n = pa_smallint
      from cobis..cl_parametro
      where pa_nemonico = 'DADNRC' 
      and pa_producto = 'CLI'
      set transaction isolation level read uncommitted
 
      -- Párametro que define el número de dato adicional que contiene el NRC del cliente (Persona Jurídica)
      select @w_dato_adicion_nrc_j = pa_smallint
      from cobis..cl_parametro
      where pa_nemonico = 'DANRCJ' 
      and pa_producto = 'CLI'
      set transaction isolation level read uncommitted
	  
      --Datos del cliente
      select @w_cod_act_cli  = en_actividad,
	         @w_tipo_persona = en_subtipo    -- Tipo persona [Natutal(P), Jurídica(C)]
      from cobis..cl_ente
      where en_ente = @w_cliente
	  
	  -- Asignaci+on ID de dato adicional dependiendo de si el ente es Persona Natural o Jurídica
      select @w_dato_adicion_nrc = case when @w_tipo_persona = 'P' 
                                        then @w_dato_adicion_nrc_n 
                                        else @w_dato_adicion_nrc_j end
										
      select @w_emi_nrc = de_valor
      from cobis..cl_dadicion_ente
      where de_ente = @w_cliente
      and de_dato = @w_dato_adicion_nrc

      -- Actividad Padre de destino económico del crédito
      select @w_cod_act_tr_padre = se_codActEc
      from cob_credito..cr_tramite with (nolock), cobis..cl_subactividad_ec
      where tr_tramite = @w_tramite
      and tr_cod_actividad = se_codigo
	     
      if exists (select 1 from ca_rubro_op with (nolock), ca_concepto, ca_categoria_rubro
                 where ro_operacion = @w_operacionca
                 and ro_valor > 0
                 and ro_concepto = co_concepto
                 and co_categoria = cr_codigo
                 and cr_codigo = 'A')
         select @w_tiene_rubs_iva = 'S'
	    
      -- Si el cliente posee como tipo de documento NRC, y si el destino económico del crédito es igual a la actividad económica del cliente
      -- y si además el crédito tiene al menos un rubro de tipo IVA con un monto mayor a cero, se establece como tipo de documento tributario 
      -- un CCF (Comprobante de Crédito Fiscal), caso contrario se establece un FCF(Factura Consumidro Final)
      select @o_tipo_doc_fiscal = case when @w_emi_nrc is not null 
                                            and @w_cod_act_cli = @w_cod_act_tr_padre 
                                            and @w_tiene_rubs_iva = 'S' 
                                       then 'CCF' 
                                       else 'FCF' end
   end   
   
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',    
@t_file  = null,
@t_from  = @w_sp_name,   
@i_num   = @w_error
  
return @w_error
go
