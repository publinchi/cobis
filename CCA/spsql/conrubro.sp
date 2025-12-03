/************************************************************************/
/*   Archivo:            		conrubro.sp                             */
/*   Stored procedure:          sp_consulta_rubro                       */
/*   Base de datos:             cob_cartera                             */
/*   Producto:                  Cartera                                 */
/*   Disenado por:              Sandra Ortiz                            */
/*   Fecha de escritura:        07/07/1994                              */
/************************************************************************/
/*            					IMPORTANTE            					*/
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*  				           PROPOSITO                                */
/*   Este programa realiza la busqueda normal y especifica de un        */
/*   rubro, asi como tambien genera ayuda de rubros.                    */
/************************************************************************/  
/*                             MODIFICACIONES                           */
/*   FECHA      AUTOR      RAZON                                        */
/*   13/May/99   XSA(CONTEXT)   Manejo de los campos Saldo de           */
/*                 operacion y Saldo por desembol-                      */
/*               sar para los rubros tipo calcu-                        */
/*               lado.                                                  */
/*                ULT:ACT:08FEB2005                                     */
/*   15/11/21 Kevin Rodríguez  Se obtiene descrip. de referencial rubro */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'tmp_rubros_cr')
   drop table tmp_rubros_cr
go

create table tmp_rubros_cr
(
concepto          varchar(10),
descripcion       varchar(64),
des_aplicar       varchar(64),
des_referencial   varchar(64),
base              float null,
signo             char(1) null,
factor            float null,
total             float null,
minimo            float null,
maximo            float null,
prioridad         tinyint,
provisiona        char(1),
tipo_valor        catalogo,
modalidad         char(1) null,
periodicidad      char(1) null,
desc_period       descripcion null,
tipo_rubro        char(1),
saldo_op          char(1) null,  
saldo_por_desem   char(1) null,  
decimales         tinyint null,  
tipo_puntos       char(1) null,  
tipo_tasa         char(1) null,
spid              int
) 
go

--alter table tmp_rubros_cr partition 100
go

if exists (select * from sysobjects where name = 'sp_consulta_rubro')
   drop proc sp_consulta_rubro
go

create proc sp_consulta_rubro (
   @s_date         datetime = null,
   @i_operacion    char (1),
   @i_tipo         char (1) = null,
   @i_toperacion   catalogo = null,
   @i_moneda       tinyint  = null,
   @i_concepto     catalogo = ' ',
   @i_transaccion  smallint = null,
   @i_banco        cuenta   = null,
   @i_tipo_rubro   char(1)  = null,
   @i_modo         int      = 0
        
)
as
declare
@w_sp_name                descripcion,
   @w_concepto            catalogo,
   @w_valor               float,
   @w_descripcion1        descripcion,
   @w_descripcion2        descripcion,
   @w_descripcion3        descripcion,
   @w_descripcion4        descripcion,
   @w_descripcion5        descripcion,
   @w_desc_t_rubro        varchar(10),
   @w_desc_v_calculo      descripcion,
   @w_tperiodo            catalogo,
   @w_referencial         catalogo,
   @w_reajuste            catalogo,
   @w_paga_mora           char(1),
   @w_prioridad           tinyint,
   @w_fpago               char(1),
   @w_tipo_rubro          char(1),
   @w_provisiona          char(1),
   @w_crear_siempre       char(1),
   @w_periodo             smallint,
   @w_signo_default       char(1),
   @w_valor_default       float,
   @w_signo_maximo        char(1),
   @w_valor_maximo        float,
   @w_signo_minimo        char(1),
   @w_valor_minimo        float,
   @w_valor_referencial   float,
   @w_total_default       float, 
   @w_total_maximo        float,
   @w_total_minimo        float,
   @w_tipo_valor          varchar(16),
   @w_monto_calculo       money,
   @w_estado              char(1),
   @w_estado_op           tinyint,
   @w_fecha_ult_proc      datetime,
   @w_fecha_ini           datetime,
   /**  VARIABLES PARA MANEJO DE DECIMALES **/
   @w_sector                   catalogo,
   @w_error                    int,
   @w_modalidad                char(1),
   @w_periodicidad             char(1),
   @w_desc_period              descripcion,
   @w_saldo_operacion          char(1),  
   @w_saldo_por_desem          char(1),  
   @w_num_dec_tapl             tinyint,   
   @w_operacionca              int,
   @w_tipo_puntos              char(1),
   @w_tipo_tasa                char(1),
   @w_iva_siempre              char(1),
   @w_porcentaje_cobrar        float,
   @w_base_calculo             char(1),
   @w_desc_tipo	               varchar(50),
   @w_desc_forma_pago	       varchar(50),
   @w_fecha                    datetime,
   @w_ref_int                  catalogo,
   @w_rubro_int                catalogo,
   @w_desc_reajuste            descripcion,
   @w_desc_referencial_reaj    descripcion,
   @w_valor_reaj			   float,
   @w_total_reaj			   float,
   @w_signo_reaj			   char(1),
   @w_signo_maximo_reaj 	   char(1),
   @w_signo_minimo_reaj		   char(1),
   @w_referencial_reaj		   catalogo,
   @w_total_maximo_reaj        float,
   @w_total_minimo_reaj        float,
   @w_valor_maximo_reaj		   float,
   @w_valor_minimo_reaj        float,
   @w_valor_referencial_reaj   float,
   @w_ru_limite                char(1),
   @w_ru_financiado            char(1)


select @w_sp_name = 'sp_consulta_rubro'

delete tmp_rubros_cr where spid = @@spid


    -- TASA REFERENCIAL ASOCIADA AL INT CORRIENTE
    select @w_ref_int  = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'REFINT'

	  -- RUBRO INTERES CORRIENTE
    select @w_rubro_int = pa_char
    from   cobis..cl_parametro
    where  pa_producto  = 'CCA'
    and    pa_nemonico  = 'INT'

if @i_operacion = 'H' begin
   select
   @w_fecha_ult_proc = opt_fecha_ult_proceso,
   @w_fecha_ini      = opt_fecha_ini,
   @w_sector         = opt_sector,
   @w_estado_op      = opt_estado
   from ca_operacion_tmp
   where opt_banco   = @i_banco

   

   /*SI LA OPERACION ES NO VIGENTE TOMA LA ULTIMA TASA CASO CONTRARIO TOMA
     LA TASA MENOR O IGUAL A LA DE LA FECHA DE ULTIMO PROCESO DE LA OP.*/

   if @w_estado_op = 0 
      select @w_fecha_ult_proc = @w_fecha_ini

   if @i_tipo = 'A'
   begin          
      declare
         registro cursor
         for select ru_concepto,  co_descripcion, ru_referencial,
                    ru_prioridad, ru_provisiona,  ru_tipo_rubro,
                    ru_saldo_op,  ru_saldo_por_desem  
             from ca_rubro, ca_concepto
             where ru_toperacion = @i_toperacion
             and ru_moneda = @i_moneda 
             and ru_estado = 'V'
             and co_concepto= ru_concepto
             and (ru_tipo_rubro = @i_tipo_rubro or @i_tipo_rubro is null)
             -- LA CONDICION ANTERIOR PARA DESEMBOLSOS PARCIALES
             order by ru_toperacion, ru_moneda, ru_concepto
         for read only
      
      open registro
      
      fetch registro
      into  @w_concepto,   @w_descripcion1, @w_tipo_valor,
            @w_prioridad, @w_provisiona, @w_tipo_rubro,
            @w_saldo_operacion, @w_saldo_por_desem
      
      while (@@fetch_status = 0 )
      begin

         if (@@fetch_status = -1)
          begin
              close registro
              deallocate registro
              select @w_error = 703006
              goto ERROR
          end


         select
         @w_descripcion2      = null,
         @w_referencial       = null,
         @w_signo_default     = null,
         @w_valor_default     = null,
         @w_signo_maximo      = null,
         @w_valor_maximo      = null,
         @w_signo_minimo      = null,
         @w_valor_minimo      = null,
         @w_descripcion3      = null,
         @w_valor_referencial = null, 
         @w_total_default     = null,
         @w_total_minimo      = null,
         @w_total_maximo      = null,
         @w_num_dec_tapl      = null,
         @w_tipo_puntos       = null,
         @w_tipo_tasa         = null
         
         if @w_tipo_valor is not null begin
            select
            @w_descripcion2  = va_descripcion,
            @w_referencial   = vd_referencia,
            @w_signo_default = vd_signo_default,
            @w_valor_default = vd_valor_default,
            @w_signo_maximo  = vd_signo_maximo,
            @w_valor_maximo  = vd_valor_maximo,
            @w_signo_minimo  = vd_signo_minimo,
            @w_valor_minimo  = vd_valor_minimo,
            @w_num_dec_tapl  = vd_num_dec,
            @w_tipo_puntos   = vd_tipo_puntos
            from ca_valor,ca_valor_det
            where va_tipo = @w_tipo_valor
            and vd_tipo = @w_tipo_valor
            and vd_sector = @w_sector

            select
            @w_descripcion3 =  tv_descripcion,
            @w_modalidad    =  tv_modalidad,
            @w_periodicidad =  tv_periodicidad,
            @w_estado       =  tv_estado,
            @w_tipo_tasa    =  tv_tipo_tasa
            from ca_tasa_valor
            where tv_nombre_tasa = @w_referencial


            /*SOLO TASAS VIGENTES: SI @w_estado ES NULO SON VALORES A APLICAR
              TIPO VALOR(V)*/
            if @w_estado is not null and @w_estado <> 'V' 
               break
   
            select @w_desc_period = td_descripcion
            from ca_tdividendo
            where td_tdividendo  = @w_periodicidad   
   
          
            select @w_fecha = max(vr_fecha_vig)
            from ca_valor_referencial
            where vr_tipo     = @w_referencial
            and vr_fecha_vig <= @w_fecha_ult_proc


            select @w_valor_referencial = vr_valor 
            from ca_valor_referencial z   
            where vr_tipo       = @w_referencial
            and vr_secuencial = (select max(vr_secuencial)
                            from ca_valor_referencial
                     where vr_tipo     = @w_referencial--z.vr_tipo
                                 and vr_fecha_vig  = @w_fecha)
   
            exec sp_calcula_valor @i_signo = @w_signo_default,
            @i_base      = @w_valor_referencial,
            @i_factor    = @w_valor_default,
            @o_resultado = @w_total_default out

            exec sp_calcula_valor @i_signo = @w_signo_maximo,
            @i_base      = @w_valor_referencial,
            @i_factor    = @w_valor_maximo,
            @o_resultado = @w_total_maximo out
   
            exec sp_calcula_valor @i_signo = @w_signo_minimo,
            @i_base      = @w_valor_referencial,
            @i_factor    = @w_valor_minimo,
            @o_resultado = @w_total_minimo out
         end

         insert into tmp_rubros_cr
               (concepto,       descripcion,      des_aplicar,
                des_referencial,base,             signo,
                factor,         total,            minimo,
                maximo,         prioridad,        provisiona,
                tipo_valor,     modalidad,        periodicidad,
                desc_period,    tipo_rubro,
                saldo_op,       saldo_por_desem,  decimales,
                tipo_puntos,    tipo_tasa,        spid)
         values(@w_concepto,        @w_descripcion1,     isnull(@w_descripcion2,''),
                isnull(@w_descripcion3,''), @w_valor_referencial, @w_signo_default,
                @w_valor_default,           @w_total_default,     @w_total_minimo,
                @w_total_maximo,            @w_prioridad,         @w_provisiona,
                @w_tipo_valor,              @w_modalidad,         @w_periodicidad,
                @w_desc_period,             @w_tipo_rubro,
                @w_saldo_operacion,        @w_saldo_por_desem,   @w_num_dec_tapl,
                @w_tipo_puntos,           @w_tipo_tasa,           @@spid)
         
         fetch registro
         into  @w_concepto, @w_descripcion1, @w_tipo_valor,
               @w_prioridad, @w_provisiona,  @w_tipo_rubro,
               @w_saldo_operacion, @w_saldo_por_desem      
      end

      close registro
      deallocate registro
 

      select 
      'Rubro' = rtrim(ltrim(concepto)), 
      descripcion, 
      des_aplicar,
      des_referencial, 
      base,        signo,
      'Valor/Puntos' = factor,
      total,       minimo,
      maximo,
      convert(int,prioridad), 
      provisiona,
      rtrim(ltrim(tipo_valor)), 
      '',
      maximo,
      tipo_rubro,      
      modalidad, 
      periodicidad,
      @w_tipo_rubro,
      desc_period, 
      saldo_op,   
      saldo_por_desem, decimales,
      'Tipo Puntos' = tipo_puntos,
      'Tipo Tasa' = tipo_tasa
      from  tmp_rubros_cr
      where concepto > @i_concepto
      and   spid = @@spid
      order by concepto
   end
   
   /* si solamente se requiere hacer un query */
   if @i_tipo = 'V'  begin
       select @w_concepto      = ru_concepto,
              @w_descripcion1  = convert(varchar(30),co_descripcion),
              @w_paga_mora     = ru_paga_mora,
              @w_prioridad     = ru_prioridad,
              @w_fpago         = ru_fpago,
              @w_tipo_rubro    = ru_tipo_rubro,
              @w_provisiona    = ru_provisiona,
              @w_crear_siempre = ru_crear_siempre,
              @w_tperiodo      = ru_tperiodo,
              @w_periodo       = ru_periodo,
              @w_tipo_valor    = ru_referencial,
			  @w_base_calculo  = '',
			  @w_desc_tipo	   = C.valor,
			  @w_desc_forma_pago = '',
			  @w_reajuste    	 = ru_reajuste,
			  @w_ru_limite       = ru_limite,
			  @w_ru_financiado   = ru_financiado
        from cob_cartera..ca_rubro, cob_cartera..ca_concepto,
         	  cobis..cl_catalogo C,
			 cobis..cl_tabla D
        where ru_concepto   = @i_concepto
          and co_concepto   = ru_concepto
          and ru_toperacion = @i_toperacion
          and ru_moneda     = @i_moneda
          and ru_estado     = 'V'
		  and D.tabla = 'fp_tipo_rubro'
      	  and C.tabla = D.codigo
		  and ru_tipo_rubro = C.codigo
		  
		  

      /* si no se encuentra, error */
      if @@rowcount = 0  begin
         select @w_error = 701003
         goto ERROR
      end

     if @w_tipo_valor IS NOT NULL
         begin
           select @w_descripcion2 = va_descripcion,
                  @w_referencial  = vd_referencia,
                  @w_signo_default= vd_signo_default,
                  @w_valor_default = vd_valor_default,
                  @w_signo_maximo = vd_signo_maximo,
                  @w_valor_maximo = vd_valor_maximo,
                  @w_signo_minimo = vd_signo_minimo,
                  @w_valor_minimo = vd_valor_minimo
           from   cob_cartera..ca_valor, cob_cartera..ca_valor_det
           where  va_tipo     = @w_tipo_valor
           and    vd_tipo     = @w_tipo_valor
           and    vd_sector   = @w_sector
          -- and   (vd_seg_cre = @w_seg_cre  or vd_seg_cre is null)
          -- order  by vd_seg_cre     --Toma la segunda asignacion o null
          	
			SELECT @w_descripcion3 = tv_descripcion 
			FROM ca_tasa_valor 
			WHERE tv_nombre_tasa = @w_referencial
			and   tv_estado       = 'V'

           -- SI TIENE TASA ASOCIADA AL INTERES OBTENGO EL VALOR DEL INTERES CORRIENTE ACTUAL
           if @w_referencial = @w_ref_int 
           begin
              select @w_valor_referencial = rot_porcentaje
              from   cob_cartera..ca_rubro_op_tmp
              where  rot_operacion = @w_operacionca
              and    rot_concepto  = @w_rubro_int

              if @@rowcount = 0 
              begin
                 select @w_valor_referencial = ro_porcentaje
                 from   cob_cartera..ca_rubro_op
                 where  ro_operacion = @w_operacionca
                 and    ro_concepto  = @w_rubro_int
              end
           end
           else
           begin
              select @w_valor_referencial = vr_valor
                    -- @w_vr_maximo         = vr_maximo
              from   cob_cartera..ca_valor_referencial z    
              where  vr_tipo       = @w_referencial
              and    vr_secuencial = (select max(vr_secuencial)
                                      from   cob_cartera..ca_valor_referencial
                                      where  vr_tipo = z.vr_tipo
                                      and    vr_fecha_vig <= @w_fecha_ini)
           end

           exec cob_cartera..sp_calcula_valor 
                @i_signo     = @w_signo_default,
                @i_base      = @w_valor_referencial,
                @i_factor    = @w_valor_default,
                @o_resultado = @w_total_default out

           exec cob_cartera..sp_calcula_valor 
                @i_signo     = @w_signo_maximo,
                @i_base      = @w_valor_referencial,
                @i_factor    = @w_valor_maximo,
                @o_resultado = @w_total_maximo out

           exec cob_cartera..sp_calcula_valor 
                @i_signo     = @w_signo_minimo,
                @i_base      = @w_valor_referencial,
                @i_factor    = @w_valor_minimo,
                @o_resultado = @w_total_minimo out
         end
                	 
		 if @w_reajuste IS not NULL
         begin
		 		
           select @w_desc_reajuste = va_descripcion,
                  @w_referencial_reaj  = vd_referencia,
                  @w_signo_reaj= vd_signo_default,
                  @w_valor_reaj = vd_valor_default,
                  @w_signo_maximo_reaj = vd_signo_maximo,
                  @w_valor_maximo_reaj = vd_valor_maximo,
                  @w_signo_minimo_reaj = vd_signo_minimo,
                  @w_valor_minimo_reaj = vd_valor_minimo
           from   cob_cartera..ca_valor, cob_cartera..ca_valor_det
           where  va_tipo     = @w_reajuste
           and    vd_tipo     = @w_reajuste
           and    vd_sector   = @w_sector
          -- and   (vd_seg_cre = @w_seg_cre  or vd_seg_cre is null)
          -- order  by vd_seg_cre     --Toma la segunda asignacion o null

           select @w_desc_referencial_reaj =  valor
             from cobis..cl_tabla x, cobis..cl_catalogo y
            where x.tabla = 'ca_tvalor'
              and x.codigo = y.tabla
              and y.codigo = @w_referencial_reaj

           -- SI TIENE TASA ASOCIADA AL INTERES OBTENGO EL VALOR DEL INTERES CORRIENTE ACTUAL
           if @w_referencial_reaj = @w_ref_int 
           begin
              select @w_valor_referencial_reaj = rot_porcentaje
              from   cob_cartera..ca_rubro_op_tmp
              where  rot_operacion = @w_operacionca
              and    rot_concepto  = @w_rubro_int

              if @@rowcount = 0 
              begin
                 select @w_valor_referencial_reaj = ro_porcentaje
                 from   cob_cartera..ca_rubro_op
                 where  ro_operacion = @w_operacionca
                 and    ro_concepto  = @w_rubro_int
              end
           end
           else
           begin
              select @w_valor_referencial_reaj = vr_valor
              from   cob_cartera..ca_valor_referencial z    
              where  vr_tipo       = @w_referencial_reaj
              and    vr_secuencial = (select max(vr_secuencial)
                                      from   cob_cartera..ca_valor_referencial
                                      where  vr_tipo = z.vr_tipo
                                      and    vr_fecha_vig <= @w_fecha_ini)
           end

		   

           exec cob_cartera..sp_calcula_valor 
                @i_signo     = @w_signo_reaj,
                @i_base      = @w_valor_referencial_reaj,
                @i_factor    = @w_valor_reaj,
                @o_resultado = @w_total_reaj out

           exec cob_cartera..sp_calcula_valor 
                @i_signo     = @w_signo_maximo_reaj,
                @i_base      = @w_valor_referencial_reaj,
                @i_factor    = @w_valor_maximo_reaj,
                @o_resultado = @w_total_maximo_reaj out

           exec cob_cartera..sp_calcula_valor 
                @i_signo     = @w_signo_minimo_reaj,
                @i_base      = @w_valor_referencial,
                @i_factor    = @w_valor_minimo_reaj,
                @o_resultado = @w_total_minimo_reaj out
         end

      select rtrim(ltrim(@w_concepto)), @w_descripcion1, @w_descripcion2, --3
             @w_descripcion3, @w_valor_referencial, @w_signo_default, --6
             @w_valor_default, @w_total_default,@w_total_minimo, --9
             @w_total_maximo, @w_prioridad, @w_provisiona,rtrim(ltrim(@w_tipo_valor)), --13
             @w_tipo_rubro,   @w_valor_maximo, @w_fpago, @w_paga_mora, --17
		   @w_base_calculo, @w_desc_tipo, @w_desc_forma_pago, --20
		   @w_reajuste, @w_desc_reajuste,      --22
		   @w_referencial_reaj,  @w_desc_referencial_reaj, @w_signo_reaj, --25
		   @w_valor_reaj,        @w_signo_maximo_reaj,     @w_valor_maximo_reaj,  --28
		   @w_signo_minimo_reaj, @w_valor_minimo_reaj,     @w_valor_referencial_reaj, --31
		   @w_total_reaj,        @w_total_maximo_reaj,     @w_total_minimo_reaj, --34
           @w_ru_limite,  @w_ru_financiado

   end

   /*PARA REAJUSTES*/
   if @i_tipo = 'R' begin
      select distinct
      ru_concepto, co_descripcion 
      from ca_rubro, ca_concepto
      where (ru_concepto   = @i_concepto or @i_concepto = '-1') 
      and   ru_estado     = 'V'
      and   co_concepto   = ru_concepto
      and   ru_tipo_rubro = @i_tipo_rubro 
      and   ru_fpago      in ('P','A')
   end
end

delete tmp_rubros_cr where spid = @@spid
return 0

ERROR:
delete tmp_rubros_cr where spid = @@spid

exec cobis..sp_cerror
@t_debug  = 'N',         
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error


go
