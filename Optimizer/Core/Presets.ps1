<#
	.SYNOPSIS
	MOLIK WINLIK - Built-in Presets (goi toi uu theo kich ban co san)

	.DESCRIPTION
	Moi Preset = 1 Mode nen + tweak cong them (ExtraIds) + tweak loai tru
	(ExcludeIds / ExcludeRisks), duoc Resolve-MolikPreset giai ra danh sach
	ID cuoi cung theo dung thu tu Catalog. Dung qua:
	  .\MolikWinlik.ps1 -ListPresets
	  .\MolikWinlik.ps1 -Preset esports-fps -Plan
	  .\MolikWinlik.ps1 -Preset farm-max -Apply -Yes
	hoac phim X trong Menu don gian. ID duoc kiem tra ton tai trong SelfTest.
#>

function Get-MolikPresets
{
	return @(
		[PSCustomObject]@{
			Name = "farm-max"; Icon = "🖥️"; Mode = "EmulatorFarm"
			Title = "FARM CỰC HẠN (multi-instance 24/7)"
			Description = "Mode Treo Giả Lập + MSI Mode cho GPU/NVMe (EXT01), khóa driver qua Update (EXT81), tắt ARSO (EXT84). Dành cho dàn farm cắm điện cố định đã có backup."
			ExtraIds = @("EXT01", "EXT81", "EXT84"); ExcludeIds = @(); ExcludeRisks = @()
		},
		[PSCustomObject]@{
			Name = "farm-safe-247"; Icon = "🛡️"; Mode = "EmulatorFarm"
			Title = "FARM AN TOÀN 24/7 (không Extreme)"
			Description = "Toàn bộ Mode Treo Giả Lập nhưng loại mọi tweak rủi ro Extreme (không tắt VBS/HVCI/Spectre, không khóa idle). Treo ổn định lâu dài cho máy còn dùng việc khác."
			ExtraIds = @("EXT81", "EXT84"); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		},
		[PSCustomObject]@{
			Name = "esports-fps"; Icon = "🎮"; Mode = "HardcoreGaming"
			Title = "ESPORTS FPS (latency tối thiểu, giữ mát)"
			Description = "Hardcore Gaming nhưng loại EXT08 (khóa C-State gây nóng) và EXT44 (tắt HWP tự trị) — giữ frame-time ổn định cho thi đấu dài thay vì ép xung nhiệt."
			ExtraIds = @("EXT76", "EXT81"); ExcludeIds = @("EXT08", "EXT44"); ExcludeRisks = @()
		},
		[PSCustomObject]@{
			Name = "streamer-workstation"; Icon = "🎬"; Mode = "Workstation"
			Title = "STREAMER / WORKSTATION"
			Description = "Workstation + SystemResponsiveness=0 (GAM07) + MMCSS Games High (EXT16) cho OBS/game capture mượt, vẫn giữ mitigations và độ ổn định khi render dài."
			ExtraIds = @("GAM07", "EXT16", "EXT40"); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		},
		[PSCustomObject]@{
			Name = "potato-plus"; Icon = "🥔"; Mode = "LowSpec"
			Title = "POTATO PLUS (máy yếu hồi sinh)"
			Description = "LowSpec + mở app Startup tức thì (EXT76) + tắt Biometric/Agent nền (EXT82/EXT83). Cho máy RAM <=8GB, ổ chậm, cần nhẹ tối đa mà vẫn an toàn."
			ExtraIds = @("EXT76", "EXT82", "EXT83"); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		},
		[PSCustomObject]@{
			Name = "privacy-max"; Icon = "🔒"; Mode = "SophiaStandard"
			Title = "PRIVACY MAX (riêng tư tối đa, không đụng hiệu năng)"
			Description = "MOLIK Standard + chặn app nền bằng Policy (EXT49), tắt CEIP/Program Inventory (EXT56/EXT57), chặn app quảng cáo tự cài (EXT72), tắt Clipboard đám mây (PRI11)."
			ExtraIds = @("EXT49", "EXT56", "EXT57", "EXT72", "PRI11"); ExcludeIds = @(); ExcludeRisks = @()
		},
		[PSCustomObject]@{
			Name = "god-safe"; Icon = "👑"; Mode = "GodMode"
			Title = "GOD SAFE (toàn bộ tweak an toàn toàn catalog)"
			Description = "Mọi tweak trong catalog trừ nhóm Extreme — gói 'quét sạch an toàn' cho người muốn tối ưu tối đa mà không đánh đổi bảo mật/ổn định kernel."
			ExtraIds = @(); ExcludeIds = @(); ExcludeRisks = @("Extreme")
		}
	)
}

function Resolve-MolikPreset
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]$Preset,
		[Parameter(Mandatory)]$Catalog
	)

	$ids = @(Get-SophiaModeTweakIds -ModeKey $Preset.Mode -Catalog $Catalog)
	foreach ($extra in @($Preset.ExtraIds))
	{
		if (($Catalog.Id -contains $extra) -and ($ids -notcontains $extra)) { $ids += $extra }
	}
	if (@($Preset.ExcludeIds).Count -gt 0)
	{
		$ids = @($ids | Where-Object { $Preset.ExcludeIds -notcontains $_ })
	}
	if (@($Preset.ExcludeRisks).Count -gt 0)
	{
		$riskById = @{}
		foreach ($t in $Catalog) { $riskById[$t.Id] = $t.Risk }
		$ids = @($ids | Where-Object { $Preset.ExcludeRisks -notcontains $riskById[$_] })
	}
	# Tra ve theo thu tu Catalog de UI/Plan de doc
	return @($Catalog | Where-Object { $ids -contains $_.Id } | ForEach-Object { $_.Id })
}
