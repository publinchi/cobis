/************************************************************************/
/*   NOMBRE LOGICO:      ca_registra_traslados_masivos.sp               */
/*   NOMBRE FISICO:      sp_registra_traslados_masivos                  */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Guisela Fernandez, Johan Hernandez             */
/*   FECHA DE ESCRITURA:                                                */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Realizar La inserción en la tabla ca_registra_traslados_masivos     */ 
/*  de los datos seleccionados tanto para el traslado de Oficina        */
/*  como de Oficial.                                                    */
/*  Registro de estados                                                 */
/*  I = Ingresado                                                       */
/*  A = Anulado   (Si ingresa duplicados el primer registro se anula)   */
/*  P = Procesado (Se ejecuta en el poseso batch de traslados)          */
/*  E = Error     (Genero un error en el proceso batch de traslados)    */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/03/2021    G. Fernandez	 Versión Inicial                        */
/* 18/03/2021    J. Hernandez	 Versión Inicial                        */
/* 21/10/2021    K. Rodriguez    Se agrega campos adicionales a la tabla*/
/*                               ca_registra_traslados_masivos          */
/* 04/05/2022    G. Fernandez    Ingreso de registro de forma individual*/
/* 17/05/2023    G. Fernandez    S785427 En traslado de oficina se adcio*/
/*                               na registra el traslado de oficial     */
/* 24/12/2023    K. Rodriguez    R220437 Rediseño proceso para registrar*/
/*                               traslado en base a OP Padre, sus hijas */
/************************************************************************/ 

USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_registra_traslados_masivos')
   drop proc sp_registra_traslados_masivos
go

CREATE PROC sp_registra_traslados_masivos(
@s_ofi                  smallint		= NULL,
@s_org                  CHAR(1)			= NULL,
@s_rol                  smallint		= NULL,
@s_sesn                 int				= NULL,
@s_user                 login			= NULL,
@s_ssn                  int				= NULL,
@s_term                 varchar (30)	= NULL,
@s_date                 datetime		= NULL,
@s_rty                  char(1)			= NULL,
@t_trn                  int				= null,

@i_cliente				INT				= NULL,
@i_banco				VARCHAR(24)		= NULL,
@i_tramite				INT				= NULL,
@i_oficina				SMALLINT		= NULL,
@i_moneda               TINYINT			= NULL,
@i_fecha_ini			DATETIME		= NULL,
@i_estado				TINYINT			= NULL,
@i_migrada				VARCHAR(24)		= NULL,
@i_tipo_registro	    VARCHAR(24)		= NULL,
@i_grupal               char(1)         = null, -- Padre: 'S', Individual = 'N'

@i_estado_operacion	    CHAR(1)			= NULL,
@i_oficial_destino      INT		    	= NULL,
@i_oficina_destino      INT  			= NULL,
@i_operacion            CHAR(1)			= NULL,
@i_existe               CHAR(1)         = 'I'
)
as

DECLARE 
@w_error	      int,
@w_cont           int,
@w_tipo_operacion char(1),
@w_banco          varchar(24),
@w_cliente        int,
@w_tramite        int,
@w_oficina        smallint,
@w_moneda         tinyint,
@w_fecha_ini      datetime,
@w_estado         tinyint,
@w_migrada        varchar(24),
@w_ref_grupal     varchar(24),
@w_tipo_grp_ind   char(1)

-- Operacion/es a trasladarse 
if object_id('tempdb..#operaciones_traslado') is not null
   drop table #operaciones_traslado

create table #operaciones_traslado(
   tipo       char(1),
   banco      varchar(24),
   cliente    int,
   tramite    int,
   oficina    smallint,
   moneda     tinyint,
   fecha_ini  datetime,
   estado     tinyint,
   migrada    varchar(24) null,
   ref_grupal varchar(24) null
)

if @i_grupal is null
begin
   
   -- Tipo de operacion [G: Grupal Padre, H: Grupal Hija, N: Individual]
   exec @w_error = sp_tipo_operacion
   @i_banco    = @i_tipo_registro,
   @i_en_linea = 'N',
   @o_tipo     = @w_tipo_grp_ind out
   
   if @w_error <> 0
      goto ERROR
   
   if @w_tipo_grp_ind = 'G' 
      select @i_grupal = 'S'
	  
   if @w_tipo_grp_ind in ('N', 'H') 
      select @i_grupal = 'N' 
   
end

if @i_grupal = 'S' -- (Si es grupal Padre, incluir en traslado a Operaciones hijas activas)
begin

   insert into #operaciones_traslado
   select 'G'         ,op_banco      ,op_cliente  ,op_tramite  ,op_oficina   
		  ,op_moneda  ,op_fecha_ini  ,op_estado   ,op_migrada  ,op_banco   
   from ca_operacion with(nolock)
   where op_banco = @i_tipo_registro
   union
   select 'H'         ,op_banco      ,op_cliente  ,op_tramite  ,op_oficina   
		  ,op_moneda  ,op_fecha_ini  ,op_estado   ,op_migrada  ,op_ref_grupal
   from  ca_operacion with(nolock)
   where op_ref_grupal = @i_tipo_registro
   and op_estado not in (0,99,3,6)

end
else 
begin

   insert into #operaciones_traslado
   select 'N'         ,op_banco      ,op_cliente  ,op_tramite  ,op_oficina   
		  ,op_moneda  ,op_fecha_ini  ,op_estado   ,op_migrada  ,null
   from ca_operacion with(nolock)
   where op_banco = @i_tipo_registro
   
end

begin tran

-- TRASLADO DE OPERACIONES
select @w_cont = count(1) 
from #operaciones_traslado
  
while @w_cont > 0
begin

   select top 1
     @w_tipo_operacion = tipo,
     @w_banco          = banco,
	 @w_cliente        = cliente,
	 @w_tramite        = tramite,
	 @w_oficina        = oficina,
	 @w_moneda         = moneda,
	 @w_fecha_ini      = fecha_ini,
	 @w_estado         = estado,
	 @w_migrada        = migrada,
	 @w_ref_grupal     = ref_grupal
   from #operaciones_traslado
   order by tipo
     
   exec @w_error = sp_registra_traslados_masivos_int
   @s_rol             = @s_rol ,
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @i_cliente		  = @w_cliente ,
   @i_banco			  = @w_banco,
   @i_tramite		  = @w_tramite,
   @i_oficina		  = @w_oficina,
   @i_moneda          = @w_moneda,
   @i_fecha_ini		  = @w_fecha_ini,
   @i_estado		  = @w_estado,
   @i_migrada		  = @w_migrada,
   @i_ref_grupal      = @w_ref_grupal, -- Op padre e hijas tiene el op_banco Padre.
   @i_tipo_registro	  = @w_banco,
   @i_oficial_destino = @i_oficial_destino,
   @i_oficina_destino = @i_oficina_destino,
   @i_operacion       = @i_operacion,
   @i_existe          = @i_existe,
   @i_tipo_grupal     = @w_tipo_operacion
  
   if @w_error <> 0
     goto ERROR
  
   delete #operaciones_traslado where banco = @w_banco
   set @w_cont = (select count(1) from #operaciones_traslado)
  
end

commit tran

RETURN 0

ERROR:
exec cobis..sp_cerror
   @t_debug   = 'N',
   @t_from    = 'sp_registra_traslados_masivos',
   @i_num     = @w_error
return @w_error
GO

