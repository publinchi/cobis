/************************************************************************/
/*  Archivo:                var_verifica_dom_dir.sp                     */
/*  Stored procedure:       sp_var_verifica_dom_dir                     */
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

if exists (select 1 from sysobjects where name = 'sp_var_verifica_dom_dir' and type = 'P')
   drop proc sp_var_verifica_dom_dir
go



CREATE PROC sp_var_verifica_dom_dir
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
        @w_fecha_proceso    DATETIME,
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
        @w_resultado        int
       

SELECT @w_sp_name='sp_var_verifica_dom_dir'

SELECT @w_grupo    = convert(int,io_campo_1),
	   @w_tramite  = convert(int,io_campo_3),
	   @w_ttramite = io_campo_4
FROM cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

select @w_tramite = isnull(@w_tramite,0)

if @w_tramite = 0 return 0
    
SELECT @w_fecha_proceso = fp_fecha FROM cobis..ba_fecha_proceso

if @w_ttramite = 'GRUPAL'
begin
  
  	SELECT @w_ente = 0
	WHILE 1 = 1
	BEGIN
	   
	   SELECT TOP 1 @w_ente = cg_ente 
	   FROM cobis..cl_cliente_grupo, 
	        cob_credito..cr_tramite_grupal
	   WHERE cg_grupo = @w_grupo
	   AND cg_grupo = tg_grupo
	   AND cg_ente = tg_cliente
	   AND cg_ente > @w_ente
	   AND cg_estado <> 'C'
	   AND tg_participa_ciclo = 'S'
	   ORDER BY cg_ente
	   
	   
	   IF @@ROWCOUNT = 0
	      BREAK
	   
	   SELECT @w_fecha     = vd_fecha,
	          @w_resultado = vd_resultado
	   FROM cr_verifica_datos 
	   WHERE vd_cliente = @w_ente
	   GROUP BY vd_fecha, vd_resultado
	   
	   IF (@w_fecha IS NULL or @@ROWCOUNT = 0)
	   begin
	      select @w_valor_nuevo  = 'NO'
	      BREAK
	   end	   
	   else
	   begin
	       SELECT @w_fecha_dif = DATEDIFF(month,@w_fecha,@w_fecha_proceso)
	       
	       select @w_fecha_dif = isnull(@w_fecha_dif,0)
	       
	       IF @w_fecha_dif >= (SELECT pa_tinyint FROM cobis..cl_parametro WHERE pa_nemonico = 'MESVCC')
	       begin
	          select @w_valor_nuevo  = 'NO'
	          BREAK
	       end
	       ELSE
	       begin
	          select @w_valor_nuevo  = 'SI'
		      select @w_fecha = null
		      select @w_fecha_dif = null
	       end	   
	   	   
	   	   IF @w_resultado < (SELECT pa_tinyint FROM cobis..cl_parametro WHERE pa_producto = 'CRE' AND pa_nemonico = 'RVDGR')
	       begin
	          select @w_valor_nuevo  = 'NO'
	          BREAK
	       end
	   	   
	   end	   
	END
end
else
begin
	
	SELECT @w_ente = @w_grupo
	
	SELECT @w_fecha		= vd_fecha,
	       @w_resultado = vd_resultado
	FROM cr_verifica_datos 
	WHERE vd_cliente = @w_ente
	GROUP BY vd_fecha, vd_resultado
	
    IF (@w_fecha IS NULL or @@ROWCOUNT = 0)
	begin
	  select @w_valor_nuevo  = 'NO'
	end
	else
	begin
	    SELECT @w_fecha_dif = DATEDIFF(month,@w_fecha,@w_fecha_proceso)
	    
	    select @w_fecha_dif = isnull(@w_fecha_dif,0)
	    
	    IF @w_fecha_dif >= (SELECT pa_tinyint FROM cobis..cl_parametro WHERE pa_nemonico = 'MESVCC')
	    begin
	      select @w_valor_nuevo  = 'NO'
	    end
	    ELSE
	    begin
	      select @w_valor_nuevo  = 'SI'
	      select @w_fecha = null
	      select @w_fecha_dif = null
	    end
		
	end
end



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

GO
