# 👑 Sophia Ultra Optimizer — Tick-Select CLI

Tool tối ưu Windows **sâu & cực mạnh** xây trên nền [Sophia Script for Windows](https://github.com/farag2/Sophia-Script-for-Windows) gốc (`src/`), bổ sung engine riêng trong `Optimizer/` với **87 tweak** chia 8 nhóm, **6 mode chuyên dụng** và giao diện **tick-chọn CLI** `[✓]/[ ]` bằng phím.

## 🚀 Chạy nhanh

```powershell
# Cách 1: double-click
Run-Sophia-Optimizer.bat

# Cách 2: PowerShell (tự nâng quyền Admin)
.\Sophia-Optimizer.ps1

# Cách 3: 1 lệnh từ xa (không cần clone)
irm https://raw.githubusercontent.com/NggKhaiz/Sophia-Script-for-Windows/main/Sophia-Ultra-Standalone.ps1 | iex
```

## 🎛️ 6 Mode tối ưu riêng cho từng nhu cầu

| Phím | Mode | Dành cho |
|---|---|---|
| `1` | 🖥️ **TREO GIẢ LẬP 24/7** | Farm multi-instance LDPlayer / MuMu / NoxPlayer / BlueStacks / MEmu: tắt VBS/Hyper-V tranh VT-x, Auto RAM Cleaner mỗi 15', pagefile cố định lớn, không ngủ/USB suspend, Defender exclusion cho thư mục giả lập, boost priority process giả lập |
| `2` | 🎮 **HARDCORE GAMING** | FPS/esports low-latency: HAGS, tắt MPO/Game DVR, BCD timer latency, Nagle off, `NetworkThrottlingIndex=0`, `SystemResponsiveness=0`, chuột 1:1, Ultimate Performance |
| `3` | 🎬 **WORKSTATION / STREAM** | Render/OBS/compile: mạnh nhưng giữ ổn định & mitigations, ưu tiên GPU encode/foreground |
| `4` | 🥔 **LOW-SPEC / POTATO PC** | Máy yếu RAM ≤8GB: tắt visual effects, services/background apps/telemetry thừa |
| `5` | 🛡️ **SOPHIA STANDARD** | Privacy + gọn gàng an toàn chuẩn Sophia gốc, không đụng kernel/BCD |
| `6` | 👑 **GOD MODE** | Toàn bộ 87 tweak kể cả nhóm `Extreme` (tắt Spectre/Meltdown mitigations...) — chỉ khi đã backup |

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
.\Sophia-Optimizer.ps1 -ListTweaks                       # liệt kê 87 tweak
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
  Core/SophiaBridge.ps1         # Bridge vào Sophia.psm1 gốc theo đúng edition Win10/11/LTSC/ARM/PS7
                                # (bỏ qua chặn cứng LGPO/UBR của InitialActions.ps1)
  Catalog/TweaksCatalog.ps1     # 87 tweak: ApplyScript / RestoreScript / CheckScript, 8 nhóm, 6 mode
  UI/InteractiveCLI.ps1         # TUI tick-chọn [✓]/[ ], tìm kiếm, thực thi & log
```

### 8 nhóm tweak

1. 🖥️ Treo Giả Lập 24/7 (13) · 2. 🎮 Gaming & Low-Latency (12) · 3. ⚡ CPU/Kernel/Timer (10) · 4. 🧠 RAM & Memory (10) · 5. 🎨 GPU & Display (10) · 6. 🌐 Network (10) · 7. 🧹 System/Services/Debloat (12) · 8. 🔒 Privacy Sophia Native (10)

## 🛟 An toàn & khôi phục

- Trước khi áp dụng, tool tự tạo **System Restore Point** + export các nhánh Registry quan trọng + BCD store vào `C:\Sophia_Backups\`.
- Mọi tweak đều có `RestoreScript` đảo ngược; phím `R` hoặc `-RestoreDefaults` khôi phục mặc định toàn bộ.
- Tweak rủi ro cao được gắn nhãn `[Extreme]` (đỏ) — đọc kỹ mô tả tiếng Việt dưới mỗi mục trước khi tick.
- Log từng lần chạy lưu tại `C:\Sophia_Backups\Logs\`.
- Nhiều tweak (HAGS, VBS, BCD, pagefile) cần **restart** mới có hiệu lực.

> ⚠️ Tắt VBS/Hyper-V/Spectre mitigations làm giảm lớp bảo mật — chỉ phù hợp máy farm/game chuyên dụng. Hãy để tool tạo backup và cân nhắc dùng mode `Sophia Standard` cho máy làm việc chính.
