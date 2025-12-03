/*************************************************************************/
/*   Archivo:              migracion.sp                                  */
/*   Stored procedure:     sp_megracion                                  */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
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
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_migracion') IS NOT NULL
    DROP PROCEDURE dbo.sp_migracion
go
create proc sp_migracion  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
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
   @i_banco              cuenta      = null,
   @i_formato_fecha      int         = null,
   @i_gasto_adm          smallint    = null,
   @i_pasar              char(1)     = null,
   @i_consulta           char(1)     = null,
   @i_login              varchar(30) = null,
   @i_accion             char(1)     = null,
   @i_operacion_unisys   cuenta      = null,
   @i_operacion_cobis    cuenta      = null,
   @i_operacion_cartera  int         = null  

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
   @w_operacion_unisys   varchar(30),
   @w_operacion_cobis    varchar(30),
   @w_operacion_cartera  int,
   @w_accion             char(1),
   @w_tramite 		 int, --IOR para grabar en gar_propuesta

   @w_estado_op          tinyint,  --SPO
   @w_estado_gar         catalogo,  --SPO

   @w_oficina_op         smallint,   --SPO
   @w_oficina_gar        smallint,   --SPO

   @w_cliente_op         int,   --SPO
   @w_cliente_gar        int,   --SPO

   @w_estcan             tinyint,  --SPO
   @w_nombre_ente        descripcion --SPO

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_migracion'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19741 and @i_operacion = 'S') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'S' 
begin

select @w_estcan=pa_tinyint 
from cobis..cl_parametro
where pa_producto='CRE'
and pa_nemonico='ESTCAN'



if @i_accion = 'I' or @i_accion = 'U' or @i_accion = 'D'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

      /*if @w_codigo_externo is null or
         @i_operacion_cobis is null
      begin
       
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 1901001
           return 1
       end  */

--IOR cambio para consultar la existencia en gar propuesta
  select @w_operacion_cobis     = tr_numero_op_banco
        from cob_credito..cr_gar_propuesta, cob_credito..cr_tramite
       where gp_garantia    = @w_codigo_externo
         and tr_numero_op_banco = @i_operacion_cobis
	 and tr_tramite = gp_tramite

/*       select @w_operacion_cobis     = go_operacion_cobis
        from cu_garantia_operacion
       where go_codigo_externo    = @w_codigo_externo
         and go_operacion_cobis   = @i_operacion_cobis
*/
 
       if @@rowcount = 0
          select @w_existe = 0
       else
          select @w_existe = 1


      --SPO

       select  @w_estado_op =op_estado,
               @w_oficina_op=op_oficina,
               @w_cliente_op  =op_cliente
       from cob_cartera..ca_operacion
       where op_banco=@i_operacion_cobis


      if @w_estado_op=@w_estcan   --Revisar estados de la op.
         begin
             print 'La operacion esta cancelada'
             return 1         
         end


      select @w_oficina_gar=cu_oficina,
             @w_estado_gar =cu_estado,
             @w_valor_actual = cu_valor_actual		--II CMI 02Dic2006
      from cob_custodia..cu_custodia
      where cu_sucursal=@i_sucursal 
      and cu_custodia=@i_custodia
      and cu_tipo=@i_tipo_cust


      if @w_estado_gar='C'
         begin
             print 'La garantia esta cancelada'
             return 1         
         end 

      if @w_estado_gar<>'V' and @w_estado_gar<>'P'
         begin
             print 'La garantias no es ni p ni v'
             return 1         
         end

      
      select @w_cliente_gar = cg_ente
      from cu_cliente_garantia

      where cg_sucursal=@i_sucursal
      and cg_custodia=@i_custodia
      and cg_tipo_cust=@i_tipo_cust
      and cg_principal      = 'S'


      if @w_oficina_gar<>@w_oficina_op
         begin
            print 'Oficina del cliente no corresponde a oficina de la operacion'
            return 1
         end
         
/*
      if @w_cliente_gar<>@w_cliente_op
          begin
             print 'Cliente de la garantia no es el mismo de la operacion'
             return 1
          end*/

      --SPO  




end

   if @i_accion = 'S'
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
             @w_ofi_contabiliza = cu_oficina_contabiliza
        from cu_custodia
       where cu_codigo_externo = @w_codigo_externo

      /*select @w_operacion_unisys     = go_operacion,
             @w_operacion_cartera = go_operacion_cartera
        from cu_garantia_operacion
       where go_codigo_externo    = @w_codigo_externo
         and go_operacion         = @i_operacion_unisys
         --and go_operacion_cartera = @i_operacion_cartera
       order by go_codigo_externo

       if @@rowcount = 0
       begin 
          select @w_accion = 'I'
       end
       else
          begin
             select @w_accion = 'U'
          end*/

      select @w_ente    = cg_ente--,
             --@w_cliente = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre
       from cu_cliente_garantia--,cobis..cl_ente 
      where cg_codigo_externo = @w_codigo_externo
        and cg_principal      = 'S'
        --and cg_ente           = en_ente


      select @w_nombre_ente=en_nombre+' '+p_p_apellido+' '+p_s_apellido
      from cobis..cl_ente
      where en_ente=@w_ente  
     
      if @i_consulta = 'S'
      begin

         exec @w_return = sp_tipo_custodia
         @i_tipo = @i_tipo_cust,
         @t_trn  = 19123,
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
                @w_valor_actual, 
                @w_moneda,
                @w_ente,
                null,--@w_cliente,
                @w_codigo_externo,
                null,
                null,
                --@w_operacion_unisys,
                --@w_operacion_cartera
                @w_nombre_ente  --SPO



       end -- Fin de la Consulta
   end     -- Accion 'S'
 

--IOR 9/07/2000, se guarda en gar_propuesta directamente
if @i_accion = 'I'
begin     
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1
    end

    select @w_operacion_cobis = op_banco,
	@w_tramite = op_tramite,
	@w_ente = op_cliente
      from cob_cartera..ca_operacion
     where op_banco = @i_operacion_cobis

    if @@rowcount = 0
    begin
     /* Registro no existe */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 1909005
    return 1
    end 

      select @w_estado = cu_estado, 
             @w_moneda = cu_moneda,
             @w_valor_actual = cu_valor_actual,
             @w_abierta_cerrada = cu_abierta_cerrada,
             @w_oficina = cu_oficina,
             @w_ofi_contabiliza = cu_oficina_contabiliza
        from cu_custodia
       where cu_codigo_externo = @w_codigo_externo

    begin tran

--print 'tr %1! code %2! abier %3! ente %4! estado %5!', 
--@w_tramite, @w_codigo_externo, @w_abierta_cerrada, @w_ente, @w_estado





         insert into cob_credito..cr_gar_propuesta(
		gp_tramite                     ,
		gp_garantia                    ,
		gp_clasificacion               ,
		gp_exceso                      ,
		gp_monto_exceso                ,
		gp_abierta                     ,
		gp_deudor                      ,
		gp_est_garantia                , 	
		gp_fecha_mod                    )
         values (
         	@w_tramite,
                @w_codigo_externo,
                'a',
                'N',
                0,
                @w_abierta_cerrada ,
                @w_ente,
                @w_estado,
				@w_today)


         	if @@error <> 0
         	begin

	         /* Error en insercion de registro */
        	     exec cobis..sp_cerror
             		@t_debug = @t_debug,
  	           	@t_file  = @t_file,
	       		@t_from  = @w_sp_name,
              		@i_num   = 1903001
             		return 1
         	end			
         commit tran
end

if @i_accion = 'U'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1
    end       
         begin tran 
               update cu_garantia_operacion
                  set go_operacion         = @i_operacion_unisys,
                      go_operacion_cartera = @i_operacion_cartera,
                      go_operacion_cobis   = @i_operacion_cobis,
                      go_fecha             = @s_date    
                where go_codigo_externo  = @w_codigo_externo 
                  and go_operacion_cobis = @i_operacion_cobis

  	if @@error <> 0
        begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1
         end 
         commit tran
end  -- Transaccion 


if @i_accion = 'C'
begin
   -- CODIGO EXTERNO
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

   select @w_operacion_unisys     = go_operacion,
          @w_operacion_cobis      = go_operacion_cobis
     from cu_garantia_operacion
    where go_codigo_externo    = @w_codigo_externo
      and go_operacion_cobis   = @i_operacion_cobis
      --and go_operacion_cartera = @i_operacion_cartera
    order by go_codigo_externo
    select @w_operacion_cobis


end

if @i_accion = 'Z'
begin
   select @w_operacion_cobis = op_banco,
               @w_estado_op =op_estado,    --SPO
               @w_oficina_op=op_oficina,   --SPO
               @w_cliente_op  =op_cliente  --SPO
     from cob_cartera..ca_operacion
    where op_banco = @i_operacion_cobis

   if @@rowcount = 0
   begin
    /* Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1909005
   return 1
   end 


   select @w_estado_op,  --SPO
          @w_estcan      --SPO

end

if @i_accion = 'D'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
     if @w_existe = 0
     begin
     /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1
    end
    begin tran
    delete cu_garantia_operacion
    where  go_codigo_externo      = @w_codigo_externo
      and  go_operacion_cobis     = @i_operacion_cobis

	  if @@error <> 0
          begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1
         end
    commit tran
end

if @i_accion = 'B'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

set rowcount 20
/* IOR busca en cr_gar_propuesta
 select 'Sucursal'= go_sucursal,'Garantia'= substring(go_codigo_externo,1,20),
                'Operacion Unisys'= substring(go_operacion,1,15),
                'Operacion Cobis' = substring(go_operacion_cobis,1,15),
                'Tipo Garantia' = substring(go_tipo_cust,1,10),
                'Secuencial'=go_custodia,'Fecha'=go_fecha
           from cu_garantia_operacion
          where go_codigo_externo = @w_codigo_externo
            and (go_operacion_cobis > @i_operacion_cobis or @i_operacion_cobis is null)
          order by go_operacion_cobis
*/
 select 'Sucursal'= cu_sucursal,
	'Garantia'= substring(cu_codigo_externo,1,20),
	'Operacion Cobis' = substring(tr_numero_op_banco ,1,15),
        'Tipo Garantia' = substring(cu_tipo,1,10),
        'Secuencial'=cu_custodia
           from cu_custodia, cob_credito..cr_gar_propuesta, cob_credito..cr_tramite
          where cu_codigo_externo = @w_codigo_externo
            and (tr_numero_op_banco > @i_operacion_cobis or @i_operacion_cobis is null)
	    and tr_tramite = gp_tramite
	    and cu_codigo_externo = gp_garantia
          order by tr_numero_op_banco             

end

--Guarda log auditoria
--II CMI 02Dic2006
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
   	@i_tipo_trn	= @i_accion,
   	@i_num_banco	= @w_codigo_externo,
	@i_cliente	= @w_cliente_gar,
	@i_monto	= @w_valor_actual

        if @w_return <> 0 
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

end
 
/* ### DEFNCOPY: END OF DEFINITION */
GO
