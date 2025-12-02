/************************************************************************/
/*      Archivo:                paramatriz.sp                           */
/*      Stored procedure:       sp_parametros_matriz                    */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jonnatan Pe¤a                           */
/*      Fecha de escritura:     Mar. 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP".                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera el control de las operaciones bajo los parametros        */
/*      de lineas de credito que tengan mas de un rango dentro de       */
/*      su parametrizacion.                                             */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_parametros_matriz')
   drop proc sp_parametros_matriz
go
---INC 113602 OCT.2013
create proc sp_parametros_matriz 
   @i_fecha          smalldatetime,  
   @i_toperacion     catalogo,
   @i_plazo          int,
   @i_tplazo         char(1),
   @i_monto_valida   float , ---money,
   @i_matriz         catalogo = 'PLAZO_MAX',
   @i_cliente        int      = null,
   @o_msg            mensaje out

as

declare 
   @w_sp_name         varchar(32),
   @w_error           int, 
   @w_msg             varchar(100),
   @w_smv             float , --money,
   @w_monto_param     decimal (20,10), ---float, 
   @w_plazo_meses     int,
   @w_meses_param     int,
   @w_plazo_min       int,
   @w_matriz          catalogo,
   @w_util_matriz     char(1),
   @w_tipo_empleado   varchar(10),
   @w_tipo_persona    varchar(10),
   @w_salario         float , ---money,
   @w_valida_salario  char(1),
   @w_monto_validar   float, ---money,
   @w_salario_smlv    money,
   @w_td_factor       smallint
                        
select @w_sp_name        = 'sp_parametros_matriz' ,
       @w_matriz         = @i_matriz,
       @w_salario        = null,
       @w_valida_salario = null      

if exists (
select 1 from ca_default_toperacion
where dt_tipo         = 'G'
and   dt_nace_vencida = 'S'
and   dt_toperacion   = @i_toperacion
and   dt_moneda       = 0)
   return 0

select @w_smv    = pa_money 
from   cobis..cl_parametro
where  pa_producto  = 'ADM' 
and    pa_nemonico  = 'SMV'

-- Verificar por Cliente cuando es Empleado 
select 
@w_tipo_empleado = pa_char
from  cobis..cl_parametro
where pa_producto = 'MIS'
and   pa_nemonico = 'TIPFUN'

select 
@w_tipo_persona    = p_tipo_persona
from   cobis..cl_ente
where  en_ente  = @i_cliente

--Es Empleado de Bancamia
if  @w_tipo_empleado = @w_tipo_persona    
and exists (select 1
            from cob_credito..cr_corresp_sib 
            where tabla  = 'T115'
            and   codigo = @i_toperacion)
begin
   select @w_matriz = 'PLAZO_EMP' 
   if exists(select 1
             from  ca_default_toperacion
             where dt_toperacion    = @i_toperacion
             and   dt_subtipo_linea = '4')
   begin
      select 
      @w_salario = isnull(tr_sueldo, 0)
      from cobis..cl_trabajo
      where tr_persona = @i_cliente
      
      if @w_salario = 0 or @w_salario is null begin
         select @o_msg = 'EL FUNCIONARIO NO TIENE SALARIO INGRESADO'
         return  703126      
      end
      
      select @w_monto_param    = @w_salario / @w_smv

      exec @w_error = sp_matriz_valor
      @i_matriz        = 'MONTO_EMP',      
      @i_fecha_vig     = @i_fecha,
      @i_eje1          = @i_toperacion,   
      @i_eje2          = @w_monto_param,   
      @o_valor         = @w_salario_smlv out,
      @o_msg           = @o_msg          out

      select @w_monto_validar  = @w_salario * @w_salario_smlv

      if @i_monto_valida > @w_monto_validar begin
         select @o_msg = 'EL MONTO SOLICTADO EXCEDE EL PERMITIDO PARA LOS SALARIOS MINIMOS DEL FUNCIONARIO: Monto Solicitado SMLV' + cast (@i_monto_valida as varchar) + ' Salarios Funcionario SMLV' + cast (@w_monto_validar as varchar)
         return  703126
      end 

      select @w_valida_salario = 'S'

   end
   else begin
      select @w_monto_param    = @i_monto_valida/@w_smv
      select @w_salario_smlv   = 0.00
      select @w_valida_salario = 'N'      
   end

end

if @w_matriz <> 'PLAZO_EMP' 
begin
  select @w_salario_smlv   = null
  select @w_valida_salario = null
end

select @w_monto_param    = convert(float,@i_monto_valida)/convert(float,@w_smv)


--- Verificar si la matrz esta asiganda a la linea de credito 

exec @w_error = sp_matriz_valor
@i_matriz        = 'VAL_MATRIZ',      
@i_fecha_vig     = @i_fecha,
@i_eje1          = @i_toperacion,   
@i_eje2          = @w_matriz,   
@o_valor         = @w_util_matriz out,
@o_msg           = @o_msg         out 

if @w_util_matriz = 0 return 0 --> La matriz no es utilizada por la linea

select @w_plazo_min = dt_plazo_min 
from ca_default_toperacion
where dt_toperacion  = @i_toperacion
and   dt_moneda     = 0
   
if @i_tplazo <> 'M'
begin
	select @w_td_factor = td_factor from ca_tdividendo where td_tdividendo = @i_tplazo
   select @w_plazo_meses = (@i_plazo * @w_td_factor) / 30
end
else  
   select @w_plazo_meses = @i_plazo  

---print ' paramatriz.sp @w_salario_smlv  : '  + cast(@w_salario_smlv as varchar) +  ' @w_monto_param  : ' + cast ( @w_monto_param as varchar)

exec @w_error = sp_matriz_valor
@i_matriz      = @w_matriz,     
@i_fecha_vig   = @i_fecha,
@i_eje1        = @i_toperacion,   
@i_eje2        = @w_monto_param,     
@i_eje3        = @w_valida_salario,
@i_eje4        = @w_salario_smlv,
@o_valor       = @w_meses_param out,
@o_msg         = @o_msg         out   

if @w_error <> 0  return @w_error
if @w_meses_param <= 0 begin
   select @o_msg   = 'DATOS NO PARAMETRIZADOS PARA DETERMINAR PLAZO MAXIMO. Toper: ' + cast(@i_toperacion as varchar) + ' Monto: SMLV' + cast(@w_monto_param as varchar) + ' Valida salario: ' + cast(@w_valida_salario as varchar) + ' Salario SMLV: ' + cast(@w_salario_smlv as varchar) + ' Matriz: ' + cast(@w_matriz as varchar)
   return  703126
end

--- CONTROLAR PLAZO MAXIMO DEL CREDITO 
if @w_plazo_meses > @w_meses_param begin
   select @o_msg   = 'EL PLAZO MAXIMO PERMITIDO DEL PRESTAMO ES: ' + cast (@w_meses_param as varchar(10)) + ' MESES' 
   return  703126
end 
            
---CONTROLAR PLAZO MINIMO DEL CREDITO 
if @w_plazo_meses < @w_plazo_min begin
   select @o_msg   = 'PLAZO INGRESADO MENOR AL MINIMO PERMITIDO'
   return  703126
end 
                                                                                                                                     
return 0

go
