/************************************************************************/
/*   Archivo:             abmagene.sp                                   */
/*   Stored procedure:    sp_carga_masivos_ext                          */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  Nov-26-2003                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                          PROPOSITO                                   */
/*   Cargar Informacion de Pagos Masivos Generales  a temporales  desde */
/*   batch                                                              */
/************************************************************************/  
/*                         ACTUALIZACIONES                              */
/*     FECHA              AUTOR            CAMBIO                       */
/*     ABR-2007           Elcira Pelaez    Def. 7804                    */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_carga_masivos_ext')
   drop proc sp_carga_masivos_ext
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_carga_masivos_ext (
   @s_date              datetime     = null,
   @s_user              login        = null,
   @s_ofi               smallint     = null,
   @s_term              varchar(30)  = null,
   @i_fecha_proceso     datetime     = null,
   @i_lote              int       
 )
as
declare
   @w_sp_name                varchar(32),
   @w_return                 int,
   @w_error                  int,
   @w_operacionca            int,
   @w_secuencial             int,
   @w_total_registros        cuenta,
   @w_fecha_archivo          datetime,
   @w_monto_total            money,
   @w_descripcion            varchar(255),
   @w_reg                    int,
   @w_mg_nro_credito         cuenta,
   @w_mg_fecha_cargue        datetime,
   @w_mg_forma_pago          catalogo,
   @w_mg_tipo_aplicacion     char(1),
   @w_mg_tipo_reduccion      char(1),
   @w_mg_monto_pago          money,
   @w_mg_prioridad_concepto  catalogo,
   @w_mg_oficina             int,
   @w_mg_cuenta              cuenta,
   @w_mg_nro_control         int,
   @w_mg_tipo_trn            smallint,
   @w_mg_posicion_error      int,
   @w_mg_codigo_error        int,
   @w_mg_descripcion_error   varchar(150),
   @w_mg_secuencial_ing      int,
   @w_mg_moneda              smallint,
   @w_reg_insertados         int



--  Captura nombre de Stored Procedure

select @w_sp_name      = 'sp_carga_masivos_ext'

---INSERCION DE REGISTRO DE CABECERA 

select  
@w_total_registros  = mg_nro_credito,
@w_fecha_archivo    = mg_fecha_cargue,
@w_monto_total      = mg_monto_pago,
@w_secuencial       = mg_oficina 
from  ca_pag_masivos_temp
where mg_forma_pago  is null
and   mg_tipo_aplicacion is null
and   mg_tipo_reduccion  is null

select @w_reg = convert(int,@w_total_registros)

insert into ca_abonos_masivos_cabecera 
(mc_total_registros,    mc_fecha_archivo,    mc_monto_total,
mc_secuencial,         mc_estado,           mc_lote, 
mc_errores)
values (@w_reg,        @w_fecha_archivo,    @w_monto_total,
@w_secuencial,         'I',                 @i_lote,
0)

if @@error != 0 
begin
   select @w_error = 710441
   select @w_descripcion = 'Error Insertando Cabecera por batch'
   goto ERROR
end    

--BORRAR CABEERA INCLUIDA EN EL DETALLE

delete  ca_pag_masivos_temp
where mg_forma_pago  is null
and mg_tipo_aplicacion is null
and mg_tipo_reduccion  is null

---INSERCION DE REGISTROS A LA TEMPORAL

declare
   abonos_masivos cursor
   for select mg_nro_credito,    mg_fecha_cargue,      mg_forma_pago,         mg_tipo_aplicacion,
       mg_tipo_reduccion, mg_monto_pago,        mg_prioridad_concepto, mg_oficina,
       mg_cuenta,         mg_nro_control,       mg_tipo_trn,           mg_posicion_error,
       mg_codigo_error,   mg_descripcion_error, mg_secuencial_ing,     mg_moneda
       from   ca_pag_masivos_temp
       for read only

   open abonos_masivos
         
   fetch abonos_masivos
   into  @w_mg_nro_credito,    @w_mg_fecha_cargue,      @w_mg_forma_pago,         @w_mg_tipo_aplicacion,
         @w_mg_tipo_reduccion, @w_mg_monto_pago,        @w_mg_prioridad_concepto, @w_mg_oficina,
         @w_mg_cuenta,         @w_mg_nro_control,       @w_mg_tipo_trn,           @w_mg_posicion_error,
         @w_mg_codigo_error,   @w_mg_descripcion_error, @w_mg_secuencial_ing,     @w_mg_moneda
         
   --while @@fetch_status not in (-1,0) -- WHILE CURSOR PRINCIPAL DE REGISTROS
   while @@fetch_status = 0 -- WHILE CURSOR PRINCIPAL DE REGISTROS
   begin


   select @w_mg_nro_control = isnull(@w_mg_nro_control,0)
   /*
   exec @w_return =  rechazos_conv..sp_verificar_correccion      
   @i_num_control =  @w_mg_nro_control
   */

      if @w_return = 1    --Se acordo con Monica Angulo que se ejectute si @w_return= 1
      begin
         exec @w_return =  sp_abonos_masivos_generales 
         @s_date              = @s_date,
         @s_user              = @s_user,
         @s_ofi               = @s_ofi,
         @s_term              = @s_term,
         @i_operacion         = 'T',
         @i_lote              = @i_lote,
         @i_banco             = @w_mg_nro_credito,
         @i_fecha_pago        = @w_mg_fecha_cargue,
         @i_forma_pago        = @w_mg_forma_pago,
         @i_tipo_aplicacion   = @w_mg_tipo_aplicacion,
         @i_tipo_reduccion    = @w_mg_tipo_reduccion,
         @i_monto             = @w_mg_monto_pago,
         @i_concepto          = @w_mg_prioridad_concepto,
         @i_oficina           = @w_mg_oficina,
         @i_secuencial        = @w_secuencial,
         @i_cuenta            = @w_mg_cuenta,
         @i_moneda            = @w_mg_moneda,
         @i_nro_control       = @w_mg_nro_control,
         @i_tipo_trn          = @w_mg_tipo_trn,
         @i_posicion_error    = @w_mg_posicion_error,
         @i_codigo_error      = @w_mg_codigo_error,
         @i_descripcion_error = @w_mg_descripcion_error,
         @i_secuencial_ing    = @w_mg_secuencial_ing
      
         if @w_return != 0
         begin
            select @w_error =  @w_return
      
            select @w_descripcion = 'Error ejecutando sp_abonos_masivos_generales por batch operacion T'
      
            insert into ca_errorlog
            (er_fecha_proc,         er_error,             er_usuario, 
            er_tran,               er_cuenta,            er_descripcion,
            er_anexo)
            values
            (@i_fecha_proceso,      @w_error,             @s_user,
            7000,                  @w_mg_nro_credito,    @w_descripcion,
            convert(varchar(12),@i_lote))
         end
      end
            
      fetch abonos_masivos
      into   @w_mg_nro_credito,    @w_mg_fecha_cargue,      @w_mg_forma_pago,         @w_mg_tipo_aplicacion,
             @w_mg_tipo_reduccion, @w_mg_monto_pago,        @w_mg_prioridad_concepto, @w_mg_oficina,
             @w_mg_cuenta,         @w_mg_nro_control,       @w_mg_tipo_trn,           @w_mg_posicion_error,
             @w_mg_codigo_error,   @w_mg_descripcion_error, @w_mg_secuencial_ing,     @w_mg_moneda

   end -- WHILE CURSOR OPERACIONES
close abonos_masivos
deallocate abonos_masivos


select @w_reg_insertados = 0
select @w_reg_insertados = count(1)
from   ca_abonos_masivos_generales
where  mg_lote = @i_lote
and    mg_estado = 'P'

PRINT 'abmagext.sp  REGISTROS PROCESADOR EXITOSAMENTE  ----> ' + CAST(@w_reg_insertados AS VARCHAR) 
PRINT 'abmagext.sp  No. LOTE PROCESADO                 ----> ' +  CAST(@i_lote AS VARCHAR)

return 0

ERROR:
insert into ca_errorlog
(er_fecha_proc,      er_error,      er_usuario,
er_tran,            er_cuenta,     er_descripcion,
er_anexo)
values(@i_fecha_proceso,   @w_error,      @s_user,
7000,               '',      @w_descripcion,
convert(varchar(12),@i_lote))

return @w_error       

go