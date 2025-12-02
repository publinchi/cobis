/************************************************************************/
/*	Nombre Fisico:		casuspe.sp    									*/
/*	Nombre Logico:		sp_suspension_causacion							*/
/*	Base de datos:		cob_cartera										*/
/*	Producto: 			Credito y Cartera								*/
/*	Disenado por:  		Xavier Maldonado								*/
/*	Fecha de escritura:	Julio. 2001. 									*/
/************************************************************************/
/*				IMPORTANTE												*/
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*		Fecha			Autor				Razon						*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go


create table #cr_operacion_aux (
co_producto                    tinyint,
co_toperacion                  varchar(64),
co_moneda                      tinyint,
co_cod_cliente                 int,
co_operacion                   int,
co_num_op_banco                varchar(64),
co_clase                       varchar(10),
co_oficina                     smallint,
co_calif_ant                   char(1),
co_calif_sug                   char(1),
co_calif_final                 char(1),
co_usuario                     varchar(14),
co_fecha                       datetime,
co_calificado                  char(1)
)       
go

if exists (select 1 from sysobjects where name = 'sp_suspension_causacion')
   drop proc sp_suspension_causacion
go

create proc sp_suspension_causacion(
@s_user		     	login,
@s_term		     	varchar(30),
@s_date		     	datetime,
@s_ofi		     	smallint,
@i_banco             	cuenta   = null, 
@s_sesn              	int      = null
)   
as

declare 
@w_error          	int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_fecha_proceso        datetime,
@w_fecha_ult_proceso    datetime,    
@w_fecha_fin_mes        datetime,
@w_co_producto          tinyint,
@w_co_toperacion        catalogo,
@w_co_moneda            tinyint,     
@w_co_cod_cliente       int,
@w_co_operacion         int, 
@w_co_num_op_banco      varchar(24), 
@w_co_clase             varchar(10),      
@w_co_oficina           smallint,
@w_co_calif_ant         char(1), 
@w_co_calif_sug         char(1),    
@w_co_calif_final       char(1),
@w_co_usuario           varchar(14), 
@w_co_fecha             datetime,     
@w_co_calificado        char(1),
@w_suspension           catalogo,
@w_situacion_cliente    catalogo,
@w_dias_mas             tinyint,
@w_estado               tinyint,
@w_est_suspenso         tinyint,
@w_est_vigente          tinyint,
@w_est_vencido          tinyint,
@w_est_castigado         tinyint,
@w_oficial              smallint,
@w_calificacion         catalogo,
@w_fecha_cierre         datetime,
@w_rowcount             int


/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name       = 'sp_suspension_causacion'

select @w_est_suspenso  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'SUSPENSO'
if @@rowcount = 0 begin select @w_error = 710251 goto ERROR end

select @w_est_vigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_castigado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


insert into #cr_operacion_aux
select 
co_producto,  co_toperacion,   co_moneda,      co_cod_cliente,
co_operacion, co_num_op_banco, co_clase,       co_oficina,
co_calif_ant, co_calif_sug,    co_calif_final, co_usuario,
co_fecha,     co_calificado
from  cob_credito..cr_calificacion_op
where (co_num_op_banco = @i_banco or @i_banco is null)
and   co_producto = 7
and   co_calif_ant <> co_calif_final
and   co_calificado = 'S'


/* CURSO PARA LEER TODAS LAS OPERACIONES A PROCESAR */
declare cursor_operacion cursor for
select 
co_producto,  co_toperacion,   co_moneda,      co_cod_cliente,
co_operacion, co_num_op_banco, co_clase,       co_oficina,
co_calif_ant, co_calif_sug,    co_calif_final, co_usuario, 
co_fecha,     co_calificado
from   #cr_operacion_aux
for read only

open  cursor_operacion

fetch cursor_operacion into 
@w_co_producto,  @w_co_toperacion,   @w_co_moneda,     @w_co_cod_cliente,
@w_co_operacion, @w_co_num_op_banco, @w_co_clase,      @w_co_oficina,
@w_co_calif_ant, @w_co_calif_sug,    @w_co_calif_final,@w_co_usuario, 
@w_co_fecha,     @w_co_calificado

while @@fetch_status = 0 begin   

   if @@fetch_status = -1 begin    
      select @w_error = 70899
      return 0
   end   

 
   /* CONDICIONES PARA SUSPENSO DE CAUSACION */
   /******************************************/

   select 
   @w_suspension = ps_suspension
   from cob_credito..cr_param_suspension
   where ps_clase = @w_co_clase
   if @@rowcount = 0 begin
      select @w_error = 710248
      goto ERROR
   end

   select @w_situacion_cliente = en_situacion_cliente
   from cobis..cl_ente
   where en_ente = @w_co_cod_cliente
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 begin
      select @w_error = 710249
      goto ERROR
   end

   select
   @w_estado       = op_estado,
   @w_oficial      = op_oficial,
   @w_calificacion = op_calificacion
   from cob_cartera..ca_operacion
   where op_operacion = @w_co_operacion
   and   op_banco     = @w_co_num_op_banco
   and   op_cliente   = @w_co_cod_cliente
   if @@rowcount = 0 begin
      select @w_error = 710250
      goto ERROR
   end


   if (@w_co_calif_final >= @w_suspension) or (@w_situacion_cliente in ('IEN','FDO')) begin

      select @w_dias_mas = (-1)*(datepart(dd,getdate()))
      select @w_fecha_fin_mes = dateadd(dd,@w_dias_mas, getdate())

      exec @w_return       = sp_fecha_valor
      @i_fecha_valor       = @w_fecha_fin_mes,
      @i_banco             = @w_co_num_op_banco,
      @i_secuencial        = NULL,
      @i_operacion         = 'F', 
      @i_observacion       = 'SUSPENSION DE CAUSACION',
      @i_susp_causacion    = 'N',
      @i_en_linea          = 'N'
	
      if @w_return <> 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      exec @w_return         = sp_batch
      @s_user                = @s_user,
      @s_term                = @s_term,
      @s_date	             = @s_date,
      @s_ofi	             = @s_ofi,
      @i_en_linea            = 'S',
      @i_banco               = @w_co_num_op_banco,
      @i_siguiente_dia       = @w_fecha_cierre,
      @i_aplicar_clausula    = 'N',
      @i_aplicar_fecha_valor = 'S',
      @i_modo                = 'F'

      if @w_return <> 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      end else 
          if @w_co_calif_final < @w_suspension begin
             exec @w_return = sp_fecha_valor
             @i_fecha_valor = @w_fecha_fin_mes,
   	     @i_banco	    = @w_co_num_op_banco,
	     @i_secuencial  = NULL,
             @i_operacion   = 'F', 
	     @i_observacion = 'SUSPENSION DE CAUSACION',
             @i_susp_causacion    = 'N',
             @i_en_linea          = 'N'	

             if @w_return <> 0 begin
                select @w_error = @w_return
                goto ERROR
             end


             update ca_operacion
             set op_calificacion = @w_calificacion 
             from cob_cartera..ca_operacion
             where op_operacion = @w_co_operacion
             and   op_banco     = @w_co_num_op_banco
             and   op_cliente   = @w_co_cod_cliente

             
             exec @w_return         = sp_batch
             @s_user                = @s_user,
             @s_term                = @s_term,
             @s_date	            = @s_date,
             @s_ofi	            = @s_ofi,
             @i_en_linea            = 'S',
             @i_banco               = @w_co_num_op_banco,
             @i_siguiente_dia       = @w_fecha_cierre,
             @i_aplicar_clausula    = 'N',
             @i_aplicar_fecha_valor = 'S',
             @i_modo                = 'F'

             if @w_return <> 0 begin
                select @w_error = @w_return
                goto ERROR
             end
    end 


   fetch cursor_operacion into 
   @w_co_producto,  @w_co_toperacion,   @w_co_moneda,     @w_co_cod_cliente,
   @w_co_operacion, @w_co_num_op_banco, @w_co_clase,      @w_co_oficina,
   @w_co_calif_ant, @w_co_calif_sug,    @w_co_calif_final,@w_co_usuario, 
   @w_co_fecha,     @w_co_calificado

end /* cursor_operacion */
close cursor_operacion
deallocate cursor_operacion

return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error

return @w_error


go


