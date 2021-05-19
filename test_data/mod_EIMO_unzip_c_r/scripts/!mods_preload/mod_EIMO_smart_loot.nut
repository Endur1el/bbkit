::mods_registerMod("SmartLootEIMO", 2.2, "Smart Loot integrated into EIMO");
::mods_queue(null, "EndsInventoryManagementOverhaulLegends, >mod_smartLoot", function ()
{
	::mods_hookNewObject("ui/screens/tactical/tactical_combat_result_screen", function ( o )
	{
		local CostPerTool = 250.0 / 20;
		local Assets = this.Const.World.Assets;
		local ItemType = this.Const.Items.ItemType;
		local isFood = function ( i )
		{
			return i.isItemType(ItemType.Food);
		};
		local baseSellValue = function ( i )
		{
			local fullValue = i.m.Value;

			if ("Assets" in this.World)
			{
				fullValue = fullValue * (this.World.Assets.getSellPriceMult() * this.Const.Difficulty.SellPriceMult[this.World.Assets.getEconomicDifficulty()]);
			}

			if (i.isItemType(ItemType.Food | ItemType.TradeGood))
			{
				return fullValue;
			}

			if (i.isItemType(ItemType.Loot))
			{
				return fullValue * Assets.BaseLootSellPrice;
			}

			if (i.isItemType(ItemType.Supply))
			{
				return fullValue * 1.5;
			}

			return fullValue * Assets.BaseSellPrice;
		};
		local sellValue = function ( i )
		{
			if (isFood(i))
			{
				return this.Math.min(i.getAmount(), i.getSpoilInDays() * 10) * (i.isDesirable() ? 6 : 4);
			}
			else
			{
				local value = baseSellValue(i);
				local condition = i.getCondition();
				local maxCondition = i.getConditionMax();

				if (condition < maxCondition)
				{
					if (::EIMOgetDratio(i) >= ::EIMOwaitUntilRepairedThreshold)
					{
						local toolsRequired = (maxCondition - condition) / 15.0;
						value = value - toolsRequired * CostPerTool;
					}
					else
					{
						value = value * condition / maxCondition;
					}
				}

				return value;
			}
		};
		local show = o.show;
		o.show = function ()
		{
			if (!this.isVisible())
			{
				local foodValue = function ( i )
				{
					return i.getAmount() * i.getSpoilInDays();
				};
				this.Tactical.CombatResultLoot.getItems().sort(function ( a, b )
				{
					local ac = isFood(a);
					local bc = isFood(b);

					if (ac)
					{
						return bc ? foodValue(b) & foodValue(a) : -1;
					}
					else if (bc)
					{
						return 1;
					}

					ac = a.isItemType(ItemType.Supply);
					bc = b.isItemType(ItemType.Supply);

					if (ac && !bc)
					{
						return -1;
					}
					else if (bc && !ac)
					{
						return 1;
					}

					ac = a.isItemType(ItemType.Crafting);
					bc = b.isItemType(ItemType.Crafting);

					if (ac && !bc)
					{
						return -1;
					}
					else if (bc && !ac)
					{
						return 1;
					}

					return sellValue(b) & sellValue(a);
				});
				  // [012]  OP_CLOSE          0      1    0    0
			}

			show();
		};
		o.onSmartLootButtonPressed <- function ()
		{
			if (this.Tactical.CombatResultLoot.isEmpty())
			{
				return this.Const.UI.convertErrorToUIData(this.Const.UI.Error.FoundLootListIsEmpty);
			}

			local si = 0;
			local stash = this.Stash.getItems();
			local loot = this.Tactical.CombatResultLoot.getItems();
			local shrinkLoot = false;
			local soundPlayed = false;
			local li;
			local lootis = this.array(loot.len());

			for( local i = 0; i < lootis.len(); i = ++i )
			{
				lootis[i] = i;
			}

			lootis.sort(function ( ai, bi )
			{
				return sellValue(loot[bi]) & sellValue(loot[ai]);
			});
			local onItemDropped = function ( i )
			{
				i.onRemovedFromStash(this.Stash.getID());
			};
			local onItemTaken = function ( i, idx )
			{
				i.onAddedToStash(this.Stash.getID());

				if (i != null && i.getItemType() < this.Const.Items.ItemType.Ammo)
				{
					if (::EIMOgetDratio(i) > ::EIMOwaitUntilRepairedThreshold)
					{
						i.setToBeRepaired(true, idx);
					}
					else if (::EIMOgetSratio(i) < ::EIMOsalvageThreshold)
					{
						if (i.canBeSalvaged())
						{
							i.setToBeSalvaged(true, idx);
						}
					}
				}

				if (!soundPlayed)
				{
					i.playInventorySound(this.Const.Items.InventoryEventType.PlacedInBag);
					soundPlayed = true;
				}
			};

			for( li = 0; li < lootis.len(); li = ++li )
			{
				local item = loot[lootis[li]];

				if (item.isItemType(ItemType.Supply))
				{
					item.consume();
					loot[lootis[li]] = null;
					shrinkLoot = true;
				}
			}

			for( li = 0; li < lootis.len(); li = ++li )
			{
				local item = loot[lootis[li]];

				if (item == null)
				{
				}
				else
				{
					while (si < stash.len() && stash[si] != null)
					{
						si = ++si;
					}

					if (si == stash.len())
					{
						break;
					}

					stash[si++] = item;
					loot[lootis[li]] = null;
					onItemTaken(item, si - 1);
					shrinkLoot = true;
				}
			}

			if (li < lootis.len())
			{
				local foodItems = [];
				local foodPerDay = "Assets" in this.World ? this.World.Assets.getDailyFoodCost() * this.World.Assets.m.FoodConsumptionMult : 30;

				foreach( i in stash )
				{
					if (isFood(i))
					{
						foodItems.append(i);
					}
				}

				local foodOrder = "Assets" in this.World ? this.World.Assets.sortFoodByFreshness : function ( a, b )
				{
					local ac = a.isDesirable();
					local bc = b.isDesirable();

					if (ac && !bc)
					{
						return -1;
					}
					else if (bc && !ac)
					{
						return 1;
					}
					else
					{
						return a.getBestBeforeTime() & b.getBestBeforeTime();
					}
				};
				foodItems.sort(foodOrder);
				local removeFoodItem = function ( i )
				{
					foodItems.remove(foodItems.find(i));
				};
				local addFoodItem = function ( i )
				{
					local left = 0;
					local right = foodItems.len() - 1;

					while (left <= right)
					{
						local mid = (left + right) / 2;
						local cmp = foodOrder(foodItems[mid], i);

						if (cmp < 0)
						{
							left = mid + 1;
						}
						else if (cmp > 0)
						{
							right = mid - 1;
						}
						else
						{
							left = mid;
							break;
						}
					}

					foodItems.insert(left, i);
				};
				local countFoodDays = function ( withoutItem = null, withItem = null )
				{
					local days = 0;
					local remaining = foodPerDay;
					local consume = function ( i )
					{
						for( local amount = i.getAmount(); amount > 0 && i.getSpoilInDays() > days; remaining = foodPerDay )
						{
							remaining = remaining - amount;

							if (remaining >= 0)
							{
								break;
							}

							amount = -remaining;
							days = ++days;
						}
					};

					foreach( item in foodItems )
					{
						if (item == withoutItem)
						{
							continue;
						}

						if (withItem != null && foodOrder(item, withItem) >= 0)
						{
							consume(withItem);
							withItem = null;
						}

						consume(item);
					}

					if (withItem != null)
					{
						consume(withItem);
					}

					return days + (foodPerDay - remaining) / foodPerDay.tofloat();
				};
				local stashis = this.array(stash.len());

				for( local i = 0; i < stashis.len(); i = ++i )
				{
					stashis[i] = i;
				}

				stashis.sort(function ( ai, bi )
				{
					return sellValue(stash[ai]) & sellValue(stash[bi]);
				});
				local IneligibleTypes = ItemType.Legendary | ItemType.Named | ItemType.Tool | ItemType.Crafting | ItemType.Supply | ItemType.Usable;
				local isEligible = function ( i )
				{
					local type = i.getItemType();

					if (type & IneligibleTypes || type == ItemType.Misc)
					{
						return false;
					}

					if (type & ItemType.Accessory && i.getSlotType() != this.Const.ItemSlot.Bag)
					{
						return false;
					}

					if (isFood(i) && countFoodDays(i) < 4)
					{
						return false;
					}

					if (i.m.isFavorite)
					{
						return false;
					}

					return true;
				};

				for( si = 0; li < lootis.len(); li = ++li )
				{
					local lootItem = loot[lootis[li]];
					local stashItem;

					if (lootItem == null)
					{
					}
					else
					{
						stashItem = stash[stashis[si]];

						while (si < stashis.len() && !isEligible(stashItem))
						{
							si = ++si;
						}

						if (si == stashis.len() || sellValue(lootItem) <= sellValue(stashItem))
						{
							break;
						}

						stash[stashis[si++]] = lootItem;
						loot[lootis[li]] = stashItem;

						if (isFood(stashItem))
						{
							removeFoodItem(stashItem);
						}

						if (isFood(lootItem))
						{
							addFoodItem(lootItem);
						}

						onItemDropped(stashItem);
						onItemTaken(lootItem, si - 1);
					}
				}

				if (foodItems.len() != 0)
				{
					local foodValueMult = this.Math.minf(0.2, foodItems.len() / foodPerDay.tofloat());
					local foodValue = function ( i )
					{
						local amount = i.getAmount();
						return this.Math.minf(amount * foodValueMult, i.getSpoilInDays()) + amount * 0.04;
					};
					lootis.sort(function ( ai, bi )
					{
						local a = loot[ai];
						local b = loot[bi];
						local ac = a != null && isFood(a);
						local bc = b != null && isFood(b);
						return ac ? (bc ? foodValue(b) & foodValue(a) : -1) : bc ? 1 : 0;
					});
					stashis.sort(function ( ai, bi )
					{
						local a = stash[ai];
						local b = stash[bi];
						local ac = isFood(a);
						local bc = isFood(b);
						return ac ? (bc ? foodValue(a) & foodValue(b) : -1) : bc ? 1 : 0;
					});
					local foodDays = countFoodDays();
					li = 0;

					for( si = 0; li < lootis.len() && si < stashis.len(); li = ++li )
					{
						local lootItem = loot[lootis[li]];

						if (lootItem == null)
						{
						}
						else
						{
							local stashItem = stash[stashis[si]];

							if (!isFood(lootItem) || !isFood(stashItem) || foodValue(lootItem) <= foodValue(stashItem))
							{
								break;
							}

							local newFoodDays = countFoodDays(stashItem, lootItem);

							if (newFoodDays > foodDays)
							{
								stash[stashis[si++]] = lootItem;
								loot[lootis[li]] = stashItem;
								removeFoodItem(stashItem);
								addFoodItem(lootItem);
								onItemDropped(stashItem);
								onItemTaken(lootItem, si - 1);
								foodDays = newFoodDays;
							}
						}
					}

					  // [325]  OP_CLOSE          0     19    0    0
				}

				  // [326]  OP_CLOSE          0     10    0    0
			}

			if (shrinkLoot)
			{
				$[stack offset 0].Tactical.CombatResultLoot.shrink();
			}

			return {
				stash = $[stack offset 0].UIDataHelper.convertStashToUIData(true),
				foundLoot = $[stack offset 0].UIDataHelper.convertCombatResultLootToUIData()
			};
		};
	});
});

