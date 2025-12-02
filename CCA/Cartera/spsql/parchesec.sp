/************************************************************************/
/*   Archivo:              caconta.sp                                   */
/*   Stored procedure:     sp_parche_sec                                */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Corregir los comprobantes repetidos                                */
/*                             MODIFICACIONES                           */
/*   FECHA      AUTOR      RAZON                                        */
/*   12DIC2003          Elcira Pelaez   Utilizacion parametro           */
/*                                      i_causacion                     */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_parche_sp')
   drop proc sp_parche_sp
go

create proc sp_parche_sp
as
declare
   @w_error                int,
   @w_rep_fecha_tran       datetime,
   @w_rep_comprobante      int,
   @w_max_comprobante_real int,
   @w_max_comprobante_teo  int
begin
   declare
      cur_repetidos cursor
      for select sc_fecha_tran, sc_comprobante
          from   cob_conta_tercero..ct_scomprobante_tmp r
          where  sc_empresa = 1
          and    sc_producto = 7
          and    exists(select 1
                        from   cob_conta_tercero..ct_scomprobante
                        where  sc_producto = 7
                        and    sc_fecha_tran = r.sc_fecha_tran
                        and    sc_comprobante = r.sc_comprobante)
      for read only
   
   open cur_repetidos
   
   fetch cur_repetidos
   into  @w_rep_fecha_tran, @w_rep_comprobante
   
   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      exec @w_error = cob_conta..sp_cseqcomp
           @i_tabla      = 'cb_scomprobante',
           @i_empresa    = 1,
           @i_fecha      = @w_rep_fecha_tran,
           @i_modulo     = 7,
           @i_modo       = 0, 
           @o_siguiente  = @w_max_comprobante_teo out
      
      select @w_max_comprobante_real = isnull(max(sc_comprobante), 0)
      from   cob_conta_tercero..ct_scomprobante
      where  sc_empresa = 1
      and    sc_producto = 7
      and    sc_fecha_tran = @w_rep_fecha_tran
      
      select @w_max_comprobante_real = isnull(@w_max_comprobante_real, 0) + 10
      
      BEGIN TRAN
      
      if @w_max_comprobante_real > @w_max_comprobante_teo
      begin
         update cob_conta..cb_seqnos_comprobante
         set    sc_actual = @w_max_comprobante_real + 1
         where  sc_fecha = @w_rep_fecha_tran
         and    sc_modulo = 7
         and    sc_tabla  = 'cb_scomprobante'
      end
      ELSE
         select @w_max_comprobante_real = @w_max_comprobante_teo
      
      --print 'sp_parche_sec: actualizando'+ @w_rep_comprobante + 'de' + @w_rep_fecha_tran + 'a'+ @w_max_comprobante_real
      
      update cob_conta_tercero..ct_scomprobante_tmp
      set    sc_comprobante = @w_max_comprobante_real
      where  sc_empresa = 1
      and    sc_producto = 7
      and    sc_fecha_tran = @w_rep_fecha_tran
      and    sc_comprobante = @w_rep_comprobante
      
      update cob_conta_tercero..ct_sasiento_tmp
      set    sa_comprobante = @w_max_comprobante_real
      where  sa_empresa = 1
      and    sa_producto = 7
      and    sa_fecha_tran = @w_rep_fecha_tran
      and    sa_comprobante = @w_rep_comprobante
      
      COMMIT
      
      fetch  cur_repetidos
      into   @w_rep_fecha_tran, @w_rep_comprobante
   end
   close cur_repetidos
   deallocate cur_repetidos
   
   return 0
end
go
