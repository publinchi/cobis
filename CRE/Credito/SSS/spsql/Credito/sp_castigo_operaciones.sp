/************************************************************************/
/*  Archivo:                castigo_operaciones.sp                       */
/*  Stored procedure:       sp_castigo_operaciones                       */
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

if exists (select 1 from sysobjects where name = 'sp_castigo_operaciones' and type = 'P')
   drop proc sp_castigo_operaciones
go

create procedure sp_castigo_operaciones(
    @s_ssn_branch           int          = null,
    @s_srv                  varchar(30)  = null,
    @s_lsrv                 varchar(30)  = null,
    @s_user                 varchar(30)  = null,
    @s_term                 varchar(10)  = null,
    @s_date                 datetime     = null,
    @s_ofi                  smallint     = null,--1,
    @s_rol                  smallint     = null,--1,
    @s_error                int          = null,
    @s_msg                  varchar(64)  = null,
    @s_org                  char(1)      = null,
    @t_show_version         bit          = 0,
    @t_trn                  int,
    @t_debug                char(1)      = 'N',
    @t_file                 varchar(14)  = null,
    @i_operacion            char(1)      = null,
    @i_int_proceso          int          = null,
    @i_num_operacion        varchar(24)  = null,
    @i_agencia              smallint     = null,
    @i_estado               char(1)      = null,
    @i_problema             varchar(255) = null,
    @i_imposibilidad_pago   varchar(255) = null,
    @i_imposibilidad_pago2  varchar(255) = null,
    @i_imposibilidad_pago3  varchar(255) = null,
    @i_razones              varchar(255) = null,
    @i_razones2             varchar(255) = null,
    @i_razones3             varchar(255) = null,
    @i_coherencia           varchar(255) = null,
    @i_observacion          varchar(255) = null,
    @i_cliente              int          = null,
    @i_tramite              int          = null,
    @i_fecha_corte          datetime     = null,
	@i_numero_juicio		varchar(255) = null,
	@i_estado_cobranza		varchar(255) = null,
	@i_txt_razon		 	varchar(255) = null
  )
  as
  declare
    @w_sp_name                      varchar(30),
    @w_error                     int,
    @w_banco                     varchar(24),
    @w_fecha_corte                  datetime,
    @w_agencia                     int,
    @w_estado                     char(1),
    @w_problema                     varchar(255),
    @w_imposibilidad_pago          varchar(765),
    @w_razones                     varchar(765),
    @w_coherencia                  varchar(255) ,
    @w_observacion                 varchar(255),
    @w_cliente                   int,
    @w_oficial                   int,
    @w_regional                  char(10),
    @w_subregional               char(10),
    @w_cargo                     varchar(10),
    @w_ambito                    char(10),
    @w_id_tramite                int,
    /* Datos de cartera */
    @w_fecha_diaria              datetime,
    @w_modulo_cobis              int,
    @w_val_prev_esp_moneda_local money,
    @w_val_prev_esp_moneda_otra  money,
    @w_calificacion_categoria    varchar(10),
	@w_numero_juicio			 varchar(255),
	@w_estado_cobranza			 varchar(255),
	@w_paramMassive  			 char(2),
	@w_date_rate                 datetime

    select @w_sp_name= 'sp_castigo_operaciones'
    if @t_show_version = 1
      begin
        print 'Stored Procedure   Version:' + @w_sp_name + convert(varchar,@t_show_version)
      return 0
      end

if @t_trn <> 21865
     begin --Tipo de transaccion no corresponde
        select @w_error = 2101006
          goto ERROR
        end

---------------------------
-- VALIDACION DE EXISTENCIAS
---------------------------

select @w_paramMassive = pa_char from cobis..cl_parametro 
				where pa_nemonico = 'CASOMA'
--Cuando se hace un update de forma masiva, estos parametros son iguales
if(@w_paramMassive is not null and @w_paramMassive ='S') and @i_operacion <> 'Q'
begin
	select @i_tramite = ca_tramite from cob_credito..cr_tr_castigo
			where ca_banco = @i_num_operacion
	select @i_int_proceso = @i_tramite
end
      if   @i_int_proceso = null
        begin
          --Campos NOT NULL con valores nulos
          /* 'Error al Insertar '*/
            exec cobis..sp_cerror
            @t_debug      = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num     = 2101001
            return 2101001
        end
---------------------------
-- OPERACION I
---------------------------
  if @i_operacion = 'I'
  begin
    select @i_cliente = isnull(@i_cliente, io_campo_1),
           @i_num_operacion = isnull(@i_num_operacion,io_campo_2)
    from cob_workflow..wf_inst_proceso
    where io_id_inst_proc = @i_int_proceso --@i_instancia_wf

    select @w_fecha_corte = max(cc_fecha_corte) from cob_cartera..ca_candidata_castigo where cc_banco = @i_num_operacion
    select @w_regional     = convert(varchar(10),@s_ofi) --of_regional, 
    select @w_subregional  = convert(varchar(10),@s_ofi) --of_subregional from cobis..cl_oficina where of_oficina = @s_ofi --1--cod oficina de conexion

    select @w_cargo = convert(varchar(10), fu_cargo) from cobis..cl_funcionario where fu_login = @s_user --'iordonez' --usuario de conexion
    select @w_ambito = ''--am_cod_ambito from cobis..ad_ambito where am_cargo = @w_cargo and am_estado = 'V'-- '1'  -- w_cargo

    if @i_tramite = null or @i_num_operacion = null
       begin
         --Campos NOT NULL con valores nulos
          /* 'Error al Insertar '*/
            exec cobis..sp_cerror
            @t_debug      = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num     = 2101001
            return 2101001
       end

    insert into cob_credito..cr_tr_castigo
           (ca_int_proceso, ca_tramite, ca_fecha_corte, ca_banco,         ca_cliente,    ca_agencia,     ca_estado,
            ca_problema,    ca_razones, ca_razones2,    ca_razones3,      ca_coherencia, ca_observacion, ca_regional,
            ca_subregional, ca_ambito,  ca_imposibilidad_pago, ca_imposibilidad_pago2, ca_imposibilidad_pago3,
			ca_numero_juicio, ca_estado_cobranza)
    values (@i_int_proceso, @i_tramite, @w_fecha_corte, @i_num_operacion, @i_cliente,    @i_agencia,     @i_estado,
            @i_problema,    @i_razones, @i_razones2,    @i_razones3,      @i_coherencia, @i_observacion, @w_regional,
            @w_subregional, @w_ambito,  @i_imposibilidad_pago, @i_imposibilidad_pago2, @i_imposibilidad_pago3,
			@i_numero_juicio, @i_estado_cobranza)
    if @@error <> 0
       begin
              rollback tran
              select @w_error = 2103001
              goto ERROR
       END
  end

---------------------------
-- OPERACION U
---------------------------	  
if @i_operacion = 'U'
begin
	
	select @w_paramMassive = pa_char from cobis..cl_parametro 
				where pa_nemonico = 'CASOMA'

	--Cuando se hace un update de forma masiva, estos parametros son iguales
	if(@w_paramMassive is not null and @w_paramMassive ='S')
	begin
		select @i_tramite = ca_tramite from cob_credito..cr_tr_castigo
				where ca_banco = @i_num_operacion
		select @i_int_proceso = @i_tramite

	end


    if @i_int_proceso = null or @i_tramite = null or @i_num_operacion = null
    begin
        select @w_error = 2101001
        goto ERROR
    end

    update cob_credito..cr_tr_castigo
    set   ca_agencia             = isnull(@i_agencia,ca_agencia),
          ca_estado              = isnull(@i_estado,ca_estado),
          ca_problema            = isnull(@i_problema,ca_problema),
          ca_imposibilidad_pago  = isnull(@i_imposibilidad_pago,ca_imposibilidad_pago),
          ca_imposibilidad_pago2 = isnull(@i_imposibilidad_pago2,ca_imposibilidad_pago2),
          ca_imposibilidad_pago3 = isnull(@i_imposibilidad_pago3,ca_imposibilidad_pago3),
          ca_razones             = isnull(@i_razones,ca_razones),
          ca_razones2            = isnull(@i_razones2,ca_razones2),
          ca_razones3            = isnull(@i_razones3,ca_razones3),
          ca_coherencia          = isnull(@i_coherencia,ca_coherencia),
          ca_observacion         = isnull(@i_observacion,ca_observacion),
		  ca_numero_juicio		 = isnull(@i_numero_juicio,ca_numero_juicio),
		  ca_estado_cobranza	 = isnull(@i_estado_cobranza, ca_estado_cobranza)
    where ca_int_proceso          = @i_int_proceso

    if @@rowcount != 1
    begin
        select @w_error = 2101021
        goto ERROR
    end
	if(@w_paramMassive is not null and @w_paramMassive ='S')
	begin
		update cob_credito..cr_tramite
		set tr_txt_razon = isnull(@i_txt_razon,tr_txt_razon)
		where	tr_tramite = @i_tramite
		
		select @w_date_rate = max(cc_fecha_corte) 
		  from cob_cartera..ca_candidata_castigo
		  
		update cob_cartera..ca_candidata_castigo
           set cc_masiva = 'S'
         where cc_fecha_corte = @w_date_rate
           and cc_banco = @i_num_operacion
	end
	
end


---------------------------
-- OPERACION Q
---------------------------
if @i_operacion = 'Q'
begin
    select  @w_fecha_corte          = ca_fecha_corte,
            @w_cliente              = ca_cliente,
            @w_agencia              = ca_agencia,
            @w_estado               = ca_estado,
            @w_problema             = ca_problema,
            @w_imposibilidad_pago   = isnull(ca_imposibilidad_pago,'') + ' ' + isnull(ca_imposibilidad_pago2,'') + ' ' + isnull(ca_imposibilidad_pago3,''),
            @w_razones              = isnull(ca_razones,'') + isnull(ca_razones2,'') + isnull(ca_razones3,'') ,
            @w_coherencia           = ca_coherencia,
            @w_observacion          = ca_observacion,
            @w_regional             = ca_regional,
            @w_subregional          = ca_subregional,
            @w_ambito               = ca_ambito,
            @w_banco                = ca_banco,
            @w_id_tramite           = ca_tramite,
			@w_numero_juicio		= ca_numero_juicio,
			@w_estado_cobranza		= ca_estado_cobranza
    from cob_credito..cr_tr_castigo
    where ca_int_proceso = @i_int_proceso

    if @@rowcount = 0
    begin
       /*Registro no existe */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = 'sp_castigo_operaciones',
       @i_num   = 2101005
       return 1
    end

    /* Datos de cartera */   --JRU se comenta este campo, al conversar con JEscobar, indica que posiblemente se lo usa para informacion de algun reporte, tabla inexistente en CPN
    select  @w_fecha_diaria                 = getdate(),--copr_fecha,
            @w_modulo_cobis                 = 0,--copr_modulo_cobis,
            @w_val_prev_esp_moneda_local    = 0,--copr_val_prev_esp_MLO_con,
            @w_val_prev_esp_moneda_otra     = 0,--copr_val_prev_esp_MOP_con,
            @w_calificacion_categoria       = ''--copr_categoria_riesgo_final
    /*from cob_cartera..rec_proc_calif_ope_result, cob_credito..cr_tr_castigo
    where copr_numero_cuenta = ca_banco
          and ca_int_proceso = @i_int_proceso
          and convert(varchar(10),copr_fecha, 103) = convert(varchar(10),getdate(),103)*/
    /*if @@rowcount = 0
    begin
       Registro no existe
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = 'sp_castigo_operaciones',
       @i_num   = 2101005
       return 1
    end*/

    /*Datos para pantalla*/
    select  @w_fecha_corte,
            @w_cliente,
            @w_agencia,
            @w_estado,
            @w_problema,
            @w_imposibilidad_pago,
            @w_razones,
            @w_coherencia,
            @w_observacion,
            @w_regional,
            @w_subregional,
            @w_ambito,
            @w_banco,
            @w_id_tramite,
            @w_fecha_diaria,
            @w_modulo_cobis,
            isnull(@w_val_prev_esp_moneda_local,0),
            isnull(@w_val_prev_esp_moneda_otra,0),
            @w_calificacion_categoria,
			@w_numero_juicio,
			@w_estado_cobranza


end
---------------------------
-- OPERACION R        
---------------------------
--consulta de la operacion por el numero de banco

if @i_operacion = 'R'
begin
    select  @w_fecha_corte          = ca_fecha_corte,
            @w_cliente              = ca_cliente,
            @w_agencia              = ca_agencia,
            @w_estado               = ca_estado,
            @w_problema             = ca_problema,
            @w_imposibilidad_pago   = isnull(ca_imposibilidad_pago,'') + ' ' + isnull(ca_imposibilidad_pago2,'') + ' ' + isnull(ca_imposibilidad_pago3,''),
            @w_razones              = isnull(ca_razones,'') + isnull(ca_razones2,'') + isnull(ca_razones3,'') ,
            @w_coherencia           = ca_coherencia,
            @w_observacion          = ca_observacion,
            @w_regional             = ca_regional,
            @w_subregional          = ca_subregional,
            @w_ambito               = ca_ambito,
            @w_banco                = ca_banco,
            @w_id_tramite           = ca_tramite,
			@w_numero_juicio		= ca_numero_juicio,
			@w_estado_cobranza		= ca_estado_cobranza
    from cob_credito..cr_tr_castigo
    where ca_banco = @i_num_operacion

    if @@rowcount = 0
    begin
       /*Registro no existe */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = 'sp_castigo_operaciones',
       @i_num   = 2101005
       return 1
    end

    /* Datos de cartera */   

    select  @w_fecha_diaria                 = getdate(),--copr_fecha,
            @w_modulo_cobis                 = 0,--copr_modulo_cobis,
            @w_val_prev_esp_moneda_local    = 0,--copr_val_prev_esp_MLO_con,
            @w_val_prev_esp_moneda_otra     = 0,--copr_val_prev_esp_MOP_con,
            @w_calificacion_categoria       = ''--copr_categoria_riesgo_final

    /*Datos para pantalla*/
    select  @w_fecha_corte,
            @w_cliente,
            @w_agencia,
            @w_estado,
            @w_problema,
            @w_imposibilidad_pago,
            @w_razones,
            @w_coherencia,
            @w_observacion,
            @w_regional,
            @w_subregional,
            @w_ambito,
            @w_banco,
            @w_id_tramite,
            @w_fecha_diaria,
            @w_modulo_cobis,
            isnull(@w_val_prev_esp_moneda_local,0),
            isnull(@w_val_prev_esp_moneda_otra,0),
            @w_calificacion_categoria,
			@w_numero_juicio,
			@w_estado_cobranza
end
 return 0
ERROR:
   --Devolver mensaje de Error
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
        return @w_error
go
