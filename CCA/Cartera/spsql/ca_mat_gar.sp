/************************************************************************/
/*   Archivo:             ca_mat_gar.sp                                 */
/*   Stored procedure:    sp_matriz_garantias                           */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Jose Julian Cortes                            */
/*   Fecha de escritura:  Mayo - 2011                                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Generar una Matriz de 6 ejes que almacenara garantias por tipo de  */
/*   productor y de garantia                                            */
/************************************************************************/
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA              AUTOR           CAMBIO                        */
/*     04/Feb/2020        Luis Ponce      Ajustes Migracion Core Digital*/
/*     01/Jun/2022        LGuisela Fernandez    Se comenta prints       */
/************************************************************************/

use cob_cartera
go

set ansi_warnings off
go

if object_id ('sp_matriz_garantias') is not null
begin
   drop proc sp_matriz_garantias
end
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
---NR000353 partiendo de la verion 19

CREATE proc [dbo].[sp_matriz_garantias]
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_tipo_garantia     varchar(20) = 'AUTOMATICA',
   @i_tramite           int         = null,
   @i_garantia          varchar(64) = null,
   @i_tipo_periodo      char(1)     = 'P',
   @i_porcentaje_resp   float       = null,
   @i_concepto          catalogo    = null,
   @i_plazo				tinyint     = null,
   @i_tplazo            catalogo    = null,
   @i_operacion         char(1)     = 'N',
   @i_crea_ext          char(1)     = null,
   @o_valor             float       out,
   @o_msg               varchar(255) out

  
as declare
   @w_sp_name                  varchar(32),
   @w_return                   int,
   @w_error                    int,
   @w_tipo_prod                varchar(3),
   @w_periodo_fag              tinyint,
   @w_pediodicidad             smallint,
   @w_periodo_fng              tinyint,
   @w_periodo_usaid            tinyint,
   @w_td_tdividendo            varchar(20),
   @w_SMV                      money,
   @w_monto                    money,
   @w_monto_SMV                varchar(20),
   @w_cod_gar_fag              varchar(30),
   @w_cod_gar_usaid            varchar(30),
   @w_tipo_gar_padre           varchar(64),
   @w_cod_gar_fng              varchar(30),
   
   @w_parametro_fag            varchar(30),
   @w_parametro_fag_des        varchar(30),  
   @w_parametro_fag_iva        varchar(30),
   @w_parametro_fag_iva_des    varchar(30),   
            
   @w_parametro_fng            varchar(30),
   @w_parametro_fng_des        varchar(30),  
   @w_parametro_fng_iva        varchar(30),
   @w_parametro_fng_iva_des    varchar(30),
   
   @w_parametro_fag_uni        varchar(30),
   @w_parametro_fag_iva_uni    varchar(30),   

   @w_par_usaid_per            varchar(30),
   @w_par_usaid_des            varchar(30),
   @w_par_iva_usaid            varchar(30),
   @w_par_iva_usaid_des        varchar(30),
   @w_tipo_garantia            varchar(64),
   @w_tipo                     varchar(64),
   @w_factor                   float,
   @w_plazo                    varchar(20),
   @w_previa                   varchar(20),
   @w_colaterales              varchar(20),
   @w_operacion                int,
   @w_dividendos 			   tinyint,
   @w_tplazo                   char(1),
   @w_tipo_tramite             char(1),
   @w_matriz                   catalogo,
   @w_parametro_fga_uni        varchar(30), --req343
   @w_parametro_fga_iva_uni    varchar(30), --req343
   @w_cod_gar_fga              varchar(30), --req343
   @w_monto_flt                float,
   --Req379
   @w_parametro_gar_uni        varchar(10),
   @w_parametro_gar_iva_uni    varchar(10),
   @w_cod_gar_uni              varchar(10),
   @w_parametro_gar_iva_per    varchar(10),
   @w_cod_gar_per              varchar(10),
   --REQ402
   @w_homo_id                  varchar(30),
   @w_tabla_id                 varchar(64),
   @w_cod_garantia             varchar(64),
   @w_td_factor                int


select @w_sp_name = 'sp_matriz_garantias',
       @w_operacion = 0

create table #garantias_operacion
(
w_tipo_garantia   varchar(6),
r_tipo_garantia   varchar(10),
p_porcentaje_resp float,
w_tipo            varchar(6),
estado            char(1),
w_garantia        varchar(30)
)


 create table #conceptos (
 codigo    varchar(10),
 tipo_gar  varchar(64)
 )

--- Tipo de Garantia Soportado FNG - FAG - USAID

-- Tipo Garantia Padre FNG
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

--PARAMETROS GARANTIAS DESEMBOLSO E IVA (FAG Y FNG)

-- FNG
------------------------------------

-- Concepto para llamar matriz
select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

select @w_parametro_fng_des = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COFNGD'

select @w_parametro_fng_iva = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'

select @w_parametro_fng_iva_des = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVFNGD'

-- FAG
------------------------------------

-- Tipo Garantia Padre FAG
select @w_cod_gar_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODFAG'

-- Periodo FAG
select @w_periodo_fag = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'PERFAG'
and   pa_producto = 'CCA'

select @w_parametro_fag = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGP'

select @w_parametro_fag_des = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGD'

select @w_parametro_fag_iva = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFAG'

select @w_parametro_fag_iva_des = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVFAGD'

-- UNI
------------------------------------

select @w_parametro_fag_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMUNI' 

select @w_parametro_fag_iva_uni = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'ICFAGU'


-- USAID
------------------------------------

select @w_cod_gar_usaid = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODUSA'

select @w_periodo_usaid = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'PERUSA'
and pa_producto = 'CCA'

select @w_par_usaid_per = pa_char     --Periodo
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'CMUSAP'

select @w_par_usaid_des = pa_char    -- Desembolso
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'CMUSAD'

select @w_par_iva_usaid = pa_char    -- IVA
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'ICMUSA'

select @w_par_iva_usaid_des = pa_char    -- IVA Desembolso
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'ICUSAD'

------------------------------------
-- UNI FGA req343
------------------------------------

select @w_parametro_fga_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFGA' 

select @w_parametro_fga_iva_uni = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFGA'

-- Tipo Garantia Padre FGA
select @w_cod_gar_fga = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODFGA'

---PARAMETRO SALARIO MINIMO VITAL VIGENTE
select @w_SMV      = pa_money 
from cobis..cl_parametro with (nolock)
where pa_producto  = 'ADM'
and   pa_nemonico  = 'SMV'

--- Parametro de garantias colaterales 
select @w_colaterales = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'GARESP'


----------------------------------------
-- REQ 379
----------------------------------------

select @w_parametro_gar_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMGAR'

select @w_parametro_gar_iva_uni = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAGAR'

select @w_cod_gar_uni = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODGAR'

select @w_parametro_gar_iva_per = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAGRP'

select @w_cod_gar_per = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'COMGRP'


---MONTO DEL TRAMITE 
select @w_monto = case tr_moneda when 0 then tr_monto else tr_montop end,
       @w_dividendos   = tr_plazo ,
       @w_tipo_tramite = tr_tipo
from  cob_credito..cr_tramite
where tr_tramite  = @i_tramite

--OPERACION CORRESPONDIENTE AL TRAMITE

select @w_operacion = tr_numero_op
from cob_credito..cr_tramite
where tr_tramite = @i_tramite
and   tr_tipo = 'E'

if @@rowcount  = 0
   select @w_operacion = op_operacion
   from cob_cartera..ca_operacion
   where op_tramite = @i_tramite

---SELECCIONO TIPO DE GARANTIA RECIBIDO 
if @i_garantia is not null and  @i_garantia <> '' begin


   select @w_tipo_garantia = tc_tipo_superior, 
          @w_tipo          = tc_tipo      
   from cob_custodia..cu_tipo_custodia, cob_custodia..cu_custodia
   Where  tc_tipo = cu_tipo
   and    cu_codigo_externo = @i_garantia
   and    cu_estado     in ('V','F','P')
   

end
else begin
   select tc_tipo as tipo_sub 
   into #colateral
   from cob_custodia..cu_tipo_custodia
   where tc_tipo_superior = @w_colaterales


   insert into #garantias_operacion
   select w_tipo_garantia   = tc_tipo_superior,
          r_tipo_garantia   = case gp_previa when 'P' then 'PREVIA' else 'AUTOMATICA' end,
          p_porcentaje_resp = gp_porcentaje, 
          w_tipo            = tc_tipo,
          estado            = 'I',
          w_garantia        = cu_codigo_externo    
   from cob_custodia..cu_custodia, #colateral, cob_credito..cr_gar_propuesta, cob_custodia..cu_tipo_custodia
   Where cu_tipo = tc_tipo
   and   tc_tipo_superior = tipo_sub
   and   gp_tramite  = @i_tramite
   and   gp_garantia = cu_codigo_externo
   and   cu_estado  in ('V','F','P')
end


-- BUSQUEDA DE CONCEPTOS REQ 379
  if @w_tipo is not null begin
     select @w_homo_id = valor 
     from  cobis..cl_tabla t, cobis..cl_catalogo c
     where t.tabla  = 'ca_conceptos_rubros'
     and   c.tabla  = t.codigo
     and   c.codigo = convert(bigint, @w_tipo)  

     if @w_homo_id = 'S' begin
        
        select @w_tabla_id = 'ca_conceptos_rubros_' + cast(@w_tipo as varchar)
        
        insert into #conceptos
        select 
        codigo = c.codigo, 
        tipo_gar = @w_tipo
        from cobis..cl_tabla t, cobis..cl_catalogo c
        where t.tabla  = @w_tabla_id
        and   c.tabla  = t.codigo
        
     end
  end
  else begin     
     select * 
     into #gar
     from #garantias_operacion
     
     while 1=1 
     begin
        set rowcount 1
        select @w_tipo_garantia   = w_tipo_garantia,
	           @i_tipo_garantia   = r_tipo_garantia,
		       @i_porcentaje_resp = p_porcentaje_resp, 
		       @w_tipo            = w_tipo,
		       @w_cod_garantia    = w_garantia
        from #gar
        where estado = 'I'
        
        if @@rowcount = 0 begin
           set rowcount 0
           break
        end
        set rowcount 0
        
        delete #gar
        where w_garantia = @w_cod_garantia 
        

        select @w_homo_id = valor 
        from  cobis..cl_tabla t, cobis..cl_catalogo c
        where t.tabla  = 'ca_conceptos_rubros'
	        and   c.tabla  = t.codigo
        and   c.codigo = convert(bigint, @w_tipo)  

        if @w_homo_id = 'S' begin

           select @w_tabla_id = 'ca_conceptos_rubros_' + cast(@w_tipo as varchar)

           insert into #conceptos
           select 
           codigo = c.codigo, 
           tipo_gar = @w_tipo
           from cobis..cl_tabla t, cobis..cl_catalogo c
           where t.tabla  = @w_tabla_id
           and   c.tabla  = t.codigo
                     
        end
     end 
  end

  
  
if @i_concepto is not null
   delete #garantias_operacion
   where w_tipo not in (select codigo from cob_credito..cr_corresp_sib where tabla = 'T130' and codigo_sib = @i_concepto ) 

if @i_operacion = 'S' begin
   update ca_rubro_op_tmp
   set rot_tabla = 'colateral'
   from cob_credito..cr_tramite, cob_cartera..ca_operacion_tmp
   where tr_tramite  = @i_tramite
   and   opt_tramite = tr_tramite
   and   opt_operacion = rot_operacion
   and   (rot_concepto in (@w_parametro_fag,    @w_parametro_fag_des,     @w_parametro_fag_iva, @w_parametro_fag_iva_des,  
                          @w_parametro_fng,     @w_parametro_fng_des,     @w_parametro_fng_iva, @w_parametro_fng_iva_des,
                          @w_parametro_fag_uni, @w_parametro_fag_iva_uni, @w_par_usaid_per,     @w_par_usaid_des,     
                          @w_par_iva_usaid,     @w_par_iva_usaid_des,     @w_parametro_gar_uni, @w_parametro_gar_iva_uni,
                          @w_parametro_gar_iva_per, @w_cod_gar_per )
          or rot_concepto in (select codigo from #conceptos)) --REQ402

   return 0
end

while 1 = 1 begin
	set rowcount 1
    select @w_tipo_garantia   = w_tipo_garantia,
	 	   @i_tipo_garantia   = r_tipo_garantia,
		   @i_porcentaje_resp = p_porcentaje_resp, 
		   @w_tipo            = w_tipo  
    from #garantias_operacion
    where estado = 'I'
    order by w_tipo
    if @@rowcount = 0 begin
       set rowcount 0
       break
    end
    set rowcount 0



	if @w_tipo_garantia is not null begin
	  delete ca_rubro_colateral
	  where ruc_tramite  = @i_tramite  
	  and  (ruc_tipo_gar = @w_tipo or ruc_tipo_gar is null)
	end

select @w_matriz = codigo_sib
from cob_credito..cr_corresp_sib
where tabla = 'T130'
and codigo  = @w_tipo

      
--- PROCESO GARANTIAS FNG 
if @w_tipo_garantia = @w_cod_gar_fng begin
   
    ---MONTO SALARIO MINIMO

   		declare
		@w_monto_SMV_dec    decimal (20,10)
		
		select @w_monto_flt = cast(@w_monto as float)/cast(@w_SMV as float)
		select @w_monto_SMV_dec = @w_monto_flt
   	  
   select @w_monto_SMV = convert(varchar(20),@w_monto_flt)
   
   
  --PARA AÑADIR LUEGO A LA RUBRO_OP
   insert into ca_rubro_colateral 
   values (@w_operacion, @w_parametro_fng,@i_tramite,@w_tipo)
   insert into ca_rubro_colateral 
   values (@w_operacion, @w_parametro_fng_des,@i_tramite,@w_tipo)
   insert into ca_rubro_colateral
   values (@w_operacion, @w_parametro_fng_iva,@i_tramite,@w_tipo)
   insert into ca_rubro_colateral
   values (@w_operacion, @w_parametro_fng_iva_des,@i_tramite,@w_tipo)
 /*NUEVA PARAMETRIZACION DEL CATALOGO CONCEPTOS POR TIPO DE GARANTIA CC379 */
   if exists(select 1 from #conceptos where tipo_gar = @w_tipo)
   begin

      delete ca_rubro_colateral where ruc_tramite = @i_tramite
      
      insert into ca_rubro_colateral
      select @w_operacion, codigo, @i_tramite,  @w_tipo
      from #conceptos
   end

   
   ---CALCULO PORCENTAJE VALOR SOLICTADO Y COBERTURA FNG
   if @w_tipo_tramite <> 'E' begin    
	  exec  cob_cartera..sp_retona_valor_en_smlv
	   @i_matriz         = @w_matriz,
	   @i_monto          = @w_monto,
	   @i_smv            = @w_SMV,
	   @o_MontoEnSMLV    = @w_monto_flt out
	
	   if @w_monto_flt  = -1
	      select @w_monto_flt = cast(@w_monto as float)/cast(@w_SMV as float)
      
	  select @o_valor = 0
	  if @w_monto_flt > 0
	  begin                   
	      exec @w_error  = cob_cartera..sp_matriz_valor
	      @i_matriz      = @w_matriz,      
	      @i_fecha_vig   = @s_date,  
	      @i_eje1        = @w_monto_flt,
	      @o_valor       = @o_valor out, 
	      @o_msg         = @o_msg   out 


	      
	      if @w_error <> 0 begin
	         return @w_error
	      end

      end
     
   end
end

--- PROCESO GARANTIAS FAG 
if @w_tipo_garantia = @w_cod_gar_fag begin   

   ---Tipo Periodicidad
   select @w_pediodicidad = @w_periodo_fag * 30
   
   select @w_td_tdividendo = ''
   select @w_td_tdividendo = 'PERIODICA' 
   from ca_tdividendo
   where td_factor = @w_pediodicidad     
   
   if @i_plazo is not null begin
        if @i_plazo = 1 begin              
        select @w_td_tdividendo = 'UNICA'
        select @w_plazo = @i_plazo
        end   
   end
   else begin
      select @w_plazo = @w_dividendos
   end  
   
   if @w_dividendos = 1 and @i_plazo is null          
      select @w_td_tdividendo = 'UNICA'
            
   ---Tipo de productor
   select @w_tipo_prod = tr_tipo_productor from cob_credito..cr_tramite
   where  tr_tramite = @i_tramite    
   
   ---Calcula salarios minimos
   select @w_monto_flt = @w_monto / @w_SMV  
   select @w_monto_SMV = convert(varchar(20),@w_monto_flt)
   
   if @w_td_tdividendo = 'PERIODICA' begin
      
      --ACTUALIZA LAS LINEAS DE GARANTIA
      
      insert into ca_rubro_colateral 
      values (@w_operacion, @w_parametro_fag,@i_tramite,@w_tipo)
	  insert into ca_rubro_colateral 
	  values (@w_operacion, @w_parametro_fag_des,@i_tramite,@w_tipo)
	  insert into ca_rubro_colateral
	  values (@w_operacion, @w_parametro_fag_iva,@i_tramite,@w_tipo)
	  insert into ca_rubro_colateral
	  values (@w_operacion, @w_parametro_fag_iva_des,@i_tramite,@w_tipo)     
	  /*NUEVA PARAMETRIZACION DEL CATALOGO CONCEPTOS POR TIPO DE GARANTIA CC379 */
      if exists(select 1 from #conceptos where tipo_gar = @w_tipo)
      begin
         delete ca_rubro_colateral where ruc_tramite = @i_tramite
      
         insert into ca_rubro_colateral
         select @w_operacion, codigo, @i_tramite,  @w_tipo
         from #conceptos
      end

      ---Ejecuta Matriz
      
      if @w_tipo_tramite <> 'E' begin      
      
	   exec  cob_cartera..sp_retona_valor_en_smlv
	   @i_matriz         = @w_matriz,
	   @i_monto          = @w_monto,
	   @i_smv            = @w_SMV,
	   @o_MontoEnSMLV    = @w_monto_flt out
	
	   if @w_monto_flt  = -1
	      select @w_monto_flt = cast(@w_monto as float)/cast(@w_SMV as float)

	  select @o_valor = 0
	  if @w_monto_flt > 0
	  begin 
         exec @w_error  = cob_cartera..sp_matriz_valor
         @i_matriz      = @w_matriz,      
         @i_fecha_vig   = @s_date,  
         @i_eje1        = @w_tipo_prod,
         @i_eje2        = @w_monto_flt,
         @i_eje3        = @i_tipo_garantia,
         @i_eje4        = @i_porcentaje_resp,
         @i_eje5        = @w_periodo_fag,
         @o_valor       = @o_valor out, 
         @o_msg         = @o_msg   out 
         
         if @w_error <> 0 begin
            if @i_crea_ext is null begin
            	exec cobis..sp_cerror
            	@t_debug = @t_debug,
            	@t_file  = @t_file,
            	@t_from  = @w_sp_name,
            	@i_num   = @w_error
            	return 1
            end
            else
            begin
              return @w_error
            end

         end
      end
   end
end
   
   if @w_td_tdividendo = 'UNICA' begin 
   
      ---Plazo de la obligaci=n
      if @i_plazo is null
      begin
      select @w_plazo = tr_plazo from cob_credito..cr_tramite
      where tr_tramite = @i_tramite 
      end
      
      if @i_tplazo is not null begin
        if @i_tplazo <> 'M'
		begin
           /*select @w_plazo = CAST(@w_plazo AS INT) * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @i_tplazo) / 30 --LPO Ajustes Migracion Core Digital  */
		   select @w_td_factor = td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @i_tplazo
           select @w_plazo = (CONVERT(int, @w_plazo) * @w_td_factor) / 30 --LPO Ajustes Migracion Core Digital   
		end
      end   
      else
      begin      
      select @w_tplazo  = tr_tipo_plazo
      from   cob_credito..cr_tramite
      where tr_tramite = @i_tramite 
      if @w_tplazo <> 'M'
	  begin
		   select @w_td_factor = td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @w_tplazo
           select @w_plazo = (CONVERT(int, @w_plazo) * @w_td_factor) / 30 --LPO Ajustes Migracion Core Digital   
	
         /*select @w_plazo = CAST(@w_plazo AS INT) * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @w_tplazo) / 30 --LPO Ajustes Migracion Core Digital*/
	  end
      end
        
      insert into ca_rubro_colateral 
      values (@w_operacion, @w_parametro_fag_uni,@i_tramite,@w_tipo)
	  insert into ca_rubro_colateral 
	  values (@w_operacion, @w_parametro_fag_iva_uni,@i_tramite,@w_tipo)
      /*NUEVA PARAMETRIZACION DEL CATALOGO CONCEPTOS POR TIPO DE GARANTIA CC379 */
      if exists(select 1 from #conceptos where tipo_gar = @w_tipo)
      begin
         delete ca_rubro_colateral where ruc_tramite = @i_tramite
      
         insert into ca_rubro_colateral
         select @w_operacion, codigo, @i_tramite,  @w_tipo
         from #conceptos
      end
      ---Ejecuta Matriz
      if @w_tipo_tramite <> 'E' begin 


       exec  cob_cartera..sp_retona_valor_en_smlv
	   @i_matriz         = @w_parametro_fag_uni,
	   @i_monto          = @w_monto,
	   @i_smv            = @w_SMV,
	   @o_MontoEnSMLV    = @w_monto_flt out
	
	   if @w_monto_flt  = -1
	      select @w_monto_flt = cast(@w_monto as float)/cast(@w_SMV as float)
	      
	      
	  select @o_valor = 0
	  if @w_monto_flt > 0
	  begin 
         exec @w_error  = cob_cartera..sp_matriz_valor
         @i_matriz      = @w_parametro_fag_uni,      
         @i_fecha_vig   = @s_date, 
         @i_eje1        = @w_tipo_prod,
         @i_eje2        = @w_monto_flt,
         @i_eje3        = @i_tipo_garantia,
         @i_eje4        = @i_porcentaje_resp,
         @i_eje5        = @w_plazo,
         @o_valor       = @o_valor out, 
         @o_msg         = @o_msg   out   
              
         if @w_error <> 0 begin
	    if @i_crea_ext is null begin
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file,
		@t_from  = @w_sp_name,
		@i_num   = @w_error
	        return 1
	    end
	    ELSE
            begin
                return @w_error
            end
         end  
       end 
     end   
   end
end

  
--- PROCESO GARANTIAS USAID 
if @w_tipo_garantia = @w_cod_gar_usaid begin

   ---MONTO SALARIO MINIMO
   select @w_monto_flt = @w_monto / @w_SMV  
   select @w_monto_SMV = convert(varchar(20),@w_monto_flt)

   --PARA AÑADIR LUEGO A LA RUBRO_OP
   insert into ca_rubro_colateral 
   values (@w_operacion, @w_par_usaid_per,@i_tramite,@w_tipo)
   insert into ca_rubro_colateral 
   values (@w_operacion, @w_par_usaid_des,@i_tramite,@w_tipo)
   insert into ca_rubro_colateral
   values (@w_operacion, @w_par_iva_usaid,@i_tramite,@w_tipo)
   insert into ca_rubro_colateral
   values (@w_operacion, @w_par_iva_usaid_des,@i_tramite,@w_tipo)
   /*NUEVA PARAMETRIZACION DEL CATALOGO CONCEPTOS POR TIPO DE GARANTIA CC379 */


   if exists(select 1 from #conceptos where tipo_gar = @w_tipo)
   begin
      delete ca_rubro_colateral where ruc_tramite = @i_tramite
     
      insert into ca_rubro_colateral
      select @w_operacion, codigo, @i_tramite,  @w_tipo
      from #conceptos
   end

   ---CALCULO PORCENTAJE VALOR SOLICTADO Y COBERTURA FNG
   if @w_tipo_tramite <> 'E' begin   

       exec  cob_cartera..sp_retona_valor_en_smlv
	   @i_matriz         = @w_parametro_fag_uni,
	   @i_monto          = @w_monto,
	   @i_smv            = @w_SMV,
	   @o_MontoEnSMLV    = @w_monto_flt out
	
	   if @w_monto_flt  = -1
	      select @w_monto_flt = cast(@w_monto as float)/cast(@w_SMV as float)

	  select @o_valor = 0
	  if @w_monto_flt > 0
	  begin 
	      exec @w_error  = cob_cartera..sp_matriz_valor
	      @i_matriz      = @w_matriz,      
	      @i_fecha_vig   = @s_date,  
	      @i_eje1        = @w_monto_flt,
	      @o_valor       = @o_valor out, 
	      @o_msg         = @o_msg   out 
	      
	      if @w_error <> 0 begin
	         return @w_error
	      end
	  end
   end
  
end

/* PROCESO GARANTIAS FGA */
if @w_tipo_garantia = @w_cod_gar_fga begin   
	         
	   /*Calcula salarios minimos*/
	   select @w_monto_SMV = @w_monto / @w_SMV
	     
	   insert into ca_rubro_colateral 
	   values (@w_operacion, @w_parametro_fga_uni,@i_tramite,@w_tipo)
	   insert into ca_rubro_colateral 
	   values (@w_operacion, @w_parametro_fga_iva_uni,@i_tramite,@w_tipo)
      /*NUEVA PARAMETRIZACION DEL CATALOGO CONCEPTOS POR TIPO DE GARANTIA CC379 */
       if exists(select 1 from #conceptos where tipo_gar = @w_tipo)
       begin
          delete ca_rubro_colateral where ruc_tramite = @i_tramite
      
          insert into ca_rubro_colateral
          select @w_operacion, codigo, @i_tramite,  @w_tipo
          from #conceptos
       end

	   /*Ejecuta Matriz*/
	   if @w_tipo_tramite <> 'E' begin 
		  exec @w_error  = cob_cartera..sp_matriz_valor
		  @i_matriz      = @w_matriz,      
		  @i_fecha_vig   = @s_date, 
		  @i_eje1        = @w_monto_SMV,
		  @o_valor       = @o_valor out, 
		  @o_msg         = @o_msg   out   


   		 if @w_error <> 0 begin
            exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = @w_error
            return 1
         end  
	  end   
   end

   /* PROCESO GARANTIAS FGU */
   if @w_tipo_garantia = @w_cod_gar_uni begin   
	
      /*Calcula salarios minimos*/
      select @w_monto_SMV = @w_monto / @w_SMV
	   
	         --REQ379
      insert into ca_rubro_colateral
      values (@w_operacion, @w_parametro_gar_uni, @i_tramite, @w_tipo)
      insert into ca_rubro_colateral
      values (@w_operacion, @w_parametro_gar_iva_uni, @i_tramite, @w_tipo)
      insert into ca_rubro_colateral
      values (@w_operacion, @w_cod_gar_per, @i_tramite, @w_tipo)
      insert into ca_rubro_colateral
      values (@w_operacion,@w_parametro_gar_iva_per, @i_tramite, @w_tipo)
  
      if exists(select 1 from #conceptos where tipo_gar = @w_tipo)
      begin
         delete ca_rubro_colateral where ruc_tramite = @i_tramite

         insert into ca_rubro_colateral
         select @w_operacion, codigo, @i_tramite,  @w_tipo
         from #conceptos
      end

	   /*Ejecuta Matriz*/
      if @w_tipo_tramite <> 'E' begin 
	     	      
         exec @w_error  = cob_cartera..sp_matriz_valor
              @i_matriz      = @w_matriz,      
              @i_fecha_vig   = @s_date, 
              @i_eje1        = @w_tipo,
              @i_eje2        = @w_monto_SMV,
              @o_valor       = @o_valor out, 
              @o_msg         = @o_msg   out      
	           
		  if @w_error <> 0 begin
			 exec cobis..sp_cerror
			 @t_debug = @t_debug,
			 @t_file  = @t_file,
			 @t_from  = @w_sp_name,
			 @i_num   = @w_error
			 return 1
		  end  
	   end   
	end
    update #garantias_operacion
    set estado = 'P'
    where @w_tipo_garantia   = w_tipo_garantia
	and   @i_tipo_garantia   = r_tipo_garantia
	and   @i_porcentaje_resp = p_porcentaje_resp 
	and   @w_tipo            = w_tipo  
    and   estado = 'I'

end
---QUITAR LOS RUBROS QUE NO SON VALIDOS

delete ca_rubro_colateral
where ruc_tramite = @i_tramite
and ruc_concepto in  ( select c.codigo
                       from cobis..cl_catalogo c
                       where tabla in (select t.codigo 
			           from cobis..cl_tabla t 
			           where t.tabla = 'ca_rubros_pendientes')
			          )
if @@error <> 0
begin
   --GFP se suprime print
   --PRINT 'ca_mat_gar.sp Error UPD ca_ruro_colateral'
   return 710003			          
end   
			          
delete ca_rubro_op_tmp
where rot_operacion = @w_operacion
and rot_concepto in  ( select c.codigo
                       from cobis..cl_catalogo c
                       where tabla in (select t.codigo 
			           from cobis..cl_tabla t 
			           where t.tabla = 'ca_rubros_pendientes')
			          )			      
if @@error <> 0
begin
   --GFP se suprime print
   --PRINT 'ca_mat_gar.sp Error UPD ca_rubro_op_tmp'
   return 710003			          
end 			          			              

	
return 0
go

