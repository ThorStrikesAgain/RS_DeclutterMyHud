class DeclutterMyHud extends ROMutator config(DeclutterMyHud);

var ClientProcessor mProcessor;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// This function is called when the map is loading.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function PostBeginPlay()
{
	// Inheritance.
	super.PostBeginPlay();
    
	`log("DeclutterMyHud Started!",, 'DeclutterMyHud');
	mProcessor = Spawn(class'DeclutterMyHud.ClientProcessor');
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Initializes a configuration menu for the mutator.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function InitializeConfigurationMenu(ROUIWidgetSettingsList SettingsList)
{
	local string wSectionHeader;

	// Set default values.
	if(!class'ClientProcessor'.default.HasBeenConfigured)
	{
		// We're in workshop, restrict as much as possible by default.
		class'ClientProcessor'.default.ToggleKey = 'T';
		class'ClientProcessor'.default.RestrictTacticalOverlay = true;
		class'ClientProcessor'.default.AnnouncementsScale = 0.1;
		class'ClientProcessor'.default.FriendlyPlayerNames = 0;
		class'ClientProcessor'.default.HideFunctionIndicator = true;
		class'ClientProcessor'.default.HasBeenConfigured = true;
		class'ClientProcessor'.default.HideCrosshair = true;
		class'ClientProcessor'.default.VOIPTalkersVisibility = 1;
		class'ClientProcessor'.default.KillWidgetReduceOwnVisibility = true;
		class'ClientProcessor'.default.KillWidgetOthersVisibility = 0;
		class'ClientProcessor'.default.ChatDelay = 3.0;
		class'ClientProcessor'.default.ChatOpacity = 0.5;
		class'ClientProcessor'.static.StaticSaveConfig();
	}
	
	// Create the controls.
	wSectionHeader = "Tactical Overlay";
	SettingsList.AddStringSetting("Tactical Overlay Key", wSectionHeader, string(class'ClientProcessor'.default.ToggleKey), OnToggleKeyChanged);
	SettingsList.AddBooleanSetting("Restrict Tactical Overlay", wSectionHeader, class'ClientProcessor'.default.RestrictTacticalOverlay, OnRestrictTacticalOverlayChanged);
	SettingsList.AddNumericRangeSetting("Minimum Tactical Overlay Display Time", wSectionHeader, 0, 10, class'ROPlayerController'.default.MinTacticalViewDisplayTime, 0.5, 1, OnMinTacticalViewDisplayTimeChanged);
	wSectionHeader = "Kill Widget";
	SettingsList.AddBooleanSetting("Semitransparent Own Messages", wSectionHeader, class'ClientProcessor'.default.KillWidgetReduceOwnVisibility, OnKillWidgetReduceOwnVisibilityChanged);
	SettingsList.AddOptionSliderSetting("Others Visibility", wSectionHeader, "Hidden|Semitransparent|Normal", class'ClientProcessor'.default.KillWidgetOthersVisibility, OnKillWidgetOthersVisibilityChanged);
	wSectionHeader = "Communications";
	SettingsList.AddOptionSliderSetting("VOIP Talkers Visibility", wSectionHeader, "Hidden|Semitransparent|Normal", class'ClientProcessor'.default.VOIPTalkersVisibility, OnVOIPTalkersVisibilityChanged);
	SettingsList.AddNumericRangeSetting("Chat Delay", wSectionHeader, 3, 10, class'ClientProcessor'.default.ChatDelay, 0.5, 1, OnChatDelayChanged);
	SettingsList.AddNumericRangeSetting("Chat Opacity", wSectionHeader, 0.5, 1.0, class'ClientProcessor'.default.ChatOpacity, 0.1, 1, OnChatOpacityChanged);
	wSectionHeader = "Miscellaneous";
	SettingsList.AddNumericRangeSetting("Announcements Y Scale", wSectionHeader, 0.1, 1.0, class'ClientProcessor'.default.AnnouncementsScale, 0.1, 1, OnAnnouncementsScaleChanged);
	SettingsList.AddOptionSliderSetting("Restrict Friendly Player Names", wSectionHeader, "None|Near|All", class'ClientProcessor'.default.FriendlyPlayerNames, OnFriendlyPlayerNamesChanged);
	SettingsList.AddBooleanSetting("Hide Function Indicator", wSectionHeader, class'ClientProcessor'.default.HideFunctionIndicator, OnHideFunctionIndicatorChanged);
	SettingsList.AddBooleanSetting("Hide Crosshair", wSectionHeader, class'ClientProcessor'.default.HideCrosshair, OnHideCrosshairChanged);
}

static function OnToggleKeyChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.ToggleKey = name(UIEditbox(Sender).GetValue());
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnRestrictTacticalOverlayChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.RestrictTacticalOverlay = UICheckBox(Sender).IsChecked();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnAnnouncementsScaleChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.AnnouncementsScale = float(UINumericEditBox(Sender).GetValue());
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnFriendlyPlayerNamesChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.FriendlyPlayerNames = ROUIWidgetOptionSlider(Sender).GetValue();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnHideFunctionIndicatorChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.HideFunctionIndicator = UICheckBox(Sender).IsChecked();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnHideCrosshairChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.HideCrosshair = UICheckBox(Sender).IsChecked();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnMinTacticalViewDisplayTimeChanged(UIObject Sender, int PlayerIndex)
{
	class'ROPlayerController'.default.MinTacticalViewDisplayTime = float(UINumericEditBox(Sender).GetValue());
	class'ROPlayerController'.static.StaticSaveConfig();
}

static function OnVOIPTalkersVisibilityChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.VOIPTalkersVisibility = ROUIWidgetOptionSlider(Sender).GetValue();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnKillWidgetReduceOwnVisibilityChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.KillWidgetReduceOwnVisibility = UICheckBox(Sender).IsChecked();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnKillWidgetOthersVisibilityChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.KillWidgetOthersVisibility = ROUIWidgetOptionSlider(Sender).GetValue();
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnChatDelayChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.ChatDelay = float(UINumericEditBox(Sender).GetValue());
	class'ClientProcessor'.static.StaticSaveConfig();
}

static function OnChatOpacityChanged(UIObject Sender, int PlayerIndex)
{
	class'ClientProcessor'.default.ChatOpacity = float(UINumericEditBox(Sender).GetValue());
	class'ClientProcessor'.static.StaticSaveConfig();
}
