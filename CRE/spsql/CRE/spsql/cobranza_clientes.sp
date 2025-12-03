/********************************************************************/
/*   NOMBRE LOGICO:         cobranza_clientes                       */
/*   NOMBRE FISICO:         cobranza_clientes.sp                    */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          D. Morales                              */
/*   FECHA DE ESCRITURA:    17-Mar-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Se registran los clientes que aplican para cobranza            */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA             AUTOR              RAZON                     */
/*   17-Mar-2023     D. Morales.      Emision Inicial               */
/*   29-Abr-2023     D. Morales.      Se añade logica para grupal   */
/*   03-May-2023     D. Morales.      Eliminacion de registros      */
/*                                    ingresados el mismo dia       */
/*   05-Jun-2023     P. Jarrin.       Ajustes Review  - S834613     */
/*   27-Jun-2023     B. Dueñas.       Se agrega saldo operacion     */
/*   17-Ago-2023     D. Morales.      Se actualiza saldo con el     */
/*                                    sp_interfaz_pago_ws_enl       */
/*   09-Nov-2023     D. Morales.      R219021:Se cambia condición   */
/*                                    para dividendos vencidos      */
/*   20-Nov-2023     D. Morales.      R219679:Se valida fecha al    */
/*                                    insertar operacion grupal     */
/*   15-May-2024     B. Dueñas.       R233500: Se usa fecha proceso */
/********************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'cobranza_clientes')
begin
   drop proc cobranza_clientes
end   
go

create procedure cobranza_clientes
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_fecha_actual             date,
        @w_error                    int,    
        @w_variables                varchar(64),
        @w_return_variable          varchar(25),
        @w_return_results           varchar(25),
        @w_last_condition_parent    varchar(10),
        @w_return_results_rule      varchar(25),
        @w_id                       int,
        @w_id_cliente               int,
        @w_tramite                  int,
        @w_num_operacion            int,
        @w_num_op_banco             varchar(24),
        @w_toperacion               varchar(10),
        @w_grupo                    int,
        @w_ref_op_padre             varchar(24),
        @w_id_oficina               int,
        @w_promedio_mora            int,
        @w_porcentaje_pag           int,
        @w_monto_total              money,
        @w_capital_pag              money,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_correo_oficial           varchar(200),
        @w_path                     varchar(254),
        @w_nom_ofi                  varchar (254),
        @w_id_funcionario           int,
        @w_banco                    varchar(24),
        @w_reference                varchar(24),
        @w_amounttopay              money,
		@w_id_max                   int,
		@w_id_contador              int

        
-- Información proceso batch

select @w_termina = 0

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..cobranza_clientes%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end
       
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente like '%cob_credito..cobranza_clientes%'

--Parametros
select @w_tiempo = isnull(pa_int, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBHCC'
and pa_producto   = 'CRE'


select @w_fecha_actual = convert(date, fp_fecha)
from cobis..ba_fecha_proceso

--Limpieza de la carpeta
declare @w_path_del varchar(100)
set @w_path_del = 'del /Q ' + @w_path +'\clientes_cobranza_*.*'
EXEC master.dbo.xp_cmdshell @w_path_del

--Limpieza de la tabla segun tiempo de validez
delete from cr_cobranza_tmp
where ct_fecha < dateadd(day, @w_tiempo * -1, @w_fecha_actual) or ct_fecha = @w_fecha_actual

delete from cr_cobranza_det_tmp 
where cdt_fecha < dateadd(day, @w_tiempo * -1, @w_fecha_actual) or cdt_fecha = @w_fecha_actual


--1. SE INSERTA TODA LA DATA REQUERIDA DE CREDITOS VENCIDOS
--PQU añadir a la tabla cr_cobranza_tmp un campo para saber cuál es la operación grupal.
insert into cr_cobranza_tmp
(ct_num_banco,              ct_num_operacion,   ct_ente,    ct_grupo,   ct_oficina, ct_fecha,           ct_ref_grupal, ct_op_grupal)  --PQU referencia grupal añadí
select 
op_banco,                   op_operacion ,      op_cliente, op_grupo,   op_oficina, @w_fecha_actual,    op_ref_grupal, 'N'  --PQU añadi el N para indicar que no es una operacicón grupal
from cob_cartera..ca_operacion with (NOLOCK)
where  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
and op_operacion in (select am_operacion 
                     from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
                     where di_estado = 2 
					 and am_operacion = di_operacion 
					 and am_dividendo = di_dividendo 
					 and am_concepto  = 'CAP' 
					 and (am_cuota - am_pagado + am_gracia) > 0 )				
and op_estado not in (0,99,3,4, 6)


--NOMBRE GRUPO                      
update cr_cobranza_tmp
set ct_nombre_grupo = (select gr_nombre from cobis..cl_grupo where gr_grupo = ct_grupo) 
where ct_grupo > 0
and ct_fecha = @w_fecha_actual
                          
--NOMBRE COMPLETO
update cr_cobranza_tmp
set ct_nombre_cliente = (select isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(p_c_apellido,'') --PQU
                        from cobis..cl_ente where en_ente = ct_ente)
where ct_fecha = @w_fecha_actual	
						
--TELEFONO
update cr_cobranza_tmp
set ct_numero_telf = (select ea_telef_recados from cobis..cl_ente_aux
                        where ea_ente = ct_ente  )
where ct_fecha = @w_fecha_actual					

--DIRRECCION
update cr_cobranza_tmp
set ct_direccion_negocio = (select top 1 isnull(di_descripcion + '|', '') + isnull(convert(varchar,dg_lat_seg) + '|' , '') + isnull(convert(varchar,dg_long_seg) , '')
                            from cobis..cl_direccion 
                            inner join cobis..cl_direccion_geo on dg_ente= di_ente and dg_direccion =  di_direccion
                            where di_tipo = 'AE' and di_ente = ct_ente  )
where ct_fecha = @w_fecha_actual							
                        

--NUMNERO DE DIVIDENDOS VENCIDOS
update cr_cobranza_tmp
set ct_dividendos_venc  = ( select count(distinct am_dividendo) 
						    from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
						    where di_estado = 2 
						    and am_operacion = ct_num_operacion
						    and am_operacion = di_operacion 
						    and am_dividendo = di_dividendo 
						    and am_concepto  = 'CAP' 
						    and (am_cuota - am_pagado + am_gracia) > 0 )
where ct_fecha = @w_fecha_actual							


--DIVIDENDOS VENCIDOS
insert into cr_cobranza_det_tmp
(cdt_num_banco,     cdt_num_operacion,      cdt_dividendo,	cdt_fecha)
select 
ct_num_banco,       ct_num_operacion,       a.am_dividendo,	@w_fecha_actual
from (select am_operacion, am_dividendo
from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
where di_estado = 2 
and am_operacion = di_operacion 
and am_dividendo = di_dividendo 
and am_concepto  = 'CAP' 
and (am_cuota - am_pagado + am_gracia) > 0 
)a
inner join  cr_cobranza_tmp on a.am_operacion = ct_num_operacion
where ct_fecha = @w_fecha_actual
group by ct_num_banco, ct_num_operacion, a.am_dividendo

--FEHCA DE VENCIMIENTO DE CADA DIVIDENDO
update cr_cobranza_det_tmp
set cdt_fecha_venc = (select di_fecha_ven from cob_cartera..ca_dividendo where di_operacion  = cdt_num_operacion and di_dividendo = cdt_dividendo )
where cdt_fecha = @w_fecha_actual

--CAPITAL VENCIDO
update cr_cobranza_det_tmp
set cdt_monto_capital =isnull((select sum(am_acumulado - am_pagado + am_gracia ) 
                        from cob_cartera..ca_amortizacion
                        inner join cob_cartera..ca_dividendo on di_operacion = am_operacion and di_dividendo = am_dividendo
                        where am_operacion = cdt_num_operacion  
                        and am_dividendo = cdt_dividendo 
                        and di_estado = 2
                        and am_concepto = 'CAP') , 0 )
where cdt_fecha = @w_fecha_actual
						
--INTERES VENCIDO                       
update cr_cobranza_det_tmp
set cdt_monto_interes = isnull((select sum(am_acumulado - am_pagado + am_gracia )
                        from cob_cartera..ca_amortizacion
                        inner join cob_cartera..ca_dividendo on di_operacion = am_operacion and di_dividendo = am_dividendo
                        where am_operacion = cdt_num_operacion  
                        and am_dividendo = cdt_dividendo 
                        and di_estado = 2
                        and am_concepto = 'INT') , 0)
where cdt_fecha = @w_fecha_actual
						
--OTROS RUBROS VENCIDO
update cr_cobranza_det_tmp
set cdt_monto_otros_rubros =isnull((select sum(am_acumulado - am_pagado + am_gracia )
                        from cob_cartera..ca_amortizacion
                        inner join cob_cartera..ca_dividendo on di_operacion = am_operacion and di_dividendo = am_dividendo
                        where am_operacion = cdt_num_operacion  
                        and am_dividendo = cdt_dividendo 
                        and di_estado = 2
                        and am_concepto not in ('INT', 'CAP')),0)  
where cdt_fecha = @w_fecha_actual						
                          
--PQU Insertar las operaciones grupales
insert into cr_cobranza_tmp
(ct_num_banco,              ct_num_operacion,   ct_ente,    ct_grupo,   ct_oficina, ct_fecha,       ct_ref_grupal, ct_op_grupal,
 ct_nombre_grupo,           
 ct_nombre_cliente, 
 ct_direccion_negocio)  --PQU referencia grupal añadí
select  
op_banco,                   op_operacion ,      op_grupo,   op_grupo,   op_oficina, @w_fecha_actual, null,          'S',  --PQU añadi S para indicar que es una operacicón grupal
       (select gr_nombre from cobis..cl_grupo where gr_grupo = op_grupo),
       (select gr_nombre from cobis..cl_grupo where gr_grupo = op_grupo),
       (select gr_dir_reunion from cobis..cl_grupo where gr_grupo = op_grupo)
from    cob_cartera..ca_operacion with (NOLOCK)
where   op_banco in (select ct_ref_grupal from cr_cobranza_tmp where ct_fecha = @w_fecha_actual)


insert into cr_cobranza_det_tmp
(cdt_num_banco,     cdt_num_operacion,      cdt_dividendo, cdt_fecha )
select 
ct_num_banco,       ct_num_operacion,        1,				@w_fecha_actual
from cr_cobranza_tmp
where   ct_ref_grupal  is null
and  ct_op_grupal = 'S'
and ct_fecha = @w_fecha_actual

--MONTOS Y DIVIDENDOS VENCIDOS GRUPAL
update a
set a.cdt_monto_capital         = b.capital,
    a.cdt_monto_interes         = b.interes,
    a.cdt_monto_otros_rubros    = b.otros
from cr_cobranza_det_tmp a
inner join 
(   select 
        padre.ct_num_operacion,
        sum(cdt_monto_capital) capital, 
        sum(cdt_monto_interes) interes, 
        sum(cdt_monto_otros_rubros) otros
    from cr_cobranza_tmp hija
    inner join cr_cobranza_tmp  padre on hija.ct_ref_grupal  = padre.ct_num_banco and hija.ct_fecha = padre.ct_fecha
    inner join cr_cobranza_det_tmp ccdt  on cdt_num_operacion  = hija.ct_num_operacion and cdt_fecha = hija.ct_fecha
	where cdt_fecha = @w_fecha_actual
    group by padre.ct_num_operacion) b
on a.cdt_num_operacion = b.ct_num_operacion
where  a.cdt_dividendo = 1 
and a.cdt_fecha = @w_fecha_actual

update a
set a.ct_dividendos_venc = b.dividendos_venc
from cr_cobranza_tmp a
inner join 
(   select 
        ct_ref_grupal,
        max(ct_dividendos_venc) dividendos_venc 
    from cr_cobranza_tmp
    where ct_ref_grupal is not null
	and ct_fecha = @w_fecha_actual
    group by ct_ref_grupal) b
on a.ct_num_banco  = b.ct_ref_grupal
where a.ct_fecha = @w_fecha_actual


create table #tmp_operaciones (
   id                  int identity(1,1),
   num_operacion       int,
   num_banco           varchar(24)
)

insert into #tmp_operaciones
(num_operacion, num_banco)
select
ct_num_operacion, ct_num_banco
from cr_cobranza_tmp
where ct_fecha = @w_fecha_actual

--SALDO DE LA OPERACION GRUPAL E INDIVIDUAL
select @w_id_max = max(id)
from #tmp_operaciones

select @w_id_contador = 1

while @w_id_contador <= @w_id_max
begin
   select @w_banco = null,
		  @w_num_operacion = null
   
   select @w_banco = num_banco,
          @w_num_operacion = num_operacion
    from #tmp_operaciones
	where id = @w_id_contador

   exec @w_error        = cob_cartera..sp_interfaz_pago_ws_enl 
   @i_canal             = 3,
   @i_operacion         ='Q', --operación de consulta
   @i_idcolector        = 0,
   --@i_numcuentacolector = '',
   @i_idreferencia      = '0',
   @i_reference         = @w_banco , --op_banco
   @i_amounttopay       = 0,
   @o_amounttopay       = @w_amounttopay out,
   @o_reference         = @w_reference out
   
   if(@w_error <> 0)
   begin
    select @w_amounttopay  = 0
   end

   update cr_cobranza_tmp
   set ct_saldo = isnull(@w_amounttopay , 0)
   where ct_num_banco = @w_banco
   and ct_fecha = @w_fecha_actual
   
   --Siguiente registro
   select @w_id_contador = @w_id_contador + 1
end



--2. SE RECORRE TODAS LAS OFICINAS DONDE EXISTAN CREDITOS VENCIDOS
if (OBJECT_ID('tempdb.dbo.#tmp_oficinas','U')) is not null
begin
    drop table #tmp_oficinas
end

create table #tmp_oficinas (
id_oficina      int         null
)

insert into #tmp_oficinas
(id_oficina)
select distinct
ct_oficina
from cr_cobranza_tmp
where ct_fecha = @w_fecha_actual

select @w_id_oficina = min(id_oficina) from tempdb.dbo.#tmp_oficinas
while @w_id_oficina is not NULL
begin
    select @w_nom_ofi  = null 
    
    select @w_nom_ofi = of_nombre from cobis..cl_oficina where of_oficina = @w_id_oficina
    
    --3. SE CREA LA TABLA PARA EL REPORTE A ENVIAR
    if (OBJECT_ID('tempdb..##tmp_info')) is not null
    begin
        drop table ##tmp_info
    end
    
    create table ##tmp_info (
        num_banco           varchar(254)   null,
        cod_cliente         varchar(254)   null,
        nom_cliente         varchar(254)   null,
        cod_grupo           varchar(254)   null,
        nom_grupo           varchar(254)   null,
        ref_grupal          varchar(254)   null,
        grupal              varchar(254)   null,
        num_dividendos      varchar(254)   null,
        direccion           varchar(254)   null,  
        telefono            varchar(254)   null,  
        num_dividendo       varchar(254)   null,
        fecha_ven           varchar(254)   null,
        capital             varchar(254)   null,
        interes             varchar(254)   null,
        otros               varchar(254)   null
    )
    
    
    --4. INSERT CABECERA DEL REPORTE
    insert into ##tmp_info
    (num_banco,                 cod_cliente,                nom_cliente,            cod_grupo,          nom_grupo,      
    ref_grupal,                 grupal,                     num_dividendos,         direccion,          telefono,               
    num_dividendo,              fecha_ven,                  capital,                interes,            otros)
    select 
    'Fecha:',           convert(varchar, getdate(), 103),   null,                   null,               null,           
    null,                       null,                       'Oficina:',             @w_nom_ofi,         null,
    null,                       null,                       null,                   null,               null
    
    insert into ##tmp_info
    (num_banco,                 cod_cliente,                nom_cliente,            cod_grupo,          nom_grupo,      
    ref_grupal,                 grupal,                     num_dividendos,         direccion,          telefono,               
    num_dividendo,              fecha_ven,                  capital,                interes,            otros)
    select 
    'REPORTE PARA COBRANZAS',   null,                       null,                   null,               null,           
    null,                       null,                       null,                   null,               null,
    null,                       null,                       null,                   null,               null
    
    insert into ##tmp_info
    (num_banco,                 cod_cliente,                nom_cliente,            cod_grupo,          nom_grupo,      
    ref_grupal,                 grupal,                     num_dividendos,         direccion,          telefono,               
    num_dividendo,              fecha_ven,                  capital,                interes,            otros)
    select 
    'NRO OPERACION',            'COD CLIENTE',              'NOMBRE CLIENTE',       'COD GRUPO',                'NOMBRE GRUPO', 
    'NRO OPERACION GRUPAL',     'ES GRUPAL',                'DIVIDENDOS VENCIDOS',  'DIRECCION NEGOCIO',        'TELEFONO PRINCIPAL',   
    'NRO DIVIDENDO',    'FECHA DE VENCIMIENTO',             'MONTO CAPITAL ADEUDADO','MONTO INTERES ADEUDADO',  'MONTO OTROS RUBROS ADEUDADO'
    
    
    
    --5. SE RECORREO TODOS LAS OPERACIONES VENCIDAS PARA MOSTRAR EN EL REPORTE 
    if (OBJECT_ID('tempdb.dbo.#tmp_clients','U')) is not null
    begin
        drop table #tmp_clients
    end
    
    create table #tmp_clients (
    num_operacion    int        null
    )
    
    insert into  #tmp_clients
    (num_operacion)
    select
    ct_num_operacion
    from cr_cobranza_tmp
    where ct_oficina = @w_id_oficina
	and ct_fecha = @w_fecha_actual
    
    
    select @w_num_operacion = min(num_operacion) from #tmp_clients
    while @w_num_operacion is not null
    begin
        
        --6. INSERTA DATA DEL REPORTE
        insert into ##tmp_info
        (num_banco,                 cod_cliente,                nom_cliente,            cod_grupo,              nom_grupo,      
        ref_grupal,                 grupal,                     num_dividendos,         direccion,              telefono,               
        num_dividendo,              fecha_ven,                  capital,                interes,                otros)
        select 
        ct_num_banco,               ct_ente,                    ct_nombre_cliente,      ct_grupo,               ct_nombre_grupo,
        ct_ref_grupal,              ct_op_grupal,               ct_dividendos_venc,     ct_direccion_negocio,   ct_numero_telf,         
        null,                       null,                       null,                    null,                  null
        from cr_cobranza_tmp
        where ct_num_operacion = @w_num_operacion
		and ct_fecha = @w_fecha_actual


        insert into ##tmp_info
        (num_banco,                 cod_cliente,                nom_cliente,            cod_grupo,              nom_grupo,      
        ref_grupal,                 grupal,                     num_dividendos,         direccion,              telefono,               
        num_dividendo,              fecha_ven,                  capital,                interes,                otros)
        select 
        null,                       null,                       null,                   null,                   null,
        null,                       null,                       null,                   null,                   null,
        cdt_dividendo,              cdt_fecha_venc,             cdt_monto_capital,      cdt_monto_interes,      cdt_monto_otros_rubros
        from cr_cobranza_det_tmp
        where cdt_num_operacion = @w_num_operacion 
		and cdt_fecha = @w_fecha_actual
    
    
    
        select @w_num_operacion = min(num_operacion) from #tmp_clients
        where num_operacion > @w_num_operacion
    end
    
   --8. SE CREA EL ARCHIVO CSV
   --csv
   DECLARE @csv_file_path NVARCHAR(MAX) = @w_path + '\clientes_cobranza_' + convert(varchar, @w_id_oficina)+'.csv' 
   
   declare @w_file varchar (254)= 'clientes_cobranza_' + convert(varchar, @w_id_oficina)+'.csv' 
   declare @w_return int,
           @w_separador char(1)
   set @w_separador = ';'
   
   --select num_banco,cod_cliente,nom_cliente,cod_grupo,nom_grupo,num_dividendos,direccion,telefono,num_dividendo,fecha_ven,capital,interes         
   DECLARE  @query NVARCHAR(MAX) = 'select num_banco,cod_cliente,nom_cliente,cod_grupo,nom_grupo,ref_grupal,grupal,num_dividendos,direccion,telefono,num_dividendo,fecha_ven,capital,interes,otros from ##tmp_info' --Datos
   -- Export query result to CSV file using BCP 
   DECLARE @bcp_command NVARCHAR(MAX) = 'bcp "' + @query + '" queryout "' + @csv_file_path + '" -c -t, -T -S ' 
   
   exec @w_return          = cobis..sp_bcp_archivos
        @i_sql             = @query,           --select o nombre de tabla para generar archivo plano
        @i_tipo_bcp        = 'queryout',             --tipo de bcp in,out,queryout
        @i_rut_nom_arch    = @csv_file_path,   --ruta y nombre de archivo
        @i_separador       = @w_separador      --separador
        
    
    
    --9. SE ENVIA EL ARCHIVO CSV A TODOS LOS FUNCIONARIOS CON LOS CARGOS DE CONBRANZA DISPONIBLES EN LA OFICINA CORRESPONDIENTE
    if (OBJECT_ID('tempdb.dbo.#tmp_correos','U')) is not null
    begin
        drop table #tmp_correos
    end
    
    create table #tmp_correos (
    id          int                     null,
    correo      varchar(254)            null
    )
    
    insert into #tmp_correos
    (id,            correo)
    select 
    fu_funcionario, fu_correo_electronico 
    from cobis..ad_usuario 
    inner join cobis..cl_funcionario on us_login = fu_login
    where us_oficina = @w_id_oficina
    and fu_cargo  in (select c.codigo  from cobis..cl_tabla t 
    inner join cobis..cl_catalogo c on t.codigo = c.tabla
    where t.tabla = 'cr_cobradores' and c.estado = 'V')
    
    select @w_id_funcionario = min(id) from tempdb.dbo.#tmp_correos
    while @w_id_funcionario is not NULL
    begin
        select @w_correo_oficial = null
        
        select @w_correo_oficial = correo from #tmp_correos where id = @w_id_funcionario
        
        --envio de correo
        exec cobis..sp_despacho_ins
                @i_cliente          = 1,
                @i_servicio         = 1,
                @i_template         = 0, --@w_template,
                @i_estado           = 'P',
                @i_tipo             = 'MAIL',
                @i_tipo_mensaje     = 'I',
                @i_prioridad        = 1,
                @i_from             = null,
                @i_to               = @w_correo_oficial, -- correo del cliente
                @i_cc               = '',
                @i_bcc              = '',
                @i_subject          = 'LISTA DE CLIENTES PARA COBRANZA',
                @i_body             = 'ESTIMADO COLABORADOR, ADJUNTO ENCONTRARA EL LISTADO DE CLIENTES DE COBRANZA.',
                @i_content_manager  = 'TEXT',
                @i_retry            = 'S',
                @i_tries            = 0,
                @i_max_tries        = 3,
                @i_var1             = @w_file
                
        select @w_id_funcionario = min(id) from tempdb.dbo.#tmp_correos
        where id > @w_id_funcionario
    end
   --Nuevo registro
   select @w_id_oficina = min(id_oficina) from tempdb.dbo.#tmp_oficinas
   where id_oficina > @w_id_oficina
end
--Generar csv

select @w_termina = 1
return 0

ERROR:
   if @w_mensaje is null
   begin
      select @w_mensaje = mensaje
      from cobis..cl_errores 
      where numero = @w_error
   end
   
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_mensaje
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
