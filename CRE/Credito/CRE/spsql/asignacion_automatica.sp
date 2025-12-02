/************************************************************************/
/*  Archivo:                asignacion_automatica.sp                    */
/*  Stored procedure:       sp_asignacion_automatica                    */
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

if exists (select 1 from sysobjects where name = 'sp_asignacion_automatica' and type = 'P')
   drop proc sp_asignacion_automatica
go



create proc [dbo].[sp_asignacion_automatica] (
@s_ofi                        int        = null,
@i_cliente                    int        = null,                     
@i_campana                    int        = null,
@i_oficina                    int        = null,
@i_desde                      varchar(50)= null,
@o_asignado_a                 varchar(60) out,    
@o_msg                        descripcion out)

as 
declare

@w_fecha_proceso              datetime,
@w_matriz_calculo             catalogo,
@w_segmento                   int,
@w_mercado                    char(1),
@w_cargo                      varchar(60),
@w_cliente                    int,
@w_campana                    int,
@w_oficial                    int,
@w_cod_funcionario            int,
@w_resultado_matriz           int,
@w_error                      int,
@w_oficina                    int

/*DETERMINAR LA FECHA DE PROCESO*/
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso


select @w_matriz_calculo = ma_matriz                  
from cob_cartera..ca_matriz    
where ma_matriz = 'ASIG_AUTO'

select @w_cliente = @i_cliente

select @w_segmento = mo_segmento, @w_mercado = mo_mercado_objetivo 
from cobis..cl_mercado_objetivo_cliente 
where mo_ente = @w_cliente

/*TIPO DE CARGO*/
exec @w_error = cob_cartera..sp_matriz_valor                   
@i_matriz     = @w_matriz_calculo,            
@i_fecha_vig  = @w_fecha_proceso,             
@i_eje1       = @i_campana ,
@i_eje2       = @w_segmento,
@i_eje3       = @w_mercado ,
@o_valor      = @w_resultado_matriz out,      
@o_msg        = @o_msg out                    
          
if @w_error <>0 return @w_error    

select @w_cargo = y.valor from cobis..cl_tabla x, cobis..cl_catalogo y
where x.codigo = y.tabla
and x.tabla = 'cl_cargo_campana'
and y.codigo = @w_resultado_matriz

if @w_cargo = 'EJECUTIVO DE MICROFINANZAS' begin

   select @w_oficial = en_oficial 
   from cobis..cl_ente 
   where en_ente = @w_cliente
    
   select @w_cod_funcionario = oc_funcionario 
   from cobis..cc_oficial 
   where oc_oficial = @w_oficial

   select @o_asignado_a = fu_login 
   from cobis..cl_funcionario 
   where fu_funcionario = @w_cod_funcionario
    
end


if @i_desde = 'carga_masiva' begin

   if @w_cargo = 'DIRECTOR DE OFICINA' begin
   
      select @o_asignado_a = fu_login
      from cobis..cl_funcionario 
      where fu_cargo = @w_resultado_matriz 
      and fu_oficina = @i_oficina  
     
   end
   
end else begin

   if @w_cargo = 'DIRECTOR DE OFICINA' begin
   
      select @w_oficina = en_oficina_prod 
      from cobis..cl_ente 
      where en_ente = @w_cliente
      
      select @o_asignado_a = fu_login
      from cobis..cl_funcionario 
      where fu_cargo = @w_resultado_matriz 
      and fu_oficina = @w_oficina  
     
   end
end
      
return 0

GO
