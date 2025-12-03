/************************************************************************/
/*   Archivo:                 chkbc52plus.sp                            */
/*   Stored procedure:        sp_check_list_bc_52_plus                  */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Septiembre. 2019                          */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Reporte Chek List Legal BC 52 PLUS                                 */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   09/Sep/2019   Edison Cajas.   Emision Inicial                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_check_list_bc_52_plus')
    drop proc sp_check_list_bc_52_plus
go

create proc sp_check_list_bc_52_plus
(
   @t_trn              int          = 77531,
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco            varchar(15),
   @i_nemonico         varchar(10),
   @i_formato_fecha    int          = 103
)
as 

declare
    @w_sp_name              varchar(30)      ,@w_error                int             ,@w_grupo               int
   ,@w_nombreGrupo          varchar(70)      ,@w_codigoGrupo          varchar(10)     ,@w_nombrePresidente    varchar(70)
   ,@w_codigoPresidente     varchar(10)      ,@w_nro_operacion        varchar(24)     ,@w_nombre_oficial      varchar(70)
   ,@w_tipo_operacion       catalogo         ,@w_tipo_tramite         catalogo        ,@w_moneda              int
   ,@w_reca                 varchar(30)
   
select @w_sp_name = 'sp_check_list_bc_52_plus'

if @t_trn <> 77537
begin
    select @w_error = 151051		
    goto ERROR
end

   select 
      @w_grupo           = op_grupo
	 ,@w_nro_operacion   = op_banco
	 ,@w_tipo_operacion  = op_toperacion
	 ,@w_tipo_tramite    = isnull((select tr_tipo from cob_credito..cr_tramite where tr_tramite = op_tramite), 'NA')
	 ,@w_moneda          = isnull(op_moneda, 0)
   from ca_operacion  
  where op_banco = @i_banco

   --Nombre y Codigo del Grupo
   select 
      @w_nombreGrupo = gr_nombre
	 ,@w_codigoGrupo = convert(varchar,gr_grupo)
   from cobis..cl_grupo 
   where gr_grupo = @w_grupo
   
   --Nombre y Codigo del Presidente del grupo y codigo
   select 
      @w_nombrePresidente = en_nombre + ' '+ p_p_apellido + ' '+ p_s_apellido
	 ,@w_codigoPresidente = convert(varchar,en_ente)
   from cobis..cl_ente, cobis..cl_cliente_grupo
  where en_ente = cg_ente
    and cg_rol = 'P'
    and cg_grupo = @w_grupo
	
	--Nombre del oficial
	select @w_nombre_oficial = fu_nombre 
	from cobis..cl_funcionario
	    ,cobis..cc_oficial
		,cobis..cl_grupo
	where fu_funcionario = oc_funcionario
	and oc_oficial = gr_oficial
	and gr_grupo   = @w_grupo

	--Obtiene el reca
	select @w_reca = id_dato
    from cob_credito..cr_imp_documento
    where id_toperacion   = @w_tipo_operacion
    and   id_moneda       = @w_moneda
    and   id_mnemonico    = @i_nemonico
    and   id_tipo_tramite = @w_tipo_tramite

   Select 
      @w_nombreGrupo
     ,@w_codigoGrupo
	 ,@w_nombrePresidente
	 ,@w_codigoPresidente
	 ,@w_nro_operacion
	 ,@w_nombre_oficial


return 0

ERROR:

   exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
   
return @w_error