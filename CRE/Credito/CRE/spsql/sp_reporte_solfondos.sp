/***********************************************************************/
/*   NOMBRE LOGICO:        sp_reporte_solfondos                        */
/*   NOMBRE FISICO:        sp_reporte_solfondos.sp                     */
/*   BASE DE DATOS:        cob_credito                                 */
/*   PRODUCTO:             Credito                                     */
/*   DISENADO POR:         P. Jarrin                                   */
/*   FECHA DE ESCRITURA:   30-Ene-2023                                 */
/***********************************************************************/
/*                     IMPORTANTE                                      */
/*  Este programa es parte de los paquetes bancarios que son           */
/*  comercializados por empresas del Grupo Empresarial TOPAZ,          */
/*	representantes exclusivos para comercializar los productos         */
/*  y licencias de TOPAZ TECHNOLOGIES S.L., sociedad constituida       */
/*	y regida por las Leyes de la República de España y las             */
/*	correspondientes de la Unión Europea. Su copia, reproducción,      */
/*  alteración en cualquier sentido, ingeniería reversa,               */
/*	almacenamiento o cualquier uso no autorizado por cualquiera        */
/*	de los usuarios o personas que hayan accedido al presente sitio,   */
/*	queda expresamente prohibido; sin el debido consentimiento por     */
/*  escrito, de parte de los representantes de TOPAZ TECHNOLOGIES S.L. */
/*	El incumplimiento de lo dispuesto en el presente texto, causará    */
/*	violaciones relacionadas con la propiedad intelectual y la         */
/*  confidencialidad de la información tratada; y por lo tanto,        */
/* 	derivará en acciones legales civiles y penales en contra del       */
/*  infractor según corresponda.                                       */
/***********************************************************************/
/*                     PROPOSITO                                       */
/*  Obtener los datos necesarios para el reporte de Solicitud de       */
/*  Fondos                                                             */
/***********************************************************************/
/*                     MODIFICACIONES                                  */
/*   FECHA              AUTOR              RAZON                       */
/*   30-Ene-2023        P. Jarrin.       Emision Inicial - S769997     */
/*   24-Mar-2023        P. Jarrin.       Se agrega totales - S801301   */
/*   30-Mar-2023        P. Jarrin.       Se agrega orden - S801301     */
/*   21-Jun-2023        P. Jarrin.       Ajustes Reporte - B854189     */
/*   11-Jul-2024        D. Morales.      R239293: Se añade updates     */
/*                                       para tr_tipo E                */
/*   28-Abr-2025        O. Diaz          R254276 - Ciclo               */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_reporte_solfondos')
   drop proc sp_reporte_solfondos  
go

create proc sp_reporte_solfondos (
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

    @o_filial            varchar(200) = null out,
    @o_oficina           varchar(200) = null out,
    @o_fecha_liq         varchar(200) = null out,
    @o_plazo             varchar(200) = null out,
    @o_tplazo            varchar(200) = null out,
    @o_tcuota            varchar(200) = null out,
    @o_toperacion        varchar(200) = null out,
    @o_oficial           varchar(200) = null out,
    @o_data_grupo        varchar(200) = null out 
)
as

declare @w_sp_name              varchar(32),
        @w_error                int,
        @w_filial               varchar(200),
        @w_oficina              varchar(200),
        @w_fecha_liq            varchar(10),
        @w_plazo                varchar(200),
        @w_tplazo               varchar(200),
        @w_tcuota               varchar(200),
        @w_toperacion           varchar(200),
        @w_oficial              varchar(200),
        @w_data_grupo           varchar(200),
        @w_grupo                varchar(200),
        @w_desc_grupo           varchar(200),
        @w_ciclo                varchar(200),
        @w_producto_renov       varchar(10),
        @w_nemonico_comdes      varchar(10),
        @w_simbolo              varchar(10),
        @w_cliente              int,  
        @w_sector               varchar(10), 
        @w_operacion            int,
        @w_nombre_completo      varchar(200), 
        @w_destino              varchar(200), 
        @w_monto                money,
        @w_refin                money,
        @w_comision             money,
        @w_otros                money,
        @w_total                money,
        @w_monto_aux            money,
        @w_refin_aux            money,
        @w_comision_aux         money,
        @w_otros_aux            money,
        @w_total_aux            money,
        @w_formato_fecha        int,        
        @w_formato              varchar(10),
		@w_tr_tipo              char(1)

declare @w_tabla_datos as table(
        id                   int not null identity(1,1),
        cliente              varchar(200),
        nombre_completo      varchar(200),
        destino              varchar(200),
        monto                varchar(200),
        refin                varchar(200),
        comision             varchar(200),
        otros                varchar(200),
        total                varchar(200),
        monto_aux            varchar(200),
        refin_aux            varchar(200),
        comision_aux         varchar(200),
        otros_aux            varchar(200),
        total_aux            varchar(200)
)

select @w_sp_name      = 'sp_reporte_solfondos',

       @w_filial          = '',
       @w_oficina         = '',
       @w_fecha_liq       = '',
       @w_plazo           = '',
       @w_tplazo          = '',
       @w_tcuota          = '',
       @w_toperacion      = '',
       @w_oficial         = '',
       @w_data_grupo      = '',
       @w_grupo           = '',
       @w_desc_grupo      = '',
       @w_ciclo           = '',
       @w_sector          = '',
       @w_nombre_completo = '',
       @w_destino         = '',
       @w_monto           = 0,
       @w_refin           = 0,
       @w_comision        = 0,
       @w_otros           = 0,
       @w_total           = 0,
       @w_monto_aux       = 0,
       @w_refin_aux       = 0,
       @w_comision_aux    = 0,
       @w_otros_aux       = 0,
       @w_total_aux       = 0,
       @w_formato_fecha   = 103,
       @w_formato         = '#,##0.00'
       

if @t_show_version = 1
begin
   print 'Stored procedure sp_reporte_solfondos, Version 1.1.0'
end

if @t_trn <> 21865
begin
exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = 151051
   return 151051
end

--Search Data
if @i_operacion = 'S'
begin
    select 
           @w_filial       = (select fi_nombre from cobis..cl_filial, cobis..cl_oficina where fi_filial = of_filial and of_oficina =  op_oficina),         
           @w_oficina      = (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
           @w_fecha_liq    = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
           @w_plazo        = op_plazo,
           @w_tplazo       = (select td_descripcion from cob_cartera..ca_tdividendo where td_tdividendo = op_tplazo),
           @w_tcuota       = (select td_descripcion from cob_cartera..ca_tdividendo where td_tdividendo = op_tdividendo),
           @w_toperacion   = op_toperacion,
           @w_oficial      = (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial 
                               where fu_funcionario = oc_funcionario and oc_oficial = op_oficial)
    from cob_credito..cr_tramite tr, cob_cartera..ca_operacion op
   where tr_tramite = op_tramite
     and tr_tramite = @i_tramite 

    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
        select top 1 @w_grupo = tg_grupo
          from cob_credito..cr_tramite_grupal 
         where tg_tramite = @i_tramite

        select @w_desc_grupo = gr_nombre
          from cobis..cl_grupo
         where gr_grupo = @w_grupo

        /*select @w_ciclo = ci_ciclo  --ODI-R254276
          from cob_cartera..ca_ciclo 
         where ci_tramite = @i_tramite*/
		 
        select @w_ciclo = gr_num_ciclo
		  from cobis..cl_grupo
         where gr_grupo = @w_grupo
        if @@rowcount = 0
        begin
            select @w_ciclo = 0
        end 
        select @w_data_grupo = '  ' + @w_grupo + '  ' + @w_desc_grupo + '  ' + '  Ciclo: ' + @w_ciclo  
    end
    else
    begin
        select @w_data_grupo = ''
    end
    
    select 
        @o_filial            = @w_filial,
        @o_oficina           = @w_oficina,
        @o_fecha_liq         = @w_fecha_liq,
        @o_plazo             = @w_plazo,
        @o_tplazo            = @w_tplazo,
        @o_tcuota            = @w_tcuota,
        @o_toperacion        = @w_toperacion,
        @o_oficial           = @w_oficial,
        @o_data_grupo        = @w_data_grupo
      
    select 
        @o_filial,
        @o_oficina,
        @o_fecha_liq,
        @o_plazo,
        @o_tplazo,
        @o_tcuota,
        @o_toperacion,
        @o_oficial,
        @o_data_grupo
end

--Query Data Fondos
if @i_operacion = 'Q'
begin
    select @w_producto_renov = pa_char
    from cobis..cl_parametro
    where pa_producto = 'CCA'
    and   pa_nemonico = 'REESFP'    
    
    select @w_nemonico_comdes = pa_char 
    from cobis..cl_parametro
    where pa_producto = 'CCA'
    and   pa_nemonico = 'COMDES'

    select @w_simbolo   = (select mo_simbolo from cobis..cl_moneda where mo_moneda = op_moneda)
     from cob_cartera..ca_operacion
    where op_tramite = @i_tramite
	
	select @w_tr_tipo = tr_tipo from cob_credito..cr_tramite where tr_tramite = @i_tramite

    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin   

        IF OBJECT_ID('tempdb..#tmp_miembros_grp') IS NOT NULL
        drop table #tmp_miembros_grp

        create table #tmp_miembros_grp
        (
            cliente    int,
            sector     varchar(10) null,
            operacion  int         null,
            monto      money       null,
            rol        char(1),
            orden      smallint 
        )

        insert into #tmp_miembros_grp
        select tg_cliente, 
               tg_sector, 
               tg_operacion, 
               isnull(tg_monto,0),
               (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = tg_cliente and cg_grupo = tg_grupo),
               0
              from cob_credito..cr_tramite_grupal  
             where tg_tramite = @i_tramite 
               and tg_participa_ciclo = 'S'
             order by tg_cliente
               
        update #tmp_miembros_grp
           set orden = 1
         where rol = 'P'

        update #tmp_miembros_grp
           set orden = 2
         where rol not in ('P' , 'M')

        update #tmp_miembros_grp
           set orden = 3
         where rol = 'M'
     
        declare cursor_grp cursor
        for select cliente, sector, operacion, isnull(monto,0)
              from #tmp_miembros_grp  
             order by orden               
        open cursor_grp    
        fetch next from cursor_grp into @w_cliente, @w_sector, @w_operacion, @w_monto
        
        while @@fetch_status = 0
        begin   
            
            select @w_nombre_completo = isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' +  isnull(trim(p_c_apellido), '')
              from cobis..cl_ente  
             where en_ente = @w_cliente
        
            select @w_destino = @w_sector + ' - ' + (select ltrim(rtrim(se_descripcion)) from cobis..cl_subactividad_ec where se_codigo = @w_sector)
            select @w_monto = isnull(@w_monto,0)
            select @w_refin = isnull(dm_monto_mop,0) from cob_cartera..ca_desembolso where dm_producto = @w_producto_renov and dm_operacion = @w_operacion          
            select @w_comision = isnull(ro_valor,0) from cob_cartera..ca_rubro_op where ro_concepto = @w_nemonico_comdes and ro_fpago = 'L' and ro_operacion = @w_operacion
            select @w_otros = isnull(sum(isnull(ro_valor,0)),0) from cob_cartera..ca_rubro_op where ro_concepto <> @w_nemonico_comdes and ro_fpago = 'L' and ro_operacion = @w_operacion
            select @w_total = isnull(@w_monto,0) - isnull(@w_refin,0) - isnull(@w_comision,0) - isnull(@w_otros,0)

            select @w_monto_aux    = isnull(@w_monto_aux,0) + isnull(@w_monto,0)
            select @w_refin_aux    = isnull(@w_refin_aux,0) + isnull(@w_refin,0)
            select @w_comision_aux = isnull(@w_comision_aux,0) + isnull(@w_comision,0)
            select @w_otros_aux    = isnull(@w_otros_aux,0) + isnull(@w_otros,0)
            select @w_total_aux    = isnull(@w_total_aux,0) + isnull(@w_total,0)

            insert into @w_tabla_datos
            select  @w_cliente, 
                    @w_nombre_completo, 
                    isnull(@w_destino,''),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_monto,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_refin,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_comision,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_otros,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_total,0), @w_formato)),
                    '','','','',''

            insert into @w_tabla_datos
            select '','','','','','',
                   (select cp_descripcion from cob_cartera..ca_producto where cp_producto = dm_producto), 
                   @w_simbolo + ' ' +  convert(varchar,format(isnull(dm_monto_mop,0), @w_formato)),
                    '','','','',''                 
              from cob_cartera..ca_desembolso 
             where dm_producto <> @w_producto_renov 
              and dm_operacion = @w_operacion   

            select @w_nombre_completo = '', @w_destino = '', @w_monto = 0, @w_refin = 0, @w_comision = 0, @w_otros = 0, @w_total = 0                
            fetch next from cursor_grp into @w_cliente, @w_sector, @w_operacion, @w_monto              
        end  
        close cursor_grp
        deallocate cursor_grp
        
        update @w_tabla_datos 
           set monto_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_monto_aux,0), @w_formato)),
               refin_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_refin_aux,0), @w_formato)),
               comision_aux = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_comision_aux,0), @w_formato)),
               otros_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_otros_aux,0), @w_formato)),
               total_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_total_aux,0), @w_formato))
    end 
    else
    begin
        declare cursor_ind cursor
        for select tr_cliente, tr_cod_actividad, tr_numero_op, tr_monto
              from cob_credito..cr_tramite, cob_credito..cr_deudores
                 where de_tramite = tr_tramite
                   and de_rol = 'D'
                   and de_tramite = @i_tramite
                 order by tr_cliente
        open cursor_ind    
        fetch next from cursor_ind into @w_cliente, @w_sector, @w_operacion, @w_monto
            
        while @@fetch_status = 0
        begin   
            
            select @w_nombre_completo = isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' +  isnull(trim(p_c_apellido), '')
              from cobis..cl_ente  
             where en_ente = @w_cliente          
             
            select @w_destino = @w_sector + ' - ' + (select ltrim(rtrim(se_descripcion)) from cobis..cl_subactividad_ec where se_codigo = @w_sector)
            select @w_monto = isnull(@w_monto,0)
            select @w_refin = isnull(dm_monto_mop,0) from cob_cartera..ca_desembolso where dm_producto = @w_producto_renov and dm_operacion = @w_operacion          
            select @w_comision = isnull(ro_valor,0) from cob_cartera..ca_rubro_op where ro_concepto = @w_nemonico_comdes and ro_fpago = 'L' and ro_operacion = @w_operacion
            select @w_otros = isnull(sum(isnull(ro_valor,0)),0) from cob_cartera..ca_rubro_op where ro_concepto <> @w_nemonico_comdes and ro_fpago = 'L' and ro_operacion = @w_operacion
            select @w_total = isnull(@w_monto,0) - isnull(@w_refin,0) - isnull(@w_comision,0) - isnull(@w_otros,0)			

            select @w_monto_aux    = isnull(@w_monto_aux,0) + isnull(@w_monto,0)
            select @w_refin_aux    = isnull(@w_refin_aux,0) + isnull(@w_refin,0)
            select @w_comision_aux = isnull(@w_comision_aux,0) + isnull(@w_comision,0)
            select @w_otros_aux    = isnull(@w_otros_aux,0) + isnull(@w_otros,0)
            select @w_total_aux    = isnull(@w_total_aux,0) + isnull(@w_total,0)
            
            insert into @w_tabla_datos
            select  @w_cliente, 
                    @w_nombre_completo, 
                    isnull(@w_destino,''),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_monto,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_refin,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_comision,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_otros,0), @w_formato)),
                    @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_total,0), @w_formato)),
                    '','','','',''

            insert into @w_tabla_datos
            select '','','','','','',
                   (select cp_descripcion from cob_cartera..ca_producto where cp_producto = dm_producto), 
                   @w_simbolo + ' ' +  convert(varchar,format(isnull(dm_monto_mop,0), @w_formato)),
                    '','','','',''                 
              from cob_cartera..ca_desembolso 
             where dm_producto <> @w_producto_renov 
              and dm_operacion = @w_operacion   
            
            select @w_nombre_completo = '', @w_destino = '', @w_monto = 0, @w_refin = 0, @w_comision = 0, @w_otros = 0, @w_total = 0                
            fetch next from cursor_ind into @w_cliente, @w_sector, @w_operacion, @w_monto
        end  
        close cursor_ind
        deallocate cursor_ind        
        
        update @w_tabla_datos 
           set monto_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_monto_aux,0), @w_formato)),
               refin_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_refin_aux,0), @w_formato)),
               comision_aux = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_comision_aux,0), @w_formato)),
               otros_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_otros_aux,0), @w_formato)),
               total_aux    = @w_simbolo + ' ' +  convert(varchar,format(isnull(@w_total_aux,0), @w_formato))
    end   

	if @w_tr_tipo = 'E'
	begin
		update @w_tabla_datos 
		set total_aux  = @w_simbolo + ' ' +  convert(varchar,format(0, @w_formato)),
			total      = @w_simbolo + ' ' +  convert(varchar,format(0, @w_formato)),
			refin      = monto,
			refin_aux  = monto_aux
	end



	select cliente,
       nombre_completo,
       destino,
       monto,
       refin,
       comision,
       otros,
       total,
       monto_aux,
       refin_aux,
       comision_aux,
       otros_aux,
       total_aux
	from @w_tabla_datos 
	order by id asc 
 
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
