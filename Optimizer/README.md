# 👑 MOLIK_WINLIK — Sophia Ultra Optimizer by @nggkhaiz

> **Credit:** Phát triển bởi **@nggkhaiz** (repo [MOLIK_WINLIK](https://github.com/NggKhaiz/MOLIK_WINLIK)) — dựa trên [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows) của farag2 và tích hợp data [winutil](https://github.com/ChrisTitusTech/winutil) của Chris Titus Tech (đều MIT).

Tool tối ưu Windows **sâu & cực mạnh** xây trên nền [Sophia Script for Windows](https://github.com/farag2/Sophia-Script-for-Windows) gốc (`src/`), bổ sung engine riêng trong `Optimizer/` với **184 tweak** chia 9 nhóm, **6 mode chuyên dụng** và giao diện **tick-chọn CLI** `[✓]/[ ]` bằng phím.

## 🌐 Dùng ONLINE như winutil — KHÔNG cần tải tool, KHÔNG cài đặt

Mở PowerShell và gõ đúng 1 lệnh (như `christitus.com/win` của winutil):

```powershell
irm "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1" | iex
```

Tool tự nâng quyền Admin (mở cửa sổ mới, không đóng shell của bạn), nạp toàn bộ engine + 184 tweak vào bộ nhớ và mở giao diện tick-chọn — **không tải file, không cài đặt, không để lại file tool** trên máy.

> Link ngắn kiểu `christitus.com/win`: bật **Settings → Pages → Source: Deploy from branch `main` / folder `/docs`** (2 click, file `docs/win.ps1` đã chuẩn bị sẵn) là dùng được `irm "nggkhaiz.github.io/MOLIK_WINLIK/win.ps1" | iex`. Không bật cũng không sao — link raw ở trên hoạt động ngay sau khi Merge.

Chọn sẵn Mode bằng cách:

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1"))) -Mode HardcoreGaming
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/win.ps1"))) -Smart
```

## 🚀 Chạy nhanh — KHÔNG CẦN CÀI ĐẶT (offline)

```powershell
# Cách 0 (TIỆN NHẤT): double-click file Sophia-1Click.bat
#   -> tự tải bản Portable 1 file vào %TEMP% rồi chạy ngay, không cài gì vào máy

# Cách 1: 1 lệnh, không cần clone/cài
irm https://raw.githubusercontent.com/NggKhaiz/MOLIK_WINLIK/main/Sophia-Ultra-Portable.ps1 | iex

# Cách 2: tải đúng 1 file Sophia-Ultra-Portable.ps1 (141KB, chứa toàn bộ engine)
#   về bất kỳ đâu (USB, Desktop, TEMP...) rồi chạy:
.\Sophia-Ultra-Portable.ps1
.\Sophia-Ultra-Portable.ps1 -Mode HardcoreGaming
.\Sophia-Ultra-Portable.ps1 -Menu        # menu số đơn giản, host nào cũng chạy được

# Cách 3: trong repo (double-click Run-Sophia-Optimizer.bat hoặc):
.\Sophia-Optimizer.ps1

# Bản Portable được sinh tự động từ nguồn bằng: .\Optimizer\Build-Portable.ps1
```

## 🎛️ 6 Mode tối ưu riêng cho từng nhu cầu

| Phím | Mode | Dành cho |
|---|---|---|
| `1` | 🖥️ **TREO GIẢ LẬP 24/7** | Farm multi-instance LDPlayer / MuMu / NoxPlayer / BlueStacks / MEmu: tắt VBS/Hyper-V tranh VT-x, Auto RAM Cleaner mỗi 15', pagefile cố định lớn, không ngủ/USB suspend, Defender exclusion cho thư mục giả lập, boost priority process giả lập |
| `2` | 🎮 **HARDCORE GAMING** | FPS/esports low-latency: HAGS, tắt MPO/Game DVR, BCD timer latency, Nagle off, `NetworkThrottlingIndex=0`, `SystemResponsiveness=0`, chuột 1:1, Ultimate Performance |
| `3` | 🎬 **WORKSTATION / STREAM** | Render/OBS/compile: mạnh nhưng giữ ổn định & mitigations, ưu tiên GPU encode/foreground |
| `4` | 🥔 **LOW-SPEC / POTATO PC** | Máy yếu RAM ≤8GB: tắt visual effects, services/background apps/telemetry thừa |
| `5` | 🛡️ **SOPHIA STANDARD** | Privacy + gọn gàng an toàn chuẩn Sophia gốc, không đụng kernel/BCD |
| `6` | 👑 **GOD MODE** | Toàn bộ 184 tweak kể cả nhóm `Extreme` (tắt Spectre/Meltdown mitigations...) — chỉ khi đã backup |

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
.\Sophia-Optimizer.ps1 -Mode EmulatorFarm -Apply -Yes   # áp dụng thẳng 1 mode
.\Sophia-Optimizer.ps1 -Mode HardcoreGaming              # mở CLI đã tick sẵn mode Gaming
.\Sophia-Optimizer.ps1 -ListModes                        # xem 6 mode
.\Sophia-Optimizer.ps1 -ListTweaks                       # liệt kê 184 tweak
.\Sophia-Optimizer.ps1 -PurgeRAM                         # dọn RAM ngay
.\Sophia-Optimizer.ps1 -BoostEmulators                   # boost process giả lập
.\Sophia-Optimizer.ps1 -ExportReport                     # xuất JSON báo cáo phần cứng + catalog
.\Sophia-Optimizer.ps1 -RestoreDefaults -Yes             # khôi phục mặc định
```

## 🧩 Kiến trúc

```
Sophia-Optimizer.ps1            # Entry point (self-elevate Admin, CLI + non-interactive)
Sophia-Ultra-Standalone.ps1     # Single-file cho irm | iex
Run-Sophia-Optimizer.bat        # Double-click launcher
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
  Core/WinUtilBridge.ps1        # Cầu nối winutil (Chris Titus Tech, MIT) -> tweak bản địa, offline
  Core/AppInstaller.ps1         # Cài 239 app qua winget (data vendor từ winutil)
  Data/WinUtilTweaks.ps1        # 25 tweak winutil đã chuyển đổi + LICENSE-winutil.txt
  Data/WinUtilApps.ps1          # 239 ứng dụng winget/choco
  Core/SophiaBridge.ps1         # Bridge vào Sophia.psm1 gốc theo đúng edition Win10/11/LTSC/ARM/PS7
                                # (bỏ qua chặn cứng LGPO/UBR của InitialActions.ps1)
  Catalog/TweaksCatalog.ps1     # 184 tweak: ApplyScript / RestoreScript / CheckScript, 9 nhóm, 6 mode
  UI/InteractiveCLI.ps1         # TUI tick-chọn [✓]/[ ], tìm kiếm, thực thi & log
```

### 9 nhóm tweak

1. 🖥️ Treo Giả Lập 24/7 (13) · 2. 🎮 Gaming & Low-Latency (12) · 3. ⚡ CPU/Kernel/Timer (10) · 4. 🧠 RAM & Memory (10) · 5. 🎨 GPU & Display (10) · 6. 🌐 Network (10) · 7. 🧹 System/Services/Debloat (12) · 8. 🔒 Privacy Sophia Native (10) · 9. 🚀 **EXTREME LAB (25)**

## 🚀 EXTREME LAB — tầng cực hạn (nhóm 9)

25 tweak sâu nhất, do `Optimizer/Core/ExtremeEngine.ps1` thực thi:

- **MSI Mode** cho GPU + NVMe + NIC (giảm DPC latency thật, cần restart)
- **Timer Resolution Daemon 0.5ms** toàn hệ thống (`NtSetTimerResolution`, Scheduled Task) + `GlobalTimerResolutionRequests` cho Win11
- **Process Booster Task mỗi 5'**: instance giả lập mới mở tự được AboveNormal + affinity tránh Core 0
- **IFEO CpuPriorityClass=High vĩnh viễn**, GPU Preference & tắt FSO theo từng exe giả lập phát hiện được
- **Power Profile cực hạn**: Ultimate + PERFEPP 0, PerfBoost Aggressive, IDLEDISABLE, ASPM off, disk không ngủ
- **NIC advanced**: RSS đa lõi, Interrupt Moderation/LSO/EEE off · **Storage**: fsutil LastAccess/8dot3 off, TRIM on · **AMD ULPS off** · SvcHost thu gọn theo RAM

## 🧠 Plan Siêu Sâu + Smart Advisor (Tự động hoá tối đa)

```powershell
.\Sophia-Optimizer.ps1 -Plan                      # xem KẾ HOẠCH chi tiết theo Mode (chưa áp dụng)
.\Sophia-Optimizer.ps1 -Smart -Plan               # Smart Advisor tự chọn Mode theo phần cứng rồi lập plan
.\Sophia-Optimizer.ps1 -Smart -Apply -Yes         # Smart Advisor chọn hộ + áp dụng luôn
# Trong CLI: phím G = Smart Auto, Menu đơn giản: phím G tương tự
```

**Plan Engine** (`Optimizer/Core/PlanEngine.ps1`) phân tích trước khi chạm vào hệ thống: tự bổ sung phụ thuộc (EXT02→EXT23 trên Win11, CPU04→EXT22), loại mâu thuẫn (EXT07 thay GAM01, EXT39 thay EMU06, EXT03 thay EMU13), sắp xếp theo 8 pha an toàn (Tasks/Services → Registry → GPU → Power → Network → Storage → Kernel/BCD cuối cùng), đánh dấu tweak cần restart, tính **Impact Score** và cảnh báo theo ngữ cảnh (laptop thì không khóa idle, RAM ≤8GB thì không tắt Memory Compression...).

**Smart Advisor** (`Optimizer/Core/SmartAdvisor.ps1`) đọc phần cứng thật: thấy giả lập → Farm, GPU AMD → thêm tắt ULPS, NVIDIA → thêm ép Power Limit, NVMe → thêm NTFS/Interrupt sâu, laptop → chặn tweak gây nóng.

**EXTREME LAB mở rộng EXT34–EXT50:** WMI Autologger off, NetBIOS off, TCP CUBIC, Interrupt Priority GPU/NVMe, Pagefile ổ nhanh nhất, NIC buffers 2048, ưu tiên IPv4, NVIDIA Power Limit max, tắt HWP Autonomous, Boot Legacy, DEP off (God Mode), Unhide Power Settings, IFEO I/O Priority, Print Spooler off...

## 🧩 Tích hợp WinUtil (Chris Titus Tech) — OFFLINE 100%, không cần tải

Data của [winutil](https://github.com/ChrisTitusTech/winutil) (MIT License, xem `Optimizer/Data/LICENSE-winutil.txt`) đã được **vendor trực tiếp vào repo này** — chạy hoàn toàn offline, không tải thêm bất cứ gì lúc chạy:

- **25 tweak winutil** (nhóm `10. WINUTIL` trong CLI): Brave Debloat, Edge Debloat (17 registry), tắt nhà Home/Gallery Explorer, End Task chuột phải, WPBT, giờ UTC, khóa màn hình, NumLock, Dark/BSoD verbose... Đã loại trừ các tweak trùng/mâu thuẫn với 137 tweak bản địa (GameDVR, telemetry, MPO, chuột 1:1...). Chuyển đổi bởi `Optimizer/Core/WinUtilBridge.ps1`, dữ liệu tại `Optimizer/Data/WinUtilTweaks.ps1`.
- **239 ứng dụng cài qua winget** (kiểu winutil) tại `Optimizer/Data/WinUtilApps.ps1`:

```powershell
.\Sophia-Optimizer.ps1 -ListApps                       # xem 239 app / nhóm
.\Sophia-Optimizer.ps1 -InstallApps "steam, vlc, chrome, discord"
.\Sophia-Optimizer.ps1 -AppsMenu                       # menu chọn app (hoặc phím A trong Menu đơn giản)
```

## 📊 Benchmark Before/After

```powershell
.\Sophia-Optimizer.ps1 -Benchmark -BenchmarkLabel Before   # đo TRƯỚC khi tối ưu
.\Sophia-Optimizer.ps1 -Mode GodMode -Apply -Yes            # áp dụng (đã gồm xác nhận Extreme qua -Yes)
# restart máy, rồi:
.\Sophia-Optimizer.ps1 -Benchmark -BenchmarkLabel After
.\Sophia-Optimizer.ps1 -CompareBenchmarks                   # xem % cải thiện CPU/Disk/RAM
.\Sophia-Optimizer.ps1 -Mode EmulatorFarm -Apply -DryRun    # xem trước, chưa thực thi
```

Trong CLI: phím `V` = kiểm tra tweak nào đã áp dụng (●), `T` = chạy benchmark, `S`/`L` = lưu/nạp Profile tick chọn (JSON, mang sang máy khác áp y hệt: `-Profile file.json`). Host không hỗ trợ phím trực tiếp sẽ tự chuyển sang **Menu đơn giản** (hoặc cờ `-Menu`), trong menu có sẵn mục tạo **Shortcut Desktop** để lần sau double-click là chạy.

## 🩺 Self-Test / Debug toàn diện

```powershell
.\Sophia-Optimizer.ps1 -SelfTest     # parse cú pháp, dựng catalog, chạy thử 170 CheckScript (chỉ đọc)
# hoặc phím D trong Menu đơn giản — không thay đổi gì trên hệ thống
```

## 🛟 An toàn & khôi phục

- Trước khi áp dụng, tool tự tạo **System Restore Point** + export các nhánh Registry quan trọng + BCD store vào `C:\Sophia_Backups\`.
- Mọi tweak đều có `RestoreScript` đảo ngược; phím `R` hoặc `-RestoreDefaults` khôi phục mặc định toàn bộ.
- Tweak rủi ro cao được gắn nhãn `[Extreme]` (đỏ) — đọc kỹ mô tả tiếng Việt dưới mỗi mục trước khi tick.
- Log từng lần chạy lưu tại `C:\Sophia_Backups\Logs\`.
- Nhiều tweak (HAGS, VBS, BCD, pagefile) cần **restart** mới có hiệu lực.

> ⚠️ Tắt VBS/Hyper-V/Spectre mitigations làm giảm lớp bảo mật — chỉ phù hợp máy farm/game chuyên dụng. Hãy để tool tạo backup và cân nhắc dùng mode `Sophia Standard` cho máy làm việc chính.
