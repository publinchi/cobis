/************************************************************************/
/*      Archivo:                operdef.sp                              */
/*      Stored procedure:       sp_operacion_def                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces                                */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Transmision definitiva en la creacion/actualizacion de una op   */
/*      llamada interna de sps                                          */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */  
/*     15/04/2019       A. Giler        Operaciones Grupales            */
/*     15/09/2022       K. Rodríguez    R193060 Instruc. with nolock    */
/*                                      a consulta de préstamos hijos   */
/*     19/09/2022       K. Rodríguez    R194789 Se comenta pasoDef grup.*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_operacion_def')
	drop proc sp_operacion_def
go
create proc sp_operacion_def
	@s_date			datetime = null,
	@s_sesn 		int      = null,    
	@s_user			login    = null,
	@s_ofi 			smallint = null,
	@t_trn          INT      = NULL,
	@i_banco		cuenta   = null,
    @i_claseoper            cuenta   = 'A'

as
declare 
@w_sp_name              descripcion,
@w_return               int,
@w_error                int,
@w_commit               char(1),
@w_grupo                int,
@w_banco_sgte           cuenta,
@w_banco_hija           cuenta 


 
/* CARGAR VALORES INICIALES */
select
@w_sp_name = 'sp_operacion_def',
@w_commit  = 'N'

if @@trancount = 0 begin  
   select @w_commit = 'S'
   begin tran 
end  

exec @w_error   =sp_operacion_def_int
@s_date         = @s_date,
@s_sesn         = @s_sesn,    
@s_user	        = @s_user,
@s_ofi 	        = @s_ofi,
@i_banco        = @i_banco,
@i_claseoper    = @i_claseoper

if @w_error <> 0 goto ERROR
   
   
select @w_grupo  = op_grupo
from   ca_operacion 
where  op_banco = @i_banco 

/* -- KDR 13/10/2022 Se comenta seccion por manejo individual de paso a definitivas de op. grupales
--INI AGI
if @w_grupo > 0   --Pasar las operaciones hijas
begin
    select @w_banco_sgte = ''
    
    while 1=1
    begin
        set rowcount 1
        
        select @w_banco_hija = opt_banco
        from   ca_operacion_tmp with (nolock) -- KDR 15/09/2022 No bloqueo de tabla
        where  opt_ref_grupal = @i_banco 
        and    opt_banco     >  @w_banco_sgte
        order by  opt_banco 
        
        if @@rowcount = 0
            break
            
        set rowcount 0
        
        exec @w_error = sp_operacion_def
        @s_date  = @s_date,
        @s_sesn  = @s_sesn,    
        @s_user	 = @s_user,
        @s_ofi 	 = @s_ofi,
        @i_banco = @w_banco_hija        
        
        if @w_error !=0
            return  @w_error
            
        select @w_banco_sgte = @w_banco_hija  
        
    end
    
    --Operaciones Hijas que salen del Grupo
    select @w_banco_sgte = ''
    
    while 1=1
    begin
        set rowcount 1
        
        select @w_banco_hija = opt_banco
        from   ca_operacion_tmp with(nolock), ca_operacion with(nolock) -- KDR 15/09/2022 No bloqueo de tablas
        where  op_ref_grupal = @i_banco 
          and  op_banco      = opt_banco
          and  opt_ref_grupal is null 
        and    opt_banco     >  @w_banco_sgte
        order by  opt_banco 
        
        if @@rowcount = 0
            break
            
        set rowcount 0
        
        exec @w_error = sp_operacion_def
        @s_date  = @s_date,
        @s_sesn  = @s_sesn,    
        @s_user	 = @s_user,
        @s_ofi 	 = @s_ofi,
        @i_banco = @w_banco_hija        
        
        if @w_error !=0
            return  @w_error
            
        select @w_banco_sgte = @w_banco_hija  
        
    end
end
--FIN AGI 
*/
   

if @w_commit = 'S'begin 
   select @w_commit = 'N'
   commit tran    
end 
   
   
return 0

ERROR:
if @w_commit = 'S'begin 
   select @w_commit = 'N'
   rollback tran    
end 

exec cobis..sp_cerror
@t_debug='N',         
@t_file = null,
@t_from =@w_sp_name,   
@i_num = @w_error

return @w_error

go




