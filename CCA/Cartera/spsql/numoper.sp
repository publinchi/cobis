/************************************************************************/
/*      Archivo:                numoper.sp                              */
/*      Stored procedure:       sp_numero_oper                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cuentas Corriente                       */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Mar. 1993                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP"                                                     */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este programa realiza la generacion del numero de banco         */
/*      interno para operacion.                                         */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      Feb 1999   Jorge Tellez C.      Formato nuevo para numero de Op.*/
/*      Abr/24/2008   Nidia Nieto.      Formato nuevo para numero de Op.*/
/*      Mar/17/2009   Jonnatan Peña.    Reduccion de digitos para el    */
/*										numero de Op. de 15 a 12 digitos*/
/*      May/01/2019   Edison Cajas      CAR-S242693-TEC: Reduccion de   */
/*                                      digitos para el numero de Op. de*/
/*                                      12 a 10 digitos                 */
/*      Feb/24/2020   Luis Ponce        LPO CDIG error de conversion de */
/*                                      tipos de datos tinyint          */
/*      Jun/01/2022   Guisela Fernandez Se comenta prints               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_numero_oper')
drop proc sp_numero_oper
go
create proc sp_numero_oper (
   @s_date          datetime,
   @i_oficina       int 	    = null,
   @i_tramite       int 	    = null,
   @i_operacionca   int 	    = null,
   @i_activas       char(1)     = null,
   @o_operacion     int 	    = null out,
   @o_num_banco     varchar(24) = null out
)
as
declare
   @w_sp_name             varchar(30),
   @w_cta_ofi             varchar(24),
   @w_p1                  tinyint,
   @w_p2                  tinyint,
   @w_p3                  tinyint,
   @w_p4                  tinyint,
   @w_p5                  tinyint,
   @w_p6                  tinyint,
   @w_p7                  tinyint,
   @w_p8                  tinyint,
   @w_p9                  tinyint,
   @w_p10                 tinyint,
   @w_p11                 tinyint,
   @w_p12                 tinyint,
   @w_consecutivo         int,
   @w_digito              INT, --tinyint, --LPO CDIG error de conversion de tipos de datos tinyint
   @w_ceros               INT, --tinyint, --LPO CDIG error de conversion de tipos de datos tinyint
   @w_long_max_conse      INT, --tinyint, --LPO CDIG error de conversion de tipos de datos tinyint
   @w_dig_conse           INT, --tinyint, --LPO CDIG error de conversion de tipos de datos tinyint
   @w_consecutivo_c       char(6),
   @w_sum_dig_ver         int,
   @w_mod_9               int,
   @w_tipo                char(1),
   @w_band                int,
   @w_num_banco           varchar(24),
   @w_num_banco1          varchar(24),
   @w_num_banco_aux       varchar(24),
   @w_operacionca_pasiva  int,
   @w_oficina             smallint,
   @w_long                smallint

/* Captura del nombre del Stored Procedure */

select @w_sp_name = 'sp_numero_oper'

exec @o_operacion = sp_gen_sec
     @i_operacion = @i_operacionca

select @w_tipo      = op_tipo, 
       @w_oficina   = op_oficina,
       @o_num_banco = op_banco
  from ca_operacion
 where op_operacion = @i_operacionca 

select @i_oficina =  isnull(@i_oficina,@w_oficina)

/* Se deben crear los Num. de operacion para tipo 'C' y 'R'  */
if @w_tipo = 'C'
Begin 
   select @w_band       = 0,
          @w_num_banco  = '1', -- Cartera Activa 
          @w_num_banco1 = '2'  -- Cartera Pasiva
end
else   
begin 
   if @w_tipo <> 'R'  or @i_activas = 'S'
   begin
      select @w_band      = 1,
             @w_num_banco = '1' -- Cartera Activa
   end
   else    
   begin
      select @w_band      = 1,
             @w_num_banco = '2' -- Cartera Pasiva
   end
end

-- Generacion del numero de operacion del banco (op_banco)
update ca_conversion
   set cv_operacion = cv_operacion + 1 
 where cv_oficina   = @i_oficina

if @@rowcount = 0
begin
   -- CUANDO HAY UN CAMBIO DE ANIO SE INSERTA REGISTROS EN ca_conversion   
   select @w_cta_ofi = convert(varchar(4), replicate('0', 4-datalength(convert(varchar(4),@i_oficina)))+convert(varchar(4),@i_oficina))      
   insert into ca_conversion(
      cv_oficina, cv_codigo_ofi, cv_operacion,
      cv_anio,    cv_pago,       cv_liquidacion,
      cv_pago_masivo) 
   values(
      @i_oficina, @w_cta_ofi,    1, 
      convert(smallint,datepart(yy,@s_date)), 0, 0,
      1) 
      
   if @@error <> 0 
   begin
      --GFP se suprime print
      --print 'numoper.sp  entre...en el error de insercion..'
      return 705015
   end
   
   select @w_consecutivo = 1 
end

select @w_consecutivo = cv_operacion, 
       @w_cta_ofi     = cv_codigo_ofi
  from ca_conversion 
 where cv_oficina = @i_oficina
   
if @@rowcount = 0 
   return 701034
   
select @w_long_max_conse = 6,  -- LONGITUD DEL NUMERO CONSECUTIVO --EC CAR-S242693-TEC: Reduccion de digitos para el numero de Op. de 12 a 10 digitos
       @w_dig_conse      = datalength(convert(varchar,@w_consecutivo)), 
	   @w_ceros          = @w_long_max_conse - @w_dig_conse

if @w_ceros >= 1 
   select @w_consecutivo_c = replicate('0', @w_ceros) + convert(varchar, @w_consecutivo)
else   
   select @w_consecutivo_c = convert(varchar,@w_consecutivo)

select @w_num_banco = convert(varchar(4), @w_cta_ofi) + TRIM(@w_consecutivo_c) --EC CAR-S242693-TEC: Reduccion de digitos para el numero de Op. de 12 a 10 digitos
 
if @w_tipo = 'C'
   select @w_num_banco1 = convert(char(4), @w_cta_ofi) + TRIM(@w_consecutivo_c) --EC CAR-S242693-TEC: Reduccion de digitos para el numero de Op. de 12 a 10 digitos


-- ***** CALCULO DEL DIGITO VERIFICADOR *****
-- PESOS ASIGNADOS . AUMENTADO 02/02/99
select @w_p1  = 2,  @w_p2  = 1,  @w_p3  = 2,
       @w_p4  = 1,  @w_p5  = 2,  @w_p6  = 1,
       @w_p7  = 2,  @w_p8  = 1,  @w_p9  = 2,
       @w_p10 = 1,  @w_p11 = 2,  @w_p12 = 1

while @w_band < 2 
Begin
   if @w_band = 0 
      select @w_num_banco_aux = @w_num_banco1 
   
   if @w_band = 1 
   	 	
      select @w_num_banco_aux = @w_num_banco 
   
   select @w_sum_dig_ver = 0
   select @w_long = datalength(@w_num_banco_aux)
   --GFP se suprime print
   --print 'BANCOAUX: ' + @w_num_banco_aux + ' numdigitos: ' + cast(@w_long as varchar)
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,1,1)) * @w_p1 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,2,1)) * @w_p2 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,3,1)) * @w_p3 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,4,1)) * @w_p4 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,5,1)) * @w_p5 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,6,1)) * @w_p6 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,7,1)) * @w_p7 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 )  
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,8,1)) * @w_p8 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,9,1)) * @w_p9 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 )  
   
   select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,10,1)) * @w_p10 
   select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 )  
   
   --select @w_mod_9 = convert(smallint,substring(@w_num_banco_aux,11,1)) * @w_p11 
   --select @w_sum_dig_ver = @w_sum_dig_ver + ( @w_mod_9 % 9 ) 
     
   select @w_digito = 10 - ( @w_sum_dig_ver % 10 ) 
   select @w_digito = @w_digito % 10 
         
   -- Numero pasivo
   if @w_band = 0 
      select @w_num_banco1 = @w_num_banco1 + convert(char(1),@w_digito )
   
   -- Numero Activo
   if @w_band = 1 
      select @w_num_banco  = @w_num_banco + convert(char(1),@w_digito )
             
   select @w_band = @w_band + 1
  
end   -- FINAL DEL WHILE

select @w_num_banco = replace(@w_num_banco, ' ','0') 
if exists (select 1 from cob_cartera..ca_operacion where op_banco = @w_num_banco)
begin
   --GFP se suprime print
   --print 'Numero de Operacion generado ya existe -> ' + cast(  @w_num_banco as varchar )
   if @@error <> 0 return 710002
end

-- Retorna el numero de la operacion
select @o_num_banco = @w_num_banco  

-- SE ACTUALIZA LA OPERACION PASIVA CON EL NUEVO NUMERO BANCO PARA LA PASIVA
if @w_tipo = 'C'
begin
   select @w_operacionca_pasiva = rp_pasiva 
   from ca_relacion_ptmo 
   where rp_activa = @i_operacionca
   
   update ca_operacion 
   set op_banco = @w_num_banco1
   where op_operacion = @w_operacionca_pasiva
   
   if @@error <> 0 return 710002
   
   update cobis..cl_det_producto
   set dp_cuenta = @w_num_banco1
   where dp_producto = 7
   and dp_cuenta = convert(varchar(24),@w_operacionca_pasiva)
   
   if @@error <> 0
      return 710002
end

return 0

go
