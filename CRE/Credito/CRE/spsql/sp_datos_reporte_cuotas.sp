/********************************************************************/
/*   NOMBRE LOGICO:        sp_datos_reporte_cuotas                  */
/*   NOMBRE FISICO:        sp_datos_reporte_cuotas.sp               */
/*   BASE DE DATOS:        cob_credito                              */
/*   PRODUCTO:             Credito                                  */
/*   DISENADO POR:         P. Jarrin                                */
/*   FECHA DE ESCRITURA:   20-Dic-2022                              */
/********************************************************************/
/*                              IMPORTANTE                          */
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
/*                          PROPOSITO                               */
/*  Obtener los datos necesarios para el reporte de Cuotas Grupales */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*      FECHA           AUTOR         RAZON                         */
/*   20-Dic-2022        P. Jarrin.    Emision Inicial - S749420     */
/*   24-Mar-2023        P. Jarrin.    Se agrega totales - S801301   */
/*   30-Mar-2023        P. Jarrin.    Se agrega orden - S801301     */
/*   30-May-2023        P. Jarrin.    Reporte Unificado - S809639   */
/*   20-Sep-2023        D. Morales.   Se modifica obtención cuota   */
/*   25-Sep-2023        P. Jarrin.    Ajuste Nombre B908476-R215936 */
/*   28-Sep-2023        D. Morales.   R216249:Se agrega @o_nombre_op*/
/*   06-Oct-2023        B. Duenas.    Ajuste NUM OP REEST  -R216935 */
/*   01-Dic-2023        D. Morales.   R220687:Se excluyen op  con   */
/*                                    estado 6                      */
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_datos_reporte_cuotas')
   drop proc sp_datos_reporte_cuotas
go

create proc sp_datos_reporte_cuotas(
        @s_ssn               int          = null,
        @s_date              datetime     = null,
        @s_user              login        = null,
        @s_term              descripcion  = null,
        @s_corr              char(1)      = null,
        @s_ssn_corr          int          = null,
        @s_ofi               smallint     = null,
        @t_rty               char(1)      = null,
        @t_debug             char(1)      = 'N',
        @t_file              varchar(14)  = null,
        @t_trn               smallint     = null,  
        @t_show_version      bit          = 0,
        @i_tramite           int,
        @i_operacion         char(1),
        @i_formato_fecha     int          = null,
        @o_filal             varchar(200) = null out,
        @o_oficina           varchar(200) = null out,
        @o_telefono          varchar(200) = null out,
        @o_plazo             varchar(200) = null out,
        @o_grupo             varchar(200) = null out,
        @o_desc_grupo        varchar(200) = null out,
        @o_fecha_inicio      varchar(200) = null out,
        @o_fecha_ven         varchar(200) = null out,
        @o_ciclo             varchar(200) = null out,
        @o_oficial           varchar(200) = null out,
        @o_banco             varchar(200) = null out,
        @o_cuota             varchar(200) = null out,
        @o_npe               varchar(200) = null out,
        @o_codigo_barra      varchar(200) = null out,
        @o_nombre_op         varchar(200) = null out
)
as
declare 
        @w_sp_name           varchar(32),
        @w_sp_msg            varchar(100),
        @w_return            int,
        @w_error             int,
        @w_banco_padre       varchar(24),
        @w_filal             varchar(200),
        @w_oficina           varchar(200),
        @w_telefono          varchar(200),
        @w_plazo             varchar(200),
        @w_grupo             varchar(200),
        @w_desc_grupo        varchar(200),
        @w_fecha_inicio      varchar(200),
        @w_fecha_ven         varchar(200),
        @w_ciclo             varchar(200),
        @w_oficial           varchar(200),
        @w_oficial_aux       varchar(200),
        @w_id                int,
        @w_dividendo         int,
        @w_fecha_venc        datetime,
        @w_orden             int,
        @w_id_ant            int,
        @w_banco             varchar(24),
        @w_simbolo           varchar(10),
        @w_formato           varchar(10),
        @w_op_cuota          money,
        @w_cuota             varchar(200),
        @w_npe_aux           varchar(200),
        @w_npe               varchar(200),
        @w_codigo_barra      varchar(200),
        @w_cons_1            varchar(24),
        @w_cons_2            varchar(24),
        @w_cons_3            varchar(24),
        @w_cons_4            varchar(24),
        @w_cons_5            int,
        @w_posicion_aux      int,
        @w_posicion          int,
        @w_numero            int,
        @w_suma_par          int,
        @w_suma_impar        int,
        @w_valor_a           int,
        @w_valor_b           int,
        @w_valor_c           int,
        @w_valor_d           int,
        @w_valor_e           int,
        @w_valor_f           int,
        @w_valor_g           int,
        @w_valor_vr          int,
        @w_verificador       varchar(200),
        @w_banco_aux         varchar(24),
        @w_operacionca       int,
        @w_cliente           int,
        @w_toperacion        varchar(200),
        --r216935
        @w_tipo_tramite      char(1)

select  @w_sp_name           = 'sp_datos_reporte_cuotas',
        @w_banco_padre       = '',
        @w_filal             = '',
        @w_oficina           = '',
        @w_telefono          = '',
        @w_plazo             = '',
        @w_grupo             = '',
        @w_desc_grupo        = '',
        @w_fecha_inicio      = '',
        @w_fecha_ven         = '',
        @w_ciclo             = '',
        @w_oficial           = '',
        @w_oficial_aux       = '',
        @w_banco             = '',
        @w_simbolo           = '',
        @w_formato           = '#,##0.00',
        @w_op_cuota          = 0,
        @w_cuota             = '',
        @w_npe_aux           = '',
        @w_npe               = '',
        @w_codigo_barra      = '',
        @w_cons_1            = '415',
        @w_cons_2            = '7419700008736',
        @w_cons_3            = '8020',
        @w_cons_4            = '0',
        @w_cons_5            = 10,
        @w_posicion_aux      = 9,
        @w_posicion          = 1,
        @w_numero            = 0,
        @w_suma_par          = 0,
        @w_suma_impar        = 0,
        @w_valor_a           = 0,
        @w_valor_b           = 0,
        @w_valor_c           = 0,
        @w_valor_d           = 0,
        @w_valor_e           = 0,
        @w_valor_f           = 0,
        @w_valor_g           = 0,
        @w_valor_vr          = 0,
        @w_verificador       = '',
        @w_banco_aux         = '' 

if @i_formato_fecha is null
begin
    select @i_formato_fecha = 103
end

if @t_trn <> 21856
begin
exec cobis..sp_cerror
     select @w_return = 151051
     goto ERROR_FIN
end

--Search Data
if @i_operacion = 'S'
begin
    select @w_tipo_tramite = tr_tipo
    from cob_credito..cr_tramite
    where tr_tramite = @i_tramite
    
    select @w_ciclo = ci_ciclo 
      from cob_cartera..ca_ciclo 
     where ci_tramite = @i_tramite
    if @@rowcount = 0
    begin
        select @w_ciclo = 0
    end

    select 
           @w_filal        = (select fi_nombre from cobis..cl_filial, cobis..cl_oficina where fi_filial = of_filial and of_oficina =  op_oficina),                  
           @w_oficina      = (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
           @w_telefono     = (select to_valor from cobis..cl_telefono_of, cobis..cl_oficina where to_oficina = of_oficina and to_oficina = op_oficina and to_secuencial = of_telefono),
           @w_plazo        = op_plazo,
           @w_fecha_inicio = convert(varchar(10),op_fecha_ini ,@i_formato_fecha),
           @w_fecha_ven    = convert(varchar(10),op_fecha_fin ,@i_formato_fecha),
           @w_oficial      = convert(varchar,op_oficial) + ' ' + (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial 
                                                                   where fu_funcionario = oc_funcionario and oc_oficial = op_oficial),
           @w_banco        = op_banco,
           @w_banco_aux    = replicate('0', 11 - len(op_banco)) + op_banco,
           @w_simbolo      = (select mo_simbolo from cobis..cl_moneda where mo_moneda = op_moneda),
           @w_operacionca  = op_operacion,
           @w_cliente      = op_cliente,
           @w_toperacion   = op_toperacion
    from cob_credito..cr_tramite tr, cob_cartera..ca_operacion with (nolock)
   where tr_tramite = op_tramite
     and tr_tramite = @i_tramite 
     
    select @w_toperacion = c.valor from cobis..cl_tabla t
    inner join cobis..cl_catalogo c on t.codigo = c.tabla
    where t.tabla = 'ca_toperacion'
    and c.codigo =  @w_toperacion 


    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
        select top 1 @w_grupo = tg_grupo
          from cob_credito..cr_tramite_grupal 
         where tg_tramite = @i_tramite

        select @w_desc_grupo = gr_nombre
          from cobis..cl_grupo
         where gr_grupo = @w_grupo
        
         select @w_op_cuota = sum(isnull(am_cuota,0))
         from cob_cartera..ca_operacion
         inner join cob_cartera..ca_amortizacion on am_operacion = op_operacion
         where op_ref_grupal = @w_banco
		 and op_estado not in (6)
         and am_dividendo = 1 
    end
    else
    begin
        select @w_op_cuota = sum(isnull(am_cuota,0)) from cob_cartera..ca_amortizacion where am_operacion = @w_operacionca and am_dividendo = 1
        select @w_grupo      = @w_cliente,
               @w_desc_grupo = isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' +  isnull(trim(p_c_apellido), '')
          from cobis..cl_ente  
         where en_ente = @w_cliente         
    end
    
    select @w_cuota = @w_simbolo + ' ' +  convert(varchar,format(@w_op_cuota, @w_formato))
    if @w_tipo_tramite = 'E' --Reestructuracion
    begin
       select @w_banco        = or_num_operacion,
              @w_banco_aux    = replicate('0', 11 - len(or_num_operacion)) + or_num_operacion
       from cob_credito.dbo.cr_op_renovar cor 
       where cor.or_tramite = @i_tramite
    end
    select @w_codigo_barra = @w_cons_1 + @w_cons_2 + @w_cons_3 + @w_cons_4 + @w_banco_aux
    select @w_npe_aux = substring(@w_cons_2, @w_posicion_aux, 4) + @w_cons_4 + @w_cons_4 + @w_banco_aux 
     
    while @w_posicion <= len(@w_npe_aux)
    begin
          select @w_numero = convert(int, substring(@w_npe_aux, @w_posicion, 1))
          if ((@w_posicion % 2) = 1)
          begin
                if ((@w_numero * 2) > = @w_cons_5)
                begin
                    select @w_suma_impar = @w_suma_impar + ((@w_numero * 2) + 1)
                end
                else
                begin
                    select @w_suma_impar = @w_suma_impar + (@w_numero * 2)
                end
          end
          if ((@w_posicion % 2) = 0)
          begin
                select @w_suma_par  = @w_suma_par + @w_numero
          end
          select @w_posicion = @w_posicion + 1
    end

    select @w_valor_a  = @w_suma_impar + @w_suma_par,
           @w_valor_b  = @w_valor_a / @w_cons_5,
           @w_valor_c  = @w_valor_b * @w_cons_5,
           @w_valor_d  = @w_valor_a - @w_valor_c,
           @w_valor_e  = @w_cons_5  - @w_valor_d,
           @w_valor_f  = @w_valor_e / @w_cons_5,
           @w_valor_g  = @w_valor_f * @w_cons_5,
           @w_valor_vr = @w_valor_e - @w_valor_g,
           @w_npe_aux  = @w_npe_aux + convert(varchar,@w_valor_vr)
           
    select @w_posicion = 1    
    while @w_posicion <= datalength(@w_npe_aux)
    begin   
        select @w_npe      = @w_npe + substring(@w_npe_aux, @w_posicion, 4) + ' '
        select @w_posicion = @w_posicion + 4
    end
 
    select @o_filal        = @w_filal,
           @o_oficina      = @w_oficina,
           @o_telefono     = @w_telefono,
           @o_plazo        = @w_plazo,
           @o_grupo        = @w_grupo,
           @o_desc_grupo   = @w_desc_grupo,
           @o_fecha_inicio = @w_fecha_inicio,
           @o_fecha_ven    = @w_fecha_ven,
           @o_ciclo        = @w_ciclo,
           @o_oficial      = @w_oficial,
           @o_banco        = @w_banco,
           @o_cuota        = @w_cuota,
           @o_npe          = @w_npe,
           @o_codigo_barra = @w_codigo_barra,
           @o_nombre_op    = @w_toperacion
      
    select @o_filal,
           @o_oficina,
           @o_telefono,
           @o_plazo,
           @o_grupo,
           @o_desc_grupo,
           @o_fecha_inicio,
           @o_fecha_ven,
           @o_ciclo,
           @o_oficial,
           @o_banco,
           @o_cuota,
           @o_npe,
           @o_codigo_barra,
           @o_nombre_op
end

-- Members Data
if @i_operacion = 'M'
begin

    IF OBJECT_ID('tempdb..#tmp_miembros') IS NOT NULL
     drop table #tmp_miembros
      
    create table #tmp_miembros
    (
    id           int,
    nombre       varchar(255)  null,
    simbolo      varchar(10)   null,
    monto        money         null,
    asesors      varchar (100) null,
    cuotas       varchar (100) null,
    total_cuotas varchar (100) null,
    rol          char(1),
    orden        smallint,
    operacion    int
    )

    select @w_banco_padre = op_banco,
           @w_simbolo     = (select mo_simbolo from cobis..cl_moneda where mo_moneda = op_moneda),
           @w_operacionca = op_operacion
      from cob_cartera..ca_operacion with (nolock)
     where op_tramite = @i_tramite  

    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
    
        select @w_op_cuota = sum(isnull(am_cuota,0))
          from cob_cartera..ca_operacion with (nolock)
         inner join cob_cartera..ca_amortizacion on am_operacion = op_operacion
         where op_ref_grupal = @w_banco_padre
		 and op_estado not in (6)
         and am_dividendo = 1 

		insert into #tmp_miembros
		select 
		op_cliente,
		(isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' + isnull(p_c_apellido,'') + ' ' + isnull(en_nombre,'')),
		(select mo_simbolo from cobis..cl_moneda where mo_moneda = op_moneda),
			isnull(op_monto,0),
		(convert(varchar,op_oficial) + ' ' + (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial 
												where fu_funcionario = oc_funcionario and oc_oficial = op_oficial)),
			0,
			@w_simbolo + ' ' +  convert(varchar,format(@w_op_cuota, @w_formato)),
		(select cg_rol from cobis..cl_cliente_grupo where  cg_ente = en_ente and cg_grupo = en_grupo),
		0,
		op_operacion
		from cob_cartera..ca_operacion with (nolock), cobis..cl_ente
		where op_cliente = en_ente
		and op_ref_grupal = @w_banco_padre
		and op_estado not in (6)
		order by op_cliente
		
		update #tmp_miembros
		set cuotas = ( select sum(isnull(am_cuota,0))
							from cob_cartera..ca_amortizacion 
							where am_operacion = operacion
							and am_dividendo = 1)
		
		update #tmp_miembros
		set orden = 1
		where rol = 'P'
	
		update #tmp_miembros
		set orden = 2
		where rol not in ('P' , 'M')
	
		update #tmp_miembros
		set orden = 3
		where rol = 'M'
		
    end
    else
    begin
        
        select @w_op_cuota = sum(isnull(am_cuota,0)) from cob_cartera..ca_amortizacion with (nolock) where am_operacion = @w_operacionca and am_dividendo = 1

        insert into #tmp_miembros
        select 
               op_cliente,
               (isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' + isnull(p_c_apellido,'') + ' ' + isnull(en_nombre,'')),
               (select mo_simbolo from cobis..cl_moneda where mo_moneda = op_moneda),
               isnull(op_monto,0),
               (convert(varchar,op_oficial) + ' ' + (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial 
                                                      where fu_funcionario = oc_funcionario and oc_oficial = op_oficial)),
               @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_op_cuota,0), @w_formato)), 
               @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_op_cuota,0), @w_formato)),
               (select de_rol from cob_credito..cr_deudores where de_tramite = op_tramite and de_cliente = en_ente ),
               0,
               op_operacion
         from cob_cartera..ca_operacion with (nolock), cobis..cl_ente
        where op_cliente = en_ente
          and op_banco   = @w_banco_padre
        order by op_cliente 

        update #tmp_miembros
           set orden = 1
         where rol = 'D'
         
    end
    
    select * from #tmp_miembros order by orden
end

-- Quotes Data
if @i_operacion = 'Q'
begin

        
    select @w_oficial_aux = convert(varchar,op_oficial) + ' ' + (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial 
                                                                  where fu_funcionario = oc_funcionario and oc_oficial = op_oficial)
      from cob_cartera..ca_operacion with (nolock) 
     where op_tramite = @i_tramite  
     
    IF OBJECT_ID('tempdb..#tmp_cuota') IS NOT NULL
     drop table #tmp_cuota
      
    create table #tmp_cuota
    (
    id         int      not null identity(1,1),
    dividendo  int      null,
    fecha_ven  datetime null,
    orden      int      not null
    )

    IF OBJECT_ID('tempdb..#tmp_data_cuota') IS NOT NULL
     drop table #tmp_data_cuota
      
    create table #tmp_data_cuota
    (
    id_imp                  int,
    dividendo_imp  int      null,
    fecha_ven_imp  datetime null,
    id_par                  int,
    dividendo_par  int      null,
    fecha_ven_par  datetime null
    )

    IF OBJECT_ID('tempdb..#tmp_report_cuota') IS NOT NULL
     drop table #tmp_report_cuota
      
    create table #tmp_report_cuota
    (
    dividendo_imp  int           null,
    fecha_ven_imp  varchar(10)   null,
    dividendo_par  int           null,
    fecha_ven_par  varchar(10)   null,
    asesor         varchar (100) null
    )
    
    insert into #tmp_cuota 
    select di_dividendo, di_fecha_ven, (di_dividendo % 2)
    from cob_cartera..ca_operacion with (nolock), cob_cartera..ca_dividendo
   where op_tramite = @i_tramite
     and di_operacion = op_operacion
    order by di_dividendo

    declare cursor_cuotas cursor
        for select id, dividendo, fecha_ven, orden from #tmp_cuota order by id
    open cursor_cuotas
    fetch next from cursor_cuotas into @w_id, @w_dividendo, @w_fecha_venc, @w_orden
        
    while @@fetch_status = 0
    begin   
         if( @w_orden = 1)
         begin
             select @w_id_ant = @w_id
             insert into #tmp_data_cuota (id_imp, dividendo_imp, fecha_ven_imp ) values (@w_id, @w_dividendo, @w_fecha_venc)      
         end
         if( @w_orden = 0)
         begin
            update #tmp_data_cuota set id_par = @w_id, dividendo_par = @w_dividendo, fecha_ven_par = @w_fecha_venc where id_imp = @w_id_ant
            select @w_id_ant = 0
         end
         fetch next from cursor_cuotas into @w_id, @w_dividendo, @w_fecha_venc, @w_orden
    end  

    close cursor_cuotas
    deallocate cursor_cuotas

    insert into #tmp_report_cuota
    select dividendo_imp, isnull(convert(varchar(10),fecha_ven_imp ,@i_formato_fecha),''), dividendo_par, isnull(convert(varchar(10),fecha_ven_par ,@i_formato_fecha),''), @w_oficial_aux 
      from #tmp_data_cuota 
     order by id_imp
        
    select * from #tmp_report_cuota order by dividendo_imp  
end

return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_return  
    
return @w_return
go
