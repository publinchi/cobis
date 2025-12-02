/************************************************************************/
/*  Archivo:                cliente_pref.sp                             */
/*  Stored procedure:       sp_cliente_pref                             */
/*  Base de datos:          cob_credito                                 */
/*  Producto:               CREDITO                                     */
/*  Disenado por:           Johan F. Ardila R.                          */
/*  Fecha de escritura:     Septiembre 2010                             */
/************************************************************************/
/*                               IMPORTANTE                             */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de la           */
/*  'NCR CORPORATION'.                                                  */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/*              PROPOSITO                                               */
/*  Permite el registro de clientes preferenciales. Campaña o Especiales*/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR        RAZON                                      */
/*  10/Sep/10   J. Ardila    Emision Inicial                            */
/*  10/Feb/12   J. Zamora    Contraofertas                              */
/*  18/Feb/15   Acelis       Req 499 Carga de Clientes Especiales       */
/************************************************************************/
use cob_credito
go

if object_id ('sp_cliente_pref') is not null
begin
    drop proc sp_cliente_pref
end
go

create proc sp_cliente_pref(
   @s_ssn                  int         = NULL,
   @s_date                 datetime    = NULL,
   @s_user                 login       = NULL,
   @s_term                 descripcion = NULL,
   @s_corr                 char(1)     = NULL,
   @s_ssn_corr             int         = NULL,
   @s_ofi                  smallint    = NULL,
   @s_sesn                 int         = NULL,
   @s_srv                  varchar(30) = NULL,
   @s_lsrv                 varchar(30) = NULL,
   @t_rty                  char(1)     = NULL,
   @t_trn                  smallint    = NULL,
   @t_debug                char(1)     = 'N',
   @t_file                 varchar(14) = NULL,
   @i_cliente              int         = null,
   @i_campana              int         = null,
   @i_tipo_id              char(2)     = null,
   @i_no_id                catalogo    = null,
   @i_tipo_pref            catalogo,
   @i_fecha                datetime,
   @i_org_carga            char(3),     -- CCA Cartera o CAM Campañas   
   @i_oficina              int,
   @i_desde                varchar(50) = 'evaluar_cliente',
   @o_msg                  descripcion = null out
)
as
declare
   @w_sp_name       varchar(30),
   @w_tipo_campana  int,
   @w_campana       int,
   @w_inserta       char(1),
   @w_cliente       int,
   @w_msg           varchar(250),
   @w_msg_e         varchar(250),
   @w_tipo_pref     catalogo,
   @w_clientesc     varchar(10),
   @w_estado        char(1),
   @w_fecha_proceso datetime,
   @w_fecha_fin     datetime,
   @w_error         int,
   @w_asignado_a    varchar(60),
   @w_dias_bloq     int,
   @w_fecha_camp    datetime,
   @w_fecha_tot     datetime,
   @w_fecha_cierre  datetime,
   @w_cam_normali   int       --REQ499 Parametro tipo campaña de normalización
 
   
select 
   @w_sp_name   = 'sp_cliente_pref', 
   @w_inserta   = 'N',
   @w_campana   = @i_campana,
   @w_tipo_pref = @i_tipo_pref  
   
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

-- Se fija parametro tipo de campaña normalizacion 
select @w_cam_normali = 3

---------------------------- 
/* Validacion de Oficina  */
----------------------------
if exists (select 1 from cobis..cl_oficina
           where  of_oficina = @i_oficina)
begin
   select @i_oficina = @i_oficina
end 
else
begin
   select 
      @w_msg     = 'No Existe Oficina',
      @w_cliente = null
   goto ERROR
end

------------------------------------------- 
/* Cartera no envía el código de Campaña */
/* debe asociarse a una Campana Especial */
-------------------------------------------
if @i_org_carga = 'CCA'
begin
   select @w_cliente = @i_cliente
   
   if exists (select 1 from cobis..cl_catalogo C, cobis..cl_tabla T
              where T.tabla   = 'cr_cli_pref_campana'
              and   T.codigo  = C.tabla
              and   C.codigo  = @i_tipo_pref
              and   C.codigo <> 'X')
   begin
      select top 1 @w_campana = ca_codigo
      from  cr_campana
      where ca_clientesc = 'ESPECIAL'
      and   ca_estado    = 'V'

      if @w_campana is null
      begin
         select @w_msg = 'No Existe Campana ESPECIAL o no esta Vigente'
         goto ERROR
      end
   end  
   else
   begin
      select @w_msg = 'Tipo de Cliente Preferencial no Corresponde: ' + @i_tipo_pref
      goto ERROR
   end   
   --------------------------------------------------------------------------------     
   /*VALIDACION DE PARAMETRO DE DIAS DE BLOQUEO DE CAMPANA POR RECHAZO*/
   -------------------------------------------------------------------------------- 

   if exists (select 1 from cr_cliente_campana where cc_campana = @w_campana and cc_cliente = @i_cliente and cc_estado = 'C')
   begin
      select @w_dias_bloq = pa_int 
      from   cobis..cl_parametro 
      where  pa_nemonico  = 'DIBLC'
               
       select @w_fecha_camp = max(cc_fecha)
       from  cr_cliente_campana 
       where cc_cliente  = @i_cliente 
       and   cc_campana  = @w_campana
             
       select @w_fecha_cierre = cc_fecha_cierre
       from cr_cliente_campana
       where cc_cliente = @i_cliente
       and   cc_campana = @w_campana
       and   cc_fecha   = @w_fecha_camp
             
       if @w_fecha_cierre  is not null
       begin
          select @w_fecha_tot = dateadd(dd,@w_dias_bloq, @w_fecha_cierre)
          if @w_fecha_tot <= @w_fecha_proceso
             select @w_inserta = 'S'  
       end
       else
       begin
          if exists (select 1 from cr_cliente_campana where cc_estado ='V' and cc_cliente = @i_cliente and cc_fecha = @w_fecha_proceso)
             select @w_inserta = 'N'
          else
             select @w_inserta = 'S'
       end   
   end
   else
   begin
      if exists (select 1 from cr_cliente_campana where cc_estado ='V' and cc_cliente = @i_cliente)
         select @w_inserta = 'N'
      else
         select @w_inserta = 'S'
   end
end  -- if @i_org_carga = 'CCA'

----------------------------------------
/* Desde la Carga de Archivo Campañas */
----------------------------------------
if @i_org_carga = 'CAM'
begin
    -- Validacion Cliente
   select @w_cliente = en_ente
   from   cobis..cl_ente
   where  en_ced_ruc  = @i_no_id
   and    en_tipo_ced = @i_tipo_id

   if @@rowcount = 0
   begin
      select 
         @w_msg     = 'No Existe Cliente',
         @w_cliente = null
      goto ERROR      
   end

   -- Validacion Campaña Especial y Vigente
   select @w_clientesc = ca_clientesc,
          @w_estado    = ca_estado
   from   cr_campana
   where  ca_codigo = @i_campana

   if @@rowcount = 0
   begin
      select @w_msg = 'No Existe Campana'
      goto ERROR 
   end
   -- Tipo campaña
   if @w_clientesc = 'ESPECIAL'   
   begin
      select @w_msg = 'No se pueden cargar Campanas Especiales'
      goto ERROR 
   end

   -- Estado campaña
   if @w_estado = 'C'
   begin
      select @w_msg = 'Campana no esta Vigente'
      goto ERROR 
   end

   select @w_inserta = 'S'
end  -- if @i_org_carga = 'CAM'

----------------------------------------------------------
/* Todo Validado se procede a registrar Cliente-Campaña */
----------------------------------------------------------
if @w_inserta = 'S'
begin
   
   select 
   @w_tipo_campana    = ca_tipo_campana,
   @w_fecha_fin       = ca_vig_fin 
   from   cr_campana 
   where  ca_codigo = @i_campana  
  

   if @w_tipo_campana = @w_cam_normali begin
      
      if not exists (select * from cobis..cl_oficina where of_oficina = @i_oficina) begin 
         select
         @w_msg   = 'CODIGO DE OFICINA NO EXISTE'
         goto RESPUESTA
         
      end    
   
      if not exists (select 1 from cobis..cl_ente where en_ced_ruc = @i_no_id and en_tipo_ced = @i_tipo_id) begin  
         select
         @w_msg   = 'NUMERO DE CEDULA NO EXISTE'
         goto RESPUESTA
      end
      
      if not exists (select 1 from cob_credito..cr_campana where ca_codigo = @i_campana) begin  
         select
         @w_msg   = 'NO EXISTE CAMPANA' 
         goto RESPUESTA
      end      

      if not exists (select 1 from cob_credito..cr_campana where ca_codigo = @i_campana and ca_estado = 'V') begin  
         select
         @w_msg   = 'LA CAMPANA NO ESTA VIGENTE' 
         goto RESPUESTA
      end    

      if exists (select 1 from cob_credito..cr_cliente_campana where  cc_cliente = @w_cliente
                                                               and cc_tipo_pref = 'X'
                                                               and cc_estado = 'V'
                                                               and cc_campana in (select ca_codigo from cob_credito..cr_campana
                                                                                  where ca_tipo_campana <> @w_cam_normali) ) begin  
         select
         @w_msg   = 'CLIENTE  SE ENCUENTRA ASOCIADO EN UNA CAMPANA VIGENTE DIFERENTE DE NORMALIZACION' 
         goto RESPUESTA
      end
      
      if exists (select 1 from cr_cliente_campana where cc_cliente = @w_cliente and cc_campana = @i_campana and cc_estado = 'V' and  @i_org_carga = 'CAM') begin  
         select
         @w_msg   = 'CLIENTE YA EXISTE EN LA MISMA CAMPANA DE NORMALIZACION'
         goto RESPUESTA
         
      end 
       
      if exists (select 1 from cob_credito..cr_cliente_campana where  cc_cliente = @w_cliente
                                                               and cc_tipo_pref = 'X'
                                                               and cc_estado = 'V'
                                                                and cc_campana in (select ca_codigo from cob_credito..cr_campana
                                                                                  where ca_tipo_campana =@w_cam_normali) ) begin 
                                                              
         update cob_credito..cr_cliente_campana
         set cc_campana =   @i_campana 
         where  cc_cliente = @w_cliente
         and cc_tipo_pref = 'X'
         and cc_estado = 'V'
         and cc_campana in (select ca_codigo from cob_credito..cr_campana
                            where ca_tipo_campana =@w_cam_normali)
         select @w_msg   = 'SE ACTUALIZA CAMPANA DE NORMALIZACION ' 
         goto RESPUESTA
      end 
      
      
      if exists    (select 1 
                    from   cob_credito..cr_tramite P    
                    where  P.tr_estado <> 'Z'
                    and    P.tr_fecha_apr is null
                    and    P.tr_tipo  = 'M'
                    and    P.tr_cliente = @w_cliente)
                    
         or exists (select 1 
                    from  cob_cartera..ca_operacion,cob_credito..cr_tramite D   
                    where op_estado = 0 
                    and   op_tramite = D.tr_tramite
                    and   D.tr_tipo  = 'M'
                    and   op_cliente =@w_cliente) begin
         
         select
         @w_msg   = 'CLIENTE SE ENCUENTRA EN UN TRAMITE DE NORMALIZACION EN CURSO'
         goto RESPUESTA
      end
   end
   else begin
  
      if exists (select 1 from cob_credito..cr_cliente_campana where  cc_cliente = @w_cliente
                                                               and cc_tipo_pref = 'X'
                                                               and cc_estado = 'V'
                                                               and cc_campana in (select ca_codigo from cob_credito..cr_campana
                                                                                  where ca_tipo_campana = @w_cam_normali) ) begin  
         select
         @w_error = 101186,
         @w_msg   = 'ERROR:CLIENTE:' + convert (varchar, @w_cliente) + ', YA TIENE CAMPANA ASIGNADA DE NORMALIZACION'
         goto ERROR
      end
      
  
      if exists (select 1 from cr_cliente_campana where cc_cliente = @w_cliente and cc_campana = @w_campana and @i_org_carga = 'CAM' and cc_estado = 'V' ) begin 
         select
         @w_error = 101186,
         @w_msg   = 'ERROR: EL CLIENTE ' + convert (varchar, @w_cliente) + ', YA EXISTE EN LA LA TABLA cr_cliente_campana CON CAMPANA ASIGNADA'
         goto ERROR
      end    
   
      if exists (select 1 from cr_cliente_campana where cc_cliente = @w_cliente and cc_campana = @w_campana and cc_estado = 'V' and  @i_org_carga = 'CCA') begin  
         select
         @w_error = 101186,
         @w_msg   = 'ERROR: EL CLIENTE ' + convert (varchar, @w_cliente) + ', YA EXISTE EN LA LA TABLA cr_cliente_campana CON LA MISMA CAMPANA'
         goto ERROR
      end    
   end

   if @i_desde = 'carga_masiva' begin

      update cr_cliente_campana set
      cc_estado   = 'C'
      from cr_campana
      where cc_campana      = ca_codigo
      and   cc_cliente      = @w_cliente
      and   ca_estado       = 'V'
      and   cc_estado       = 'V'
      and   ca_tipo_campana = @w_tipo_campana
                                                 
      if @@error <> 0 begin
         select 
         @w_error = 13000,  
         @w_msg = 'ERROR AL ACTUALIZAR EL CAMPO cc_estado'
         goto ERROR
      end
   end else begin
   if exists (select 1 
              from  cr_cliente_campana, cr_campana 
              where cc_campana      = ca_codigo
              and   cc_cliente      = @i_cliente
              and   ca_estado       = 'V'
              and   cc_estado       = 'V'
              and   ca_tipo_campana = @w_tipo_campana) 
      begin
         return 0
      end       
   end      

   exec @w_error = sp_asignacion_automatica
   @i_cliente    = @w_cliente,
   @i_campana    = @w_campana,
   @i_oficina    = @i_oficina,                  --CCFU
   @i_desde      = @i_desde,                    --CCFU  
   @o_asignado_a = @w_asignado_a out,
   @o_msg        = @o_msg out         
     
   if @w_error <> 0
   begin
      select @w_msg = 'Error al Insertar Registro cr_cliente_campana'
      goto ERROR
   end      
   
   
   
   insert into cr_cliente_campana (
   cc_cliente,      cc_campana,     cc_tipo_pref,
   cc_fecha,        cc_oficina,     cc_estado,
   cc_fecha_ini,    cc_fecha_fin,   cc_asignado_a,  
   cc_asignado_por)
   values (
   @w_cliente,       @w_campana,     @w_tipo_pref,
   @i_fecha,         @i_oficina,     'V',
   @w_fecha_proceso, @w_fecha_fin,   @w_asignado_a,
   'SISTEMA')

   if @@error <> 0
   begin
      select @w_msg = 'Error al Insertar Registro cr_cliente_campana'
      goto ERROR
   end   
   else
      select @o_msg = 'INSERCION DE CAMPANA EXITOSA'
       
       
   insert into cr_asignacion_campana (
   ac_campana,       ac_cliente,           ac_usuario_asigna,
   ac_fecha_asigna,  ac_usuario_reasigna,  ac_fecha_reasigna)
   values (
   @w_campana,       @w_cliente,           'SISTEMA',
   @w_fecha_proceso, null,                 null)         

   if @@error <> 0
   begin
      select @w_msg = 'Error al Insertar Registro cr_cliente_campana'
      goto ERROR
   end  
   
   
end  -- if @w_inserta = 'S'
return 0

RESPUESTA:
select @o_msg = @w_msg


ERROR:   
select @o_msg = @w_msg
insert into cr_carga_campana_log 
   (cl_oficina,     cl_campana,  cl_cliente,
    cl_id,          cl_tipo_id,  cl_fecha_carga,
    cl_descripcion, cl_origen)
values 
   (@i_oficina,     @w_campana,  @w_cliente,
    @i_no_id,       @i_tipo_id,  @i_fecha,
    @w_msg,         @i_org_carga)

if @@error <> 0
begin

   select @w_msg_e = 'Error al Insertar Registro cr_carga_campana_log'
end

if @i_org_carga = 'CCA'
begin
   return 0
end

return 1
go

