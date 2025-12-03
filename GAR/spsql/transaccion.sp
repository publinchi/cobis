
/*********************************************************************/
/*   NOMBRE LOGICO:      transaccion.sp                              */
/*   NOMBRE FISICO:      sp_transaccion                              */
/*   BASE DE DATOS:      cob_custodia                                */
/*   PRODUCTO:           GARANTIAS                                   */
/*   DISENADO POR:                                                   */
/*   FECHA DE ESCRITURA:                                             */
/*********************************************************************/
/*                     IMPORTANTE                                    */
/*   Este programa es parte de los paquetes bancarios que son        */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,   */
/*   representantes exclusivos para comercializar los productos y    */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida  */
/*   y regida por las Leyes de la República de España y las          */
/*   correspondientes de la Unión Europea. Su copia, reproducción,   */
/*   alteración en cualquier sentido, ingeniería reversa,            */
/*   almacenamiento o cualquier uso no autorizado por cualquiera     */
/*   de los usuarios o personas que hayan accedido al presente       */
/*   sitio, queda expresamente prohibido; sin el debido              */
/*   consentimiento por escrito, de parte de los representantes de   */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto   */
/*   en el presente texto, causará violaciones relacionadas con la   */
/*   propiedad intelectual y la confidencialidad de la información   */
/*   tratada; y por lo tanto, derivará en acciones legales civiles   */
/*   y penales en contra del infractor según corresponda.            */
/*********************************************************************/
/*                      MODIFICACIONES                               */
/* FECHA               AUTOR              RAZON                      */
/* 28/Mar/2019       Luis  Ramirez  	  Emision Inicial            */
/* 30/Jun/2019       BSJ                  Controlar la creacion      */
/*                                        de transacción cuando      */
/*                                        se crea la garantía        */
/*                                        liquida automática         */
/*                                        desde cartera              */
/* 22/May/20 Luis Castellanos  CDIG Pignoracion y reversa de DPF     */
/* 08/Ago/22 Kevin Rodríguez   R-191163: Valor defecto param         */
/*                             i_cancelacion                         */
/* 30/Ago/23 Kevin Rodríguez   R214302 Ajuste paginacion oper.'B'    */
/*********************************************************************/


USE cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_transaccion')
    drop proc sp_transaccion
go

create proc sp_transaccion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
 --@s_term               descripcion = null,  --Miguel Aldaz 26/Feb/2015	
   @s_term 				 varchar(30)   = null,--Miguel Aldaz 26/Feb/2015
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo_cust          descripcion  = null,
   @i_custodia           int  = null,
   @i_transaccion        smallint  = null,
   @i_fecha_tran         datetime  = null,
   @i_debcred            char(  1)  = null,
   @i_valor              money  = 0,
   @i_descripcion        descripcion  = null,
   @i_fecha1             datetime  =  null,
   @i_fecha2             datetime  =  null,
   @i_formato_fecha      int   =  null,
   @i_usuario 		 login     =  null,
   @i_perfil 		 varchar(10) = null,
   @i_cancelacion 	 char(1)   = 'N',
   @i_estado      	 char(1)   = null,
   @i_estado_aux  	 char(1)   = null,
   @i_param1      	 varchar(64)   = null,
   @i_ind_depre      	 int   = null,
   @i_codigo_externo     varchar(64) = null,
   @i_custodia_aut       char(1) = 'N',
   @i_estado_fin         char(1) = null,
   @i_estado_gar         char(1) = null,
   @i_tipo_tran          catalogo = null,
   @i_banderabe		 char(1) = null,
   @i_actualiza_valor    char(1) = 'S'
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_transaccion        smallint,
   @w_fecha_tran         datetime,
   @w_debcred            char(  1),
   @w_valor              money,
   @w_descripcion        descripcion,
   @w_error              int,
   @w_usuario 		 login,
   @w_perfil             varchar(10),
   @w_valor_custodia 	 money,
   @w_valor_actual   	 money,
   @w_valor_conta    	 money, 
   @w_valor_aux      	 money,
   @w_signo 		 int,
   @w_moneda		 tinyint,
   @w_estado      	 char(1),
   @w_codigo_externo     varchar(64),
   @w_clave              varchar(64),
   @w_nombre_usr         varchar(64),
   @w_contabilizar	 char(1),
   @w_ofi_contabiliza    smallint,
   @w_tipo               descripcion,
   @w_tipo_cca           catalogo,
   @w_tabla_rec          smallint,
   @w_codval             int,
   @w_valor_anterior     money,
   @w_cod_externo        varchar(64),
   @w_fecha_ingreso      char(10),
   @w_aseguradora        varchar(20),
   @w_fvigencia_ini      char(10),
   @w_fvigencia_fin      char(10),
   @w_tramite            int,
   @w_cod_colateral       catalogo,
   @w_colateral           char(1),
   @w_clase_cartera       catalogo,
   @w_calificacion        char(1),  
   @w_clase_custodia      char(1),
   @w_agotada             char(1) 

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_transaccion'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19000 and @i_operacion = 'I') or
   (@t_trn <> 19001 and @i_operacion = 'U') or
   (@t_trn <> 19002 and @i_operacion = 'D') or
   (@t_trn <> 19003 and @i_operacion = 'V') or
   (@t_trn <> 19004 and @i_operacion = 'S') or
   (@t_trn <> 19005 and @i_operacion = 'Q') or
   (@t_trn <> 19007 and @i_operacion = 'B') or
   (@t_trn <> 19008 and @i_operacion = 'C') or
   (@t_trn <> 19009 and @i_operacion = 'F') or
   (@t_trn <> 19006 and @i_operacion = 'A') or
   (@t_trn <> 19004 and @i_operacion = 'R')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_filial = tr_filial,
         @w_sucursal = tr_sucursal,
         @w_tipo_cust = tr_tipo_cust,
         @w_custodia = tr_custodia,
         @w_transaccion = tr_transaccion,
         @w_fecha_tran = tr_fecha_tran,
         @w_debcred = tr_debcred,
         @w_valor = tr_valor,
         @w_descripcion = tr_descripcion,
         @w_usuario = tr_usuario,
         @w_codigo_externo = tr_codigo_externo
    from cob_custodia..cu_transaccion
    where 
         tr_filial = @i_filial and
         tr_sucursal = @i_sucursal and
         tr_tipo_cust = @i_tipo_cust and
         tr_custodia = @i_custodia and
         tr_transaccion = @i_transaccion

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end



/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if 
         (@i_filial is null or 
         @i_sucursal is null or 
         @i_tipo_cust is null or 
         @i_custodia is null or 
         @i_fecha_tran is null or 
         @i_debcred is null or 
         @i_valor is null) and @i_custodia_aut = 'N'
    begin
        /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,

        @i_num   = 1901001
        return 1 
    end
end

/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
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

    begin tran 
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
                         
         if @i_custodia_aut = 'S'
            select @w_codigo_externo = @i_codigo_externo

         select @w_transaccion = isnull(max(tr_transaccion)+1,1)
         from cu_transaccion 
         where tr_codigo_externo = @w_codigo_externo
     
        if @w_transaccion is null
           select @w_transaccion = 1

        select @w_moneda   = cu_moneda,
               @w_estado   = cu_estado,
               @w_tipo     = cu_tipo,
               @w_tipo_cca = cu_tipo_cca,
               @w_valor_anterior = cu_valor_actual
        from cu_custodia 
        where cu_codigo_externo = @w_codigo_externo
/*
        select @w_valor = cu_valor_actual * dtc_porcentaje / 100
          from cu_custodia, cu_dtipo_custodia
         where cu_codigo_externo = @w_codigo_externo
           and cu_tipo = dtc_tipo
           and dtc_anio = datediff(yy,cu_fecha_ingreso,@i_fecha_tran)

        if @@rowcount > 0
          select @i_valor = @w_valor
*/
        if @i_estado_aux = 'C'  /* CANCELADO */
        begin 
           /* El estado debe ser distinto de Cancelada */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1905010
           return 1 
        end 

/*  
       print "filial %1!",@i_filial
        print "sucursal %1!",@i_sucursal
        print "tipo_cust %1!",@i_tipo_cust
        print "custodia %1!",@i_custodia
        print "transaccion %1!",@w_transaccion
        print "fecha_tran %1!",@i_fecha_tran
        print "debcred %1!",@i_debcred
        print "valor %1!",@i_valor
        print "descripcion %1!", @i_descripcion
        print "usuario %1!", @i_usuario
        print "codigo_externo %1!", @w_codigo_externo
*/
	if @i_custodia_aut = 'S'
	   begin
              /*PARAMETRO DE LA GARANTIA DE FNGD*/
             select @w_cod_colateral = pa_char
               from cobis..cl_parametro 
              where pa_nemonico = 'COFIAD'
                and   pa_producto = 'GAR'

              -- Validacion Cambios Estados
             if @i_estado_gar = 'P' and @i_estado_fin = 'A' begin -- Si cambio de estado de Propuesta a Anulada no Contabiliza
                return 0
              end

             if exists (select 1 from cu_tipo_custodia, cu_custodia
                 where tc_tipo_superior in (select tc_tipo from cu_tipo_custodia where tc_tipo_superior = @w_cod_colateral)
                   and   tc_tipo = cu_tipo
                   and   cu_codigo_externo = @i_codigo_externo)
           
                select @w_colateral = 'S'
             else
                select @w_colateral = 'N'
   

             -- Obtención de características para generar la Transacción

             if isnull(@i_valor,0) = 0 
                select @w_valor          = case @w_colateral when 'N' then cu_valor_inicial when 'S' then cu_valor_actual end,
                       @w_clase_custodia = cu_clase_custodia,
                       @w_agotada        = cu_agotada
                  from   cu_custodia
                 where  cu_codigo_externo = @i_codigo_externo 
             else
                select @w_valor = @i_valor,
                @w_clase_custodia = cu_clase_custodia,
                @w_agotada        = cu_agotada
                  from   cu_custodia
                 where  cu_codigo_externo = @i_codigo_externo 
   
              -- Definición del Código Valor

             if @i_estado_fin = 'F' begin
                if @w_clase_custodia = 'I'
                   select @w_codval = 21
                if @w_clase_custodia = 'O'
                   select @w_codval = 41
                end 
  
             if @i_estado_fin = 'V' and @w_agotada = 'N' begin
                if @w_clase_custodia = 'I'
                   select @w_codval = 22  
                if @w_clase_custodia = 'O'
                   select @w_codval = 42  
                end

             if @i_estado_fin = 'V' and @w_agotada = 'S' begin 
                if @w_clase_custodia = 'I'
                   select @w_codval = 23  
                if @w_clase_custodia = 'O'
                   select @w_codval = 43  
                end

             if @i_estado_fin = 'X' and @w_agotada = 'N' begin
                if @w_clase_custodia = 'I'
                   select @w_codval = 24  
                if @w_clase_custodia = 'O'
                   select @w_codval = 44  
               end

             if @i_estado_fin = 'X' and @w_agotada = 'S' begin 
                if @w_clase_custodia = 'I'
                   select @w_codval = 25  
                if @w_clase_custodia = 'O'
                   select @w_codval = 45  
                end

             if @i_estado_fin = 'C' and @w_agotada = 'N' begin 
                if @w_clase_custodia = 'I'
                   select @w_codval = 26  
                if @w_clase_custodia = 'O'
                   select @w_codval = 46  
                   select @i_tipo_tran = 'CAN'
                end

             if @i_estado_fin = 'C' and @w_agotada = 'S' begin 
                if @w_clase_custodia = 'I'
                   select @w_codval = 27  
                if @w_clase_custodia = 'O'
                   select @w_codval = 47  
                   select @i_tipo_tran = 'CAN'
                end

             if @i_estado_fin is null and @i_tipo_tran = 'VAL' begin

             select @i_estado_fin = @i_estado_gar
   
             if @w_agotada = 'S' begin
                if @w_clase_custodia = 'I'
                   select @w_codval = 28  
                if @w_clase_custodia = 'O'
                   select @w_codval = 48  
                end
             if @w_agotada = 'N' begin
                if @w_clase_custodia = 'I'
                   select @w_codval = 29  
                if @w_clase_custodia = 'O'
                   select @w_codval = 49 
                end    
             end
	   
	end
	
        insert into cu_transaccion(
              tr_filial,
              tr_sucursal,
              tr_tipo_cust,
              tr_custodia,
              tr_transaccion,
              tr_fecha_tran,
              tr_debcred,
              tr_valor,
              tr_descripcion,
              tr_usuario,
              tr_codigo_externo,
              tr_valor_anterior)
        values  (
              @i_filial,
              @i_sucursal,
              @i_tipo_cust,
              @i_custodia,
              @w_transaccion,
              @i_fecha_tran,
              @i_debcred,
              @i_valor,
              @i_descripcion,
              @i_usuario,
              @w_codigo_externo,
              @w_valor_anterior)

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
            
         select @w_ofi_contabiliza = cu_oficina_contabiliza
         from cu_custodia
         where cu_codigo_externo = @w_codigo_externo
 
         --  TRANSACCION CONTABLE 
         select @w_contabilizar = tc_contabilizar
         from cu_tipo_custodia
         where tc_tipo = @i_tipo_cust

         select @w_codval = 19

         if @w_contabilizar = 'S'
         begin
            /* La cancelacion genera su propia contab. */
      	    if @i_cancelacion <> 'S' and (@w_estado <> 'P' or (@i_estado_fin = 'P' and @i_estado_gar = 'V'))
            begin

                ---Programacion para manejo de Relacion de
                ---garantias con Operaciones               
                select @w_tabla_rec = codigo
                  from cobis..cl_tabla 
                 where tabla = 'cu_reclasifica'

                if exists (select codigo
                             from cobis..cl_catalogo
                            where tabla = @w_tabla_rec
                              and codigo = @w_tipo 
                              and estado = 'V')
                begin
                  if @i_debcred = 'D'
                    if @w_tipo_cca <> null --Debito con relacion
                      select @w_codval = 3
                  else
                    if @w_tipo_cca <> null --Credito con relacion
                      select @w_codval = 4
                end
                --  TRANSACCION CONTABLE 
                exec @w_return = sp_conta
                @s_date = @s_date,
				@s_user = @s_user,  --Miguel Aldaz 26/Feb/2015
				@s_term = @s_term,  --Miguel Aldaz 26/Feb/2015
         	    @t_trn = 19300,
         	    @i_operacion = 'I',
		        @i_filial = @i_filial,
		        @i_oficina_orig = @w_ofi_contabiliza,
 		        @i_oficina_dest = @w_ofi_contabiliza,
		        @i_tipo = @i_tipo_cust,
		        @i_moneda = @w_moneda,
		        @i_valor = @i_valor,
		        @i_operac = @i_debcred,
		        @i_signo = 1,
                @i_codval = @w_codval,
                @i_tipo_cca = @w_tipo_cca,                
                @i_codigo_externo = @w_codigo_externo

                if @w_return <> 0 
                begin
                   /* Error en insercion de Registro Contable */
                    exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file, 
                      @t_from  = @w_sp_name,
                      @i_num   = 1901012
                    return 1 
                end
         end
     end

     /* Transaccion de Servicio */
     /***************************/
     insert into ts_transaccion
     values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_transaccion',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @w_transaccion,
         @i_fecha_tran,
         @i_debcred,
         @i_valor,
         @i_descripcion,
         @i_usuario,
         @w_codigo_externo)

      if @@error <> 0 
      begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
      end
         
      /* Modificacion del valor actual de la garantia */
      select @w_valor_actual = cu_valor_actual
      from cu_custodia
      where cu_codigo_externo = @w_codigo_externo

      if @i_debcred = 'D' -- Disminucion de valor
      begin
           if @i_ind_depre = null 
            begin
		   if @i_valor > @w_valor_actual
		   begin
		   /* El valor del debito no puede ser mayor al valor actual */
		       exec cobis..sp_cerror
		       @t_debug = @t_debug,
		       @t_file  = @t_file, 
		       @t_from  = @w_sp_name,
		       @i_num   = 1903008
		       return 1 
		   end
		   else 
		       select @w_valor_custodia = @i_valor * -1
	     end
	    else
	     begin
	     	select @w_valor_custodia = @i_valor * -1
	     end
      end
      else                -- Aumento de valor
            select @w_valor_custodia = @i_valor
      

      if @i_actualiza_valor = 'N' --LCA CDIG Pignoracion y reversa de DPF
	 select @w_valor_custodia = 0

      if @i_ind_depre is null 
       begin
	      update cu_custodia 
	      set cu_valor_actual = cu_valor_actual + @w_valor_custodia,
		  cu_fecha_modificacion = @s_date 
	      where  cu_codigo_externo = @w_codigo_externo
	end
       else
        begin
        	update cu_custodia 
        	   set cu_valor_actual = cu_valor_inicial + @w_valor_custodia,
				  cu_fecha_modificacion = @s_date 
	         where  cu_codigo_externo = @w_codigo_externo
        end

      if @@error <> 0 
      begin
         /* Error en actualizacion del registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
      end
    commit tran 
end

/* Actualizacion de registros */
/****************************/
if @i_operacion = 'U'
begin
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

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         update cob_custodia..cu_transaccion
         set 
              tr_fecha_tran = @i_fecha_tran,
              tr_debcred = @i_debcred,
              tr_valor = @i_valor,
              tr_descripcion = @i_descripcion,
              tr_usuario = @i_usuario,
              tr_codigo_externo = @w_codigo_externo
    where 
         tr_filial = @i_filial and
         tr_sucursal = @i_sucursal and
         tr_tipo_cust = @i_tipo_cust and
         tr_custodia = @i_custodia and
         tr_transaccion = @i_transaccion

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

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_transaccion
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_transaccion',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_transaccion,
         @w_fecha_tran,
         @w_debcred,
         @w_valor,
         @w_descripcion,
         @w_usuario,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_transaccion
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_transaccion',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_transaccion,
         @i_fecha_tran,
         @i_debcred,
         @i_valor,
         @i_descripcion,
         @i_usuario,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
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

/***** Integridad Referencial *****/
/*****                        *****/


    begin tran
         delete cob_custodia..cu_transaccion
    where 
         tr_filial = @i_filial and
         tr_sucursal = @i_sucursal and
         tr_tipo_cust = @i_tipo_cust and
         tr_custodia = @i_custodia and
         tr_transaccion = @i_transaccion

                                        
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

            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_transaccion
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_transaccion',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_transaccion,
         @w_fecha_tran,
         @w_debcred,
         @w_valor,
         @w_descripcion,
         @w_usuario,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

if @i_operacion = 'B'
begin
   set rowcount 20
   if @i_usuario is null
      select @i_usuario = @i_param1
   select distinct 'LOGIN'=substring(us_login,1,15),
                   'NOMBRE' = substring(fu_nombre,1,30)
     from cobis..ad_usuario,cobis..cl_funcionario
    where us_login = fu_login
      and (us_login > @i_usuario or @i_usuario is null)
    order by 1 --us_login
   if @@rowcount = 0
   begin
      if @i_usuario is null
      begin
      /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901003
        return 1 
      end
      else
      begin
      /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901004
        return 1 
      end    
   end
end


if @i_operacion = 'C'
begin
	select @w_clave = us_login
     from cobis..ad_usuario
    where us_login = @i_usuario

   if @@rowcount = 0
   begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005
        return 1 
   end 
   else
   begin
		select @w_nombre_usr = fu_nombre
         from cobis..cl_funcionario,cobis..ad_usuario
        where fu_login = @w_clave
       select @w_nombre_usr
	   
   end
end


/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
         select 
              @w_filial,
              @w_sucursal,
              @w_tipo_cust,
              @w_custodia,
              @w_transaccion,
              @w_fecha_tran,
              @w_debcred,
              @w_valor,
              @w_descripcion,
              @w_usuario
    else
    begin
    /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005
        return 1 
    end
    return 0
end

if @i_operacion = 'S'
begin
   if @i_modo = 0
   select isnull(cu_valor_inicial,0) from cu_custodia
    where cu_filial   = @i_filial
      and cu_sucursal = @i_sucursal
      and cu_tipo     = @i_tipo_cust
      and cu_custodia = @i_custodia
   set rowcount 20
   select 'NRO.'= tr_transaccion,
          'FECHA'=convert(char(10),tr_fecha_tran,@i_formato_fecha),
          'USUARIO'=convert(char(30),tr_usuario),
          'TIPO TRAN' = tr_debcred, 
          'VALOR'=tr_valor,
          'DESCRIPCION' = tr_descripcion
     from cu_transaccion 
    where tr_filial    = @i_filial
      and tr_sucursal  = @i_sucursal
      and tr_tipo_cust = @i_tipo_cust
      and tr_custodia  = @i_custodia 
      and (tr_usuario like @i_usuario or @i_usuario is null)
      and (tr_fecha_tran >= @i_fecha1 or @i_fecha1 is null)
      and (tr_fecha_tran <= @i_fecha2 or @i_fecha2 is null)
      and (tr_transaccion > @i_transaccion or @i_transaccion is null)
      order by 	  tr_fecha_tran,  tr_transaccion --CSA Migracion Sybase

         if @@rowcount = 0
         begin
            if @i_transaccion is null       
               select @w_error  = 1901003
            else
               --select @w_error  = 1901004 esto ya estaba
               return 1
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1 
         end
    return 0
end

if @i_operacion = 'F'
begin
   set rowcount 20
   select 'TIPO' = tr_tipo_cust,
          'GARANTIA' = tr_custodia,
          'NRO.' = tr_transaccion,
          'FECHA'= convert(char(10),tr_fecha_tran,@i_formato_fecha),
          'TIPO TRAN' = tr_debcred, 
          'VALOR'=tr_valor,
          'DESCRIPCION' = tr_descripcion
     from cu_transaccion 
    where tr_filial    = @i_filial
      and tr_sucursal  = @i_sucursal
      and (tr_usuario like @i_usuario or @i_usuario is null)
      and (tr_fecha_tran >= @i_fecha1 or @i_fecha1 is null)
      and (tr_fecha_tran <= @i_fecha2 or @i_fecha2 is null)
      and (
(tr_tipo_cust > @i_tipo_cust or (tr_tipo_cust = @i_tipo_cust and tr_custodia > @i_custodia)) or 
((tr_tipo_cust = @i_tipo_cust and tr_custodia = @i_custodia) and (tr_transaccion > @i_transaccion))
           or @i_transaccion is null) 
      order by tr_tipo_cust,tr_custodia,tr_transaccion,tr_fecha_tran
         if @@rowcount = 0
         begin
            if @i_transaccion is null  
               select @w_error  = 1901003
            else
               select @w_error  = 1901004
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1 
         end
    return 0
end

if @i_operacion = 'R'
 begin
  set rowcount 0

  create table #tmp_depre
	(operacion    char(10)     null,
	 cliente      int          null,
	 nombre       varchar(64)  null,
	 aseguradora  varchar(64)  null,
	 garantia     varchar(64)  null,
	 fecha_cons   char(10)	   null,
	 fecha_tran   char(10)	   null,
	 fecha_ingr   char(10)	   null,
	 fecha_vige   char(10)	   null,
	 val_actual   money	   null,
	 val_ante     money	   null,
	 val_dife     money	   null,
	 val_tasa     money	   null,
	 val_prima    money	   null)

  create table #tmp_depre1
	(ind	      numeric	   identity,
	 operacion    char(10)     null,
	 cliente      int          null,
	 nombre       varchar(64)  null,
	 aseguradora  varchar(64)  null,
	 garantia     varchar(64)  null,
	 fecha_cons   char(10)	   null,
	 fecha_tran   char(10)	   null,
	 fecha_ingr   char(10)	   null,
	 fecha_vige   char(10)	   null,
	 val_actual   money	   null,
	 val_ante     money	   null,
	 val_dife     money	   null,
	 val_tasa     money	   null,
	 val_prima    money	   null)

  insert into #tmp_depre
  select null, null, null, null, 
  	 cu_codigo_externo, 
  	 cu_fecha_ingreso = convert(char(10), cu_fecha_ingreso, @i_formato_fecha),
         tr_fecha_tran = convert(char(10), tr_fecha_tran, @i_formato_fecha),         
         null, null, cu_valor_actual, 
         tr_valor_anterior, diferencia = tr_valor_anterior - cu_valor_actual, 
         null, null
    from cu_transaccion, cu_custodia
   where tr_fecha_tran >= @i_fecha1
     and tr_fecha_tran <= @i_fecha2
     and ( tr_sucursal = @i_sucursal or @i_sucursal is null )
     and tr_codigo_externo = cu_codigo_externo
     and tr_valor_anterior is not null
   order by 
   	 cu_codigo_externo


  if @i_param1 <> null
   delete #tmp_depre
    where garantia not in ( select garantia from #tmp_depre, cu_poliza
                             where po_codigo_externo = garantia and po_aseguradora = @i_param1 )

  set rowcount 1

  select @w_cod_externo = garantia
    from #tmp_depre

  if @@rowcount <> 0
   begin
    while 1 = 1
     begin
      set rowcount 0

      select @w_fecha_ingreso = convert(char(10),cu_fecha_ingreso,@i_formato_fecha), @w_tipo = cu_tipo
        from cu_custodia
       where cu_codigo_externo = @w_cod_externo

      select @w_aseguradora = po_aseguradora, 
             @w_fvigencia_ini = convert(char(10),po_fvigencia_inicio,@i_formato_fecha),
             @w_fvigencia_fin = convert(char(10),po_fvigencia_fin,@i_formato_fecha)
        from cu_poliza
       where po_codigo_externo = @w_cod_externo

      if @@rowcount = 0
       select @w_aseguradora = '', @w_fvigencia_ini = '', @w_fvigencia_fin = ''

      select @w_tramite = gp_tramite
        from cob_credito..cr_gar_propuesta
       where gp_garantia = @w_cod_externo

      if @@rowcount = 0
       select @w_tramite = 999999

      update #tmp_depre
         set operacion = (case when @w_tramite > 0 then 
				( select op_banco from cob_cartera..ca_operacion where op_tramite = @w_tramite )
			 else
				null
			 end),
               cliente = ( select cg_ente from cu_cliente_garantia
                            where cg_principal = 'S'
                              and cg_codigo_externo = @w_cod_externo ),
                nombre = ( select en_nomlar from cu_cliente_garantia, cobis..cl_ente
                            where cg_principal = 'S'
                              and cg_codigo_externo = @w_cod_externo
                              and cg_ente = en_ente ),
           aseguradora = (case when @w_aseguradora <> '' then 
				( select isnull(valor,'') from cobis..cl_catalogo a, cobis..cl_tabla b
	                            where a.tabla = b.codigo and b.tabla = 'cu_des_aseguradora'
        	                      and a.codigo = @w_aseguradora )
			 else
				null
			 end),
            fecha_ingr = @w_fvigencia_ini,
            fecha_vige = @w_fvigencia_fin,
              val_tasa = (case when @w_tramite > 0 then 
				(isnull(( select ro_porcentaje from cob_cartera..ca_rubro_op, cob_cartera..ca_operacion
                                   where ro_concepto in ('SEGFIN','SEGVEH')
                                     and ro_operacion = op_operacion
                                     and op_tramite = @w_tramite ),0.0))
			 else
				null
			 end),
            val_prima = isnull(( select max(se_valor_anual) from cob_cartera..ca_seguro, cob_cartera..ca_operacion
                                  where se_concepto in ('SEGFIN','SEGVEH')
                                    and se_periodo in ( select datediff(yy,@w_fecha_ingreso, fecha_tran)
							 from #tmp_depre
							 where garantia = @w_cod_externo )
                                    and se_operacion = op_operacion
                                    and op_tramite = @w_tramite ),0.0)
									
/*            val_prima = isnull(( select se_valor_anual from cob_cartera..ca_seguro, cob_cartera..ca_operacion
                                  where se_concepto in ('SEGFIN','SEGVEH')
                                    and se_periodo = ( select dtc_anio from cu_dtipo_custodia
                                                        where dtc_tipo = @w_tipo
                                                          and dtc_anio = datediff(yy,@w_fecha_ingreso, @i_fecha_tran) )
                                    and se_operacion = op_operacion
                                    and op_tramite = @w_tramite ),0.0)*/
       where garantia = @w_cod_externo

      set rowcount 1

      select @w_cod_externo = garantia
        from #tmp_depre
       where garantia > @w_cod_externo

      if @@rowcount = 0
       break

     end
   end

  set rowcount 0/* Adaptive Server has expanded all '*' elements in the following statement */ 

  insert into #tmp_depre1
  select #tmp_depre.operacion, #tmp_depre.cliente, #tmp_depre.nombre, #tmp_depre.aseguradora, #tmp_depre.garantia, #tmp_depre.fecha_cons, #tmp_depre.fecha_tran, #tmp_depre.fecha_ingr, #tmp_depre.fecha_vige, #tmp_depre.val_actual, #tmp_depre.val_ante, #tmp_depre.val_dife, #tmp_depre.val_tasa, #tmp_depre.val_prima
   from #tmp_depre
  order by aseguradora

  set rowcount 10

  select 'Operacion' = operacion, 'Cliente' = cliente, 'Nombre' = nombre, 'Aseguradora' = aseguradora, 
         'Garantia' = garantia, 'Concesion' = fecha_cons, 'Depreciada' = fecha_tran, 'Poliza Ini' = fecha_ingr, 
         'Poliza Fin' = fecha_vige, 'Valor Actual' = val_actual, 'Valor Anterior' = val_ante, 
         'Diferencia' = val_dife, 'Tasa' = val_tasa, 'Prima' = val_prima
   from #tmp_depre1
  where ( ind > @i_ind_depre or @i_ind_depre is null )
 end
go

