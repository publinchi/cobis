/********************************************************************/
/*   NOMBRE LOGICO:          sp_act_dist_geo                        */
/*   NOMBRE FISICO:          sp_act_dist_geo.sp                     */
/*   Producto:               Clientes                               */
/*   Disenado por:           Bruno Dueñas                           */
/*   Fecha de escritura:     11-Diciembre-2023                      */
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
/*    11/12/2023        BDU        Emision Inicial                  */
/*    29/12/2023        BDU        Ajustes manejo de errores        */
/*    04/01/2024        BDU        Toma en cuenta cl_negocio_cliente*/
/********************************************************************/
use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_act_dist_geo')
   drop proc sp_act_dist_geo 
go

create proc sp_act_dist_geo
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
   
select @w_sp_name = 'sp_act_dist_geo',
       @w_sp_msg  = ''


print 'Inicia proceso a las ' + convert(varchar, getdate(), 121)

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cobis..sp_act_dist_geo%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_error  = 808071 
   goto errores
end
  
begin try
   BEGIN TRAN
      --Actualizacion cl_negocio_cliente
      print 'Actualizando cl_negocio_cliente'
      set @w_tabla = 'cobis..cl_negocio_cliente'
      
      select *
      from cobis..cl_ciudad_hmg
      INNER JOIN cobis..cl_negocio_cliente on  ch_ciudad_actual = nc_municipio
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_negocio_cliente
      set nc_municipio = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = nc_municipio
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      
      select *
      from cobis..cl_parroquia_hmg
      INNER JOIN cobis..cl_negocio_cliente on ph_parroquia_actual = nc_colonia
      and ph_parroquia_actual <> ph_parroquia_nueva
      
      update cobis..cl_negocio_cliente
      set nc_colonia = ph_parroquia_nueva
      from cobis..cl_parroquia_hmg
      where ph_parroquia_actual = nc_colonia
      and ph_parroquia_actual <> ph_parroquia_nueva
      
   
      --Actualizacion cl_direcciones
      print 'Actualizando cl_direccion'
      set @w_tabla = 'cobis..cl_direccion'
      
      select *
      from cobis..cl_ciudad_hmg
      INNER JOIN cobis..cl_direccion on  ch_ciudad_actual = di_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_direccion
      set di_ciudad = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = di_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      
      select *
      from cobis..cl_ciudad_hmg
      INNER JOIN cobis..cl_direccion on  ch_ciudad_actual = di_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_direccion
      set di_parroquia = ph_parroquia_nueva
      from cobis..cl_parroquia_hmg
      where ph_parroquia_actual = di_parroquia
      and ph_parroquia_actual <> ph_parroquia_nueva
      
      
      --Actualizacion cobis..cl_codigo_postal
      print 'Actualizando cobis..cl_codigo_postal'
      set @w_tabla = 'cobis..cl_codigo_postal'
      
      select *
      from cobis..cl_ciudad_hmg 
      inner join cobis.dbo.cl_codigo_postal on ch_ciudad_actual = cp_municipio
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_codigo_postal
      set cp_municipio = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = cp_municipio
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      
      select *
      from cobis..cl_parroquia_hmg 
      inner join cobis.dbo.cl_codigo_postal on ph_parroquia_actual = cp_colonia
      and ph_parroquia_actual <> ph_parroquia_nueva
      
      update cobis..cl_codigo_postal
      set cp_colonia = ph_parroquia_nueva
      from cobis..cl_parroquia_hmg
      where ph_parroquia_actual = cp_colonia
      and ph_parroquia_actual <> ph_parroquia_nueva
       
       
      
      --Actualizacion cl_beneficiario_seguro
      print 'Actualizando cl_beneficiario_seguro'
      set @w_tabla = 'cobis..cl_beneficiario_seguro'
      
      select *
      from cobis..cl_ciudad_hmg
      inner join cobis..cl_beneficiario_seguro on ch_ciudad_actual = bs_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_beneficiario_seguro
      set bs_ciudad = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = bs_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      select *
      from cobis..cl_parroquia_hmg
      inner join cobis..cl_beneficiario_seguro on ph_parroquia_actual = bs_parroquia
      and ph_parroquia_actual <> ph_parroquia_nueva
      
      update cobis..cl_beneficiario_seguro
      set bs_parroquia = ph_parroquia_nueva
      from cobis..cl_parroquia_hmg
      where ph_parroquia_actual = bs_parroquia
      and ph_parroquia_actual <> ph_parroquia_nueva
      
      
      --Actualizacion cl_ente
      print 'Actualizando cl_ente'
      set @w_tabla = 'cobis..cl_ente'
      
      select *
      from cobis..cl_ciudad_hmg
      inner join cobis.dbo.cl_ente on ch_ciudad_actual = p_ciudad_nac
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_ente
      set p_ciudad_nac = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = p_ciudad_nac
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      
      select *
      from cobis..cl_ciudad_hmg
      inner join cobis.dbo.cl_ente on ch_ciudad_actual = en_ciudad_emision
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cobis..cl_ente
      set en_ciudad_emision = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = en_ciudad_emision
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      
      --Actualizacion cr_tramite
      print 'Actualizando cr_tramite'
      set @w_tabla = 'cob_credito..cr_tramite'
      
      select *
      from cobis..cl_ciudad_hmg
      inner join cob_credito..cr_tramite on ch_ciudad_actual = tr_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cob_credito..cr_tramite
      set tr_ciudad = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = tr_ciudad
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      select *
      from cobis..cl_ciudad_hmg
      inner join cob_credito..cr_tramite on ch_ciudad_actual = tr_ciudad_destino
      and ch_ciudad_actual <> ch_ciudad_nueva
      
      update cob_credito..cr_tramite
      set tr_ciudad_destino = ch_ciudad_nueva
      from cobis..cl_ciudad_hmg
      where ch_ciudad_actual = tr_ciudad_destino
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

