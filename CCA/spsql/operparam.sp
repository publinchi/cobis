/************************************************************************/
/*      Archivo:                operparam.sp                            */
/*      Stored procedure:       sp_operacion_param                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Lorena Regalado                         */
/*      Fecha de escritura:     Ene. 2017                               */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Inserta Operaciones asociadas a un parametro                    */
/*    FECHA            AUTOR              CAMBIO	                    */
/*    01-Jun-2022      G. Fernandez    Se comenta prints                */
/************************************************************************/  

use cob_cartera
go


IF OBJECT_ID ('dbo.sp_operacion_param') IS NOT NULL
	DROP PROCEDURE dbo.sp_operacion_param
GO

create proc sp_operacion_param (
    @i_operacion    char(1),
    @i_operacionca  INT ,
    @i_columna      varchar(30),
    @i_grupal       char(1)

)
as

declare
@w_sp_name               varchar(30),
@w_return                int

/*  Captura nombre de Stored Procedure  */
select  @w_sp_name   = 'sp_operacion_param'


if @i_operacion = 'I' 
begin

   /*  Creacion de Registros de tabla de parametros de Cartera  */
   
      IF @i_operacionca is NULL 
      BEGIN
	     --GFP se suprime print
         --PRINT 'Error debe enviar operacion de Cartera'
         return 724600
   
      END
   
      IF @i_columna is NULL 
      BEGIN
	     --GFP se suprime print
         --PRINT 'Error debe enviar columna de parametro'
         return 724601
   
      END
   

      insert into cob_cartera..ca_operacion_ext_tmp (
      oet_operacion, 	oet_columna,	oet_char,	oet_tinyint,
      oet_smallint, 	oet_int, 	oet_money, 	oet_datetime,
      oet_estado, 	oet_tinyInteger, oet_smallInteger,
      oet_integer, 	oet_float)
      values (
      @i_operacionca,      @i_columna,     @i_grupal, NULL,    
      NULL, NULL, NULL,
      NULL, NULL, NULL, NULL,
      NULL, NULL
      )
  
      if @@error != 0 return 724602
 


END

if @i_operacion = 'U' 
begin
   /*  Creacion de Registros de tabla de parametros de Cartera  */
   
      IF @i_operacionca is NULL 
      BEGIN
	     --GFP se suprime print
         --PRINT 'Error debe enviar operacion de Cartera'
         return 724600
   
      END
   
      IF @i_columna is NULL 
      BEGIN
	     --GFP se suprime print
         --PRINT 'Error debe enviar columna de parametro'
         return 724601
   
      END
   
   
      update cob_cartera..ca_operacion_ext_tmp 
      SET oet_char = @i_grupal
      WHERE oet_operacion = @i_operacionca
      AND oet_columna = @i_columna
      
        
      if @@error != 0 return 724602
 


END


return 0 


GO

