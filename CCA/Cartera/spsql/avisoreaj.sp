/************************************************************************/
/*   Archivo:             avisoreaj.sp                                  */
/*   Stored procedure:    sp_estados                                    */
/*   Base de datos:       cob_cartera                                   */  
/*   Disenado por:        Elcira Pelaez                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                                  PROPOSITO                           */
/*   Este programa obtiene los codigos de estado definidos en el        */
/*   sistema                                                            */
/************************************************************************/  
/*                          ODIFICACIONES                               */
/*   FECHA                      AUTOR           RAZON                   */
/*   ENE-31-2007               EPB              NR-684                  */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_aviso_reaj_masivo')
   drop proc  sp_aviso_reaj_masivo 
go

create proc sp_aviso_reaj_masivo 
(@s_ssn                  int           = null,
 @s_date                 datetime      = null,
 @s_user                 login         = null,
 @s_term                 descripcion   = null,
 @s_corr                 char(1)       = null,
 @s_ssn_corr             int           = null,
 @s_ofi                  smallint      = null,
 @t_rty                  char(1)       = null,
 @t_debug                char(1)       = 'N',
 @t_file                 varchar(14)   = null,
 @t_trn                  smallint      = null,  
 @i_fecha_reaj       datetime      =  null,
 @i_operacion            char(1)       =  null,
 @i_sec_aviso             int           =  0,
 @i_asunto             varchar(255)  =  null,
 @i_parte_fin           varchar(255)  =  null,
 @i_fecha_reajuste      datetime,
 @i_toperacion         catalogo      = null,
 @i_oficina              int          = null,
 @i_generar              char(1)       = null,
 @i_deseconomico         catalogo      = null,
 @i_modo                 char(1)       = null,
 @i_operacionca          int           = null,
 @i_siguiente            int           = 0,
 @i_nombre_cliente       descripcion   = null,
 @i_direccion            varchar(254)  = null,
 @i_ciudad_destino       descripcion   = null,
 @i_banco                cuenta         = null,
 @i_nombre_director      descripcion   = null,
 @i_sec_ini              int           = 0,
 @i_sec_fin              int           = 0,
 @i_tamano_bloque        float         = 1000
 
)
as

declare
   @w_sp_name               varchar(32),
   @w_act_secuencial       int,
   @w_act_fecha_proceso    datetime,
   @w_act_usuario          login,
   @w_act_fecha_reajuste    datetime,
   @w_act_asunto           descripcion,
   @w_act_parte_cuerpo     descripcion,
   @w_act_des_economico    catalogo,
   @w_act_oficina           smallint,
   @w_act_linea             catalogo,
   @w_act_generar           char(1),
   @w_fecha_proceso        datetime,
   @w_secuencial           int,
   @w_error                  int,
   @w_secuencia            int,
   @w_operacion            int,
   @w_bloque               int,
   @w_inicio               int,
   @w_fin                  int,
   @w_bloques              int,
   @w_inicio_imp           int,
   @w_fin_imp              int


select @w_sp_name = 'sp_aviso_reaj_masivo'
       


-- Retorno de datos al front-end
if @i_operacion = 'Q'
begin

   --Retornar al front-end  FavisoReajMasivos a la grilla 'grdaviso' todos los registros de avisos 
   --de la fecha digitada en esta pantalla
   --Retornar al front-end a la grilla grdOperaciones las operaciones relacionadas a este aviso

   select 
   @w_act_secuencial       = act_secuencial,    
   @w_act_fecha_proceso    = act_fecha_proceso, 
   @w_act_usuario          = act_usuario,       
   @w_act_fecha_reajuste    = act_fecha_reajuste,
   @w_act_asunto           = act_asunto,        
   @w_act_parte_cuerpo     = act_parte_cuerpo,  
   @w_act_des_economico    = act_des_economico, 
   @w_act_oficina           = act_oficina,        
   @w_act_linea             = act_linea,          
   @w_act_generar           = act_generar
   from ca_aviso_cambio_tasas
   where act_fecha_reajuste = @i_fecha_reajuste

end


if @i_operacion = 'S'
begin
   if @i_modo = 'A'
   begin
      ---Retornar al front-end a la grilla grdOperaciones las operaciones relacionadas a este aviso

      select 
      'SECUENCIAL'     = act_secuencial,    
      'FECHA PROCESO'  = convert(varchar(10),act_fecha_proceso,101), 
      'USUARIO'        = act_usuario,       
      'FECHA REAJUSTE' = convert(varchar(10),act_fecha_reajuste,101), 
      'ASUNTO'         = act_asunto,        
      'PARTE CARTA'    = act_parte_cuerpo,  
      'DEST ECONOMICO' = act_des_economico, 
      'OFICINA'        = act_oficina,        
      'LINEA'          = act_linea,          
      'GENERAR CARTA'        = act_generar
      from ca_aviso_cambio_tasas
      where act_fecha_reajuste = @i_fecha_reajuste

      
   end


   if @i_modo = 'B'
   begin
      set rowcount 5
      select 
      'SECUENCIAL'     = act_secuencial, 
      'OPERACION'      = se_operacion,    
      'BANCO'          = se_banco, 
      'FECHA REAJUSTE' = se_fecha_reajuste,       
      'ASUNTO'         = act_asunto,        
      'PARTE CARTA'    = act_parte_cuerpo,  
      'DEST ECONOMICO' = act_des_economico, 
      'GENERAR CARTA'        = act_generar
      from ca_secasunto, ca_aviso_cambio_tasas
      where se_fecha_reajuste = @i_fecha_reajuste
      and   act_fecha_reajuste = se_fecha_reajuste 
      and   act_secuencial     = se_secuencial
      and   se_secuencial      = @i_sec_aviso
      order by se_operacion

      set rowcount 0
   end


   if @i_modo = 'C'
   begin
      set rowcount 5
      select 
      'SECUENCIAL'     = act_secuencial, 
      'OPERACION'      = se_operacion,    
      'BANCO'          = se_banco, 
      'FECHA REAJUSTE' = se_fecha_reajuste,       
      'ASUNTO'         = act_asunto,        
      'PARTE CARTA'    = act_parte_cuerpo,  
      'DEST ECONOMICO' = act_des_economico, 
      'GENERAR CARTA'        = act_generar
      from ca_secasunto, ca_aviso_cambio_tasas
      where se_fecha_reajuste = @i_fecha_reajuste
      and   act_fecha_reajuste = se_fecha_reajuste 
      and   act_secuencial     = se_secuencial
      and   se_secuencial      = @i_sec_aviso
      and   se_operacion       > @i_operacionca
      order by se_operacion

      set rowcount 0
   end
end



--Actualizacion datos del registro del aviso
if @i_operacion = 'U'
begin
   if @i_modo = '0'
   begin
      --- Actualizar la tabla de avisos con la variable enviada desde el front-end @i_generar,@i_sec_aviso
      update ca_aviso_cambio_tasas
      set act_generar      = @i_generar,      --Puede ser S/N
          act_usuario      =  @s_user
      from ca_secasunto,ca_aviso_cambio_tasas
      where  act_secuencial     = @i_sec_aviso
      and    act_secuencial     = se_secuencial
      and    act_fecha_reajuste = @i_fecha_reajuste
      and    act_generar        = 'S'   
      and    se_estado          = 'I'
   end
 

   if @i_modo = '1'
   begin
      --- Actualizar la tabla de avisos con la variable enviada desde el front-end @i_generar,@i_sec_aviso
      update ca_aviso_cambio_tasas
      set act_asunto =        @i_asunto,
          act_parte_cuerpo =  @i_parte_fin,
          act_generar      = 'S',
          act_usuario      =  @s_user
      from ca_secasunto,ca_aviso_cambio_tasas
      where  act_secuencial = @i_sec_aviso
      and    act_secuencial = se_secuencial
      and    act_fecha_reajuste =  @i_fecha_reajuste
      and    se_estado = 'I'

      select 
      'SECUENCIAL'     = act_secuencial,    
      'FECHA PROCESO'  = convert(varchar(10),act_fecha_proceso,101), 
      'USUARIO'        = act_usuario,       
      'FECHA REAJUSTE' = convert(varchar(10),act_fecha_reajuste,101), 
      'ASUNTO'         = act_asunto,        
      'PARTE CARTA'    = act_parte_cuerpo,  
      'DEST ECONOMICO' = act_des_economico, 
      'OFICINA'        = act_oficina,        
      'LINEA'          = act_linea,          
      'GENERAR CARTA'        = act_generar
      from ca_aviso_cambio_tasas
      where act_fecha_reajuste = @i_fecha_reajuste

   end
end



if @i_operacion = 'I'
begin

   --- Insertar los datos para la carta de avisos a los clientes
   select @w_fecha_proceso = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7


   select @w_secuencial  = isnull(max(se_secuencial), 0)
   from ca_secasunto
   where se_fecha_reajuste  = @i_fecha_reajuste
   and   se_estado          = 'N'

   if @w_secuencial= 0
   begin
      print 'Verifique ( Boton Avisos )  si ya se ingreso el Registro'
      select @w_error = 710566
      goto ERROR
   end


   insert into  ca_aviso_cambio_tasas
   (
   act_secuencial,   act_fecha_proceso,      act_usuario,
   act_fecha_reajuste,   act_asunto,         act_parte_cuerpo,
   act_des_economico,   act_oficina,         act_linea,    
   act_generar                            
   )
   values
   (
   @w_secuencial,   @w_fecha_proceso,      @s_user,
   @i_fecha_reajuste,   @i_asunto,         @i_parte_fin,
   @i_deseconomico,   @i_oficina,         @i_toperacion,
   'S'
   )
   if @@error <> 0 
   begin
      select @w_error =   708189
      goto ERROR
   end

   update ca_secasunto
   set se_estado = 'I' 
   where se_fecha_reajuste  = @i_fecha_reajuste
   and   se_estado          = 'N'

end


if @i_operacion = 'C'
begin
   
   if @i_modo = '0'
   begin

      set rowcount 20
      
       select ca_secuencial,
              ca_nombre,
              ca_direccion,
              ca_ciudad,   
              ca_asunto,   
              ca_cuerpo,      
              ca_banco,       
              ca_nombre_direc,
              ci_descripcion
      from ca_carta,cobis..cl_oficina,
            cobis..cl_ciudad
       where ca_fecha   = @i_fecha_reajuste
         and ca_oficina = @s_ofi
         and ca_oficina = of_oficina
         and ci_ciudad = of_ciudad    
         and ca_secuencial > @i_siguiente  
         and ca_secuencial between @i_sec_ini  and @i_sec_fin

       
       set rowcount 0
   end --modo 0
   
  --VAlidacion de la existencia de las cartas y
  --Particion de los bloques
  
  if @i_modo = '1'
  begin

    delete ca_impresion_carta
    where impc_oficina = @s_ofi
    
   select @w_fin     = count(1),
          @w_bloques = convert(float,round(count(1)/@i_tamano_bloque,0)) 
    from ca_carta
   where ca_fecha = @i_fecha_reajuste
   and   ca_oficina = @s_ofi
   
   if @w_fin  = 0
    begin
       select @w_error =  710574
       goto ERROR
    end
   
   
    
    if @w_fin < @i_tamano_bloque
     begin
      
       select @i_tamano_bloque = @w_fin

       select  @w_bloques = convert(float,round(count(1)/@i_tamano_bloque,0)) 
       from ca_carta
       where ca_fecha = @i_fecha_reajuste
       and   ca_oficina = @s_ofi
         
     end  
       
       
    select @w_bloque = 1

    while @w_bloque <= @w_bloques
    begin

      select @w_inicio_imp = (@w_bloque-1) * @i_tamano_bloque + 1
      select @w_fin_imp = (@w_bloque) * @i_tamano_bloque 
      
      
       insert into ca_impresion_carta
      (
      impc_fecha,            impc_oficina,          impc_nro_cartas,       impc_nro_bloques,
      impc_bloque,           impc_ini,                impc_fin,                impc_user 
      
      )
      values
      (
      getdate(),             @s_ofi,              @w_fin,         @w_bloques,
      @w_bloque,             @w_inicio_imp,       @w_fin_imp,      @s_user
      )
      
      select @w_bloque = @w_bloque + 1
   end --while
   
   select 
      'Oficina'                 =  impc_oficina,    
      'Total Cartas'            =  impc_nro_cartas, 
      'Nro BLoques'             =  impc_nro_bloques,
      'Nro Bloque de Impresion' =  impc_bloque,     
      'Carta Ini'               =  impc_ini,          
      'Carta Fin'               =  impc_fin   
   from  ca_impresion_carta        
   where impc_oficina = @s_ofi      
   
     
  end    --modo 1
  
end


--SE EJECUTA DESDE BATCH  PARA INSERTAR DATOS CARTA


if @i_modo = 'I'
begin

   select  @w_secuencia  = isnull(max(ca_secuencial),0)
   from ca_carta
   where ca_fecha   = @i_fecha_reajuste
   and   ca_oficina = @s_ofi

   select @w_secuencia = @w_secuencia +1 
   
   if exists (select 1 from ca_transaccion
   where tr_banco = @i_banco
   and   tr_tran = 'REJ'
   and   tr_fecha_ref = @i_fecha_reajuste)
   begin
      
      insert into ca_carta
      values (@w_secuencia,        @i_fecha_reajuste,   @i_nombre_cliente,   
              @i_direccion,        @i_ciudad_destino,   @i_asunto,      
              @i_parte_fin,        @i_banco,           @i_nombre_director,     
              @i_oficina
             )
   end

end

                         
                         
return 0    

ERROR:

   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error

   return @w_error
go
             
                         
go                       
                         
                         
                         
                         
