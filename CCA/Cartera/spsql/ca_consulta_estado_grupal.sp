/************************************************************************/ 
/*    ARCHIVO:         sp_consulta_estado_grupal.sp               	    */ 
/*    NOMBRE LOGICO:   ca_consulta_estado_grupal                        */ 
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Obtener el estado del prestamo grupal consultando el estado	        */ 
/*  de cada una de las operaciones hijas                                */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 26/04/2021    G. Fernandez	 Versión Inicial                        */
/* 21/08/2023    Kevin Rodríguez S873644 Se valida que el tramite es una*/
/*                               renovación para actualiza el estado    */
/* 25/08/2023    G. Fernandez    R213766 Act. consulta por renovación   */
/* 06/12/2023    Kevin Rodríguez R220933 No considerae estado Anulado   */
/************************************************************************/ 

USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_consulta_estado_grupal')
   drop proc sp_consulta_estado_grupal
go

CREATE PROC sp_consulta_estado_grupal
(
@i_operacion                 int   = NULL,  -- numero de prestamo
@o_estado_grupo              int   output	-- salida del estado de prestamo grupal     
)
as

declare 
@w_operacionca             int,	  
@w_estado_hija             int,
@w_estado_aux              int,
@w_estado_padre            int,
@w_banco                   varchar(25),
@w_error                   int,
@w_sp_name                 varchar(25),
@w_return                  int,
@w_tr_tipo                 char(1)

select @w_sp_name = 'sp_consulta_estado_grupal'

--Validacion y obtencion de Datos de operaciones Grupales
select @w_operacionca  = op_operacion,
       @w_estado_padre = op_estado,
       @w_banco	       = op_banco,
       @w_tr_tipo      = tr_tipo
from   ca_operacion with(nolock), cob_credito..cr_tramite
where  op_operacion = @i_operacion
and    op_grupal='S'
and    op_tramite = tr_tramite

if @@rowcount = 0
begin
    select @w_error =  710201 
    goto ERROR
end

if @w_tr_tipo in ('R') and exists (select 1 
                                   from ca_operacion with(nolock), ca_desembolso with(nolock)
                                   where op_ref_grupal = @w_banco
								   and op_operacion    = dm_operacion 
								   and op_estado = 0)
begin
   select @w_estado_aux = @w_estado_padre
   goto RESULTADO
end

--Obtener el minimo secuencial de Operaciones hijas
select @w_operacionca = min(op_operacion)
from ca_operacion with (nolock)
where op_grupal='S'
and op_ref_grupal = @w_banco

-- Validacion de existencia de operacion hija
while @w_operacionca is not null
begin
    --Obtener estado de operacion hija	
	select @w_estado_hija = op_estado 
	from ca_operacion with (nolock)
	WHERE op_grupal = 'S'
	and op_operacion = @w_operacionca
	
	--Valida que el estado de la operacion hija no este dentro de (NO VIGENTE, CANCELADO o ANULADO)
	if(@w_estado_hija NOT IN(0, 3, 6))
	begin
		select @w_estado_aux = 66
		goto RESULTADO
	end
	else
	begin
		select @w_estado_aux = @w_estado_padre
	end
	
	--Recorre a la siguiente operacion hija	
	select @w_operacionca = min(op_operacion)
    from ca_operacion with (nolock)
    where op_grupal='S'
    and op_ref_grupal = @w_banco
	and op_operacion > @w_operacionca
end
	
RESULTADO:
select @o_estado_grupo = @w_estado_aux
	
return 0	
	
ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_from  = @w_sp_name,
     @i_num   = @w_error
return @w_error
GO
