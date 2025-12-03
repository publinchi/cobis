/************************************************************************/
/*  Archivo:                pag_telecom.sp                              */
/*  Stored procedure:       sp_pag_telecom                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_pag_telecom')
    drop proc sp_pag_telecom
go

create proc sp_pag_telecom(
      @s_user login = NULL
    , @s_sesn int = NULL
    , @s_term varchar(30) = NULL
    , @s_date datetime = NULL
    , @s_lsrv varchar(30) = NULL
    , @s_org char(1) = NULL
    , @s_culture varchar(30) = NULL
    , @s_srv               varchar(30) = NULL
    , @s_rol               smallint      = null
    , @s_ofi               smallint = NULL
    , @s_ssn               int = NULL
    , @t_trn               smallint =NULL
    , @t_debug             char(1) 	   = 'N'
    , @t_file              varchar(14)   = null
	, @t_from              varchar(32)   = null
	, @t_show_version      bit           = 0
    , @i_operacion 		   char(1)
    , @i_element_id 	   smallint
	, @i_reference 		   varchar(22)
	, @i_payment_date	   date
	, @i_branch_id  	   int
	, @i_authorization_num int
	, @i_payment_amount	   decimal
	, @i_column1		   int
	, @i_column2		   int
	, @i_payment_amount2   decimal
	, @i_payment_hour      char(4)
	) as

begin

	declare
		@w_sp_name varchar(20)
		, @w_codigoError int
		,@w_reference varchar(30)
        ,@w_moneda tinyint
        ,@w_cta_banco char(16)
        ,@w_causa char(10)
        ,@w_fecha smalldatetime

	select @w_codigoError = 1

	select @w_sp_name = 'sp_pag_telecom'


	--Se verifica si el registro ya existe
/*
	if exists(select top 1 * from cob_credito..cr_pagos_telecom
				where pt_reference = @i_reference
				and pt_payment_date=@i_payment_date
				and pt_authorization_num=@i_authorization_num
				and pt_payment_hour=@i_payment_hour)
	begin*/

--		select @w_codigoError = 101186   /*Error de que el registro ya existe*/
--		goto Error
--	end

    if @i_operacion = 'I' and @i_payment_amount > 0
	    begin
		    declare @w_id_movmiento int

		    exec cobis..sp_cseqnos

		       @i_tabla = 'cr_pagos_telecom',

		       @o_siguiente = @w_id_movmiento out



		insert into cr_pagos_telecom ( pt_id , pt_element_num	, pt_reference	, pt_payment_date	, pt_branch_id

									  ,pt_authorization_num     ,pt_payment_amount ,pt_column1   ,pt_column2 ,pt_payment_amount2

									  ,pt_payment_hour )

							 values ( @w_id_movmiento	, @i_element_id ,@i_reference, @i_payment_date, @i_branch_id
									  ,@i_authorization_num,@i_payment_amount,@i_column1,@i_column2,@i_payment_amount2
									  ,@i_payment_hour)

		   	if @@error != 0
				begin
				select @w_codigoError = 101186   /*  Error en el registro */
				goto Error
			end


         /*  select @w_reference=substring(@i_reference,6,len(@i_reference)-6 )
           select @w_moneda= ah_moneda, @w_cta_banco=ah_cta_banco
                  from cob_ahorros..ah_cuenta
                  where ah_cta_banco=(select  op_cuenta from cob_cartera..ca_operacion
                        where op_banco=  @w_reference) */-- '3F4830003900' -- numero de credito sin ceros a la izquierda)

            -- harcode quitaer estas lineas de codigo
         select  @w_cta_banco=null
         select  @w_moneda=0

          -- Validar que codigo usar
         /* select top 1  @w_causa=codigo
            from cobis..cl_catalogo
            where valor='ah_causa_nd'*/


          begin tran
          /* Generar la nota de debito por envio de estado de cuenta */
          exec @w_codigoError   = cob_interface..sp_ahndc_automatica
           @s_ssn          = @s_ssn,
           @s_srv          = @s_srv,
           @s_ofi          = @s_ofi,
           @s_user         = @s_user,
           @t_trn          = 253,
           @i_cta          = @w_cta_banco,       --  Parámetro en nulo porque va la referecia
           @i_val          = @i_payment_amount,
           @i_cau          = '21',           --@w_causa,
           @i_mon          = @w_moneda,
           @i_fecha        = @s_date,
           --@t_ssn_corr     = @w_ssn_corr,      --secuencial (@s_ssn) de la transacci=n a reversar.
           @t_corr         = 'N' ,     --@w_corr,          --S/N dependiendo si es una reversa o no.
           --@i_alt          = @i_alt,
           @i_inmovi       = 'S',
           @i_activar_cta  = 'N',
           @i_is_batch     = 'N' ,       --@w_is_batch,
           @i_referencia = @i_reference,
           @i_fecha_corresponsal  = @i_payment_date,
           @i_id_trn_corresponsal = @i_authorization_num,
           @i_corresponsal     = 'S'

            if @w_codigoError > 0
                begin
                       --  select @w_codigoError = @w_codigoError   /* validar numero de error */
                        goto Error
                end
	       commit tran
    end --Fin opcion I

	return 0
Error:
	exec cobis..sp_cerror
		 @t_debug = @t_debug
		, @t_file = @t_file
		, @t_from = @w_sp_name
		, @i_num = @w_codigoError

    return @w_codigoError

end

SET NOCOUNT OFF
go
