/*************************************************************************/
/*   Archivo:              ctrl_inspec.sp                                */
/*   Stored procedure:     sp_ctrl_inspect                               */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_ctrl_inspect') IS NOT NULL
    DROP PROCEDURE dbo.sp_ctrl_inspect
go
create proc sp_ctrl_inspect (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_inspector          tinyint  = null,
   @i_fenvio_carta       datetime  = null,
   @i_frecep_reporte     datetime  = null,
   @i_valor_facturado    money  = null,
   @i_fecha_pago         datetime  = null,
   @i_inspector1         tinyint  = null,
   @i_formato_fecha      int = null,
   @i_fenvio1  		 datetime = null,
   @i_fenvio2            datetime = null,
   @i_param1             varchar(10) = null,
   @i_param2             varchar(10) = null,
   @i_cond1              varchar(15) = null,
   @i_cond2              varchar(15) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_inspector          tinyint,
   @w_fenvio_carta       datetime,
   @w_frecep_reporte     datetime,
   @w_valor_facturado    money,
   @w_fecha_pago         datetime,
   @w_aux                money 

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_ctrl_inspect'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19070 and @i_operacion = 'I') or
   (@t_trn <> 19071 and @i_operacion = 'U') or
   (@t_trn <> 19072 and @i_operacion = 'D') or
   (@t_trn <> 19073 and @i_operacion = 'V') or
   (@t_trn <> 19074 and @i_operacion = 'S') or
   (@t_trn <> 19075 and @i_operacion = 'Q') or
   (@t_trn <> 19076 and @i_operacion = 'A') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,

    @i_num   = 1901006
    return 1 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_inspector = ci_inspector,
         @w_fenvio_carta = ci_fenvio_carta,
         @w_frecep_reporte = ci_frecep_reporte,
         @w_valor_facturado = ci_valor_facturado,
         @w_fecha_pago = ci_fecha_pago
    from cob_custodia..cu_control_inspector
    where 
         ci_inspector = @i_inspector and
         ci_fenvio_carta = @i_fenvio_carta

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if 
         @i_inspector = NULL or 
         @i_fenvio_carta = NULL 
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end


    begin tran
         insert into cu_control_inspector(
              ci_inspector,
              ci_fenvio_carta,
              ci_frecep_reporte,
              ci_valor_facturado,
              ci_fecha_pago)
         values (
              @i_inspector,
              @i_fenvio_carta,
              @i_frecep_reporte,
              @i_valor_facturado,
              @i_fecha_pago)

         if @@error <> 0 
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_control_inspector
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_control_inspector',
         @i_inspector,
         @i_fenvio_carta,
         @i_frecep_reporte,
         @i_valor_facturado,
         @i_fecha_pago)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran 
    return 0
end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */

        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    begin tran
         update cob_custodia..cu_control_inspector
         set 
              ci_frecep_reporte = @i_frecep_reporte,
              ci_valor_facturado = @i_valor_facturado,
              ci_fecha_pago = @i_fecha_pago
    where 
         ci_inspector = @i_inspector and
         ci_fenvio_carta = @i_fenvio_carta

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_control_inspector
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_control_inspector',
         @w_inspector,
         @w_fenvio_carta,
         @w_frecep_reporte,
         @w_valor_facturado,
         @w_fecha_pago)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_control_inspector
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_control_inspector',
         @i_inspector,

         @i_fenvio_carta,
         @i_frecep_reporte,
         @i_valor_facturado,
         @i_fecha_pago)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

/***** Integridad Referencial *****/
/*****                        *****/


    begin tran
         delete cob_custodia..cu_control_inspector
    where 
         ci_inspector = @i_inspector and
         ci_fenvio_carta = @i_fenvio_carta

                                          
         if @@error <> 0
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end

            


         /* Transaccion de Servicio */
         /***************************/

         insert into ts_control_inspector
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_control_inspector',
         @w_inspector,
         @w_fenvio_carta,
         @w_frecep_reporte,
         @w_valor_facturado,
         @w_fecha_pago)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
         select 
              convert(char(10),@w_frecep_reporte,@i_formato_fecha),
              convert(char(10),@w_fecha_pago,@i_formato_fecha),
              @w_valor_facturado
    else
    begin
    /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005
        return 1 
    end
    return 0
end

/* Busqueda de registros */
if @i_operacion = 'S'
begin
   if @i_modo = 0
   begin
      select "INSPECTOR"=ci_inspector,"ENVIO CARTA"=convert(char(10),ci_fenvio_carta,@i_formato_fecha),
             "RECEPCION REPORTE"=convert(char(10),ci_frecep_reporte,@i_formato_fecha),
             "VALOR FACTURADO"=ci_valor_facturado,"FECHA PAGO"=convert(char(10),ci_fecha_pago,@i_formato_fecha)
      from cu_control_inspector with(index(cu_control_inspector_Key)) --CSA Migracion Sybase
      where (ci_inspector = @i_inspector or @i_inspector is null)
        and (ci_fenvio_carta >= @i_fenvio1 or @i_fenvio1 is null)
        and (ci_fenvio_carta <= @i_fenvio2 or @i_fenvio2 is null)
      order by ci_inspector, ci_fenvio_carta --CSA Migracion Sybase
      if @@rowcount = 0
      begin
        /*No existes registros */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901003
        return 1 
      end
   end
   if @i_modo = 1
   begin
      select "INSPECTOR"=ci_inspector,"ENVIO CARTA"=convert(char(10),ci_fenvio_carta,@i_formato_fecha),
             "RECEPCION REPORTE"=convert(char(10),ci_frecep_reporte,@i_formato_fecha),
             "VALOR FACTURADO"=ci_valor_facturado,"FECHA PAGO"=convert(char(10),ci_fecha_pago,@i_formato_fecha)
      from cu_control_inspector with(index(cu_control_inspector_Key)) --CSA Migracion Sybase
      where (ci_inspector = @i_inspector or @i_inspector is null)
        and (ci_fenvio_carta >= @i_fenvio1 or @i_fenvio1 is null)
        and (ci_fenvio_carta <= @i_fenvio2 or @i_fenvio2 is null)
        and ((ci_inspector > @i_inspector1) or
            (ci_inspector = @i_inspector1 and ci_fenvio_carta > @i_fenvio_carta)) 
        order by ci_inspector, ci_fenvio_carta --CSA Migracion Sybase
      if @@rowcount = 0
      begin
        /*No existes mas registros */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901004
        return 1 
      end
   end
end 
            
if @i_operacion = 'A'
begin
      set rowcount 20
      if @i_fenvio_carta is null
         select @i_fenvio_carta = convert(datetime,@i_cond2,101)
      if @i_inspector is null
         select @i_inspector = convert(tinyint,@i_cond1)
      select "INSPECTOR" = ci_inspector,
             "FECHA ENVIO CARTA" = convert(varchar(10),ci_fenvio_carta,101) 
        from cu_control_inspector with(index(cu_control_inspector_Key)) --CSA Migracion Sybase
       where (ci_inspector = @i_inspector or @i_inspector is null)
         and (ci_fenvio_carta > @i_fenvio_carta or @i_fenvio_carta is null)
         order by ci_inspector, ci_fenvio_carta --CSA Migracion Sybase
      if @@rowcount = 0
        /*  begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
         end */
        return 1
end

if @i_operacion = 'V'
begin
   if exists (select * from cu_control_inspector
               where ci_inspector = @i_inspector
                 and convert(varchar(10),ci_fenvio_carta,@i_formato_fecha) = 
                     convert(varchar(10),@i_fenvio_carta,@i_formato_fecha))
      select  @w_aux = @w_valor_facturado
   else
   begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1901003
      return 1 
   end
end
go