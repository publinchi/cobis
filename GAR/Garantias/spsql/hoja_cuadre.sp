/*************************************************************************/
/*   Archivo:              hoja_cuadre.sp                                */
/*   Stored procedure:     sp_hoja_cuadre_gar                            */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_hoja_cuadre_gar') IS NOT NULL
    DROP PROCEDURE dbo.sp_hoja_cuadre_gar
go
create proc sp_hoja_cuadre_gar ( 
        @i_opcion      char(1),
        @i_user        varchar(20),
        @i_fecha       datetime,        
        @i_fin_mes     char(1),
		@s_user        login    = null,   --Miguel Aldaz 26/Feb/2015
		@s_term        varchar(30)   = null --Miguel Aldaz 26/Feb/2015
)

as
declare @w_sp_name         descripcion,
        @w_fecha           datetime,
        @w_min_fecha       datetime,        
        @w_max_fecha       datetime,
        @w_error           int,
        @w_mensaje         varchar(255),
        @w_return          int,
        @w_filial          smallint,
        @w_codigo_externo  varchar(64),
        @w_oficina         smallint,
        @w_ofconta         smallint,
        @w_moneda          tinyint,
        @w_tipo_custodia   varchar(10),
        @w_tipo_cca        varchar(10),
        @w_concepto        varchar(10),
        @w_maduracion      char(2),
        @w_estado          tinyint,
        @w_cuenta_aux      varchar(20),
        @w_cuenta_aux1     varchar(20),
        @w_cuenta_aux2     varchar(20),
        @w_producto        varchar(3),
        @w_cuenta_final    varchar(34),
        @w_valor           money,
        @w_periodo         tinyint

select @w_sp_name = 'sp_hoja_cuadre_gar'
select @w_fecha = @i_fecha --convert(varchar,getdate(), 101)

   
   select @w_cuenta_aux1 = pa_char
   from cobis..cl_parametro
   where pa_producto = 'GAR'
   and pa_nemonico = 'STCON'

---- Parametro que contine string contable en casod e contabilizar por tipo de cartera de la oepracion asociada   
   select @w_cuenta_aux2 = pa_char
   from cobis..cl_parametro
   where pa_producto = 'GAR'
   and pa_nemonico = 'STCO1'

   
if @i_opcion = 'P'  --Procesar
begin

   select @w_min_fecha = min(hc_fecha)
     from cob_custodia_his..cu_det_hcuadre

   select @w_max_fecha = max(hc_fecha)
     from cob_custodia_his..cu_det_hcuadre
  
   --truncate table ca_det_hcuadre
   delete cob_custodia_his..cu_det_hcuadre
    where hc_fecha >= @w_min_fecha
      and hc_fecha <= @i_fecha
      and (hc_fin_mes = 'N' or (hc_fin_mes = 'S' and @i_fecha = @w_max_fecha))      
  
   if @@error != 0 
   begin
      select @w_error = 5
      select @w_mensaje = 'Error al eliminar datos de ca_det_hcuadre opcion T'
      goto ERROR_INI
   end
   
   if exists (select 1 
                from cob_custodia_his..cu_det_hcuadre
               where hc_fecha = @i_fecha)
   begin
      select @w_error = 6
      select @w_mensaje = 'Error: Existen datos con la misma fecha!!'
      goto ERROR_INI
   end               
               
   --- 
--   declare crs_operacion insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
   declare crs_operacion cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
    select cu_filial,cu_codigo_externo,  cu_sucursal, cu_moneda, cu_tipo, cu_tipo_cca,cu_valor_actual  ------,cu_valor_compartida
      from cob_custodia..cu_custodia a,cob_custodia..cu_tipo_custodia
     where cu_estado in ('V')
       and cu_tipo = tc_tipo 
       and  tc_contabilizar = 'S'
       for read only
      open crs_operacion   
     fetch crs_operacion into @w_filial,@w_codigo_externo, @w_oficina, @w_moneda, @w_tipo_custodia, @w_tipo_cca,@w_valor
           
   while @@FETCH_STATUS != -1   
   begin

     select @w_mensaje = null,@w_error = 0

     select @w_cuenta_aux = @w_cuenta_aux1


     select @w_ofconta = isnull(re_ofconta,0)      
       from cob_conta..cb_relofi
      where re_filial  = @w_filial
        and re_empresa = @w_filial
        and re_ofadmin = @w_oficina

     
     select @w_cuenta_final = null
     exec @w_return = sp_resuelve_cuenta          
	  @i_filial        = @w_filial,                   
	  @i_moneda        = @w_moneda,                   
	  @i_tipo_custodia    = @w_tipo_custodia,                    
	  @i_tipo_cca      = @w_tipo_cca,                   
	  @i_cuenta        = @w_cuenta_aux,                   
	  @o_cuenta_final  = @w_cuenta_final out,         
	  @o_error         = @w_mensaje      out   
     if @w_return != 0
     begin
       select @w_mensaje = 'Error en sp_resuelve_cuenta ' + @w_cuenta_aux + ' ' + @w_cuenta_final + ' Codigo externo: ' + @w_codigo_externo + ' Tipo Custodia: ' + @w_tipo_custodia + ' Tipo Cartera: ' + @w_tipo_cca 
       select @w_error = 20
       goto ERROR
     end
 

     --validar que exista cuenta contable  
     if not exists (select 1 
                      from cob_conta..cb_cuenta 
                     where cu_empresa = 1
                       and cu_cuenta = @w_cuenta_final)
     begin
       select @w_mensaje = 'No existe cuenta contable: ' + @w_cuenta_final +  'Codigo externo: ' + @w_codigo_externo + ' Tipo Custodia: ' + @w_tipo_custodia + ' Tipo Cartera: ' + @w_tipo_cca
       select @w_error = 30
       goto ERROR
     end


   ERROR:        

     insert cob_custodia_his..cu_det_hcuadre (hc_filial,hc_fecha, hc_codigo_externo, hc_oficina, hc_moneda, hc_tipo_custodia,hc_tipo_cca,hc_monto, hc_cuenta, hc_fin_mes,hc_error)
     values (@w_filial,@i_fecha, @w_codigo_externo, @w_ofconta, @w_moneda, @w_tipo_custodia, @w_tipo_cca,@w_valor, @w_cuenta_final, @i_fin_mes,@w_error)
     if @@error != 0
     begin
       select @w_mensaje = 'Error en ingreso cu_det_hcuadre. Cuenta:' + @w_cuenta_final + ' Codigo externo: ' + @w_codigo_externo + ' Tipo Custodia:' + @w_tipo_custodia + ' Tipo_cartera: ' + @w_tipo_cca 
       select @w_error = 40
       goto ERROR    
     end
   
   if @w_error > 0
      begin   
-----      print 'ERROR!!!! %1!', @w_mensaje
      exec sp_errorlog           
           @i_fecha       = @w_fecha,           
           @i_error       = @w_error,           
           @i_usuario     = @i_user,           
           @i_tran        = 7000,           
           @i_tran_name   = @w_sp_name,           
           @i_rollback    = 'N',           
           @i_cuenta      = 'HCUADRE',           
           @i_descripcion = @w_mensaje   
     end
       
     SIGUIENTE:
    
     fetch crs_operacion into @w_filial,@w_codigo_externo, @w_oficina, @w_moneda, @w_tipo_custodia, @w_tipo_cca, @w_valor
   end
   close crs_operacion   
   deallocate crs_operacion

end

if @i_opcion = 'L'  --Procesar
begin
   declare crs_operacion cursor for
   select   hc_filial, hc_codigo_externo, hc_oficina, hc_moneda, hc_tipo_custodia,hc_tipo_cca,hc_monto
   from cob_custodia_his..cu_det_hcuadre
   where hc_error > 0
   FOR  UPDATE OF hc_cuenta, hc_error
   open crs_operacion  
   fetch crs_operacion into @w_filial,@w_codigo_externo, @w_oficina, @w_moneda, @w_tipo_custodia, @w_tipo_cca,@w_valor
           
   while @@FETCH_STATUS != -1   
   begin
     select @w_mensaje = null,@w_error = 0

     select @w_cuenta_aux = @w_cuenta_aux1


     select @w_cuenta_final = null
     exec @w_return = sp_resuelve_cuenta          
	  @i_filial        = @w_filial,                   
	  @i_moneda        = @w_moneda,                   
	  @i_tipo_custodia    = @w_tipo_custodia,                    
	  @i_tipo_cca      = @w_tipo_cca,                   
	  @i_cuenta        = @w_cuenta_aux,                   
	  @o_cuenta_final  = @w_cuenta_final out,         
	  @o_error         = @w_mensaje      out   
     if @w_return != 0
     begin
       select @w_mensaje = 'Error en sp_resuelve_cuenta ' + @w_cuenta_aux + ' ' + @w_cuenta_final + ' Codigo externo: ' + @w_codigo_externo + ' Tipo Custodia: ' + @w_tipo_custodia + ' Tipo Cartera: ' + @w_tipo_cca 
       select @w_error = 20
       goto ERROR1
     end
 

     --validar que exista cuenta contable  
     if not exists (select 1 
                      from cob_conta..cb_cuenta 
                     where cu_empresa = 1
                       and cu_cuenta = @w_cuenta_final)
     begin
       select @w_mensaje = 'No existe cuenta contable: ' + @w_cuenta_final +  'Codigo externo: ' + @w_codigo_externo + ' Tipo Custodia: ' + @w_tipo_custodia + ' Tipo Cartera: ' + @w_tipo_cca
       select @w_error = 30
       goto ERROR1
     end

             update cob_custodia_his..cu_det_hcuadre
             set hc_cuenta = @w_cuenta_final,
                 hc_error  = @w_error
             WHERE CURRENT OF crs_operacion

   ERROR1: 
   if @w_error > 0
      begin   
-----      print 'ERROR!!!! %1!', @w_mensaje
      exec sp_errorlog           
           @i_fecha       = @w_fecha,           
           @i_error       = @w_error,           
           @i_usuario     = @i_user,           
           @i_tran        = 7000,           
           @i_tran_name   = @w_sp_name,           
           @i_rollback    = 'N',           
           @i_cuenta      = 'HCUADRE',           
           @i_descripcion = @w_mensaje   
     end


     SIGUIENTE1:
    
     fetch crs_operacion into @w_filial,@w_codigo_externo, @w_oficina, @w_moneda, @w_tipo_custodia, @w_tipo_cca, @w_valor
   end
   close crs_operacion   
   deallocate crs_operacion

end

if @i_opcion = 'D'  --Depurar
begin
   select @w_min_fecha = min(hc_fecha)
     from cob_custodia_his..cu_det_hcuadre
     
   if @i_fecha > (select fp_fecha
     from cobis..ba_fecha_proceso)
   begin 
      select @w_error = 4
      select @w_mensaje = ' Fecha ingresada mayor a fecha proceso. No se puede inciar depuracion '
      goto ERROR_INI
   end
   
   select @w_fecha = dateadd(mm, -3, @i_fecha)
   
   delete cob_custodia_his..cu_det_hcuadre
    where hc_fecha >= @w_min_fecha
      and hc_fecha <= @w_fecha
      and hc_fin_mes = 'S'

   if @@error != 0 begin
      select @w_error = 5
      select @w_mensaje = ' Error al eliminar datos de cu_det_hcuadre opcion D '
      goto ERROR_INI
   end
end

return 0

ERROR_INI:
   print 'ERROR!!!! ' + @w_mensaje
   exec sp_errorlog
        @i_fecha       = @w_fecha,
        @i_error       = @w_error,
        @i_usuario     = @i_user,
        @i_tran        = 7000,
        @i_tran_name   = @w_sp_name,
        @i_rollback    = 'N',
        @i_cuenta      = 'HCUADRE',
        @i_descripcion = @w_mensaje
go