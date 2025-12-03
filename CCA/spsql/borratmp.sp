/************************************************************************/
/*      Archivo:                borratmp.sp                             */
/*      Stored procedure:       sp_borrar_tmp                           */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces                                */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                           */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Eliminar las tablas temporales de una operacion                 */
/************************************************************************/
/* 05/05/2017        M. Custode           Eliminaciond el conver tramite*/
/*                                        por i_banco                   */
/* 15/04/2019        A. Giler             Operaciones Grupales          */
/* 14/09/2022        K. Rodríguez         R193060 Instruc. with nolock  */
/*                                        a consulta de préstamos hijos */
/* 06/03/2025        K.  Rodriguez        R256950(235424) Optimiz. bucle*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_borrar_tmp')
    drop proc sp_borrar_tmp
go
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
---NR000353 partiendo de la verion inical
create proc sp_borrar_tmp
        @s_user                   login        = null,
        @s_term                   varchar(30)  = null, 
        @s_sesn                   int          = null,
		@t_trn                    INT          = NULL,
        @i_desde_cre              char(1)      = null,
        @i_banco                  cuenta       = null,
        @i_crea_ext               char(1)      = null,
        @o_msg_msv                varchar(255) = null out

as
declare @w_operacionca            int ,
        @w_error                  int ,
        @w_sp_name                descripcion,
        @w_return                 int,
        @w_grupo                  int,
        @w_banco_sgte             cuenta,
        @w_banco_hija             cuenta,
        @w_cont                   smallint
                                  
begin tran

if @i_desde_cre = 'S'
   select @i_banco = op_banco
from ca_operacion
where op_banco = @i_banco


exec @w_return =  sp_borrar_tmp_int
@s_user      = @s_user,
@s_sesn      = @s_sesn,
@i_banco     = @i_banco

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end    

--INI AGI
select @w_grupo = op_grupo
from ca_operacion  with (nolock)
where op_banco = @i_banco
and op_grupal = 'S'
and op_ref_grupal is null

if @w_grupo > 0   --Pasar las operaciones hijas
begin

   if object_id('tempdb..#tmp_ops_hijas') is not null
      drop table #tmp_ops_hijas
	  
   create table #tmp_ops_hijas (
      op_banco cuenta
   )
   
   insert into #tmp_ops_hijas
   select op_banco
   from   ca_operacion with (nolock)
   where  op_ref_grupal = @i_banco 
   order by  op_banco
   
   select @w_cont = count(1) 
   from #tmp_ops_hijas
   
   while @w_cont > 0 
   begin
   
      select top 1 
	  @w_banco_hija = op_banco
      from #tmp_ops_hijas
	  order by  op_banco 
	  
      exec @w_error = sp_borrar_tmp
      @s_user      = @s_user,
      @s_sesn      = @s_sesn,
      @i_banco     = @w_banco_hija        
      
      if @w_error != 0
         return  @w_error
	  
      delete #tmp_ops_hijas where op_banco = @w_banco_hija
      set @w_cont = (select count(1) from #tmp_ops_hijas)
   
   end
	  
end
--FIN AGI 

commit tran

return 0

ERROR:
if @i_crea_ext is null
begin
	exec cobis..sp_cerror
	@t_debug  = 'N', 
	@t_file   = null,
	@t_from   = @w_sp_name,
	@i_num    = @w_error
	
	return @w_error
end
ELSE
begin
   select @o_msg_msv = 'Error en Borrado de Temporales ' + @w_sp_name
   return @w_error
end
