/************************************************************************/
/*   Archivo:            sp_consulta_pago_solidario.sp                  */
/*   Stored procedure:   sp_consulta_pago_solidario                     */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Milton Custode                                 */
/*   Fecha de escritura: 22-Mayo 2017                                   */
/************************************************************************/
/*          IMPORTANTE                                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA',representantes exclusivos para el Ecuador de la            */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de MACOSA o su representante                  */
/************************************************************************/
/*          PROPOSITO                                                   */
/*  Genera archivo de pagos pendiente, sp para pantalla de pago         */
/*  solidario                                                           */
/************************************************************************/
/*                               OPERACIONES                            */
/*   OPER. OPCION                     DESCRIPCION                       */
/*     S    C       Cabecera la pantalla de Pago solidario              */
/*     S    D       Detalle de los pagos solidario                      */
/*     G            Genera el archivo en Visual B                       */
/************************************************************************/
/*          MODIFICACIONES                                              */
/*  FECHA           AUTOR           RAZON                               */
/*  22/Mayo/2017    M. Custode      Emision Inicial                     */
/*  09/Junio/2017   P. Ortiz        Correccion de extraccion del Plazo  */
/************************************************************************/
use cob_cartera
go
if object_id ('sp_consulta_pago_solidario') is not null
   drop proc sp_consulta_pago_solidario
go
create proc sp_consulta_pago_solidario(
 @s_ssn             int             = null,
 @s_user            login           = null,
 @s_term            varchar(32)     = null,
 @s_date            datetime        = null,
 @s_sesn            int             = null,
 @s_culture         varchar(10)     = null,
 @s_srv             varchar(30)     = null,
 @s_lsrv            varchar(30)     = null,
 @s_ofi             smallint        = null,
 @s_rol             smallint        = null,
 @s_org_err         char(1)         = null,
 @s_error           int             = null,
 @s_sev             tinyint         = null,
 @s_msg             descripcion     = null,
 @s_org             char(1)         = null,
 @t_debug           char(1)         = 'N',
 @t_file            varchar(10)     = null,
 @t_from            varchar(32)     = null,
 @t_trn             int             = null,
 @t_show_version    bit             = 0,
 @i_operacion        char(1)        = null,
 @i_fecha_proceso    datetime       = null,
 @i_archivo          varchar(255)   = null,
 @i_banco_grupal     cuenta         = null,
 @i_grupo            int            = null,
 @i_opcion           char(1)        = null,
 @i_dividendo        int            = null,
 --Visual B
 @i_param1           varchar(255)   = null, -- opcion
 @i_param2           varchar(255)   = null, -- fecha proceso
 @i_param3           varchar(255)   = null  -- nombre archivo
)
as declare
    @w_error         int,
    @w_sp_name       descripcion,
    @w_operacion     int,
    @w_grupo         int,
    @w_dividendo     int,
    @w_return        int,
    @w_path_sapp     varchar(200),
    @w_sapp          varchar(200),
    @w_path          varchar(200),
    @w_msg           varchar(200),
    @w_comando       varchar(2000),
    @w_bd            varchar(200),
    @w_tabla         varchar(200),
    @w_destino       varchar(200),
    @w_errores       varchar(200),
    @w_sep           varchar(1),
    @w_fecha_arch    varchar(10),
    @w_est_ing           char(1),
    @w_est_env           char(1),
    @w_est_rcp           char(1),
    @w_est_apl           char(1),
    @w_hora              char(6),
    @w_plazo_inf	VARCHAR(64),
    @w_tasa			float


select @w_sp_name        = 'sp_consulta_pago_solidario'

create table #operacion (
       grupo               int            null,
       opegrupal           cuenta         null,
       descripcion_gp      varchar(100)   null,
       ciclo_gp            int            null,
       operacion           int,
       banco               cuenta         null, 
       fecha_solicitud     datetime       null,
       oficial             int            null,
       descripOficial      varchar(30)    null,
       oficina             int            null,
       descripOficini      varchar(30)    null,
       tipo_credito        varchar(30)    null,
       monto_grupal        money          null,
       tasa                float          null,
       plazo1              varchar(10)    null,
       plazo2              varchar(10)    null,
       saldo_liquid        money          default 0,
       num_couta           int            null,  --coutas vencidas
       num_couta_vig       int            null,
       num_couta_max       int            null,
       fecha_vencimiento   datetime       null,
       monto_couta         money          null,
       debito              char(1)        default 'S',
       cliente             int            null,
       nombre              varchar(100)   null,
       mon_solidario       int            default 0 )
       
create table #dividendo (
      ope_div     int,
      tot_div     int,
      div_vig     int      null,
      div_max     int      null,
      monto_div   money    null,
      fecha       datetime null)
      
if @i_operacion = 'S'
begin
  if @i_opcion = 'C'
  begin --Inicio de opcion C
  --actualizo las suma de la operacion grupal
    exec sp_actualiza_grupal
      @i_desde_cca   = 'N',
      @i_banco       =  @i_banco_grupal

    select @w_operacion = op_operacion , @w_grupo = op_cliente from ca_operacion where op_banco = @i_banco_grupal
    
    select @w_plazo_inf = td_descripcion
         from cob_cartera..ca_tdividendo
         where td_estado = 'V'
         and td_tdividendo = (select op_tplazo from ca_operacion where op_banco = @i_banco_grupal)
         order by td_tdividendo
         
    
	SELECT @w_tasa = ro_porcentaje FROM cob_cartera..ca_rubro_op
	WHERE ro_concepto = 'INT'
	AND ro_operacion = @w_operacion


    
    --Saco los datos basicos de la operacion grupal padre
    insert into #operacion 
    (operacion,    grupo,      opegrupal, monto_grupal,  fecha_solicitud,  oficial,     oficina,    tipo_credito,  tasa,
     plazo1,       plazo2 )
    select 
    op_operacion,  op_cliente, op_banco, op_monto,       op_fecha_ini,     op_oficial,  op_oficina, op_toperacion, @w_tasa, 
    op_plazo,     @w_plazo_inf
    from ca_operacion where op_banco = @i_banco_grupal
    
    --actualizo la descripcion del tipo de operacion
    update #operacion 
    set tipo_credito = tipo_credito + ' - ' + c.valor
    from cobis..cl_tabla t, cobis..cl_catalogo c
    where t.codigo = c.tabla
      and t.tabla  = 'ca_toperacion'
      and c.codigo = tipo_credito
      
    --nombre de grupo y numero de ciclos
    update #operacion
     set   descripcion_gp = gr_nombre,
           ciclo_gp       = gr_num_ciclo
    from cobis..cl_grupo
    where grupo= gr_grupo

    --actualización del oficial y oficina
    update #operacion
    set descripOficial = (select fu_nombre from cobis..cc_oficial,cobis..cl_funcionario 
                            where oc_funcionario = fu_funcionario and oc_oficial = oficial)

    update #operacion
     set descripOficini = (select of_nombre from cobis..cl_oficina where of_oficina = oficina)

    --dividendo vencido
    insert into #dividendo
    select  @w_operacion, count(di_dividendo), null, null, null, null
    from ca_dividendo
    where di_operacion = @w_operacion 
      and di_estado = 2
   
    --Dividendo vigente
    update #dividendo
    set div_vig  = (select top 1 cp_dividendo
    from ca_control_pago, #operacion
    where cp_referencia_grupal = opegrupal
    and cp_estado = 1)

    --Saldo vencido hasta el dividendo vigente 
    update #dividendo
    set monto_div  = (select sum(cp_saldo_vencido)
    from ca_control_pago, #operacion
    where cp_referencia_grupal = opegrupal
    and cp_estado = 1)
   
    --div vigente proximo vencimiento
    update #dividendo
     set fecha = di_fecha_ven
    from ca_dividendo
    where ope_div = di_operacion
    and di_estado = 1

    --max dividendo
    update #dividendo
    set div_max  = (select max(di_dividendo)
    from ca_dividendo
    where ope_div = di_operacion)

    update #operacion
    set num_couta         = tot_div,
      fecha_vencimiento   = fecha,
      monto_couta         = monto_div,
      num_couta_vig       = div_vig,
      num_couta_max       = div_max
    from #dividendo
    where ope_div = operacion

    drop table #dividendo
      
    select
        'codGrupo'           = grupo,
        'descGrupo'          = descripcion_gp,
        'ciclo'              = ciclo_gp,
        'fechaIni'           = convert(varchar(10),fecha_solicitud, 101), 
        'asesor'             = descripOficial,
        'sucursal'           = descripOficini, 
        'tipoCred'           = tipo_credito,
        'montoGrupal'        = monto_grupal,
        'tasa'               = tasa,
        'plazo'              = plazo1 + ' ' + plazo2,
        'saldoGarLiquida'    = saldo_liquid,
        'cuotaVencidas'      = num_couta,
        'fechaProxVcto'      = convert(varchar(10),fecha_vencimiento, 101),
        'montoCubrirPgSolid' = isnull(monto_couta,0),
        'pagDebito'          = debito,
        'coutaVigente'       = num_couta_vig,
        'coutaMaxima'        = num_couta_max
    from #operacion
     goto fin
    end --fin opcion C
    
    if @i_opcion = 'D'
    begin
        select 
         'cliente'               = op_cliente,
         'clienteNombre'         = op_nombre,
         'valorCuota'            = cp_cuota_pactada,
         'montoPagado'           = cp_pago,
         'montoVencido'          = cp_saldo_vencido,
         'montoSolidario'        = cp_pago_solidario,
         'dividendo'             = cp_dividendo,
         'operacion'             = cp_operacion
        from cob_cartera..ca_operacion, ca_control_pago
    where cp_grupo            = @i_grupo
         and cp_dividendo_grupal  = @i_dividendo
         and cp_referencia_grupal = @i_banco_grupal
         and cp_operacion  = op_operacion
     goto fin
    end
end
if @i_param1 = 'G'
begin
   select
    @i_fecha_proceso    = convert(datetime, @i_param2, 101),
    @i_archivo          = isnull(@i_param3, 'COBRANZA')

   --operaciones que tienes dividendos en estado 2
   insert into #operacion (operacion)
   select di_operacion from ca_dividendo, cob_credito..cr_tramite_grupal
   where di_operacion = tg_operacion
   and tg_monto > 0
   and di_estado = 2
   group by di_operacion
   
   --Datos basicos de las operaciones hijas
   update #operacion 
   set operacion        = op_operacion, 
       banco            = op_banco, 
       fecha_solicitud  = op_fecha_ini, 
       oficial          = op_oficial, 
       oficina          = op_oficina, 
       tipo_credito     = op_toperacion, 
       tasa             = op_tasa_cap, 
       plazo1           = op_plazo, 
       cliente          = op_cliente
   from ca_operacion 
   where operacion = op_operacion
   
   --# de grupo y operacion grupal
   update #operacion
   set grupo      = tg_grupo,
       opegrupal  = tg_referencia_grupal
   from cob_credito..cr_tramite_grupal
   where tg_operacion = operacion

   --Montos por operacion hija
   update #operacion
   set monto_grupal = op_monto 
   from ca_operacion 
   where opegrupal = op_banco
    
   --nombre de grupo y numero de ciclos
   update #operacion
   set   descripcion_gp = gr_nombre,
         ciclo_gp       = gr_num_ciclo
   from cobis..cl_grupo
   where grupo= gr_grupo
   
   --Nombres de los clientes
   update #operacion
   set nombre =en_nomlar
   from cobis..cl_ente
   where cliente = en_ente

   --Todos los dividendos vencidos
   insert into #dividendo
   select di_operacion, count(di_dividendo), null, null, null, null
   from ca_dividendo, #operacion
   where operacion = di_operacion
   and di_estado = 2
   group by di_operacion
   
   --Fecha del proximo vencimiento
   update #dividendo
   set fecha = di_fecha_ven
   from ca_dividendo D
   where D.di_operacion = ope_div
   and D.di_estado = 1

   --Suma de los valores vencidos
   select di_operacion, sum(am_cuota) 'suma'
   into #monto
   from ca_amortizacion, ca_dividendo, #dividendo
   where am_operacion = di_operacion
   and ope_div = di_operacion
   and am_dividendo = di_dividendo
   and di_estado = 2
   group by di_operacion
    
   --Actualizo la suma de lo vencidos a la tb de Dividendos
   update #dividendo
   set monto_div =  isnull(suma,0)
   from #monto
   where ope_div = di_operacion

   drop table #monto
   
   update #operacion
   set num_couta = tot_div,
       fecha_vencimiento = fecha,
       monto_couta = monto_div
   from #dividendo
   where ope_div = operacion
   
   drop table #dividendo

   --Generacion del archivo
   select @w_path_sapp = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'S_APP'

   if @w_path_sapp is null
   begin
      select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
      select @w_return = 724607
      goto errores
    end

   select @w_path  = pp_path_destino
   from cobis..ba_path_pro
   where pp_producto  = 7

   select @w_sapp      = @w_path_sapp + 's_app'

   select
      @w_bd       = 'cob_cartera',
      @w_tabla    = 'tmp_cadena',
      @w_sep      = '|' --char(9)  -- tabulador

   select @w_fecha_arch = convert(varchar, @i_fecha_proceso, 112)
   select @w_hora = substring(convert(varchar, getdate(), 108), 1,2)+
 substring(convert(varchar, getdate(), 108), 4,2)+
                    substring(convert(varchar, getdate(), 108), 7,2)

   select
      @w_destino  = @i_archivo + '_' + @w_fecha_arch + '.txt',
      @w_errores  = @i_archivo + '_' + @w_fecha_arch + '_' + @w_hora + '.err'
   
   truncate table tmp_cadena

   insert into tmp_cadena
   select 
      convert(varchar,grupo)
      + @w_sep + descripcion_gp
      + @w_sep + convert(varchar,ciclo_gp)
      + @w_sep + isnull(convert(varchar,fecha_solicitud, 101),'null')
      + @w_sep + convert(varchar,oficial)
      + @w_sep + convert(varchar,oficina) 
      + @w_sep + isnull(tipo_credito, 'null')
      + @w_sep + convert(varchar,monto_grupal)
      + @w_sep + isnull(convert(varchar,tasa),'0')
      + @w_sep + isnull(plazo1, 'null')
      + @w_sep + isnull(convert(varchar,saldo_liquid),'0')
      + @w_sep + isnull(convert(varchar,num_couta),'0') 
      + @w_sep + isnull(convert(varchar,fecha_vencimiento,101),'null') 
      + @w_sep + isnull(convert(varchar,monto_couta),'0') 
      + @w_sep + debito
      + @w_sep + isnull(convert(varchar,cliente),'null')
      + @w_sep + isnull(nombre,'null')
      + @w_sep + isnull(convert(varchar,mon_solidario),'0')
   from #operacion
 
   select  @w_comando = @w_sapp + ' bcp -auto -login ' + @w_bd + '..' + @w_tabla + ' out ' + @w_path+@w_destino + ' -b5000 -c -e' + @w_path+@w_errores + ' -t"'+@w_sep + '" -config ' + @w_sapp + '.ini'

   print ' COMANDO = '+ @w_comando
   exec @w_return = xp_cmdshell @w_comando
   if @w_return <> 0 begin
      select @w_msg = 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_return)
      goto errores
   end
   
   goto fin
end
--Control errores
errores:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error
fin:
   return 0

go