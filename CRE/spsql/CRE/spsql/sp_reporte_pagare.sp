/************************************************************************/
/*   Archivo            :        reppag.sp                              */
/*   Stored procedure   :        sp_reporte_pagare                      */
/*   Base de datos      :        cob_credito                            */
/*   Producto           :        Credito                                */
/*   Disenado por                Bruno Duenas                           */
/*   Fecha de escritura :        Dic. 22                                */
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
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Obtener los datos necesarios para el reporte de Pagare Individual  */
/*   o grupal                                                           */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* Dic/20/2022    Bruno Duenas     Emision inicial                      */
/* Dic/28/2022    Dilan Morales    Se completa operacion C              */
/* Mar/16/2023    Dilan Morales    Se corrige obtencion de direccion    */
/* Mar/23/2023    Dilan Morales    Se corrige obtencion muncipio        */
/* Jun/20/2023    Bruno Duenas     Se corrige oficina por ciudad        */
/* Ago/23/2023    Dilan Morales    R214026-Se corrige lo observado por  */
/*                                 ENL                                  */
/* Sep/13/2023    Patricia Jarrin  B903397-R215234-Se agrega fecha fin  */
/* Oct/02/2023    Patricia Jarrin  B911932-R216404-Se modifica direccion*/
/* Oct/24/2023    Bruno Duenas     R217743 - Se agrega tasa mensual     */
/* Oct/26/2023    Bruno Duenas     R217743 - Se evita tasa negativa     */
/* Nov/16/2023    Bruno Duenas     R219497:Se agrega apellido casada    */
/* Abr/24/2024    Dilan Morales    R233298:Se añade nuevos @o           */
/* Dic/12/2024    Oscar Diaz       R251298:IMPRESIÓN DE PAGARÉS         */
/************************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_reporte_pagare')
   drop proc sp_reporte_pagare  
go

create proc sp_reporte_pagare (
   @t_show_version   bit       = 0, -- Mostrar la version del programa
   @s_ssn            int                = NULL,
   @s_user           login              = NULL,
   @s_sesn           int                = NULL,
   @s_term           varchar(30)        = NULL,
   @s_date           datetime           = NULL,
   @s_srv            varchar(30)        = NULL,
   @s_lsrv           varchar(30)        = NULL,
   @s_rol            smallint           = NULL,
   @s_ofi            smallint           = NULL,
   @s_org_err        char(1)            = NULL,
   @s_error          int                = NULL,
   @s_sev            tinyint            = NULL,
   @s_msg            descripcion        = NULL,
   @s_org            char(1)            = NULL,
   @t_debug          char(1)            = 'N',
   @t_file           varchar(14)        = null,
   @t_from           varchar(32)        = null,
   @t_trn            smallint           = NULL,
   @i_tramite        int,
   @i_operacion      char(1),
   @o_montoLetras    varchar(200)       = NULL   OUT,
   @o_fechaLetras    varchar(200)       = NULL   OUT,
   @o_maxSeguro      varchar(200)       = NULL   OUT,
   @o_tasaIMO        varchar(200)       = NULL   OUT,
   @o_tasaINT        varchar(200)       = NULL   OUT,
   @o_monto          varchar(50)        = NULL   OUT,
   @o_cobertura      varchar(200)       = NULL   OUT,
   @o_oficina        varchar(100)       = NULL   OUT,
   @o_nom_grupo      varchar(100)       = NULL   OUT,
   @o_nom_presi      varchar(150)       = NULL   OUT,
   @o_fecha_ini      varchar(10)        = NULL   OUT,
   @o_filial         varchar(150)       = NULL   OUT,
   @o_tasaMensual    varchar(200)       = NULL   OUT,
   @o_edad_seguro_muerte varchar(200)   = NULL   OUT,
   @o_edad_seguro_invalidez varchar(200)= NULL   OUT,
   @o_monto_reclamo varchar(200)        = NULL   OUT
   
)
as

declare @w_sp_name              varchar(32),
        @w_monto_letras         varchar(500),
        @w_monto                money,
        @w_fecha_inicio         varchar(10),
        @w_fecha_fin            varchar(10),
        @w_fecha_inicio_letras  varchar(150),
        @w_maxSeguro            varchar(500),
        @w_tasaIMO              varchar(10),
        @w_tasaINT              varchar(10),
        @w_tasaIMO_letras       varchar(200),
        @w_tasaINT_letras       varchar(200),
        @w_coberturaPoliza      varchar(200),
        @w_oficina              varchar(200),
        @w_nombre_grupo         varchar(100),
        @w_nombre_presidente    varchar(400),
        @w_filial               varchar(200),
        @w_operacion            varchar(20),
        @w_moneda               int,
        @w_grupal               char(1),
        @w_cliente              int,
        @w_grupo                int,
        @w_error                int,
        @w_tasaMes              varchar(10),
        @w_tasaMesFloat         float,
        @w_tasaMesLetras        varchar(200),
        @w_edad_seguro_muerte_param   tinyint,
        @w_edad_seguro_invalidez_param tinyint,
        @w_monto_reclamo_param        money,
        @w_edad_seguro_muerte   varchar(200),
        @w_edad_seguro_invalidez varchar(200),
        @w_monto_reclamo        varchar(200)


--tabla para consulta de participantes
declare @w_tabla_usuarios as table(
                                  nombre_completo      varchar(255),
                                  tipo_identificacion  varchar(50),
                                  num_identificacion   varchar(50),
                                  direccion            varchar(255),
                                  ciudad               varchar(50),
                                  rol                  char(1),
                                  id                   int,
                                  orden                int default 0)


select @w_sp_name = 'sp_reporte_pagare'
if @t_show_version = 1
begin
   print 'Stored procedure sp_reporte_pagare, Version 1.0.0'
end

if @t_trn <> 21855 --Aun no defino el numero de trn
begin
exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file = @t_file,
   @t_from = @w_sp_name,
   @i_num = 151051
   /* 'No corresponde codigo de transaccion' */
   return 151051
end
/* Buscar parametros */
select @w_maxSeguro = pa_char 
from cobis..cl_parametro 
where pa_nemonico = 'MAXSEG' 
and pa_producto = 'CRE'
if @@rowcount = 0
begin
   select @w_error = 2110246
   goto ERROR
end

select @w_coberturaPoliza = pa_char 
from cobis..cl_parametro 
where pa_nemonico = 'PRCOPO' 
and pa_producto = 'CRE'
if @@rowcount = 0
begin
   select @w_error = 2110246
   goto ERROR
end


select @w_edad_seguro_muerte_param = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'EDOPSD' 
and pa_producto = 'CCA'
if @@rowcount = 0
begin
   select @w_error = 2110246
   goto ERROR
end

select @w_edad_seguro_invalidez_param = pa_tinyint 
from cobis..cl_parametro 
where pa_nemonico = 'EDINSD' 
and pa_producto = 'CCA'
if @@rowcount = 0
begin
   select @w_error = 2110246
   goto ERROR
end

select @w_monto_reclamo_param = pa_money
from cobis..cl_parametro 
where pa_nemonico = 'MOREAD' 
and pa_producto = 'CCA'
if @@rowcount = 0
begin
   select @w_error = 2110246
   goto ERROR
end



/* Buscar el nomero de operacion */
select @w_operacion = op_operacion,
       @w_moneda    = op_moneda,
       @w_cliente   = op_cliente,
       @w_grupal    = op_grupal
from cob_cartera..ca_operacion
where op_tramite = @i_tramite
if @@rowcount = 0
begin
   select @w_error = 2110185
   goto ERROR
end

if @i_operacion = 'D' /* Datos de la operaci©n */
begin

   select @w_tasaIMO = ro_porcentaje --/12 ODI_Requerimiento #251298
   from cob_cartera.dbo.ca_rubro_op 
   where ro_concepto = 'IMO' 
   AND ro_operacion = @w_operacion
   if @@rowcount = 0
   begin
      select @w_error = 2110246
      goto ERROR
   end
   
   select @w_tasaINT = ro_porcentaje --/12 ODI_Requerimiento #251298
   from cob_cartera.dbo.ca_rubro_op
   where ro_concepto = 'INT' 
   AND ro_operacion = @w_operacion
   if @@rowcount = 0
   begin
      select @w_error = 2110246
      goto ERROR
   end
   
   select @w_tasaMesFloat = convert(float,@w_tasaIMO) - convert(float,@w_tasaINT)
   
   if @w_tasaMesFloat < 0
   begin
      select @w_tasaMesFloat = 0 --No existe una tasa negativa
   end
   
   
   select @w_tasaMes = convert(varchar,@w_tasaMesFloat)
    
    if exists( select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
         select @w_monto       = ca.op_monto,
          @w_oficina           = cc.ci_descripcion,
          @w_filial            = cf.fi_nombre,
          @w_nombre_grupo      = cg.gr_nombre,
          @w_nombre_presidente = case when ce.en_nomlar not like '%' + ce.p_c_apellido + '%' then ce.en_nomlar + ' ' + isnull(ce.p_c_apellido,'') --AGREGAR CUANDO NO ESTE
                                 else ce.en_nomlar --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
                                 end,
          @w_fecha_inicio      = convert(varchar, FORMAT(ca.op_fecha_ini, 'dd/MM/yyyy')),
          @w_fecha_fin         = convert(varchar, FORMAT(ca.op_fecha_fin, 'dd/MM/yyyy'))
    
        from cob_cartera..ca_operacion ca,
             cobis..cl_oficina co,
             cobis..cl_grupo cg,
             cobis..cl_filial cf,
             cobis..cl_ente ce,
             cobis.dbo.cl_ciudad cc 
        where ca.op_operacion = @w_operacion and
              ca.op_oficina   = co.of_oficina and
              co.of_ciudad    = cc.ci_ciudad and
              co.of_filial    = cf.fi_filial and
              ca.op_grupo     = cg.gr_grupo and
              ce.en_ente      = cg.gr_representante
    end
    else
    begin
    
    select @w_monto            = ca.op_monto,
          @w_oficina           = cc.ci_descripcion,
          @w_filial            = cf.fi_nombre,
          @w_nombre_grupo      = ca.op_nombre,
          @w_nombre_presidente = case when ce.en_nomlar not like '%' + ce.p_c_apellido + '%' then ce.en_nomlar + ' ' + isnull(ce.p_c_apellido,'') --AGREGAR CUANDO NO ESTE
                                 else ce.en_nomlar --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
                                 end,
          @w_fecha_inicio      = convert(varchar, FORMAT(ca.op_fecha_ini, 'dd/MM/yyyy')),
          @w_fecha_fin         = convert(varchar, FORMAT(ca.op_fecha_fin, 'dd/MM/yyyy'))
    
        from cob_cartera..ca_operacion ca,
             cobis..cl_oficina co,
             cobis..cl_filial cf,
             cobis..cl_ente ce,
             cobis.dbo.cl_ciudad cc
        where ca.op_operacion = @w_operacion and
              ca.op_oficina   = co.of_oficina and
              co.of_ciudad    = cc.ci_ciudad and
              co.of_filial    = cf.fi_filial and
              ca.op_cliente   = ce.en_ente
    
    end
         
         
    
    exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 5,
        @i_dinero  = @w_tasaIMO,
        @o_letras  = @w_tasaIMO_letras out /* valor en letras */

   exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 5,
        @i_dinero  = @w_tasaINT,
        @o_letras  = @w_tasaINT_letras out /* valor en letras */        
   
   exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 5,
        @i_dinero  = @w_tasaMes,
        @o_letras  = @w_tasaMesLetras out /* valor en letras */ 
   
   exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 4,
        @i_dinero  = @w_monto,
        @i_moneda  = @w_moneda,
        @o_letras  = @w_monto_letras out /* valor en letras */
        
    exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 6,
        @i_fecha   = @w_fecha_inicio,
        @o_letras  = @w_fecha_inicio_letras out /* valor en letras */
    
    exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 3,
        @i_moneda  = @w_moneda,
        @i_dinero  = @w_monto_reclamo_param,
        @o_letras  = @w_monto_reclamo out /* valor en letras */
        
    exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 3,
        @i_moneda  = @w_moneda,
        @i_dinero  = @w_edad_seguro_invalidez_param,
        @o_letras  = @w_edad_seguro_invalidez out /* valor en letras */
        
    exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 3,
        @i_moneda  = @w_moneda,
        @i_dinero  = @w_edad_seguro_muerte_param,
        @o_letras  = @w_edad_seguro_muerte out /* valor en letras */
   
   --devolver los datos
   select @o_montoLetras    = trim(@w_monto_letras),
          @o_fechaLetras    = trim(@w_fecha_inicio_letras),
          @o_maxSeguro      = trim(@w_maxSeguro),
          @o_tasaIMO        = trim(@w_tasaIMO_letras),
          @o_tasaINT        = trim(@w_tasaINT_letras),
          @o_tasaMensual    = trim(@w_tasaMesLetras),
          @o_monto          = trim(convert(varchar, FORMAT(@w_monto, 'C'))),          
          @o_cobertura      = trim(@w_coberturaPoliza),
          @o_oficina        = trim(@w_oficina),
          @o_nom_grupo      = trim(@w_nombre_grupo),
          @o_nom_presi      = trim(@w_nombre_presidente),
          @o_fecha_ini      = trim(@w_fecha_fin),
          @o_filial         = trim(@w_filial),
          @o_monto_reclamo  = trim(@w_monto_reclamo),
          @o_edad_seguro_muerte  = trim(@w_edad_seguro_muerte),
          @o_edad_seguro_invalidez  = trim(@w_edad_seguro_invalidez)
      
      select @o_montoLetras,
             @o_fechaLetras,
             @o_maxSeguro,
             @o_tasaIMO,
             @o_tasaINT,
             @o_monto,
             @o_cobertura,
             @o_oficina,
             @o_nom_grupo,
             @o_nom_presi,
             @o_fecha_ini,
             @o_filial,
             @o_tasaMensual,
             @o_monto_reclamo,
             @o_edad_seguro_invalidez,
             @o_edad_seguro_muerte
      
end

if @i_operacion = 'C' /* Datos de los clientes de la operaci©n */
begin

    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
        select @w_grupo = tr_grupo  from cob_credito..cr_tramite where tr_tramite   = @i_tramite
            
        insert into @w_tabla_usuarios
        (nombre_completo,
        tipo_identificacion, 
        num_identificacion, 
        direccion, 
        ciudad,                 
        id)
        select 
        case when ce.en_nomlar not like '%' + ce.p_c_apellido + '%' then ce.en_nomlar + ' ' + isnull(ce.p_c_apellido,'') --AGREGAR CUANDO NO ESTE
                                 else ce.en_nomlar --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
                                 end,
        en_tipo_ced,           
        en_ced_ruc,   
        (select top 1 isnull(trim(di_conjunto), ' ') + ', ' + isnull(trim(di_piso), ' ') + ', ' + isnull(trim(di_numero_casa), ' ') from cobis..cl_direccion where di_ente = en_ente and di_principal = 'S' and di_tipo = 'RE'),
        (isnull( (select top 1 C.valor from cobis..cl_catalogo C with(nolock)
            inner join cobis..cl_tabla  T with(nolock) on C.tabla = T.codigo
            inner join cobis..cl_direccion with(nolock) on C.codigo = di_ciudad
            where di_ente = en_ente and di_tipo = 'RE'
            and T.tabla = 'cl_ciudad')+ ', ', '')
        + isnull((select top 1  pv_descripcion from cobis..cl_direccion , cobis..cl_provincia  where pv_provincia = di_provincia and di_ente = en_ente), '')
        ),   
        en_ente
        from cobis..cl_ente ce,
        cob_credito..cr_tramite_grupal  
        where  tg_tramite = @i_tramite 
        and tg_participa_ciclo = 'S'        
        and en_ente = tg_cliente
        
        
        update @w_tabla_usuarios
        set rol = (select cg_rol from cobis..cl_cliente_grupo with(nolock) where  cg_ente = id and cg_grupo = @w_grupo)
        
        update @w_tabla_usuarios
        set orden = 1
        where rol = 'P'
        
        update @w_tabla_usuarios
        set orden = 2
        where rol not in ('P' , 'M')
        
        update @w_tabla_usuarios
        set orden = 3
        where rol = 'M'

    end 
    else
    begin
     
        insert into @w_tabla_usuarios
        (nombre_completo,
        tipo_identificacion, 
        num_identificacion, 
        direccion, 
        ciudad,                 
        rol,
        id)
        select 
        case when ce.en_nomlar not like '%' + ce.p_c_apellido + '%' then ce.en_nomlar + ' ' + isnull(ce.p_c_apellido,'') --AGREGAR CUANDO NO ESTE
                                 else ce.en_nomlar --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
                                 end,
        en_tipo_ced,           
        en_ced_ruc,   
        (select top 1 isnull(trim(di_conjunto), ' ') + ', ' + isnull(trim(di_piso), ' ') + ', ' + isnull(trim(di_numero_casa), ' ') from cobis..cl_direccion where di_ente = en_ente and di_principal = 'S' and di_tipo = 'RE'),
        (isnull( (select top 1 C.valor from cobis..cl_catalogo C with(nolock)
            inner join cobis..cl_tabla  T with(nolock) on C.tabla = T.codigo
            inner join cobis..cl_direccion with(nolock) on C.codigo = di_ciudad
            where di_ente = en_ente and di_tipo = 'RE'
            and T.tabla = 'cl_ciudad')+ ', ', '')
        + isnull((select top 1  pv_descripcion from cobis..cl_direccion , cobis..cl_provincia  where pv_provincia = di_provincia and di_ente = en_ente), '')
        ),  
        de_rol,
        en_ente
        from cobis..cl_ente ce,
        cob_credito..cr_deudores 
        where de_tramite = @i_tramite and en_ente = de_cliente

        --SE AÑADE GARANTES                                     
       insert into @w_tabla_usuarios
        (nombre_completo,
        tipo_identificacion, 
        num_identificacion, 
        direccion, 
        ciudad,                 
        rol,
        id)
        select 
        case when ce.en_nomlar not like '%' + ce.p_c_apellido + '%' then ce.en_nomlar + ' ' + isnull(ce.p_c_apellido,'') --AGREGAR CUANDO NO ESTE
                                 else ce.en_nomlar --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
                                 end,
        en_tipo_ced,           
        en_ced_ruc,   
        (select top 1 isnull(trim(di_conjunto), ' ') + ', ' + isnull(trim(di_piso), ' ') + ', ' + isnull(trim(di_numero_casa), ' ') from cobis..cl_direccion where di_ente = en_ente and di_principal = 'S' and di_tipo = 'RE'),
        (select top 1  pv_descripcion from cobis..cl_direccion , cobis..cl_provincia  where pv_provincia = di_provincia and di_ente = en_ente),         
        'X',
        en_ente   
        from cob_custodia..cu_custodia  , cob_credito..cr_gar_propuesta , cobis..cl_ente ce
        where  cu_codigo_externo = gp_garantia 
        and gp_tramite = @i_tramite  
        and cu_garante is not null
        and  en_ente = cu_garante
        
        
        update @w_tabla_usuarios
        set orden = 1
        where rol = 'D'
        
        update @w_tabla_usuarios
        set orden = 2
        where rol  = 'C'
        
        update @w_tabla_usuarios
        set orden = 3
        where rol not in ('D' , 'C')
        
        update @w_tabla_usuarios
        set orden = 4
        where rol = 'X'
    end
    
    select * from @w_tabla_usuarios order by orden asc 

end

return 0

ERROR:
   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null,
      @t_from  = @w_sp_name,
      @i_num   = @w_error
   return @w_error

go
