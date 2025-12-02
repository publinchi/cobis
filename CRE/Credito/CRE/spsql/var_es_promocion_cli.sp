/************************************************************************/
/*  Archivo:                var_es_promocion_cli.sp                     */
/*  Stored procedure:       sp_var_es_promocion_cli                     */
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

if exists (select 1 from sysobjects where name = 'sp_var_es_promocion_cli' and type = 'P')
   drop proc sp_var_es_promocion_cli
go


create proc sp_var_es_promocion_cli(
	@t_debug       		char(1)     = 'N',
	@t_from        		varchar(30) = null,
	@s_ssn              int,
	@s_user             varchar(30),
	@s_sesn             int,
	@s_term             varchar(30),
	@s_date             datetime,
	@s_srv              varchar(30),
	@s_lsrv             varchar(30),
	@s_ofi              smallint,
	@t_file             varchar(14) = null,
	@s_rol              smallint    = null,
	@s_org_err          char(1)     = null,
	@s_error            int         = null,
	@s_sev              tinyint     = null,
	@s_msg              descripcion = null,
	@s_org              char(1)     = null,
	@s_culture         	varchar(10) = 'NEUTRAL',
	@t_rty              char(1)     = null,
	@t_trn				int = null,
	@t_show_version     BIT = 0,
    @i_id_inst_proc    	int,    --codigo de instancia del proceso
    @i_id_inst_act     	int,    
    @i_id_asig_act     	int,
    @i_id_empresa      	int, 
    @i_id_variable     	smallint
)
as
declare	@w_sp_name 							varchar(64),
		@w_error							int,
		@w_grupo							int,
		@w_tramite							int,
		@w_es_promocion		                char(1),
		@w_asig_actividad 					int,		
		@w_valor_ant      					varchar(255),
		@w_valor_nuevo    					varchar(255),
		@w_tr_promocion_grupo               char(1),
		@w_id_variable			            INT,
		@w_valor_actual			            varchar(10),
		@w_cliente				            INT,
		@w_id_variable_promo                INT,
		@w_valor_actual_promo               varchar(10)
		
select @w_sp_name = 'sp_var_es_promocion_cli'

select @w_id_variable_promo = vb_codigo_variable
  from cob_workflow..wf_variable
 where vb_abrev_variable 	= 'CLINROCLIN'
 
 select @w_valor_actual_promo    = va_valor_actual
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @w_id_variable_promo
   
     
select @w_grupo 		= io_campo_1,
	   @w_tramite 		= io_campo_3
  from cob_workflow..wf_inst_proceso
 where io_id_inst_proc 	= @i_id_inst_proc
   and io_campo_7 		= 'S' -- Cambiar a Grupo Solidario 'S'
   
   select @w_cliente = convert(int,@w_valor_actual_promo)
   
   PRINT'Numero de cliente en Es Promcion CLI'+ convert (VARCHAR(50),@w_cliente)
   
   SELECT @w_tr_promocion_grupo=tr_promocion FROM cob_credito..cr_tramite WHERE tr_tramite=@w_tramite
   
   select @w_tr_promocion_grupo = isnull(@w_tr_promocion_grupo,'N')
   
PRINT'@w_tr_promocion_grupo en Es Promocion CLI...'+ convert(VARCHAR(50),@w_tr_promocion_grupo)
   
   IF (@w_tr_promocion_grupo = 'S')
         BEGIN
          IF EXISTS(SELECT 1 FROM cob_credito..cr_grupo_promo_inicio WHERE gpi_tramite=@w_tramite 
                    AND gpi_grupo=@w_grupo AND gpi_ente=@w_cliente)
           BEGIN
            SELECT @w_es_promocion='S' 
           END
          ELSE
           BEGIN
             SELECT @w_es_promocion='N' 
           END

       END
       ELSE
        BEGIN
         SELECT @w_es_promocion='N' 
        END
        
  PRINT 'Promocion del cliente en  sp_var_es_promocion CLI --->'+ convert(varchar(50),@w_es_promocion)
   
/*select @w_es_promocion = isnull(tr_promocion, 'N')
  from cob_credito..cr_tramite
 where tr_tramite = @w_tramite
 */
select @w_valor_nuevo = @w_es_promocion

if @t_debug = 'S'
begin
	print '@w_valor_nuevo: ' + convert(varchar, @w_valor_nuevo )	
end

-- valor anterior de variable tipop en la tabla cob_workflow..wf_variable
select @w_valor_ant    = isnull(va_valor_actual, '')
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @i_id_variable

if @@rowcount > 0  --ya existe
begin
	update cob_workflow..wf_variable_actual
	   set va_valor_actual = @w_valor_nuevo 
	 where va_id_inst_proc = @i_id_inst_proc
	   and va_codigo_var   = @i_id_variable
	
end
else
begin
	insert into cob_workflow..wf_variable_actual
			(va_id_inst_proc, va_codigo_var, va_valor_actual)
	values (@i_id_inst_proc, @i_id_variable, @w_valor_nuevo )

end


return 0




GO
