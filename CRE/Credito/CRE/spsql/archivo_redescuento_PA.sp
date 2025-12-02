/************************************************************************/
/*  Archivo:                archivo_redescuento_PA.sp                   */
/*  Stored procedure:       sp_archivo_redescuento_PA                   */
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

if exists (select 1 from sysobjects where name = 'sp_archivo_redescuento_PA' and type = 'P')
   drop proc sp_archivo_redescuento_PA
go



create proc sp_archivo_redescuento_PA (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_ofi                smallint  = null,
   @s_srv                varchar(30) = null,
   @s_lsrv               varchar(30) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_tramite            int = null,
   @i_num_operacion      cuenta = null,
   @i_fecha_envio        datetime = null,
   @i_cliente            int = null,
   @i_estado_reg         char(1) = null,
   @i_cuota_desde_1		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_1		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_1		money = null,		--VALOR CUOTA 1
   @i_cuota_desde_2		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_2		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_2		money = null,		--VALOR CUOTA 2
   @i_cuota_desde_3		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_3		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_3		money = null,		--VALOR CUOTA 3
   @i_cuota_desde_4		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_4		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_4		money = null,		--VALOR CUOTA 4
   @i_cuota_desde_5		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_5		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_5		money = null,		--VALOR CUOTA 5
   @i_cuota_desde_6		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_6		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_6		money = null,		--VALOR CUOTA 6
   @i_cuota_desde_7		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_7		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_7		money = null,		--VALOR CUOTA 7
   @i_cuota_desde_8		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_8		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_8		money = null,		--VALOR CUOTA 8
   @i_cuota_desde_9		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_9		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_9		money = null,		--VALOR CUOTA 9
   @i_cuota_desde_10		smallint = null,           --NUMERO CUOTA INICIAL	
   @i_cuota_hasta_10		smallint = null,		--NUMERO CUOTA FINAL
   @i_valor_cuota_10		money = null,		--VALOR CUOTA 10
   @i_fecha_amor_1		datetime = null,		--FECHA AMORT. 1     
   @i_valor_amor_1		money = null,		--VALOR AMORT
   @i_tipo_amor_1		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_2		datetime = null,		--FECHA AMORT. 2
   @i_valor_amor_2		money = null,		--VALOR AMORT
   @i_tipo_amor_2		smallint = null,		--TIPO AMORT
   @i_fecha_amor_3		datetime = null,		--FECHA AMORT. 3
   @i_valor_amor_3		money = null,		--VALOR AMORT
   @i_tipo_amor_3		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_4		datetime = null,		--FECHA AMORT. 4     
   @i_valor_amor_4		money = null,		--VALOR AMORT
   @i_tipo_amor_4		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_5		datetime = null,		--FECHA AMORT. 5
   @i_valor_amor_5		money = null,		--VALOR AMORT
   @i_tipo_amor_5		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_6		datetime = null,		--FECHA AMORT. 6
   @i_valor_amor_6		money = null,		--VALOR AMORT
   @i_tipo_amor_6		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_7		datetime = null,		--FECHA AMORT. 7
   @i_valor_amor_7		money = null,		--VALOR AMORT
   @i_tipo_amor_7		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_8		datetime = null,		--FECHA AMORT. 8
   @i_valor_amor_8		money = null,		--VALOR AMORT
   @i_tipo_amor_8		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_9		datetime = null,		--FECHA AMORT. 9
   @i_valor_amor_9		money = null,		--VALOR AMORT
   @i_tipo_amor_9		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_10		datetime = null,		--FECHA AMORT. 10
   @i_valor_amor_10		money = null,		--VALOR AMORT
   @i_tipo_amor_10		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_11		datetime = null,		--FECHA AMORT. 11
   @i_valor_amor_11		money = null,		--VALOR AMORT
   @i_tipo_amor_11		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_12		datetime = null,		--FECHA AMORT. 12
   @i_valor_amor_12		money = null,		--VALOR AMORT
   @i_tipo_amor_12		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_13		datetime = null,		--FECHA AMORT. 13
   @i_valor_amor_13		money = null,		--VALOR AMORT
   @i_tipo_amor_13		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_14		datetime = null,		--FECHA AMORT. 14
   @i_valor_amor_14		money = null,		--VALOR AMORT
   @i_tipo_amor_14		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_15		datetime = null,		--FECHA AMORT. 15
   @i_valor_amor_15		money = null,		--VALOR AMORT
   @i_tipo_amor_15		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_16		datetime = null,		--FECHA AMORT. 16
   @i_valor_amor_16		money = null,		--VALOR AMORT
   @i_tipo_amor_16		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_17		datetime = null,		--FECHA AMORT. 17
   @i_valor_amor_17		money = null,		--VALOR AMORT
   @i_tipo_amor_17		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_18		datetime = null,		--FECHA AMORT. 18
   @i_valor_amor_18		money = null,		--VALOR AMORT
   @i_tipo_amor_18		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_19		datetime = null,		--FECHA AMORT. 19
   @i_valor_amor_19		money = null,		--VALOR AMORT
   @i_tipo_amor_19		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_20		datetime = null,		--FECHA AMORT. 20
   @i_valor_amor_20		money = null,		--VALOR AMORT
   @i_tipo_amor_20		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_21		datetime = null,		--FECHA AMORT. 21     
   @i_valor_amor_21		money = null,		--VALOR AMORT
   @i_tipo_amor_21		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_22		datetime = null,		--FECHA AMORT. 22
   @i_valor_amor_22		money = null,		--VALOR AMORT
   @i_tipo_amor_22		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_23		datetime = null,		--FECHA AMORT. 23
   @i_valor_amor_23		money = null,		--VALOR AMORT
   @i_tipo_amor_23		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_24		datetime = null,		--FECHA AMORT. 24
   @i_valor_amor_24		money = null,		--VALOR AMORT
   @i_tipo_amor_24		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_25		datetime = null,		--FECHA AMORT. 25
   @i_valor_amor_25		money = null,		--VALOR AMORT
   @i_tipo_amor_25		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_26		datetime = null,		--FECHA AMORT. 26
   @i_valor_amor_26		money = null,		--VALOR AMORT
   @i_tipo_amor_26		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_27		datetime = null,		--FECHA AMORT. 27
   @i_valor_amor_27		money = null,		--VALOR AMORT
   @i_tipo_amor_27		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_28		datetime = null,		--FECHA AMORT. 28
   @i_valor_amor_28		money = null,		--VALOR AMORT
   @i_tipo_amor_28		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_29		datetime = null,		--FECHA AMORT. 29
   @i_valor_amor_29		money = null,		--VALOR AMORT
   @i_tipo_amor_29		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_30		datetime = null,		--FECHA AMORT. 30
   @i_valor_amor_30		money = null,		--VALOR AMORT
   @i_tipo_amor_30		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_31		datetime = null,		--FECHA AMORT. 31     
   @i_valor_amor_31		money = null,		--VALOR AMORT
   @i_tipo_amor_31		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_32		datetime = null,		--FECHA AMORT. 32
   @i_valor_amor_32		money = null,		--VALOR AMORT
   @i_tipo_amor_32		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_33		datetime = null,		--FECHA AMORT. 33     
   @i_valor_amor_33		money = null,		--VALOR AMORT
   @i_tipo_amor_33		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_34		datetime = null,		--FECHA AMORT. 34     
   @i_valor_amor_34		money = null,		--VALOR AMORT
   @i_tipo_amor_34		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_35		datetime = null,		--FECHA AMORT. 35     
   @i_valor_amor_35		money = null,		--VALOR AMORT
   @i_tipo_amor_35		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_36		datetime = null,		--FECHA AMORT. 36     
   @i_valor_amor_36		money = null,		--VALOR AMORT
   @i_tipo_amor_36		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_37		datetime = null,		--FECHA AMORT. 37     
   @i_valor_amor_37		money = null,		--VALOR AMORT
   @i_tipo_amor_37		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_38		datetime = null,		--FECHA AMORT. 38     
   @i_valor_amor_38		money = null,		--VALOR AMORT
   @i_tipo_amor_38		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_39		datetime = null,		--FECHA AMORT. 39     
   @i_valor_amor_39		money = null,		--VALOR AMORT
   @i_tipo_amor_39		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_40		datetime = null,		--FECHA AMORT. 40     
   @i_valor_amor_40		money = null,		--VALOR AMORT
   @i_tipo_amor_40		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_41		datetime = null,		--FECHA AMORT. 41     
   @i_valor_amor_41		money = null,		--VALOR AMORT
   @i_tipo_amor_41		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_42		datetime = null,		--FECHA AMORT. 42
   @i_valor_amor_42		money = null,		--VALOR AMORT
   @i_tipo_amor_42		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_43		datetime = null,		--FECHA AMORT. 43     
   @i_valor_amor_43		money = null,		--VALOR AMORT
   @i_tipo_amor_43		smallint = null,		--TIPO AMORT. 
   @i_fecha_amor_44		datetime = null,		--FECHA AMORT. 44     
   @i_valor_amor_44		money = null,		--VALOR AMORT
   @i_tipo_amor_44		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_45		datetime = null,		--FECHA AMORT. 45     
   @i_valor_amor_45		money = null,		--VALOR AMORT
   @i_tipo_amor_45		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_46		datetime = null,		--FECHA AMORT. 46     
   @i_valor_amor_46		money = null,		--VALOR AMORT
   @i_tipo_amor_46		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_47		datetime = null,		--FECHA AMORT. 47     
   @i_valor_amor_47		money = null,		--VALOR AMORT
   @i_tipo_amor_47		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_48		datetime = null,		--FECHA AMORT. 48     
   @i_valor_amor_48		money = null,		--VALOR AMORT
   @i_tipo_amor_48		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_49		datetime = null,		--FECHA AMORT. 49     
   @i_valor_amor_49		money = null,		--VALOR AMORT
   @i_tipo_amor_49		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_50		datetime = null,		--FECHA AMORT. 50     
   @i_valor_amor_50		money = null,		--VALOR AMORT
   @i_tipo_amor_50		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_51		datetime = null,		--FECHA AMORT. 51     
   @i_valor_amor_51		money = null,		--VALOR AMORT
   @i_tipo_amor_51		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_52		datetime = null,		--FECHA AMORT. 52     
   @i_valor_amor_52		money = null,		--VALOR AMORT
   @i_tipo_amor_52		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_53		datetime = null,		--FECHA AMORT. 53     
   @i_valor_amor_53		money = null,		--VALOR AMORT
   @i_tipo_amor_53		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_54		datetime = null,		--FECHA AMORT. 54     
   @i_valor_amor_54		money = null,		--VALOR AMORT
   @i_tipo_amor_54		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_55		datetime = null,		--FECHA AMORT. 55     
   @i_valor_amor_55		money = null,		--VALOR AMORT
   @i_tipo_amor_55		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_56		datetime = null,		--FECHA AMORT. 56    
   @i_valor_amor_56		money = null,		--VALOR AMORT
   @i_tipo_amor_56		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_57		datetime = null,		--FECHA AMORT. 57     
   @i_valor_amor_57		money = null,		--VALOR AMORT
   @i_tipo_amor_57		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_58		datetime = null,		--FECHA AMORT. 58     
   @i_valor_amor_58		money = null,		--VALOR AMORT
   @i_tipo_amor_58		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_59		datetime = null,		--FECHA AMORT. 59     
   @i_valor_amor_59		money = null,		--VALOR AMORT
   @i_tipo_amor_59		smallint = null,		--TIPO AMORT.
   @i_fecha_amor_60		datetime = null,		--FECHA AMORT. 60    
   @i_valor_amor_60		money = null,		--VALOR AMORT
   @i_tipo_amor_60		smallint = null,		--TIPO AMORT.
   @i_cod_rubro_ppal		char(6)	= null,		--CODIGO RUBRO PPAL.
   @i_cant_unid_finan_ppal	int = null,		--CANTIDAD UNIDADES A FINANCIAR
   @i_costo_inv_rubro_ppal	money = null,		--COSTO DE INVERSION RUBRO PPAL
   @i_valor_fin_rubro_ppal	money = null,		--VALOR A FINANCIAR RUBRO PPAL
   @i_cod_rubro_2		char(6) = null,		--CODIGO RUBRO PPAL.
   @i_cant_unid_finan_2	        int = null,		--CANTIDAD UNIDADES A FINANCIAR
   @i_costo_inv_rubro_2	        money = null,		--COSTO DE INVERSION RUBRO PPAL
   @i_valor_fin_rubro_2	        money = null,		--VALOR A FINANCIAR RUBRO PPAL
   @i_cod_rubro_3		char(6) = null,		--CODIGO RUBRO PPAL.
   @i_cant_unid_finan_3	        int = null,		--CANTIDAD UNIDADES A FINANCIAR
   @i_costo_inv_rubro_3	        money = null,		--COSTO DE INVERSION RUBRO PPAL
   @i_valor_fin_rubro_3		money = null,		--VALOR A FINANCIAR RUBRO PPAL
   @i_cod_rubro_4		char(6) = null,		--CODIGO RUBRO PPAL.
   @i_cant_unid_finan_4		int = null,		--CANTIDAD UNIDADES A FINANCIAR
   @i_costo_inv_rubro_4		money = null,		--COSTO DE INVERSION RUBRO PPAL
   @i_valor_fin_rubro_4		money = null,		--VALOR A FINANCIAR RUBRO PPAL
   @i_cod_rubro_5		char(6)	= null,		--CODIGO RUBRO PPAL.
   @i_cant_unid_finan_5		int = null,		--CANTIDAD UNIDADES A FINANCIAR
   @i_costo_inv_rubro_5		money = null,		--COSTO DE INVERSION RUBRO PPAL
   @i_valor_fin_rubro_5		money = null,		--VALOR A FINANCIAR RUBRO PPAL
   @i_codesamo                  tinyint = null,
   @i_covalgir                  tinyint = null,
   @i_copermue                  tinyint = null
)
as

declare
   @w_today              datetime,     /* FECHA DEL DIA      */ 
   @w_return             int,          /* VALOR QUE RETORNA  */
   @w_sp_name            varchar(32),  /* NOMBRE STORED PROC */
   @w_existe             tinyint       /* EXISTE EL REGISTRO */

select @w_today   = @s_date,
       @w_sp_name = 'sp_archivo_redescuento_PA',
       @w_existe  = 0

/* Codigos de Transacciones     */
/********************************/
if (@t_trn <> 22000 and @i_operacion = 'I') -- or
   -- (@t_trn <> 22001 and @i_operacion = 'U') or
   -- (@t_trn <> 22002 and @i_operacion = 'D') or
   -- (@t_trn <> 22003 and @i_operacion = 'S') or
   -- (@t_trn <> 22005 and @i_operacion = 'Q')
   -- (@t_trn <> 22004 and @i_operacion = 'V') or
   -- (@t_trn <> 22006 and @i_operacion = 'A')

BEGIN
    /* TIPO DE TRANSACCION NO CORRESPONDE */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 2101006
end


/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' -- or @i_operacion = 'U'
BEGIN
    if   @i_num_operacion is NULL and
         @i_fecha_envio   is NULL and
         @i_cliente       is NULL
    BEGIN
        /* CAMPOS NOT NULL CON VALORES NULOS */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 2101001
    END
END


/* INSERCION DEL REGISTRO */
/**************************/
if @i_operacion = 'I'
BEGIN
    BEGIN TRAN
        insert into cr_arch_redes_tamortiz (
        re_tramite,		        re_operacion,			re_fecha_envio,
   	re_cliente,                     re_cuota_desde_1,	
	re_cuota_hasta_1,		re_valor_cuota_1,
	re_cuota_desde_2,		re_cuota_hasta_2,		re_valor_cuota_2,
	re_cuota_desde_3,		re_cuota_hasta_3,		re_valor_cuota_3,		
	re_cuota_desde_4,		re_cuota_hasta_4,		re_valor_cuota_4,		
	re_cuota_desde_5,		re_cuota_hasta_5,		re_valor_cuota_5,		
	re_cuota_desde_6,		re_cuota_hasta_6,		re_valor_cuota_6,		
	re_cuota_desde_7,		re_cuota_hasta_7,		re_valor_cuota_7,		
	re_cuota_desde_8,		re_cuota_hasta_8,		re_valor_cuota_8,		
	re_cuota_desde_9,		re_cuota_hasta_9,		re_valor_cuota_9,		
	re_cuota_desde_10,		re_cuota_hasta_10,		re_valor_cuota_10,		     
	re_fecha_amor_1,		re_valor_amor_1,		re_tipo_amor_1,	        
	re_fecha_amor_2,		re_valor_amor_2,		re_tipo_amor_2,	        
	re_fecha_amor_3,		re_valor_amor_3,		re_tipo_amor_3,	        
	re_fecha_amor_4,		re_valor_amor_4,		re_tipo_amor_4,	        
	re_fecha_amor_5,		re_valor_amor_5,		re_tipo_amor_5,	        
	re_fecha_amor_6,		re_valor_amor_6,		re_tipo_amor_6,	        
	re_fecha_amor_7,		re_valor_amor_7,		re_tipo_amor_7,	        
	re_fecha_amor_8,		re_valor_amor_8,		re_tipo_amor_8,	        
	re_fecha_amor_9,		re_valor_amor_9,		re_tipo_amor_9,	        
	re_fecha_amor_10,		re_valor_amor_10,		re_tipo_amor_10,
	re_fecha_amor_11,		re_valor_amor_11,		re_tipo_amor_11,		        
	re_fecha_amor_12,		re_valor_amor_12,		re_tipo_amor_12,		        
	re_fecha_amor_13,		re_valor_amor_13,		re_tipo_amor_13,		        
	re_fecha_amor_14,		re_valor_amor_14,		re_tipo_amor_14,		        
	re_fecha_amor_15,		re_valor_amor_15,		re_tipo_amor_15,		        
	re_fecha_amor_16,		re_valor_amor_16,		re_tipo_amor_16,		        
	re_fecha_amor_17,		re_valor_amor_17,		re_tipo_amor_17,		        
	re_fecha_amor_18,		re_valor_amor_18,		re_tipo_amor_18,	        
	re_fecha_amor_19,		re_valor_amor_19,		re_tipo_amor_19,		        
	re_fecha_amor_20,		re_valor_amor_20,		re_tipo_amor_20,	         
	re_fecha_amor_21,		re_valor_amor_21,		re_tipo_amor_21,		        
	re_fecha_amor_22,		re_valor_amor_22,		re_tipo_amor_22,		        
	re_fecha_amor_23,		re_valor_amor_23,		re_tipo_amor_23,		        
	re_fecha_amor_24,		re_valor_amor_24,		re_tipo_amor_24,		        
	re_fecha_amor_25,		re_valor_amor_25,		re_tipo_amor_25,		        
	re_fecha_amor_26,		re_valor_amor_26,		re_tipo_amor_26,		        
	re_fecha_amor_27,		re_valor_amor_27,		re_tipo_amor_27,		        
	re_fecha_amor_28,		re_valor_amor_28,		re_tipo_amor_28,		        
	re_fecha_amor_29,		re_valor_amor_29,		re_tipo_amor_29,		        
	re_fecha_amor_30,		re_valor_amor_30,		re_tipo_amor_30,		                        
	re_fecha_amor_31,		re_valor_amor_31,		re_tipo_amor_31,		        
	re_fecha_amor_32,		re_valor_amor_32,		re_tipo_amor_32,		        
	re_fecha_amor_33,		re_valor_amor_33,		re_tipo_amor_33,		        
	re_fecha_amor_34,		re_valor_amor_34,		re_tipo_amor_34,		        
	re_fecha_amor_35,		re_valor_amor_35,		re_tipo_amor_35,		        
	re_fecha_amor_36,		re_valor_amor_36,		re_tipo_amor_36,		        
	re_fecha_amor_37,		re_valor_amor_37,		re_tipo_amor_37,		        
	re_fecha_amor_38,		re_valor_amor_38,		re_tipo_amor_38,		        
	re_fecha_amor_39,		re_valor_amor_39,		re_tipo_amor_39,		        
	re_fecha_amor_40,		re_valor_amor_40,		re_tipo_amor_40,		                         
	re_fecha_amor_41,		re_valor_amor_41,		re_tipo_amor_41,		        
	re_fecha_amor_42,		re_valor_amor_42,		re_tipo_amor_42,		        
	re_fecha_amor_43,		re_valor_amor_43,		re_tipo_amor_43,		        
	re_fecha_amor_44,		re_valor_amor_44,		re_tipo_amor_44,		        
	re_fecha_amor_45,		re_valor_amor_45,		re_tipo_amor_45,		        
	re_fecha_amor_46,		re_valor_amor_46,		re_tipo_amor_46,		                           
	re_fecha_amor_47,		re_valor_amor_47,		re_tipo_amor_47,		        
	re_fecha_amor_48,		re_valor_amor_48,		re_tipo_amor_48,		        
	re_fecha_amor_49,		re_valor_amor_49,		re_tipo_amor_49,		        
	re_fecha_amor_50,		re_valor_amor_50,		re_tipo_amor_50,		                          
	re_fecha_amor_51,		re_valor_amor_51,		re_tipo_amor_51,		        
	re_fecha_amor_52,		re_valor_amor_52,		re_tipo_amor_52,		        
	re_fecha_amor_53,		re_valor_amor_53,		re_tipo_amor_53,		        
	re_fecha_amor_54,		re_valor_amor_54,		re_tipo_amor_54,		        
	re_fecha_amor_55,		re_valor_amor_55,		re_tipo_amor_55,		        
	re_fecha_amor_56,		re_valor_amor_56,		re_tipo_amor_56,		        
	re_fecha_amor_57,		re_valor_amor_57,		re_tipo_amor_57,		        
	re_fecha_amor_58,		re_valor_amor_58,		re_tipo_amor_58,	        
	re_fecha_amor_59,		re_valor_amor_59,		re_tipo_amor_59,		        
	re_fecha_amor_60,		re_valor_amor_60,		re_tipo_amor_60,		                        
	re_cod_rubro_ppal,		re_cant_unid_finan_ppal,	re_costo_inv_rubro_ppal,	        
	re_valor_fin_rubro_ppal,	re_cod_rubro_2,			re_cant_unid_finan_2,	        
	re_costo_inv_rubro_2,		re_valor_fin_rubro_2,		re_cod_rubro_3,		        
	re_cant_unid_finan_3,		re_costo_inv_rubro_3,		re_valor_fin_rubro_3,	        
	re_cod_rubro_4,			re_cant_unid_finan_4,		re_costo_inv_rubro_4,	        
	re_valor_fin_rubro_4,		re_cod_rubro_5,			re_cant_unid_finan_5,	        
	re_costo_inv_rubro_5,		re_valor_fin_rubro_5,           re_codesamo,
        re_covalgir,                    re_copermue
        )
        values (
        @i_tramite,		        @i_num_operacion,	        @i_fecha_envio,
        @i_cliente,                     @i_cuota_desde_1,	
	@i_cuota_hasta_1,		@i_valor_cuota_1,
	@i_cuota_desde_2,		@i_cuota_hasta_2,		@i_valor_cuota_2,
	@i_cuota_desde_3,		@i_cuota_hasta_3,		@i_valor_cuota_3,		
	@i_cuota_desde_4,		@i_cuota_hasta_4,		@i_valor_cuota_4,		
	@i_cuota_desde_5,		@i_cuota_hasta_5,		@i_valor_cuota_5,		
	@i_cuota_desde_6,		@i_cuota_hasta_6,		@i_valor_cuota_6,		
	@i_cuota_desde_7,		@i_cuota_hasta_7,		@i_valor_cuota_7,		
	@i_cuota_desde_8,		@i_cuota_hasta_8,		@i_valor_cuota_8,		
	@i_cuota_desde_9,		@i_cuota_hasta_9,		@i_valor_cuota_9,		
	@i_cuota_desde_10,		@i_cuota_hasta_10,		@i_valor_cuota_10,		     
	@i_fecha_amor_1,		@i_valor_amor_1,		@i_tipo_amor_1,	        
	@i_fecha_amor_2,		@i_valor_amor_2,		@i_tipo_amor_2,	        
	@i_fecha_amor_3,		@i_valor_amor_3,		@i_tipo_amor_3,	        
	@i_fecha_amor_4,		@i_valor_amor_4,		@i_tipo_amor_4,	        
	@i_fecha_amor_5,		@i_valor_amor_5,		@i_tipo_amor_5,	        
	@i_fecha_amor_6,		@i_valor_amor_6,		@i_tipo_amor_6,	        
	@i_fecha_amor_7,		@i_valor_amor_7,		@i_tipo_amor_7,	        
	@i_fecha_amor_8,		@i_valor_amor_8,		@i_tipo_amor_8,	        
	@i_fecha_amor_9,		@i_valor_amor_9,		@i_tipo_amor_9,	        
	@i_fecha_amor_10,		@i_valor_amor_10,		@i_tipo_amor_10,
	@i_fecha_amor_11,		@i_valor_amor_11,		@i_tipo_amor_11,		        
	@i_fecha_amor_12,		@i_valor_amor_12,		@i_tipo_amor_12,		        
	@i_fecha_amor_13,		@i_valor_amor_13,		@i_tipo_amor_13,		        
	@i_fecha_amor_14,		@i_valor_amor_14,		@i_tipo_amor_14,		        
	@i_fecha_amor_15,		@i_valor_amor_15,		@i_tipo_amor_15,		        
	@i_fecha_amor_16,		@i_valor_amor_16,		@i_tipo_amor_16,		        
	@i_fecha_amor_17,		@i_valor_amor_17,		@i_tipo_amor_17,		        
	@i_fecha_amor_18,		@i_valor_amor_18,		@i_tipo_amor_18,	        
	@i_fecha_amor_19,		@i_valor_amor_19,		@i_tipo_amor_19,		        
	@i_fecha_amor_20,		@i_valor_amor_20,		@i_tipo_amor_20,	         
	@i_fecha_amor_21,		@i_valor_amor_21,		@i_tipo_amor_21,		        
	@i_fecha_amor_22,		@i_valor_amor_22,		@i_tipo_amor_22,		        
	@i_fecha_amor_23,		@i_valor_amor_23,		@i_tipo_amor_23,		        
	@i_fecha_amor_24,		@i_valor_amor_24,		@i_tipo_amor_24,		        
	@i_fecha_amor_25,		@i_valor_amor_25,		@i_tipo_amor_25,		        
	@i_fecha_amor_26,		@i_valor_amor_26,		@i_tipo_amor_26,		        
	@i_fecha_amor_27,		@i_valor_amor_27,		@i_tipo_amor_27,		        
	@i_fecha_amor_28,		@i_valor_amor_28,		@i_tipo_amor_28,		        
	@i_fecha_amor_29,		@i_valor_amor_29,		@i_tipo_amor_29,		        
	@i_fecha_amor_30,		@i_valor_amor_30,		@i_tipo_amor_30,		                        
	@i_fecha_amor_31,		@i_valor_amor_31,		@i_tipo_amor_31,		        
	@i_fecha_amor_32,		@i_valor_amor_32,		@i_tipo_amor_32,		        
	@i_fecha_amor_33,		@i_valor_amor_33,		@i_tipo_amor_33,		        
	@i_fecha_amor_34,		@i_valor_amor_34,		@i_tipo_amor_34,		        
	@i_fecha_amor_35,		@i_valor_amor_35,		@i_tipo_amor_35,		        
	@i_fecha_amor_36,		@i_valor_amor_36,		@i_tipo_amor_36,		        
	@i_fecha_amor_37,		@i_valor_amor_37,		@i_tipo_amor_37,		        
	@i_fecha_amor_38,		@i_valor_amor_38,		@i_tipo_amor_38,		        
	@i_fecha_amor_39,		@i_valor_amor_39,		@i_tipo_amor_39,		        
	@i_fecha_amor_40,		@i_valor_amor_40,		@i_tipo_amor_40,		                         
	@i_fecha_amor_41,		@i_valor_amor_41,		@i_tipo_amor_41,		        
	@i_fecha_amor_42,		@i_valor_amor_42,		@i_tipo_amor_42,		        
	@i_fecha_amor_43,		@i_valor_amor_43,		@i_tipo_amor_43,		        
	@i_fecha_amor_44,		@i_valor_amor_44,		@i_tipo_amor_44,		        
	@i_fecha_amor_45,		@i_valor_amor_45,		@i_tipo_amor_45,		        
	@i_fecha_amor_46,		@i_valor_amor_46,		@i_tipo_amor_46,		                           
	@i_fecha_amor_47,		@i_valor_amor_47,		@i_tipo_amor_47,		        
	@i_fecha_amor_48,		@i_valor_amor_48,		@i_tipo_amor_48,		        
	@i_fecha_amor_49,		@i_valor_amor_49,		@i_tipo_amor_49,		        
	@i_fecha_amor_50,		@i_valor_amor_50,		@i_tipo_amor_50,		                          
	@i_fecha_amor_51,		@i_valor_amor_51,		@i_tipo_amor_51,		        
	@i_fecha_amor_52,		@i_valor_amor_52,		@i_tipo_amor_52,		        
	@i_fecha_amor_53,		@i_valor_amor_53,		@i_tipo_amor_53,		        
	@i_fecha_amor_54,		@i_valor_amor_54,		@i_tipo_amor_54,		        
	@i_fecha_amor_55,		@i_valor_amor_55,		@i_tipo_amor_55,		        
	@i_fecha_amor_56,		@i_valor_amor_56,		@i_tipo_amor_56,		        
	@i_fecha_amor_57,		@i_valor_amor_57,		@i_tipo_amor_57,		        
	@i_fecha_amor_58,		@i_valor_amor_58,		@i_tipo_amor_58,	        
	@i_fecha_amor_59,		@i_valor_amor_59,		@i_tipo_amor_59,		        
	@i_fecha_amor_60,		@i_valor_amor_60,		@i_tipo_amor_60,		                        
	@i_cod_rubro_ppal,		@i_cant_unid_finan_ppal,	@i_costo_inv_rubro_ppal,	        
	@i_valor_fin_rubro_ppal,	@i_cod_rubro_2,			@i_cant_unid_finan_2,	        
	@i_costo_inv_rubro_2,		@i_valor_fin_rubro_2,		@i_cod_rubro_3,		        
	@i_cant_unid_finan_3,		@i_costo_inv_rubro_3,		@i_valor_fin_rubro_3,	        
	@i_cod_rubro_4,			@i_cant_unid_finan_4,		@i_costo_inv_rubro_4,	        
	@i_valor_fin_rubro_4,		@i_cod_rubro_5,			@i_cant_unid_finan_5,	        
	@i_costo_inv_rubro_5,		@i_valor_fin_rubro_5,   	@i_codesamo,
	@i_covalgir,   			@i_copermue
        )

         if @@error <> 0 
         BEGIN
            /* ERROR EN INSERCION DE REGISTRO */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103001
             return 2103001
         END
    COMMIT TRAN 
END
                                        
return 0

GO
