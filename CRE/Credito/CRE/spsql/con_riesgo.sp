/************************************************************************/
/*  Archivo:                con_riesgo.sp                               */
/*  Stored procedure:       sp_con_riesgo                               */
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

if exists (select 1 from sysobjects where name = 'sp_con_riesgo' and type = 'P')
   drop proc sp_con_riesgo
go

create proc sp_con_riesgo (
   @s_date              datetime    = null,
   @i_grupo             int         = null,
   @i_cliente           int         = null,     
   @i_modo              tinyint     = null, 
   @i_producto          catalogo    = null, 
   @i_toperacion        varchar(4)  = null, 
   @i_tipor             varchar(12) = null,
   @i_submodo           tinyint     = null,
   @i_rol               char(1)     = null,
   @i_tipo_op           char(1)     = null,
   @i_banco             varchar(24) = null
)
as
declare
   @w_today             datetime,     
   @w_return            int,          
   @w_sp_name           varchar(32),  
   @w_cliente           int,
   @w_producto          smallint    

select @w_sp_name = 'sp_con_riesgo'

if @i_modo is NULL 
begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2101001
   return 1 
 end

if @i_modo <> 4 
begin
   exec @w_return   = sp_riesgo_icl
   @s_date          = @s_date,
   @i_cliente       = @i_cliente,
   @i_grupo         = @i_grupo,
   @i_modo          = @i_modo,
   @i_tipor         = @i_tipor,
   @i_rol           = @i_rol,
   @i_tipo_op       = @i_tipo_op,
   @i_banco         = @i_banco,
   @i_producto      = @i_producto

   if @w_return != 0
      return @w_return
end

if @i_modo = 4
begin
   if @i_cliente is not null
   begin
       exec @w_return   = sp_cons_linea
       @s_date          = @s_date,
       @i_cliente       = @i_cliente    

       if @w_return != 0
          return @w_return
   end
   else
   begin
      exec @w_return    = sp_cons_linea_grupo
      @s_date           = @s_date,
      @i_grupo          = @i_grupo  

      if @w_return != 0
         return @w_return
   end
end

return 0

GO
