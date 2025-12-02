/************************************************************************/
/*   Stored procedure:     sp_rec_pagos_recib                           */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rec_pagos_recib')
   drop proc sp_rec_pagos_recib
go

create proc sp_rec_pagos_recib
@t_debug       char(1)      = 'N',  
@t_file        varchar(14)  = null,
@t_from        varchar(30)  = null,
@i_fecha_ini   datetime     = null,
@i_fecha_fin   datetime     = null
 
as

set nocount on

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_msg                varchar(60),
        @w_op_oficina         smallint,
        @w_des_oficina        varchar(64),
        @w_cod_oficial        smallint,
        @w_nombre_funcionario varchar(64),
        @w_concepto           varchar(10),
        @w_monto              money,
        @w_auxiliar           money,
        @w_valor_total        money,
        @w_cod_funcionario    int
   
select  @w_op_oficina         = 0,
        @w_des_oficina        = '',
        @w_cod_oficial        = 0,
        @w_nombre_funcionario = '',
        @w_concepto           = '',
        @w_monto              = 0,
        @w_auxiliar           = 0,
        @w_valor_total        = 0


delete cob_cartera..ca_rec_pagos_recib 
where tmp_nro_oper >= 0


/*CUENTA NUMERO DE OPERACIONES POR OFICINA */
select   
op_oficina,op_oficial, count(distinct(op_banco)) as total into #banco_ofi
from  cob_cartera..ca_operacion,cob_cartera..ca_dividendo,cob_cartera..ca_transaccion,
      cob_cartera..ca_det_trn
where op_estado in (1,2,9) 
and   di_operacion   = op_operacion
and   di_fecha_ven between @i_fecha_ini and @i_fecha_fin
and   tr_operacion   = op_operacion
and   tr_tran        = 'PAG'
and   tr_estado      <> 'RV'
and   tr_fecha_mov between @i_fecha_ini and @i_fecha_fin
and   dtr_concepto   <> 'VAC0'
and   dtr_operacion  = tr_operacion
and   dtr_secuencial = tr_secuencial  
and   di_dividendo   = dtr_dividendo
group by op_oficina, op_oficial

    
    
/* CURSOR PARA LA LECTURA DE LAS OPERACIONES DE RECAUDOS EFECTIVOS DE PAGOS RECIBIDOS */    
declare
cursor_rec_pagos_recib cursor
for select
    op_oficina,      dtr_concepto,   sum(dtr_monto),   op_oficial  
    from  cob_cartera..ca_operacion,cob_cartera..ca_dividendo,cob_cartera..ca_transaccion,
          cob_cartera..ca_det_trn
    where op_estado in (1,2,9) 
    and   di_operacion   = op_operacion
    and   di_fecha_ven between @i_fecha_ini and @i_fecha_fin
    and   tr_operacion   = op_operacion
    and   tr_tran        = 'PAG'
    and   tr_estado      <> 'RV'
    and   tr_fecha_mov between @i_fecha_ini and @i_fecha_fin
    and   dtr_concepto <> 'VAC0'
    and   dtr_operacion  = tr_operacion
    and   dtr_secuencial = tr_secuencial  
    and   di_dividendo   = dtr_dividendo
    group by op_oficina, op_oficial, dtr_concepto
    order by op_oficina, op_oficial, dtr_concepto
for read only

open  cursor_rec_pagos_recib
fetch cursor_rec_pagos_recib
into  @w_op_oficina,    @w_concepto,    @w_monto,    @w_cod_oficial 

while   @@fetch_status = 0
begin

   select @w_cod_funcionario = oc_funcionario
   from cobis..cc_oficial
   where oc_oficial = @w_cod_oficial

   select @w_nombre_funcionario = fu_nombre
   from cobis..cl_funcionario
   where fu_funcionario = @w_cod_funcionario


   /* INSERCION EN LA TABLA TEMPORAL POR VARIABLES */
   if not exists (select 1 from ca_rec_pagos_recib 
                   where tmp_cod_ofi         = @w_op_oficina
                     and tmp_cod_funcionario = @w_cod_oficial)
   begin
      insert into ca_rec_pagos_recib 
      (tmp_nro_oper,              tmp_cod_ofi,               tmp_des_ofi,        
       tmp_cod_funcionario,       tmp_nombre_funcionario,    tmp_cap,            
       tmp_int,                   tmp_imo,                   tmp_mipymes,        
       tmp_ivamipymes,            tmp_otros,                 tmp_valor_total
      )
      values
      (0,                         @w_op_oficina,             @w_des_oficina,           
       @w_cod_oficial,            @w_nombre_funcionario,     0,                         
       0,                         0,                         0,                         
       0,                         0,                         0
      )
   end

   update ca_rec_pagos_recib
   set   tmp_des_ofi = valor          
   from  cobis..cl_tabla t,                         
         cobis..cl_catalogo c,
         ca_rec_pagos_recib
   where t.tabla     = 'cl_oficina'
   and   c.tabla     = t.codigo
   and   c.codigo    = @w_op_oficina
   and   tmp_cod_ofi = @w_op_oficina
        
   if (@w_concepto= 'CAP') begin  
      update ca_rec_pagos_recib
      set    tmp_cap             = @w_monto
      where  tmp_cod_ofi         = @w_op_oficina
      and    tmp_cod_funcionario = @w_cod_oficial
   end
   else begin
      if (@w_concepto='INT')    begin  
         update ca_rec_pagos_recib
         set    tmp_int             = @w_monto
         where  tmp_cod_ofi         = @w_op_oficina
         and    tmp_cod_funcionario = @w_cod_oficial
      end
      else begin
         if (@w_concepto='IMO') begin 
            update ca_rec_pagos_recib
            set    tmp_imo             = @w_monto
            where  tmp_cod_ofi         = @w_op_oficina
            and    tmp_cod_funcionario = @w_cod_oficial
         end        
         else begin
            if (@w_concepto='MIPYMES') begin
               update ca_rec_pagos_recib
               set    tmp_mipymes         = @w_monto
               where  tmp_cod_ofi         = @w_op_oficina
               and    tmp_cod_funcionario = @w_cod_oficial
             end
             else begin
               if (@w_concepto='IVAMIPYMES') begin
                  update ca_rec_pagos_recib
                  set    tmp_ivamipymes       = @w_monto
                  where  tmp_cod_ofi          = @w_op_oficina
                  and    tmp_cod_funcionario  = @w_cod_oficial
               end    
               else begin
                  update ca_rec_pagos_recib 
                  set    tmp_otros           = tmp_otros + @w_monto
                  where  tmp_cod_ofi         = @w_op_oficina 
                  and    tmp_cod_funcionario = @w_cod_oficial
               end
            end
         end    --else IMO
      end   -- else INT
   end     

   fetch cursor_rec_pagos_recib
   into  @w_op_oficina,            @w_concepto,     @w_monto, @w_cod_oficial
end --while

close cursor_rec_pagos_recib 
deallocate cursor_rec_pagos_recib 

update ca_rec_pagos_recib
set    tmp_valor_total  = tmp_cap  + tmp_int  +  tmp_imo +  tmp_mipymes + tmp_ivamipymes +   tmp_otros            
from   ca_rec_pagos_recib
where tmp_nro_oper >= 0
 
update ca_rec_pagos_recib                        
set    tmp_nro_oper = total 
from   ca_rec_pagos_recib, #banco_ofi                          
where  tmp_cod_ofi         = op_oficina   
and    tmp_cod_funcionario = op_oficial             

--select
--tmp_cod_ofi,
--tmp_des_ofi,
--tmp_cod_funcionario,
--tmp_nombre_funcionario,
--tmp_cap,      
--tmp_int,      
--tmp_imo,      
--tmp_mipymes,  
--tmp_ivamipymes,
--tmp_otros    
--tmp_valor_total 
--from rec_pagos_recib

return 0

ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error 

return @w_error
set nocount off 
go


