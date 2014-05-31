class ClientProcessor extends ReplicationInfo config(DeclutterMyHud) dependson(Interaction);

// State variables.
var bool mMustHide;
var bool mMovedAnnouncements;
var byte mServerFriendlyPlayerNames;

// Optimization variables.
var ROPlayerController mPC;
var ROHUD mHUD;

// General configuration variables.
var config name ToggleKey;

// Specific configuration variables.
var config bool HasBeenConfigured;
var config bool RestrictTacticalOverlay;
var config float AnnouncementsScale;
var config int FriendlyPlayerNames;
var config bool HideFunctionIndicator;
var config bool HideCrosshair;
var config int VOIPTalkersVisibility;
var config bool KillWidgetReduceOwnVisibility;
var config int KillWidgetOthersVisibility;
var config float ChatDelay;
var config float ChatOpacity;

replication
{
	if ( bNetDirty && Role == ROLE_Authority )
		mServerFriendlyPlayerNames;
}

simulated function PostBeginPlay()
{
	if(!HasBeenConfigured)
	{
		// Server doesn't transfer the default configuration values.
		// By default, do not restrict anything.
		ToggleKey = 'T';
		RestrictTacticalOverlay = false;
		AnnouncementsScale = 1.0;
		FriendlyPlayerNames = 2;
		HideFunctionIndicator = false;
		HideCrosshair = false;
		HasBeenConfigured = true;
		VOIPTalkersVisibility = 2;
		KillWidgetReduceOwnVisibility = false;
		KillWidgetOthersVisibility = 2;
		ChatDelay = 6.0;
		ChatOpacity = 1.0;
	}
	
	// Validation.
	AnnouncementsScale = FClamp(AnnouncementsScale, 0.1, 1.0);
	FriendlyPlayerNames = Clamp(FriendlyPlayerNames, 0, 2);
	VOIPTalkersVisibility = Clamp(VOIPTalkersVisibility, 0, 2);
	KillWidgetOthersVisibility = Clamp(KillWidgetOthersVisibility, 0, 2);
	ChatDelay = FClamp(ChatDelay, 3, 10);
	ChatOpacity = FClamp(ChatOpacity, 0.5, 1.0);
	
	SaveConfig();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Periodically hides parts of the HUD.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
simulated function Tick(float iDeltaTime)
{
	// Get the Player.
	if(mPC == none)
	{
		mPC = ROPlayerController(GetALocalPlayerController());
	}
	
	// Get the HUD.
	if(mPC != none && mHUD == none)
	{
		mHUD = ROHUD(mPC.myHUD);
	}

	// Update all features.
	UpdatePlayerNames();
	if(mPC != none && mHUD != none && WorldInfo.NetMode != NM_DedicatedServer)
	{
		UpdateTacticalOverlay();
		
		if(!mMovedAnnouncements)
		{
			UpdateAnnouncements();
		}
		
		if(HideFunctionIndicator)
		{
			UpdateUseKeyIndicator();
		}
		
		if(HideCrosshair)
		{
			UpdateCrosshair();
		}
		
		UpdateVOIPTalkers();
		
		if(KillWidgetOthersVisibility < 2 || KillWidgetReduceOwnVisibility)
		{
			UpdateKillWidgetVisibility();
		}
		
		UpdateChat();
	}
}

simulated function UpdateTacticalOverlay()
{
	if(RestrictTacticalOverlay && mPC.PlayerInput.PressedKeys.Find(ToggleKey) < 0)
	{
		mPC.HideTacticalDisplay();
	}
	
	mMustHide = !mHUD.WorldWidget.bVisible || mHUD.WorldWidget.bHiddenTemporarily;
}

simulated function UpdateAnnouncements()
{
	local float wOffset;
	local float wSpaceLeft;
	
	if(mHUD.MessagesAlertsWidget != none)
	{
		wSpaceLeft = 768.0 / 2.0 + mHUD.MessagesAlertsWidget.Y; // Caculate how much space left between the default location and the top.
		wOffset = wSpaceLeft * (1.0 - AnnouncementsScale);      // Calculate the offset.
		mHUD.MessagesAlertsWidget.Y -= wOffset;                 // Apply the offset.
		mMovedAnnouncements = true;
	}
}

simulated function UpdatePlayerNames()
{
	if(WorldInfo.NetMode == NM_ListenServer)
	{
		// This mode is not supported because the GRI is used as a tool.
		return;
	}
	
	// Update the server setting.
	if(WorldInfo.NetMode == NM_DedicatedServer)
	{
		// Use the GameReplicationInfo.
		if(mServerFriendlyPlayerNames != ROGameReplicationInfo(WorldInfo.GRI).FriendlyPlayerNames)
		{
			mServerFriendlyPlayerNames = ROGameReplicationInfo(WorldInfo.GRI).FriendlyPlayerNames;
			bNetDirty = true;
		}
	}
	else if(WorldInfo.NetMode == NM_Standalone)
	{
		// Use the GameInfo.
		if(mServerFriendlyPlayerNames != ROGameInfo(WorldInfo.Game).FriendlyPlayerNames)
		{
			mServerFriendlyPlayerNames = ROGameInfo(WorldInfo.Game).FriendlyPlayerNames;
			bNetDirty = true;
		}
	}

	// Apply the visibility settings.
	if(WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_Client)
	{
		if(mMustHide)
		{
			// Set to the lowest setting.
			ROGameReplicationInfo(WorldInfo.GRI).FriendlyPlayerNames = Min(FriendlyPlayerNames, mServerFriendlyPlayerNames);
		}
		else
		{
			// Set to the server setting.
			ROGameReplicationInfo(WorldInfo.GRI).FriendlyPlayerNames = mServerFriendlyPlayerNames;
		}
	}
}

simulated function UpdateUseKeyIndicator()
{
	if(mMustHide)
	{
		mHUD.IndicatorWidget.bVisible = false;
	}
	else
	{
		mHUD.IndicatorWidget.bVisible = true;
	}
}

simulated function UpdateCrosshair()
{
	if(mMustHide)
	{
		mHUD.bDrawCrosshair = false;
	}
	else
	{
		mHUD.bDrawCrosshair = true;
	}
}

simulated function UpdateVOIPTalkers()
{
	local int i;
	local int wDesiredAlpha;

	if(mMustHide)
	{
		if(VOIPTalkersVisibility == 0)
		{
			// Hide totally.
			wDesiredAlpha = 0;
		}
		else if(VOIPTalkersVisibility == 1)
		{
			// Hide partly.
			wDesiredAlpha = 127;
		}
		else
		{
			// Do not hide.
			wDesiredAlpha = 255;
		}
	}
	else
	{
		wDesiredAlpha = 255;
	}
	
	if(mHUD.VOIPTalkersWidget.HUDComponents[0].FullAlpha != wDesiredAlpha)
	{
		// If one is wrong, they're all wrong.
		for(i = 0 ; i < mHUD.VOIPTalkersWidget.HUDComponents.Length ; i++)
		{
			mHUD.VOIPTalkersWidget.HUDComponents[i].FullAlpha = wDesiredAlpha;
		}
	}
}

simulated function UpdateKillWidgetVisibility()
{
	local int i, j;
	local int wBackgroundAlpha;
	local int wForegroundAlpha;
	local ROHUDWidgetKillMessages wWidget;
	local bool wIsOwnMessage;

	wWidget = mHUD.KillMessageWidget;
	for(i = 0 ; i < 4; i++)
	{
		// Find the player name.
		wIsOwnMessage = false;
		for(j = 1 ; j < 7; j++)
		{
			if(wWidget.KillMessagesArray[i].MessageComponents[j].Text == mPC.PlayerReplicationInfo.PlayerName)
			{
				wIsOwnMessage = true;
				break;
			}
		}
	
		// Define the visibility settings for this message.
		wBackgroundAlpha = 96;
		wForegroundAlpha = 255;
		if(mMustHide)
		{
			if(wIsOwnMessage)
			{
				// Is own message.
				if(KillWidgetReduceOwnVisibility)
				{
					wBackgroundAlpha = 48;
					wForegroundAlpha = 127;
				}
			}
			else
			{
				// Is NOT own message.
				if(KillWidgetOthersVisibility == 0)
				{
					wBackgroundAlpha = 0;
					wForegroundAlpha = 0;
				}
				else if(KillWidgetOthersVisibility == 1)
				{
					wBackgroundAlpha = 48;
					wForegroundAlpha = 127;
				}
			}
		}

		// Apply the visibility settings.
		wWidget.KillMessagesArray[i].MessageComponents[0].FullAlpha = wBackgroundAlpha;
		for(j = 1 ; j < 7; j++)
		{
			wWidget.KillMessagesArray[i].MessageComponents[j].FullAlpha = wForegroundAlpha;
		}
	}
}

simulated function UpdateChat()
{
	local int i;
	local float wDesiredAlpha;

	// Apply the settings.
	mHUD.MessagesChatWidget.FadeOutDelay = ChatDelay;
	wDesiredAlpha = (mMustHide ? ChatOpacity : 1.0) * 255;
	if(mHUD.MessagesChatWidget.HUDComponents[0].FullAlpha != wDesiredAlpha)
	{
		// If one is wrong, they're all wrong.
		for(i = 0 ; i < mHUD.MessagesChatWidget.HUDComponents.Length; i++)
		{
			mHUD.MessagesChatWidget.HUDComponents[i].FullAlpha = wDesiredAlpha;
		}
	}
}

defaultproperties
{
	mMustHide=false
	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy
}
