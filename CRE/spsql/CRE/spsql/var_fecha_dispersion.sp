/************************************************************************/
/*  Archivo:                var_fecha_dispersion.sp                     */
/*  Stored procedure:       sp_var_fecha_dispersion                     */
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

if exists (select 1 from sysobjects where name = 'sp_var_fecha_dispersion' and type = 'P')
   drop proc sp_var_fecha_dispersion
go

CREATE PROC sp_var_fecha_dispersion
		(@s_ssn        int         = null,
	     @s_ofi        smallint    = null,
	     @s_user       login       = null,
         @s_date       datetime    = null,
	     @s_srv		   varchar(30) = null,
	     @s_term	   descripcion = null,
	     @s_rol		   smallint    = null,
	     @s_lsrv	   varchar(30) = null,
	     @s_sesn	   int 	       = null,
	     @s_org		   char(1)     = NULL,
		燖s_org_err牋牋int 	       = null,
牋牋牋牋燖s_error牋牋牋int 	       = null,
牋牋牋牋燖s_sev        tinyint     = null,
         @s_msg        descripcion = null,
牋牋牋牋 @t_rty        char(1)     = null,
牋牋牋牋燖t_trn        int         = null,
牋牋牋牋燖t_debug      char(1)     = 'N',
牋牋牋牋燖t_file       varchar(14) = null,
牋牋牋牋燖t_from       varchar(30)  = null,
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
        @w_return        	int,
        ---var variables	
        @w_asig_actividad 	int,
        @w_valor_ant      	varchar(255),
        @w_valor_nuevo    	varchar(255),
        @w_actividad      	catalogo,
        @w_grupo			int,
        @w_ente             int,
        @w_fecha			datetime,
        @w_fecha_dif		datetime,
        @w_numero           int,
        @w_proceso			varchar(5),
        @w_usuario			varchar(64),
        @w_comentario		varchar(255),
        @w_fecha_disp       datetime,
        @w_fecha_proceso    datetime,
        @w_dias_dif         int,
        @w_id_inst_act		int
       	

select @w_sp_name='sp_var_fecha_dispersion'

select @w_tramite  = convert(int,io_campo_3)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

/* PARAMETROS */
select @w_proceso = pa_int from cobis..cl_parametro where pa_nemonico = 'OAA'

select @w_tramite = isnull(@w_tramite,0)
if @w_tramite = 0 return 0


select @w_comentario = 'La fecha de dispersi贸n para esta solicitud es el: ' 

/* OBTENER FECHAS */
select @w_fecha_disp = tr_fecha_dispersion 
from cob_credito..cr_tramite
where tr_tramite = @w_tramite

select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso


--si fecha dispersi贸n es menor o igual a fecha de proceso si debe dejar pasar
select @w_dias_dif = datediff(dd, @w_fecha_disp, @w_fecha_proceso)

print 'Dias: ' + isnull(convert(varchar,@w_dias_dif),'Alguna Fecha es nula')

if ((@w_dias_dif >= 0) or (@w_fecha_disp is null))
begin
    select @w_valor_nuevo = 'SI'
end
else
begin
	select @w_valor_nuevo = 'NO'
    
    delete cob_workflow..wf_observaciones 
    where ob_id_asig_act = @i_id_asig_act
    and ob_numero in (select ol_observacion from  cob_workflow..wf_ob_lineas 
    where ol_id_asig_act = @i_id_asig_act 
    and ol_texto like 'La fecha de dispersi贸n para esta solicitud es el:%')
    
    delete cob_workflow..wf_ob_lineas 
    where ol_id_asig_act = @i_id_asig_act 
    and ol_texto like 'La fecha de dispersi贸n para esta solicitud es el:%'
    
    select @w_comentario = @w_comentario + convert(varchar, isnull(@w_fecha_disp,''))
    
    select top 1 @w_numero = ob_numero from cob_workflow..wf_observaciones 
    where ob_id_asig_act = @i_id_asig_act
    order by ob_numero desc
    
    if (@w_numero is not null)
    begin
    	select @w_numero = @w_numero + 1 --aumento en uno el maximo
    end
    else
    begin
    	select @w_numero = 1
    end
    
    select @w_usuario = fu_nombre from cobis..cl_funcionario where fu_login = @s_user
    
    insert into cob_workflow..wf_observaciones (ob_id_asig_act, ob_numero, ob_fecha, ob_categoria, ob_lineas, ob_oficial, ob_ejecutivo)
    values (@i_id_asig_act, @w_numero, getdate(), @w_proceso, 1, 'a', @w_usuario)
    
    insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
    values (@i_id_asig_act, @w_numero, 1, @w_comentario)
	
end


--insercion en estrucuturas de variables

select @w_asig_actividad = max(aa_id_asig_act)
from cob_workflow..wf_asig_actividad
where aa_id_inst_act   in (select max(ia_id_inst_act) from cob_workflow..wf_inst_actividad
                           where ia_id_inst_proc = @i_id_inst_proc)

if @w_asig_actividad is null
  select @w_asig_actividad = 0

-- valor anterior de variable tipo en la tabla cob_workflow..wf_variable
select @w_valor_ant    = isnull(va_valor_actual, '')
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @i_id_variable

if @@rowcount > 0  --ya existe
begin
  --print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
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
--print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
if not exists(select 1 from cob_workflow..wf_mod_variable
              where mv_id_inst_proc = @i_id_inst_proc AND
                    mv_codigo_var= @i_id_variable AND
                    mv_id_asig_act = @w_asig_actividad)
BEGIN
    insert into cob_workflow..wf_mod_variable
           (mv_id_inst_proc, mv_codigo_var, mv_id_asig_act,
            mv_valor_anterior, mv_valor_nuevo, mv_fecha_mod)
    values (@i_id_inst_proc, @i_id_variable, @w_asig_actividad,
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
GO
