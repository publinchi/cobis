/******************************************************************/
/*   NOMBRE LOGICO:      propagosgrp.sp                           */
/*   NOMBRE FISICO:      sp_prorrateo_pago_grp                    */
/*   BASE DE DATOS:      cob_cartera                              */
/*   PRODUCTO:           Cartera                                  */
/*   DISENADO POR:       Adriana Giler                            */
/*   FECHA DE ESCRITURA: 25-Jun-2019                              */
/******************************************************************/
/*                     IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios que son     */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,*/
/*   representantes exclusivos para comercializar los productos y */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituid*/
/*   y regida por las Leyes de la República de España y las       */
/*   correspondientes de la Unión Europea. Su copia, reproducción,*/
/*   alteración en cualquier sentido, ingeniería reversa,         */
/*   almacenamiento o cualquier uso no autorizado por cualquiera  */
/*   de los usuarios o personas que hayan accedido al presente    */
/*   sitio, queda expresamente prohibido; sin el debido           */
/*   consentimiento por escrito, de parte de los representantes de*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto*/
/*   en el presente texto, causará violaciones relacionadas con la*/
/*   propiedad intelectual y la confidencialidad de la información*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles*/
/*   y penales en contra del infractor según corresponda.         */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Prorratera el abono de un padre en relación a la hija      */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  26Jun19            Adriana Giler    Emision Inicial           */
/*  14Ene21      Patricio Narvaez  Correccion siguientes          */
/*  20Oct21      Guisela Fernandez  Ingreso de secuencial de tran-*/
/*                                  y campo solidario             */
/*  25Abr22      Guisela Fernandez Se comenta proceso de obtención*/
/*                                 para operaciones grupales hijas*/
/*  12Jul22      Guisela Fernandez Se cambia campo de secuencial  */
/*                                 para la paginación             */
/*  10Ago22      Guisela Fernandez R191162 Ingreso de campo de    */
/*                                 descripción                    */
/*  12Mar24      K. Rodriguez   R221782- Ajus. consulta abn-grupal*/
/******************************************************************/


use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_prorrateo_pago_grp')
   drop proc sp_prorrateo_pago_grp
go

create proc sp_prorrateo_pago_grp
   @s_user                 login            = null,
   @s_date                 datetime         = null,
   @i_operacionca          int,
   @i_banco                cuenta,
   @i_formato_fecha        int              = null,
   @i_secuencial_ing       int              = 0,
   @i_operacion            char(1),
   @i_sec_detpago          int              = 0
  
   
as declare
   @w_sp_name             varchar(30),
   @w_return              int,
   @w_monto_hija          money,
   @w_monto_padre         money,
   @w_oper_padre          int,
   @w_porcentaje          money,
   @o_error               int,
   @w_contador            int,
   @w_dtr_dividendo       int,
   @w_dtr_concepto        catalogo,
   @w_dtr_estado          char(20),
   @w_dtr_cuenta          cuenta,
   @w_dtr_moneda          char(20),
   @w_dtr_monto           money,
   @w_dtr_monto_mn        money,
   @w_secuencial_apl      int,
   @w_op_migrada          varchar(20),
   @w_tipo_operacion      char(1),
   @w_operacionca         int,
   @w_cont_oper           smallint,
   @w_cont_det_pags       smallint,
   @w_sec_tabla           int
   
select @w_sp_name = 'sp_busqueda_grupales',
       @w_return  = 0 ,
       @w_porcentaje = 1

--GFP se comenta calculo de porcentaje no aplica a FINCA
--Es operacion Grupal Hijas con Administración Individual
/*
if exists (select 1 from ca_operacion 
           where op_operacion = @i_operacionca
           and op_grupal = 'S'
           and op_ref_grupal > ''
           and op_admin_individual = 'S')  
begin           
    select @w_monto_padre = P.op_monto,
           @w_monto_hija  = H.op_monto,
           @w_oper_padre  = P.op_operacion
    from ca_operacion P, ca_operacion H
    where H.op_operacion = @i_operacionca
      and P.op_banco     = H.op_ref_grupal
  
  
    select @w_porcentaje = (@w_monto_hija * 100) / @w_monto_padre
end
*/

-- Tipo de operación [G: Grupal Padre, H: Grupal Hija, N: Individual]
exec @w_return = sp_tipo_operacion
@i_banco    = @i_banco,
@i_en_linea = 'N',
@o_tipo     = @w_tipo_operacion out

if @w_return <> 0
   return @w_return

--- CONSULTAR ABONOS
if @i_operacion = 'A'    
Begin
   
   --LPO Ajustes por migracion a Java INICIO     
   CREATE TABLE #consulta_abono (
   Sec_ing           INT NULL ,
   Sec_pag           INT NULL ,
   Fecha_Ing         VARCHAR(12) NULL,
   Fecha_Pag         VARCHAR(12) NULL,
   Usuario           VARCHAR(14) NULL,
   Regional          INT NULL,
   Retencion         INT NULL,
   Cuota_Completa    CHAR(1) NULL,
   Anticipos         CHAR(1) NULL,
   Tipo_Reduccion    VARCHAR(10) NULL,
   Tipo_Cobro        CHAR(1) NULL,
   Clase             VARCHAR (10) NULL,
   Forma_de_Pago     VARCHAR (10) NULL,
   Moneda            INT NULL,
   Cuenta_Referencia VARCHAR (24) NULL,
   Comentario        VARCHAR (50) NULL,
   Monto             MONEY NULL,
   Estado            VARCHAR (10) NULL, --LPO CDIG se amplia la longitud del tipo de dato de 1 a 10
   Sec_consulta      INT IDENTITY,
   Cod_banco         varchar(10),
   Sec_trans_banco   INT NULL,       --GFP Ingreso de secuncial de transaccion de banco
   Solidario         CHAR(1) NULL,    --GFP Ingreso de abono solidario
   Descripcion       VARCHAR (50) NULL
   )
   
   INSERT INTO #consulta_abono (Sec_ing,Sec_pag,Fecha_Ing,Fecha_Pag,Usuario,Regional,Retencion,Cuota_Completa,Anticipos,
                                Tipo_Reduccion,Tipo_Cobro,Clase,Forma_de_Pago,Moneda,Cuenta_Referencia,Comentario,Monto,
                                Estado, Cod_banco,Sec_trans_banco,Solidario,Descripcion)
   select
   ab_secuencial_ing,
   ab_secuencial_pag,
   substring(convert(varchar,ab_fecha_ing,@i_formato_fecha),1,15),
   substring(convert(varchar,ab_fecha_pag,@i_formato_fecha),1,15),
   ab_usuario,
   ab_oficina,
   ab_dias_retencion,
   ab_cuota_completa,
   ab_aceptar_anticipos,
   ab_tipo_reduccion,
   ab_tipo_cobro,
   abd_tipo,
   abd_concepto,
   abd_moneda,
   substring(abd_cuenta,1,24),
   substring(abd_beneficiario,1,50),
   (abd_monto_mpg * @w_porcentaje),
   ab_estado,
   abd_cod_banco,
   abd_secuencial_interfaces,  --GFP Ingreso de secuencial de transaccion de banco
   abd_solidario,              --GFP Ingreso de abono solidario
   abd_descripcion
   from  ca_abono,
         ca_abono_det
   where ab_operacion = @i_operacionca
   and   ab_operacion = abd_operacion
   and   ab_secuencial_ing = abd_secuencial_ing
   order by abd_operacion, ab_secuencial_ing
--LPO Ajustes por migracion a Java FIN

    set rowcount 20  --GFP 12Jul22
    
    select
    Sec_ing   ,
    Sec_pag   ,
    Fecha_Ing ,
    Fecha_Pag ,
    Usuario   ,
    Regional  ,
    Retencion ,
    Cuota_Completa,
    Anticipos,
    Tipo_Reduccion,
    Tipo_Cobro,
    Clase,
    Forma_de_Pago,
    Moneda,
    Cuenta_Referencia,
    Comentario,
    Monto,
    Estado,
    Sec_consulta,    
    Cod_banco,       
    convert(varchar(24),Sec_trans_banco), --GFP Ingreso de secuncial de transaccion de banco
    Solidario,                             --GFP Ingreso de abono solidario
    Descripcion
    from  #consulta_abono
    where Sec_consulta > @i_secuencial_ing  --GFP 12Jul22
    order by Sec_consulta
    
    set rowcount 0
   
End

--- CONSULTA DEL DETALLE DEL ABONO
if @i_operacion = 'D'
begin
    if @i_sec_detpago = 0 and @w_op_migrada is null
    begin
	
      ---Elimina todo lo del usuario para insertar nuevamente
      delete from ca_consulta_rec_pago_tmp
      where usuario = @s_user
	  
      if object_id('tempdb..#tmp_consulta_rec_pago') is not null
         drop table #tmp_consulta_rec_pago
		 
	  select * into #tmp_consulta_rec_pago from ca_consulta_rec_pago_tmp where 1=2
	  
      if object_id('tempdb..#operaciones_pagos') is not null
         drop table #operaciones_pagos
		 
      create table #operaciones_pagos(
      operacion      int not null,
      secuencia_pag  int not null)

	  if @w_tipo_operacion = 'G'
	  begin
	           
         insert into #operaciones_pagos
         select ab_operacion, ab_secuencial_pag 
         from ca_operacion with (nolock), ca_abono with (nolock)
		 where op_ref_grupal = @i_banco
		 and ab_operacion = op_operacion
		 and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
         
         if @@rowcount = 0
            return 701119 -- No existe Registro de Abono
   
	  end
	  
      if @w_tipo_operacion in ('H', 'N')
	  begin
	  
         insert into #operaciones_pagos
         select ab_operacion, ab_secuencial_pag
         from   ca_abono with (nolock)
         where  ab_secuencial_ing = @i_secuencial_ing
         and    ab_operacion = @i_operacionca
         
         if @@rowcount = 0
            return 701119 -- No existe Registro de Abono
	  
	  end
	  
      select @w_cont_oper = count(1) 
	  from #operaciones_pagos -- Si es Individual o Hija, este count es 1

      -- Recorre operación individual/hija u operaciones hijas que participaron en el pago de la referencia grupal 
      while @w_cont_oper > 0
      begin
	  
         select top 1
         @w_operacionca    = operacion,
	     @w_secuencial_apl = secuencia_pag
         from #operaciones_pagos
		 
         if object_id('tempdb..#det_pagos') is not null
            drop table #det_pagos
		    
         create table #det_pagos(
		 sec_tabla  int      identity not null,
         dividendo  int      not null,
         concepto   catalogo not null,
		 estado     char(20) not null,
		 cuenta     cuenta   not null,
		 moneda     char(20) not null,
		 monto      money    not null,
		 monto_mn   money    not null)
		 
		 insert into #det_pagos
		 select dtr_dividendo,
                dtr_concepto,
                substring((select es_descripcion from ca_estado  where es_codigo = ca_det_trn.dtr_estado),1,10),
                rtrim(ltrim(dtr_cuenta)),
                substring((select convert(varchar(2),mo_moneda) + '-' + mo_descripcion from cobis..cl_moneda
                           where mo_moneda = ca_det_trn.dtr_moneda),1,10),
                convert(float, (dtr_monto * @w_porcentaje)),   
				convert(float, (dtr_monto_mn * @w_porcentaje))
         from  ca_det_trn with (nolock)
         where dtr_secuencial = @w_secuencial_apl
         and   dtr_operacion  = @w_operacionca
         and   dtr_codvalor <> 10099
		 
         select @w_cont_det_pags = count(1) 
         from #det_pagos
		 
		 select @w_contador = 0

         -- Recorre detalles de pago de la operacion
         while @w_cont_det_pags > 0
         begin
		    
            select top 1
			@w_sec_tabla       = sec_tabla,
            @w_dtr_dividendo   = dividendo,
            @w_dtr_concepto    = concepto ,
            @w_dtr_estado      = estado   ,
            @w_dtr_cuenta      = cuenta   ,
            @w_dtr_moneda      = moneda   ,
            @w_dtr_monto       = monto    ,
            @w_dtr_monto_mn    = monto_mn 
            from #det_pagos
		 
			select @w_contador = @w_contador + 1
			
            ---cargar la tabla temporal
            insert into #tmp_consulta_rec_pago (
            identifica,       secuencial,        usuario,
            descripcion,      cuota,             dias,
            fecha_ini,        fecha_fin,         monto,
            monto_mn,         tasa,              des_moneda,
            des_estado,       operacion,         cuenta)
            values(
            'DOP',            @w_contador,       @s_user,
            @w_dtr_concepto,  @w_dtr_dividendo,  0,
            @s_date,          @s_date,           @w_dtr_monto,
            @w_dtr_monto_mn,  0,                 @w_dtr_moneda,
            @w_dtr_estado,    @i_operacionca,    @w_dtr_cuenta)
			
            delete #det_pagos where sec_tabla = @w_sec_tabla
            set @w_cont_det_pags = (select count(1) from #det_pagos)
			
		 end
		  
         delete #operaciones_pagos where operacion = @w_operacionca
         set @w_cont_oper = (select count(1) from #operaciones_pagos)
	  
	  end
	  
      if object_id('tempdb..#operaciones_pagos') is not null
         drop table #operaciones_pagos
		
      insert into ca_consulta_rec_pago_tmp
      select 'DOP'                      , row_number() over (order by cuota), @s_user  , descripcion,
             cuota                      , 0                                 , @s_date  , @s_date,
             sum(convert(float, monto)) , sum(convert(float, monto_mn))     , 0        , des_moneda,
             des_estado                 , @i_operacionca                    , cuenta
      from #tmp_consulta_rec_pago
      where usuario  = @s_user
      and   identifica in( 'DOP','TOTALES')
      and   operacion  = @i_operacionca
      and   secuencial > @i_sec_detpago
      group by cuota, descripcion, des_estado, cuenta, des_moneda
      order by cuota
	  
   end --secuencial = 0

   set rowcount 20

   select 'Dividendo'  = cuota,
          'Concepto'   = descripcion,
          'Estado'     = des_estado,
          'Cuenta'     = cuenta,
          'Moneda'     = des_moneda,
          'Monto MOP'  = convert(float, monto),
          'Monto MLE'  = convert(float, monto_mn),
          'Sec'        = secuencial
   from ca_consulta_rec_pago_tmp
   where usuario  = @s_user
   and   identifica in( 'DOP','TOTALES')
   and   operacion  = @i_operacionca
   and   secuencial > @i_sec_detpago
   order by secuencial
   
   set rowcount 0

end

return 0

go





