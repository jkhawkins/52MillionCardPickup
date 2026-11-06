#!/usr/bin/env python3
"""Regenerate the canonical 104-entry catalog from the approved GDD tables.
Run from the repository root. Effect strings are presentation; rules live in game/core.
"""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ROWS = '''C01|Deep Pockets|10||A|+52 capacity
C02|Deck Racks|5|C01:2|A|+208 capacity
C03|Casino Shelves|3|C02:2|B|+520 capacity
C04|Bigger Table|4|C03:1|C|×1.50 total capacity
C05|Overflow Tray|3|C01:4|B|One extra final manual pickup action above capacity
C06|Quick Count|6||A|+25% base deposit rate
C07|Sorted Stacks|5|C02:1|B|+20% deposit rate for batches of at least 10 decks
C08|Clean Transfer|4|C06:4|C|×1.35 deposit rate
C09|Full-Batch Bonus|3|C07:2|C|+30% deposit rate when starting at least 90% full
C10|Deposit Momentum|4|C06:2|B|+5% rate per continuous second; cap +25 percentage points
C11|Felt Rollers|3|C08:2|D|×1.60 deposit rate
C12|Industrial Counting|8|C11:2|E|×2.00 deposit rate
C13|Buffer Logistics|4|A03:1,C04:1|D|+10% capacity per helper, capped at +200% total
C14|Master Counting Room|1|C12:6,C04:4|F:3|×3 deposit rate and ×2 capacity
M01|Wide Grip|10||A|+1 card per manual pickup
M02|Two-Handed|5|M01:2|A|+25% manual pickup yield
M03|Sweeping Motion|4|M02:3|C|×1.50 manual pickup yield
M04|Fast Fingers|5|M01:1|A|+10% hold-to-pickup rate and animation speed
M05|Sweep Burst|1|M02:2|B|3% chance for a manual action to burst
M06|Burst Chance|5|M05:1|B|+2 percentage points Sweep Burst chance
M07|Burst Power|4|M05:1|C|+100% of normal yield to bursts; base burst ×2
M08|Manual Momentum|4|M02:1|B|12 manual pickups in 3 seconds: +20% manual yield for 3 seconds
M09|Momentum Duration|4|M08:1|B|+1 second Manual Momentum duration
M10|Pickup Combo|1|M04:2,M08:1|B|Manual stacks: +1% yield and +0.5% card income per stack
M11|Combo Ceiling|5|M10:1|C|+25 maximum Combo; base maximum 50
M12|Combo Memory|4|M10:1|B|+0.5 seconds before decay; −15% decay rate
M13|Combo Yield|4|M11:1|C|+0.25 percentage points yield per Combo stack
M14|Combo Value|4|M11:1|C|+0.125 percentage points income per Combo stack
M15|Combo Starter|3|M12:2|D|After full decay, next manual input starts with +10 Combo
M16|Shared Rhythm|1|M13:2,M14:2,A05:1|E|Helpers inherit 25% of current Combo yield and income bonuses
M17|Lucky Pickup|1|M05:1|B|5% Lucky chance: +100% cards and +50% money
M18|Lucky Chance|5|M17:1|C|+1.5 percentage points Lucky chance
M19|Lucky Cards|4|M17:1|C|+50% additional cards on Lucky pickups
M20|Lucky Money|4|M17:1|C|+25% additional money on Lucky pickups
A01|Auto-Picker|1|C01:1,M01:1|B|One helper: one card per second
A02|Picker Speed|8|A01:1|B|+20% base automatic pickup rate
A03|Additional Picker|7|A01:1,A02:2|C|+1 auto-picker
A04|Worker Grips|5|A03:1|C|+1 card per automatic pickup
A05|Mechanical Rhythm|4|A02:4|D|×1.50 automatic pickup rate
A06|Shared Tools|3|A04:1,M01:5|D|Helpers inherit 5% of flat Wide Grip and Worker Grips bonuses
A07|Continuous Motion|3|A02:2,C06:2|C|+15% automatic pickup rate during deposits
A08|Overclocked Workers|4|A05:2|E|×1.60 automatic pickup rate
A09|Auto-Depositor|1|A01:1,C06:2|B|Automatic deposits at 100% capacity
A10|Threshold Controls|1|A09:1|C|Select 25%, 50%, 75%, or 100% auto-deposit thresholds
A11|Smart Thresholds|3|A10:1,A07:1|D|Predictive earlier deposits reduce full-tray idle time
A12|Automation Value|4|A03:1|C|+15% income from automatically picked cards
A13|Seeker Integration|3|S02:1,A03:1|D|Helpers inherit +15% of the player's Seeker bias
A14|Master Automation|1|A08:3,A03:7|F:3|×2 helper rate, ×2 helper yield, +25 percentage points Continuous Motion
V01|Premium Stock|10||A|+15% card income
V02|Compound Value|5|V01:5|C|×1.35 card income
V03|Card Lamination|5|V01:2|B|+1 flat value to every card
V04|Ace Appreciation|4|V03:1|B|+100% Ace income
V05|Low Card Floor|4|V03:1|B|+20% income for ranks 2–10
V06|Face Card Premium|5|V01:3|B|+20% Jack, Queen and King income
V07|Royal Court|3|V06:3|D|×1.50 Jack, Queen and King income
V08|Deck Bonus|5|V01:2|B|+52 money per bound deck
V09|Complete Deck Multiplier|4|V08:2|D|×1.50 deck-bonus income
V10|Foil Chance|5|V01:3|C|+0.5 percentage points foil chance
V11|Foil Value|5|V10:1|C|+1× foil income multiplier
V12|Foil Polish|3|V11:3|E|×1.50 foil income
V13|Manual Appraisal|4|V01:4,M01:3|C|+20% income from manually picked cards
V14|Automated Appraisal|4|V01:4,A01:1|C|+20% income from automatically picked cards
V15|Full-Batch Appraisal|3|C09:1,V01:5|D|+25% card income for batches started at least 90% full
V16|Master Appraiser|1|V02:5,V09:3|F:3|×3 card income and ×2 deck-bonus income
S01|Card Seeker|1|V08:1|C|Replace 5% of generated identities with a random missing identity
S02|Seeker Focus|5|S01:1|C|+7 percentage points Seeker replacement chance
S03|Auto-Seeker|1|S02:2,A01:1|D|Collect one missing card every 60 seconds when space permits
S04|Seeker Speed|4|S03:1|D|−15% Auto-Seeker interval, multiplicatively
S05|Seeker Quantity|3|S03:1|E|+1 missing card per Auto-Seeker activation
S06|Guaranteed Find|3|S02:3|E|Guarantee a missing card every 100 generated cards; interval −20 per rank
S07|High-Value Priority|3|S02:1|D|20% of Seeker replacements favor the highest missing rank
S08|Master Seeker|1|S05:2,S06:2|F:3|+25 percentage points bias; two independent Auto-Seeker activations
H01|Heart Values|5|V01:2|B|+25% Heart card income
H02|Heart Appraisal|4|H01:2|C|+8% income to every non-Heart card
H03|Heart Foils|3|V10:1,H01:1|D|+1 percentage point Heart foil chance and +25% Heart foil income
H04|Heart of the Deck|1|H01:5,H02:3,V09:1|E|Heart income bonuses apply at 25% strength to deck bonuses
D01|Diamond Pockets|4|C02:1|B|+20% total capacity
D02|Diamond Counting|4|C06:2|C|+25% deposit rate
D03|Diamond Full Batch|3|C09:1,D02:1|D|+20% to Full-Batch Bonus and Full-Batch Appraisal effects
D04|Diamond Logistics|1|D01:4,D02:4,C11:1|E|×2 capacity and ×2 deposit rate
P01|Spade Tempo|4|A02:1|C|+20% automatic pickup rate
P02|Spade Grips|4|A04:1|C|+15% automatic pickup yield
P03|Spade Workforce|3|A03:2,P01:2|D|+1 helper and +10% rate to all helpers
P04|Spade Overdrive|1|P01:4,P02:3,X04:1|E|Card Surge automation effect 50% stronger; otherwise +25% helper rate
B01|Club Grip|4|M02:2|C|+25% manual pickup yield
B02|Club Combo|3|M10:1|D|+10 maximum Combo and +10% Combo yield effect
B03|Club Luck|3|M17:1,M05:1|D|+1 percentage point Lucky and Sweep Burst chance
B04|Club Performance|1|B01:4,B02:2|E|+25% timed ability duration; +50% manual yield while a timed ability is active
X01|Card Surge|1|M03:1|C|10 seconds: manual inputs resolve ×3 pickup actions; 60-second cooldown
X02|Surge Duration|4|X01:1|C|+2 seconds Card Surge duration
X03|Surge Potency|4|X01:1|D|+50% of base manual output to Card Surge per rank
X04|Surge Automation|1|X02:2,A05:1|E|Card Surge also grants ×2 automatic pickup rate
X05|Express Deposit|1|C08:1|C|×5 deposit rate for 8 seconds; 75-second cooldown
X06|Express Duration|4|X05:1|D|+2 seconds Express Deposit duration
X07|Express Overclock|4|X05:1|D|+100% Express speed and −5% cooldown per rank
X08|Foil Frenzy|1|V10:1,M17:1|D|12 seconds: +4pp foil chance, +100% Lucky chance, +50% income; 120-second cooldown
X09|Frenzy Duration|3|X08:1|D|+3 seconds Foil Frenzy duration
X10|Frenzy Potency|4|X08:1|E|+1pp foil chance and +15% card income during Frenzy per rank
X11|Seeker Pulse|1|S02:1|D|Next 52 generated cards: 65% Seeker bias; 150-second cooldown
X12|Pulse Charges|3|X11:1|D|+26 affected cards
X13|Pulse Focus|3|X11:1|E|+5pp Pulse bias and +2 guaranteed missing cards per rank
X14|Card Cyclone|1|M03:2,C04:1|D|Collect 10% of capacity, limited by free space; 90-second cooldown
X15|Cyclone Size|4|X14:1|E|+5 percentage points of capacity collected
X16|Cyclone Cooldown|4|X14:1|E|−10% Card Cyclone cooldown, multiplicatively'''
BRANCHES = {'C':'Capacity & Deposit','M':'Manual, Combo & Luck','A':'Automation','V':'Value, Decks & Foils','S':'Card Seekers','H':'Suit Specializations','D':'Suit Specializations','P':'Suit Specializations','B':'Suit Specializations','X':'Active Abilities'}
SUITS = {'H':'Hearts · Income','D':'Diamonds · Throughput','P':'Spades · Automation','B':'Clubs · Active play'}
PARENT = {'X01':'M','X02':'M','X03':'M','X04':'M','X05':'C','X06':'C','X07':'C','X08':'V','X09':'V','X10':'V','X11':'S','X12':'S','X13':'S','X14':'M','X15':'M','X16':'M'}
entries=[]
for line in ROWS.splitlines():
    ident,name,ranks,prereq,band,effect=line.split('|')
    cost_mult=1
    if ':' in band: band,cost_mult=band.split(':')
    entries.append({'id':ident,'name':name,'ranks':int(ranks),'prerequisites':[{'id':p.split(':')[0],'rank':int(p.split(':')[1])} for p in prereq.split(',') if p], 'band':band,'cost_multiplier':int(cost_mult),'effect':effect,'branch':BRANCHES[ident[0]],'parent_branch':PARENT.get(ident,ident[0]),'suit_branch':SUITS.get(ident[0],'')})
assert len(entries)==104
assert len({x['id'] for x in entries})==104
byid={x['id']:x for x in entries}
for e in entries:
    for p in e['prerequisites']:
        assert p['id'] in byid and 1<=p['rank']<=byid[p['id']]['ranks']
out={'schema_version':1,'bands':{'A':{'base':25,'growth':1.65},'B':{'base':2500,'growth':1.8},'C':{'base':100000,'growth':1.9},'D':{'base':2000000,'growth':2.0},'E':{'base':50000000,'growth':2.1},'F':{'base':1000000000,'growth':2.25}},'entries':entries}
(ROOT/'data').mkdir(exist_ok=True)
(ROOT/'data/upgrades.json').write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n')
print(f'Wrote {len(entries)} upgrades, {sum(x["ranks"] for x in entries)} purchasable ranks')
