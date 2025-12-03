/************************************************************************/
/*   Archivo:               moracosecha.sp                              */
/*   Stored procedure:      sp_mora_creditos_cosecha                    */
/*   Base de datos:         cob_cartera                                 */
/*   Producto:              Cartera                                     */
/*   Disenado por:          M.Bernal                                    */
/*   Fecha de escritura:    05/10/2008                                  */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                              PROPOSITO                               */
/*   Procedimiento que realiza el calculo diario de mora de creditos    */
/*   por cosecha                                                        */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA             AUTOR             CAMBIO                      */
/*      05/10/2008        M.Bernal          Emision Inicial             */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_mora_creditos_cosecha')
   drop proc sp_mora_creditos_cosecha
go

create proc sp_mora_creditos_cosecha
   @i_fecha_ini          datetime = null,
   @i_fecha_fin          datetime = null,
   @i_tipo_linea         char(1)= 'T',
   @i_linea              catalogo
as
declare
    @w_sp_name           varchar (32),
    @w_op_toperacion     catalogo,
    @w_op_oficina        smallint,
    @w_credito           smallint,
    @w_capital           money,
    @w_rr_rango          smallint,
    @w_rr_desde          int,
    @w_rr_hasta          int

select @w_sp_name    = 'sp_mora_creditos_cosecha'

declare @mora_cosecha_tmp table 
      ( cod_rango      smallint,
        toperacion     catalogo,
        oficina        smallint,
        credito        smallint,
        capital        money
      )                                

declare cursor_moracosecha cursor
for select   rr_rango,
             rr_desde,
             rr_hasta
from cob_credito..cr_resumen_rango_mora
order  by rr_rango
for read only

open cursor_moracosecha 
fetch from cursor_moracosecha into
           @w_rr_rango,
           @w_rr_desde,
           @w_rr_hasta

while (@@fetch_status = 0) -- Inicio cursor_moracosecha
begin
    if (@@fetch_status = -1) return 708999

    if @i_tipo_linea = 'L' and @i_linea is not null
    begin
        select @w_op_toperacion = op_toperacion,
               @w_op_oficina    = op_oficina,
               @w_credito       = count(*),
               @w_capital       = sum(de_total_saldo_cap)
        from   cob_cartera..ca_operacion,
               cob_palm..ca_detalle_ejecutivo_pda2
        where  op_estado in (1,2,4,9)
        and    op_fecha_liq between @i_fecha_ini and @i_fecha_fin
        and    op_toperacion = @i_linea
        and    de_banco      = op_banco
        and    de_dias_vencimiento between @w_rr_desde and @w_rr_hasta
        group by op_toperacion, op_oficina
        order by op_toperacion, op_oficina

        if @@rowcount > 0
        begin
            --Insercion en la tabla temporal
            insert into @mora_cosecha_tmp
                   (cod_rango,      toperacion,       oficina,       credito,    capital)
            values (@w_rr_rango,    @w_op_toperacion, @w_op_oficina, @w_credito, @w_capital)   

            if @@error != 0
            begin 
                exec cobis..sp_cerror
                @t_from     = @w_sp_name,
                @i_num      = @@error  --Pendiente definir codigo de error
                /* 'Error Insercion tabla temporal'*/
                close cursor_moracosecha
                deallocate cursor_moracosecha
                return
            end 
        end 
    end

    if @i_tipo_linea = 'T'
    begin
        select @w_op_toperacion = op_toperacion,
               @w_op_oficina    = op_oficina,
               @w_credito       = count(*),
               @w_capital       = sum(de_total_saldo_cap)
        from   cob_cartera..ca_operacion,
               cob_palm..ca_detalle_ejecutivo_pda2
        where  op_estado           in (1,2,4,9)
        and    op_fecha_liq        between @i_fecha_ini and @i_fecha_fin
        and    de_banco            = op_banco
        and    de_dias_vencimiento between @w_rr_desde and @w_rr_hasta
        
        group by op_toperacion, op_oficina
        order by op_toperacion, op_oficina

        if @@rowcount > 0
        begin
            --Insercion en la tabla temporal
            insert into @mora_cosecha_tmp
                   (cod_rango,      toperacion,       oficina,       credito,    capital)
            values (@w_rr_rango,    @w_op_toperacion, @w_op_oficina, @w_credito, @w_capital)
            
            if @@error != 0
            begin 
                exec cobis..sp_cerror
                @t_from     = @w_sp_name,
                @i_num      = @@error  --Pendiente definir codigo de error
                /* 'Error Insercion tabla temporal'*/
                close cursor_moracosecha
                deallocate cursor_moracosecha
                return 0
            end
        end 
    end

    if not exists (select 1 from @mora_cosecha_tmp
                   where cod_rango = @w_rr_rango)
    begin
        insert into @mora_cosecha_tmp
               (cod_rango,      toperacion,       oficina,       credito,    capital)
        values (@w_rr_rango,    @w_op_toperacion, @w_op_oficina, @w_credito, @w_capital)
    end



    fetch cursor_moracosecha into
    @w_rr_rango,
    @w_rr_desde,
    @w_rr_hasta

end  --While -- Fin cursor_moracosecha

close cursor_moracosecha
deallocate cursor_moracosecha

select cod_rango,
       toperacion, 
       oficina,
       credito, 
       capital
from   @mora_cosecha_tmp

return 0
go
