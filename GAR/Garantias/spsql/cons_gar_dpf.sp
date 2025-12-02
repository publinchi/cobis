/*************************************************************************/
/*   Archivo:              cons_gar_dpf.sp                               */
/*   Stored procedure:     sp_cons_gar_dpf                               */
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
/*    Abril/2022          ARO                       Mejora Is NULL       */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_cons_gar_dpf') IS NOT NULL
    DROP PROCEDURE dbo.sp_cons_gar_dpf
go

create proc dbo.sp_cons_gar_dpf  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @s_rol                tinyint   = null,      --II CMI 02Dic2006
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_opcion             char(1)     = 'Q',
   @i_modo               tinyint     = null,
   @i_fecha_ini          datetime    = null,
   @i_fecha_fin          datetime    = null,
   @i_cliente            int         = null,
   @i_tcca               catalogo    = null,
   @i_tramite            int         = null,
   @i_codigo_externo     varchar(64) = null,
   @i_codigo_sig         varchar(64) = null,
   @i_formato_fecha      tinyint     = null,
   @i_tarjeta            varchar(16) = null
)
as

declare
   @w_sp_name            varchar(32),
   @w_tabla_rec          smallint,
   @w_error              int,
   @w_tot_gar            money,
   @w_tot_op             money,
   @w_corte              int,
   @w_periodo            tinyint,
   @w_estado             char(1),
   @w_param_busqueda     varchar(24)            --II CMI 02Dic2006

select @w_sp_name = 'sp_cons_gar_dpf'

if @i_opcion = 'Q'   
begin

   select @w_tabla_rec = codigo
     from cobis..cl_tabla 
    where tabla = 'cu_reclasifica'


   create table #gar_dpf (
     tramite              int          null,
     cliente              int          null,
     nombre               descripcion  null,
     garantia             descripcion  null,
     tipo_garantia        descripcion  null,
     operacion            cuenta       null,
     monto_op             money        null,
     tcca                 catalogo     null,
     des_tcca             descripcion  null,
     valor_gar            money        null,
     valor_gar_ini        money        null,
     dpf                  varchar(30)  null,  --AMH 2010/01/18 antes estaba de 24 
     fven_dpf             datetime     null,
     beneficiario         descripcion  null) 

   create table #duplicados (
     dgarantia            descripcion  null,
     cantidad             tinyint      null)

   ---CARGA INICIAL
   insert into #gar_dpf
   select gp_tramite,
          null,
          null,
          gp_garantia,
          tc_descripcion,
          null,
          null,
          cu_tipo_cca, ---GCR:04/Ene/2007
          null,
          cu_valor_actual,
          cu_valor_inicial,
          cu_plazo_fijo,
          null,
          null
     from cob_credito..cr_gar_propuesta,
          cob_custodia..cu_custodia C,
          cob_custodia..cu_tipo_custodia
    where gp_tramite >= 1
      and gp_garantia = cu_codigo_externo
      and gp_est_garantia = 'V'
      and cu_tipo = tc_tipo
      and cu_tipo in (select codigo
                        from cobis..cl_catalogo
                       where tabla = @w_tabla_rec
                         and codigo = C.cu_tipo
                         and estado = 'V')

   ---DEPURAR REGISTROS 
   delete #gar_dpf
     from #gar_dpf, cob_credito..cr_tramite
    where tr_tramite =  tramite
      and tr_tipo = 'L'

   delete #gar_dpf
     from #gar_dpf, cob_cartera..ca_operacion 
    where op_tramite = tramite
---      and op_estado in (0,99,3,11) GCR
      and op_estado in (0,99,11)

	  
   delete #gar_dpf
     from #gar_dpf, cob_cartera_his..ca_operacion 
    where op_tramite = tramite
---     and op_estado in (0,99,3,11) GCR
     and op_estado in (0,99,11) 


	 
   delete #gar_dpf
     from #gar_dpf, cob_cartera..ca_operacion,
          cob_cartera..ca_transaccion
    where op_tramite = tramite
      and tr_operacion = op_operacion
      and tr_secuencial >= 0
      and not (tr_fecha_mov between @i_fecha_ini and @i_fecha_fin)
      and tr_tran = 'DES'
      and tr_estado <> 'REV'
	  


	/*delete #gar_dpf
    from #gar_dpf, cob_cartera..ca_operacion,
          cob_cartera..ca_transaccion_his
    where op_tramite = tramite
      and trh_operacion = op_operacion
      and trh_secuencial >= 0
      and not (trh_fecha_mov between @i_fecha_ini and @i_fecha_fin)
      and trh_tran = 'DES'
      and trh_estado <> 'REV'*/


   ---COMPLEMENTAR INFORMACION
    /*update #gar_dpf
      set operacion = op_banco,
          monto_op  = isnull((select lo_valor_financiar
                                from cob_cartera..lea_operacion
                               where lo_operacion = O.op_operacion),op_monto_aprobado),
          tcca      = isnull(tcca,1), ---GCR:04/Ene/2007 --Se cambia de op_tipo_cca a 1 10/05/19
          des_tcca  = C.valor
     from #gar_dpf, cob_cartera..ca_operacion O,
          cobis..cl_tabla T, cobis..cl_catalogo C
    where op_tramite = tramite
      and T.tabla = 'ca_tipo_cartera'
      and C.tabla = T.codigo
      and C.codigo = isnull(tcca,1) --Se cambia de op_tipo_cca a 1 10/05/19
	
	update #gar_dpf
      set operacion = op_banco, 
          monto_op  = isnull((select lo_valor_financiar
                                from cob_cartera..lea_operacion
                               where lo_operacion = O.op_operacion),op_monto_aprobado),
          tcca      = isnull(tcca,1), ---GCR:04/Ene/2007
          des_tcca  = C.valor
     from #gar_dpf, cob_cartera_his..ca_operacion O,
          cobis..cl_tabla T, cobis..cl_catalogo C
    where op_tramite = tramite
      and T.tabla = 'ca_tipo_cartera'
      and C.tabla = T.codigo
      and C.codigo = isnull(tcca,1) --Se cambia de op_tipo_cca a 1 10/05/19
	*/

	----AR:01/27/2022 Agrego la actualización de la Operación y su monto adicional la descrión de tipo de operacion
    update #gar_dpf
      set operacion = op_banco,
          monto_op  = op_monto,
          tcca      = isnull(tcca,1), ---GCR:04/Ene/2007 --Se cambia de op_tipo_cca a 1 10/05/19  ---AR:01/27/2022 LO DEJO ASI AUNQUE DEBERIA SER COMO LA CONDICION
          des_tcca  = C.valor
     from #gar_dpf, cob_cartera..ca_operacion O,
          cobis..cl_tabla T, cobis..cl_catalogo C
    where op_tramite = tramite
      and T.tabla = 'ca_toperacion'			---'ca_tipo_cartera'
      and C.tabla = T.codigo
      and C.codigo = isnull(tcca, op_toperacion)	---AR:01/27/2022	isnull(tcca,1) --Se cambia de op_tipo_cca a 1 10/05/19

	---AR:01/27/2022 Hasta aqui agregar la operación
	
	update #gar_dpf
      set cliente = cg_ente,
          nombre  = cg_nombre
     from #gar_dpf, cu_cliente_garantia
    where cg_codigo_externo = garantia
      and cg_principal = 'S'

   update #gar_dpf
      set fven_dpf = op_fecha_ven,
          beneficiario = (select ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)) from cobis..cl_ente where en_ente = Y.be_ente)     
      from #gar_dpf, cob_pfijo..pf_operacion,cob_pfijo..pf_beneficiario Y
    where dpf = op_num_banco
      ----and dpf <> null 
	  and dpf is not null			----AR:01/27/2022
      and Y.be_operacion = op_operacion
      and be_rol = 'T'

	  
  ---Borrar registros inconsistentes
  delete #gar_dpf
   where operacion = null


  ---CARGAR GARANTIAS DUPLICADAS
  insert into #duplicados
   select garantia,
          count(1)
     from #gar_dpf
    where (cliente = @i_cliente or @i_cliente = null)
      and (tcca = @i_tcca or @i_tcca = null)
      and (garantia = @i_codigo_externo or @i_codigo_externo = null)
   group by garantia
   having count(1) > 1
   


   ---ENVIO DE DATOS AL FRONTEND      
   set rowcount 0	--9  --Antes estaba 15  AMH 2010/01/21
   
   select 'TRAMITE' = tramite,
          'CLIENTE' = nombre,
          'OPERACION' = operacion,
          'M.APROBADO' = monto_op,
          'GARANTIA' = garantia,
          'V.GARANTIA' = valor_gar,
          'F.VCTO.DPF' = convert(varchar(10),fven_dpf,@i_formato_fecha),
          'TIPO CARTERA' = des_tcca,
          'TIPO GARANTIA' = tipo_garantia,
          'VALOR INICIAL' = valor_gar_ini,
           'BENEFICIARIO' = beneficiario,
          'CERT. DEPOSITO' = dpf             --AMH 2010/01/01
     from #gar_dpf
    where (cliente = @i_cliente or @i_cliente is null)								---AR:01/27/2022 Cambio a is null = null no toma los datos tabla temporal acepta nulos
      and (tcca = @i_tcca or @i_tcca is null)
      and (garantia = @i_codigo_externo or @i_codigo_externo is null)
      and (
           (tramite = @i_tramite and (garantia > @i_codigo_sig or @i_codigo_sig is null)) or
           (tramite > @i_tramite or @i_tramite is null)
          ) 

    --where (cliente = @i_cliente or @i_cliente = null)
    --  and (tcca = @i_tcca or @i_tcca = null)
    --  and (garantia = @i_codigo_externo or @i_codigo_externo = null)
    --  and (
    --       (tramite = @i_tramite and (garantia > @i_codigo_sig or @i_codigo_sig = null)) or
    --       (tramite > @i_tramite or @i_tramite = null)
    --      )

    order by tramite, garantia
   set rowcount 0 


   if @i_modo = 0 
   begin        

     /* select @w_tot_gar = sum(isnull(valor_gar,0)),
               @w_tot_op = sum(isnull(monto_op,0))
          from #gar_dpf */

     select dgarantia
       from #duplicados
      order by dgarantia        

     ---select @w_tot_op          
     ---select @w_tot_gar
   end 

end --- @i_opcion = 'Q'



if @i_opcion = 'T'   
begin

   select @w_tabla_rec = codigo
     from cobis..cl_tabla 
    where tabla = 'cu_reclasifica'

   create table #gar_visa (
     tarjeta              cuenta       null,
     garantia             descripcion  null,
     tcca                 catalogo     null,
     valor_gar            money        null,
     dpf                  varchar(30)  null,      --AMH 2010/01/18 antes tenia de 24
     cliente              int          null,
     nombre               descripcion  null,
     monto                money        null,
     des_tcca             descripcion  null,
     fven_dpf             datetime     null )


   ---CARGA INICIAL
   insert into #gar_visa
   select rv_tarjeta,
          rv_codigo_externo,
          rv_tipo_cca,
          cu_valor_actual,
          cu_plazo_fijo,
          cg_ente,
          cg_nombre,
          null,
          null,
          null
     from cob_custodia..cu_relvisa,
          cob_custodia..cu_custodia,
          cob_custodia..cu_cliente_garantia
    where rv_codigo_externo = cu_codigo_externo
      and (rv_fecha between @i_fecha_ini and @i_fecha_fin)
      and (rv_tipo_cca = @i_tcca or @i_tcca = null)
      and cg_codigo_externo = cu_codigo_externo
      and (cg_ente = @i_cliente or @i_cliente = null)
      and cg_principal = 'S'


	---COMPLEMENTAR INFORMACION
	/*update #gar_visa
    set monto     = mt_cupo_rotativo,
        des_tcca  = C.valor
    from #gar_visa, cob_externos..ex_mst_tarjeta,
          cobis..cl_tabla T, cobis..cl_catalogo C
    where mt_tarjeta = tarjeta 
      and T.tabla = 'ca_tipo_cartera'
      and C.tabla = T.codigo
      and C.codigo = tcca*/

   update #gar_visa
      set fven_dpf = op_fecha_ven
     from #gar_visa, cob_pfijo..pf_operacion
    where dpf = op_num_banco
      and dpf <> null 


   set rowcount 10   --AMH 2010/01/21 antes estaba 20 
   select 'TARJETA' = tarjeta,
          'CLIENTE' = nombre,
          'M.TARJETA' = monto,
          'GARANTIA' = garantia,
          'V.GARANTIA' = valor_gar,
          'F.VCTO.DPF' = convert(varchar(10),fven_dpf,@i_formato_fecha),
          'TIPO CARTERA' = des_tcca,
          'CERT. DEPOSITO'= dpf  --AMH 2010/01/01
     from #gar_visa
    where (
           (tarjeta = @i_tarjeta and (garantia > @i_codigo_sig or @i_codigo_sig = null)) or
           (tarjeta > @i_tarjeta or @i_tarjeta = null)
          )
    order by tarjeta, garantia
   set rowcount 0 

end --- @i_opcion = 'T'




/*******************************/
/* SALDOS DE CUENTAS CONTABLES */
/*******************************/

if @i_opcion = 'S'  
begin

   create table #cuentas (
     tcca                 catalogo     null,
     cuenta               char(20)     null,
     saldo                money        null )

  select @w_tabla_rec = codigo
    from cobis..cl_tabla 
   where tabla = 'cu_cuentas_dpf'

  select @w_corte = co_corte,
         @w_periodo = co_periodo,
         @w_estado = co_estado
    from cob_conta..cb_corte
   where @i_fecha_fin between co_fecha_ini and co_fecha_fin
     and co_empresa = 1


  if @w_estado <> 'A' ---Saldos en Historicos  
  begin
    insert into #cuentas
    select codigo, valor , isnull(sum(hi_saldo),0)
     from cobis..cl_catalogo,
          cob_conta..cb_jerarquia,
          cob_conta..cb_jerararea,
          cob_conta_his..cb_hist_saldo
    where tabla = @w_tabla_rec
      and (codigo = @i_tcca or @i_tcca = null)
      and estado = 'V'
      and je_empresa = 1
      and je_oficina_padre = 255 
      and ja_empresa = je_empresa 
      and ja_area_padre = 255
      and hi_empresa = je_empresa
      and hi_oficina = je_oficina
      and hi_area    = ja_area
      and hi_cuenta  = valor
      and hi_periodo = @w_periodo
      and hi_corte = @w_corte
   group by codigo,valor
   order by codigo,valor /* HHO Mayo/2012    Migracion SYBASE 15 */
  end
  else
  begin
    insert into #cuentas
    select codigo, valor , isnull(sum(sa_saldo),0)
     from cobis..cl_catalogo,
          cob_conta..cb_jerarquia,
          cob_conta..cb_jerararea,
          cob_conta..cb_saldo
    where tabla = @w_tabla_rec
      and (codigo = @i_tcca or @i_tcca = null)
      and estado = 'V'
      and je_empresa = 1
      and je_oficina_padre = 255 
      and ja_empresa = je_empresa 
      and ja_area_padre = 255
      and sa_empresa = je_empresa
      and sa_periodo = @w_periodo
      and sa_corte = @w_corte
      and sa_oficina = je_oficina
      and sa_area    = ja_area
      and sa_cuenta  = valor
   group by codigo,valor
   order by codigo,valor /* HHO Mayo/2012    Migracion SYBASE 15 */
  end

  ---Envio al frontend
  select valor,
         cuenta,
         saldo
    from #cuentas, cobis..cl_tabla T, 
         cobis..cl_catalogo C
    where T.tabla = 'ca_tipo_cartera'
      and C.tabla = T.codigo
      and C.codigo = tcca
      and C.estado = 'V'
  order by tcca

end


--Guarda log auditoria
--II CMI 02Dic2006

        select @w_param_busqueda = substring(@i_codigo_externo, 1, 24)
        if @i_opcion = 'S'
                select @w_param_busqueda = convert(varchar(24), @i_fecha_fin)
        
        /*exec @w_error = cob_cartera..sp_trnlog_auditoria_activas
        @s_ssn          = @s_ssn,                   
        @i_cod_alterno  = 0,
        @t_trn          = @t_trn,
        @i_producto     = '19',      
        @s_date         = @s_date,
        @s_user         = @s_user,
        @s_term         = @s_term,
        @s_rol          = @s_rol,
        @s_ofi          = @s_ofi,
        @i_tipo_trn     = @i_opcion,
        @i_num_banco    = @w_param_busqueda,
        @i_cliente      = @i_cliente

        if @w_error <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1903003
                return 1 
        end*/

--FI CMI 02Dic2006


return 0
go

