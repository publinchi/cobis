
/************************************************************************/
/*	Archivo: 		qrtran.sp				*/
/*	Stored procedure: 	sp_consulta_trn      		        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Z. Bedon 	  		        */
/*	Fecha de escritura: 	23/Dic/1997				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Consulta las transacciones de una operacion a la fecha dada   	*/
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA     AUTOR             RAZON                                   */
/*  12-01-12  L.Moreno          293-No mostrar tx REC en reversos       */
/*  23-07-19  L.Ponce           Reversas Pagos Grupales e Interciclos   */
/*  03-04-19  L.Ponce           Se incluye tran REJ en consultas        */
/*  18-09-20  Sandro Vallejo    Considerar API                          */
/************************************************************************/


use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_consulta_trn')
	drop proc sp_consulta_trn
go

create proc sp_consulta_trn (
@s_date			        datetime    = null,
@s_culture              varchar(10) = 'NEUTRAL',  --Internacionalizacion
@t_trn                  int         = null,       --LPO CDIG Cambio de Servicios a Blis                  
@i_banco		        cuenta,
@i_operacion            char(1)	    = null,
@i_fecha_valor	        datetime    = null,
@i_secuencial           int 	    = 0,
@i_formato_fecha        int         = 101,
@i_tipo                 char(1)     = null,
@i_grupal               char(1)     = NULL,
@i_api                  char(1)     = 'N'   -- SVA API
)        
as
declare 
@w_sp_name		        varchar (32),
@w_return		        int,
@w_error		        int,
@w_secuencial		    int,
@w_operacionca		    int,
@w_fecha_prox           datetime,
@w_tamanio              int,
@w_fecha_liq            datetime,
@w_fecha_max            datetime,
@w_fecha_contable       datetime,
@w_fecha_hoy            datetime,
@w_fecha_credito        datetime,
@w_periodo              int,

@w_fecha_proceso        datetime,   --HRE Ref 005 05/03/2002
@w_dias_contr           int,        --HRE Ref 005 05/03/2002
@w_dias_hoy             int,         --HRE Ref 005 05/03/2002 
@w_rowcount             int,
@w_estado               tinyint,
@w_estado_desc          varchar(64)

select @w_sp_name   = 'sp_consulta_trn'

/* Ref 005 05/03/2002 */
select @w_dias_contr = pa_smallint
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'DFVAL'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
begin
   exec cobis..sp_cerror
       @t_debug='N',
       @t_file = null,
       @t_from =@w_sp_name,
       @i_num = 710215
--     @i_cuenta= ' '
       return 1
end

select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7  -- 7 pertence a Cartera

/*Fin Ref 005*/
 

/*  VERIFICACION DE EXISTENCIAS  */
select	
@w_operacionca  = op_operacion,
@w_fecha_prox   = op_fecha_ult_proceso
from  ca_operacion
where op_banco = @i_banco

if @@rowcount = 0 begin
   select @w_error = 701025
   goto ERROR
end  

if @i_api = 'N' -- SVA API
begin
   /* CABECERA DE LA PANTALLA DE REVERSA O FECHA VALOR */
   if exists (select 1 from ca_ciclo where ci_prestamo = @i_banco) 
   begin
      select @w_estado = min(op_estado)
      from   ca_operacion, ca_det_ciclo
      where  op_operacion = dc_operacion
      and    dc_referencia_grupal = @i_banco 
   end 
   else 
   begin
      select @w_estado = op_estado 
      from   ca_operacion 
      where  op_banco = @i_banco
   end

   select @w_estado_desc = es_descripcion 
   from   ca_estado 
   where  es_codigo = @w_estado

   select 
   op_toperacion ,   
   valor,
   op_moneda,
   mo_descripcion,
   op_cliente,
   op_nombre, 
   @w_estado_desc,
   substring(convert(varchar,op_fecha_ult_proceso, @i_formato_fecha),1,15) ---EPB:oct-16-2001 formato fecha
   from   ca_operacion, cobis..cl_catalogo, cobis..cl_moneda
   where  op_banco      = @i_banco
   and    op_toperacion = codigo        
   and    tabla         = (select distinct(codigo) from cobis..cl_tabla where tabla = 'ca_toperacion')
   and    op_moneda     = mo_moneda
end

if @i_operacion = 'S' 
begin
--LPO TEC Se comenta porque no aplica en Te Creemos
/*   if @i_grupal ='G'
   begin
		 select 
		 'Transaccion' = 'PAG', 
		 'Secuencial'  = co_secuencial,
		 'Operacion'   = substring(op_banco,1,17),
		 'Fecha Trn'   = substring(convert(varchar,co_fecha_proceso, @i_formato_fecha),1,15),
		 'Fecha Ref'   = substring(convert(varchar,co_fecha_valor, @i_formato_fecha),1,15),
		 'Estado '     = case when exists (select 1 
                        from ca_corresponsal_trn x 
                        where x.co_trn_id_corresp = y.co_trn_id_corresp 
                        and x.co_tipo = 'PG' 
                        and co_accion = 'R' 
                        and co_estado in ('I')) then 'REV.PEND X PROCESAR' when  co_estado = 'I' then 'INGRESADO' else 'PROCESADO' end,
		 'Usuario'    = co_login
		from cob_cartera..ca_corresponsal_trn y, cob_cartera..ca_operacion
		where co_codigo_interno = op_operacion
		and op_banco  =  @i_banco
        and co_tipo   = 'PG'
		and co_estado in ('P','I')
		and co_accion <> 'R'  
	    and co_secuencial > @i_secuencial
        order by co_fecha_proceso, co_secuencial
   end
   else
   begin
*/
   select @w_tamanio = -100

   select @w_fecha_liq = min(tr_fecha_ref),
          @w_fecha_max = max(tr_fecha_ref)
   from   ca_transaccion
   where  tr_banco   = @i_banco
   and    tr_estado <> 'RV'

   if @i_api = 'N' -- SVA API
      set rowcount 20
   else
      set rowcount 0   
	   
   select 'Transaccion' = tr_tran,
	      'Secuencial'  = tr_secuencial,
	      'Operacion'   = substring(tr_banco,1,17),
	      'Fecha Trn'   = substring(convert(varchar,tr_fecha_mov, @i_formato_fecha),1,15),
	      'Fecha Ref'   = substring(convert(varchar,tr_fecha_ref, @i_formato_fecha),1,15),
	      'Estado '     = tr_estado,
	      'Usuario '    = tr_usuario
   from   ca_transaccion, ca_tipo_trn
   where  tr_banco      = @i_banco
   and    tr_secuencial > @i_secuencial
   and    tr_tran       = tt_codigo
   and    tt_reversa    = 'S'
 --and   tr_tran not in ('EST','REJ','CMO','REC') --LPO CDIG Se incluye tran REJ en consultas
   and   tr_tran   not in ('EST','CMO','REC') --LPO CDIG Se incluye tran REJ en consultas	   
   and   tr_estado    <> 'RV'
 --and   tr_fecha_mov between dateadd(dd,-@w_dias_contr,@w_fecha_proceso) and @w_fecha_proceso  --HRE Ref 005 05/03/2002
   order by tr_secuencial

   select @w_tamanio = @@rowcount

   if @i_api = 'N' -- SVA API
   begin
	  select @w_tamanio = 20 - @w_tamanio

      if @w_tamanio = 20
         select @w_tamanio * -1
	  else
	     select @w_tamanio
   end
   else
      select @w_tamanio
end

if @i_operacion = 'R' 
begin
   select @w_tamanio = -100

   select @w_fecha_liq = min(tr_fecha_ref),
          @w_fecha_max = max(tr_fecha_ref)
   from   ca_transaccion
   where  tr_banco   = @i_banco
   and    tr_estado <> 'RV'

   if @i_api = 'N' -- SVA API
      set rowcount 20
   else
      set rowcount 0   
	   
   select 'Transaccion' = tr_tran,
	      'Secuencial'  = tr_secuencial,
	      'Operacion'   = substring(tr_banco,1,17),
	      'Fecha Trn'   = substring(convert(varchar,tr_fecha_mov, @i_formato_fecha),1,15),
	      'Fecha Ref'   = substring(convert(varchar,tr_fecha_ref, @i_formato_fecha),1,15),
	      'Estado '     = tr_estado,
	      'Usuario '    = tr_usuario
   from   ca_transaccion, ca_tipo_trn
   where  tr_banco      = @i_banco
   and    tr_secuencial > @i_secuencial
   and    tr_tran       = tt_codigo
   and    tt_reversa    = 'S'
   and   tr_tran   not in ('EST','CMO','REC') --LPO CDIG Se incluye tran REJ en consultas	   
   and   tr_estado    = 'RV'
   order by tr_secuencial

   select @w_tamanio = @@rowcount

   if @i_api = 'N' -- SVA API
   begin
	  select @w_tamanio = 20 - @w_tamanio

      if @w_tamanio = 20
         select @w_tamanio * -1
	  else
	     select @w_tamanio
   end
   else
      select @w_tamanio
end

if @i_operacion = 'P' 
begin
   select @w_tamanio = -100

   select @w_fecha_liq = min(tr_fecha_ref),
          @w_fecha_max = max(tr_fecha_ref)
   from   ca_transaccion
   where  tr_banco   = @i_banco
   and    tr_estado <> 'RV'

   if @i_api = 'N' -- SVA API
      set rowcount 20
   else
      set rowcount 0   
	   
   select     'Fecha Trn'   = substring(convert(varchar,tp_fecha_mov, @i_formato_fecha),1,15),
	      'Fecha Ref'   = substring(convert(varchar,tp_fecha_ref, @i_formato_fecha),1,15),
              'Dividendo'   = tp_dividendo, 
              'Concepto'    = tp_concepto, 
              'Moneda'      = tp_moneda, 
              'Monto'       = tp_monto, 
              'Monto MN'    = tp_monto_mn, 
              'Estado'      = tp_estado
     FROM ca_transaccion_prv
    WHERE tp_operacion = @w_operacionca
    order by tp_dividendo, tp_concepto

   select @w_tamanio = @@rowcount

   if @i_api = 'N' -- SVA API
   begin
	  select @w_tamanio = 20 - @w_tamanio

      if @w_tamanio = 20
         select @w_tamanio * -1
	  else
	     select @w_tamanio
   end
   else
      select @w_tamanio
end

if @i_operacion = 'D'
begin
   select 'Dividendo'  = dtr_dividendo,
          'Rubro'      = dtr_concepto,
          'Estado'     = dtr_estado,
          'Moneda'     = dtr_moneda,
          'Monto'      = dtr_monto,
          'Monto MN'   = dtr_monto_mn,
          'Codvalor'   = dtr_codvalor,
          'Afectacion' = dtr_afectacion,
          'Cuenta'     = dtr_cuenta,
          'Beneficiario' = dtr_beneficiario
    from ca_det_trn
   where dtr_operacion  = @w_operacionca
     and dtr_secuencial = @i_secuencial
   ORDER BY dtr_dividendo, dtr_concepto, dtr_estado  
end

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug   = 'N',
   @t_from    = @w_sp_name,
   @s_culture = @s_culture, 
   @i_num     = @w_error
return @w_error

go
