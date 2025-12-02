/************************************************************************/
/*      Archivo              :     condporc.sp                          */
/*      Stored procedure     :     sp_condonacion_porcentaje            */
/*      Base de datos        :     cob_cartera                          */
/*      Producto             :     cartera                              */
/*      Fecha de escritura   :     Diciembre-2011                       */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'                                                     */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                          PROPOSITO                                   */
/************************************************************************/
/*                          HISTORIA                                    */
/*  FECHA                  AUTOR                                        */
/* 09042015     ACELIS    REQ 447 INCLUIR RUBROS NO VENCIDOS            */
/************************************************************************/
USE cob_cartera
GO
if exists (select 1 from sysobjects where name = 'sp_param_condonacion')
           drop proc sp_param_condonacion
go
create proc sp_param_condonacion
   @s_user                   login,
   @s_date                   datetime,
   @t_trn                    int          = 0,
   @s_sesn                   int          = 0,
   @s_term                   varchar (30) = NULL,
   @s_ssn                    int          = 0,
   @s_srv                    varchar (30) = null,
   @s_lsrv                   varchar (30) = null,
   @s_ofi                    smallint     = null,
   @i_secuencial             smallint     = null,
   @t_debug                  char(1)      = 'N',
   @t_file                   varchar(14)  = null,  
   @i_operacion              char(1)      ='S',
   @i_codigo                 int          =null,
   @i_estado                 smallint     = null,
   @i_banca                  catalogo     = null,
   @i_mora_inicial           int          = null,
   @i_mora_final             int          = null,
   @i_ano_castigo            int          = null,
   @i_rubro                  varchar(10)  = null,
   @i_porcentaje             float        = null,
   @i_valor_maximo           money        = null,
   @i_vlr_vigentes           char(1)      = null,
   @i_vlr_noven              char(1)      = null,
   @i_autorizacion           char(1)      = null,
   @i_modo                   tinyint      = null,    
   @o_consec                 int          = null out
as
declare
   @w_error                int,
   @w_sp_name              descripcion,
   @w_estado               smallint,
   @w_banca                catalogo ,
   @w_mora_inicial         int,
   @w_mora_final           int,
   @w_ano_castigo          int,
   @w_rubro                varchar(10),
   @w_porcentaje           float,
   @w_valor_maximo         money,
   @w_vlr_vigentes         char(1),
   @w_autorizacion         char(1),      
   @w_sec                  int,
   @w_clave1			   varchar(255)

--- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name        = 'sp_param_condonacion'

/*if @i_operacion = 'U'
begin
    -- (3) verificacion de cruce de rangos
    -- (3.1) limite inferior
    if @i_mora_inicial is not null and @i_mora_final is not null
    begin
    if exists (   select 1
            from ca_param_condona
            where pc_estado    = @i_estado 
            and   pc_banca   = @i_banca
            and   pc_rubro   = @i_rubro
            and   pc_mora_inicial <= @i_mora_inicial
            and   pc_mora_final > @i_mora_inicial
            and   pc_codigo <> @i_codigo)
    begin
     --Limite minimo se cruza con otra definición 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101042
        return 1 
    end


    -- (3.2) limite superior
    if exists (   select 1
            from ca_param_condona
            where pc_estado       = @i_estado
            and   pc_banca        = @i_banca
            and   pc_rubro        = @i_rubro    
            and   pc_mora_inicial <  @i_mora_final
            and   pc_mora_final   >= @i_mora_final
            and   pc_codigo <> @i_codigo)
    begin
    -- Limite maximo se cruza con otra definición 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101045
        return 1 
    end

    -- (3.3) el nuevo rango abarca a otros
    if exists (   select 1
      from ca_param_condona
      where pc_estado   = @i_estado
      and   pc_banca  = @i_banca
      and   pc_rubro  = @i_rubro        
      and   ((pc_mora_inicial > @i_mora_inicial and pc_mora_final < @i_mora_final) or  (pc_mora_final > @i_mora_inicial and pc_mora_final <= @i_mora_final))
      and   pc_codigo <> @i_codigo)
    begin
    -- Rango definido se cruza con el correspondiente a otra calificacion 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101116
        return 1 
    end
    end
    if exists (   select 1
      from ca_param_condona
      where pc_estado   = @i_estado
      and   pc_banca    = @i_banca
      and   pc_rubro    = @i_rubro        
      and   pc_ano_castigo = @i_ano_castigo
      and   @i_ano_castigo is not null)
    begin    
    -- Rango definido se cruza con el correspondiente a otra calificacion 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101116
        return 1 
    end
end*/ 

if @i_operacion = 'S' begin
     
        set rowcount 20
        if @i_codigo = 0
        begin
              select  
                    'Codigo'          = pc_codigo,  
                    'Estado'          = pc_estado,
                    'Des. Estado'     = (select top 1 es_descripcion 
                                         from cob_cartera..ca_estado
                                         where  es_codigo = p.pc_estado),              
                    'Banca'           = pc_banca,
                    'Des. Banca'      = (select top 1 b.valor 
                                         from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cl_banca_cliente'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_banca),
                    'Concepto'        = pc_rubro,
                    'Des. Concepto'   = (select top 1 b.valor 
                                         from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro), 
                    'Mora Inicial'    = pc_mora_inicial,
                    'Mora Final'      = pc_mora_final,
                    'Ano Castigo'     = isnull(pc_ano_castigo,0),
                    'Porcentaje Maximo' = pc_porcentaje_max,
                    'Valor Maximo'    = pc_valor_maximo,
                    'Valores Vigentes'= pc_valores_vigentes,
                    'Valores No Vencidos'= pc_valores_noven,
                    'Autorizacion'    = pc_control_autorizacion
              from  ca_param_condona p
              order by pc_codigo
              
              set rowcount 0
        end
        else
        begin
              select  
                    'Codigo'          = pc_codigo,  
                    'Estado'          = pc_estado,
                    'Des. Estado'     = (select top 1 es_descripcion 
                                         from cob_cartera..ca_estado
                                         where  es_codigo = p.pc_estado),              
                    'Banca'           = pc_banca,
                    'Des. Banca'      = (select top 1 b.valor 
                                         from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cl_banca_cliente'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_banca),
                    'Concepto'        = pc_rubro,
                    'Des. Concepto'   = (select top 1 b.valor 
                                         from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro), 
                    'Mora Inicial'    = pc_mora_inicial,
                    'Mora Final'      = pc_mora_final,
                    'Ano Castigo'     = isnull(pc_ano_castigo,0),
                    'Porcentaje Maximo' = pc_porcentaje_max,
                    'Valor Maximo'    = pc_valor_maximo,
                    'Valores Vigentes'= pc_valores_vigentes,
                    'Valores No Vencidos'= pc_valores_noven,
                    'Autorizacion'    = pc_control_autorizacion
              from  ca_param_condona p
              where (pc_codigo > @i_codigo)
              order by pc_codigo
              
              set rowcount 0
        end      
end

if @i_operacion = 'A'
begin
        set rowcount 20
        if @i_modo = 0
        begin
           select 
           'Codigo'      = pc_codigo,
           'Descripcion' = (select top 1 es_descripcion from cob_cartera..ca_estado
                where  es_codigo = p.pc_estado) + ' - ' + cast(pc_banca as varchar) + ' - '+
               (select top 1 b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro)+ ' - '+
                    cast(pc_mora_inicial as varchar)+' - '+
                    cast(pc_mora_final as varchar)+' - '+
                    cast(isnull(pc_ano_castigo,0) as varchar)+' - '+cast(pc_valor_maximo as varchar)
           from ca_param_condona p            
           order by pc_codigo   
           
           set rowcount 0
        end
        else
        begin
          select 
           'Codigo'      = pc_codigo,
           'Descripcion' = (select top 1 es_descripcion from cob_cartera..ca_estado
                where  es_codigo = p.pc_estado) + ' - ' + cast(pc_banca as varchar) + ' - '+
               (select top 1 b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro)+ ' - '+
                    cast(pc_mora_inicial as varchar)+' - '+
                    cast(pc_mora_final as varchar)+' - '+
                    cast(isnull(pc_ano_castigo,0) as varchar)+' - '+cast(pc_valor_maximo as varchar)
           from ca_param_condona p
           where pc_codigo > @i_codigo
           order by pc_codigo   

          set rowcount 0
        end        
end

if @i_operacion = 'I' begin 


   if @i_mora_inicial is not null and @i_mora_final is not null
   begin
          if exists(select 1 from ca_param_condona
                    where pc_estado = @i_estado and pc_banca = @i_banca and pc_rubro = @i_rubro and pc_porcentaje_max = @i_porcentaje
                    and pc_mora_inicial = @i_mora_inicial and pc_mora_final = @i_mora_final)
          begin
             select @w_error = '2101116'
             goto ERROR
          end
   end
   else
   begin
          if exists(select 1 from ca_param_condona
                    where pc_estado = @i_estado and pc_banca = @i_banca and pc_rubro = @i_rubro and pc_porcentaje_max = @i_porcentaje
                    and pc_ano_castigo = @i_ano_castigo)
          begin
             select @w_error = '2101116'
             goto ERROR
          end   
   end                  

   
   
   select @w_sec = isnull(max(pc_codigo),0)
   from ca_param_condona
   
   select @w_sec = @w_sec + 1

   insert into ca_param_condona
      (pc_codigo, pc_estado, pc_banca, pc_rubro, pc_mora_inicial, pc_mora_final, 
       pc_ano_castigo, pc_porcentaje_max, pc_valor_maximo, pc_valores_vigentes,pc_valores_noven, pc_control_autorizacion)
   values
      ( @w_sec, @i_estado, @i_banca, @i_rubro, @i_mora_inicial, @i_mora_final,
        @i_ano_castigo, @i_porcentaje, @i_valor_maximo, @i_vlr_vigentes,@i_vlr_noven, @i_autorizacion)
        
    if @@error <>0 begin
        select @w_error = '603059'
        goto ERROR
    end
    
    select @w_clave1 = convert(varchar(255),@w_sec)
   
    exec @w_error = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_param_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @i_operacion
   
    if @w_error <> 0
    begin
      goto ERROR
    end    
    
end

if @i_operacion = 'D' begin

    select @w_clave1 = convert(varchar(255),@i_codigo)
   
    exec @w_error = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_param_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @i_operacion
   
    if @w_error <> 0
    begin
      goto ERROR
    end 

    if exists(select top 1 1 from ca_rol_condona where rc_condonacion = @i_codigo)
    begin
       select @w_error = '722239'
       goto ERROR
    end   
    else
    begin
       delete  ca_param_condona
       where pc_codigo = @i_codigo
       if @@error <>0
       begin
          select @w_error = '710003'
          goto ERROR
       end
    end   
end

if @i_operacion = 'U' begin 
    
    if @i_mora_inicial is not null and @i_mora_final is not null
   begin
          if exists(select 1 from ca_param_condona
                    where pc_estado = @i_estado and pc_banca = @i_banca and pc_rubro = @i_rubro and pc_porcentaje_max = @i_porcentaje
                    and pc_mora_inicial = @i_mora_inicial and pc_mora_final = @i_mora_final and pc_codigo <> @i_codigo)
          begin
             select @w_error = '2101116'
             goto ERROR
          end
   end
   else
   begin
          if exists(select 1 from ca_param_condona
                    where pc_estado = @i_estado and pc_banca = @i_banca and pc_rubro = @i_rubro and pc_porcentaje_max = @i_porcentaje
                    and pc_ano_castigo = @i_ano_castigo and pc_codigo <> @i_codigo)
          begin
             select @w_error = '2101116'
             goto ERROR
          end   
   end      

    update ca_param_condona
    set pc_estado = @i_estado,
        pc_banca  = @i_banca,
        pc_rubro  = @i_rubro,
        pc_mora_inicial = @i_mora_inicial,
        pc_mora_final   = @i_mora_final,
        pc_ano_castigo  = @i_ano_castigo,
        pc_porcentaje_max = @i_porcentaje,
        pc_valor_maximo   = @i_valor_maximo,
        pc_valores_vigentes = @i_vlr_vigentes,
        pc_valores_noven = @i_vlr_noven,
        pc_control_autorizacion = @i_autorizacion
    where pc_codigo = @i_codigo
    
    if @@error <>0 begin
        select @w_error = '601162'
        goto ERROR
    end

    select @w_clave1 = convert(varchar(255),@i_codigo)
   
    exec @w_error = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_param_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @i_operacion
   
    if @w_error <> 0
    begin
  
      goto ERROR
    end    
    
    
end

/**** VALUE ****/
/***************/
if @i_operacion = 'V'
begin
      select pc_codigo,   
               (select top 1 es_descripcion from cob_cartera..ca_estado
                where  es_codigo = p.pc_estado) + ' - ' + cast(pc_banca as varchar) + ' - '+
               (select top 1 b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro)+ ' - '+
                    cast(pc_mora_inicial as varchar)+' - '+
                    cast(pc_mora_final as varchar)+' - '+
                    cast(isnull(pc_ano_castigo,0) as varchar)+' - '+cast(pc_valor_maximo as varchar)
        from  ca_param_condona p
        where pc_codigo = @i_codigo
        
        if @@rowcount = 0
        begin
          -- 'NO EXISTE DATO SOLICITADO '
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file        = @t_file,
          @t_from        = @w_sp_name,
          @i_num         = 2101005
          return 1
        end
end

goto FIN

ERROR:

exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error

return @w_error

FIN:

return 0
go