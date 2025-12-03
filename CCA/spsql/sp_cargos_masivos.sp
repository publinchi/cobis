/************************************************************************/
/*    Archivo:                  sp_cargos_masivos.sp                    */
/*    Stored procedure:         sp_cargos_masivos                       */
/*    Base de datos:            cob_cartera                             */
/*    Producto:                 Cartera                                 */
/*    Disenado por:             Jorge Escobar                           */
/*    Fecha de escritura:       13/Nov/2019                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "MACOSA",  representantes  exclusivos  para  el Ecuador de la     */
/*    "NCR CORPORATION".                                                */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de MACOSA o su representante.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*    Proceso de carga masiva de otros cargos a prestamos de cartera    */
/************************************************************************/
/*				MODIFICACIONES				*/
/*    FECHA		AUTOR			RAZON			*/
/*  22/11/2019         EMP-JJEC                Creaciòn                 */
/************************************************************************/
use cob_cartera
go
 
if exists (select * from sysobjects where name = "sp_cargos_masivos")
  drop proc sp_cargos_masivos
go

CREATE PROCEDURE dbo.sp_cargos_masivos ( 
@s_ssn		int         = null, 
@s_user		login       = null, 
@s_term		varchar(30) = null, 
@s_date		datetime    = null, 
@s_srv		varchar(30) = null, 
@s_lsrv		varchar(30) = null, 
@s_rol		smallint    = NULL, 
@s_ofi		smallint    = NULL, 
@s_org_err	char(1)     = NULL, 
@s_error	int         = NULL, 
@s_sev		tinyint     = NULL, 
@s_msg		descripcion = NULL, 
@s_org		char(1)     = NULL, 
@t_trn		smallint    = NULL, 
@t_debug	char (1)    = 'N', 
@t_file		varchar (14)= null, 
@i_operacion	char (1), 
@i_banco	cuenta, 
@i_base_con	varchar (24), 
@i_base_cal	money, 
@i_valor	money, 
@i_comentario	varchar (255)
) 
as 
                                                                                                                                                                                                                                                           
declare	
@w_sp_name	       varchar(30),
@w_estado_registro     varchar(10),
@w_est_cancelado       tinyint,
@w_est_credito         tinyint,
@w_est_anulado         tinyint,
@w_est_novigente       tinyint,
@w_est_vigente         tinyint,
@w_est_vencido         tinyint,
@w_nrows               int,
@w_sec_previo          int,
@w_return              int,
@w_desc_error          varchar(100),
@w_operacion           cuenta,
@w_concepto            catalogo,
@w_monto               money,
@w_comentario          varchar(255),
@w_base_calculo        money

          
/* INICIALIZACION DE VARIABLES */
select @w_sp_name = "sp_cargos_masivos"

-- OBTENGO LOS ESTADOS DE CARTERA
exec sp_estados_cca
@o_est_credito    = @w_est_credito    out,
@o_est_anulado    = @w_est_anulado    out,
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado  out,
@o_est_vigente    = @w_est_vigente    out,
@o_est_vencido    = @w_est_vencido    out

if @i_operacion ='I'  
begin 
   /*  Insercion  */ 
   begin tran 
      --insert into ca_cargos_masivos (cm_usuario, cm_fecha_ingreso, cm_operacion, cm_concepto_base, cm_base_calculo, cm_valor, cm_comentario, cm_estado, cm_desc_error) 
      --select value, @s_user, @s_date, @i_base_con, @i_base_cal,  @i_valor, @i_comentario FROM STRING_SPLIT(@i_operacion_pres, ' '),'',''
                                                                                                                                                 
      insert into ca_cargos_masivos (cm_usuario, cm_fecha_ingreso, cm_operacion, cm_concepto_base, cm_base_calculo, cm_valor, cm_comentario, cm_estado, cm_desc_error) 
      values (@s_user,@s_date, @i_banco, @i_base_con, @i_base_cal, @i_valor, @i_comentario, 'ING','')
      
      if @@error != 0 
      begin 
         return 1 
      end 

   select @w_nrows = 1, 
          @w_sec_previo = 0 

   while (@w_nrows > 0) 
   begin 

   select @w_estado_registro = 'PROCESADO', 
          @w_desc_error      = null
          
      select top 1
      @w_operacion     = cm_operacion,
      @w_sec_previo    = cm_secuencial,
      @w_concepto      = cm_concepto_base,
      @w_monto         = cm_valor,
      @w_comentario    = cm_comentario,
      @w_base_calculo  = cm_base_calculo
      from ca_cargos_masivos 
      where cm_usuario       = @s_user
        and cm_fecha_ingreso = @s_date
        and cm_estado        = 'ING'
        and cm_secuencial    > @w_sec_previo
      order by cm_secuencial
           
      if @@rowcount = 0 break 
 
      exec @w_return = sp_otros_cargos 
           @s_date           = @s_date,
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_ofi            = @s_ofi,
           @i_banco          = @w_operacion,
           @i_operacion      = 'I',
           @i_concepto       = @w_concepto,
           @i_monto          = @w_monto,
           @i_comentario     = @w_comentario,
           @i_base_calculo   = @w_base_calculo
              
       if  @w_return <> 0
       begin
          select @w_desc_error = mensaje
          from cobis..cl_errores
          where numero = @w_return
          select @w_estado_registro = 'ERROR'	
       end	   

      update ca_cargos_masivos
      set cm_estado     = @w_estado_registro,
          cm_desc_error = isnull(@w_desc_error,'Error en la carga del rubro: sp_otros_cargos')
      where cm_usuario       = @s_user
        and cm_fecha_ingreso = @s_date
        and cm_secuencial    = @w_sec_previo

   end
   commit tran 
end

return 0 
                                                                                                                                                                                                                                                    
go
