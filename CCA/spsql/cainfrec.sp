/************************************************************************/
/*	Archivo:		Cainfrec.sp        			*/
/*	Stored procedure:	sp_cca_informacion_rec_273              */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez               		*/
/*	Fecha de escritura:	dic 19 2003  				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	                                                                */ 
/*	Proceso que  genera informacion  para REC formato 273           */
/*      Este Sp es ejcutado por REC en la geenracion de sus datos       */
/*      La tabla cob_conta_super..tbl_cca_formato_273  inserta valores  */
/*      en los campos de moneda extranjera solo si la moneda de la Op.  */
/*      es diferente de 0 moneda naciona y 2 moneda uvr                 */
/*                            MODIFICACIONES                            */
/*      FECHA             AUTOR                       RAZON             */
/*      12/19/2003        Eclira Pelaez           Emsiion Inicial       */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_cca_informacion_rec_273')
	drop proc sp_cca_informacion_rec_273
go

create proc sp_cca_informacion_rec_273(
        @i_fecha_ini		datetime,
        @i_fecha_fin		datetime)
as
declare @w_sp_name                                       descripcion,
        @w_op_operacion                                   int,
        @w_ente                                          int,
        @w_op_cliente                                    int,
        @w_op_moneda                                     smallint,
        @w_di_fecha_ven                                  datetime,
        @w_di_dividendo                                  int,
        @w_capital_esperado                              money,
        @w_capital_esperado_mn                           money,
        @w_interes_esperado                              money,
        @w_interes_esperado_mn                           money,
        @w_contador                                      int,
        @w_int_imo_pagado                                money,
        @w_int_imo_pagado_mn                             money,
        @w_capital_pagado                                money,
        @w_capital_pagado_mn                             money,
        @w_moneda_nacional                               smallint,
        @w_producto                                      tinyint,
        @w_fecha_proceso_cca                             datetime,
        @w_capital                                       money,
        @w_pago_mn                                       money,
        @w_interes                                       money,
        @w_moneda_uvr                                    tinyint


      
	

select	@w_sp_name  = 'sp_cca_informacion_rec_273',
        @w_contador = 0



select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

select @w_moneda_uvr= pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'MUVR'
set transaction isolation level read uncommitted


     PRINT 'cainfrec.sp  INICIO DEL PROCESO  trunca y luego carga datos en cob_conta_super..tbl_cca_formato_273'

        -- borra las operaciones_anteriores
        truncate  table cob_conta_super..tbl_cca_formato_273                
        
        -- fecha de proceso 

	select @w_producto = pd_producto
	from cobis..cl_producto
	where pd_abreviatura = 'CCA'
	set transaction isolation level read uncommitted

	select  @w_fecha_proceso_cca = fc_fecha_cierre 
	from cobis..ba_fecha_cierre
	where fc_producto = @w_producto


-- crea la tabla temporal

        declare operaciones cursor for
        select distinct op_operacion,   
               op_cliente,
               op_moneda
        from  ca_operacion, ca_dividendo
        where di_operacion = op_operacion
        and di_fecha_ven between @i_fecha_ini and @i_fecha_fin           
        and  op_estado in (1,2,9,10,4)
        and  op_naturaleza <> 'R'
        for read only

        open operaciones
      
        fetch operaciones into
           @w_op_operacion,
           @w_op_cliente,
           @w_op_moneda
                            

        while (@@fetch_status = 0 ) begin
       
           if @@fetch_status = -1 
           begin    /* error en la base */
              PRINT ' cainfrec.sp  Error en lectura de cursor  operaciones'
           end       

           -- preguntar si tiene dividendos a la fecha
        
           select @w_contador = @w_contador + 1


           -- LO ESPERADO EN EL RANGO DE FECHAS


          select  @w_capital_esperado = 0
          select  @w_capital_esperado_mn = 0
          select  @w_interes_esperado = 0
          select  @w_interes_esperado_mn = 0


          declare operaciones_por_dividendo cursor for
          select di_fecha_ven,
                 di_dividendo 
           from  ca_dividendo
           where di_operacion = @w_op_operacion
           and  di_fecha_ven between @i_fecha_ini and @i_fecha_fin
           for read only

           open operaciones_por_dividendo
      
           fetch operaciones_por_dividendo into
             @w_di_fecha_ven,
             @w_di_dividendo

             while (@@fetch_status = 0 ) begin
       
               if @@fetch_status = -1 
                  begin    /* error en la base */
                    PRINT 'cainfrec.sp Error en lectura de cursor  operaciones_por_dividendo '
                  end       

                  select @w_capital = 0
                  select @w_pago_mn = 0

                  select @w_capital = isnull(sum(am_cuota),0)
                  from ca_concepto, ca_amortizacion, ca_dividendo
                  where co_concepto = am_concepto 
	          and am_operacion = @w_op_operacion           
                  and co_categoria = 'C'
                  and am_dividendo = @w_di_dividendo  
                  and am_operacion = di_operacion
                  and am_dividendo = di_dividendo

                  exec  sp_conversion_moneda
                  @s_date             = @w_fecha_proceso_cca,
                  @i_opcion           = 'L',
                  @i_moneda_monto     = @w_op_moneda,
                  @i_moneda_resultado = @w_moneda_nacional,
                  @i_monto            = @w_capital, --en moneda de la operacion
                  @i_fecha            = @w_di_fecha_ven,
                  @o_monto_resultado  = @w_pago_mn out       --en moneda nacional

 
                  ---ESPERADO INTERESES
                  select  @w_capital_esperado = isnull(@w_capital_esperado + @w_capital,0)
                  select  @w_capital_esperado_mn = isnull(@w_capital_esperado_mn + @w_pago_mn,0)


                  select @w_interes = 0
                  select @w_pago_mn = 0
                  select @w_interes = isnull(sum(am_cuota),0)
                  from ca_concepto, ca_amortizacion, ca_dividendo
                  where co_concepto = am_concepto 
	          and am_operacion = @w_op_operacion           
                  and co_categoria in ('I','M')
                  and am_dividendo = @w_di_dividendo  
                  and am_operacion = di_operacion
                  and am_dividendo = di_dividendo

                  exec  sp_conversion_moneda
                  @s_date             = @w_fecha_proceso_cca,
                  @i_opcion           = 'L',
                  @i_moneda_monto     = @w_op_moneda,
                  @i_moneda_resultado = @w_moneda_nacional,
                  @i_monto            = @w_interes, --en moneda de la operacion
                  @i_fecha            = @w_di_fecha_ven,
                  @o_monto_resultado  = @w_pago_mn out       --en moneda nacional

                  select  @w_interes_esperado = isnull(@w_interes_esperado  + @w_interes,0)
                  select  @w_interes_esperado_mn = isnull(@w_interes_esperado_mn + @w_pago_mn,0)

             fetch operaciones_por_dividendo into
                @w_di_fecha_ven,
                @w_di_dividendo
           end

           close operaciones_por_dividendo
           deallocate operaciones_por_dividendo


          ---ACTUALIZAR  CAP ESPERADOS

          if @w_capital_esperado  > 0
            begin

              if @w_op_moneda = @w_moneda_nacional or @w_op_moneda = @w_moneda_uvr
                 select @w_capital_esperado = 0

              INSERT INTO cob_conta_super..tbl_cca_formato_273 (ca_fecha_ini,
              ca_fecha_fin, ca_operacion, ca_cliente, ca_concepto, ca_moneda,
              ca_valor_pagado_mn, ca_valor_pagado_me, ca_valor_esperado_mn, 
              ca_valor_esperado_me)
             values(
              @i_fecha_ini,               @i_fecha_fin,
              @w_op_operacion,            @w_op_cliente,
              'CAPITAL',                  @w_op_moneda,
              0,       0,
              @w_capital_esperado_mn,@w_capital_esperado)

           end


          ---ACTUALIZAR  INTERESES ESPERADOS
          if @w_interes_esperado  > 0
            begin

              if @w_op_moneda = @w_moneda_nacional or @w_op_moneda = @w_moneda_uvr
                 select @w_interes_esperado = 0

              INSERT INTO cob_conta_super..tbl_cca_formato_273 (ca_fecha_ini,
              ca_fecha_fin, ca_operacion, ca_cliente, ca_concepto, ca_moneda,
              ca_valor_pagado_mn, ca_valor_pagado_me, ca_valor_esperado_mn, 
              ca_valor_esperado_me)
              values(
              @i_fecha_ini,               @i_fecha_fin,
              @w_op_operacion,            @w_op_cliente,
              'INTERES',                  @w_op_moneda,
              0,       0,
              @w_interes_esperado_mn,@w_interes_esperado)
           end

           
           --VALORES PAGADOS EN ESTE RANGO         
           
          
           select @w_capital_pagado = isnull(sum(ar_monto),0),
                  @w_capital_pagado_mn = isnull(sum(ar_monto_mn),0)
           from ca_abono_rubro,ca_concepto
           where ar_operacion = @w_op_operacion
           and   ar_concepto = co_concepto
           and co_categoria = 'C'
           and ar_fecha_pag between @i_fecha_ini and @i_fecha_fin


          ---INSERTAR CAP
          if @w_capital_pagado > 0
            begin

              if @w_op_moneda = @w_moneda_nacional or @w_op_moneda  = @w_moneda_uvr
                 select @w_capital_pagado = 0

              if exists (select (1) from cob_conta_super..tbl_cca_formato_273
                 where ca_operacion = @w_op_operacion
                 and   ca_cliente   = @w_op_cliente
                 and   ca_concepto  = 'CAPITAL')
                 begin
                    update cob_conta_super..tbl_cca_formato_273
                     set  ca_valor_pagado_mn  = @w_capital_pagado_mn,
                          ca_valor_pagado_me  = @w_capital_pagado
                    where ca_operacion = @w_op_operacion
                    and   ca_cliente   = @w_op_cliente
                    and   ca_concepto  = 'CAPITAL'
                 end

           end
         

           -- Abono ANTERIOR INTERESES CORRIENTES  Y MORA
           
           
           select @w_int_imo_pagado = isnull(sum(ar_monto),0),
                  @w_int_imo_pagado_mn = isnull(sum(ar_monto_mn),0)
           from ca_abono_rubro,ca_concepto
           where ar_operacion = @w_op_operacion
           and   ar_concepto = co_concepto
           and co_categoria in ('I','M')
           and ar_fecha_pag between @i_fecha_ini and @i_fecha_fin


          ---ACTUALIZAR INTERES
          if @w_int_imo_pagado > 0
            begin
              if @w_op_moneda = @w_moneda_nacional or @w_op_moneda = @w_moneda_uvr
                 select @w_int_imo_pagado = 0

              if exists (select (1) from cob_conta_super..tbl_cca_formato_273
                 where ca_operacion = @w_op_operacion
                 and   ca_cliente   = @w_op_cliente
                 and   ca_concepto  = 'INTERES')
                 begin
                    update cob_conta_super..tbl_cca_formato_273
                     set  ca_valor_pagado_mn  = @w_int_imo_pagado_mn,
                          ca_valor_pagado_me  = @w_int_imo_pagado
                    where ca_operacion = @w_op_operacion
                    and   ca_cliente   = @w_op_cliente
                    and   ca_concepto  = 'INTERES'
                 end
           end




        ---SIGUIENTE OPERACION
        fetch operaciones into
           @w_op_operacion,
           @w_op_cliente,
           @w_op_moneda

     end

     close operaciones
     deallocate operaciones

     PRINT 'cainfrec.sp  FINNN PROCESO  No. de Obligaciones Procesadas   ---> ' + cast(@w_contador as varchar)

return 0
go
