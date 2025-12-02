/************************************************************************/
/*	Nombre Fisico       :     clauaint.sp                               */
/*	Nombre Logico    	:  	  sp_clausula_aceleratoria_int              */
/*	Base de datos       :     cob_cartera                               */
/*	Producto            :     Cartera                                   */
/*	Disenado por        :     Juan Carlos Espinosa V.                   */
/*	Fecha de escritura  : 	  7/Mayo/1998                               */
/************************************************************************/
/*	                        IMPORTANTE                                  */
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
/*	                        PROPOSITO                                   */
/* Aplica la Clausula Aceleratoria                                      */
/************************************************************************/  
/*                              CAMBIOS                                 */
/************************************************************************/  
/*      FECHA        AUTOR                CAMBIO                        */
/*	FEB-14-2002       RRB	          Agregar campos al insert          */
/*                                   en ca_transaccion                  */
/*	11/30/2002       Julio C Quintero Actualizar la Obtencion 	        */
/*					                      del Dividendo Vigente         */
/*                                   Por el Minimo Dividendo Vencido    */
/*	02/22/2006       Elcira Pelaez    Recoger los otros cargos def.6007 */
/*	03/09/2006       Elcira Pelaez    def.6099                          */
/* Ssep-05-2007     Elcira Pelaez    def. 8726 capitales pagados futuros*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go 

if exists (select 1 from sysobjects where name = 'capital')
   drop table capital
go

create table capital (
       concepto     catalogo, 
       secuencia    tinyint,
       estado       smallint,
       valor_acum   money,
       valor_pag    money,
       codigo       int null
)
go


if exists (select * from sysobjects where name = 'sp_clausula_aceleratoria_int')
   drop proc sp_clausula_aceleratoria_int
go

create proc  sp_clausula_aceleratoria_int(
   @s_user          login,      
   @s_term          varchar(30),
   @s_date          datetime,   
   @s_ofi           smallint,   
   @i_operacionca   int,
   @i_en_linea      char
)

as
declare
      @w_sp_name              varchar(32),
      @w_error                int,
      @w_return               int, 
      @w_secuencial           int,
      @w_div_vigente          smallint,
      @w_capital              money,
      @w_fecha_proceso        datetime,
      @w_toperacion           catalogo,
      @w_moneda               smallint, 
      @w_banco                cuenta,
      @w_numrubr              int,
      @w_oficina_or           smallint,
      @w_claus_aplic          char(1),
      @w_estado               tinyint,
      @w_concepto             catalogo,
      @w_gerente              smallint,
      @w_gar_admisible	      char(1), 
      @w_reestructuracion     char(1), 
      @w_calificacion	      catalogo, 
      @w_di_fecha_ini         datetime,
      @w_op_tipo              char(1),
      @w_am_estado_clausula    smallint,
      @w_valor_Rubro           money,
      @w_secuencia             tinyint,
      @w_am_estado             tinyint,
      @w_sec_amor              int,
      @w_sum_cuotas_ant        money,
      @w_op_monto              money,
      @w_valor_Pagado          money
      


select	@w_sp_name = 'sp_clausula_aceleratoria_int'


select 
   @w_op_tipo          = op_tipo,
   @w_banco            = op_banco,
   @w_moneda           = op_moneda,
   @w_toperacion       = op_toperacion, 
   @w_fecha_proceso    = op_fecha_ult_proceso,
   @w_oficina_or       = op_oficina, 
   @w_claus_aplic      = op_clausula_aplicada,
   @w_estado           = op_estado,
   @w_gerente          = op_oficial,
   @w_gar_admisible    = op_gar_admisible, 
   @w_reestructuracion      = op_reestructuracion,
   @w_calificacion	    = op_calificacion,
   @w_op_monto           = op_monto
from ca_operacion
where  op_operacion = @i_operacionca

if @w_claus_aplic = 'S'  or @w_estado in (3,0,99,6)
   return 701123   
   
 if @w_op_tipo = 'R'
    return 710095

if @w_estado = 4
   select  @w_am_estado_clausula = 4
else
   select  @w_am_estado_clausula = 2

-- BUSCA DIVIDENDO VIGENTE  6099
select @w_div_vigente = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_estado    = 1 
and    di_operacion = @i_operacionca

if @w_div_vigente = 0 
begin
   
   --SOLO SE RESPALDA Y SE GEENRA TRANSACCION
  
   exec @w_secuencial  = sp_gen_sec
     @i_operacion   = @i_operacionca

   --- RESPALDO DE LA OPERACION
   exec @w_return = sp_historial
   @i_operacionca = @i_operacionca,
   @i_secuencial  = @w_secuencial
   
   if  @w_return <> 0 
      return @w_return
   


   update ca_operacion set
   op_clausula_aplicada = 'S'
   where  op_operacion = @i_operacionca
   
   ---TRANSACCION DE REGISTRO PARA RECUPERAR HISTORIA
   insert into ca_transaccion (
   tr_secuencial,     tr_fecha_mov,     tr_toperacion,
   tr_moneda,         tr_operacion,     tr_tran,
   tr_en_linea,       tr_banco,         tr_dias_calc,
   tr_ofi_oper,       tr_ofi_usu,       tr_usuario,
   tr_terminal,       tr_fecha_ref,     tr_secuencial_ref,
   tr_estado,         tr_gerente, 	     tr_gar_admisible,	
   tr_reestructuracion , 		     tr_calificacion,
   tr_observacion,    tr_fecha_cont, tr_comprobante)
   values (
   @w_secuencial,     @s_date,          @w_toperacion,
   @w_moneda,         @i_operacionca,   'ACE',
   @i_en_linea,       @w_banco,         1,
   @w_oficina_or,     @s_ofi,           @s_user,          
   @s_term,           @w_fecha_proceso, 0,
   'NCO',		      @w_gerente ,	     isnull(@w_gar_admisible,''),
   isnull(@w_reestructuracion,''),	     isnull(@w_calificacion,''),
   '',                @s_date,         0)
   if @@error != 0 
   begin
     if @i_en_linea ='N'  
       return 708165
     else
     begin
      select @w_error =  708165
        goto ERROR
     end
   end
   
   
   return 0
   
end   


-- BUSCA  FECHA DIVIDENDO VENCIDO O  VENCIDO 
select @w_di_fecha_ini = di_fecha_ini
from   ca_dividendo
where  di_operacion = @i_operacionca 
and    di_estado = 1

exec @w_secuencial  = sp_gen_sec
     @i_operacion   = @i_operacionca

--- RESPALDO DE LA OPERACION
exec @w_return = sp_historial
@i_operacionca = @i_operacionca,
@i_secuencial  = @w_secuencial

if  @w_return <> 0 
   return @w_return

-- ACTUALIZAR EL VALOR DE LOS RUBROS  DE TIPO CAPITAL E INTERES DEL DIVIDENDO VIGENTE 
update ca_amortizacion set
      am_cuota = am_acumulado
from  ca_amortizacion, ca_rubro_op
where am_operacion   = @i_operacionca 
and   am_operacion   = ro_operacion   
and   am_dividendo   = @w_div_vigente
and   am_concepto    = ro_concepto
and   am_estado     <> 3
and   ro_tipo_rubro in ('C','I','M') 

if @@error != 0 
begin 
   if @i_en_linea ='N'  
       return 705072
     else
     begin
      select @w_error =  705072
        goto ERROR
     end
end


--SUMA VALORES DE RUBROS DE TIPO CAPITAL E INTERES DE LOS DIVIDENDOS MAYORES AL DIVIDENDO VIGENTE
-- CREAR TABLA TEMPORAL 
insert into capital
select am_concepto,am_secuencia, am_estado,sum(am_acumulado),sum(am_pagado),null
from  ca_amortizacion , ca_concepto
where am_operacion  =  @i_operacionca  
and   am_dividendo  > @w_div_vigente
and   am_concepto   =  co_concepto
and   co_categoria  in ('C','I','M','R') 
group by am_concepto,am_secuencia ,am_estado
order by am_concepto,am_secuencia,am_estado

if @@error != 0 
begin
    if @i_en_linea ='N'  
       return 705072
     else
     begin
      select @w_error =  705072
        goto ERROR
     end
end

--- OBTENCION DE CODIGO VALOR DEL RUBRO 
update capital
set codigo = co_codigo * 1000  + 10 
from   ca_concepto, 
       capital
where  co_concepto = concepto

select @w_numrubr = count(*)
from capital
where codigo is null

if @w_numrubr != 0 
begin 
   if @i_en_linea ='N'  
       return 701151
     else
     begin
      select @w_error =  701151
        goto ERROR
     end
end
   
---SUMA LO ANTERIOR A LA CUOTA Y AL ACUMULADO DEL DIVIDENDO VIGENTE

declare rubros cursor for
select
valor_acum,
valor_pag,
concepto,
secuencia,
estado
from capital
order by concepto
for read only

open rubros

fetch rubros 
into @w_valor_Rubro,
     @w_valor_Pagado,
     @w_concepto,
     @w_secuencia,
     @w_am_estado

--while @@fetch_status  not in(-1,0) 
while @@fetch_status = 0 
begin
    if (@@fetch_status = -1)
    begin
        close rubros
        deallocate rubros
        if @i_en_linea ='N'  
            return 710004   -- Error en la lectura del cursor
          else
          begin
               select @w_error =  710004
               goto ERROR
          end
    end

    if exists (select 1 from ca_amortizacion
               where am_operacion = @i_operacionca
               and   am_dividendo = @w_div_vigente 
               and   am_concepto  = @w_concepto
               and   am_estado    = @w_am_estado
               and   am_secuencia = @w_secuencia)
    begin
         update ca_amortizacion
          set   am_cuota     = am_cuota     + isnull(@w_valor_Rubro,0),
                am_acumulado = am_acumulado + isnull(@w_valor_Rubro,0),
                am_pagado    = am_pagado    + isnull(@w_valor_Pagado,0)
          where am_operacion  = @i_operacionca
          and   am_dividendo  = @w_div_vigente 
          and   am_concepto   = @w_concepto
          and   am_estado     = @w_am_estado
          and   am_secuencia = @w_secuencia
         
          if @@error != 0
          begin
              close rubros
              deallocate rubros
               if @i_en_linea ='N'  
                 return 705072
               else
               begin
                  select @w_error =  705072
                  goto ERROR
               end
          end
    end  
    else
    begin
        --se debe insertar el rubro
        select @w_sec_amor = 0
        select @w_sec_amor = isnull(max(am_secuencia),1)
        from ca_amortizacion
        where am_operacion  = @i_operacionca
        and   am_dividendo  = @w_div_vigente 
        and   am_concepto   = @w_concepto
        and   am_estado     = @w_am_estado
        
        select @w_sec_amor = @w_sec_amor + 1
        insert ca_amortizacion
              (am_operacion,   am_dividendo,      am_concepto,
               am_estado,      am_periodo,        am_cuota,
               am_gracia,      am_pagado,         am_acumulado,
               am_secuencia )
        values(@i_operacionca, @w_div_vigente,           @w_concepto,
               @w_am_estado,   0,                        isnull(@w_valor_Rubro,0),
               0,              isnull(@w_valor_Pagado,0), isnull(@w_valor_Rubro,0),
               @w_sec_amor)
         
        if @@error != 0
        begin
            close rubros
            deallocate rubros
              if @i_en_linea ='N'  
                 return 710257
              else
              begin
                select @w_error =  710257
                  goto ERROR
              end
        end         
    end            
      
    fetch rubros 
    into @w_valor_Rubro,
         @w_valor_Pagado,
         @w_concepto,
         @w_secuencia,
         @w_am_estado

end -- CURSOR rubros

close rubros
deallocate rubros

delete capital WHERE secuencia >= 0


if @@error != 0 
begin
    if @i_en_linea ='N'  
        return 724402
    else
    begin
        select @w_error =  724402
        goto ERROR
    end
end

update ca_amortizacion
set   am_estado    = @w_am_estado_clausula  
from   ca_amortizacion,ca_concepto
where am_operacion  = @i_operacionca 
and   am_dividendo  = @w_div_vigente 
and   am_concepto  = co_concepto
and   am_estado not in (3,4,44,9)

if @@error != 0 
begin 
    if @i_en_linea ='N'  
        return 724401
    else
    begin
        select @w_error =  724401
        goto ERROR
    end
end

---BORRAR LOS DIVIDENDOS POSTERIORES AL MINIMO DIVIDENDO VIGENTE JCQ 11/30/2002
delete ca_cuota_adicional
where ca_operacion = @i_operacionca
and   ca_dividendo > @w_div_vigente

if @@error != 0 
begin 
   if @i_en_linea ='N'  
        return 724403
    else
    begin
        select @w_error =  724403
        goto ERROR
    end
end

delete ca_amortizacion
where am_operacion = @i_operacionca
and   am_dividendo > @w_div_vigente

if @@error != 0 
begin
    if @i_en_linea ='N'  
        return 724404
    else
    begin
        select @w_error =  724404
        goto ERROR
    end
end

delete ca_dividendo
where di_operacion = @i_operacionca
and   di_dividendo > @w_div_vigente
  
if @@error != 0 
begin
    if @i_en_linea ='N'  
        return 724405
    else
    begin
        select @w_error =  724405
        goto ERROR
    end
end
      
if @w_fecha_proceso >= @w_di_fecha_ini
begin
    update ca_dividendo  set 
    di_fecha_ven   = @w_fecha_proceso,
    di_gracia      = 0,
    di_gracia_disp = 0,
    di_estado      = 2 
    where di_operacion = @i_operacionca 
    and  di_dividendo = @w_div_vigente
    
    if @@error != 0 
    begin
       if @i_en_linea ='N'  
         return 724406
       else
       begin
         select @w_error =  724406
         goto ERROR
       end
    end    
   
    update ca_operacion set
    op_clausula_aplicada = 'S',
    op_fecha_fin         = @w_fecha_proceso,
    op_fecha_ult_mov     = @w_fecha_proceso
    where    op_operacion = @i_operacionca
   
    if @@error != 0 
    begin
      if @i_en_linea ='N'  
         return 724406
       else
       begin
         select @w_error =  724406
         goto ERROR
       end
    end

end
else
Begin
    update ca_dividendo  set 
    di_fecha_ven   = @w_di_fecha_ini,
    di_gracia      = 0,
    di_gracia_disp = 0,
    di_estado      = 2 --Para que cobre mora asi no este en esta fecha de proceso aun 
    where di_operacion = @i_operacionca 
    and   di_dividendo = @w_div_vigente
      
    if @@error != 0 
    begin
      if @i_en_linea ='N'  
         return 724407
       else
       begin
         select @w_error =  724407
         goto ERROR
       end
    end
   
    update ca_operacion set
    op_clausula_aplicada = 'S',
    op_fecha_fin         =  @w_di_fecha_ini,
    op_fecha_ult_mov     = @w_fecha_proceso  
    where op_operacion = @i_operacionca   
   
    if @@error != 0 
    begin
      if @i_en_linea ='N'  
         return 724408
       else
       begin
         select @w_error =  724408
         goto ERROR
       end
    end
end   

-- LA MORA SOLO SE APLICA AL SALDO DE CAPITAL
update ca_rubro_op set
       ro_paga_mora = 'S'  
where ro_operacion = @i_operacionca
and   ro_tipo_rubro not in('C','M') 

if @@error != 0 
begin
       if @i_en_linea ='N'  
         return 724409
       else
       begin
         select @w_error =  724409
         goto ERROR
       end
end


---TRANSACCION DE REGISTRO PARA RECUPERAR HISTORIA
insert into ca_transaccion (
tr_secuencial,     tr_fecha_mov,     tr_toperacion,
tr_moneda,         tr_operacion,     tr_tran,
tr_en_linea,       tr_banco,         tr_dias_calc,
tr_ofi_oper,       tr_ofi_usu,       tr_usuario,
tr_terminal,       tr_fecha_ref,     tr_secuencial_ref,
tr_estado,         tr_gerente, 	     tr_gar_admisible,	
tr_reestructuracion , 		     tr_calificacion,
tr_observacion,    tr_fecha_cont, tr_comprobante)
values (
@w_secuencial,     @s_date,          @w_toperacion,
@w_moneda,         @i_operacionca,   'ACE',
@i_en_linea,       @w_banco,         1,
@w_oficina_or,     @s_ofi,           @s_user,          
@s_term,           @w_fecha_proceso, 0,
'NCO',		      @w_gerente ,	     isnull(@w_gar_admisible,''),
isnull(@w_reestructuracion,''),	     isnull(@w_calificacion,''),
'',                @s_date,         0)

if @@error != 0 
begin
      if @i_en_linea ='N'  
         return 724410
       else
       begin
         select @w_error =  724410
         goto ERROR
       end
end
   
---VALIDAR MONTO DE CAPITAL AL SALIR DE LA CLAUSULA

select @w_sum_cuotas_ant = isnull(sum(am_cuota), 0)
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_concepto  = 'CAP'

/*if @w_sum_cuotas_ant <> @w_op_monto
begin
    if exists(select 1 from ca_acciones 
              where ac_operacion = @i_operacionca)
       select @w_sum_cuotas_ant = @w_sum_cuotas_ant
    else
    begin
--      PRINT 'clauaint.sp diferencia en CAPITAL @w_sum_cuotas_ant @w_op_monto' + @w_sum_cuotas_ant + @w_op_monto
        return 724411
    end
end*/

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug = 'N',
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error

go

