/************************************************************************/
/*      Archivo           :  repsolaprob.sp                             */
/*      Base de datos     :  cob_cartera                                */
/*      Producto          :  cartera                                    */
/*      Fecha de escritura:  NOV/20/2014                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA DE COLOMBIA S.A.".  Representantes exclusivos para      */
/*      Colombia de "COBISCORP".                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*   FECHA           AUTOR               RAZON                          */
/* 07/23/2015      D. Lozano           Version Inicial                  */
/************************************************************************/
use cob_cartera
go 

if exists (select 1 from sysobjects where name = 'sp_rep_solaprob')
   drop proc sp_rep_solaprob
go

SET ANSI_NULLS ON
go 
SET ANSI_WARNINGS ON
go

create proc sp_rep_solaprob
  
as  
declare @w_periodo  	    smallint,
        @w_empresa 	        tinyint,
        @w_pais             smallint,
		@w_dir_bancamia     varchar(64),
		@w_comando          varchar(255),
		@w_path             varchar(64),
		@w_archivo          varchar(100),
		@w_destino          varchar(255),
		@w_errores          varchar(255),
		@w_s_app            varchar(64),
		@w_error            int,
		@w_super            tinyint,
        @w_puc              tinyint,
        @w_fecha_ini        datetime,
        @w_fecha_fin        datetime,
        @w_fecha            varchar(10),
        @w_fecha_arch       varchar(10),
        @w_cmd              varchar(255),
        @w_sec  			int, 
        @w_cadena 			varchar(255),
        @w_sec1 			int, 
        @w_cliente 			int, 
        @w_sec2 			int, 
        @w_cadena2 			varchar(255), 
        @w_sec3 			int, 
        @w_cadena3 			varchar(255), 
        @w_prod 			tinyint
        
        

select @w_fecha = convert(varchar(10), getdate(), 101)

select @w_fecha_arch = substring(@w_fecha ,1,2)  + substring(@w_fecha ,4,2)  + substring(@w_fecha ,7,4)

 
select @w_path = pp_path_destino
from cobis..ba_path_pro  
where pp_producto = 7

if @@rowcount = 0 
begin
    print 'No Existe Path de Cartera'
    return 1
end

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP' 

if @@rowcount = 0 
begin
    print 'No Existe Ruta de s_app'
    return 1
end

if exists(select 1 from sysobjects where name = 'opera')
   drop table opera
    
create table opera
(sec int identity (1,1) ,
 opera varchar(24) null)
 
select distinct 'zona_c' = of_zona  
into #zonas
from cobis..cl_oficina where of_zona is not null

select 'zona1' = zona_c, 'deszona' = of_nombre 
into #deszona
from cobis..cl_oficina, #zonas
where of_oficina = zona_c

select distinct 'reg_c' = of_regional  
into #regional
from cobis..cl_oficina where of_regional  is not null

select 'reg1' = reg_c, 'desreg' = of_nombre 
into #desreg
from cobis..cl_oficina, #regional
where of_oficina = reg_c

select 'opera' 		= op_operacion,
       'banco' 		= op_banco,
       'ente'  		= op_cliente,
       'ofi'   		= op_oficina,
       'fecha' 		= op_fecha_ini,
       'linea'  	= op_toperacion,
       'monto'  	=  op_monto,
       'monto_apr' 	= op_monto_aprobado ,
       'plazo' 		= op_plazo,
       'cuota' 		= op_cuota,
       'tramite' 	= op_tramite,
       'cc'      	= en_ced_ruc, 
       'nom'     	= en_nomlar,
       'estadociv'  = p_estado_civil,
       'enofi'      = en_oficina,
       'activ'      = en_actividad,
       'fecneg'     = en_fecha_negocio,
       'tipov'      = p_tipo_vivienda,
       'fecapr'     = tr_fecha_apr,
       'sector'     = en_sector
into #operaciones
from cob_cartera..ca_operacion with (nolock), cobis..cl_ente with (nolock),  cob_credito..cr_tramite with (nolock)
where op_estado = 0
and op_cliente = en_ente
and tr_tramite = op_tramite


select 'operacion' = opera,
       'cuota' = sum(am_cuota)  
into #cuota
from cob_cartera..ca_amortizacion with (nolock) , #operaciones
where am_operacion = opera
and am_dividendo = 1
group by opera

select  'codeud'      = en_nomlar,
        'cc_codeud'   = de_ced_ruc,
        'de_cliente'  = de_cliente,
        'de_tramite'  = o.tramite
into #deudores
from cob_credito..cr_deudores d with (nolock), #operaciones o, cobis..cl_ente with (nolock)
where d.de_tramite = o.tramite
and de_rol = 'C'
and d.de_cliente = en_ente

--se toman los 14 primeros sectores y se exeptua los 2 primeros
select  top 14 'codigo_sec' = g.codigo
into #sector
  from cobis..cl_tabla f, cobis..cl_catalogo g
 where f.tabla = 'cl_sectoreco'
   and  g.tabla =  f.codigo
   and g.estado = 'V'
order by g.codigo

set rowcount 2
delete #sector

set rowcount 0

select distinct   'cc' = b.cc, 'nom' = b.nom, 'ente1' = b.ente, 
'tramite' =b.tramite,
'direcc' = (select top 1 di_descripcion  from cobis..cl_direccion with (nolock) where di_ente = b.ente and di_tipo = '011'),
'tel1' = (select top 1 (isnull(te_prefijo,' ') + isnull(te_valor, ' ')) from cobis..cl_direccion with (nolock), cobis..cl_telefono with (nolock) where di_ente = b.ente and di_ente = te_ente and di_direccion = te_direccion and di_tipo = '011' and te_tipo_telefono = 'D' ),
'tel2' = (select top 1 (isnull(te_prefijo,' ') + isnull(te_valor, ' ')) from cobis..cl_direccion with (nolock), cobis..cl_telefono with (nolock) where di_ente = b.ente and di_ente = te_ente and di_direccion = te_direccion and di_tipo = '002' and te_tipo_telefono = 'D' ),
'celular' = (select top 1 (te_prefijo + te_valor) from cobis..cl_direccion with (nolock), cobis..cl_telefono with (nolock) where di_ente = b.ente and di_ente = te_ente and te_direccion = 1 and te_tipo_telefono = 'C'),
'depto' = (select top 1 pv_descripcion from cobis..cl_ciudad, cobis..cl_provincia with (nolock) where ci_provincia = pv_provincia and ci_ciudad =  (select of_ciudad from cobis..cl_oficina where of_oficina = b.ofi) ),
'mun' =  (select  top 1 ci_descripcion from cobis..cl_ciudad where ci_ciudad = (select of_ciudad from cobis..cl_oficina with (nolock) where of_oficina = b.ofi)),
'zona' = (select of_zona from cobis..cl_oficina with (nolock) where of_oficina = b.ofi),
'desczona' = (select deszona from #deszona where zona1 = (select of_zona from cobis..cl_oficina with (nolock) where of_oficina = b.ofi)),
'ofi' = b.ofi,
'desofi' = (select of_nombre from cobis..cl_oficina with (nolock) where of_oficina = b.ofi),
'regional' = (select top 1 of_regional from cobis..cl_oficina with (nolock) where of_oficina = b.ofi),
'descreg' = (select desreg from #desreg where reg1 = (select of_regional from cobis..cl_oficina with (nolock) where of_oficina = b.ofi)),
'actividad' = (select d.valor
		from cobis..cl_tabla c with (nolock) , cobis..cl_catalogo d with (nolock)
		where c.tabla = 'cl_actividad'
		and  d.tabla =  c.codigo
		and d.estado = 'V'
		and d.codigo = b.activ),
'segmento' = (case when e.mo_mercado_objetivo = 'U' then 'URBANO' else 'RURAL' end),  
'subseg' = (case when b.sector in (select codigo_sec from #sector) then 'AGRO' else 'NO AGRO' end),
'negocio'  = (select datediff(mm,b.fecneg,getdate())),
'estado_civil' =  (select  h.valor
			from cobis..cl_tabla i with (nolock), cobis..cl_catalogo h with (nolock)
			where i.tabla = 'cl_ecivil'
			and  h.tabla =  i.codigo
			and h.estado = 'V'
			and h.codigo = b.estadociv	),
'conyuge' = (select top 1 (hi_nombre + ' '  + hi_papellido + ' ' + hi_sapellido) from cobis..cl_hijos with (nolock) where hi_ente  = b.ente and  hi_tipo = 'C'),
'doc_cony' = (select top 1 hi_documento from cobis..cl_hijos with (nolock) where hi_ente  = b.ente and  hi_tipo = 'C'),
'tel_cony' = (select top 1 hi_telefono  from cobis..cl_hijos with (nolock) where hi_ente  = b.ente and  hi_tipo = 'C'),       
'codeudor' = (select top 1 codeud from #deudores where de_tramite = b.tramite),
'cc_cod'   = (select top 1 cc_codeud from #deudores where de_tramite = b.tramite),
'direcc_cod' = (select top 1 di_descripcion from cobis..cl_direccion with (nolock), #deudores where di_ente = de_cliente and di_tipo = '011' and de_tramite = b.tramite),
'tel_cod' = (select top 1 (isnull(te_prefijo,' ') + isnull(te_valor, ' ')) from cobis..cl_direccion with (nolock), cobis..cl_telefono, #deudores where di_ente = de_cliente and te_ente = de_cliente and di_direccion = te_direccion and di_tipo = '011' and te_tipo_telefono = 'D' and de_tramite = b.tramite),
'celular_cod' = (select top 1 (isnull(te_prefijo,' ') + isnull(te_valor, ' ')) from cobis..cl_direccion with (nolock), cobis..cl_telefono with (nolock), #deudores where di_ente = de_cliente and te_ente = de_cliente  and te_tipo_telefono = 'C'  and de_tramite = b.tramite),
'tipo_viv' =  (select z.valor
			from cobis..cl_tabla x with (nolock), cobis..cl_catalogo z with (nolock)
			where x.tabla = 'cl_tipo_vivienda'
			and  z.tabla =  x.codigo
			and z.estado = 'V'
			and z.codigo = b.tipov),
'fechaini' = b.fecha,
'linea' = b.linea,
'monto' = b.monto,
'monto_apr' = b.monto_apr,
'fecha_apr' = b.fecapr,
'plazo' = b.plazo, 
'cuota' = (select isnull(cuota,0) from #cuota where operacion = b.opera)
into #datos
from  #operaciones b, cobis..cl_mercado_objetivo_cliente e with (nolock)
where mo_ente = ente

if @@error <> 0 
begin
    print 'Error insertando registros  '
    return 1
end  


update #datos
set direcc = replace(direcc,char(13),' '),
    direcc_cod = replace(direcc_cod,char(13),' ')

    
if @@error <> 0 
begin
    print 'Error actualizando registros direcc '
    return 1
end  

update #datos
set direcc = replace(direcc,char(10),' '),
    direcc_cod = replace(direcc_cod,char(10),' ') 

if @@error <> 0 
begin
    print 'Error actualizando registros direcc 2'
    return 1
end  

select
'cliente2' = ente,
'oblig' = REPLICATE(' ', 255),
'cta' = REPLICATE(' ', 100),
'cdt' = REPLICATE(' ', 100)
into #datos_2
from  #operaciones o

select
'cliente' = ente,
'cta' = dp_cuenta,
'prod'= dp_producto
into #datos_pr
from cobis..cl_det_producto p,  #operaciones o
where dp_cliente_ec = ente
and dp_estado_ser = 'V'
and dp_producto in (7,4,14)
and dp_cuenta <> o.banco
order by dp_cliente_ec, dp_producto

while 1= 1
begin
    select top 1 @w_cliente = cliente
     from   #datos_pr

    if  @@rowcount = 0
      break

   insert into opera
   select cta
     from #datos_pr
   where cliente  = @w_cliente
   and    prod = 7  

   if @@rowcount > 0
   begin
		select @w_sec  = 1
		select @w_cadena = ' '
		select @w_sec1 = isnull(max(sec),0)
		from opera
	
		while @w_sec  <= @w_sec1
		begin 
		   set rowcount 1
		    select @w_cadena = @w_cadena +  opera + ','
		    from opera
		    where sec = @w_sec
		
		    select @w_sec = @w_sec + 1
	
		end
		
	    truncate table opera
	
	    set rowcount 0
	    delete #datos_pr where cliente = @w_cliente
	    and prod = 7
	        
		update #datos_2
		set oblig = @w_cadena
		where cliente2 = @w_cliente
		
	end --rowcount
	
	truncate table opera
			
	insert into opera
	   select cta
	     from #datos_pr
	   where cliente  = @w_cliente
	   and    prod = 4  
	
	if @@rowcount > 0 
	begin
	
		select @w_sec  = 1
		select @w_cadena2 = ' '
		select @w_sec2 = isnull(max(sec),0)
		from opera
	 

	  while @w_sec  <= @w_sec2
      begin 
	   set rowcount 1
	    select @w_cadena2 = @w_cadena2 +  opera + ','
	    from opera
	    where sec = @w_sec
	
	    select @w_sec = @w_sec + 1

	  end
	
      set rowcount 0

	  update #datos_2
	  set cta = @w_cadena2
	  where cliente2 = @w_cliente
	  
	  delete #datos_pr
	   where cliente  = @w_cliente
	   and    prod = 4 
	end --sec2
	
	truncate table opera
	
	insert into opera
	   select cta
	     from #datos_pr
	   where cliente  = @w_cliente
	   and    prod = 14 
	
	if @@rowcount > 0 
	begin  
	
		select @w_sec  = 1
		select @w_cadena3 = ' '
		select @w_sec3 = isnull(max(sec),0)
		from opera

	  while @w_sec  <= @w_sec3
	  begin 
	   set rowcount 1
	    select @w_cadena3 = @w_cadena3 +  opera + ','
	    from opera
	    where sec = @w_sec
	
	    select @w_sec = @w_sec + 1
	  end
	
      set rowcount 0
      
      truncate table opera
      
	  update #datos_2
	  set cdt = @w_cadena3
	  where cliente2 = @w_cliente
	
	   delete #datos_pr
	   where cliente  = @w_cliente
	   and    prod = 14 
	end --sec3
	
end	--while


 
if exists(select 1 from sysobjects where name = 'ca_data_temp')
   drop table ca_data_temp 
   
create table ca_data_temp
(
 dt_data varchar(1000)
)

insert into ca_data_temp values('TRAMITE|CC CLIENTE |NOMBRE CLIENTE|DIRECC NEGOCIO|TELEFONO NEGOCIO|TELEFONO CASA|CELULAR|DEPTO|MUNICIPIO|OFICINA CREDITO|DESC OFICINA|ZONA|DES ZONA|REGIONAL|DES REGIONAL|ACTIVIDAD|SEGMENTO|SUB SEGMENTO|ANTIGUEDAD NEGOCIO|ESTADO CIVIL|CONYUGE|CC CONYUGE|TEL CONYUGE|NOMBRE CODEUDOR|CC CODEUDOR|TELEFONO CODEUDOR|CELULAR CODEUDOR|OBLIGACION|CUENTA|CDTS|TIPOVIV|FECHA CREA|LINEA DE CREDITO|MONTO SOLICITADO|PLAZO SOLICITADO|FECHA APROB.|MONTO APROB.|PLAZO APROB.|VALOR CUOTA')


insert into ca_data_temp 
select isnull(convert(varchar(15),tramite),'0') + '|' + cc + '|' + nom + '|' + isnull(direcc,'  ' ) + '|' + isnull(tel1,'  ') + '|' + isnull(tel2, '  ') + '|' +  isnull(celular, '  ') + '|' + isnull(depto, '  ') + '|' + isnull(mun, '  ')  + '|' +
       isnull(convert(varchar(6),ofi),'  ') + '|' + isnull(desofi,'  ') + '|' + isnull(convert(varchar(4),zona),'  ') + '|' + isnull(desczona,'  ')  + '|' + isnull(convert(varchar(4),regional),'  ') + '|' +  isnull(descreg,'  ')  + '|' + isnull(actividad,'  ') + '|' + 
       isnull(segmento, '   ') + '|' +  isnull(subseg, '  ')   + '|' +  isnull(convert(varchar(4),negocio), '  ' )  + '|' +  isnull(estado_civil,'  ')  + '|' +  isnull(conyuge, '  ')  + '|' + 
       isnull(doc_cony, '  ' )  + '|' +  isnull(tel_cony, '  ')  + '|' +  isnull(codeudor, '            ')  + '|' + isnull(cc_cod, '  ') + '|' + isnull(tel_cod, '  ') + '|' + isnull(celular_cod, '  ') + '|' + isnull(oblig,'  ') + '|'+ isnull(cta, '  ') + '|'+ isnull(cdt,'  ' ) + '|'+ 
       isnull(tipo_viv, '  ') + '|' + isnull(convert(varchar(10),fechaini, 103),' ') + '|' + isnull(linea, '  ') + '|'+  isnull(convert(varchar(20),monto),'0') + '|'+ isnull(convert(varchar(6),plazo),'') + '|' +
       isnull(convert(varchar(10),fecha_apr, 103), '  ') + '|'+ isnull(convert(varchar(20),monto_apr),'0') + '|' + isnull(convert(varchar(6),plazo),' ') + '|'+ isnull(convert(varchar(20),cuota),0)
from  #datos, #datos_2
where cliente2 = ente1

select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_data_temp out '

select 
@w_destino  = @w_path + 'APND_'+ @w_fecha_arch + '.txt',
@w_errores  = @w_path + 'APND_'+ @w_fecha_arch + '.err'

select @w_comando = @w_cmd + @w_destino + ' -b5000  -b1000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

print @w_comando

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin 
   print 'Error generando el archivo plano'
   return 1
end 

return 0
go
