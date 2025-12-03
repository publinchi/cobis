
/************************************************************************/
/*   Archivo:              devolseg.sp                                  */
/*   Stored procedure:     sp_devolcuiones_seguros                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Ene-29-2003                                  */
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
/*   Procedimiento que realiza el abono de la devolucion por pago de    */
/*      seguros anticipados solo si hay precancelacion de la obligacion */
/*      este sp es llamado desde abonoca.sp                             */
/************************************************************************/  
/*                               CAMBIOS                                */
/*      FECHA              AUTOR          CAMBIO                        */
/*                                                                      */
/*      jun-2004         Elcira Pelaez        Reverso sobrante          */
/*      Dic-2005         Elcira Pelaez        defecto5484 error 710295  */
/*	     junio-2006		  Elcira Pelaez	    def 6737 BAC              */
/*      20/10/2021      G. Fernandez     Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_devolcuiones_seguros')
   drop proc sp_devolcuiones_seguros
go

create proc sp_devolcuiones_seguros   
@s_sesn                   int          = NULL,
@s_user               login        = NULL,
@s_term         varchar (30) = NULL,
@s_date         datetime     = NULL,
@s_ofi         smallint     = NULL,
@s_ssn                  int          = null,
@s_srv                  varchar (30) = null,
@i_operacionca          int,
@i_div_vigente          int,
@i_secuencial_ing       int,
@i_secuencial_pag       int,
@i_num_dec_op           int,
@i_en_linea             char(1) = 'S'

as 
declare 
@w_return               int,
@w_sp_name              varchar(30),
@w_concepto             catalogo,
@w_comentario           varchar(50),
@w_num_periodo_d        smallint,
@w_periodo_d            catalogo,
@w_valor_pagado         money,
@w_valor_dia_rubro      money,
@w_dias_div             int,
@w_dias_faltan_cuota    int,
@w_devolucion           money,
@w_devolucion_mn        money,
@w_valor_rubro      money,
@w_op_cuenta            cuenta,
@w_op_cliente           int,
@w_concepto_dse         catalogo,
@w_param_devseg         catalogo,
@w_codvalor_dse         int, 
@w_cotizacion           money,
@w_moneda_ab            smallint,
@w_cxc                  cuenta,
@w_tcotizacion          char(1),
@w_oficina_op           int,
@w_pcobis               int,
@w_producto             int,
@w_pfpago               catalogo,
@w_fecha_proceso        datetime,
@w_op_banco      cuenta,
@w_moneda_op            tinyint,
@w_num_dec              tinyint,
@w_moneda_n             smallint,
@w_num_dec_n            tinyint,
@w_concepto_puente      char(4),
@w_devolucion_concepto    money,
@w_devolucion_concepto_mn money,
@w_area                   int,
@w_operacion_sidac          varchar(15),
@w_sec_sidac                varchar(15),
@w_referencia_sidac         varchar(50),
@w_di_fecha_ini             datetime,
@w_di_fecha_ven             datetime,
@w_di_dividendo             int,
@w_rowcount                 int



--- CARGADO DE VARIABLES DE TRABAJO 
select @w_sp_name     = 'sp_devolcuiones_seguros',
       @w_devolucion  = 0,
       @w_valor_rubro = 0,
       @w_devolucion_concepto_mn  = 0

--- SELECCIONAR LA COTIZACION Y EL TIPO DE COTIZACION 
select @w_cotizacion  = abd_cotizacion_mop,
       @w_tcotizacion = abd_tcotizacion_mop,
       @w_moneda_ab   = abd_moneda
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo           = 'PAG'

--- INFORMACION DE OPERACION 
select @w_num_periodo_d      = op_periodo_int,
       @w_periodo_d          = op_tdividendo,
       @w_fecha_proceso      = op_fecha_ult_proceso,
       @w_op_cuenta          = op_cuenta,
       @w_op_cliente         = op_cliente,
       @w_op_banco           = op_banco,
       @w_oficina_op         = op_oficina,
       @w_moneda_op          = op_moneda
from   ca_operacion
where  op_operacion = @i_operacionca

---LECTURA DE DECIMALES 
exec @w_return  = sp_decimales
     @i_moneda       = @w_moneda_op,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_n out

if @w_return != 0 
   return @w_return

select @w_num_dec = isnull(@w_num_dec, 0)

if @w_moneda_op = 2 -- UVR
   select @w_num_dec_n = 2 -- MAYOR PRECISION EN UVR

select @w_devolucion    = 0,
       @w_devolucion_mn = 0
       
--CURSOR DE RUBROS TIPO SEGURO
declare cursor_rubros_dev cursor
   for select ro_concepto
       from ca_rubro_op, ca_concepto
       where ro_operacion = @i_operacionca
       and   co_categoria  = 'S'
       and   ro_calcular_devolucion = 'S'
       and ro_concepto = co_concepto
   for read only

open cursor_rubros_dev

fetch cursor_rubros_dev
into  @w_concepto

while @@fetch_status = 0 
begin
    
      --CURSOR DE DIVIDENDOS FUTUROS  QUE TIENE SEGUROS PAGADOS
      -----------------------------------------------------------------------

         declare cursor_dividendos_devseg cursor
            for select di_dividendo,di_fecha_ini,di_fecha_ven, am_cuota, am_pagado
            from ca_dividendo,ca_amortizacion
            where di_operacion = @i_operacionca
            and di_operacion = am_operacion
            and di_dividendo = am_dividendo
            and am_concepto = @w_concepto
            and am_pagado > 0
            and di_fecha_ven > @w_fecha_proceso
            for read only

            open cursor_dividendos_devseg
            
            fetch cursor_dividendos_devseg
            into  @w_di_dividendo,@w_di_fecha_ini,@w_di_fecha_ven,@w_valor_rubro,@w_valor_pagado
            
               while @@fetch_status = 0 
               begin
   
                  if @w_valor_pagado  = @w_valor_rubro  
                   begin
                  
                     --- NUMERO DE DIAS POR DIVIDENDO 
                     select @w_devolucion_concepto = @w_valor_rubro
            
                     --EN ESTA PARTE SE SACA LA PORCION DEL  SEGURO A DEVOLVER PARA LA CUOTA EN CURSO
                     -------------------------------------------------------------------------------
                     if @w_fecha_proceso between @w_di_fecha_ini and @w_di_fecha_ven
                     begin
                        select @w_dias_div = td_factor * @w_num_periodo_d
                        from   ca_tdividendo
                        where  td_tdividendo = @w_periodo_d 
                        
                        select @w_valor_dia_rubro    = (@w_valor_pagado / @w_dias_div)
                        select @w_dias_faltan_cuota  = datediff(dd, @w_fecha_proceso, @w_di_fecha_ven)
                        
                        select @w_devolucion_concepto    = round(@w_valor_dia_rubro * @w_dias_faltan_cuota, @w_num_dec)
                     end                  
                     -------------------------------------------------------------------------------
                     select @w_devolucion_concepto_mn =  round(@w_devolucion_concepto * @w_cotizacion, @w_num_dec_n)
                     insert into ca_det_trn
                           (dtr_secuencial,           dtr_operacion,          dtr_dividendo,
                            dtr_concepto,              dtr_estado,             dtr_periodo,
                            dtr_codvalor,              dtr_monto,              dtr_monto_mn,
                            dtr_moneda,                dtr_cotizacion,         dtr_tcotizacion,
                            dtr_afectacion,            dtr_cuenta,             dtr_beneficiario,  
                            dtr_monto_cont)  
                     select @i_secuencial_pag,         @i_operacionca,       @w_di_dividendo,
                            @w_concepto,                1,                   0,
                            co_codigo * 1000 +4,       @w_devolucion_concepto,   @w_devolucion_concepto_mn, 
                            @w_moneda_ab,               @w_cotizacion,   @w_tcotizacion,
                            'C',            '',      '000000',
                            0
                     from   ca_concepto
                     where co_concepto = @w_concepto
                     
                     if @@error != 0
                        return 708166
                     
                     select @w_devolucion    = @w_devolucion + @w_devolucion_concepto
                     select @w_devolucion_mn = @w_devolucion_mn + @w_devolucion_concepto_mn
               end 

               fetch cursor_dividendos_devseg
               into  @w_di_dividendo , @w_di_fecha_ini,@w_di_fecha_ven,@w_valor_rubro,@w_valor_pagado
         
            end  --CURSOR DIVIDENDOS
      
      close cursor_dividendos_devseg
      deallocate cursor_dividendos_devseg           

      --FIN CURSOR DE DIVIDENDOS QUE TIENEN SEGURO PAGADO
  
   fetch cursor_rubros_dev
   into  @w_concepto
end  --CURSOR

close cursor_rubros_dev
deallocate cursor_rubros_dev
-- FIN CURSOR DE RUBROS TIPO SEGURO
------------------------------ 

------------------------------------------------------------------
--SE INSERTA EL DETALLE DE TRANSACCION POR  DEVOLCUION DE SEGUROS 
------------------------------------------------------------------
if  @w_devolucion != 0
begin
   select @w_comentario  = 'DEVSEG CANCELA CREDITO No.' + @w_op_banco,
          @w_op_cuenta = 'CxP SIDAC'               
   
   select @w_pfpago = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'CXPDSE'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0  
      return 710421
   
   -- PARAMETROS GENERALES PARA ENVIAR A SIDAC
   select @w_param_devseg = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'DEVSEG'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0  
      return  710400
   
   if not exists (select 1 from ca_producto
                  where cp_producto = @w_pfpago)
      return  710424
   
   --CODIGO DEL PRODUCTO
   select @w_producto = pd_producto
   from   cobis..cl_producto
   where  pd_abreviatura = 'CCA'
   set transaction isolation level read uncommitted
   
   select @w_area = pa_int
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'ARCXP'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0  
      return 710421 
   
   --- GENERAR NOTA DE CUENTA POR PAGAR A SIDAC 
   select @w_operacion_sidac = convert(varchar,@i_operacionca )
   select @w_sec_sidac = convert(varchar,@i_secuencial_pag)
   select @w_referencia_sidac = rtrim(ltrim(@w_operacion_sidac)) + ':' + rtrim(ltrim(@w_sec_sidac))
   select @w_devolucion_mn  = round(@w_devolucion_mn,@w_num_dec_n)
   
   if @s_ssn is null
   begin
      ---SECUENCIAL PARA SIDAC
     exec @s_ssn = sp_gen_sec
     @i_operacion      = @i_operacionca
   end
   /* No se tiene cob_sidac en Banca Mia
   exec @w_return = cob_sidac..sp_cuentaxpagar   
        @s_ssn               =  @s_ssn,
        @s_user              =  @s_user,
        @s_date              =  @s_date,
        @s_term              =  @s_term,
        @s_ssn_corr          =  @s_ssn,
        @s_srv               =  @s_srv,
        @s_ofi               =  @s_ofi,
        @t_trn               =  32550,
        @i_operacion         = 'I',
        @i_empresa           =  1,
        @i_fecha_rad         =  @s_date,
        @i_modulo            =  @w_producto,         --- 7  numero de cartera   
        @i_fecha_ven         =  @s_date,             --- Fecha proceso
        @i_moneda            =  @w_moneda_ab,        --- Moneda dela operacion              
        @i_valor             =  @w_devolucion_mn,       --- Valor devolucion
        @i_concepto          =  @w_param_devseg,     --- Este esta definido como parametro gral 14CART19 en cl_parametro
        @i_condicion         = '1',                  --- 1 es un caracter   
        @i_tipo_referencia   = '01',
        @i_formato_fecha     =  101,                 --- Formato de fecha  
        @i_ente              =  @w_op_cliente,       --- Op_cliente
        @i_referencia        =  @w_referencia_sidac, --- No. del credito
        @i_area              =  @w_area,
        @i_oficina           =  @w_oficina_op,       ---Ofi del credito
        @i_estado            = 'P',
        @i_descripcion       =  @w_comentario
   
   if @w_return  != 0   
   begin
      return 710336 
   end
   */ -- No se tiene cob_sidac en Banca Mia
   ---INSERCION DETALLE POR DEVOLUCION DE SEGURO CON EL MISMO SECUENCIAL DEL PAGO
   insert into ca_det_trn
         (dtr_secuencial,     dtr_operacion,    dtr_dividendo,
          dtr_concepto,       dtr_estado,       dtr_periodo,
          dtr_codvalor,       dtr_monto,        dtr_monto_mn,
          dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
          dtr_afectacion,     dtr_cuenta,       dtr_beneficiario,  
          dtr_monto_cont)
   select @i_secuencial_pag,  @i_operacionca,   @i_div_vigente,
          @w_pfpago,          1,                0,
          cp_codvalor,        @w_devolucion,    @w_devolucion_mn, 
          @w_moneda_ab,       @w_cotizacion,    @w_tcotizacion,
          'D',                @w_op_cuenta,     @w_comentario,
          0
   from   ca_producto
   where  cp_producto = @w_pfpago
   
   if @@error != 0 
      return 708166
   
   ---INSERCION DE LA DEVOLUCION EN EL DETALLE DEL ABONO PARA EL CASO DE REVERSO 
   delete ca_abono_det
   where abd_secuencial_ing = @i_secuencial_ing
   and   abd_operacion = @i_operacionca
   and   abd_tipo = 'SEG'
   and   abd_concepto = @w_pfpago

   insert into ca_abono_det
         (abd_secuencial_ing,   abd_operacion,               abd_tipo,            abd_concepto ,
          abd_cuenta,           abd_beneficiario,            abd_moneda,          abd_monto_mpg,
          abd_monto_mop,        abd_monto_mn,                abd_cotizacion_mpg,  abd_cotizacion_mop,
          abd_tcotizacion_mpg,  abd_tcotizacion_mop,         abd_cheque,          abd_cod_banco,
          abd_inscripcion,      abd_carga,                   abd_solidario)                        --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   values(@i_secuencial_ing,    @i_operacionca,              'SEG',               @w_pfpago,
          @w_op_cuenta,         @w_comentario,              @w_moneda_ab,        @w_devolucion_mn,
          @w_devolucion,         @w_devolucion_mn,           @w_cotizacion,       @w_cotizacion,
          'C',                  'C',                         null,                null,
          null,                 null,                        'N')
   
   if @@error != 0
   begin
      --PRINT 'devolseg.sp error @w_pfpago' + @w_pfpago + ' @w_devolucion' + cast(@w_devolucion as varchar) + '@w_comentario' + @w_comentario
      return 710295
  end
end

return 0

go
