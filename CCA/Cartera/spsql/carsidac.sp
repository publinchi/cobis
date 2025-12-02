/************************************************************************/
/*   Archivo:              carsidac.sp                                  */
/*   Stored procedure:     sp_reversos_sob_sidac                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Ene-24-2005                                  */
/************************************************************************/
/*                            IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Procedimiento que realiza el reverso de los SOBRANTES de sidac por */
/*   efectos de transacciones de cartear                                */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA              AUTOR          CAMBIO                        */
/*      FEB-2006           E.Pelaez       BAC-def-5957                  */
/*      mar-2006           EPB            NR  479                       */
/*                                        ULT:ACT:MAYO-25-2006          */
/*      junio-2006        Elcira Pelaez   def 6515 BAC                  */
/*      junio-2006        Elcira Pelaez   def 6737 BAC                  */
/*      junio-2006        Fabian Quintero def 6756 BAC                  */
/*      julio-2006        Elcira Pelaez   def 6780 BAC                  */
/*      AGosto-2006       Elcira Pelaez   def 6973 BAC                  */
/*      SEP-01-2006       Elcira Pelaez   rfp 126 BAC-FACTORING         */
/*      sep-26-2006       Elcira Pelaez   def 7134-7152 BAC             */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversos_sob_sidac')
   drop proc sp_reversos_sob_sidac
go

create proc sp_reversos_sob_sidac   
@s_sesn                 int          = NULL,
@s_user                 login        = NULL,
@s_term                 varchar (30) = NULL,
@s_date                 datetime     = NULL,
@s_ofi                  smallint     = NULL,
@s_ssn                  int          = null,
@s_srv                  varchar (30) = null,
@t_rty                  char(1)      = null,
@t_debug                char(1)      = 'N',
@t_file                 varchar(14)  = null,
@t_trn                  smallint     = null,
@i_operacionca          int,
@i_banco                cuenta,
@i_secuencial_retro     int,
@i_cliente              int,
@i_oficina              int,
@i_programa             catalogo =  null,
@i_proceso              char(1) = 'F'

as 
declare 
@w_return               int,
@w_sp_name              varchar(30),
@w_concepto_devseg      catalogo,
@w_descripcion          varchar(255),
@w_referencia_sidac     varchar(50),
@w_operacion_sidac      varchar(15),
@w_sec_sidac            varchar(15),
@w_area_devseg          int,
@w_param_devseg         catalogo,
@w_param_sobaut         catalogo,
@w_monto_sobrante       money,
@w_area_sobaut          int,
@w_param_sobaut_sidac   catalogo,
@w_concepto_sob         catalogo,
@w_secuencial_pag       int,
@w_error                int,
@w_secuencial_cxp       int,
@w_par_fpago_depogar    catalogo,
@w_abd_cheque           int,
@w_parametro_depoga     catalogo,
@w_reverso              catalogo,
@w_area_depogar         int,
@w_consecutivo          int,
@w_pcobis               tinyint,
@w_rp_saldo             money,
@w_forma_reversa        catalogo,
@w_dev_colchon          catalogo,
@w_re_area               int,
@w_concepto_cxp         catalogo,
@w_rowcount             int


--- CARGADO DE VARIABLES DE TRABAJO 
select @w_sp_name            = 'sp_reversos_sob_sidac',
       @w_monto_sobrante     = 0

--PARAMETRO PARA SOBRANTE AUTOMATICO POR DEVOLUCION DE SEGUROS
select @w_param_devseg = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CXPDSE'
set transaction isolation level read uncommitted
       
--PARAMETRO PARA SOBRANTE AUTOMATICO POR CANCELACION
select @w_param_sobaut = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SOBAUT'
set transaction isolation level read uncommitted


select @w_param_sobaut_sidac = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CONSOB'
set transaction isolation level read uncommitted

select @w_par_fpago_depogar = pa_char
from cobis..cl_parametro
where pa_nemonico = 'FPDGIA'
and pa_producto = 'CCA'
set transaction isolation level read uncommitted

--PARAMETROP PARA DEVOLUCIONES DE COLCHON EN OEPRACIONES FACTORING

select @w_dev_colchon = pa_char
from cobis..cl_parametro
where pa_nemonico = 'DEVCOL'
and pa_producto = 'CCA'
set transaction isolation level read uncommitted


if @i_proceso = 'F'
begin
declare
   cursor_rev_ctas_sidac cursor
   for select ab_secuencial_pag,
              abd_concepto,
              abd_monto_mn,
              abd_cheque
      from   ca_abono_det,ca_abono
      where  abd_secuencial_ing = ab_secuencial_ing
      and    abd_operacion      = ab_operacion
      and    ab_secuencial_pag  >= @i_secuencial_retro
      and    abd_operacion      = @i_operacionca
      and    ab_operacion       = @i_operacionca
      and    ab_estado          = 'A'
      and    abd_concepto       in (@w_param_devseg,@w_param_sobaut,@w_par_fpago_depogar,@w_dev_colchon)
   for read only
end
else
begin
---Para reversos  se hace unicamente los que estan en estado 'A'
   if @i_programa = 'fechaval'
   begin

      declare
         cursor_rev_ctas_sidac cursor
         for select ab_secuencial_pag,
                    abd_concepto,
                    abd_monto_mn,
                    abd_cheque
            from   ca_abono_det,ca_abono
            where  abd_secuencial_ing = ab_secuencial_ing
            and    abd_operacion      = ab_operacion
            and    ab_secuencial_pag  >= @i_secuencial_retro
            and    abd_operacion      = @i_operacionca
            and    ab_operacion       = @i_operacionca
            and    ab_estado          = 'A'
            and    abd_concepto       in (@w_param_devseg,@w_param_sobaut,@w_par_fpago_depogar,@w_dev_colchon)
         for read only
    end
    else --para elimpag
    begin
      
      declare
         cursor_rev_ctas_sidac cursor
         for select ab_secuencial_pag,
                    abd_concepto,
                    abd_monto_mn,
                    abd_cheque
            from   ca_abono_det,ca_abono
            where  abd_secuencial_ing = ab_secuencial_ing
            and    abd_operacion      = ab_operacion
            and    ab_secuencial_pag  >= @i_secuencial_retro
            and    abd_operacion      = @i_operacionca
            and    ab_operacion       = @i_operacionca
            and    ab_estado          = 'NA'
            and    abd_concepto       in (@w_param_devseg,@w_param_sobaut,@w_par_fpago_depogar,@w_dev_colchon)
         for read only
      end    
     
end

open cursor_rev_ctas_sidac

fetch cursor_rev_ctas_sidac
into  @w_secuencial_pag,
      @w_concepto_sob,
      @w_monto_sobrante,
      @w_abd_cheque

--while @@fetch_status  not in (-1,0)
while @@fetch_status  = 0
begin
   
   
   --INICIO DE LA TRANSACCION
   --CLAVE PARA EL REVERSO EN SIDAC
   select @w_operacion_sidac = convert(varchar,@i_operacionca )
   select @w_sec_sidac = convert(varchar,@w_secuencial_pag )
   select @w_referencia_sidac = rtrim(ltrim(@w_operacion_sidac)) + ':' + rtrim(ltrim(@w_sec_sidac))
   select @w_descripcion  = 'REVERSO SOB OBLIGACION No.' + @i_banco
   
   if @w_concepto_sob = @w_param_devseg
   begin
      select @w_concepto_devseg = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'DEVSEG'
      set transaction isolation level read uncommitted
      
      --AREA DE DEVOLCUION DE SEGUROS
       select @w_area_devseg = pa_int
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'ARCXP'
      set transaction isolation level read uncommitted
      
     
      exec cob_interface..sp_rev_interfase
        @i_operacion          =  'OP1',
        @i_cliente            =  @i_cliente,
        @i_referencia_sidac   =  @w_referencia_sidac,
        @i_concepto_devseg    =  @w_concepto_devseg,
        @i_operacionca        =  @i_operacionca
   end 
   ---FIN REVERSO SEGURO
   
   --INICIO REVERSO SOBRANTE POR MAYOR VALOR
   if @w_concepto_sob = @w_param_sobaut
   begin
      --AREA DE DEVOLCUION DE SOBRANTE
      select @w_area_sobaut = pa_int
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'ARESOB'
      set transaction isolation level read uncommitted
      
      
      exec cob_interface..sp_rev_interfase
        @i_operacion          =  'OP1',
        @i_cliente            =  @i_cliente,
        @i_referencia_sidac   =  @w_referencia_sidac,
        @i_concepto_devseg    =  @w_param_sobaut_sidac,
        @i_operacionca        =  @i_operacionca,
        @s_ssn                =  @s_ssn 
   end
   
   --FIN REVERSO SOBRANTE POR MAYOR VALOR
   --FIN DE LA TRANSACCION 

    --def 6780 REVERSAR DEPOSITOS EN GARANTIA  SOLO EN REVERSOS 
    
   if @w_concepto_sob = @w_par_fpago_depogar and @i_proceso = 'R'
   begin
      
      select @w_forma_reversa = cp_producto_reversa
      from   ca_producto
      where  cp_producto = @w_par_fpago_depogar    
        
      select @w_pcobis          = cp_pcobis
      from   ca_producto
      where  cp_producto = @w_forma_reversa
      
      if @w_pcobis = 48
      begin
         select @w_parametro_depoga = rp_concepto,
                @w_consecutivo      = isnull(rp_consecutivo ,0)
         from   cob_sidac..sid_registros_padre
         where  rp_empresa = 1 
         and    rp_submodulo in ('CC','CP')
         and    rp_ente =  @i_cliente
         and    rp_consecutivo =  @w_abd_cheque
         and    rp_oficina > 0
         
         if @w_consecutivo  = 0
            return 711035
         
         select @w_reverso = valor from cobis..cl_catalogo
         where  tabla = (select codigo from cobis..cl_tabla where
                         tabla = 'sid_reversos_pagos') 
         and    codigo='PAGODEP' and estado='V'
         
         select @w_area_depogar = pa_int
         from   cobis..cl_parametro
         where  pa_producto = 'CCA'
         and    pa_nemonico = 'ARDEPO'
         select @w_rowcount = @@rowcount
         set transaction isolation level read uncommitted

         if @w_rowcount =  0 
            return 711024
      end
   end
   
   ----RFP 126 FACTORING
   ---------------------------------
   --INICIO REVERSO COLCHON OEPRACIONE FACTORING 
   if @w_concepto_sob = @w_dev_colchon
   begin
      
      select @w_re_area = pa_int
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'ARCXP'
      set transaction isolation level read uncommitted
      
      select @w_concepto_cxp = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'CXPCOL'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0
         return 710335
      
      exec cob_interface..sp_rev_interfase
        @i_operacion          =  'OP1',
        @i_cliente            =  @i_cliente,
        @i_referencia_sidac   =  @w_referencia_sidac,
        @i_concepto_devseg    =  @w_concepto_cxp,
        @i_operacionca        =  @i_operacionca

   end
   
   ---RFP 126 FACTORING
   ------------------------------------
   fetch cursor_rev_ctas_sidac
   into  @w_secuencial_pag,
         @w_concepto_sob,
         @w_monto_sobrante,
         @w_abd_cheque
end  --CURSOR

close cursor_rev_ctas_sidac
deallocate cursor_rev_ctas_sidac
-- FIN CURSOR DE RUBROS TIPO SEGURO

return 0
go

