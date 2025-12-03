/************************************************************************/
/*  Archivo:                in_cupos_asoc.sp                            */
/*  Stored procedure:       sp_in_cupos_asoc                            */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*  Este stored procedure permite realizar operaciones                  */
/*  Insert, Update, Delete, Search y Query en la tabla                  */
/*      cr_ctrl_cupo_asoc                                               */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*      16/dic/02       Alfredo Zuluaga         Emision Inicial         */
/*      14/dic/2005     Rafael Adames           Optimizacion            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_in_cupos_asoc')
    drop proc sp_in_cupos_asoc
go

create proc sp_in_cupos_asoc (
	@s_ssn 		int      = null,
	@s_user		login    = null,
	@s_sesn		int    = null,
	@s_term		descripcion = null,
	@s_date		datetime = null,
	@s_srv		varchar(30)  = null,
	@s_lsrv		varchar(30) = null,
	@s_rol		smallint = null,
	@s_ofi		smallint  = null,
	@s_org_err	char(1) = null,
	@s_error	int = null,
	@s_sev		tinyint = null,
	@s_msg		descripcion = null,
	@s_org		char(1) = null,
	@t_rty		char(1)  = null,
	@t_trn		smallint = null,
	@t_debug	char(1)  = 'N',
	@t_file		varchar(14) = null,
	@t_from		varchar(30) = null,
	@i_operacion	char(1)  = null,
        @i_num_cupo     int  = null,
        @i_modo         int  = 0,
        @i_tramite      int = null,
	@i_secuencial	int  = null,
	@i_montoDP	float = null,
	@i_plazoDP	int  = null,
	@i_fecha_des	datetime  = null,
	@i_acta		varchar(20)  = null,
	@i_estado	catalogo  = null,
        @i_linea        cuenta = null,
        @i_operacionca  int = null,
        @o_numero       int = null out

)
as
declare
@w_today              datetime,     /* fecha del dia */
@w_return             int,          /* valor que retorna */
@w_sp_name            varchar(32),  /* nombre stored proc*/
@w_existe             tinyint,      /* existe el registro*/
@w_num_cupo           int,
@w_secuencial         int,
@w_sec                int,
@w_montoDP            float,
@w_plazoDP            int,
@w_fecha_des          datetime,
@w_acta               varchar(20),
@w_estado             catalogo,
@w_numero             int,
@w_sumpor             float,
@w_num_linea          int
,@w_op_lin_credito    cuenta  -- RHA



/*
select @w_today = @s_date
select @w_sp_name = 'sp_in_cupos_asoc'
select @w_existe = 0
select @w_numero = 0



--*****************************
--/ Codigos de Transacciones   

if (@t_trn <> 21865 and @i_operacion = 'I') or
   (@t_trn <> 21866 and @i_operacion = 'U') or
   (@t_trn <> 21867 and @i_operacion = 'D') or
   (@t_trn <> 21868 and @i_operacion = 'S') or
   (@t_trn <> 21868 and @i_operacion = 'T') or
   (@t_trn <> 21869 and @i_operacion = 'Q')
begin
--   / tipo de transaccion no corresponde
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = 2101006
   return 1
end

--/ Con el dato del tramite conseguir Numero de Cupo 
--***************************************************
if @i_num_cupo is null and @i_tramite is not NULL
begin
   select @i_num_cupo = li_numero
   from   cr_linea
   where  li_tramite = @i_tramite
end

--/ Chequeo de Existencias 
--*************************
if @i_operacion <> 'S'
begin
	select	@w_num_cupo   = ca_num_cupo,
		@w_secuencial = ca_secuencial,
		@w_montoDP    = ca_porcentaje,
		@w_plazoDP    = ca_plazo,
		@w_fecha_des  = ca_fecha_desembolso,
		@w_acta       = ca_acta,
		@w_estado     = ca_estado
	from 	cr_ctrl_cupo_asoc
	where 	ca_num_cupo   = @i_num_cupo
        and   	ca_secuencial = @i_secuencial
	if 	@@rowcount > 0
		select 	@w_existe = 1
	else
		select 	@w_existe = 0
end

--* VALIDACION DE CAMPOS NULOS           
--***************************************
if @i_operacion = 'I' or @i_operacion = 'U'  or @i_operacion = 'D'
begin
   if @i_tramite is NULL
   begin
--	   Campos NOT NULL con valores nulos 
	  exec cobis..sp_cerror
	  @t_debug = @t_debug,
	  @t_file  = @t_file,
	  @t_from  = @w_sp_name,
	  @i_num   = 2101001
	  return  1
   end
end


--/ Insercion del registro 
--*************************
if @i_operacion = 'I'
begin
   if @w_existe = 1
   begin
      --/ Registro ya existe 
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101002
      return 1
   end

	select 	@w_sumpor     = sum(ca_porcentaje)
        from 	cr_ctrl_cupo_asoc
        where 	ca_num_cupo   = @i_num_cupo
        and     ca_secuencial >= 0

	select @w_sumpor = isnull(@w_sumpor ,0)  + @i_montoDP

        if (@w_sumpor > 100.0)
	begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2108014
         return 1
	end


        select	@w_numero = isnull(max(ca_secuencial),0)
        from 	cr_ctrl_cupo_asoc
        where 	ca_num_cupo = @i_num_cupo
        and     ca_secuencial >= 0

        select @i_secuencial = @w_numero + 1

        insert into cr_ctrl_cupo_asoc (
	ca_num_cupo,  ca_secuencial,  ca_porcentaje,
        ca_plazo,     ca_acta,        ca_fecha_desembolso,
        ca_estado)
	values (
	@i_num_cupo,  @i_secuencial,  @i_montoDP,
        @i_plazoDP,   @i_acta,        @i_fecha_des,
        @i_estado)

	if @@error <> 0
	begin
	   --/ Error en insercion de registro 
	   exec cobis..sp_cerror
	   @t_debug = @t_debug,
	   @t_file  = @t_file,
	   @t_from  = @w_sp_name,
	   @i_num   = 2103001
	   return 1
	end

end

--/ Actualizacion del registro 
--******************************

if @i_operacion = 'U'
begin
   if @w_existe = 0
   begin
      exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 2101005
      --/ No existe linea  
      return 1
   end
   else
   begin

	select 	@w_sumpor = sum(ca_porcentaje)
        from 	cr_ctrl_cupo_asoc
        where 	ca_num_cupo   =  @i_num_cupo
        and   	ca_secuencial <> @i_secuencial

	select @w_sumpor = isnull(@w_sumpor ,0)  + @i_montoDP

        if (@w_sumpor > 100.0)
	begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2108014
         return 1
	end

      update cr_ctrl_cupo_asoc
      set    ca_porcentaje       = @i_montoDP,
             ca_plazo            = @i_plazoDP,
             ca_acta             = @i_acta,
             ca_fecha_desembolso = @i_fecha_des,
             ca_estado           = @i_estado
      where  ca_num_cupo   = @i_num_cupo
      and    ca_secuencial = @i_secuencial

      if @@error <> 0
      begin
         --/ Error en actualizacion de registro
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2105001
         return 1
      end

   end
end


--/ Eliminacion de registros
--***************************

if @i_operacion = 'D'
begin

  select @w_sec 	= max(ca_secuencial)
  from 	 cr_ctrl_cupo_asoc
  where  ca_num_cupo    = @i_num_cupo
  and    ca_secuencial  > 0

  select @w_sec = isnull(@w_sec ,0)

  if @w_sec <> @i_secuencial and @i_secuencial is not null
  begin
      --/ Error en insercion de transaccion de servicio 
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2108013
         return 1
  end

      delete 	cr_ctrl_cupo_asoc
      where 	ca_num_cupo   = @i_num_cupo
      and   	ca_secuencial = @i_secuencial

      if @@error <> 0
      begin
         --Error en eliminacion de registro
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2107001
         return 1
      end
end

--**** Search ****
--****************

if @i_operacion = 'S'
begin
      SELECT
      "Secuencial"       = ca_secuencial,
      "Porcentaje"       = ca_porcentaje,
      "Plazo"            = ca_plazo,
      "Acta"             = ca_acta,
      "Fecha Desembolso" = convert(varchar(10), ca_fecha_desembolso, 103),
      "Estado"           = ca_estado
      FROM 		cr_ctrl_cupo_asoc
      WHERE 		ca_num_cupo   = @i_num_cupo
      and   		ca_secuencial > 0

end

--**** Ordenada por Menor Secuencial ***
--**************************************
if @i_operacion = 'T'
begin
   if @i_linea is not null
   begin
      SELECT	@i_num_cupo  = li_numero
      FROM 	cr_linea
      WHERE 	li_num_banco = @i_linea
   end

   if @i_modo = 0
   begin
      SELECT
      "Secuencial"       = ca_secuencial,
      "Porcentaje"       = ca_porcentaje,
      "Plazo"            = ca_plazo,
      "Acta"             = ca_acta,
      "Fecha Desembolso" = convert(varchar(10), ca_fecha_desembolso, 103),
      "Estado"           = ca_estado
      FROM  		cr_ctrl_cupo_asoc
      WHERE 		ca_num_cupo   = @i_num_cupo
      and   		ca_secuencial > 0
      order by ca_secuencial, ca_estado desc
   end

   if @i_modo = 1
   begin

     select @w_num_linea   = li_numero
     from   cob_credito..cr_linea
     where  li_num_banco   = @i_linea

   select "TRAMITE  "    = gp_tramite,
          "EST.TRAMITE  "=  case tr_estado
                            when "A" then "APROBADO"
                            when "N" then "TRAMITE"
                            when "D" then "DEVUELTO"
                            when "A" then "APLAZADO"
			    else " "
                            end,
       "OPERACION  " 	=  (select op_banco from  cob_cartera..ca_operacion
			    where op_tramite = X.gp_tramite),
       "EST.OPERACION  "=  (select case op_estado
                            when 0 then "NO VIGENTE"
                            when 1 then "VIGENTE"
                            when 2 then "VENCIDO"
                            when 3 then "CANCELADO"
                            when 4 then "CASTIGADO"
                            when 5 then "COBRO JURIDICO ACTIVAS"
                            when 6 then "ANULADO"
                            when 7 then "CONDONADO"
                            when 8 then "COBRO JURIDICO PASIVAS"
                            when 9 then "SUSPENSO"
                            when 10 then "NOVEDADES"
                            when 99 then "CREDITO"
		           else " "
                            end
		            from  cob_cartera..ca_operacion
			    where op_tramite = X.gp_tramite),
       "GARANTIA  "	= gp_garantia
      from   cr_gar_propuesta X,
	     cr_tramite
      where  gp_tramite 	= tr_tramite
      and    tr_tipo     	in ("O","R")
      and    tr_linea_credito 	= @w_num_linea
      and    gp_tramite 	> 0
      and    gp_garantia        > "0"
   end

   if @i_modo = 2
   begin
      SELECT
      "Secuencial"       = ca_secuencial,
      "Porcentaje"       = ca_porcentaje,
      "Plazo"            = ca_plazo,
      "Acta"             = ca_acta,
      "Fecha Desembolso" = convert(varchar(10), ca_fecha_desembolso, 103),
      "Estado"           = ca_estado
      FROM  	cr_ctrl_cupo_asoc
      WHERE 	ca_num_cupo   = @i_num_cupo
      AND   	ca_fecha_desembolso is null
      and   	ca_secuencial > 0
      order by ca_secuencial, ca_estado desc
   end
end


--* Consulta opcion QUERY 
--*************************

if @i_operacion = 'Q'
begin
   if @w_existe = 1
   begin

      select @w_num_cupo,
             @w_secuencial,
             @w_montoDP,
             @w_plazoDP,
             @w_acta,          --5
             convert(varchar(10), @w_fecha_des, 103),
             @w_estado
   end
end

-- Desembolso            
--************************

if @i_operacion = 'L'
begin

--**
--  * select @w_num_cupo    = li_numero
--  * from   cob_cartera..ca_operacion,
--  *	  cr_linea
--  * where  op_operacion 	 = @i_operacionca
--  * and    op_lin_credito = li_num_banco
--  * and    li_numero 	 > 0
--**
   select @w_op_lin_credito = a.op_lin_credito
     from cob_cartera..ca_operacion a
   where  op_operacion 	 = @i_operacionca
     and exists (select 1 from cr_linea b
         where b.li_num_banco= a.op_lin_credito)

    select @w_num_cupo    = li_numero from cr_linea
       where li_num_banco = @w_op_lin_credito


   update cr_ctrl_cupo_asoc
   set    ca_estado = "D"
   where  ca_secuencial in (    select min(ca_secuencial)
			   	from   cr_ctrl_cupo_asoc
   				where  ca_num_cupo    = @w_num_cupo
   				and    ca_estado      = "T"
				and    ca_secuencial  > 0)
   and	  ca_num_cupo	= @w_num_cupo
   and    ca_secuencial > 0

end

if @i_operacion = 'R'
begin

   select @w_num_cupo    = li_numero
   from   cob_cartera..ca_operacion,
	  cr_linea
   where  op_operacion 	 = @i_operacionca
   and    op_lin_credito = li_num_banco
   and    li_numero 	 > 0


   update cr_ctrl_cupo_asoc
   set    ca_estado = "T"
   where  ca_secuencial in (    select max(ca_secuencial)
			   	from   cr_ctrl_cupo_asoc
   				where  ca_num_cupo    = @w_num_cupo
   				and    ca_estado      = "D"
      				and    ca_secuencial > 0)
   and	  ca_num_cupo	= @w_num_cupo
   and    ca_secuencial > 0
end

if @i_operacion = 'M'
begin
   select @w_num_cupo	= tr_linea_credito
   from   cr_tramite
   where  tr_tramite 	= @i_tramite

   update cr_ctrl_cupo_asoc
   set    ca_estado = "T"
   where  ca_secuencial in (    select min(ca_secuencial)
			   	from   cr_ctrl_cupo_asoc
   				where  ca_num_cupo    = @w_num_cupo
   				and    ca_estado      = "N"
      				and    ca_secuencial > 0)
   and	  ca_num_cupo	= @w_num_cupo
   and    ca_secuencial > 0
end

if @i_operacion = 'N'
begin

   select @w_num_cupo	= tr_linea_credito
   from   cr_tramite
   where  tr_tramite 	= @i_tramite

   update cr_ctrl_cupo_asoc
   set    ca_estado = "N"
   where  ca_secuencial in (    select max(ca_secuencial)
			   	from   cr_ctrl_cupo_asoc
   				where  ca_num_cupo    = @w_num_cupo
   				and    ca_estado      = "T"
				and    ca_secuencial > 0)
   and	  ca_num_cupo	= @w_num_cupo
   and    ca_secuencial > 0
end
*/
return 0
go
