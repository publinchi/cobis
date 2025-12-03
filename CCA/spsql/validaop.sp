/******************************************************************/
/*  Archivo:            validaop.sp                               */
/*  Stored procedure:   sp_valida_op_tmp                          */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 04-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Interface de Creacion de Operaciones                       */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  04/Jun/19        Lorena Regalado    Valida datos en tablas    */
/*                                      Temporales                */
/* 18/10/19         J.Calvillo         Valida rol 'D'             */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_valida_op_tmp')
   drop proc sp_valida_op_tmp
go

create proc sp_valida_op_tmp
   @i_secuencial           int,            --Secuencial de referencia con el que se grabo la informacion en tablas temporales
   @i_es_interciclo        char(1)        = 'N',
   @o_fecha_primer_pago    datetime = null out  --Solo aplica para operaciones interciclo
   
as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_tipo_operacion       varchar(10),
   @w_oficina              smallint,
   @w_toperacion           varchar(10),
   @w_destino              varchar(10),
   @w_fecha_desemb         datetime,
   @w_moneda               tinyint,
   @w_monto                money,
   @w_plazo                smallint,
   @w_frecuencia           varchar(10),
   @w_tasa                 float,
   @w_fecha_primer_pago    datetime,
   @w_otros                varchar(255),
   @w_grupo                int,
   @w_monto_ahorro         money,
   @w_codeudor             int,
   @w_oficial              smallint,
   @w_monto_hijas          money,
   @w_mensaje              varchar(230),
   @w_banco                cuenta,
   @w_num_div              smallint,
   @w_min_div              smallint, 
   @w_max_div              smallint,
   @w_cliente              int,
   @w_num_div_pend         smallint,
   @w_div_ini              smallint

 


--Consultar los datos de la operacion temporal.

select @w_tipo_operacion = iot_tipo_operacion,
       @w_oficina        = iot_oficina,
       @w_toperacion     = iot_toperacion,
       @w_destino        = iot_destino,
       @w_fecha_desemb   = iot_fecha_desemb,
       @w_moneda         = iot_moneda,
       @w_monto          = iot_monto,
       @w_plazo          = iot_plazo,
       @w_frecuencia     = iot_frecuencia,
       @w_tasa           = iot_tasa,
       @w_fecha_primer_pago = iot_fecha_primer_pago,
       @w_otros          = iot_otros,
       @w_grupo          = iot_grupo,
       @w_monto_ahorro   = iot_monto_ahorro,
       @w_codeudor       = iot_codeudor,
       @w_oficial        = iot_oficial,
	   @w_banco          = iot_banco,
	   @w_cliente        = iot_cliente
from cob_cartera..ca_interf_op_tmp
where iot_sesn = @i_secuencial

if @@rowcount = 0
begin
       select @w_error = 725002
       goto ERROR
end

--LRE 26Ago19 Se validan productos en catalogo de solo Tipos de Operacion Grupal/Interciclo
if @w_banco is NULL   --Validar cuando no son operaciones de interciclo.
begin
   if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
                  where x.tabla = 'ca_grupal'
                  and   x.codigo = y.tabla
                  and   y.codigo  = @w_toperacion
                  and   y.estado = 'V' )
   begin

    --print 'No Existe Tipo de Operacion'
       select @w_error = 77531
       return @w_error
   end
end
else
begin
   if @i_es_interciclo = 'S'
      if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
                     where x.tabla = 'ca_interciclo'
                     and   x.codigo = y.tabla
                     and   y.codigo  = @w_toperacion
                     and   y.estado = 'V' )
      begin
       --print 'No Existe Tipo de Operacion'
         select @w_error = 77532
         return @w_error
      end
end
--FIN LRE 26Ago19 Se validan productos en catalogo de solo Tipos de Operacion Grupal/Interciclo




--print 'Tipo op' + @w_tipo_operacion

--TIPO DE OPERACION: Validar que solo pueda venir IN: Inauguracion, RE: Renovacion, RF: Refinanciamiento

if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
              where x.tabla = 'ca_tipo_operacion'
                and   x.codigo = y.tabla
                and   y.codigo  = @w_tipo_operacion
                and   y.estado = 'V' )
begin

    --print 'No Existe Tipo de Operacion'
       select @w_error = 725011
       return @w_error
end



--OFICINA: Que el codigo corresponda a una oficina creada en la cobis..cl_oficina
if not exists (select 1 from cobis..cl_oficina
               where of_oficina = @w_oficina)
begin
    print 'No Existe Oficina'
       select @w_error = 701102
       return @w_error

end


--TIPO DE PRODUCTO: Que el tipo de producto corresponda a uno que exista en la cob_cartera..ca_default_toperacion
if not exists (select 1 from cob_cartera..ca_default_toperacion
               where dt_toperacion = @w_toperacion
                and  dt_moneda     = @w_moneda)
begin
    print 'No Existe Tipo de Producto'
       select @w_error = 701110
       return @w_error

end



--DESTINO ECONOMICO: Que el destino exista en la tabla de catalogo cr_destino
if not exists (select 1 from cobis..cl_tabla x, cobis..cl_catalogo y
              where x.tabla = 'cr_destino'
                and   x.codigo = y.tabla
                and   y.codigo  = @w_destino
                and   y.estado = 'V' )
begin

    print 'No Existe Destino Economico'
       select @w_error = 6900188
       return @w_error

end




--FECHA DE DESEMBOLSO: Que la fecha sea menor a la fecha de primer pago
if @w_banco is NULL   --Solo validar cuando no son operaciones de interciclo.
begin
   if @w_fecha_desemb >= @w_fecha_primer_pago
   begin
       --print 'Erros: Fecha de desembolso es Mayor o Igual a la fecha del primer pago'
       --select @w_mensaje = 'Datos Operacion Padre: Fecha del desembolso: ' + cast(@w_fecha_desemb as varchar) + ' ' + 'es mayor o igual a la Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar)
        print  'Datos Operacion Padre: Fecha del desembolso: ' + cast(@w_fecha_desemb as varchar) + ' ' + 'es mayor o igual a la Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar)
        select @w_error = 725001
        return @w_error

   end
end   



--FECHA DEL PRIMER PAGO: Que la fecha de primer pago sea mayor a la fecha de desembolso
if @w_banco is NULL   --Solo validar cuando no son operaciones de interciclo.
begin
   if @w_fecha_primer_pago <= @w_fecha_desemb
   begin
    --print 'Error: Fecha de desembolso no es Mayor a la fecha del primer pago'
       --select @w_mensaje = 'Datos Operacion Padre: Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar) + ' ' + 'es menor o igual a la Fecha del Desembolso: ' + cast(@w_fecha_desemb as varchar)
       print  'Datos Operacion Padre2: Fecha del desembolso: ' + cast(@w_fecha_desemb as varchar) + ' ' + 'es mayor o igual a la Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar)
       select @w_error = 725001
       return @w_error

   end
end   




--MONEDA: Que el codigo corresponsa a uno existente en la tabla cobis..l_moneda
if not exists (select 1 from cobis..cl_moneda
               where mo_moneda = @w_moneda)
begin
    print 'No Existe Moneda'
       select @w_error = 701069
       return @w_error

end


--MONTO: Que el monto sea igual al de la suma de sus operaciones individuales, si viene un valor
if @w_banco is NULL   --Solo validar cuando no son operaciones de interciclo.
begin
    select @w_monto_hijas = sum(iht_monto)
    from cob_cartera..ca_interf_hijas_tmp
    where iht_sesn = @i_secuencial
    and iht_rol <> 'D'  --No se agregal desertores

    select @w_monto_hijas = isnull(@w_monto_hijas,0)

    if @w_monto <> @w_monto_hijas
    begin
       print 'Error: La suma del monto de las operaciones hijas es diferente al monto Operacion Grupal'
       select @w_error = 725007
       return @w_error
    end 
end





--PLAZO: Que el plazo sea mayor a 1 y menor a 10000
if @w_plazo <= 1 or @w_plazo >= 10000
begin
print 'Error, Plazo de la Operacion Grupal Invalido'
       select @w_error = 2110106
       return @w_error
end 



--TASA: Que la tasa sea mayor a 0
if @w_tasa <= 0
begin
    print 'Error Tasa es menor o igual a cero (0)'
       select @w_error = 722201
       return @w_error

end

if  @i_es_interciclo  = 'N'
begin

   --FRECUENCIA: Que el codigo de frecuencia exista en la tabla cob_cartera..ca_tdividendo
   if not exists (select 1 from cob_cartera..ca_tdividendo
                  where td_tdividendo = @w_frecuencia)
   begin
       print 'Error en codigo de Frecuencia de pago'
       select @w_error = 725003
       return @w_error

   end


   --GRUPO: Que el grupo exista en la tabla cobis..cl_grupo
   if not exists (select 1 from cobis..cl_grupo
               where gr_grupo = @w_grupo
                and  gr_tipo = 'S' )
   begin
       print 'Error No existe Grupo solidario'
       select @w_error = 725004
       return @w_error

   end


   --MONTO AHORRO: Que el monto de ahorro sea mayor a 0

   if @w_monto_ahorro <= 0
   begin
       print 'Error Monto del ahorro es menor o igual a 0'
       select @w_error = 725005
       return @w_error

   end

   --CODEUDOR: Si envian el codeudor que exista en la tabla cobis..cl_ente
   if @w_codeudor is not NULL
      if not exists (select 1 from cobis..cl_ente
                     where en_ente = @w_codeudor)
      begin
         print 'Error No Existe Codeudor en Maestro de Clientes'
         select @w_error = 725006
         return @w_error
      end



   --PROMOTOR: Que el codigo enviado este creado en la tabla cobis..cc_oficial
      if not exists (select 1 from cobis..cc_oficial
                     where oc_oficial = @w_oficial)
      begin
         print 'Codigo de Oficial no existe'
         select @w_error = 151091
         return @w_error
      end
end

/*****************************************************/   
--VALIDACIONES ADICIONALES PARA OPERACIONES INTERCICLO
/*****************************************************/

--CLIENTE : Que el cliente exista en la cobis..cl_ente, 

if @w_cliente is not NULL
begin
   if not exists (select 1 from cobis..cl_ente where en_ente = @w_cliente)
   begin
        print 'Codigo de Cliente no existe'
       select @w_error = 725009
       return @w_error
   end 
end
 
--NRO.CREDITO GRUPAL: Que la operacion grupal exista y que este activo. 
if @w_banco is not NULL
begin

    if not exists (select 1 from cob_cartera..ca_operacion
                  where op_banco = @w_banco
				    and op_grupal = 'S'
					and op_estado not in (0,99,3))
    begin
       print 'Operacion Grupal no estiva o no Existe'
       select @w_error = 710022
       return @w_error
    end

    select @w_grupo = op_grupo
    from cob_cartera..ca_operacion
    where op_banco =  @w_banco

  --Validar que el cliente sea un miembro del grupo al que pertenece la operacion grupal
  if not exists (select 1 from cobis..cl_cliente_grupo
                 where cg_grupo = @w_grupo
                  and  cg_ente  = @w_cliente)
  begin
       print 'Cliente no es miembro del grupo'
       select @w_error = 725013
       return @w_error
  end


    --NRO.CREDITO GRUPAL: Que la operacion no este en su penultima cuota o ultima.
	
    select @w_num_div = count(*)
    from cob_cartera..ca_dividendo, 
         cob_cartera..ca_operacion
    where op_banco = @w_banco 
     and  di_operacion = op_operacion



    if exists (select 1 from cob_cartera..ca_operacion,
                             cob_cartera..ca_dividendo          
		  	   where op_banco = @w_banco
                 and op_operacion = di_operacion
                 and (di_dividendo = @w_num_div or di_dividendo = @w_num_div -1)
				 and  di_estado in (1,2))

     begin
       --print 'Operacion Grupal esta en su ultimo o penultimo dividendo'
       select @w_error = 710040
       return @w_error
    end

  --FECHA DE DESEMBOLSO: que la fecha coincida con la fecha de inicio de un dividendo que no sea el primero ni el ultimo.
  select @w_min_div = min(di_dividendo) , 
         @w_max_div = max(di_dividendo) 
  from ca_operacion, ca_dividendo
  where op_banco    = @w_banco
  and  di_operacion = op_operacion
  

  if not exists (select 1 
                 from ca_operacion, ca_dividendo 
                 where op_banco    = @w_banco
                   and   op_operacion = di_operacion 
                   and   di_fecha_ini >= @w_fecha_desemb  
                   and   di_dividendo not in (@w_min_div,@w_max_div))
  begin
       --print 'Erros: No existe un dividendo cuya fecha de inicio de operacion padre coincida o este proxima con la fecha de desembolso'
       --select @w_mensaje = 'Datos Operacion Padre: Fecha del desembolso: ' + cast(@w_fecha_desemb as varchar) + ' ' + 'es mayor o igual a la Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar)
       select @w_error = 725001
       return @w_error
  end


      --OBTENER LA FECHA DEL PRIMER PAGO
      select @w_div_ini = min(di_dividendo)
      from ca_operacion, ca_dividendo
      where op_banco    = @w_banco
      and   op_operacion = di_operacion 
      and   di_fecha_ven >= @w_fecha_desemb  --fecha desem
      and   di_dividendo not in (@w_min_div,@w_max_div)

--print 'dividendo elegido : ' + cast(@w_div_ini as varchar)

  
  --FECHA DE DESEMBOLSO: Obtener la fecha del primer vencimiento, buscando la fecha que coincida con el plan de pagos del padre

--print 'Fecha desemb: ' + cast(@w_fecha_desemb as varchar)

--print 'Div Min: ' + cast(@w_min_div as varchar)

--print 'Div Max: ' + cast(@w_max_div as varchar)

 
    select @w_fecha_primer_pago = di_fecha_ven
    from ca_operacion, ca_dividendo
    where op_banco    = @w_banco
      and   op_operacion = di_operacion 
      and   di_dividendo = @w_div_ini
      --and   di_fecha_ini = @w_fecha_desemb  --fecha desem
      --and   di_dividendo not in (@w_min_div,@w_max_div)

    if @w_fecha_primer_pago <= @w_fecha_desemb
    begin
    --print 'Error: Fecha de desembolso no es Mayor a la fecha del primer pago'
       --select @w_mensaje = 'Datos Operacion Padre: Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar) + ' ' + 'es menor o igual a la Fecha del Desembolso: ' + cast(@w_fecha_desemb as varchar)
       --print  'Datos Operacion Padre2: Fecha del desembolso: ' + cast(@w_fecha_desemb as varchar) + ' ' + 'es mayor o igual a la Fecha del Primer Pago: ' + cast(@w_fecha_primer_pago as varchar)
       select @w_error = 725001
       return @w_error
    end	  
	
	select @o_fecha_primer_pago =  @w_fecha_primer_pago
  
 --FECHA DE CANCELACION: Que el plazo sea tal que se pueda cancelar antes del vencimiento del ultimo dividendo de la operacion grupal
if @w_plazo is not null
begin

    --Obtener el numero de cuotas pendientes de la operacion grupal
	select @w_num_div_pend = count(*)
    from cob_cartera..ca_dividendo, 
         cob_cartera..ca_operacion
    where op_banco = @w_banco 
     and  di_operacion = op_operacion
	 and  di_estado <> 3  --Cancelado
	 
    if @w_plazo > @w_num_div_pend
	begin
	   print 'Erros: Plazo es mayor al numero de cuotas pendientes de la operacion grupal '
       select @w_error = 725001
       return @w_error
	end
	

end
 
print 'FIN'  
end
		  

return 0

ERROR:

    
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    --@i_msg    = @w_mensaje,
    @i_sev    = 0
   
   return @w_error
   
go

