/************************************************************************/
/*  Archivo:                var_integrantes_original.sp                  */
/*  Stored procedure:       sp_var_integrantes_original                  */
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

if exists (select 1 from sysobjects where name = 'sp_var_integrantes_original' and type = 'P')
   drop proc sp_var_integrantes_original
go


CREATE PROC sp_var_integrantes_original
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
		 @s_org_err    int 	       = null,
         @s_error      int 	       = null,
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
as
declare @w_sp_name       	varchar(32),
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
        @w_ttramite         varchar(255),
        @w_promocion        char(1),
        @w_min_original     int,
        @w_asig_act         int,
        @w_numero           int,
        @w_proceso			varchar(5),
        @w_usuario			varchar(64),
        @w_comentario		varchar(255),
        @w_nombre           varchar(64) ,
        @w_num_valida_monto int,
        @w_porcentaje_min   float,
        @w_porcentaje_ente  float,
        @w_fecha_proceso    datetime,
        @w_registros        int  
        
select @w_sp_name='sp_var_integrantes_original'

select @w_grupo    = convert(int,io_campo_1),
	   @w_tramite  = convert(int,io_campo_3),
	   @w_ttramite = io_campo_4,
       @w_asig_act   = convert(int,io_campo_2)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_valor_nuevo = '0'


select @w_porcentaje_min = pa_tinyint/100.00
from cobis..cl_parametro 
WHERE pa_nemonico in ('POPAGP')

/* PARAMETROS */
select @w_min_original = (select pa_tinyint from cobis..cl_parametro where pa_nemonico = 'MINEO' and pa_producto = 'CRE')
select @w_proceso = pa_int from cobis..cl_parametro where pa_nemonico = 'OAA'

select @w_tramite = isnull(@w_tramite,0)

if @w_tramite = 0 return 0

declare @clientes as table 
(
	idCliente		    int, 
	nombreOtorgante		varchar(16), 
	tipoCuena			varchar(1), 
	tipoResp        	varchar(1), 
	tipoContrato		varchar(2), 
	fchAperturaCta	    varchar(8), 
	fchCierrecta		varchar(8), 
    frecuenciaPago		varchar(1), 
	formaPagoActual		varchar(2), 
	histMorosidadGr		varchar(2), 
	creditoMax		    varchar(9), 
	saldoActual		    varchar(9),
	porcentajePago      money 
)

declare @original as table 
(
	idCliente		    int, 
	nombreOtorgante		varchar(16), 
	tipoCuena			varchar(1), 
	tipoResp        	varchar(1), 
	tipoContrato		varchar(2), 
	fchAperturaCta	    varchar(8), 
	fchCierrecta		varchar(8), 
    frecuenciaPago		varchar(1), 
	formaPagoActual		varchar(2), 
	histMorosidadGr		varchar(2)
)

/* Determinar si en grupo es promocion */
select @w_promocion = tr_promocion from cob_credito..cr_tramite where tr_tramite = @w_tramite
select @w_promocion = isnull(@w_promocion,'N')

print 'Inicia Proceso Promo'

select @w_comentario = 'ERROR GRUPO ORIGEN: Grupo PROMO no cumple integrantes mÃ­nimos del grupo origen. Los clientes que cumplen son: '

if (@w_promocion = 'S')
begin 
    if @w_ttramite = 'GRUPAL'
    begin
      	select @w_ente = 0
    	while 1 = 1
    	begin
    	   
    	   if exists(select 1 
    	             from cob_credito..cr_tramite_grupal 
    	             where tg_tramite         = @w_tramite
    	             and   tg_grupo           = @w_grupo
    	             and   tg_participa_ciclo = 'S')
    	   begin
    	         
    	         print 'Entra Proceso cr_tramite_grupal participa S'
    	         
    	         select top 1 @w_ente = cg_ente 
    	         from cobis..cl_cliente_grupo, cob_credito..cr_tramite_grupal 
    	         where cg_grupo = @w_grupo
    	         and tg_tramite = @w_tramite
    	         and cg_grupo = tg_grupo
    	         and tg_cliente = cg_ente
    	         and tg_participa_ciclo = 'S'
    	         and cg_estado = 'V'
    	         and cg_ente > @w_ente
    	         order by cg_ente asc
    	         
    	         IF @@ROWCOUNT = 0
                    BREAK
    	   end
    	   else
    	   begin
    	        
    	        print 'Entra Proceso cr_tramite_grupal participa N'
    	        
    	        select top 1 @w_ente = cg_ente 
    	         from cobis..cl_cliente_grupo, cob_credito..cr_tramite_grupal 
    	         where cg_grupo = @w_grupo
    	         and tg_tramite = @w_tramite
    	         and cg_grupo = tg_grupo
    	         and tg_cliente = cg_ente
    	         and cg_estado = 'V'
    	         and cg_ente > @w_ente
    	         order by cg_ente asc
    	        
    	        IF @@ROWCOUNT = 0
                    BREAK  
    	   end
    	 
    	   
    	   insert into @clientes
    	   select   bc_id_cliente,
                    isnull(bc_nombre_otorgante, '|'),
                    isnull(bc_tipo_cuenta, '|'),
                    isnull(bc_indicador_tipo_responsabilidad, '|'),
                    isnull(bc_tipo_contrato, '|'),
                    isnull(bc_fecha_apertura_cuenta, '|'),
                    isnull(bc_fecha_cierre_cuenta, '|'),
                    isnull(bc_frecuencia_pagos, '|'),
                    isnull(bc_forma_pago_actual, '|'),
                    isnull(bc_mop_historico_morosidad_mas_grave, '|'),
                    isnull(bc_credito_maximo, '|'),
                    isnull(bc_saldo_actual, '|'),
                    case when convert(money,replace(replace(bc_credito_maximo,'+',''),'-','')) != 0 then
                         convert(money,replace(replace(bc_saldo_actual,'+',''),'-',''))  / convert(money,replace(replace(bc_credito_maximo,'+',''),'-',''))
                    else
                         0
                    end
    	   from cob_credito..cr_buro_cuenta 
    	   where bc_id_cliente  = @w_ente 
    	   and   bc_tipo_cuenta = 'I'                           -- I  -> Pagos Fijos
    	   and   bc_indicador_tipo_responsabilidad in ('I', 'J')-- I  -> individual y los J-> mancomunado
    	   and   bc_tipo_contrato in ('CS', 'PL')               -- CS -> Credito Simple y PL ->Prestamo Personal
    	   and   bc_frecuencia_pagos in ('W', 'K')              -- W  -> Semanal o K -> Catorcenal
    	   and   bc_forma_pago_actual = '01'                    -- MOP1
    	   and   (bc_mop_historico_morosidad_mas_grave is null or bc_mop_historico_morosidad_mas_grave = '01')
    	   and   (bc_fecha_cierre_cuenta is null or  datediff(mm,(convert(datetime,SUBSTRING(bc_fecha_cierre_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_cierre_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_cierre_cuenta,5,4),103)),@w_fecha_proceso) <=6)            
    	   and   convert(money,replace(replace(bc_credito_maximo,'+',''),'-','')) >0
    	   and   convert(money,replace(replace(bc_saldo_actual,'+',''),'-',''))/convert(money,replace(replace(bc_credito_maximo,'+',''),'-',''))<= @w_porcentaje_min
    	    
    	end
    end
    
    if exists(select 1 from @clientes)
    begin
        print 'Evaluacion Promo'
        select @w_valor_nuevo = (select top 1 count(nombreOtorgante) as cont
        from @clientes
        group by nombreOtorgante, 	tipoCuena,	tipoResp,	tipoContrato,
        fchAperturaCta,	fchCierrecta,    frecuenciaPago,	formaPagoActual,
    	histMorosidadGr
        having count(nombreOtorgante) > 1
        order by cont desc)
        
        insert into @original
        select top 1 count(nombreOtorgante) as cont,
        nombreOtorgante, 	tipoCuena,	tipoResp,	tipoContrato,
        fchAperturaCta,	fchCierrecta,    frecuenciaPago,	formaPagoActual,
    	histMorosidadGr
        from @clientes
        group by nombreOtorgante, 	tipoCuena,	tipoResp,	tipoContrato,
        fchAperturaCta,	fchCierrecta,    frecuenciaPago,	formaPagoActual,
    	histMorosidadGr
        having count(nombreOtorgante) = convert(INT,@w_valor_nuevo)
        order by cont desc
        
        delete cob_credito..cr_grupo_promo_inicio where gpi_tramite = @w_tramite 
        
        insert into cob_credito..cr_grupo_promo_inicio
        select @w_tramite, @w_grupo, idCliente  from @clientes 
        where nombreOtorgante = (select top 1 nombreOtorgante from @original)
        and tipoCuena = (select top 1 tipoCuena from @original)
        and	tipoResp = (select top 1 tipoResp from @original)
        and	tipoContrato = (select top 1 tipoContrato from @original)
        and fchAperturaCta = (select top 1 fchAperturaCta from @original)
        and	(fchCierrecta =   (select top 1 fchCierrecta from @original) or fchCierrecta is null)
        and frecuenciaPago = (select top 1 frecuenciaPago from @original)
        and	formaPagoActual = (select top 1 formaPagoActual from @original)
        and	histMorosidadGr = (select top 1 histMorosidadGr from @original)
        
        select @w_ente = 0
    	while 1 = 1
    	begin
            
            select @w_ente   = idCliente
            from @clientes
            where idCliente > @w_ente
            and nombreOtorgante = (select top 1 nombreOtorgante from @original)
            and tipoCuena = (select top 1 tipoCuena from @original)
            and	tipoResp = (select top 1 tipoResp from @original)
            and	tipoContrato = (select top 1 tipoContrato from @original)
            and fchAperturaCta = (select top 1 fchAperturaCta from @original)
            and	(fchCierrecta = (select top 1 fchCierrecta from @original) or fchCierrecta is null)
            and frecuenciaPago = (select top 1 frecuenciaPago from @original)
            and	formaPagoActual = (select top 1 formaPagoActual from @original)
            and	histMorosidadGr = (select top 1 histMorosidadGr from @original)
            order by idCliente desc
            
            IF @@ROWCOUNT = 0
    	      BREAK
            
            set @w_comentario = @w_comentario + convert(varchar,@w_ente) +', '
        end
    end
    
    if (convert(int,@w_valor_nuevo) < @w_min_original ) 
    begin
            print 'INGRESA OBSERVACION ORIGINALES:' + @w_comentario
            
            delete cob_workflow..wf_observaciones 
            where ob_id_asig_act = @w_asig_act
            and ob_numero in (select ol_observacion from  cob_workflow..wf_ob_lineas 
            where ol_id_asig_act = @w_asig_act 
            and ol_texto like 'ERROR GRUPO ORIGEN:%')
            
            delete cob_workflow..wf_ob_lineas 
            where ol_id_asig_act = @w_asig_act 
            and ol_texto like 'ERROR GRUPO ORIGEN:%'
            
            set @w_comentario = substring(@w_comentario,0,len(@w_comentario)) + '.'
            
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
            values (@w_asig_act, @w_numero, getdate(), @w_proceso, 1, 'a', @w_usuario)
            
            insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
            values (@w_asig_act, @w_numero, 1, @w_comentario)
            
            
            
    end
end
else
begin
    select @w_valor_nuevo = @w_min_original
end

print 'EVALUA INTEGRANTES GRUPO PROMO: '+ @w_valor_nuevo

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
              where mv_id_inst_proc = @i_id_inst_proc and
                    mv_codigo_var= @i_id_variable and
                    mv_id_asig_act = @w_asig_actividad)
begin
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
