/***********************************************************************/
/*      Producto:                       Cartera                        */
/*      Disenado por:                   Elcira Pelaez                  */
/*      Fecha de Documentacion:         Enero 2014                     */
/*      Procedimiento                   ca_planoAboExtra.sp            */
/***********************************************************************/
/*                      IMPORTANTE                                     */
/*      Este programa es parte de los paquetes bancarios propiedad de  */
/*      'MACOSA',representantes exclusivos para el Ecuador de la       */
/*      AT&T                                                           */
/*      Su uso no autorizado queda expresamente prohibido asi como     */
/*      cualquier autorizacion o agregado hecho por alguno de sus      */
/*      usuario sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/*     Enero 2014       Epelaez                 ORS 759                */
/***********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_plano_abnos_extras')
   drop proc sp_plano_abnos_extras
go
---MAR.17.2014
create proc sp_plano_abnos_extras (
   @i_param1              datetime  = null,
   @i_param2              datetime  = null
)
as

declare
@w_error            int,
@w_msg              varchar(250),
@w_sp_name          varchar(30),
@w_fecha_arch       varchar(10),
@w_comando          varchar(800),
@w_cmd              varchar(800),
@w_s_app            varchar(30),
@w_path_listados    varchar(250),
@w_archivo          varchar(300),
@w_archivoc         varchar(300),
@w_batch            int,
@w_cabecera         varchar(500),
@w_fecha_ini        varchar(10),
@w_fecha_fin        varchar(10),
@w_errores          varchar(250),
@w_fecha            varchar(10),
@w_cant             int,
@w_col              varchar(100), 
@w_campos           varchar(255),
@w_campo            varchar(20),
@w_encab3           varchar(500),
@w_comando3         varchar(600),
@w_cantidad         int,
@w_comando1         varchar(255),
@w_campo1           varchar(20),
--Conceptos detalle pago
@w_dtr_operacion       int,
@w_dtr_secuencial      int,
@w_dtr_concepto        catalogo,
@w_VlorPAgo            money,
@w_servidor            varchar(20),
@w_sec_pago            int,
@w_secuencial_reg      int,
@w_operacion           int,
@w_cuota_antes_pago    money,
@w_dias                int


set ANSI_WARNINGS ON

select @w_fecha_ini    = convert(varchar(10), @i_param1,101)
select @w_fecha_fin    = convert(varchar(10), @i_param2,101)

select @w_fecha = @w_fecha_ini

---VALIDACION FECHAS DE ENTRADA
select @w_dias = datediff(dd,@w_fecha_ini ,@w_fecha_fin)
if  (@w_dias > 30) or (@w_dias < 1)
begin
    print 'Atencion!!! Los dias de consulta no pueden exceder a 30, por favor cambiar las fechas: '
    print 'Dias de consulta: ==> ' +  cast (@w_dias as varchar)
    select @w_error = 2101084
    goto ERROR    
end

--- PARAMETRO GENERAL SERVIDOR HISTORICO
select @w_servidor = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SRVHIS'
       	
--INICIALIZACION DE LAS TABLAS DE TRABAJO    	
if exists(select 1 from sysobjects where name = 'tmp_Operacion_PAgos')
    drop table tmp_Operacion_PAgos
   
truncate table  ca_oper_universo_tmp   --carga lsa operaciones objetos de pago extra en las fechas dadas
truncate table  cabecera_tmp_pag_ext
truncate table  ca_conceptos_tmp 
truncate table  ca_amortizacion_his_plano
truncate table  ca_dividendo_his_plano   

    
---INSERTAR MASIVAMENTE LOS PAGOS EN UNRANGO DE FECHAS
    
insert into ca_oper_universo_tmp	
select distinct ab_fecha_pag,ab_operacion, ab_secuencial_pag
from ca_abono a with (nolock),
     ca_abono_det with (nolock)
where  ab_operacion = abd_operacion
and ab_secuencial_ing  = abd_secuencial_ing
and   abd_concepto <> 'RENOVACION'
and ab_fecha_pag   between  @w_fecha_ini and @w_fecha_fin
and ab_tipo_reduccion in ('C','T')
and ab_estado = 'A'
and exists (select 1 from ca_dividendo with (nolock)
            where di_operacion = a.ab_operacion
            and di_estado = 3
            and  di_fecha_can between  @w_fecha_ini and @w_fecha_fin
  	    and   di_fecha_ven > di_fecha_can)
order by ab_operacion


PRINT ''
PRINT 'Registrar los otros valores de los pagos  en la tabla de trabajo NRo.2'
PRINT ''
select 'Fecha' = convert(varchar(10),fecha_pag,101),---fecha_pag,
   'Oficina '  = op_oficina,
   'Cliente '  = op_cliente,
   'Nombre '   = op_nombre,
   'Operacion' = op_operacion,
   'Nro_Obligacion' = op_banco,
   'Tipo_de_Plazo'  = op_tplazo,
   'Sec_pago'       = sec_pag,
   'Monto_Pagado'   = convert(money,0),
   'Valor_Cuota_Ant'= convert(money,0),
   'EstadoOp'       =  (select es_descripcion from cob_cartera..ca_estado where es_codigo = op_estado),
   'Tipo_Cobro'     = case ab_tipo_cobro when 'P' then 'Proyectado' else 'Acumulado' end,
   'Tipo_Reduccion' =   case ab_tipo_reduccion when 'N' then 'Normal' when 'T' then 'Reduccion de Tiempo' when 'C' then 'Reduccion de Cuota' end,
   'cantidad_cuotas_PAG'       = 0,
   'tasa_interes' = convert(float,0.00),
   'ultimo_pago'  = convert(varchar(10),null),
   'proximo_pago' = convert(varchar(10),null),
   'saldo_cap'    = convert(money,0)
    into tmp_Operacion_PAgos
from ca_oper_universo_tmp,
             cob_cartera..ca_operacion with(nolock),
             ca_abono with (nolock)
where oper =  op_operacion
and   oper = ab_operacion
and ab_secuencial_pag = sec_pag

PRINT ''
PRINT 'Registrar los detalles de los pagos  en la tabla de trabajo NRo.3'
PRINT ''

insert into ca_conceptos_tmp
select fecha_pag,dtr_operacion,dtr_secuencial,dtr_concepto,'VlorPAgo'=sum(dtr_monto)
from ca_det_trn with (nolock),
     ca_oper_universo_tmp
where dtr_operacion = oper
and dtr_secuencial = sec_pag
and dtr_dividendo > 0
group by fecha_pag,dtr_operacion,dtr_secuencial,dtr_concepto

---------------------------------------------------------------------------
----alterar la tabla ya generada con los conceptos que se cargaron
---------------------------------------------------------------------------

---Datos Para Generar El plano

select @w_cabecera = ''
select @w_encab3 = ''
---Poner la primera parte de la cabecera
select @w_cabecera  = 'FECHA_PAG;OFICINA;CLIENTE;NOMBRE;NRO_OPER;NRO_OBLIGACION;TIPO_PLAZO;SEC_PAGO;MONTO_PAG;VALOR_CUOTA_ANTES_PAGO;ESTOPER;TIPOCOBRO;TIPOREDUCCION;NRO_CUOTAS_PAG;TASAINT;FECHAULTPAG;FECHAPROXPAG;SALDO_CAP;'
insert into cabecera_tmp_pag_ext values (@w_cabecera)

select dtr_concepto  
into  #conmcepto2
from  cob_cartera..ca_conceptos_tmp
group by dtr_concepto 

while 1 = 1
begin
  set rowcount 1
  select @w_campo = dtr_concepto
   from #conmcepto2
   order by dtr_concepto

  if @@rowcount = 0
     break
  ---PRINT 'while DOS va @w_campo ' + cast (@w_campo as varchar)
  select @w_encab3 =  @w_encab3 +   @w_campo + ';'
  
  ---ALter la tabla para los nuevos campos
  select @w_comando =  @w_campo + ' money null '
  select @w_cmd = 'alter table tmp_Operacion_PAgos add ' +  @w_comando
  exec (@w_cmd)
  
  delete  #conmcepto2
  where dtr_concepto = @w_campo

end ---While
set rowcount 0

select @w_encab3 = substring (@w_encab3,1,(datalength(@w_encab3)-1))
---Poner la segunda parte de la cabecera
update  cabecera_tmp_pag_ext 
set campo1 = campo1 + @w_encab3
WHERE campo1 >= ''


--- Inicio poner datospara leer del historico la cuota nates del abono extra

select @w_secuencial_reg = 0
while 1 = 1 
begin
      set rowcount 1
      select  
             @w_secuencial_reg = secuencial_reg,
             @w_operacion      = oper,        
             @w_sec_pago       = sec_pag 
      from ca_oper_universo_tmp
      where secuencial_reg > @w_secuencial_reg
      order by secuencial_reg

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      
      
      
      set rowcount 0
      select @w_comando = ''
      select @w_cuota_antes_pago = 0
      if not exists (select 1 
      from ca_rubro_op_his
      where roh_operacion  = @w_operacion
      and   roh_secuencial = @w_sec_pago
      )
      and @w_servidor <> 'NOHIST'
      begin
           ---PRINT 'while TRES va a Historico  @w_operacion ' + cast (@w_operacion as varchar)
           ---Sacar el historico del SERVIDOR DE HISTORICOS
           select @w_comando = 'insert into ca_dividendo_his_plano select * from '+ @w_servidor +'.cob_cartera.dbo.ca_dividendo_his'
			select @w_comando = @w_comando + ' where dih_operacion  = ' + convert(varchar(25),@w_operacion)
			select @w_comando = @w_comando + ' and   dih_secuencial = ' + convert(varchar(25),@w_sec_pago)
			exec @w_error = sp_sqlexec @w_comando
			select @w_comando = ''
			if @w_error <> 0 begin
			   print 'Error recuperando LINK ca_dividendo_his_plano'
			   goto ERROR
			end
			
			---if @@trancount > 0
			   ---commit transaction
			
			select @w_comando = 'insert into ca_amortizacion_his_plano select * from '+ @w_servidor +'.cob_cartera.dbo.ca_amortizacion_his'
			select @w_comando = @w_comando + ' where amh_operacion  = ' + convert(varchar(25),@w_operacion)
			select @w_comando = @w_comando + ' and   amh_secuencial = ' + convert(varchar(25),@w_sec_pago)
			exec @w_error = sp_sqlexec @w_comando
			select @w_comando = ''
			if @w_error <> 0 begin
			   print 'Error recuperando LINK ca_amortizacion_his_plano'
			   goto ERROR
			end
			
			---if @@trancount > 0
			   ---commit transaction
     
	       select @w_cuota_antes_pago = isnull(sum(amhp_cuota-amhp_pagado),0)
	       from ca_amortizacion_his_plano with (nolock),
	           ca_dividendo_his_plano  with (nolock)
	       where amhp_operacion = @w_operacion
	       and   amhp_secuencial = @w_sec_pago
	       and   amhp_operacion = dihp_operacion
	       and   amhp_secuencial = dihp_secuencial
	       and   amhp_dividendo = dihp_dividendo
	       and   dihp_estado in(1,2)
		      
		      --PRINT 'actualiza de historicos: ' + cast(@w_operacion as varchar) +  'sec_pago: ' + cast ( @w_sec_pago as varchar) + ' @w_cuota_antes_pago: ' + cast (@w_cuota_antes_pago as varchar)
      			
      end  ---leer en historicos
      else
      BEGIN
          set rowcount 0
	      select @w_cuota_antes_pago = isnull(sum(amh_cuota-amh_pagado),0)
	      from ca_amortizacion_his with (nolock),
	           ca_dividendo_his with (nolock)
	      where amh_operacion = @w_operacion
	      and   amh_secuencial = @w_sec_pago
	      and   amh_operacion = dih_operacion
	      and   amh_secuencial = dih_secuencial
	      and   amh_dividendo = dih_dividendo
	      and   dih_estado in(1,2)      
	      
	      ---PRINT 'actualiza de Central : ' + cast(@w_operacion as varchar) +  'sec_pago: ' + cast ( @w_sec_pago as varchar) + ' @w_cuota_antes_pago: ' + cast (@w_cuota_antes_pago as varchar)
	      
      END
      
      update tmp_Operacion_PAgos
      set  Valor_Cuota_Ant = @w_cuota_antes_pago
      where  Operacion = @w_operacion
      and    Sec_pago = @w_sec_pago
      
end ---While leer para historicos
set rowcount 0
    
---  FIn sacar hstoricos para leer cuota antes del pago extra

---------------------------------------------------------------------------
---Inico actualizacion de datos del pago por concepto
---------------------------------------------------------------------------

select 
'columna' = c.name,
'col_id'  = c.colid
into #columnas2
from cob_cartera..sysobjects o, cob_cartera..syscolumns c
where o.id    = c.id
and   o.name  = 'tmp_Operacion_PAgos'
and   c.colid >  18
order by c.colid

set rowcount 0

while 1 = 1
begin

	set rowcount 1
	
	select @w_campo1 = columna
	from  #columnas2
	
	if @@rowcount = 0
	   break
	
	set rowcount 0
	
	---PRINT 'while CUATRO va @w_campo1 ' + cast (@w_campo1 as varchar)
	
	select @w_comando1 = 'update cob_cartera..tmp_Operacion_PAgos  '
	select @w_comando1 =  @w_comando1  + 'set ' + @w_campo1 + ' =  VlorPAgo '
	select @w_comando1 =  @w_comando1 + 'from cob_cartera..ca_conceptos_tmp, cob_cartera..tmp_Operacion_PAgos '
	select @w_comando1 =  @w_comando1 + 'where dtr_concepto = ' + '''' +  @w_campo1 +  '''' + ' and Operacion =  dtr_operacion '
	select @w_comando1 =  @w_comando1 + 'and  dtr_secuencial =  Sec_pago and fecha_pag = Fecha '
	
	exec (@w_comando1)
	
	set rowcount 1
		
	delete #columnas2 where columna = @w_campo1
end
set rowcount 0
drop table #columnas2
    
set rowcount 0

---------------------------------------------------------------------------
---FIn actualizacion de lospagos por concepto
---------------------------------------------------------------------------
---PONER EL TOTAL DEL VALOR PAGADO
select fecha_pag,dtr_operacion, dtr_secuencial, 'TotValPAgo'=sum(VlorPAgo)
into #pagos_x_oper
from ca_conceptos_tmp
group by fecha_pag,dtr_operacion, dtr_secuencial


update  tmp_Operacion_PAgos
set Monto_Pagado = TotValPAgo
from  #pagos_x_oper,
      tmp_Operacion_PAgos
where  Operacion = dtr_operacion
and    Sec_pago  = dtr_secuencial
and    Fecha     = fecha_pag

---FIN PONER EL TOTAL DEL VALOR PAGADO
    
---PONER EL VALOR ANTES DEL PAGO y LA TASA
update tmp_Operacion_PAgos
set   tasa_interes    = ro_porcentaje
 from ca_rubro_op with (nolock)
where  ro_operacion = Operacion
and    ro_concepto = 'INT'

---FIN PONER EL VALRO ANTES DEL PAGO y LA TASA


---PONER LA FECHA DE PROXIMO PAGO
select di_operacion, 'proxPAgo'= max(di_fecha_ven)
into #proxPago
 from ca_dividendo
where di_estado in (1,2)
and di_operacion in (select distinct Operacion from tmp_Operacion_PAgos)
group by di_operacion

update tmp_Operacion_PAgos
set proximo_pago = convert(varchar(10),proxPAgo,101)
from #proxPago
where di_operacion = Operacion
---PONER LA FECHA DE PROXIMO PAGO


---PONER LA FECHA DE ULTIMO PAgO
select ab_operacion,'fecha_ult_pago'=max(ab_fecha_pag)
into #ULTPago
 from ca_abono
where ab_estado ='A'
and ab_operacion in (select distinct Operacion from tmp_Operacion_PAgos)
group by ab_operacion

update tmp_Operacion_PAgos
set ultimo_pago  = convert(varchar(10),fecha_ult_pago,101)
from #ULTPago
where ab_operacion = Operacion
---FIN PONER FECHA ULTIMO PAgO

---PONER EL SALDO CAPITAL
select am_operacion,'SaldoCAP'=sum(am_acumulado - am_pagado)
into #SaldoCAP
 from ca_amortizacion
where am_concepto = 'CAP'
and am_operacion in (select distinct Operacion from tmp_Operacion_PAgos)
group by am_operacion

update tmp_Operacion_PAgos
set saldo_cap  = SaldoCAP
from  #SaldoCAP
where am_operacion = Operacion
---FIN PONER SALDO CAPITAL

---PONER LAS CUOTAS QUE SE PAGARON POR CADA ABONO EXTRA


select 'secPago'= dtr_secuencial,
       'Oper'=     dtr_operacion, 
       'TotDiv'=count(distinct (dtr_dividendo))
into #CantidaDivPAgados
 from tmp_Operacion_PAgos,ca_det_trn
where dtr_operacion = Operacion
and dtr_secuencial = Sec_pago
and dtr_dividendo > 0
group by dtr_secuencial,dtr_operacion

update tmp_Operacion_PAgos
set cantidad_cuotas_PAG = TotDiv
from #CantidaDivPAgados
where Oper = Operacion
and   secPago = Sec_pago    

---FIN PONER LAS CUOTAS PAGADAS

---QUITAR DE LA TABAL LOS PAGOS CUYO VALOR PAGADO SEA MENOR O IGUAL QUE 
---EL VALOR DE LA CUOTA ANTES DEL PAGO

delete tmp_Operacion_PAgos
where  Monto_Pagado <= Valor_Cuota_Ant
      
---------------------------------------------------------------------------
--------------- GEnerar planos de cabeceras
---------------------------------------------------------------------------
select @w_fecha_arch    = substring(@w_fecha_ini,1,2)+ substring(@w_fecha_ini,4,2)+substring(@w_fecha_ini,7,4)
select @w_archivo = 'ABONOS_EXTRAS_' + @w_fecha_arch
select @w_archivoc = 'ABONOS_EXTRAS_CABECERA' + @w_fecha_arch

select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @@rowcount = 0
 begin
 print 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
 select @w_error = 2101084
 goto ERROR
end

select @w_path_listados = ba_path_destino
from cobis..ba_batch
where ba_batch = 7179

if @@rowcount = 0
 begin
 print 'ERROR NO HAY PATH PARA GENERAR SALIDA'
 select @w_error = 2101084
 goto ERROR
end

---select * from cob_cartera..cabecera_tmp_pag_ext
---select * from cob_cartera..tmp_Operacion_PAgos 

---antes se borra la cabecera
select @w_comando  = 'ERASE ' + @w_path_listados + 'CABECERA.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error borrando Archivo: ' + 'CABECERA.TXT'
    select @w_error = 2101084
    goto ERROR    
end
---Borrar Plano

select @w_comando  = 'ERASE ' + @w_path_listados + 'CUERPO.TXT'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error borrando Archivo: ' + 'CUERPO.TXT'
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + @w_archivo + '.csv'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error borrando Archivo final: '
    select @w_error = 2101084
    goto ERROR    
end


select @w_errores = @w_path_listados + @w_archivoc + '.err'
select @w_cmd = @w_s_app + 's_app bcp cob_cartera..cabecera_tmp_pag_ext out '
select @w_comando = @w_cmd + @w_path_listados + 'CABECERA.TXT' + ' -b5000 -c -e' + @w_errores + ' -t";" ' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error generando Archivo: ' + 'CABECERA.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

----------------------------------------------------------------------------------------------
--- GENERACION ARCHIVO PLANO
----------------------------------------------------------------------------------------------


select @w_comando = '',
       @w_cmd     = ''
select @w_errores  = @w_path_listados + @w_archivo + '.err'
select @w_cmd = @w_s_app + 's_app bcp cob_cartera..tmp_Operacion_PAgos out '
select @w_comando  = @w_cmd + @w_path_listados + 'CUERPO.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' +';'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'
select @w_comando                                                                                                        
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error generando Archivo: ' + 'CUERPO.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

---UNIR LOS DOS ARCHIVOS CUERPO.TXT  + CABECERA.TXT
select @w_comando = 'TYPE ' + @w_path_listados + 'CABECERA.TXT  ' + @w_path_listados + 'CUERPO.TXT >> '+ @w_path_listados + @w_archivo + '.csv'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 
begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo
    select @w_error = 2101084
    goto ERROR    
end

----------------------------------------------------------------------------------------------
--- GENERACION ARCHIVO PLANO
----------------------------------------------------------------------------------------------

return 0


ERROR:
return @w_error

go

