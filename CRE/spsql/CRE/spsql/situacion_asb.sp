/************************************************************************/
/*  Archivo:                situacion_asb.sp                            */
/*  Stored procedure:       sp_situacion_asb                            */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_situacion_asb')
    drop proc sp_situacion_asb
go

create proc sp_situacion_asb (
   @s_ssn	        int = null,
   @s_user		login = null,
   @s_sesn		int = null,
   @s_term		descripcion = null, --MTA
   @s_date		datetime = null,
   @s_srv		varchar(30) = null,
   @s_lsrv		varchar(30) = null,
   @s_rol		smallint = NULL,
   @s_ofi		smallint = NULL,
   @s_org_err		char(1) = NULL,
   @s_error		int = NULL,
   @s_sev		tinyint = NULL,
   @s_msg		descripcion = NULL,
   @s_org		char(1) = NULL,
   @t_rty               char(1)  = null,
   @t_trn               smallint = null,
   @t_debug             char(1)  = 'N',
   @t_file              varchar(14) = null,
   @t_from              varchar(30) = null,
   @t_show_version bit = 0, -- Mostrar la version del programa
   @i_tramite           int         = 0,
   @i_operacion_i       int         = 0,
   @i_limite            char(1)     = null,  -- S si N no
   @i_aprobado          char(1)     = null,  -- S si N no
   @i_cliente		int         = null,
   @i_cliente_sig       int         = 0,
   @i_grupo             int         = null,
   @i_operacion         char(1)     = null,
   @i_modo              int         = null,
   @i_en_tramite        char(1)     = null,
   @i_retorna           char(1)     = 'S',   
   @i_cabecera          char(1)     = null,
   @i_operacion_ban     cuenta      = ' ',
   @i_usuario           login       = null,
   @i_secuencia         int         = null,
   @i_bandera           char(1)     = null,
   @i_consulta          char(1)     = 'I',   --I=Riesgo Individual   T=Total
   @i_modo_c            char(2)     = 'T',   -- Modo de Consulta 1=individual o 2=total
   @i_carga             char(2)     = 'T',   -- Modo de Consulta 1=individual o 2=total
   @i_categoria         char(2)     = null,   -- Modo de Consulta 1=individual o 2=total
   @i_formato_fecha     int         = null,
   @i_tramite_d         int         = null,
   @i_tipo_deuda        char(1)     = 'D',	--Vivi
   @i_prendario         char(1)     = 'S',      --Familia Prendaria
   @i_impresion         char(1)     = 'S',  --Si se lo llama desde la impresion del MAC viene 'N'
   @i_desde_front       char(1)     = 'N',  --Si viene desde las pantallas de Credito, Forigin..etc
   @i_vista_360	        char(1)     = 'N',  -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
   @i_act_can           char(1)		= 'N',   -- ECA: para determinar si se conuslta las operaciones canceladas
   @i_grupo_vinculado   char(1)     = 'N',
   @o_total_deuda       money       = null out
)
as

declare
   @w_sp_name		 descripcion,
   @w_today              datetime,
   @w_rela_identico	 tinyint,
   @w_rela_natural	 smallint,
   @w_rela_juridico	 smallint,
   @w_cliente_tmp        int,
   @w_tipo_deuda         char(1),
   @w_return             int,
   @w_error              int,
   @w_cliente_con        int,
   @w_tipo_con           char(1),
   @w_tipo_cliente       char(1),
   @w_spid              smallint --OCU#


select @w_today = getdate()
select @w_sp_name = 'sp_situacion_asb'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_asb, Version 4.0.0.3'
    return 0
end

--OCU# obtengo numero de proceso 
select @w_spid = @@spid

--/**************** BLOQUEADO HASTA ADAPTAR VERSION (MSU)
--print 'SIASB Usuario .. %1! Secuencia .. %2! ', @s_user, @s_sesn

/* Generacion de Tablas         */

if @i_operacion = 'I'
begin
   if  @i_cliente is null and @i_grupo is null and @i_tramite is null
   begin
       /* Campos NOT NULL con valores nulos */
       exec cobis..sp_cerror
   	 @t_debug = @t_debug,
	 @t_file  = @t_file, 
	 @t_from  = @w_sp_name,
	 @i_num   = 2101001
    return  1 
   end

											 
											   
   if @i_carga = 'C' or @i_carga = 'T'
   begin

      --OCU#  comento creacion de tanla temporal para cambiar a tabla fisica
      if @i_desde_front = 'S' and @i_cliente is not null
      begin

         if exists( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_cliente ) 
            select @i_grupo   = cg_grupo,
                   @i_cliente = null
              from cobis..cl_cliente_grupo, cobis..cl_grupo_view
             where cg_ente  = @i_cliente 
               and cg_grupo = gr_grupo
               and gr_tipo_grupo <> ( select pa_char from cobis..cl_parametro where pa_nemonico = 'GEE' and pa_producto = 'CLI')
               and gr_grupo <> ( select convert(int, pa_char ) from cobis..cl_parametro where pa_nemonico = 'GRUBAN' and pa_producto = 'CRE')

      end

      if @i_cliente is not null  and @i_cliente <> 0-- Inserta el cliente
      begin
         select @w_tipo_con = 'C'
         select @w_cliente_con = @i_cliente        

         select  @w_tipo_cliente = '0' --en_party
         from cobis..cl_ente
         where en_ente = @i_cliente

         insert into cr_clientes_tmp --#cr_clientes_tmp  --OCU#
                   (spid, ct_tramite,ct_usuario, ct_ssn, ct_tipo_con, ct_cliente_con, ct_cliente, 
	           ct_relacion)
         values ( @w_spid, @i_tramite, @s_user,   @s_sesn,  @w_tipo_con, @i_cliente,   @i_cliente, 'D')

         --Vivi - CD00034
         if @i_tramite is not null
            insert into cr_clientes_tmp --#cr_clientes_tmp  --OCU#
                   (spid, ct_tramite,ct_usuario, ct_ssn, ct_tipo_con, ct_cliente_con, ct_cliente, ct_relacion, ct_identico)
            select @w_spid, @i_tramite, @s_user,  @s_sesn, @w_tipo_con,  @i_cliente, de_cliente, de_rol, null
              from cr_deudores
             where de_tramite = @i_tramite
               --and de_rol     = 'C'
      end
      else
      --Inserta el grupo
      if @i_grupo is not null and @i_grupo <> 0
      begin
         select @i_modo = 1 -- Por cuentas individuales, no total           
         --SRO Grupo Solidario
         select @w_tipo_con = gr_tipo from cobis..cl_grupo_view where gr_grupo = @i_grupo
         select @w_cliente_con = @i_grupo

         --SRO 05/29/2009 Cuando es grupo debe guardar el codigo del cliente del grupo
         --#cr_clientes_tmp  --OCU# 
         insert into cr_clientes_tmp(spid, ct_tramite,ct_usuario, ct_ssn, ct_tipo_con, ct_cliente_con, ct_cliente, ct_relacion, ct_identico)
         select @w_spid, @i_tramite, @s_user, @s_sesn, @w_tipo_con,@i_grupo, cg_ente,  'D', null
         from  cobis..cl_cliente_grupo
         where  cg_grupo = @i_grupo
        --SRO Grupo Solidario
        if @w_tipo_con = 'S'
        begin

												
            insert into cr_clientes_tmp (spid, ct_tramite,ct_usuario, ct_ssn, ct_tipo_con, ct_cliente_con, ct_cliente, ct_relacion)
            values ( @w_spid, @i_tramite, @s_user,   @s_sesn,  @w_tipo_con, @i_grupo,  @i_grupo, 'D')
        end


         
     if @i_grupo_vinculado = 'S' and @i_grupo = 0
        begin
         --MDI 08/24/2012 Cuando es grupo vinculado debe guardar el codigo del cliente de clientes vinculados al banco

           select @w_tipo_con = 'V'

         insert into cr_clientes_tmp --#cr_clientes_tmp  --OCU#
                   (spid, ct_tramite, ct_usuario, ct_ssn,   ct_tipo_con, ct_cliente_con, ct_cliente, ct_relacion)
             select @w_spid, @i_tramite, @s_user,    @s_sesn,  @w_tipo_con, en_ente,       en_ente,   'D'  
             from cobis..cl_ente
             where en_vinculacion = 'S'
             union
             select @w_spid, @i_tramite, @s_user,    @s_sesn,  @w_tipo_con, cg_ente,       cg_ente,   'D'  
             from cobis..cl_grupo_view, cobis..cl_cliente_grupo
             where gr_vinculacion = 'S'
               and cg_grupo = gr_grupo

       end

      end
      else
      begin
         --Vivi - CD00034
         if @i_tramite is not null and @i_tramite <> 0
         begin
            select @i_cliente = de_cliente
              from cr_deudores
             where de_tramite = @i_tramite
               and de_rol     = 'D'

            insert into cr_clientes_tmp --#cr_clientes_tmp  --OCU#
                   (spid, ct_tramite,ct_usuario, ct_ssn, ct_tipo_con, ct_cliente_con, ct_cliente, ct_relacion, ct_identico)
            select @w_spid, @i_tramite, @s_user,  @s_sesn, @w_tipo_con,  @i_cliente, de_cliente, de_rol, null
              from cr_deudores
             where de_tramite = @i_tramite
         end
      end

    -- Elimino los clientes anteriores

   delete cr_situacion_cliente
   where sc_usuario = @s_user

   delete cr_situacion_deudas
   where sd_usuario = @s_user

   delete cr_situacion_inversiones
   where si_usuario = @s_user

   delete cr_situacion_lineas
   where  sl_usuario   = @s_user

   delete cr_situacion_gar
   where  sg_usuario    = @s_user

   delete cr_situacion_gar_p
   where  sg_p_usuario   = @s_user

   delete cr_situacion_poliza
   where  sp_usuario   = @s_user

   delete cr_situacion_otras
   where  so_usuario   = @s_user

   -- Pasar de la tabla temporal a la definitiva los datos de los clientes
   insert into cr_situacion_cliente 
              (sc_tramite, sc_usuario, sc_secuencia, sc_tipo_con, 
               sc_cliente_con, sc_cliente, sc_identico, sc_rol)

   select distinct ct_tramite, ct_usuario, ct_ssn, ct_tipo_con, 
                   ct_cliente_con, ct_cliente, ct_identico, ct_relacion		--Vivi
   from  cr_clientes_tmp --#cr_clientes_tmp  --OCU#
   where spid = @w_spid --OCU#
   end -- (i_carga = C)

   --IOR nombre cliente para Vcc
   UPDATE cr_situacion_cliente
   SET sc_nombre_cliente = en_nomlar
   FROM cobis..cl_ente
   WHERE sc_cliente = en_ente
   --PQU correccion porque en grupos el i_cliente es 0  and en_ente = @i_cliente
   and sc_secuencia = @s_sesn

    --SRO Grupo Solidario
   UPDATE cr_situacion_cliente
   SET sc_nombre_cliente = gr_nombre
   FROM cobis..cl_grupo_view
   WHERE sc_cliente = gr_grupo
   and sc_cliente = @i_grupo
   and sc_secuencia = @s_sesn  --PQU correccion
   
   -- Carga de datos de operaciones, lineas y garantias, de los clientes que fueron ingresados en la 
   -- tabla cr_situacion_cliente
   --print 'bandera %1!', @i_bandera

   if @i_bandera <> 'N'
   begin
      select @s_user,
             @s_sesn
   end

   if @i_carga = 'I' or @i_carga = 'T'
   begin
      exec @w_return = sp_situacion_inversiones
      @s_sesn    = @s_sesn,
      @s_user    = @s_user,
      @s_date    = @s_date,
      @i_tramite = @i_tramite,
										 
																												 
	  @i_act_can   = @i_act_can

      if @w_return <> 0
         return @w_return     
   end

   if @i_carga = 'D' or @i_carga = 'T'
   begin
      exec @w_return = sp_situacion_deudas
         @s_user      = @s_user,
         @s_sesn      = @s_sesn,
         @s_date      = @s_date,
         @i_limite    = @i_limite,
         @i_aprobado  = @i_aprobado,
         @i_tramite   = @i_tramite,
         @i_cliente   = @i_cliente, 	--Vivi
         @i_grupo     = @i_grupo, 		--SRO 12/JUN/2009 Grupos Economicos
         @i_tipo_deuda  = @i_tipo_deuda,	--Vivi
										 
         @i_formato_fecha = @i_formato_fecha,
         @i_impresion   = @i_impresion,
		 @i_act_can   = @i_act_can

     if @w_return <> 0
         return @w_return
   end

   if @i_carga = 'L' or @i_carga = 'T'
   begin
      exec @w_return = sp_situacion_lineas
       @s_user  = @s_user,
       @s_sesn  = @s_sesn,
       @s_date  = @s_date,
       @i_tramite  = @i_tramite,
       @i_tramite_d   = @i_tramite_d,
       @i_cliente     = @i_cliente, 		--Vivi
       @i_grupo       = @i_grupo,      --SRO 12/JUN/2009 Enviar Grupo para vinculacion 
       @i_tipo_deuda  = @i_tipo_deuda,	--Vivi
       @i_prendario   = @i_prendario,
       @i_impresion   = @i_impresion,  --Si se lo llama desde la impresion del MAC viene 'N'
	   --PQU @i_vista_360 = @i_vista_360, -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS																										  
	   @i_act_can   = @i_act_can
     if @w_return <> 0
         return @w_return

        -- Contingentes Limites de tarjetas de credito
/*
        exec @w_return = cob_atm..sp_atm_con_tarj 
                @s_sesn     = @s_sesn, 
                @s_user     = @s_user,
                @s_date     = @s_date,
                @t_trn      = 16967,
                @i_operacion= 'L', -- Operacion: 'L - Limite de Tarjetas'
                @i_cliente  = @i_cliente,
                @i_grupo    = @i_grupo

        if @w_return != 0
        begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2103001
            rollback
            return 1 
        end
*/


   end 

   if @i_carga = 'G' or @i_carga = 'T'
   begin  
      exec @w_return   = sp_situacion_gar           -- de las operaciones en deuda
           @s_user     = @s_user,
           @s_sesn     = @s_sesn,
           @s_date     = @s_date,
           @i_subopcion= 'D',
           @i_tramite  = @i_tramite,
           @i_cliente  = @i_cliente,
           @i_impresion= @i_impresion,  --Si se lo llama desde la impresion del MAC viene 'N'
           @i_vista_360 = @i_vista_360, -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
           @i_act_can   = @i_act_can,
           @i_grupo 	= @i_grupo
      if @w_return <> 0
         return @w_return
   end

   if @i_carga = 'GP' or @i_carga = 'T'
   begin
      exec @w_return   = sp_situacion_gar                    -- de los clientes (cu_cliente_garantia)
           @s_user     = @s_user,
           @s_sesn     = @s_sesn,
           @s_date     = @s_date,
           @i_subopcion= 'P',
           @i_tramite  = @i_tramite,
           @i_cliente  = @i_cliente,
           @i_impresion= @i_impresion,  --Si se lo llama desde la impresion del MAC viene 'N'
           @i_vista_360 = @i_vista_360, -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
           @i_act_can   = @i_act_can,
           @i_grupo 	= null
      if @w_return <> 0
          return @w_return
   end

   /**  POLIZAS DEL CLIENTE  **/
   if @i_carga = 'P' or @i_carga = 'T'
   begin
      exec @w_return = sp_situacion_poliza  
           @s_user         = @s_user,
           @s_sesn         = @s_sesn,
           @s_date         = @s_date,
           @i_tramite      = @i_tramite,
           @i_tramite_d    = @i_tramite_d,
           @i_cliente      = @i_cliente,
           @i_tipo_deuda   = @i_tipo_deuda,
           @i_impresion    = @i_impresion,  --Si se lo llama desde la impresion del MAC viene 'N'
           @i_formato_fecha= @i_formato_fecha,
		   --PQU @i_vista_360 = @i_vista_360, -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS																										  
		   @i_act_can   = @i_act_can
      if @w_return <> 0
          return @w_return
   end

end -- Operacion 'I'

--Entrega Datos Detallados

if @i_operacion = 'S'
begin
   /** CONSULTA DE INFORMACION DEL CLIENTE O AFILIACIONES A GLOBAL NET**/
   if @i_modo_c = 'C' or @i_modo_c = 'A' 
   begin
      exec @w_return = sp_situacion_consulta
           @s_user          = @s_user,
           @s_sesn          = @s_sesn,
           @s_date          = @s_date,
           @i_usuario       = @i_usuario,
           @i_secuencia     = @i_secuencia,
           @i_modo_c        = @i_modo_c,
           @i_cliente       = @i_cliente,
           @i_grupo         = @i_grupo,  --SRO 06/03/2009 Envio grupo
           @i_cliente_sig   = @i_cliente_sig,
           @i_operacion     = @i_operacion,
           @i_formato_fecha = @i_formato_fecha,
           @i_tramite       = @i_tramite,
           @i_tramite_d     = @i_tramite_d,
           @i_operacion_ban = @i_operacion_ban,
           @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
           @i_vista_360     = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS

      if @w_return <> 0
         return @w_return
   end 

   if @i_modo_c = 'I' or @i_modo_c = 'T'
   begin
      exec @w_return        = sp_situacion_consulta
           @s_user          = @s_user,
           @s_sesn          = @s_sesn,
           @s_date          = @s_date,
           @i_modo_c        = @i_modo_c,
         --  @i_cliente     = @i_cliente,
           @i_operacion     = @i_operacion,
           @i_operacion_ban = @i_operacion_ban,
           @i_modo          = @i_modo,
           @i_usuario       = @i_usuario,
           @i_secuencia     = @i_secuencia,
           @i_categoria     = @i_categoria,
           @i_operacion_i   = @i_operacion_i,
           @i_formato_fecha = @i_formato_fecha,
           @i_tramite       = @i_tramite,
           @i_tramite_d     = @i_tramite_d,
           @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
           @i_vista_360     = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
      if @w_return <> 0
         return @w_return
   end

   if @i_modo_c = 'D' or @i_modo_c = 'T'
   begin
      exec @w_return        = sp_situacion_consulta
           @s_user          = @s_user,
           @s_sesn          = @s_sesn,
           @s_date          = @s_date,
           @i_modo_c        = @i_modo_c,
           @i_modo          = @i_modo,
           @i_cliente       = @i_cliente,
           @i_grupo         = @i_grupo,  --SRO 06/03/2009 Envio grupo
           @i_operacion     = @i_operacion,
           @i_limite        = @i_limite,
           @i_operacion_ban = @i_operacion_ban,
           @i_tramite       = @i_tramite,
           @i_cabecera      = @i_cabecera,
           @i_usuario       = @i_usuario,
           @i_secuencia     = @i_secuencia,
           @i_formato_fecha = @i_formato_fecha,
           @i_tramite_d     = @i_tramite_d,
           @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
           @i_vista_360 = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS

      if @w_return <> 0
         return @w_return
   end

   if @i_modo_c = 'L' or @i_modo_c = 'T'
   begin
      exec @w_return        = sp_situacion_consulta
           @s_user          = @s_user,
           @s_sesn          = @s_sesn,
           @s_date          = @s_date,
           @i_modo_c        = @i_modo_c,
           @i_operacion_ban = @i_operacion_ban,
           @i_tramite       = @i_tramite,
           @i_cliente       = @i_cliente,
           @i_grupo         = @i_grupo,  --SRO 06/03/2009 Envio grupo
           @i_operacion     = 'S',
           @i_usuario       = @i_usuario,
           @i_secuencia     = @i_secuencia,
           @i_formato_fecha = @i_formato_fecha,
           @i_tramite_d     = @i_tramite_d,
           @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
           @i_vista_360     = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS

      if @w_return <> 0
         return @w_return
   end

   if @i_modo_c = 'G' or @i_modo_c = 'T'
   begin
      exec @w_return        = sp_situacion_consulta
           @s_user          = @s_user,
           @s_sesn          = @s_sesn,
           @s_date          = @s_date,
           @i_modo_c        = @i_modo_c,
           @i_operacion     = @i_operacion,
           @i_operacion_ban = @i_operacion_ban,
           @i_usuario       = @i_usuario,
           @i_secuencia     = @i_secuencia,
           @i_formato_fecha = @i_formato_fecha,
           @i_tramite       = @i_tramite,
           @i_cliente       = @i_cliente,
           @i_grupo         = @i_grupo,  --SRO 06/03/2009 Envio grupo
           @i_tramite_d     = @i_tramite_d,
           @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
           @i_vista_360     = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS

      if @w_return <> 0
         return @w_return
   end
    
    if @i_modo_c = 'GP' or @i_modo_c  = 'T'
    begin
       exec @w_return        = sp_situacion_consulta
            @s_user          = @s_user,
            @s_sesn          = @s_sesn,
            @s_date          = @s_date,
            @i_modo_c        = @i_modo_c,
            @i_operacion     = @i_operacion,
            @i_operacion_ban = @i_operacion_ban,
            @i_usuario       = @i_usuario,
            @i_secuencia     = @i_secuencia,
            @i_formato_fecha = @i_formato_fecha,
            @i_tramite       = @i_tramite,
            @i_cliente       = @i_cliente,
            @i_grupo         = @i_grupo,  --SRO 06/03/2009 Envio grupo
            @i_tramite_d     = @i_tramite_d,
            @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
            @i_vista_360     = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS

      if @w_return <> 0
         return @w_return
   end

   /** POLIZAS DEL CLIENTE O TRAMITE **/
   --Vivi
    if @i_modo_c = 'P' or @i_modo_c  = 'T'
    begin
       exec @w_return        = sp_situacion_consulta
            @s_user          = @s_user,
            @s_sesn          = @s_sesn,
            @s_date          = @s_date,
            @i_modo_c        = @i_modo_c,
            @i_operacion     = @i_operacion,
            @i_usuario       = @i_usuario,
            @i_secuencia     = @i_secuencia,
            @i_formato_fecha = @i_formato_fecha,
            @i_tramite       = @i_tramite,
            @i_tramite_d     = @i_tramite_d,
            @i_tipo_deuda    = @i_tipo_deuda,
            @i_vista_360     = @i_vista_360 -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS

      if @w_return <> 0
         return @w_return
   end
end        


-- Devolver datos sumarizados
-- Utilizado en tramites y limites
if @i_operacion = 'C'
begin
   exec @w_return = sp_situacion_consulta
        @s_user        = @s_user,
        @s_sesn        = @s_sesn,
        @s_date        = @s_date,
        @i_modo_c      = 'C',
        @i_en_tramite  = @i_en_tramite,  --'S'  incluye operaciones en TRAMITE / 'N'  no inlcuye tramites solo OPERACIONES
        @i_cliente     = @i_cliente,
        @i_grupo       = @i_grupo,
        @i_operacion   = @i_operacion,
        @i_limite      = @i_limite,
        @i_retorna     = @i_retorna,	-- 'S' devuelve select
        @i_categoria   = @i_categoria  ,
        @i_formato_fecha = @i_formato_fecha,
        @i_tramite       = @i_tramite,
        @i_tipo_deuda    = @i_tipo_deuda,	--Vivi
        @i_prendario     = @i_prendario,       --S Considera Familia Prendario, N No considera Prendarios
        @i_aprobado      = @i_aprobado,
	    @i_vista_360     = @i_vista_360, -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
        @o_total_deuda   = @o_total_deuda out   

   if @w_return <> 0
      return @w_return       
end

-- Limpiar tablas de trabajo

if @i_operacion = 'D'
begin
   begin tran
    -- borrar las tablas de consulta para el tramite, usuario y secuencia
 
   delete cr_situacion_cliente
   where  sc_cliente   = @i_cliente
   and    sc_usuario   = @s_user
   and    sc_secuencia = @s_sesn
   and    sc_tramite   = @i_tramite

   if @@error <> 0
   begin
       /*Error en eliminacion de registro */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2107001
       return 1 
   end


   delete cr_situacion_inversiones
   where  si_tramite   = @i_tramite
   and    si_usuario   = @s_user
   and    si_secuencia = @s_sesn

   if @@error <> 0
   begin
       /*Error en eliminacion de registro */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2107001
       return 1 
   end

   delete cr_situacion_deudas
   where  sd_tramite   = @i_tramite
   and    sd_usuario   = @s_user
   and    sd_secuencia = @s_sesn

   if @@error <> 0
   begin
       /*Error en eliminacion de registro */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2107001
       return 1 
   end

   delete cr_situacion_lineas
   where  sl_tramite   = @i_tramite
   and    sl_usuario   = @s_user
   and    sl_secuencia = @s_sesn

   if @@error <> 0
   begin
       /*Error en eliminacion de registro */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from = @w_sp_name,
            @i_num   = 2107001
       return 1 
   end

   delete cr_situacion_gar
   where  sg_tramite    = @i_tramite
   and    sg_usuario    = @s_user
   and    sg_secuencia  = @s_sesn

   if @@error <> 0
   begin
       /*Error en eliminacion de registro */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2107001
       return 1 
   end


   delete cr_situacion_gar_p
   where  sg_p_tramite   = @i_tramite
   and    sg_p_usuario   = @s_user
   and    sg_p_secuencia = @s_sesn

   if @@error <> 0
   begin
       /*Error en eliminacion de registro */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2107001
       return 1 
   end
   commit tran
end
--******************* BLOQUEDADO MSU ************/
delete from cr_clientes_tmp where spid = @w_spid 
return 0

ERROR:
  delete from cr_clientes_tmp where spid = @w_spid 
  exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = @w_error
  return 1


GO

