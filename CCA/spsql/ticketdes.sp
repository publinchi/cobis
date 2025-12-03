/************************************************************************/
/*   Archivo:                 ticketdes.sp                              */
/*   Stored procedure:        sp_ticket_desembolso                     */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Adrianag Giler.                           */
/*   Fecha de Documentacion:  Agosto 2019                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Generación de datos para la impresion del ticket de desembolso       */
/************************************************************************/
/*                            CAMBIOS                                   */
/*  05/Ago/2019  Adriana Giler       Ajuste Te Creemos                  */
/*  11/Sep/2019  Jonathan Tomala     consulta parametro FDESRE          */
/*  14/Sep/2019  Jonathan Tomala     correccion logica de consulta      */
/*  19/Nov/2019  Gerardo Barron     correccion en obtencion de datos      */
/*  06/12/2019    Gerardo Barron    Se modifica el sp para generar la referencia de pago*/
/************************************************************************/ 

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_ticket_desembolso')
   drop proc sp_ticket_desembolso
go

create proc sp_ticket_desembolso
(  
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @t_trn              int          = 0,
   @i_banco            cuenta       = null
)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_fec_proceso           datetime,
   @w_error                 int,
   @w_fecha                 varchar(50),    
   @w_oficina               smallint,
   @w_cajero                varchar(10),
   @w_modulo                varchar(10),
   @w_nom_oficial           varchar(100),
   @w_ente                  int,
   @w_nom_ente              varchar(100),
   @w_op_banco              cuenta,
   @w_recibo                varchar(15),
   @w_toperacion            varchar(100),
   @w_fdesembolso           varchar(40),
   @w_facreditar            varchar(40),
   @w_moneda                varchar(40),
   @w_monto                 money,
   @w_fecha_fin             varchar(10),
   @w_fecha_ven             varchar(10),
   @w_monto_cred            money,
   @w_op_anterior           cuenta,
   @w_operacion             int,
   @w_ope_renovada          money,
   @w_monto_liq             money,
   @w_seguro_basico         money,
   @w_seguro_voluntario     money,
   @w_monto_entregar        money,
   @w_certificado           varchar(30),
   @w_dir_sucursal          varchar(100),
   @w_referencia            varchar(50),
   @w_fec_impresion         varchar(50),
   @w_referencia_2          varchar(50),
   @w_numero                int,
   @w_oficina_r             smallint,
   @w_est_vigente           int,
   @w_est_novigente         int,
   @w_est_anulado           int,
   @w_est_credito           int,
   @w_producto_desembolso   varchar(30)  -- JTO 11/09/2019 consulta de producto de desembolso
 , @w_cont2          		tinyint   			--LGBC 06/12/2019
 , @w_cont3          		tinyint				--LGBC 06/12/2019
 , @wi_referencia1   		varchar(17)		--LGBC 06/12/2019
 , @wi_referencia2   		varchar(17)		--LGBC 06/12/2019
 , @w_paytel         		varchar(10)		--LGBC 06/12/2019
 , @w_wallmart       		varchar(10)		--LGBC 06/12/2019
 , @w_digito         		tinyint				--LGBC 06/12/2019
 , @w_referencia1    	varchar(24)		--LGBC 06/12/2019
 , @w_referencia2    	varchar(24)		--LGBC 06/12/2019
 , @w_referencia_tmp 	varchar(24)		--LGBC 06/12/2019
 , @w_num1           		int					--LGBC 06/12/2019		
 , @w_num2           		int					--LGBC 06/12/2019
 , @w_num3           		int					--LGBC 06/12/2019
 , @w_num4           		int					--LGBC 06/12/2019
 , @w_indice         		int					--LGBC 06/12/2019
 , @w_caracter       		char(1)			--LGBC 06/12/2019
 , @w_banco          		int					--LGBC 06/12/2019
 , @w_long           		tinyint				--LGBC 06/12/2019
 , @w_cadena         		varchar(10)		--LGBC 06/12/2019
 , @w_cont           		tinyint				--LGBC 06/12/2019
 , @w_dif            			tinyint				--LGBC 06/12/2019
 , @w_cont1          		tinyint				--LGBC 06/12/2019
 , @w_lref           			char(1)			--LGBC 06/12/2019
 , @w_cadena1        	varchar(11)		--LGBC 06/12/2019

if @t_trn <> 77523 
begin        
   select @w_error = 151023
   goto ERROR
end

--Obtener Fecha de Proceso
select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

--Estados de Cartera
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

-- CONSULTA DEL PRODUCTO DE DESEMBOLSO PARAMETRIZADO
SELECT @w_producto_desembolso = pa_char FROM cobis..cl_parametro WHERE pa_nemonico = 'FDESRE'


if not exists (select 1 from cob_cartera..ca_operacion where op_banco = @i_banco)
begin
   select @w_error =  171096
   goto ERROR
end

if exists (select 1 from cob_cartera..ca_operacion where op_banco = @i_banco
                and op_estado = @w_est_anulado)  -- JTO 14-09-2019 CORRECCION DE LOGICA DE CONSULTA
               --and op_estado in (@w_est_novigente,@w_est_credito,@w_est_anulado))  -- JTO 14-09-2019 CORRECCION DE LOGICA DE CONSULTA
begin
   select @w_error =  171096
   goto ERROR
end
   
--Obteniendo Datos
select @w_fecha          = convert(varchar,getdate(),103) + ' ' + convert(varchar,getdate(),108) + ' '+  RIGHT(convert(varchar,getdate(),109), 2),
       @w_oficina        = isnull(op_oficina,0),
       @w_dir_sucursal   = (select of_direccion
                            from cobis..cl_oficina
                            where of_oficina = A.op_oficina),
       @w_cajero         = ' ',
       @w_modulo         = ' ',    
       @w_nom_oficial    = (select fu_nombre
                            from  cobis..cc_oficial, cobis..cl_funcionario
                            where oc_oficial = A.op_oficial
                            and oc_funcionario = fu_funcionario),
       @w_ente           = op_cliente,         
       @w_nom_ente       = (select p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre + ' ' + p_s_nombre
                            from cobis..cl_ente
                            where en_ente = A.op_cliente),
       @w_op_banco       = op_banco,
       @w_fdesembolso    = 'A CUENTA DE AHORRO',
       @w_facreditar     = (select top 1 cp_descripcion  -- JTO 11/09/2019 consulta de producto de desembolso
                            from cob_cartera..ca_producto, cob_cartera..ca_desembolso
                            where dm_operacion = A.op_operacion
                              and dm_secuencial = (select max(dm_secuencial) from cob_cartera..ca_desembolso where dm_operacion = A.op_operacion)
                              and dm_producto = cp_producto
                              and dm_producto = @w_producto_desembolso),  -- JTO 11/09/2019 consulta de producto de desembolso
       @w_moneda         = (select mo_descripcion
                            from cobis..cl_moneda
                            where mo_moneda = A.op_moneda),
       @w_monto          = op_monto,
       @w_fecha_fin      = convert(varchar,op_fecha_fin,103),
       @w_fecha_ven      = (select convert(varchar,di_fecha_ven,103)
                            from cob_cartera..ca_dividendo
                            where di_operacion = A.op_operacion
                              and di_estado = @w_est_vigente),
       @w_monto_cred     = op_monto,
       @w_op_anterior    = op_anterior,
       @w_toperacion     = op_toperacion,
       @w_operacion      = op_operacion,
       @w_certificado    = 'TCSV-32100',
       --@w_referencia     = '00003F11800696719',
       --@w_referencia_2   = '0003371180069671',
       @w_fec_impresion  = convert(varchar,getdate(),103) + ' ' + convert(varchar,getdate(),108) + ' '+  RIGHT(convert(varchar,getdate(),109), 2)
from cob_cartera..ca_operacion A
where op_banco = @i_banco
  
if @@error != 0
begin
    select @w_error =  70170
    goto ERROR
end

select @w_toperacion = upper(b.valor)
from cobis..cl_tabla as a
inner join cobis..cl_catalogo as b on a.codigo = b.tabla
where a.tabla = 'ca_toperacion' and b.codigo = @w_toperacion

--LGBC INICIO ---Se obtienen los numeros de referencia
select @w_cont2 = 1,
	 @w_cont3 = 10
select @w_cadena1 = isnull(substring(@wi_referencia1,7,10), substring(@wi_referencia2, 7, 11))
--select @w_cadena1 = substring(@i_referencia,7,10)
while @w_cont2 <= 10
begin
	select @w_lref = substring(@w_cadena1,@w_cont2,1)
	if @w_lref <> '0'
	begin
		select @w_cadena1 = substring(@w_cadena1,@w_cont2,@w_cont3)
		break
	end
	select @w_cont2 = @w_cont2 +1
	select @w_cont3 = @w_cont3 - 1
end
select @i_banco = op_banco, 
	 @w_banco = op_operacion
from cob_cartera..ca_operacion
where op_operacion = convert(int,@w_cadena1)

select @w_banco  = op_operacion
from cob_cartera..ca_operacion, cobis..cl_ente
where op_cliente = en_ente
and op_banco = @i_banco
if @@rowcount = 0
begin
	exec cobis..sp_cerror
	  @t_from  = @w_sp_name,
	  @i_num   = 701025
	return 701025
end

-- Parametros de referencia
select @w_paytel = pa_char
from cobis..cl_parametro
where pa_producto = 'ATX'
and pa_nemonico = 'RPAYT'
if @@rowcount = 0
begin
	exec cobis..sp_cerror
	   @t_debug  = 'N',
	   @t_file   = null,
	   @t_from   = @w_sp_name,
	   @i_num    = 201196
	return 201196
end

select @w_wallmart = pa_char
from cobis..cl_parametro
where pa_producto = 'ATX'
and pa_nemonico = 'RWALL'
if @@rowcount = 0
begin
	exec cobis..sp_cerror
	   @t_debug  = 'N',
	   @t_file   = null,
	   @t_from   = @w_sp_name,
	   @i_num    = 201196
	return 201196
end

--Generacion operacion en base a codigo interno de operacion
select @w_long  = 10,
	  @w_cont1 = 0,
	  @w_cadena = null
	  
--select @w_cont = len(@w_banco),
select @w_cont = len(convert(VARCHAR,@w_banco)),
	  @w_dif  = @w_long - @w_cont
	  
while (@w_cont1 < @w_dif)
begin
	select @w_cadena = '0'+ isnull(@w_cadena,convert(VARCHAR,@w_banco))
	select @w_cont1 = @w_cont1 +1
end

-- Calculo del digito verificador

-- Se construye la referencia
select @w_referencia1 = @w_paytel + @i_banco
-- Se invierte la referencia
select @w_referencia_tmp = REVERSE(upper(rtrim(@w_referencia1)))

--Se inicializan las variables para obtener el digito verificador
select @w_num1 = 2, @w_num2 = 0, @w_indice = 0

-- Se obtiene el digito verificador
while @w_indice < LEN(@w_referencia_tmp)
begin
	select @w_num3 = 0, @w_num4 = 0
	select @w_caracter = substring(@w_referencia_tmp, @w_indice + 1, 1)
	-- Se obtiene un digito referencial
	
	SELECT @w_num3 = @w_num3
	   IF @w_caracter = '0' SELECT @w_num3 = 0
	   IF @w_caracter in ('1', 'A', 'J')      SELECT @w_num3 = 1
	   IF @w_caracter in ('2', 'B', 'K', 'S') SELECT @w_num3 = 2
	   IF @w_caracter in ('3', 'C', 'L', 'T') SELECT @w_num3 = 3
	   IF @w_caracter in ('4', 'D', 'M', 'U') SELECT @w_num3 = 4
	   IF @w_caracter in ('5', 'E', 'N', 'V') SELECT @w_num3 = 5
	   IF @w_caracter in ('6', 'F', 'O', 'W') SELECT @w_num3 = 6
	   IF @w_caracter in ('7', 'G', 'P', 'X') SELECT @w_num3 = 7
	   IF @w_caracter in ('8', 'H', 'Q', 'Y') SELECT @w_num3 = 8
	   IF @w_caracter in ('9', 'I', 'R', 'Z') SELECT @w_num3 = 9
	   
	   
	-- Se generan calculos para obtener el digito verificador
	select @w_num4 = @w_num1 * @w_num3
	if @w_num4 > 9
		select @w_num4 = ((@w_num4/10) + @w_num4 + 10)
	select @w_num2 = @w_num2 + @w_num4
	if @w_num1 <> 2
		select @w_num1 = 2
	else
		select @w_num1 = 1

	-- Se incrementa el indice
	select @w_indice = @w_indice + 1
end

-- Se calcula el digito verificador
select @w_digito = (((@w_num2/10) + 1) * 10 - @w_num2)
if @w_digito = 10
	select @w_digito = 0

select @w_referencia = @w_referencia1 + convert(char(1), @w_digito),
		@w_referencia_2 = @w_wallmart + @i_banco
		
--LGBC FIN

--Generacion del numero de recibo
select 
   @w_numero    = isnull(tr_dias_calc,-1),
   @w_oficina_r = tr_ofi_usu
   from cob_cartera..ca_transaccion
   where tr_operacion = @w_operacion
   and tr_tran        = 'DES'
   and tr_secuencial  = (select max(dm_secuencial)
                         from  cob_cartera..ca_desembolso
                         where dm_operacion = @w_operacion)

exec @w_return = sp_numero_recibo
@i_tipo       = 'G',
@i_oficina    = @w_oficina_r,
@i_secuencial = @w_numero,
@o_recibo     = @w_recibo out

if @w_return != 0
begin
   select @w_error = @w_return
   goto ERROR
end

--Obtener monto de pago en caso de ser una operacion renovada.
if isnull(@w_op_anterior,'') > ''
begin
    select @w_ope_renovada = op_operacion 
    from cob_cartera..ca_operacion 
    where op_banco = @w_op_anterior
    
    select @w_monto_liq = sum(dtr_monto)
    from cob_cartera..ca_det_trn 
    where dtr_operacion  = @w_ope_renovada 
    and dtr_secuencial = (select max(tr_secuencial)
                  from cob_cartera..ca_transaccion
                  where tr_operacion = @w_ope_renovada 
                  and tr_tran = 'PAG' 
                  and tr_estado <> 'RV')
    and dtr_dividendo > 0
end

--Valor del seguro Basico
select @w_seguro_basico =  sum(so_monto_seguro)
from cob_cartera..ca_seguros_op
where so_oper_padre = @w_operacion
   or (so_operacion = @w_operacion and isnull(so_oper_padre,0) = 0)
and so_tipo_seguro = 'B'

--Valor del seguro Voluntario
select @w_seguro_voluntario =  sum(so_monto_seguro)
from cob_cartera..ca_seguros_op
where so_oper_padre = @w_operacion
   or (so_operacion = @w_operacion and isnull(so_oper_padre,0) = 0)
and so_tipo_seguro != 'B'

--Valor del Monto a Entregar 
select @w_monto_entregar = @w_monto_cred - isnull(@w_monto_liq,0) - isnull(@w_seguro_basico,0) - isnull(@w_seguro_voluntario,0)
select @w_facreditar = 'EFECTIVO'

--Retornando Datos
select @w_fecha,
       isnull(@w_oficina,0),      
       isnull(@w_cajero,''),       
       isnull(@w_modulo,''),      
       isnull(@w_nom_oficial,''),  
       isnull(@w_ente,0),        
       isnull(@w_nom_ente,''),    
       isnull(@w_op_banco,''),    
       isnull(@w_recibo, '0'),      
       isnull(@w_toperacion,''),  
       isnull(@w_fdesembolso,''), 
       isnull(@w_facreditar,''),  
       isnull(@w_moneda,''),      
       isnull(@w_monto,0),       
       isnull(@w_fecha_fin,''),   
       isnull(@w_fecha_ven,''),   
       isnull(@w_monto_cred,0), 
       isnull(@w_monto_liq,0),
       isnull(@w_seguro_basico,0),
       isnull(@w_seguro_voluntario,0),
       isnull(@w_monto_entregar,0),
       isnull(@w_certificado,''),
       isnull(@w_dir_sucursal,''),    
       isnull(@w_referencia,''),     
       isnull(@w_toperacion,''),
       isnull(@w_nom_ente,''),
       isnull(@w_fec_impresion,''),   
       isnull(@w_referencia_2,'')    
       
return  0

        
ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null, 
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
	 @i_sev   = 0
    
return @w_error

go