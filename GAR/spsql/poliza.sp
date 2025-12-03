/*************************************************************************/
/*   Archivo:              poliza.sp                                     */
/*   Stored procedure:     sp_poliza                                     */
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
IF OBJECT_ID('dbo.sp_poliza') IS NOT NULL
    DROP PROCEDURE dbo.sp_poliza
go
create procedure sp_poliza (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
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
   @i_aseguradora        varchar( 20)  = null,
   @i_poliza             varchar( 20)  = null,
   @i_fvigencia_inicio   datetime  = null,
   @i_fvigencia_fin      datetime  = null,
   @i_moneda             tinyint   = null,
   @i_monto_poliza       money  = null,
   @i_monto_endozo       money  = null,
   @i_fecha_endozo       datetime  = null,
   @i_fendozo_fin        datetime  = null,
   @i_param1	         varchar(64) = null,	
   @i_param2	         varchar(64) = null,
   @i_formato_fecha      int = null,
   @i_cobertura          catalogo = null,
   @i_descripcion        varchar(64) = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo               varchar(64)  = null,
   @i_custodia           int  = null,
   @i_codigo_externo     varchar(64) = null,
   @i_estado_poliza      catalogo    = null,
   @i_renovacion	 char(1)     = 'N',		--TRugel 01/23/2007
   @i_pago		 int	     = null,		--FAndrade 12/02/2008
   @i_secuencial_pag	 int	     = null,		--FAndrade 12/02/2008
   @i_externo		 char(01)    = null,		--Fandrade 25/06/2009
   @o_poliza		 varchar(20) = null output,	--FAndrade 12/02/2008
   @o_msg		 varchar(255) = null output	--Fandrade 25/06/2009
)
as declare
   @w_today                     datetime,     /* fecha del dia */ 
   @w_return                    int,          /* valor que retorna */
   @w_sp_name                   varchar(32),  /* nombre stored proc*/
   @w_existe                    tinyint,      /* existe el registro*/
   @w_aseguradora               varchar( 20),
   @w_poliza                    varchar( 20),
   @w_fvigencia_inicio          datetime,
   @w_fvigencia_fin             datetime,
   @w_moneda                    tinyint,
   @w_monto_poliza              money,
   @w_fecha_endozo              datetime,
   @w_fendozo_fin               datetime,
   @w_monto_endozo              money,
   @w_des_moneda                varchar(30),
   @w_des_aseguradora           descripcion,
   @w_des_estado_poliza         descripcion,
   @w_estado_poliza             char(1),
   @w_error                     int,
   @w_cobertura                 catalogo,
   @w_des_cobertura             varchar(64),
   @w_descripcion               varchar(64),
   @w_valor_inicial             money,
   @w_valor_comparativo         float,
   @w_porcentaje                float,
   @w_valor_poliza_aux          money,
   @w_valor_poliza_tot          money,
   @w_codigo_externo            varchar(64),
   @w_moneda_local              tinyint,
   @w_tip_vehp			varchar(30),		--TRugel 01/23/2007
   @w_tip_vehl			varchar(30),
   @w_tipo_veh			catalogo,
   @w_poliza_tveh		catalogo,
   @w_sec_endoso_colonial	int,
   --II FAE 11/Mar/2011
   @w_aseg_sec_unico		catalogo,
   @w_sucursal                  smallint,
   @w_endoso_unico              char(1),
   --FI FAE 11/Mar/2011   
   --HHO
    @w_aseg_veh	 		varchar(30),
    @w_concepto     	        catalogo,
    @w_es_veh			smallint,
    @w_existep			char(1),
    @w_validar			char(1)
   --HHO


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_poliza'

select	@w_aseg_sec_unico = pa_char
from	cobis..cl_parametro
where	pa_nemonico  = 'ASEGSU'
and	pa_producto  = 'GAR'

if @i_pago is null
begin
   create table #temporal (moneda money, cotizacion money)
	   
   insert into #temporal --(moneda,cotizacion)
   select ct_moneda,ct_compra
   from   cob_conta..cb_cotizacion a
   where  ct_fecha = (select max(b.ct_fecha)
                      from cob_conta..cb_cotizacion b
                      where b.ct_moneda = a.ct_moneda
                      and b.ct_fecha <= @w_today)
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

      select 
         @w_aseguradora = po_aseguradora,
         @w_poliza = po_poliza,
         @w_monto_poliza = po_monto_poliza,
         @w_fvigencia_inicio = po_fvigencia_inicio,
         @w_fvigencia_fin = po_fvigencia_fin,
         @w_fecha_endozo = po_fecha_endozo,
         @w_monto_endozo = po_monto_endozo,
         @w_moneda       = po_moneda,
         @w_cobertura    = isnull(po_cobertura,''), --PAL integraciÃ³n, se envÃ­a vacio para no enviar nulo
         @w_descripcion  = po_descripcion,
         @w_codigo_externo = po_codigo_externo,
         @w_fendozo_fin    = po_fendozo_fin,
         @w_estado_poliza = po_estado_poliza
      from cob_custodia..cu_poliza
      where po_aseguradora = @i_aseguradora
        and po_poliza      = @i_poliza 
        and po_codigo_externo = @w_codigo_externo 

      if @@rowcount > 0
            select @w_existe = 1
      else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

      if @i_aseguradora = NULL or 
         @i_poliza = NULL or
         @w_codigo_externo = NULL
      begin
      	 --print '@w_codigo_externo %1!, @i_aseguradora %2!, @i_poliza %3!', @w_codigo_externo, @i_aseguradora, @i_poliza
         /* Campos NOT NULL con valores nulos */
          exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1901001
          return 1 
      end

 if @i_pago is null 
  begin
      if @i_monto_poliza <> 0
      begin
          select @w_porcentaje = pa_float -- PORCENTAJE POLIZA
          from cobis..cl_parametro
          where pa_producto = 'GAR'
            and pa_nemonico = 'PPO'

          select @w_valor_inicial = isnull(cu_valor_inicial,0)*isnull(cotizacion,1)
          from cu_custodia
		  left join #temporal on cu_moneda = moneda
        where cu_codigo_externo = @w_codigo_externo
        --and po_aseguradora = @i_aseguradora
        --and po_poliza = @i_poliza

        if @w_valor_inicial = 0
        begin
           /* Campos NOT NULL con valores nulos */
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1909025
           return 1909025 
        end

        select @w_moneda_local = pa_tinyint -- MONEDA LOCAL
        from cobis..cl_parametro
        where pa_producto = 'ADM'
          and pa_nemonico = 'MLO'

        if @i_moneda = @w_moneda_local
           select @w_valor_poliza_aux = @i_monto_poliza
        else  
           select @w_valor_poliza_aux = @i_monto_poliza * isnull(cotizacion,1)
           from #temporal
           where moneda = @i_moneda  


       /* Calcula el Total del valor de las polizas de una garantia  */
       select @w_valor_poliza_tot = sum(isnull(po_monto_poliza,0)*isnull(cotizacion,1))
         from cu_poliza
		 left join #temporal on po_moneda = moneda
        where po_codigo_externo = @w_codigo_externo
        group by po_codigo_externo
        order by po_codigo_externo

       select @w_valor_poliza_tot = isnull(@w_valor_poliza_aux,0)
              + isnull(@w_valor_poliza_tot,0)

       select @w_valor_comparativo = @w_valor_poliza_tot/@w_valor_inicial


       /* Valor de poliza no cubre el porcentaje del valor inicial 
       if @w_valor_comparativo < @w_porcentaje/100
       begin
          /* Error en valor del monto de la poliza */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901016
           return 2
           print 'La Poliza no cubre el monto minimo' 
      end  */
    end

    if @i_monto_endozo <> 0
     begin
       if @i_monto_endozo > @i_monto_poliza
        begin
          --print '@w_codigo_externo %1!, @i_monto_endozo %2!, @i_monto_poliza %3!', @w_codigo_externo, @i_monto_endozo, @i_monto_poliza
          /* Error en valor del monto del endoso */
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901018
           return 1 
        end
      end
   end
end


/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    begin tran
    
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    if @w_existe = 0
    begin --1

       --Solo Si Encuentra la Empresa en esta tabla, debe generar el nro de pÃ‚Â¢liza autom tico
       if @i_renovacion = 'N' and exists (select 1
                                          from cu_endoso_colonial
                                          where ec_empresa = @i_aseguradora)
       begin --2

       	  --TRugel 01/23/2007
          select @w_tip_vehl  = pa_char
          from cobis..cl_parametro
          where pa_producto = 'GAR'
            and pa_nemonico = 'TVEHL'

          select @w_tip_vehp  = pa_char
          from cobis..cl_parametro
          where pa_producto = 'GAR'
            and pa_nemonico = 'TVEHP'

	  select @w_tipo_veh = null

          if exists (select 1
        	     from cobis..cl_tabla a, cobis..cl_catalogo b
                     where a.tabla = 'cu_tgar_vehlivianos'
                       and a.codigo = b.tabla
                       and b.codigo = @i_tipo)
          begin
             select @w_tipo_veh = @w_tip_vehl
          end

          if exists (select 1
        	     from cobis..cl_tabla a, cobis..cl_catalogo b
                     where a.tabla = 'cu_tgar_vehpesados'
                       and a.codigo = b.tabla
                       and b.codigo = @i_tipo)
          begin
             select @w_tipo_veh = @w_tip_vehp
          end

          --DAR 23Sep2011
          --Nuevo catalogo donde se colocan todas las aseguradoras
          --que manejan numero unico de endoso 
          --independiente que sea Livianos o pesados e independiente
          --de que oficina
          
          select @w_endoso_unico = 'N'          
          if exists(select 1
        	             from cobis..cl_tabla a, cobis..cl_catalogo b
                     where a.tabla = 'cu_unico_endoso_aseg'
                       and a.codigo = b.tabla
                       and b.codigo = @i_aseguradora)  --codigo de aseguradora
             select @w_endoso_unico = 'S' 

          --Debe continuar si el tipo de garantÃ‚Â¡a corresponde a VehÃ‚Â¡culos Livianos o Pesados
	  --De lo contrario debe tomar el secuencial de la pÃ‚Â¢liza ingresado
         
          if @w_tipo_veh = @w_tip_vehl or @w_tipo_veh = @w_tip_vehp
          begin
             
	     select @w_poliza_tveh = null

             select distinct @w_poliza_tveh = ec_poliza
             from cu_endoso_colonial
             where ec_empresa = @i_aseguradora
               and (ec_tipo   = @w_tipo_veh or @w_endoso_unico = 'S')
         
	     if @w_poliza_tveh is null
	     begin
		   if @i_externo is null	--Fandrade 25/06/2009
		   begin
		      exec cobis..sp_cerror
			     @t_debug = @t_debug,
			     @t_file  = @t_file, 
			     @t_from  = @w_sp_name,
			     @i_num   = 1909014			--Aseguradora No Parametrizada, Error al obtener secuencial
			--rollback tran
		      return 1 
		   end
		   else
		   begin	----Fandrade 25/06/2009
			select @o_msg = 'Aseguradora No Parametrizada, Error al obtener secuencial'
			print 'GarantiÂ­a: ' + @w_codigo_externo + ', Mensaje: ' + @o_msg
			rollback tran
			return 1909014
		   end	-----Fandrade 25/06/2009
	     end
             
             --DAR 11/DIC/2014 Poder considerar mas de una aseguradora que pueda tener secuencial de endoso sin importar la oficina
             if charindex(@i_aseguradora + ';',@w_aseg_sec_unico) > 0 or @i_aseguradora = @w_aseg_sec_unico or @w_endoso_unico = 'S'
             	 select @w_sucursal = 50	--Unico secuencial para todas las sucursales
             else
             	 select @w_sucursal = @i_sucursal
 	     
 	     --DAR 15DIC2011
 	     --CONTROLAR QUE SOLO PUEDA INGRESAR UNA POLIZA PARA CUOTA SEGURA
 	     if @w_endoso_unico = 'S'
 	     begin
	        if exists(select 1
			 from cob_custodia..cu_poliza
			where po_poliza like @w_poliza_tveh + '-' + '%'
			  and po_estado_poliza = 'V'
			  and po_codigo_externo = @w_codigo_externo)
	        begin
		  select @o_msg = 'Ya existe ingresada una poliza para cuota segura'
		  print 'GarantÄ‚Â­a: ' + @w_codigo_externo + ', Mensaje: ' + @o_msg
		  rollback tran
		  return 1909014
	        end
 	     end
 	     
             if exists (select 1
                        from cu_endoso_colonial
         	           where ec_empresa = @i_aseguradora
           	             and (ec_tipo    = @w_tipo_veh or @w_endoso_unico = 'S')
                             and ec_poliza  = @w_poliza_tveh
                             and ec_oficina = @w_sucursal)	--@i_sucursal) FAE 11/Mar/2011
             begin

  	       select @w_sec_endoso_colonial  = max(ec_secuencial) + 1
                 from cu_endoso_colonial 
  	         where ec_empresa = @i_aseguradora
                  and (ec_tipo    = @w_tipo_veh or @w_endoso_unico = 'S')
                  and ec_poliza  = @w_poliza_tveh
                  and ec_oficina = @w_sucursal	--@i_sucursal  FAE 11/Mar/2011
                
                --Fandrade 07/May/2009 Inicio
                while 1 = 1
                begin
                 	select @i_poliza = @w_poliza_tveh + '-' + convert(varchar(10),@w_sec_endoso_colonial)
                 	if exists(select 1
				    from cu_poliza
				   where po_aseguradora    = @i_aseguradora
				     and po_poliza         = @i_poliza
				     and po_codigo_externo = @w_codigo_externo
				 )
			         begin
			           --print '@i_aseguradora %1! @i_poliza %2! @w_codigo_externo %3! ', @i_aseguradora, @i_poliza, @w_codigo_externo
			           select @w_sec_endoso_colonial  = @w_sec_endoso_colonial + 1
			         end
			         else
			           break
                end
                --Fandrade 07/May/2009 Fin
                
               update cu_endoso_colonial 
		  set ec_secuencial = @w_sec_endoso_colonial
		where ec_empresa = @i_aseguradora
		  and (ec_tipo   = @w_tipo_veh or @w_endoso_unico = 'S')
		  and ec_poliza  = @w_poliza_tveh
		  and ec_oficina = @w_sucursal --@i_sucursal  FAE 18/Abr/2011

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
             end
	     else
		begin
		   select @w_sec_endoso_colonial = 1

		   insert into cu_endoso_colonial(ec_empresa, ec_tipo, ec_poliza, ec_oficina, ec_secuencial)
					 values (@i_aseguradora, @w_tipo_veh, @w_poliza_tveh, @i_sucursal, @w_sec_endoso_colonial)

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
		end    

		select @i_poliza = @w_poliza_tveh + '-' + convert(varchar(10),@w_sec_endoso_colonial)                 
		select @o_poliza = @i_poliza
						 --print '@i_poliza %1!, @o_poliza %2!', @i_poliza, @o_poliza
	       end		--GarantÃ‚Â¡as tipo vehÃ‚Â¡culo
	end    --Renovacion N

	select @o_poliza = @i_poliza --FAndrade 12/02/2008
	 
         insert into cu_poliza(
              po_aseguradora,
              po_poliza,
              po_fvigencia_inicio,
              po_fvigencia_fin,
              po_moneda,
              po_monto_poliza,
              po_fecha_endozo,
	           po_monto_endozo,
              po_cobertura,
              po_descripcion,
              po_codigo_externo,
              po_fendozo_fin,
              po_estado_poliza)    
         values (
              @i_aseguradora,
              @i_poliza,
              @i_fvigencia_inicio,
              @i_fvigencia_fin,
              @i_moneda,
              @i_monto_poliza,
              @i_fecha_endozo,
 	           @i_monto_endozo,
              @i_cobertura,
              @i_descripcion,
              @w_codigo_externo,
              @i_fendozo_fin,
              @i_estado_poliza)

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

         /* Transaccion de Servicio */
         /***************************/
         insert into ts_poliza
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_poliza',
         @i_aseguradora,
         @i_poliza,
         @i_fvigencia_inicio,
         @i_fvigencia_fin,
         @i_moneda,
         @i_monto_poliza,
         @i_fecha_endozo,
	      @i_monto_endozo,
         @i_cobertura,
         @i_descripcion,
         @i_codigo_externo,
         @i_fendozo_fin)

         if @@error <> 0 
         begin
            /* Error en transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    end --if @w_existe = 0
    else
    begin
    	 select @o_poliza = @i_poliza	--FAndrade 12/02/2008
    	 
         update cob_custodia..cu_poliza
         set 
              po_fvigencia_inicio = @i_fvigencia_inicio,
              po_fvigencia_fin    = @i_fvigencia_fin,
              po_moneda           = @i_moneda,
              po_monto_poliza     = @i_monto_poliza,
              po_fecha_endozo     = @i_fecha_endozo,
	      po_monto_endozo     = @i_monto_endozo,
              po_cobertura        = @i_cobertura,
              po_descripcion      = @i_descripcion,
              po_fendozo_fin      = @i_fendozo_fin,
              po_estado_poliza    = @i_estado_poliza,
              po_secuencial_pag	  = @i_secuencial_pag	--Fandrade 12/02/2008 Aumento de secuencial de pago
         where po_aseguradora = @i_aseguradora 
           and po_poliza      = @i_poliza 
           and po_codigo_externo = @w_codigo_externo

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
         insert into ts_poliza
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_poliza',
         @w_aseguradora,
         @w_poliza,
         @w_fvigencia_inicio,
         @w_fvigencia_fin,
         @w_moneda,
         @w_monto_poliza,
         @w_fecha_endozo,
	 @w_monto_endozo,
         @w_cobertura,
         @w_descripcion,
         @w_codigo_externo,
         @w_fendozo_fin)

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
         insert into ts_poliza
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_poliza',
         @i_aseguradora,
         @i_poliza,
         @i_fvigencia_inicio,
         @i_fvigencia_fin,
         @i_moneda,
         @i_monto_poliza,
         @i_fecha_endozo,
	 @i_monto_endozo,
         @i_cobertura,
         @i_descripcion,
         @w_codigo_externo,
         @i_fendozo_fin)

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
    end  --@w_existe = 0

    /** SI SE ACTUALIZA LA POLIZA SE REGULARIZA LAS EXCEPCION CON SEGUROS VENCIDOS **/
    /** VERIFICANDO QUE LA NUEVA FECHA DE VENCIMIENTO SEA MAYOR AL DIA DE HOY.     **/
    --VIVI, 31/Mar/08
    if @i_fvigencia_fin > @w_today and @i_estado_poliza = 'V'
    begin
	    if exists( select 1 from cob_credito..cr_excepciones
		       where ex_codigo  = '1G'	
			 and ex_fecha_regula is null 
			 and ex_garantia= @w_codigo_externo)
	    begin
	      update cob_credito..cr_excepciones
	         set ex_fecha_regula  = @s_date,
	             ex_razon_regula  = @i_poliza,
	             ex_estado        = 'R',
	             ex_login_regula  = @s_user
	       where ex_codigo  = '1G'	--and  ex_clase  = 'R' and ex_estado  = 'A'	
		 and ex_fecha_regula is null 
		 and ex_garantia= @w_codigo_externo

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
	   end		--If exists		
    end
    /** FIN de @i_fvigencia_fin > @w_today **/
    
    commit tran
    return 0
end

/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin
         select @w_des_aseguradora = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla 
           and B.tabla = 'cu_des_aseguradora'
           and A.codigo = @w_aseguradora

         select @w_des_moneda = mo_descripcion
         from cobis..cl_moneda
         where mo_moneda = @w_moneda

         select @w_des_cobertura = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla 
           and B.tabla = 'cu_cob_poliza'
           and A.codigo = @w_cobertura

         select @w_des_estado_poliza = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla 
           and B.tabla = 'cu_estado_poliza' 
           and A.codigo = @w_estado_poliza

         select 
              @w_aseguradora,
              @w_des_aseguradora,
              @w_poliza,
              convert(char(10),@w_fvigencia_inicio,@i_formato_fecha),
              convert(char(10),@w_fvigencia_fin,@i_formato_fecha),
              isnull(convert(varchar(25),@w_moneda),''),
              @w_des_moneda,
              @w_monto_poliza,
              convert(char(10),@w_fecha_endozo,@i_formato_fecha),
	      @w_monto_endozo,  -- 10
              @w_cobertura,
              @w_des_cobertura,
              @w_descripcion,
              @w_codigo_externo,
              convert(char(10),@w_fendozo_fin,@i_formato_fecha),
              @w_estado_poliza,
              @w_des_estado_poliza
    end
    else
        return 1 
    return 0
end

if @i_operacion = 'A'
begin
      set rowcount 20
      if (@i_aseguradora is null and @i_poliza is null)
         select @i_aseguradora = @i_param1,
                @i_poliza = @i_param2
      if @i_modo = 0 
      begin
         select 'ASEGURADORA' = po_aseguradora, 'POLIZA' = po_poliza,
                'MONTO' = po_monto_poliza
           from cu_poliza with(1)
         if @@rowcount = 0
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
      end
      else 
      begin
         select po_aseguradora, po_poliza, po_monto_poliza
         from cu_poliza with(1)
         where ((po_aseguradora > @i_aseguradora) or
               (po_poliza > @i_poliza and po_aseguradora = @i_aseguradora))
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'S'
begin
      set rowcount 20
      if @i_modo = 0 
      begin
         select 'ASEGURADORA' = po_aseguradora, 
				'POLIZA' = po_poliza,
                'GARANTIA' = po_codigo_externo,
                'FECHA VENCIMIENTO' = po_fvigencia_inicio,
                'FECHA VIGENCIA' = po_fvigencia_fin, 
                'MONTO' = po_monto_poliza,
                'FECHA ENDOSO' = po_fecha_endozo
         from cu_poliza with(1) 
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1
         end
      end
      else 
      begin
         select 'ASEGURADORA' = po_aseguradora, 'POLIZA' = po_poliza,
                'GARANTIA' = po_codigo_externo,
                'FECHA VENCIMIENTO' = po_fvigencia_inicio,
                'FECHA VIGENCIA' = po_fvigencia_fin, 
                'MONTO' = po_monto_poliza,
                'FECHA ENDOSO' = po_fecha_endozo
         from cu_poliza with(1) 
         where ((po_aseguradora > @i_aseguradora) or
               (po_poliza > @i_poliza and po_aseguradora = @i_aseguradora))
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'D'
begin
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

   BEGIN TRAN

      delete cu_poliza
      where po_aseguradora    = @i_aseguradora
        and po_poliza         = @i_poliza
        and po_codigo_externo = @w_codigo_externo

      if @@error <> 0
      begin
            exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1907001
      end

         /* Transaccion de Servicio */
         /***************************/
	 --Vivi, 1/Abr/08
         insert into ts_poliza
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_poliza',
         @i_aseguradora,        @i_poliza,
         @w_fvigencia_inicio,   @w_fvigencia_fin,
         @w_moneda,         	@w_monto_poliza,
         @w_fecha_endozo,	@w_monto_endozo,
         @w_cobertura,          @w_descripcion,
         @w_codigo_externo,     @w_fendozo_fin)

         if @@error <> 0 
         begin
            /* Error en transaccion de servicio */
            exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1903003

	    ROLLBACK TRAN

            return 1 
         end
   COMMIT TRAN
end


if @i_operacion = 'V'
begin
   set rowcount 20
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    select po_aseguradora,po_poliza,po_codigo_externo
    from cu_poliza
    where po_codigo_externo = @w_codigo_externo
    order by po_aseguradora,po_poliza
end


if @i_operacion = 'Z'
begin   
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

      if exists (select * from cu_poliza
                 where po_aseguradora = @i_aseguradora
                 and po_poliza      = @i_poliza
                 and po_codigo_externo =@w_codigo_externo)
      begin
          select @w_aseguradora = po_aseguradora,
                 @w_poliza = po_poliza,
                 @w_monto_poliza = po_monto_poliza,
                 @w_fvigencia_inicio = po_fvigencia_inicio,
                 @w_fvigencia_fin = po_fvigencia_fin,
                 @w_fecha_endozo = po_fecha_endozo,
                 @w_monto_endozo = po_monto_endozo,
                 @w_moneda = po_moneda,
                 @w_cobertura = isnull(po_cobertura,''),  --PAL integraciÃ³n, si es nulo se envÃ­a 0
                 @w_descripcion = po_descripcion,
                 @w_codigo_externo = po_codigo_externo,
                 @w_fendozo_fin = po_fendozo_fin,
                 @w_estado_poliza = po_estado_poliza
          from cob_custodia..cu_poliza
          where po_aseguradora = @i_aseguradora
            and po_poliza = @i_poliza 

          select @w_des_aseguradora = A.valor
          from cobis..cl_catalogo A,cobis..cl_tabla B
          where B.codigo = A.tabla 
            and B.tabla = 'cu_des_aseguradora' 
            and A.codigo = @w_aseguradora

          select @w_des_moneda = mo_descripcion
          from cobis..cl_moneda
          where mo_moneda = @w_moneda

          select @w_des_cobertura = A.valor
          from cobis..cl_catalogo A,cobis..cl_tabla B
          where B.codigo = A.tabla 
            and B.tabla = 'cu_cob_poliza' 
            and A.codigo = @w_cobertura

          select @w_des_estado_poliza = A.valor
          from cobis..cl_catalogo A,cobis..cl_tabla B
          where B.codigo = A.tabla 
            and B.tabla = 'cu_estado_poliza' 
            and A.codigo = @w_estado_poliza

          select @w_aseguradora,
                 @w_des_aseguradora,
                 @w_poliza,
                 convert(char(10),@w_fvigencia_inicio,@i_formato_fecha),
                 convert(char(10),@w_fvigencia_fin,@i_formato_fecha),
                 isnull(convert(varchar(25),@w_moneda),''),
                 @w_des_moneda,
                 @w_monto_poliza,
                 convert(char(10),@w_fecha_endozo,@i_formato_fecha),
	         @w_monto_endozo,
                 @w_cobertura,
                 @w_des_cobertura,
                 @w_descripcion,
                 @w_codigo_externo,
                 convert(char(10),@w_fendozo_fin,@i_formato_fecha),
                 @w_estado_poliza,
                 @w_des_estado_poliza
         end
         else
             return 1
end


/* HHO */
if @i_operacion = 'Y'
begin


   select @w_aseg_veh = rtrim(pa_char)           
	from cobis..cl_parametro
	where pa_producto = 'CCA'
	and pa_nemonico = 'AVEH'

	select @w_existep   = 'N'
	select @w_validar  = 'N'   


	
    if exists (Select 1	from cobis..cl_tabla a, cobis..cl_catalogo b
					where a.tabla = 'cu_tgar_vehpesados'
					and a.codigo = b.tabla
					and b.codigo = @i_tipo )
		SELECT @w_validar  = 'S'   				
   
	if exists (Select 1	from cobis..cl_tabla a, cobis..cl_catalogo b
					where a.tabla = 'cu_tgar_vehlivianos'
					and a.codigo = b.tabla
					and b.codigo = @i_tipo )
		SELECT @w_validar  = 'S'   							

			
    if @w_validar  = 'S'
	begin
	    select @w_es_veh = 0
--		declare cursor_cuotas_sp insensitive cursor for  
		declare cursor_cuotas_sp cursor for  
		select po_aseguradora
		from  cob_custodia..cu_poliza
		where	 po_codigo_externo = @i_codigo_externo
		and 	 po_estado_poliza 		= 'V'
		--and 	 po_poliza        		<> ''
		
		open    cursor_cuotas_sp   
		fetch   cursor_cuotas_sp into @w_aseguradora
		while   @@FETCH_STATUS != -1 
		begin
			if convert(smallint,   @w_aseguradora) < 10
				select @w_aseguradora = '0' + @w_aseguradora
				
			select @w_es_veh = patindex ('%' +@w_aseguradora +'%', @w_aseg_veh)
			--print '@w_aseguradora %1! @w_es_veh  %2!', @w_aseguradora, @w_es_veh 
			if @w_es_veh > 0 --Si es la aseguradora 17 o 47 EXISTE
			begin
				   select @w_existep = 'S'
			end	   			

		fetch cursor_cuotas_sp into @w_aseguradora	
		end
		close cursor_cuotas_sp
		deallocate cursor_cuotas_sp		
		
		If @w_existep = 'S' 
			select  'S'  --tiene Poliza
		else
			select 'N'  -- No tiene Poliza
		
   end
   else
		select  'S'  --tiene Poliza

end
/* HHO */
if @i_operacion = 'K'
begin
	-- set rowcount = @i_rowcount
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
	
	SELECT	po_aseguradora, A.valor AS po_aseguradora_descripcion, po_poliza,po_codigo_externo
	from 	cob_custodia..cu_poliza, cobis..cl_catalogo A, cobis..cl_tabla B
	where 	po_codigo_externo = @w_codigo_externo
	AND 	B.codigo = A.tabla 
	and 	B.tabla = 'cu_des_aseguradora' 
	and 	A.codigo = po_aseguradora
	order by po_aseguradora,po_poliza
end

return 0
error:    /* Rutina que dispara sp_cerror dado el codigo de error */

             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1
go