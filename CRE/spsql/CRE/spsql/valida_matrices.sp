/************************************************************************/
/*  Archivo:                valida_matrices.sp                          */
/*  Stored procedure:       sp_valida_matrices                          */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_valida_matrices' and type = 'P')
   drop proc sp_valida_matrices
go


create proc sp_valida_matrices(
   @s_user               login       = null,
   @s_rol                smallint    = null,
   @t_debug              char(1)     = 'N' ,
   @i_ente               int         = null,
   @i_tramite            int         = null,
   @i_tipo_credito       char(2)     = null,
   @i_mercado            catalogo    = null,
   @i_mercado_objetivo   catalogo    = null,
   @i_clase_cca          catalogo    = null,
   @i_toperacion         catalogo    = null,   
   @i_monto_solicitado   money       = null,
   @i_plazo              smallint    = null,   
   @i_concepto           catalogo    = null,   
   @o_spread             float       = null out,
   @o_signo              char(1)     = null out,
   @o_msg                varchar(255)= null out,
   @i_campana            int         = null,        --CCFU REQ 233,236
   @i_destino            catalogo    = null,        --CCFU REQ 233,236
   @i_alianza            int         = 0   ,
   @i_msv                char(1)     = 'N'
   
)
as
declare
   @w_return             int           ,  /* VALOR QUE RETORNA */
   @w_sp_name            varchar(32)   ,  /* NOMBRE STORED PROC*/
   @w_existe             tinyint       ,  /* EXISTE EL REGISTRO*/
   @w_dictamen_mir       varchar(8000) ,   
   @w_spread             float         ,
   @w_msg                varchar(255)  ,
   @w_fecha_proceso      datetime      ,
   @w_error              int           ,
   @w_eje1               varchar(20)   ,
   @w_eje2               varchar(20)   ,
   @w_eje3               varchar(20)   ,
   @w_eje4               varchar(20)   ,
   @w_eje5               varchar(20)   ,
   @w_eje6               varchar(20)   ,
   @w_eje7               varchar(20)   ,
   @w_eje8               varchar(20)   ,
   @w_matriz             varchar(20)   ,
   @w_util_matriz        tinyint       ,
   @w_smlmv              money         ,
   @w_monto              float         ,
   @w_def_pdmir          varchar(30)   ,
   @w_tipo_credito       char(2)       ,
   @w_tplazo             catalogo      ,
   @w_tipo               char (1)      ,
   @w_pl_meses           int           ,
   @w_fecha_ult_can      datetime      ,
   @w_eje9               varchar(20)   ,
   @w_min_op_fecha_ini 	 datetime      , 
   @w_op_banco_aux       cuenta        ,
   @w_rubros             catalogo      ,     --CCFU REQ 233,236
   @w_est_cancelado      tinyint       ,     --CCFU REQ 233,236
   @w_num_creditos       int           ,     --CCFU REQ 233,236
   @w_operacion          int           ,
   @w_signo_negociado    char(1)       ,
   @w_factor_negociado   float         ,
   @w_signo_matriz       char(1)       ,
   @w_tipo_tramite       char(1)       ,
   @w_eje10              varchar(20)
 
   
select @w_matriz = 'TASAS_MAX',
       @w_sp_name = 'sp_valida_matrices'

--  NYMY NR 223

create table #prestamos_cli (
op_banco       cuenta     null,
op_fecha_ini   datetime   null)

create table #nota_cli (
nota           int         null)

/* SALARIO MINIMO LEGAL */
select @w_smlmv = pa_money 
from cobis..cl_parametro 
where pa_nemonico = 'SMLMV'       
       
/* INC 15234 - VALOR DEFAULT PARA PD GESTOR MIR */
select @w_def_pdmir = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'DPDMIR' 
and   pa_producto = 'CRE'
       
select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso
if @w_fecha_proceso is null
begin
   select 
   @w_error = 2110389
   goto ERROR
end

if @i_toperacion is null
begin
   select 
   @w_error = 2110390
   goto ERROR
end

if @i_monto_solicitado is null
begin
   select 
   @w_error = 2110391
   goto ERROR
end

if @i_plazo is null
begin
   select 
   @w_error = 2110392
   goto ERROR
end

if @i_tipo_credito is null
begin
   select 
   @w_error = 2110393
   goto ERROR
end

select 
@w_tplazo  = tr_tipo_plazo,
@w_tipo    = tr_tipo
from   cr_tramite
where  tr_tramite = @i_tramite


if @i_msv = 'S'
begin
   if @w_tipo in ('T', 'O')
	select @w_tipo_credito = 'N'
   else
	select @w_tipo_credito = @i_tipo_credito
end
else
begin
	if exists(select 1
			  from cob_cartera..ca_operacion (nolock) 
			  where op_cliente = @i_ente
			   and op_estado in (1, 3)
			   and datediff(dd, op_fecha_ult_proceso, @w_fecha_proceso) <= 360)
	   select @w_tipo_credito = 'R'
	else
	   select @w_tipo_credito = 'N'
end

if @w_tplazo <> 'M'                                                                                                                                                                                                   
   select @w_pl_meses = @i_plazo * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @w_tplazo) / 30   
else  
   select @w_pl_meses = @i_plazo  


/* NIVEL DE RIESGO */
select 
@w_dictamen_mir = rm_valor 
from cob_credito..cr_respuesta_mir_ws 
where rm_tramite   = @i_tramite
and   rm_variable  = 'pd'
order by rm_fecha_resp asc

-- INC 15324 - SI EL DICTAMEN ES NULO / NO NUMERICO / CERO SE ASIGNA EL VALOR DEFAULT 
if isnumeric(@w_dictamen_mir) = 0
   select @w_dictamen_mir = @w_def_pdmir
else
   if convert(float, @w_dictamen_mir) = 0
      select @w_dictamen_mir = @w_def_pdmir

if @w_dictamen_mir is null
   select @w_dictamen_mir = @w_def_pdmir


/* Verificar si la matrz esta asiganda a la linea de credito */

if @i_campana is not null
begin
   select @w_matriz = ma_matriz
   from cob_cartera..ca_matriz
   where ma_matriz = 'TASA_DEF'
end  

exec @w_error = cob_cartera..sp_matriz_valor
@i_matriz        = 'VAL_MATRIZ',      
@i_fecha_vig     = @w_fecha_proceso,
@i_eje1          = @i_toperacion,   
@i_eje2          = @w_matriz,   
@o_valor         = @w_util_matriz out, --0/1
@o_msg           = @o_msg         out 

if @w_error <> 0  
   return @w_error

if @w_util_matriz = 0 
begin
   if @t_debug = 'S' print 'cr_valimat.sp La matriz '+ @w_matriz +' no es utilizada por la linea:  '  + cast (@i_toperacion as varchar)
   return 0 --> La matriz no es utilizada por la linea
end

select @w_monto = (@i_monto_solicitado/@w_smlmv)

-- NYMR NR 223 se obtiene el credito mas antiguo del cliente

insert  into #prestamos_cli
select 	op_banco, op_fecha_ini
from 	cob_cartera..ca_operacion
where	((op_estado in (1,2,4,9))
or      (op_estado in (3) and op_fecha_ult_proceso >= dateadd(yy,-1,@w_fecha_proceso)))
and	op_cliente  = @i_ente
union
select 	oph_banco, oph_fecha_ini
from 	cob_cartera_his..ca_operacion_his
where	oph_estado in (3)
and 	oph_fecha_ult_proceso >=  dateadd(yy,-1,@w_fecha_proceso)
and	oph_cliente  = @i_ente


--print '@w_min_op_fecha_ini  ' + cast(@w_min_op_fecha_ini  as varchar)
--print '@w_op_banco_aux  ' + cast(@w_op_banco_aux  as varchar)

-- NYMR NR 223 se obtiene la nota asociada a credito mas antiguo }
-- si no existe se retorna la maxima calificacion

insert  into #nota_cli
select  ci_nota
from    cob_credito..cr_califica_int_mod ,
	#prestamos_cli
where   ci_banco            = op_banco
and     ci_cliente          = @i_ente
union
select  ci_nota
from    cob_credito_his..cr_califica_int_mod_his,
	#prestamos_cli
where   ci_banco            = op_banco
and     ci_cliente          = @i_ente

select  @w_eje9  = isnull(min(nota),5)
from    #nota_cli


select
@w_eje1  = convert(varchar(20),@w_tipo_credito),
@w_eje2  = convert(varchar(20),@i_toperacion),
@w_eje3  = convert(varchar(20),@i_mercado),
@w_eje4  = convert(varchar(20),@i_mercado_objetivo),
@w_eje5  = convert(varchar(20),@i_clase_cca),
@w_eje6  = convert(varchar(20),@w_dictamen_mir),
@w_eje7  = convert(varchar(20),@w_monto),
@w_eje8  = convert(varchar(20),@w_pl_meses),
@w_eje10 = convert(varchar(20),@i_alianza)


if @t_debug = 'S' print '@w_eje1 ' + cast(@w_eje1  as varchar)
if @t_debug = 'S' print '@w_eje2 ' + cast(@w_eje2  as varchar)
if @t_debug = 'S' print '@w_eje3 ' + cast(@w_eje3  as varchar)
if @t_debug = 'S' print '@w_eje4 ' + cast(@w_eje4  as varchar)
if @t_debug = 'S' print '@w_eje5 ' + cast(@w_eje5  as varchar)
if @t_debug = 'S' print '@w_eje6 ' + cast(@w_eje6  as varchar)
if @t_debug = 'S' print '@w_eje7 ' + cast(@w_eje7  as varchar)
if @t_debug = 'S' print '@w_eje8 ' + cast(@w_eje8  as varchar)
if @t_debug = 'S' print '@w_eje9 ' + cast(@w_eje9  as varchar)
if @t_debug = 'S' print '@w_eje10' + cast(@w_eje10 as varchar)

/* LLAMADA PARA OBTENER EL SPREAD */


--select 'cr_valimat.sp Campaña', @i_campana, ' Aliaza ', @i_alianza

if @i_campana is null
begin 
   --select 'ELSE  ---> ' , @w_matriz, @w_eje1, @w_eje2, @w_eje3, @w_eje4, @w_eje5, @w_eje6, @w_eje7, @w_eje8, @w_eje10

   exec @w_error  = cob_cartera..sp_matriz_valor
         @i_matriz      = @w_matriz,         
         @i_fecha_vig   = @w_fecha_proceso,   
         @i_eje1        = @w_eje1,
         @i_eje2        = @w_eje2,
         @i_eje3        = @w_eje3,
         @i_eje4        = @w_eje4,
         @i_eje5        = @w_eje5,
         @i_eje6        = @w_eje6,
         @i_eje7        = @w_eje7,
         @i_eje8        = @w_eje8,
         @i_eje9        = @w_eje9,
         @i_eje10       = @w_eje10,
         @o_valor       = @w_spread out, 
         @o_msg         = @w_msg    out
         
   if @w_error<>0 return @w_error
   
   if @w_spread >= 0
      select @o_signo = '+'
   else
      select @o_signo = '-'   
   
   select @o_spread = abs(@w_spread)

   return 0
end 

   --select @w_matriz, @w_eje1, @w_eje2, @w_eje3, @w_eje4, @w_eje5, @w_eje6, @w_eje7, @w_eje8, @w_eje10
   
   select @w_operacion    = op_operacion,
          @w_tipo_tramite = tr_tipo 
   from cob_cartera..ca_operacion, cob_credito..cr_tramite
   where op_tramite = @i_tramite
   and   op_tramite = tr_tramite 

if @i_campana is not null
begin

   select @w_signo_negociado =ro_signo ,
          @w_factor_negociado=ro_factor
   from cob_cartera..ca_rubro_op 
   where ro_operacion =@w_operacion 
   and ro_tipo_rubro='I' 


   select @w_matriz = ma_matriz                  
   from cob_cartera..ca_matriz    
   where ma_matriz = 'TASA_DEF'
   
   select @w_rubros = co_concepto 
   from cob_cartera..ca_concepto 
   where co_categoria='I'
   
   exec @w_error = cob_cartera..sp_estados_cca
   @o_est_cancelado  = @w_est_cancelado out
   
   if @w_error <> 0 begin
      select @o_msg = 'ERROR AL EJECUTAR sp_estados_cca'
      return @w_error
   end
   
   select @w_num_creditos = count(1) 
   from cob_cartera..ca_operacion 
   where op_estado=@w_est_cancelado
   and   op_cliente = @i_ente 


   if ((@i_tramite > 0 and  @i_campana <> 0 )or (@i_tramite is null and  @i_campana is not null ) ) 
   begin
      
      if @t_debug = 'S' begin
       print 'cr_valimat.sp    @w_matriz  ' + cast (@w_matriz as varchar) +  ' @i_toperacion= eje1: ' + cast (@i_toperacion as varchar)
       print 'cr_valimat.sp    @i_campana= 2 ' + cast (@i_campana as varchar) +  ' @w_rubros= eje3: ' + cast (@w_rubros as varchar)
       print 'cr_valimat.sp    @i_clase_cca= eje4 ' + cast (@i_clase_cca as varchar) +  ' @i_destino= eje5: ' + cast (@i_destino as varchar)
       print 'cr_valimat.sp    @w_num_creditos=eje6 ' + cast (@w_num_creditos as varchar) +  '@w_monto = eje7: ' + cast (@w_monto as varchar)
       print 'cr_valimat.sp    @w_tipo_credito=eje8 ' + cast (@w_tipo_credito as varchar) +  '@w_tipo_tramite=eje9: ' + cast (@w_tipo_tramite as varchar)
      end
      
      exec @w_error = cob_cartera..sp_matriz_valor                   
      @i_matriz         = @w_matriz,             
      @i_fecha_vig      = @w_fecha_proceso,             
      @i_eje1           = @i_toperacion,         
      @i_eje2           = @i_campana,            
      @i_eje3           = @w_rubros,             
      @i_eje4           = @i_clase_cca,          
      @i_eje5           = @i_destino,            
      @i_eje6           = @w_num_creditos,       
      @i_eje7           = @w_monto,
      @i_eje8           = @w_tipo_credito,
      @i_eje9           = @w_tipo_tramite,
      @o_valor          = @w_spread out,         
      @o_msg            = @w_msg out   

      if @w_error<>0 return @w_error
   
      if @w_spread < 0 begin
         select @w_signo_matriz = '-'
      end  else begin 
         select @w_signo_matriz = '+'
      end

      select @o_spread = abs(@w_spread),
             @o_signo  = @w_signo_matriz

      if @t_debug = 'S' print 'entro  tramite  > 0 spread  ' + cast( @o_spread as varchar) + ' tramite: ' + cast( @i_tramite as varchar)      

   end
   else 
   begin 
     if ((@i_tramite <> 0 and @i_campana<> 0) or (@i_tramite is not null and  @i_campana is not null )  )
     begin
       select @o_spread = abs(@w_factor_negociado),
              @o_signo  = @w_signo_negociado

       if @t_debug = 'S' print 'entro  tramite  < no es 0 es mayor ' + cast( @o_spread as varchar)
     end
   end
end
else begin 
     exec @w_error  = cob_cartera..sp_matriz_valor
         @i_matriz      = @w_matriz,         
         @i_fecha_vig   = @w_fecha_proceso,   
         @i_eje1        = @w_eje1,
         @i_eje2        = @w_eje2,
         @i_eje3        = @w_eje3,
         @i_eje4        = @w_eje4,
         @i_eje5        = @w_eje5,
         @i_eje6        = @w_eje6,
         @i_eje7        = @w_eje7,
         @i_eje8        = @w_eje8,
         @i_eje9        = @w_eje9,
         @o_valor       = @w_spread out, 
         @o_msg         = @w_msg    out
         
      if @w_error<>0 return @w_error
   
      if @w_spread >= 0
         select @o_signo = '+'
      else
         select @o_signo = '-'   
   
      select @o_spread = abs(@w_spread)
end       

return 0


ERROR:

exec cobis..sp_cerror
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error


GO
