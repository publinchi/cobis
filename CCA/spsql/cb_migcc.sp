/************************************************************************/
/*      Archivo           :  cb_migcc.sp                               */
/*      Base de datos     :  cob_conta                                  */
/*      Producto          :  Contabilidad                               */
/*      Disenado por      :  Johanna Botero                             */
/*      Fecha de escritura:  Marzo 27 de 2003                           */
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
/*     Consolidar todos los procesos que se realizan en la migracion	*/
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/

use cob_conta
go


if exists (select 1 from sysobjects where name = 'sp_cb_migcc_ej')
   drop proc sp_cb_migcc_ej
go

create proc sp_cb_migcc_ej
(
  @t_show_version  bit         = 0,
  @i_param1       tinyint        , --empresa  
  @i_param2       varchar(20)        , --archivo  
  @i_param3       char(1)        , --automatica  
  @i_param4       char(1)        , --tipo_carga  
  -- parametros para registro del log de ejcucion
  @i_sarta         int         = null,
  @i_batch         int         = null,
  @i_secuencial    int         = null,
  @i_corrida       int         = null,
  @i_intento       int         = null
)
as
declare @w_return int,
        @w_fecha  datetime,
        @w_usuario varchar(20), 
        @w_archivo  varchar(30),
        @w_comprobantes int,
        @w_anio int,
        @w_mes  int,
        @w_dia   int
        
if @i_param4 = 'M'  
begin
   insert into cb_estado_mig (em_empresa, em_archivo, em_estado)
   values (@i_param1, @i_param2, 'I')   
end

if @i_param4 = 'A'
begin
   select
      @w_usuario = ct_usuario_modulo,
      @w_fecha   = ct_fecha_tran
   from cob_conta..cb_convivencia_tmp
/*   
   execute cobis..sp_datepart
   @i_fecha = @w_fecha,
   @o_anio  = @w_anio  out,
   @o_mes   = @w_mes   out,
   @o_dia   = @w_dia   out
*/   
   select @w_archivo = @w_usuario + substring(convert(VARCHAR,@w_anio),3,4) + convert(varchar,@w_mes) + convert(varchar,@w_dia)

   insert into cb_estado_mig (em_empresa, em_archivo, em_estado)
   values (@i_param1, @w_archivo, 'I')
end

if exists(select 1 from cob_conta..cb_estado_mig
            where em_empresa = @i_param1
            and   em_estado = 'I')
begin 
      select @w_comprobantes = count(*)    
      from cob_conta..cb_convivencia_tmp
         
      if (@w_comprobantes > 0)   
      begin
           exec @w_return = cob_conta..sp_valida_mig
           @i_empresa        = @i_param1,
            @i_valautomatica  = @i_param3
   
           if @w_return <> 0
           begin               
               return @w_return
            end            
      end
end      

update cob_conta..cb_convivencia
set co_concepto_imp = '0000',
    co_base_imp = 0,
    co_tipo = ' ',
    co_identifica   = ' '
where co_empresa = 1
and   co_cuenta not in (select cp_cuenta from cob_conta..cb_cuenta_proceso
                         where cp_empresa = 1
                         and   cp_proceso in (6003,6095))

return 0
go
    
