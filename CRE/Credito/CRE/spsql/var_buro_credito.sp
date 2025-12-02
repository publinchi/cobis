/************************************************************************/
/*  Archivo:                var_buro_credito.sp                         */
/*  Stored procedure:       sp_var_buro_credito                         */
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

if exists (select 1 from sysobjects where name = 'sp_var_buro_credito' and type = 'P')
   drop proc sp_var_buro_credito
go


create proc sp_var_buro_credito(
    @t_debug            char(1)     = 'N',
    @t_from             varchar(30) = null,
    @s_ssn              int         = null,
    @s_user             varchar(30) = null,
    @s_sesn             int         = null,
    @s_term             varchar(30) = null,
    @s_date             datetime    = null,
    @s_srv              varchar(30) = null,
    @s_lsrv             varchar(30) = null,
    @s_ofi              smallint    = null,
    @t_file             varchar(14) = null,
    @s_rol              smallint    = null,
    @s_org_err          char(1)     = null,
    @s_error            int         = null,
    @s_sev              tinyint     = null,
    @s_msg              descripcion = null,
    @s_org              char(1)     = null,
    @s_culture          varchar(10) = 'NEUTRAL',
    @t_rty              char(1)     = null,
    @t_trn              int = null,
    @t_show_version     BIT = 0,
    @i_id_inst_proc     int,    --codigo de instancia del proceso
    @i_id_inst_act      int,    
    @i_id_asig_act      int,
    @i_id_empresa       int, 
    @i_id_variable      smallint
)
as
declare @w_sp_name                          varchar(64),
        @w_error                            int,
        @w_grupo                            int,
        @w_tramite                          int,
        @w_num_miembros                     int,
        @w_resultado                        varchar(10),
        @w_asig_actividad                   int,        
        @w_valor_ant                        varchar(255),
        @w_valor_nuevo                      varchar(255),
        @w_return                           int
        
select @w_sp_name = 'sp_var_buro_credito',
@w_resultado = 'BUENO'

select @w_grupo         = io_campo_1,
       @w_tramite       = io_campo_3
  from cob_workflow..wf_inst_proceso
 where io_id_inst_proc  = @i_id_inst_proc
   and io_campo_7       = 'S' -- Cambiar a Grupo Solidario 'S'
 

select @w_num_miembros  = count(cg_ente) 
from cobis..cl_cliente_grupo
where cg_grupo = @w_grupo
 
 
if @w_num_miembros > 2 begin
  
   EXEC @w_return = cob_credito..sp_var_buro_credito_int
   @i_grupo       = @w_grupo,
   @i_tramite     = @w_tramite,
   @o_resultado   = @w_valor_nuevo OUTPUT

   if @w_return  <> 0
   begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file = @t_file, 
      @t_from = @t_from,
      @i_num = 2101002
      return 1
   end
   
   
   select @w_resultado = @w_valor_nuevo
   
END

print 'INSTANCIA:' + convert(VARCHAR,@i_id_inst_proc) +' - GRUPO -' + convert(varchar,@w_grupo) +  ' CALIFICACION BURO -->' + @w_valor_nuevo 

if @t_debug = 'S'
begin
	print '@w_resultado: ' + convert(varchar, @w_resultado )
end


-- valor anterior de variable tipop en la tabla cob_workflow..wf_variable
select @w_valor_ant    = isnull(va_valor_actual, '')
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @i_id_variable

if @@rowcount > 0  
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
