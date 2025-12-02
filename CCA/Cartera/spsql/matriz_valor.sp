/************************************************************************/
/*   Archivo:              matriz_valor.sp                              */
/*   Stored procedure:     sp_matriz_valor                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         RRB                                          */
/*   Fecha de escritura:   Febrero/2009                                 */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Consulta un valor en tablas Matriz Dimensional                     */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA        AUTOR          CAMBIO                              */
/* Nov-10-2015       Andres Diab    CCA YYY Ajuste rangos para Comision */
/*                                  Mipyme                              */
/* Jul-03/2020       Luis Ponce     CDIG Ajustes Migracion a Java       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_matriz_valor')
   drop proc sp_matriz_valor
go

create proc sp_matriz_valor
@i_matriz                catalogo,
@i_fecha_vig             smalldatetime,
@i_eje1                  varchar(20)     ,
@i_eje2                  varchar(20)     = null,
@i_eje3                  varchar(20)     = null,
@i_eje4                  varchar(20)     = null,
@i_eje5                  varchar(20)     = null,
@i_eje6                  varchar(20)     = null,
@i_eje7                  varchar(20)     = null,
@i_eje8                  varchar(20)     = null,
@i_eje9                  varchar(20)     = null,
@i_eje10                 varchar(20)     = null,
@i_eje11                 varchar(20)     = null,
@i_eje12                 varchar(20)     = null,
@i_eje13                 varchar(20)     = null,
@i_eje14                 varchar(20)     = null,
@i_eje15                 varchar(20)     = null,
@o_valor                 float               out,
@o_2valor                float           = 0 out,
@o_msg                   mensaje             out

as
declare 
@w_error             int,
@w_sp_name           descripcion,
@w_eje               varchar(20),
@w_rango             char(1),
@w_posicion          int,
@w_posicion1         int,
@w_posicion2         int,
@w_posicion3         int,
@w_posicion4         int,
@w_posicion5         int,
@w_posicion6         int,
@w_posicion7         int,
@w_posicion8         int,
@w_posicion9         int,
@w_posicion10        int,
@w_posicion11        int,
@w_posicion12        int,
@w_posicion13        int,
@w_posicion14        int,
@w_posicion15        int,
@w_tipo_dato         char(1),
@w_fecha_vig         smalldatetime,
@w_eje_f             float,
@w_eje_d             datetime,
@w_valor_default     float,
@w_cont              int,
@w_eje_max           int

select 
@w_sp_name = 'sp_matriz_valor',
@w_posicion1   = 0, 
@w_posicion2   = 0, 
@w_posicion3   = 0, 
@w_posicion4   = 0, 
@w_posicion5   = 0, 
@w_posicion6   = 0,
@w_posicion7   = 0, 
@w_posicion8   = 0, 
@w_posicion9   = 0, 
@w_posicion10  = 0, 
@w_posicion11  = 0, 
@w_posicion12  = 0,
@w_posicion13  = 0, 
@w_posicion14  = 0, 
@w_posicion15  = 0,
@w_eje_max     = 0,
@o_valor       = 0,
@o_2valor      = 0,
@o_msg         = ''

return 0


/* VALIDAR PARAMETROS DE ENTRADA */
if @i_fecha_vig is null begin
   select @o_msg = 'EL PARAMETRO FECHA ES OBLIGATORIO (sp_matriz_valor)'
   select @o_msg
   return 701188
end

/* BUSCA LA FECHA MAS CERCANA ANTES DE LA SOLICITADA */
select @w_fecha_vig = max(ma_fecha_vig)
from ca_matriz with (nolock)
where ma_matriz   = @i_matriz
and ma_fecha_vig <= @i_fecha_vig

if @w_fecha_vig is null begin
   select @o_msg = 'NO EXISTE UNA MATRIZ ' + @i_matriz + ' PARAMETRIZADA A LA FECHA ' + convert(varchar,@i_fecha_vig,103)
   select @o_msg
   return 701188
end

select @w_eje_max  = max(ej_eje)
from ca_eje
where ej_matriz     = @i_matriz
and   ej_fecha_vig <= @w_fecha_vig
if @w_eje_max > 1 and @i_eje2 is null begin
   select @o_msg = 'PARA LA MATRIZ  ' + @i_matriz + ' EL EJE DOS ES OBLIGATIRO ' +  @i_eje2
   select @o_msg
   return 701188
End 

select @w_valor_default = ma_valor_default
from ca_matriz with (nolock)
where ma_matriz    = @i_matriz
and   ma_fecha_vig = @w_fecha_vig

/* VALIDAR QUE LA MATRIZ RECIBIDA EXISTA Y ESTE PARAMETRIZADA MINIMO EN UN EJE*/
if not exists (select 1 from ca_matriz  with (nolock) where ma_matriz = @i_matriz and ma_fecha_vig = @w_fecha_vig)
or not exists (select 1 from ca_eje     with (nolock) where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig) begin
   select @o_msg = 'ERROR ENCONTRADO EN LOS DATOS DE LA MATRIZ ' + @i_matriz
   return 701188
end
   


/* BUSCAR RESULTADO */
select @w_cont = 0

while @w_cont < 16 begin

   select @w_cont = @w_cont + 1 , @w_posicion = 0

--LPO CDIG Cambio de case por if por migracion a Java INICIO
   if @w_cont = 1 
   begin
	if @i_eje1 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 1
	else
		select @w_eje = @i_eje1
   end
   
   if @w_cont = 2 
   begin
	if @i_eje2 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 2
	else
		select @w_eje = @i_eje2
   end
   
   if @w_cont = 3 
   begin
	if @i_eje3 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 3
	else
		select @w_eje = @i_eje3
   end
	
   if @w_cont = 4 
   begin
	if @i_eje4 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 4
	else
		select @w_eje = @i_eje4
   end
   
   if @w_cont = 5 
   begin
	if @i_eje5 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 5
	else
		select @w_eje = @i_eje5
   end
   
   if @w_cont = 6 
   begin
	if @i_eje6 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 6
	else
		select @w_eje = @i_eje6
   end
   
   if @w_cont = 7 
   begin
	if @i_eje7 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 7
	else
		select @w_eje = @i_eje7
   end
   
   if @w_cont = 8 
   begin
	if @i_eje8 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 8
	else
		select @w_eje = @i_eje8
   end

   if @w_cont = 9 
   begin
	if @i_eje9 is null 
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 9
	else
		select @w_eje = @i_eje9
   end

   if @w_cont = 10 
   begin
	if @i_eje10 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 10
	else
		select @w_eje = @i_eje10
   end

   if @w_cont = 11 
   begin
	if @i_eje11 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 11
	else
		select @w_eje = @i_eje11
   end

   if @w_cont = 12 
   begin
	if @i_eje12 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 12
	else
		select @w_eje = @i_eje12
   end

   if @w_cont = 13 
   begin
	if @i_eje13 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 13
	else
		select @w_eje = @i_eje13
   end
   
   if @w_cont = 14 
   begin
	if @i_eje14 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 14
	else
		select @w_eje = @i_eje14
   end

   if @w_cont = 15 
   begin
	if @i_eje15 is null
		select @w_eje = ej_valor_default from cob_cartera..ca_eje where ej_matriz = @i_matriz and ej_fecha_vig = @w_fecha_vig and ej_eje = 15
	else
		select @w_eje = @i_eje15
   end
--LPO CDIG Cambio de case por if por migracion a Java FIN


   if @w_eje is null break

   select 
   @w_rango     = ej_rango,
   @w_tipo_dato = ej_tipo_dato
   from ca_eje  with (nolock)
   where ej_matriz      = @i_matriz
   and   ej_fecha_vig   = @w_fecha_vig
   and   ej_eje         = @w_cont



   if @w_rango = 'N' begin

      select @w_posicion   = er_rango
      from  ca_eje_rango  with (nolock)
      where er_matriz      = @i_matriz
      and   er_fecha_vig   = @w_fecha_vig
      and   er_eje         = @w_cont
      and   er_rango_desde = @w_eje 

   end else 
   begin
      if @w_tipo_dato in ('I','F','M') and @i_matriz <> 'MIPYMES' begin

         select @w_eje_f = convert(float,@w_eje)

         select @w_posicion = er_rango
         from  ca_eje_rango  with (nolock)
         where er_matriz     = @i_matriz
         and   er_fecha_vig  = @w_fecha_vig
         and   er_eje        = @w_cont
         and   er_rango      = 1 -- Permite que el limite inferior del primer rango siempre sea tenido en cuenta
         and   @w_eje_f     >= convert(float,er_rango_desde) 
         and   @w_eje_f     <= convert(float,er_rango_hasta)
            
         if @@rowcount = 0 begin
             select @w_posicion = er_rango
             from  ca_eje_rango  with (nolock)
             where er_matriz     = @i_matriz
             and   er_fecha_vig  = @w_fecha_vig
             and   er_eje        = @w_cont
             and   er_rango     >  1
             and   @w_eje_f     >  convert(float,er_rango_desde) 
             and   @w_eje_f     <= convert(float,er_rango_hasta)
         end
      end
      

      if @w_tipo_dato in ('I','F','M') and @i_matriz = 'MIPYMES' begin
      /* ATENCION: POR EL TIPO DE OPERADOR REQUERIDO SOLO PUEDEN PARAMETRIZARSE DOS RANGOS PARA ESTA MATRIZ. */
            select @w_eje_f = convert(float,@w_eje)

         select @w_posicion = er_rango
         from  ca_eje_rango  with (nolock)
         where er_matriz     = @i_matriz
         and   er_fecha_vig  = @w_fecha_vig
         and   er_eje        = @w_cont
         and   er_rango      = 1 -- Permite que el limite inferior del primer rango siempre sea tenido en cuenta
         and   @w_eje_f     >= convert(float,er_rango_desde) 
         and   @w_eje_f     < convert(float,er_rango_hasta)
            
         if @@rowcount = 0 begin
             select @w_posicion = er_rango
             from  ca_eje_rango  with (nolock)
             where er_matriz     = @i_matriz
             and   er_fecha_vig  = @w_fecha_vig
             and   er_eje        = @w_cont
             and   er_rango     >  1
             and   @w_eje_f     >=  convert(float,er_rango_desde) 
             and   @w_eje_f     <= convert(float,er_rango_hasta) -- MENOR O IGUAL PARA INCLUIR LOS EXTREMOS

         end
      end


      if @w_tipo_dato in ('D') begin
 
         select @w_eje_d = convert(datetime,@w_eje)

         select @w_posicion = er_rango
         from  ca_eje_rango  with (nolock)
         where er_matriz     = @i_matriz
         and   er_fecha_vig  = @w_fecha_vig
         and   er_eje        = @w_cont
         and   er_rango      = 1 -- Permite que el limite inferior del primer rango siempre sea tenido en cuenta
         and   @w_eje_d     >= convert(datetime,er_rango_desde) 
         and   @w_eje_d     <= convert(datetime,er_rango_hasta)
            
         if @@rowcount = 0 begin
             select @w_posicion = er_rango
             from  ca_eje_rango  with (nolock)
             where er_matriz     = @i_matriz
             and   er_fecha_vig  = @w_fecha_vig
             and   er_eje        = @w_cont
             and   er_rango     >  1
             and   @w_eje_d     >  convert(datetime,er_rango_desde) 
             and   @w_eje_d     <= convert(datetime,er_rango_hasta)

             if @@rowcount = 0 select @w_posicion = 0

         end
      end
   end

   if @w_cont = 1 select @w_posicion1 = @w_posicion
   if @w_cont = 2 select @w_posicion2 = @w_posicion
   if @w_cont = 3 select @w_posicion3 = @w_posicion
   if @w_cont = 4 select @w_posicion4 = @w_posicion
   if @w_cont = 5 select @w_posicion5 = @w_posicion
   if @w_cont = 6 select @w_posicion6 = @w_posicion
   if @w_cont = 7 select @w_posicion7 = @w_posicion
   if @w_cont = 8 select @w_posicion8 = @w_posicion
   if @w_cont = 9 select @w_posicion9 = @w_posicion
   if @w_cont = 10 select @w_posicion10 = @w_posicion
   if @w_cont = 11 select @w_posicion11 = @w_posicion
   if @w_cont = 12 select @w_posicion12 = @w_posicion
   if @w_cont = 13 select @w_posicion13 = @w_posicion
   if @w_cont = 14 select @w_posicion14 = @w_posicion
   if @w_cont = 15 select @w_posicion15 = @w_posicion   

end  --while

/* BUSCA EL VALOR RESULTANTE */


select @o_valor = mv_valor
from ca_matriz_valor with (nolock)
where mv_matriz    = @i_matriz
and   mv_fecha_vig = @w_fecha_vig
and   mv_rango1    = @w_posicion1
and   mv_rango2    = @w_posicion2
and   mv_rango3    = @w_posicion3
and   mv_rango4    = @w_posicion4
and   mv_rango5    = @w_posicion5
and   mv_rango6    = @w_posicion6
and   mv_rango7    = @w_posicion7
and   mv_rango8    = @w_posicion8
and   mv_rango9    = @w_posicion9
and   mv_rango10   = @w_posicion10
and   mv_rango11   = @w_posicion11
and   mv_rango12   = @w_posicion12
and   mv_rango13   = @w_posicion13
and   mv_rango14   = @w_posicion14
and   mv_rango15   = @w_posicion15

if @@rowcount = 0 begin
   select @o_valor = @w_valor_default
end


select @o_2valor = max(mv_valor) 
from ca_matriz_valor with (nolock)
where mv_matriz    = @i_matriz
and   mv_fecha_vig = @w_fecha_vig
and   mv_rango1    = @w_posicion1
and   mv_valor     < @o_valor 

if @@rowcount = 0 select @o_2valor = 0

return 0

go
