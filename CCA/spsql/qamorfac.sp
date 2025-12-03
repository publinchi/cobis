/************************************************************************/
/*      Archivo:                qamorfac.sp                             */
/*      Stored procedure:       sp_cargar_facturas                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Diego Aguilar                           */
/*      Fecha de escritura:     Sep. 1999                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Consulta la tabla cr_facturas de credito la cual tiene las      */
/*      facturas de factoring asociados al tramite                      */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cargar_facturas')
	drop proc sp_cargar_facturas
go
create proc sp_cargar_facturas
@s_user                 login = null,
@s_term                 login = null,
@s_date                 datetime = null,
@s_ofi                  smallint = null,
@i_banco		cuenta,
@i_dividendo            tinyint = 0,
@i_formato_fecha        int  = null,
@i_opcion               char(1)  = null,
@i_grupo_fact           int = null,
@i_no_grupo             int = 0,
@i_tramite_ficticio     int = null
as
declare 
@w_error		int ,
@w_return		int ,
@w_operacionca          int ,
@w_sp_name		descripcion,
@w_dias                 int,
@w_valor                money,
@w_banco                cuenta

/* VARIABLES INICIALES */
select 
@w_sp_name = 'sp_cargar_facturas'

/* DATOS GENERALES DEL PRESTAMO */
select @w_operacionca = opt_operacion
from ca_operacion_tmp
where opt_banco = @i_banco 

if @@rowcount = 0 begin
   select @w_error = 701025
   GOTO ERROR 
end

if not exists(select 1 from cob_credito..cr_facturas
   where fa_tramite = @i_tramite_ficticio) begin 
   select @w_error = 710149
   GOTO ERROR 
end

if @i_opcion = 'S' begin --CARGAR GRUPOS
   set rowcount 20
   select '# de Grupo' = convert(varchar(7),fa_grupo),
   'Monto del Grupo' = fa_valor,
   'Fecha Inicio Negocio' = convert(varchar(10),fa_fecini_neg,@i_formato_fecha),
   'Fecha Fin Negocio' = convert(varchar(10),fa_fecfin_neg,@i_formato_fecha)
   from cob_credito..cr_facturas
   where fa_tramite = @i_tramite_ficticio
   and fa_grupo > @i_grupo_fact
   and fa_grupo != @i_no_grupo
   and fa_usada = 'N'
   order by fa_tramite,fa_grupo
end

if @i_opcion = 'U' begin --ACTUALIZAR CUAL ES EL GRUPO ESCOGIDO
   update ca_operacion_tmp 
   set opt_grupo_fact = @i_grupo_fact
   where opt_operacion = @w_operacionca

   update cob_credito..cr_facturas 
   set fa_usada = 'S'
   where fa_tramite = @i_tramite_ficticio
   and fa_grupo   = @i_grupo_fact
end

if @i_opcion = 'R' begin --DESHACER EL GRUPO ESCOGIDO
   update ca_operacion_tmp 
   set opt_grupo_fact = null
   where opt_operacion = @w_operacionca

   update cob_credito..cr_facturas 
   set fa_usada = 'N'
   where fa_tramite = @i_tramite_ficticio
   and fa_grupo   = @i_grupo_fact
end



if @i_opcion = 'C' begin --CARGAR LA FACTURA ESCOGIDA
   select @w_valor = fa_valor,
   @w_dias = datediff(dd,fa_fecini_neg,fa_fecfin_neg)
   from cob_credito..cr_facturas
   where fa_tramite = @i_tramite_ficticio
   and fa_grupo   = @i_grupo_fact

   select @w_banco = op_banco
   from ca_operacion
   where op_operacion = @w_operacionca

   update ca_operacion_tmp
   set opt_tplazo      = 'D',
   opt_plazo           = @w_dias,
   opt_tdividendo      = 'D',
   opt_periodo_cap     = @w_dias,
   opt_periodo_int     = @w_dias,
   opt_monto           = @w_valor,
   opt_monto_aprobado  = @w_valor,
   opt_cuota           = @w_valor
   where opt_operacion = @w_operacionca

   update ca_rubro_op_tmp
   set rot_valor = @w_valor
   where rot_operacion = @w_operacionca
   and rot_tipo_rubro = 'C'

   select 'D',
          @w_dias,
          'D',
          @w_dias,
          @w_dias,
          @w_valor
   
   exec @w_return = sp_qamortmp_fac
   @i_banco             = @w_banco, 
   @i_operacion         = @w_operacionca ,
   @i_dividendo         = 0,
   @i_formato_fecha     = @i_formato_fecha, 
   @i_grupo_fact        = @i_grupo_fact,
   @i_tramite_ficticio  = @i_tramite_ficticio

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go