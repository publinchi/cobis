/************************************************************************/
/*  Archivo:                concentracion_capital.sp                    */
/*  Stored procedure:       sp_concentracion_capital                    */
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

if exists (select 1 from sysobjects where name = 'sp_concentracion_capital' and type = 'P')
   drop proc sp_concentracion_capital
go



CREATE PROC sp_concentracion_capital
		(@s_ssn        int         = null,
	     @s_ofi        smallint,
	     @s_user       login,
	     @s_date       DATETIME = NULL,
	     @s_srv		   varchar(30) = null,
	     @s_term	   descripcion = null,
	     @s_rol		   smallint    = null,
	     @s_lsrv	   varchar(30) = null,
	     @s_sesn	   int 	       = null,
	     @s_org		   char(1)     = NULL,
		  @s_org_err        int 	       = null,
                  @s_error            int 	       = null,
                  @s_sev        tinyint     = null,
         @s_msg        descripcion = null,
                 @t_rty        char(1)     = null,
                  @t_trn        int         = null,
                  @t_debug      char(1)     = 'N',
                  @t_file       varchar(14) = null,
                  @t_from       varchar(30)  = null,
         --variables
		 @i_id_inst_proc int,    --codigo de instancia del proceso
		 @i_id_inst_act  int,    
		 @i_id_asig_act  int,
		 @i_id_empresa   int, 
		 @i_id_variable  smallint 
		 )
AS
DECLARE @w_sp_name       	varchar(32),
        @w_tramite       	int,
        @w_return        	INT,
        @w_error            INT,
        @w_retorno          INT,
        ---var variables	
        @w_asig_actividad 	int,
        @w_valor_ant      	varchar(255),
        @w_valor_nuevo    	varchar(255),
        @w_actividad      	catalogo,
        @w_codigo_proceso   INT,
        @w_version_proceso  INT,
        @w_operacion        INT,
        @w_relacion_conyugue      INT,
        @w_relacion_padrehijo     INT,
        @w_param_porc_descubierto FLOAT,
        @w_param_microcredito     VARCHAR(64),
        @w_param_liquida          VARCHAR(64),
        @w_param_hipotecaria      VARCHAR(64),
        @w_param_nivef            VARCHAR(64),
        @w_moneda_UDIS            INT,
        @w_param_capef            MONEY,
        @w_microcredito           CHAR(24),
        @w_limite_concentracion   MONEY,
        @w_param_limite_no_grupal MONEY,
        @w_param_limite_grupal    MONEY,
        @w_param_limite_operacion MONEY,
        @w_grupal                 CHAR(1),
        @w_porcentaje_concentracion FLOAT,
        @w_return_results         VARCHAR(64),
        @w_rule_mnemonic          VARCHAR(30),
        @w_tipo_persona           CHAR(1),
        @w_valor_garantias        MONEY,
        @w_var_values             VARCHAR(50),
        @w_return_variable        VARCHAR(100),
        @w_saldo_capital          MONEY,
        @w_nro_operaciones        INT,
        @w_monto_operaciones      MONEY	
        
       

SELECT @w_sp_name='sp_concentracion_capital'

SELECT @w_tramite = convert(int,io_campo_3),
	   @w_codigo_proceso = io_codigo_proc,
	   @w_version_proceso = io_version_proc
FROM cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

select @w_tramite = isnull(@w_tramite,0)

if @w_tramite = 0 return 0
/*
INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_money, pa_producto)
VALUES ('CAPITAL DE LA ENTIDAD FINANCIERA', 'CAPEF','M',1000000,'CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_char, pa_producto)
VALUES ('NIVEL DE LA ENTIDAD FINANCIERA', 'NIVEF','C','1','CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_int, pa_producto)
VALUES ('RELACION PADRE-HIJO', 'RPAHI','I',1,'CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_char, pa_producto)
VALUES ('SUBTIPO MICROCREDITO', 'SUBTM','C','05','CCA')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_char, pa_producto)
VALUES ('TIPO GARANTIA LIQUIDABLE', 'TGLIQ','C','LIQ','CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_char, pa_producto)
VALUES ('TIPO GARANTIA HIPOTECARIA', 'TGHIP','C','HIP','CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_float, pa_producto)
VALUES ('PORCENTAJE DE GARANTIAS LIQ-HIP','PGLHI','F',75,'CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_money, pa_producto)
VALUES ('LIMITE MICRO-NOGRUPAL UDIS', 'LMNGR','M',12000,'CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_money, pa_producto)
VALUES ('LIMITE MICRO-GRUPAL UDIS', 'LMGRU','M',20000,'CRE')

INSERT INTO cobis..cl_parametro (pa_parametro,pa_nemonico,pa_tipo,pa_int, pa_producto)
VALUES ('MONEDA UDIS', 'MUDIS','I',6,'CRE')
*/

select @w_sp_name = 'sp_concentracion_capital'

--	Solicitante del credito que estamos aprobando
--	Padres del Solicitante.
--	Hijos del Solicitante.
--  Conyuge o Pareja del Solicitante.

SELECT @w_operacion = op_operacion
FROM cob_cartera..ca_operacion
WHERE op_tramite = @w_tramite

SELECT @w_relacion_conyugue = pa_int 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'RCONY'
AND pa_producto = 'CRE'

SELECT @w_relacion_padrehijo = pa_int 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'RPAHI'
AND pa_producto = 'CRE'

SELECT @w_param_porc_descubierto = pa_float
FROM cobis..cl_parametro
WHERE pa_nemonico = 'PGLHI'
AND pa_producto = 'CRE'

SELECT @w_param_microcredito = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'SUBTM'
AND pa_producto = 'CCA'

SELECT @w_param_liquida = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'TGLIQ'
AND pa_producto = 'CRE'

SELECT @w_param_hipotecaria = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'TGHIP'
AND pa_producto = 'CRE'

SELECT @w_param_nivef = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'NIVEF'
AND pa_producto = 'CRE'


SELECT @w_param_limite_no_grupal = pa_money 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'LMNGR'
AND pa_producto = 'CRE'

SELECT @w_param_limite_grupal = pa_money 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'LMGRU'
AND pa_producto = 'CRE'

SELECT @w_moneda_UDIS = pa_int 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'MUDIS'
AND pa_producto = 'CRE'


SELECT @w_param_limite_no_grupal= @w_param_limite_no_grupal--* cz_valor
--FROM cob_credito..cr_cotizacion
--WHERE cz_moneda = @w_moneda_UDIS


SELECT @w_param_limite_grupal= @w_param_limite_grupal --* cz_valor
--FROM cob_credito..cr_cotizacion
--WHERE cz_moneda = @w_moneda_UDIS


SELECT @w_rule_mnemonic = 'PCOC'

--Es una operacion Microcredito normal
SELECT @w_microcredito = op_subtipo_linea 
FROM cob_cartera..ca_operacion
WHERE op_tramite = @w_tramite

SELECT @w_grupal = oe_char
FROM cob_cartera..ca_operacion_ext  
WHERE oe_operacion = @w_operacion
AND oe_columna = 'opt_grupal'

SELECT @w_tipo_persona = en_subtipo
FROM cob_credito..cr_deudores DEU, cobis..cl_ente
WHERE de_tramite = @w_tramite
AND de_rol = 'D'
AND de_cliente = en_ente

SELECT @w_saldo_capital = 0,
@w_nro_operaciones = 0

   EXEC @w_error = cob_credito..sp_saldo_capital_concentracion
			@t_debug       	= 'N',
			@t_file         	= @t_file,
			@t_from         	= @t_from,
            @s_rol              = @s_rol,
            @i_grupal           = @w_grupal,
            @i_tramite          = @w_tramite,
            @i_microcredito     = @w_microcredito,
            @i_tipo_persona     = @w_tipo_persona,            
            @o_saldo_capital    = @w_saldo_capital OUT,
            @o_nro_operaciones  = @w_nro_operaciones OUT
    
    if @w_error <> 0
	    goto ERROR
       
    
  /****** REGLA - Retorna porcentaje de limite de concentracion ***/
  SELECT @w_var_values = isnull(@w_param_nivef,' ') + '|' + isnull(@w_tipo_persona,' ')
  
     exec @w_retorno    = cob_pac..sp_rules_param_run
     @s_rol             = @s_rol,
     @i_rule_mnemonic   = @w_rule_mnemonic,
     @i_var_values      = @w_var_values, --'TIPO CALIFICACION CREDITO' | 'SECTOR CREDITO CAEDEC'
     @i_var_separator   = '|',
     @o_return_variable = @w_return_variable  out,
     @o_return_results  = @w_return_results   OUT
     
    set @w_error = @w_retorno --Se produjo un error al evaluar la regla
    IF @w_error <> 0
    BEGIN
     print @w_error
     goto ERROR
    END
    
    if @w_return_results = null
    BEGIN
	    set @w_error = 2103018 --La regla no devolvio un resultado con la informacion(condiciones) proporcionada
	    PRINT 'error en resultados'	    
	    goto ERROR
    END
    
    -- MAPEA RESULTADO DE SALIDA, VIENE CONCATENADO CON UN pipe |
    SELECT @w_porcentaje_concentracion= convert(FLOAT,ltrim(substring(@w_return_results,1, len(@w_return_results)-1)))
    
    SELECT @w_limite_concentracion  = @w_param_capef * @w_porcentaje_concentracion/100
    
    SELECT @w_valor_nuevo = 'NO'
    
    --- CONDICION NO MICROCREDITO 
    IF  @w_microcredito <> @w_param_microcredito 
    BEGIN 
      IF @w_limite_concentracion >  @w_saldo_capital
        SELECT @w_valor_nuevo = 'NO'
      ELSE 
        SELECT @w_valor_nuevo = 'SI'
    END
   
    IF  @w_microcredito = @w_param_microcredito AND @w_grupal = 'N'
    BEGIN
      IF @w_param_limite_no_grupal >  @w_saldo_capital
          SELECT @w_valor_nuevo = 'NO'
      ELSE 
          SELECT @w_valor_nuevo = 'SI'
    END
    
    IF  @w_microcredito = @w_param_microcredito AND @w_grupal = 'S'
    BEGIN
      IF @w_param_limite_grupal >  @w_saldo_capital
          SELECT @w_valor_nuevo = 'NO'
      ELSE 
          SELECT @w_valor_nuevo = 'SI'
          
      SELECT @w_monto_operaciones = @w_saldo_capital / @w_nro_operaciones  
      
      IF @w_param_limite_operacion > @w_monto_operaciones 
          SELECT @w_valor_nuevo = 'NO'
      ELSE 
          SELECT @w_valor_nuevo = 'SI'
    END
    
      
--insercion en estrucuturas de variables
if @i_id_asig_act is null
  select @i_id_asig_act = 0

-- valor anterior de variable tipo en la tabla cob_workflow..wf_variable
select @w_valor_ant    = isnull(va_valor_actual, '')
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @i_id_variable

if @@rowcount > 0  --ya existe
begin
  --print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
  update cob_workflow..wf_variable_actual
     set va_valor_actual = isnull(@w_valor_nuevo, 'NO')
   where va_id_inst_proc = @i_id_inst_proc
     and va_codigo_var   = @i_id_variable    
end
else
BEGIN
 
  insert into cob_workflow..wf_variable_actual
         (va_id_inst_proc, va_codigo_var, va_valor_actual)
  values (@i_id_inst_proc, @i_id_variable, isnull(@w_valor_nuevo,'NO') )
  
  PRINT @@ERROR

end
--print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
if not exists(select 1 from cob_workflow..wf_mod_variable
              where mv_id_inst_proc = @i_id_inst_proc AND
                    mv_codigo_var= @i_id_variable AND
                    mv_id_asig_act = @i_id_asig_act)
BEGIN
    insert into cob_workflow..wf_mod_variable
           (mv_id_inst_proc, mv_codigo_var, mv_id_asig_act,
            mv_valor_anterior, mv_valor_nuevo, mv_fecha_mod)
    values (@i_id_inst_proc, @i_id_variable, @i_id_asig_act,
            @w_valor_ant, @w_valor_nuevo , getdate())
			
	if @@error > 0
	begin
            --registro ya existe
			
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file = @t_file, 
          @t_from = @t_from,
          @i_num = 2101002
    return 1
	end 

END

return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error

GO
