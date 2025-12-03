/*************************************************************************/
/*   Archivo:              buscar_custodia.sp                            */
/*   Stored procedure:     sp_buscar_custodia                            */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go

IF OBJECT_ID('sp_buscar_custodia') IS NOT NULL
    DROP PROCEDURE sp_buscar_custodia
go

create proc sp_buscar_custodia (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
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
   @i_periodicidad       catalogo = null,
   @i_depositario     varchar(255) = null,
   @i_posee_poliza    char(1) = null,
   @i_custodia1          int = null,
   @i_custodia2          int = null,
   @i_custodia3          int = null,
   @i_fecha_ingreso1     datetime = null,
   @i_fecha_ingreso2     datetime = null,
   @i_fecha_ingreso3     datetime = null,
   @i_tipo1              descripcion = null,
   @i_cond1     descripcion = null,
   @i_cond2     descripcion = null,
   @i_cond3     descripcion = null,
   @i_param1            descripcion = null,
   @i_parte              tinyint = null,
   @i_cobranza_judicial  char(1) = null,
   @i_fecha_retiro    datetime = null,
   @i_fecha_devolucion   datetime = null,
   @i_estado_poliza      char(1)  = null,
   @i_cobrar_comision    char(1) = null,
   @i_codigo_compuesto   varchar(64) = null,
   @i_compuesto          varchar(64) = null,
   @i_cuenta_dpf         varchar(30) = null,
   @i_cliente            int = null,
   @i_oficial            smallint = null,
   @i_num_op_banco       cuenta = null,
   @i_codigo_externo     varchar(64) = null

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
   @w_direccion_prenda   descripcion,
   @w_ciudad_prenda      descripcion,
   @w_telefono_prenda    varchar( 20),
   @w_mex_prx_inspec     tinyint,
   @w_fecha_modif        datetime,
   @w_fecha_const        datetime,
   @w_porcentaje_valor   float,
   @w_suficiencia_legal  char(  1),
   @w_motivo_noinsp      catalogo,
   @w_des_est_custodia   descripcion,
   @w_des_fuente_valor   descripcion,
   @w_des_motivo_noinsp  catalogo,
   @w_des_inspeccionar   descripcion,
   @w_des_tipo           catalogo,
   @w_des_moneda         catalogo,
   @w_periodicidad    catalogo,
   @w_des_periodicidad   catalogo,
   @w_depositario        varchar(255),
   @w_posee_poliza    char(1),
   @w_des_garante        descripcion,
   @w_des_almacenera  descripcion,
   @w_des_aseguradora    descripcion,
   @w_valor_intervalo    tinyint,
   @w_error     int,
   @w_cobranza_judicial  char(1),
   @w_fecha_retiro       datetime,
   @w_fecha_devolucion   datetime,
   @w_fecha_modificacion datetime,
   @w_usuario_crea    login,
   @w_usuario_modifica   login,
   @w_estado_poliza      char(1),
   @w_des_estado_poliza  descripcion,
   @w_cobrar_comision    char(1),
   @w_abr_cer            char(1),
   @w_status       int,
   @w_perfil       varchar(10),
   @w_valor_conta        money,
   @w_cuenta_dpf         varchar(30),
   @w_cliente            int,
   @w_des_cliente        descripcion,
   @w_nro_cliente        tinyint

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_buscar_custodia'


/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19304 and @i_operacion = 'S') or
   (@t_trn <> 19307 and @i_operacion = 'C') or
   (@t_trn <> 19308 and @i_operacion = 'F') or
   (@t_trn <> 19309 and @i_operacion = 'V') or
   (@t_trn <> 19305 and @i_operacion = 'O')
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1
end
else
begin
   create table #temporal (moneda money, cotizacion money)
   insert into #temporal (moneda,cotizacion)
   select ct_moneda,ct_compra
   from cob_conta..cb_cotizacion a
   where    ct_fecha = (select max(b.ct_fecha)
         from cob_conta..cb_cotizacion b
         where b.ct_moneda = a.ct_moneda
           and b.ct_fecha <= @w_today)
   --group by ct_moneda
   --having ct_fecha = max(ct_fecha)
end

if @i_operacion = 'S'
begin
      set rowcount 20
      if @i_modo = 0
      begin
         select distinct 'GARANTIA' = cu_custodia,
                'TIPO' = cu_tipo,
                'DES' = tc_descripcion,
                'ESTADO' = cu_estado,
                'INGRESO' = convert(char(10),cu_fecha_ingreso,@i_formato_fecha),
                'MONEDA' = cu_moneda,
                'VALOR INICIAL' = cu_valor_inicial,
                'VALOR ACTUAL' = cu_valor_actual,
                'VALOR MN' = cu_valor_actual * isnull(cotizacion,1),
                'CODIGO' = substring(cu_codigo_externo,1,20)
         from cu_custodia
		 inner join cu_tipo_custodia on cu_tipo = tc_tipo
		 left join #temporal on moneda = cu_moneda
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal or @i_sucursal is null) and
               (cu_custodia >= @i_custodia1 or @i_custodia1 is null) and
               (cu_custodia <= @i_custodia2 or @i_custodia2 is null) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               (cu_estado = @i_estado or @i_estado is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cu_fecha_ingreso >= @i_fecha_ingreso1 or
                @i_fecha_ingreso1 is null) and
               (cu_fecha_ingreso <= @i_fecha_ingreso2 or
                @i_fecha_ingreso2 is null)
         order by cu_tipo,cu_custodia
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1   -- No existen registros
         end
      end
      else
      begin
         select distinct 'GARANTIA' = cu_custodia, 'TIPO' = cu_tipo,
                'DES'=tc_descripcion,
                'ESTADO' = cu_estado,
                'INGRESO' = convert(char(10),cu_fecha_ingreso,@i_formato_fecha),
                'MONEDA' = cu_moneda,
                'VALOR INICIAL' = cu_valor_inicial,
                'VALOR ACTUAL' = cu_valor_actual,
                'VALOR MN' = cu_valor_actual * isnull(cotizacion,1),
                'CODIGO' = substring(cu_codigo_externo,1,20)
         from cu_custodia
		 inner join cu_tipo_custodia on cu_tipo = tc_tipo
		 left join #temporal on moneda = cu_moneda
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal or @i_sucursal is null) and
               (cu_custodia >= @i_custodia1 or @i_custodia1 is null) and
               (cu_custodia <= @i_custodia2 or @i_custodia2 is null) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               (cu_estado = @i_estado or @i_estado is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cu_fecha_ingreso >= @i_fecha_ingreso1
                or @i_fecha_ingreso1 is null) and
               (cu_fecha_ingreso <= @i_fecha_ingreso2
                or @i_fecha_ingreso2 is null) and
               (cu_tipo > @i_tipo1 or (cu_tipo = @i_tipo1
                 and cu_custodia > @i_custodia3))
         order by cu_tipo,cu_custodia
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 2  -- No existen mas registros
         end
      end
end

/*  Para busqueda de Garantias de Clientes */
if @i_operacion = 'C'
begin
      --LRE 10/13/05 Si no se envia como parametro la sucursal, solo se puede consultar las garantias
      --      de la oficina a la que esta conectado

      if @i_sucursal is NULL
          select @i_sucursal = @s_ofi

      set rowcount 20
      if @i_modo = 0
      begin
         select distinct 'GARANTIA' = cu_custodia, 'TIPO' = cu_tipo,
                'DES'=tc_descripcion,
                'ESTADO' = cu_estado,
                'INGRESO' = convert(char(10),cu_fecha_ingreso,@i_formato_fecha),
                'MONEDA' = cu_moneda,
                'VALOR INICIAL' = cu_valor_inicial,
                'VALOR ACTUAL' = cu_valor_actual,
                'VALOR MN' = cu_valor_actual * isnull(cotizacion,1),
                'CODIGO' = substring(cu_codigo_externo,1,20)
         from cu_custodia
		 inner join cu_cliente_garantia on cg_codigo_externo= cu_codigo_externo
		 inner join cu_tipo_custodia on cu_tipo = tc_tipo
              --cobis..cl_ente,
         left join #temporal on moneda = cu_moneda
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal or @i_sucursal is null) and
               (cu_custodia >= @i_custodia1 or @i_custodia1 is null) and
               (cu_custodia <= @i_custodia2 or @i_custodia2 is null) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               (cu_estado = @i_estado or @i_estado is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cu_fecha_ingreso >= @i_fecha_ingreso1 or
                @i_fecha_ingreso1 is null) and
               (cu_fecha_ingreso <= @i_fecha_ingreso2 or
                @i_fecha_ingreso2 is null) and
               (cg_ente = @i_cliente or @i_cliente is null) and
               --(en_ente = cg_ente) and
               --(en_oficial = @i_oficial or @i_oficial is null) and
               (cg_oficial = @i_oficial or @i_oficial is null) 
         order by cu_tipo,cu_custodia
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1       
         end
      end
      else
      begin
         select distinct 'GARANTIA' = cu_custodia, 'TIPO' = cu_tipo,
                'DES'=tc_descripcion,
                'ESTADO' = cu_estado,
                'INGRESO' = convert(char(10),cu_fecha_ingreso,@i_formato_fecha),
                'MONEDA' = cu_moneda,
                'VALOR INICIAL' = cu_valor_inicial,
                'VALOR ACTUAL' = cu_valor_actual,
                'VALOR MN' = cu_valor_actual * isnull(cotizacion,1),
                'CODIGO' = substring(cu_codigo_externo,1,20)
         from cu_custodia
		 inner join cu_cliente_garantia on cg_codigo_externo = cu_codigo_externo
		 inner join cu_tipo_custodia on cu_tipo = tc_tipo
         --cobis..cl_ente,
         left join #temporal on moneda = cu_moneda
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal or @i_sucursal is null) and
               (cu_custodia >= @i_custodia1 or @i_custodia1 is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cu_custodia <= @i_custodia2 or @i_custodia2 is null) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               (cu_estado = @i_estado or @i_estado is null) and
               (cu_fecha_ingreso >= @i_fecha_ingreso1
                or @i_fecha_ingreso1 is null) and
               (cu_fecha_ingreso <= @i_fecha_ingreso2
                or @i_fecha_ingreso2 is null) and
               (cg_ente = @i_cliente or @i_cliente is null) and
               --(en_ente = cg_ente) and
               --(en_oficial = @i_oficial or @i_oficial is null) and
               (cg_oficial = @i_oficial or @i_oficial is null) and
               (cu_tipo > @i_tipo1 or (cu_tipo = @i_tipo1
                 and cu_custodia > @i_custodia3)) 
         order by cu_tipo,cu_custodia
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1
         end
      end
end

/*  Para busqueda General de Garantias  */
if @i_operacion = 'F'
begin
      set rowcount 20
         select distinct
				'CODIGO' = cu_codigo_externo,
                'TIPO' = cu_tipo,
                'DES'= tc_descripcion,
                'SECUENCIAL' = cu_custodia,
                'SUCURSAL' = cu_sucursal,
                ' ' = of_nombre
         from cu_custodia,cu_cliente_garantia,cu_tipo_custodia,
              cobis..cl_oficina
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal) and
               (cu_sucursal = of_oficina) and
               (cu_tipo = tc_tipo) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               (cg_ente = @i_cliente or @i_cliente is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cg_codigo_externo= cu_codigo_externo) and
               (cu_codigo_externo>@i_codigo_externo or @i_codigo_externo is null)
         order by cu_codigo_externo
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1
        end
end

if @i_operacion = 'V'
begin
   select cu_codigo_externo,
          cu_sucursal,
          of_nombre,
          cu_tipo,
          tc_descripcion,
          cu_custodia
     from cu_custodia,cu_tipo_custodia,cobis..cl_oficina
    where cu_codigo_externo = @i_codigo_externo
      and cu_tipo           = tc_tipo
     --inicio prueba
      and cu_estado <> 'A'
      --fin prueba
      and cu_sucursal       = of_oficina
   if @@rowcount = 0
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1901003
         return 1
      end
end

if @i_operacion = 'O'  --MVI 09/25/96 Consulta por Numero de Operacion
begin

      set rowcount 20
      if @i_modo = 0
      begin
         select distinct 'GARANTIA' = cu_custodia, 'TIPO' = cu_tipo,
                'DE'=tc_descripcion,
                'ESTADO' = cu_estado,
                'INGRESO' = convert(char(10),cu_fecha_ingreso,@i_formato_fecha),
                'MONEDA' = cu_moneda,
                'VALOR INICIAL' = cu_valor_inicial,
                'VALOR ACTUAL' = cu_valor_actual,
                'VALOR MN' = cu_valor_actual * isnull(cotizacion,1),
                'CODIGO' = cu_codigo_externo
         from cu_custodia
		 inner join cu_cliente_garantia on cu_codigo_externo = cg_codigo_externo
		 inner join cobis..cl_ente on cg_ente = en_ente
		 inner join cu_tipo_custodia on cu_tipo = tc_tipo
		 left join #temporal on moneda = cu_moneda
         
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal) and
               (cu_custodia >= @i_custodia1 or @i_custodia1 is null) and
               (cu_custodia <= @i_custodia2 or @i_custodia2 is null) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cu_estado = @i_estado or @i_estado is null) and
               (cg_ente = @i_cliente or @i_cliente is null) and
               (en_oficial = @i_oficial or @i_oficial is null) and
               (cu_fecha_ingreso >= @i_fecha_ingreso1 or
                @i_fecha_ingreso1 is null) and
               (cu_fecha_ingreso <= @i_fecha_ingreso2 or
                @i_fecha_ingreso2 is null)
         order by cu_tipo,cu_custodia
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1   -- No existen registros
         end
      end
      else
      begin
         select distinct 'GARANTIA' = cu_custodia, 'TIPO' = cu_tipo,
                'DES'=tc_descripcion,
                'ESTADO' = cu_estado,
                'INGRESO' = convert(char(10),cu_fecha_ingreso,@i_formato_fecha),
                'MONEDA' = cu_moneda,
                'VALOR INICIAL' = cu_valor_inicial,
                'VALOR ACTUAL' = cu_valor_actual,
                'VALOR MN' = cu_valor_actual * isnull(cotizacion,1),
                'CODIGO' = cu_codigo_externo
         from cu_custodia
		 inner join cu_tipo_custodia on cu_tipo = tc_tipo
         inner join cu_cliente_garantia on cu_codigo_externo = cg_codigo_externo
		 inner join cobis..cl_ente on cg_ente = en_ente
		 left join #temporal on moneda = cu_moneda
         where (cu_filial = @i_filial) and
               (cu_sucursal = @i_sucursal) and
               (cu_custodia >= @i_custodia1 or @i_custodia1 is null) and
               (cu_custodia <= @i_custodia2 or @i_custodia2 is null) and
               (cu_tipo like @i_tipo or @i_tipo is null) and
               --inicio prueba
               (cu_estado <> 'A') and
               --fin prueba
               (cu_estado = @i_estado or @i_estado is null) and
               (cg_ente = @i_cliente or @i_cliente is null) and
               (en_oficial = @i_oficial or @i_oficial is null) and
               (cu_fecha_ingreso >= @i_fecha_ingreso1
                or @i_fecha_ingreso1 is null) and
               (cu_fecha_ingreso <= @i_fecha_ingreso2
                or @i_fecha_ingreso2 is null) and
               (cu_tipo > @i_tipo1 or (cu_tipo = @i_tipo1
                 and cu_custodia > @i_custodia3)) --and
         order by cu_tipo,cu_custodia
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 2  -- No existen mas registros
         end
      end
end
GO
