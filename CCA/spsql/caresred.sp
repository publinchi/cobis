/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*	     Archivo:	              careserd.sp                             */
/*      Disenado por:           Xavier Maldonado                        */
/*      Fecha de escritura:     Mayo 2005                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Programa para genera el resumen de los movimientos de           */
/*      Redescuentos en totales por banco de segundo piso, ademas da    */
/*       mantenimiento a la forma                                       */
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_resumen_mov_redescuento')
   drop proc sp_resumen_mov_redescuento
go


create proc  sp_resumen_mov_redescuento
@s_user                 login        = NULL,
@s_term                 varchar (30) = NULL,
@s_date                 datetime     = NULL,
@s_ofi                  smallint     = NULL,
@i_operacion            char(1)      = 'B',   ---La opcion B es ejecucion de batch
@i_fecha_proceso        datetime     = NULL,
@i_ref_1                descripcion  = NULL,
@i_ref_2                descripcion  = NULL,
@i_ref_3                varchar(254) = NULL,
@i_ref_4                descripcion  = NULL,
@i_ref_5                varchar(254) = NULL,
@i_modo                 char(1)      = NULL


as 
declare
   @w_error             int,
   @w_ref1 		descripcion,
   @w_ref2 		descripcion,
   @w_ref3 		varchar(254),
   @w_ref4 		descripcion,
   @w_ref5 		varchar(254),
   @w_sp_name           descripcion,
   @w_bcoldex_vven	money,
   @w_bcoldex_vnov	money,
   @w_bcoldex_vred	money,
   @w_finagro_vven	money,
   @w_finagro_vnov	money,
   @w_finagro_vred	money,
   @w_findeter_vven	money,
   @w_findeter_vnov	money,
   @w_findeter_vred	money,
   @w_fecha_proceso     datetime,
   @w_dia               int,
   @w_mes               int,
   @w_anio              int,
   @w_fecha             varchar(10),
   @w_mes_letras        char(10)



/*INSERTA DATOS DE LA CARTA*/
/***************************/
if @i_operacion = 'I'  
begin

   truncate table ca_datos_carta_redes

   insert into ca_datos_carta_redes
   (dc_fecha, 	dc_login,	dc_ref_1,
    dc_ref_2,	dc_ref_3,	dc_ref_4,
    dc_ref_5)
   values
   (@s_date,	@s_user,	@i_ref_1,
    @i_ref_2,	@i_ref_3,	@i_ref_4,
    @i_ref_5)

   if @@error <> 0
   begin
     select @w_error = 710558
     goto ERROR
   end

end  


/*CONSULTA DATOS DE LA CARTA*/
/****************************/
if @i_operacion = 'Q'  
begin

   if @i_modo = 'A'   ---ENVIA LOS DATOS DE GENERALES DEL GERENTE DE OPERACIONES
   begin
      select 
      @w_ref1 = dc_ref_1,
      @w_ref2 = dc_ref_2,
      @w_ref3 = dc_ref_3,
      @w_ref4 = dc_ref_4,
      @w_ref5 = dc_ref_5 
      from  ca_datos_carta_redes

      /*DATOS AL FRONT-END*/
      /********************/
      select 
      @w_ref1, 
      @w_ref2,
      @w_ref3,
      @w_ref4,
      @w_ref5 
   end


   if @i_modo = 'B' --para la impresion   DATOS DE LOS TOTALES POR CADA BANCO DE SEGUNDO PISO
   begin

     /*INICIALIZACION DE VARIABLES*/
     select @w_bcoldex_vven   = 0, 
            @w_bcoldex_vnov   = 0,
            @w_bcoldex_vred   = 0,
            @w_finagro_vven   = 0,
            @w_finagro_vnov   = 0,
            @w_finagro_vred   = 0,
            @w_findeter_vven  = 0,
            @w_findeter_vnov  = 0,
            @w_findeter_vred  = 0


     if @i_fecha_proceso is null
     begin
        print 'Ingrese la fecha a procesar'
        return 0
     end

     /*BORRA TABLA DE DATOS CA_DATOS_IMPRESION*/
     truncate table ca_datos_impresion


     /*INSERCION DE CABECERA*/
     insert into ca_datos_impresion
     values ('BANCOLDEX',0,0,0)

     insert into ca_datos_impresion
     values ('FINDETER-',0,0,0)

     insert into ca_datos_impresion
     values ('FINAGRO-F',0,0,0)


     /*ACTUALIZACION DE LOS DATOS DE LA TABLA CA_DATOS_IMPRESION */
     update ca_datos_impresion
     set di_valor_ven = isnull(rt_valor,0)
     from ca_resumen_tmp
     where di_banco = rt_banco
     and   rt_tipo  = 'PAGO VENCIMIENTOS'
     and   rt_fecha_proceso = @i_fecha_proceso

     update ca_datos_impresion
     set di_valor_nov = isnull(rt_valor,0)
     from ca_resumen_tmp
     where di_banco = rt_banco
     and   rt_tipo  = 'PAGO NOVEDADES'
     and   rt_fecha_proceso = @i_fecha_proceso

     update ca_datos_impresion
     set di_valor_red = isnull(rt_valor,0)
     from ca_resumen_tmp
     where di_banco = rt_banco
     and   rt_tipo  = 'REDESCUENTOS NUEVOS'
     and   rt_fecha_proceso = @i_fecha_proceso


     /*SELECT DE MONTOS POR BANCO DE SEGUNDO DE LA TABLA CA_DATOS_IMPRESION*/
     select @w_bcoldex_vven = di_valor_ven,
            @w_bcoldex_vnov = di_valor_nov,
            @w_bcoldex_vred = di_valor_red
     from ca_datos_impresion
     where di_banco = 'BANCOLDEX'

     select @w_finagro_vven = di_valor_ven,
            @w_finagro_vnov = di_valor_nov,
            @w_finagro_vred = di_valor_red
     from ca_datos_impresion
     where di_banco = 'FINAGRO-F'

     select @w_findeter_vven = di_valor_ven,
            @w_findeter_vnov = di_valor_nov,
            @w_findeter_vred = di_valor_red
     from ca_datos_impresion
     where di_banco = 'FINDETER-'

     /*
     select @w_fecha_proceso = rt_fecha_proceso
     from ca_resumen_tmp
     */

     select @w_fecha  = convert(varchar(10),@i_fecha_proceso,101)

     select @w_dia  = datepart(dd,@w_fecha)
     select @w_mes  = datepart(mm,@w_fecha)
     select @w_anio = datepart(yy,@w_fecha)

     if @w_mes = 1
        select @w_mes_letras = 'ENERO'
     if @w_mes = 2
        select @w_mes_letras = 'FEBRERO'
     if @w_mes = 3
        select @w_mes_letras = 'MARZO'
     if @w_mes = 4
        select @w_mes_letras = 'ABRIL'
     if @w_mes = 5
        select @w_mes_letras = 'MAYO'
     if @w_mes = 6
        select @w_mes_letras = 'JUNIO'
     if @w_mes = 7
        select @w_mes_letras = 'JULIO'
     if @w_mes = 8
        select @w_mes_letras = 'AGOSTO'
     if @w_mes = 9
        select @w_mes_letras = 'SEPTIEMBRE'
     if @w_mes = 10
        select @w_mes_letras = 'OCTUBRE'
     if @w_mes = 11
        select @w_mes_letras = 'NOVIEMBRE'
     if @w_mes = 12
        select @w_mes_letras = 'DICIEMBRE'

      select 
      @w_ref1 = dc_ref_1,
      @w_ref2 = dc_ref_2,
      @w_ref3 = dc_ref_3,
      @w_ref4 = dc_ref_4,
      @w_ref5 = dc_ref_5 
      from  ca_datos_carta_redes

      /*DATOS AL FRONT-END*/
      /********************/
      select 
      @w_ref1, 
      @w_ref2,
      @w_ref3,
      @w_ref4,
      @w_ref5,
      @w_dia,
      @w_mes_letras,
      @w_anio,
      @w_bcoldex_vven, 
      @w_bcoldex_vnov,
      @w_bcoldex_vred,
      @w_findeter_vven,
      @w_findeter_vnov,
      @w_findeter_vred,
      @w_finagro_vven,
      @w_finagro_vnov,
      @w_finagro_vred


   end

end 




/*TOTALES POR CADA BANCO DE SEGUNDO PISO*/
/****************************************/

if @i_operacion = 'S'
begin
     select 'Banco Segundo Piso' = rt_banco, 
            'Tipo Resumen'       = rt_tipo, 
            'Total'              = rt_valor
     from   ca_resumen_tmp
     where rt_fecha_proceso = @i_fecha_proceso
end




/*EJECUCION DESDE BATCH*/
/***********************/
if @i_operacion = 'B'  
begin

   --BORRAR LOS REGISTROS DE LA FECHA PARA LA TABLA resumen
   --SI ESTOS YA FUERON CARGADOS
   
   delete ca_resumen_tmp
   where rt_fecha_proceso =  @i_fecha_proceso
   

   /*CARGAR LOS BANCOS DE REDESCUENTO*/
   /**********************************/
   select distinct codigo 
   into #banco_redes
   from cobis..cl_catalogo,ca_default_toperacion
   where tabla  = (select  codigo from cobis..cl_tabla where tabla = 'ca_tipo_linea')   ---2734
   and codigo   = dt_tipo_linea
   and dt_tipo  = 'R'

 
   /*SELECCIONAR LAS NOVEDADES DE LA FECHA*/
   /***************************************/
   select 'TIPO'         = 'PAGO NOVEDADES             ',
          codigo, 
          'Valor'        = isnull(sum(pp_saldo_intereses+pp_valor_prepago),0)
   into   #resumen
   from   ca_prepagos_pasivas, #banco_redes
   where  pp_estado_registro      = 'I'
   and    pp_estado_aplicar       != 'P' ---Rechazados
   and    pp_fecha_aplicar        = @i_fecha_proceso
   and    substring(pp_linea,1,3) = codigo
   group by codigo



   /*SELECCIONAR LOS VENCIMIENTOS DE LA FECHA*/
   /******************************************/
    insert into #resumen
   select 'PAGO VENCIMIENTOS',
          'CODIGO BANCO'   = cd_banco_sdo_piso,
          'MONTO VENCIDO'  = sum(cd_abono_capital + cd_abono_interes)
   from ca_conciliacion_diaria
   where cd_fecha_proceso = @i_fecha_proceso
   and cd_estado          = 'N'  ---antes P  
   group by cd_banco_sdo_piso


   /*SELECCIONAR LOS REDESCUENTOS NUEVOS DE LA FECHA*/
   /*************************************************/

   insert into #resumen
   select 'REDESCUENTOS NUEVOS',
          op_tipo_linea,
          sum(op_monto)
   from ca_operacion,
        ca_desembolso
   where op_operacion = dm_operacion
   and   op_estado    = 0
   and   op_tipo      = 'R'
   and   dm_fecha = @i_fecha_proceso
   group by op_tipo_linea


   insert into  ca_resumen_tmp
   select  @i_fecha_proceso,
           substring(b.valor,1,9),
           a.TIPO,
           a.Valor 
   from #resumen a, cobis..cl_catalogo b
   where b.tabla  = (select  codigo from cobis..cl_tabla where tabla = 'ca_tipo_linea')
   and a.codigo = b.codigo
   order by substring(b.valor,1,9)

end 

return 0

ERROR:
begin
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
  
end

go 
