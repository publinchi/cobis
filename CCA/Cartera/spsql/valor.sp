/************************************************************************/
/*  Archivo:        valor.sp                                            */
/*  Stored procedure:   sp_valor                                        */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:       Credito y Cartera                                   */
/*  Disenado por:       Fabian Espinosa                                 */
/*  Fecha de escritura: 05/31/1995                                      */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*              PROPOSITO                                               */
/*  Este stored procedure maneja los valores de los rubros.             */
/*  I: Insercion de valores                                             */
/*  U: Actualizacion de valores                                         */
/*  S: Search de valores                                                */
/*  Q: Query de valores                                                 */
/*  H: Help de valores                                                  */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  05/31/1995  Fabian Espinosa Emision inicial                         */
/*  01/20/2017  DFu             Ajustes del SP para funcionamiento del  */
/*                              frontend version web                    */
/*  08/10/2021  Kevin Rodríguez Campos sin datos cuando es un rubro de  */
/*                              tipo valor.                             */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valor')
    drop proc sp_valor
go

create proc sp_valor (
@s_user               varchar(64)  = null,
@s_ofi                smallint     = null,
@s_date               datetime     = null,
@s_term               varchar(30)  = null,
@i_operacion          char(1),
@i_tipo               varchar(10)  = null,
@i_tipoh              char(1)      = null,
@i_find_pit           char(1)      = 'N',
@i_descripcion        varchar(64)  = null,
@i_tipo_puntos        char(1)      = null,
@i_num_dec            tinyint      = null,
@i_tasa_pit           char(1)      = 'N',
@i_clase              varchar(10)  = null,
@i_signo_default      char(1)      = null,
@i_valor_default      float        = null,
@i_signo_maximo       char(1)      = null,
@i_valor_maximo       float        = null,
@i_signo_minimo       char(1)      = null,
@i_valor_minimo       float        = null,
@i_referencia         varchar(10)  = null,
@i_sector             varchar(10)  = null,
@i_opcion             tinyint      = null,
@i_tipo_rubro         char(1)      = null,
@i_banco              varchar(30)  = null,
@i_rowcount           smallint     = 20,
@o_accion             char(1)      = NULL OUT
)
as

declare
@w_return             int,          
@w_sp_name            varchar(32),  
@w_error              int,   
@w_existe             tinyint,      
@w_tipo               varchar(10),
@w_descripcion        varchar(64),
@w_clase              varchar(10),
@w_pit                char(1),
@w_tipo_puntos        char(1),
@w_tipo_tasa          char(1),
@w_signo_default      char(1),
@w_valor_default      float,
@w_signo_maximo       char(1),
@w_valor_maximo       float,
@w_signo_minimo       char(1),
@w_valor_minimo       float,
@w_referencia         varchar(10),
@w_cliente            float,    
@w_valor              float,    
@v_descripcion        varchar(64),
@v_valor_default      float,
@w_des_sector         descripcion,
@w_auxerr             int,
@w_sector             catalogo,
@w_fecha              datetime,
@w_descrip            descripcion,
@w_auxclase           char(1),
@w_valor_Ref          descripcion,
@w_modalidad          char(1),
@w_periodicidad       char(1),
@w_desc_Period        descripcion,
@w_clave1             varchar(255),
@w_clave2             varchar(255),
@w_valor_aplicar      float,
@w_total_maximo       float,
@w_total_minimo       float,
@w_des_tasarefe       descripcion,
@w_desc_periodid      descripcion,
@w_valor_tasarefe     float,
@w_num_dec            tinyint,
@w_producto           tinyint,
@w_fecha_max          datetime,
@w_total_default      float,
@v_valor_maximo       float 


/* Inicializacion de variables */
select @w_sp_name = 'sp_valor'

select @w_producto = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

select @w_fecha = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = @w_producto
       
/* Chequeo de Existencias */
if @i_operacion <> 'S' and @i_operacion <> 'A' 
begin
   --@i_opcion = Null  (viene del monolitico)
   --@i_opcion = 1     (viene de la web e indica que se va a guardar la tasa - ca_valor)
   --@i_opcion = 2     (viene de la web e indica que se va a guardar valores de la tasa - ca_valor_det)
   
   if @i_opcion in (1,2)
   begin
       select 
       @w_tipo          = va_tipo,
       @w_descripcion   = va_descripcion,
       @w_clase         = va_clase
       from ca_valor
       where va_tipo = @i_tipo
   end
   
   if @i_opcion = 0 or @i_opcion is null
   begin
       if (@i_sector is null)
          select @i_sector= opt_sector from cob_cartera..ca_operacion_tmp  where opt_banco = @i_banco  
		       
       select 
       @w_tipo          = va_tipo,
       @w_descripcion   = va_descripcion,
       @w_clase         = va_clase,
       @w_signo_default = vd_signo_default,
       @w_valor_default = vd_valor_default,
       @w_signo_maximo  = vd_signo_maximo,
       @w_valor_maximo  = vd_valor_maximo,
       @w_signo_minimo  = vd_signo_minimo,
       @w_valor_minimo  = vd_valor_minimo,
       @w_referencia    = vd_referencia,
       @w_tipo_puntos   = vd_tipo_puntos,
       @w_num_dec       = vd_num_dec
       from ca_valor,ca_valor_det
       where va_tipo = @i_tipo
       and vd_tipo   = @i_tipo
       and vd_sector = @i_sector 
   end

   if @@rowcount > 0
      select @w_existe = 1
   else
      select @w_existe = 0
end
     

if @i_tipo_rubro <> 'V'      -- ('O','I','M','Q')
   select @i_tipo_rubro = 'F'

/* INSERCION DEL REGISTRO*/
if @i_operacion = 'I'
begin
   --@i_opcion = Null  (viene del monolitico)
   --@i_opcion = 1     (viene de la web e indica que se va a guardar la tasa - ca_valor)
   --@i_opcion = 2     (viene de la web e indica que se va a guardar valores de la tasa - ca_valor_det)
   
   begin tran
   
   /* TASAS */
   if @i_opcion = 1 or @i_opcion is null
   begin
       if exists (select 1 from ca_valor
                  where va_tipo = @i_tipo) 
       begin
          update ca_valor set
          va_descripcion = @i_descripcion,
          va_pit         = @i_tasa_pit
          where  va_tipo = @i_tipo
         
          if @@error <> 0 begin
             select @w_error = 705068
             goto ERROR
          end

          select @w_clase = va_clase 
          from ca_valor
          where va_tipo = @i_tipo

          if @w_clase != @i_clase and 
             exists(select 1 from ca_valor_det where
                    vd_tipo = @i_tipo) begin
              select @w_error = 705068
              goto ERROR
          END
          
          SELECT @o_accion = 'U' --Hizo Update
       end
       else begin
          insert into ca_valor
          (va_tipo, va_descripcion, va_clase,va_pit)
          values
          (@i_tipo, @i_descripcion, @i_clase,@i_tasa_pit)

          if @@error <> 0 begin
             select @w_error = 703101
             goto ERROR
          END
          SELECT @o_accion = 'I' --Hizo Insert
       end
   end 
   
   /* VALORES DE TASAS DEFINIDAS */
   if @i_opcion = 2 or @i_opcion is null
   begin
   
       if @w_clase = 'V'
          begin
             select
             @i_signo_default = null,
             @i_referencia   = null,
             @i_valor_maximo = null,
             @i_signo_maximo = null,
             @i_valor_minimo = null,
             @i_signo_minimo = null,
             @i_num_dec  = null
       end
   
       if exists (select 1 from ca_valor_det
                  where vd_tipo  = @i_tipo
                  and vd_sector  = @i_sector)
       begin
          select @w_clave1 = convert(varchar(255),@i_tipo)
          select @w_clave2 = convert(varchar(255),@i_sector)

          exec @w_return = sp_tran_servicio
          @s_user    = @s_user,
          @s_date    = @s_date,
          @s_ofi     = @s_ofi,
          @s_term    = @s_term,
          @i_tabla   = 'ca_valor_det',
          @i_clave1  = @w_clave1,
          @i_clave2  = @w_clave2

          if @w_return != 0
          begin
             select @w_error = @w_return
             goto ERROR
          end

          update ca_valor_det set 
          vd_signo_default = @i_signo_default,
          vd_valor_default = @i_valor_default, 
          vd_signo_minimo  = @i_signo_minimo,
          vd_valor_minimo  = @i_valor_minimo, 
          vd_signo_maximo  = @i_signo_maximo,
          vd_valor_maximo  = @i_valor_maximo,
          vd_referencia    = @i_referencia,
          vd_tipo_puntos   = @i_tipo_puntos,
          vd_num_dec       = @i_num_dec
          where vd_tipo = @i_tipo
          and vd_sector = @i_sector

          SELECT @o_accion = 'U' --Hizo Update
       end
       else
       begin

          insert into ca_valor_det
          (vd_tipo,         vd_sector,        vd_signo_default,
          vd_valor_default, vd_signo_maximo,  vd_valor_maximo,
          vd_signo_minimo,  vd_valor_minimo,  vd_referencia,vd_tipo_puntos,
          vd_num_dec)
          values
          (@i_tipo,         @i_sector,        @i_signo_default,
          @i_valor_default, @i_signo_maximo,  @i_valor_maximo,
          @i_signo_minimo,  @i_valor_minimo,  @i_referencia,@i_tipo_puntos,
          @i_num_dec)

          select @w_clave1 = convert(varchar(255),@i_tipo)
          select @w_clave2 = convert(varchar(255),@i_sector)

          exec @w_return = sp_tran_servicio
          @s_user        = @s_user,
          @s_date        = @s_date,
          @s_ofi         = @s_ofi,
          @s_term        = @s_term,
          @i_tabla       = 'ca_valor_det',
          @i_clave1      = @w_clave1,
          @i_clave2      = @w_clave2

          if @w_return != 0
          begin
             select @w_error = @w_return
             goto ERROR
          end
          
          SELECT @o_accion = 'I' --Hizo Insert
          
       end
   end
   if @@error <> 0 begin
      select @w_error = 703101
      goto ERROR
   end
   commit tran 
end

                
/* Consulta opcion SEARCH */
if @i_operacion = 'S' begin
   select @i_tipo= isnull(@i_tipo, ' ')

   set rowcount @i_rowcount
   if @i_opcion = 1 -- TASAS DEFINIDAS

      select 
      'Identificador'  = va_tipo,
      'Descripcion'    = substring(va_descripcion,1,50),
      'Clase'          = va_clase,
      'Tasa PIT'       = va_pit
      from ca_valor
      where va_tipo > @i_tipo
      order by va_tipo  

    else  -- VALORES TASAS DEFINIDAS
       select 
       'Identificador'     = vd_tipo,
       'Sector'            = vd_sector,
       'Sig. Defecto'      = vd_signo_default,
       'Val. Defecto'      = vd_valor_default ,  
       'Sig. Minimo'       = vd_signo_minimo,
       'Val. Minimo'       = vd_valor_minimo,
       'Sig. Maximo'       = vd_signo_maximo,
       'Val. Maximo'       = vd_valor_maximo,
       'Referencia'        = vd_referencia,
       'Tipo de Puntos'    = vd_tipo_puntos,
       'Num. de Decimales' = vd_num_dec
       from ca_valor_det 
       where vd_tipo = @i_tipo
   set rowcount 0
end

            
/* Consulta opcion QUERY */
if @i_operacion = 'Q'
begin
   if @w_existe = 1 
   begin
      select @w_des_sector =  valor
      from cobis..cl_tabla x, cobis..cl_catalogo y
      where x.tabla = 'cr_clase_cartera' ---"cl_banca_cliente"  --"cc_tipo_banca" --"cc_sector"
      and x.codigo = y.tabla
      and y.codigo = @i_sector
      set transaction isolation level read uncommitted

      if @w_referencia is not null 
      begin
         select @v_descripcion =  tv_descripcion,
                @w_tipo_tasa   =  tv_tipo_tasa
         from ca_tasa_valor
         where tv_nombre_tasa  = @w_referencia
         and   tv_estado       = 'V'

         select @w_fecha_max = max(vr_fecha_vig)
         from ca_valor_referencial
         where vr_tipo = @w_referencia  --vr_tipo
         and   vr_fecha_vig <= @w_fecha


         select @v_valor_default = vr_valor, 
         @v_valor_maximo  =null
         from ca_valor_referencial z    
         where vr_tipo = @w_referencia
         and vr_secuencial = (select max(vr_secuencial)
                              from ca_valor_referencial
                              where vr_tipo = z.vr_tipo
                              and   vr_fecha_vig = @w_fecha_max)
      end
      else
         select @v_descripcion = null,
         @v_valor_default = null

      select 
      @w_tipo,
      @w_descripcion,
      @w_clase,
      @w_referencia,
      @v_descripcion,
      @v_valor_default,
      @w_signo_default,
      @w_total_default, 
      @w_signo_minimo,
      @w_total_minimo, 
      @w_signo_maximo,
      @w_total_maximo, 
      @i_sector,
      @w_des_sector,    
      @w_valor_default, 
      @v_valor_maximo,
      null, --@w_vd_aplica_ajuste,
      null  --@w_vd_periodo_ajuste 

   end
   else 
   begin
      select @w_error = 701142
      goto ERROR
   end
end



/* Consulta opcion HELP */
select @i_tipo = isnull(@i_tipo, '')



if @i_operacion = 'H' 
begin
     
   if @i_tipoh = 'A'  /*F5 VALOR A APLICAR NEGOCIACION DE RUBROS*/
   begin 
      create table   #valores (
      codigo         varchar(10),
      descripcion    varchar(64),
      clase          varchar(10),
      tasarefe       varchar(64),
      modalidad      char(1),
      periodicidad   char(1),
      desperiodici   varchar(64),
      valortasarefe  float,
      signodefault   char(1),
      valordefault   float,
      valoraplicar   float,
      minimo         float,
      maximo         float,
      decimales      tinyint null,
      tipopuntos     char(1) null,
      tipotasa       char(1) null)

      --set rowcount @i_rowcount

      /*CURSOR PARA VALORES A APLICAR*/
      if @i_find_pit = 'N' 
      begin
         declare valor_aplicar cursor for 
         select distinct 
         va_tipo,          va_descripcion,      va_clase,
         vd_valor_default, vd_referencia,       vd_signo_default,
         vd_signo_maximo,  vd_valor_maximo,     vd_signo_minimo,
         vd_valor_minimo,  vd_num_dec,          vd_tipo_puntos
         from ca_valor,ca_valor_det
         where va_tipo        > @i_tipo
           and  va_tipo       = vd_tipo
           and  va_clase      = isnull(@i_tipo_rubro, va_clase)
           and  (va_pit       = @i_find_pit or va_pit is null)
           and  (vd_sector    = @i_sector or @i_sector is null)
         order by va_tipo
         for read only
      end
      else 
      begin
         declare valor_aplicar cursor for 
         select distinct 
         va_tipo,          va_descripcion,      va_clase,
         vd_valor_default, vd_referencia,       vd_signo_default,
         vd_signo_maximo,  vd_valor_maximo,     vd_signo_minimo,
         vd_valor_minimo,  vd_num_dec,          vd_tipo_puntos
         from ca_valor,ca_valor_det
         where va_tipo        > @i_tipo
           and  va_tipo       = vd_tipo
           and  va_clase      = @i_tipo_rubro
           and  (va_pit       = @i_find_pit)
           and  (vd_sector    = @i_sector or @i_sector is null)
         order by va_tipo
         for read only
       end

      open valor_aplicar

      fetch valor_aplicar into
      @w_tipo,           @w_descripcion,       @w_clase,
      @w_valor_default,  @w_referencia,        @w_signo_default,
      @w_signo_maximo,   @w_valor_maximo,      @w_signo_minimo,
      @w_valor_minimo,   @w_num_dec,           @w_tipo_puntos

      if (@@fetch_status = -1)
      begin
         select @w_error = 703006
         goto ERROR
      end

      while (@@fetch_status = 0)
      begin
         select
         @w_des_tasarefe  = '',
         @w_modalidad     = '',
         @w_tipo_tasa     = '',
         @w_periodicidad  = '',
         @w_desc_periodid = '',
         @w_signo_default = isnull(@w_signo_default,''),
         @w_valor_tasarefe= 0,
         @w_valor_aplicar = @w_valor_default,
         @w_total_maximo  = 0,
         @w_total_minimo  = 0

         if @w_clase = 'F'/*FACTOR TIENE ASOCIADO UNA TASA REFERENCIAL*/
         begin
            select @w_valor_tasarefe = vr_valor
            from ca_valor_referencial
            where vr_tipo      = @w_referencia
            and   vr_fecha_vig <= @w_fecha
            group by vr_tipo,vr_secuencial,vr_valor, vr_fecha_vig
            having max(vr_secuencial) = vr_secuencial

            select 
            @w_des_tasarefe  = tv_descripcion,
            @w_modalidad     = tv_modalidad,
            @w_periodicidad  = tv_periodicidad,
            @w_desc_periodid = td_descripcion,
            @w_tipo_tasa     = tv_tipo_tasa
            from ca_tasa_valor,ca_tdividendo
            where tv_nombre_tasa  = @w_referencia
            and   tv_estado       = 'V'
            and   tv_periodicidad = td_tdividendo
            and   td_estado       = 'V'

            if @@rowcount = 0 begin
               goto NEXT_TASA 
            end

            exec sp_calcula_valor 
            @i_signo  = @w_signo_default,
            @i_base      = @w_valor_tasarefe,
            @i_factor    = @w_valor_default,
            @o_resultado = @w_valor_aplicar out

            exec sp_calcula_valor 
            @i_signo     = @w_signo_maximo,
            @i_base      = @w_valor_tasarefe,
            @i_factor    = @w_valor_maximo,
            @o_resultado = @w_total_maximo out
            
            exec sp_calcula_valor 
            @i_signo     = @w_signo_minimo,
            @i_base      = @w_valor_tasarefe,
            @i_factor    = @w_valor_minimo,
            @o_resultado = @w_total_minimo out

         end

         insert into #valores values  (
         @w_tipo,
         @w_descripcion,
         @w_clase,
         @w_des_tasarefe,
         @w_modalidad,
         @w_periodicidad,
         @w_desc_periodid,
         @w_valor_tasarefe,
         @w_signo_default,
         @w_valor_default,
         @w_valor_aplicar,
         @w_total_minimo,
         @w_total_maximo,
         @w_num_dec,
         @w_tipo_puntos,
         @w_tipo_tasa)

  NEXT_TASA:
         fetch valor_aplicar into
         @w_tipo,           @w_descripcion,       @w_clase,
         @w_valor_default,  @w_referencia,        @w_signo_default,
         @w_signo_maximo,   @w_valor_maximo,      @w_signo_minimo,
         @w_valor_minimo,   @w_num_dec,           @w_tipo_puntos

      end
 
      close valor_aplicar
      deallocate valor_aplicar
 
      select * from #valores

      drop table #valores

      set rowcount 0
   end
   
   if @i_tipoh = 'V' 
   begin  /*LOSTFOCUS VALOR A APLICAR NEGOCIACION DE RUBROS*/

      select
      @w_des_tasarefe  = '',
      @w_modalidad     = '',
      @w_tipo_tasa     = '',
      @w_periodicidad  = '',
      @w_desc_periodid = '',
      @w_valor_tasarefe= 0,
      @w_total_maximo  = 0,
      @w_total_minimo  = 0

      select
      @w_tipo          = va_tipo,
      @w_descripcion   = va_descripcion,
      @w_clase         = va_clase,
      @w_pit           = va_pit,
      @w_valor_default = vd_valor_default,
      @w_referencia    = vd_referencia,
      @w_signo_default = vd_signo_default,
      @w_signo_maximo  = vd_signo_maximo,
      @w_valor_maximo  = vd_valor_maximo,
      @w_signo_minimo  = vd_signo_minimo,
      @w_valor_minimo  = vd_valor_minimo,
      @w_tipo_puntos   = vd_tipo_puntos,
      @w_num_dec       = vd_num_dec
      from ca_valor,ca_valor_det
      where va_tipo        = @i_tipo
      and   va_tipo        = vd_tipo
      and   va_clase       = @i_tipo_rubro
      and   (va_pit        = @i_find_pit or va_pit is null)
      and   (vd_sector     = @i_sector or @i_sector is null)
      order by va_tipo

      if @@rowcount = 0 begin
         select @w_error = 708153
         goto ERROR
      end

      if @w_signo_default is null select @w_signo_default = ''

      select @w_valor_aplicar = @w_valor_default

      if @w_clase = 'F'/*FACTOR TIENE ASOCIADO UNA TASA REFERENCIAL*/
      begin
         select @w_valor_tasarefe = vr_valor
         from ca_valor_referencial
         where vr_tipo      = @w_referencia
         and   vr_fecha_vig <= @w_fecha
         group by vr_tipo, vr_secuencial, vr_valor, vr_fecha_vig
         having max(vr_secuencial) = vr_secuencial
         --order by vr_secuencial asc

         select 
         @w_des_tasarefe  = tv_descripcion,
         @w_modalidad     = tv_modalidad,
         @w_periodicidad  = tv_periodicidad,
         @w_desc_periodid = td_descripcion,
         @w_tipo_tasa     = tv_tipo_tasa
         from ca_tasa_valor,ca_tdividendo
         where tv_nombre_tasa  = @w_referencia
         and   tv_estado       = 'V'
         and   tv_periodicidad = td_tdividendo
         and   td_estado       = 'V'

         if @@rowcount = 0 begin
            select @w_error = 708153
            goto ERROR
         end

         exec sp_calcula_valor 
   @i_signo     = @w_signo_default,
         @i_base      = @w_valor_tasarefe,
         @i_factor    = @w_valor_default,
         @o_resultado = @w_valor_aplicar out

         exec sp_calcula_valor 
         @i_signo     = @w_signo_maximo,
         @i_base      = @w_valor_tasarefe,
         @i_factor    = @w_valor_maximo,
         @o_resultado = @w_total_maximo out
            
         exec sp_calcula_valor 
         @i_signo     = @w_signo_minimo,
         @i_base      = @w_valor_tasarefe,
         @i_factor    = @w_valor_minimo,
         @o_resultado = @w_total_minimo out

      end

      select 
      @w_tipo,           @w_descripcion,       @w_clase,
      @w_des_tasarefe,   @w_modalidad,         @w_periodicidad,
      @w_desc_periodid,  @w_valor_tasarefe,    @w_signo_default,
      @w_valor_default,  @w_valor_aplicar,     @w_total_minimo,
      @w_total_maximo,   @w_pit,               @w_num_dec,
      @w_tipo_puntos,    @w_tipo_tasa

   end
   
   if @i_tipoh = 'P'
   begin /*F5 VALOR A APLICAR PARAMETRIZACION DE RUBROS*/

       select
       'Codigo'      =   va_tipo,
       'Descripcion' =   va_descripcion,
       'Clase'       =   va_clase
       from ca_valor 
       where  va_tipo > @i_tipo
       and    va_pit  = @i_find_pit

   end

   if @i_tipoh = 'L' begin  /*LOSTFOCUS VALORES A APLICAR PARAM. DE RUBROS*/
      select
      'Descripcion'    = va_descripcion, 
      'Valor'          = 0          --Add Valor LAMH
      from ca_valor 
      where  va_tipo   = @i_tipo
      and    va_clase  = 'F'
      and    va_pit    = @i_find_pit
      union all
      select distinct
      'Descripcion'    = va_descripcion, 
      'Valor'          = vd_valor_default   --Add Valor LAMH
      from ca_valor, ca_valor_det, ca_tasa_valor
      where  va_tipo       = @i_tipo
      and    va_clase      = 'F'
      and    va_tipo       = vd_tipo
      and    va_pit        = @i_find_pit
      and    vd_referencia = tv_nombre_tasa
      and    tv_estado     = 'V'   /*SOLO TASAS VIGENTES*/

      if @@rowcount = 0
      begin
         select @w_error = 710123
         goto ERROR
      end
   end
end



if @i_operacion = 'D' --Eliminacion de Tasas Aplicar 
begin
   if @i_opcion = 0
   begin
      select @w_clave1 = convert(varchar(255),@i_tipo)
      select @w_clave2 = convert(varchar(255),'D')

      exec @w_return = sp_tran_servicio
      @s_user    = @s_user,
      @s_date    = @s_date,
      @s_ofi     = @s_ofi,
      @s_term    = @s_term,
      @i_tabla   = 'ca_valor',
      @i_clave1  = @w_clave1,
      @i_clave2  = @w_clave2

      if @w_return != 0
      begin
         select @w_error = @w_return
         goto ERROR
      end 

      delete ca_valor where va_tipo = @i_tipo

      delete ca_valor_det where vd_tipo = @i_tipo
   end

   if @i_opcion = 1
   begin
      select @w_clave1 = convert(varchar(255),@i_tipo)
      select @w_clave2 = convert(varchar(255),'D')

      exec @w_return = sp_tran_servicio
      @s_user    = @s_user,
      @s_date    = @s_date,
      @s_ofi     = @s_ofi,
      @s_term    = @s_term,
      @i_tabla   = 'ca_valor',
      @i_clave1  = @w_clave1,
      @i_clave2  = @w_clave2

      if @w_return != 0
      begin
         select @w_error = @w_return
         goto ERROR
      end 

      delete ca_valor_det 
      where vd_tipo   = @i_tipo
      and   vd_sector = @i_sector
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

GO

