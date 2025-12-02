/************************************************************************/
/*	Archivo:		        concepto.sp				                    */
/*	Stored procedure:	    sp_concepto				                    */
/*	Base de datos:		    cob_cartera	   		                        */
/*	Producto:               Cobis CARTERA                     	        */
/*	Disenado por:           Monica Torres G.			                */
/*	Fecha de escritura:     07-AGO-1995				                    */
/************************************************************************/
/*				              IMPORTANTE				                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	'MACOSA'.							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				               PROPOSITO				                */
/*	Este programa procesa las siguientes operaciones de ca_concepto	    */
/*	I: Creacion del concepto					                        */
/*	U: Actualizacion del registro de concepto			                */
/*	D: Eliminacion del registro de concepto				                */
/*	S: Busqueda del registro de concepto				                */
/*	Q: Consulta del registro de concepto				                */
/*	H: Ayuda en el registro de concepto				                    */
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_concepto')
   drop proc sp_concepto

go

---INC. 56639 ABR.18.2012

create proc sp_concepto (
@t_trn                  int	    = null,
@s_user                 login       = null,
@s_sesn                 int         = null,
@s_date		            datetime    = null,              
@s_term                 varchar(30) = null,
@s_org                  char(1)     = null,
@s_ofi                  smallint    = null,
@i_operacion		    char(2),
@i_modo			        tinyint 	= null,
@i_tipo			        char(1) 	= null,
@i_concepto	 	        catalogo	= null,
@i_descripcion		    descripcion	= null,
@i_categoria		    char(1)		= null,
@i_tipo_garantia        varchar(64)     = null,
@i_banco                cuenta          = null 
)
as  
declare 
@w_sp_name		    varchar(32),
@w_error		    int,
@w_codigo           tinyint,
@w_cos_concepto		catalogo,
@w_cos_descripcion	descripcion,
@w_cos_codigo		tinyint,
@w_cos_categoria  	catalogo,
@w_co_concepto		catalogo,
@w_co_descripcion	descripcion,
@w_co_codigo		tinyint,
@w_co_categoria  	catalogo

--- INICIALIZACION DE VARIABLES 
select @w_sp_name = 'sp_concepto'

if @i_operacion = 'I' begin

   --- VERIFICAR LA NO EXISTENCIA DEL CONCEPTO 
   if exists (select 1 from cob_cartera..ca_concepto
   where co_concepto = @i_concepto) begin
      select @w_error = 701146 
      goto ERROR
   end
   
   select @w_codigo = max(co_codigo) + 1
   from ca_concepto

   select @w_codigo = isnull(@w_codigo,0)

   if @w_codigo < 10 select @w_codigo = 10

   begin tran
   
   -- INSERT A CA_CONCEPTO 
   insert into ca_concepto (co_concepto, co_descripcion, co_categoria, co_codigo)
   values                  (@i_concepto, @i_descripcion, @i_categoria, @w_codigo)

   if @@error <> 0 begin
      select @w_error = 703103 
      goto ERROR
   end

      ---Transaccion de servicio - Inserción de Concepto
   insert into cob_cartera..ca_concepto_ts 
          (cos_fecha_proceso_ts, cos_fecha_ts, cos_usuario_ts, cos_oficina_ts,	
		   cos_terminal_ts, cos_tipo_transaccion_ts, cos_origen_ts, cos_clase_ts,
 	       cos_concepto, cos_descripcion, cos_codigo, cos_categoria	
		   )
   values (@s_date, getdate(), @s_user, @s_ofi, 
           @s_term, @t_trn, @s_org, 'N', 
           @i_concepto, @i_descripcion, @w_codigo, @i_categoria)
     if @@error <> 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end  

   delete cob_conta..cb_codigo_valor
   where cv_codval >= @w_codigo * 1000
   and   cv_codval <= (@w_codigo * 1000) + 999
   and   cv_producto = 7

   if @@error <> 0 begin
      select @w_error = 710003 
      goto ERROR
   end

   insert into cob_conta..cb_codigo_valor
   select 
   1,7,((co_codigo * 1000) + (es_codigo * 10)),
   rtrim(co_concepto)+'.' + rtrim(es_descripcion) + '.' + 'ACTUAL'
   from ca_concepto, ca_estado
   where co_concepto = @i_concepto
   and   es_codigo not in (98,99)

   if @@error <> 0 begin
      select @w_error = 710001 
      goto ERROR
   end

   commit tran

   return 0
end


--- UPDATE 
if @i_operacion = 'U' begin

   select @w_codigo = co_codigo
   from ca_concepto
   where co_concepto = @i_concepto

   if @@rowcount <> 1 begin
      select @w_error = 701146 
      goto ERROR
   end

   begin tran

  --- Seleccionar los nuevos datos 
      select @w_co_concepto    = co_concepto ,
   	     @w_co_descripcion = co_descripcion,
   	     @w_co_codigo      = co_codigo,  
   	     @w_co_categoria   = co_categoria
        from cob_cartera..ca_concepto
       where co_concepto = @i_concepto

     if @@rowcount = 0
        begin
          exec cobis..sp_cerror
          @t_from               = @w_sp_name,
          @i_num                = 710047
          return 1
        end


   --- UPDATE DATOS DEL CONCEPTO 
   update   cob_cartera..ca_concepto set
   co_descripcion   = @i_descripcion,
   co_categoria     = @i_categoria	
   where co_concepto = @i_concepto

   if @@error <> 0 begin
      select @w_error = 705063 
      goto ERROR
   end

      ---Transaccion de servicio - Inserción de Concepto
   insert into cob_cartera..ca_concepto_ts 
		   (cos_fecha_proceso_ts, cos_fecha_ts, cos_usuario_ts, cos_oficina_ts,	
		    cos_terminal_ts, cos_tipo_transaccion_ts, cos_origen_ts, cos_clase_ts,
		    cos_concepto, cos_descripcion, cos_codigo, cos_categoria )
    values (@s_date, getdate(), @s_user, @s_ofi, 
            @s_term, @t_trn, @s_org, 'P', 
            @w_co_concepto, @w_co_descripcion, @w_co_codigo, @w_co_categoria)

    if @@error <> 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end  

      ---Transaccion de servicio - Inserción de Concepto
   insert into cob_cartera..ca_concepto_ts 
          (cos_fecha_proceso_ts, cos_fecha_ts, cos_usuario_ts, cos_oficina_ts,	
		    cos_terminal_ts, cos_tipo_transaccion_ts, cos_origen_ts, cos_clase_ts,
		    cos_concepto, cos_descripcion, cos_codigo, cos_categoria)
    values (@s_date, getdate(), @s_user, @s_ofi, 
            @s_term, @t_trn, @s_org, 'A', 
            @i_concepto, @i_descripcion, @w_co_codigo, @i_categoria)

   if @@error <> 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end  

   delete cob_conta..cb_codigo_valor
   where cv_codval >= @w_codigo * 1000
   and   cv_codval <= (@w_codigo * 1000) + 999
   and   cv_producto = 7

   if @@error <> 0 begin
      select @w_error = 710003 
      goto ERROR
   end

   insert into cob_conta..cb_codigo_valor
   select 
   1,7,((co_codigo *1000) + (es_codigo * 10)),
   rtrim(co_concepto)+'.' + rtrim(es_descripcion) + '.' + 'ACTUAL'
   from ca_concepto, ca_estado
   where co_concepto = @i_concepto
   and   es_codigo not in (98,99)

   if @@error <> 0 begin
      select @w_error = 710001 
      goto ERROR
   end

   commit tran
  
   return 0
end


---- ELIMINACION 
if @i_operacion = 'D' begin

   select @w_codigo = co_codigo
   from ca_concepto
   where co_concepto = @i_concepto

   if @@rowcount <> 1 begin
      select @w_error = 701146
      goto ERROR
   end

   begin tran

    --- Valores para transaccion de servicio Concepto
     select @w_cos_concepto	= co_concepto,
	    @w_cos_descripcion	= co_descripcion,
	    @w_cos_codigo	= co_codigo, 
	    @w_cos_categoria    = co_categoria	
       from cob_cartera..ca_concepto
      where co_concepto = @i_concepto

   delete cob_cartera..ca_concepto
   where co_concepto = @i_concepto

   if @@error <> 0 begin
       select @w_error = 707066 
       goto ERROR
   end

      ---Transaccion de servicio - Eliminación de Concepto
   insert into cob_cartera..ca_concepto_ts 
	   (cos_fecha_proceso_ts, cos_fecha_ts, cos_usuario_ts, cos_oficina_ts,	
	    cos_terminal_ts, cos_tipo_transaccion_ts, cos_origen_ts, cos_clase_ts,
		cos_concepto, cos_descripcion, cos_codigo, cos_categoria	)
   values (@s_date, getdate(), @s_user, @s_ofi, 
        @s_term, @t_trn, @s_org, 'B', 
        @w_cos_concepto, @w_cos_descripcion, @w_cos_codigo, @w_cos_categoria)
   
          if @@error <> 0
     begin
        exec cobis..sp_cerror
                @t_from         = @w_sp_name,
                @i_num          = 710047
        return 1
     end 

   delete cob_conta..cb_codigo_valor
   where cv_codval >= @w_codigo * 1000
   and   cv_codval <= (@w_codigo * 1000) + 999
   and   cv_producto = 7

   if @@error <> 0 begin
      select @w_error = 710003 
      goto ERROR
   end

   commit tran
end


--- SEARCH 
if @i_operacion = 'S' begin
   set rowcount 20
 
   if @i_modo = 0
      select 'Rubro' = co_concepto,
      'Descripci¢n' = substring(co_descripcion,1,30),
      'C¢digo' = co_codigo,
      'Categor¡a' = co_categoria 		                      
      from   cob_cartera..ca_concepto
      order by co_concepto
      
   if @i_modo = 1
      select 'Rubro'	= co_concepto,
      'Descripci¢n' = substring(co_descripcion,1,30),
      'C¢digo' = co_codigo,                      
      'Categor¡a' = co_categoria 		                            
      from   cob_cartera..ca_concepto
      where co_concepto  > @i_concepto
      order by co_concepto

   set rowcount 0

end

--- QUERY         

if @i_operacion = 'Q' begin

   select  co_descripcion,co_codigo 
   from	cob_cartera..ca_concepto
   where   co_concepto  = @i_concepto

   if @@rowcount = 0 begin
      select @w_error = 701145 
      goto ERROR
   end

end

--- HELP 

if @i_operacion = 'H' begin
   --- CONSULTA DE LOS CONCEPTOS  
   if @i_tipo = 'A' begin
    
   if   @i_concepto is not null
        select @i_modo = 1
      
      set rowcount 25
      if @i_modo = 0
         select 'Rubro' = co_concepto,
  	            'Descripcion' = substring(co_descripcion,1,30),
   	            'Codigo' = co_codigo,
                'categoria' = co_categoria
         from	cob_cartera..ca_concepto
	     order by co_concepto
        
      if @i_modo = 1
       	 select 'Rubro' = co_concepto,
	            'Descripción' = substring(co_descripcion,1,30),
	            'Código' = co_codigo,
                'categoria' = co_categoria
         from	cob_cartera..ca_concepto
	     where co_concepto > @i_concepto
	     order by co_concepto
        
     set rowcount 0 
     return 0
   end ---- H

   if @i_tipo = 'V' begin
      select substring(co_descripcion,1,30) 
      from cob_cartera..ca_concepto
      where co_concepto = @i_concepto
      --and   co_categoria = 'C'

      if @@rowcount = 0 begin
         select @w_error = 701145 
         goto ERROR
      end
   end

   --- TRAE LOS RUBROS PARA UNA OPERACION ESPECIFICA. 
   if @i_tipo = 'C' begin
      select 'Rubro' = co_concepto, 
		      'Descripcion' = substring(co_descripcion,1,30),
		      'Codigo' = co_codigo
      from ca_operacion, ca_rubro_op, ca_concepto 
      where op_banco = @i_banco 
      and op_operacion = ro_operacion 
      and ro_concepto = co_concepto 
      and co_categoria in ('M','I')
      and ro_fpago in ('P','A')
      order by co_concepto
   end



   --- TRAE LOS TIPOS DE GARATIAS PARAMETRIZADOS
   if @i_tipo = 'G' begin

    select 'TIPO GARANTIA'=substring(tc_tipo,1,10),
       'DESCRIPCION'  = substring(tc_descripcion,1,30)
    from cob_custodia..cu_tipo_custodia
    order by tc_tipo

  end

   if @i_tipo = 'U' begin

      select substring(tc_descripcion,1,30)
      from cob_custodia..cu_tipo_custodia
     where tc_tipo = @i_tipo_garantia

   end

   --- TRAE LAS TABLAS DE CATALOGO DE CARTERA 
   if @i_tipo = 'T' begin

      select 'TABLA'=tabla,
        'DESCRIPCION'= descripcion
      from cobis..cl_tabla
      where tabla like 'ca_otr%'
      order by tabla
      set transaction isolation level read uncommitted
  end

   if @i_tipo = 'B' begin
     if @i_modo = 0 begin
         select 'Rubro' = co_concepto,
  	 'Descripcion' = substring(co_descripcion,1,30),
   	 'Codigo' = co_codigo,
         'categoria' = co_categoria
         from	cob_cartera..ca_concepto
         where  co_categoria = 'I'
	 order by co_concepto
      end

     if @i_modo = 1 begin
         select 'Rubro'         = co_concepto,
  		  	    'Descripcion' = substring(co_descripcion,1,30),
		   	    'Codigo'      = co_codigo,
                'categoria'   = co_categoria
         from	cob_cartera..ca_concepto
         where  co_categoria = 'C'
	 order by co_concepto
      end


   end


end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug  = 'N', 
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error

go




















