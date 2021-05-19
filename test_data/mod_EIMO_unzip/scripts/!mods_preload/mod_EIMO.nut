local modID = "EndsInventoryManagementOverhaulLegends";
::mods_registerMod(modID, 7.0999999, "End\'s Inventory Management Overhaul Legends");
::mods_queue(null, null, function ()
{
	::EIMOrepairThreshold <- 125;
	::EIMOwaitUntilRepairedThreshold <- 150;
	::EIMOsalvageThreshold <- 40;
	local getToolBuyPrice = function ()
	{
		if (!("Assets" in this.World))
		{
			return 1;
		}

		return 1.25 * this.Math.ceil(200 * this.Const.Difficulty.BuyPriceMult[this.World.Assets.getEconomicDifficulty()]);
	};
	local getRepairCost = function ( item )
	{
		if (::mods_isClass(item, "legend_armor") != null || ::mods_isClass(item, "legend_helmet") != null)
		{
			return getToolBuyPrice() / 20 * (item.getRepairMax() - item.getRepair()) / 15;
		}
		else
		{
			return getToolBuyPrice() / 20 * (item.getConditionMax() - item.getCondition()) / 15;
		}
	};
	local getMaxItemSellPrice = function ( item )
	{
		if (!("Assets" in this.World))
		{
			return 1;
		}

		return this.Math.floor(item.m.Value * this.Const.World.Assets.BaseSellPrice) * this.Const.Difficulty.SellPriceMult[this.World.Assets.getEconomicDifficulty()];
	};
	local getMaxArmorSellPrice = function ( armor )
	{
		local upgrade = armor.getUpgrade();

		if (upgrade != null)
		{
			return getMaxItemSellPrice(upgrade) + getMaxItemSellPrice(armor);
		}
		else
		{
			return getMaxItemSellPrice(armor);
		}
	};
	local getMaxLegendArmorSellPrice = function ( armor )
	{
		local sellPrice = getMaxItemSellPrice(armor);

		foreach( upgrade in armor.m.Upgrades )
		{
			if (upgrade != null)
			{
				sellPrice = sellPrice + getMaxItemSellPrice(upgrade);
			}
		}

		return sellPrice;
	};
	local getMaxSellPrice = function ( item )
	{
		if (::mods_isClass(item, "legend_armor") != null || ::mods_isClass(item, "legend_helmet") != null)
		{
			return getMaxLegendArmorSellPrice(item);
		}
		else if (::mods_isClass(item, "armor") != null)
		{
			return getMaxArmorSellPrice(item);
		}
		else
		{
			return getMaxItemSellPrice(item);
		}
	};
	local getValueChange = function ( item )
	{
		if (::mods_isClass(item, "legend_armor") != null || ::mods_isClass(item, "legend_helmet") != null)
		{
			local valueChange = getMaxItemSellPrice(item) * (1 - item.getCondition() / item.getConditionMax());

			foreach( upgrade in item.m.Upgrades )
			{
				if (upgrade != null)
				{
					valueChange = valueChange + getMaxItemSellPrice(upgrade) * (1 - upgrade.getCondition() / upgrade.getConditionMax());
				}
			}

			return valueChange;
		}
		else
		{
			return getMaxSellPrice(item) * (1 - item.getCondition() / item.getConditionMax());
		}
	};
	::EIMOgetDratio <- function ( item )
	{
		if ((::mods_isClass(item, "legend_armor") != null || ::mods_isClass(item, "legend_helmet") != null) && item.getRepairMax() == item.getRepair())
		{
			return 100;
		}

		if (!(::mods_isClass(item, "legend_armor") != null || ::mods_isClass(item, "legend_helmet") != null) && item.getConditionMax() == item.getCondition())
		{
			return 100;
		}
		else
		{
			return 100 * getValueChange(item) / getRepairCost(item);
		}
	};
	::EIMOgetSratio <- function ( item )
	{
		local durability;

		if (::mods_isClass(item, "legend_armor") != null || ::mods_isClass(item, "legend_helmet") != null)
		{
			durability = item.getRepairMax();
		}
		else
		{
			durability = item.getConditionMax();
		}

		return 100 * getMaxSellPrice(item) / (getToolBuyPrice() / 20 * durability / 15);
	};
	::EIMOcalcBalanceDiffFromRepair <- function ( item )
	{
		return getValueChange(item) - getRepairCost(item);
	};
	local visibilityLevel = 0;
	local getVisibilityLevelFlag = function ()
	{
		return modID + ".visibilityLevel";
	};
	local getStashIndexFlag = function ( i )
	{
		return modID + "." + i + ".indexFavorited";
	};
	local getItemSaleFlag = function ( item )
	{
		return modID + "." + item.getID() + item.getName() + ".forsale";
	};
	::mods_registerJS("mod_EIMO.js");
	::mods_registerJS("mod_EIMO_nohook.js");
	::mods_registerCSS("mod_EIMO.css");
	::mods_registerJS("smart_loot/mod_EIMO_smart_loot.js");
	::mods_registerCSS("smart_loot/mod_EIMO_smart_loot.css");
	::mods_hookClass("items/item", function ( o )
	{
		o.m.isFavorite <- false;
	});
	::mods_hookNewObjectOnce("states/world_state", function ( o )
	{
		local onSerialize = o.onSerialize;
		o.onSerialize = function ( _out )
		{
			local items = this.m.Assets.getStash().getItems();

			if (visibilityLevel != 0)
			{
				this.World.Flags.set(getVisibilityLevelFlag(), visibilityLevel);
			}
			else if (this.World.Flags.has(getVisibilityLevelFlag()))
			{
				this.World.Flags.remove(getVisibilityLevelFlag());
			}

			for( local i = 0; i != items.len(); i = i )
			{
				local item = items[i];

				if (item != null && item.m.isFavorite)
				{
					this.World.Flags.set(getStashIndexFlag(i), 1);
				}
				else if (this.World.Flags.has(getStashIndexFlag(i)))
				{
					this.World.Flags.remove(getStashIndexFlag(i));
				}

				i = ++i;
			}

			onSerialize(_out);

			foreach( bro in this.World.getPlayerRoster().getAll() )
			{
				foreach( item in bro.getItems().getAllItems() )
				{
					if (item != null)
					{
						if (bro.getFlags().has("EIMO" + item.getCurrentSlotType()))
						{
							bro.getFlags().remove("EIMO" + item.getCurrentSlotType());
						}
					}
				}
			}
		};
		local onBeforeSerialize = o.onBeforeSerialize;
		o.onBeforeSerialize = function ( _out )
		{
			foreach( bro in this.World.getPlayerRoster().getAll() )
			{
				foreach( item in bro.getItems().getAllItems() )
				{
					if (item != null)
					{
						if (item.m.isFavorite)
						{
							bro.getFlags().add("EIMO" + item.getCurrentSlotType());
						}
					}
				}
			}

			onBeforeSerialize(_out);
		};
		local onDeserialize = o.onDeserialize;
		o.onDeserialize = function ( _in )
		{
			onDeserialize(_in);
			local items = this.m.Assets.getStash().getItems();

			if (this.World.Flags.has(getVisibilityLevelFlag()) && this.World.Flags.get(getVisibilityLevelFlag()) >= 0)
			{
				visibilityLevel = this.World.Flags.get(getVisibilityLevelFlag());
			}
			else
			{
				visibilityLevel = 0;
			}

			for( local i = 0; i != items.len(); i = i )
			{
				local item = items[i];

				if (item == null || !this.World.Flags.has(getStashIndexFlag(i)) || this.World.Flags.get(getStashIndexFlag(i)) == 0)
				{
				}
				else if (this.World.Flags.get(getStashIndexFlag(i)) == 1)
				{
					item.m.isFavorite = true;
					this.World.Flags.remove(getStashIndexFlag(i));
				}

				i = ++i;
			}

			foreach( bro in this.World.getPlayerRoster().getAll() )
			{
				foreach( item in bro.getItems().getAllItems() )
				{
					if (item != null)
					{
						if (bro.getFlags().has("EIMO" + item.getCurrentSlotType()))
						{
							item.m.isFavorite = true;
							bro.getFlags().remove("EIMO" + item.getCurrentSlotType());
						}
					}
				}
			}
		};
	});
	::mods_hookNewObjectOnce("ui/global/data_helper", function ( o )
	{
		local convertItemToUIData = o.convertItemToUIData;
		o.convertItemToUIData = function ( _item, _forceSmallIcon, _owner = null )
		{
			if (_item == null)
			{
				return null;
			}

			local result = convertItemToUIData(_item, _forceSmallIcon, _owner);

			if (_item != null && _item.getItemType() < this.Const.Items.ItemType.Ammo)
			{
				if ((::mods_isClass(_item, "legend_armor") != null || ::mods_isClass(_item, "legend_helmet") != null) && _item.getRepairMax() > _item.getRepair())
				{
					result.showDratio <- true;
				}
				else if (_item.getConditionMax() > _item.getCondition())
				{
					result.showDratio <- true;
				}
				else
				{
					result.showDratio <- false;
				}
			}
			else
			{
				result.showDratio <- false;
			}

			result.dratio <- ::EIMOcalcBalanceDiffFromRepair(_item);

			if ("Flags" in this.World)
			{
				if (_item == null || !this.World.Flags.has(getItemSaleFlag(_item)) || this.World.Flags.get(getItemSaleFlag(_item)) == 0)
				{
					result.markc <- false;
				}
				else
				{
					result.markc <- true;
				}
			}

			if (_item.m.isFavorite)
			{
				result.favorite <- true;
			}
			else
			{
				result.favorite <- false;
			}

			return result;
		};
	});
	::mods_hookNewObjectOnce("ui/screens/tooltip/tooltip_events", function ( o )
	{
		local queryTooltipData = o.general_queryUIElementTooltipData;
		o.general_queryUIElementTooltipData = function ( entityId, elementId, elementOwner )
		{
			local tooltip = queryTooltipData(entityId, elementId, elementOwner);

			if (tooltip != null)
			{
				return tooltip;
			}

			if (elementId == "character-screen.right-panel-header-module.DrepairButton")
			{
				return [
					{
						id = 1,
						type = "title",
						text = "Mark Items For Repair"
					},
					{
						id = 2,
						type = "description",
						text = "Marks all worthwile repairable items in your inventory for repair."
					},
					{
						id = 3,
						type = "hint",
						icon = "ui/icons/EIMO_mouse_right_button_shift.png",
						text = "Shift-click on items to mark their type for sale"
					},
					{
						id = 4,
						type = "hint",
						icon = "ui/icons/EIMO_mouse_right_button_ctrl_shift.png",
						text = "Ctrl-Shift-click on items to mark them as favorite (they will then not be sold)"
					}
				];
			}
			else if (elementId == "character-screen.right-panel-header-module.SalvageAllButton")
			{
				return [
					{
						id = 1,
						type = "title",
						text = "Mark Appropriate Items For Salvage"
					},
					{
						id = 2,
						type = "description",
						text = "Marks all salvageable items in your iventory with low enough ratio for salvage"
					}
				];
			}
			else if (elementId == "character-screen.right-panel-header-module.ChangeVisibilityButton")
			{
				return [
					{
						id = 1,
						type = "title",
						text = "Cycle Visibility of EIMO Info"
					},
					{
						id = 2,
						type = "description",
						text = "Cycles through 3 different levels of visibility for EIMO Info"
					}
				];
			}
			else if (elementId == "character-screen.right-panel-header-module.SellAllButton")
			{
				return [
					{
						id = 1,
						type = "title",
						text = "Sell All Loot"
					},
					{
						id = 2,
						type = "description",
						text = "Sell all items marked for sale. Favorited items will be ignored, even if marked for sale. Items with ratio 175+ will only be sold when in full condition."
					}
				];
			}
			else if (elementId == "tactical-combat-result-screen.loot-panel.SmartLootButton")
			{
				return [
					{
						id = 1,
						type = "title",
						text = "Smart Loot"
					},
					{
						id = 2,
						type = "description",
						text = "Intelligently loot all items including moving items from player inventory and automatically adding consumables to their totals."
					}
				];
			}

			return null;
		};
	});
	::mods_hookNewObjectOnce("ui/screens/character/character_screen", function ( o )
	{
		o.onFavoriteInventoryItem <- function ( itemID )
		{
			if (!("Assets" in this.World))
			{
				return;
			}

			local item = this.World.Assets.getStash().getItemByInstanceID(itemID).item;

			if (item.m.isFavorite)
			{
				item.m.isFavorite = false;
			}
			else
			{
				item.m.isFavorite = true;
			}

			return true;
		};
		o.onRepairAllButtonClicked <- function ()
		{
			if (!("Assets" in this.World))
			{
				return;
			}

			local items = this.World.Assets.getStash().getItems();

			foreach( i, item in items )
			{
				if (item != null && item.getItemType() < this.Const.Items.ItemType.Ammo)
				{
					local dratio = ::EIMOgetDratio(item);

					if (dratio > ::EIMOrepairThreshold)
					{
						item.setToBeRepaired(true, i);
					}
				}
			}

			this.loadStashList();
		};
		o.onSalvageAllButtonClicked <- function ()
		{
			local items = this.World.Assets.getStash().getItems();

			foreach( i, item in items )
			{
				if (item != null && item.canBeSalvaged() && !item.m.isFavorite)
				{
					if (::EIMOgetSratio(item) < ::EIMOsalvageThreshold)
					{
						item.setToBeSalvaged(true, i);
					}
				}
			}

			this.loadStashList();
		};
		o.onSetForSaleInventoryItem <- function ( data )
		{
			if (!("Assets" in this.World))
			{
				return;
			}

			local item = this.World.Assets.getStash().getItemByInstanceID(data).item;

			if (item != null)
			{
				if (!this.World.Flags.has(getItemSaleFlag(item)) || this.World.Flags.get(getItemSaleFlag(item)) == 0)
				{
					this.World.Flags.set(getItemSaleFlag(item), 1);
					this.loadStashList();
					return true;
				}
				else if (item != null && this.World.Flags.get(getItemSaleFlag(item)) == 1)
				{
					this.World.Flags.set(getItemSaleFlag(item), 0);
					this.loadStashList();
					return true;
				}
			}
			else
			{
				return false;
			}
		};
		o.EIMOonChangeVisibilityButtonClicked <- function ()
		{
			switch(visibilityLevel)
			{
			case 0:
			case 1:
				visibilityLevel = visibilityLevel + 1;
				break;

			case 2:
			default:
				visibilityLevel = 0;
			}

			this.loadStashList();
			return visibilityLevel;
		};
		o.EIMOgetVisibilityLevel <- function ()
		{
			return visibilityLevel;
		};
	});
	::mods_hookClass("ui/screens/world/modules/world_town_screen/town_shop_dialog_module", function ( o )
	{
		o.onSellAllButtonClicked <- function ()
		{
			if (!this.Tactical.isActive())
			{
				local dratio = 0;
				local item;
				local itemid;
				local removedItem;
				local shopStash = this.m.Shop.getStash();

				for( local i = this.World.Assets.getStash().getCapacity() - 1; i >= 0; i = i )
				{
					if (this.Stash.getItemAtIndex(i).item != null)
					{
						item = this.Stash.getItemAtIndex(i).item;
						itemid = item.getID() + item.getName();
						dratio = ::EIMOgetDratio(item);

						if (this.World.Flags.has(getItemSaleFlag(item)) && this.World.Flags.get(getItemSaleFlag(item)) == 1 && !item.m.isFavorite && !(item.getCondition() < item.getConditionMax() && dratio > ::EIMOwaitUntilRepairedThreshold))
						{
							removedItem = this.Stash.removeByIndex(i);

							if (removedItem != null)
							{
								this.World.Assets.addMoney(removedItem.getSellPrice());
								shopStash.add(removedItem);

								if (removedItem.isBought())
								{
									removedItem.setBought(false);
								}
								else
								{
									removedItem.setSold(true);
								}

								if (removedItem.isItemType(this.Const.Items.ItemType.TradeGood))
								{
									this.World.Statistics.getFlags().increment("TradeGoodsSold");
								}
							}
						}
					}

					i = --i;
				}

				local result = {
					Result = 0,
					Assets = this.m.Parent.queryAssetsInformation(),
					Shop = [],
					Stash = [],
					StashSpaceUsed = this.Stash.getNumberOfFilledSlots(),
					StashSpaceMax = this.Stash.getCapacity(),
					IsRepairOffered = this.m.Shop.isRepairOffered()
				};
				this.UIDataHelper.convertItemsToUIData(this.m.Shop.getStash().getItems(), result.Shop, this.Const.UI.ItemOwner.Shop);
				result.Stash = this.UIDataHelper.convertStashToUIData(false, this.m.InventoryFilter);

				if (this.World.Statistics.getFlags().has("TradeGoodsSold") && this.World.Statistics.getFlags().get("TradeGoodsSold") >= 10)
				{
					this.updateAchievement("Trader", 1, 1);
				}

				if (this.World.Statistics.getFlags().has("TradeGoodsSold") && this.World.Statistics.getFlags().get("TradeGoodsSold") >= 50)
				{
					this.updateAchievement("MasterTrader", 1, 1);
				}

				return result;
			}
		};
		o.EIMOgetVisibilityLevel <- function ()
		{
			return visibilityLevel;
		};
	});
});

