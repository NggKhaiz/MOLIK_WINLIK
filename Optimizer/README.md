# 👑 MOLIK_WINLIK — MOLIK WINLIK by @nggkhaiz

> **Credit:** Phát triển bởi **@nggkhaiz** (repo [MOLIK_WINLIK](https://github.com/NggKhaiz/MOLIK_WINLIK)) — dựa trên [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows) của farag2 và tích hợp data [winutil](https://github.com/ChrisTitusTech/winutil) của Chris Titus Tech (đều MIT).

Tool tối ưu Windows **sâu & cực mạnh** xây trên nền [Sophia Script for Windows](https://github.com/farag2/Sophia-Script-for-Windows) gốc (`src/`), bổ sung engine riêng trong `Optimizer/` với **197 tweak** chia 9 nhóm, **6 mode chuyên dụng** và giao diện **tick-chọn CLI** `[✓]/[ ]` bằng phím.

## 📴 OFFLINE 100% — chạy đơn giản: double-click là xong (tự xin Admin)

MOLIK WINLIK **không còn bản online** (`irm | iex` đã bị loại bỏ: Windows Defender/AMSI
chặn chạy code trong bộ nhớ và ExecutionPolicy chặn chạy file lạ — hai lỗi thực tế đã gặp).
Bản chính thức là **offline hoàn toàn**: tải/nhận bản **một lần duy nhất**, sau đó chạy
không cần Internet, không tải thêm code khi chạy.

### Cách chạy chuẩn (khuyên dùng)

1. Tải file ZIP của repo này (nút **Code → Download ZIP** trên GitHub) hoặc nhận cả thư mục
   qua USB/LAN. Giải nén vào bất kỳ đâu (Desktop, `D:\MOLIK_WINLIK`...).
2. **Double-click `MOLIK_WINLIK.bat`** → bấm **Yes** ở hộp UAC → giao diện tick-chọn mở ra.
   Xong. Không cài đặt, không sửa ExecutionPolicy của máy (`Bypass` chỉ áp cho đúng
   tiến trình PowerShell mà .bat khởi chạy).

`MOLIK_WINLIK.bat` tự tìm `MolikWinlik-Portable.ps1` (bản 1 file, chứa toàn bộ engine +
197 tweak + data 239 app) ngay cạnh nó. Giữ 2 file này cùng thư mục là đủ chạy ở mọi máy.

### Chạy bằng PowerShell (khi đã mở sẵn terminal Admin)

```powershell
.\MolikWinlik-Portable.ps1            # ban 1 file (offline)
.\MolikWinlik-Portable.ps1 -Menu      # menu so don gian
.\MolikWinlik.ps1                     # trong repo (nap engine tu Optimizer/)
```

Lệnh chỉ-đọc (`-ListModes`, `-ListTweaks`, `-ListApps`, `-Plan`, `-SelfTest`,
`-CompareBenchmarks`) **không cần Admin** và không hiện UAC. Thao tác áp dụng tweak
tự nâng quyền qua UAC như trước.

### Toàn vẹn file khi nhận bản qua người khác

Đối chiếu SHA256 của `MolikWinlik-Portable.ps1` với file `MolikWinlik-Portable.ps1.sha256`
đi kèm (hoặc trên repo):

```powershell
Get-FileHash .\MolikWinlik-Portable.ps1 -Algorithm SHA256
```

### Tên file cũ (tương thích ngược)

`Sophia-Optimizer.ps1`, `Sophia-Ultra-Portable.ps1`, `Sophia-1Click.bat`,
`Run-Sophia-Optimizer.bat` chỉ còn là shim chuyển tiếp sang tên mới — đừng dùng cho
bản phát hành mới. `win.ps1` / `docs/win.ps1` / `Sophia-Ultra-Standalone.ps1` (bản
online cũ) đã bị xóa hẳn.

## 🎛️ 6 Mode tối ưu riêng cho từng nhu cầu

| Phím | Mode | Dành cho |
|---|---|---|
| `1` | 🖥️ **TREO GIẢ LẬP 24/7** | Farm multi-instance LDPlayer / MuMu / NoxPlayer / BlueStacks / MEmu: tắt VBS/Hyper-V tranh VT-x, Auto RAM Cleaner mỗi 15', pagefile cố định lớn, không ngủ/USB suspend, Defender exclusion cho thư mục giả lập, boost priority process giả lập |
| `2` | 🎮 **HARDCORE GAMING** | FPS/esports low-latency: HAGS, tắt MPO/Game DVR, BCD timer latency, Nagle off, `NetworkThrottlingIndex=0`, `SystemResponsiveness=0`, chuột 1:1, Ultimate Performance |
| `3` | 🎬 **WORKSTATION / STREAM** | Render/OBS/compile: mạnh nhưng giữ ổn định & mitigations, ưu tiên GPU encode/foreground |
| `4` | 🥔 **LOW-SPEC / POTATO PC** | Máy yếu RAM ≤8GB: tắt visual effects, services/background apps/telemetry thừa |
| `5` | 🛡️ **MOLIK STANDARD** | Privacy + gọn gàng an toàn, không đụng kernel/BCD (tên khóa nội bộ vẫn là `SophiaStandard` để tương thích Profile cũ) |
| `6` | 👑 **GOD MODE** | Toàn bộ 197 tweak kể cả nhóm `Extreme` (tắt Spectre/Meltdown mitigations...) — chỉ khi đã backup |

## ⌨️ Điều khiển trong CLI

| Phím | Tác dụng |
|---|---|
| `↑` `↓` / `K` `J` | Di chuyển |
| `SPACE` | Tick / bỏ tick tweak |
| `1`–`6` hoặc `M` | Chuyển Mode (tick sẵn theo mode) |
| `A` / `N` | Tick tất cả / bỏ tất cả (trong danh sách đang lọc) |
| `/` | Tìm kiếm tweak |
| `P` | Purge RAM ngay (EmptyWorkingSet + Standby List qua NTAPI) |
| `E` | Emulator Auto-Booster (nâng priority process giả lập + purge RAM) |
| `B` | Tạo backup ngay |
| `R` | Restore mặc định toàn bộ |
| `ENTER` | **Áp dụng** các tweak đã tick (tự backup trước) |
| `Q` / `Esc` | Thoát |

## 🖥️ Chế độ không tương tác (automation)

```powershell
.\MolikWinlik.ps1 -Mode EmulatorFarm -Apply -Yes   # áp dụng thẳng 1 mode
.\MolikWinlik.ps1 -Mode HardcoreGaming              # mở CLI đã tick sẵn mode Gaming
.\MolikWinlik.ps1 -ListModes                        # xem 6 mode
.\MolikWinlik.ps1 -ListTweaks                       # liệt kê 197 tweak
.\MolikWinlik.ps1 -PurgeRAM                         # dọn RAM ngay
.\MolikWinlik.ps1 -BoostEmulators                   # boost process giả lập
.\MolikWinlik.ps1 -ExportReport                     # xuất JSON báo cáo phần cứng + catalog
.\MolikWinlik.ps1 -RestoreDefaults -Yes             # khôi phục mặc định
```

## 🔬 v3.3 — DEEPER: kiểm chứng sau áp dụng + audit sâu catalog

- **Tự kiểm chứng sau khi áp dụng**: mỗi tweak áp xong được chạy lại CheckScript — kết quả phiên tách rõ `verified` (trạng thái thật đã đạt) và `unverified` (đã chạy nhưng không xác nhận được trạng thái, ví dụ tweak hành động 1 lần). Trước khi áp còn quét nhanh số tweak đã ở trạng thái đích. Hết cảnh "báo OK nhưng registry ghi thất bại bị nuốt lỗi".
- **Audit sâu toàn catalog**: sửa restore thiếu đối xứng (SYS01/SYS02/EXT14/EXT15/EXT78 khôi phục thiếu service/task đã tắt), RAM04 restore vô nghĩa, NET02 restore thiếu ECN/timestamps; viết lại Check thật cho NET01/NET04/NET05/RAM08/EXT05/EXT06/EXT36/EXT45/EXT69 (trước luôn báo chưa áp).
- **Sửa lỗi tràn DWORD**: GAM08/RAM09 dùng 4294967295 vượt giới hạn DWord có dấu khiến lệnh ghi bị nuốt lỗi âm thầm — nay dùng -1 (đúng cùng 32 bit 0xFFFFFFFF).
- **GPU05 viết lại**: chỉ áp DisableDynamicPstate lên adapter NVIDIA thật (quét DriverDesc) thay vì ghi cứng vào adapter `0000` có thể là iGPU.
- **Tweak sâu mới**: EXT85 tắt Delivery Optimization (DoSvc), EXT86 tắt Diagnostic Policy Service/SRUM — tổng **197 tweak**.
- SelfTest có thêm kiểm tra xung đột registry (cùng khóa, khác giá trị đích) chạy thật trên Windows.

## 🎨 v3.2 — TUI tối giản chuyên nghiệp

Viết lại khung hiển thị của giao diện tick-chọn theo chuẩn công cụ terminal gọn: **3 dòng header** (tiêu đề + tab Mode + trạng thái), danh sách **1 dòng/tweak** cột thẳng hàng (`[x] ID  Tên ... EXT/MOD`), **panel chi tiết cố định 2 dòng ở đáy** (danh sách không còn nhảy layout khi di chuyển), **1 dòng phím tắt duy nhất** — toàn bộ phím đầy đủ nằm trong màn hình `?`. Bỏ hộp viền, emoji và các dải hướng dẫn chiếm chỗ; Menu đơn giản và header Plan cũng gọn theo cùng phong cách. Mọi phím tắt/chức năng giữ nguyên.

## 🩺 v3.1 — Hoàn thiện & An toàn (đợt CONTINUE)

- **Hoàn tác phiên gần nhất `-UndoLast`** (phím `U` trong cả 2 giao diện): đọc log phiên áp dụng mới nhất, chạy khôi phục mặc định cho đúng các tweak đã áp thành công theo thứ tự ngược — sai một phiên là lùi lại được ngay.
- **`-Doctor`**: chẩn đoán chỉ-đọc sau tối ưu — chờ restart, VT-x, VBS/HVCI, HAGS/MPO, ổ gần đầy, laptop — kèm danh sách tweak Extreme đang có hiệu lực.
- **`-ListBackups` / `-ListProfiles`**: liệt kê backup (đúng thư mục `Backup_*`) và profile đã lưu. Đã sửa lỗi bản cũ chọn nhầm thư mục `Logs/Profiles` làm "backup mới nhất" khiến khôi phục rỗng.
- **TUI mượt hơn nữa**: tự xóa phần dư của khung hình trước (hết rác khi danh sách rút ngắn), vẽ lại sạch sau mỗi phím chức năng, tự thích ứng khi đổi kích thước cửa sổ; mở TUI từ Menu không còn làm sập Menu trên host lạ; mọi đường áp dụng đều truyền đúng Snapshot cho Plan Engine.
- `-Apply -DryRun` xem trước không còn bị hỏi xác nhận thừa.

## 🆕 v3.0 — Đa năng & Giao diện chuyên nghiệp

### 🎁 Presets theo kịch bản (phím `X` trong Menu, hoặc `-Preset`)

```powershell
.\MolikWinlik.ps1 -ListPresets
.\MolikWinlik.ps1 -Preset esports-fps -Plan        # xem ke hoach truoc
.\MolikWinlik.ps1 -Preset farm-max -Apply -Yes     # ap dung thang
.\MolikWinlik.ps1 -Preset privacy-max -DryRun      # xem danh sach, chua chay
```

7 preset: `farm-max`, `farm-safe-247` (không Extreme), `esports-fps`, `streamer-workstation`, `potato-plus`, `privacy-max`, `god-safe` (toàn catalog trừ Extreme).

### 🎛️ Áp dụng / khôi phục theo ID, xem trạng thái, backup độc lập

```powershell
.\MolikWinlik.ps1 -ApplyIds "EXT76,EXT81,GAM05" -Yes   # chi ap dung dung cac ID nay
.\MolikWinlik.ps1 -RestoreIds "EXT81" -Yes             # khoi phuc rieng tung ID
.\MolikWinlik.ps1 -Status ""                           # quet toan bo: DA AP / CHUA (khong can Admin)
.\MolikWinlik.ps1 -Status "EXT01,GPU01"                # kiem tra rieng vai ID
.\MolikWinlik.ps1 -BackupOnly                          # chi tao Restore Point + backup
.\MolikWinlik.ps1 -RestoreBackup -Yes                  # nap lai backup moi nhat
.\MolikWinlik.ps1 -Version                             # phien ban + thong ke catalog
```

Chạy automation bằng `-Apply -Yes` / `-Preset ... -Apply -Yes` **không còn bị kẹt** ở câu hỏi restart cuối quy trình (bản cũ luôn `Read-Host` dù đã `-Yes`).

### 📄 Báo cáo HTML Dashboard (phím `H`)

`-ExportReport` nay sinh **cả JSON lẫn HTML**: dashboard tĩnh (mở bằng trình duyệt, offline) gồm thông số máy, trạng thái chờ restart, bảng 6 Mode + Impact Score, và toàn bộ 197 tweak với trạng thái Đã áp/Chưa. Gửi kèm file này khi cần hỗ trợ kỹ thuật.

### 🖥️ Giao diện tick-chọn nâng cấp

- Vẽ lại bằng đưa con trỏ về đầu trang (hết nhấp nháy Clear liên tục), tên tweak tự cắt theo chiều rộng cửa sổ, badge rủi ro `[SAFE]/[MOD]/[EXT]`, panel chi tiết tự xuống dòng + nhãn **Cần RESTART**.
- Phím **`F`**: đổi bộ lọc All → Selected → Extreme → NotApplied. Phím **`?`**: màn hình trợ giúp đầy đủ. Phím **`H`**: xuất báo cáo HTML ngay trong TUI.
- Đã sửa lỗi TUI cũ: biến trạng thái "đã áp dụng" chưa khởi tạo khiến giao diện văng ngay khung đầu (hay rơi về Menu đơn giản).

## 🧩 Kiến trúc

```
MolikWinlik.ps1                 # Entry point trong repo v3.0 (self-elevate Admin, CLI + non-interactive)
MolikWinlik-Portable.ps1        # Ban 1 FILE offline (sinh boi Optimizer/Build-Portable.ps1)
MOLIK_WINLIK.bat                # Double-click: tu xin Admin -> chay Portable (offline 100%)
Optimizer/
  Core/HardwareDetector.ps1     # Nhận diện CPU/RAM/GPU/SSD, VBS/HVCI/Hyper-V, giả lập đã cài
  Core/RamCleanerDaemon.ps1     # NTAPI EmptyWorkingSet + NtSetSystemInformation purge Standby List,
                                # Scheduled Task SYSTEM tự dọn RAM 24/7 khi RAM >70%
  Core/BackupRestore.ps1        # System Restore Point + export Registry/BCD + rollback
  Core/ExtremeEngine.ps1        # MSI interrupts, Timer 0.5ms daemon, Process Booster affinity,
                                # IFEO priority, NIC advanced, powercfg cực hạn, NTFS/ULPS
  Core/Benchmark.ps1            # Benchmark CPU/Disk/RAM Before-After + so sánh %
  Core/PlanEngine.ps1           # Lập kế hoạch: phụ thuộc/mâu thuẫn/8 pha/Impact Score/cảnh báo
  Core/SmartAdvisor.ps1         # Tự khuyên Mode + tweak theo phần cứng thật của máy
  Core/Presets.ps1              # 7 Preset theo kich ban (Farm/Esports/Streamer/Potato/Privacy/GodSafe)
  Core/ReportEngine.ps1         # Xuat Dashboard HTML + quet trang thai da ap dung
  Core/WinUtilBridge.ps1        # Cầu nối winutil (Chris Titus Tech, MIT) -> tweak bản địa, offline
  Core/AppInstaller.ps1         # Cài 239 app qua winget (data vendor từ winutil)
  Data/WinUtilTweaks.ps1        # 25 tweak winutil đã chuyển đổi + LICENSE-winutil.txt
  Data/WinUtilApps.ps1          # 239 ứng dụng winget/choco
  Core/SophiaBridge.ps1         # Bridge vào Sophia.psm1 gốc theo đúng edition Win10/11/LTSC/ARM/PS7
                                # (bỏ qua chặn cứng LGPO/UBR của InitialActions.ps1)
  Catalog/TweaksCatalog.ps1     # 197 tweak: ApplyScript / RestoreScript / CheckScript, 9 nhóm, 6 mode
  UI/InteractiveCLI.ps1         # TUI tick-chọn [✓]/[ ], tìm kiếm, thực thi & log
```

### 9 nhóm tweak

1. 🖥️ Treo Giả Lập 24/7 (13) · 2. 🎮 Gaming & Low-Latency (12) · 3. ⚡ CPU/Kernel/Timer (10) · 4. 🧠 RAM & Memory (10) · 5. 🎨 GPU & Display (10) · 6. 🌐 Network (10) · 7. 🧹 System/Services/Debloat (12) · 8. 🔒 Privacy (10) · 9. 🚀 **EXTREME LAB (78)** · 10. 🧩 WinUtil (25)

## 🚀 EXTREME LAB — tầng cực hạn (nhóm 9)

78 tweak sâu nhất (EXT01–EXT80, trừ EXT13/EXT46 đã gỡ vì bị Antivirus gắn cờ mạnh), phần lõi do `Optimizer/Core/ExtremeEngine.ps1` thực thi:

- **MSI Mode** cho GPU + NVMe + NIC (giảm DPC latency thật, cần restart)
- **Timer Resolution Daemon 0.5ms** toàn hệ thống (`NtSetTimerResolution`, Scheduled Task) + `GlobalTimerResolutionRequests` cho Win11
- **Process Booster Task mỗi 5'**: instance giả lập mới mở tự được AboveNormal + affinity tránh Core 0
- **IFEO CpuPriorityClass=High vĩnh viễn**, GPU Preference & tắt FSO theo từng exe giả lập phát hiện được
- **Power Profile cực hạn**: Ultimate + PERFEPP 0, PerfBoost Aggressive, IDLEDISABLE, ASPM off, disk không ngủ
- **NIC advanced**: RSS đa lõi, Interrupt Moderation/LSO/EEE off · **Storage**: fsutil LastAccess/8dot3 off, TRIM on · **AMD ULPS off** · SvcHost thu gọn theo RAM

## 🧠 Plan Siêu Sâu + Smart Advisor (Tự động hoá tối đa)

```powershell
.\MolikWinlik.ps1 -Plan                      # xem KẾ HOẠCH chi tiết theo Mode (chưa áp dụng)
.\MolikWinlik.ps1 -Smart -Plan               # Smart Advisor tự chọn Mode theo phần cứng rồi lập plan
.\MolikWinlik.ps1 -Smart -Apply -Yes         # Smart Advisor chọn hộ + áp dụng luôn
# Trong CLI: phím G = Smart Auto, Menu đơn giản: phím G tương tự
```

**Plan Engine** (`Optimizer/Core/PlanEngine.ps1`) phân tích trước khi chạm vào hệ thống: tự bổ sung phụ thuộc (EXT02→EXT23 trên Win11, CPU04→EXT22), loại mâu thuẫn (EXT07 thay GAM01, EXT39 thay EMU06, EXT03 thay EMU13), sắp xếp theo 8 pha an toàn (Tasks/Services → Registry → GPU → Power → Network → Storage → Kernel/BCD cuối cùng), đánh dấu tweak cần restart, tính **Impact Score** và cảnh báo theo ngữ cảnh (laptop thì không khóa idle, RAM ≤8GB thì không tắt Memory Compression...).

**Smart Advisor** (`Optimizer/Core/SmartAdvisor.ps1`) đọc phần cứng thật: thấy giả lập → Farm, GPU AMD → thêm tắt ULPS, NVIDIA → thêm ép Power Limit, NVMe → thêm NTFS/Interrupt sâu, laptop → chặn tweak gây nóng.

**EXTREME LAB mở rộng EXT34–EXT50:** WMI Autologger off, NetBIOS off, TCP CUBIC, Interrupt Priority GPU/NVMe, Pagefile ổ nhanh nhất, NIC buffers 2048, ưu tiên IPv4, NVIDIA Power Limit max, tắt HWP Autonomous, Boot Legacy, Unhide Power Settings, IFEO I/O Priority, Print Spooler off...

## 🛡️ Vì sao bỏ hẳn bản online? (Antivirus/AMSI + ExecutionPolicy)

Hai lỗi thực tế khi chạy `irm ... | iex` trên máy thật:

1. **Defender/AMSI chặn blob trong bộ nhớ**: nạp ~290KB script qua `iex` bị quét toàn văn
   và gắn cờ (`This script contains malicious content...`) — tool tối ưu nào chứa lệnh
   BCD/service/registry mạnh cũng dễ bị, kể cả winutil từng bị gắn cờ oan.
2. **ExecutionPolicy chặn file .ps1**: fallback tải file về `%TEMP%` rồi `& file.ps1` vẫn
   chết vì phiên PowerShell hiện tại đang `Restricted` (`running scripts is disabled`).

Giải pháp triệt để của MOLIK WINLIK: **chỉ chạy file local qua `MOLIK_WINLIK.bat`** —
`.bat` không bị ExecutionPolicy chặn, tự xin Admin bằng UAC chuẩn, và mở PowerShell con
với `-ExecutionPolicy Bypass` **chỉ cho tiến trình đó** (không đổi policy của máy).
Chạy file script từ đĩa cũng là đường ít bị AMSI gắn cờ nhất vì Defender quét file
thông thường thay vì blob `iex`. Tool không dùng bất kỳ kỹ thuật che giấu/mã hoá nào
để qua mặt Antivirus — toàn bộ code đều đọc được công khai trong repo này.

## 🧩 Tích hợp WinUtil (Chris Titus Tech) — OFFLINE 100%, không cần tải

Data của [winutil](https://github.com/ChrisTitusTech/winutil) (MIT License, xem `Optimizer/Data/LICENSE-winutil.txt`) đã được **vendor trực tiếp vào repo này** — chạy hoàn toàn offline, không tải thêm bất cứ gì lúc chạy:

- **25 tweak winutil** (nhóm `10. WINUTIL` trong CLI): Brave Debloat, Edge Debloat (17 registry), tắt nhà Home/Gallery Explorer, End Task chuột phải, WPBT, giờ UTC, khóa màn hình, NumLock, Dark/BSoD verbose... Đã loại trừ các tweak trùng/mâu thuẫn với 165 tweak bản địa (GameDVR, telemetry, MPO, chuột 1:1...). Chuyển đổi bởi `Optimizer/Core/WinUtilBridge.ps1`, dữ liệu tại `Optimizer/Data/WinUtilTweaks.ps1`.
- **239 ứng dụng cài qua winget** (kiểu winutil) tại `Optimizer/Data/WinUtilApps.ps1`:

```powershell
.\MolikWinlik.ps1 -ListApps                       # xem 239 app / nhóm
.\MolikWinlik.ps1 -InstallApps "steam, vlc, chrome, discord"
.\MolikWinlik.ps1 -AppsMenu                       # menu chọn app (hoặc phím A trong Menu đơn giản)
```

## 📊 Benchmark Before/After

```powershell
.\MolikWinlik.ps1 -Benchmark -BenchmarkLabel Before   # đo TRƯỚC khi tối ưu
.\MolikWinlik.ps1 -Mode GodMode -Apply -Yes            # áp dụng (đã gồm xác nhận Extreme qua -Yes)
# restart máy, rồi:
.\MolikWinlik.ps1 -Benchmark -BenchmarkLabel After
.\MolikWinlik.ps1 -CompareBenchmarks                   # xem % cải thiện CPU/Disk/RAM
.\MolikWinlik.ps1 -Mode EmulatorFarm -Apply -DryRun    # xem trước, chưa thực thi
```

Trong CLI: phím `V` = kiểm tra tweak nào đã áp dụng (●), `T` = chạy benchmark, `S`/`L` = lưu/nạp Profile tick chọn (JSON, mang sang máy khác áp y hệt: `-Profile file.json`). Host không hỗ trợ phím trực tiếp sẽ tự chuyển sang **Menu đơn giản** (hoặc cờ `-Menu`), trong menu có sẵn mục tạo **Shortcut Desktop** để lần sau double-click là chạy.

## 🩺 Self-Test / Debug toàn diện

```powershell
.\MolikWinlik.ps1 -SelfTest     # parse cú pháp, dựng catalog, chạy thử toàn bộ CheckScript của catalog (chỉ đọc)
# hoặc phím D trong Menu đơn giản — không thay đổi gì trên hệ thống
```

## 🛟 An toàn & khôi phục

- Trước khi áp dụng, tool tự tạo **System Restore Point** + export các nhánh Registry quan trọng + BCD store vào `C:\MOLIK_WINLIK_Backups\`.
- Mọi tweak đều có `RestoreScript` đảo ngược; phím `R` hoặc `-RestoreDefaults` khôi phục mặc định toàn bộ.
- Tweak rủi ro cao được gắn nhãn `[Extreme]` (đỏ) — đọc kỹ mô tả tiếng Việt dưới mỗi mục trước khi tick.
- Log từng lần chạy lưu tại `C:\MOLIK_WINLIK_Backups\Logs\`.
- Nhiều tweak (HAGS, VBS, BCD, pagefile) cần **restart** mới có hiệu lực.

> ⚠️ Tắt VBS/Hyper-V/Spectre mitigations làm giảm lớp bảo mật — chỉ phù hợp máy farm/game chuyên dụng. Hãy để tool tạo backup và cân nhắc dùng mode `Sophia Standard` cho máy làm việc chính.
