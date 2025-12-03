/************************************************************************/
/*   Archivo:              acdatconso.sp                                */
/*   Stored procedure:     sp_actualizar_consolidador                   */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   May 2005                                     */
/************************************************************************/
/*                          MPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                         PROPOSITO                                    */
/*   Procedimiento que realiza la actualizacion del consolidador        */
/*   para igualar los estados de oblgiaciones de ca_operacion y         */
/*   cr_tmp_datooper                                                    */
/************************************************************************/
/*                                CAMBIOS                               */
/*   FECHA          AUTOR               CAMBIO                          */
/*   dic-07-2005    Elcira Pelaez        Actualizaciones sobre tem      */
/*                                       generacion replica finmes      */
/*   feb-19-2007    Elcira Pelaez        NR-396  BAC                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualizar_consolidador')
   drop proc sp_actualizar_consolidador
go

create proc sp_actualizar_consolidador
@s_date        datetime,      --Fecha de proceso digitada por operador
@s_user        login,
@i_modo        char(1)  = 'N' -- R Para reprocesar 

as 

declare
@w_error                   int,          
@w_return                  int,    
@w_sp_name                 descripcion,  
@w_fecha1                  datetime,
@w_mes                     smallint,
@w_siguiente_dia           datetime,
@w_mes1                    smallint,
@w_fin_mes                 char(1),
@w_fecha                   datetime


select @w_sp_name              = 'sp_actualizar_consolidador',
       @w_siguiente_dia        = @s_date,
       @w_error                = 0,
       @w_fin_mes              = 'N'

select @w_siguiente_dia = dateadd(dd,1,@w_siguiente_dia)

exec @w_return = sp_dia_habil 
     @i_fecha       = @w_siguiente_dia,
     @i_ciudad      = 11001,  ---BOGOTA
     @o_fecha       = @w_siguiente_dia out

if @w_return !=0
begin
   select @w_error = @w_return
   goto ERROR
end

select @w_fecha  = convert(varchar(10),@s_date,101)
select @w_mes    = datepart(mm,@w_fecha)

select @w_fecha1 = convert(varchar(10),@w_siguiente_dia,101)
select @w_mes1   = datepart(mm,@w_fecha1)

if @w_mes1 <> @w_mes 
   select @w_fin_mes = 'S'
else
   select @w_fin_mes = 'N'

--realizar las actualizaciones unicamente a fin de mes
-- Actualizar las operaciones que en ca_operacion estan NO VIGENTE y en Consolidador estan VIGENTES
   
   update cob_credito..cr_dato_operacion
   set do_saldo_cap                  = 0,
       do_saldo_int                  = 0,
       do_saldo_otros                = 0,
       do_saldo_int_contingente      = 0,
       do_saldo                      = 0,
       do_valor_mora                 = 0,
       do_saldo_cuotaven             = 0,
       do_capsusxcor                 = 0,
       do_intsusxcor                 = 0,
       do_estado_contable            = 5,
       do_estado_cartera              = 0
   from   ca_operacion
   where  op_estado  = 0
   and    do_codigo_producto = 7
   and    do_numero_operacion_banco = op_banco
   and    do_tipo_reg  = 'D'
   and    do_fecha = @s_date


if  @w_fin_mes = 'S' 
 begin

   update cob_credito..cr_tmp_concepto
   set    cpt_saldo = 0
   from   ca_operacion
   where  cpt_producto = 7
   and    cpt_num_op_banco = op_banco
   and    op_estado in (3,6,0)
   and    cpt_fecha = @s_date
   
   --REPLICA PARA CARTERA
   insert into cob_cartera.. ca_tmp_datooper   
   select 
   @w_fecha,
   getdate(),
   dot_numero_operacion ,
   dot_numero_operacion_banco,
   dot_codigo_cliente,
   dot_oficina,
   dot_moneda,
   dot_monto,
   dot_tasa,
   dot_dias_vto_div,
   dot_saldo_cap,
   dot_saldo_int,
   dot_saldo_otros,
   dot_saldo_int_contingente,
   dot_saldo,
   dot_estado_contable,
   dot_estado_desembolso,
   dot_estado_terminos,
   dot_calificacion,
   dot_edad_mora,
   dot_valor_mora,
   dot_estado_cartera  
   from cob_credito..cr_tmp_datooper 
       
 end
   

return 0

ERROR:
   begin
      exec sp_errorlog                                             
      @i_fecha       = @s_date,
      @i_error       = @w_error,
      @i_usuario     = @s_user,
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name,
      @i_rollback    = 'S',  
      @i_cuenta      = 'CONSOLIDADOR',
      @i_anexo       = 'ACTUALIZANDO CONSOLIDADOR',
      @i_descripcion = ''
   end
      
go
