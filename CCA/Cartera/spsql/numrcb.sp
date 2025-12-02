/************************************************************************/ 
/*      Archivo:                numrcb.sp                               */ 
/*      Stored procedure:       sp_numero_recibo                        */ 
/*      Base de datos:          cob_cartera                             */ 
/*      Producto:               Cartera                                 */ 
/*      Disenado por:           R Garces                                */ 
/*      Fecha de escritura:     Ene 1998                                */ 
/************************************************************************/ 
/*                              IMPORTANTE                              */ 
/*      Este programa es parte de los paquetes bancarios propiedad de   */ 
/*      "MACOSA".                                                       */ 
/*      Su uso no autorizado queda expresamente prohibido asi como      */ 
/*      cualquier alteracion o agregado hecho por alguno de sus         */ 
/*      usuarios sin el debido consentimiento por escrito de la         */ 
/*      Presidencia Ejecutiva de MACOSA o su representante.             */ 
/************************************************************************/ 
/*                        PROPOSITO                                     */ 
/*  Procedimiento que consulta el numero de secuencial para el          */ 
/*  recibo de pagos y liquidaciones.                                    */ 
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*      AGO-22-2006             EPB           Correcciones para BV BAC  */
/************************************************************************/ 
 
use cob_cartera 
go 
 
if exists (select 1 from sysobjects where name = 'sp_numero_recibo') 
        drop proc sp_numero_recibo 
go 
 
 
 
create proc sp_numero_recibo  
    @i_tipo         char(1)     = null,  
    @i_secuencial   int         = null,  
    @i_oficina      smallint    = null,  
    @o_numero       int         = null out,  
    @o_recibo       cuenta      = null out  
as  
  
declare  
        @w_numero           int,  
        @w_long_max_ope     tinyint,  
        @w_codigo           varchar(24),  
        @w_ceros            int,  
        @w_cta_ofi          catalogo  
  
  
select @w_long_max_ope = 10  
  
if @i_tipo = 'P' 
begin -- Pago  
  
  
    select @w_numero = cv_pago + 1  
    from   ca_conversion  
    where  cv_oficina = @i_oficina  
   
   
    if @w_numero > 0  
    begin
       update ca_conversion  
       set    cv_pago = @w_numero  
       where  cv_oficina = @i_oficina  
  
       select @o_numero = @w_numero  
    end  
    else 
    begin  
   
        select @w_cta_ofi = convert(varchar(4),replicate('0', 4-datalength(convert(varchar(4),@i_oficina))) + convert(varchar(4),@i_oficina))       
     
        insert into ca_conversion  
            (cv_oficina,    cv_codigo_ofi,  cv_operacion,   cv_anio,                                 
             cv_pago,       cv_liquidacion, cv_pago_masivo)   
        values   
            (@i_oficina,    @w_cta_ofi,     1,              convert(smallint,datepart(yy,getdate())),
             0,             0,              1)   
   
        if @@error != 0   
        begin  
            --print 'numrcb.sp  error de insercion. ca_conversion.'  
            return 705015  
        end  
        
        update ca_conversion  
        set    cv_pago = 1
        where  cv_oficina = @i_oficina  
           
        select @o_numero = 1
    end  
end  
  
if @i_tipo = 'L' 
begin -- Liquidacion  
    select @w_numero = cv_liquidacion + 1  
    from   ca_conversion  
    where  cv_oficina = @i_oficina  
  
    update ca_conversion  
    set    cv_liquidacion = @w_numero  
    where  cv_oficina = @i_oficina  
  
    select @o_numero = @w_numero  
end  
  
  
if @i_tipo = 'G'
begin -- Generacion del numero de recibo  
     
    select @w_cta_ofi = cv_codigo_ofi  
    from   ca_conversion  
    where  cv_oficina = @i_oficina  
      
    select @w_codigo = convert(varchar(24), @i_secuencial)  
    select @w_ceros  = @w_long_max_ope - datalength(@w_codigo) -  datalength(@w_cta_ofi)   
   
   
    select @w_codigo = replicate('0', @w_ceros) + @w_codigo  
    select @o_recibo =  rtrim(@w_cta_ofi) + rtrim(@w_codigo)    
  
end  
  
  
if @i_tipo = 'I' 
begin -- Generacion del Consecutivo para Informe de pagos anuales  
     
    select @w_cta_ofi = cv_codigo_ofi  
    from   ca_conversion  
    where  cv_oficina = @i_oficina  
      
    select @w_codigo = convert(varchar(24), @i_secuencial)  
    select @w_ceros  = @w_long_max_ope - datalength(@w_codigo) -  datalength(@w_cta_ofi)   
   
   
    select  @w_codigo = replicate('0', @w_ceros) + @w_codigo  
    select  @o_recibo =  rtrim(@w_cta_ofi) + '-' + rtrim(@w_codigo)   
  
end  
  
  
  
return 0  
  
                                            
go 
 
 
