/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                receprec.sp                             */
/*      Procedimiento:          sp_recibir_recaudos                     */
/*      Disenado por:           Juan Bernardo Quinche                   */
/*      Fecha de escritura:     28 de Mayo de 2008                      */
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
/*      Recibe los recaudos masivos establecidos por convenios          */
/*      i_operacion = '1' Retorna el nombre del archivo a importar      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recibir_recaudos' )
   drop proc sp_recibir_recaudos
go
create procedure sp_recibir_recaudos (
   @s_term           descripcion   = 'MACOSA',   --null, DETERMINAR COMO ES RESPECTO A LA CONEXION DEL OPERADOR
   @s_ofi            smallint      = 1,          --null, DETERMINAR COMO ES RESPECTO A LA CONEXION DEL OPERADOR
   @s_user           login         = 'Operador', --null, DETERMINAR COMO ES RESPECTO A LA CONEXION DEL OPERADOR
   @s_date           datetime      = NULL,
   @i_codigo         int           = 0,
   @t_trn            int           = 0,
   @t_debug          char          = 'N',
   @i_formato_fecha  int           = 103,
   @i_operacion      char          = null,
   @i_reg_ini        int           = 0,
   @i_tipo_cobro     char          = null,
   @i_valor          money         = 0,
   @i_cobra_iva      char          = '',
   @i_delimit        char          = null,
   @i_tipo_iva       catalogo      = null,
   @i_ancho_fijo     char          = null,
   @i_moneda         tinyint       = 0,
   @i_procesa        char          = 'S',           --verificar y procesar
   @i_fecha          datetime      = '2005-06-23',  -- formato AAAAMMDD
   @i_FilePath       varchar(1000) = 'F:\Vbatch\Cartera\' output,
   @i_FileNameMask   varchar(1000) = '*.*',
   @i_subtipo        char          = '0',
   @i_lote           int           = null,
   @i_archivo        varchar(1000),
   @i_validar       char(1)       = 'S',
   @o_error          int       = 0 output
   )
as
declare  @w_sp_name        descripcion,
         @w_error          int, 
         @w_fisico         catalogo,
         @w_rows           int,
         @w_codigo         descripcion,
         @w_tipo_cobro     cuenta, 
         @w_valor          money,
         @w_cobra_iva      char,
         @w_moneda         tinyint,
         @w_tipo_iva       catalogo,
         @w_delimit        char,
         @w_anchofijo      char,
         @w_pone_prefijo   char,
         @w_prefijo        cuenta,
         @w_pone_subfijo   char,
         @w_subfijo        cuenta,
         @w_formato_fecha  cuenta,
         @w_fecha          datetime,
         @w_cfecha         varchar(10),
         @w_rowcount       int,
         @w_archivo        varchar(1024),
         @w_cmd            varchar(1024),
         @w_r1_tipo        smallint,
         @w_r1_codigo      varchar(13),
         @w_r1_fecha_pag   datetime,
         @w_r1_cod_ent     smallint,
         @w_r1_num_cta     cuenta,
         @w_r1_filler      descripcion,
         @w_tipo           int,
         @w_cedula         int,
         @w_banco          cuenta,
         @w_valor_pag      money,
         @w_oficina        int,
         @w_oficina_baloto int,         
         @w_num_reg        int,
         @w_fecha_pag      datetime,
         @w_cedula_cartera int,
         @count_records    int,
         @suma_pagos       money,
         @w_valor_cartera  money,
         @r3_tipo          int,
         @r3_num_rec       int,
         @r3_fecha_pag     datetime,
         @r3_sum_valor     money,
         @r3_filler        cuenta, 
         @w_filepath       varchar(1000), 
         @w_forma_pago     varchar(10),  --DEBE SER: catalogo
         @w_lote           int,
         @w_tipo_aplica    varchar(10),  --DEBE SER CHAR(1)
         @w_tipo_reduc     varchar(10),  --DEBE SER CHAR(1)  
         @w_concepto       varchar(10),
         @w_ruc            varchar(30)

select @w_sp_name = 'sp_recibir_recaudos',
       @w_fisico  = 'receprec.sp',
       @w_error   = 0,
       @w_cmd     =  ''

select @w_tipo_cobro    = cr_tipo_cobro,    
       @w_valor         = cr_valor,
       @w_cobra_iva     = cr_cobra_iva, 
       @w_moneda        = cr_moneda,        
       @w_tipo_iva      = cr_tipo_iva,   
       @w_delimit       = cr_delimit,
       @w_anchofijo     = cr_anchofijo,
       @w_pone_prefijo  = cr_pone_prefijo ,
       @w_prefijo       = cr_prefijo,
       @w_pone_subfijo  = cr_pone_subfijo,
       @w_subfijo       = cr_subfijo,
       @w_formato_fecha = cr_formato_fecha,
       @w_forma_pago    = cr_concepto,
       @w_tipo_aplica   = cr_tipo_aplicacion,
       @w_tipo_reduc    = cr_tipo_reduccion
from ca_convenio_recaudo        
where cr_codigo= @i_codigo

delete recaudos_masivos_tmp1
where r1_fecha_pag >= '01/01/1900'

delete recaudos_masivos_tmp2
where r2_fecha >= '01/01/1900'

select @w_fecha =  @i_fecha
if @i_subtipo = '1' or @i_subtipo ='0'
begin
--    select @w_cfecha = CONVERT(VARCHAR(10),@w_fecha,112)
  select @w_cfecha = dbo.cadena_zeros(day(@w_fecha),2)+ right('0'+ltrim(str(month(@w_fecha),2)),2)+ str(year(@w_fecha),4)

    /*armar nombre del archivo a importar*/
    select @w_archivo = ''
   
    if @w_pone_prefijo = 'S'
       select @w_archivo = rtrim(@w_prefijo)
      
    select @w_archivo = rtrim(@w_archivo) + rtrim(@w_cfecha)
    if @w_pone_subfijo = 'S'
       select @w_archivo = rtrim(@w_archivo) + rtrim(@w_subfijo)
      
    select @w_archivo = rtrim(@i_FilePath) + rtrim(@w_archivo) + '.txt'
    select @i_archivo = @w_archivo
   
    if @t_debug = 'S'
       print @i_FilePath+@w_archivo
    if @i_subtipo='1'
       select @w_archivo
   
end     /* fin subtipo = '1' */

if @i_subtipo = '0'
begin
    select @w_error = 0

    select @w_concepto      = ''

    exec sp_abonos_masivos_generales --(abmagene.sp)
         @i_operacion = 'L',
         @o_lote_gen  = @w_lote out

    create table #temp_entrada_datos (s varchar (200))

    /* valida que el archivo se encuentre */        

    truncate table #temp_entrada_datos
 
    select @w_cmd = ' bulk insert #temp_entrada_datos from '''
    select @w_cmd = @w_cmd + replace(@w_archivo,'"','') + ''''
    select @w_cmd = @w_cmd + ' with (FIELDTERMINATOR=''|'''+ ', ROWTERMINATOR = '''
    select @w_cmd = @w_cmd + char(10) + ''')' -- , LASTROW = 1)'     
    --print @w_cmd

    EXEC (@w_cmd)
    if @@error <> 0
    begin
        select @w_error = 710585
        goto ERROR
    end
   
    if @t_debug='S'
       print 'ejecutar merges 1'
      
    insert recaudos_masivos_tmp1
    (
    r1_tipo     ,   
    r1_codigo   ,
    r1_fecha_pag,
    r1_cod_ent  ,
    r1_num_cta  ,
    r1_filler   
    )
    select               
    r1_tipo        = convert(int,substring(s,1,2)),
    r1_codigo      = substring(s,3,13) ,
    r1_fecha_pag   = convert(datetime,substring(s,16,8)),
    r1_cod_ent     = convert(int,substring(s,24,3)),
    r1_num_cta     = substring(s,27,15), 
    r1_filler      = substring(s,42,23)
    from  #temp_entrada_datos
    where substring(s,1,2) = '01'
   

--------------------------------------------
-- version para 13 caracteres --definitivo
--------------------------------------------
    insert recaudos_masivos_tmp2
    (
    r2_tipo      ,      r2_cedula    ,    r2_banco     ,    r2_valor     ,
    r2_oficina   ,    r2_secuen    ,    r2_fecha     
    )
    select               
    r2_tipo      = substring(s,1,2),
    r2_cedula    = convert (int,substring(s,3,12)),
    r2_banco     = substring(s,15,13) ,
    r2_valor     = convert(int,substring(s,28,13)),   --convert(int,substring(s,30,13)),
    r2_oficina   = convert(int,substring(s,41,2)),    --convert(int,substring(s,43,2)),
    r2_secuen    = convert(int,substring(s,43,7)),
    r2_fecha     = convert(datetime, substring(s,50,8)+' '+substring(s,58,2)+':'+substring(s,60,2)+':'+substring(s,62,2),111)
    from  #temp_entrada_datos
    where substring(s,1,2) = '02'
    

    if @t_debug='S'
       print 'ejecutar merges 3'
   
    set nocount on
    insert   recaudos_masivos_tmp3
    (
    r3_tipo        , 
    r3_num_rec     ,
    r3_sum_valor   ,
    r3_filler      )
    select               
    r3_tipo         = substring(s,1,2) ,
    r3_num_rec      = convert(int,substring(s,3,9)) ,
    r3_sum_valor    = convert(int,substring(s,12,18)) ,
    r3_filler       = substring(s,30,35)
    from  #temp_entrada_datos
    where substring(s,1,2) = '09'
    
    drop table #temp_entrada_datos
    if exists ( select  1 
                from ca_abonos_masivos_cabecera
                where mc_secuencial= @i_codigo
                and   mc_fecha_archivo = @i_fecha)
    begin
        select @w_error = 710586
        goto ERROR
    end
               
    /* validacion de encabezado */
    select @w_r1_tipo       =  r1_tipo     ,   
           @w_r1_codigo     =  r1_codigo,
           @w_r1_fecha_pag  =  r1_fecha_pag,
           @w_r1_cod_ent    =  r1_cod_ent  ,
           @w_r1_num_cta    =  r1_num_cta  ,
           @w_r1_filler     =  r1_filler   
    from recaudos_masivos_tmp1

    if @@rowcount =0
    begin 
        select @w_error = 710587
        goto ERROR
    end
       
    if @w_r1_tipo <> 1
    begin
        select @w_error = 710588
        goto ERROR
    end

    select @w_ruc = fi_ruc 
    from  cobis..cl_filial
    where fi_filial = 1
    
    
    if charIndex('-',@w_ruc) !=0
        select @w_ruc = substring(@w_ruc,1,charIndex('-',@w_ruc)-1)
   
    
--    if @i_codigo <> @w_r1_cod_ent
--    begin
--        select @w_error = 710588
--        PRINT 'El codigo de la entidad en el archivo no coincide, con la entidad recaudadora'
--        goto ERROR
--    end
    
    if @w_r1_fecha_pag <> @i_fecha
    begin
        select @w_error = 710589
        goto ERROR
    end
    --begin tran
    select @w_banco = '19112345678'  
    if ( substring(@w_r1_num_cta, patindex('%[1-9]%',@w_r1_num_cta),24) <> @w_banco  )
    begin
        select  @w_error = 710590
        print substring(@w_r1_num_cta,patindex('%[1-9]%',@w_r1_num_cta),12)+ '-' +@w_banco
        --los demas datos del encabezado no coinciden
        goto ERROR
    end
    if @@error <>0
    begin
        select @w_error = 710591
        print 'Error creando el cursor de detalles'
        goto ERROR
    end

    declare cur_detalles cursor for 
    select r2_tipo,      r2_cedula,  r2_banco,   r2_valor,
           r2_oficina,   r2_secuen,  r2_fecha
    from recaudos_masivos_tmp2
    if @t_debug='S'
       Print 'Validacion encabezado terminada'
      
    open cur_detalles
    select @count_records = 1 -- ESTABA EN 1
    select @suma_pagos = 0
    fetch from cur_detalles
    into  @w_tipo,          @w_cedula,     @w_banco,      @w_valor_pag,
          @w_oficina_baloto,@w_num_reg,    @w_fecha_pag 

    while @@fetch_status = 0
    begin
        
        select @count_records = @count_records  + 1
        if @w_tipo <> 2
        begin
            select @w_error = 710592
            goto ERROR_CUR
        end
        if patindex('%[A-Z]%', @w_banco)<>0 begin
            --operacion migrada, poner guiones
             select substring(@w_banco,1, 6)+'-'+substring(@w_banco,7,4 )+'-'+substring(@w_banco,11, 1)
        end
        
        /* busca informacion del cliente contra el archivo historico*/
        select @w_cedula_cartera = fh_cedula,
               @w_valor_cartera  = fh_valor -- + fh_valor_recaudo
        from  ca_facturacion_recaudos_his
        where fh_codigo = @i_codigo
        and   fh_fecha  = @i_fecha
        and   fh_banco = @w_banco
        if @@rowcount = 0
        begin
            select @w_error = 710593
            print 'Error : ' + cast(@w_error as varchar) +@w_banco
            goto ERROR_CUR
        end
        else
        begin
            if @w_valor_cartera <> @w_valor_pag
            begin
                select @w_error = 710594
                print 'Error : ' + cast(@w_error as varchar) + cast(@w_valor_pag as varchar) + '  ' + cast(@w_valor_cartera as varchar)
                -- no coincide valor
                goto ERROR_CUR
            end 
            select @suma_pagos = @suma_pagos + @w_valor_pag
            if @w_num_reg <> @count_records
            begin
                select @w_error = 710595
                print 'Error : ' + cast(@w_num_reg as varchar)+' - '+ cast(@count_records as varchar)
                goto ERROR_CUR
            end
        end
        select @w_oficina = ho_entero
        from  ca_homologar
        where ho_tabla      = 'of_baloto'
        and   ho_codigo_org = @w_oficina_baloto
        if @@rowcount = 0
        begin
            select @w_error = 710596
            print 'Error : ' + cast(@w_num_reg as varchar)+' - '+ cast(@count_records as varchar)
            goto ERROR_CUR
        end
        
        execute sp_abonos_convenio
             @s_term              = @s_term,
             @s_ofi               = @s_ofi,
             @s_user              = @s_user,
             @s_date              = @s_date,
             @t_debug             = @t_debug,
             @i_operacion         = 'B',
             @i_lote              = @w_lote,
             @i_banco             = @w_banco,
             @i_fecha_pago        = @w_fecha_pag,
             @i_forma_pago        = @w_forma_pago,
             @i_tipo_aplicacion   = @w_tipo_aplica,
             @i_tipo_reduccion    = @w_tipo_reduc,
             @i_monto             = @w_valor_pag,
             @i_concepto          = @w_concepto,
             @i_oficina           = @w_oficina,
             @i_moneda            = @w_moneda,
             @i_cuenta            = ''
             
        if @@error != 0
        begin
            select @w_error = 710600
            print 'Error : insertando en abonos_masivos_generales'
            goto ERROR_CUR
        end
         
        fetch from cur_detalles
        into  @w_tipo,          @w_cedula,  @w_banco, @w_valor_pag,
              @w_oficina_baloto,@w_num_reg, @w_fecha_pag 
              
        
    end
    
    
    if @t_debug='S'   
       print 'Validacion de cuerpo terminada'
    select   @r3_tipo       = r3_tipo ,
             @r3_num_rec    = r3_num_rec ,         
             @r3_sum_valor  = r3_sum_valor ,
             @r3_filler     = r3_filler 
    from recaudos_masivos_tmp3

  
    if @r3_num_rec <> @count_records -1
    begin
        select @w_error = 710597
        goto ERROR_CUR
    end
    if @r3_sum_valor <> @suma_pagos
    begin
        select @w_error = 710598
        goto ERROR_CUR
    end
    if @r3_tipo <> 9
    begin
        select @w_error = 710599
        goto ERROR_CUR
    end

    insert into ca_abonos_masivos_cabecera (
    mc_total_registros,    mc_fecha_archivo,    mc_monto_total,
    mc_secuencial,         mc_estado,           mc_lote, 
    mc_errores )
    values (
    @r3_num_rec,           @i_fecha,            @r3_sum_valor,
    @i_codigo,             'I',                 @w_lote,
    0 )
                                         
   
    /* procesamiento de los pagos */
   
    truncate table recaudos_masivos_tmp1
    truncate table recaudos_masivos_tmp2
    truncate table recaudos_masivos_tmp3
   
   
    close cur_detalles
    deallocate cur_detalles
    select mg_lote,         mg_nro_credito,   mg_operacion,  mg_fecha_pago,   
           mg_forma_pago,   mg_monto_pago,    mg_estado,     mg_moneda 
    from ca_abonos_masivos_generales
    where mg_lote = @w_lote
    
end

return 0

 
ERROR:
--select @i_error = @w_error  -- para manejo de errores
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error

   
return @w_error

ERROR_CUR:
--if exists (cursor) begin
close cur_detalles
deallocate cur_detalles
 
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
  
return @w_error

go

