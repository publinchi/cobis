USE cob_interface
GO
/************************************************************/
/*   ARCHIVO:         sp_asociar_garantias_int.sp           */
/*   NOMBRE LOGICO:   sp_asociar_garantias_int              */
/*   PRODUCTO:        COBIS                                 */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Exponer el servicio para asociar las garantias         */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 15/SEP/2021     EBA                 Emision Inicial      */
/************************************************************/

if exists (select 1 from sysobjects where name = 'sp_asociar_garantias_int')
   drop proc sp_asociar_garantias_int
go

CREATE PROCEDURE sp_asociar_garantias_int (
        @s_ssn                  int          = null,
        @s_date                 datetime     = null,
        @s_user                 login        = null,
        @s_term                 varchar(64)  = null,
        @s_ofi                  smallint     = null,
        @s_srv                  varchar(30)  = null,
        @s_rol                  smallint     = null,
        @s_sesn                 int          = null,
        @s_org                  char(1)      = null,
        @s_culture              varchar(10)  = null,
		@s_lsrv                 varchar(30)  = null,
        @t_trn                  smallint     = null,
        @t_debug                char(1)      = 'N',
        @t_file                 varchar(14)  = null,
        @t_from                 varchar(30)  = null,
		@i_operacion            char(1)      = null,
		@i_deudor               int          = null,
        @i_clase                char(1)      = null,
		@i_estado               varchar(10)  = null,
		@i_tramite              int          = NULL,
		@i_garantia             varchar(64)  = null

)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
		@w_return               int,
		@w_codigo_externo       varchar(64)
        


select @w_sp_name = 'sp_asociar_garantias_int',
       @w_error           = 0,
       @w_return          = 0

	if @i_operacion = 'I'
	begin
		
		if not exists (select 1 from cob_credito..cr_tramite
                       where tr_tramite = @i_tramite
                       and tr_estado = 'N')
		begin
			select @w_error = 2110180
		    goto ERROR
		end
		
	    if not exists (select 1 from cob_custodia..cu_custodia
                       where cu_codigo_externo = @i_garantia
					   and cu_estado <> 'C'
                       and cu_abierta_cerrada = 'A')
		begin
			select @w_error = 2110181
		    goto ERROR
		end

		if @i_tramite is not null AND (@i_garantia <> '')
		begin
		exec @w_error = cob_credito..sp_gar_propuesta
		     @s_srv                 = @s_srv,
             @s_user                = @s_user,
             @s_term                = @s_term,
             @s_ofi                 = @s_ofi,
             @s_rol                 = @s_rol,
             @s_ssn                 = @s_ssn,
             @s_lsrv                = @s_lsrv,
             @s_date                = @s_date,
             @s_sesn                = @s_sesn,
             @t_trn                 = 21028,
             @i_operacion           = 'I',
             @i_tramite             = @i_tramite,
             @i_garantia            = @i_garantia,
             @i_estado              = @i_estado,
             @i_clase               = @i_clase,
		     @i_deudor              = @i_deudor
			 
	        if @w_error != 0
            begin
               goto ERROR
            end
		end
	         
	end

return 0

ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return 1
GO

