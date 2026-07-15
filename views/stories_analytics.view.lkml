# The name of this view in Looker is "Stories Analytics"




view: stories_analytics {
  # The sql_table_name parameter indicates the underlying database table
  # to be used for all fields in this view.
  sql_table_name: `shortcut.stories_analytics` ;;
  drill_fields: [story_id]

  # dimensions originais (geradas automaticamente a partir da tabela)

  # This primary key is the unique key for this table in the underlying database.
  dimension: story_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.story_id ;;
  }

  dimension: completed {
    type: yesno
    sql: ${TABLE}.completed ;;
  }

  dimension_group: completed {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.completed_at ;;
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: deadline {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.deadline ;;
  }

  dimension: diretoria {
    type: string
    sql: ${TABLE}.diretoria ;;
  }

  dimension: epic_id {
    type: number
    sql: ${TABLE}.epic_id ;;
  }

  dimension: epic_name {
    type: string
    sql: ${TABLE}.epic_name ;;
  }

  dimension: estimate {
    type: number
    sql: ${TABLE}.estimate ;;
  }

  dimension: objective_name {
    type: string
    sql: ${TABLE}.objective_name ;;
  }

  dimension_group: sprint_end {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.sprint_end_date ;;
  }

  dimension: sprint_id {
    type: number
    sql: ${TABLE}.sprint_id ;;
  }

  dimension: sprint_name {
    type: string
    sql: ${TABLE}.sprint_name ;;
  }

  dimension_group: sprint_start {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.sprint_start_date ;;
  }

  dimension: squad {
    type: string
    sql: ${TABLE}.squad ;;
  }

  dimension: state_name {
    type: string
    sql: ${TABLE}.state_name ;;
  }

  dimension: state_type {
    type: string
    sql: ${TABLE}.state_type ;;
  }

  dimension: story_dev_type {
    type: string
    sql: ${TABLE}.story_dev_type ;;
  }

  dimension: story_name {
    type: string
    sql: ${TABLE}.story_name ;;
  }

  dimension: user {
    type: string
    sql: ${TABLE}.user ;;
  }

  # dimensions novas (calculadas, réplica da lógica do Power BI)

  dimension: is_atrasada {
    type: yesno
    description: "História com prazo vencido e ainda não concluída"
    sql: ${deadline_raw} IS NOT NULL
         AND ${deadline_raw} < CAST(CURRENT_TIMESTAMP() AS DATE)
         AND ${state_type} <> 'done' ;;
  }

  dimension: concluida_no_prazo {
    type: yesno
    description: "História concluída dentro do prazo definido"
    sql: ${state_type} = 'done'
         AND ${deadline_raw} IS NOT NULL
         AND CAST(${completed_raw} AS DATE) <= ${deadline_raw} ;;
  }

  dimension: is_current_sprint {
    type: yesno
    description: "Réplica exata da coluna calculada do Power BI: IF(sprint_end_date >= TODAY(), 1, 0)"
    sql: ${sprint_end_raw} >= CAST(CURRENT_TIMESTAMP() AS DATE) ;;
  }

  # measures · volume geral

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  measure: total_historias {
    type: count
    label: "Total de Histórias"
  }

  measure: esforco_estimado {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço Estimado"
    value_format_name: decimal_0
  }

  # measures · status (state_type)

  measure: historias_concluidas {
    type: count
    label: "Histórias Concluídas"
    filters: [state_type: "done"]
  }

  measure: esforco_concluido {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço Concluído"
    filters: [state_type: "done"]
  }

  measure: pct_esforco_concluido {
    type: number
    label: "% Esforço Concluído"
    sql: 1.0 * ${esforco_concluido} / NULLIF(${esforco_estimado}, 0) ;;
    value_format_name: percent_0
  }

  measure: historias_em_andamento {
    type: count
    label: "Histórias Em Andamento"
    filters: [state_type: "started"]
  }

  measure: esforco_em_andamento {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço Em Andamento"
    filters: [state_type: "started"]
  }

  measure: pct_esforco_em_andamento {
    type: number
    label: "% Esforço Em Andamento"
    sql: 1.0 * ${esforco_em_andamento} / NULLIF(${esforco_estimado}, 0) ;;
    value_format_name: percent_0
  }

  measure: esforco_nao_iniciado {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço Não Iniciado"
    filters: [state_type: "unstarted"]
  }

  # measures · em validação (state_name, granularidade mais fina)

  measure: historias_em_validacao {
    type: count
    label: "Histórias Em Validação"
    filters: [state_name: "Em validação"]
  }

  measure: esforco_em_validacao {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço Em Validação"
    filters: [state_name: "Em validação"]
  }

  measure: pct_esforco_em_validacao {
    type: number
    label: "% Esforço Em Validação"
    sql: 1.0 * ${esforco_em_validacao} / NULLIF(${esforco_estimado}, 0) ;;
    value_format_name: percent_0
  }

  # measures · prazo

  measure: historias_atrasadas {
    type: count
    label: "Histórias Atrasadas"
    filters: [is_atrasada: "yes"]
  }

  measure: historias_concluidas_no_prazo {
    type: count
    label: "Histórias Concluídas No Prazo"
    filters: [concluida_no_prazo: "yes"]
  }

  measure: pct_concluidas_no_prazo {
    type: number
    label: "% Concluídas No Prazo"
    sql: 1.0 * ${historias_concluidas_no_prazo} / NULLIF(${historias_concluidas}, 0) ;;
    value_format_name: percent_0
  }

  # measures · épicos

  measure: total_epicos {
    type: count_distinct
    label: "Total de Épicos"
    sql: ${epic_name} ;;
  }

  measure: epicos_concluidos {
    type: count_distinct
    label: "Épicos Concluídos"
    sql: ${epic_name} ;;
    filters: [state_type: "done"]
  }

  measure: epicos_em_andamento {
    type: count_distinct
    label: "Épicos Em Andamento"
    sql: ${epic_name} ;;
    filters: [state_type: "started"]
  }

  measure: epicos_atrasados {
    type: count_distinct
    label: "Épicos Atrasados"
    sql: ${epic_name} ;;
    filters: [is_atrasada: "yes"]
  }

  # measures · tipo de desenvolvimento

  measure: esforco_estrutural {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço · Projeto Estruturante"
    filters: [story_dev_type: "Projeto estruturante"]
  }

  measure: esforco_bug_sustentacao {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço · Bug & Sustentação"
    filters: [story_dev_type: "Bug & Sustentação"]
  }

  measure: esforco_melhorias {
    type: sum
    sql: ${estimate} ;;
    label: "Esforço · Melhorias Rápidas"
    filters: [story_dev_type: "Melhorias rápidas"]
  }

  # measures · saúde dos dados

  measure: historias_sem_prazo {
    type: count
    label: "Histórias Sem Prazo"
    filters: [deadline_date: "NULL"]
  }

  measure: historias_sem_estimate {
    type: count
    label: "Histórias Sem Estimate"
    filters: [estimate: "NULL"]
  }

  measure: historias_sem_responsavel {
    type: count
    label: "Histórias Sem Responsável"
    filters: [user: "NULL"]
  }

  measure: historias_dados_ok {
    type: number
    label: "Histórias Com Dados OK"
    sql: ${total_historias} - ${historias_sem_prazo} - ${historias_sem_estimate} - ${historias_sem_responsavel} ;;
  }

  measure: pct_campos_preenchidos {
    type: number
    label: "% Campos Preenchidos"
    sql: 1.0 * ${historias_dados_ok} / NULLIF(${total_historias}, 0) ;;
    value_format_name: percent_0
  }

  # measures · sprint atual (réplica de [Sprint Atual ID]: MAX(sprint_id)
  # entre os sprints cujo sprint_end_date ainda não passou)

  measure: sprint_atual_id {
    type: max
    label: "Sprint Atual ID"
    sql: ${sprint_id} ;;
    filters: [is_current_sprint: "yes"]
  }

  measure: sprint_atual_nome {
    type: string
    label: "Sprint Atual · Nome"
    sql: (ARRAY_AGG(CASE WHEN ${is_current_sprint} THEN ${sprint_name} END IGNORE NULLS ORDER BY ${sprint_id} DESC LIMIT 1))[SAFE_OFFSET(0)] ;;
  }

  measure: sprint_atual_inicio {
    type: string
    label: "Sprint Atual · Início"
    sql: FORMAT_DATE("%d %b", (ARRAY_AGG(CASE WHEN ${is_current_sprint} THEN ${sprint_start_raw} END IGNORE NULLS ORDER BY ${sprint_id} DESC LIMIT 1))[SAFE_OFFSET(0)]) ;;
  }

  measure: sprint_atual_fim_data {
    type: string
    label: "Sprint Atual · Data Fim (interna)"
    hidden: yes
    sql: (ARRAY_AGG(CASE WHEN ${is_current_sprint} THEN ${sprint_end_raw} END IGNORE NULLS ORDER BY ${sprint_id} DESC LIMIT 1))[SAFE_OFFSET(0)] ;;
  }

  measure: sprint_atual_fim {
    type: string
    label: "Sprint Atual · Fim"
    sql: FORMAT_DATE("%d %b", ${sprint_atual_fim_data}) ;;
  }

  measure: sprint_atual_dias_restantes {
    type: number
    label: "Sprint Atual · Dias Restantes"
    sql: DATE_DIFF(${sprint_atual_fim_data}, CAST(CURRENT_TIMESTAMP() AS DATE), DAY) ;;
  }

  measure: html_cabecalho_coordenador {

    type: number
    label: "HTML · Cabeçalho Coordenador"
    sql: COALESCE(${sprint_atual_dias_restantes}, -999) ;;
    html:
    <div style="width:100%;overflow:hidden;font-family:'Segoe UI',sans-serif;background:#fff;border:1px solid #E0DFD8;border-radius:12px;padding:20px 32px;">
      <div style="float:left;text-align:left;">
        <img src="https://static.shortcut.com/images/common-room/shortcut-community.png" style="width:48px;height:48px;vertical-align:middle;margin-right:24px;" alt="Shortcut" />
        <span style="font-size:20px;font-weight:600;color:#1a1a18;vertical-align:middle;">Sprint · Atividades priorizadas</span>
        <div style="font-size:15px;color:#888780;margin-top:6px;margin-left:72px;">Time de Plataforma · {{ stories_analytics.sprint_atual_nome._rendered_value }}</div>
      </div>
      <div style="float:right;text-align:right;">
        <div style="font-size:15px;font-weight:600;color:#1a1a18;">{{ stories_analytics.sprint_atual_inicio._rendered_value }} – {{ stories_analytics.sprint_atual_fim._rendered_value }}</div>
        {% if value == -999 %}
          <div style="font-size:13px;color:#888780;margin-top:3px;font-weight:600;">Sem sprint identificado</div>
        {% elsif value > 5 %}
          <div style="font-size:13px;color:#1a1a18;margin-top:3px;font-weight:600;">{{ value }} dias restantes</div>
        {% elsif value > 1 %}
          <div style="font-size:13px;color:#F68300;margin-top:3px;font-weight:600;">{{ value }} dias restantes</div>
        {% elsif value == 1 %}
          <div style="font-size:13px;color:#F68300;margin-top:3px;font-weight:600;">Último dia</div>
        {% elsif value == 0 %}
          <div style="font-size:13px;color:#E11515;margin-top:3px;font-weight:600;">Encerra hoje</div>
        {% else %}
          <div style="font-size:13px;color:#E11515;margin-top:3px;font-weight:600;">Sprint encerrada</div>
        {% endif %}
      </div>
    </div>
  ;;
  }

  # measures · kpi cards (linha de esforço/andamento/validação/concluído)

  measure: kpi_esforco_estimado {
    type: number
    label: "KPI · Esforço Estimado"
    sql: ${esforco_estimado} ;;
    html:
      <div style="background:#fff;border:1px solid #E0DFD8;border-radius:10px;padding:14px 16px;font-family:'Segoe UI',sans-serif;overflow:hidden;">
        <div style="float:right;width:28px;height:28px;background:#EAECEE;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#4F5E69;">⏱</div>
        <div style="font-size:12px;color:#888780;">Esforço estimado</div>
        <div style="font-size:26px;font-weight:600;color:#4F5E69;margin-top:4px;">{{ rendered_value }} pts</div>
        <div style="font-size:12px;color:#888780;margin-top:2px;">{{ stories_analytics.total_historias._rendered_value }} histórias</div>
      </div>
    ;;
  }

  measure: kpi_em_andamento {
    type: number
    label: "KPI · Em Andamento"
    sql: ${esforco_em_andamento} ;;
    html:
      <div style="background:#fff;border:1px solid #E0DFD8;border-radius:10px;padding:14px 16px;font-family:'Segoe UI',sans-serif;overflow:hidden;">
        <div style="float:right;width:28px;height:28px;background:#FEF0DC;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#F68300;">↻</div>
        <div style="font-size:12px;color:#888780;">Em andamento</div>
        <div style="font-size:26px;font-weight:600;color:#F68300;margin-top:4px;">{{ rendered_value }} pts</div>
        <div style="font-size:12px;color:#888780;margin-top:2px;">{{ stories_analytics.historias_em_andamento._rendered_value }} histórias · {{ stories_analytics.pct_esforco_em_andamento._rendered_value }}</div>
      </div>
    ;;
  }

  measure: kpi_em_validacao {
    type: number
    label: "KPI · Em Validação"
    sql: ${esforco_em_validacao} ;;
    html:
      <div style="background:#fff;border:1px solid #E0DFD8;border-radius:10px;padding:14px 16px;font-family:'Segoe UI',sans-serif;overflow:hidden;">
        <div style="float:right;width:28px;height:28px;background:#FFF4D6;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#FBA600;">✓</div>
        <div style="font-size:12px;color:#888780;">Em validação</div>
        <div style="font-size:26px;font-weight:600;color:#FBA600;margin-top:4px;">{{ rendered_value }} pts</div>
        <div style="font-size:12px;color:#888780;margin-top:2px;">{{ stories_analytics.historias_em_validacao._rendered_value }} histórias · {{ stories_analytics.pct_esforco_em_validacao._rendered_value }}</div>
      </div>
    ;;
  }

  measure: kpi_concluido {
    type: number
    label: "KPI · Concluído"
    sql: ${esforco_concluido} ;;
    html:
      <div style="background:#fff;border:1px solid #E0DFD8;border-radius:10px;padding:14px 16px;font-family:'Segoe UI',sans-serif;overflow:hidden;">
        <div style="float:right;width:28px;height:28px;background:#D6F4F3;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#00AFAA;">✓</div>
        <div style="font-size:12px;color:#888780;">Concluído</div>
        <div style="font-size:26px;font-weight:600;color:#00AFAA;margin-top:4px;">{{ rendered_value }} pts</div>
        <div style="font-size:12px;color:#888780;margin-top:2px;">{{ stories_analytics.historias_concluidas._rendered_value }} histórias · {{ stories_analytics.pct_esforco_concluido._rendered_value }}</div>
      </div>
    ;;
  }

  measure: kpi_concluido_no_prazo {
    type: number
    label: "KPI · Concluído No Prazo"
    sql: ${pct_concluidas_no_prazo} ;;
    html:
      <div style="background:#fff;border:1px solid #E0DFD8;border-radius:10px;padding:14px 16px;font-family:'Segoe UI',sans-serif;overflow:hidden;">
        {% if value >= 0.8 %}
          <div style="float:right;width:28px;height:28px;background:#D6F4F3;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#00AFAA;">✓</div>
          <div style="font-size:12px;color:#888780;">Concluído no prazo</div>
          <div style="font-size:26px;font-weight:600;color:#00AFAA;margin-top:4px;">{{ rendered_value }}</div>
        {% elsif value >= 0.5 %}
          <div style="float:right;width:28px;height:28px;background:#FEF0DC;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#F68300;">✓</div>
          <div style="font-size:12px;color:#888780;">Concluído no prazo</div>
          <div style="font-size:26px;font-weight:600;color:#F68300;margin-top:4px;">{{ rendered_value }}</div>
        {% else %}
          <div style="float:right;width:28px;height:28px;background:#FDECEA;border-radius:8px;text-align:center;line-height:28px;font-size:14px;color:#E11515;">✓</div>
          <div style="font-size:12px;color:#888780;">Concluído no prazo</div>
          <div style="font-size:26px;font-weight:600;color:#E11515;margin-top:4px;">{{ rendered_value }}</div>
        {% endif %}
        <div style="font-size:12px;color:#888780;margin-top:2px;">{{ stories_analytics.historias_concluidas_no_prazo._rendered_value }} de {{ stories_analytics.historias_concluidas._rendered_value }} histórias</div>
      </div>
    ;;
  }

  # ----- Sets of fields for drilling ------
  set: detail {
    fields: [
      story_id,
      story_name,
      epic_name,
      sprint_name,
      state_name,
      objective_name
    ]
  }
}
