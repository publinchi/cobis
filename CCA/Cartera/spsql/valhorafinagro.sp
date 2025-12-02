/************************************************************************/
/*   Archivo:             valhorafinagro.sp                             */
/*   Stored procedure:    sp_val_hora_des_finagro                       */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Luis Carlos Moreno                            */
/*   Fecha de escritura:  2015/01                                       */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Realiza validaciones de la hora del desembolso para FINAGRO        */
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2015-01-02   Luis Carlos Moreno  Req479:Cartera Finagro Fase 2     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_val_hora_des_finagro')
   drop proc sp_val_hora_des_finagro
go

create proc sp_val_hora_des_finagro
   @s_user           login        = null,
   @s_ofi            smallint     = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @i_operacionca    int,
   @i_debug          char         = 'N'
as
declare
   @w_tipo_operacion         catalogo,
   @w_hora_ini_fina          catalogo,
   @w_hora_fin_fina          catalogo,
   @w_hora_ini_fisu          catalogo,
   @w_hora_fin_fisu          catalogo,
   @w_hora_des               varchar(5),
   @w_min_des                varchar(5),
   @w_hora_desembolso        catalogo,
   @w_error                  int,
   @w_codigo_sib             char(1)

begin

   --CCA 479 OBTIENE HORAS DE DESEMBOLSO DE FINAGRO CARTERA AGROPECUARIA
   select @w_hora_ini_fina = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'HINIFI'

   if @@ROWCOUNT = 0
      return 708153

   select @w_hora_fin_fina = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'HFINFI'
   
   if @@ROWCOUNT = 0
      return 708153

   --CCA 500 OBTIENE HORAS DE DESEMBOLSO DE FINAGRO CARTERA SUSTITUTIVA
   select @w_hora_ini_fisu = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'HIFISU'

   if @@ROWCOUNT = 0
      return 708153

   select @w_hora_fin_fisu = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'HFFISU'
   
   if @@ROWCOUNT = 0
      return 708153

   -- SI EL TIPO DE OPERACION PERTENECE A FINAGRO SE VALIDA QUE EL DESEMBOLSO SE ENCUENTRE EN EL
   -- HORARIO ESTABLECIDO
   select @w_tipo_operacion = op_toperacion
   from ca_operacion
   where  op_operacion = @i_operacionca

   --Dependiendo de la linea de credito evaluamos si es cartera agropecuaria o sustitutiva
   select @w_codigo_sib = s.codigo_sib from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c  
   where s.descripcion_sib = t.tabla
   and t.codigo            = c.tabla
   and s.tabla             = 'T301'
   and c.codigo            = @w_tipo_operacion
   and s.codigo_sib        in ('A','S')
   and c.estado            = 'V'
   
   if @@error <> 0
     return 701049
   
   if exists (select 1 from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c  
              where s.descripcion_sib = t.tabla
              and t.codigo            = c.tabla
              and s.tabla             = 'T301'
              and c.codigo            = @w_tipo_operacion
              and s.codigo_sib        in ('A','S')
              and c.estado            = 'V')
   begin
		if(len(convert(varchar(2),datepart(hh,getdate()))) = 1)
		begin
			select @w_hora_des = '0' + convert(varchar(2),datepart(hh,getdate()))
		end
		else 
		begin
			select @w_hora_des = convert(varchar(2),datepart(hh,getdate()))
		end

		if(len(convert(varchar(2),datepart(mi,getdate()))) = 1)
		begin
			select @w_min_des  = '0' + convert(varchar(2),datepart(mi,getdate()))
		end
		else
		begin
			select @w_min_des  = convert(varchar(2),datepart(mi,getdate()))
		end
		
/*
      select @w_hora_des = case when len(convert(varchar(2),datepart(hh,getdate()))) = 1 then '0' + convert(varchar(2),datepart(hh,getdate())) else  convert(varchar(2),datepart(hh,getdate())) end, 
             @w_min_des  = case when len(convert(varchar(2),datepart(mi,getdate()))) = 1 then '0' + convert(varchar(2),datepart(mi,getdate())) else  convert(varchar(2),datepart(mi,getdate())) end
  */           
      select @w_hora_desembolso = @w_hora_des + @w_min_des
      
      select @w_hora_ini_fina = REPLACE(@w_hora_ini_fina,':','')
      select @w_hora_fin_fina = REPLACE(@w_hora_fin_fina,':','')

      --Formateo de hora para cartera sustitutiva
      select @w_hora_ini_fisu = REPLACE(@w_hora_ini_fisu,':','')
      select @w_hora_fin_fisu = REPLACE(@w_hora_fin_fisu,':','')
      
      if @i_debug = 'S'
         print 'OPERACION ' + convert(varchar, @i_operacionca)
             + ' @w_tipo_operacion ' + convert(varchar, @w_tipo_operacion)
             + ' @w_hora_ini_fina ' + convert(varchar, @w_hora_ini_fina)
             + ' @w_hora_fin_fina ' + convert(varchar, @w_hora_fin_fina)
             + ' @@w_hora_desembolso ' + convert(varchar, @w_hora_desembolso)

      if @w_codigo_sib = 'A'
      begin
         if @w_hora_desembolso < @w_hora_ini_fina or @w_hora_desembolso > @w_hora_fin_fina
            return 724031
      end
      else
      begin
         if @w_hora_desembolso < @w_hora_ini_fisu or @w_hora_desembolso > @w_hora_fin_fisu
            return 724031
      end
   end

   return 0
   
end
go
