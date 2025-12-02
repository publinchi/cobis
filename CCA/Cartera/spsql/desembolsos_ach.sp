/************************************************************************/
/*      Archivo:                desembolsos_ach.sp                      */
/*      Stored procedure:       sp_desembolsos_ach                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Etna Johana Laguna R.                   */
/*      Fecha de escritura:     25-Feb-2002                             */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*    Este programa procesa la aplicacion de desembolsos de Cartera que */
/*    han sido generados por ACH					*/
/*                           MODIFICACIONES                             */
/*    FECHA           AUTOR            RAZON                            */
/*    25/Feb/2002     E. Laguna        Emision Inicial                  */
/*    26/Mar/2002     E. Laguna        Ajustes manejo de error          */
/*    24/Jun/2022     KDR              Nuevo parámetro sp_liquid        */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desembolsos_ach')
   drop proc sp_desembolsos_ach
go


create proc sp_desembolsos_ach(
       	@s_user		login = null,
       	@s_term		varchar(30) = null,
       	@s_date		datetime = null,
       	@s_srv		varchar(30) = null,
       	@s_lsrv		varchar(30) = null,
       	@s_ofi		smallint = null,
	@s_rol	 
	smallint = NULL,
	@s_org_err	char(1) = NULL,
	@s_error	int = NULL,
	@s_sev		tinyint = NULL,
	@s_msg		descripcion = NULL,
	@s_org		char(1) = NULL,
       	@t_debug	char(1) = 'N',
       	@t_file		varchar(10) = null,
       	@t_from		varchar(32) = null,
       	@t_trn		smallint = null)

as declare


/** GENERALES **/
	@w_return	 	int,
	@w_error         	int,
	@w_parametro	 	money, 
	@w_sp_name	 	descripcion,
	@w_fecha_proceso 	datetime,
        @w_fecha_ult_proceso    datetime,
	@w_prenotificacion	int,
	@w_valor                money,
        @w_secuencial_ach       int,
	@w_sec  		int,
       	@w_lsrv		        char(15),
	@w_ente_orig 		int,
	@w_ced_ruc_orig         varchar(15),
	@w_cuenta_orig          varchar(17),
	@w_tipo_cta_orig        varchar(3),
	@w_nom_cliente_orig     varchar(50),
	@w_descripcion          varchar(255),
        @w_desc_adenda          varchar(80),
        @w_commit               char(1),
	@w_carga		int,
        @w_op_banco             cuenta
	

 
     
select @w_sp_name = 'sp_desembolsos_ach'

select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7


select @w_lsrv = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SRVR'
and pa_producto  = 'ADM'
set transaction isolation level read uncommitted

 /* Encuentra el SSN inicial */

  select @w_sec = se_numero
  from cobis..ba_secuencial
  
  if @@rowcount <> 1
  begin
      /* Error en lectura de SSN */
      exec cobis..sp_cerror
           @i_num       = 201163
      return 201163
  end

  update cobis..ba_secuencial
     set se_numero = @w_sec + 100
   WHERE se_numero >=0     

  if @@rowcount <> 1
    begin
      
 /* Error en actualizacion de SSN */
      exec cobis..sp_cerror
           @i_num       = 205031
      return 205031
    end

/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR -- JCQ -- 10/10/2002 **/ 
/**

/** LECTURA DE PAGOS PENDIENTES DE APLICAR **/
declare cursor_desembolso_ach cursor for select 
        op_banco,
  	dm_prenotificacion,
        op_fecha_ult_proceso,
	dm_monto_mds,--or_valor ,
	or_cont_tran,
	or_ente_orig,
	or_ced_ruc_orig,
	or_cuenta_orig,
	or_tipo_cta_orig,
	or_nom_cliente_orig,
	or_descripcion,
	or_desc_adenda
from cob_cartera..ca_desembolso,
     cob_cartera..ca_operacion
     cob_ach..ach_originador
where op_operacion = dm_operacion 
and dm_prenotificacion = or_cont_tran
and dm_estado = 'NA'
and dm_producto = 'NCACH'
and dm_prenotificacion not in(null,0)
and dm_carga in(null,0)
for read only

open cursor_desembolso_ach


	fetch cursor_desembolso_ach into
	 	@w_op_banco,
		@w_fecha_ult_proceso,
		@w_valor,
		@w_secuencial_ach,
		@w_ente_orig,
		@w_ced_ruc_orig,
		@w_cuenta_orig,
		@w_tipo_cta_orig,
		@w_nom_cliente_orig,
		@w_descripcion,
		@w_desc_adenda



while @@fetch_status = 0 begin

   if (@@fetch_status = -1) 
   begin
      select @w_error = 701007
     
  goto ERROR
   end



   if @w_op_banco is not null begin


	   exec @w_return    = cob_ach..sp_originador
		@s_ssn		      = @w_sec,
		@s_srv		      = @s_srv,
		@s_lsrv		      = @w_lsrv,
		@s_user		      = 'sa',
		@s_sesn		      = @w_sec,
		@s_term		      = 'consola',
		@s_date		      = @w_fecha_proceso,
		@s_org		      = @s_org, 
		@s_ofi		      = 99,
    		@t_trn                = 20414,
		@i_operacion          = 'I',
    		@i_valor              = @w_valor,
    		@i_servicio           = 'CAR',
	        @i_origen	      = @w_secuencial_ach,
    		@i_ente_orig          = @w_ente_orig,
    		@i_modulo             = 7,
    		@i_ced_ruc_orig       = @w_ced_ruc_orig,
    		@i_cuenta_orig        = @w_cuenta_orig,
    		@i_tipo_cta_orig      = @w_tipo_cta_orig,
    		@i_nom_cliente_orig   = @w_nom_cliente_orig,
    		@i_descripcion        = @w_descripcion,
    		@i_adenda             = 'S',
    		@i_desc_adenda        = @w_desc_adenda,
                @i_enlinea            = 'N', /* Bandera para manejo de error - controla ACH */
                @o_cont_tran          = @w_carga out


         if @w_return != 0 
         begin
           select @w_error = @w_return
         goto ERROR
         end 




     exec @w_return   
    = sp_pasotmp
       @s_term             = 'consola',
       @s_user             = 'sa',
       @i_banco            = @w_op_banco,
       @i_operacionca      = 'S',
       @i_dividendo        = 'S',
       @i_amortizacion     = 'S',
       @i_cuota_adicional  = 'S',
       @i_rubro_op         = 'S',
       @i_nomina           = 'S'   

      if @w_return != 0 
      begin
         select @w_error = @w_return
         goto ERROR
      end                            



	  exec @w_return = sp_liquida
           @s_ssn            = @w_sec,
           @s_sesn           = @w_sec,
           @s_user           = 'sa',
           @s_date           = @w_fecha_proceso,--@s_date,
           @s_ofi            = 900,
           @s_rol            = 1,
           @s_term           = 'consola',
           @i_banco_ficticio = @w_op_banco,
           @i_banco_real     = @w_op_banco,
           @i_afecta_credito = 'N',
           @i_fecha_liq      =  @w_fecha_ult_proceso,
           @i_tramite_batc   = 'S',
	   @i_prenotificacion = @w_secuencial_ach,
	       @i_desde_cartera   = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
           @i_carga           = @w_carga 

      if @w_return <> 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      /* BORAR TEMPORALES */
      exec @w_return = sp_borrar_tmp
         @i_banco  = @w_op_banco,
         @s_date   = @w_fecha_proceso,--@i_fecha_proceso,
         @s_user   = @s_user

      if @w_return <> 0  
         return @w_return


   commit tran     ---Fin de la transaccion 
 
   select @w_commit = 'N'

end
   goto SIGUIENTE1

 ERROR:


   exec sp_errorlog                                             
   @i_fecha       = @w_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = 'sa',
   @i_tran        = 7030, 
   @i_tran_name   = @w_sp_name,
   @i_rollback    = 'N',  
   @i_cuenta      = @w_op_banco,
   @i_descripcion = 'APLICACION DESEMBOLSO ORIGINADO EN ACH'

   if @w_commit = 'S' commit tran
   goto SIGUIENTE1

   SIGUIENTE1: 
   select @w_sec = @w_sec +1

   fetch cursor_desembolso_ach into
	 	@w_op_banco,
 		@w_fecha_ult_proceso,
		@w_valor,
		@w_secuencial_ach,
		@w_ente_orig,
		@w_ced_ruc_orig,
		@w_cuenta_orig,
		@w_tipo_cta_orig,
		@w_nom_cliente_orig,
		@w_descripcion,
		@w_desc_adenda
end
close cursor_desembolso_ach
deallocate cursor_desembolso_ach

**/
return 0
go
