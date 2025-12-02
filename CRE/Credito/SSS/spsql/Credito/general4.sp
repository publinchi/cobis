/***********************************************************************/
/*  Archivo:      cr_gral4.sp                     */
/*  Stored procedure:   sp_general4                     */
/*  Base de Datos:      cob_credito                    */
/*  Producto:     Credito                        */
/*  Disenado por:     Myriam Davila                  */
/*  Fecha de Documentacion:   08/Ago/95                      */
/***********************************************************************/
/*      IMPORTANTE                     */
/*  Este programa es parte de los paquetes bancarios propiedad de  */
/*  'MACOSA',representantes exclusivos para el Ecuador de la       */
/*  AT&T                     */
/*  Su uso no autorizado queda expresamente prohibido asi como     */
/*  cualquier autorizacion o agregado hecho por alguno de sus      */
/*  usuario sin el debido consentimiento por escrito de la         */
/*  Presidencia Ejecutiva de MACOSA o su representante         */
/***********************************************************************/
/*      PROPOSITO              */
/*  Este stored procedure permite calcular el numero de banco de   */
/*  una linea de Credito                 */
/*                       */
/***********************************************************************/
/*      MODIFICACIONES               */
/*  FECHA   AUTOR     RAZON          */
/*  08/Ago/95 Ivonne Ordonez  Emision Inicial        */
/*  13/Sep/95 F. Arellano   Optimizacion         */
/*  23/Sep/95   Gcobos          Version FIE                            */
/***********************************************************************/
use cob_credito
go
if exists (select * from sysobjects where name = 'sp_general4')
    drop proc sp_general4
go
create proc sp_general4 (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_ofi                smallint  = null,
   @s_srv    varchar(30) = null,
   @s_lsrv       varchar(30) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_modo     tinyint = null, /* define la op. a realizar */
   @i_tramite    int = null,
   @i_oficina    int = null,
   @o_numero_bco   cuenta  = null out             -- numero de banco para L. Credito */
   
)
as
declare
   @w_today             datetime,     /* fecha del dia */ 
   @w_return            int,          /* valor que retorna */
   @w_sp_name           varchar(32),  /* nombre stored proc*/
   @w_grupo   int,
   @w_codigo    int,
   @w_saldo_suc_a money,
   @w_saldo_ext_c money,
   @w_saldop_suc_a  money,
   @w_saldop_ext_c  money,
   @w_moneda    tinyint,
   @w_def_moneda  tinyint,
   @w_cot_moneda  money,
   @w_producto    varchar(4),
   @w_desc_moneda varchar(35),
   @w_saldo   money,
   @w_saldop    money,
   @w_oficina     smallint,
   @w_char_oficina  varchar(5),
   @w_secuencial  int,
   @w_char_secuencial varchar(20),
   @w_prefijo   char(2),
   @w_truta   tinyint,
   @w_etapa   tinyint,
   @w_nivel   catalogo,
   @w_monto_max   money,
   @w_estacion_o  smallint,
   @w_paso    tinyint,
   @w_longitud    int,
   @w_inicio    int,
   @w_char_moneda varchar(5),
   @w_moneda_local  tinyint,
   @w_moneda_dolar  tinyint,
   @w_long_max_line   tinyint,
   @w_num_line       varchar(15),
   @w_long_num_linea tinyint,
   @w_indice_line   tinyint,
   @w_suma    smallint,
   @w_indice_pesos  tinyint,
   @w_valor_line    smallint,
   @w_digito    tinyint,
   @w_residuo              tinyint,
   @w_modulo    tinyint,
   @w_pesos   varchar(20),
   @w_valor_pesos   smallint,
   @w_moneda_ufv   tinyint
select  @w_today = @s_date,
  @w_sp_name = 'sp_general4',
  @w_prefijo = '30'

/* Codigos de Transacciones                                */
if (@t_trn != 21823)
   
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1 
end
/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_modo = 0 or
   @i_modo = 4
begin
 if @i_tramite is null and @i_oficina is null
 begin
 /* Campos NOT null con valores nulos */
  exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 1 
 end
end
/* calcular numero de linea de banco */
/* FORMATO FIE :  Estructura: PP-M-CCCCCCC-V 
   PP :       30 - Codigo de producto contigente
   M  :       Moneda de la linea
   CCCCCCC :  Secuencial 
   V  :       Digito Verificador  */
   
if @i_modo = 4
begin
  if @i_oficina is null
  begin
    SELECT @w_oficina = tr_oficina
    FROM   cr_tramite
    WHERE  tr_tramite = @i_tramite  
  end
  else
  begin
    select @w_oficina = @i_oficina
  end
  -- GCO ya no es secuencial por oficina
  select @w_oficina = 9999
  SELECT @w_secuencial = lv_secuencial
  FROM   cr_linea_conv
  WHERE  lv_oficina = @w_oficina
  select @w_char_oficina = convert(varchar(5),@w_oficina)
  
  
   select @w_moneda_ufv = pa_tinyint
       from  cobis..cl_parametro
         where pa_nemonico = 'MONUFV' 
     and pa_producto = 'CON'


  
  --consulta moneda local
   select @w_moneda_local = pa_tinyint
       from  cobis..cl_parametro , cobis..cl_producto
         where pa_nemonico = 'MLO' 
     and pa_producto = 'ADM'
     and pa_producto = pd_abreviatura
     
     select @w_moneda_dolar = pa_tinyint
     from cobis..cl_parametro
     where pa_nemonico = 'CDOLAR'
     and pa_producto = 'ADM'


    select @w_moneda = li_moneda from cob_credito..cr_linea
    where li_tramite = @i_tramite

    if (@w_moneda_local = @w_moneda)
    begin
      select @w_char_moneda = '0'
    end
    else
     if @w_moneda_dolar = @w_moneda
        begin
         select @w_char_moneda = '2'
        end
     else
     if @w_moneda_ufv = @w_moneda
        begin
         select @w_char_moneda = '4'
        end
     else   
           select @w_char_moneda = '3'
  --fin
  
  if @w_secuencial > 0
  begin
    select @w_secuencial = @w_secuencial + 1
    UPDATE cr_linea_conv  
    SET lv_secuencial = @w_secuencial  
    WHERE cr_linea_conv.lv_oficina = @w_oficina   
    if @@error != 0
    begin
                   /*No se pudo actualizar el registro secuencial de Lineaa*/
                   exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file, 
       @t_from  = @w_sp_name, 
       @i_num   = 2105006
             return 1
    end
  end
  else
  begin
    select @w_secuencial = 1
    INSERT INTO cr_linea_conv  
           ( lv_oficina,   
             lv_codigo_ofi,   
             lv_secuencial )  
    VALUES ( @w_oficina,   
             @w_char_oficina,   
             @w_secuencial)  
    if @@error != 0
    begin
                   /*No se pudo actualizar el registro secuencial de Lineaa*/
                   exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file, 
       @t_from  = @w_sp_name, 
       @i_num   = 2105006
             return 1
    end
  end
  
  
  select  @w_long_max_line = pa_tinyint
  from  cobis..cl_parametro
  where pa_nemonico = 'LOP'
  and  pa_producto = 'CRE'
  
  select  @w_modulo = pa_tinyint
  from  cobis..cl_parametro
  where pa_nemonico = 'MOP'
  and  pa_producto = 'CTE'
  
  select  @w_pesos = pa_char
  from  cobis..cl_parametro
  where pa_nemonico = 'POP'
  and  pa_producto = 'CTE'
  
  
  /* Formar el numero de banco de linea*/
  select @w_char_secuencial = convert(char(7),@w_secuencial)  
  select @w_longitud=datalength(rtrim(@w_char_secuencial))  --aumento
  select @w_inicio = 7 - @w_longitud +1
    select @w_char_secuencial = stuff('0000000',@w_inicio,@w_longitud,@w_char_secuencial)
    select @w_char_secuencial = ltrim(rtrim(@w_char_secuencial))
    select @w_num_line = @w_prefijo + @w_char_moneda + @w_char_secuencial
--calcula digito verificador
  select  @w_long_num_linea = datalength(@w_num_line),
  @w_suma = 0, 
  @w_indice_line = 1
  select  @w_indice_pesos = @w_long_max_line - @w_long_num_linea  
  while @w_indice_pesos < @w_long_max_line
  begin 
     select   @w_valor_line = convert(smallint, substring(@w_num_line, @w_indice_line, 1)),
      @w_valor_pesos = convert(smallint, substring(@w_pesos, @w_indice_pesos, 1)) 
     select   @w_suma = @w_suma + @w_valor_line * @w_valor_pesos
     select   @w_indice_line = @w_indice_line + 1
     select   @w_indice_pesos = @w_indice_pesos + 1
  end

  select @w_residuo = @w_suma % @w_modulo
  select @w_digito = @w_modulo - @w_residuo

  if @w_digito >= 10 
    select @w_digito = 0

  select @o_numero_bco = @w_prefijo + '-' + @w_char_moneda + '-' + @w_char_secuencial + '-' +  convert(char(1), @w_digito)
end
return 0
go
