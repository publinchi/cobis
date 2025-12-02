/******************************************************************/
/*  Archivo:            interfopg_srv.sp                          */
/*  Stored procedure:   sp_interface_opgrupal_srv                 */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 30-May-2019                               */
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
/*  30/May/19        Lorena Regalado    Interface Creacion        */
/*                                      Operacion Grupal          */
/*  04/Jul/19        Adriana Giler      Nuevo Campo Clasificacion */
/*  15/Jul/19        Lorena Regalado    Genera Secuencial         */
/*  14/Ene/2020      Armando Miramón    Obtener el código oficial */
/******************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interface_opgrupal_srv')
   drop proc sp_interface_opgrupal_srv
go

create proc sp_interface_opgrupal_srv
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @t_trn                  int = 7469,
   @i_interfaz             char(1),
   @i_tipo_operacion       varchar(10),
   @i_oficina              smallint = null,
   @i_toperacion           varchar(10),
   @i_destino              varchar(10),
   @i_fecha                datetime, --(MM/DD/AAAA)     
   @i_moneda               tinyint,
   @i_monto                money,
   @i_plazo                smallint,
   @i_frecuencia           varchar(10)  = ' ',
   @i_tasa                 float,
   @i_fecha_primer_pago    datetime,
   @i_otros                varchar(255) = null,
   @i_grupo                int          = null,
   @i_monto_ahorro         money        = 0,
   @i_codeudor             int          = null,
   @i_oficial              smallint     = null,
   @i_cliente              int  = null,
   @i_banco                cuenta = null,
   @i_clasificacion        varchar(10) = null,           --AGC 04JUL19
   @o_secuencial           int     output                --LRE 15/Jul/2019

   

as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_secuencial           int,
   @w_oficial			   int
   
 
   exec @w_secuencial = ADMIN...rp_ssn      

	/*******	AMG - INICIO Consulta de código de oficial por código de funcionario	******/
	select @w_oficial = oc_oficial 
	from cobis..cl_funcionario inner join cobis..cc_oficial
		on oc_funcionario = fu_funcionario
	where fu_funcionario = @i_oficial

	if @w_oficial is null
	begin
		select @w_error = 151091
		goto ERROR
	end
	/*******	AMG - FIN Consulta de código de oficial por código de funcionario	******/
   
    insert cob_cartera..ca_interf_op_tmp  (
    iot_sesn,        iot_user,        iot_ofi,      iot_fecha_proceso,    iot_interfaz,   iot_tipo_operacion,
    iot_oficina,     iot_toperacion,  iot_destino,  iot_fecha_desemb,     iot_moneda,     iot_monto,
    iot_plazo,       iot_frecuencia,  iot_tasa,     iot_fecha_primer_pago,iot_otros,
    iot_grupo,       iot_monto_ahorro,iot_codeudor, iot_oficial,          iot_operacion,
    iot_ctaho_grupal,iot_banco,       iot_cliente,  iot_clasificacion )
    values (
    @w_secuencial,     @s_user,       @s_ofi,    @s_date,    @i_interfaz,   @i_tipo_operacion,
    @i_oficina,        @i_toperacion, @i_destino,@i_fecha,   @i_moneda,     @i_monto,
    @i_plazo,          @i_frecuencia, @i_tasa,   @i_fecha_primer_pago,      @i_otros,
    @i_grupo,          @i_monto_ahorro, @i_codeudor, @w_oficial, NULL, 
    NULL,              @i_banco,      @i_cliente, @i_clasificacion)    --AGC 04JUL19)   
       
    if @@error <> 0
    begin
       select @w_error = 725050
       goto ERROR
    end

    select @o_secuencial = @w_secuencial

return 0

ERROR:

    while @@trancount > 0 ROLLBACK TRAN
    
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
   
   return @w_error
   
go

