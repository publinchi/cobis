/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                conentco.sp                             */
/*      Procedimiento:          sp_consulta_entidad_convenio            */
/*      Disenado por:           Juan Bernardo Quinche                   */
/*      Fecha de escritura:     22 de Mayo de 2008                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Consulta las entidades para realizar recaudos por convenios     */
/*             Operaciones:  Q  Consulta codigo y valor del catalogo    */
/*                           C  Consulta el codigo y obtiene datos      */
/*                           A  Agrega datos de un nuevo convenio       */
/*                           U  Hace un update de datos                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 
           from sysobjects 
           where name = 'sp_consulta_entidad_convenio'
           )
   drop proc sp_consulta_entidad_convenio
go

create procedure sp_consulta_entidad_convenio (
   @i_codigo         int      = 0,
   @t_trn            int      = 0,
   @t_debug          char     = 'N',
   @i_formato_fecha  int      = 101,
   @i_operacion      char     = null,
   @i_reg_ini        int      = 0,
   @i_tipo_cobro     char     = null,
   @i_valor          money    = 0,
   @i_cobra_iva      char     = '',
   @i_delimit        char     = null,
   @i_tipo_iva       catalogo = null,
   @i_ancho_fijo     char     = null,
   @i_moneda         tinyint  = 0,
   @i_concepto       varchar(20) = ''
   )
as


declare  @w_error          int, 
         @w_sp_name        descripcion,
         @w_fisico         catalogo,
         @w_convenio       descripcion,
         @w_rowcount       int,
         @w_tipo_aplicacion char(1),
         @w_tipo_reduccion  char(1)
         
         
         
select @w_sp_name = 'sp_consulta_entidad_convenio',
         @w_fisico = 'conentco.sp',
         @w_error = 0

if @i_operacion='Q' 
   begin
   
      select 'Codigo' = b.codigo,
             'Valor ' = b.valor
      from  cobis..cl_tabla a,
         cobis..cl_catalogo b
      where a.tabla = 'ca_convenio_recaudo'
      and   b.tabla = a.codigo
      and   b.estado = 'V'
   end

   

if @i_operacion='C'   -- Consulta
   begin
           
      select @w_convenio = b.valor
      from  cobis..cl_tabla a,
            cobis..cl_catalogo b
      where a.tabla  = 'ca_convenio_recaudo'
      and   b.tabla  = a.codigo
      and   b.estado = 'V'
      and   b.codigo = @i_codigo
      
      select @w_rowcount=@@rowcount
      if not @w_rowcount = 0
         select cr_moneda,    cr_tipo_cobro, cr_valor,      cr_cobra_iva,
                cr_tipo_iva,  cr_anchofijo,  cr_delimit,    mo_descripcion,
                mo_decimales, @w_convenio as convenio, va_tipo, va_descripcion,
                cr_concepto
         from  ca_convenio_recaudo, cobis..cl_moneda, ca_valor
         where cr_codigo = @i_codigo
               and mo_moneda =cr_moneda
               and va_tipo = cr_tipo_iva
   end


if @i_operacion='A'    -- Agregar de datos
   begin
    print 'incluir'
   /* insertar la informacion para un nuevo convenio */
   
   select 
   @w_tipo_aplicacion ='C',
   @w_tipo_reduccion ='N'
             
   insert into ca_convenio_recaudo
      (  cr_codigo,     cr_tipo_cobro,    cr_valor,   cr_cobra_iva,
         cr_tipo_iva,   cr_delimit,       cr_moneda,  cr_anchofijo,
         cr_concepto,   cr_tipo_aplicacion,cr_tipo_reduccion)
      values
      (  @i_codigo,     @i_tipo_cobro,    @i_valor,   @i_cobra_iva,
         @i_tipo_iva,   @i_delimit,       @i_moneda,  @i_ancho_fijo,
         @i_concepto,   @w_tipo_aplicacion,@w_tipo_reduccion)
   
   end 
 
if @i_operacion='U'  begin -- Update de tablas
   /* actualizar la informacion del convenio */
   select 
   @w_tipo_aplicacion ='C',
   @w_tipo_reduccion ='N'
   update  ca_convenio_recaudo 
        set cr_tipo_cobro  =@i_tipo_cobro,
            cr_valor       =@i_valor,
            cr_cobra_iva   =@i_cobra_iva,
            cr_anchofijo   =  @i_ancho_fijo, 
            cr_delimit     =@i_delimit,
            cr_tipo_iva    =@i_tipo_iva,
            cr_moneda      =@i_moneda,
            cr_concepto   = @i_concepto,
            cr_tipo_aplicacion = @w_tipo_aplicacion,
            cr_tipo_reduccion = @w_tipo_reduccion
   where cr_codigo = @i_codigo
  end

return 0

 
ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   
return @w_error
                        
go
