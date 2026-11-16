function LoadGame()
{
   trace("LoadGame");
   DestroyGame();
   if(_pdata.data.skinnum)
   {
      ModeSettings.skinNum = _pdata.data.skinnum;
   }
   else
   {
      ModeSettings.skinNum = 3;
   }
   if(_pdata.data.bgnum)
   {
      ModeSettings.bgNum = _pdata.data.bgnum;
   }
   else
   {
      ModeSettings.bgNum = 1;
   }
   if(Game.prototype.wireOriginalShowFinish == undefined)
   {
      Game.prototype.wireOriginalShowFinish = Game.prototype.ShowFinish;
      Game.prototype.ShowFinish = function()
      {
         if(this.lives.Get() <= 0 && !ModeSettings.MPMode && !ModeSettings.PMPMode)
         {
            this.gameState = 2;
            _global.wireContinuePending = true;
            return;
         }
         this.wireOriginalShowFinish();
      };
   }
   _global.wireContinuePending = false;
   _gn = "g" + random(1000);
   _root[_gn] = new Game();
   _global.URLOK.Set(true);
   _root[_gn].SetVolume(_root.vol);
   GameGUI.InitGUI();
   Game.me.Init();
   Game.me.SPStart();
   onEnterFrame = function()
   {
      wireMaybeCheckpoint();
      _root[_gn].FrameTick();
   };
}
function ShowMenu()
{
   if(_root[_gn])
   {
      DestroyGame();
   }
   gotoAndStop(2);
}
onEnterFrame = LoadGame;

function wireSaveCheckpoint()
{
   var g = Game.me;
   if(g == undefined || g.gameState != 1 || ModeSettings.scoreGroup != "sandbox" || ModeSettings.MPMode || ModeSettings.PMPMode || ModeSettings.scenario)
   {
      return "Start a single-player Sandbox run first.";
   }
   if(g.lastLevel) return "The final wave has started; no later checkpoint is available.";
   _global.wireCheckpointPending = true;
   _global.wireCheckpointMessage = "Waiting for a clear moment between waves.";
   return _global.wireCheckpointMessage;
}
function wireCheckpointStatus()
{
   if(_global.wireCheckpointMessage == undefined) return "";
   return _global.wireCheckpointMessage;
}
function wireMaybeCheckpoint()
{
   if(!_global.wireCheckpointPending) return;
   var g = Game.me;
   if(g == undefined || g.gameState != 1) return;
   if(g.lastLevel)
   {
      _global.wireCheckpointPending = false;
      _global.wireCheckpointMessage = "The final wave started before a checkpoint was available.";
      return;
   }
   if(g.gameInfo.creeps.length != 0 || g.gameInfo.shots.length != 0 || g.timeToLevel.Get() < 1) return;
   var i = 0;
   while(i < g.gameInfo.towers.length)
   {
      var t = g.gameInfo.towers[i];
      if(t.upTicks > 0 || t.sellTicks > 0 || t.firing) return;
      i++;
   }
   var cp = {version:1, mode:String(ModeSettings.modeNum), mapConfig:ModeSettings.mapConfig, mapSize:ModeSettings.mapSize, difficulty:ModeSettings.difficulty,
      towers:Storage.CreateTowerString(g.gameInfo.towers), levels:g.gameInfo.gameData.levels,
      gold:g.gold.Get(), lives:g.lives.Get(), score:g.score.Get(), wave:g.level.Get(), levelBonus:g.levelBonus.Get(),
      timeToLevel:g.timeToLevel.Get(), currentLevelTime:g.currentLevelTime, levelTime:g.levelTime,
      fcount:g.fcount, tick:g.tick, targetTick:g.targetTick, newLevelTick:g.newLevelTick,
      creepKills:g.creepKills, goldSpent:g.goldSpent, sellNum:g.sellNum, towersBuilt:ModeSettings.towersBuilt,
      firstLeak:ModeSettings.firstLeak, barPos:GameGUI.levelBar.posX, barIncrement:GameGUI.levelBar.increment,
      elapsed:g.GetTime()-g.startTime};
   g.cookie.data.wireCheckpoint = cp;
   var result = g.cookie.flush();
   _global.wireCheckpointPending = false;
   if(result == false || result == "pending") _global.wireCheckpointMessage = "Checkpoint could not be confirmed on this device.";
   else _global.wireCheckpointMessage = "Checkpoint saved after wave " + cp.wave + ".";
}
function wireLoadCheckpoint()
{
   var g = Game.me;
   if(g == undefined || g.gameState != 0 || ModeSettings.scoreGroup != "sandbox" || ModeSettings.MPMode || ModeSettings.PMPMode || ModeSettings.scenario)
      return "Open a new Sandbox game with the saved settings, before starting it.";
   if(g.gameInfo.towers.length != 0)
      return "Open a fresh Sandbox game without preloading or placing towers first.";
   var cp = g.cookie.data.wireCheckpoint;
   if(cp == undefined || cp.version != 1 || cp.levels == undefined || cp.towers == undefined || cp.towers.length % 6 != 0)
      return "No valid local checkpoint was found.";
   if(cp.mode != String(ModeSettings.modeNum) || cp.mapConfig != ModeSettings.mapConfig || cp.mapSize != ModeSettings.mapSize || cp.difficulty != ModeSettings.difficulty)
      return "Choose the same Sandbox settings used for the checkpoint.";
   if(cp.wave < 0 || cp.wave >= cp.levels.length - 1 || cp.timeToLevel < 1 || cp.lives < 1)
      return "The local checkpoint is incomplete or invalid.";
   var i = 0;
   while(i < cp.towers.length)
   {
      var row = int(cp.towers.substring(i,i+2)); var col = int(cp.towers.substring(i+2,i+4));
      var kind = int(cp.towers.substring(i+4,i+5)); var lvl = int(cp.towers.substring(i+5,i+6));
      if(row < 0 || col < 0 || row + 1 >= g.gameInfo.cellRows || col + 1 >= g.gameInfo.cellCols || kind < 1 || kind > 9 || lvl < 1 || lvl > 6)
         return "The saved tower layout is invalid.";
      i += 6;
   }
   g.Reset();
   g.gameInfo.gameData.levels = cp.levels;
   GameGUI.levelBar.CreateLevels(cp.levels);
   ModeSettings.towersBuilt = 0;
   Storage.LoadTowers(cp.towers);
   g.Start();
   g.gold.Set(cp.gold); g.goldChange = true; g.lives.Set(cp.lives); g.score.Set(cp.score);
   g.level.Set(cp.wave); g.levelBonus.Set(cp.levelBonus); g.timeToLevel.Set(cp.timeToLevel);
   g.currentLevelTime = cp.currentLevelTime; g.levelTime = cp.levelTime;
   g.fcount = cp.fcount; g.tick = cp.tick; g.targetTick = cp.targetTick; g.newLevelTick = cp.newLevelTick;
   g.creepKills = cp.creepKills; g.goldSpent = cp.goldSpent; g.sellNum = cp.sellNum;
   ModeSettings.towersBuilt = cp.towersBuilt; ModeSettings.firstLeak = cp.firstLeak;
   g.startTime = g.GetTime() - cp.elapsed; g.lastLevel = false;
   GameGUI.txtLives.text = "" + cp.lives; GameGUI.txtScore.text = "" + (cp.score + cp.levelBonus);
   GameGUI.txtGold.text = "" + cp.gold; GameGUI.txtTime.text = "" + cp.timeToLevel;
   GameGUI.NextLevel(cp.levels.length - 1,cp.wave,cp.timeToLevel,false);
   GameGUI.levelBar.posX = cp.barPos; GameGUI.levelBar.increment = cp.barIncrement; GameGUI.levelBar._x = int(cp.barPos);
   _global.wireCheckpointPending = false;
   _global.wireCheckpointMessage = "Checkpoint restored after wave " + cp.wave + ".";
   return _global.wireCheckpointMessage;
}
flash.external.ExternalInterface.addCallback("wireSaveCheckpoint", null, wireSaveCheckpoint);
flash.external.ExternalInterface.addCallback("wireLoadCheckpoint", null, wireLoadCheckpoint);
flash.external.ExternalInterface.addCallback("wireCheckpointStatus", null, wireCheckpointStatus);
function wireUpgradeAvailable()
{
   var g = Game.me;
   var p = GameGUI.infoPanel;
   return g != undefined && g.gameState <= 1 && p != undefined && p.tower != undefined && p.towerObj != undefined && p.btnUpgrade._visible && p.btnUpgrade._enabled && p.tower.upTicks == 0 && !p.tower.dragged && !p.tower.firing && g.gameInfo.CanUpgrade() && g.gold.Get() >= int(p.towerObj.cost) - p.tower.cost.Get();
}
function wireUpgradeSelected()
{
   if(!wireUpgradeAvailable()) return false;
   GameGUI.infoPanel.ButtonClick("upgrade");
   return true;
}
flash.external.ExternalInterface.addCallback("wireUpgradeAvailable", null, wireUpgradeAvailable);
flash.external.ExternalInterface.addCallback("wireUpgradeSelected", null, wireUpgradeSelected);
function wireSellAvailable()
{
   var g = Game.me;
   var p = GameGUI.infoPanel;
   if(g == undefined || g.gameState > 1 || p == undefined || p.tower == undefined || !p.btnSell._visible) return false;
   var t = p.tower;
   if(t.topLeftCell == undefined || t.dragged || t.sellTicks > 0 || t.upTicks > 0) return false;
   if(t.towerType == 8 && g.gameState > 0) return true;
   return !t.noSell && g.gameInfo.CanSell();
}
function wireSellSelected()
{
   if(!wireSellAvailable()) return false;
   GameGUI.infoPanel.ButtonClick("sell");
   return true;
}
flash.external.ExternalInterface.addCallback("wireSellAvailable", null, wireSellAvailable);
flash.external.ExternalInterface.addCallback("wireSellSelected", null, wireSellSelected);

function wireIsGameScreen()
{
   return _root._currentframe == 3 || _root._currentframe == 4 || _root._currentframe == 5;
}
flash.external.ExternalInterface.addCallback("wireIsGameScreen", null, wireIsGameScreen);
function wirePlaceTower(type, x, y)
{
   var g = Game.me;
   var grid = GameGUI.grid;
   if(g == undefined || grid == undefined || g.gameState >= 2 || type < 1 || type > 9 || !g.gameInfo.CanBuy(type)) return false;
   var col = int((x - grid.startX) / grid.gridSize);
   var row = int((y - grid.startY) / grid.gridSize);
   if(x < grid.startX || y < grid.startY || col < 0 || row < 0 || col >= grid.cols || row >= grid.rows) return false;
   var cell = g.gameInfo.cells[row][col];
   if(y < cell.top + grid.gridSize / 2) row--;
   if(x < cell.left + grid.gridSize / 2) col--;
   row = Math.max(0, Math.min(grid.rows - 2, row));
   col = Math.max(0, Math.min(grid.cols - 2, col));
   var t = grid.dragTower;
   if(t == undefined || t.towerType != type) t = g.gameInfo.AddTower(type,true);
   if(t == undefined || grid.CellHitTest(row,col,t) != 0) { g.CancelSelect(); return false; }
   var oldCount = g.gameInfo.towers.length;
   g.PlaceTower(t,g.gameInfo.cells[row][col]);
   return g.gameInfo.towers.length > oldCount;
}
flash.external.ExternalInterface.addCallback("wirePlaceTower", null, wirePlaceTower);
function wireBeginTower(type)
{
   var g = Game.me;
   if(g == undefined || GameGUI.grid == undefined || g.gameState >= 2 || type < 1 || type > 9 || !g.gameInfo.CanBuy(type)) return false;
   var t = GameGUI.grid.dragTower;
   if(t == undefined || t.towerType != type) t = g.gameInfo.AddTower(type,true);
   return t != undefined;
}
function wireCancelTower()
{
   var g = Game.me;
   var grid = GameGUI.grid;
   if(g == undefined || grid == undefined || (grid.dragTower == undefined && grid.tower == undefined)) return false;
   g.CancelSelect();
   return true;
}
flash.external.ExternalInterface.addCallback("wireBeginTower", null, wireBeginTower);
flash.external.ExternalInterface.addCallback("wireCancelTower", null, wireCancelTower);
function wireTowerEconomy()
{
   var g = Game.me;
   var p = GameGUI.infoPanel;
   if(g == undefined || p == undefined || !p._visible || p.tower == undefined || p.tower.topLeftCell == undefined) return "";
   var t = p.tower;
   var value = t.cost.Get();
   if(t.upTicks > 0 && t.upObject != undefined) return "Upgrading: paid $" + (int(t.upObject.cost) - value);
   if(t.sellTicks > 0) return "Sale in progress";
   var text = "Value $" + value;
   if(p.towerObj != undefined) text += " | Upgrade $" + (int(p.towerObj.cost) - value);
   else text += " | MAX";
   if(t.towerType == 8 && g.gameState > 0) text += " | FIRE";
   else if(t.noSell || !g.gameInfo.CanSell()) text += " | No sell";
   else
   {
      var full = g.gameState == 0 || ModeSettings.arcadeMode;
      if(ModeSettings.MPMode || ModeSettings.PMPMode) full = !GameMP.started || ModeSettings.arcadeMode;
      text += " | Sell $" + (full ? value : int(value * 0.75));
   }
   return text;
}
flash.external.ExternalInterface.addCallback("wireTowerEconomy", null, wireTowerEconomy);
function wireMagnifierTap(x, y)
{
   var g = Game.me;
   var grid = GameGUI.grid;
   if(g == undefined || grid == undefined || g.gameState >= 2 || x < grid.startX || y < grid.startY) return false;
   var col = int((x - grid.startX) / grid.gridSize);
   var row = int((y - grid.startY) / grid.gridSize);
   if(col < 0 || col >= grid.cols || row < 0 || row >= grid.rows) return false;
   if(grid.dragTower != undefined) return wirePlaceTower(grid.dragTower.towerType,x,y);
   g.SelectCell(row,col);
   return true;
}
flash.external.ExternalInterface.addCallback("wireMagnifierTap", null, wireMagnifierTap);

function wireContinueAvailable()
{
   return _global.wireContinuePending == true && Game.me != undefined && Game.me.gameState == 2;
}
function wireContinueChoice(keepPlaying)
{
   var g = Game.me;
   if(!wireContinueAvailable()) return false;
   _global.wireContinuePending = false;
   if(keepPlaying)
   {
      g.lives.Set(20);
      GameGUI.txtLives.text = "20";
      g.gameState = 1;
   }
   else
   {
      g.wireOriginalShowFinish();
   }
   return true;
}
flash.external.ExternalInterface.addCallback("wireContinueAvailable", null, wireContinueAvailable);
flash.external.ExternalInterface.addCallback("wireContinueChoice", null, wireContinueChoice);
