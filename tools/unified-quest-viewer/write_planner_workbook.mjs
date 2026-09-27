import fs from 'node:fs/promises';
import path from 'node:path';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) throw new Error('Usage: write_planner_workbook.mjs input.json output.xlsx');
const { records } = JSON.parse(await fs.readFile(inputPath, 'utf8'));
const book = Workbook.create();
const byKey = (table, key) => new Map(records[table].map(row => [String(row[key]), row]));
const eventByKey = byKey('EventType', 'event_key');
const paramsByEvent = new Map();
for (const param of records.EventParam) {
  const list = paramsByEvent.get(param.event_key) || [];
  list.push(param);
  paramsByEvent.set(param.event_key, list);
}
const eventNumber = key => {
  const match = /^EMQCT_(\d+)$/.exec(String(key || ''));
  if (!match) throw new Error(`事件编号无法转换为数字：${key}`);
  return Number(match[1]);
};
const typeIds = {main: 1, side: 2, daily: 3, cumulative: 4};
const cycleIds = {'一次': 1, '每日': 2, '累计': 3};
const filterOperatorIds = {'>=': 1, '=': 2, '<=': 3, '>': 4, '<': 5};
const operatorNames = {'大于等于': '>=', '等于': '=', '小于等于': '<=', '大于': '>', '小于': '<'};
const enumGroups = [
  [1, '发布状态', ['待定义', '草稿', '已验收']],
  [2, '玩法分类', ['招募', '登录', '装备', '法宝', '封神列传', '每日任务']],
  [3, '事件计数方式', ['累加事件增量', '取当前状态值']],
  [4, '计数单位', ['次', '场', '件', '点']],
  [5, '事件生效范围', ['角色', '账号', '帮派']],
  [6, '参数用途', ['计数增量', '筛选参数', '状态值']],
  [7, '参数值类型', ['整数', '文本', '布尔']],
  [8, 'Steam范围', ['纳入', '待核对', '屏蔽']],
];
const enumValue = (groupId, value) => {
  if (value === undefined || value === null || value === '') return '';
  const group = enumGroups.find(item => item[0] === groupId);
  const index = group?.[2].indexOf(String(value)) ?? -1;
  if (index < 0) throw new Error(`未知枚举 ${group?.[1] || groupId}：${value}`);
  return index + 1;
};
const questNumber = value => {
  if (value === undefined || value === null || value === '') return '';
  const match = /^(?:daily\.)?(\d+)$/.exec(String(value));
  if (!match) throw new Error(`任务编号无法转换为数字：${value}`);
  return Number(match[1]);
};
const dialogueNumber = value => {
  if (value === undefined || value === null || value === '') return '';
  if (!/^\d+$/.test(String(value))) throw new Error(`对话组编号不是数字：${value}`);
  return Number(value);
};
const parameterIds = new Map();
for (const [eventKey, params] of paramsByEvent) {
  params.forEach((param, index) => parameterIds.set(`${eventKey}:${param.param_key}`, index + 1));
}
const dialoguePhaseNames = [
  ['before_accept', '未接取前对话组ID'],
  ['accepted_incomplete', '已接未完成对话组ID'],
  ['completed_unclaimed', '已完成未领取对话组ID'],
];
const letters = n => {
  let text = '';
  for (let value = n; value > 0; value = Math.floor((value - 1) / 26)) {
    text = String.fromCharCode(65 + (value - 1) % 26) + text;
  }
  return text;
};
function sheet(name, columns, rows) {
  const page = book.worksheets.add(name);
  page.freezePanes.freezeRows(4);
  const last = letters(columns.length);
  page.getRange(`A1:${last}4`).values = [
    columns.map(column => column.key),
    columns.map(() => 'all'),
    columns.map(column => column.label),
    columns.map(column => column.type),
  ];
  page.getRange(`A1:${last}4`).format.font = {name: 'DengXian', size: 11, color: '#222222'};
  if (rows.length) {
    const bottom = rows.length + 4;
    page.getRange(`A5:${last}${bottom}`).values = rows.map(row =>
      row.map(value => value === undefined || value === null ? '' :
        typeof value === 'string' && value.startsWith('=') ? `'${value}` : value));
    page.getRange(`A5:${last}${bottom}`).format.font = {name: 'DengXian', size: 11, color: '#222222'};
  }
  for (let index = 0; index < columns.length; index++) {
    const column = letters(index + 1);
    page.getRange(`${column}1:${column}${Math.max(5, rows.length + 4)}`).format.columnWidth = columns[index].width || 18;
  }
  return page;
}

const conditionsByQuest = new Map(records.QuestCondition.filter(row => row.phase === '完成')
  .map(row => [String(row.quest_id), row]));
const dialogueByQuest = new Map();
for (const node of records.QuestNode.filter(row => row.node_type === 'Dialogue')) {
  const state = dialogueByQuest.get(String(node.quest_id)) || {};
  state[node.dialogue_phase] = node.reference || '';
  dialogueByQuest.set(String(node.quest_id), state);
}
const questRows = records.Quest.map(quest => {
  const condition = conditionsByQuest.get(String(quest.quest_id));
  const dialogue = dialogueByQuest.get(String(quest.quest_id)) || {};
  const typeId = typeIds[quest.quest_type];
  const cycleId = cycleIds[quest.repeat_cycle];
  if (!typeId || !cycleId || !condition) throw new Error(`任务类型、周期或完成条件缺失：${quest.quest_id}`);
  let filterParamId = '', filterOperatorId = '', filterValue = '';
  if (condition.filter_param) {
    const parameter = (paramsByEvent.get(condition.event_key) || [])
      .find(item => item.param_key === condition.filter_param && item.param_kind === '筛选参数');
    if (!parameter || parameter.data_type !== '整数') {
      throw new Error(`任务 ${quest.quest_id} 的筛选参数未定义或不是整数`);
    }
    filterParamId = parameterIds.get(`${condition.event_key}:${condition.filter_param}`);
    filterOperatorId = filterOperatorIds[condition.filter_operator];
    filterValue = Number(condition.filter_value);
    if (!filterParamId || !filterOperatorId || !Number.isInteger(filterValue)) {
      throw new Error(`任务 ${quest.quest_id} 的筛选参数、比较或数值无效`);
    }
  }
  return [questNumber(quest.quest_id), quest.name, typeId, cycleId,
    quest.min_level ?? '', questNumber(quest.pre_quest_id), eventNumber(condition.event_key),
    condition.target_value ?? '', filterParamId, filterOperatorId, filterValue,
    ...dialoguePhaseNames.map(([phase]) => dialogueNumber(dialogue[phase])),
    enumValue(1, quest.publish_state)];
});
const questIds = questRows.map(row => row[0]);
if (new Set(questIds).size !== questIds.length) throw new Error('数字任务 ID 重复');
sheet('任务配置', [
  {key: 'id', label: '任务ID', type: 'int'},
  {key: 'name', label: '任务名称', type: 'string', width: 27},
  {key: 'taskTypeId', label: '任务类型ID', type: 'int'},
  {key: 'repeatCycleId', label: '重复周期ID', type: 'int'},
  {key: 'minLevel', label: '开放等级', type: 'int'},
  {key: 'preTaskId', label: '前置任务ID', type: 'int'},
  {key: 'completeEventId', label: '完成事件ID', type: 'int'},
  {key: 'targetCount', label: '目标数量', type: 'int'},
  {key: 'filterParamId', label: '筛选参数ID（见事件参数）', type: 'int', width: 28},
  {key: 'filterOperatorId', label: '筛选比较ID（见筛选比较）', type: 'int', width: 29},
  {key: 'filterValue', label: '筛选值（见参数范围）', type: 'int', width: 26},
  {key: 'dialogBeforeId', label: '未接取前对话组ID', type: 'int', width: 24},
  {key: 'dialogActiveId', label: '已接未完成对话组ID', type: 'int', width: 25},
  {key: 'dialogReadyId', label: '已完成未领取对话组ID', type: 'int', width: 27},
  {key: 'publishStateId', label: '发布状态ID（通用枚举1）', type: 'int', width: 28},
], questRows);

const visibleEvents = records.EventType.filter(event => event.steam_scope !== '屏蔽');
const eventRows = visibleEvents.map(event => {
  const params = paramsByEvent.get(event.event_key) || [];
  const progress = params.filter(param => param.param_kind === '计数增量' || param.param_kind === '状态值');
  const filters = params.filter(param => param.param_kind === '筛选参数');
  if (progress.length > 1 || filters.length > 3) {
    throw new Error(`事件 ${event.event_key} 的进度参数或筛选参数超出当前表结构`);
  }
  return [eventNumber(event.event_key), event.name, enumValue(2, event.category),
    progress[0] ? progress[0].param_kind === '状态值' ? 2 : 1 : '',
    enumValue(4, event.unit), enumValue(5, event.scope),
    progress[0] ? parameterIds.get(`${event.event_key}:${progress[0].param_key}`) : '',
    ...[0, 1, 2].map(index => filters[index] ? parameterIds.get(`${event.event_key}:${filters[index].param_key}`) : ''),
    enumValue(1, event.publish_state), enumValue(8, event.steam_scope)];
});
sheet('任务事件', [
  {key: 'id', label: '事件ID', type: 'int'},
  {key: 'name', label: '事件名称', type: 'string', width: 27},
  {key: 'categoryId', label: '玩法分类ID（通用枚举2）', type: 'int', width: 27},
  {key: 'counterModeId', label: '计数方式ID（通用枚举3）', type: 'int', width: 28},
  {key: 'unitId', label: '单位ID（通用枚举4）', type: 'int', width: 25},
  {key: 'scopeId', label: '生效范围ID（通用枚举5）', type: 'int', width: 27},
  {key: 'progressParamId', label: '进度参数ID', type: 'int'},
  {key: 'filterParam1Id', label: '筛选参数1ID', type: 'int'},
  {key: 'filterParam2Id', label: '筛选参数2ID', type: 'int'},
  {key: 'filterParam3Id', label: '筛选参数3ID', type: 'int'},
  {key: 'definitionStateId', label: '定义状态ID（通用枚举1）', type: 'int', width: 28},
  {key: 'steamScopeId', label: 'Steam范围ID（通用枚举8）', type: 'int', width: 29},
], eventRows);

sheet('事件说明', [
  {key: 'eventId', label: '事件ID', type: 'int'},
  {key: 'triggerPoint', label: '何时触发', type: 'string', width: 52},
  {key: 'counterDescription', label: '计数说明', type: 'string', width: 48},
  {key: 'description', label: '策划说明', type: 'string', width: 62},
  {key: 'scopeReason', label: 'Steam范围依据', type: 'string', width: 42},
], visibleEvents.map(event => [eventNumber(event.event_key), event.trigger_point,
  event.counter_mode, event.description, event.scope_reason]));

const paramRows = records.EventParam.filter(param =>
  visibleEvents.some(event => event.event_key === param.event_key)).map(param => [
  eventNumber(param.event_key), parameterIds.get(`${param.event_key}:${param.param_key}`),
  param.name, enumValue(6, param.param_kind), enumValue(7, param.data_type),
  param.param_kind === '筛选参数' ? filterOperatorIds[operatorNames[param.comparison]] || '' : '',
]);
sheet('事件参数', [
  {key: 'eventId', label: '事件ID', type: 'int'},
  {key: 'paramId', label: '参数ID（事件内）', type: 'int', width: 23},
  {key: 'name', label: '参数名称', type: 'string', width: 24},
  {key: 'kindId', label: '参数用途ID（通用枚举6）', type: 'int', width: 27},
  {key: 'dataTypeId', label: '值类型ID（通用枚举7）', type: 'int', width: 27},
  {key: 'suggestedOperatorId', label: '建议筛选比较ID', type: 'int', width: 24},
], paramRows);

sheet('事件参数说明', [
  {key: 'eventId', label: '事件ID', type: 'int'},
  {key: 'paramId', label: '参数ID（事件内）', type: 'int', width: 23},
  {key: 'allowedValues', label: '可配置范围', type: 'string', width: 42},
  {key: 'comparison', label: '原计数或比较说明', type: 'string', width: 30},
  {key: 'example', label: '填写示例', type: 'string'},
  {key: 'description', label: '参数说明', type: 'string', width: 44},
], records.EventParam.filter(param => visibleEvents.some(event => event.event_key === param.event_key))
  .map(param => [eventNumber(param.event_key), parameterIds.get(`${param.event_key}:${param.param_key}`),
    param.allowed_values, param.comparison, String(param.example ?? ''), param.description]));

sheet('通用枚举', [
  {key: 'enumTypeId', label: '枚举类型ID', type: 'int'},
  {key: 'enumTypeName', label: '枚举类型名称', type: 'string', width: 25},
  {key: 'id', label: '枚举值ID', type: 'int'},
  {key: 'name', label: '枚举值名称', type: 'string', width: 25},
], enumGroups.flatMap(([groupId, groupName, values]) =>
  values.map((name, index) => [groupId, groupName, index + 1, name])));

sheet('筛选比较', [
  {key: 'id', label: '比较ID', type: 'int'},
  {key: 'operator', label: '比较符号', type: 'string'},
  {key: 'name', label: '含义', type: 'string'},
], [
  [1, '>=', '大于等于'], [2, '=', '等于'], [3, '<=', '小于等于'],
  [4, '>', '大于'], [5, '<', '小于'],
]);

sheet('任务类型', [
  {key: 'id', label: '类型ID', type: 'int'},
  {key: 'name', label: '任务类型', type: 'string'},
  {key: 'defaultCycleId', label: '默认重复周期ID', type: 'int', width: 22},
], records.QuestType.map(type => [typeIds[type.type_key], type.name,
  cycleIds[type.type_key === 'daily' ? '每日' : type.type_key === 'cumulative' ? '累计' : '一次']]));

sheet('任务类型说明', [
  {key: 'typeId', label: '类型ID', type: 'int'},
  {key: 'rule', label: '默认规则', type: 'string', width: 42},
  {key: 'description', label: '类型说明', type: 'string', width: 68},
], records.QuestType.map(type => [typeIds[type.type_key], type.structure, type.description]));

sheet('重复周期', [
  {key: 'id', label: '周期ID', type: 'int'},
  {key: 'name', label: '周期名称', type: 'string'},
  {key: 'rule', label: '计数起点与重置规则', type: 'string', width: 54},
], [
  [1, '一次', '接取任务后计数；完成后不重复'],
  [2, '每日', '每日周期开始时重置任务进度'],
  [3, '累计', '角色创建后累计进度；不按日重置'],
]);

sheet('对话表', [
  {key: 'groupId', label: '对话组ID', type: 'int'},
  {key: 'order', label: '句序', type: 'int'},
  {key: 'speaker', label: '说话人', type: 'string'},
  {key: 'position', label: '立绘位置', type: 'int'},
  {key: 'text', label: '对白内容', type: 'string', width: 76},
  {key: 'scale', label: '缩放', type: 'int'},
  {key: 'speed', label: '播放速度', type: 'int'},
  {key: 'delay', label: '延时', type: 'int'},
  {key: 'showSkip', label: '显示跳过', type: 'int'},
], records.DialogueLine.map(line => [dialogueNumber(line.sequence_id), line.line_order,
  line.speaker, line.position, line.text, line.scale, line.speed, line.delay, line.show_skip]));

const legacyRows = records.LegacyMap.filter(row => row.source === 'EMQCT' && row.record_kind === '事件')
  .map(row => {
    const event = eventByKey.get(String(row.new_id));
    return [Number(row.legacy_id), row.new_id, event?.name || '',
      String(row.note || '').split('；')[0], event?.steam_scope || '', row.migration_state];
  });
sheet('旧编号对照', [
  {key: 'eventId', label: '事件ID', type: 'int'},
  {key: 'legacyEnum', label: '服务端旧枚举', type: 'string', width: 24},
  {key: 'eventName', label: '当前事件名称', type: 'string', width: 28},
  {key: 'legacyComment', label: '旧代码注释', type: 'string', width: 44},
  {key: 'steamScope', label: 'Steam范围', type: 'string'},
  {key: 'reviewState', label: '核对状态', type: 'string'},
], legacyRows);

await fs.mkdir(path.dirname(outputPath), {recursive: true});
const xlsx = await SpreadsheetFile.exportXlsx(book);
await xlsx.save(outputPath);
process.stdout.write(JSON.stringify({outputPath, quests: questRows.length, events: eventRows.length}));
