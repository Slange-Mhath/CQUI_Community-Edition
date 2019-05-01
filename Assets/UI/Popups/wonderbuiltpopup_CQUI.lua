-- ===========================================================================
-- Base File
-- ===========================================================================
include("WonderBuiltPopup");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_OnWonderCompleted = OnWonderCompleted;
BASE_CQUI_Close = Close;

local m_kPopupMgr :table = ExclusivePopupManager:new("WonderBuiltPopup");

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_wonderBuiltVisual = true;
local CQUI_wonderBuiltAudio = true;

function CQUI_OnSettingsUpdate()
  CQUI_wonderBuiltVisual = GameConfiguration.GetValue("CQUI_WonderBuiltPopupVisual");
  CQUI_wonderBuiltAudio = GameConfiguration.GetValue("CQUI_WonderBuiltPopupAudio");
end

-- ===========================================================================
--  CQUI modified OnWonderCompleted functiton
--  Setting to disable wonder movie and/or audio
-- ===========================================================================
function OnWonderCompleted( locX:number, locY:number, buildingIndex:number, playerIndex:number, cityId:number, iPercentComplete:number, pillaged:number)

  local localPlayer = Game.GetLocalPlayer();
  if (localPlayer == PlayerTypes.NONE) then
    return;  -- Nobody there to click on it, just exit.
  end

  -- Ignore if wonder isn't for this player.
  if (localPlayer ~= playerIndex ) then
    return;
  end

  -- TEMP (ZBR): Ignore if pause-menu is up; prevents stuck camera bug.
  local uiInGameOptionsMenu:table = ContextPtr:LookUpControl("/InGame/TopOptionsMenu");
  if (uiInGameOptionsMenu and uiInGameOptionsMenu:IsHidden()==false) then
    return;
  end

  local kData:table = nil;

  if (GameInfo.Buildings[buildingIndex].RequiresPlacement and iPercentComplete == 100) then
    local currentBuildingType :string = GameInfo.Buildings[buildingIndex].BuildingType;
    if currentBuildingType ~= nil then

      -- Remolten: Begin CQUI changes (reordered in front of visual code)
      if(GameInfo.Buildings[buildingIndex].QuoteAudio ~= nil and CQUI_wonderBuiltAudio) then
      -- Remolten: End CQUI changes
        UI.PlaySound(GameInfo.Buildings[buildingIndex].QuoteAudio);
      end

      -- Remolten: Begin CQUI changes (just added this if statement and put visual code inside of it)
      if CQUI_wonderBuiltVisual then
      -- Remolten: End CQUI changes

        local kData:table =
        {
          locX = locX,
          locY = locY,
          buildingIndex = buildingIndex,
          currentBuildingType = currentBuildingType
        };

        if not m_kPopupMgr:IsLocked() then
          m_kPopupMgr:Lock( ContextPtr, PopupPriority.High );
          ShowPopup( kData );
          LuaEvents.WonderBuiltPopup_Shown();  -- Signal other systems (e.g., bulk hide UI)
        else
          table.insert( m_kQueuedPopups, kData );
        end
      end
    end
  end
end

-- ===========================================================================
--  CQUI modified OnWonderCompleted functiton
--  Moved the sound to OnWonderCompleted
-- ===========================================================================
function ShowPopup( kData:table )

  if(UI.GetInterfaceMode() ~= InterfaceModeTypes.CINEMATIC) then
    UILens.SaveActiveLens();
    UILens.SetActive("Cinematic");
    UI.SetInterfaceMode(InterfaceModeTypes.CINEMATIC);
  end

  m_kCurrentPopup = kData;

  -- In marketing mode, hide all the UI (temporarly via a timer) but still
  -- play the animation and camera curve.
  if UI.IsInMarketingMode() then
    ContextPtr:SetHide( true );
    Controls.ForceAutoCloseMarketingMode:SetToBeginning();
    Controls.ForceAutoCloseMarketingMode:Play();
    Controls.ForceAutoCloseMarketingMode:RegisterEndCallback( OnClose );
  end

  local locX          :number = m_kCurrentPopup.locX;
  local locY          :number = m_kCurrentPopup.locY;
  local buildingIndex      :number = m_kCurrentPopup.buildingIndex;
  local currentBuildingType  :string = m_kCurrentPopup.currentBuildingType;

  Controls.WonderName:SetText(Locale.ToUpper(Locale.Lookup(GameInfo.Buildings[buildingIndex].Name)));
  Controls.WonderIcon:SetIcon("ICON_"..currentBuildingType);
  Controls.WonderIcon:SetToolTipString(Locale.Lookup(GameInfo.Buildings[buildingIndex].Description));
  if(Locale.Lookup(GameInfo.Buildings[buildingIndex].Quote) ~= nil) then
    Controls.WonderQuote:SetText(Locale.Lookup(GameInfo.Buildings[buildingIndex].Quote));
  else
    UI.DataError("The field 'Quote' has not been initialized for "..GameInfo.Buildings[buildingIndex].BuildingType);
  end

  UI.LookAtPlot(locX, locY);

  Controls.ReplayButton:SetEnabled(UI.GetWorldRenderView() == WorldRenderView.VIEW_3D);
  Controls.ReplayButton:SetHide(not UI.IsWorldRenderViewAvailable(WorldRenderView.VIEW_3D));
end

function Close()
  BASE_CQUI_Close()
  m_kPopupMgr:Unlock();
end

-- ===========================================================================
function Initialize()
  Events.WonderCompleted.Remove( BASE_CQUI_OnWonderCompleted );
  Events.WonderCompleted.Add( OnWonderCompleted );

  LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
  LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );
end
Initialize();