module Workspaces where

import Control.Lens
import Control.Monad (liftM2, when)
import Data.List (find, isInfixOf, sortBy)
import Data.Maybe (fromJust, fromMaybe, isNothing, isJust, maybeToList)
import Data.Monoid (All(..))

import XMonad
import XMonad.Actions.CycleWS (Direction1D(Prev), WSType(NonEmptyWS), findWorkspace)
import XMonad.Actions.DynamicWorkspaceOrder (getSortByOrder)
import XMonad.Actions.DynamicWorkspaces (removeEmptyWorkspace)
import XMonad.Actions.OnScreen (greedyViewOnScreen, Focus(FocusNew), onScreen)
import XMonad.Actions.PhysicalScreens (ScreenComparator, screenComparatorById)
import XMonad.Hooks.Place (fixed)
import XMonad.Hooks.XPropManage (pmP, XPropMatch)
import XMonad.Util.WorkspaceCompare (getSortByIndex)
import XMonad.Util.XUtils (fi)
import qualified XMonad.StackSet as W
import qualified XMonad.Util.ExtensibleState as ES


newWSName = "new ws"

type WSData = ( String         -- name
              , (Maybe [Char]) -- mapping
              , Bool           -- enabled
              , Bool           -- permanent
              )

primaryWorkspaces, secondaryWorkspaces :: [WSData]

primaryWorkspaces =
  [ ("web", Just "<F1>", True, True)
  , ("work", Just "<F2>", True, True)
  , ("tools", Just "<F4>", True, True)
  ]

secondaryWorkspaces =
  [ ("shell", Just "<F3>", True, True)
  , ("read", Just "4", True, True)
  , ("media", Just "5", True, True)
  , ("im", Just "3", True, True)
  ]

scratchpadWorkspace :: WSData
scratchpadWorkspace = ("scratch", Just "<Esc>", True, True)

xPropMatches :: [XPropMatch]
xPropMatches = [ ([ (wM_CLASS, any ("Alacritty" ==))], pmP (viewShift "shell"))
               , ([ (wM_CLASS, any ("Apvlv" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("Chromium-browser" ==))], pmP (viewShift "web"))
               , ([ (wM_CLASS, any ("Digikam" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Djview3" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("Djview4" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("Dolphin" ==))], pmP (viewShift "work"))
               , ([ (wM_CLASS, any ("Emacs" ==))], pmP (viewShift "work"))
               , ([ (wM_CLASS, any ("FBReader" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("Firefox" ==))], pmP (viewShift "web"))
               , ([ (wM_CLASS, any ("Gimp" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Gwenview" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Homebank" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Inkview" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Nautilus" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Pidgin" ==))], pmP (viewShift "im"))
               , ([ (wM_CLASS, any ("Rapid Photo Downloader" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Sakura" ==))], pmP (viewShift "shell"))
               , ([ (wM_CLASS, any ("Simple-scan" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("Skype" ==))], pmP (viewShift "im"))
               , ([ (wM_CLASS, any ("Slack" ==))], pmP (viewShift "im"))
               , ([ (wM_CLASS, any ("TelegramDesktop" ==))], pmP (viewShift "im"))
               , ([ (wM_CLASS, any ("URxvt" ==))], pmP (viewShift "shell"))
               , ([ (wM_CLASS, any ("Virt-manager" ==))], pmP (viewShift "tools"))
               , ([ (wM_CLASS, any ("Virt-viewer" ==))], pmP (viewShift "tools"))
               , ([ (wM_CLASS, any ("Xsane" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("aft-linux-qt" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("athura" `isInfixOf`))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("calibre" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("glogg" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("llpp" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("polar-bookshelf" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("psi" ==))], pmP (viewShift "im"))
               , ([ (wM_CLASS, any ("scantailor-advanced" ==))], pmP (viewShift "scratch"))
               , ([ (wM_CLASS, any ("zoom" ==))], pmP (viewShift "im"))
               , ([ (wM_CLASS, any ("Soffice" ==))], pmP (viewShift "read"))
               , ([ (wM_CLASS, any ("Code" ==))], pmP (viewShift "work"))
               , ([ (wM_CLASS, any ("mpv" ==))], pmP (viewShift "media"))
               , ([ (wM_CLASS, any ("com-eviware-soapui-SoapUI" ==))], pmP (viewShift "tools"))
               ]
  where
    viewShift = liftM2 (.) W.view W.shift

placePolicy = (fixed (0.5, 0.5))

naturalScreenOrderer :: ScreenComparator
naturalScreenOrderer = screenComparatorById comparator where
  comparator id1 id2 = compare id1 id2

mergedWorkspaces = (p:s:scratchpadWorkspace:ps) ++ ss
  where p:ps = primaryWorkspaces
        s:ss = secondaryWorkspaces

wsEnabled (_, _, enabled, _) = enabled
wsMapped (_, mapping, _, _) = isJust mapping
wsMapping (name, mapping, _, _) = (name, fromJust mapping)
wsName (name, _, _, _) = name
wsTransient (_, _, _, permanent) = not permanent


greedyViewOnScreenFocus :: ScreenId     -- ^ screen id
                        -> WorkspaceId  -- ^ index of the workspace
                        -> WindowSet    -- ^ current stack
                        -> WindowSet
greedyViewOnScreenFocus sid i = onScreen (W.greedyView i) FocusNew sid

isCurrentWorkspaceEmpty ss = isNothing . W.stack . W.workspace . W.current $ ss

isCurrentWorkspaceTransient ss = (W.currentTag $ ss) `elem` transientWorkspaceNames
  where
    transientWorkspaceNames = map wsName $ filter wsTransient $ filter wsEnabled mergedWorkspaces

deleteLastWSWindowHook :: Event -> X All
deleteLastWSWindowHook (DestroyWindowEvent {ev_window = w}) = do
  ws <- gets windowset
  when (isCurrentWorkspaceTransient ws) removeEmptyWorkspace
  when (isCurrentWorkspaceEmpty ws && (not $ isCurrentWorkspaceTransient ws))
    (findWorkspace getSortByOrder Prev NonEmptyWS 2 >>= \t -> windows . W.greedyView $ t)
  return (All True)
deleteLastWSWindowHook _ = return (All True)

showWSOnProperScreenHook :: Event -> X All
showWSOnProperScreenHook ClientMessageEvent { ev_window = w
                                            , ev_message_type = mt
                                            , ev_data = d } =
  withWindowSet $ \s -> do
    sort' <- getSortByIndex
    let ws = sort' $ W.workspaces s

    a_aw <- getAtom "_NET_ACTIVE_WINDOW"
    a_cd <- getAtom "_NET_CURRENT_DESKTOP"
    a_cw <- getAtom "_NET_CLOSE_WINDOW"
    a_d <- getAtom "_NET_WM_DESKTOP"
    if mt == a_cd then do
      let n = head d
      if 0 <= n && fi n < length ws then showWSOnProperScreen (W.tag (ws !! fi n))
      else trace $ "Bad _NET_CURRENT_DESKTOP with data[0]=" ++ show n
    else if mt == a_d then do
      let n = head d
      if 0 <= n && fi n < length ws then windows $ W.shiftWin (W.tag (ws !! fi n)) w
      else trace $ "Bad _NET_DESKTOP with data[0]=" ++ show n
    else if mt == a_aw then do
      case W.findTag w s of
        Nothing -> pure ()
        Just tag -> do
          showWSOnProperScreen tag
          windows $ W.focusWindow w
    else if mt == a_cw then do
      killWindow w
    else do
      -- The Message is unknown to us, but that is ok, not all are meant
      -- to be handled by the window manager
      pure ()
    return (All True)
showWSOnProperScreenHook _ = return (All True)

showWSOnProperScreen :: String -> X ()
showWSOnProperScreen ws = case classifyWorkspace ws of
  Primary -> switchToPrimary ws
  Secondary -> switchToSecondary ws
  Tertiary -> switchToTertiary ws

data WorkspaceType = Primary | Secondary | Tertiary deriving (Eq)

classifyWorkspace :: WorkspaceId -> WorkspaceType
classifyWorkspace ws
  | ws `elem` (map wsName primaryWorkspaces) = Primary
  | ws `elem` (map wsName secondaryWorkspaces) = Secondary
  | otherwise = Tertiary

switchToPrimary :: WorkspaceId -> X ()
switchToPrimary name = do
  windows $ viewPrimary name
  ES.modify $ primaryChoiceL .~ name
  pure ()

switchToSecondary :: WorkspaceId -> X ()
switchToSecondary name = do
  windows $ viewSecondary name
  ES.modify $ secondaryChoiceL .~ name
  pure ()

switchToTertiary :: WorkspaceId -> X ()
switchToTertiary name = do
  windows $ viewTertiary name
  ES.modify $ tertiaryChoiceL .~ name
  pure ()

viewPrimary, viewSecondary, viewTertiary :: WorkspaceId -> WindowSet -> WindowSet

viewPrimary i ss = go (detectMonitorConfig ss)
  where
    go SingleMonitor = W.view i ss
    go _ = greedyViewOnScreenFocus 1 i ss

viewSecondary i ss = go (detectMonitorConfig ss)
  where
    go SingleMonitor = W.view i ss
    go DualMonitor = greedyViewOnScreenFocus 1 i ss
    go (TripleMonitor sec _) = greedyViewOnScreenFocus sec i ss

viewTertiary i ss = go (detectMonitorConfig ss)
  where
    go SingleMonitor = W.view i ss
    go DualMonitor = greedyViewOnScreenFocus 0 i ss
    go (TripleMonitor _ ter) = greedyViewOnScreenFocus ter i ss

data WorkspaceChoice = WorkspaceChoice WorkspaceId WorkspaceId WorkspaceId deriving (Typeable, Read, Show, Eq)
instance ExtensionClass WorkspaceChoice where
  initialValue = WorkspaceChoice
    (wsName $ head primaryWorkspaces)
    (wsName $ head secondaryWorkspaces)
    (wsName scratchpadWorkspace)
  extensionType = PersistentExtension

primaryChoiceL :: Lens' WorkspaceChoice WorkspaceId
primaryChoiceL k (WorkspaceChoice prim sec ter) = fmap (\newPrim -> WorkspaceChoice newPrim sec ter) (k prim)

secondaryChoiceL :: Lens' WorkspaceChoice WorkspaceId
secondaryChoiceL k (WorkspaceChoice prim sec ter) = fmap (\newSec -> WorkspaceChoice prim newSec ter) (k sec)

tertiaryChoiceL :: Lens' WorkspaceChoice WorkspaceId
tertiaryChoiceL k (WorkspaceChoice prim sec ter) = fmap (\newTer -> WorkspaceChoice prim sec newTer) (k ter)

data MonitorConfig = SingleMonitor
                   | DualMonitor
                   | TripleMonitor ScreenId ScreenId

detectMonitorConfig :: WindowSet -> MonitorConfig
detectMonitorConfig W.StackSet {W.visible = []} = SingleMonitor
detectMonitorConfig W.StackSet {W.visible = [_]} = DualMonitor
detectMonitorConfig ss@(W.StackSet {W.visible = (_:_:[])}) = TripleMonitor (chooseSecondary ss) (chooseTertiary ss)
detectMonitorConfig _ = SingleMonitor -- No idea how to handle more than 3 monitors =)

chooseSecondary :: WindowSet -> ScreenId
chooseSecondary W.StackSet { W.visible = visible, W.current = current } =
  case sorted of
    _primary:a:b:_ ->
      case W.screen a of
        1 -> W.screen b
        _ -> W.screen a
    _ -> W.screen current
  where
    allScreens = current : visible
    sorted = sortBy (\x y -> compare (W.screen x) (W.screen y)) allScreens

chooseTertiary :: WindowSet -> ScreenId
chooseTertiary ss = case chooseSecondary ss of
                      1 -> 2
                      2 -> 0
                      _ -> 0

scratchPadPosition :: WindowSet -> ScreenId
scratchPadPosition ss = go (detectMonitorConfig ss)
  where
    go SingleMonitor = 0
    go DualMonitor = 1
    go (TripleMonitor _ ter) = ter

placeWorkplaces :: X ()
placeWorkplaces = do
  monConf <- detectMonitorConfig <$> gets windowset
  WorkspaceChoice prim sec ter <- ES.get
  case monConf of
    SingleMonitor -> do
      switchToPrimary prim
    DualMonitor -> do
      switchToSecondary sec
      switchToPrimary prim
    TripleMonitor _ _ -> do
      switchToTertiary ter
      switchToSecondary sec
      switchToPrimary prim

onRescreen :: X () -> Event -> X All
onRescreen u (ConfigureEvent {ev_window = w}) = do
  rootPred <- isRoot w
  case rootPred of
    True -> do
      rescreen
      u
      return (All False)
    _ -> return (All True)
onRescreen _ _ = return (All True)

-- TODO: rethink tagging setup
