using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>
    /// 基于 Unity 的地图数据编辑器（只读分析 + 可视化重配置 + 导出）。
    ///
    /// 不修改游戏任何运行时代码（FubenDetailMap / FuBenDetailUI / JsonConfig / WorldPresenter 等），
    /// 只读取 map_res_dat.lua，拖拽调整 NPC / 怪物坐标，再导出为同格式 lua。
    ///
    /// 坐标空间与客户端严格一致（WYSIWYG）：
    ///   · 底图瓦片：1:1 复刻 FubenDetailMap.LoadMap()——1024 瓦片、行优先、自左上起。
    ///   · 数据 → 底图像素：imgX = data.x / SCREENRATE，imgY(fromTop) = H - (data.y + anchorDy) / SCREENRATE，
    ///     SCREENRATE = 750/1080 来自 FuBenDetailUI.lua，MapPanel:setScale(SCREENRATE)。
    ///   · 客户端锚点偏移：怪物 node1:setPosition(x, y + 100)，模型子节点再 -85；
    ///     主角 _myNode:setPosition(x, y + 33)。
    /// </summary>
    public class MapEditorWindow : EditorWindow
    {
        private enum CoorType { Role, Monster, Camera }

        [System.Serializable]
        private class Coor
        {
            public int x;
            public int y;
            public Coor(int x, int y) { this.x = x; this.y = y; }
        }

        [System.Serializable]
        private class MapEntry
        {
            public int id;
            public string name = "";
            public List<Coor> role_coor = new List<Coor>();
            public List<Coor> monster_coor = new List<Coor>();
            // camera_coor 已不再驱动视角（副本视角改为“以主角为中心”），编辑器不再提供镜头编辑。
            // 字段仅原样保留，导出时逐字节写回，避免破坏 map_res 格式与其它消费端。
            public List<Coor> camera_coor = new List<Coor>();
            public Coor map_size = new Coor(5500, 1500); // {w,h}
        }

        // ===== 客户端常量（务必与 client/ProjectX/src/View/FuBenMap 保持一致）=====
        private const float ScreenRate = 750f / 1080f;    // FuBenDetailUI.lua: local SCREENRATE = 750 / 1080
        private const float DataToImage = 1080f / 750f;   // 1/SCREENRATE：数据坐标 → 底图像素
        private const float MonsterAnchorDy = 100f;       // monster_coor → node1:setPosition(cc.p(x, y + 100))
        private const float MonsterModelDy = 15f;         // 怪物模型子节点 -85，故可视中心 = y + 100 - 85
        private const float RoleAnchorDy = 33f;           // _myNode:setPosition(cc.p(x, y + 33))
        // 立绘贴图的固有偏移 Δ：静态立绘图（Monster_Bust / Role_Bust）的可见中心相对
        // 客户端锚点的差值。实测默认 63（数据单位）。
        // 注意：游戏内实际渲染的是 ModelAniNode / ImodAnim 骨骼模型，立绘 PNG 只是编辑器
        // 预览用的等价替代，故 Δ 只服务于“编辑器里看起来站得对”，不改变导出数据。
        private const float ModelTextureDelta = 63f;

        // ---- paths ----
        private string _sourcePath = "";
        private string _exportPath = "";
        private string _resRoot = "";   // .../client/ProjectX/res/fuben
        private string _artRoot = "";   // .../client/ProjectX/res2（Monster_Bust / Role_Bust 单帧立绘）

        // ---- data ----
        private List<MapEntry> _entries = new List<MapEntry>();
        private int _selectedMap = 0;

        // ---- view ----
        private Vector2 _pan = Vector2.zero;
        private float _zoom = 0.2f;
        private bool _showRole = true;
        private bool _showMonster = true;
        private bool _showModel = true;
        private bool _showAnchor = true;
        private bool _snap = false;
        private int _gridSize = 50;

        // ---- model preview ----
        private int _monsterId = 101;
        private int _heroId = 4;
        private float _modelHeight = 320f; // 立绘在底图上的目标高度（底图像素）
        private float _modelDy = ModelTextureDelta; // Δ：贴图在图集内的固有偏移，叠加到各类型锚点上
        private List<int> _monsterIds = new List<int>();
        private List<int> _heroIds = new List<int>();
        private int _monsterIdIdx = -1;
        private int _heroIdIdx = -1;

        // ---- selection / interaction ----
        private CoorType _selType;
        private int _selIndex = -1;
        private Vector2 _dragStartMouse;
        private Vector2 _dragStartVal;
        private Vector2 _dragStartPan;
        private bool _draggingMarker;
        private bool _panning;

        private readonly Dictionary<string, Texture2D> _texCache = new Dictionary<string, Texture2D>();
        private Texture2D _circleTex;
        private Rect _canvasRect;
        private bool _needFit;

        private static readonly float HandleRadius = 9f;
        private static readonly Color ColorRole = new Color(0.23f, 0.55f, 0.95f);    // 蓝 NPC / 主角
        private static readonly Color ColorMonster = new Color(0.90f, 0.30f, 0.28f); // 红 怪物

        [MenuItem("Tools/ProjectX 工具/地图编辑器 (Map Editor)")]
        public static void Open()
        {
            var w = GetWindow<MapEditorWindow>("地图编辑器");
            w.minSize = new Vector2(920, 620);
        }

        private void OnEnable()
        {
            _sourcePath = EditorPrefs.GetString("MapEditor.Source", DefaultSource());
            _exportPath = EditorPrefs.GetString("MapEditor.Export", _sourcePath);
            _resRoot = EditorPrefs.GetString("MapEditor.ResRoot", DefaultResRoot());
            _artRoot = EditorPrefs.GetString("MapEditor.ArtRoot2", DefaultArtRoot());
            _monsterId = EditorPrefs.GetInt("MapEditor.MonsterId", 101);
            _heroId = EditorPrefs.GetInt("MapEditor.HeroId", 4);
            _modelHeight = EditorPrefs.GetFloat("MapEditor.ModelHeight", 320f);
            _modelDy = EditorPrefs.GetFloat("MapEditor.ModelDeltaV2", ModelTextureDelta);
            _circleTex = MakeCircleTexture();
            RefreshMonsterIds();
            if (File.Exists(_sourcePath)) Load(); // 打开即读取
        }

        private void OnDisable()
        {
            EditorPrefs.SetString("MapEditor.Source", _sourcePath);
            EditorPrefs.SetString("MapEditor.Export", _exportPath);
            EditorPrefs.SetString("MapEditor.ResRoot", _resRoot);
            EditorPrefs.SetString("MapEditor.ArtRoot2", _artRoot);
            EditorPrefs.SetInt("MapEditor.MonsterId", _monsterId);
            EditorPrefs.SetInt("MapEditor.HeroId", _heroId);
            EditorPrefs.SetFloat("MapEditor.ModelHeight", _modelHeight);
            EditorPrefs.SetFloat("MapEditor.ModelDeltaV2", _modelDy);
        }

        /// <summary>立绘可视中心的 Y 偏移 = 客户端锚点(怪物 +100 / 主角 +33) + Δ。</summary>
        private float ModelDy(CoorType t) { return t == CoorType.Camera ? 0f : AnchorDy(t) + _modelDy; }

        private static string ProjectRoot()
        {
            return Path.GetDirectoryName(Application.dataPath); // .../unityclient
        }

        private string DefaultSource()
        {
            return Path.GetFullPath(Path.Combine(ProjectRoot(), "..", "client", "ProjectX", "src", "ConfigData", "map_res_dat.lua"));
        }

        private string DefaultResRoot()
        {
            return Path.GetFullPath(Path.Combine(ProjectRoot(), "..", "client", "ProjectX", "res", "fuben"));
        }

        private string DefaultArtRoot()
        {
            return Path.GetFullPath(Path.Combine(ProjectRoot(), "..", "client", "ProjectX", "res"));
        }

        // ===================== 坐标变换 =====================
        private float ImgX(float dataX) { return dataX * DataToImage; }
        private float ImgYFromTop(MapEntry e, float dataY, float anchorDy) { return e.map_size.y - (dataY + anchorDy) * DataToImage; }

        private float MaxDataX(MapEntry e) { return e.map_size.x * ScreenRate; }
        private float MaxDataY(MapEntry e, float anchorDy) { return e.map_size.y * ScreenRate - anchorDy; }

        private float AnchorDy(CoorType t)
        {
            if (t == CoorType.Monster) return MonsterAnchorDy;
            if (t == CoorType.Role) return RoleAnchorDy;
            return 0f;
        }

        // ===================== GUI =====================
        private void OnGUI()
        {
            DrawToolbar();
            EditorGUILayout.BeginHorizontal();
            DrawSidePanel();
            DrawCanvas();
            EditorGUILayout.EndHorizontal();
        }

        private void DrawToolbar()
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("数据源 lua", GUILayout.Width(70));
            _sourcePath = EditorGUILayout.TextField(_sourcePath);
            if (GUILayout.Button("浏览", GUILayout.Width(50))) Pick(ref _sourcePath);
            if (GUILayout.Button("读取", GUILayout.Width(50))) Load();
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("底图目录", GUILayout.Width(70));
            _resRoot = EditorGUILayout.TextField(_resRoot);
            if (GUILayout.Button("浏览", GUILayout.Width(50))) PickFolder(ref _resRoot);
            EditorGUILayout.LabelField("美术目录", GUILayout.Width(60));
            _artRoot = EditorGUILayout.TextField(_artRoot);
            if (GUILayout.Button("浏览", GUILayout.Width(50))) { PickFolder(ref _artRoot); RefreshMonsterIds(); }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("导出 lua", GUILayout.Width(70));
            _exportPath = EditorGUILayout.TextField(_exportPath);
            if (GUILayout.Button("浏览", GUILayout.Width(50))) Pick(ref _exportPath);
            if (GUILayout.Button("导出", GUILayout.Width(50))) Export();
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("地图", GUILayout.Width(40));
            string[] opts = new string[_entries.Count];
            for (int i = 0; i < _entries.Count; i++) opts[i] = $"{_entries[i].id}  {_entries[i].name}";
            if (_entries.Count > 0)
            {
                int prev = _selectedMap;
                _selectedMap = EditorGUILayout.Popup(_selectedMap, opts);
                if (prev != _selectedMap) _needFit = true;
            }
            EditorGUILayout.LabelField("缩放", GUILayout.Width(35));
            _zoom = EditorGUILayout.Slider(_zoom, 0.02f, 1.5f);
            if (GUILayout.Button("适配", GUILayout.Width(50)) && _entries.Count > 0) Fit();
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            _showRole = EditorGUILayout.ToggleLeft("NPC/主角", _showRole, GUILayout.Width(80));
            _showMonster = EditorGUILayout.ToggleLeft("怪物", _showMonster, GUILayout.Width(55));
            _showModel = EditorGUILayout.ToggleLeft("显示模型", _showModel, GUILayout.Width(80));
            _showAnchor = EditorGUILayout.ToggleLeft("显示锚点", _showAnchor, GUILayout.Width(80));
            _snap = EditorGUILayout.ToggleLeft("吸附", _snap, GUILayout.Width(50));
            _gridSize = EditorGUILayout.IntField(_gridSize, GUILayout.Width(50));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("怪物模型", GUILayout.Width(60));
            _monsterId = DrawIdPopup(_monsterIds, ref _monsterIdIdx, _monsterId, "Monster_Bust");
            EditorGUILayout.LabelField("主角模型", GUILayout.Width(60));
            _heroId = DrawIdPopup(_heroIds, ref _heroIdIdx, _heroId, "Role_Bust");
            EditorGUILayout.LabelField("立绘高度(底图px)", GUILayout.Width(115));
            _modelHeight = EditorGUILayout.Slider(_modelHeight, 80f, 1200f);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("立绘贴图偏移 Δ (数据单位，+向上)", GUILayout.Width(190));
            _modelDy = EditorGUILayout.Slider(_modelDy, -200f, 200f);
            EditorGUILayout.LabelField(
                string.Format("（默认 {0:F0}；实际偏移 怪物 {1:F0} / 主角 {2:F0}）",
                    ModelTextureDelta, MonsterAnchorDy + _modelDy, RoleAnchorDy + _modelDy),
                EditorStyles.miniLabel);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.LabelField("左键拖拽标记改坐标；中/右键平移；滚轮缩放。坐标 = 客户端 node 位置（怪物 +100 / 主角 +33）；绿/蓝十字即该锚点。", EditorStyles.miniLabel);
            EditorGUILayout.EndVertical();
        }

        private void DrawSidePanel()
        {
            EditorGUILayout.BeginVertical(GUILayout.Width(250), GUILayout.ExpandHeight(true));
            EditorGUILayout.LabelField("选中标记", EditorStyles.boldLabel);
            if (_selectedMap >= 0 && _selectedMap < _entries.Count && _selIndex >= 0)
            {
                var e = _entries[_selectedMap];
                List<Coor> list = CurList(e, _selType);
                if (_selIndex < list.Count)
                {
                    EditorGUILayout.LabelField($"类型：{TypeName(_selType)}  序号：{_selIndex + 1}/{list.Count}");
                    var c = list[_selIndex];
                    EditorGUI.BeginChangeCheck();
                    int nx = EditorGUILayout.IntField("X", c.x);
                    int ny = EditorGUILayout.IntField("Y", c.y);
                    if (EditorGUI.EndChangeCheck())
                    {
                        c.x = Mathf.Clamp(nx, 0, Mathf.RoundToInt(MaxDataX(e)));
                        c.y = Mathf.Clamp(ny, 0, Mathf.RoundToInt(MaxDataY(e, AnchorDy(_selType))));
                    }
                    float ix = ImgX(c.x);
                    float iy = ImgYFromTop(e, c.y, AnchorDy(_selType));
                    EditorGUILayout.LabelField($"底图像素：({ix:F0}, {iy:F0})", EditorStyles.miniLabel);
                    if (GUILayout.Button("删除该点"))
                    {
                        list.RemoveAt(_selIndex);
                        _selIndex = list.Count > 0 ? Mathf.Min(_selIndex, list.Count - 1) : -1;
                    }
                }
            }
            else
            {
                EditorGUILayout.LabelField("（未选中）");
            }

            EditorGUILayout.Space();
            if (_selectedMap >= 0 && _selectedMap < _entries.Count)
            {
                var e = _entries[_selectedMap];
                EditorGUILayout.LabelField("新增点到当前地图", EditorStyles.boldLabel);
                if (GUILayout.Button("+ NPC/主角点")) AddPoint(e, CoorType.Role);
                if (GUILayout.Button("+ 怪物点")) AddPoint(e, CoorType.Monster);

                EditorGUILayout.Space();
                EditorGUILayout.LabelField("当前地图点位数", EditorStyles.boldLabel);
                EditorGUILayout.LabelField($"NPC/主角 {e.role_coor.Count}   怪物 {e.monster_coor.Count}", EditorStyles.miniLabel);
                EditorGUILayout.LabelField($"数据可用区 0~{MaxDataX(e):F0} × 0~{e.map_size.y * ScreenRate:F0}", EditorStyles.miniLabel);
                EditorGUILayout.LabelField($"底图 {e.map_size.x} × {e.map_size.y}", EditorStyles.miniLabel);
            }
            EditorGUILayout.EndVertical();
        }

        private void DrawCanvas()
        {
            Rect canvas = GUILayoutUtility.GetRect(0, 0, GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
            EditorGUI.DrawRect(canvas, new Color(0.18f, 0.18f, 0.20f));

            GUI.BeginGroup(canvas);
            if (_selectedMap >= 0 && _selectedMap < _entries.Count)
            {
                var e = _entries[_selectedMap];
                DrawTiles(e);
                DrawMapBorder(e);
                if (_snap) DrawGrid(e);
                DrawMarkers(e);
            }
            GUI.EndGroup();
            _canvasRect = canvas;
            if (_needFit) { _needFit = false; Fit(); }

            HandleEvents(canvas);
        }

        // ===================== drawing =====================
        private void DrawTiles(MapEntry e)
        {
            int w = e.map_size.x, h = e.map_size.y;
            int xNum = Mathf.CeilToInt((float)w / 1024f);
            int yNum = Mathf.CeilToInt((float)h / 1024f);
            for (int cnt = 1; cnt <= xNum * yNum; cnt++)
            {
                int col = (cnt - 1) % xNum;
                int row = (cnt - 1) / xNum;
                string file = Path.Combine(_resRoot, e.name, $"map_{cnt}.jpg");
                Texture2D tex = LoadTexture(file);
                if (tex == null) continue;
                float px = _pan.x + col * 1024 * _zoom;
                float py = _pan.y + row * 1024 * _zoom;
                GUI.DrawTexture(new Rect(px, py, tex.width * _zoom, tex.height * _zoom), tex, ScaleMode.StretchToFill, true);
            }
        }

        private void DrawMapBorder(MapEntry e)
        {
            float w = e.map_size.x * _zoom;
            float h = e.map_size.y * _zoom;
            float lw = 2f;
            EditorGUI.DrawRect(new Rect(_pan.x, _pan.y, w, lw), Color.white);
            EditorGUI.DrawRect(new Rect(_pan.x, _pan.y + h - lw, w, lw), Color.white);
            EditorGUI.DrawRect(new Rect(_pan.x, _pan.y, lw, h), Color.white);
            EditorGUI.DrawRect(new Rect(_pan.x + w - lw, _pan.y, lw, h), Color.white);
            GUI.Label(new Rect(_pan.x + 4, _pan.y + 4, 300, 18), $"{e.id} {e.name}  底图 {e.map_size.x}x{e.map_size.y}");

            // 数据可用区（数据坐标有效范围），超出此框的点位不会被客户端渲染在底图内
            float dw = MaxDataX(e) * DataToImage * _zoom;
            float dh = e.map_size.y * ScreenRate * DataToImage * _zoom;
            Color old = GUI.color;
            GUI.color = new Color(0f, 1f, 0.6f, 0.55f);
            float t = 2f;
            EditorGUI.DrawRect(new Rect(_pan.x, _pan.y, dw, t), GUI.color);
            EditorGUI.DrawRect(new Rect(_pan.x, _pan.y + dh - t, dw, t), GUI.color);
            EditorGUI.DrawRect(new Rect(_pan.x, _pan.y, t, dh), GUI.color);
            EditorGUI.DrawRect(new Rect(_pan.x + dw - t, _pan.y, t, dh), GUI.color);
            GUI.color = old;
        }

        private void DrawGrid(MapEntry e)
        {
            if (_gridSize <= 0) return;
            float step = _gridSize * DataToImage * _zoom; // 数据单位 -> 底图像素 -> 屏幕
            if (step < 3f) return;
            float w = e.map_size.x * _zoom;
            float h = e.map_size.y * _zoom;
            Color line = new Color(1, 1, 1, 0.14f);
            for (float sx = _pan.x; sx <= _pan.x + w; sx += step)
                EditorGUI.DrawRect(new Rect(sx, _pan.y, 1f, h), line);
            for (float sy = _pan.y; sy <= _pan.y + h; sy += step)
                EditorGUI.DrawRect(new Rect(_pan.x, sy, w, 1f), line);
        }

        private void DrawMarkers(MapEntry e)
        {
            if (_showRole) DrawSet(e, e.role_coor, CoorType.Role, ColorRole);
            if (_showMonster) DrawSet(e, e.monster_coor, CoorType.Monster, ColorMonster);
        }

        private void DrawSet(MapEntry e, List<Coor> list, CoorType type, Color col)
        {
            if (_showModel && type != CoorType.Camera)
            {
                for (int i = 0; i < list.Count; i++)
                    DrawModel(e, list[i], type, i == _selIndex && type == _selType);
            }

            for (int i = 0; i < list.Count; i++)
            {
                var c = list[i];
                float ax = _pan.x + ImgX(c.x) * _zoom;
                float ay = _pan.y + ImgYFromTop(e, c.y, AnchorDy(type)) * _zoom; // 锚点 = 客户端 node 位置
                bool selected = (type == _selType && i == _selIndex);

                // 可视模型中心（怪物模型子节点 -85）
                float mx = _pan.x + ImgX(c.x) * _zoom;
                float my = _pan.y + ImgYFromTop(e, c.y, ModelDy(type)) * _zoom;

                if (_showAnchor)
                {
                    float cw = 2f;
                    Color old = GUI.color;
                    GUI.color = selected ? Color.white : new Color(col.r, col.g, col.b, 0.85f);
                    EditorGUI.DrawRect(new Rect(ax - 7, ay - cw / 2f, 14, cw), GUI.color);
                    EditorGUI.DrawRect(new Rect(ax - cw / 2f, ay - 7, cw, 14), GUI.color);
                    GUI.color = old;
                }

                if (!_showModel || type == CoorType.Camera)
                {
                    Color old = GUI.color;
                    GUI.color = col;
                    GUI.DrawTexture(new Rect(mx - HandleRadius, my - HandleRadius, HandleRadius * 2, HandleRadius * 2), _circleTex, ScaleMode.StretchToFill, true);
                    GUI.color = old;
                }

                if (selected)
                {
                    float r = HandleRadius + 4f;
                    EditorGUI.DrawRect(new Rect(mx - r - 2, my - r - 2, (r + 2) * 2, 2f), Color.white);
                    EditorGUI.DrawRect(new Rect(mx - r - 2, my + r, (r + 2) * 2, 2f), Color.white);
                }

                if (_zoom > 0.08f)
                    GUI.Label(new Rect(mx + HandleRadius + 4, my - 9, 70, 18), (i + 1).ToString());
            }
        }

        /// <summary>绘制真实立绘：怪物取 res2/Monster_Bust/&lt;id&gt;.png，主角取 res2/Role_Bust/&lt;id&gt;.png。</summary>
        private void DrawModel(MapEntry e, Coor c, CoorType type, bool selected)
        {
            Texture2D tex = type == CoorType.Monster ? LoadMonsterTex() : LoadHeroTex();
            if (tex == null) return;
            Rect bbox = OpaqueBounds(tex);
            if (bbox.width < 1f || bbox.height < 1f) return;

            // 主角点与怪物点常常相邻，主角略小以免遮挡
            float targetH = (type == CoorType.Monster) ? _modelHeight : _modelHeight * 0.8f;
            float scale = targetH / bbox.height;
            float w = tex.width * scale;
            float h = tex.height * scale;

            float cx = _pan.x + ImgX(c.x) * _zoom;
            float cy = _pan.y + ImgYFromTop(e, c.y, ModelDy(type)) * _zoom;

            // bbox 中心对齐到 (cx, cy)；贴图像素 y 向上，屏幕 y 向下，故需翻转
            float bcx = (bbox.xMin + bbox.xMax) * 0.5f;
            float bcScreen = tex.height - (bbox.yMin + bbox.yMax) * 0.5f;
            var r = new Rect(cx - bcx * scale * _zoom, cy - bcScreen * scale * _zoom, w * _zoom, h * _zoom);

            Color old = GUI.color;
            GUI.color = selected ? Color.white : new Color(1f, 1f, 1f, 0.92f);
            GUI.DrawTexture(r, tex, ScaleMode.StretchToFill, true);
            GUI.color = old;
        }

        // ===================== events =====================
        private void HandleEvents(Rect canvas)
        {
            Event ev = Event.current;
            Vector2 mouse = ev.mousePosition - canvas.position;
            if (!canvas.Contains(ev.mousePosition)) return;

            if (ev.type == EventType.ScrollWheel)
            {
                float factor = ev.delta.y < 0 ? 1.1f : 1f / 1.1f;
                float newZoom = Mathf.Clamp(_zoom * factor, 0.02f, 1.5f);
                Vector2 mapPt = (mouse - _pan) / _zoom;
                _zoom = newZoom;
                _pan = mouse - mapPt * _zoom;
                ev.Use();
                Repaint();
                return;
            }

            if (ev.type == EventType.MouseDown)
            {
                if (ev.button == 0)
                {
                    int hit = HitTest(mouse, out CoorType t);
                    if (hit >= 0)
                    {
                        _selType = t; _selIndex = hit;
                        _draggingMarker = true;
                        _dragStartMouse = mouse;
                        var cur = CurList(_entries[_selectedMap], t)[hit];
                        _dragStartVal = new Vector2(cur.x, cur.y);
                        ev.Use(); Repaint();
                    }
                }
                else
                {
                    _panning = true;
                    _dragStartMouse = mouse;
                    _dragStartPan = _pan;
                    ev.Use();
                }
            }
            else if (ev.type == EventType.MouseDrag)
            {
                if (_draggingMarker && _selectedMap >= 0 && _selectedMap < _entries.Count)
                {
                    var e = _entries[_selectedMap];
                    var list = CurList(e, _selType);
                    if (_selIndex >= 0 && _selIndex < list.Count)
                    {
                        Vector2 d = (mouse - _dragStartMouse) / _zoom; // 屏幕像素 -> 底图像素
                        float nx = _dragStartVal.x + d.x * ScreenRate; // 底图像素 -> 数据
                        float ny = _dragStartVal.y - d.y * ScreenRate;
                        int x = Mathf.RoundToInt(nx);
                        int y = Mathf.RoundToInt(ny);
                        if (_snap && _gridSize > 0)
                        {
                            x = Mathf.RoundToInt((float)x / _gridSize) * _gridSize;
                            y = Mathf.RoundToInt((float)y / _gridSize) * _gridSize;
                        }
                        x = Mathf.Clamp(x, 0, Mathf.RoundToInt(MaxDataX(e)));
                        y = Mathf.Clamp(y, 0, Mathf.RoundToInt(MaxDataY(e, AnchorDy(_selType))));
                        list[_selIndex].x = x; list[_selIndex].y = y;
                        ev.Use(); Repaint();
                    }
                }
                else if (_panning)
                {
                    _pan = _dragStartPan + (mouse - _dragStartMouse);
                    ev.Use(); Repaint();
                }
            }
            else if (ev.type == EventType.MouseUp)
            {
                _draggingMarker = false;
                _panning = false;
                ev.Use();
            }
        }

        private int HitTest(Vector2 mouse, out CoorType type)
        {
            type = CoorType.Role;
            if (_selectedMap < 0 || _selectedMap >= _entries.Count) return -1;
            var e = _entries[_selectedMap];
            int m = TestSet(e, e.monster_coor, CoorType.Monster, mouse); if (m >= 0) { type = CoorType.Monster; return m; }
            int r = TestSet(e, e.role_coor, CoorType.Role, mouse); if (r >= 0) { type = CoorType.Role; return r; }
            return -1;
        }

        private int TestSet(MapEntry e, List<Coor> list, CoorType type, Vector2 mouse)
        {
            if (type == CoorType.Role && !_showRole) return -1;
            if (type == CoorType.Monster && !_showMonster) return -1;
            float pick = HandleRadius + 6f;
            for (int i = list.Count - 1; i >= 0; i--)
            {
                float mx = _pan.x + ImgX(list[i].x) * _zoom;
                float my = _pan.y + ImgYFromTop(e, list[i].y, ModelDy(type)) * _zoom;
                if (Vector2.Distance(mouse, new Vector2(mx, my)) <= pick) return i;
            }
            return -1;
        }

        private void Fit()
        {
            if (_selectedMap < 0 || _selectedMap >= _entries.Count) return;
            var e = _entries[_selectedMap];
            float availW = (_canvasRect.width > 1 ? _canvasRect.width : position.width - 270);
            float availH = (_canvasRect.height > 1 ? _canvasRect.height : position.height - 200);
            float zx = availW / e.map_size.x;
            float zy = availH / e.map_size.y;
            _zoom = Mathf.Clamp(Mathf.Min(zx, zy) * 0.95f, 0.02f, 1.5f);
            float w = e.map_size.x * _zoom;
            float h = e.map_size.y * _zoom;
            _pan = new Vector2((availW - w) / 2f, (availH - h) / 2f);
        }

        // ===================== data ops =====================
        private List<Coor> CurList(MapEntry e, CoorType t)
        {
            if (t == CoorType.Role) return e.role_coor;
            if (t == CoorType.Monster) return e.monster_coor;
            return e.camera_coor;
        }

        private void AddPoint(MapEntry e, CoorType t)
        {
            var list = CurList(e, t);
            int cx = Mathf.RoundToInt(MaxDataX(e) * 0.5f);
            int cy = Mathf.RoundToInt(Mathf.Max(0f, MaxDataY(e, AnchorDy(t)) * 0.5f));
            list.Add(new Coor(cx, cy));
            _selType = t; _selIndex = list.Count - 1;
            Repaint();
        }

        private void Load()
        {
            if (!File.Exists(_sourcePath)) { Debug.LogError("[MapEditor] 数据源不存在: " + _sourcePath); return; }
            _entries = ParseLua(File.ReadAllText(_sourcePath));
            _selectedMap = Mathf.Clamp(_selectedMap, 0, Mathf.Max(0, _entries.Count - 1));
            _selIndex = -1;
            _texCache.Clear();
            _needFit = _entries.Count > 0;
            Debug.Log($"[MapEditor] 已读取 {_entries.Count} 张地图");
        }

        private void Export()
        {
            if (_entries.Count == 0) { Debug.LogWarning("[MapEditor] 无数据可导出"); return; }
            string text = BuildLua(_entries);
            File.WriteAllText(_exportPath, text);
            Debug.Log($"[MapEditor] 已导出 {_entries.Count} 张地图 -> {_exportPath}");
            string resCopy = Path.Combine(Application.dataPath, "ProjectX", "Resources", "WorldUI", "Config", "map_res_dat.txt");
            if (File.Exists(resCopy) && EditorUtility.DisplayDialog("同步 Resources", "是否同时覆盖 Unity Resources 的 map_res_dat.txt？", "是", "否"))
            {
                File.WriteAllText(resCopy, text);
                Debug.Log("[MapEditor] 已同步 Resources/WorldUI/Config/map_res_dat.txt");
            }
        }

        // ===================== lua parse / build =====================
        private static readonly Regex ReField = new Regex(@"^\s*(\w+)\s*=\s*(.*)$");
        private static readonly Regex RePair = new Regex(@"\{(\d+),(\d+)\}");

        private List<MapEntry> ParseLua(string text)
        {
            var list = new List<MapEntry>();
            MapEntry cur = null;
            var lines = text.Split('\n');
            foreach (var raw in lines)
            {
                string line = raw.TrimEnd('\r').Trim();
                if (line == "{") { cur = new MapEntry(); continue; }
                if (line == "}" || line == "},")
                {
                    if (cur != null) { list.Add(cur); cur = null; }
                    continue;
                }
                if (cur == null) continue;

                var m = ReField.Match(line);
                if (!m.Success) continue;
                string key = m.Groups[1].Value;
                string val = m.Groups[2].Value.Trim().TrimEnd(',');

                if (key == "id") { int.TryParse(val, out cur.id); }
                else if (key == "name") { cur.name = val.Trim('"'); }
                else if (key == "map_size")
                {
                    var p = RePair.Match(val);
                    if (p.Success) cur.map_size = new Coor(int.Parse(p.Groups[1].Value), int.Parse(p.Groups[2].Value));
                }
                else if (key.EndsWith("_coor"))
                {
                    var coors = new List<Coor>();
                    foreach (Match pm in RePair.Matches(val))
                        coors.Add(new Coor(int.Parse(pm.Groups[1].Value), int.Parse(pm.Groups[2].Value)));
                    if (key == "role_coor") cur.role_coor = coors;
                    else if (key == "monster_coor") cur.monster_coor = coors;
                    else if (key == "camera_coor") cur.camera_coor = coors;
                }
            }
            return list;
        }

        private string BuildLua(List<MapEntry> entries)
        {
            var sb = new StringBuilder();
            sb.Append("map_res_dat = {\n");
            for (int i = 0; i < entries.Count; i++)
            {
                var e = entries[i];
                sb.Append("\t{\n");
                sb.Append("\t\tid = ").Append(e.id).Append(",\n");
                sb.Append("\t\tname = \"").Append(e.name).Append("\",\n");
                sb.Append("\t\trole_coor = ").Append(CoorList(e.role_coor)).Append(",\n");
                sb.Append("\t\tmonster_coor = ").Append(CoorList(e.monster_coor)).Append(",\n");
                sb.Append("\t\tcamera_coor = ").Append(CoorList(e.camera_coor)).Append(",\n");
                sb.Append("\t\tmap_size = {{").Append(e.map_size.x).Append(",").Append(e.map_size.y).Append("}}\n");
                sb.Append(i == entries.Count - 1 ? "\t}\n" : "\t},\n");
            }
            sb.Append("}\n\nreturn map_res_dat\n");
            return sb.ToString();
        }

        private string CoorList(List<Coor> list)
        {
            if (list == null || list.Count == 0) return "{}";
            var parts = new List<string>();
            foreach (var c in list) parts.Add("{" + c.x + "," + c.y + "}");
            return "{" + string.Join(",", parts) + "}";
        }

        private string TypeName(CoorType t)
        {
            return t == CoorType.Role ? "NPC/主角" : (t == CoorType.Monster ? "怪物" : "镜头");
        }

        // ===================== texture helpers =====================
        private Texture2D LoadTexture(string file)
        {
            if (_texCache.TryGetValue(file, out var cached)) return cached;
            Texture2D tex = null;
            if (File.Exists(file))
            {
                try
                {
                    var bytes = File.ReadAllBytes(file);
                    tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
                    tex.LoadImage(bytes);
                }
                catch (System.Exception ex) { Debug.LogWarning("[MapEditor] 贴图加载失败 " + file + " " + ex.Message); }
            }
            _texCache[file] = tex;
            return tex;
        }

        /// <summary>兼容旧配置：美术根目录下若没有 Monster_Bust，则依次尝试 res2 与默认位置。</summary>
        private string ArtRootResolved()
        {
            var cands = new List<string>
            {
                _artRoot,
                string.IsNullOrEmpty(_artRoot) ? null : Path.Combine(_artRoot, "res2"),
                DefaultArtRoot(),
                Path.GetFullPath(Path.Combine(ProjectRoot(), "..", "client", "ProjectX", "res2")),
            };
            foreach (var c in cands)
                if (!string.IsNullOrEmpty(c) && Directory.Exists(Path.Combine(c, "Monster_Bust"))) return c;
            return _artRoot;
        }

        // 单帧立绘：res2/Monster_Bust/<monsterId>.png、res2/Role_Bust/<heroId>.png
        //（res/Monster/btm*_zd_show.png 是动画图集、含多帧，不能直接当标记；故取 Bust 单图）
        private Texture2D LoadMonsterTex() { return LoadTexture(Path.Combine(ArtRootResolved(), "Monster_Bust", _monsterId + ".png")); }
        private Texture2D LoadHeroTex() { return LoadTexture(Path.Combine(ArtRootResolved(), "Role_Bust", _heroId + ".png")); }

        /// <summary>粗采样求不透明包围盒（贴图像素坐标，y 向上）。</summary>
        private readonly Dictionary<Texture2D, Rect> _boundsCache = new Dictionary<Texture2D, Rect>();
        private Rect OpaqueBounds(Texture2D tex)
        {
            if (_boundsCache.TryGetValue(tex, out var r)) return r;
            int step = Mathf.Max(1, Mathf.Max(tex.width, tex.height) / 256);
            int xMin = tex.width, xMax = -1, yMin = tex.height, yMax = -1;
            for (int y = 0; y < tex.height; y += step)
                for (int x = 0; x < tex.width; x += step)
                    if (tex.GetPixel(x, y).a > 0.02f)
                    {
                        if (x < xMin) xMin = x; if (x > xMax) xMax = x;
                        if (y < yMin) yMin = y; if (y > yMax) yMax = y;
                    }
            r = (xMax < 0) ? new Rect(0, 0, tex.width, tex.height)
                           : new Rect(xMin, yMin, xMax - xMin + 1, yMax - yMin + 1);
            _boundsCache[tex] = r;
            return r;
        }

        private static int DrawIdPopup(List<int> ids, ref int idx, int cur, string label)
        {
            if (ids.Count == 0)
            {
                EditorGUILayout.LabelField($"未找到 {label}/", GUILayout.Width(140));
                return cur;
            }
            if (idx < 0 || idx >= ids.Count) idx = Mathf.Max(0, ids.IndexOf(cur));
            string[] opts = new string[ids.Count];
            for (int i = 0; i < ids.Count; i++) opts[i] = ids[i].ToString();
            int ni = EditorGUILayout.Popup(idx, opts, GUILayout.Width(90));
            if (ni != idx) idx = ni;
            return ids[idx];
        }

        private static List<int> ScanIds(string dir)
        {
            var ids = new List<int>();
            if (!Directory.Exists(dir)) return ids;
            var re = new Regex(@"^(\d+)\.png$");
            foreach (var f in Directory.GetFiles(dir, "*.png"))
            {
                var m = re.Match(Path.GetFileName(f));
                if (m.Success) ids.Add(int.Parse(m.Groups[1].Value));
            }
            ids.Sort();
            return ids;
        }

        private void RefreshMonsterIds()
        {
            _monsterIds = ScanIds(Path.Combine(ArtRootResolved(), "Monster_Bust"));
            _heroIds = ScanIds(Path.Combine(ArtRootResolved(), "Role_Bust"));
            _monsterIdIdx = _monsterIds.IndexOf(_monsterId);
            _heroIdIdx = _heroIds.IndexOf(_heroId);
        }

        private static Texture2D MakeCircleTexture()
        {
            int s = 32;
            var t = new Texture2D(s, s, TextureFormat.RGBA32, false);
            Color[] px = new Color[s * s];
            Vector2 c = new Vector2(s / 2f, s / 2f);
            for (int y = 0; y < s; y++)
                for (int x = 0; x < s; x++)
                {
                    float d = Vector2.Distance(new Vector2(x + 0.5f, y + 0.5f), c);
                    px[y * s + x] = d <= s / 2f - 1f ? Color.white : (d <= s / 2f ? new Color(1, 1, 1, 0.4f) : Color.clear);
                }
            t.SetPixels(px);
            t.Apply();
            return t;
        }

        private void Pick(ref string field)
        {
            string p = EditorUtility.OpenFilePanel("选择 lua", field, "lua");
            if (!string.IsNullOrEmpty(p)) field = p;
        }

        private void PickFolder(ref string field)
        {
            string p = EditorUtility.OpenFolderPanel("选择目录", field, "");
            if (!string.IsNullOrEmpty(p)) field = p;
        }
    }
}
