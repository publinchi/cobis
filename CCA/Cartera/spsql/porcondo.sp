/************************************************************************/
/*      Archivo:                porcondo.sp                             */
/*      Stored procedure:       sp_porc_condonacion                     */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jonnatan Peña                           */
/*      Fecha de escritura:     May. 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP".                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calcula el porcentaje que se ingrese del los rubros IMO y INT   */
/*      para la condonacion de pagos por este concepto.                 */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA               AUTOR           RAZON                       */
/*      20/12/2019          Luis Ponce      Consulta Rubros a Condonar  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_porc_condonacion')
   drop proc sp_porc_condonacion
go

---Ver-9 Inc. 18447 MAr-10-2011 PAriendo de la Ver. 8

create proc sp_porc_condonacion 
   @s_user              login       = NULL,
   @i_banco             varchar(20) = NULL,  
   @i_concepto          catalogo    = NULL,
   @i_valor             smallint    = NULL,
   @i_operacion         char(1)     = NULL,
   @i_fecha_ini         datetime    = NULL,
   @i_fecha_fin         datetime    = NULL,
   @i_secuencial        int         = 0
as

declare 
   @w_sp_name           varchar(32),
   @w_error             int, 
   @w_msg               varchar(100),
   @t_trn               int,
   @w_smv               money,
   @w_operacion         int,
   @w_monto             money,
   @w_dividendo         int,
   @w_monto_porcentaje  MONEY,
   @w_tipo_cobro        CHAR(1),
   @w_est_vigente       INT,
   @w_est_vencido       INT,
   @w_est_cancelado     INT,
   @w_est_novigente     INT
   
select @w_sp_name  = 'sp_porc_condonacion' 

if @i_operacion = 'S' begin

   select    
   'RUBROS'           = ac_rubro, 
   'DESCRIPCION'      = ac_des_rubro,
   'PROCENTAJE'     = ac_procentaje
   from ca_autorizacion_condonacion
   where ac_cargo = (select fu_cargo from cobis..cl_funcionario   -- ITO 3Feb2010 Req00072
                      where fu_login = @s_user)
         
   if @@rowcount = 0  begin                        
      select                                 
      @w_error  = 2101005,                    
      @w_msg    = 'NO EXISTEN REGISTROS PARA EL USUARIO'     
      goto ERROR                             
   end                                  
             
end

--LPO TEC Opcion para consulta de rubros a Condonar
/* consulta de los rubros condonables de la operacion */
if @i_operacion = 'R' begin
   select @w_operacion = op_operacion,
          @w_tipo_cobro = op_tipo_cobro
   from   ca_operacion 
   where  op_banco = @i_banco
   

   /* ESTADOS DE CARTERA */
   exec @w_error = sp_estados_cca
   @o_est_vigente    = @w_est_vigente   out,
   @o_est_vencido    = @w_est_vencido   out,
   @o_est_cancelado  = @w_est_cancelado OUT,
   @o_est_novigente  = @w_est_novigente OUT
   
   if @w_error <> 0  GOTO ERROR
   
   CREATE TABLE #rub_condonar(
   rc_concepto         catalogo,
   rc_descripcion      descripcion,
   rc_monto_vencido    MONEY,
   rc_monto_vigente    MONEY,
   rc_monto_por_vencer MONEY,
   rc_total_rubro      MONEY
   )
   
   
   INSERT INTO #rub_condonar
   SELECT distinct am_concepto,
          co_descripcion,
          0,
          0,
          0,
          0
   from ca_amortizacion,
        ca_rubro_op,
        ca_concepto
   where  am_operacion = ro_operacion
   and    ro_operacion = @w_operacion
   and    am_concepto  = ro_concepto
   and    ro_concepto  = co_concepto

update #rub_condonar
set rc_monto_vencido = isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                        from   ca_amortizacion, ca_dividendo
                        where  di_operacion  = am_operacion
                        and    di_dividendo  = am_dividendo
                        and    di_operacion  = @w_operacion
                        and    di_estado     = @w_est_vencido
                        and    am_estado     <> @w_est_cancelado
                        and    am_concepto   = AM.am_concepto),0),

   rc_monto_vigente = /*CASE @w_tipo_cobro 
                          WHEN 'P' THEN isnull((SELECT (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                            from   ca_amortizacion, ca_dividendo
                            where  di_operacion         = am_operacion
                            and    di_dividendo         = am_dividendo
                            and    di_operacion         = @w_operacion
                            and    di_estado            = @w_est_vigente
                            and    am_estado            <> @w_est_cancelado
                            and    am_concepto   = AM.am_concepto),0)
                         
                           WHEN 'A' THEN*/ isnull((SELECT (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                            from   ca_amortizacion, ca_dividendo
                            where  di_operacion         = am_operacion
                            and    di_dividendo         = am_dividendo
                            and    di_operacion         = @w_operacion
                            and    di_estado            = @w_est_vigente
                            and    am_estado            <> @w_est_cancelado
                            and    am_concepto   = AM.am_concepto),0),
                           --END,
   rc_monto_por_vencer = isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                          from   ca_amortizacion, ca_dividendo, ca_rubro_op
                          where  di_operacion = am_operacion
                          and    di_dividendo = am_dividendo
                          and    di_operacion = @w_operacion
                          and    di_estado    = @w_est_novigente
                          and    am_estado   <> @w_est_cancelado
                          and    di_operacion = ro_operacion
                          and    am_operacion = ro_operacion
                          and    ro_concepto  = am_concepto
                          and    ro_tipo_rubro = 'C'
                          and    am_concepto   = AM.am_concepto),0)
from #rub_condonar , ca_amortizacion AM 
where AM.am_concepto = rc_concepto


update #rub_condonar
set rc_total_rubro = rc_monto_vencido + rc_monto_vigente + rc_monto_por_vencer
from #rub_condonar , ca_amortizacion AM 
where AM.am_concepto = rc_concepto
   

SELECT    
   rc_concepto         ,
   rc_descripcion      ,
   rc_monto_vigente    ,
   rc_monto_vencido    ,   
   rc_monto_por_vencer ,
   rc_total_rubro
from #rub_condonar
   

/*
    select 'RUBROS'      = am_concepto, 
           'DESCRIPCION' = co_descripcion
    from   ca_dividendo,
           ca_amortizacion,
           ca_rubro_op,
           ca_concepto
    where  am_operacion = @w_operacion
    and    di_operacion = @w_operacion
    and    ro_operacion = @w_operacion
    and    am_operacion = di_operacion
    and    am_concepto  = ro_concepto
    and    di_operacion = ro_operacion
    and    (di_estado  = 2 or di_estado = 1 )
    and    co_concepto  = am_concepto
    and    am_estado    <> 3
    and    ((am_dividendo = di_dividendo + charindex (ro_fpago, 'A') and not(co_categoria in ('S','A') and am_secuencia > 1))
    or     (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = di_dividendo))
    group by am_concepto, co_descripcion
*/

end
--LPO TEC FIN Opcion para consulta de rubros a Condonar



if @i_operacion = 'Q' begin

   select ac_procentaje   
   from   ca_autorizacion_condonacion
   where  ac_cargo = (select fu_cargo from cobis..cl_funcionario   -- ITO 3Feb2010 Req00072
                      where fu_login = @s_user)
   and ac_rubro   = @i_concepto
         
   if @@rowcount = 0  begin                        
      select                                 
      @w_error = 2101005,                    
      @w_msg   = 'RUBRO NO AUTORIZADO PARA EL ROL DEL USUARIO, SOLICITE AUTORIZACON'     
      goto ERROR                             
   end                                  
             
end

/*  CONSULTA DE CONDONACIONES   */
-- ITO 3Feb2010: Req 00072

if @i_operacion = 'C' 
begin

   create table #consolidacion   (
   secuencial    int          identity,
   fecha         varchar(10)  null,
   cliente       int          null,
   cedula        int          null,
   usuario       varchar(15)  null,
   cargo         varchar(60)  null,
   item          varchar(15)  null,
   valor         money        null,
   porcentaje    float        null,
   estado        char(3)      null
   )
   
   insert into #consolidacion
   select 
   'FECHA'       = convert(varchar(10),ab_fecha_pag,103),
   'CLIENTE'     = op_cliente,
   'CED CLIENTE' = (select en_ced_ruc from cobis..cl_ente where en_ente = op_cliente),
   'USUARIO'     = ab_usuario,
   'CARGO'       = (select valor from   cobis..cl_catalogo 
                    where  tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_cargo')
                    and    codigo in (select fu_cargo from cobis..cl_funcionario 
                                       where fu_login = ab_usuario)) ,  
   'RUBRO'        = abd_concepto,
   'VALOR'       = abd_monto_mpg,
   'PORCENTAJE'  = abd_porcentaje_con,
   'ESTADO'      = ab_estado
   from  ca_operacion, ca_abono,ca_abono_det
   where ab_secuencial_ing = abd_secuencial_ing
   and   op_banco      = @i_banco
   and   abd_operacion = op_operacion
   and   ab_operacion  = op_operacion
   and   abd_tipo      = 'CON'
   and   ab_fecha_pag between @i_fecha_ini and @i_fecha_fin

   if @@rowcount = 0  begin                        
      select                                 
      @w_error = 2101005,                    
      @w_msg   = 'NO EXISTEN REGISTROS PARA EL USUARIO'     
      goto ERROR                             
   end       

   set rowcount 25
   select 
   'FECHA'       = fecha,
   'CLIENTE'     = cliente,
   'CED CLIENTE' = cedula,
   'RUBRO'        = item,
   'VALOR'       = valor,
   'PORCENTAJE'  = porcentaje,
   'ESTADO'      = estado,
   'USUARIO'     = usuario,
   'CARGO'       = cargo
   from #consolidacion
   where secuencial > @i_secuencial
   order by secuencial

   set rowcount 0
                           
end

-- fin - ITO 3Feb2010: Req 00072



/*DATOS DE LA OPERACION*/

select 
@w_operacion = op_operacion 
from ca_operacion 
where op_banco = @i_banco

select 
@w_dividendo = max(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacion
and   di_estado    in (1,2)

if @i_concepto = 'CAP'
   select @w_monto  = isnull(sum(am_cuota + am_gracia - am_pagado), 0)
   from   ca_amortizacion
   where  am_concepto  = @i_concepto
   and    am_operacion = @w_operacion
   and    am_dividendo <= @w_dividendo 
else
   select @w_monto  = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
   from   ca_amortizacion
   where  am_concepto  = @i_concepto
   and    am_operacion = @w_operacion
   and    am_dividendo <= @w_dividendo 

select @w_monto_porcentaje = (@w_monto * isnull(@i_valor,0))/100

select @w_monto_porcentaje

return 0       
        

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null, 
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error

go



