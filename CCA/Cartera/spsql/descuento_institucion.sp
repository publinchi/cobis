/************************************************************************/
/*   Archivo:             dsctoins.sp                                   */
/*   Stored procedure:    sp_descuento_institucion                      */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:                                                      */
/*   Fecha de escritura:  12-ABR-2005                                   */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA", representantes exclusivos para el Ecuador de la          */
/*   "NCR CORPORATION".                                                 */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*            PROPOSITO                                                 */
/*   Este SP controla las opciones de la ventana FDescuentoInstitucion  */
/*   los Las Busquedas, las inserciones, y actualizaciones              */
/************************************************************************/  
/*            MODIFICACIONES                                            */
/*   FECHA         AUTOR               RAZON                            */
/*   12-ABR-2005   Serguey Pat         Emision inicial                  */
/*   25-ABR-2005   Segundo Correa      Recuperar el formato de Archivo  */
/*   06-SEP-2005   Diego Aguilar       Re-Diseñado                      */
/*   Dic06-Abr07   Ricardo Reyes B.    Planillas Fase II -Global		*/
/************************************************************************/
use cob_cartera
go
if exists (select * from sysobjects where name = 'sp_descuento_institucion')
   drop proc sp_descuento_institucion
go
create proc sp_descuento_institucion (
   @s_ssn            int       = null,
   @s_user           login     = null,
   @s_term           varchar (30) = null,
   @s_date           datetime = null,
   @s_srv            varchar (30) = null,
   @s_lsrv           varchar (30) = null,
   @s_ofi            smallint = null,
   @t_debug          char(1) ='N',
   @t_file           varchar (14) = null,
   @t_from           descripcion = null,
   @t_trn            SMALLINT = null,
   @i_operacion      char(1) = null,
   @i_modo           tinyint = null,
   @i_institucion    catalogo = null,
   @i_cliente        int = null,
   @i_nombre         descripcion = null,
   @i_nombre_sel     descripcion = null,
   @i_direccion      descripcion = null,
   @i_telefono       descripcion = null,
   @i_contacto       descripcion = null,
   @i_area_cobro     descripcion = null,
   @i_porcent_servi  float = null,
   @i_frec_desc      char(1) = null,
   @i_forma_pago     catalogo = null,
   @i_forma_pago_servicio   CHAR(1) = NULL,
   @i_ruc            VARCHAR(30) = NULL,
   @i_cuenta         cuenta = null,
   @i_estado         catalogo = null,
   @i_concepto       catalogo = null,
   @i_clasificacion  catalogo = null,				--LIM 04/Abr/2006
   @i_plazo	         catalogo = null,				--LIM 04/Abr/2006
   @i_categoria	     catalogo = null,				--LIM 04/Abr/2006
   @i_antiguedad     catalogo = null,				--LIM 04/Abr/2006
   @i_convenio       char(1) = null,
   @i_tasa_aplicar   float = null

)
as
declare
   @w_sp_name        descripcion,
   @w_return         int,
   @w_operacionca    int,
   @w_toperacion     catalogo,
   @w_concepto       catalogo,
   @w_valor          float,
   @v_toperacion     catalogo,
   @v_concepto       catalogo,
   @w_institucion    catalogo ,
   @w_cliente        int , 
   @w_cliente_aux    varchar(20), 
   @w_nombre         descripcion ,
   @w_direccion      descripcion ,
   @w_telefono       descripcion ,
   @w_contacto       descripcion ,
   @w_area_cobro     descripcion ,
   @w_porcent_servi  float ,
   @w_frec_desc      char(1),
   @w_forma_pago     catalogo ,
   @w_archivo        catalogo ,
   @w_cuenta         cuenta ,
   @w_estado         catalogo,
   @w_clasificacion  catalogo,	 
   @w_plazo          catalogo,
   @w_categoria      catalogo,
   @w_antiguedad     catalogo,     
   @w_semiautonoma   catalogo,
   @w_conta          catalogo,
   @w_convenio       char(1),
   @w_tasa           float,
   @w_ruc            varchar(25),
   @w_forma_pago_serv char(1)

/*  Inicializar nombre del stored procedure  */
select @w_sp_name = 'sp_descuento_institucion'

/****************************************************************/
/* ** Search ** */

if @i_operacion = 'S'             /* Busca todos los 20 primeros */
begin
   set rowcount 20

   if @i_modo = 0   /* traer los 20 primeros */
   begin
      select "233965"   = di_institucion,
            "RUC" = di_ruc,
            "233802" = di_nombre ,
            "233512" = di_direccion,
            "233462" = di_telefono,
            "211278" = di_contacto,
            "233966" = di_area_cobro ,
            "233967" = di_porcent_servi_cobro,
            "Forma pago servicio" = di_forma_pago_servicio,
            "233968" = di_frecuencia_desc,
            "233350" = di_forma_pago,
            "233154" = di_cliente ,  
            "233157" = di_cuenta,
            "233311" = di_estado  ,
            "61338"  = di_clasificacion,		  
	        "230901" = di_plazo, 				
            "234319" = di_categoria,				
            "234320" = di_antiguedad,   		   
            "15798"  = di_tasa_aplicar, 
            "15799"  = di_convenio
        from ca_descuento_institucion
             order by di_institucion
   end
   
   if @i_modo = 1   /* traer los siguientes, a partir del ultimo que se trajo */
   begin
      select "233965"   = di_institucion,
            "RUC"  = di_ruc,
            "233802" = di_nombre ,
            "233512" = di_direccion,
            "233462" = di_telefono,
            "211278" = di_contacto,
            "233966" = di_area_cobro ,
            "233967" = di_porcent_servi_cobro,
            "Forma pago servicio" = di_forma_pago_servicio,
            "233968" = di_frecuencia_desc,
            "233350" = di_forma_pago,
            "233154" = di_cliente ,  
            "233157" = di_cuenta,
            "233311" = di_estado , 
            "61338"  = di_clasificacion,		   
            "230901" = di_plazo, 				
            "234319" = di_categoria,			   
            "234320" = di_antiguedad,   			
            "15798"  = di_tasa_aplicar, 
            "15799"  = di_convenio           
        from ca_descuento_institucion
       where di_institucion > @i_concepto
       order by di_institucion
   end

   if @i_modo = 2   /* TRAER DATOS DE UNA INSTITUCION */
   begin
      select di_institucion,
             di_ruc,
             di_nombre,
             di_direccion,
             di_telefono,
             di_contacto,
             di_area_cobro ,
             di_porcent_servi_cobro,
             di_forma_pago_servicio,
             di_frecuencia_desc,
             di_forma_pago,
             di_cliente ,  
             di_cuenta,
             di_estado , 
             di_clasificacion,			
             di_plazo, 				
             di_categoria,			
             di_antiguedad,   			
             di_tasa_aplicar, 
             di_convenio
        from ca_descuento_institucion
       where di_institucion = @i_concepto
   end

   set rowcount 0
   return 0

end


/****************************************************************/
/* ** Alfabetico ** */

if @i_operacion = 'A'             /* Busca todos los 20 primeros */
begin
   set rowcount 20

   select @i_nombre_sel = isnull(@i_nombre_sel, '')
   if right(@i_nombre_sel, 1) != '%'
      select @i_nombre_sel = rtrim(rtrim(@i_nombre_sel)) + '%'

   if @i_modo = 0   /* traer los 20 primeros */
   begin
      select "233965" = di_institucion,
             "233802" = di_nombre ,
             "RUC"       = di_ruc,
             "233512" = di_direccion,
             "233462" = di_telefono,
             "211278" = di_contacto,
             "233966" = di_area_cobro ,
             "233967" = di_porcent_servi_cobro,
             "Forma pago servicio" = di_forma_pago_servicio,
             "233968" = di_frecuencia_desc,
             "233350" = di_forma_pago,
             "233154" = di_cliente ,  
             "233157" = di_cuenta,
             "233311" = di_estado  ,
             "61338"  = di_clasificacion,		   
	     	 "230901" = di_plazo, 				
             "234319" = di_categoria,			   
             "234320" = di_antiguedad,   			
             "15798"  = di_tasa_aplicar, 
             "15799"  = di_convenio
        from ca_descuento_institucion
       where di_nombre like @i_nombre_sel
       order by di_nombre
   end
   
   if @i_modo = 1   /* traer los siguientes, a partir del ultimo que se trajo */
   begin
      select "233965" = di_institucion,
             "233802" = di_nombre ,
             "RUC"       = di_ruc,
             "233512" = di_direccion,
             "233462" = di_telefono,
             "211278" = di_contacto,
             "233966" = di_area_cobro ,
             "233967" = di_porcent_servi_cobro,
             "Forma pago servicio" = di_forma_pago_servicio,
             "233968" = di_frecuencia_desc,
             "233350" = di_forma_pago,
             "233154" = di_cliente ,  
             "233157" = di_cuenta,
             "233311" = di_estado , 
             "61338"  = di_clasificacion,		   
             "230901" = di_plazo, 				
             "234319" = di_categoria,				
             "234320" = di_antiguedad,   		   
             "15798"  = di_tasa_aplicar, 
             "15799"  = di_convenio
        from ca_descuento_institucion
       where di_nombre like @i_nombre_sel
         and ((di_nombre  = @i_nombre and di_institucion > @i_institucion)
           or (di_nombre > @i_nombre))
       order by di_nombre, di_institucion
   end

   set rowcount 0
   return 0

end


if @i_operacion = 'C'             -- Convenio
begin
   set rowcount 20              /* Busca  20 registros */

   if @i_modo = 0   /* traer los 20 primeros */
   begin
      select "233965" = di_institucion,
             "RUC" = di_ruc,
             "233802" = di_nombre ,
             "233512" = di_direccion,
             "233462" = di_telefono,
             "211278" = di_contacto,
             "233966" = di_area_cobro ,
             "233967" = di_porcent_servi_cobro,
             "Forma pago servicio" = di_forma_pago_servicio,
             "233968" = di_frecuencia_desc,
             "233350" = di_forma_pago,
             "233154" = di_cliente ,  
             "233157" = di_cuenta,
             "233311" = di_estado  ,
             "61338"  = di_clasificacion,			
	     	 "230901" = di_plazo, 			   
             "234319" = di_categoria,				
             "234320" = di_antiguedad,   		   
             "15798"  = di_tasa_aplicar, 
             "15799"  = di_convenio
        from ca_descuento_institucion
       where di_convenio = 'S'
       order by di_nombre
   end
   
   if @i_modo = 1   /* traer los siguientes, a partir del ultimo que se trajo */
   begin
      select "233965" = di_institucion,
             "RUC" = di_ruc,
             "233802" = di_nombre ,
             "233512" = di_direccion,
             "233462" = di_telefono,
             "211278" = di_contacto,
             "233966" = di_area_cobro ,
             "233967" = di_porcent_servi_cobro,
             "Forma pago servicio" = di_forma_pago_servicio,
             "233968" = di_frecuencia_desc,
             "233350" = di_forma_pago,
             "233154" = di_cliente ,  
             "233157" = di_cuenta,
             "233311" = di_estado , 
             "61338"  = di_clasificacion,		   
             "230901" = di_plazo, 			   
             "234319" = di_categoria,				
             "234320" = di_antiguedad,   			
             "15798"  = di_tasa_aplicar, 
             "15799"  = di_convenio
        from ca_descuento_institucion
       where di_convenio = 'S'
	      and ((di_nombre  = @i_nombre and di_institucion > @i_institucion)
           or (di_nombre > @i_nombre))
       order by di_nombre, di_institucion
   end
   set rowcount 0
   return 0
end
/****************************************************************/

if @i_operacion = 'Q'
   begin
   --if @t_trn = 7393            /* trae el detalle de un solo reguistro */
   -- begin

      select @w_institucion = di_institucion,           
             @w_ruc         = di_ruc,
             @w_nombre      = di_nombre,                
             @w_direccion   = di_direccion,             
             @w_telefono    = di_telefono,              
             @w_contacto    = di_contacto,              
             @w_area_cobro  = di_area_cobro ,           
             @w_porcent_servi   = di_porcent_servi_cobro, 
             @w_forma_pago_serv = di_forma_pago_servicio,
             @w_frec_desc   = di_frecuencia_desc,       
             @w_forma_pago  = di_forma_pago,            
             @w_cliente     = di_cliente ,              
             @w_cuenta      = di_cuenta,                
             @w_estado      = di_estado,                
             @w_clasificacion = di_clasificacion,	 
             @w_plazo         = di_plazo,                
             @w_categoria     = di_categoria,		 
             @w_antiguedad    = di_antiguedad,   	 
             @w_convenio      = di_convenio,    
             @w_tasa          = di_tasa_aplicar
        from ca_descuento_institucion
          where di_institucion = @i_institucion

      select  @w_institucion ,   
              @w_ruc,
              @w_nombre ,        
              @w_direccion ,     
              @w_telefono ,      
              @w_contacto ,      
              @w_area_cobro ,    
              @w_porcent_servi , 
              @w_forma_pago_serv,
              @w_frec_desc ,     
              @w_forma_pago ,    
              @w_cliente ,       
              @w_cuenta ,        
              @w_estado,         
              @w_clasificacion,	 
              @w_plazo,          
              @w_categoria,      
              @w_antiguedad,     
              @w_convenio,
              @w_tasa    
   if @@rowcount = 0 
      begin
      exec cobis..sp_cerror   /* No hay registros para este codigo */
         @t_debug = @t_debug,
         @t_file = @t_file,
         @t_from = @w_sp_name,
         @i_num = 708192
      return 708192   
   end
END


/****************************************************************/

if @i_operacion = 'I'
   begin
   if @i_frec_desc not in('Q','M')
      begin 
      print ' Error en Frecuencia de Pago '
      return 725003
   end 
   if exists (select 1 from ca_descuento_institucion where di_ruc = @i_ruc )
      begin
      print 'El registro ya existe'
      return 263501
      end
   else
      begin
      begin TRAN
      SELECT @i_institucion = isnull(max(di_institucion),0) FROM ca_descuento_institucion
      SELECT @i_institucion = @i_institucion +1
      insert into ca_descuento_institucion(
          di_institucion,  di_cliente, 
          di_nombre,       di_direccion,
          di_telefono,     di_contacto,
          di_area_cobro,   di_porcent_servi_cobro, 
          di_frecuencia_desc, di_forma_pago,
          di_cuenta,       di_estado, 
          di_clasificacion,di_plazo, di_categoria,
          di_antiguedad,   
          di_convenio, 
          di_tasa_aplicar, di_ruc, di_forma_pago_servicio)
      values ( 
          @i_institucion,  @i_cliente,
          @i_nombre,       @i_direccion,
          @i_telefono,     @i_contacto,
          @i_area_cobro,   @i_porcent_servi,
          @i_frec_desc,    @i_forma_pago,
          @i_cuenta,       @i_estado,  
          @i_clasificacion,@i_plazo, @i_categoria,
          @i_antiguedad,   @i_convenio,
          @i_tasa_aplicar, @i_ruc, @i_forma_pago_servicio)

      if @@error != 0 
         begin 
         exec cobis..sp_cerror  /* 'Error en Insercion'  */
      	   @t_debug = @t_debug,
	       @t_file = @t_file,
	       @t_from = @w_sp_name,
	       @i_num = 708189
	     return 708189 
      end
      commit tran
    end 
    return 0
end

/****************************************************************/
if @i_operacion = 'U'
   begin
   if exists (select 1 from ca_descuento_institucion where di_institucion = @i_institucion )
      BEGIN
      IF EXISTS(SELECT 1 FROM ca_descuento_institucion WHERE di_ruc = @i_ruc AND di_institucion <> @i_institucion)
      BEGIN
         exec cobis..sp_cerror  /* 'Error en Insercion'  */
      	   @t_debug = @t_debug,
	       @t_file = @t_file,
	       @t_from = @w_sp_name,
	       @i_num = 1850033
 	     return 1850033 
      END
      
      begin tran
      update ca_descuento_institucion set
          di_nombre = @i_nombre ,
          di_cliente = @i_cliente ,
          di_direccion = @i_direccion ,
          di_telefono = @i_telefono ,
          di_contacto = @i_contacto ,
          di_area_cobro = @i_area_cobro ,
          di_porcent_servi_cobro = @i_porcent_servi ,
          di_frecuencia_desc = @i_frec_desc ,
          di_forma_pago = @i_forma_pago ,
          di_cuenta = @i_cuenta ,
          di_estado = @i_estado,
          di_clasificacion = @i_clasificacion,			
          di_plazo = @i_plazo,					
          di_categoria = @i_categoria,				
          di_antiguedad = @i_antiguedad,			
          di_convenio = @i_convenio,
          di_tasa_aplicar = @i_tasa_aplicar,
          di_ruc = @i_ruc,
          di_forma_pago_servicio = @i_forma_pago_servicio
       where di_institucion = @i_institucion
       if @@error != 0    
          begin 
          exec cobis..sp_cerror   /* error error en update */
             @t_debug = @t_debug,
             @t_file = @t_file,
             @t_from = @w_sp_name,
             @i_num = 708190
          return 708190
       end
       commit tran  
       end
    else
       begin
       exec cobis..sp_cerror   /*el registro no existe*/
           @t_debug = @t_debug,
           @t_file = @t_file,
           @t_from = @w_sp_name,
           @i_num = 701156
       return 708190  
    end 
    return 0
end

go