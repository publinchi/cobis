/************************************************************************/
/*  Archivo:                clasif_cartera.sp                           */
/*  Stored procedure:       sp_clasif_cartera                           */
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

if exists (select 1 from sysobjects where name = 'sp_clasif_cartera' and type = 'P')
   drop proc sp_clasif_cartera
go

create proc sp_clasif_cartera
   @s_ssn               int          = null,
   @s_user		login        = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @i_toperacion	catalogo     = null,
   @i_moneda		tinyint      = null,
   @i_salida            char(1)      = 'S',
   @i_monto		money	     = null,
   @i_cliente           int          = null,
   @i_destino           catalogo     = null,
   @i_tramite           int          = null,
   @o_clase_cartera	catalogo     = null out,
   @o_desc_clase        varchar(20)  = null out,
   @o_tipo_cliente      char(1)      = null out
as
declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_tipo		char(1),
   @w_producto		catalogo,
   @w_sal_min_vig       money,    
   @w_cod_vivienda      catalogo,
   @w_cod_consumo       catalogo,
   @w_cod_comercial     catalogo,
   @w_cod_microcredito  catalogo,
   @w_clase_cartera	catalogo,     
   @w_desc_clase        varchar(20),
   @w_riesgo		money,
   @w_num_empleados     int,
   @w_tot_activos	money,
   @w_num_emp  		int,
   @w_num_sal_deuda	smallint,
   @w_num_planta	smallint,
   @w_num_sal_activo	smallint,
   @w_t_persona		char(1),
   @w_cliente		int,
   @w_grupo             int,
   @w_picv              int,
   @w_pfcv              int,
   @w_toperacion	catalogo,
   @w_tipo_productor	catalogo,
   @w_microempfinagro	char(1),
   @w_rowcount          int

/* CARGAR VALORES INICIALES */
SELECT @w_sp_name = 'sp_clasif_cartera'


/*** OBTENER PARAMETROS GENERALES ***/
-- Cod Vivienda fijo Sacar de parametro
SELECT @w_cod_vivienda = pa_char 
FROM cobis..cl_parametro
WHERE pa_producto = 'CRE'
  and pa_nemonico = 'CVIV'
set transaction isolation level READ UNCOMMITTED

-- Cod Consumo fijo  Sacar de parametro
SELECT @w_cod_consumo = pa_char 
FROM cobis..cl_parametro
WHERE pa_producto = 'CRE'
  and pa_nemonico = 'CCON'
set transaction isolation level READ UNCOMMITTED

--Cod comercial Sacar Parametro
SELECT @w_cod_comercial = pa_char 
FROM cobis..cl_parametro
WHERE pa_producto = 'CRE'
  and pa_nemonico = 'CCOM'
set transaction isolation level READ UNCOMMITTED

--Cod Microcredito Sacar Parametro
SELECT @w_cod_microcredito = pa_char 
FROM cobis..cl_parametro
WHERE pa_producto = 'CRE'
  and pa_nemonico = 'CMIC'
set transaction isolation level READ UNCOMMITTED

--Plazo Minimo Amortizacion Clase de Vivienda
SELECT @w_picv = pa_int
FROM cobis..cl_parametro
WHERE pa_producto = 'CRE'
  and pa_nemonico = 'PICV'
set transaction isolation level READ UNCOMMITTED


--Plazo Maximo Amortizacion Clase de Vivienda
SELECT @w_pfcv = pa_int
FROM cobis..cl_parametro
WHERE pa_producto = 'CRE'
  and pa_nemonico = 'PFCV'
set transaction isolation level READ UNCOMMITTED



SELECT @w_producto = to_producto
FROM cr_toperacion
WHERE to_toperacion = @i_toperacion
and to_estado = 'V' 
set transaction isolation level READ UNCOMMITTED


if @i_cliente is null
BEGIN
   SELECT @w_cliente		= tr_cliente,
	  @i_cliente		= tr_cliente,
	  @w_toperacion		= tr_toperacion,
	  @w_tipo_productor	= tr_tipo_productor
   FROM   cr_tramite
   WHERE  tr_tramite = @i_tramite
END


SELECT @w_t_persona = en_subtipo,
       @w_num_empleados = isnull(c_num_empleados,0),
       @w_tot_activos = isnull(c_total_activos,0)
FROM cobis..cl_ente
WHERE en_ente = @i_cliente
set transaction isolation level READ UNCOMMITTED


SELECT @w_clase_cartera = NULL
if @w_t_persona = 'P' -- Persona Natural
BEGIN
   if exists(SELECT * FROM cr_destino_economico
	     WHERE de_codigo_inversion = @i_destino
	     and   de_clase = @w_cod_vivienda)
   BEGIN
      SELECT @w_clase_cartera = @w_cod_vivienda /* '3' VIVIENDA */
      if exists(SELECT	1 
		FROM	cob_custodia..cu_custodia,
			cr_gar_propuesta,
			cr_corresp_sib
		WHERE	cu_codigo_externo =	gp_garantia
		AND	gp_tramite	  =	@i_tramite
		AND	cu_tipo		  =	codigo      
		AND 	tabla		  =	'T1')
      BEGIN
         if not exists(SELECT	1 
		       FROM	cob_cartera..ca_operacion,
		       cob_cartera..ca_tdividendo
		       WHERE	op_tramite	=	@i_tramite
		       AND	op_tplazo	=	td_tdividendo
		       AND      td_estado	=	'V'
		       AND      td_factor*op_plazo >=	@w_picv 
		       AND      td_factor*op_plazo <=	@w_pfcv)
         BEGIN
            SELECT @w_clase_cartera = null
         END		   
      END
      ELSE
      BEGIN
         SELECT @w_clase_cartera = null
      END
   END
END

if @w_clase_cartera  IS NULL
BEGIN
   SELECT @w_num_planta = pa_tinyint
   FROM   cobis..cl_parametro
   WHERE  pa_producto   = 'CRE'
   and    pa_nemonico   = 'NEMIC'
   select @w_rowcount = @@rowcount
   set transaction isolation level READ UNCOMMITTED

   if @w_rowcount = 0 
   BEGIN
      exec cobis..sp_cerror
	   @t_from  = @w_sp_name,
	   @i_num   = 2101084
	   return 1 
   END

   -- Numero de salarios para Activos Microcredito
   SELECT @w_num_sal_activo = pa_smallint
   FROM   cobis..cl_parametro
   WHERE  pa_producto 	= 'CRE'
   and    pa_nemonico 	= 'NSMIC'
   select @w_rowcount = @@rowcount
   set transaction isolation level READ UNCOMMITTED

   if @w_rowcount = 0 
   BEGIN
      exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 2101084
	   return 1 
   END

   SELECT @w_sal_min_vig = pa_money
   FROM   cobis..cl_parametro
   WHERE  pa_producto = 'ADM'
   and    pa_nemonico = 'SMV'
   select @w_rowcount = @@rowcount
   set transaction isolation level READ UNCOMMITTED

   if @w_rowcount = 0 
   BEGIN
      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = 2101084
      return 1 
   END

   select @w_microempfinagro = 'N'
   if exists (select 1 
              from   cr_corresp_sib
	      where  codigo = @w_toperacion
	      and	  tabla	 = 'T17')
   begin
      if exists (select 1 
		 from   cr_corresp_sib
		 where  codigo	= @w_tipo_productor
		 and    tabla	= 'T28')
      begin
	 select @w_microempfinagro = 'S'
      end
   end

   if ((@w_num_empleados <=  @w_num_planta and @w_num_empleados <>  0) or @w_microempfinagro = 'S') or
       (@w_tot_activos <= @w_num_sal_activo * @w_sal_min_vig)
   BEGIN
      SELECT @w_num_sal_deuda = pa_tinyint
      FROM cobis..cl_parametro
      WHERE pa_producto = 'CRE'
      and   pa_nemonico = 'NSMC'
      select @w_rowcount = @@rowcount
      set transaction isolation level READ UNCOMMITTED

      if @w_rowcount = 0 
      BEGIN
         exec cobis..sp_cerror
	 @t_from  = @w_sp_name,
	 @i_num   = 2101084
	 return 1 
      END

      exec @w_return = sp_riesgo_i
    	   --@s_ssn	  = @s_ssn,
           --@s_user	  = @s_user,
    	   --@s_date        = @s_date,
     	   @i_cliente     = @w_cliente,
    	   @i_grupo       = @w_grupo,
    	   @i_tramite     = @i_tramite,
    	   @i_detalle     = 'N',
    	   @o_opcion      = @w_riesgo output 

      SELECT @w_riesgo  = isnull(@w_riesgo ,0)
      SELECT @i_monto   = isnull(@i_monto ,0)
      SELECT @i_tramite   = isnull(@i_tramite ,0)

      if @i_tramite = 0
      BEGIN
         SELECT @w_riesgo  = @i_monto + @w_riesgo 
      END

      if @w_riesgo <= @w_num_sal_deuda * @w_sal_min_vig 
         SELECT @w_clase_cartera = @w_cod_microcredito /*'4' MICROCREDITO */
   END 
END


if @w_t_persona = 'P' and @w_clase_cartera  IS NULL -- Persona Natural
BEGIN
   if exists( SELECT * FROM cr_destino_economico
	      WHERE de_codigo_inversion = @i_destino
	      and de_clase = @w_cod_consumo)
      SELECT @w_clase_cartera = @w_cod_consumo /*'2'  CONSUMO   */
   else
   BEGIN
      SELECT @w_clase_cartera = null
   END
END

SELECT @w_clase_cartera = isnull(@w_clase_cartera, @w_cod_comercial)

SELECT @w_desc_clase = c.valor  
FROM  cobis..cl_tabla t, cobis..cl_catalogo c
WHERE c.tabla = t.codigo 
and   t.tabla = 'cr_clase_cartera' 
and c.codigo = ltrim(rtrim(@w_clase_cartera))
set transaction isolation level READ UNCOMMITTED

SELECT @o_clase_cartera = @w_clase_cartera
SELECT @o_desc_clase    = @w_desc_clase
SELECT @o_tipo_cliente  = @w_t_persona
   	
update 	cr_tramite
set	tr_clase    = @w_clase_cartera
from	cob_cartera..ca_operacion
where	tr_tramite  =  @i_tramite
and	op_tramite  =  tr_tramite
and	op_estado   in (99,0)

if @i_salida = 'S'
BEGIN
   SELECT @o_clase_cartera 
   SELECT @o_desc_clase
   SELECT @o_tipo_cliente 
END  

return 0

GO
