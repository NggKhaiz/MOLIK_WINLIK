<#
	Sophia Ultra Optimizer - WinUtil Tweaks Data (VENDORED, works OFFLINE - no download needed)
	Converted from ChrisTitusTech/winutil config/tweaks.json (commit 2ef5e5d), MIT License - see LICENSE-winutil.txt
	Only pure-registry Toggle tweaks were converted; tweaks duplicating/conflicting with the native 137-tweak catalog were excluded.
#>
function Get-WinUtilRawTweaks
{
	return @(
		[PSCustomObject]@{
			Id = 'WU01'; SourceKey = 'WPFTweaksRevertStartMenu'; Name = 'Start Menu Previous Layout - Enable'; Description = 'Bring back the old Start Menu layout from before the gradual rollout of the new one in 25H2. On newer versions of Windows !!THIS TWEAK WILL NOT WORK!!'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\3036241548'; Name = 'EnabledState'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU02'; SourceKey = 'WPFTweaksBraveDebloat'; Name = 'Brave Browser - Debloat'; Description = 'Disables various annoyances like Brave Rewards, Leo AI, Crypto Wallet and VPN.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveRewardsDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveWalletDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveVPNDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveAIChatEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveStatsPingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveNewsDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveTalkDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'TorDisabled'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'BraveP3AEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'UrlKeyedAnonymizedDataCollectionEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'SafeBrowsingExtendedReportingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'; Name = 'MetricsReportingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU03'; SourceKey = 'WPFTweaksDisableWarningForUnsignedRdp'; Name = 'RDP Unsigned File Warnings - Disable'; Description = 'Disables warnings shown when launching unsigned RDP files introduced with the latest Windows 10 and 11 updates.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client'; Name = 'RedirectionWarningDialogVersion'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKCU:\SOFTWARE\Microsoft\Terminal Server Client'; Name = 'RdpLaunchConsentAccepted'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU04'; SourceKey = 'WPFTweaksEdgeDebloat'; Name = 'Microsoft Edge - Debloat'; Description = 'Disables various telemetry options, popups, and other annoyances in Edge.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'; Name = 'CreateDesktopShortcutDefault'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'PersonalizationReportingEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallBlocklist'; Name = '1'; Value = 'ofefcgjbeghpigppfmkologfjadafddi'; Type = 'String'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowRecommendationsEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HideFirstRunExperience'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'UserFeedbackAllowed'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ConfigureDoNotTrack'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'AlternateErrorPagesEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeCollectionsEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeShoppingAssistantEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'MicrosoftEdgeInsiderPromotionEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowMicrosoftRewards'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'WebWidgetAllowed'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DiagnosticData'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeAssetDeliveryServiceEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'WalletDonationEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DefaultBrowserSettingsCampaignEnabled'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU05'; SourceKey = 'WPFTweaksConsumerFeatures'; Name = 'ConsumerFeatures - Disable'; Description = 'Stops promoted app installs and reduces app suggestions from Microsoft Store content.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsConsumerFeatures'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU06'; SourceKey = 'WPFTweaksUTC'; Name = 'Date & Time - Set Time to UTC'; Description = 'Essential for computers that are dual booting. Fixes the time sync with Linux systems.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'; Name = 'RealTimeIsUniversal'; Value = '1'; Type = 'QWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU07'; SourceKey = 'WPFTweaksRemoveHomeAndGallery'; Name = 'File Explorer Home and Gallery - Disable'; Description = 'Removes the Home and Gallery from Explorer and sets This PC as default.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'; Name = 'System.IsPinnedToNameSpaceTree'; Value = '0'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU08'; SourceKey = 'WPFTweaksEndTaskOnTaskbar'; Name = 'End Task With Right Click - Enable'; Description = 'Enables option to end task when right-clicking a program in the taskbar.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name = 'TaskbarEndTask'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU09'; SourceKey = 'WPFTweaksWPBT'; Name = 'Windows Platform Binary Table (WPBT) - Disable'; Description = 'If enabled, WPBT allows your computer vendor to execute programs at boot time, such as anti-theft software, software drivers, as well as force install software without user consent. Poses potential security risk.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'DisableWpbtExecution'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU10'; SourceKey = 'WPFTweaksPreventDeviceMetadataFromNetwork'; Name = 'Prevent Device Companion Apps'; Description = 'Prevents additional software from being installed when plugging in devices (e.g. Ads when plugging in a monitor). Poses potential security risk.'
			SourceCategory = 'Essential Tweaks'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata'; Name = 'PreventDeviceMetadataFromNetwork'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU11'; SourceKey = 'WPFTweaksDisableNotifications'; Name = 'System Tray Notifications & Calendar - Disable'; Description = 'Disables all Notifications INCLUDING Calendar.'
			SourceCategory = 'z__Advanced Tweaks - CAUTION'; Risk = 'Moderate'; Modes = @()
			Entries = @(
				@{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name = 'DisableNotificationCenter'; Value = '1'; Type = 'DWord'; Original = $null }
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications'; Name = 'ToastEnabled'; Value = '0'; Type = 'DWord'; Original = '1' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU12'; SourceKey = 'WPFToggleDetailedBSoD'; Name = 'BSoD Verbose Mode'; Description = 'Gives more information when you blue screen.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisplayParameters'; Value = '1'; Type = 'DWord'; Original = '0' }
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisableEmoticon'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU13'; SourceKey = 'WPFToggleBatteryPercentage'; Name = 'System Tray Battery Percentage'; Description = 'Shows numeric battery percentage next to the battery icon in the system tray.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'IsBatteryPercentageEnabled'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU14'; SourceKey = 'WPFToggleNewOutlook'; Name = 'Microsoft Outlook New Version'; Description = 'This will ensure the new Outlook application is used.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences'; Name = 'UseNewOutlook'; Value = '1'; Type = 'DWord'; Original = '0' }
				@{ Path = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\General'; Name = 'HideNewOutlookToggle'; Value = '0'; Type = 'DWord'; Original = '1' }
				@{ Path = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Options\General'; Name = 'DoNewOutlookAutoMigration'; Value = '0'; Type = 'DWord'; Original = '0' }
				@{ Path = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Preferences'; Name = 'NewOutlookMigrationUserSetting'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU15'; SourceKey = 'WPFToggleScrollbars'; Name = 'Scrollbars Always Visible'; Description = 'If enabled, scrollbars will always be visible. If disabled, Windows will automatically hide scrollbars when not in use.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Control Panel\Accessibility'; Name = 'DynamicScrollbars'; Value = '0'; Type = 'DWord'; Original = '1' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU16'; SourceKey = 'WPFToggleNumLock'; Name = 'Num Lock on Startup'; Description = 'Toggle the Num Lock key state when your computer starts.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKU:\.Default\Control Panel\Keyboard'; Name = 'InitialKeyboardIndicators'; Value = '2'; Type = 'String'; Original = '0' }
				@{ Path = 'HKCU:\Control Panel\Keyboard'; Name = 'InitialKeyboardIndicators'; Value = '2'; Type = 'String'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU17'; SourceKey = 'WPFToggleWindowSnapping'; Name = 'Window Snapping'; Description = 'Toggles the window snapping feature when dragging windows.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'WindowArrangementActive'; Value = '1'; Type = 'String'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU18'; SourceKey = 'WPFToggleStandbyFix'; Name = 'S0 Sleep Network Connectivity'; Description = 'Toggles network connectivity during S0 Sleep which is low power idle in modern laptops.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9'; Name = 'ACSettingIndex'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU19'; SourceKey = 'WPFToggleS3Sleep'; Name = 'S3 Sleep'; Description = 'Toggles between Modern Standby and S3 Sleep, which cuts off power to the CPU while continuing to refresh the memory.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'; Name = 'PlatformAoAcOverride'; Value = '0'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU20'; SourceKey = 'WPFToggleHideSettingsHome'; Name = 'Settings Home Page'; Description = 'Toggles the Home Page in the Windows Settings app.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility'; Value = 'show:home'; Type = 'String'; Original = 'hide:home' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU21'; SourceKey = 'WPFToggleBingSearch'; Name = 'Start Menu Bing Search'; Description = 'Toggles Bing web search results in Windows Search.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU22'; SourceKey = 'WPFToggleLoginBlur'; Name = 'Logon Screen Acrylic Blur'; Description = 'Toggles the acrylic blur effect on login screen background.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'DisableAcrylicBackgroundOnLogon'; Value = '0'; Type = 'DWord'; Original = '1' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU23'; SourceKey = 'WPFToggleDisableLockscreen'; Name = 'Lock Screen - Disable'; Description = 'Skips the lock screen entirely and goes directly to the sign-in screen on boot and wake.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoLockScreen'; Value = '1'; Type = 'DWord'; Original = $null }
			)
		}
		[PSCustomObject]@{
			Id = 'WU24'; SourceKey = 'WPFToggleTaskbarSearch'; Name = 'Taskbar Search Icon'; Description = 'Toggles the Search Button on the Taskbar.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
		[PSCustomObject]@{
			Id = 'WU25'; SourceKey = 'WPFToggleTaskView'; Name = 'Taskbar Task View Icon'; Description = 'Toggles the Task View Button in the Taskbar.'
			SourceCategory = 'Customize Preferences'; Risk = 'Safe'; Modes = @("SophiaStandard")
			Entries = @(
				@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTaskViewButton'; Value = '1'; Type = 'DWord'; Original = '0' }
			)
		}
	)
}
