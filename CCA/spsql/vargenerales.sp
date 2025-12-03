/************************************************************************/
/*   Archivo              :    vargenerales.sp                          */
/*   Stored procedure     :    sp_variables_generales                   */
/*   Base de datos        :    cob_cartera                              */
/*   Producto             :    Cartera                                  */
/*   Disenado por         :    Fabian de la Torre, Rodrigo Garces       */
/*   Fecha de escritura   :    Ene. 98                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                               PROPOSITO                              */
/*   Variables Generales de cartera                                     */
/************************************************************************/
/*                              ACTUALIZACIONES                         */
/*      FECHA               AUTOR            CAMBIO                     */
/*   29/JUN/2020  Luis Ponce      CDIG Multimoneda                      */
/************************************************************************/


use cob_cartera
go 


if exists (select 1 from sysobjects where name = 'sp_variables_generales')
   drop proc sp_variables_generales
go

create proc sp_variables_generales
   @s_ofi       smallint = null,
   @s_user              login,
   @s_term              varchar(30),
   @s_sesn              int,
   @t_trn               INT         = NULL, --LPO CDIG Cambio de Servicios a Blis   
   @i_fecha     datetime = null
                                                                                                                                                                                                                               
as
                                                                                                                                                                                                                                                            
declare 
   @w_sp_name         descripcion,
   @w_return              int,
   @w_error               int,
   @w_moneda_local    int,
   @w_est_vigente     catalogo,
   @w_est_no_vigente      catalogo,
   @w_est_vencido     catalogo,
   @w_est_cancelado   catalogo,
   @w_est_castigado       catalogo,
   @w_cod_oficina     varchar(10),
   @w_desc_oficina        descripcion,
   @w_cod_oficial     smallint,
   @w_desc_oficial        descripcion,
   @w_cod_destino     catalogo,
   @w_desc_destino        descripcion,
   @w_cod_ciudad      int,
   @w_desc_ciudad         descripcion,
   @w_num_dec             tinyint,
   @w_num_dec_om          tinyint,
   @w_est_credito         catalogo,
   @w_operacionca         int,
   @w_banco               cuenta,
   @w_clase_cartera       catalogo,
   @w_desc_clase_cartera  descripcion,
   @w_origen_fondos       catalogo,
   @w_desc_origen_fondos  descripcion,
   @w_tipo_rotativo       varchar(30),
   @w_producto            tinyint,
   @w_fecha_cotizacion    datetime,
   @w_rowcount            INT,
   @w_codusd              INT
   
                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                              
/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_variables_generales'

                                                                                                                                                                                                                                                              
/*AUMENTADO 20/10/98*/
                                                                                                                                                                                                                                                              
/*CONSULTA CODIGO DE MONEDA LOCAL */
SELECT  @w_moneda_local = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_nemonico = 'MLO'
AND pa_producto = 'ADM'
set transaction isolation level read uncommitted
                                                                                                                                                                                                              
-- Codigo de moneda LOCAL  --LPO CDIG Multimoneda
select @w_codusd = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and pa_nemonico = 'CDOLAR'


                                                                                                                                                                                                                                                              
/* NUMERO DE DECIMALES */
select @w_num_dec = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'NDE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted
                                                                                                                                                                                                                                                              
if @w_rowcount = 0
begin
   select @w_error = 708130
   goto ERROR
end   
                                                                                                                                                                                                                                                              
/* EPB NUMERO DE DECIMALES  OTRAS MONEDAS */
  select @w_num_dec_om = pa_tinyint
  from cobis..cl_parametro
  where pa_producto = 'CCA'
  and   pa_nemonico = 'NDEOM'
                                                                                                                                                                                                                                 
  select @w_rowcount = @@rowcount
  set transaction isolation level read uncommitted
                                                                                                                                                                                                                                                              
   if @w_rowcount = 0
   begin
     select @w_error = 708130
      goto ERROR
   end
                                                                                                                                                                                                                                                        
/* FIN EPB NUMERO DE DECIMALES  OTRAS MONEDAS */
if @i_fecha is null
   select @w_fecha_cotizacion = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7
else 
   select @w_fecha_cotizacion = @i_fecha
   
                                                                                                                                                                                                                                                           
select vlrmoneda,vlrfecha,vlrvalor,vrlresult
 from                                                                                                                                                                                                                                                         
(select distinct ct_moneda as vlrmoneda,ct_fecha as vlrfecha,convert(float,ct_valor) as vlrvalor,
       case
       when mo_decimales = 'N' then case
                                    when ct_moneda <> @w_moneda_local then @w_num_dec_om
                                    else 0
                                    end
                                                                                                                                                                                                                                                              
       else case
            when ct_moneda <> @w_moneda_local then @w_num_dec_om
            else @w_num_dec
            end
       end as vrlresult
                                                                                                                                                                                                                                                             
from cob_conta..cb_cotizacion, cobis..cl_moneda) as non_group_query
inner join
(select ct_moneda,max(ct_fecha) as vlr_ct_fecha
from   cob_conta..cb_cotizacion, cobis..cl_moneda
where  ct_moneda = mo_moneda
       and datediff(dd, ct_fecha,@w_fecha_cotizacion) <= 0   --xma
group by ct_moneda) as group_query
on non_group_query.vlrmoneda = group_query.ct_moneda
where (non_group_query.vlrfecha=group_query.vlr_ct_fecha)

                                                                                                                                                                                                                                                              
select @w_moneda_local, @w_codusd --LPO CDIG Multimoneda

                                                                                                                                                                                                                                                              
select fi_nombre
from   cobis..cl_filial
where  fi_filial = 1 
set transaction isolation level read uncommitted

                                                                                                                                                                                                                                                              
/* ESTADOS */
select @w_est_no_vigente = es_descripcion
from   ca_estado
where  es_codigo = 0
                                                                                                                                                                                                                                          

select @w_est_vigente = es_descripcion
from   ca_estado
where  es_codigo = 1
                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                              
select @w_est_vencido = es_descripcion
from   ca_estado
where  es_codigo = 2
                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                              
select @w_est_cancelado = es_descripcion
from   ca_estado
where  es_codigo = 3
                                                                                                                                                                                                                                                              
select @w_est_castigado = es_descripcion
from   ca_estado
where  es_codigo = 4                   

                                                                                                                                                                                                                                                              
select @w_est_credito = es_descripcion
                                                                                                                                                                                                                        
from   ca_estado
                                                                                                                                                                                                                                              
where  es_codigo = 99                   
                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
select 
                                                                                                                                                                                                                                                       
@w_est_vigente,
                                                                                                                                                                                                                                               
@w_est_no_vigente,
                                                                                                                                                                                                                                            
@w_est_vencido,
                                                                                                                                                                                                                                               
@w_est_cancelado,
                                                                                                                                                                                                                                             
@w_est_vencido,
                                                                                                                                                                                                                                               
@w_est_cancelado,
                                                                                                                                                                                                                                             
@w_est_castigado    
                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                              
  select @w_producto = pd_producto
                                                                                                                                                                                                                            
  from cobis..cl_producto
                                                                                                                                                                                                                                     
  where pd_abreviatura = 'CCA'
                                                                                                                                                                                                                                
  set transaction isolation level read uncommitted
                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              
  select convert(varchar(10),fc_fecha_cierre,101)
                                                                                                                                                                                                             
    from cobis..ba_fecha_cierre
                                                                                                                                                                                                                               
   where fc_producto = @w_producto
                                                                                                                                                                                                                            

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/* NUERO DE DIAS DE LOS TIPOS DE DIVIDENDO */
                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
select   td_tdividendo,td_factor
                                                                                                                                                                                                                              
from     ca_tdividendo
                                                                                                                                                                                                                                        
where    td_estado = 'V'
                                                                                                                                                                                                                                      
order by td_tdividendo           
                                                                                                                                                                                                                             

                                                                                                                                                                                                                                                              
/* PARAMETROS POR DEFECTO PARA CREACION DE OPERACIONES */
                                                                                                                                                                                                     
select
                                                                                                                                                                                                                                                        
@w_desc_oficina = of_nombre
                                                                                                                                                                                                                                   
from   cobis..cl_oficina
                                                                                                                                                                                                                                      
where  of_oficina = @s_ofi
                                                                                                                                                                                                                                    
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
set rowcount 1
                                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
select @w_cod_oficina = Y.codigo
                                                                                                                                                                                                                              
from cobis..cl_tabla X,
                                                                                                                                                                                                                                       
cobis..cl_catalogo Y
                                                                                                                                                                                                                                          
where X.tabla = 'cl_oficina'
                                                                                                                                                                                                                                  
and   X.codigo = Y.tabla
                                                                                                                                                                                                                                      
and  Y.codigo  = convert(varchar(255),@s_ofi)
                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select 
                                                                                                                                                                                                                                                       
@w_cod_oficial   = oc_oficial,
                                                                                                                                                                                                                                
@w_desc_oficial  = fu_nombre
                                                                                                                                                                                                                                  
from   cobis..cc_oficial,cobis..cl_funcionario
                                                                                                                                                                                                                
where  oc_funcionario = fu_funcionario
                                                                                                                                                                                                                        
order  by oc_oficial
                                                                                                                                                                                                                                          
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
set rowcount 1
                                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
select @w_cod_destino=y.codigo,@w_desc_destino=valor
                                                                                                                                                                                                          
from cobis..cl_catalogo y, cobis..cl_tabla t
                                                                                                                                                                                                                  
where t.tabla = 'cr_destino'
                                                                                                                                                                                                                                  
and y.tabla   = t.codigo
                                                                                                                                                                                                                                      
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select @w_cod_ciudad=of_ciudad,@w_desc_ciudad=ci_descripcion
                                                                                                                                                                                                  
from   cobis..cl_oficina,cobis..cl_ciudad
                                                                                                                                                                                                                     
where  of_oficina = @s_ofi
                                                                                                                                                                                                                                    
and    of_ciudad  = ci_ciudad
                                                                                                                                                                                                                                 
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
set rowcount 0
                                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/* BORRADO DE LA TABLA ca_en temporales */
                                                                                                                                                                                                                    
/*AUMENTADO CURSOR PARA BORRAR TODAS LAS OPERACIONES QUE SE HAN QUEDADO EN 
                                                                                                                                                                                   
TEMPORALES PARA ESE USUARIO Y ESE TERMINAL 20/10/98*/
                                                                                                                                                                                                         
if @i_fecha is null
                                                                                                                                                                                                                                           
begin
                                                                                                                                                                                                                                                         
   declare
                                                                                                                                                                                                                                                    
      temporales cursor
                                                                                                                                                                                                                                       
      for select  en_operacion 
                                                                                                                                                                                                                               
          from ca_en_temporales 
                                                                                                                                                                                                                              
          where en_usuario  = @s_user
                                                                                                                                                                                                                         
          and   en_terminal = @s_term
                                                                                                                                                                                                                         
      for read only
                                                                                                                                                                                                                                           
   
                                                                                                                                                                                                                                                           
   open temporales
                                                                                                                                                                                                                                            
   
                                                                                                                                                                                                                                                           
   fetch temporales into @w_operacionca
                                                                                                                                                                                                                       
   
                                                                                                                                                                                                                                                           
   if (@@fetch_status = 0)
                                                                                                                                                                                                                                    
   begin
                                                                                                                                                                                                                                                      
      while (@@fetch_status = 0 )
                                                                                                                                                                                                                             
      begin
                                                                                                                                                                                                                                                   
         select @w_banco = opt_banco
                                                                                                                                                                                                                          
         from   ca_operacion_tmp 
                                                                                                                                                                                                                             
         where  opt_operacion = @w_operacionca
                                                                                                                                                                                                                
         
                                                                                                                                                                                                                                                     
         exec sp_borrar_tmp_int
                                                                                                                                                                                                                               
         @s_user   = @s_user,
                                                                                                                                                                                                                                 
         --@s_term   = @s_term,
                                                                                                                                                                                                                               
         @s_sesn   = @s_sesn,
                                                                                                                                                                                                                                 
         @i_banco  = @w_banco
                                                                                                                                                                                                                                 
         
                                                                                                                                                                                                                                                     
         fetch temporales into @w_operacionca
                                                                                                                                                                                                                 
      end
                                                                                                                                                                                                                                                     
   end
                                                                                                                                                                                                                                                        
   
                                                                                                                                                                                                                                                           
   close temporales
                                                                                                                                                                                                                                           
   deallocate temporales
                                                                                                                                                                                                                                      
   -- HASTA AQUI AUMENTADO CURSOR 20/10/98
                                                                                                                                                                                                                    
end
                                                                                                                                                                                                                                                           

                                                                                                                                                                                                                                                              
select @w_clase_cartera = '1'
                                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
set rowcount 1
                                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              
/*DESCRIPCIONES DE CLASE DE CARTERA Y ORIGEN DE FONDOS*/
                                                                                                                                                                                                      
select @w_desc_clase_cartera = valor
                                                                                                                                                                                                                          
from cobis..cl_tabla X, cobis..cl_catalogo Y
                                                                                                                                                                                                                  
where X.tabla = 'cr_clase_cartera'
                                                                                                                                                                                                                            
and   X.codigo= Y.tabla
                                                                                                                                                                                                                                       
and   Y.codigo= @w_clase_cartera 
                                                                                                                                                                                                                             
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
select @w_origen_fondos = 'ORD'
                                                                                                                                                                                                                               

                                                                                                                                                                                                                                                              
select @w_desc_origen_fondos = valor
                                                                                                                                                                                                                          
from cobis..cl_tabla X, cobis..cl_catalogo Y
                                                                                                                                                                                                                  
where X.tabla = 'ca_fondos_propios'
                                                                                                                                                                                                                           
and   X.codigo= Y.tabla
                                                                                                                                                                                                                                       
and   Y.codigo= @w_origen_fondos 
                                                                                                                                                                                                                             
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/*TIPO DE CREDITOS ROTATIVOS*/
                                                                                                                                                                                                                                
select @w_tipo_rotativo = pa_char
                                                                                                                                                                                                                             
from cobis..cl_parametro
                                                                                                                                                                                                                                      
where pa_producto = 'CCA'
                                                                                                                                                                                                                                     
and   pa_nemonico = 'ROT'
                                                                                                                                                                                                                                     
set transaction isolation level read uncommitted
                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
/*DESPLEGAR AL FRONT-END*/
                                                                                                                                                                                                                                    
select @w_cod_oficina
                                                                                                                                                                                                                                         
select @w_desc_oficina
                                                                                                                                                                                                                                        
select @w_cod_oficial
                                                                                                                                                                                                                                         
select @w_desc_oficial
                                                                                                                                                                                                                                        
select @w_cod_destino
                                                                                                                                                                                                                                         
select @w_desc_destino
                                                                                                                                                                                                                                        
select @w_cod_ciudad
                                                                                                                                                                                                                                          
select @w_desc_ciudad
                                                                                                                                                                                                                                         
select @w_est_credito
                                                                                                                                                                                                                                         
select @w_clase_cartera
                                                                                                                                                                                                                                       
select @w_desc_clase_cartera
                                                                                                                                                                                                                                  
select @w_origen_fondos
                                                                                                                                                                                                                                       
select @w_desc_origen_fondos
                                                                                                                                                                                                                                  
select @w_tipo_rotativo
                                                                                                                                                                                                                                       
select @w_moneda_local
                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
set rowcount 0
                                                                                                                                                                                                                                                

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
return 0
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              
ERROR:
                                                                                                                                                                                                                                                        

                                                                                                                                                                                                                                                              
exec cobis..sp_cerror
                                                                                                                                                                                                                                         
@t_debug='N',         @t_file = null,
                                                                                                                                                                                                                         
@t_from =@w_sp_name,   @i_num = @w_error
                                                                                                                                                                                                                      
--@i_cuenta= ' '
                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
return @w_error                                                                                                                                                                                                                                                 

GO
