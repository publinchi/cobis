/********************************************************************/
/*   NOMBRE LOGICO:          sp_act_dist_geo_gar_ej                 */
/*   NOMBRE FISICO:          sp_act_dist_geo_gar_ej.sp              */
/*   Producto:               Garantias                              */
/*   Disenado por:           Bruno Dueñas                           */
/*   Fecha de escritura:     04-Enero-2024                          */
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
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                          PROPOSITO                               */
/********************************************************************/
/*   Este programa actualiza campos segun distribucion geografica SV*/
/********************************************************************/
/*                        MODIFICACIONES                            */
/********************************************************************/
/*      FECHA           AUTOR           RAZON                       */
/*    04/01/2024        BDU         Emision Inicial                 */
/*    11/01/2024        BDU         Correccion update               */
/********************************************************************/
use cob_custodia
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_act_dist_geo_gar_ej')
   drop proc sp_act_dist_geo_gar_ej 
go

create proc sp_act_dist_geo_gar_ej
as
declare 
   @w_num_error          int,
   @w_sp_name            varchar(32),
   @w_sp_msg             varchar(600),
   @w_tabla              varchar(100),
   @w_sarta              int,
   @w_batch              int,
   @w_retorno_ej         int,
   @w_error              int
   
select @w_sp_name = 'sp_act_dist_geo_gar_ej',
       @w_sp_msg  = ''


print 'Inicia proceso a las ' + convert(varchar, getdate(), 121)

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_custodia..sp_act_dist_geo_gar_ej%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_error  = 808071 
   goto errores
end
  
begin try
   BEGIN TRAN
      print 'Base de datos: cob_custodia'
      print 'Actualizando cu_custodia'
      set @w_tabla = 'cob_custodia..cu_custodia'
      
	  
	  select *
      from cobis..cl_ciudad_hmg
      inner join cob_custodia.dbo.cu_custodia on ch_ciudad_actual = cu_canton
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cob_custodia..cu_custodia
      set cu_canton = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = cu_canton
      and ch_ciudad_actual <> ch_ciudad_nueva
   
   COMMIT TRAN
end try
begin catch
   IF @@TRANCOUNT > 0
   begin
      ROLLBACK TRAN
   end
   select @w_sp_msg =  '[' + ERROR_PROCEDURE() + '] <' + @w_tabla + '> ' + convert(varchar, ERROR_NUMBER()) + ' - ' +  ERROR_MESSAGE(),
          @w_error = 1647266
   goto errores
end catch



print 'Termina proceso a las ' + convert(varchar, getdate(), 121)


return 0

--Control errores
errores:
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_sp_msg
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end


GO

