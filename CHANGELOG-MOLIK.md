# MOLIK WINLIK — Changelog

Tool tối ưu Windows offline của fork này (nằm ngoài module upstream `src/`).
Chạy: double-click `MOLIK_WINLIK.bat`. Chi tiết kỹ thuật: `Optimizer/README.md`.

## v4.1.0 — Debug sâu & hoàn thiện cực hạn

- **Audit engine cực hạn** (ExtremeEngine/RAM Daemon/WinUtil): Restore của
  Unhide Power Settings nay xóa giá trị đúng trạng thái gốc; fsutil 8dot3
  khôi phục về mặc định hệ thống (2); dừng Timer Daemon chỉ khớp đúng
  tiến trình `MolikTimer.ps1`.
- **Không còn nhân bản Power Plan**: GAM01/EXT07 chỉ tạo Ultimate
  Performance khi chưa tồn tại (trước đây mỗi lần áp lại nhân thêm 1 bản).
- **Restore đối xứng nốt**: EMU03 bật lại đủ 3 tính năng Hyper-V đã tắt;
  EMU05 gỡ đủ exclusion đường dẫn + tiến trình đã thêm.
- **Phát hiện giả lập toàn diện**: các tweak theo exe (EXT05/EXT06) dùng
  luôn kết quả quét toàn ổ đĩa + registry của HardwareDetector.
- **Marker phiên đang chạy**: nếu mất điện/tắt máy giữa lúc áp dụng,
  Doctor lần sau cảnh báo ngay và hướng dẫn `-UndoLast`.
- Danh sách tweak cần restart đầy đủ hơn (RAM03/EXT25/EXT79/EXT80/EXT83);
  SelfTest kiểm tra thêm ID cần-restart tồn tại + khóa Mode hợp lệ.

## v4.0.0 — Bản hoàn thiện

- Đồng bộ version 4.0.0 toàn hệ thống; bản Portable khi build lại tự lấy
  version từ launcher (không còn lệch banner).
- `-ExportReport` ghi vào `C:\MOLIK_WINLIK_Backups\Reports` (không rải file
  vào thư mục repo nữa).
- `-RestoreDefaults -Yes` chạy thẳng không dừng chờ ENTER.
- Menu đơn giản có thêm phím `K` — Doctor.
- Metadata backup ghi kèm phiên bản tool.

## v3.3.0 — DEEPER

- Áp dụng xong **tự kiểm chứng**: mỗi tweak được chạy lại CheckScript, kết
  quả tách `verified` / `unverified` / FAIL (cả trong log phiên).
- Audit sâu catalog: sửa Restore thiếu đối xứng (SYS01/SYS02/EXT14/EXT15/
  EXT78), RAM04, lỗi tràn DWORD âm thầm ở GAM08/RAM09 (4294967295 → -1),
  GPU05 chỉ áp lên GPU NVIDIA thật.
- Check thật cho NET01/NET04/NET05/RAM08/EXT05/EXT06/EXT36/EXT45/EXT69.
- Tweak mới EXT85 (DoSvc), EXT86 (DPS/SRUM) — **197 tweak**.
- SelfTest: kiểm tra xung đột registry (cùng khóa, khác giá trị đích).

## v3.2.0 — TUI tối giản

- Viết lại giao diện tick-chọn: 3 dòng header, 1 dòng/tweak cột thẳng hàng,
  panel chi tiết cố định ở đáy, 1 dòng phím tắt. Bỏ hộp viền/emoji thừa.
- Menu đơn giản và header Plan gọn cùng phong cách.

## v3.1.0 — Hoàn tác & chẩn đoán

- `-UndoLast` / phím `U`: hoàn tác đúng phiên áp dụng gần nhất theo log.
- `-Doctor`: chẩn đoán chỉ đọc (VT-x, VBS/HVCI, chờ restart, HAGS/MPO...).
- `-ListBackups` / `-ListProfiles`; sửa lỗi Restore chọn nhầm thư mục
  `Logs/Profiles` làm backup mới nhất.
- TUI hết rác khung hình cũ; Plan Engine nhận Snapshot ở mọi đường áp dụng.

## v3.0.0 — Đa năng & giao diện chuyên nghiệp

- 7 Presets theo kịch bản (`-Preset`), báo cáo **HTML Dashboard**
  (`-ExportReport`, phím `H`), CLI headless đầy đủ (`-ApplyIds`,
  `-RestoreIds`, `-Status`, `-BackupOnly`, `-Version`...).
- Tweak mới EXT81–EXT84 + PRI11 — 195 tweak; EMU12 dừng thật service
  WSearch. Sửa lỗi TUI sập ngay khung đầu (thiếu khởi tạo trạng thái).

## v2.x — Offline hoàn toàn

- Bỏ hẳn đường chạy online (`irm | iex`): entry point chuẩn là
  `MOLIK_WINLIK.bat` → file local `MolikWinlik-Portable.ps1`, tự xin Admin.
- Đổi tên tool thành **MOLIK WINLIK by @nggkhaiz**; tên `Sophia-*` chỉ còn
  là shim tương thích. Encoding chuẩn UTF-8 có BOM cho PowerShell 5.1.

## v1.x — Nền tảng

- Engine tick-chọn `[✓]/[ ]`, 6 Mode (Farm/Gaming/Workstation/LowSpec/
  Standard/GodMode), catalog tweak sâu (BCD/MSI/timer/GPU/network),
  Plan Engine, Smart Advisor, Benchmark before/after, backup/restore,
  tích hợp dữ liệu winutil offline (25 tweak + 239 app, MIT).
