/************************************************************************/
/*	Archivo:		           registros.sp				                        */
/*	Stored procedure:	     sp_registros     		                        */
/*	Base de datos:		     cob_cartera			    	                     */
/*	Disenado por:  		  Xavier Maldonado			                     */
/*	Fecha de escritura:	  Abril 2004 				                        */
/************************************************************************/
/*				                 IMPORTANTE				                     */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	"MACOSA".							                                       */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus		         */
/*	usuarios sin el debido consentimiento por escrito de la 	            */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/
/*				                   PROPOSITO				                     */
/*	Consulta cuantos regristros se han procesado,no procesados y         */ 
/*  rechazadoa de       PIT                                             */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*		  FEB-2007           EPB               DEF-7917 BAC               */   
/************************************************************************/

use cob_cartera
go



if exists (select 1 from sysobjects where name = 'sp_registros')
   drop proc sp_registros
go

create proc sp_registros
--@i_fecha_proceso     	datetime,
@i_modo                 tinyint,
@i_lote                 int = 0,
@i_producto             int = 7,  --Por defecto Cartera
@o_reg_totales      	   int out,
@o_procesados           int out,
@o_no_procesados        int out



as
declare 
	@w_return         	   int,
	@w_sp_name        	   descripcion,
   @w_procesados           int,
   @w_reg_totales          int,
   @w_no_procesados        int


--CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_registros'


if @i_producto = 7  --Cartera
begin
   if @i_modo = 1   ---cadescon.sqr
   begin
      select @o_reg_totales = count(1) 
      from ca_desembolso_conv

      select @o_procesados = 0,
	     @o_no_procesados = 0
   end

   if @i_modo = 2   ---caplapit.sqr
   begin

     select @o_reg_totales = count(1) 
     from cob_cartera..ca_pag_masivos_temp

     select @o_procesados = count(1)
     from ca_abonos_masivos_generales 
     where mg_lote = @i_lote
     and mg_estado = 'P'
     and mg_terminal = 'PIT'

     select @o_no_procesados = count(1)
     from ca_abonos_masivos_generales 
     where mg_lote = @i_lote
     and mg_estado = 'I'
     and mg_terminal = 'PIT'

   end


   if @i_modo = 3   ---carplabs.sqr
   begin

     select @o_reg_totales = 0

     select @w_procesados = count(1)
     from cob_cartera..ca_plano_banco_segundo_piso 

     select @o_procesados = isnull(@w_procesados,0)
     select @o_no_procesados = 0
   end


   if @i_modo = 4   ---carplame.sqr
   begin
      select @o_reg_totales = 0
      select @w_procesados = count(1)
      from cob_cartera..ca_plano_mensual

      select @o_procesados = isnull(@w_procesados,0)
      select @o_no_procesados = 0
   end

   if @i_modo = 5   ---carplame.sqr
   begin

      select @o_reg_totales = 0

      select @w_procesados = count(1)
      from cob_cartera..ca_convenios_tmp

      select @o_procesados = isnull(@w_procesados,0)
      select @o_no_procesados = 0
   end
end --Cartera


if @i_producto = 21
begin
   if @i_modo = 0
   begin
      select @w_reg_totales = count(1)
      from cobis..cl_no_cobis_tarjeta_cred

      select @w_procesados = count(1)
      from cobis..cl_det_producto_no_cobis


      select @w_no_procesados = count(1)
      from cobis..cl_inconsis_tarjeta_cred


      select @o_reg_totales   = isnull(@w_reg_totales,0),
             @o_procesados    = isnull(@w_procesados,0),
             @o_no_procesados = isnull(@w_no_procesados,0)




   end
end  --Credito



return 0
go

