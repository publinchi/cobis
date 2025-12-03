/************************************************************************/
/*  Archivo:            direccion_cons.sp                               */
/*  Stored procedure:   sp_direccion_cons                               */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
/*  Disenado por:       Mauricio Bayas/Sandra Ortiz                     */
/*  Fecha de escritura: 07-Nov-1992                                     */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este programa procesa las transacciones de consultas de             */
/*  direcciones                                                         */
/************************************************************************/
/*              MODifICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/* 09/03/05    R Garcia     Eliminacion de busqueda de campos de codpos */
/* 18/05/20    MBA          Cambio nombre y compilacion BDD cobis       */
/* 25/06/20    FSAP         Estandarizacion clientes                    */
/* 22/12/20    IYU          Agregar Campos direccion - CLI-S412684      */
/* 27/04/20    COBIS        Nueva operacion para consulta de un correo  */
/* 27/11/23    BDU          R220277-Tomar 1 registro de direccion_geo   */
/************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTifIER off
go

if exists (select 1 
             from sysobjects 
            where name = 'sp_direccion_cons')
   drop proc sp_direccion_cons 
go
create proc sp_direccion_cons (
    @s_culture         varchar(10) = 'NEUTRAL',
    @s_ssn             int,
    @s_user            login       = null,
    @s_term            varchar(32) = null,
    @s_date            datetime,
    @s_srv             varchar(30) = null,
    @s_lsrv            varchar(30) = null,
    @s_ofi             smallint    = NULL,
    @s_rol             smallint    = NULL,
    @s_org_err         char(1)     = NULL,
    @s_error           int         = NULL,
    @s_sev             tinyint     = NULL,
    @s_msg             descripcion = NULL,
    @s_org             char(1)     = NULL,
    @t_debug           char(1)     = 'N',
    @t_file            varchar(10) = null,
    @t_from            varchar(32) = null,
    @t_trn             int         = null,
    @t_show_version    bit         = 0,    -- Versionamiento
    @i_operacion       char(1),            -- Opcion con la que se ejecuta el programa
    @i_ente            int         = null, -- Codigo secuencial del cliente
    @i_direccion       tinyint     = null, -- Numero que indica el correspondiente a la direccion del cliente
    @i_descripcion     varchar(254)= null, -- Descripcion de la direccion
    @i_tipo            catalogo    = null, -- Tipo de direccion
    @i_calle           varchar(70) = null, -- Calle del cliente
    @i_casa            varchar(40) = null, -- casa o Dept del cliente
    @i_formato_fecha   int         = 103,  -- NULL
    @i_secuencial      int         = null,   ---Paginación mas d30 direcciones
    @i_tipo_prop       char(10)    = null,
    @i_origen          char(1)     = 'M'  -- se agrega variable por mensaje de error en la pantalla de apk
)
as
declare
    @w_transaccion         int,
    @w_sp_name             varchar(32),
    @w_sp_msg              varchar(132),
    @w_codigo              int,
    @w_error               int,
    @w_return              int,
    @w_descripcion         varchar(254),
    @w_tipo                catalogo,
    @w_sector              catalogo,
    @w_zona_ant            catalogo,
    @w_zona                catalogo,
    @w_parroquia           int,
    @w_barrio              char(40),
    @w_ciudad              int,
    @w_oficina             smallint,
    @w_verificado          char(1),
    @w_vigencia            char(1),
    @w_principal           char(1),
    @w_casa                varchar(40),
    @w_calle               varchar(70),
    @w_dir_comer           char(1),
    @v_descripcion         varchar(254),
    @v_tipo                catalogo,
    @v_sector              catalogo,
    @v_zona                catalogo,
    @v_parroquia           int,
    @v_barrio              char(40),
    @v_ciudad              int,
    @v_oficina             smallint,
    @v_verificado          char(1),
    @v_vigencia            char(1),
    @v_principa            char(1),
    @v_casa                varchar(40),
    @v_calle               varchar(70),
    @v_dir_comer           char(1),
    @o_ente                int,
    @o_ennombre            descripcion,
    @o_cedruc              numero,
    @o_direccion           tinyint,
    @o_descripcion         varchar(254),
    @o_ciudad              int,
    @o_cinombre            descripcion,
    @o_parroquia           int,
    @o_barrio              char(40),
    @o_pqnombre            descripcion,
    @o_tipo                catalogo,
    @o_tinombre            descripcion,
    @o_sector              catalogo,
    @o_cod_prov            smallint,
    @o_provincia           descripcion,
    @o_sector_nombre       descripcion,
    @o_zona                catalogo,
    @o_zona_nombre         descripcion,
    @o_telefono            tinyint,
    @o_valor               varchar(12),
    @o_siguiente           int,
    @o_oficina             smallint,
    @o_ofinombre           descripcion,
    @o_verificado          char(1),
    @o_vigencia            char(1),
    @o_principal           char(1),
    @o_fecha_registro      datetime,
    @o_fecha_modificacion  datetime,
    @o_funcionario         login,
    @o_fecha_ver           datetime,
    @o_codpostal           varchar(30),
    @o_casa                varchar(40),
    @o_calle               varchar(70),    -- TVI 05/31/2011 INC 2124
    @o_rural_urbano        char(1),
    -- CAMPOS NUEVOS       
    @o_nom_rural_urbano    char(10),
    @o_departamento        varchar(10),
    @o_nom_depart          varchar(40),
    @o_fact_serv_pu        char(1),
    @o_tipo_prop           char(10),
    @o_nom_tipo_prop       varchar(15),
    --PSO Sincronización   
    @w_pais_local          smallint,       -- Vivi, CL00025
    @w_pais_ecuad          smallint,       -- Vivi, CL00025
    @w_vu_pais             catalogo,
    @w_vu_banco            catalogo,
    --PSO FIN Sincronización
    @w_pais                smallint,
    @w_canton              int,
    @w_codbarrio           int,
    @w_correspondencia     char(1),
    @w_alquilada           char(1),
    @w_cobro               char(1),
    @w_otrasenas           varchar(254),
    @v_pais                smallint,
    @v_canton              int,
    @v_codbarrio           int,
    @v_correspondencia     char(1),
    @v_alquilada           char(1),
    @v_cobro               char(1),
    @v_otrasenas           varchar(254),
    @o_pais                smallint,
    @o_despais             varchar(40),
    @o_canton              int,
    @o_descanton           varchar(40),
    @o_codbarrio           int,
    @o_distrito            int,
    @o_desdistrito         varchar(40),
    @o_correspondencia     char(1),
    @o_alquilada           char(1),
    @o_cobro               char(1),
    @o_otrasenas           varchar(254),
    @o_montoalquiler       money,
    @o_edificio            varchar(40),
    @o_dir_comer           char(1),
    @o_nombre_agencia      varchar(20),
    @o_fuente_verif        varchar(10),
    @o_localidad           varchar(20),
    @o_desc_localidad      varchar(100),
      @o_localidad_cobis     varchar(30),
    --nuevos campos para   validar Direcciones--
                           
    @w_fecha_proceso       datetime,
    @w_parametro_di        int,
        ---Nuevos campos   para envio de mail al oficial PXSG--
    @w_cliente             int,
    @w_nombre_cli          varchar(50),
    @w_apellido            varchar(50),
    @w_mail_oficial        varchar(30),
    @w_email_body          varchar(1000),
    @w_oficial_ente        int,
    @w_tmail               varchar(10),
    @w_poblacion           varchar(100),
    @w_conjunto            varchar(100),
    @w_apart_casa          varchar(100),
    @w_latitud             varchar(100), 
    @w_longitud            varchar(100),
    @w_piso                varchar(100),
    @w_nro_resi            char(1),
    @w_tiempo_resi         char(1),
    @w_asunto_mail         varchar(200),
    @w_head_mail           varchar(200)

    
select @w_sp_name = 'sp_direccion_cons'
-------------- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
     
if @s_culture = 'NEUTRAL'
begin
   ---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
   exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
end
select @w_asunto_mail = re_valor                                                                                                                                                                           
from   cobis..cl_errores 
inner join cobis..ad_error_i18n 
on    (numero = pc_codigo_int                                                                                                                                                                                                                        
       and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
where  numero = 1720612 


select @w_head_mail = re_valor                                                                                                                                                                           
from   cobis..cl_errores 
inner join cobis..ad_error_i18n 
on   (numero = pc_codigo_int 
      and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
where numero = 1720613

--PSO Sincronización
-- CODIGO DE PAIS LOCAL PANAMA
-- Vivi, 18/Ago/09 CL00025
select @w_pais_local = pa_smallint
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico = 'CP'

-- CODIGO DE PAIS EXTRANJERO ECUADOR
-- PSO Se cambia select
select @w_pais_ecuad = convert( smallint, pa_char )
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'PEX'

-- LEE PARAMETROS DE PAIS Y BANCO DE LA VERSION
-- Vivi, CC0008
select @w_vu_banco = pa_char
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico = 'CLIENT'

if @@rowcount <> 1
begin
   exec cobis..sp_cerror
        @t_debug     = @t_debug,
        @t_file      = @t_file,
        @t_from      = @w_sp_name,
        @i_num       = 1720226
   return 1
end

select @w_vu_pais = pa_char
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico = 'ABPAIS'

if @@rowcount <> 1
begin
   exec cobis..sp_cerror
        @t_debug     = @t_debug,
        @t_file      = @t_file,
        @t_from      = @w_sp_name,
        @i_num       = 1720226
   return 1
end
--PSO FIN Sincronización

--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn  <> 172012 and @i_operacion = 'G') or
   ((@t_trn <> 172012 and @t_trn <> 1227)   and @i_operacion = 'S') or
   (@t_trn  <> 172012 and @i_operacion = 'X') or
   (@t_trn  <> 172012 and @i_operacion = 'P') or
   ((@t_trn <> 172013 and @t_trn <> 172015) and @i_operacion = 'Q') or
   (@t_trn  <> 172014 and @i_operacion = 'H')
begin 
   /* Tipo de transaccion no corresponde */ 
   exec cobis..sp_cerror 
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720075
   return 1
end

/** Consulta General **/
-- Se crea esta opcion porque la existente no filtra las direcciones por tipo --GDE -07/17/2012
if @i_operacion = 'G'
begin
   if @t_trn = 172012
   begin
      if @i_tipo is null --PSO Sincronización
      begin

        select  'No.'         = a.di_direccion,
            'DIRECCION NO LOCAL / EDifICIO'   = convert(varchar(255),(case when (@w_vu_pais = 'CR' and @w_vu_banco = 'HSBC')  then ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + convert(varchar(100),a.di_descripcion) + ' ' + a.di_casa + a.di_codpostal)     --Vivi CC00009
                                               else ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + a.di_casa +' ' + convert(varchar(100),a.di_descripcion) ) end)) ,
            'COD. PAIS'             = a.di_pais,
            'NOMBRE PAIS'           = pa_descripcion,
            'PROVINCIA'             = a.di_provincia,
            'NOMBRE PROV.'          = pv_descripcion,
            'COD. CANTON'           = a.di_ciudad, --a.di_canton se cambia por di_ciudad
            'CANTON'                = substring(ci_descripcion,1,20), --substring(ca_descripcion,1,20),
            'COD. DISTRITO'         = a.di_parroquia, --a.di_distrito,
            'DISTRITO'              = substring(e.pq_descripcion,1,20), --substring(e.di_descripcion,1,20),
            'COD. BARRIO'           = a.di_codbarrio,
            'BARRIO'                = substring(ba_descripcion,1,20),
            'OTRA SENAS'            = a.di_otrasenas,
            'COD. TIPO DIR.'        = a.di_tipo,
            'TIPO DIRECCION'        = substring(c.valor, 1, 20),
            'OFICINA'               = a.di_oficina,
            'DESC. OFICINA'         = substring(of_nombre,1,30),
            'VERif.'                = a.di_verificado,
            'PRINCIPAL'             = a.di_principal,
            'DIR. COORRESPONDENCIA' = a.di_correspondencia,
            'ALQUILADA'             = a.di_alquilada,
            'DIR. COBRO'            = a.di_cobro,
            'CALLE'                 = a.di_calle,
            'CASA O APTO.'          = a.di_casa,
            'LOCALIDAD'             = a.di_localidad,
            'DESC. LOCALIDAD'       = lo.lo_desc_localidad,
            'LOCALIDAD COBIS'    = lo.lo_localidad
        from 
          cobis..cl_direccion a left join cobis..cl_ciudad ci
                                on     a.di_ciudad    = ci.ci_ciudad 
          
                                left join cobis..cl_oficina
                                 on     a.di_oficina   = of_oficina

                                left join   cobis..cl_barrio
                                on     a.di_codbarrio = ba_barrio

                                left join cobis..cl_parroquia e
                                on     a.di_parroquia = e.pq_parroquia

                                left join cobis..cl_provincia
                                on     a.di_provincia = pv_provincia
                                left join cobis..cl_pais 
                                on     pa_pais        = convert(int,a.di_pais)
                                left join cobis..cl_localidad lo
                                on     a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,

            cobis..cl_catalogo c, 
            cobis..cl_tabla d
        where  a.di_ente       = @i_ente
        and    a.di_tipo       = c.codigo
        and    c.tabla         = d.codigo
        and    d.tabla         = 'cl_tdireccion'


        --------- Nuevo filtro --------------
        and    a.di_tipo      <> 'CE'
        order by di_direccion

        return 0
      end
   end
end

/** Search **/
if @i_operacion = 'S'
begin
   if @t_trn = 172012 or @t_trn = 1227
   begin
      if @i_tipo = 'A' or @i_tipo is null --PSO Sincronización
      begin --PSO Sincronización
         select  'No.'     = di_direccion,
            'DIRECCION NO LOCAL / EDifICIO' = convert(varchar(255),(case when (@w_vu_pais = 'CR' and @w_vu_banco = 'HSBC')  then ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + convert(varchar(100),a.di_descripcion) + ' ' + a.di_casa + a.di_codpostal)  --Vivi CC00009
                                             else ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + a.di_casa +' ' + convert(varchar(100),a.di_descripcion) ) end )),
            'RURAL/URBANO'           = a.di_rural_urbano,
            'COD. PAIS'              = a.di_pais,
            'NOMBRE PAIS'            = (select pa_descripcion from cobis..cl_pais where pa_pais = a.di_pais),
            'PROVINCIA'              = a.di_provincia,
            'NOMBRE PROV.'           = (select pv_descripcion from cobis..cl_provincia where pv_provincia = a.di_provincia),
            'DEPARTAMENTO'           = a.di_departamento,
            'NOMBRE DEP.'            = (select dp_descripcion from cobis..cl_depart_pais where dp_departamento = a.di_departamento),
            'COD. LOCAL/CIUDAD'      = a.di_ciudad, --a.di_canton se cambia por di_ciudad
            'LOCAL/CIUDAD'           = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = a.di_ciudad),
            'BARRIO'                 = a.di_barrio,
            'UBICACION REF.'         = a.di_otrasenas,
            'COD. TIPO DIR.'         = a.di_tipo,
            'TIPO DIRECCION'         = substring(c.valor, 1, 20),
            'OFICINA'                = a.di_oficina,
            'DESC. OFICINA'          = (select of_nombre from cobis..cl_oficina where of_oficina = a.di_oficina),
            'VERif.'                 = a.di_verificado,
            'PRINCIPAL'              = a.di_principal,
            'DIR. COORRESPONDENCIA'  = a.di_correspondencia,
            'TIPO PROPIEDAD'         = a.di_tipo_prop,
            'CUOTAS ALQUILER'        = a.di_montoalquiler,
            'DIR. COBRO'             = a.di_cobro,
            'AV./CALLE/PAS.'         = a.di_calle,
            'CASA O DPTO.'           = a.di_casa,
            'EDifICIO/CASA'          = a.di_edificio,
            'PRES. FACTURAS S.P.'    = a.di_fact_serv_pu,
            'NOMBRE AGENCIA'         = a.di_nombre_agencia,
            'LOCALIDAD'              = a.di_localidad,
            'DESC. LOCALIDAD'        = lo.lo_desc_localidad,
               'LOCALIDAD COBIS'        = lo.lo_localidad
            --'DIR. COMERCIAL'         = a.di_so_igu_co
             from    cobis..cl_direccion a left join cobis..cl_localidad lo
                                on     a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,  
                                cobis..cl_catalogo c, cobis..cl_tabla d
             where  a.di_ente       = @i_ente
               and  a.di_tipo       = c.codigo
               and  c.tabla         = d.codigo
               and  d.tabla         = 'cl_tdireccion'

             order by di_direccion

       return 0
      end

      --PSO SIncronización
      if @i_tipo = 'B'
      begin
         select  'No.'        = a.di_direccion,
            'DIRECCION NO LOCAL / EDifICIO' = convert(varchar(255),(case when (@w_vu_pais = 'CR' and @w_vu_banco = 'HSBC')  then
                                             (case when pv_pais = @w_pais_ecuad then (ltrim(di_barrio + ' ' + convert(varchar(100),a.di_descripcion) ))
                                              when pv_pais = @w_pais_local then (ltrim(g.pq_descripcion + ' ' + a.di_barrio + ' ' + a.di_calle+ ' ' + convert(varchar(100),a.di_descripcion) + ' ' + a.di_casa ))
                                              else (ltrim(convert(varchar(100),a.di_descripcion) + ' ' + a.di_codpostal)) end )
                                              else ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + a.di_casa + ' ' + convert(varchar(100),a.di_descripcion)) end)) ,
            'COD. PAIS'             = a.di_pais,
            'NOMBRE PAIS'           = pa_descripcion,
            'PROVINCIA'             = a.di_provincia,
            'NOMBRE PROV.'          = pv_descripcion,
            'COD. CANTON'           = a.di_ciudad, --a.di_canton se cambia por di_ciudad
            'CANTON'                = substring(ci_descripcion,1,20), --substring(ca_descripcion,1,20),
            'COD. DISTRITO'         = a.di_parroquia, --a.di_distrito,
            'DISTRITO'              = substring(g.pq_descripcion,1,20), --substring(g.di_descripcion,1,20),
            'COD. BARRIO'           = a.di_codbarrio,
            'BARRIO'                = substring(ba_descripcion,1,20),
            'OTRA SEÑA'             = a.di_otrasenas,
            'COD. TIPO DIR.'        = a.di_tipo,
            'TIPO DIRECCION'        = substring(c.valor, 1, 20),
            'OFICINA'               = a.di_oficina,
            'DESC. OFICINA'         = substring(of_nombre,1,30),
            'VERif.'                = a.di_verificado,
            'PRINCIPAL'             = a.di_principal,
            'DIR. COORRESPONDENCIA' = a.di_correspondencia,
            'ALQUILADA'             = a.di_alquilada,
            'MONTO ALQUILER'        = a.di_montoalquiler,
            'DIR. COBRO'            = a.di_cobro,
            'CALLE'                 = a.di_calle,
            'CASA O APTO.'          = a.di_casa,
            'ZIP CODE '             = a.di_codpostal,
            'COD.ZONA/SECTOR'       = a.di_zona,
            'ZONA/SECTOR '          = (select c1.valor from cobis..cl_catalogo c1, cobis..cl_tabla t1 where t1.tabla = 'cl_zona' and  c1.tabla = t1.codigo and c1.codigo        = a.di_zona),
            'LOCALIDAD'             = a.di_localidad,
            'DESC. LOCALIDAD'       = lo.lo_desc_localidad,
               'LOCALIDAD COBIS'       = lo.lo_localidad
         from 
 cobis..cl_direccion a 
              left join cobis..cl_ciudad             on a.di_ciudad     = ci_ciudad
              left join cobis..cl_oficina            on a.di_oficina    = of_oficina
              left join cobis..cl_barrio             on a.di_codbarrio  = ba_barrio
              left join cobis..cl_parroquia g  on a.di_parroquia  = g.pq_parroquia 
              left join cobis..cl_provincia    on a.di_provincia  = pv_provincia
              left join cobis..cl_pais         on pa_pais         = convert(int,a.di_pais)
              left join cobis..cl_localidad lo on a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,
              cobis..cl_catalogo c, cobis..cl_tabla d
         where  a.di_ente        = @i_ente
         and    a.di_tipo        = c.codigo
         and    c.tabla          = d.codigo
         and    d.tabla          = 'cl_tdireccion'
         order by di_direccion

         return 0
      end

      /*CONSULTA DIRECCIONES DE UN CLIENTE*/
      if @i_tipo = 'C'
      begin
         select 'COD. DIRECCION'   = di_direccion,
                'COD. DEPARTAMENTO'= di_departamento,
                'DEPARTAMENTO'     =(select  b.valor
                                    from cobis..cl_tabla a,
      cobis..cl_catalogo b
                                   where a.tabla  = 'cl_depart_pais'
                   and a.codigo = b.tabla
                                     and b.codigo = convert(varchar(10),c.di_departamento)),
                'COD. PROVINCIA'   = di_provincia,
                'PROVINCIA'        =(select  b.valor
                                     from cobis..cl_tabla a,
                                       cobis..cl_catalogo b
                                    where a.tabla  = 'cobis..cl_provincia'
                                      and a.codigo = b.tabla
                                      and convert(int, b.codigo) = c.di_provincia),
                'COD. CIUDAD'            = di_ciudad,
                'CIUDAD'           =(select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cobis..cl_ciudad'
                                      and a.codigo = b.tabla
                                      and b.codigo = convert(varchar(10),c.di_ciudad)),
                'DIRECCION'          = di_calle+' '+di_edificio+' '+di_casa+' '+di_barrio,
                'TIPO TELEFONO'      = te_tipo_telefono,
                'COD. AREA'          = te_area,
                'NUMERO TELEFONO'    = te_valor,
                'LOCALIDAD'          = c.di_localidad,
                'DESC. LOCALIDAD'    = lo.lo_desc_localidad,
                'LOCALIDAD COBIS'    = lo.lo_localidad
           from cobis..cl_direccion c left join cobis..cl_localidad lo on c.di_localidad = lo.lo_localidad and c.di_ciudad = lo.lo_ciudad, 
                cobis..cl_telefono
          where te_ente        = di_ente
            and di_direccion   = te_direccion
            and di_ente        = @i_ente
            and (@i_tipo_prop  = null or di_tipo  = @i_tipo_prop)
            and te_secuencial  = 1       
         if @@rowcount=0
         begin
          /*--No hay mas registros--*/
                exec cobis..sp_cerror
                @t_debug= @t_debug,
                @t_file = @t_file,
                @t_from = @w_sp_name,
                @i_num  = 1720227
            return 1
         end
         return 0
      end
      --MTA INCIO nueva opcion de consulta para la version base de producto
      if @i_tipo = 'D'
      begin
         --validaciones Direcciones PXSG--
         select @w_fecha_proceso=fp_fecha from cobis..ba_fecha_proceso;
      
         select @w_parametro_di=pa_int 
         from cobis..cl_parametro 
         where pa_producto='CLI'
            and pa_nemonico='FDVD'
         
         --envio de mail al oficial--
         if exists( select 1 
            from cobis..cl_direccion c 
            where c.di_ente=@i_ente 
               and (datediff(mm,c.di_fecha_modificacion,@w_fecha_proceso)) >@w_parametro_di)
         begin
            --obtengo los datos del  cliente--
            select @w_cliente        = c.en_ente, 
                   @w_nombre_cli     = c.en_nombre,
                   @w_apellido       = c.p_p_apellido, 
                   @w_oficial_ente   = c.en_oficial
            from cobis..cl_ente c
            where en_ente=@i_ente

            --PRINT ('codigo')+CONVERT(varchar(30),@w_cliente)
            --PRINT ('nombre')+CONVERT(varchar(30),@w_nombre_cli)
            --PRINT ('apellido')+CONVERT(varchar(30),@w_apellido)
         
            select @w_tmail = pa_char 
            from cobis..cl_parametro 
            where pa_producto = 'ADM' 
               and pa_nemonico= 'TEMFU'

            -- CORREO PARA OFICIAL
            select TOP 1 @w_mail_oficial = isnull(mf_descripcion, '1')
            from cobis..cc_oficial, cobis..cl_funcionario, cobis..cl_medios_funcio
            where oc_oficial       = @w_oficial_ente
               and fu_funcionario  = oc_funcionario
               and fu_funcionario  = mf_funcionario
               and mf_tipo         = @w_tmail 

            select @w_mail_oficial = isnull(@w_mail_oficial, '1')

            if @w_mail_oficial <> '1'
            begin
               select @w_email_body = '' +@w_nombre_cli +' '+ @w_apellido +'.<br><br>' + @w_asunto_mail +
                     '<br><br><br>'
                     
               exec cobis..sp_notificacion_general
                  @i_operacion    =  'I',
                  @i_mensaje      =  @w_email_body,
                  @i_correo       =  @w_mail_oficial,
                  @i_asunto       =  @w_head_mail
            end
      end
      select 'COD. DIRECCION'     = di_direccion,
             'COD. TIPO'          = di_tipo,
             'TIPO'               = (select  b.valor
                                     from cobis..cl_tabla a,
                                         cobis..cl_catalogo b
                                     where a.tabla  = 'cl_tdireccion'
                                       and a.codigo = b.tabla
                                       and b.codigo = convert(varchar(10),c.di_tipo)
                                    ),
             'COD. PAIS'          = di_pais,
             'PAIS'               = (select pa_descripcion from cobis..cl_pais where pa_pais = c.di_pais),
             'COD. PROVINCIA'     = c.di_provincia,
             'PROVINCIA'          = (select  b.valor
                                     from cobis..cl_tabla a,
                                         cobis..cl_catalogo b
                                     where a.tabla  = 'cl_provincia'
                                       and a.codigo = b.tabla
                                       and convert(int, b.codigo) = c.di_provincia
                                    ),
             'COD. CIUDAD'        = di_ciudad,
             'CIUDAD'             = (select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                     where a.tabla  = 'cl_ciudad'
                                       and a.codigo = b.tabla
                                       and convert(int, b.codigo) = c.di_ciudad
                                    ),
             'COD. PAQRROQUIA'    = di_parroquia,
             'PARROQUIA'          = (select b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                     where a.tabla  = 'cl_parroquia'
                                       and a.codigo = b.tabla
                                       and b.codigo = convert(varchar(10),c.di_parroquia)
                                    ),
             'DIRECCION'          = di_descripcion,
             'CALLE'              = di_calle,
             'BARRIO'             = di_barrio,
             'PRINCIPAL'          = di_principal,
             'CORRESPONDENCIA'    = di_correspondencia,
             'COD. DPTO'          = di_departamento,
             'DEPARTAMENTO'       = (select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                     where a.tabla  = 'cl_depart_pais'
                                       and a.codigo = b.tabla
                                       and b.codigo = convert(varchar(10),c.di_departamento)
                                    ),
             'TIEMPO RESIDENCIA'  = di_tiempo_reside,
             'COD. BARRIO'        = di_rural_urbano,
             'LATITUD'            = (select top 1 dg_lat_seg from cobis..cl_direccion_geo where dg_ente = c.di_ente and dg_direccion = c.di_direccion),
             'LONGITUD'           = (select top 1 dg_long_seg from cobis..cl_direccion_geo where dg_ente = c.di_ente and dg_direccion = c.di_direccion),
             'ID_CODIGO_BARRIO'   = di_codbarrio,
             'NRO_CALLE'          = di_casa,
             'COD_POSTAL'         = di_codpostal,
             'NRO_RESIDENTES'     = di_nro_residentes,
             'NRO_CALLE_INTER'    = di_edificio,
             'MESES_VIGENCIA'     = (datediff(mm,c.di_fecha_modificacion,@w_fecha_proceso)),
             'COD. NEGOCIO'       = di_negocio,
             'TIPO VIVIENDA'      = rtrim(di_tipo_prop),
             'CIUDAD POBLACION'   = isnull(di_poblacion,''),
             'LOCALIDAD'          = c.di_localidad,
             'DESC. LOCALIDAD'    = lo.lo_desc_localidad,
             'LOCALIDAD COBIS'    = lo.lo_localidad,
             'OTRO TIPO'          = di_otro_tipo,
             'CONJUNTO'           = di_conjunto,
             'PISO'               = di_piso,
             'NUMERO_CASA'        = di_numero_casa,
             'ZONA'               = di_zona,
             'SECTOR'             = di_sector
      from cobis..cl_direccion c left join cobis..cl_localidad lo on c.di_localidad = lo.lo_localidad and c.di_ciudad = lo.lo_ciudad
      where di_ente  = @i_ente
         
         
        if @@rowcount=0 and @i_origen <> 'M'
         begin
          /*--No hay mas registros--*/
            exec cobis..sp_cerror
               @t_debug= @t_debug,
               @t_file = @t_file,
               @t_from = @w_sp_name,
               @i_num  = 1720227
            return 1
         end
         return 0
      end
  --MTA FIN
  /* modificacion para consulta de direcciones de negocios desde el Movil */
  if @i_tipo = 'E'
      begin
      --validaciones Direcciones PXSG--
      select @w_fecha_proceso=fp_fecha 
        from cobis..ba_fecha_proceso;
      
      select @w_parametro_di=pa_int 
        from cobis..cl_parametro 
       where pa_producto='CLI' 
         and pa_nemonico='FDVD'
         
      --envio de mail al oficial--
      if exists( select 1 from cobis..cl_direccion c where c.di_ente=@i_ente and (datediff(mm,c.di_fecha_modificacion,@w_fecha_proceso)) >@w_parametro_di)
      begin
      --obtengo los datos del  cliente--
      select @w_cliente=c.en_ente, 
             @w_nombre_cli= c.en_nombre,
             @w_apellido=c.p_p_apellido, 
             @w_oficial_ente = c.en_oficial
      from cobis..cl_ente c
      where en_ente=@i_ente
                        
            --PRINT ('codigo')+CONVERT(varchar(30),@w_cliente)
           --PRINT ('nombre')+CONVERT(varchar(30),@w_nombre_cli)
            --PRINT ('apellido')+CONVERT(varchar(30),@w_apellido)
            
    select @w_tmail = pa_char 
      from cobis..cl_parametro 
     where pa_producto = 'ADM' 
       and pa_nemonico= 'TEMFU'

      -- CORREO PARA OFICIAL
    select TOP 1 @w_mail_oficial = isnull(mf_descripcion, '1')
    from cobis..cc_oficial, cobis..cl_funcionario, cobis..cl_medios_funcio
    where oc_oficial = @w_oficial_ente
    and fu_funcionario = oc_funcionario
    and fu_funcionario = mf_funcionario
    and mf_tipo  = @w_tmail 
   
   
    select @w_mail_oficial = isnull(@w_mail_oficial, '1')
                            
      if @w_mail_oficial <> '1'
            begin
               select @w_email_body = '' +@w_nombre_cli +' '+ @w_apellido +'.<br><br>' + @w_asunto_mail +
                     '<br><br><br>'
                     
               exec cobis..sp_notificacion_general
                  @i_operacion    =  'I',
                  @i_mensaje      =  @w_email_body,
                  @i_correo       =  @w_mail_oficial,
                  @i_asunto       =  @w_head_mail
            end
      End
      
         select 'COD. DIRECCION'   = di_direccion,
                'COD. TIPO'        = di_tipo,
                'TIPO'             =(select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cl_tdireccion'
                                      and a.codigo = b.tabla
                                      and b.codigo = convert(varchar(10),c.di_tipo)),
                'COD. PAIS'        = di_pais,
                'PAIS'             =(select pa_descripcion from cobis..cl_pais where pa_pais = c.di_pais ),
                'COD. PROVINCIA'   = c.di_provincia,
                'PROVINCIA'        =(select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cl_provincia'
                                      and a.codigo = b.tabla
                                      and convert(int, b.codigo) = c.di_provincia),
                'COD. CIUDAD'      = di_ciudad,
                'CIUDAD'           =(select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cl_ciudad'
                                      and a.codigo = b.tabla
                                      and convert(int, b.codigo) = c.di_ciudad),
                'COD. PAQRROQUIA'  = di_parroquia,
                'PARROQUIA'        =(select  b.valor
                                     from cobis..cl_tabla a,
                                          cobis..cl_catalogo b
                                    where a.tabla  = 'cl_parroquia'
                                      and a.codigo = b.tabla
                                      and b.codigo = convert(varchar(10),c.di_parroquia)),
                'DIRECCION'        = di_descripcion,
                'CALLE'            = di_calle,
                'BARRIO'           = di_barrio,
                'PRINCIPAL'        = di_principal,
                'CORRESPONDENCIA'  = di_correspondencia,
                    'COD. DPTO'        = di_departamento,
                    'DEPARTAMENTO'     = (select  b.valor
                    from cobis..cl_tabla a,
                                         cobis..cl_catalogo b
                                   where a.tabla  = 'cl_depart_pais'
                                     and a.codigo = b.tabla
                                     and b.codigo = convert(varchar(10),c.di_departamento)),
                'TIEMPO RESIDENCIA'= di_tiempo_reside,
                    'COD. BARRIO'      = di_rural_urbano,
                    'LATITUD'          = (select top 1 dg_lat_seg from cobis..cl_direccion_geo where dg_ente = c.di_ente and dg_direccion = c.di_direccion),
                    'LONGITUD'         = (select top 1 dg_long_seg from cobis..cl_direccion_geo where dg_ente = c.di_ente and dg_direccion = c.di_direccion),
                    'ID_CODIGO_BARRIO' = di_codbarrio,
                    'NRO_CALLE'       = di_casa,
                    'COD_POSTAL'         = di_codpostal,
                    'NRO_RESIDENTES'   = di_nro_residentes,
                    'NRO_CALLE_INTER'  = di_edificio,
                    'MESES_VIGENCIA'   =(datediff(mm,c.di_fecha_modificacion,@w_fecha_proceso)),
                    'COD. NEGOCIO'     = di_negocio,
                    'TIPO VIVIENDA'    = rtrim(di_tipo_prop),
                    'CIUDAD POBLACION' = isnull(di_poblacion,''),
                'LOCALIDAD'        = c.di_localidad,
                'DESC. LOCALIDAD'  = lo.lo_desc_localidad,
                    'LOCALIDAD COBIS'    = lo.lo_localidad
           from cobis..cl_direccion c left join cobis..cl_localidad lo on c.di_localidad = lo.lo_localidad and c.di_ciudad = lo.lo_ciudad
          where di_ente = @i_ente
          and   di_tipo        = 'AE'
         
         return 0
      end
  
 end   
   --PSO FIN SIncronización
   else
   begin
      exec cobis..sp_cerror
         @t_debug      = @t_debug,
         @t_file       = @t_file,
         @t_from       = @w_sp_name,
         @i_num        = 1720075
        /* 'No corresponde codigo de transaccion' */
      return 1
   end
end

/** Query **/
If @i_operacion = 'Q'
begin
   if @t_trn = 172013
   begin
      select @o_direccion             = a.di_direccion,
             @o_descripcion           = a.di_descripcion,
             @o_tipo                  = a.di_tipo,
             @o_principal             = a.di_principal,
             @o_tinombre              = substring(x.valor,1,30),
             @o_cod_prov              = a.di_provincia,
             @o_provincia             = pv_descripcion,
             @o_pais                  = a.di_pais,
             @o_despais               = substring(pa_descripcion,1,20),
             @o_canton                = a.di_ciudad, --a.di_canton,  a.di_ciudad      --10
             @o_descanton             = substring(ci_descripcion,1,20), --substring(ca_descripcion,1,20),
             @o_barrio                = substring(ba_descripcion,1,30),--CC-CLI-0009 CAMBIO DE FORMATO A TIPO CATÁLOGO BARRIO Y ZONA: en el campo di_barrio se va a guardar la descripcion del catalogo
             @o_codbarrio             = a.di_codbarrio,--CC-CLI-0009 CAMBIO DE FORMATO A TIPO CATÁLOGO BARRIO Y ZONA: en el campo di_codbarrio se va a guardar el id del catalogo
             @o_distrito              = a.di_parroquia, --a.di_distrito,
             @o_desdistrito           = substring(g.pq_descripcion,1,20), --substring(g.di_descripcion,1,20),
             @o_correspondencia       = a.di_correspondencia,
             @o_cobro                 = a.di_cobro,
             @o_otrasenas             = a.di_otrasenas,
             @o_zona                  = a.di_zona,
             @o_zona_nombre           = (select valor from cl_catalogo where tabla = 213 and codigo = a.di_zona),
             @o_fecha_registro        = a.di_fecha_registro,                         --20
             @o_fecha_modificacion    = a.di_fecha_modificacion,
             @o_verificado            = a.di_verificado, 
             @o_funcionario           = a.di_funcionario,
             @o_fecha_ver             = a.di_fecha_ver,
             @o_codpostal             = a.di_codpostal,
             @o_sector                = a.di_sector,
             @o_casa                  = a.di_casa,
             @o_calle                 = a.di_calle,
             @o_edificio              = a.di_edificio,
             @o_rural_urbano          = a.di_rural_urbano,                           --30
             @o_nom_rural_urbano      = (select c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
                                         where t.tabla = 'cl_sector'
                                         and   t.codigo = c.tabla
                                         and   a.di_rural_urbano = c.codigo),
             @o_departamento          = a.di_departamento,
             @o_nom_depart            = (select dp_descripcion
                                         from  cobis..cl_depart_pais
                                         where dp_departamento = a.di_departamento),
             @o_fact_serv_pu          = a.di_fact_serv_pu,
             @o_tipo_prop             = a.di_tipo_prop,
             @o_nom_tipo_prop         = (select c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
                                         where t.tabla = 'cl_tpropiedad'
                                         and   t.codigo = c.tabla
                                         and   a.di_tipo_prop = c.codigo),
             @o_montoalquiler          = a.di_montoalquiler,
             @o_nombre_agencia         = a.di_nombre_agencia,
             @o_fuente_verif           = a.di_fuente_verif,
             @o_localidad              = a.di_localidad,
             @o_desc_localidad         = lo.lo_desc_localidad,
             @o_localidad_cobis        = lo.lo_localidad
      from cobis..cl_direccion a
           left join cobis..cl_ciudad
        on a.di_ciudad = ci_ciudad
           left join cobis..cl_oficina
        on a.di_oficina = of_oficina
           left join cobis..cl_barrio 
        on a.di_codbarrio = ba_barrio
           left join cobis..cl_parroquia g
        on a.di_parroquia = g.pq_parroquia --g.di_distrito x pq_parroquia
           left join cobis..cl_provincia e 
        on a.di_provincia = pv_provincia
           left join cobis..cl_pais
        on convert(int,a.di_pais) = pa_pais 
           left join cobis..cl_depart_pais   --se quita la tabla cobis..cl_canton
        on a.di_departamento = dp_departamento
           left join cobis..cl_localidad lo 
        on a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,
           cobis..cl_catalogo x,  
           cobis..cl_ente,
            cobis..cl_tabla y
      where  en_ente = @i_ente
        and  en_ente = di_ente
        and  a.di_direccion = @i_direccion
        and  y.tabla = 'cl_tdireccion'
        and  x.tabla = y.codigo
        and  a.di_tipo = x.codigo
        order by di_direccion

      if @@rowcount = 0
      begin
         exec cobis..sp_cerror
            @t_debug  = @t_debug,
            @t_file   = @t_file,
            @t_from   = @w_sp_name,
            @i_num    = 1720074
           /* 'No existe dato solicitado'*/
         return 1
      end

      select @w_poblacion        = di_poblacion,
             @w_barrio           = di_barrio,
             @w_conjunto         = di_conjunto,
             @w_piso             = di_piso,
             @w_apart_casa       = di_numero_casa,
             @w_latitud          = dg_lat_seg,
             @w_longitud         = dg_long_seg,
             @w_nro_resi         = di_nro_residentes,
             @w_tiempo_resi      = di_tiempo_reside
      from cl_direccion, cl_direccion_geo
      where  di_ente             = @i_ente
      and    di_direccion        = @i_direccion
      and    di_ente             = dg_ente
      and    di_direccion        = dg_direccion
      
      select @o_direccion,
         isnull(@o_descripcion,''),
         @o_tipo,
         @o_tinombre,
         @o_principal,
         @o_pais,
         @o_despais,
         @o_cod_prov,
         @o_provincia,
         @o_canton,                 --10
         @o_descanton,
         @o_distrito,
         @o_desdistrito,
         @o_codbarrio,
         isnull(@o_barrio,''),
         @o_correspondencia,
         @o_alquilada,
         @o_montoalquiler,
         @o_cobro,
         @o_otrasenas,              --20
         @o_zona,
         @o_zona_nombre,
         convert(varchar(10),@o_fecha_registro,@i_formato_fecha),
         convert(varchar(10),@o_fecha_modificacion,@i_formato_fecha),
         convert(varchar(10),@o_verificado,@i_formato_fecha),
         @o_funcionario,
         convert(varchar(10),@o_fecha_ver,@i_formato_fecha),
         @o_codpostal,
         @o_sector,
         isnull(@o_casa,''),              --30
         @o_calle,
         @o_edificio,
         @o_dir_comer,
         @o_rural_urbano,
         @o_nom_rural_urbano,
         @o_departamento,
         @o_nom_depart,
         @o_fact_serv_pu,
         @o_tipo_prop,
         @o_nom_tipo_prop,                
         @o_montoalquiler,
         @o_nombre_agencia,
         @o_fuente_verif,
         @o_localidad,
         @o_desc_localidad,
         @o_localidad_cobis,
         @w_poblacion,
         @w_barrio,
         @w_conjunto,
         @w_piso,
         @w_apart_casa,
         @w_latitud,
         @w_longitud,
         @w_nro_resi,
         @w_tiempo_resi
   end
   else
      /*Consulta de Telefonos de CLiente NVR */
   if @t_trn = 172015
   begin
      select  'SEC.'          = te_secuencial,
              'NUMERO'        = rtrim(ltrim(te_valor)),
              'COD.'          = rtrim(ltrim(cobis..cl_catalogo.codigo)),
              'TIPO TELEFONO' = rtrim(ltrim(cobis..cl_catalogo.valor)),
              'COD AREA'      = te_area  -- req 27122
      from  cobis..cl_telefono, cobis..cl_catalogo, cobis..cl_tabla
      where  te_ente = @i_ente
       and  te_direccion = @i_direccion
       and  cobis..cl_catalogo.codigo = te_tipo_telefono
       and  cobis..cl_catalogo.tabla = cobis..cl_tabla.codigo
       and  cobis..cl_tabla.tabla = 'cl_ttelefono'
      order  by te_ente, te_direccion, te_secuencial

    return 0
   end
   else
   begin
      exec cobis..sp_cerror
         @t_debug      = @t_debug,
         @t_file       = @t_file,
         @t_from       = @w_sp_name,
         @i_num        = 1720075
         /*'No corresponde codigo de transaccion' */
      return 1
   end
end

/* ** HELP **/
if @i_operacion = 'H'
begin
   if @t_trn = 172014
   begin
      if @i_tipo = 'A'
         if @w_vu_pais = 'PA' and @w_vu_banco = 'BBP' --PSO Sincronización
            select  'SEC.'=di_direccion,
                    'DESCRIPCION'     = convert(varchar(255),(case when (@w_vu_pais = 'PA' and @w_vu_banco = 'BBP') then ltrim(di_barrio + ' ' + di_calle+ ' ' + convert(varchar(100),di_descripcion) + ' ' + di_casa + ' ' + di_codpostal)       --Vivi, CC00009
                                        else (ltrim(di_barrio + ' ' + di_calle+ ' ' + di_casa + ' ' + convert(varchar(100),di_descripcion) ) ) end)),
                    'TIPO' = valor
            from    cobis..cl_ente, cobis..cl_direccion, cobis..cl_catalogo
            where   en_ente = di_ente
            and en_ente = @i_ente
            and di_tipo = codigo
            and tabla = 299
         else --PSO Sincronización
            select  'SEC.'=di_direccion,
                    'DESCRIPCION'     = (ltrim(di_barrio + ' ' + di_calle+ ' ' + di_casa + ' ' + convert(varchar(100),di_descripcion)))
            from    cobis..cl_ente, cobis..cl_direccion
            where   en_ente = di_ente
            and en_ente = @i_ente
      else
      if @i_tipo = 'C'  --PSO Sincronización
      begin
      --PSO Sincronización
         select  'SEC.'        = di_direccion,
                'DESCRIPCION' = case when
                               (@w_vu_pais = 'PA' and @w_vu_banco = 'BBP') then
                               (case when pv_pais = @w_pais_ecuad then (ltrim(pv_descripcion +' '+ ci_descripcion + ' ' + pq_descripcion + ' ' + di_barrio + ' ' + convert(varchar(100),di_descripcion) ))
                                when pv_pais = @w_pais_local then (ltrim(pv_descripcion +' '+ ci_descripcion + ' ' + di_barrio + ' ' + di_calle+ ' ' + convert(varchar(100),di_descripcion) + ' ' + di_casa ))
                                else (ltrim(pv_descripcion +' '+ ci_descripcion + ' ' + convert(varchar(100),di_descripcion) + ' ' + di_codpostal)) end)
                                else ltrim(di_barrio + ' ' + di_calle+ ' ' + di_casa + ' ' + convert(varchar(100),di_descripcion)) end,
                'TIPO'        = valor
         from  
         cobis..cl_ente, 
         cobis..cl_direccion
             left join cobis..cl_provincia              on di_provincia = pv_provincia
             left join cobis..cl_ciudad                 on di_ciudad    = ci_ciudad
             left join cobis..cl_parroquia              on di_parroquia = pq_parroquia,
         cobis..cl_catalogo
         where  en_ente = di_ente
         and  en_ente = @i_ente
         and di_tipo = codigo
         and tabla = 299
      end
      else
        if @i_tipo = 'M'  --Se crea esta opcion para consulta de direccion <> Mail  --GDE -07/17/2012
        begin
           select case when (@w_vu_pais = 'PA' and @w_vu_banco = 'BBP') then  ltrim(di_barrio + ' ' + di_calle+ ' ' + convert(varchar(100),di_descripcion) + ' ' + di_casa + di_codpostal)
                            else (ltrim(di_barrio + ' ' + di_calle+ ' ' + di_casa + ' ' + convert(varchar(100),di_descripcion))) end
           from cobis..cl_ente, cobis..cl_direccion
           where en_ente = di_ente
           and en_ente = @i_ente
           and di_direccion = @i_direccion
           and di_tipo <> 'CE'

           if @@rowcount = 0
           begin
              exec cobis..sp_cerror
                 @t_debug  = @t_debug,
                 @t_file   = @t_file,
                 @t_from   = @w_sp_name,
                 @i_num    = 1720074
                 /* 'No existe dato solicitado'*/
             return 1
           end
        end
        else
       begin
          --PSO FIN Sincronización
          select  --PSO Se cambia (ltrim(di_barrio + ' ' + di_calle+ ' ' + di_casa + ' ' + convert(varchar(100),di_descripcion)))
                case when (@w_vu_pais = 'PA' and @w_vu_banco = 'BBP') then  ltrim(di_barrio + ' ' + di_calle+ ' ' + convert(varchar(100),di_descripcion) + ' ' + di_casa + di_codpostal)
                else (ltrim(di_barrio + ' ' + di_calle+ ' ' + di_casa + ' ' + convert(varchar(100),di_descripcion))) end
                  --PSO FIN Sincronización BOLIVARIANO
          from    cobis..cl_ente, cobis..cl_direccion
          where   en_ente = di_ente
          and en_ente = @i_ente
          and di_direccion = @i_direccion

          if @@rowcount = 0
          begin
             exec cobis..sp_cerror
                @t_debug  = @t_debug,
                @t_file   = @t_file,
                @t_from   = @w_sp_name,
                @i_num    = 1720074
               /* 'No existe dato solicitado'*/
             return 1
          end
    end


    if @i_tipo = 'B'
        if not exists ( select di_direccion
                        from cobis..cl_direccion
                        where di_ente = @i_ente
                        and di_principal = 'S')
        begin
           exec cobis..sp_cerror
              @t_debug  = @t_debug,
              @t_file   = @t_file,
              @t_from   = @w_sp_name,
              @i_num    = 1720101
              /* 'Debe existir una direccion principal'*/
           return 1
        end

        return 0
    end
   else
   begin
      exec cobis..sp_cerror
         @t_debug      = @t_debug,
         @t_file       = @t_file,
         @t_from       = @w_sp_name,
         @i_num        = 1720075
         /*  'No corresponde codigo de transaccion' */
      return 1
   end
end

/** Search **/
If @i_operacion = 'X'
begin
   if @t_trn = 172012
   begin
      if @i_tipo = 'A' or @i_tipo is null --PSO Sincronización
      begin --PSO Sincronización
         select  'No.'        = di_direccion,
                 'DIRECCION NO LOCAL / EDifICIO' = convert(varchar(255),(case when (@w_vu_pais = 'CR' and @w_vu_banco = 'HSBC')  then ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + convert(varchar(100),a.di_descripcion) + ' ' + a.di_casa + a.di_codpostal)     --Vivi CC00009
                                                   else ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + a.di_casa +' ' + convert(varchar(100),a.di_descripcion) ) end)) ,
                 'COD. PAIS'             = a.di_pais,
                 'NOMBRE PAIS'           = pa_descripcion,
                 'PROVINCIA'             = a.di_provincia,
                 'NOMBRE PROV.'          = pv_descripcion,
                 'COD. CANTON'           = a.di_ciudad, --a.di_canton se cambia por di_ciudad
                 'CANTON'                = substring(ci_descripcion,1,20), --substring(ca_descripcion,1,20),
                 'COD. DISTRITO'         = a.di_parroquia, --a.di_distrito,
                 'DISTRITO'              = substring(e.pq_descripcion,1,20), --substring(e.di_descripcion,1,20),
                 'COD. BARRIO'           = a.di_codbarrio,
                 'BARRIO'                = substring(ba_descripcion,1,20),
                 'OTRA SEÑAS'            = a.di_otrasenas,
                 'COD. TIPO DIR.'        = a.di_tipo,
                 'TIPO DIRECCION'        = substring(c.valor, 1, 20),
                 'OFICINA'               = a.di_oficina,
                 'DESC. OFICINA'         = substring(of_nombre,1,30),
                 'VERif.'                = a.di_verificado,
                 'PRINCIPAL'             = a.di_principal,
                 'DIR. COORRESPONDENCIA' = a.di_correspondencia,
                 'ALQUILADA'             = a.di_alquilada,
                 'MONTO ALQUILER'        = a.di_montoalquiler,
                 'DIR. COBRO'            = a.di_cobro,
                 'CALLE'                 = a.di_calle,
                 'CASA O APTO.'          = a.di_casa,
                 'EDifICIO'              = a.di_edificio,
                 'LOCALIDAD'             = a.di_localidad,
                 'DESC. LOCALIDAD'       = lo.lo_desc_localidad,
                     'LOCALIDAD COBIS'       = lo.lo_localidad
         from    
         cobis..cl_direccion a
             left join cobis..cl_ciudad      on  a.di_ciudad             = ci_ciudad
             left join cobis..cl_oficina     on  a.di_oficina            = of_oficina
             left join cobis..cl_barrio      on  a.di_codbarrio          = ba_barrio
             left join cobis..cl_parroquia e on  a.di_parroquia          = e.pq_parroquia --a.di_distrito  *= e.di_distrito
             left join cobis..cl_provincia   on  a.di_provincia          = pv_provincia
             left join cobis..cl_pais        on  convert(int,a.di_pais)  = pa_pais
             left join cobis..cl_localidad lo on a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,
         cobis..cl_catalogo c, cobis..cl_tabla d
         where  a.di_ente       = @i_ente
           and  a.di_tipo       = c.codigo
           and  c.tabla         = d.codigo
           and  d.tabla         = 'cl_tdireccion'
           order by di_direccion

         return 0
      end
   end
end

/** Search **/
if @i_operacion = 'P'
begin
   if @t_trn = 172012
   begin
      if @i_tipo = 'A' or @i_tipo is null --PSO Sincronización
      begin --PSO Sincronización

            set rowcount 20

            select  'No.'     = di_direccion,
                    'DIRECCION NO LOCAL / EDifICIO' = convert(varchar(255),(case when (@w_vu_pais = 'CR' and @w_vu_banco = 'HSBC')  then ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + convert(varchar(100),a.di_descripcion) + ' ' + a.di_casa + a.di_codpostal)  --Vivi CC00009
                                                      else ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + a.di_casa +' ' + convert(varchar(100),a.di_descripcion) ) end )),
                    'COD. PAIS'              = a.di_pais,
                    'NOMBRE PAIS'            = (select pa_descripcion from cobis..cl_pais where pa_pais = a.di_pais),
                    'PROVINCIA'              = a.di_provincia,
                    'NOMBRE PROV.'           = (select pv_descripcion from cobis..cl_provincia where pv_provincia = a.di_provincia),
                    'COD. CANTON'            = a.di_ciudad, --a.di_canton se cambia por di_ciudad
                    'CANTON'                 = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = a.di_ciudad),
                    'COD. DISTRITO'          = a.di_parroquia, --a.di_distrito,
                    'DISTRITO'               = (select pq_descripcion from cobis..cl_parroquia where pq_parroquia = a.di_parroquia and pq_ciudad = a.di_ciudad),
                    'COD. BARRIO'            = a.di_codbarrio,
                    'BARRIO'                 = (select ba_descripcion from cobis..cl_barrio where ba_barrio = a.di_codbarrio
                                                and ba_canton = a.di_ciudad and ba_distrito = a.di_parroquia),
                    'OTRA SEÑAS'             = a.di_otrasenas,
                    'COD. TIPO DIR.'         = a.di_tipo,
                    'TIPO DIRECCION'         = substring(c.valor, 1, 20),
                    'OFICINA'                = a.di_oficina,
                    'DESC. OFICINA'          = (select of_nombre from cobis..cl_oficina where of_oficina = a.di_oficina),
                    'VERif.'                 = a.di_verificado,
                    'PRINCIPAL'              = a.di_principal,
                    'DIR. COORRESPONDENCIA'  = a.di_correspondencia,
                    'ALQUILADA'              = a.di_alquilada,
                    'MONTO ALQUILER'         = a.di_montoalquiler,
                    'DIR. COBRO'             = a.di_cobro,
                    'CALLE'                  = a.di_calle,
                    'CASA O APTO.'           = a.di_casa,
                   'EDifICIO'                = a.di_edificio,
                    'DIR. COMERCIAL'         = a.di_so_igu_co,
                    'LOCALIDAD'              = a.di_localidad,
                    'DESC. LOCALIDAD'        = lo.lo_desc_localidad,
                    'LOCALIDAD COBIS'        = lo.lo_localidad
                from    cobis..cl_direccion a left join cobis..cl_localidad lo on a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,  
                        cobis..cl_catalogo c, cobis..cl_tabla d
                where  a.di_ente       = @i_ente
                  and  a.di_tipo       = c.codigo
                  and  c.tabla         = d.codigo
                  and  d.tabla         = 'cl_tdireccion'
                  and  a.di_direccion > @i_secuencial
                order by di_direccion
                return 0
        end


      --PSO SIncronización
      if @i_tipo = 'B'
      begin

            set rowcount 20
 
            select  'No.'         = a.di_direccion,
                    'DIRECCION NO LOCAL / EDifICIO' = convert(varchar(255),(case when (@w_vu_pais = 'CR' and @w_vu_banco = 'HSBC')  then
                                                     (case when pv_pais = @w_pais_ecuad then (ltrim(di_barrio + ' ' + convert(varchar(100),a.di_descripcion) ))
                                                      when pv_pais = @w_pais_local then (ltrim(g.pq_descripcion + ' ' + a.di_barrio + ' ' + a.di_calle+ ' ' + convert(varchar(100),a.di_descripcion) + ' ' + a.di_casa ))
                                                      else (ltrim(convert(varchar(100),a.di_descripcion) + ' ' + a.di_codpostal)) end )
                                                      else ltrim(a.di_barrio + ' ' + a.di_calle+ ' ' + a.di_casa + ' ' + convert(varchar(100),a.di_descripcion)) end )),
                    'COD. PAIS'             = a.di_pais,
                    'NOMBRE PAIS'           = pa_descripcion,
                    'PROVINCIA'             = a.di_provincia,
                    'NOMBRE PROV.'          = pv_descripcion,
                    'COD. CANTON'           = a.di_ciudad, --a.di_canton se cambia por di_ciudad
                    'CANTON'                = substring(ci_descripcion,1,20), --substring(ca_descripcion,1,20),
                    'COD. DISTRITO'         = a.di_parroquia, --a.di_distrito,
                    'DISTRITO'              = substring(g.pq_descripcion,1,20), --substring(g.di_descripcion,1,20),
                    'COD. BARRIO'           = a.di_codbarrio,
                    'BARRIO'                = substring(ba_descripcion,1,20),
                    'OTRA SEÑA'             = a.di_otrasenas,
                    'COD. TIPO DIR.'        = a.di_tipo,
                    'TIPO DIRECCION'        = substring(c.valor, 1, 20),
                    'OFICINA'               = a.di_oficina,
                    'DESC. OFICINA'         = substring(of_nombre,1,30),
                    'VERif.'                = a.di_verificado,
                    'PRINCIPAL'             = a.di_principal,
                    'DIR. COORRESPONDENCIA' = a.di_correspondencia,
                    'ALQUILADA'             = a.di_alquilada,
                    'MONTO ALQUILER'        = a.di_montoalquiler,
                    'DIR. COBRO'            = a.di_cobro,
                    'CALLE'                 = a.di_calle,
                    'CASA O APTO.'          = a.di_casa,
                    'ZIP CODE '             = a.di_codpostal,
                    'COD.ZONA/SECTOR'       = a.di_zona,
                    'ZONA/SECTOR '          = (select c1.valor from cobis..cl_catalogo c1, cobis..cl_tabla t1 where t1.tabla = 'cl_zona' and  c1.tabla = t1.codigo and c1.codigo        = a.di_zona),
                    'LOCALIDAD'             = a.di_localidad,
                    'DESC. LOCALIDAD'       = lo.lo_desc_localidad,
                         'LOCALIDAD COBIS'        = lo.lo_localidad
             from 
             cobis..cl_direccion a 
                 left join cobis..cl_ciudad        on  a.di_ciudad            = ci_ciudad
                 left join cobis..cl_oficina       on  a.di_oficina           = of_oficina
                 left join cobis..cl_barrio        on  a.di_codbarrio         = ba_barrio
                 left join cobis..cl_parroquia g on  a.di_parroquia         = g.pq_parroquia --a.di_distrito  *= g.di_distrito
                 left join cobis..cl_provincia   on  a.di_provincia         = pv_provincia
                 left join cobis..cl_pais          on  convert(int,a.di_pais) = pa_pais
                 left join cobis..cl_localidad lo on a.di_localidad = lo.lo_localidad and a.di_ciudad = lo.lo_ciudad,
             cobis..cl_catalogo c, cobis..cl_tabla d
    where  a.di_ente        = @i_ente
             and a.di_tipo        = c.codigo
             and    c.tabla          = d.codigo
             and    d.tabla          = 'cl_tdireccion'
             and   a.di_direccion > @i_secuencial
             order by di_direccion
              return 0
 
      end

   end
   --PSO FIN SIncronización
   else
   begin
      exec cobis..sp_cerror
         @t_debug      = @t_debug,
         @t_file       = @t_file,
         @t_from       = @w_sp_name,
         @i_num        = 1720075
        /* 'No corresponde codigo de transaccion' */
      return 1
   end
end

if @i_operacion = 'Y'
begin
   select di_ente, di_direccion, di_descripcion
   from cobis..cl_direccion
   where di_ente = @i_ente
   and di_tipo = 'CE'
   and di_direccion in (select max(di_direccion) 
                        from cobis..cl_direccion 
                        where di_ente = @i_ente 
                        and di_tipo = 'CE')
   if @@error != 0
   begin
      exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720464
         /*  'No existe dato solicitado'*/
      return 1
   end
end

GO

