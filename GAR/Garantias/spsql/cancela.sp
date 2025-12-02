/*************************************************************************/
/*   Archivo:              cancela.sp                                    */
/*   Stored procedure:     sp_cancela                                    */
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

IF OBJECT_ID('dbo.sp_cancela') IS NOT NULL
    DROP PROCEDURE dbo.sp_cancela
go
 
create proc dbo.sp_cancela  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
 --@s_term               varchar(64) = null, --Miguel Aldaz 26/Feb/2015
   @s_term 			  	 varchar(30) = null, --Miguel Aldaz 26/Feb/2015
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @s_rol		 tinyint   = null,	--II CMI 02Dic2006
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_producto           char(64) = null,
   @i_modo               smallint = null,
   @i_cliente            int = null,
   @i_ente               int = null,
   @i_filial 		 tinyint = null,
   @i_sucursal		 smallint = null,
   @i_tipo_cust		 varchar(64) = null,
   @i_custodia 		 int = null,
   @i_moneda             tinyint = null,
   @i_garante  		 int = null,
   @i_opcion             tinyint = null,
   @i_codigo_externo     varchar(64) = null,
   @i_operacion          cuenta      = null,
   @i_formato_fecha      int         = null,
   @i_gasto_adm          smallint    = null,
   @i_pasar              char(1)     = null,
   @i_consulta           char(1)     = null,
   @i_riesgos            char(1)     = null,
   @i_login              varchar(30) = null,
   @i_clave              varchar(30) = null,
   @i_cancelacion_credito char(1)    = null

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_retorno            int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_status             int,
   @w_contador           tinyint,
   @w_riesgos            char(1),
   @w_abierta_cerrada    char(1),
   @w_codigo_externo     varchar(64),
   @w_des_est_custodia   varchar(64),
   @w_des_abcerrada      varchar(64),
   @w_estado             catalogo,
   @w_moneda             tinyint,
   @w_valor_actual       money,
   @w_oficina            smallint,
   @w_ente               int,
   @w_cliente            descripcion,
   @w_ofi_contabiliza    smallint,
   @w_contabilizar       char(1),
   @w_codval             int,  
   @w_tipo_cca           catalogo,
   @w_tabla_rec          smallint,
   @w_tipo               descripcion,
   @w_descripcion        varchar(60)  --LRC 06/16/2010

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_cancela'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19624 and @i_operacion = 'S') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end


if @i_operacion = 'S' and @i_cancelacion_credito is null
begin
   -- CODIGO EXTERNO
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

   select @w_estado = cu_estado, 
          @w_moneda = cu_moneda,
          @w_valor_actual = cu_valor_actual,
          @w_abierta_cerrada = cu_abierta_cerrada,
          @w_oficina = cu_oficina,
          @w_ofi_contabiliza = cu_oficina_contabiliza,
          @w_tipo_cca = cu_tipo_cca,
          @w_tipo = cu_tipo         
     from cu_custodia
    where cu_codigo_externo = @w_codigo_externo

   select @w_ente    = cg_ente,
          @w_cliente = cg_nombre
          --@w_cliente = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre
   from cu_custodia,cu_cliente_garantia --,cobis..cl_ente 
   where cu_codigo_externo = @w_codigo_externo
     and cg_codigo_externo = @w_codigo_externo
     and cg_principal      = 'S'
     --and cg_ente           = en_ente

   if @i_consulta = 'S'
   begin
      exec @w_return = sp_tipo_custodia
      @i_tipo = @i_tipo_cust,
      @t_trn  = 19123,
      @s_user = @s_user, --Miguel Aldaz 26/Feb/2015
	  @s_term = @s_term, --Miguel Aldaz 26/Feb/2015		  
      @i_operacion = 'V',
      @i_modo = 0

      if @w_return <> 0 
      begin
      /* Error de ejecucion  
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901003 */
         return 1 
      end 

      exec @w_return = sp_custopv
      @i_filial     = @i_filial,
      @i_sucursal   = @i_sucursal,
      @i_tipo       = @i_tipo_cust,
      @i_custodia   = @i_custodia,
      @s_user	  = @s_user, --Miguel Aldaz 26/Feb/2015
	  @s_term 	  = @s_term, --Miguel Aldaz 26/Feb/2015	
      @t_trn        = 19565,
      @i_operacion  = 'B',
      @i_modo       = 0
 
      if @w_return <> 0 
      begin
     /* Error de ejecucion 
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901005 */
         return 1 
      end 

      if @w_abierta_cerrada = 'A'
         select @w_des_abcerrada = 'ABIERTA'
      else
         select @w_des_abcerrada = 'CERRADA'

      select @w_des_est_custodia = A.valor
        from cobis..cl_catalogo A,cobis..cl_tabla B
       where B.codigo = A.tabla and
             B.tabla = 'cu_est_custodia' and
             A.codigo = @w_estado

      select @w_estado,
             @w_des_est_custodia,
             @w_des_abcerrada,
             @w_valor_actual, --MVI 07/10/96 para los nuevos datos en frontend
             @w_moneda,
             @w_ente,
             @w_cliente

      exec @w_retorno = sp_riesgos1           -- SE SACAN LOS RIESGOS
      @t_trn            = 19604,
      @s_date           = @s_date,
	  @s_user	  		= @s_user, --Miguel Aldaz 26/Feb/2015
	  @s_term 	  		= @s_term, --Miguel Aldaz 26/Feb/2015	
      @i_operacion      = 'Q',
      @i_codigo_externo = @w_codigo_externo,
      @o_riesgos        = @w_riesgos out

      if @w_retorno <> 0
      begin
      /*  Error en consulta de registro */
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909002
           return 1 
      end
      select @w_riesgos

   end  -- Fin de la Consulta
   else -- Se realiza la Cancelacion
   begin
      if @w_estado <> 'C' 
      -- LA CANCELACION DE LA GARANTIA HACE QUE SU VALOR SEA 0
      begin 
         if @w_estado = 'P'  -- ESTADO PROPUESTO
         begin
         /* No se puede cancelar una garantia con un estado de Propuesta */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1905007
            return 1
         end
        
         if @i_riesgos = 'S' and @i_pasar = 'N'
         begin
            /*  La garantia tiene riesgos, compruebo login y passwd  */
            if exists (select * from cobis..ad_usuario,cobis..ad_usuario_rol,
                                     cobis..ad_tr_autorizada
                        where us_filial  = @i_filial
                          and us_oficina = @i_sucursal
                          and us_login   = @i_login
                          --and us_clave   = @i_clave
                          and us_estado  = 'V'
                          and us_login   = ur_login
                          and ur_rol     = ta_rol
                          and ta_transaccion = 19625) -- Transaccion virtual
               select @i_pasar = 'S'    
            else
               return 2 
         end

         if @i_pasar = 'S'
         begin
            if exists (select * from cu_por_inspeccionar
                       where pi_codigo_externo = @w_codigo_externo)

            delete cu_por_inspeccionar
            where pi_codigo_externo = @w_codigo_externo

            /********
            if exists (select * from cu_vencimiento
                       where ve_codigo_externo = @w_codigo_externo)

            --delete cu_vencimiento
            --where ve_codigo_externo = @w_codigo_externo

            if exists (select * from cu_recuperacion
                       where re_codigo_externo = @w_codigo_externo)

            --delete cu_recuperacion
            --where re_codigo_externo = @w_codigo_externo
            *********/
 
            --II LRC 06/15/2010
            if @w_tipo = 'GARPFI' and @w_abierta_cerrada = 'C'
               select @w_descripcion = 'CANCELACION DE LA GARANTIA MANUAL'
            else
               select @w_descripcion = 'CANCELACION DE LA GARANTIA'
            --FI LRC 06/15/2010

            if @i_login = null
               select @i_login = @s_user
               
            exec @w_status = sp_transaccion
              @s_ssn = @s_ssn,
              @s_ofi = @s_ofi,
              @s_date = @s_date,
			  @s_user = @s_user, --Miguel Aldaz 26/Feb/2015
		      @s_term = @s_term, --Miguel Aldaz 26/Feb/2015				  
              @t_trn = 19000,
              @i_operacion = 'I',
              @i_filial = @i_filial,
              @i_sucursal = @i_sucursal,
              @i_tipo_cust = @i_tipo_cust,
              @i_custodia = @i_custodia,
              @i_fecha_tran = @w_today, --s_date,
              @i_debcred =  'D', 
              @i_valor = @w_valor_actual,
              @i_descripcion = @w_descripcion,  --LRC 06.15.2010
              @i_usuario = @i_login,
              @i_cancelacion = 'S'

              if @w_status <> 0 
              begin
               /* Error en actualizacion de registro */
                 exec cobis..sp_cerror
                    @t_debug = @t_debug,
                    @t_file  = @t_file, 
                    @t_from  = @w_sp_name,
                    @i_num   = 1901013
                    return 1 
              end
 
         -- Aumentado por MVI 08/12/96
         select @w_contabilizar = tc_contabilizar
         from cu_tipo_custodia
         where tc_tipo = @i_tipo_cust
          
         if @w_contabilizar = 'S' 
         begin

            ---Evaluar si se trata de Garantias con 
            ---Reclasificacion Contable
            select @w_codval = 19

            select @w_tabla_rec = codigo
              from cobis..cl_tabla 
             where tabla = 'cu_reclasifica'

             if exists (select codigo
                          from cobis..cl_catalogo
                         where tabla = @w_tabla_rec
                           and codigo = @w_tipo 
                           and estado = 'V')
             begin
               if @w_tipo_cca = null --No existe ya la relacion
                 select @w_codval = 1
               else
                 select @w_codval = 2 --Levanta la Relacion
             end

            --  TRANSACCION CONTABLE 
            exec @w_return = sp_conta
         	@t_trn = 19300,
            @s_date = @s_date,
			@i_operacion = 'I',
			@s_user	  = @s_user, --Miguel Aldaz 26/Feb/2015
		    @s_term 	  = @s_term, --Miguel Aldaz 26/Feb/2015	
		@i_filial = @i_filial,
		@i_oficina_orig = @w_ofi_contabiliza,
 		@i_oficina_dest = @w_ofi_contabiliza,
		@i_tipo = @i_tipo_cust,
		@i_moneda = @w_moneda,
		@i_valor = @w_valor_actual,
		@i_operac = 'E',
		@i_signo = 1,
                @i_codval = @w_codval,
                @i_tipo_cca = @w_tipo_cca,
                @i_codigo_externo = @w_codigo_externo

             if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1901012
                return 1 
            end
         end

      begin tran

         update cu_custodia
         set cu_estado = 'C',
             cu_fecha_modif = @s_date,
             cu_fecha_modificacion = @s_date,
             cu_usuario_modifica = @i_login
         where cu_codigo_externo = @w_codigo_externo

         update cob_credito..cr_gar_propuesta
            set gp_est_garantia = 'C'
          where gp_garantia     = @w_codigo_externo

         ---GCR: Cambiar estado de vencimientos
         update cu_vencimiento
            set ve_estado = 'D'
          where ve_codigo_externo = @w_codigo_externo
            and ve_estado = 'T'          

         select @w_estado = cu_estado
           from cu_custodia
          where cu_codigo_externo = @w_codigo_externo

         select @w_des_est_custodia = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
          where B.codigo = A.tabla and
                B.tabla = 'cu_est_custodia' and
                A.codigo = @w_estado
 

      commit tran
      select @w_estado, @w_des_est_custodia  
         end  -- Pasar (S)i
      end  -- @w_estado <> 'C'
   end  -- Cancelacion 
end

/*   Cancelacion - Eliminacion del registro no utilizado para el Credito   */
if @i_operacion = 'S' and @i_cancelacion_credito = 'S'
begin
        if @i_codigo_externo is not null 
        begin
           exec sp_compuesto
		   @s_user	  = @s_user, --Miguel Aldaz 26/Feb/2015
		   @s_term 	  = @s_term, --Miguel Aldaz 26/Feb/2015	
           @t_trn = 19245,
           @i_operacion = 'Q',
           @i_compuesto = @i_codigo_externo,
           @o_filial    = @i_filial out,
           @o_sucursal  = @i_sucursal out,
           @o_tipo      = @i_tipo_cust out,
           @o_custodia  = @i_custodia out
        end

   -- CODIGO EXTERNO
--   exec sp_externo @i_filial,@i_sucursal,@i_tipo_cust,@i_custodia,
--                   @w_codigo_externo out
--print "codigo externo %1!",@i_codigo_externo
select @w_codigo_externo = @i_codigo_externo

  select @w_estado = cu_estado
    from cu_custodia
   where cu_codigo_externo = @i_codigo_externo
  if @w_estado = 'V' --Garantia Vigente
  begin
  /* Error en actualizacion de registro */
     exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1905013
     return 1 
  end

/*   Cancelacion - Eliminacion del registro no utilizado para el Credito   */
   if exists (select 1 from cu_custodia
                       where cu_codigo_externo = @w_codigo_externo)
   begin
   if @w_estado <> 'A'
   begin  
      begin tran

         --TRugel 03/31/08 No se deben anular garant¡as con polizas vigentes
         if exists (select 1
                    from cu_poliza
                    where po_codigo_externo = @w_codigo_externo
                      and po_estado_poliza  = 'V')
         begin
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1909015		--Existe poliza vigente asociada a la Garantia
            return 1 
         end

         if exists (select 1 from cob_credito..cr_gar_propuesta
                     where gp_garantia = @w_codigo_externo)
         begin
        /* Error en actualizacion de registro */         

           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909004			--TRugel 03/31/08 Codigo de error no corresponde 1905013
           return 1 
        end
             
         update cu_custodia
            set cu_estado = 'A' -- (A)nulado
         where cu_codigo_externo = @w_codigo_externo

         update cob_credito..cr_gar_propuesta
            set gp_est_garantia = 'A'
          where gp_garantia     = @w_codigo_externo
          
      if exists (select 1 from cu_por_inspeccionar
                       where pi_codigo_externo = @w_codigo_externo)
         delete cu_por_inspeccionar
          where pi_codigo_externo = @w_codigo_externo

      if exists (select 1 from cu_vencimiento      
                       where ve_codigo_externo = @w_codigo_externo)
         delete cu_vencimiento      
          where ve_codigo_externo = @w_codigo_externo

      if exists (select 1 from cu_recuperacion      
                       where re_codigo_externo = @w_codigo_externo)
         delete cu_recuperacion     
          where re_codigo_externo = @w_codigo_externo

      if exists (select 1 from cu_gastos      
                       where ga_codigo_externo = @w_codigo_externo)
         delete cu_gastos           
          where ga_codigo_externo = @w_codigo_externo
      commit tran
   end
   end
   else 
   begin
      /* No existe el registro  */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901005
         return 1
   end
end

--Guarda log auditoria
--II CMI 02Dic2006
	if @i_consulta = 'S'
		select @i_operacion = 'S'
	else
		select @i_operacion = 'T'

	select @w_codigo_externo = substring(@w_codigo_externo, 1, 24)
	
	/*exec @w_return = cob_cartera..sp_trnlog_auditoria_activas
	@s_ssn 		= @s_ssn,                   
   	@i_cod_alterno	= 0,
   	@t_trn		= @t_trn,
	@i_producto	= '19',      
   	@s_date		= @s_date,
   	@s_user		= @s_user,
   	@s_term		= @s_term,
   	@s_rol		= @s_rol,
   	@s_ofi		= @s_ofi,
   	@i_tipo_trn	= @i_operacion,
   	@i_num_banco	= @w_codigo_externo,
	@i_cliente	= @w_ente,
	@i_monto	= @w_valor_actual */

        if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1903003
                return 1 
        end

--FI CMI 02Dic2006
go