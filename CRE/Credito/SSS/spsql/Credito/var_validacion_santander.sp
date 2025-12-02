/************************************************************************/
/*  Archivo:                var_validacion_santander.sp                 */
/*  Stored procedure:       sp_var_validacion_santander                 */
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

if exists (select 1 from sysobjects where name = 'sp_var_validacion_santander' and type = 'P')
   drop proc sp_var_validacion_santander
go



CREATE PROC sp_var_validacion_santander
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
		 @s_org_err    int 	       = null,
         @s_error      int 	       = null,
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
        ---var variables	
        @w_asig_actividad 	int,
        @w_valor_ant      	varchar(255),
        @w_valor_nuevo    	varchar(255),
        @w_actividad      	catalogo,
        @w_grupo			int,
        @w_ente             int,
        @w_fecha			datetime,
        @w_fecha_dif		DATETIME,
        @w_ttramite         varchar(255),
        @w_promocion        char(1),
        @w_asig_act         int,
        @w_numero           int,
        @w_proceso			varchar(5),
        @w_usuario			varchar(64),
        @w_comentario		varchar(1000),
        @w_nombre           varchar(64),
        @w_exp_credit       varchar(1),
        @w_emprendedor      varchar(1),
        @w_nombre_ente      varchar(500),
        @w_ea_cta_banco     varchar(45),
   		@w_ea_estado_std    varchar(10),
   		@w_en_banco         varchar(20),
   		@w_condicionado     char(1),
        @w_id_observacion   smallint
       

select @w_sp_name='sp_var_validacion_santander'

select @w_grupo    = convert(int,io_campo_1),
	   @w_tramite  = convert(int,io_campo_3),
	   @w_ttramite = io_campo_4,
       @w_asig_act   = convert(int,io_campo_2)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc


select @w_tramite = isnull(@w_tramite,0)
if @w_tramite = 0 return 0

select @w_condicionado = 'N'
select @w_nombre_ente = '' 

if @w_ttramite = 'GRUPAL'
begin
	
	select @w_ente = 0
	while 1 = 1
	begin
	   
		select top 1 @w_ente         = cg_ente,
					@w_nombre        = (isnull(en_nombre,'') + ' ' + isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'')),
					@w_en_banco 	 = en_banco,
					@w_ea_cta_banco  = ea_cta_banco,
					@w_ea_estado_std = ea_estado_std
		from cobis..cl_cliente_grupo, cob_credito..cr_tramite_grupal,
			cobis..cl_ente_aux, cobis..cl_ente
		where cg_grupo = @w_grupo
		and tg_tramite = @w_tramite
		and cg_grupo = tg_grupo
		and tg_cliente = cg_ente
		and en_ente = cg_ente
		and ea_ente = en_ente
		and tg_participa_ciclo = 'S'
		and cg_estado = 'V'
		and cg_ente > @w_ente
		order by cg_ente asc
		
		IF @@ROWCOUNT = 0
		  BREAK
	   
		if((@w_ea_cta_banco IS NULL) and (@w_ea_estado_std IS NULL) and (@w_en_banco IS NULL))
		begin
			select @w_nombre_ente = @w_nombre_ente + @w_nombre + ', '
			select @w_condicionado = 'S'
		end
	    select @w_nombre = null
	    select @w_ea_cta_banco = null
	    select @w_ea_estado_std = null
	    select @w_en_banco = null
	end
	
	if(@w_condicionado = 'S')
	begin
		select @w_comentario = @w_nombre_ente + 'no tienen cuenta de ahorro en Banco Santander.'
		
		select @w_id_observacion = ol_observacion from  cob_workflow..wf_ob_lineas 
		where ol_id_asig_act = @w_asig_act 
		and ol_texto like '%no tienen cuenta de ahorro en Banco Santander.'
		
		delete cob_workflow..wf_observaciones 
		where ob_id_asig_act = @w_asig_act
		and ob_numero = @w_id_observacion
		
		delete cob_workflow..wf_ob_lineas 
		where ol_id_asig_act = @w_asig_act 
		and ol_observacion = @w_id_observacion
		
		
		select top 1 @w_numero = ob_numero from cob_workflow..wf_observaciones 
		where ob_id_asig_act = @w_asig_act
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
		values (@w_asig_act, @w_numero, getdate(), @w_proceso, 1, @s_user, @w_usuario)
		
		insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
		values (@w_asig_act, @w_numero, 1, @w_comentario)
		
		select @w_valor_nuevo = 'NO'
	end
	else
	begin
		select @w_valor_nuevo = 'SI'
	end
	
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
