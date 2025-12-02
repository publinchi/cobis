/**************************************************************************/
/*   Archivo:             ca_pagfin.sp                                    */
/*   Stored procedure:    sp_pagare_finagro                               */
/*   Base de datos:       cob_cartera                                     */
/*   Producto:            Cartera                                         */
/*   Disenado por:                                                        */
/*   Fecha de escritura:  ENE/2015                                        */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de        */
/*   'MACOSA'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como           */
/*   cualquier alteracion o agregado hecho por alguno de sus              */
/*   usuarios sin el debido consentimiento por escrito de la              */
/*   Presidencia Ejecutiva de MACOSA o su representante.                  */
/**************************************************************************/
/*                              PROPOSITO                                 */
/*   Obtiene los datos necesarios para la impresión del Pagaré            */
/*   y solicitud de servicio                                              */
/**************************************************************************/
/*                               MODIFICACIONES                           */
/*  FECHA              AUTOR          CAMBIO                              */
/*  ENE/2015         LIANA COTO     EMISION INICIAL                       */  
/*                                  REQ479-FASE2 FINAGRO                  */
/*  JUL/2015         ELCIRA PELAEZ  REQ.500 UPDTE PAGARE                  */
/**************************************************************************/ 

use 
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagare_finagro')
   drop proc sp_pagare_finagro 
go

create proc sp_pagare_finagro 
@s_user                     login        = null,
@s_ofi                      int          = null,
@t_trn                      smallint     = null,
@i_banco                    varchar(30),      --NUMERO DE OPERACION, BANCO O CREDITO
@i_operacion                char(1)      = null


as
declare
@w_operacion                int,
@w_banco                    varchar(30),
@w_sp_name                  varchar(30),
@w_pagare                   varchar(30),
@w_capital_mon              int,
@w_cant_cuotas              int,
@w_val_prim_cuota_num       int,
@w_fecha_prim_cuota         varchar(10),
@w_dia_pago_num             tinyint,
@w_val_comision_num         int,
@w_tasa_efec_anual_num      float,
@w_fecha_firma              varchar(10),
@w_dia                      varchar(2),
@w_mes                      varchar(2),
@w_anio                     varchar(2),
@w_comision_fag             int,
@w_comision_fag1            money,
@w_comision_fag2            money,
@w_comision_mipymes         int,
@w_comision_mipymes1        varchar(20),
@w_comision_mipymes2        varchar(20),
@w_seg_vida                 int,
@w_seg_vida1                money,
@w_seg_vida2                money,
@w_tasa1                    varchar(20),
@w_tasa2                    varchar(20),
@w_porcentaje_fag           float,
@w_capital_mon_char         varchar(250),
@w_cant_cuotas_char         varchar(250),
@w_val_prim_cuota_char      varchar(250),
@w_fecha_prim_cuota_char    varchar(250),
@w_dia_pago_char            varchar(250),
@w_val_comision_char        varchar(250),
@w_tasa_efec_anual_char     varchar(250),
@w_tasa_efec_anual_char1    varchar(250),
@w_tasa_efec_anual_char2    varchar(250),
@w_dia_char                 varchar(250),
@w_mes_char                 varchar(250),
@w_comision_fag_char        varchar(250),
@w_comision_mipymes_char    varchar(250),
@w_seg_vida_char            varchar(250),
@w_mensaje                  varchar(250),
@w_error                    int,
@w_error1                   int,
@w_transaccion              int,
@w_finagro                  char(1),
@w_toperacion               varchar(25),
@w_tdividendo               char(1),
@w_det_tdividendo           varchar(25),
@w_sec_tran                 int,
@w_oficina                  int,
@w_ciudad                   varchar(64)

select @w_sp_name     = 'sp_pagare_finagro',
       @w_banco       = @i_banco,
       @w_transaccion = @t_trn,
       @w_finagro     = 'N'

--VALIDANDO NUMERO DE TRANSACCIÓN       
if @w_transaccion <> 7305
begin
   select @w_mensaje = 'TRANSACCION NO CORRESPONDE, FAVOR VALIDAR',
          @w_error   = 701046
   goto ERRORFIN
end

--OBTENIENDO DATOS DE PAGARE (FORMATO PAGARE)
       
--OBTENIENDO NUMERO DE OPERACION
select @w_operacion    = op_operacion,
       @w_toperacion   = op_toperacion,
       @w_dia_pago_num = isnull(op_dia_fijo, 0), --j9
       @w_tdividendo   = op_tdividendo,
       @w_cant_cuotas  = isnull(op_plazo, 0),
       @w_oficina      = op_oficina
from   ca_operacion
where  op_banco  = @w_banco
	
if @@rowcount = 0
begin
   select @w_mensaje = 'ERROR AL OBTENER EL NUMERO DE LA OPERACION',
          @w_error   = 724567
   goto ERRORFIN
end

if @s_ofi is null
   select @s_ofi = @w_oficina

   
select @w_ciudad = ci_descripcion
 from cobis..cl_oficina,
      cobis..cl_ciudad
where of_oficina = @s_ofi
and of_ciudad = ci_ciudad

if @i_operacion = 'V'
begin
   -- VALIDAR SI OPERACION PERTENECE A FINAGRO
   if exists (select 1 from ca_operacion, ca_opera_finagro where of_pagare = op_banco and op_banco = @w_banco)
   begin 
      -- VALIDA SI LINEA SIGUE ACTIVA COMO FINAGRO EN CATALOGO
      if exists (select 1 from  cob_credito..cr_corresp_sib s, 
                                cobis..cl_tabla t,
                                cobis..cl_catalogo c  
                          where s.descripcion_sib   = t.tabla
                          and   t.codigo            = c.tabla
                          and   s.tabla             = 'T301'
                          and   c.estado            = 'V'
                          and   c.codigo            = @w_toperacion)
         select @w_finagro = 'S'
      else
         select @w_finagro = 'N'
   end
   else 
      select @w_finagro = 'N'
      
   /*** MAPEA VALIDACION DE OPERACION FINAGRO AL FRONTEND ***/
   select @w_finagro
end

--IMPORESION DEL PAGARE FINAGRO
if @i_operacion = 'R'
begin
   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
   if @w_dia_pago_num > 0 or @w_dia_pago_num is not null
   begin
	   exec @w_error1 = sp_numeros_letras
	      @t_trn    = 29322,
	      @i_dinero = @w_dia_pago_num,
	      @i_moneda = 0,
	      @i_idioma = 'E',
	      @o_texto  = @w_dia_pago_char out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR VALOR CUOTA, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else 
      select @w_dia_pago_char = ' '

   --OBTENIENDO NUMERO DE CREDITO O PAGARE, CAPITAL, CANTIDAD DE CUOTAS Y FECHA DE PRIMERA CUOTA
   select @w_pagare               = @w_banco,                      --j1
	      @w_capital_mon          = isnull(of_cap_total,0),        --j2
	      @w_fecha_prim_cuota     = isnull(of_fecha_pri_ven,'')    --j8
   from cob_cartera..ca_opera_finagro
   where of_pagare = @w_banco

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER DATOS DE LA OPERACION' ,
             @w_error = 724568
      goto ERRORFIN
   end
   
   select @w_det_tdividendo = c.valor
   from   cobis..cl_tabla t,
          cobis..cl_catalogo c
   where  t.codigo = c.tabla
   and    t.tabla  = 'ca_plazos_fag'
   and    c.codigo = @w_tdividendo
   and    c.estado = 'V'
   
   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER LA PERIODICIDAD DE LA OPERACION' ,
             @w_error = 724526
      goto ERRORFIN
   end

   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
   if @w_capital_mon > 0 
   begin
	   exec @w_error1 = sp_numeros_letras
	      @t_trn      = 29322,
	      @i_dinero   = @w_capital_mon,
	      @i_moneda   = 0,
	      @i_idioma   = 'E',
	      @o_texto    = @w_capital_mon_char out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR VALOR CAPITAL, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else
      select @w_capital_mon_char = 'CERO PESOS '

   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR   
   if @w_cant_cuotas > 0 or @w_cant_cuotas is not null
   begin
	   exec @w_error1 = sp_numeros_letras
	      @t_trn    = 29322,
	      @i_dinero = @w_cant_cuotas,
	      @i_moneda = 0,
	      @i_idioma = 'E',
	      @o_texto  = @w_cant_cuotas_char out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR NUMERO CUOTAS, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else
   begin
      select @w_cant_cuotas_char = 'CERO '
   end

   --OBTENIENDO VALOR DE LA PRIMERA CUOTA
   select @w_val_prim_cuota_num   = isnull(sum(am_cuota),0) --j6
   from ca_amortizacion
   where am_operacion  = @w_operacion
   and   am_dividendo  = 1
   and   am_concepto   in ('CAP')  -- RQ500 ATSK-962 nueva version de pagare
   group by am_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER DATOS DE LA OPERACION' ,
             @w_error = 724568
      goto ERRORFIN
   end

   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
   if @w_val_prim_cuota_num > 0
   begin
    exec @w_error1 = sp_numeros_letras
      @t_trn    = 29322,
      @i_dinero = @w_val_prim_cuota_num,
      @i_moneda = 0,
      @i_idioma = 'E',
      @o_texto  = @w_val_prim_cuota_char out
      
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR VALOR CUOTA, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else 
      select @w_val_prim_cuota_char = 'CERO PESOS '
   
   --OBTENIENDO SECUENCIAL TRANSACCION DE DESEMBOLSO
   select @w_sec_tran = tr_secuencial
   from cob_cartera..ca_transaccion 
   where tr_operacion = @w_operacion
   and   tr_tran = 'DES'
   and   tr_estado <> 'RV'
   
   --OBTENIENDO VALOR DE COMISION DE APERTURA COBRADA EN EL DESEMBOLSO
   select @w_val_comision_num = isnull(convert(int, sum(dtr_monto)),0)  --j13
   from cob_cartera..ca_det_trn
   where dtr_operacion  = @w_operacion
   and   dtr_secuencial = @w_sec_tran
   and   dtr_concepto   in ( 'APERCRED')  -- RQ500 se muestra en el pagare el valor de la comision sin I.V.A

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER VALOR DE COMISION DE LA OPERACION' ,
             @w_error = 724568
      goto ERRORFIN
   end

   if @w_val_comision_num > 0
   begin
   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
	   exec @w_error1 = sp_numeros_letras
	      @t_trn    = 29322,
	      @i_dinero = @w_val_comision_num,
	      @i_moneda = 0,
	      @i_idioma = 'E',
	      @o_texto  = @w_val_comision_char out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR VALOR DE COMISION, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else
      select @w_val_comision_char = 'CERO PESOS '

   --OBTENIENDO TASA EFECTIVA ANUAL
   select   @w_tasa_efec_anual_num  = ro_porcentaje_efa --j11
   from ca_rubro_op
   where ro_operacion = @w_operacion
   and ro_concepto = 'INT'

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER TASA EFECTIVA ANUAL DE LA OPERACION',
             @w_error = 2
      goto ERRORFIN
   end

   if @w_tasa_efec_anual_num > 0 or @w_tasa_efec_anual_num is not null
   begin
      select @w_tasa_efec_anual_char = @w_tasa_efec_anual_num

      select @w_tasa1 = substring(@w_tasa_efec_anual_char, 1, CHARINDEX('.', @w_tasa_efec_anual_char) - 1)
      select @w_tasa2 = substring(@w_tasa_efec_anual_char, CHARINDEX('.', @w_tasa_efec_anual_char) + 1, LEN(@w_tasa_efec_anual_char))

	   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
	   exec @w_error1 = sp_numeros_letras
	      @t_trn    = 29322,
	      @i_dinero = @w_tasa1,
	      @i_moneda = 0,
	      @i_idioma = 'E',
	      @o_texto  = @w_tasa_efec_anual_char1  out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR TASA EFECTIVA, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
	   else
	      select @w_tasa_efec_anual_char1 = SUBSTRING(@w_tasa_efec_anual_char1, 1, CHARINDEX(' PESOS', @w_tasa_efec_anual_char1))

	   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
	   exec @w_error1 = sp_numeros_letras
	      @t_trn    = 29322,
	      @i_dinero = @w_tasa2,
	      @i_moneda = 0,
	      @i_idioma = 'E',
	      @o_texto  = @w_tasa_efec_anual_char2  out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR TASA EFECTIVA, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
	   else
         select @w_tasa_efec_anual_char2 = SUBSTRING(@w_tasa_efec_anual_char2, 1, CHARINDEX(' PESOS', @w_tasa_efec_anual_char2))
      
      
       select @w_tasa_efec_anual_char = @w_tasa_efec_anual_char1 + ' PUNTO ' + @w_tasa_efec_anual_char2 + ' POR CIENTO '	
   end	
   else
     select @w_tasa_efec_anual_char = 'CERO POR CIENTO '
     
   --OBTENIENDO VALOR COMISION FAG J15
   select @w_comision_fag1 = isnull(sum(ro_valor),0) 
   from  ca_rubro_op
   where ro_operacion = @w_operacion
   and   ro_concepto in ('COMFAGANU', 'COMFAGDES') -- RQ500 se muestran valores de la comision sin I.V.A
   group by ro_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER COMISION FAG DE LA OPERACION 1',
             @w_error = 724568
      goto ERRORFIN
   end

   select @w_comision_fag2 = isnull(sum(am_cuota),0)
   from  ca_amortizacion
   where am_operacion = @w_operacion
   and   am_concepto in ('COMFAGANU') -- RQ500 se muestran valores de la comision sin I.V.A
   group by am_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER COMISION FAG DE LA OPERACION 2',
             @w_error = 724568
      goto ERRORFIN
   end

   select @w_comision_fag = isnull(convert(int, sum(@w_comision_fag1 + @w_comision_fag2)),0)

   if @w_comision_fag > 0
   begin
   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
   exec @w_error1 = sp_numeros_letras
      @t_trn    = 29322,
      @i_dinero = @w_comision_fag,
      @i_moneda = 0,
      @i_idioma = 'E',
      @o_texto  = @w_comision_fag_char  out
      
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR COMISION FAG, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else
      select @w_comision_fag_char = 'CERO PESOS '

   --OBTENIENDO VALOR COMISION MIPYMES J17
   select @w_comision_mipymes1 = isnull(sum(ro_valor),0)
   from  ca_rubro_op
   where ro_operacion = @w_operacion
   and   ro_concepto in ('MIPYMES') -- RQ500 se muestra el valor de comision sin IVA
   group by ro_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER COMISION MIPYMES DE LA OPERACION 1',
             @w_error = 724568
      goto ERRORFIN
   end

   select @w_comision_mipymes2 = isnull(sum(am_cuota),0)
   from  ca_amortizacion
   where am_operacion = @w_operacion
   and   am_concepto in ('MIPYMES') -- RQ500 se muestra el valor de comision sin IVA
   group by am_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER COMISION MIPYMES DE LA OPERACION 2',
             @w_error = 724568
      goto ERRORFIN
   end

   select @w_comision_mipymes = isnull(convert(int, sum(convert(money,@w_comision_mipymes1) + convert(money,@w_comision_mipymes2))),0)

   if @w_comision_mipymes > 0
   begin
	   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
	   exec @w_error1 = sp_numeros_letras
	      @t_trn    = 29322,
	      @i_dinero = @w_comision_mipymes,
	      @i_moneda = 0,
	      @i_idioma = 'E',
	      @o_texto  = @w_comision_mipymes_char   out
   	   
	   if @w_error1 <> 0
	   begin
	      select @w_mensaje = ' ERROR AL CONVERTIR COMISION MIPYMES, NUMERICO A CARACTER ',
			     @w_error = 724569
	      goto ERRORFIN
	   end
   end
   else
	   select @w_comision_mipymes_char = 'CERO PESOS '

   --OBTENIENDO VALOR SEGUROS DE VIDA J19
   select @w_seg_vida1 = ISNULL(sum(ro_valor),0)
   from cob_cartera..ca_rubro_op 
   where ro_operacion = @w_operacion
   and   ro_concepto in ('SEGDEUVEN','EXEQUIAL','SEGVIDPRI','SEGVIDIND','SEGEXEQ','SEGDAMAT','SEGDEUANT', 'SEGVIDA', 'MICROSEG')
   group by ro_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER SEGURO DE VIDA DE LA OPERACION 1',
             @w_error = 724568
      goto ERRORFIN
   end

   select @w_seg_vida2 = ISNULL(sum(am_cuota),0)
   from   ca_amortizacion
   where am_operacion = @w_operacion
   and   am_concepto in ('SEGDEUVEN','EXEQUIAL','SEGVIDPRI','SEGVIDIND','SEGEXEQ','SEGDAMAT','SEGDEUANT', 'SEGVIDA', 'MICROSEG')
   group by am_operacion

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER SEGURO DE VIDA DE LA OPERACION 2',
             @w_error = 724568
      goto ERRORFIN
   end

   select @w_seg_vida = isnull(convert(int,sum(@w_seg_vida1 + @w_seg_vida2)),0)

   --OBTENIENDO LOS VALORES EN LETRAS
   if @w_seg_vida > 0
   begin
   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
   exec @w_error1 = sp_numeros_letras
      @t_trn    = 29322,
      @i_dinero = @w_seg_vida,
      @i_moneda = 0,
      @i_idioma = 'E',
      @o_texto  = @w_seg_vida_char out
      
   if @w_error1 <> 0
   begin
      select @w_mensaje = ' ERROR AL CONVERTIR VALOR SEGURO DE VIDA, NUMERICO A CARACTER ',
             @w_error = 724569
      goto ERRORFIN
   end
   end
   else
      select @w_seg_vida_char = 'CERO PESOS '

   --OBTENIENDO FECHA DE PROCESO
   select @w_fecha_firma = convert(varchar(10),fp_fecha,101)
   from cobis..ba_fecha_proceso 

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER FECHA DE PROCESO',
             @w_error = 724568
      goto ERRORFIN
   end

   --OBTENIENDO FECHA DE FIRMA DE PAGARE j21, 22, 23   
    select @w_dia  = substring(@w_fecha_firma,4,5),
		   @w_mes  = substring(@w_fecha_firma,1,2),
		   @w_anio = substring(@w_fecha_firma,9,10)	
   		
   --REALIZANDO CONVERSIÓN DE NUMERO A CHAR
   exec @w_error1 = sp_numeros_letras
      @t_trn    = 29322,
      @i_dinero = @w_dia,
      @i_moneda = 0,
      @i_idioma = 'E',
      @o_texto  = @w_dia_char out		
      
   if @w_error1 <> 0
   begin
      select @w_mensaje = ' ERROR AL CONVERTIR DIA, NUMERICO A CARACTER ',
             @w_error = 724569
      goto ERRORFIN
   end

   if @w_mes = 1
       select @w_mes_char = 'ENERO'
    if @w_mes = 2
       select @w_mes_char = 'FEBRERO'
    if @w_mes = 3
       select @w_mes_char = 'MARZO'
    if @w_mes = 4
       select @w_mes_char = 'ABRIL'
    if @w_mes = 5
       select @w_mes_char = 'MAYO'
    if @w_mes = 6
       select @w_mes_char = 'JUNIO'
    if @w_mes = 7
       select @w_mes_char = 'JULIO'
    if @w_mes = 8
       select @w_mes_char = 'AGOSTO'
    if @w_mes = 9
       select @w_mes_char = 'SEPTIEMBRE'
    if @w_mes = 10
       select @w_mes_char = 'OCTUBRE'
    if @w_mes = 11
       select @w_mes_char = 'NOVIEMBRE'
    if @w_mes = 12
       select @w_mes_char = 'DICIEMBRE'
       
   --OBTENIENDO PORCENTAJE DE GARANTIA FAG (FORMATO DE ACEPTACION FAG)        
   select @w_porcentaje_fag = isnull(of_porcentaje_fag,0)
   from ca_opera_finagro
   where of_pagare = @w_banco 

   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL OBTENER GARANTIA FAG',
             @w_error = 724568
      goto ERRORFIN
   end
   	   
   --ASIGNANDO VARIABLES DE SALIDA
   select @w_pagare,																			--1
         isnull(@w_capital_mon_char,'CERO PESOS '),											--2
         isnull(convert(money,@w_capital_mon),0),												--3
         isnull(substring(@w_cant_cuotas_char,1,CHARINDEX(' PESOS',@w_cant_cuotas_char)),''),  --4
         isnull(@w_cant_cuotas,0),																--5
         isnull(@w_val_prim_cuota_char,'CERO PESOS '),											--6
         isnull(convert(money,@w_val_prim_cuota_num),0),										--7
         isnull(@w_fecha_prim_cuota,0),														--8
         isnull(substring(@w_dia_pago_char,1,CHARINDEX(' PESOS',@w_dia_pago_char)),''),		--9
         isnull(@w_dia_pago_num,0),															--10
         @w_tasa_efec_anual_char,																--11
         isnull(@w_tasa_efec_anual_num,0),														--12
         isnull(@w_val_comision_char,'CERO PESOS '),											--13
         isnull(convert(money,@w_val_comision_num),0),											--14
         isnull(@w_comision_fag_char,'CERO PESOS '),											--15
         isnull(convert(money,@w_comision_fag),0),												--16
         isnull(@w_comision_mipymes_char,'CERO PESOS '),										--17
         isnull(convert(money,@w_comision_mipymes),0),											--18
         isnull(@w_seg_vida_char,'CERO PESOS '),												--19
         isnull(convert(money,@w_seg_vida),0),													--20
         isnull(substring(@w_dia_char,1,CHARINDEX(' PESOS',@w_dia_char)),''),					--21
         isnull(@w_dia,0),																		--22
         @w_mes_char,																			--23
         isnull(@w_anio,0),																	--24
         isnull(@w_porcentaje_fag,0),															--25
         @w_det_tdividendo,                                                      --26
         isnull(substring(@w_ciudad,1,49),'')                                   --27
         
   if @@rowcount =  0
   begin
      select @w_mensaje = 'ERROR AL ASIGNAR VARIABLES PARA F.E.',
             @w_error = 724570
      goto ERRORFIN
   end
end    

return 0

ERRORFIN:

exec cobis..sp_cerror
        @t_debug = 'N',
        @t_file  = null, 
        @t_from  = @w_sp_name,
        @i_num   = @w_error,
        @i_msg   = @w_mensaje 
return @w_error

go
