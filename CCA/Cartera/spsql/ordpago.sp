/******************************************************************/
/*  Archivo:            ordpago.sp                                */
/*  Stored procedure:   sp_orden_pago                             */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 26-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Envia a aplicar las ordenes de pago de las operaciones     */
/*     hijas                                                      */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR           RAZON                      */
/*  20/Jun/19        Lorena Regalado   Permite realizar las       */
/*                                     Ordenes de Pago            */
/******************************************************************/


USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_orden_pago') IS NOT NULL
	DROP PROCEDURE dbo.sp_orden_pago
GO

create proc sp_orden_pago
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_operacion        int,             --Operacion de Cartera
   @i_grupo            int 


as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_monto                money,
   @w_cliente              int,
   @w_mensaje              varchar(255),
   @w_rol_act              varchar(10),
   @w_oficial              smallint,
   @w_plazo_op             smallint,
   @w_plazo                smallint,
   @w_tipo_seguro          varchar(10), 
   @w_monto_seguro         money, 
   @w_fecha_inicial        datetime,
   @w_fecha_desemb         datetime,
   @w_operacion            int,
   @w_cotizacion_hoy       money,
   @w_rowcount		   int,
   @w_moneda_nacional      tinyint,
   @w_num_dec              tinyint,
   @w_ssn                  int,
   @w_op_forma_pago        catalogo,
   @w_secuencial           int,
   @w_return               int,
   @w_porc_iva             float,
   @w_porc_iva2            float,
   @w_num_renovacion       int,
   @w_num_secuencial       int,
   @w_commit               char(1),
   @w_banco_hija           cuenta, 
   @w_oper_hija            int,
   @p_convenio             int,
   @p_fecha_vigencia       datetime,
   @p_referencia           varchar(30),
   @w_monto_desembolso     money,
   @w_tipo_orden           catalogo,
   @w_banco                catalogo,
   @w_grupo                int,
   @w_odp_generada         varchar(20),
   @w_convenio             varchar(10),    
   @w_fecha_odp            datetime,
   @w_fecha_ing            datetime         


      
select @w_commit = 'N'

--print  'Operacion: ' + cast(@i_operacion as varchar)
--print  'Grupo: ' + cast(@i_grupo as varchar)

 
/* COMENTADO HASTA QUE RESUELVA BANCOS
      execute @w_return =  cobis..sp_dispersion_retiro
              @s_lsrv           = @s_lsrv,
              @s_ssn            = @s_ssn,
              @s_date           = @s_date, 
              @s_user           = @s_user,
              @t_trn            = 2213,
              @i_forma_retiro   =  ' ',        --Se envia vacio no lo usa para esta operacion
              @i_monto          = 0, 
              @i_fecha_apl      = @s_date,  
	      @s_ofi            = @s_ofi, 
              @i_operacion      = "U",         -- ACTIVACION DE FORMAS DE RETIRO
              @i_grupo          = @i_grupo,    -- CODIGO DEL GRUPO SOLIDARIO
              @i_car_operacion  = @i_operacion -- CODIGO INTERNO DE LA OPERACION DE CARTERA
             

      if @w_return <> 0
      begin
--print 'Error en la dispersion ' + cast(@w_return as varchar)
        select @w_error = @w_return
        goto ERROR            
      end
 
*/


return 0

ERROR:
  if @w_commit = 'S'
   begin
--print 'entro a la rutina de ERROR'
        while @@trancount > 0 ROLLBACK TRAN


    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = @w_mensaje,
    @i_sev    = 0
   
     return @w_error 
   end
   else
   begin
  
     return @w_error
   end
   

GO

