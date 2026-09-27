let model = null;
let table = 'Quest';
let index = 0;
let query = '';
let dirty = false;
let eventSummary = {rows: [], total: 0, current_type_count: 0};

const names = {
  EventType: '事件类型', EventParam: '事件参数', QuestType: '任务类型', Quest: '任务配置',
  QuestCondition: '条件配置', QuestNode: '流程节点',
  DialogueLine: '对话组', LegacyMap: '迁移审计',
};
const navKeys = ['Quest', 'QuestType', 'EventType', 'DialogueLine', 'LegacyMap'];
const nodeNames = { Start: '开始', Dialogue: '播放对白', WaitEvent: '等待事件', CheckState: '检查状态', Complete: '完成' };
const dialoguePhases = [
  ['before_accept', '未接取前对话'],
  ['accepted_incomplete', '已接未完成对话'],
  ['completed_unclaimed', '已完成未领取时对话'],
];
const numeric = new Set(['legacy_group', 'min_level', 'target_value', 'filter_value', 'line_order', 'position', 'scale', 'speed', 'delay', 'show_skip']);
const $ = id => document.getElementById(id);
const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
const dialogueGroups = () => [...new Set(model.records.DialogueLine.map(line => String(line.sequence_id)))].map(groupId => {
  const lines = model.records.DialogueLine.filter(line => String(line.sequence_id) === groupId);
  return {sequence_id: groupId, name: `${lines.length} 句`, search_text: lines.map(line => `${line.speaker} ${line.text}`).join(' ')};
}).sort((a, b) => a.sequence_id.localeCompare(b.sequence_id, 'zh-CN', {numeric: true}));
const rows = () => table === 'DialogueLine' ? dialogueGroups() : model.records[table];
const isAudit = () => table === 'LegacyMap';
const steamEvents = () => model.records.EventType.filter(row => row.steam_scope !== '屏蔽');
const candidateEvents = () => model.records.EventType.filter(row => row.steam_scope === '纳入');
const selectableEvents = () => model.records.EventType.filter(row =>
  row.steam_scope === '纳入' && ['草稿', '已验收'].includes(row.publish_state));
function eventOptions(value) {
  const groups = [
    ['已定义 · 可配置', selectableEvents(), false],
    ['待定义 · 可选入任务草稿', candidateEvents().filter(row => row.publish_state === '待定义'), false],
    ['入口待核对 · 暂不可选', steamEvents().filter(row => row.steam_scope === '待核对'), true],
  ];
  return groups.map(([label, events, disabled]) => `<optgroup label="${esc(label)}">${events.map(event =>
    `<option value="${esc(event.event_key)}" ${event.event_key === value ? 'selected' : ''} ${disabled ? 'disabled' : ''}>${esc(event.name)}（${esc(event.event_key)}）${event.publish_state === '待定义' ? ' · 参数待定义' : ''}</option>`
  ).join('')}</optgroup>`).join('');
}

function status(message, error = false) {
  $('status').className = 'banner' + (error ? ' error' : '');
  $('status').textContent = message;
}

function identity(row) {
  if (table === 'EventParam') return `${row.event_key} · ${row.name || row.param_key}`;
  if (table === 'LegacyMap') return `${row.source} · ${row.legacy_id}`;
  return String(row.event_key || row.type_key || row.quest_id || row.condition_id || row.node_id || row.sequence_id || '新记录');
}

function caption(row) {
  return String(row.name || row.text || row.node_type || row.note || row.record_kind || '').slice(0, 85);
}

function render() {
  if (!model) return;
  const definitions = selectableEvents().length;
  $('scope').innerHTML = `<span>任务类型 <b>${model.records.QuestType.length}</b> 种</span><span>Steam 事件候选 <b>${steamEvents().length}</b> / 旧编号 ${model.records.EventType.length}</span><span>已写参数合同 <b>${definitions}</b> 种</span><span>已导入任务 <b>${model.records.Quest.length}</b></span>`;
  $('nav').innerHTML = navKeys.map((key, i) =>
    `${i === 4 ? '<div class="group">只读迁移资料</div>' : ''}<button class="${table === key ? 'on' : ''}" data-table="${key}"><span>${names[key]}</span><b>${key === 'EventType' ? steamEvents().length : key === 'DialogueLine' ? dialogueGroups().length : model.records[key].length}</b></button>`
  ).join('');
  document.querySelectorAll('[data-table]').forEach(button => button.onclick = () => {
    table = button.dataset.table;
    index = 0;
    query = '';
    $('search').value = '';
    render();
  });
  $('listTitle').textContent = table === 'EventType'
    ? `Steam 事件候选 · ${steamEvents().length} 种（已屏蔽 ${rows().length - steamEvents().length} 种仅在审计页）`
    : table === 'DialogueLine' ? `对话组 · ${rows().length} 组 / ${model.records.DialogueLine.length} 句`
    : `${names[table]} · ${rows().length} 条`;
  $('add').textContent = table === 'DialogueLine' ? '新建对话组' : '新增配置';
  $('add').disabled = isAudit() || table === 'EventType' || table === 'QuestType' || table === 'QuestNode';
  $('remove').disabled = isAudit() || table === 'EventType' || table === 'QuestType' || table === 'QuestNode';
  const matches = rows().map((row, rowIndex) => [row, rowIndex]).filter(([row]) =>
    (table !== 'EventType' || row.steam_scope !== '屏蔽') &&
    (!query || JSON.stringify(row).toLowerCase().includes(query)));
  const definedHtml = matches.slice(0, 150).map(([row, rowIndex]) =>
    `<button class="${rowIndex === index ? 'on' : ''}" data-index="${rowIndex}"><b>${esc(identity(row))} · ${esc(caption(row))}</b><small>${table === 'EventType' ? `${esc(row.steam_scope)} · ${esc(row.publish_state)} · daily ${eventSummary.rows.find(item => item.legacy_key === row.event_key)?.current_task_count || 0} / 七日 ${eventSummary.rows.find(item => item.legacy_key === row.event_key)?.seven_task_count || 0} 条引用` : table === 'Quest' ? `${esc(model.records.QuestType.find(item => item.type_key === row.quest_type)?.name || '待分类')} · ${esc(row.repeat_cycle)} · ${esc(row.entry)}` : esc(caption(row))}</small></button>`
  ).join('');
  $('list').innerHTML = definedHtml + (matches.length > 150 ? '<p class="hint">只显示前 150 条，请用搜索定位其余记录。</p>' : '');
  document.querySelectorAll('[data-index]').forEach(button => button.onclick = () => {
    index = Number(button.dataset.index);
    renderForm();
    document.querySelectorAll('[data-index]').forEach(item => item.classList.toggle('on', item === button));
  });
  renderForm();
  $('foot').textContent = model.workbook + (dirty ? ' · 有未保存修改' : ' · 已保存');
}

function selection(key, value, items) {
  return `<select data-key="${key}">${items.map(([option, text]) =>
    `<option value="${esc(option)}" ${String(option) === String(value) ? 'selected' : ''}>${esc(text)}</option>`
  ).join('')}</select>`;
}

function fieldInput(key, value, row) {
  if (key === 'legacy_group' && table === 'Quest') return `<input data-key="${key}" value="${esc(value)}" disabled>`;
  if (key === 'quest_type' && table === 'Quest') {
    return selection(key, value, model.records.QuestType.map(item => [item.type_key, item.name]));
  }
  if (key === 'event_key' && table === 'EventParam') {
    return selection(key, value, model.records.EventType.map(event => [event.event_key, event.name]));
  }
  if (key === 'event_key' && table === 'QuestCondition') {
    return `<select data-key="${key}">${eventOptions(value)}</select>`;
  }
  if (key === 'filter_param' && table === 'QuestCondition') {
    const params = model.records.EventParam.filter(param =>
      param.event_key === row.event_key && param.param_kind === '筛选参数');
    return selection(key, value, [['', '不筛选'], ...params.map(param => [param.param_key, param.name])]);
  }
  if (key === 'publish_state') return selection(key, value, table === 'EventType'
    ? [['待定义', '待定义（不可配置）'], ['草稿', '参数已定义（仅预览）'], ['已验收', '已验收（可正式导出）']]
    : [['草稿', '草稿（仅预览）'], ['已验收', '已验收（可正式导出）']]);
  if (key === 'steam_scope') return selection(key, value, [['纳入', '纳入当前 Steam 范围'], ['屏蔽', '已屏蔽'], ['待核对', '入口待核对']]);
  if (key === 'node_type') return selection(key, value, Object.entries(nodeNames));
  if (key === 'operator' || key === 'filter_operator') {
    return selection(key, value, [['', '不设置'], ['>=', '大于等于'], ['=', '等于'], ['<=', '小于等于'], ['>', '大于'], ['<', '小于']]);
  }
  if (key === 'param_kind') return selection(key, value, [['计数增量', '增加任务进度'], ['筛选参数', '筛选事件'], ['状态值', '读取当前状态']]);
  if (key === 'data_type') return selection(key, value, [['整数', '整数'], ['文本', '文本'], ['布尔', '是 / 否']]);
  if (key === 'phase') return selection(key, value, [['完成', '完成条件'], ['触发', '触发条件']]);
  if (key === 'scope') return selection(key, value, [['', '未核对'], ['角色', '角色'], ['账号', '账号'], ['帮派', '帮派']]);
  if (key === 'repeat_cycle') return selection(key, value, [['一次', '一次'], ['每日', '每日'], ['累计', '累计']]);
  if (key === 'count_start') return selection(key, value, [['周期开始', '本次周期开始'], ['接取任务', '接取任务时'], ['角色创建', '角色创建时']]);
  if (key === 'logic_group') return selection(key, value, [['AND', '全部满足'], ['OR', '满足其一']]);
  const long = ['trigger_point', 'description', 'allowed_values', 'reward_ref', 'note', 'text'].includes(key);
  if (long && String(value).length > 48) return `<textarea data-key="${key}">${esc(value)}</textarea>`;
  return `<input data-key="${key}" ${numeric.has(key) ? 'type="number"' : ''} value="${esc(value)}">`;
}

function renderForm() {
  let workflowArea = $('workflowArea');
  if (!workflowArea) {
    workflowArea = document.createElement('div');
    workflowArea.id = 'workflowArea';
    $('form').before(workflowArea);
  }
  workflowArea.replaceChildren();
  const row = rows()[index];
  $('formTitle').textContent = row ? `${names[table]} · ${identity(row)}` : `暂无${names[table]}`;
  if (!row) {
    $('form').innerHTML = '<p class="hint">点击“新增配置”开始填写。</p>';
    $('previewArea').innerHTML = '';
    return;
  }
  if (table === 'DialogueLine') {
    renderDialogueGroup(row);
    return;
  }
  const fieldHtml = ([key, title]) => {
    const value = row[key] ?? '';
    const wide = ['trigger_point', 'description', 'scope_reason', 'allowed_values', 'reward_ref', 'note', 'text'].includes(key);
    const input = fieldInput(key, value, row);
    return `<label class="${wide ? 'wide' : ''}"><span>${esc(title)}</span>${input}</label>`;
  };
  if (table === 'Quest') {
    const advanced = new Set(['quest_id', 'legacy_group', 'reward_ref']);
    $('form').innerHTML = model.schema.Quest.filter(([key]) => !advanced.has(key)).map(fieldHtml).join('') +
      `<details class="advanced"><summary>高级字段 · 旧编号与奖励引用</summary><div class="advanced-grid">${model.schema.Quest.filter(([key]) => advanced.has(key)).map(fieldHtml).join('')}</div></details>`;
  } else {
    $('form').innerHTML = model.schema[table].map(fieldHtml).join('');
  }
  document.querySelectorAll('#form [data-key]').forEach(input => {
    input.disabled = isAudit() || (table === 'Quest' && ['quest_id', 'legacy_group'].includes(input.dataset.key)) ||
      (table === 'EventType' && ['event_key', 'steam_scope', 'scope_reason'].includes(input.dataset.key)) ||
       (table === 'QuestType' && input.dataset.key === 'type_key') || table === 'QuestNode';
    input.oninput = () => {
      const key = input.dataset.key;
      const value = input.value;
      row[key] = numeric.has(key) && value !== '' && Number.isFinite(Number(value)) ? Number(value) : value;
      if (table === 'Quest' && key === 'quest_type') {
        row.repeat_cycle = value === 'daily' ? '每日' : value === 'cumulative' ? '累计' : '一次';
        for (const condition of model.records.QuestCondition.filter(item => item.quest_id === row.quest_id)) {
          condition.count_start = value === 'daily' ? '周期开始' : value === 'cumulative' ? '角色创建' : '接取任务';
        }
        renderForm();
      }
      if (table === 'QuestCondition' && key === 'event_key') {
        row.filter_param = '';
        row.filter_operator = '';
        row.filter_value = '';
        renderForm();
      }
      dirty = true;
      $('foot').textContent = model.workbook + ' · 有未保存修改';
      renderPreview(row);
    };
  });
  renderPreview(row);
}

function conditionText(condition) {
  const event = model.records.EventType.find(item => item.event_key === condition.event_key);
  const param = model.records.EventParam.find(item =>
    item.event_key === condition.event_key && item.param_key === condition.filter_param);
  const filterText = param ? `，仅统计${param.name}${condition.filter_operator}${condition.filter_value}` : '';
  if (event?.publish_state === '待定义') {
    return `${event.name}，目标${condition.operator || '>='}${condition.target_value || '?'}（计数和参数待定义）`;
  }
  const valueMode = model.records.EventParam.some(item => item.event_key === condition.event_key && item.param_kind === '状态值');
  return `${event?.name || '未选事件'}${filterText}，${valueMode ? '当前值' : '累计'}${condition.operator || '>='}${condition.target_value || '?'}${event?.unit || ''}`;
}

function renderPreview(row) {
  $('workflowArea').replaceChildren();
  if (table === 'EventType') {
    const source = eventSummary.rows.find(item => item.legacy_key === row.event_key);
    const params = model.records.EventParam.filter(item => item.event_key === row.event_key);
    const linkedConditions = model.records.QuestCondition.filter(item => item.event_key === row.event_key);
    const linkedNodes = model.records.QuestNode.filter(node => node.node_type === 'WaitEvent' &&
      linkedConditions.some(condition => condition.condition_id === node.reference));
    const paramFields = [['param_key', '参数编号'], ['name', '参数名称'], ['data_type', '值类型'],
      ['param_kind', '参数用途'], ['allowed_values', '可配置范围'], ['comparison', '筛选方式'],
      ['example', '填写示例'], ['description', '参数说明']];
    $('previewArea').innerHTML = `<section class="parameter"><h3>事件来源与任务引用</h3><p class="hint">当前 Steam 范围：${esc(row.steam_scope)}。${esc(row.scope_reason)}。任务阈值和过滤值配置在任务条件中。</p><div class="item">${esc(row.event_key)} · ${esc(row.publish_state)}；daily 引用 ${source?.current_task_count || 0} 条；七日引用 ${source?.seven_task_count || 0} 条；C++ 直接调用 ${source?.cpp_call_count || 0} 处。${esc(source?.reason || '')}</div>${(source?.current_examples || []).map(item =>
      `<div class="item">源任务 ${esc(item.id)} · ${esc(item.name)} · condition [${esc(item.condition.join(', '))}]</div>`).join('')}<h3>事件参数 · 随事件类型维护</h3>${params.map(item => {
      const paramIndex = model.records.EventParam.indexOf(item);
      return `<div class="item"><div class="param-fields">${paramFields.map(([key, label]) =>
        `<label><span>${label}</span>${key === 'data_type' || key === 'param_kind' || key === 'comparison' ?
          `<select data-param-index="${paramIndex}" data-param-key="${key}">${(
            key === 'data_type' ? ['整数', '文本', '布尔'] :
            key === 'param_kind' ? ['计数增量', '筛选参数', '状态值'] :
            ['累加', '取当前值', '大于等于', '等于', '小于等于', '大于', '小于']
          ).map(option => `<option value="${esc(option)}" ${option === String(item[key]) ? 'selected' : ''}>${esc(option)}</option>`).join('')}</select>` :
          `<input data-param-index="${paramIndex}" data-param-key="${key}" value="${esc(item[key])}">`}</label>`
      ).join('')}</div><button data-remove-param="${paramIndex}" class="danger">删除此参数</button></div>`;
    }).join('') || '<p class="hint">尚未定义参数。</p>'}<button id="addParam">添加事件参数</button><h3>事件节点 · 引用此事件的任务流程</h3><p class="hint">${linkedNodes.length} 个等待事件节点；节点属于对应任务流程。</p>${linkedNodes.slice(0, 8).map(node =>
      `<div class="item"><button data-open-node="${esc(node.node_id)}">${esc(node.quest_id)} · ${esc(node.node_id)}</button></div>`
    ).join('')}<h3>任务完成条件引用 · ${linkedConditions.length} 条已导入</h3><details><summary>展开全部引用</summary>${linkedConditions.map(item =>
      `<div class="item">${esc(item.quest_id)} · ${esc(conditionText(item))}</div>`).join('') || '<p class="hint">暂未导入任务配置。</p>'}</details></section>`;
    document.querySelectorAll('[data-param-index]').forEach(input => input.oninput = () => {
      const param = model.records.EventParam[Number(input.dataset.paramIndex)];
      const value = input.value;
      param[input.dataset.paramKey] = input.dataset.paramKey === 'example' && Number.isFinite(Number(value)) ? Number(value) : value;
      dirty = true;
      $('foot').textContent = model.workbook + ' · 有未保存修改';
    });
    document.querySelectorAll('[data-param-index]').forEach(input => input.onchange = input.oninput);
    $('addParam').onclick = () => {
      model.records.EventParam.push({event_key: row.event_key, param_key: '', name: '', data_type: '整数',
        param_kind: '筛选参数', allowed_values: '', comparison: '', example: '', description: ''});
      dirty = true;
      renderPreview(row);
    };
    document.querySelectorAll('[data-remove-param]').forEach(button => button.onclick = () => {
      model.records.EventParam.splice(Number(button.dataset.removeParam), 1);
      dirty = true;
      renderPreview(row);
    });
    document.querySelectorAll('[data-open-node]').forEach(button => button.onclick = () => {
      table = 'QuestNode';
      index = model.records.QuestNode.findIndex(item => item.node_id === button.dataset.openNode);
      render();
    });
    return;
  }
  if (table === 'QuestType') {
    const tasks = model.records.Quest.filter(item => item.quest_type === row.type_key);
    $('previewArea').innerHTML = `<section class="parameter"><h3>该类型下的任务配置 · ${tasks.length} 条</h3>${tasks.slice(0, 80).map(item =>
      `<div class="item"><button data-open-quest="${esc(item.quest_id)}">${esc(item.quest_id)} · ${esc(item.name)}</button></div>`
    ).join('') || '<p class="hint">暂无任务。</p>'}</section>`;
    document.querySelectorAll('[data-open-quest]').forEach(button => button.onclick = () => {
      table = 'Quest';
      index = model.records.Quest.findIndex(item => item.quest_id === button.dataset.openQuest);
      render();
    });
    return;
  }
  if (table === 'QuestCondition') {
    $('previewArea').innerHTML = `<section class="parameter"><h3>任务引用的事件类型</h3><div class="item">${esc(conditionText(row))}</div><p class="hint">完成条件引用 EMQCT 事件类型；目标数量和筛选值是本任务的参数，不会生成另一种事件类型。</p></section>`;
    return;
  }
  if (table === 'LegacyMap') {
    $('previewArea').innerHTML = '<section class="parameter"><h3>迁移审计资料</h3><p class="hint">此处保留旧编号和核对结果，不参与任务条件下拉选择。原表、Lua 调用和代码行号请到审计页查看。</p></section>';
    return;
  }
  const questId = row.quest_id;
  if (!questId) {
    $('previewArea').innerHTML = '';
    return;
  }
  const nodes = model.records.QuestNode.filter(item => item.quest_id === questId);
  const byId = new Map(nodes.map(item => [item.node_id, item]));
  let current = nodes.find(item => item.node_type === 'Start');
  const ordered = [], seen = new Set();
  while (current && !seen.has(current.node_id)) {
    ordered.push(current);
    seen.add(current.node_id);
    current = byId.get(current.next_node);
  }
  const condition = model.records.QuestCondition.find(item => item.quest_id === questId && item.phase === '完成');
  const event = condition && model.records.EventType.find(item => item.event_key === condition.event_key);
  const filters = condition ? model.records.EventParam.filter(item => item.event_key === condition.event_key && item.param_kind === '筛选参数') : [];
  const dialogueHtml = dialoguePhases.map(([phase, label]) => {
    const node = nodes.find(item => item.node_type === 'Dialogue' && item.dialogue_phase === phase);
    const groupId = String(node?.reference || '');
    const lines = model.records.DialogueLine.filter(item => String(item.sequence_id) === groupId)
      .sort((a, b) => Number(a.line_order) - Number(b.line_order));
    return `<div class="dialogue-slot"><h4>${label}</h4><label><span>对话表组 ID</span><select data-dialogue-phase="${phase}" ${node ? '' : 'disabled'}><option value="">不配置对白</option>${dialogueGroups().map(group => `<option value="${esc(group.sequence_id)}" ${group.sequence_id === groupId ? 'selected' : ''}>${esc(group.sequence_id)} · ${esc(group.name)}</option>`).join('')}</select></label>${node ? '' : '<p class="hint">固定节点缺失，请校验工作簿。</p>'}${groupId ? `<div class="dialogue"><b>组 ${esc(groupId)} · ${lines.length} 句</b>${lines.map(line => `<div>第 ${esc(line.line_order)} 句 · ${esc(line.speaker)}：${esc(line.text)}</div>`).join('')}</div><button data-open-group="${esc(groupId)}">编辑对话组</button>` : '<p class="hint">此状态没有对话组，进入该状态时不播放对白。</p>'}</div>`;
  }).join('');
  $('previewArea').innerHTML = `<section class="flow"><h3>任务流程</h3><div class="flow-rail">${ordered.map((item, i) =>
    `${i ? '<span class="arrow">→</span>' : ''}<div class="node"><b>${esc(nodeNames[item.node_type] || item.node_type)}</b><button data-edit-node="${esc(item.node_id)}">${esc(item.node_type === 'Start' ? row.entry || '任务入口' : item.node_type === 'WaitEvent' ? event?.name || '选择事件' : item.node_type === 'Complete' ? '达成任务' : item.node_type === 'Dialogue' ? '查看对白' : item.reference || '编辑节点')}</button></div>`
  ).join('') || '<span class="hint">尚无节点</span>'}</div>${condition ? `<div class="item" id="quest-condition"><h3>完成目标 · 选择统一事件</h3><p class="hint">当前事件：${esc(event?.name || '未选择')}（${esc(condition.event_key)}）；${esc(event?.publish_state || '待核对')}。下拉框列出全部 ${steamEvents().length} 种未屏蔽事件，其中 ${steamEvents().length - candidateEvents().length} 种入口待核对，暂不能选择。</p><div class="param-fields"><label><span>完成事件</span><select id="questEvent">${eventOptions(condition.event_key)}</select></label><label><span>目标数量（${esc(event?.unit || '单位待定义')}）</span><input id="questTarget" type="number" min="1" value="${esc(condition.target_value)}"></label>${filters.length ? `<label><span>筛选参数</span><select id="questFilter">${[['', '不筛选'], ...filters.map(item => [item.param_key, item.name])].map(([key, name]) => `<option value="${esc(key)}" ${key === condition.filter_param ? 'selected' : ''}>${esc(name)}</option>`).join('')}</select></label><label><span>筛选比较</span>${selection('filter_operator', condition.filter_operator, [['', '不设置'], ['>=', '大于等于'], ['=', '等于'], ['<=', '小于等于']])}</label><label><span>筛选值</span><input id="questFilterValue" value="${esc(condition.filter_value)}"></label>` : ''}</div><div class="hint">${esc(conditionText(condition))} · ${esc(event?.trigger_point || '产生时机待定义；可保存任务草稿，正式导出前须补全事件定义并验收。')}</div></div>` : '<p class="hint">尚未配置完成目标。</p>'}<div class="parameter"><h3>固定状态对话节点</h3><p class="hint">任务状态决定使用哪一个对话组。每个槽只填组 ID；组内多句对白在“对话组”中维护。未填组 ID 时不播放对白。</p><div class="dialogue-slots">${dialogueHtml}</div></div></section>`;
  const flow = $('previewArea').querySelector('.flow');
  const conditionPanel = $('quest-condition');
  const dialoguePanel = flow.querySelector('.parameter');
  if (conditionPanel) flow.prepend(conditionPanel);
  $('previewArea').append(dialoguePanel);
  $('workflowArea').append(flow);
  document.querySelectorAll('[data-edit-node]').forEach(button => button.onclick = () => {
    const node = model.records.QuestNode.find(item => item.node_id === button.dataset.editNode);
    if (node?.node_type === 'WaitEvent') {
      $('quest-condition')?.scrollIntoView({block: 'nearest'});
      return;
    }
    table = 'QuestNode';
    index = model.records.QuestNode.findIndex(item => item.node_id === button.dataset.editNode);
    render();
  });
  document.querySelectorAll('[data-dialogue-phase]').forEach(select => select.onchange = () => {
    const node = nodes.find(item => item.node_type === 'Dialogue' && item.dialogue_phase === select.dataset.dialoguePhase);
    if (!node) return;
    node.reference = select.value;
    dirty = true;
    renderPreview(row);
  });
  document.querySelectorAll('[data-open-group]').forEach(button => button.onclick = () => {
    table = 'DialogueLine';
    index = dialogueGroups().findIndex(group => group.sequence_id === button.dataset.openGroup);
    render();
  });
  if (condition) {
    $('questEvent').onchange = event => {
      condition.event_key = event.target.value;
      condition.filter_param = '';
      condition.filter_operator = '';
      condition.filter_value = '';
      dirty = true;
      renderPreview(row);
    };
    $('questTarget').oninput = event => {
      condition.target_value = Number(event.target.value);
      dirty = true;
      $('foot').textContent = model.workbook + ' · 有未保存修改';
    };
    $('questTarget').onchange = () => renderPreview(row);
    if ($('questFilter')) $('questFilter').onchange = event => {
      condition.filter_param = event.target.value;
      if (!condition.filter_param) { condition.filter_operator = ''; condition.filter_value = ''; }
      dirty = true;
      renderPreview(row);
    };
    const compare = document.querySelector('#workflowArea [data-key="filter_operator"]');
    if (compare) compare.onchange = event => { condition.filter_operator = event.target.value; dirty = true; };
    if ($('questFilterValue')) $('questFilterValue').oninput = event => {
      const value = event.target.value;
      const param = filters.find(item => item.param_key === condition.filter_param);
      condition.filter_value = param?.data_type === '整数' && value !== '' ? Number(value) : value;
      dirty = true;
    };
    if ($('questFilterValue')) $('questFilterValue').onchange = () => renderPreview(row);
  }
}

function renderDialogueGroup(group) {
  const groupId = String(group.sequence_id);
  const lines = model.records.DialogueLine.filter(line => String(line.sequence_id) === groupId)
    .sort((a, b) => Number(a.line_order) - Number(b.line_order));
  const source = model.records.LegacyMap.some(item => item.source === 'mission_dialog.xlsx' &&
    String(item.legacy_id) === groupId && item.record_kind === '剧情');
  $('form').innerHTML = `<div class="dialogue-group-header"><b>组 ID：${esc(groupId)}</b><p class="hint">${source ? '来自章节对话源表；尚未自动关联任务。' : '策划新建对话组。'}一个组可包含多句对白。</p></div>`;
  $('previewArea').innerHTML = `<section class="parameter"><div class="dialogue-toolbar"><h3>组内对白 · ${lines.length} 句</h3><button id="addDialogueLine">添加一句</button></div>${lines.map(line => {
    const lineIndex = model.records.DialogueLine.indexOf(line);
    return `<div class="item dialogue-line"><div class="param-fields"><label><span>说话人 · 第 ${esc(line.line_order)} 句</span><input data-line-index="${lineIndex}" data-line-key="speaker" value="${esc(line.speaker)}" placeholder="填写角色名称"></label><label><span>对白正文</span><textarea data-line-index="${lineIndex}" data-line-key="text" placeholder="填写这句对白">${esc(line.text)}</textarea></label></div><details><summary>表现参数</summary><div class="param-fields">${[['position', '立绘位置'], ['scale', '缩放'], ['speed', '播放速度'], ['delay', '延时'], ['show_skip', '显示跳过']].map(([key, label]) => `<label><span>${label}</span><input type="number" data-line-index="${lineIndex}" data-line-key="${key}" value="${esc(line[key])}"></label>`).join('')}</div></details><button class="danger" data-remove-line="${lineIndex}" ${lines.length === 1 ? 'disabled' : ''}>删除这句</button></div>`;
  }).join('')}</section>`;
  $('addDialogueLine').onclick = () => {
    const order = Math.max(0, ...lines.map(item => Number(item.line_order) || 0)) + 1;
    model.records.DialogueLine.push({sequence_id: groupId, line_order: order, speaker: '',
      position: 0, text: '', scale: 1, speed: 100, delay: 0, show_skip: 1});
    dirty = true;
    render();
  };
  document.querySelectorAll('[data-remove-line]').forEach(button => button.onclick = () => {
    model.records.DialogueLine.splice(Number(button.dataset.removeLine), 1);
    dirty = true;
    render();
  });
  document.querySelectorAll('[data-line-index]').forEach(input => input.oninput = () => {
    const line = model.records.DialogueLine[Number(input.dataset.lineIndex)];
    const key = input.dataset.lineKey;
    line[key] = numeric.has(key) && input.value !== '' ? Number(input.value) : input.value;
    dirty = true;
    $('foot').textContent = model.workbook + ' · 有未保存修改';
  });
}

async function request(path, options) {
  const response = await fetch(path, { cache: 'no-store', ...options });
  const data = await response.json();
  if (!response.ok || data.error) throw new Error(data.error || `HTTP ${response.status}`);
  return data;
}

async function load() {
  try {
    [model, eventSummary] = await Promise.all([request('/api/model'), request('/api/event-summary')]);
    dirty = false;
    render();
    status('任务类型固定为主线、支线、日常、累计；任务条件显示全部未屏蔽事件，待定义事件仅供配置草稿。');
  } catch (error) {
    status('读取失败：' + error.message, true);
  }
}

$('audit').onclick = () => location.assign('/?tab=events');
$('search').oninput = event => { query = event.target.value.toLowerCase(); render(); };
$('add').onclick = () => {
  if (isAudit() || table === 'EventType' || table === 'QuestType' || table === 'QuestNode') return;
  if (table === 'DialogueLine') {
    const numericIds = dialogueGroups().map(group => Number(group.sequence_id)).filter(Number.isInteger);
    const proposed = String(Math.max(10000, ...numericIds) + 1);
    const groupId = prompt('请输入新的对话组 ID', proposed);
    if (groupId === null) return;
    if (!/^\d+$/.test(groupId) || dialogueGroups().some(group => group.sequence_id === groupId)) {
      status('对话组 ID 必须是不重复的整数。', true); return;
    }
    model.records.DialogueLine.push({sequence_id: groupId, line_order: 1, speaker: '',
      position: 0, text: '', scale: 1, speed: 100, delay: 0, show_skip: 1});
    index = dialogueGroups().findIndex(group => group.sequence_id === groupId);
    dirty = true;
    render();
    status(`已创建对话组 ${groupId}，填写第一句后校验保存。`);
    return;
  }
  if (table === 'Quest') {
    const numericIds = model.records.Quest.map(item => /^(?:daily\.)?(\d+)$/.exec(String(item.quest_id)))
      .filter(Boolean).map(match => Number(match[1]));
    const id = String(Math.max(0, ...numericIds) + 1);
    const event = selectableEvents()[0];
    if (!event) { status('尚无参数已定义且纳入 Steam 的事件，不能新建有事件目标的任务。', true); return; }
    const row = {quest_id: id, name: '新任务', quest_type: 'daily', legacy_group: '', scope: '角色',
      repeat_cycle: '每日', entry: '任务列表', min_level: 0, pre_quest_id: '', reward_ref: '', publish_state: '草稿'};
    model.records.Quest.push(row);
    model.records.QuestCondition.push({condition_id: `${id}.complete`, quest_id: id, phase: '完成',
      event_key: event.event_key, filter_param: '', filter_operator: '', filter_value: '',
      operator: '>=', target_value: 1, logic_group: 'AND', count_start: '周期开始', scope: '角色'});
    for (const [node_type, suffix, next_node, reference] of [
      ['Start', 'start', 'wait', ''], ['WaitEvent', 'wait', 'complete', `${id}.complete`],
      ['Complete', 'complete', '', '']]) {
      model.records.QuestNode.push({node_id: `${id}.${suffix}`, quest_id: id, node_type,
        reference, next_node: next_node ? `${id}.${next_node}` : '', entry: node_type === 'Start' ? '任务列表' : '', dialogue_phase: ''});
    }
    for (const [phase] of dialoguePhases) {
      model.records.QuestNode.push({node_id: `${id}.dialogue.${phase}`, quest_id: id,
        node_type: 'Dialogue', reference: '', next_node: '', entry: '', dialogue_phase: phase});
    }
    index = model.records.Quest.length - 1;
    dirty = true;
    render();
    status('已创建任务草稿，填写名称、类型和事件目标后校验保存。');
    return;
  }
  const row = Object.fromEntries(model.schema[table].map(([key]) => [key, '']));
  if (table === 'QuestCondition') { row.operator = '>='; row.target_value = 1; row.phase = '完成'; row.logic_group = 'AND'; row.event_key = selectableEvents()[0]?.event_key || ''; }
  if (table === 'EventType' || table === 'Quest') row.publish_state = '草稿';
  if (table === 'QuestType') row.publish_state = '草稿';
  if (table === 'EventParam') { row.data_type = '整数'; row.param_kind = '筛选参数'; row.event_key = model.records.EventType[0]?.event_key || ''; }
  rows().push(row);
  index = rows().length - 1;
  dirty = true;
  render();
  status('已新增草稿，填写完整后校验并保存。');
};
$('remove').onclick = () => {
  if (isAudit() || table === 'EventType' || table === 'QuestType' || table === 'QuestNode' || !rows().length) return;
  const id = identity(rows()[index]);
  if (table === 'DialogueLine') {
    if (model.records.QuestNode.some(node => node.node_type === 'Dialogue' && String(node.reference) === id)) {
      status(`对话组 ${id} 已被任务引用，请先清除任务中的组 ID。`, true); return;
    }
    if (model.records.LegacyMap.some(item => item.record_kind === '剧情' && String(item.new_id) === id)) {
      status(`对话组 ${id} 来自旧表并保留迁移映射，不能在策划页删除。`, true); return;
    }
    if (!confirm(`删除对话组 ${id} 及组内全部对白？`)) return;
    model.records.DialogueLine = model.records.DialogueLine.filter(line => String(line.sequence_id) !== id);
    index = Math.max(0, index - 1);
    dirty = true;
    render();
    return;
  }
  if (!confirm(`删除 ${id}？关联校验会阻止悬空引用。`)) return;
  if (table === 'Quest') {
    const quest = rows()[index];
    model.records.QuestCondition = model.records.QuestCondition.filter(item => item.quest_id !== quest.quest_id);
    model.records.QuestNode = model.records.QuestNode.filter(item => item.quest_id !== quest.quest_id);
  }
  rows().splice(index, 1);
  index = Math.max(0, index - 1);
  dirty = true;
  render();
  status('已删除 ' + id + '，尚未写入 Excel。');
};
$('check').onclick = async () => {
  try {
    await request('/api/validate', { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ records: model.records }) });
    status('事件参数、任务引用、条件和流程均通过校验。');
  } catch (error) { status('校验失败：' + error.message, true); }
};
$('save').onclick = async () => {
  try {
    status('正在写入 Excel 并回读校验…');
    const saved = await request('/api/model', { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ records: model.records }) });
    dirty = false;
    render();
    status('已保存并复核：' + saved.workbook);
  } catch (error) { status('保存失败：' + error.message, true); }
};
$('preview').onclick = async () => {
  try {
    if (dirty) throw new Error('请先保存 Excel');
    const result = await request('/api/export?preview=1');
    status(`预览导出完成：${result.accepted_quests} 条草稿或已验收任务，JSON 标记 preview_only=true。`);
    window.open('/api/download?file=preview_server', '_blank');
    window.open('/api/download?file=preview_client', '_blank');
  } catch (error) { status('预览导出失败：' + error.message, true); }
};
$('release').onclick = async () => {
  try {
    if (dirty) throw new Error('请先保存 Excel');
    const result = await request('/api/export');
    status(`正式导出完成：${result.accepted_quests} 条已验收任务。`);
    window.open('/api/download?file=server', '_blank');
    window.open('/api/download?file=client', '_blank');
  } catch (error) { status('正式导出失败：' + error.message, true); }
};
$('download').textContent = '下载策划核对表';
$('download').onclick = () => {
  if (dirty) { status('当前有未保存修改，请先保存。', true); return; }
  location.assign('/api/download?file=planner');
};
const sourceDownload = document.createElement('button');
sourceDownload.textContent = '下载技术源表';
$('download').after(sourceDownload);
sourceDownload.onclick = () => {
  if (dirty) { status('当前有未保存修改，请先保存。', true); return; }
  location.assign('/api/download?file=workbook');
};
load();
