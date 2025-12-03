/*************************************************************************/
/*   Archivo:              custopv.sp                                    */
/*   Stored procedure:     sp_custopv                                    */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_custopv') IS NOT NULL
    DROP PROCEDURE dbo.sp_custopv
go
create proc sp_custopv (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo               varchar(64)  = null,
   @i_custodia           int  = null,
   @i_propuesta          int  = null,
   @i_estado             catalogo  = null,
   @i_fecha_ingreso      datetime  = null,
   @i_valor_inicial      money  = null,
   @i_valor_actual       money  = null,
   @i_moneda             tinyint  = null,
   @i_garante            int  = null,
   @i_instruccion        varchar(255)  = null,
   @i_descripcion        varchar(255)  = null,
   @i_poliza             varchar( 20)  = null,
   @i_inspeccionar       char(  1)  = null,
   @i_motivo_noinsp      catalogo = null,
   @i_suficiencia_legal  char(1) = null,
   @i_fuente_valor       catalogo  = null,
   @i_situacion          char(  1)  = null,
   @i_almacenera         smallint  = null,
   @i_aseguradora        varchar( 20)  = null,
   @i_cta_inspeccion     ctacliente  = null,
   @i_direccion_prenda   descripcion  = null,
   @i_ciudad_prenda      descripcion  = null,
   @i_telefono_prenda    varchar( 20)  = null,
   @i_mex_prx_inspec     tinyint  = null,
   @i_fecha_modif        datetime  = null,
   @i_fecha_const        datetime  = null,
   @i_porcentaje_valor   float  = null,
   @i_formato_fecha      int = null,
   @i_periodicidad   	 catalogo = null,
   @i_depositario   	 varchar(255) = null,
   @i_posee_poliza	 char(1) = null,
   @i_custodia1          int = null,
   @i_custodia2          int = null,
   @i_custodia3          int = null,
   @i_fecha_ingreso1     datetime = null,
   @i_fecha_ingreso2     datetime = null,
   @i_fecha_ingreso3     datetime = null,
   @i_tipo1              varchar(64) = null,
   @i_cond1	         varchar(64) = null,
   @i_cond2		 varchar(64) = null,
   @i_cond3		 varchar(64) = null,
   @i_param1	         varchar(64) = null,
   @i_parte              tinyint = null,
   @i_cobranza_judicial	 char(1) = null,
   @i_fecha_retiro	 datetime = null,
   @i_fecha_devolucion   datetime = null,
   @i_estado_poliza      char(1)  = null,
   @i_cobrar_comision    char(1) = null,
   @i_codigo_compuesto	 varchar(64) = null,
   @i_compuesto          varchar(64) = null,
   @i_cuenta_dpf         varchar(30) = null,
   @i_cliente            int = null,
   @i_ente               int = null,
   @i_abierta_cerrada    char(1) = null
 
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo               varchar(64),
   @w_custodia           int,
   @w_propuesta          int,      -- no se utiliza, sirve para
   @w_num_inspecc        tinyint,  -- numero de inspecciones
   @w_estado             catalogo,
   @w_fecha_ingreso      datetime,
   @w_valor_inicial      money,
   @w_valor_actual       money,
   @w_moneda             tinyint,
   @w_garante            int,
   @w_instruccion        varchar(255),
   @w_descripcion        varchar(255),
   @w_poliza             varchar( 20),
   @w_inspeccionar       char(  1),
   @w_fuente_valor       catalogo,
   @w_situacion          char(  1),
   @w_almacenera         smallint,
   @w_aseguradora        varchar( 20),
   @w_cta_inspeccion     ctacliente,
   @w_direccion_prenda   varchar(64),
   @w_ciudad_prenda      varchar(64),
   @w_telefono_prenda    varchar( 20),
   @w_mex_prx_inspec     tinyint,
   @w_fecha_modif        datetime,
   @w_fecha_const        datetime,
   @w_porcentaje_valor   float,
   @w_suficiencia_legal  char(  1),
   @w_motivo_noinsp      catalogo,
   @w_des_est_custodia   varchar(64),
   @w_des_fuente_valor   varchar(64),
   @w_des_motivo_noinsp  catalogo, 
   @w_des_inspeccionar   varchar(64),
   @w_des_tipo           varchar(20),
   @w_des_moneda         catalogo,
   @w_periodicidad  	 catalogo,
   @w_des_periodicidad	 catalogo,
   @w_depositario    	 varchar(255),
   @w_posee_poliza	 char(1),
   @w_des_garante        varchar(64),
   @w_des_almacenera	 varchar(64),
   @w_des_aseguradora 	 varchar(64),
   @w_valor_intervalo    tinyint,
   @w_error		 int,
   @w_cobranza_judicial  char(1),
   @w_fecha_retiro       datetime, 
   @w_fecha_devolucion   datetime,
   @w_fecha_modificacion datetime,
   @w_usuario_crea	 login,
   @w_usuario_modifica	 login,
   @w_estado_poliza      char(1),
   @w_des_estado_poliza  varchar(64),
   @w_cobrar_comision    char(1),
   @w_abr_cer            char(1),
   @w_status		 int,
   @w_perfil		 varchar(10),
   @w_valor_conta        money,
   @w_cuenta_dpf         varchar(30),
   @w_cliente            int,
   @w_des_cliente        varchar(64),
   @w_nro_cliente        tinyint,
   @w_ente               int,
   @w_codigo_externo     varchar(64),
   @w_abierta_cerrada    char(1),
   @w_riesgos            money

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_custopv'


/***********************************************************/
/* Codigos de Transacciones                                */

   if (@t_trn <> 19093 and @i_operacion = 'V') or
      (@t_trn <> 19096 and @i_operacion = 'A') or
      (@t_trn <> 19565 and @i_operacion = 'B') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Consulta opcion VALUE */
/*************************/

if @i_operacion = 'V'
begin
   select cu_custodia,cu_tipo,cu_descripcion
      from cu_custodia
      where cu_filial = @i_filial and
            cu_sucursal = @i_sucursal and
            cu_custodia = @i_custodia and
            cu_tipo = @i_tipo 
      if @@rowcount = 0 
      begin
         /* No existe el registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1901005
             return 1 
      end
      return 0
end
 
if @i_operacion = 'B'
begin
   select @w_custodia    = cu_custodia,
          @w_tipo        = cu_tipo,
          @w_descripcion = cu_descripcion
      from cu_custodia
      where cu_filial = @i_filial and
            cu_sucursal = @i_sucursal and
            cu_custodia = @i_custodia and
            cu_tipo = @i_tipo and
            cu_estado not in ('A')
      if @@rowcount = 0 
      begin
         /* No existe el registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1901005
             return 1 
      end
      return 0
end

if @i_operacion = 'A'
begin
   if @i_filial is null
      select @i_filial = convert(tinyint,@i_cond1)
   if @i_sucursal is null
      select @i_sucursal = convert(smallint,@i_cond2)  
   if @i_tipo is null
      select @i_tipo = @i_cond3
   if @i_custodia is null
      select @i_custodia = convert(int,@i_param1)
   set rowcount 20 
   select cu_custodia,substring(cu_descripcion,1,25)--,p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre
   from cu_custodia with(1)--,cobis..cl_ente
   where cu_filial   = @i_filial 
     and cu_sucursal = @i_sucursal
     and cu_tipo     = @i_tipo
    -- and cu_cliente  = en_ente
     and (cu_custodia > @i_custodia or @i_modo = 0)
         if @@rowcount = 0 
         begin
         /* No existe el registro */
             if @i_custodia is null
                select @w_error = 1901003
             else
                select @w_error = 1901004
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1 
         end
end
go