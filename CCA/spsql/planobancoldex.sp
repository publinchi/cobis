/************************************************************************/
/*      Archivo:                cabancoldex.sp                          */
/*      Stored procedure:       so_no_se_utiliza                        */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan B. Quinche                         */
/*      Fecha de escritura:     Mayo 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      de justificaciones financieras                                  */
/************************************************************************/
use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'so_no_se_utiliza')
   drop proc so_no_se_utiliza
go
create proc so_no_se_utiliza
    @i_param1  varchar(10)  , --Fecha inicial de fechas de desembolso
    @i_param2  varchar(10)  , --Fecha final de fechas de desembolso
    @i_param3  varchar(10)  , --Origen Fondos 
    @i_param4  varchar(10)    --Batch 
as

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_retorno            int,
        @w_tramite            int,
        @w_est_vigente        tinyint,
        @w_est_vencido        tinyint,
        @w_est_cancelado      tinyint,
        @w_est_castigado      tinyint,
        @w_est_suspenso       tinyint,
        @w_pa_char_tdr        char(3),
        @w_pa_char_tdn        char(3),
        @w_en_tipo_ced        char(2),
        @w_operacion          int,
        @w_saldo_cap          money,
        @w_op_monto           money,
        @w_sal_capital        money ,
        @w_valor              money,
        @w_tipo               varchar(100),
        @w_num_obligacion     int,           
        @w_intermediario      varchar(24),          
        @w_monto_destino1     money,         
        @w_destino2           catalogo,            
        @w_monto_destino2     money,         
        @w_destino3           catalogo,           
        @w_monto_destino3     money ,        
        @w_fecha_desembolso   datetime,    
        @w_fecha_vencimiento  datetime,   
        @w_clase_credito      char(2),        
        @w_periodo_gracia     char(2),       
        @w_amortizacion       char(2), 
        @w_sqr                varchar(250), 
        @w_file               varchar(250), 
        @w_s_app              varchar(250),
        @w_cmd                varchar(250),
        @w_path               varchar(250),
        @w_bd                 varchar(250),
        @w_tabla              varchar(250),
        @w_margen             float,               
        @w_tasa_interes       float ,          
        @w_saldo_credito      money,         
        @w_nit_intermediario  varchar(24),
        @w_linea              catalogo,           
        @w_telefono           varchar(16), 
        @w_comando            varchar(500),
        @w_batch              int,
        @w_errores            varchar(255),
        @w_destino            varchar(255),
        @w_fecha_ini          datetime,
        @w_fecha_fin          datetime,
        @w_tipo_gar           catalogo,
        @w_activos_fijos      money

return 0  ---No se utiliza

truncate table cob_cartera..ca_justifica_fina 

if exists (select 1 from sysobjects where name = 'ca_planobancoldex') drop table ca_planobancoldex
create table ca_planobancoldex ( dato varchar(600) null )

select 
    @w_fecha_ini = @i_param1, --Fecha inicial de fechas de desembolso
    @w_fecha_fin = @i_param2, --Fecha final de fechas de desembolso
    @w_batch     = convert(int,@i_param4)

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out

/* PARAMETROS DE TIPOS DE DIRECCION */
select @w_pa_char_tdr = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDR'

/* CODIGO TELEFONO DEL NEGOCIO */
select @w_pa_char_tdn = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDN'

/* crear tabla con codigos de fuentes de recurso emprender */
select c.codigo
into #temp_cod
from cobis..cl_tabla as t ,
cobis..cl_catalogo as c
where t.tabla='cr_fuente_recurso'
and t.codigo = c.tabla
--and c.valor like '%BANCOLDEX%'

/* INSERCION EN TABLA TEMPORAL DE LOS DATOS DEL REPORTE */
insert into cob_cartera..ca_justifica_fina
select  op_operacion,                                        
        op_tramite,                                         
        'AAAAAAAAAAAAAAA',
        isnull(replace(replace(replace(op_banco, '-',''), 'P',''), 'M',''),'0'),
        (case when en_tipo_ced = 'CC' then '2'   
              when en_tipo_ced = 'NI' then '1'
              when en_tipo_ced = 'TI' then '3' 
              when en_tipo_ced = 'CE' then '4' 
              when en_tipo_ced = 'PA' THEN '0'
              when isnull(en_tipo_ced, '' ) = '0' THEN '0' end) ,
        convert(varchar,en_ced_ruc),
        convert(char(50),op_nombre),
        '00',
        convert(char(50),isnull(di_descripcion,'')), 
        convert(varchar,di_ciudad) ,
        isnull(substring(ltrim(rtrim(en_actividad)),1,4),'0000') ,   
        (select convert(varchar,isnull(mi_num_trabaj_remu,'0'))
        from cob_credito..cr_microempresa
        where mi_tramite = tr_tramite)  , 
        '000'   , 
        convert(varchar,isnull(convert(int,c_total_activos),'0'))  ,          
        isnull(year(en_fecha_patri_bruto),year(op_fecha_liq)) , 
        convert(varchar,convert(int,op_monto_aprobado)),
        '1',    
        convert(varchar,convert(int,op_monto)), 
        '0','00000000000','0','00000000000',                                        
        cast(year(op_fecha_liq) as varchar(4))+  replicate ('0' ,2  - len (cast(month(op_fecha_liq) as varchar(2))) ) + cast(month(op_fecha_liq) as varchar(2)) + replicate ('0' ,2  - len (cast(day (op_fecha_liq) as varchar(2))) ) +  
        cast(day(op_fecha_liq) as varchar(2)), 
        cast(year(op_fecha_fin) as varchar(4))+  replicate ('0' ,2  - len (cast(month(op_fecha_fin) as varchar(2))) ) + cast(month(op_fecha_fin) as varchar(2)) + replicate ('0' ,2  - len (cast(day (op_fecha_fin) as varchar(2))) ) +  
        cast(day(op_fecha_fin) as varchar(2)), 
        '1','000','1', 
        '00.00',  
        (select isnull(substring(convert(varchar,isnull(ro_porcentaje_efa,'00.00')) ,1,5) , '00.00') 
          from cob_cartera..ca_rubro_op
          where ro_operacion = op_operacion
          and   ro_concepto = 'INT') ,                      
        '00000000000',              
        '18','00000000000','20','00000000000', '00','00000000000',                     
        (case when p_sexo  ='M' then '1'   
              when p_sexo  ='F' then '2'  end),            
        convert(varchar(11),isnull(op_codigo_externo,'0')),
        (case 	when op_origen_fondos = 1 then '0000'   
                when op_origen_fondos = 2 then '6001'   
     			when op_origen_fondos = 3 then '6095' 
     			when op_origen_fondos = 4 then '6915' end),                                                                 
     			        
        (select top 1  case when te_prefijo <> '' then ltrim(rtrim(te_prefijo)) + isnull(te_valor,0) else te_valor end 
         from   cobis..cl_direccion
                left outer join cobis..cl_telefono on
                     te_ente      = di_ente
                and  te_direccion = di_direccion
         where di_ente      = op_cliente
         and   di_tipo      = @w_pa_char_tdn) ,             
         
        cast(year(p_fecha_nac) as varchar(4))+  replicate ('0' ,2  - len (cast(month(p_fecha_nac) as varchar(2))) ) + cast(month(p_fecha_nac) as varchar(2)) + replicate ('0' ,2  - len (cast(day (p_fecha_nac) as varchar(2))) ) +  
        cast(day(p_fecha_nac) as varchar(2)), 
        '05',                                               
        '02'                                                                                    
from  cob_cartera..ca_operacion,
      cob_credito..cr_tramite,
      cobis..cl_ente,
      cobis..cl_direccion
where op_estado     in (@w_est_vigente,@w_est_vencido,@w_est_cancelado,@w_est_castigado,@w_est_suspenso)
and   op_fecha_liq  between @w_fecha_ini and @w_fecha_fin
and   tr_tramite     = op_tramite
and   en_ente        = op_cliente
and   op_toperacion <> 'ALT_FNG'    
and   en_ente        = di_ente
and   di_principal   = 'S'
and   op_origen_fondos in (select * from #temp_cod)
and   tr_tipo not in ('T', 'U')

order by op_fecha_liq

DECLARE cur_financiero cursor for
select 
   fi_operacion, 
   fi_tramite,
   fi_activos

from cob_cartera..ca_justifica_fina
order by fi_operacion 
   
OPEN cur_financiero

FETCH cur_financiero  INTO
   @w_operacion,
   @w_tramite,
   @w_activos_fijos

while @@fetch_status = 0
begin
   if @@fetch_status = -1
    begin
       /* ERROR EN RECUPERACION DE DATOS DEL CURSOR */
       select @w_error   = 'ERROR EN RECUPERACION DE DATOS DEL CURSOR',
              @w_retorno = 1
              close cur_financiero
              deallocate cur_financiero
              return 1 
    end

    exec  sp_calcula_saldo
     @i_operacion       = @w_operacion, 
     @i_tipo_pago       = 'A',
     @o_saldo           = @w_saldo_cap out
     
   update ca_justifica_fina
   set fi_saldo_credito =  replicate('0',11-len(isnull(ltrim(rtrim(convert(varchar,convert(int,isnull(@w_saldo_cap,0))))),''))) + isnull(ltrim(rtrim(convert(varchar,convert(int,isnull(@w_saldo_cap,0))))),'')
   where fi_operacion = @w_operacion
   
   if @@error <> 0
   begin
            print 'Error en actualizacion  de saldo: '  +cast(@w_operacion as varchar)
            select @w_error = 'Error'
            close cur_financiero
            deallocate cur_financiero
          return 1
    end
   
   /*     
   select @w_valor    = cu_valor_actual
   from cob_credito..cr_gar_propuesta , cob_custodia..cu_custodia              
   where gp_tramite  =  @w_tramite         
   and   cu_codigo_externo = gp_garantia     
   and   cu_tipo <>  '1200'
   */
   
   select @w_valor = 0
   select @w_valor = isnull(sum(dj_total_bien),0)
   from cob_credito..cr_microempresa, cob_credito..cr_dec_jurada
   where mi_tramite    = @w_tramite    
   and   dj_codigo_mic = mi_secuencial    
         
   if @w_valor > 0
   begin
        update ca_justifica_fina set 
        fi_valor_garan_1 = replicate('0',11-len(isnull(ltrim(rtrim(convert(varchar,convert(int,isnull(@w_valor,0))))),''))) + isnull(ltrim(rtrim(convert(varchar,convert(int,isnull(@w_valor,0))))),'')
        where fi_operacion = @w_operacion        

            if @@error <> 0
            begin
                     print 'Error en actualizacion Vlr. de garantias_1: '  +cast(@w_operacion as varchar)
                     select @w_error = 'Error'
                     close cur_financiero
                     deallocate cur_financiero
                   return 1
             end        
   end
   
   if @w_activos_fijos = 0
   begin
      select @w_activos_fijos = mi_total_eyb+ mi_total_cxc +(mi_total_mp+mi_total_pep+ mi_total_pt)+mi_total_af 
      from cob_credito..cr_microempresa
      where mi_tramite    = @w_tramite       
            
      if @w_activos_fijos > 0
      begin
           update ca_justifica_fina set 
           fi_activos = replicate('0',11-len(isnull(ltrim(rtrim(convert(varchar,convert(int,isnull(@w_valor,0))))),''))) + isnull(ltrim(rtrim(convert(varchar,convert(int,isnull(@w_activos_fijos,0))))),'')
           where fi_operacion = @w_operacion        
           
               if @@error <> 0
               begin
                        print 'Error en actualizacion Vlr. de activos fijos: '  +cast(@w_operacion as varchar)
                        select @w_error = 'Error'
                        close cur_financiero
                        deallocate cur_financiero
                      return 1
                end        
      end   
   end
   
   FETCH cur_financiero INTO
   @w_operacion,
   @w_tramite,
   @w_activos_fijos
   
   end 
close cur_financiero
deallocate cur_financiero 

-- NIT Banca mia

update cob_cartera..ca_justifica_fina
set fi_nit_intermediario = replace(fi_ruc, '-','')
from cobis..cl_filial
where fi_filial = 1

update cob_cartera..ca_justifica_fina
set fi_valor_garan_1 = fi_monto_destino1
where fi_clase_garan_1 = 9

update cob_cartera..ca_justifica_fina
set fi_ciudad = codigo_sib
from cob_credito..cr_corresp_sib
where fi_ciudad = codigo
and   tabla = 'T107'

truncate table cob_cartera..ca_planobancoldex

insert into ca_planobancoldex
select 
dbo.cadena_zeros(fi_num_obligacion    ,15) +                                                            -- 1     
dbo.cadena_zeros(fi_intermediario     ,15) +                                                            -- 2
dbo.cadena_zeros(fi_tipo_nit          ,1 ) +                                                            -- 3
dbo.cadena_zeros(fi_nit               ,11) +                                                            -- 4
convert(char(50),fi_nom_beneficiario     ) +                                                            -- 5
dbo.cadena_zeros(fi_tipo_sociedad     ,2 ) +                                                            -- 6
convert(char(50),fi_direccion)             +                                                            -- 7  
dbo.cadena_zeros(fi_ciudad            ,5 ) +                                                            -- 8
dbo.cadena_zeros(fi_ciu               ,4 ) +                                                            -- 9
dbo.cadena_zeros(fi_empleos           ,3 ) +                                                            -- 10
dbo.cadena_zeros(fi_empleo_genera     ,3 ) +                                                            -- 11
dbo.cadena_zeros(fi_activos           ,11) +                                                            -- 12
dbo.cadena_zeros(fi_fecha_corte_act   ,4 ) +                                                            -- 13
dbo.cadena_zeros(fi_valor_credito     ,11) +                                                            -- 14
dbo.cadena_zeros(fi_destino1          ,1 ) +                                                            -- 15
dbo.cadena_zeros(fi_monto_destino1    ,11) +                                                            -- 16
dbo.cadena_zeros(fi_destino2          ,1 ) +                                                            -- 17
dbo.cadena_zeros(fi_monto_destino2    ,11) +                                                            -- 18
dbo.cadena_zeros(fi_destino3          ,1 ) +                                                            -- 19
dbo.cadena_zeros(fi_monto_destino3    ,11) +                                                            -- 20
dbo.cadena_zeros(fi_fecha_desembolso  ,8 ) +                                                            -- 21
dbo.cadena_zeros(fi_fecha_vencimiento ,8 ) +                                                            -- 22
dbo.cadena_zeros(fi_clase_credito     ,1 ) +                                                            -- 23
dbo.cadena_zeros(fi_periodo_gracia    ,3 ) +                                                            -- 24
dbo.cadena_zeros(fi_amortizacion      ,1 ) +                                                            -- 25
dbo.cadena_zeros(fi_margen            ,5 ) +                                                            -- 26
dbo.cadena_zeros(fi_tasa_interes      ,5 ) +                                                            -- 27
dbo.cadena_zeros(fi_saldo_credito     ,11) +                                                            -- 28
dbo.cadena_zeros(fi_clase_garan_1     ,2 ) +                                                            -- 29
dbo.cadena_zeros(fi_valor_garan_1     ,11) +                                                            -- 30
dbo.cadena_zeros(fi_clase_garan_2     ,2 ) +                                                            -- 31
dbo.cadena_zeros(fi_valor_garan_2     ,11) +                                                            -- 32
dbo.cadena_zeros(fi_clase_garan_3     ,2 ) +                                                            -- 33
dbo.cadena_zeros(fi_valor_garan_3     ,11) +                                                            -- 34
fi_genero                                  +                                                            -- 35
dbo.cadena_zeros(fi_nit_intermediario ,11) +                                                            -- 36
fi_linea                                   +                                                            -- 37
ltrim(rtrim(isnull(fi_telefono,''))) + replicate(' ',15 - len(ltrim(rtrim(isnull(fi_telefono,''))))) +  -- 38
dbo.cadena_zeros(fi_fecha_nacimiento  ,8 ) +                                                            -- 39
dbo.cadena_zeros(fi_escolaridad       ,2 ) +                                                            -- 40
dbo.cadena_zeros(fi_destino           ,2 )                                                              -- 41
from cob_cartera..ca_justifica_fina 
where fi_linea = @i_param3

----------------------------------------
--Generar Archivo Plano
----------------------------------------
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch

select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_planobancoldex out '

select @w_destino  = @w_path + 'PLANOBANCOLEX' + '.txt',
       @w_errores  = @w_path + 'PLANOBANCOLEX' + '.err'
       
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e ' + @w_errores + ' -t"" ' + '-config '+ @w_s_app + 's_app.ini'

select ' COMANDO ', @w_comando
select ' PATH '   , @w_path

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo Plano Bancoldex'
   print @w_comando
   return 1
end

                
return 0
   
go

/*
Ejecucion Prueba

exec cob_cartera..so_no_se_utiliza
     @i_param1  = '10/13/2009',
     @i_param2  = '10/31/2009',
     @i_param3  = '6001',
     @i_param4  = '7061'


*/
