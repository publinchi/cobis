/************************************************************************/
/*   Archivo:              teller_consulta_operacion.sp                 */
/*   Stored procedure:     sp_teller_consulta_operacion                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   04/08/2021                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Obtener el estado actual de una operacion de cartera para Teller   */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 04/08/2021     G. Fernandez       Versión inicial                    */
/* 12/08/2021     Ricardo Rincon     Se agregan a la consulta           */
/*                                   la identificacion y nombre         */
/************************************************************************/

USE cob_cartera
GO

if exists(select 1 from sysobjects where name ='sp_teller_consulta_operacion')
   drop proc sp_teller_consulta_operacion

go

CREATE PROC sp_teller_consulta_operacion
(
   @s_sesn                 int          = null,
   @s_date                 DATETIME     = null,
   @s_user                 login        = null,
   @s_culture              varchar(10)  = null,
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_org                  char(1)      = null,
   @s_srv                  varchar (30) = null,
   @s_ofi                  smallint     = null,
   @s_lsrv                 varchar (30) = null,
   @s_rol                  int          = null,
   @t_trn                  int          = null,
   @i_banco                cuenta       = null
)
as declare
    @w_sp_name             descripcion,
    @w_error               int

---  VARIABLES DE TRABAJO
select @w_sp_name = 'sp_teller_consulta_operacion'

-- Validación transacción
if @t_trn <> 77547 
begin        
   select @w_error = 141018 -- Error en codigo de transaccion
   goto ERROR
end

-- Obtenecion de estado de la operacion, identificación y nombre del titular
SELECT 
'Estado' = op_estado,
'Identificacion' = en_ced_ruc,
'Nombre' = en_nomlar
FROM cob_cartera..ca_operacion
left join cobis..cl_ente on en_ente = op_cliente
WHERE op_banco = @i_banco

if @@rowcount =  0
begin
   select @w_error    = 725054 ---- 'Error, no existe la operacion
   goto ERROR
end

return 0

ERROR:
exec cobis..sp_cerror
     @t_debug  = 'N',
     @t_file   = null,
     @t_from   = @w_sp_name,
     @i_num    = @w_error
return @w_error 

GO

