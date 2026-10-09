# kiseki-style · 轨言轨语常驻语气

把《英雄传说 轨迹系列》的「轨言轨语」腔调**常驻**装到 AI agent 上：默认每一轮回复的叙述部分都轨化，代码／命令／路径／报错照旧原样。

## 来源与致谢

「轨言轨语」是 ACGN 圈对 Falcom《轨迹系列》过度滥用定番台词与谜语人表达的调侃。

- 用语分类骨架（可汗大点兵／打招呼寒暄／车轱辘否定／谜语人立场）整理自 [萌娘百科·轨言轨语](https://zh.moegirl.org.cn/%E8%BD%A8%E8%A8%80%E8%BD%A8%E8%AF%AD)（CC BY-NC-SA 3.0）。
- 目录结构与规则组织方式参考了社区既有实现 [kiseki-lang](https://github.com/Vincent-the-gamer/skills)（Apache-2.0）。
- 本项目的脚本与文案自写，按 [MIT](LICENSE) 授权；涉及上述来源的衍生部分请同时遵守其原始许可。

## 包内有什么

| 文件 | 作用 |
| --- | --- |
| `kiseki.md` | 风格细则本体：开关、豁免硬规则、五要素、场景配方、浓度配额、自检清单 |
| `kiseki-state` | 读开关，输出 `on` / `off`（文件不存在按 `on`） |
| `kiseki-toggle` | 切开关：`on` / `off` / `toggle` |
| `kiseki-level` | 读 / 切浓度：`light` / `medium` / `heavy`（默认 `medium`） |
| `agents-block.md` | 要挂进 agent 指令文件的 `<kiseki_style>` 块，`{{KISEKI_DIR}}` 安装时替换 |
| `install.sh` | 一键部署 / 卸载，幂等 |
| `SKILL.md` | skill 形态入口（按需触发用） |

## 装到新设备

```bash
# 1) 把本目录弄到那台机器上（git / AirDrop / scp / U 盘 都行）
git clone <你的仓库地址> ~/kiseki-style

# 2) 跑安装
bash ~/kiseki-style/install.sh

# 3) 想先看会改什么
bash ~/kiseki-style/install.sh --dry-run
```

装完开个新会话就生效。常见选项：

```bash
bash install.sh --dir ~/.kiseki                  # 指定风格文件目录
bash install.sh --agents ~/.codex/AGENTS.md      # 指定挂哪个指令文件
bash install.sh --uninstall                      # 摘掉挂载（风格文件保留）
```

### 它会改哪些文件

- **风格目录**：默认有 `~/.dsh` 就用 `~/.dsh/style`，否则用 `~/.kiseki`
- **指令文件**：自动探测 `~/AGENTS.md` > `~/.claude/CLAUDE.md` > `~/.codex/AGENTS.md`，都没有就新建 `~/AGENTS.md`

改之前一律备份成 `<文件>.bak-<时间戳>-<pid>`。挂载是**幂等**的：重复跑只会替换 `<kiseki_style>…</kiseki_style>` 那一段，**不动**文件里的其他内容——包括 `mtskills` 管理的 `<skills_system>` 区块。

## 用在别的 agent 上

风格细则与脚本跟 agent 无关，只是"挂哪儿"不同：

| agent | 常驻指令文件 |
| --- | --- |
| DSH | `~/AGENTS.md` |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| Cursor 等 | 项目内 `AGENTS.md` 或对应规则文件，用 `--agents` 指过去 |

细则里只有"读开关 / 切开关"两条用到了 shell，任何能跑 bash 的 agent 都能用。

## 按需（skill）形态

不想常驻、只想在点名时轨化，就把本目录当 skill 装：

```bash
cp -r ~/kiseki-style ~/.claude/skills/kiseki-style/   # 或对应 skills 目录
mtskills i <git-url> --skill kiseki-style             # 支持 mtskills 的环境
```

## 开关与浓度

```bash
bash ~/.dsh/style/kiseki-state            # on / off
bash ~/.dsh/style/kiseki-toggle off       # 关
bash ~/.dsh/style/kiseki-toggle on        # 开

bash ~/.dsh/style/kiseki-level            # light / medium / heavy
bash ~/.dsh/style/kiseki-level heavy      # 调浓
bash ~/.dsh/style/kiseki-level light      # 调淡
```

也可以直接跟 agent 说「关闭轨言轨语」「说人话」／「打开轨言轨语」「轨起来」／「浓一点」「淡一点」。

## 硬规则

- 代码块、命令、路径、文件名、报错、配置、URL、结构化数据——**一律原样**，判不准就保留原文。
- 技术结论必须照样准确、完整、可执行，**信息量不许打折**。
- **配额是下限，不是上限**：中度每轮至少 3 处定番台词、1 次车轱辘否定、1 处谜语收尾；有可点名的名字（产品名／工具名／团队名／人名都算）就报菜名；出现"不必麻烦"的语境就用「没有那个必要」。
- 招牌要错开：同一句台词、「——不，应该是……」，不在相邻两段里重复。
- 组织名与称号加书名号《》（如《卡普亚一家》），但代码／路径里的名字**不加**。

## Windows

脚本是 bash 的，用 WSL 或 Git Bash 跑。原生 PowerShell 下就手动复制三个文件，再把 `agents-block.md` 里的 `{{KISEKI_DIR}}` 换成实际路径、粘进指令文件。
