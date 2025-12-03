/************************************************************************/
/*Archivo             :   mensajef.sp                                   */
/*Stored procedure    :   sp_mensaje_extracto                           */
/*Base de datos       :   cob_cartera                                   */
/*Producto            :   Credito y Cartera                             */
/*Disenado por        :   Elcira Pelaez                                 */
/*Fecha de escritura  :   jul.2005                                      */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*"MACOSA"                                                              */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/
/*                      PROPOSITO                                       */
/* Actualiza los registros de la tabla ca_info_extracto enel campo      */
/* ie_referencia                                                        */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR             CAMBIOS                        */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_mensaje_extracto')
   drop proc sp_mensaje_extracto
go

create proc sp_mensaje_extracto
@i_fecha_ini    datetime,
@i_fecha_fin    datetime

as

declare 
   
   @w_return                  int,
   @w_sp_name                 descripcion,
   @w_op_operacion            int,
   @w_sec                     int,
   @w_banco                   cuenta,
   @w_oficina_central         int,
   @w_error                   int,
   @w_sujeto_credito          catalogo,
   @w_tipo_productor          varchar(24),
   @w_tipo_banca              catalogo,
   @w_mercado                 catalogo,
   @w_mercado_objetivo        catalogo,
   @w_cod_linea               catalogo,
   @w_destino_economico       catalogo,
   @w_oficina                 smallint,
   @w_zona                    smallint,
   @w_regional                smallint,
   @w_estado_op               tinyint,
   @w_mensaje                 varchar(255)
   


--  CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_mensaje_extracto'
 
select 
@w_sujeto_credito     =   mf_sujeto_credito,   
@w_tipo_productor     =   mf_tipo_productor,   
@w_tipo_banca         =   mf_tipo_banca,       
@w_mercado            =   mf_mercado,          
@w_mercado_objetivo   =   mf_mercado_objetivo, 
@w_cod_linea          =   mf_cod_linea,        
@w_destino_economico  =   mf_destino_economico,
@w_oficina            =   mf_oficina,          
@w_zona               =   mf_zona,             
@w_regional           =   mf_regional,         
@w_estado_op          =   mf_estado_op,        
@w_mensaje            =   mf_mensaje           
from ca_mensaje_facturacion
where mf_fecha_ini_facturacion = @i_fecha_ini
and mf_fecha_fin_facturacion   = @i_fecha_fin


if  @w_sujeto_credito    is null
and @w_tipo_productor    is null
and @w_tipo_banca        is null
and @w_mercado           is null
and @w_mercado_objetivo  is null
and @w_cod_linea         is null
and @w_destino_economico is null
and @w_oficina           is null
and @w_zona              is null
and @w_regional          is null
and @w_estado_op         is null
begin
   update ca_info_extracto
   set ie_referencia =  @w_mensaje
   where ie_numero_obligacion >= ''
end   
else
begin
 update ca_info_extracto
 set ie_referencia =  @w_mensaje
 where (ie_sujeto_credito     = @w_sujeto_credito       or @w_sujeto_credito        is null)
 and   (ie_tipo_productor     = @w_tipo_productor       or  @w_tipo_productor       is null)
 and   (ie_tipo_banca         = @w_tipo_banca           or  @w_tipo_banca           is null)
 and   (ie_mercado            = @w_mercado              or  @w_mercado              is null)
 and   (ie_mercado_objetivo   = @w_mercado_objetivo     or  @w_mercado_objetivo     is null)
 and   (ie_cod_linea          = @w_cod_linea            or  @w_cod_linea            is null)
 and   (ie_destino_economico  = @w_destino_economico    or  @w_destino_economico    is null)
 and   (ie_zona               = @w_zona                 or  @w_zona                 is null)
 and   (ie_regional           = @w_regional             or  @w_regional             is null)
 and   (ie_estado_op          = @w_estado_op            or  @w_estado_op            is null)
 and   (ie_cod_oficina        = @w_oficina              or  @w_oficina              is null)
 
end
            
 
return 0
 
go
 
 
