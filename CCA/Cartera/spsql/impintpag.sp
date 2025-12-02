/************************************************************************/
/*   Archivo:            impintpag.sp                                   */
/*   Stored procedure:   sp_imp_interes_pagado                          */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Tania Suarez                                   */
/*   Fecha de escritura: 22/Jul/2009                                    */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                       PROPOSITO                                      */
/*   Consulta de los datos de una transaccion                           */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_imp_interes_pagado')
   drop proc sp_imp_interes_pagado
go
---LLS053696 MAR.24.2012
create proc sp_imp_interes_pagado (
       @s_ssn               int         = null,
       @s_date              datetime    = null,
       @s_user              login       = null,
       @s_term              descripcion = null,
       @s_corr              char(1)     = null,
       @s_ssn_corr          int         = null,
       @s_ofi               smallint    = null,
       @t_rty               char(1)     = null,
       @t_debug             char(1)     = 'N',
       @t_file              varchar(14) = null,
       @t_trn               smallint    = null,  
       @i_operacion         char(1)     = null,
       @i_formato_fecha     int         = null,
       @i_banco             cuenta      = null,
       @i_periodo           int         = null,
       @i_secuencial        int         = 0
)
as
declare @w_sp_name          varchar(32),
        @w_return           int,
        @w_error            int,
        @w_cliente          int,
        @w_tabla            int,
        @w_registros        int,
        @w_total            int,
        @w_est_castigado    int,
        @w_cliente_rl       int

--- Captura nombre de Stored Procedure  
select 
@w_sp_name = 'sp_imp_interes_pagado',
@w_error   = 0

select @w_cliente = op_cliente
from cob_cartera..ca_operacion
where op_banco    = @i_banco

if @@rowcount = 0 begin
   select @w_cliente = op_cliente
   from cob_cartera_his..ca_operacion
   where op_banco    = @i_banco
end

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out

--- Consulta Periodos que tiene el Cliente 
if @i_operacion = 'Q' begin

   select distinct 'PERIODO A CONSULTAR' = vp_periodo
   from cob_cartera..ca_valores_pag
   where vp_cliente = @w_cliente
      
   if @@rowcount = 0 begin
      select @w_error = 710026
      goto ERROR
   end 
end

--- Consulta Periodos que tiene el Cliente 
if @i_operacion = 'C' begin

   --- Validar si existen operaciones Castigadas con Saldo Cero 
   if exists (select 1 from ca_valores_pag, cobis..cl_ente, ca_operacion 
              where vp_periodo   = @i_periodo
              and   vp_cliente   = @w_cliente
              and   vp_cliente   = en_ente
              and   vp_saldo     = 0
              and   vp_operacion = op_operacion
              and   op_estado    = 4
             )
   begin
      select @w_error = 724523
      goto ERROR   
   end
             
   select @w_tabla = codigo  from cobis..cl_tabla where tabla = 'ca_toperacion'

   select @w_registros = count(1),
          @w_total     = max(vp_operacion)
   from ca_valores_pag, cobis..cl_ente, cobis..cl_oficina, cobis..cl_catalogo
   where vp_periodo = @i_periodo
   and vp_cliente   = @w_cliente
   and vp_cliente   = en_ente
   and tabla        = @w_tabla
   and codigo       = vp_toperacion
   and vp_oficina   = of_oficina
     
   select @w_registros, 
          @w_total
   
---LLS 53696 SE quita el Else por que segunel banco debe salir es a 
---          nombre de la empresa no del representante legal
      set rowcount 15
      select vp_periodo,
             en_nomlar, 
             en_ced_ruc, 
             convert(varchar, vp_oficina) + ' - ' + of_nombre , 
             vp_banco, 
             valor, 
             vp_int_pag, 
             vp_imo_pag, 
             vp_saldo,
             vp_operacion
      from ca_valores_pag, cobis..cl_ente, cobis..cl_oficina, cobis..cl_catalogo
      where vp_periodo = @i_periodo
      and vp_cliente   = @w_cliente
      and vp_cliente   = en_ente
      and tabla        = @w_tabla
      and codigo       = vp_toperacion
      and vp_oficina   = of_oficina
      and vp_operacion > @i_secuencial
      order by vp_operacion
      
      if @@rowcount = 0 begin
         set rowcount 0
         select @w_error = 710026
         goto ERROR
      end 
      set rowcount 0
end


ERROR:
if @w_error <> 0 begin
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error

   return @w_error
end

go
