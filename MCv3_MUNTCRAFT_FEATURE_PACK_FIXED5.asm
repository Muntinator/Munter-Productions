;==============================================================================
; MCv2 - Sinecraft-style TI-84 Plus C Silver Edition expanded full-feature build candidate
;------------------------------------------------------------------------------
; Target: TI-84 Plus C Silver Edition (Z80), 320x240 color LCD
; Logical renderer: 96x64, scaled 2x and centered on the LCD for Z80 speed
; Toolchain: SPASM-ng / ti84pcse.inc (SPASM-ng CSE target)
; Program header: tExtTok,tAsm84CCmp
;
; Based on the uploaded Sinecraft 0.2.0 source by James Livesey.
; Original project is MIT licensed:
; Copyright © James Livesey. All Rights Reserved.
; See the original Sinecraft LICENCE.md for the full license text.
;
; CSE-specific changes from the monochrome build:
;   - uses ti84pcse.inc and the CSE assembly header
;   - draws through the CSE ILine/IPoint LCD routines
;   - uses the CSE ILine/IPoint foreground color state (drawFGColor)
;   - keeps the 96x64 logical renderer so the Z80 is not overloaded
;   - scales the logical frame 2x onto the 320x240 LCD
; Controls:
;   8/5 = forward/back
;   4/6 = strafe
;   Arrow keys = camera
;   ENTER = jump
;   2nd = mine/break (hold)
;   ALPHA = place
;   + / - = hotbar
;   WINDOW = inventory
;   VARS = crafting
;   MODE = toggle creative/survival
;   CLEAR = quit
;
; This is deliberately written as one .asm file for SPASM-ng Online.
; Calculator program name: MCV1 (4 characters; CSE program-token-safe).
; Version: MCv3 feature-packed build candidate (NOT emulator/debug verified).
;==============================================================================

.nolist
#include "ti84pcse.inc"
.list

.org UserMem-2

BinaryStart:
    .db tExtTok,tAsm84CCmp

ASMStart:
    ; MCv3 main menu before gameplay initialization.
    call MC3_MainMenu
    jp c,QuitGame

;------------------------------------------------------------------------------
; Constants
;------------------------------------------------------------------------------
SCREEN_W        .equ 96
SCREEN_H        .equ 64
SCREEN_BYTES    .equ 12

BLOCK_EMPTY     .equ 0
BLOCK_STONE     .equ 1
BLOCK_GRASS     .equ 2
BLOCK_DIRT      .equ 3
BLOCK_COBBLE    .equ 4
BLOCK_PLANK     .equ 5
BLOCK_WOOD      .equ 17
BLOCK_LEAVES    .equ 18
BLOCK_TABLE     .equ 58
BLOCK_SAND      .equ 6
ITEM_STICK      .equ 7         ; compact TI-84 internal item IDs
ITEM_AXE        .equ 8
ITEM_COAL       .equ 20
ITEM_IRON       .equ 21
ITEM_GOLD       .equ 22

BLOCK_WATER     .equ 9
BLOCK_LAVA      .equ 10
BLOCK_COAL_ORE  .equ 11
BLOCK_IRON_ORE  .equ 12
BLOCK_GOLD_ORE  .equ 13
BLOCK_BEDROCK   .equ 14
BLOCK_GRAVEL    .equ 15
BLOCK_GLASS     .equ 16
BLOCK_TORCH     .equ 19
BLOCK_SNOW      .equ 20

GAME_SURV       .equ 0
GAME_CREATIVE  .equ 1

WORLD_R         .equ 3
EDIT_MAX        .equ 40
HOTBAR_COUNT    .equ 6
INV_ROWS        .equ 4
MOB_MAX         .equ 4
SAVE_MAGIC      .equ $5A
INV_COUNT       .equ 24
SLOT_EMPTY      .equ 0

; MCv1 expanded content IDs / systems
BLOCK_CACTUS      .equ 23
BLOCK_BED         .equ 24
BLOCK_FURNACE     .equ 25
BLOCK_SNOWBLOCK   .equ 26
BLOCK_ICE         .equ 27
BLOCK_FLOWER      .equ 28
BLOCK_TALLGRASS   .equ 29
BLOCK_LAMP        .equ 30
BLOCK_CRAFTING    .equ 58

ITEM_WOOD_PICK    .equ 40
ITEM_STONE_PICK   .equ 41
ITEM_IRON_PICK    .equ 42
ITEM_GOLD_PICK    .equ 43
ITEM_DIAMOND_PICK .equ 44
ITEM_WOOD_SWORD   .equ 45
ITEM_STONE_SWORD  .equ 46
ITEM_IRON_SWORD   .equ 47
ITEM_GOLD_SWORD   .equ 48
ITEM_DIAMOND_SWORD .equ 49
ITEM_COOKED_MEAT  .equ 50
ITEM_BED          .equ 51
ITEM_CACTUS       .equ 52
ITEM_FLOWER       .equ 53
ITEM_SEED         .equ 54
ITEM_STRING         .equ 91
ITEM_STONE          .equ 92
ITEM_FEATHER        .equ 93
ITEM_COOKED_MEAT2   .equ 94
ITEM_LEATHER        .equ 95
ITEM_WOOL           .equ 96

BIOME_PLAINS      .equ 0
BIOME_FOREST      .equ 1
BIOME_DESERT      .equ 2
BIOME_SNOW        .equ 3
BIOME_TAIGA       .equ 4

WEATHER_CLEAR     .equ 0
WEATHER_RAIN      .equ 1
WEATHER_SNOW      .equ 2

DIFF_PEACEFUL     .equ 0
DIFF_EASY         .equ 1
DIFF_NORMAL       .equ 2
DIFF_HARD         .equ 3

DROP_MAX          .equ 8
ACH_MAX           .equ 16
SAVE_SLOTS        .equ 4
SAVE_SLOT_BYTES   .equ 512

; MCv2 expanded gameplay IDs
BLOCK_FARMLAND      .equ 31
BLOCK_WHEAT         .equ 32
BLOCK_WHEAT_RIPE    .equ 33
BLOCK_OBSIDIAN      .equ 34
BLOCK_NETHER_PORTAL .equ 35
BLOCK_NETHERRACK    .equ 36
BLOCK_QUARTZ        .equ 37
BLOCK_ENDSTONE      .equ 38
BLOCK_PURPUR        .equ 39
BLOCK_CHORUS        .equ 40
BLOCK_REDSTONE_ORE  .equ 41
BLOCK_REDSTONE      .equ 42
BLOCK_BOOKSHELF     .equ 43
BLOCK_TNT           .equ 44
BLOCK_SANDSTONE     .equ 45
BLOCK_SOUL_SAND     .equ 46
BLOCK_MOSS          .equ 47
BLOCK_GLOWSTONE     .equ 48
BLOCK_LADDER        .equ 49
BLOCK_RAIL          .equ 50
BLOCK_BUTTON        .equ 51
BLOCK_PRESSURE      .equ 52
BLOCK_SIGN          .equ 53
BLOCK_CHEST         .equ 54
BLOCK_ENCHANT       .equ 55
BLOCK_ANVIL         .equ 56
BLOCK_BREWING       .equ 57

ITEM_WHEAT_SEED     .equ 62
ITEM_WHEAT          .equ 63
ITEM_RAW_MEAT       .equ 64
ITEM_BREAD          .equ 65
ITEM_RAW_FISH       .equ 66
ITEM_COOKED_FISH    .equ 67
ITEM_EMERALD        .equ 68
ITEM_DIAMOND        .equ 69
ITEM_ARROW          .equ 70
ITEM_BOW            .equ 71
ITEM_SHIELD         .equ 72
ITEM_FISHING_ROD    .equ 73
ITEM_POTION_HEAL    .equ 74
ITEM_POTION_SPEED   .equ 75
ITEM_POTION_STRENGTH .equ 76
ITEM_POTION_POISON  .equ 77
ITEM_POTION_FIRE_RES .equ 78
ITEM_ENDER_PEARL    .equ 79
ITEM_GOLDEN_APPLE   .equ 80
ITEM_BOOK           .equ 81
ITEM_ENCHANTED_BOOK .equ 82
ITEM_IRON_HELMET    .equ 83
ITEM_IRON_CHEST     .equ 84
ITEM_IRON_LEGS      .equ 85
ITEM_IRON_BOOTS     .equ 86
ITEM_DIAMOND_HELMET .equ 87
ITEM_DIAMOND_CHEST  .equ 88
ITEM_DIAMOND_LEGS   .equ 89
ITEM_DIAMOND_BOOTS  .equ 90

DIM_OVERWORLD       .equ 0
DIM_NETHER          .equ 1
DIM_END             .equ 2

EFFECT_NONE         .equ 0
EFFECT_SPEED        .equ 1
EFFECT_STRENGTH     .equ 2
EFFECT_REGEN        .equ 3
EFFECT_POISON       .equ 4
EFFECT_FIRE_RES     .equ 5

PROJ_MAX            .equ 4
NPC_MAX             .equ 2

; GetCSC aliases supplied by ti83plus.inc are used below.
;------------------------------------------------------------------------------
; Program entry
;------------------------------------------------------------------------------

bcall(_maybe_ClrScrnFull)
    set fullScrnDraw,(iy+apiFlg4)
    set plotLoc,(iy+plotFlags)
    call SetColorBlack
    call InitGame

MainLoop:
    call ReadKeys
    call PhysicsTick
    call S84_WorldTick
    call S84_SurvivalTick
    call S84_MobTick
    call S84_LinkTick
    call S84_AdvancedTick
    call MC3_LivestockTick
    call MC3_MobSoundTick

    ; Only redraw when something actually changed.
    ; The CSE renderer writes directly to the LCD, so clearing and
    ; redrawing every CPU loop makes the clear operation visibly flash.
    ld a,(S84_RenderDirty)
    or a
    jp z,MainNoRender

    call RenderFrame
    call MC3_RenderLivestock
    call DrawHUD
    call DrawCrosshair
    call S84_RenderWeather
    xor a
    ld (S84_RenderDirty),a

MainNoRender:
    call S84_MusicTick
    call SmallDelay
    jp MainLoop

QuitGame:
    call S84_Silence
    bcall(_maybe_ClrScrnFull)
    bcall(_GetCSC)
    ret

;------------------------------------------------------------------------------
; Initialization
;------------------------------------------------------------------------------
InitGame:
    xor a
    ld (S84_GameMode),a
    ld (S84_Yaw),a
    ld (S84_Pitch),a
    ld (S84_HotbarSel),a
    ld (S84_EditCount),a
    ld a,1
    ld (S84_RenderDirty),a
    xor a
    ld (S84_InvOpen),a
    ld (S84_CraftOpen),a
    ld (S84_PauseOpen),a

    ld a,6
    ld (S84_PlayerX),a
    ld a,4
    ld (S84_PlayerY),a
    ld a,6
    ld (S84_PlayerZ),a
    xor a
    ld (S84_YVel),a

    xor a
    ld (S84_WorldTime),a
    ld (S84_WorldDay),a
    ld (S84_NightLevel),a
    ld (S84_PlayerHP),a
    ld (S84_PlayerHunger),a
    ld (S84_HungerClock),a
    ld (S84_MobTickCount),a
    ld (S84_LinkMode),a
    ld (S84_LinkPeerReady),a
    ld (S84_SaveValid),a
    ld (S84_SystemMenuSel),a
    ld (S84_CraftRecipe),a
    ld (S84_InvCursor),a
    ld (S84_ChunkX),a
    ld (S84_ChunkZ),a
    ld a,20
    ld (S84_PlayerHP),a
    ld (S84_PlayerHunger),a

    call S84_InitMobsReal
    call MC3_InitLivestock
    ld a,(MC3_InitialMode)
    ld (S84_GameMode),a

    ; Start with the same basic block inventory idea as Sinecraft.
    ld hl,S84_InvTypes
    ld a,BLOCK_STONE
    ld (hl),a
    inc hl
    ld a,BLOCK_GRASS
    ld (hl),a

    ld hl,S84_InvCounts
    ld a,16
    ld (hl),a
    inc hl
    ld (hl),a

    ; Prototype starter kit.
    ld hl,S84_InvTypes+2
    ld a,BLOCK_WOOD
    ld (hl),a
    inc hl
    ld a,BLOCK_PLANK
    ld (hl),a
    inc hl
    ld a,ITEM_COAL
    ld (hl),a
    ld hl,S84_InvCounts+2
    ld a,8
    ld (hl),a
    inc hl
    ld a,8
    ld (hl),a
    inc hl
    ld a,4
    ld (hl),a

    ; MCv2 starter utility items.
    ld hl,S84_InvTypes+5
    ld a,ITEM_FISHING_ROD
    ld (hl),a
    inc hl
    ld a,ITEM_BREAD
    ld (hl),a
    inc hl
    ld a,ITEM_WHEAT_SEED
    ld (hl),a
    ld hl,S84_InvCounts+5
    ld a,1
    ld (hl),a
    inc hl
    ld a,4
    ld (hl),a
    inc hl
    ld a,8
    ld (hl),a

    ; Clear all edit records.
    call ClearEdits

    ; MCv1 world/config defaults.
    ld a,$31
    ld (S84_WorldSeed),a
    ld a,$A7
    ld (S84_WorldSeed+1),a
    xor a
    ld (S84_WorldSeed+2),a
    ld a,$5C
    ld (S84_WorldSeedHi),a
    xor a
    ld (S84_Biome),a
    ld (S84_Weather),a
    ld (S84_Difficulty),a
    ld (S84_WeatherTimer),a
    ld (S84_FurnaceFuel),a
    ld (S84_FurnaceProgress),a
    ld (S84_FurnaceInput),a
    ld (S84_FurnaceOutput),a
    ld (S84_Sleeping),a
    ld (S84_DropCount),a
    ld (S84_AchievementCount),a
    ld a,6
    ld (S84_SpawnX),a
    ld a,4
    ld (S84_SpawnY),a
    ld a,6
    ld (S84_SpawnZ),a
    ld a,DIFF_NORMAL
    ld (S84_Difficulty),a
    ld a,32
    ld (S84_FOV),a
    ld a,8
    ld (S84_RenderDistance),a
    ld a,2
    ld (S84_TimeScale),a
    ld a,1
    ld (S84_Level),a
    xor a
    ld (S84_XPLo),a
    ld (S84_XPHi),a
    ld (S84_ArmorValue),a
    ld (S84_ShieldUp),a
    ld a,32
    ld (S84_ShieldDurability),a
    ld a,20
    ld (S84_Oxygen),a
    xor a
    ld (S84_Fishing),a
    ld (S84_CropTimer),a
    ld (S84_Dimension),a
    ld (S84_EffectType),a
    ld (S84_EffectTimer),a
    ld (S84_ProjectileCount),a
    ld (S84_Emeralds),a
    ld (S84_EnchantmentLevel),a
    ld a,64
    ld (S84_TradeTimer),a
    ld hl,S84_ArmorHelmet
    ld de,S84_ArmorChest
    ld bc,3
    xor a
    ld (hl),a
    ldir
    ld hl,S84_ArmorBoots
    ld (hl),a
    ld hl,S84_ProjectileType
    ld de,S84_ProjectileType+1
    ld bc,PROJ_MAX-1
    ld (hl),a
    ldir
    ld hl,S84_InvDurability
    ld de,S84_InvDurability+1
    ld bc,INV_COUNT-1
    xor a
    ld (hl),a
    ldir
    ; Four volatile quick-save slots are available even before AppVar binding.
    xor a
    ld (S84_SaveSlot),a

    ; Start the original Sinecraft soundtrack.
    call S84_InitMusic
    ret

ClearEdits:
    xor a
    ld (S84_EditCount),a
    ld hl,S84_EditData
    ld de,S84_EditData+1
    ld bc,EDIT_MAX*4-1
    ld (hl),a
    ldir
    ret

;------------------------------------------------------------------------------
; Input
;------------------------------------------------------------------------------
ReadKeys:
    bcall(_GetCSC)
    ld (S84_KeyNow),a
    or a
    ret z

    ; Any key that reaches the game loop can change the displayed state.
    ld a,1
    ld (S84_RenderDirty),a
    ld a,(S84_KeyNow)

    cp skEnter
    jp z,KeyJump
    cp skAlpha
    jp z,KeyPlace
    cp sk2nd
    jp z,KeyBreak
    cp skDel
    jp z,KeyBreak

    cp skUp
    jp z,KeyUp
    cp skRight
    jp z,KeyRight
    cp skDown
    jp z,KeyDown
    cp skLeft
    jp z,KeyLeft

    cp sk8
    jp z,MoveForward
    cp sk5
    jp z,MoveBack
    cp sk4
    jp z,MoveLeft
    cp sk6
    jp z,MoveRight
    cp skAdd
    jp z,HotbarNext
    cp skSub
    jp z,HotbarPrev

    ; TRACE -> music on/off
    cp skTrace
    jp z,S84_ToggleMusic

    ; ZOOM -> next music track
    cp skZoom
    jp z,S84_NextMusic

    ; WINDOW -> inventory
    cp skWindow
    jp z,OpenInventory

    ; VARS -> crafting
    cp skVars
    jp z,OpenCrafting

    ; MODE -> toggle survival/creative
    cp skMode
    jp z,ToggleMode

    ; Y= -> system menu (save/load/link/help)
    cp S84_KEY_YEQU
    jp z,OpenSystemMenu

    ; GRAPH -> quick RAM save / second press loads
    cp skGraph
    jp z,S84_QuickSaveLoad

    ; CLEAR exits
    cp skClear
    jp z,QuitGame

    ret

KeyJump:
    call TryJump
    ret

KeyPlace:
    call PlaceTarget
    ret

KeyBreak:
    call BreakTarget
    ret

KeyUp:
    ld a,(S84_Pitch)
    cp 8
    ret z
    inc a
    ld (S84_Pitch),a
    ret

KeyDown:
    ld a,(S84_Pitch)
    cp 248
    ret z
    dec a
    ld (S84_Pitch),a
    ret

KeyLeft:
    ld a,(S84_Yaw)
    dec a
    and 31
    ld (S84_Yaw),a
    ret

KeyRight:
    ld a,(S84_Yaw)
    inc a
    and 31
    ld (S84_Yaw),a
    ret

MoveForward:
    ld a,1
    call MoveRelative
    ret

MoveBack:
    ld a,3
    call MoveRelative
    ret

MoveLeft:
    ld a,2
    call MoveRelative
    ret

MoveRight:
    ld a,4
    call MoveRelative
    ret

HotbarNext:
    ld a,(S84_HotbarSel)
    inc a
    cp HOTBAR_COUNT
    jp c,HotbarStoreN
    xor a
HotbarStoreN:
    ld (S84_HotbarSel),a
    ret

HotbarPrev:
    ld a,(S84_HotbarSel)
    or a
    jp nz,HotbarDec
    ld a,HOTBAR_COUNT-1
    jp HotbarStoreP
HotbarDec:
    dec a
HotbarStoreP:
    ld (S84_HotbarSel),a
    ret

ToggleMode:
    ld a,(S84_GameMode)
    xor 1
    ld (S84_GameMode),a
    ret

OpenInventory:
    call InventoryScreen
    ret

OpenCrafting:
    call CraftingScreen
    ret

;------------------------------------------------------------------------------
; Movement and simple collision
;------------------------------------------------------------------------------
MoveRelative:
    ; A = 1 fwd, 2 left, 3 back, 4 right.
    push af
    ld a,(S84_Yaw)
    and 24
    ; Quantize yaw to 8 compass directions.
    rrca
    rrca
    rrca
    and 3
    ld b,a
    pop af

    cp 1
    jp z,MRForward
    cp 3
    jp z,MRBack
    cp 2
    jp z,MRLeft

; right
    ld a,b
    cp 0
    jp z,MRRightEast
    cp 1
    jp z,MRRightSouth
    cp 2
    jp z,MRRightWest
    jp MRRightNorth

MRForward:
    ld a,b
    cp 0
    jp z,MRNorth
    cp 1
    jp z,MREast
    cp 2
    jp z,MRSouth
    jp MRWest

MRBack:
    ld a,b
    cp 0
    jp z,MRSouth
    cp 1
    jp z,MRWest
    cp 2
    jp z,MRNorth
    jp MREast

MRLeft:
    ld a,b
    cp 0
    jp z,MRWest
    cp 1
    jp z,MRNorth
    cp 2
    jp z,MREast
    jp MRSouth

MRNorth:
    ld a,(S84_PlayerZ)
    dec a
    call TryMoveZFix
    ret
MRSouth:
    ld a,(S84_PlayerZ)
    inc a
    call TryMoveZFix
    ret
MREast:
    ld a,(S84_PlayerX)
    inc a
    call TryMoveX
    ret
MRWest:
    ld a,(S84_PlayerX)
    dec a
    call TryMoveX
    ret

MRRightEast:
    jp MREast
MRRightSouth:
    jp MRSouth
MRRightWest:
    jp MRWest
MRRightNorth:
    jp MRNorth

TryMoveX:
    ld (S84_TempMove),a
    ld a,(S84_PlayerZ)
    ld c,a
    ld a,(S84_TempMove)
    ld b,a
    call GetColumnHeight
    ld b,a
    ld a,(S84_PlayerY)
    sub 2
    cp b
    jp c,TMXBlocked
    ld a,b
    add a,2
    ld (S84_PlayerY),a
    ld a,(S84_TempMove)
    ld (S84_PlayerX),a
TMXBlocked:
    ret

TryMoveZ:
    jp TryMoveZFix

TryMoveZFix:
    ld (S84_TempMove),a
    ld a,(S84_PlayerX)
    ld c,a
    ld a,(S84_TempMove)
    ld b,a
    call GetColumnHeight
    ld b,a
    ld a,(S84_PlayerY)
    sub 2
    cp b
    jp c,TMZBlocked
    ld a,b
    add a,2
    ld (S84_PlayerY),a
    ld a,(S84_TempMove)
    ld (S84_PlayerZ),a
TMZBlocked:
    ret

;------------------------------------------------------------------------------
; Physics
;------------------------------------------------------------------------------
PhysicsTick:
    call S84_CheckFluidState

    ; Gravity is intentionally quantized for Z80 performance.
    ld a,(S84_YVel)
    or a
    jp z,PTGround

    ; While airborne, keep rendering the changing player height.
    ld a,1
    ld (S84_RenderDirty),a
    ld a,(S84_YVel)
    ld b,a
    ld a,(S84_PlayerY)
    add a,b
    ld (S84_PlayerY),a

    ld a,(S84_YVel)
    dec a
    dec a
    ld (S84_YVel),a

PTGround:
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerZ)
    ld c,a
    call GetColumnHeight
    add a,2
    ld b,a

    ld a,(S84_PlayerY)
    cp b
    jp nc,PTDone
    ld a,b
    ld (S84_PlayerY),a
    xor a
    ld (S84_YVel),a

PTDone:
    ret

TryJump:
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerZ)
    ld c,a
    call GetColumnHeight
    add a,2
    ld b,a
    ld a,(S84_PlayerY)
    cp b
    jp nz,TJDone
    ld a,4
    ld (S84_YVel),a
TJDone:
    ret

;------------------------------------------------------------------------------
; MCv2 utility helpers that were implicit in earlier prototypes.
;------------------------------------------------------------------------------
rnd:
    ; 16-bit Galois-ish LFSR; OUT A = low byte.
    ld hl,(S84_RndSeed)
    ld a,h
    rra
    ld a,l
    rra
    xor h
    ld h,a
    ld a,l
    rra
    ld a,h
    rra
    xor l
    ld l,a
    xor h
    ld h,a
    res 7,h
    ld (S84_RndSeed),hl
    ld a,l
    ret

FindEdit:
    ; IN B=x, C=y, D=z. Carry if edit exists, S84_EditType = type.
    ld a,(S84_EditCount)
    or a
    ret z
    ld e,a
    ld hl,S84_EditData
FEloop:
    ld a,(hl)
    cp b
    jp nz,FEnext
    inc hl
    ld a,(hl)
    cp c
    jp nz,FEback1
    inc hl
    ld a,(hl)
    cp d
    jp nz,FEback2
    inc hl
    ld a,(hl)
    ld (S84_EditType),a
    scf
    ret
FEback2:
    dec hl
FEback1:
    dec hl
FEnext:
    inc hl
    inc hl
    inc hl
    inc hl
    dec e
    jp nz,FEloop
    and a
    ret

S84_MobIndexBase:
    ; IN A=index, OUT HL=index. Kept as a tiny compatibility helper.
    ld l,a
    ld h,0
    ret

;------------------------------------------------------------------------------
; Terrain generation / world lookup
; This ports the concept of Sinecraft's generated-vs-changed block lookup
; into a tiny deterministic height-field suitable for 24 KiB RAM.
;------------------------------------------------------------------------------
GetColumnHeight:
    ; IN A=x, C=z. OUT A=height. Dimension-aware terrain height.
    ld b,a
    ld a,(S84_Dimension)
    cp DIM_NETHER
    jp z,GCHNether
    cp DIM_END
    jp z,GCHEnd
    ld a,c
    add a,b
    rrca
    xor b
    add a,7
    and 7
    add a,3
    ret
GCHNether:
    ld a,c
    xor b
    add a,5
    and 3
    add a,5
    ret
GCHEnd:
    ld a,c
    add a,b
    and 7
    cp 2
    jp c,GCHEndLow
    add a,5
    ret
GCHEndLow:
    ld a,3
    ret

S84_BlockHash:
    ; IN B=x, C=y, D=z. OUT A=8-bit deterministic hash.
    ld a,b
    rlca
    xor c
    add a,d
    xor 5Ah
    ld e,a
    ld a,(S84_WorldSeed)
    xor e
    ld e,a
    ld a,(S84_WorldSeedHi)
    add a,e
    rrca
    add a,b
    xor c
    ret

S84_IsTreeColumn:
    ; IN B=x, D=z. Carry if this column contains a tree.
    ; Preserve DE because callers use D as the world-Z coordinate after return.
    push de
    ld a,b
    add a,d
    xor 3Dh
    and 0Fh
    cp 0
    jp z,S84_TreeYes
    cp 9
    jp z,S84_TreeYes
    pop de
    and a
    ret
S84_TreeYes:
    pop de
    scf
    ret

GetGeneratedBlock:
    ; IN B=x, C=y, D=z. OUT A=generated block.
    ld a,b
    ld (S84_GenX),a
    ld a,c
    ld (S84_GenY),a
    ld a,d
    ld (S84_GenZ),a
    push bc
    push de

    ; Surface height for this column.
    ld a,(S84_GenZ)
    ld c,a
    ld a,(S84_GenX)
    call GetColumnHeight
    ld e,a                    ; surface height
    ld a,(S84_GenY)
    ld c,a

    ; Alternate dimensions have their own compact terrain palettes.
    ld a,(S84_Dimension)
    cp DIM_NETHER
    jp z,GGNether
    cp DIM_END
    jp z,GGEnd

    ; Bedrock layer.
    or a
    jp nz,GGNotBedrock
    ld a,BLOCK_BEDROCK
    jp GGRet
GGNotBedrock:

    ; Below or at the surface.
    ld a,c
    cp e
    jp c,GGBelowSurface
    jp z,GGSuface

    ; Above surface: generated trees, then shoreline fluid, else air.
    ld a,(S84_GenX)
    ld b,a
    ld a,(S84_GenZ)
    ld d,a
    call S84_IsTreeColumn
    jp nc,GGTreeCheckDone
    ld a,(S84_GenY)
    sub e
    cp 4
    jp c,GGTreeTrunk
    cp 5
    jp z,GGTreeLeaf
    jp GGTreeCheckDone
GGTreeTrunk:
    ld a,BLOCK_WOOD
    jp GGRet
GGTreeLeaf:
    ld a,BLOCK_LEAVES
    jp GGRet
GGTreeCheckDone:

    ; Shallow water on low shoreline columns.
    ld a,e
    cp 4
    jp nc,GGNoWater
    ld a,(S84_GenY)
    sub e
    cp 2
    jp nz,GGNoWater
    ld a,(S84_GenX)
    add a,d
    xor 27h
    and 7
    jp nz,GGNoWater
    ld a,BLOCK_WATER
    jp GGRet
GGNoWater:
    xor a
    jp GGRet

GGSuface:
    ; Trees and biome variation.
    ld a,(S84_GenX)
    ld b,a
    ld a,(S84_GenZ)
    ld d,a
    call S84_IsTreeColumn
    jp nc,GGGrassOrSand
    ld a,BLOCK_WOOD
    jp GGRet
GGGrassOrSand:
    ld a,(S84_GenX)
    ld b,a
    ld a,(S84_GenZ)
    ld d,a
    call S84_GetBiome
    ld (S84_Biome),a
    cp BIOME_DESERT
    jp z,GGSand
    cp BIOME_SNOW
    jp z,GGSnowSurface
    cp BIOME_TAIGA
    jp z,GGForestGrass
    cp BIOME_FOREST
    jp z,GGForestGrass
    ld a,(S84_GenX)
    add a,d
    xor 6Bh
    and 7
    cp 0
    jp z,GGSand
    cp 1
    jp z,GGSand
    ld a,BLOCK_GRASS
    jp GGRet
GGForestGrass:
    ld a,BLOCK_GRASS
    jp GGRet
GGSnowSurface:
    ld a,BLOCK_SNOW
    jp GGRet
GGSand:
    ld a,BLOCK_SAND
    jp GGRet

GGBelowSurface:
    ; y=1 becomes dirt/gravel, y=2+ becomes stone with caves/ores.
    ld a,c
    cp 2
    jp c,GGDirtLayer

    ; Cave voids. Lava appears in a subset of deep caves.
    ld a,(S84_GenX)
    ld b,a
    ld a,(S84_GenY)
    ld c,a
    ld a,(S84_GenZ)
    ld d,a
    call S84_BlockHash
    and 0Fh
    cp 0
    jp nz,GGNoCave
    ld a,(S84_GenY)
    cp 3
    jp c,GGNoCave
    ld a,(S84_GenY)
    and 3
    jp nz,GGCaveAir
    ld a,BLOCK_LAVA
    jp GGRet
GGCaveAir:
    xor a
    jp GGRet
GGNoCave:
    ; Ores by hash bands.
    ld a,(S84_GenX)
    ld b,a
    ld a,(S84_GenY)
    ld c,a
    ld a,(S84_GenZ)
    ld d,a
    call S84_BlockHash
    and 31
    cp 3
    jp z,GGCoal
    cp 9
    jp z,GGIron
    cp 17
    jp z,GGGold
    cp 21
    jp z,GGGravel
    ld a,BLOCK_STONE
    jp GGRet
GGCoal:
    ld a,BLOCK_COAL_ORE
    jp GGRet
GGIron:
    ld a,BLOCK_IRON_ORE
    jp GGRet
GGGold:
    ld a,BLOCK_GOLD_ORE
    jp GGRet
GGGravel:
    ld a,BLOCK_GRAVEL
    jp GGRet
GGDirtLayer:
    ld a,BLOCK_DIRT
    jp GGRet

GGNether:
    ld a,c
    or a
    jp z,GGNBed
    ld a,c
    cp e
    jp c,GGNBelow
    jp GGNAir
GGNBelow:
    ld a,(S84_GenX)
    ld b,a
    ld a,(S84_GenY)
    ld c,a
    ld a,(S84_GenZ)
    ld d,a
    call S84_BlockHash
    and 15
    cp 2
    jp z,GGNQuartz
    cp 6
    jp z,GGNSoul
    cp 10
    jp z,GGNLava
    ld a,BLOCK_NETHERRACK
    jp GGRet
GGNBed:
    ld a,BLOCK_BEDROCK
    jp GGRet
GGNAir:
    xor a
    jp GGRet
GGNQuartz:
    ld a,BLOCK_QUARTZ
    jp GGRet
GGNSoul:
    ld a,BLOCK_SOUL_SAND
    jp GGRet
GGNLava:
    ld a,BLOCK_LAVA
    jp GGRet

GGEnd:
    ld a,c
    or a
    jp z,GGEBed
    ld a,c
    cp e
    jp c,GGEBelow
    jp GGEAir
GGEBelow:
    ld a,BLOCK_ENDSTONE
    jp GGRet
GGEBed:
    ld a,BLOCK_BEDROCK
    jp GGRet
GGEAir:
    xor a
GGRet:
    pop de
    pop bc
    ret

GetBlockAt:
    ; IN B=x,C=y,D=z. OUT A=block type.
    ld a,d
    ld (S84_GenZ),a
    ld a,c
    ld (S84_GenY),a
    call FindEdit
    jp c,GBAEdit
    call GetGeneratedBlock
    ret
GBAEdit:
    ld a,(S84_EditType)
    ret

; Get terrain height at x,z with edits ignored.
GetHeightOnly:
    ld a,(S84_TempZ)
    ld c,a
    ld a,(S84_TempX)
    ld b,a
    call GetColumnHeight
    ld (S84_TempHeight),a
    ret

;------------------------------------------------------------------------------
; Editing
;------------------------------------------------------------------------------
FindTarget:
    ; Finds closest generated/edit block along camera direction.
    ; OUT: Carry set if valid, S84_TargetX/Y/Z and S84_TargetType set.
    xor a
    ld (S84_TargetFound),a
    ld (S84_TargetDepth),a
    ld (S84_TargetType),a

    ; Start with the column in front of the camera.
    ld a,(S84_PlayerX)
    ld (S84_ScanX),a
    ld a,(S84_PlayerZ)
    ld (S84_ScanZ),a
    ld a,4
    ld (S84_ScanStep),a

FTloop:
    ld a,(S84_ScanStep)
    cp 11
    jp nc,FTnone

    ; Direction bucket from yaw.
    ld a,(S84_Yaw)
    and 24
    rrca
    rrca
    rrca
    and 3
    ld b,a
    ld a,(S84_ScanX)
    ld c,a
    ld a,(S84_ScanZ)
    ld d,a

    ld a,b
    or a
    jp z,FTNorth
    cp 1
    jp z,FTEast
    cp 2
    jp z,FTSouth
    jp FTWest

FTNorth:
    ld a,(S84_PlayerZ)
    ld b,a
    ld a,(S84_ScanStep)
    ld c,a
    ld a,b
    sub c
    ld d,a
    jp FTCheck
FTEast:
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_ScanStep)
    ld c,a
    ld a,b
    add a,c
    ld c,a
    jp FTCheck
FTSouth:
    ld a,(S84_PlayerZ)
    ld b,a
    ld a,(S84_ScanStep)
    ld c,a
    ld a,b
    add a,c
    ld d,a
    jp FTCheck
FTWest:
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_ScanStep)
    ld c,a
    ld a,b
    sub c
    ld c,a

FTCheck:
    ; The generated terrain top at this position.
    ld a,c
    ld (S84_TempX),a
    ld a,d
    ld (S84_TempZ),a
    call GetHeightOnly
    ld a,(S84_TempHeight)
    ld (S84_TargetY),a
    dec a
    ld c,a
    ld a,(S84_TempX)
    ld b,a
    ld a,(S84_TempZ)
    ld d,a
    call GetBlockAt
    or a
    jp z,FTnext

    ld (S84_TargetType),a
    ld a,(S84_TempX)
    ld (S84_TargetX),a
    ld a,(S84_TempZ)
    ld (S84_TargetZ),a
    ld a,(S84_ScanStep)
    ld (S84_TargetDepth),a
    ld a,1
    ld (S84_TargetFound),a
    scf
    ret

FTnext:
    ld a,(S84_ScanStep)
    inc a
    ld (S84_ScanStep),a
    jp FTloop

FTnone:
    and a
    ret

BreakTarget:
    call FindTarget
    ret nc
    ld a,(S84_TargetType)
    ld (S84_LastBreakType),a
    call StoreTargetEditAir
    call MC3_SFX_PlayBlockBreak
    ld a,1
    call S84_GainXP
    ld a,(S84_GameMode)
    or a
    ret nz
    ld a,(S84_LastBreakType)
    cp BLOCK_WHEAT_RIPE
    jp nz,SBTNormalDrop
    ld a,ITEM_WHEAT
    call AddInventory
    ld a,ITEM_WHEAT_SEED
    ld b,2
    call S84_AddMany
    ret
SBTNormalDrop:
    ld a,(S84_LastBreakType)
    call AddInventory
    ret

StoreTargetEditAir:
    ld a,(S84_TargetX)
    ld (S84_EditXTmp),a
    ld a,(S84_TargetY)
    ld (S84_EditYTmp),a
    ld a,(S84_TargetZ)
    ld (S84_EditZTmp),a
    xor a
    ld (S84_EditTypeTmp),a
    call StoreEdit
    ret

PlaceTarget:
    call FindTarget
    ret nc
    ld a,S84_NOTE_C4
    call S84_PlayToneChunk

    ; Require an item in survival; creative keeps the stack effectively infinite.
    ld a,(S84_GameMode)
    or a
    jp nz,PlaceHasItem
    ld a,(S84_HotbarSel)
    ld e,a
    ld d,0
    ld hl,S84_InvCounts
    add hl,de
    ld a,(hl)
    or a
    ret z

PlaceHasItem:
    ; Place directly above selected top block. This mirrors placing on PY,
    ; while avoiding a full face solver on the tiny Z80 port.
    ld a,(S84_TargetX)
    ld (S84_EditXTmp),a
    ld a,(S84_TargetY)
    ld (S84_EditYTmp),a
    inc a
    ld (S84_EditYTmp),a
    ld a,(S84_TargetZ)
    ld (S84_EditZTmp),a

    call GetHotbarType
    or a
    ret z
    push af
    call MC3_SFX_PlayBlockPlace
    pop af
    ld (S84_EditTypeTmp),a
    call StoreEdit
    call RemoveHotbar
    ret

StoreEdit:
    ; Update existing edit if present.
    ld a,(S84_EditCount)
    or a
    jp z,SEAdd

    ld e,a
    ld hl,S84_EditData
SEloop:
    ld a,(hl)
    ld b,a
    ld a,(S84_EditXTmp)
    cp b
    jp nz,SENext
    inc hl
    ld a,(hl)
    ld b,a
    ld a,(S84_EditYTmp)
    cp b
    jp nz,SEBackY
    inc hl
    ld a,(hl)
    ld b,a
    ld a,(S84_EditZTmp)
    cp b
    jp nz,SEBackZ
    inc hl
    ld a,(S84_EditTypeTmp)
    ld (hl),a
    ret
SEBackZ:
    dec hl
SEBackY:
    dec hl
SENext:
    inc hl
    inc hl
    inc hl
    inc hl
    dec e
    jp nz,SEloop

SEAdd:
    ld a,(S84_EditCount)
    cp EDIT_MAX
    ret nc

    ld b,a
    inc a
    ld (S84_EditCount),a

    ld a,b
    add a,a
    add a,a
    ld e,a
    ld d,0
    ld hl,S84_EditData
    add hl,de

    ld a,(S84_EditXTmp)
    ld (hl),a
    inc hl
    ld a,(S84_EditYTmp)
    ld (hl),a
    inc hl
    ld a,(S84_EditZTmp)
    ld (hl),a
    inc hl
    ld a,(S84_EditTypeTmp)
    ld (hl),a
    ret

;------------------------------------------------------------------------------
; Inventory
; Sinecraft uses 24 slots (4 rows x 6). We keep the same slot count here,
; with compact one-byte type/count arrays.
;------------------------------------------------------------------------------
GetHotbarType:
    ld a,(S84_HotbarSel)
    ld e,a
    ld d,0
    ld hl,S84_InvTypes
    add hl,de
    ld a,(hl)
    ret

RemoveHotbar:
    ld a,(S84_GameMode)
    or a
    ret nz
    ld a,(S84_HotbarSel)
    ld e,a
    ld d,0
    ld hl,S84_InvCounts
    add hl,de
    ld a,(hl)
    or a
    ret z
    dec a
    ld (hl),a
    ret

AddInventory:
    ; IN A=item/block type
    or a
    ret z
    ld (S84_InvTypeTmp),a

    ; First find an existing stack.
    ld hl,S84_InvTypes
    ld bc,S84_InvCounts
    ld e,0
AIFindLoop:
    ld a,e
    cp INV_COUNT
    jp nc,AIFindEmptyStart
    ld a,(hl)
    ld d,a
    ld a,(S84_InvTypeTmp)
    cp d
    jp nz,AIFindNext
    push hl
    push bc
    ld d,0
    ld a,e
    ld l,a
    ld h,0
    ld de,S84_InvCounts
    add hl,de
    ld a,(hl)
    cp 16
    jp nc,AIFindPop
    inc a
    ld (hl),a
    pop bc
    pop hl
    ret
AIFindPop:
    pop bc
    pop hl
AIFindNext:
    inc hl
    inc e
    jp AIFindLoop

AIFindEmptyStart:
    ld hl,S84_InvTypes
    xor a
    ld e,a
AIEmptyLoop:
    ld a,e
    cp INV_COUNT
    ret nc
    ld a,(hl)
    or a
    jp nz,AIEmptyNext
    ld a,(S84_InvTypeTmp)
    ld (hl),a
    ld d,0
    ld a,e
    ld l,a
    ld h,0
    ld de,S84_InvCounts
    add hl,de
    ld a,1
    ld (hl),a
    ret
AIEmptyNext:
    inc hl
    inc e
    jp AIEmptyLoop

FindSlotOffset:
    ; IN A=slot 0..23; OUT A=type.
    ld e,a
    ld d,0
    ld hl,S84_InvTypes
    add hl,de
    ld a,(hl)
    ld (S84_InvTypeTmp),a
    ret

RemoveSelectedOne:
    ld a,(S84_HotbarSel)
    ld e,a
    ld d,0
    ld hl,S84_InvCounts
    add hl,de
    ld a,(hl)
    or a
    ret z
    dec a
    ld (hl),a
    ret

;------------------------------------------------------------------------------
; Rendering
;------------------------------------------------------------------------------
RenderFrame:
    ; Direct LCD rendering on the CSE.  The logical renderer remains 96x64
    ; and the LCD routines scale it to 2x in PlotPixel/LineGeneral.
    bcall(_maybe_ClrScrnFull)
    set fullScrnDraw,(iy+apiFlg4)
    set plotLoc,(iy+plotFlags)
    call SetColorBlack

    ; Draw a simple horizon first.
    ld a,31
    ld (S84_LineY),a
    call HLine

    ; Draw terrain columns around camera.
    xor a
    ld (S84_RenderDX),a
RFXLoop:
    ld a,(S84_RenderDX)
    cp WORLD_R*2+1
    jp c,RFXContinue
    call RenderEdits
    call RenderMobs
    ret
RFXContinue:

    xor a
    ld (S84_RenderDZ),a
RFZLoop:
    ld a,(S84_RenderDZ)
    cp WORLD_R*2+1
    jp nc,RFXNext

    ; World X/Z = player + loop offset - render radius.
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_RenderDX)
    add a,b
    sub WORLD_R
    ld (S84_TempX),a

    ld a,(S84_PlayerZ)
    ld b,a
    ld a,(S84_RenderDZ)
    add a,b
    sub WORLD_R
    ld (S84_TempZ),a

    ; Height.
    call GetHeightOnly
    ld a,(S84_TempHeight)
    ld (S84_RenderH),a

    ; Draw the highest visible generated/edit block (trees/fluid included).
    ld a,(S84_TempX)
    ld b,a
    ld a,(S84_TempHeight)
    ld c,a
    ld a,(S84_TempZ)
    ld d,a
    call GetBlockAt
    ld (S84_DrawBlock),a
    or a
    jp nz,RFTerrainReady
    ld a,(S84_RenderH)
    dec a
    ld c,a
    ld a,(S84_TempX)
    ld b,a
    ld a,(S84_TempZ)
    ld d,a
    call GetBlockAt
    ld (S84_DrawBlock),a
    or a
    jp nz,RFTerrainReady
    jp RFZNext
RFTerrainReady:
    ; Water and lava render one logical unit above the solid surface.
    ld a,(S84_DrawBlock)
    cp BLOCK_WATER
    jp nz,RFNoFluidRaise
    ld a,(S84_RenderH)
    inc a
    ld (S84_RenderH),a
RFNoFluidRaise:
    cp BLOCK_LAVA
    jp nz,RFNoLavaRaise
    ld a,(S84_RenderH)
    inc a
    ld (S84_RenderH),a
RFNoLavaRaise:
    ; Project this column.
    call ProjectColumn
    jp nc,RFZNext

    call DrawProjectedCube

RFZNext:
    ld a,(S84_RenderDZ)
    inc a
    ld (S84_RenderDZ),a
    jp RFZLoop

RFXNext:
    ld a,(S84_RenderDX)
    inc a
    ld (S84_RenderDX),a
    jp RFXLoop

; Draw edited/placed blocks after generated terrain.
RenderEdits:
    ld a,(S84_EditCount)
    ld e,a
    ld hl,S84_EditData
RELoop:
    ld a,e
    or a
    ret z
    ld a,(hl)
    ld (S84_TempX),a
    inc hl
    ld a,(hl)
    ld (S84_TempY),a
    inc hl
    ld a,(hl)
    ld (S84_TempZ),a
    inc hl
    ld a,(hl)
    ld (S84_RenderEditType),a
    inc hl

    ld a,(S84_RenderEditType)
    ld (S84_DrawBlock),a
    or a
    jp z,RENext

    ld a,(S84_TempY)
    ld (S84_RenderH),a
    call ProjectColumn
    jp nc,RENext
    call DrawProjectedCube

RENext:
    dec e
    jp RELoop



;------------------------------------------------------------------------------
; MOB RENDERING
;------------------------------------------------------------------------------
RenderMobs:
    xor a
    ld (S84_RenderMobsFlag),a
    ld e,0
RMobLoop:
    ld a,e
    cp MOB_MAX
    ret nc
    ld hl,S84_MobActive
    add hl,de
    ld a,(hl)
    or a
    jp z,RMobNext

    ld a,e
    call S84_MobIndexBase
    ; base index returned in HL for packed arrays
    push hl
    ld a,e
    call S84_GetMobX
    ld (S84_TempX),a
    ld a,e
    call S84_GetMobY
    ld (S84_RenderH),a
    ld a,e
    call S84_GetMobZ
    ld (S84_TempZ),a
    call ProjectColumn
    pop hl
    jp nc,RMobNext

    ld a,1
    ld (S84_RenderMobsFlag),a
    ld a,e
    call S84_GetMobType
    cp 1
    jp z,RMobZombieColor
    cp 2
    jp z,RMobSheepColor
    cp 3
    jp z,RMobSlimeColor
    cp 4
    jp z,RMobCowColor
    cp 5
    jp z,RMobPigColor
    cp 6
    jp z,RMobChickenColor
    ld a,BLOCK_PLANK
    jp RMobTypeReady
RMobZombieColor:
    ld a,BLOCK_LEAVES
    jp RMobTypeReady
RMobSheepColor:
    ld a,BLOCK_SNOW
    jp RMobTypeReady
RMobSlimeColor:
    ld a,BLOCK_WATER
    jp RMobTypeReady
RMobCowColor:
    ld a,BLOCK_WOOD
    jp RMobTypeReady
RMobPigColor:
    ld a,BLOCK_CACTUS
    jp RMobTypeReady
RMobChickenColor:
    ld a,BLOCK_SNOW
RMobTypeReady:
    ld (S84_DrawBlock),a
    call DrawProjectedCube
    xor a
    ld (S84_RenderMobsFlag),a
RMobNext:
    inc e
    jp RMobLoop

; HLine: S84_LineY is y.
HLine:
    ld a,(S84_LineY)
    ld (S84_Y1),a
    ld (S84_Y2),a
    xor a
    ld (S84_X1),a
    ld a,SCREEN_W-1
    ld (S84_X2),a
    call LineGeneral
    ret

ProjectColumn:
    ; Camera-relative integer projection with a 32-step yaw table.
    ; OUT carry if visible; stores S84_ProjX, S84_ProjY, S84_ProjDepth, S84_ProjSize.
    ld a,(S84_TempX)
    ld b,a
    ld a,(S84_PlayerX)
    sub b
    neg
    ld (S84_DX),a

    ld a,(S84_TempZ)
    ld b,a
    ld a,(S84_PlayerZ)
    sub b
    neg
    ld (S84_DZ),a

    ; Rotate using small 8-direction buckets, keeping the renderer fast.
    ld a,(S84_Yaw)
    and 24
    rrca
    rrca
    rrca
    and 3
    ld b,a

    ld a,b
    or a
    jp z,PCA0
    cp 1
    jp z,PCA1
    cp 2
    jp z,PCA2
    jp PCA3

PCA0:
    ld a,(S84_DX)
    ld (S84_CamX),a
    ld a,(S84_DZ)
    ld (S84_CamZ),a
    jp PCAEnd
PCA1:
    ld a,(S84_DZ)
    ld (S84_CamX),a
    ld a,(S84_DX)
    neg
    ld (S84_CamZ),a
    jp PCAEnd
PCA2:
    ld a,(S84_DX)
    neg
    ld (S84_CamX),a
    ld a,(S84_DZ)
    neg
    ld (S84_CamZ),a
    jp PCAEnd
PCA3:
    ld a,(S84_DZ)
    neg
    ld (S84_CamX),a
    ld a,(S84_DX)
    ld (S84_CamZ),a

PCAEnd:
    ld a,(S84_CamZ)
    bit 7,a
    ret nz
    add a,6
    ld (S84_ProjDepth),a
    cp 1
    ret c

    cp 20
    ret nc

    ; screen x = 48 + S84_CamX*18/depth
    ld a,(S84_CamX)
    ld b,a
    call ScaleByDepth
    add a,48
    ld (S84_ProjX),a

    ; center y = 30 - ((height - playerY) * 10/depth) + pitch
    ld a,(S84_RenderH)
    ld b,a
    ld a,(S84_PlayerY)
    sub b
    neg
    ld b,a
    call ScaleByDepth10
    ld c,a
    ld a,30
    sub c

    ld b,a
    ld a,(S84_Pitch)
    add a,b
    ld (S84_ProjY),a

    ld a,(S84_ProjDepth)
    ld b,a
    ld a,18
    call DivSmall
    inc a
    cp 9
    jp c,PsizeOk
    ld a,8
PsizeOk:
    ld (S84_ProjSize),a

    scf
    ret

ScaleByDepth:
    ; IN A=signed value, OUT A=value*18/depth (small integer)
    ld (S84_ScaleVal),a
    ld a,(S84_ProjDepth)
    ld b,a
    ld a,(S84_ScaleVal)
    ld c,a
    call SignedAbsA
    ld d,a
    xor a
    ld e,a
SBDloop:
    ld a,d
    or a
    jp z,SBDSum
    ld a,e
    add a,18
    ld e,a
    dec d
    jp SBDloop
SBDSum:
    ld a,e
    ld d,a
    ld a,b
    call DivSmallDE
    ld a,d
    ld b,a
    ld a,(S84_ScaleVal)
    or a
    bit 7,a
    jp z,SBDPos
    ld a,b
    neg
    ret
SBDPos:
    ld a,b
    ret

ScaleByDepth10:
    ld (S84_ScaleVal),a
    ld a,(S84_ProjDepth)
    ld b,a
    ld a,(S84_ScaleVal)
    call SignedAbsA
    ld d,a
    xor a
    ld e,a
SBD10L:
    ld a,d
    or a
    jp z,SBD10D
    ld a,e
    add a,10
    ld e,a
    dec d
    jp SBD10L
SBD10D:
    ld a,b
    call DivSmallE
    ld b,a
    ld a,(S84_ScaleVal)
    bit 7,a
    jp z,SBD10P
    ld a,b
    neg
    ret
SBD10P:
    ld a,b
    ret

SignedAbsA:
    bit 7,a
    ret z
    neg
    ret

DivSmall:
    ; A=numerator, B=denom. returns quotient A.
    ld d,a
    xor a
DSloop:
    ld c,a
    ld a,d
    cp b
    jp c,DSdone
    sub b
    ld d,a
    ld a,c
    inc a
    jp DSloop
DSdone:
    ret

DivSmallDE:
    ; A=denom, E=numerator, returns quotient D.
    ld b,a
    ld d,0
DSDE:
    ld a,e
    cp b
    jp c,DSDEDone
    sub b
    ld e,a
    inc d
    jp DSDE
DSDEDone:
    ret

DivSmallE:
    ; A=denom, E=numerator, returns quotient A.
    ld b,a
    ld d,0
DSEL:
    ld a,e
    cp b
    jp c,DSED
    sub b
    ld e,a
    inc d
    jp DSEL
DSED:
    ld a,d
    ret

DrawProjectedCube:
    ; Filled textured isometric block. Texture colour is selected by
    ; LineGeneral for each scanline using the supplied MC3D texture assets.
    ld a,1
    ld (S84_TextureMode),a
    xor a
    ld (S84_TextureShade),a

    ld a,(S84_ProjX)
    ld (S84_CubeCX),a
    ld a,(S84_ProjY)
    ld (S84_CubeCY),a
    ld a,(S84_ProjSize)
    ld (S84_CubeS),a

    ; TOP FACE: filled diamond from CY-S through CY+S.
    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    sub c
    ld (S84_FillY),a

    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    ld (S84_FillEnd),a

TopFillLoop:
    ld a,(S84_FillY)
    ld b,a
    ld a,(S84_CubeCY)
    sub b
    ; We need abs(CY-Y). Recompute as Y-CY then abs.
    ld a,(S84_FillY)
    ld b,a
    ld a,(S84_CubeCY)
    sub b
    call SignedAbsA
    ld b,a

    ld a,(S84_CubeS)
    sub b
    ld (S84_FillWidth),a

    ld a,(S84_CubeCX)
    ld c,a
    ld a,(S84_FillWidth)
    ld b,a
    ld a,c
    sub b
    ld (S84_X1),a
    ld a,c
    add a,b
    ld (S84_X2),a
    ld a,(S84_FillY)
    ld (S84_Y1),a
    ld (S84_Y2),a
    call LineGeneral

    ld a,(S84_FillY)
    inc a
    ld (S84_FillY),a
    ld b,a
    ld a,(S84_FillEnd)
    cp b
    jp c,TopFillLoop
    jp z,TopFillDone

TopFillDone:
    ; LEFT/RIGHT faces use the dim palette.
    ld a,1
    ld (S84_TextureShade),a

    ; LEFT FACE: upper sloping half.
    ld a,(S84_CubeCY)
    ld (S84_FillY),a
    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    ld (S84_FillEnd),a

LeftFaceUpper:
    ld a,(S84_CubeCX)
    ld c,a
    ld a,(S84_CubeS)
    ld b,a
    ld a,c
    sub b
    ld (S84_X1),a

    ld a,(S84_FillY)
    ld b,a
    ld a,(S84_CubeCY)
    ld c,a
    ld a,b
    sub c
    ld b,a
    ld a,(S84_CubeCX)
    ld c,a
    ld a,(S84_CubeS)
    ld d,a
    ld a,c
    sub d
    add a,b
    ld (S84_X2),a

    ld a,(S84_FillY)
    ld (S84_Y1),a
    ld (S84_Y2),a
    call LineGeneral

    ld a,(S84_FillY)
    inc a
    ld (S84_FillY),a
    ld b,a
    ld a,(S84_FillEnd)
    cp b
    jp c,LeftFaceUpper

    ; LEFT FACE: lower vertical half.
    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    ld (S84_FillY),a

    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    add a,c
    ld (S84_FillEnd),a

    ld a,(S84_CubeCX)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    sub c
    ld (S84_X1),a
    ld a,(S84_CubeCX)
    ld (S84_X2),a

LeftFaceLowerLoop:
    ld a,(S84_FillY)
    ld (S84_Y1),a
    ld (S84_Y2),a
    call LineGeneral
    ld a,(S84_FillY)
    inc a
    ld (S84_FillY),a
    ld b,a
    ld a,(S84_FillEnd)
    cp b
    jp c,LeftFaceLowerLoop

    ; RIGHT FACE: upper sloping half.
    ld a,(S84_CubeCY)
    ld (S84_FillY),a
    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    ld (S84_FillEnd),a

RightFaceUpper:
    ld a,(S84_FillY)
    ld b,a
    ld a,(S84_CubeCY)
    ld c,a
    ld a,b
    sub c
    ld b,a
    ld a,(S84_CubeCX)
    ld c,a
    ld a,(S84_CubeS)
    ld d,a
    ld a,c
    add a,d
    sub b
    ld (S84_X1),a

    ld a,(S84_CubeCX)
    ld c,a
    ld a,(S84_CubeS)
    ld b,a
    ld a,c
    add a,b
    ld (S84_X2),a

    ld a,(S84_FillY)
    ld (S84_Y1),a
    ld (S84_Y2),a
    call LineGeneral

    ld a,(S84_FillY)
    inc a
    ld (S84_FillY),a
    ld b,a
    ld a,(S84_FillEnd)
    cp b
    jp c,RightFaceUpper

    ; RIGHT FACE: lower vertical half.
    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    ld (S84_FillY),a

    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    add a,c
    add a,c
    ld (S84_FillEnd),a

    ld a,(S84_CubeCX)
    ld (S84_X1),a
    ld a,(S84_CubeCX)
    ld c,a
    ld a,(S84_CubeS)
    ld b,a
    ld a,c
    add a,b
    ld (S84_X2),a

RightFaceLowerLoop:
    ld a,(S84_FillY)
    ld (S84_Y1),a
    ld (S84_Y2),a
    call LineGeneral
    ld a,(S84_FillY)
    inc a
    ld (S84_FillY),a
    ld b,a
    ld a,(S84_FillEnd)
    cp b
    jp c,RightFaceLowerLoop

    xor a
    ld (S84_TextureMode),a
    call ConsiderTarget
    ret

ConsiderTarget:
    ld a,(S84_RenderMobsFlag)
    or a
    ret nz
    ld a,(S84_TargetFound)
    or a
    ret nz
    ld a,(S84_ProjDepth)
    cp 11
    ret nc
    ld a,(S84_ProjX)
    sub 48
    call SignedAbsA
    cp 8
    ret nc
    ld a,(S84_TempX)
    ld (S84_TargetX),a
    ld a,(S84_RenderH)
    dec a
    ld (S84_TargetY),a
    ld a,(S84_TempZ)
    ld (S84_TargetZ),a
    ld a,(S84_ProjDepth)
    ld (S84_TargetDepth),a
    ld b,a
    ld a,(S84_TargetX)
    ld b,a
    ld a,(S84_TargetY)
    ld c,a
    ld a,(S84_TargetZ)
    ld d,a
    call GetBlockAt
    ld (S84_TargetType),a
    ld a,1
    ld (S84_TargetFound),a
    ret

;------------------------------------------------------------------------------
; Line + pixel routines
;------------------------------------------------------------------------------
LineGeneral:
    ; CSE ILine: DE=start X, C=start Y-from-bottom, HL=end X, B=end Y.
    ; The logical 96x64 coordinates are scaled 2x and centered.
    ld a,(S84_X1)
    add a,a
    add a,64
    ld e,a
    ld d,0

    ld a,(S84_Y1)
    ld b,a
    ld a,63
    sub b
    add a,a
    add a,56
    ld c,a

    ld a,(S84_X2)
    add a,a
    add a,64
    ld l,a
    ld h,0

    ld a,(S84_Y2)
    ld b,a
    ld a,63
    sub b
    add a,a
    add a,56
    ld b,a

    ld a,(S84_TextureMode)
    or a
    jp z,S84_LineNoTex
    call S84_ApplyTextureColor
S84_LineNoTex:
    ld a,1
    bcall(_ILine)
    ret


;------------------------------------------------------------------------------
; S84_ApplyTextureColor
;------------------------------------------------------------------------------
; Chooses one RGB565 colour from the supplied 16x16 texture for the current
; logical scanline. This keeps the renderer cheap: the LCD still receives one
; solid horizontal run, but the material pattern comes from a real texture.
; Preserves ILine endpoint registers (BC/DE/HL).
;------------------------------------------------------------------------------
S84_ApplyTextureColor:
    push af
    push bc
    push de
    push hl

    ; Special blocks use direct RGB565 colors before palette textures.
    ld a,(S84_DrawBlock)
    cp BLOCK_WATER
    jp z,S84_ColorWater
    cp BLOCK_LAVA
    jp z,S84_ColorLava
    cp BLOCK_COAL_ORE
    jp z,S84_ColorCoal
    cp BLOCK_IRON_ORE
    jp z,S84_ColorIron
    cp BLOCK_GOLD_ORE
    jp z,S84_ColorGold
    cp BLOCK_GRAVEL
    jp z,S84_ColorGravel
    cp BLOCK_GLASS
    jp z,S84_ColorGlass
    cp BLOCK_SNOW
    jp z,S84_ColorSnow
    cp BLOCK_NETHERRACK
    jp z,S84_ColorNetherrack
    cp BLOCK_QUARTZ
    jp z,S84_ColorQuartz
    cp BLOCK_ENDSTONE
    jp z,S84_ColorEndstone
    cp BLOCK_OBSIDIAN
    jp z,S84_ColorObsidian
    cp BLOCK_NETHER_PORTAL
    jp z,S84_ColorPortal
    cp BLOCK_FARMLAND
    jp z,S84_ColorFarmland
    cp BLOCK_WHEAT
    jp z,S84_ColorWheat
    cp BLOCK_WHEAT_RIPE
    jp z,S84_ColorWheatRipe
    cp BLOCK_SOUL_SAND
    jp z,S84_ColorSoul
    cp BLOCK_GLOWSTONE
    jp z,S84_ColorGlowstone
    ld a,(S84_DrawBlock)
    call MC3_SelectExtraTexture
    jp c,S84_TexBaseReady
    ld a,(S84_DrawBlock)
    cp BLOCK_STONE
    jp z,S84_TexStoneSel
    cp BLOCK_COBBLE
    jp z,S84_TexCobbleSel
    cp BLOCK_DIRT
    jp z,S84_TexDirtSel
    cp BLOCK_GRASS
    jp z,S84_TexGrassSel
    cp BLOCK_PLANK
    jp z,S84_TexPlankSel
    cp BLOCK_WOOD
    jp z,S84_TexLogSel
    cp BLOCK_LEAVES
    jp z,S84_TexLeafSel
    cp BLOCK_TABLE
    jp z,S84_TexBrickSel
    cp BLOCK_SAND
    jp z,S84_TexSandSel
    jp S84_TexStoneSel

S84_ColorWater:
    ld hl,001Fh
    jp S84_ApplyDirectColor
S84_ColorLava:
    ld hl,00F800h
    jp S84_ApplyDirectColor
S84_ColorCoal:
    ld hl,39C7h
    jp S84_ApplyDirectColor
S84_ColorIron:
    ld hl,7BEFh
    jp S84_ApplyDirectColor
S84_ColorGold:
    ld hl,00FD60h
    jp S84_ApplyDirectColor
S84_ColorGravel:
    ld hl,6B4Dh
    jp S84_ApplyDirectColor
S84_ColorGlass:
    ld hl,7DFFh
    jp S84_ApplyDirectColor
S84_ColorSnow:
    ld hl,00F7DEh
S84_ApplyDirectColor:
    ld (drawFGColor),hl
    pop hl
    pop de
    pop bc
    pop af
    ret

S84_ColorNetherrack:
    ld hl,8410h
    jp S84_ApplyDirectColor
S84_ColorQuartz:
    ld hl,0E71Ch
    jp S84_ApplyDirectColor
S84_ColorEndstone:
    ld hl,0DEB8h
    jp S84_ApplyDirectColor
S84_ColorObsidian:
    ld hl,2104h
    jp S84_ApplyDirectColor
S84_ColorPortal:
    ld hl,701Fh
    jp S84_ApplyDirectColor
S84_ColorFarmland:
    ld hl,6240h
    jp S84_ApplyDirectColor
S84_ColorWheat:
    ld hl,96A0h
    jp S84_ApplyDirectColor
S84_ColorWheatRipe:
    ld hl,0FD20h
    jp S84_ApplyDirectColor
S84_ColorSoul:
    ld hl,39A6h
    jp S84_ApplyDirectColor
S84_ColorGlowstone:
    ld hl,0FDE0h
    jp S84_ApplyDirectColor

S84_TexStoneSel:
    ld de,texStone
    jp S84_TexBaseReady
S84_TexCobbleSel:
    ld de,texCobble
    jp S84_TexBaseReady
S84_TexDirtSel:
    ld de,texDirt
    jp S84_TexBaseReady
S84_TexGrassSel:
    ld de,texGrass
    jp S84_TexBaseReady
S84_TexPlankSel:
    ld de,texPlank
    jp S84_TexBaseReady
S84_TexLogSel:
    ld de,texLog
    jp S84_TexBaseReady
S84_TexLeafSel:
    ld de,texLeaf
    jp S84_TexBaseReady
S84_TexBrickSel:
    ld de,texBrick
    jp S84_TexBaseReady
S84_TexSandSel:
    ld de,texSand

S84_TexBaseReady:
    ; U = midpoint of the scanline, modulo 16.
    ld a,(S84_X1)
    ld b,a
    ld a,(S84_X2)
    add a,b
    srl a
    and 15
    ld (S84_TexU),a

    ; V = scanline offset from the top of the cube, modulo 16.
    ld a,(S84_CubeCY)
    ld b,a
    ld a,(S84_CubeS)
    ld c,a
    ld a,b
    sub c
    ld b,a
    ld a,(S84_Y1)
    sub b
    and 15
    ld c,a                  ; V

    ; index = v*16 + u
    rlca
    rlca
    rlca
    rlca
    ld b,a
    ld a,(S84_TexU)
    add a,b
    ld l,a
    ld h,0
    add hl,de
    ld a,(hl)
    ld c,a

    ; Palette = lit for top, dim for sides.
    ld hl,palLit
    ld a,(S84_TextureShade)
    or a
    jp nz,S84_UseDimPalette
    ld a,(S84_NightLevel)
    cp 2
    jp c,S84_PalReady
S84_UseDimPalette:
    ld hl,palDim
S84_PalReady:
    ld a,c
    add a,a
    ld e,a
    ld d,0
    add hl,de
    ld a,(hl)
    ld h,a
    inc hl
    ld a,(hl)
    ld l,a
    ld (drawFGColor),hl

    pop hl
    pop de
    pop bc
    pop af
    ret

PlotPixel:
    ; IN A=x, B=y. Draw a 2x2 RGB pixel on the CSE LCD.
    push af
    push bc
    push de
    push hl

    cp SCREEN_W
    jp nc,PPDone
    ld c,a
    ld a,b
    cp SCREEN_H
    jp nc,PPDone
    ld a,c
    add a,a
    add a,64
    ld e,a
    ld d,0

    ld a,b
    ld c,a
    ld a,63
    sub c
    add a,a
    add a,56
    ld c,a
    ld h,0

    ld a,1
    bcall(_IPoint)

    inc e
    ld a,1
    bcall(_IPoint)

    dec e
    inc c
    ld a,1
    bcall(_IPoint)

    inc e
    ld a,1
    bcall(_IPoint)

PPDone:
    pop hl
    pop de
    pop bc
    pop af
    ret

SetColorBlack:
    ld hl,0000h
    ld (drawFGColor),hl
    ret

SetColorWhite:
    ld hl,0FFFFh
    ld (drawFGColor),hl
    ret

SetBlockColor:
    ld a,(S84_DrawBlock)
    cp BLOCK_GRASS
    jp z,SBCGrass
    cp BLOCK_LEAVES
    jp z,SBCLeaves
    cp BLOCK_DIRT
    jp z,SBCDirt
    cp BLOCK_WOOD
    jp z,SBCWood
    cp BLOCK_PLANK
    jp z,SBCPlank
    cp BLOCK_COBBLE
    jp z,SBCCobble
    cp BLOCK_TABLE
    jp z,SBCTable
    cp BLOCK_NETHERRACK
    jp z,SBCNetherrack
    cp BLOCK_QUARTZ
    jp z,SBCQuartz
    cp BLOCK_ENDSTONE
    jp z,SBCEndstone
    cp BLOCK_OBSIDIAN
    jp z,SBCObsidian
    cp BLOCK_NETHER_PORTAL
    jp z,SBCPortal
    cp BLOCK_FARMLAND
    jp z,SBCFarmland
    cp BLOCK_WHEAT
    jp z,SBCWheat
    cp BLOCK_WHEAT_RIPE
    jp z,SBCWheatRipe
    cp BLOCK_SOUL_SAND
    jp z,SBCSoul
    cp BLOCK_GLOWSTONE
    jp z,SBCGlow
    call SetColorBlack
    ret
SBCGrass:
    ld hl,07E0h
    ld (drawFGColor),hl
    ret
SBCLeaves:
    ld hl,03E0h
    ld (drawFGColor),hl
    ret
SBCDirt:
    ld hl,8A20h
    ld (drawFGColor),hl
    ret
SBCWood:
    ld hl,79E0h
    ld (drawFGColor),hl
    ret
SBCPlank:
    ld hl,0D69Ah
    ld (drawFGColor),hl
    ret
SBCCobble:
    ld hl,7BEFh
    ld (drawFGColor),hl
    ret
SBCTable:
    ld hl,0FD20h
    ld (drawFGColor),hl
    ret
SBCNetherrack:
    ld hl,8410h
    ld (drawFGColor),hl
    ret
SBCQuartz:
    ld hl,0E71Ch
    ld (drawFGColor),hl
    ret
SBCEndstone:
    ld hl,0DEB8h
    ld (drawFGColor),hl
    ret
SBCObsidian:
    ld hl,2104h
    ld (drawFGColor),hl
    ret
SBCPortal:
    ld hl,701Fh
    ld (drawFGColor),hl
    ret
SBCFarmland:
    ld hl,6240h
    ld (drawFGColor),hl
    ret
SBCWheat:
    ld hl,96A0h
    ld (drawFGColor),hl
    ret
SBCWheatRipe:
    ld hl,0FD20h
    ld (drawFGColor),hl
    ret
SBCSoul:
    ld hl,39A6h
    ld (drawFGColor),hl
    ret
SBCGlow:
    ld hl,0FDE0h
    ld (drawFGColor),hl
    ret


;------------------------------------------------------------------------------
; HUD / crosshair
;------------------------------------------------------------------------------
DrawHUD:
    call SetColorBlack
    call DrawStatusBars
    call S84_DrawXPBar
    call S84_DrawArmorBar
    call S84_DrawOxygenBar
    call S84_DrawCompass
    ; hotbar slots along bottom
    ld a,44
    ld (S84_HudX),a
    xor a
    ld (S84_HudSlot),a
DHLoop:
    ld a,(S84_HudSlot)
    cp HOTBAR_COUNT
    ret nc

    ld a,(S84_HudX)
    ld b,a
    ld a,58
    ld c,a
    call DrawSlot

    ld a,(S84_HudX)
    add a,8
    ld (S84_HudX),a
    ld a,(S84_HudSlot)
    inc a
    ld (S84_HudSlot),a
    jp DHLoop


DrawStatusBars:
    ; 20px health bar at left, 20px hunger bar at right.
    ld a,3
    ld (S84_HudX),a
    ld a,(S84_PlayerHP)
    call DrawBar20
    ld a,73
    ld (S84_HudX),a
    ld a,(S84_PlayerHunger)
    call DrawBar20
    ret

DrawBar20:
    ; IN A=value 0..20, S84_HudX is x. y is fixed logical 2.
    ld b,a
    ld a,(S84_HudX)
    ld (S84_X1),a
    ld a,2
    ld (S84_Y1),a
    ld a,(S84_HudX)
    ld c,a
    ld a,b
    add a,a
    add a,c
    ld (S84_X2),a
    ld a,2
    ld (S84_Y2),a
    call LineGeneral
    ret

DrawSlot:
    ; B=x, C=y. Draw a 7x5 rectangle using only horizontal/vertical lines.
    ld a,b
    ld d,a
    ld a,c
    ld e,a

    ; top edge
    ld a,d
    ld (S84_X1),a
    ld a,e
    ld (S84_Y1),a
    ld a,d
    add a,6
    ld (S84_X2),a
    ld a,e
    ld (S84_Y2),a
    call LineGeneral

    ; bottom edge
    ld a,d
    ld (S84_X1),a
    ld a,e
    add a,4
    ld (S84_Y1),a
    ld a,d
    add a,6
    ld (S84_X2),a
    ld a,e
    add a,4
    ld (S84_Y2),a
    call LineGeneral

    ; left edge
    ld a,d
    ld (S84_X1),a
    ld a,e
    ld (S84_Y1),a
    ld a,e
    add a,4
    ld (S84_Y2),a
    ld a,d
    ld (S84_X2),a
    call LineGeneral

    ; right edge
    ld a,d
    add a,6
    ld (S84_X1),a
    ld a,e
    ld (S84_Y1),a
    ld a,d
    add a,6
    ld (S84_X2),a
    ld a,e
    add a,4
    ld (S84_Y2),a
    call LineGeneral
    ret

DrawCrosshair:
    call SetColorBlack
    ld a,48
    ld b,31
    call PlotPixel
    ld a,47
    ld b,31
    call PlotPixel
    ld a,49
    ld b,31
    call PlotPixel
    ld a,48
    ld b,30
    call PlotPixel
    ld a,48
    ld b,32
    call PlotPixel
    ret

;------------------------------------------------------------------------------
; Inventory / crafting screens
;------------------------------------------------------------------------------
InventoryScreen:
    bcall(_maybe_ClrScrnFull)
ISLoop:
    call DrawInventoryWindow
    bcall(_GetCSC)
    cp skClear
    ret z
    cp skWindow
    ret z
    cp skLeft
    jp nz,ISNoL
    ld a,(S84_InvCursor)
    or a
    jp z,ISNoL
    dec a
    ld (S84_InvCursor),a
ISNoL:
    cp skRight
    jp nz,ISNoR
    ld a,(S84_InvCursor)
    inc a
    cp INV_COUNT
    jp c,ISStoreR
    xor a
ISStoreR:
    ld (S84_InvCursor),a
ISNoR:
    cp skUp
    jp nz,ISNoU
    ld a,(S84_InvCursor)
    cp 6
    jp c,ISNoU
    sub 6
    ld (S84_InvCursor),a
ISNoU:
    cp skDown
    jp nz,ISNoD
    ld a,(S84_InvCursor)
    add a,6
    cp INV_COUNT
    jp nc,ISNoD
    ld (S84_InvCursor),a
ISNoD:
    cp skEnter
    jp nz,ISLoop
    call S84_UseSelectedItem
    jp c,ISLoop
    ld a,(S84_InvCursor)
    cp HOTBAR_COUNT
    jp nc,ISLoop
    ld (S84_HotbarSel),a
    jp ISLoop

CraftingScreen:
    bcall(_maybe_ClrScrnFull)
CSLoop:
    call DrawCraftingWindow
    bcall(_GetCSC)
    cp skClear
    ret z
    cp skVars
    ret z
    cp skLeft
    jp nz,CSNoL
    ld a,(S84_CraftRecipe)
    or a
    jp z,CSNoL
    dec a
    ld (S84_CraftRecipe),a
CSNoL:
    cp skRight
    jp nz,CSNoR
    ld a,(S84_CraftRecipe)
    inc a
    cp 16
    jp c,CSStoreR
    xor a
CSStoreR:
    ld (S84_CraftRecipe),a
CSNoR:
    cp skEnter
    jp nz,CSLoop
    call CraftSelected
    jp CSLoop

DrawInventoryWindow:
    call SetColorBlack
    ; Outer frame.
    ld a,8
    ld (S84_X1),a
    ld a,4
    ld (S84_Y1),a
    ld a,88
    ld (S84_X2),a
    ld a,55
    ld (S84_Y2),a
    call LineGeneral

    ; 4x6 slot grid. Logical slots are 12x8.
    xor a
    ld (S84_InvDrawSlot),a
DInvRow:
    ld a,(S84_InvDrawSlot)
    cp INV_COUNT
    ret nc
    ; derive row = slot / 6, col = slot % 6
    ld a,(S84_InvDrawSlot)
    ld b,0
DInvDiv:
    cp 6
    jp c,DInvColReady
    sub 6
    inc b
    jp DInvDiv
DInvColReady:
    ld c,a                    ; col
    ; x = 12 + col*12
    ld a,c
    add a,a
    add a,a
    add a,a
    add a,c
    add a,c
    add a,12
    ld b,a
    ; y = 9 + row*10
    ld a,(S84_InvDrawSlot)
    ld c,a
    ld a,0
    ld d,a
DInvRowCalc:
    ld a,c
    cp 6
    jp c,DInvRowReady
    sub 6
    ld c,a
    inc d
    jp DInvRowCalc
DInvRowReady:
    ld a,d
    add a,a
    add a,a
    add a,a
    add a,a
    add a,9
    ld c,a
    ; selected cursor gets a second outline.
    push bc
    call DrawSlot
    pop bc
    ld a,(S84_InvDrawSlot)
    ld d,a
    ld a,(S84_InvCursor)
    cp d
    jp nz,DInvNext
    ld a,b
    ld (S84_X1),a
    ld a,c
    ld (S84_Y1),a
    ld a,b
    add a,6
    ld (S84_X2),a
    ld a,c
    add a,4
    ld (S84_Y2),a
    call LineGeneral
DInvNext:
    ld a,(S84_InvDrawSlot)
    inc a
    ld (S84_InvDrawSlot),a
    jp DInvRow

DrawCraftingWindow:
    call DrawInventoryWindow
    ; Recipe selection bar.
    ld a,12
    ld (S84_X1),a
    ld a,31
    ld (S84_Y1),a
    ld a,84
    ld (S84_X2),a
    ld a,46
    ld (S84_Y2),a
    call LineGeneral
    ret

CraftSelected:
    ; Six compact prototype recipes.
    ld a,(S84_CraftRecipe)
    cp 0
    jp z,CraftWood
    cp 1
    jp z,CraftStick
    cp 2
    jp z,CraftTable
    cp 3
    jp z,CraftGlass
    cp 4
    jp z,CraftTorch
    cp 5
    jp z,CraftIron
    cp 6
    jp z,CraftFurnace
    cp 7
    jp z,CraftSmeltIron
    cp 8
    jp z,CraftBread
    cp 9
    jp z,CraftBow
    cp 10
    jp z,CraftArrows
    cp 11
    jp z,CraftShield
    cp 12
    jp z,CraftFishingRod
    cp 13
    jp z,CraftEnchanting
    cp 14
    jp z,CraftAnvil
    cp 15
    jp z,CraftPortal
    ret

CraftFurnace:
    ld a,BLOCK_COBBLE
    call S84_CountType
    cp 8
    ret c
    ld b,8
CFConsumeLoop:
    push bc
    ld a,BLOCK_COBBLE
    call S84_ConsumeTypeOne
    pop bc
    djnz CFConsumeLoop
    ; Furnace block/item uses a free high ID in this prototype.
    ld a,61
    ld b,1
    call S84_AddMany
    ret

CraftSmeltIron:
    ld a,BLOCK_IRON_ORE
    call S84_FindItemSlot
    ret nc
    ld a,ITEM_COAL
    call S84_FindItemSlot
    ret nc
    ld a,BLOCK_IRON_ORE
    call S84_ConsumeTypeOne
    ld a,ITEM_COAL
    call S84_ConsumeTypeOne
    ld a,ITEM_IRON
    ld b,1
    call S84_AddMany
    ret

CraftWood:
    ld a,BLOCK_WOOD
    call S84_FindItemSlot
    ret nc
    call S84_ConsumeTypeOne
    ld a,BLOCK_PLANK
    ld b,4
    call S84_AddMany
    ret

CraftStick:
    ld a,BLOCK_PLANK
    ld b,0
    call S84_CountType
    cp 2
    ret c
    ld a,BLOCK_PLANK
    call S84_ConsumeType
    ld a,BLOCK_PLANK
    call S84_ConsumeType
    ld a,ITEM_STICK
    ld b,4
    call S84_AddMany
    ret

CraftTable:
    ld a,BLOCK_PLANK
    call S84_CountType
    cp 4
    ret c
    ld a,BLOCK_PLANK
    call S84_ConsumeType
    ld a,BLOCK_PLANK
    call S84_ConsumeType
    ld a,BLOCK_PLANK
    call S84_ConsumeType
    ld a,BLOCK_PLANK
    call S84_ConsumeType
    ld a,BLOCK_TABLE
    call AddInventory
    ret

CraftGlass:
    ld a,BLOCK_SAND
    call S84_ConsumeTypeOne
    ret nc
    ld a,BLOCK_GLASS
    call AddInventory
    ret

CraftTorch:
    ld a,ITEM_COAL
    call S84_CountType
    cp 1
    ret c
    ld a,ITEM_STICK
    call S84_CountType
    cp 1
    ret c
    ld a,ITEM_COAL
    call S84_ConsumeType
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,BLOCK_TORCH
    ld b,4
    call S84_AddMany
    ret

CraftIron:
    ld a,BLOCK_IRON_ORE
    call S84_ConsumeTypeOne
    ret nc
    ld a,ITEM_IRON
    call AddInventory
    ret

; Additional MCv2 recipes.
CraftBread:
    ld a,ITEM_WHEAT
    call S84_CountType
    cp 3
    ret c
    ld a,ITEM_WHEAT
    call S84_ConsumeType
    ld a,ITEM_WHEAT
    call S84_ConsumeType
    ld a,ITEM_WHEAT
    call S84_ConsumeType
    ld a,ITEM_BREAD
    call AddInventory
    ret

CraftBow:
    ld a,ITEM_STICK
    call S84_CountType
    cp 3
    ret c
    ld a,ITEM_STRING
    call S84_CountType
    cp 3
    ret c
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STRING
    call S84_ConsumeType
    ld a,ITEM_STRING
    call S84_ConsumeType
    ld a,ITEM_STRING
    call S84_ConsumeType
    ld a,ITEM_BOW
    call AddInventory
    ret

CraftArrows:
    ld a,ITEM_STICK
    call S84_CountType
    cp 1
    ret c
    ld a,ITEM_STONE
    call S84_CountType
    cp 1
    ret c
    ld a,ITEM_FEATHER
    call S84_CountType
    cp 1
    ret c
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STONE
    call S84_ConsumeType
    ld a,ITEM_FEATHER
    call S84_ConsumeType
    ld a,ITEM_ARROW
    ld b,4
    call S84_AddMany
    ret

CraftShield:
    ld a,BLOCK_PLANK
    call S84_CountType
    cp 6
    ret c
    ld a,ITEM_IRON
    call S84_CountType
    cp 1
    ret c
    ld a,BLOCK_PLANK
    ld b,6
CSShLoop:
    push bc
    call S84_ConsumeType
    pop bc
    djnz CSShLoop
    ld a,ITEM_IRON
    call S84_ConsumeType
    ld a,ITEM_SHIELD
    call AddInventory
    ret

CraftFishingRod:
    ld a,ITEM_STICK
    call S84_CountType
    cp 3
    ret c
    ld a,ITEM_STRING
    call S84_CountType
    cp 2
    ret c
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STICK
    call S84_ConsumeType
    ld a,ITEM_STRING
    call S84_ConsumeType
    ld a,ITEM_STRING
    call S84_ConsumeType
    ld a,ITEM_FISHING_ROD
    call AddInventory
    ret

CraftEnchanting:
    ld a,BLOCK_OBSIDIAN
    call S84_CountType
    cp 4
    ret c
    ld a,ITEM_DIAMOND
    call S84_CountType
    cp 2
    ret c
    ld a,ITEM_BOOK
    call S84_CountType
    cp 1
    ret c
    ld a,BLOCK_OBSIDIAN
    ld b,4
CENLoop:
    push bc
    call S84_ConsumeType
    pop bc
    djnz CENLoop
    ld a,ITEM_DIAMOND
    call S84_ConsumeType
    ld a,ITEM_DIAMOND
    call S84_ConsumeType
    ld a,ITEM_BOOK
    call S84_ConsumeType
    ld a,BLOCK_ENCHANT
    call AddInventory
    ret

CraftAnvil:
    ld a,ITEM_IRON
    call S84_CountType
    cp 9
    ret c
    ld b,9
CAConsume:
    push bc
    ld a,ITEM_IRON
    call S84_ConsumeType
    pop bc
    djnz CAConsume
    ld a,BLOCK_ANVIL
    call AddInventory
    ret

CraftPortal:
    ld a,BLOCK_OBSIDIAN
    call S84_CountType
    cp 10
    ret c
    ld b,10
CPConsume:
    push bc
    ld a,BLOCK_OBSIDIAN
    call S84_ConsumeType
    pop bc
    djnz CPConsume
    ld a,BLOCK_NETHER_PORTAL
    call AddInventory
    ret

S84_AddMany:
    ; IN A=type, B=count
    push bc
SAMLoop:
    push af
    call AddInventory
    pop af
    djnz SAMLoop
    pop bc
    ret

S84_FindItemSlot:
    ; IN A=type, OUT carry if present, A=slot index.
    ld (S84_FindItemType),a
    ld hl,S84_InvTypes
    ld e,0
S84_FindItemLoop:
    ld a,e
    cp INV_COUNT
    ret nc
    ld a,(hl)
    ld d,a
    ld a,(S84_FindItemType)
    cp d
    jp z,S84_FindItemFound
    inc hl
    inc e
    jp S84_FindItemLoop
S84_FindItemFound:
    ld a,e
    scf
    ret

S84_CountType:
    ; IN A=type, OUT A=count capped at 255.
    ld (S84_FindItemType),a
    ld hl,S84_InvTypes
    ld de,S84_InvCounts
    ld b,INV_COUNT
    xor a
S84_CountTypeLoop:
    push af
    ld a,(hl)
    ld c,a
    ld a,(S84_FindItemType)
    cp c
    jp nz,S84_CountSkip
    ld a,(de)
    ld c,a
    pop af
    add a,c
    jp nc,S84_CountKeep
    ld a,255
    ret
S84_CountSkip:
    pop af
S84_CountKeep:
    inc hl
    inc de
    djnz S84_CountTypeLoop
    ret

S84_ConsumeTypeOne:
    call S84_FindItemSlot
    ret nc
    call S84_ConsumeSlotA
    scf
    ret

S84_ConsumeType:
    call S84_FindItemSlot
    ret nc
    call S84_ConsumeSlotA
    ret

S84_ConsumeSlotA:
    ; A=slot
    ld e,a
    ld d,0
    ld hl,S84_InvCounts
    add hl,de
    ld a,(hl)
    or a
    ret z
    dec a
    ld (hl),a
    ret

;==============================================================================
; WORLD / DAY-NIGHT / SURVIVAL / MOBS / SAVE / LINK PROTOTYPES
;==============================================================================

S84_WorldTick:
    ld a,(S84_WorldTime)
    inc a
    ld (S84_WorldTime),a
    jp nz,SWTTickBrightness
    ld a,(S84_WorldDay)
    inc a
    ld (S84_WorldDay),a
SWTTickBrightness:
    ld a,(S84_PlayerX)
    srl a
    srl a
    srl a
    ld (S84_ChunkX),a
    ld a,(S84_PlayerZ)
    srl a
    srl a
    srl a
    ld (S84_ChunkZ),a
    call S84_UpdateNightLevel
    ld a,(S84_WorldTime)
    and 15
    ret nz
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_UpdateNightLevel:
    ld a,(S84_WorldTime)
    cp 48
    jp c,SWDay
    cp 80
    jp c,SWDusk
    cp 176
    jp c,SWNight
    cp 208
    jp c,SWDawn
SWDay:
    xor a
    ld (S84_NightLevel),a
    ret
SWDusk:
    ld a,1
    ld (S84_NightLevel),a
    ret
SWNight:
    ld a,2
    ld (S84_NightLevel),a
    ret
SWDawn:
    ld a,1
    ld (S84_NightLevel),a
    ret

S84_CheckFluidState:
    ld a,(S84_GameMode)
    or a
    ret nz
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerY)
    dec a
    ld c,a
    ld a,(S84_PlayerZ)
    ld d,a
    call GetBlockAt
    cp BLOCK_LAVA
    ret nz
    call S84_DamagePlayer
    ret

S84_SurvivalTick:
    ld a,(S84_GameMode)
    or a
    ret nz
    ld a,(S84_HungerClock)
    inc a
    ld (S84_HungerClock),a
    and 63
    ret nz
    ld a,(S84_PlayerHunger)
    or a
    jp z,SSTStarve
    cp 18
    jp c,SSTNoRegen
    ld a,(S84_PlayerHP)
    cp 20
    jp nc,SSTNoRegen
    inc a
    ld (S84_PlayerHP),a
SSTNoRegen:
    ld a,(S84_PlayerHunger)
    or a
    ret z
    dec a
    ld (S84_PlayerHunger),a
    ret
SSTStarve:
    call S84_DamagePlayer
    ret

S84_DamagePlayer:
    ; Shields absorb part of direct damage. Armor absorbs another portion.
    ld a,(S84_ShieldUp)
    or a
    jp z,SDPArmor
    ld a,(S84_ShieldDurability)
    or a
    jp z,SDPArmor
    dec a
    ld (S84_ShieldDurability),a
    ld a,1
    ld (S84_RenderDirty),a
    ret
SDPArmor:
    ld a,(S84_ArmorValue)
    cp 4
    jp c,SDPLight
    ld a,(S84_ArmorValue)
    sub 4
    ld (S84_ArmorValue),a
    jp SDPNoArmorDamage
SDPLight:
    ld a,(S84_PlayerHP)
    or a
    ret z
    dec a
    ld (S84_PlayerHP),a
SDPNoArmorDamage:
    or a
    jp nz,SDPNoRespawn
    call S84_RespawnPlayer
SDPNoRespawn:
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_RespawnPlayer:
    ld a,6
    ld (S84_PlayerX),a
    ld (S84_PlayerZ),a
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerZ)
    ld c,a
    call GetColumnHeight
    add a,2
    ld (S84_PlayerY),a
    ld a,20
    ld (S84_PlayerHP),a
    ld (S84_PlayerHunger),a
    xor a
    ld (S84_YVel),a
    ret

;------------------------------------------------------------------------------
; MOB SYSTEM
;------------------------------------------------------------------------------
S84_GetMobX:
    ld l,a
    ld h,0
    ld de,S84_MobX
    add hl,de
    ld a,(hl)
    ret
S84_GetMobY:
    ld l,a
    ld h,0
    ld de,S84_MobY
    add hl,de
    ld a,(hl)
    ret
S84_GetMobZ:
    ld l,a
    ld h,0
    ld de,S84_MobZ
    add hl,de
    ld a,(hl)
    ret
S84_GetMobType:
    ld l,a
    ld h,0
    ld de,S84_MobType
    add hl,de
    ld a,(hl)
    ret
S84_InitMobsReal:
    xor a
    ld hl,S84_MobActive
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a

    ld a,1
    ld (S84_MobActive),a
    ld a,8
    ld (S84_MobX),a
    ld a,8
    ld (S84_MobZ),a
    ld a,1
    ld (S84_MobType),a
    ld a,12
    ld (S84_MobHP),a

    ld a,1
    ld (S84_MobActive+1),a
    ld a,3
    ld (S84_MobX+1),a
    ld a,9
    ld (S84_MobZ+1),a
    xor a
    ld (S84_MobType+1),a
    ld a,8
    ld (S84_MobHP+1),a

    ld a,1
    ld (S84_MobActive+2),a
    ld a,11
    ld (S84_MobX+2),a
    ld a,4
    ld (S84_MobZ+2),a
    ld a,2
    ld (S84_MobType+2),a
    ld a,8
    ld (S84_MobHP+2),a

    ld a,1
    ld (S84_MobActive+3),a
    ld a,4
    ld (S84_MobX+3),a
    ld a,4
    ld (S84_MobZ+3),a
    ld a,3
    ld (S84_MobType+3),a
    ld a,6
    ld (S84_MobHP+3),a

    ld e,0
SMIY:
    ld a,e
    call S84_GetMobX
    ld b,a
    ld a,e
    call S84_GetMobZ
    ld c,a
    call GetColumnHeight
    add a,2
    ld b,a
    ld a,e
    ld l,a
    ld h,0
    ld de,S84_MobY
    add hl,de
    ld (hl),b
    inc e
    ld a,e
    cp MOB_MAX
    jp c,SMIY
    ret

S84_MobTick:
    ld a,(S84_MobTickCount)
    inc a
    ld (S84_MobTickCount),a
    and 7
    ret nz
    ld e,0
SMobLoop:
    ld a,e
    cp MOB_MAX
    ret nc
    ld l,a
    ld h,0
    ld de,S84_MobActive
    add hl,de
    ld a,(hl)
    or a
    jp z,SMobNext

    ld a,e
    call S84_GetMobX
    ld b,a
    ld a,(S84_PlayerX)
    sub b
    call SignedAbsA
    ld c,a
    ld a,e
    call S84_GetMobZ
    ld b,a
    ld a,(S84_PlayerZ)
    sub b
    call SignedAbsA
    add a,c
    cp 10
    jp nc,SMobNext

    ld a,e
    call S84_GetMobType
    cp 0
    jp z,SMobPassive
    cp 2
    jp z,SMobPassive
    cp 4
    jp z,SMobPassive
    cp 5
    jp z,SMobPassive
    cp 6
    jp z,SMobPassive

    ld a,e
    call S84_GetMobX
    ld b,a
    ld a,(S84_PlayerX)
    cp b
    jp z,SMobHostileZ
    jp c,SMobXDec
    inc b
    jp SMobStoreX
SMobXDec:
    dec b
SMobStoreX:
    ld a,e
    ld l,a
    ld h,0
    ld de,S84_MobX
    add hl,de
    ld (hl),b
SMobHostileZ:
    ld a,e
    call S84_GetMobZ
    ld b,a
    ld a,(S84_PlayerZ)
    cp b
    jp z,SMobAttack
    jp c,SMobZDec
    inc b
    jp SMobStoreZ
SMobZDec:
    dec b
SMobStoreZ:
    ld a,e
    ld l,a
    ld h,0
    ld de,S84_MobZ
    add hl,de
    ld (hl),b
SMobAttack:
    ld a,e
    call S84_GetMobX
    ld b,a
    ld a,(S84_PlayerX)
    sub b
    call SignedAbsA
    cp 2
    jp nc,SMobNext
    ld a,e
    call S84_GetMobZ
    ld b,a
    ld a,(S84_PlayerZ)
    sub b
    call SignedAbsA
    cp 2
    jp nc,SMobNext
    call S84_DamagePlayer
    jp SMobNext
SMobPassive:
    ld a,e
    call S84_GetMobX
    inc a
    ld l,e
    ld h,0
    ld de,S84_MobX
    add hl,de
    ld (hl),a
SMobNext:
    inc e
    jp SMobLoop

;------------------------------------------------------------------------------
; MCv1 ADVANCED GAME SYSTEMS
;------------------------------------------------------------------------------
; These are deliberately compact Z80 systems intended for Claude/emulator
; debugging. They make the feature set explicit and provide live state for:
; biomes, weather, difficulty, tool durability, beds/respawn, furnace,
; dropped items, achievements, world seed, render settings, and autosave.
;------------------------------------------------------------------------------

S84_GetBiome:
    ; IN B=x, D=z. OUT A=biome.
    ld a,b
    add a,d
    ld c,a
    ld a,b
    xor d
    add a,c
    ld e,a
    ld a,(S84_WorldSeed)
    xor e
    and 31
    cp 7
    jp c,SGBForest
    cp 13
    jp c,SGBDesert
    cp 19
    jp c,SGBSnow
    cp 25
    jp c,SGBTai
    xor a
    ret
SGBForest:
    ld a,BIOME_FOREST
    ret
SGBDesert:
    ld a,BIOME_DESERT
    ret
SGBSnow:
    ld a,BIOME_SNOW
    ret
SGBTai:
    ld a,BIOME_TAIGA
    ret

S84_AdvancedTick:
    call S84_BiomeTick
    call S84_WeatherTick
    call S84_FurnaceTick
    call S84_DropTick
    call S84_AchievementTick
    call S84_AutoSaveTick
    call S84_ToolMaintenance
    call S84_XPTick
    call S84_CropTick
    call S84_StatusTick
    call S84_FishingTick
    call S84_ProjectileTick
    call S84_DimensionTick
    call S84_RedstoneTick
    call S84_NPCTick
    call S84_BreedingTick
    call MC3_GameplayTick
    ret

S84_BiomeTick:
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerZ)
    ld d,a
    call S84_GetBiome
    ld (S84_Biome),a
    ret

S84_WeatherTick:
    ld a,(S84_WeatherTimer)
    inc a
    ld (S84_WeatherTimer),a
    cp 96
    ret c
    xor a
    ld (S84_WeatherTimer),a
    call rnd
    and 7
    jp nz,SWTKeep
    ld a,(S84_Biome)
    cp BIOME_SNOW
    jp z,SWTSnow
    ld a,WEATHER_RAIN
    ld (S84_Weather),a
    ld a,1
    ld (S84_RenderDirty),a
    ret
SWTSnow:
    ld a,WEATHER_SNOW
    ld (S84_Weather),a
    ld a,1
    ld (S84_RenderDirty),a
    ret
SWTKeep:
    ld a,(S84_Weather)
    or a
    ret z
    ld a,WEATHER_CLEAR
    ld (S84_Weather),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_RenderWeather:
    ld a,(S84_Weather)
    or a
    ret z
    ; A few deterministic precipitation streaks/flake markers in logical view.
    ld b,6
SRWLoop:
    push bc
    call rnd
    and 95
    ld (S84_X1),a
    call rnd
    and 55
    ld (S84_Y1),a
    ld a,(S84_Weather)
    cp WEATHER_SNOW
    jp z,SRWSnow
    ld a,(S84_X1)
    ld (S84_X2),a
    ld a,(S84_Y1)
    add a,4
    ld (S84_Y2),a
    jp SRWDraw
SRWSnow:
    ld a,(S84_X1)
    inc a
    ld (S84_X2),a
    ld a,(S84_Y1)
    inc a
    ld (S84_Y2),a
SRWDraw:
    call LineGeneral
    pop bc
    djnz SRWLoop
    ret

S84_FurnaceTick:
    ld a,(S84_FurnaceFuel)
    or a
    jp z,SFTNoFuel
    dec a
    ld (S84_FurnaceFuel),a
    ld a,(S84_FurnaceInput)
    cp BLOCK_IRON_ORE
    jp z,SFTIron
    cp BLOCK_GOLD_ORE
    jp z,SFTGold
    ret
SFTIron:
    ld a,(S84_FurnaceProgress)
    inc a
    ld (S84_FurnaceProgress),a
    cp 12
    ret c
    xor a
    ld (S84_FurnaceProgress),a
    ld a,ITEM_IRON
    ld (S84_FurnaceOutput),a
    xor a
    ld (S84_FurnaceInput),a
    ret
SFTGold:
    ld a,(S84_FurnaceProgress)
    inc a
    ld (S84_FurnaceProgress),a
    cp 12
    ret c
    xor a
    ld (S84_FurnaceProgress),a
    ld a,ITEM_GOLD
    ld (S84_FurnaceOutput),a
    xor a
    ld (S84_FurnaceInput),a
    ret
SFTNoFuel:
    ret

S84_DropTick:
    ld a,(S84_DropCount)
    or a
    ret z
    ld b,a
    ld hl,S84_DropTimer
SDropLoop:
    ld a,(hl)
    or a
    jp z,SDropExpiredCheck
    dec a
    ld (hl),a
    jp SDropNext
SDropExpiredCheck:
    ld a,(S84_DropCount)
    or a
    jp z,SDropNext
    dec a
    ld (S84_DropCount),a
    jp SDropNext
SDropNext:
    inc hl
    djnz SDropLoop
    ret

S84_SpawnDrop:
    ; IN A=item, creates a tiny RAM-only dropped-item record if capacity exists.
    ld (S84_DropTemp),a
    ld a,(S84_DropCount)
    cp DROP_MAX
    ret nc
    ld e,a
    ld d,0
    ld hl,S84_DropType
    add hl,de
    ld a,(S84_DropTemp)
    ld (hl),a
    ld hl,S84_DropTimer
    add hl,de
    ld a,32
    ld (hl),a
    ld a,(S84_DropCount)
    inc a
    ld (S84_DropCount),a
    ret

S84_AchievementTick:
    ; Compact achievement bitset: first break, first craft, first mob hit,
    ; first day, first night, first furnace output, first bed spawn, first death.
    ld a,(S84_WorldDay)
    or a
    jp z,SATNoDay
    ld hl,S84_Achievements
    set 3,(hl)
SATNoDay:
    ld a,(S84_EditCount)
    or a
    jp z,SATNoBreak
    ld hl,S84_Achievements
    set 0,(hl)
SATNoBreak:
    ld a,(S84_FurnaceOutput)
    or a
    jp z,SATNoSmelt
    ld hl,S84_Achievements
    set 5,(hl)
SATNoSmelt:
    ret

S84_AutoSaveTick:
    ld a,(S84_GameMode)
    ld b,a
    ld a,(S84_AutoSaveTimer)
    inc a
    ld (S84_AutoSaveTimer),a
    cp 192
    ret c
    xor a
    ld (S84_AutoSaveTimer),a
    call S84_SaveGame
    ld a,b
    ld (S84_GameMode),a
    ret

S84_ToolMaintenance:
    ; A simple passive durability repair in creative, and a survival decay
    ; trigger driven by the mining action counter.
    ld a,(S84_GameMode)
    or a
    ret z
    ld a,(S84_HotbarSel)
    ld e,a
    ld d,0
    ld hl,S84_InvTypes
    add hl,de
    ld a,(hl)
    cp ITEM_WOOD_PICK
    jp c,STMDone
    cp ITEM_DIAMOND_SWORD+1
    jp nc,STMDone
    ld hl,S84_InvDurability
    add hl,de
    ld a,(hl)
    cp 100
    ret nc
    inc a
    ld (hl),a
STMdone:
    ret

S84_SetBedSpawn:
    ld a,(S84_PlayerX)
    ld (S84_SpawnX),a
    ld a,(S84_PlayerY)
    ld (S84_SpawnY),a
    ld a,(S84_PlayerZ)
    ld (S84_SpawnZ),a
    ld hl,S84_Achievements
    set 6,(hl)
    ret

S84_SleepAtBed:
    ld a,1
    ld (S84_Sleeping),a
    xor a
    ld (S84_Weather),a
    ld (S84_NightLevel),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_SetDifficultyNext:
    ld a,(S84_Difficulty)
    inc a
    cp DIFF_HARD+1
    jp c,SSDNStore
    xor a
SSDNStore:
    ld (S84_Difficulty),a
    ret

S84_SetWeatherNext:
    ld a,(S84_Weather)
    inc a
    cp WEATHER_SNOW+1
    jp c,SSWNStore
    xor a
SSWNStore:
    ld (S84_Weather),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_SetTexturePackNext:
    ld a,(S84_TexturePack)
    inc a
    and 3
    ld (S84_TexturePack),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

;------------------------------------------------------------------------------
; MCv2 GAMEPLAY EXPANSION
;------------------------------------------------------------------------------

S84_GainXP:
    ; IN A=small XP amount. 16-bit XP accumulator.
    ld b,a
    ld a,(S84_XPLo)
    add a,b
    ld (S84_XPLo),a
    ld a,(S84_XPHi)
    adc a,0
    ld (S84_XPHi),a
S84_XPCheck:
    ld a,(S84_Level)
    inc a
    ld c,a
    add a,a
    add a,c
    add a,a
    add a,8
    ld c,a
    ld a,(S84_XPLo)
    cp c
    jp c,S84_XPDone
    sub c
    ld (S84_XPLo),a
    ld a,(S84_Level)
    inc a
    ld (S84_Level),a
    ld a,(S84_PlayerHP)
    cp 24
    jp nc,S84_XPDone
    inc a
    ld (S84_PlayerHP),a
S84_XPDone:
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_XPTick:
    ; Slow ambient XP orb pickup simulation: nearby drops grant XP.
    ld a,(S84_DropCount)
    or a
    ret z
    ld a,(S84_DropType)
    cp ITEM_EMERALD
    jp z,S84_XPDrop
    cp ITEM_DIAMOND
    ret nz
S84_XPDrop:
    ld a,2
    call S84_GainXP
    xor a
    ld (S84_DropCount),a
    ret

S84_CropTick:
    ld a,(S84_CropTimer)
    inc a
    ld (S84_CropTimer),a
    and 63
    ret nz
    ld a,(S84_EditCount)
    or a
    ret z
    ld e,a
    ld hl,S84_EditData
S84_CropScan:
    ld a,(hl)
    ld b,a
    inc hl
    inc hl
    inc hl
    ld a,(hl)
    cp BLOCK_WHEAT
    jp nz,S84_CropNext
    ld a,BLOCK_WHEAT_RIPE
    ld (hl),a
S84_CropNext:
    inc hl
    dec e
    jp nz,S84_CropScan
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_StatusTick:
    ld a,(S84_EffectTimer)
    or a
    jp z,S84_StatusDone
    dec a
    ld (S84_EffectTimer),a
    ld a,(S84_EffectType)
    cp EFFECT_REGEN
    jp z,S84_EffectRegen
    cp EFFECT_POISON
    jp z,S84_EffectPoison
    jp S84_StatusDone
S84_EffectRegen:
    ld a,(S84_PlayerHP)
    cp 20
    jp nc,S84_StatusDone
    inc a
    ld (S84_PlayerHP),a
    jp S84_StatusDone
S84_EffectPoison:
    call S84_DamagePlayer
S84_StatusDone:
    ld a,(S84_EffectTimer)
    or a
    ret nz
    xor a
    ld (S84_EffectType),a
    ret

S84_UseSelectedItem:
    ; Inventory-screen Enter consumes/activates usable items.
    ld a,(S84_InvCursor)
    ld e,a
    ld d,0
    ld hl,S84_InvTypes
    add hl,de
    ld a,(hl)
    ld (S84_UseItemTmp),a
    cp ITEM_BREAD
    jp z,S84_UseFood5
    cp ITEM_COOKED_MEAT
    jp z,S84_UseFood8
    cp ITEM_COOKED_FISH
    jp z,S84_UseFood6
    cp ITEM_GOLDEN_APPLE
    jp z,S84_UseGapple
    cp ITEM_POTION_HEAL
    jp z,S84_UsePotionHeal
    cp ITEM_POTION_SPEED
    jp z,S84_UsePotionSpeed
    cp ITEM_POTION_STRENGTH
    jp z,S84_UsePotionStrength
    cp ITEM_POTION_POISON
    jp z,S84_UsePotionPoison
    cp ITEM_POTION_FIRE_RES
    jp z,S84_UsePotionFire
    cp ITEM_SHIELD
    jp z,S84_UseShield
    cp ITEM_FISHING_ROD
    jp z,S84_UseRod
    cp ITEM_BOW
    jp z,S84_UseBow
    cp ITEM_ENDER_PEARL
    jp z,S84_UsePearl
    cp ITEM_IRON_HELMET
    jp z,S84_EquipIron1
    cp ITEM_IRON_CHEST
    jp z,S84_EquipIron4
    cp ITEM_IRON_LEGS
    jp z,S84_EquipIron3
    cp ITEM_IRON_BOOTS
    jp z,S84_EquipIron2
    cp ITEM_DIAMOND_HELMET
    jp z,S84_EquipDiamond2
    cp ITEM_DIAMOND_CHEST
    jp z,S84_EquipDiamond6
    cp ITEM_DIAMOND_LEGS
    jp z,S84_EquipDiamond5
    cp ITEM_DIAMOND_BOOTS
    jp z,S84_EquipDiamond3
    cp ITEM_WHEAT_SEED
    jp z,S84_PlantSelectedSeed
    cp ITEM_BED
    jp z,S84_UseBed
    and a
    ret

S84_UseFood5:
    ld a,5
    jp S84_EatAmount
S84_UseFood8:
    ld a,8
    jp S84_EatAmount
S84_UseFood6:
    ld a,6
S84_EatAmount:
    ld b,a
    ld a,(S84_PlayerHunger)
    add a,b
    cp 20
    jp c,S84_EatStore
    ld a,20
S84_EatStore:
    ld (S84_PlayerHunger),a
    call S84_ConsumeSelected
    scf
    ret
S84_UseGapple:
    ld a,20
    ld (S84_PlayerHunger),a
    ld a,20
    ld (S84_PlayerHP),a
    ld a,EFFECT_REGEN
    ld (S84_EffectType),a
    ld a,32
    ld (S84_EffectTimer),a
    call S84_ConsumeSelected
    ld a,4
    call S84_GainXP
    scf
    ret
S84_UsePotionHeal:
    ld a,20
    ld (S84_PlayerHP),a
    call S84_ConsumeSelected
    scf
    ret
S84_UsePotionSpeed:
    ld a,EFFECT_SPEED
    ld (S84_EffectType),a
    ld a,96
    ld (S84_EffectTimer),a
    call S84_ConsumeSelected
    scf
    ret
S84_UsePotionStrength:
    ld a,EFFECT_STRENGTH
    ld (S84_EffectType),a
    ld a,96
    ld (S84_EffectTimer),a
    call S84_ConsumeSelected
    scf
    ret
S84_UsePotionPoison:
    ld a,EFFECT_POISON
    ld (S84_EffectType),a
    ld a,48
    ld (S84_EffectTimer),a
    call S84_ConsumeSelected
    scf
    ret
S84_UsePotionFire:
    ld a,EFFECT_FIRE_RES
    ld (S84_EffectType),a
    ld a,128
    ld (S84_EffectTimer),a
    call S84_ConsumeSelected
    scf
    ret
S84_UseShield:
    ld a,(S84_ShieldUp)
    xor 1
    ld (S84_ShieldUp),a
    ld a,32
    ld (S84_ShieldDurability),a
    scf
    ret
S84_UseRod:
    ld a,(S84_Fishing)
    xor 1
    ld (S84_Fishing),a
    ld a,48
    ld (S84_FishTimer),a
    scf
    ret
S84_UseBow:
    ld a,ITEM_ARROW
    call S84_CountType
    or a
    ret z
    ld a,ITEM_ARROW
    call S84_ConsumeType
    call S84_SpawnProjectile
    scf
    ret
S84_UsePearl:
    call rnd
    and 7
    add a,4
    ld (S84_PlayerX),a
    call rnd
    and 7
    add a,4
    ld (S84_PlayerZ),a
    call S84_RespawnPlayer
    call S84_ConsumeSelected
    scf
    ret
S84_EquipIron1:
    ld a,1
    ld (S84_ArmorHelmet),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipIron4:
    ld a,4
    ld (S84_ArmorChest),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipIron3:
    ld a,3
    ld (S84_ArmorLegs),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipIron2:
    ld a,2
    ld (S84_ArmorBoots),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipDiamond2:
    ld a,2
    ld (S84_ArmorHelmet),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipDiamond6:
    ld a,6
    ld (S84_ArmorChest),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipDiamond5:
    ld a,5
    ld (S84_ArmorLegs),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_EquipDiamond3:
    ld a,3
    ld (S84_ArmorBoots),a
    call S84_ConsumeSelected
    call S84_RecalcArmor
    scf
    ret
S84_ConsumeSelected:
    ld a,(S84_InvCursor)
    jp S84_ConsumeSlotA

S84_PlantSelectedSeed:
    call FindTarget
    ret nc
    ld a,(S84_TargetType)
    cp BLOCK_DIRT
    jp z,S84_PlantOK
    cp BLOCK_GRASS
    ret nz
S84_PlantOK:
    ld a,(S84_TargetX)
    ld (S84_EditXTmp),a
    ld a,(S84_TargetY)
    inc a
    ld (S84_EditYTmp),a
    ld a,(S84_TargetZ)
    ld (S84_EditZTmp),a
    ld a,BLOCK_WHEAT
    ld (S84_EditTypeTmp),a
    call StoreEdit
    call S84_ConsumeSelected
    scf
    ret

S84_UseBed:
    call S84_SetBedSpawn
    call S84_SleepAtBed
    call S84_ConsumeSelected
    scf
    ret

S84_RecalcArmor:
    ld a,(S84_ArmorHelmet)
    ld b,a
    ld a,(S84_ArmorChest)
    add a,b
    ld b,a
    ld a,(S84_ArmorLegs)
    add a,b
    ld b,a
    ld a,(S84_ArmorBoots)
    add a,b
    ld (S84_ArmorValue),a
    ret

S84_FishingTick:
    ld a,(S84_Fishing)
    or a
    ret z
    ld a,(S84_FishTimer)
    or a
    jp z,S84_FishCatch
    dec a
    ld (S84_FishTimer),a
    ret
S84_FishCatch:
    ld a,ITEM_RAW_FISH
    call AddInventory
    ld a,3
    call S84_GainXP
    xor a
    ld (S84_Fishing),a
    ret

S84_SpawnProjectile:
    ld a,(S84_ProjectileCount)
    cp PROJ_MAX
    ret nc
    ld e,a
    ld d,0
    ld hl,S84_ProjectileType
    add hl,de
    ld a,ITEM_ARROW
    ld (hl),a
    ld hl,S84_ProjectileX
    add hl,de
    ld a,(S84_PlayerX)
    ld (hl),a
    ld hl,S84_ProjectileZ
    add hl,de
    ld a,(S84_PlayerZ)
    ld (hl),a
    ld a,(S84_ProjectileCount)
    inc a
    ld (S84_ProjectileCount),a
    ret

S84_ProjectileTick:
    ld a,(S84_ProjectileCount)
    or a
    ret z
    ld b,a
    ld hl,S84_ProjectileLife
SPTickLoop:
    ld a,(hl)
    inc a
    ld (hl),a
    cp 12
    jp c,SPTickNext
    xor a
    ld (hl),a
SPTickNext:
    inc hl
    djnz SPTickLoop
    ret

S84_DimensionTick:
    ld a,(S84_PortalCooldown)
    or a
    jp z,S84_CheckPortal
    dec a
    ld (S84_PortalCooldown),a
    ret
S84_CheckPortal:
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerY)
    dec a
    ld c,a
    ld a,(S84_PlayerZ)
    ld d,a
    call GetBlockAt
    cp BLOCK_NETHER_PORTAL
    ret nz
    call S84_SetDimensionNext
    ld a,32
    ld (S84_PortalCooldown),a
    ret

S84_SetDimensionNext:
    ld a,(S84_Dimension)
    inc a
    cp 3
    jp c,S84_DimStore
    xor a
S84_DimStore:
    ld (S84_Dimension),a
    ; Every dimension transition returns the player to a safe surface location.
    ld a,6
    ld (S84_PlayerX),a
    ld (S84_PlayerZ),a
    ld a,(S84_PlayerX)
    ld b,a
    ld a,(S84_PlayerZ)
    ld c,a
    call GetColumnHeight
    add a,2
    ld (S84_PlayerY),a
    xor a
    ld (S84_YVel),a
    ld (S84_Weather),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_RedstoneTick:
    ld a,(S84_RedstonePulse)
    inc a
    ld (S84_RedstonePulse),a
    and 31
    ret nz
    ld a,(S84_LampOn)
    xor 1
    ld (S84_LampOn),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_NPCTick:
    ld a,(S84_TradeTimer)
    or a
    ret z
    dec a
    ld (S84_TradeTimer),a
    ret nz
    ; Periodically refresh a villager offer.
    call rnd
    and 3
    inc a
    ld (S84_TradeIndex),a
    ret

S84_BreedingTick:
    ld a,(S84_BreedingTimer)
    inc a
    ld (S84_BreedingTimer),a
    and 127
    ret nz
    ld a,(S84_MobActive+1)
    or a
    ret z
    ld a,(S84_MobType+1)
    or a
    ret nz
    ; Passive pair can occasionally produce a new passive mob if a slot is free.
    ld a,(S84_MobActive+3)
    or a
    ret nz
    ld a,1
    ld (S84_MobActive+3),a
    ld a,(S84_MobX)
    inc a
    ld (S84_MobX+3),a
    ld a,(S84_MobZ)
    ld (S84_MobZ+3),a
    xor a
    ld (S84_MobType+3),a
    ld a,6
    ld (S84_MobHP+3),a
    ld a,1
    ld (S84_Achievements),a
    ret

; HUD extras.
S84_DrawXPBar:
    ld a,(S84_XPLo)
    and 31
    add a,4
    ld (S84_X1),a
    ld a,61
    ld (S84_Y1),a
    ld a,(S84_XPLo)
    and 31
    ld (S84_X2),a
    add a,4
    ld (S84_X2),a
    ld a,61
    ld (S84_Y2),a
    call LineGeneral
    ret

S84_DrawArmorBar:
    ld a,(S84_ArmorValue)
    add a,1
    ld (S84_X1),a
    ld a,4
    ld (S84_Y1),a
    ld a,(S84_ArmorValue)
    add a,1
    ld (S84_X2),a
    ld a,4
    ld (S84_Y2),a
    call LineGeneral
    ret

S84_DrawOxygenBar:
    ld a,(S84_Oxygen)
    or a
    ret z
    ld a,3
    ld (S84_X1),a
    ld a,60
    ld (S84_Y1),a
    ld a,(S84_Oxygen)
    srl a
    add a,3
    ld (S84_X2),a
    ld a,60
    ld (S84_Y2),a
    call LineGeneral
    ret

S84_DrawCompass:
    ld a,(S84_Yaw)
    and 31
    ld b,a
    ld a,48
    ld (S84_X1),a
    ld a,56
    ld (S84_Y1),a
    ld a,48
    ld (S84_X2),a
    ld a,b
    and 7
    add a,53
    ld (S84_Y2),a
    call LineGeneral
    ret

;------------------------------------------------------------------------------
; SAVE / LOAD + MULTIPLAYER/LINK PROTOTYPE
;------------------------------------------------------------------------------
OpenSystemMenu:
    bcall(_maybe_ClrScrnFull)
SysLoop:
    call DrawSystemMenu
    bcall(_GetCSC)
    cp skClear
    ret z
    cp S84_KEY_YEQU
    ret z
    cp skLeft
    jp nz,SysRight
    ld a,(S84_SystemMenuSel)
    or a
    jp z,SysLeftWrap
    dec a
    ld (S84_SystemMenuSel),a
    jp SysLoop
SysLeftWrap:
    ld a,7
    ld (S84_SystemMenuSel),a
    jp SysLoop
SysRight:
    cp skRight
    jp nz,SysEnter
    ld a,(S84_SystemMenuSel)
    inc a
    cp 8
    jp c,SysRightStore
    xor a
SysRightStore:
    ld (S84_SystemMenuSel),a
    jp SysLoop
SysEnter:
    cp skEnter
    jp nz,SysLoop
    ld a,(S84_SystemMenuSel)
    cp 0
    jp z,SysSave
    cp 1
    jp z,SysLoad
    cp 2
    jp z,SysLink
    cp 3
    jp z,SysHelp
    cp 4
    jp z,SysDifficulty
    cp 5
    jp z,SysWeather
    cp 6
    jp z,SysTexture
    call S84_SetDimensionNext
    jp SysLoop
SysHelp:
    call S84_HelpScreen
    jp SysLoop
SysDifficulty:
    call S84_SetDifficultyNext
    jp SysLoop
SysWeather:
    call S84_SetWeatherNext
    jp SysLoop
SysTexture:
    call S84_SetTexturePackNext
    jp SysLoop
SysSave:
    call S84_SaveGame
    jp SysLoop
SysLoad:
    call S84_LoadGame
    jp SysLoop
SysLink:
    call S84_LinkMenu
    jp SysLoop

DrawSystemMenu:
    call SetColorBlack
    bcall(_maybe_ClrScrnFull)
    ld a,10
    ld (S84_X1),a
    ld a,10
    ld (S84_Y1),a
    ld a,32
    ld (S84_X2),a
    ld a,18
    ld (S84_Y2),a
    call LineGeneral
    ld a,36
    ld (S84_X1),a
    ld a,10
    ld (S84_Y1),a
    ld a,58
    ld (S84_X2),a
    ld a,18
    ld (S84_Y2),a
    call LineGeneral
    ld a,10
    ld (S84_X1),a
    ld a,24
    ld (S84_Y1),a
    ld a,32
    ld (S84_X2),a
    ld a,32
    ld (S84_Y2),a
    call LineGeneral
    ld a,36
    ld (S84_X1),a
    ld a,24
    ld (S84_Y1),a
    ld a,58
    ld (S84_X2),a
    ld a,32
    ld (S84_Y2),a
    call LineGeneral
    ret

S84_SaveGame:
    ld a,SAVE_MAGIC
    ld (S84_SaveBuffer+0),a
    ld a,(S84_GameMode)
    ld (S84_SaveBuffer+1),a
    ld a,(S84_PlayerX)
    ld (S84_SaveBuffer+2),a
    ld a,(S84_PlayerY)
    ld (S84_SaveBuffer+3),a
    ld a,(S84_PlayerZ)
    ld (S84_SaveBuffer+4),a
    ld a,(S84_Yaw)
    ld (S84_SaveBuffer+5),a
    ld a,(S84_Pitch)
    ld (S84_SaveBuffer+6),a
    ld a,(S84_HotbarSel)
    ld (S84_SaveBuffer+7),a
    ld a,(S84_WorldTime)
    ld (S84_SaveBuffer+8),a
    ld a,(S84_WorldDay)
    ld (S84_SaveBuffer+9),a
    ld a,(S84_PlayerHP)
    ld (S84_SaveBuffer+10),a
    ld a,(S84_PlayerHunger)
    ld (S84_SaveBuffer+11),a
    ld a,(S84_EditCount)
    ld (S84_SaveBuffer+12),a
    ld hl,S84_InvTypes
    ld de,S84_SaveBuffer+13
    ld bc,INV_COUNT
    ldir
    ld hl,S84_InvCounts
    ld de,S84_SaveBuffer+37
    ld bc,INV_COUNT
    ldir
    ld hl,S84_EditData
    ld de,S84_SaveBuffer+61
    ld bc,EDIT_MAX*4
    ldir
    ld hl,S84_MobActive
    ld de,S84_SaveBuffer+221
    ld bc,MOB_MAX
    ldir
    ld hl,S84_MobType
    ld de,S84_SaveBuffer+225
    ld bc,MOB_MAX
    ldir
    ld hl,S84_MobX
    ld de,S84_SaveBuffer+229
    ld bc,MOB_MAX
    ldir
    ld hl,S84_MobY
    ld de,S84_SaveBuffer+233
    ld bc,MOB_MAX
    ldir
    ld hl,S84_MobZ
    ld de,S84_SaveBuffer+237
    ld bc,MOB_MAX
    ldir
    ld hl,S84_MobHP
    ld de,S84_SaveBuffer+241
    ld bc,MOB_MAX
    ldir
    ; MCv1 config/state footer fits the original 256-byte snapshot.
    ld a,(S84_WorldSeed)
    ld (S84_SaveBuffer+248),a
    ld a,(S84_WorldSeed+1)
    ld (S84_SaveBuffer+249),a
    ld a,(S84_WorldSeedHi)
    ld (S84_SaveBuffer+250),a
    ld a,(S84_Weather)
    ld (S84_SaveBuffer+251),a
    ld a,(S84_Difficulty)
    ld (S84_SaveBuffer+252),a
    ld a,(S84_FOV)
    ld (S84_SaveBuffer+253),a
    ld a,(S84_RenderDistance)
    ld (S84_SaveBuffer+254),a
    ld a,(S84_TexturePack)
    ld (S84_SaveBuffer+255),a
    ld a,(S84_Dimension)
    ld (S84_SaveBuffer+256),a
    ld a,(S84_Level)
    ld (S84_SaveBuffer+257),a
    ld a,(S84_XPLo)
    ld (S84_SaveBuffer+258),a
    ld a,(S84_XPHi)
    ld (S84_SaveBuffer+259),a
    ld a,(S84_ArmorValue)
    ld (S84_SaveBuffer+260),a
    ld a,(S84_ShieldDurability)
    ld (S84_SaveBuffer+261),a
    ld a,(S84_Oxygen)
    ld (S84_SaveBuffer+262),a
    ld a,(S84_EffectType)
    ld (S84_SaveBuffer+263),a
    ld a,(S84_EffectTimer)
    ld (S84_SaveBuffer+264),a
    ld a,(S84_Emeralds)
    ld (S84_SaveBuffer+265),a
    ld a,(S84_EnchantmentLevel)
    ld (S84_SaveBuffer+266),a
    ld a,(S84_PortalCooldown)
    ld (S84_SaveBuffer+267),a
    ld a,1
    ld (S84_SaveValid),a
    ret

S84_LoadGame:
    ld a,(S84_SaveValid)
    or a
    ret z
    ld a,(S84_SaveBuffer+0)
    cp SAVE_MAGIC
    ret nz
    ld a,(S84_SaveBuffer+1)
    ld (S84_GameMode),a
    ld a,(S84_SaveBuffer+2)
    ld (S84_PlayerX),a
    ld a,(S84_SaveBuffer+3)
    ld (S84_PlayerY),a
    ld a,(S84_SaveBuffer+4)
    ld (S84_PlayerZ),a
    ld a,(S84_SaveBuffer+5)
    ld (S84_Yaw),a
    ld a,(S84_SaveBuffer+6)
    ld (S84_Pitch),a
    ld a,(S84_SaveBuffer+7)
    ld (S84_HotbarSel),a
    ld a,(S84_SaveBuffer+8)
    ld (S84_WorldTime),a
    ld a,(S84_SaveBuffer+9)
    ld (S84_WorldDay),a
    ld a,(S84_SaveBuffer+10)
    ld (S84_PlayerHP),a
    ld a,(S84_SaveBuffer+11)
    ld (S84_PlayerHunger),a
    ld a,(S84_SaveBuffer+12)
    ld (S84_EditCount),a
    ld hl,S84_SaveBuffer+13
    ld de,S84_InvTypes
    ld bc,INV_COUNT
    ldir
    ld hl,S84_SaveBuffer+37
    ld de,S84_InvCounts
    ld bc,INV_COUNT
    ldir
    ld hl,S84_SaveBuffer+61
    ld de,S84_EditData
    ld bc,EDIT_MAX*4
    ldir
    ld hl,S84_SaveBuffer+221
    ld de,S84_MobActive
    ld bc,MOB_MAX
    ldir
    ld hl,S84_SaveBuffer+225
    ld de,S84_MobType
    ld bc,MOB_MAX
    ldir
    ld hl,S84_SaveBuffer+229
    ld de,S84_MobX
    ld bc,MOB_MAX
    ldir
    ld hl,S84_SaveBuffer+233
    ld de,S84_MobY
    ld bc,MOB_MAX
    ldir
    ld hl,S84_SaveBuffer+237
    ld de,S84_MobZ
    ld bc,MOB_MAX
    ldir
    ld hl,S84_SaveBuffer+241
    ld de,S84_MobHP
    ld bc,MOB_MAX
    ldir
    ld a,(S84_SaveBuffer+248)
    ld (S84_WorldSeed),a
    ld a,(S84_SaveBuffer+249)
    ld (S84_WorldSeed+1),a
    ld a,(S84_SaveBuffer+250)
    ld (S84_WorldSeedHi),a
    ld a,(S84_SaveBuffer+251)
    ld (S84_Weather),a
    ld a,(S84_SaveBuffer+252)
    ld (S84_Difficulty),a
    ld a,(S84_SaveBuffer+253)
    ld (S84_FOV),a
    ld a,(S84_SaveBuffer+254)
    ld (S84_RenderDistance),a
    ld a,(S84_SaveBuffer+255)
    ld (S84_TexturePack),a
    ld a,(S84_SaveBuffer+256)
    ld (S84_Dimension),a
    ld a,(S84_SaveBuffer+257)
    ld (S84_Level),a
    ld a,(S84_SaveBuffer+258)
    ld (S84_XPLo),a
    ld a,(S84_SaveBuffer+259)
    ld (S84_XPHi),a
    ld a,(S84_SaveBuffer+260)
    ld (S84_ArmorValue),a
    ld a,(S84_SaveBuffer+261)
    ld (S84_ShieldDurability),a
    ld a,(S84_SaveBuffer+262)
    ld (S84_Oxygen),a
    ld a,(S84_SaveBuffer+263)
    ld (S84_EffectType),a
    ld a,(S84_SaveBuffer+264)
    ld (S84_EffectTimer),a
    ld a,(S84_SaveBuffer+265)
    ld (S84_Emeralds),a
    ld a,(S84_SaveBuffer+266)
    ld (S84_EnchantmentLevel),a
    ld a,(S84_SaveBuffer+267)
    ld (S84_PortalCooldown),a
    ld a,1
    ld (S84_RenderDirty),a
    ret

S84_QuickSaveLoad:
    ld a,(S84_SaveValid)
    or a
    jp z,S84_QuickSave
    call S84_LoadGame
    ret
S84_QuickSave:
    call S84_SaveGame
    ret

S84_LinkTick:
    ld a,(S84_LinkMode)
    or a
    ret z
    call S84_BuildLinkPacket
    ret

S84_BuildLinkPacket:
    ld hl,S84_LinkTx
    ld a,$53
    ld (hl),a
    inc hl
    ld a,1
    ld (hl),a
    inc hl
    ld a,(S84_PlayerX)
    ld (hl),a
    inc hl
    ld a,(S84_PlayerY)
    ld (hl),a
    inc hl
    ld a,(S84_PlayerZ)
    ld (hl),a
    inc hl
    ld a,(S84_Yaw)
    ld (hl),a
    inc hl
    ld a,(S84_PlayerHP)
    ld (hl),a
    inc hl
    ld a,(S84_HotbarSel)
    ld (hl),a
    ret

S84_LinkMenu:
    bcall(_maybe_ClrScrnFull)
    ld a,1
    ld (S84_LinkMode),a
LinkLoop:
    call DrawLinkScreen
    bcall(_GetCSC)
    cp skClear
    jp z,LinkExit
    cp S84_KEY_YEQU
    jp z,LinkExit
    cp skEnter
    jp nz,LinkLoop
    ld a,(S84_LinkPeerReady)
    xor 1
    ld (S84_LinkPeerReady),a
    jp LinkLoop
LinkExit:
    xor a
    ld (S84_LinkMode),a
    ret

DrawLinkScreen:
    call SetColorBlack
    bcall(_maybe_ClrScrnFull)
    ld a,22
    ld (S84_X1),a
    ld a,12
    ld (S84_Y1),a
    ld a,74
    ld (S84_X2),a
    ld a,44
    ld (S84_Y2),a
    call LineGeneral
    ret

S84_HelpScreen:
    bcall(_maybe_ClrScrnFull)
HelpLoop:
    bcall(_GetCSC)
    cp skClear
    ret z
    cp S84_KEY_YEQU
    ret z
    jp HelpLoop


;==============================================================================
; SINECRAFT CSE - ORIGINAL MUSIC SUPPORT
;------------------------------------------------------------------------------
; The soundtrack is original Sinecraft music with parody-style titles.
; Audio uses the calculator's Z80 I/O-port tone path. This is intentionally
; a small monophonic player so it can coexist with the color renderer.
;
; TRACE = music on/off
; ZOOM  = skip to next track
;
; Titles:
;   Finland
;   Dry Hands
;   Damp Hands
;   Rats on Mars
;   Tweeter Lullaby
;   Haggstone
;   Living Rats
;   Aria Meth
;   Beep City
;   Clarke
;   Danni
;
; The compositions below are original and are not transcriptions of the
; original Minecraft/C418 melodies.
;==============================================================================

; Note IDs: G2=0 through B5=40, one semitone per ID. 48=rest, 49=end.
S84_NOTE_G2      .equ 0
S84_NOTE_GS2     .equ 1
S84_NOTE_A2      .equ 2
S84_NOTE_AS2     .equ 3
S84_NOTE_B2      .equ 4
S84_NOTE_C3      .equ 5
S84_NOTE_CS3     .equ 6
S84_NOTE_D3      .equ 7
S84_NOTE_DS3     .equ 8
S84_NOTE_E3      .equ 9
S84_NOTE_F3      .equ 10
S84_NOTE_FS3     .equ 11
S84_NOTE_G3      .equ 12
S84_NOTE_GS3     .equ 13
S84_NOTE_A3      .equ 14
S84_NOTE_AS3     .equ 15
S84_NOTE_B3      .equ 16
S84_NOTE_C4      .equ 17
S84_NOTE_CS4     .equ 18
S84_NOTE_D4      .equ 19
S84_NOTE_DS4     .equ 20
S84_NOTE_E4      .equ 21
S84_NOTE_F4      .equ 22
S84_NOTE_FS4     .equ 23
S84_NOTE_G4      .equ 24
S84_NOTE_GS4     .equ 25
S84_NOTE_A4      .equ 26
S84_NOTE_AS4     .equ 27
S84_NOTE_B4      .equ 28
S84_NOTE_C5      .equ 29
S84_NOTE_CS5     .equ 30
S84_NOTE_D5      .equ 31
S84_NOTE_DS5     .equ 32
S84_NOTE_E5      .equ 33
S84_NOTE_F5      .equ 34
S84_NOTE_FS5     .equ 35
S84_NOTE_G5      .equ 36
S84_NOTE_GS5     .equ 37
S84_NOTE_A5      .equ 38
S84_NOTE_AS5     .equ 39
S84_NOTE_B5      .equ 40
S84_NOTE_REST    .equ 48
S84_NOTE_END     .equ 49

S84_MusicCount   .equ 11

;------------------------------------------------------------------------------
; Music state
;------------------------------------------------------------------------------
S84_InitMusic:
    xor a
    ld (S84_MusicTrack),a
    ld (S84_MusicWait),a
    ld (S84_MusicNote),a
    ld a,1
    ld (S84_MusicEnabled),a
    call S84_LoadMusicTrack
    ret

S84_ToggleMusic:
    ld a,(S84_MusicEnabled)
    xor 1
    ld (S84_MusicEnabled),a
    or a
    jp nz,S84_ToggleDone
    call S84_Silence
S84_ToggleDone:
    ret

S84_NextMusic:
    ld a,(S84_MusicTrack)
    inc a
    cp S84_MusicCount
    jp c,S84_NextStore
    xor a
S84_NextStore:
    ld (S84_MusicTrack),a
    xor a
    ld (S84_MusicWait),a
    call S84_LoadMusicTrack
    ret

S84_LoadMusicTrack:
    ld a,(S84_MusicTrack)
    add a,a
    ld e,a
    ld d,0
    ld hl,S84_MusicTable
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
    ld (S84_MusicPtr),hl
    xor a
    ld (S84_MusicWait),a
    ret

; Called every game-loop iteration. One short tone chunk is emitted per tick,
; so the music advances without monopolizing the renderer for an entire note.
S84_MusicTick:
    ld a,(S84_MusicEnabled)
    or a
    ret z

    ld a,(S84_MusicWait)
    or a
    jp z,S84_MusicFetch

    dec a
    ld (S84_MusicWait),a

    ld a,(S84_MusicNote)
    cp S84_NOTE_REST
    ret z
    cp S84_NOTE_END
    ret z
    call S84_PlayToneChunk
    ret

S84_MusicFetch:
    ld hl,(S84_MusicPtr)
    ld a,(hl)
    inc hl
    ld (S84_MusicNote),a
    ld a,(hl)
    inc hl
    ld (S84_MusicWait),a
    ld (S84_MusicPtr),hl

    ld a,(S84_MusicNote)
    cp S84_NOTE_END
    jp z,S84_MusicEnded
    cp S84_NOTE_REST
    ret z
    call S84_PlayToneChunk
    ret

S84_MusicEnded:
    ld a,(S84_MusicTrack)
    inc a
    cp S84_MusicCount
    jp c,S84_MusicEndStore
    xor a
S84_MusicEndStore:
    ld (S84_MusicTrack),a
    jp S84_LoadMusicTrack

;------------------------------------------------------------------------------
; Tiny monophonic tone chunk.
; This follows the classic TI Z80 I/O-port square-wave technique. Port 0 is
; the audio/link-port path used by calculator sound drivers such as NoteMan.
;------------------------------------------------------------------------------
S84_PlayToneChunk:
    cp S84_NOTE_REST
    ret z
    cp S84_NOTE_END
    ret z

    ld e,a
    ld d,0
    ld hl,S84_NotePeriods
    add hl,de
    ld c,(hl)

    ; G2..B5 are stored in the period table.
    ld a,e
    cp 41
    ret nc

    di
    xor a
    ld e,a
    ld b,4
S84_ToneOuter:
    ld a,c
S84_ToneInner:
    dec a
    jp nz,S84_ToneInner
    ld a,e
    xor 3
    ld e,a
    out (0),a
    djnz S84_ToneOuter
    xor a
    out (0),a
    ei
    ret

S84_Silence:
    xor a
    out (0),a
    ret

; Period values are approximate and intentionally compact. The exact sound
; character depends on the CSE clock/audio path.
S84_NotePeriods:
    .db 160,151,143,135,127
    .db 120,113,107,101,95,90,85,80,76,71,67,64
    .db 60,57,54,50,48,45,42,40,38,36,34,32
    .db 30,28,27,25,24,22,21,20,19,18,17,16

;------------------------------------------------------------------------------
; Original Sinecraft soundtrack
;------------------------------------------------------------------------------

S84_Music_Finland:
    .db S84_NOTE_C4,2,S84_NOTE_E4,2,S84_NOTE_G4,4,S84_NOTE_E4,2,S84_NOTE_D4,2,S84_NOTE_C4,4,S84_NOTE_REST,2
    .db S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_B4,4,S84_NOTE_G4,2,S84_NOTE_E4,2,S84_NOTE_D4,4,S84_NOTE_REST,2
    .db S84_NOTE_A3,2,S84_NOTE_C4,2,S84_NOTE_E4,4,S84_NOTE_C4,2,S84_NOTE_B3,2,S84_NOTE_A3,4
    .db S84_NOTE_G3,2,S84_NOTE_B3,2,S84_NOTE_D4,4,S84_NOTE_B3,2,S84_NOTE_A3,2,S84_NOTE_G3,6,S84_NOTE_END,0

S84_Music_DryHands:
    .db S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_B4,4,S84_NOTE_G4,2,S84_NOTE_E4,2,S84_NOTE_D4,4
    .db S84_NOTE_F4,2,S84_NOTE_A4,2,S84_NOTE_C5,4,S84_NOTE_A4,2,S84_NOTE_F4,2,S84_NOTE_E4,4
    .db S84_NOTE_D4,2,S84_NOTE_FS4,2,S84_NOTE_A4,4,S84_NOTE_FS4,2,S84_NOTE_D4,2,S84_NOTE_C4,4
    .db S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_C5,6,S84_NOTE_B4,2,S84_NOTE_G4,2,S84_NOTE_E4,8,S84_NOTE_END,0

S84_Music_DampHands:
    .db S84_NOTE_G4,2,S84_NOTE_A4,2,S84_NOTE_B4,4,S84_NOTE_D5,2,S84_NOTE_B4,2,S84_NOTE_A4,4
    .db S84_NOTE_F4,2,S84_NOTE_G4,2,S84_NOTE_A4,4,S84_NOTE_C5,2,S84_NOTE_A4,2,S84_NOTE_G4,4
    .db S84_NOTE_E4,2,S84_NOTE_FS4,2,S84_NOTE_G4,4,S84_NOTE_B4,2,S84_NOTE_G4,2,S84_NOTE_FS4,4
    .db S84_NOTE_D4,2,S84_NOTE_F4,2,S84_NOTE_A4,4,S84_NOTE_C5,2,S84_NOTE_A4,2,S84_NOTE_D5,8,S84_NOTE_END,0

S84_Music_RatsOnMars:
    .db S84_NOTE_A3,4,S84_NOTE_C4,2,S84_NOTE_E4,4,S84_NOTE_B3,2,S84_NOTE_D4,2,S84_NOTE_G4,6,S84_NOTE_REST,4
    .db S84_NOTE_F3,4,S84_NOTE_A3,2,S84_NOTE_C4,4,S84_NOTE_G3,2,S84_NOTE_B3,2,S84_NOTE_D4,6,S84_NOTE_REST,4
    .db S84_NOTE_E3,4,S84_NOTE_G3,2,S84_NOTE_B3,4,S84_NOTE_F3,2,S84_NOTE_A3,2,S84_NOTE_C4,6
    .db S84_NOTE_D4,2,S84_NOTE_FS4,2,S84_NOTE_A4,6,S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_B4,8,S84_NOTE_END,0

S84_Music_Tweeter:
    .db S84_NOTE_C5,4,S84_NOTE_G4,4,S84_NOTE_E4,6,S84_NOTE_REST,4
    .db S84_NOTE_D5,4,S84_NOTE_A4,4,S84_NOTE_F4,6,S84_NOTE_REST,4
    .db S84_NOTE_E5,4,S84_NOTE_B4,4,S84_NOTE_G4,6,S84_NOTE_REST,4
    .db S84_NOTE_D5,4,S84_NOTE_G4,4,S84_NOTE_B4,8,S84_NOTE_REST,6
    .db S84_NOTE_C5,3,S84_NOTE_E5,3,S84_NOTE_G5,8,S84_NOTE_E5,3,S84_NOTE_D5,3,S84_NOTE_C5,8,S84_NOTE_END,0

S84_Music_Haggstone:
    .db S84_NOTE_D4,3,S84_NOTE_F4,2,S84_NOTE_A4,5,S84_NOTE_G4,2,S84_NOTE_E4,3,S84_NOTE_D4,6,S84_NOTE_REST,3
    .db S84_NOTE_C4,2,S84_NOTE_E4,3,S84_NOTE_G4,5,S84_NOTE_F4,2,S84_NOTE_D4,3,S84_NOTE_C4,6,S84_NOTE_REST,3
    .db S84_NOTE_A3,3,S84_NOTE_C4,2,S84_NOTE_E4,5,S84_NOTE_D4,2,S84_NOTE_B3,3,S84_NOTE_A3,6
    .db S84_NOTE_G3,2,S84_NOTE_B3,3,S84_NOTE_D4,5,S84_NOTE_C4,2,S84_NOTE_A3,3,S84_NOTE_G3,9,S84_NOTE_END,0

S84_Music_LivingRats:
    .db S84_NOTE_C4,2,S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_E4,2,S84_NOTE_D4,2,S84_NOTE_F4,2,S84_NOTE_A4,4
    .db S84_NOTE_D4,2,S84_NOTE_FS4,2,S84_NOTE_A4,2,S84_NOTE_FS4,2,S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_B4,4
    .db S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_B4,2,S84_NOTE_G4,2,S84_NOTE_FS4,2,S84_NOTE_A4,2,S84_NOTE_C5,4
    .db S84_NOTE_F4,2,S84_NOTE_A4,2,S84_NOTE_C5,2,S84_NOTE_A4,2,S84_NOTE_G4,2,S84_NOTE_B4,2,S84_NOTE_D5,8,S84_NOTE_END,0

S84_Music_AriaMeth:
    .db S84_NOTE_C4,1,S84_NOTE_G4,1,S84_NOTE_E4,1,S84_NOTE_B4,1,S84_NOTE_D4,1,S84_NOTE_A4,1,S84_NOTE_F4,1,S84_NOTE_C5,1
    .db S84_NOTE_E4,1,S84_NOTE_B4,1,S84_NOTE_G4,1,S84_NOTE_D5,1,S84_NOTE_F4,1,S84_NOTE_C5,1,S84_NOTE_A4,1,S84_NOTE_E5,1
    .db S84_NOTE_G4,2,S84_NOTE_B4,2,S84_NOTE_D5,2,S84_NOTE_FS4,2,S84_NOTE_A4,2,S84_NOTE_C5,2
    .db S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_C5,2,S84_NOTE_D4,2,S84_NOTE_G4,2,S84_NOTE_B4,6
    .db S84_NOTE_REST,4,S84_NOTE_C4,2,S84_NOTE_E4,2,S84_NOTE_G4,8,S84_NOTE_END,0

S84_Music_BeepCity:
    .db S84_NOTE_C4,2,S84_NOTE_C4,2,S84_NOTE_E4,4,S84_NOTE_G4,2,S84_NOTE_E4,2,S84_NOTE_D4,4
    .db S84_NOTE_F4,2,S84_NOTE_F4,2,S84_NOTE_A4,4,S84_NOTE_C5,2,S84_NOTE_A4,2,S84_NOTE_G4,4
    .db S84_NOTE_E4,2,S84_NOTE_E4,2,S84_NOTE_G4,4,S84_NOTE_B4,2,S84_NOTE_G4,2,S84_NOTE_E4,4
    .db S84_NOTE_D4,2,S84_NOTE_FS4,2,S84_NOTE_A4,4,S84_NOTE_C5,2,S84_NOTE_B4,2,S84_NOTE_G4,8,S84_NOTE_END,0

S84_Music_Clarke:
    .db S84_NOTE_E4,4,S84_NOTE_B3,2,S84_NOTE_C4,4,S84_NOTE_G3,2,S84_NOTE_A3,4,S84_NOTE_E4,6,S84_NOTE_REST,4
    .db S84_NOTE_F4,4,S84_NOTE_C4,2,S84_NOTE_D4,4,S84_NOTE_A3,2,S84_NOTE_B3,4,S84_NOTE_F4,6,S84_NOTE_REST,4
    .db S84_NOTE_G4,4,S84_NOTE_D4,2,S84_NOTE_E4,4,S84_NOTE_B3,2,S84_NOTE_C4,4,S84_NOTE_G4,6
    .db S84_NOTE_A4,3,S84_NOTE_G4,3,S84_NOTE_E4,6,S84_NOTE_D4,3,S84_NOTE_C4,3,S84_NOTE_B3,8,S84_NOTE_END,0

S84_Music_Danni:
    .db S84_NOTE_C4,4,S84_NOTE_E4,4,S84_NOTE_G4,6,S84_NOTE_E4,3,S84_NOTE_D4,3,S84_NOTE_C4,6
    .db S84_NOTE_E4,4,S84_NOTE_G4,4,S84_NOTE_B4,6,S84_NOTE_G4,3,S84_NOTE_F4,3,S84_NOTE_E4,6
    .db S84_NOTE_D4,4,S84_NOTE_F4,4,S84_NOTE_A4,6,S84_NOTE_G4,3,S84_NOTE_E4,3,S84_NOTE_D4,6
    .db S84_NOTE_C4,3,S84_NOTE_DS4,2,S84_NOTE_E4,8,S84_NOTE_REST,4
    .db S84_NOTE_C4,2,S84_NOTE_E4,2,S84_NOTE_G4,2,S84_NOTE_C5,10,S84_NOTE_END,0

S84_MusicTable:
    .dw S84_Music_Finland
    .dw S84_Music_DryHands
    .dw S84_Music_DampHands
    .dw S84_Music_RatsOnMars
    .dw S84_Music_Tweeter
    .dw S84_Music_Haggstone
    .dw S84_Music_LivingRats
    .dw S84_Music_AriaMeth
    .dw S84_Music_BeepCity
    .dw S84_Music_Clarke
    .dw S84_Music_Danni

; Music state variables.
S84_MusicEnabled .db 1
S84_MusicTrack   .db 0
S84_MusicWait    .db 0
S84_MusicNote    .db S84_NOTE_REST
S84_MusicPtr     .dw 0

;------------------------------------------------------------------------------
; Small delay so the loop does not hammer the OS scan routine.
;------------------------------------------------------------------------------
SmallDelay:
    ld bc,700
SDLoop:
    dec bc
    ld a,b
    or c
    jp nz,SDLoop
    ret

;------------------------------------------------------------------------------
; Data
;------------------------------------------------------------------------------
S84_RndSeed         .dw $A731
S84_KeyNow          .db 0
S84_RenderDirty     .db 1
S84_GameMode        .db 0
S84_Yaw             .db 0
S84_Pitch           .db 0
S84_HotbarSel       .db 0
S84_PlayerX         .db 6
S84_PlayerY         .db 4
S84_PlayerZ         .db 6
S84_YVel            .db 0

S84_EditCount       .db 0

S84_InvOpen         .db 0
S84_CraftOpen       .db 0
S84_PauseOpen       .db 0

S84_InvTypes        .fill INV_COUNT,0
S84_InvCounts       .fill INV_COUNT,0
S84_InvTypeTmp      .db 0
S84_InvCountTmp     .db 0

S84_TempX           .db 0
S84_TempY           .db 0
S84_TempZ           .db 0
S84_TempHeight      .db 0
S84_TempMove        .db 0
S84_LastBreakType   .db 0

S84_DX              .db 0
S84_DZ              .db 0
S84_CamX            .db 0
S84_CamZ            .db 0

S84_RenderDX        .db 0
S84_RenderDZ        .db 0
S84_RenderH         .db 0
S84_RenderEditType  .db 0
S84_DrawBlock        .db BLOCK_STONE
S84_TextureMode     .db 0
S84_TextureShade    .db 0
S84_TexU             .db 0

S84_ProjX           .db 0
S84_ProjY           .db 0
S84_ProjDepth       .db 0
S84_ProjSize        .db 0
S84_ScaleVal        .db 0

S84_CubeCX          .db 0
S84_CubeCY          .db 0
S84_CubeS           .db 0
S84_FillY           .db 0
S84_FillEnd         .db 0
S84_FillWidth       .db 0

S84_LineY           .db 0
S84_LGXDir          .db 1
S84_LGYStep        .db 1
S84_X1              .db 0
S84_Y1              .db 0
S84_X2              .db 0
S84_Y2              .db 0
S84_YBottom         .db 0

S84_HudX            .db 0
S84_HudSlot         .db 0

S84_ScanX           .db 0
S84_ScanZ           .db 0
S84_ScanStep        .db 0

S84_TargetFound     .db 0
S84_TargetX         .db 0
S84_TargetY         .db 0
S84_TargetZ         .db 0
S84_TargetType      .db 0
S84_TargetDepth     .db 0

S84_EditXTmp        .db 0
S84_EditYTmp        .db 0
S84_EditZTmp        .db 0
S84_EditTypeTmp     .db 0
S84_EditType        .db 0

; MCv2 live gameplay state.
S84_Level           .db 1
S84_XPLo            .db 0
S84_XPHi            .db 0
S84_XPNeed           .db 12
S84_ArmorValue      .db 0
S84_ArmorHelmet      .db 0
S84_ArmorChest       .db 0
S84_ArmorLegs        .db 0
S84_ArmorBoots       .db 0
S84_ShieldUp         .db 0
S84_ShieldDurability .db 0
S84_Oxygen           .db 20
S84_Fishing          .db 0
S84_FishTimer        .db 0
S84_CropTimer        .db 0
S84_TradeTimer       .db 64
S84_TradeIndex       .db 1
S84_BreedingTimer    .db 0
S84_RedstonePulse    .db 0
S84_LampOn           .db 0
S84_Dimension        .db DIM_OVERWORLD
S84_PortalCooldown   .db 0
S84_EffectType       .db EFFECT_NONE
S84_EffectTimer      .db 0
S84_UseItemTmp       .db 0
S84_Emeralds         .db 0
S84_EnchantmentLevel .db 0
S84_ProjectileCount  .db 0
S84_ProjectileType         .fill PROJ_MAX,0
S84_ProjectileX            .fill PROJ_MAX,0
S84_ProjectileZ            .fill PROJ_MAX,0
S84_ProjectileLife         .fill PROJ_MAX,0
S84_ArmorSpecial     .db 0

;==============================================================================
; MCv2 EXTRA STATE / DATA
;==============================================================================

; 40 edit records * 4 bytes = 160 bytes
S84_EditData:
    .fill EDIT_MAX*4,0

; CSE uses direct LCD drawing; no monochrome plotSScreen buffer is required.
; Leave remaining RAM to the system / app runtime.

;------------------------------------------------------------------------------
; Expanded prototype data/state
;------------------------------------------------------------------------------
S84_WorldTime       .db 0
S84_WorldDay        .db 0
S84_NightLevel      .db 0
S84_PlayerHP        .db 20
S84_PlayerHunger    .db 20
S84_HungerClock     .db 0
S84_MobTickCount    .db 0
S84_RenderMobsFlag  .db 0
S84_GenX             .db 0
S84_GenY             .db 0
S84_GenZ             .db 0
S84_SystemMenuSel   .db 0
S84_CraftRecipe      .db 0
S84_InvCursor        .db 0
S84_InvDrawSlot      .db 0
S84_FindItemType     .db 0
S84_ChunkX          .db 0
S84_ChunkZ          .db 0
S84_LinkMode        .db 0
S84_LinkPeerReady   .db 0
S84_SaveValid       .db 0
S84_LinkTx          .fill 16,0

S84_MobActive       .fill MOB_MAX,0
S84_MobType         .fill MOB_MAX,0
S84_MobX            .fill MOB_MAX,0
S84_MobY            .fill MOB_MAX,0
S84_MobZ            .fill MOB_MAX,0
S84_MobHP           .fill MOB_MAX,0

; MCv1 expanded state
S84_WorldSeed       .db $31,$A7,$00
S84_WorldSeedHi     .db $5C
S84_Biome           .db BIOME_PLAINS
S84_Weather         .db WEATHER_CLEAR
S84_WeatherTimer    .db 0
S84_Difficulty      .db DIFF_NORMAL
S84_SpawnX          .db 6
S84_SpawnY          .db 4
S84_SpawnZ          .db 6
S84_Sleeping        .db 0
S84_FOV             .db 32
S84_RenderDistance  .db 8
S84_TimeScale       .db 2
S84_AutoSaveTimer   .db 0
S84_TexturePack     .db 0
S84_SaveSlot        .db 0
S84_FurnaceFuel     .db 0
S84_FurnaceProgress .db 0
S84_FurnaceInput    .db 0
S84_FurnaceOutput   .db 0
S84_DropCount       .db 0
S84_DropTemp        .db 0
S84_DropType        .fill DROP_MAX,0
S84_DropTimer       .fill DROP_MAX,0
S84_InvDurability   .fill INV_COUNT,0
S84_AchievementCount .db 0
S84_Achievements    .fill ACH_MAX,0

; RAM snapshot layout used by the prototype save/load system.
S84_SaveBuffer      .fill 384,0

;------------------------------------------------------------------------------
; Embedded CSE texture/palette assets
; This is embedded directly so SPASM-ng Online does not need assets.inc.
;------------------------------------------------------------------------------
; ===========================================================
; assets.inc -- supplied Sinecraft/MC3D CSE assets
; ===========================================================

palLit:
	.db $00, $00, $6B, $6D, $84, $30, $5A, $CB
	.db $9C, $D3, $7A, $A6, $8B, $27, $62, $25
	.db $49, $A3, $5C, $66, $6D, $47, $43, $84
	.db $85, $E9, $A3, $C9, $BC, $6B, $83, $07
	.db $6A, $65, $3B, $44, $4C, $05, $2A, $83
	.db $21, $E2, $92, $47, $AA, $C9, $79, $E6
	.db $B5, $94, $DE, $73, $E6, $F5, $C5, $D0
	.db $B5, $2E, $49, $A4, $5A, $25, $31, $23

palDim:
	.db $00, $00, $42, $28, $52, $8A, $31, $A6
	.db $63, $0C, $49, $A3, $51, $E4, $39, $43
	.db $31, $02, $3A, $C3, $43, $44, $2A, $23
	.db $53, $A5, $62, $65, $72, $C6, $51, $E4
	.db $41, $63, $22, $02, $32, $83, $19, $82
	.db $11, $21, $59, $64, $69, $A5, $49, $23
	.db $73, $6C, $83, $EB, $8C, $4D, $7B, $8A
	.db $6B, $28, $29, $02, $39, $43, $20, $A1

skyHi	.equ $6D
skyLo	.equ $5D
flrHi	.equ $49
flrLo	.equ $C5

hotbarCol:
	.db $6B, $6D, $84, $30, $7A, $A6, $5C, $66
	.db $A3, $C9, $49, $A4, $3B, $44, $92, $47
	.db $DE, $73

sinTab:
	.db $00, $00, $06, $00, $0D, $00, $13, $00, $19, $00, $1F, $00, $26, $00, $2C, $00
	.db $32, $00, $38, $00, $3E, $00, $44, $00, $4A, $00, $50, $00, $56, $00, $5C, $00
	.db $62, $00, $68, $00, $6D, $00, $73, $00, $79, $00, $7E, $00, $84, $00, $89, $00
	.db $8E, $00, $93, $00, $98, $00, $9D, $00, $A2, $00, $A7, $00, $AC, $00, $B1, $00
	.db $B5, $00, $B9, $00, $BE, $00, $C2, $00, $C6, $00, $CA, $00, $CE, $00, $D1, $00
	.db $D5, $00, $D8, $00, $DC, $00, $DF, $00, $E2, $00, $E5, $00, $E7, $00, $EA, $00
	.db $ED, $00, $EF, $00, $F1, $00, $F3, $00, $F5, $00, $F7, $00, $F8, $00, $FA, $00
	.db $FB, $00, $FC, $00, $FD, $00, $FE, $00, $FF, $00, $FF, $00, $00, $01, $00, $01
	.db $00, $01, $00, $01, $00, $01, $FF, $00, $FF, $00, $FE, $00, $FD, $00, $FC, $00
	.db $FB, $00, $FA, $00, $F8, $00, $F7, $00, $F5, $00, $F3, $00, $F1, $00, $EF, $00
	.db $ED, $00, $EA, $00, $E7, $00, $E5, $00, $E2, $00, $DF, $00, $DC, $00, $D8, $00
	.db $D5, $00, $D1, $00, $CE, $00, $CA, $00, $C6, $00, $C2, $00, $BE, $00, $B9, $00
	.db $B5, $00, $B1, $00, $AC, $00, $A7, $00, $A2, $00, $9D, $00, $98, $00, $93, $00
	.db $8E, $00, $89, $00, $84, $00, $7E, $00, $79, $00, $73, $00, $6D, $00, $68, $00
	.db $62, $00, $5C, $00, $56, $00, $50, $00, $4A, $00, $44, $00, $3E, $00, $38, $00
	.db $32, $00, $2C, $00, $26, $00, $1F, $00, $19, $00, $13, $00, $0D, $00, $06, $00
	.db $00, $00, $FA, $FF, $F3, $FF, $ED, $FF, $E7, $FF, $E1, $FF, $DA, $FF, $D4, $FF
	.db $CE, $FF, $C8, $FF, $C2, $FF, $BC, $FF, $B6, $FF, $B0, $FF, $AA, $FF, $A4, $FF
	.db $9E, $FF, $98, $FF, $93, $FF, $8D, $FF, $87, $FF, $82, $FF, $7C, $FF, $77, $FF
	.db $72, $FF, $6D, $FF, $68, $FF, $63, $FF, $5E, $FF, $59, $FF, $54, $FF, $4F, $FF
	.db $4B, $FF, $47, $FF, $42, $FF, $3E, $FF, $3A, $FF, $36, $FF, $32, $FF, $2F, $FF
	.db $2B, $FF, $28, $FF, $24, $FF, $21, $FF, $1E, $FF, $1B, $FF, $19, $FF, $16, $FF
	.db $13, $FF, $11, $FF, $0F, $FF, $0D, $FF, $0B, $FF, $09, $FF, $08, $FF, $06, $FF
	.db $05, $FF, $04, $FF, $03, $FF, $02, $FF, $01, $FF, $01, $FF, $00, $FF, $00, $FF
	.db $00, $FF, $00, $FF, $01, $FF, $01, $FF, $02, $FF, $03, $FF, $04, $FF, $05, $FF
	.db $06, $FF, $08, $FF, $09, $FF, $0B, $FF, $0D, $FF, $0F, $FF, $11, $FF, $13, $FF
	.db $16, $FF, $19, $FF, $1B, $FF, $1E, $FF, $21, $FF, $24, $FF, $28, $FF, $2B, $FF
	.db $2F, $FF, $32, $FF, $36, $FF, $3A, $FF, $3E, $FF, $42, $FF, $47, $FF, $4B, $FF
	.db $4F, $FF, $54, $FF, $59, $FF, $5E, $FF, $63, $FF, $68, $FF, $6D, $FF, $72, $FF
	.db $77, $FF, $7C, $FF, $82, $FF, $87, $FF, $8D, $FF, $93, $FF, $98, $FF
	.db $9E, $FF, $A4, $FF, $AA, $FF, $B0, $FF, $B6, $FF, $BC, $FF, $C2, $FF, $C8, $FF
	.db $CE, $FF, $D4, $FF, $DA, $FF, $E1, $FF, $E7, $FF, $ED, $FF, $F3, $FF, $FA, $FF

; 16x16 palette-indexed textures, column-major.
; block id 1
texStone:
	.db $02,$01,$02,$02,$01,$02,$02,$01,$02,$03,$02,$01,$02,$01,$02,$02
	.db $03,$03,$02,$01,$01,$03,$02,$03,$02,$01,$02,$02,$01,$02,$03,$02
	.db $03,$03,$01,$02,$01,$02,$01,$02,$02,$02,$02,$01,$02,$01,$02,$01
	.db $03,$02,$01,$02,$01,$01,$01,$01,$01,$02,$01,$03,$02,$01,$02,$01
	.db $01,$03,$04,$04,$01,$02,$01,$03,$03,$01,$01,$01,$01,$01,$01,$01
	.db $02,$03,$03,$03,$01,$03,$03,$01,$03,$02,$01,$02,$01,$01,$01,$02
	.db $03,$01,$03,$03,$01,$03,$03,$02,$01,$02,$02,$02,$01,$01,$01,$02
	.db $01,$01,$03,$04,$01,$01,$02,$01,$01,$01,$02,$01,$02,$02,$02,$02
	.db $02,$01,$02,$02,$02,$01,$03,$03,$01,$01,$01,$03,$01,$02,$03,$01
	.db $01,$01,$01,$02,$01,$01,$03,$03,$02,$03,$02,$01,$01,$03,$03,$01
	.db $03,$01,$03,$03,$01,$02,$01,$01,$02,$02,$03,$02,$01,$03,$01,$03
	.db $02,$03,$03,$01,$01,$01,$02,$01,$02,$01,$03,$03,$03,$03,$01,$02
	.db $01,$04,$04,$01,$01,$03,$01,$02,$01,$01,$03,$04,$04,$03,$01,$02
	.db $01,$01,$01,$01,$02,$01,$01,$02,$01,$03,$01,$01,$01,$03,$02,$01
	.db $01,$01,$01,$02,$01,$01,$02,$01,$02,$01,$02,$01,$01,$01,$02,$01
	.db $01,$01,$03,$02,$02,$02,$01,$01,$03,$01,$01,$01,$01,$03,$03,$02

texCobble:
	.db $01,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$04,$04,$04
	.db $01,$01,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$04,$04,$04
	.db $01,$01,$01,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$04,$04,$04
	.db $02,$02,$02,$02,$02,$03,$03,$01,$01,$01,$01,$01,$01,$04,$04,$04
	.db $02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $02,$02,$02,$02,$02,$03,$01,$01,$01,$03,$03,$03,$03,$03,$03,$03
	.db $02,$02,$02,$02,$03,$01,$01,$01,$01,$01,$02,$02,$03,$03,$03,$03
	.db $02,$02,$02,$03,$01,$01,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03
	.db $03,$03,$03,$03,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03
	.db $03,$03,$03,$03,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03
	.db $03,$03,$03,$03,$03,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03
	.db $03,$03,$03,$03,$03,$03,$01,$01,$04,$04,$04,$04,$04,$04,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$04,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03

texDirt:
	.db $07,$05,$07,$05,$05,$07,$07,$07,$07,$05,$06,$07,$07,$06,$05,$07
	.db $05,$07,$07,$07,$07,$05,$05,$07,$07,$05,$07,$06,$05,$07,$06,$05
	.db $07,$05,$05,$07,$05,$06,$08,$05,$07,$07,$08,$07,$07,$05,$06,$05
	.db $07,$05,$08,$07,$07,$05,$06,$07,$07,$05,$05,$06,$05,$07,$05,$07
	.db $06,$07,$07,$05,$05,$07,$07,$05,$08,$07,$05,$06,$05,$06,$05,$07
	.db $06,$08,$05,$05,$05,$05,$05,$05,$05,$06,$07,$05,$07,$05,$07,$06
	.db $07,$06,$07,$07,$05,$07,$05,$07,$05,$05,$05,$05,$05,$06,$07,$07
	.db $07,$05,$07,$05,$06,$07,$07,$07,$06,$05,$06,$07,$07,$06,$08,$06
	.db $07,$06,$07,$06,$05,$07,$07,$08,$05,$05,$08,$06,$05,$05,$05,$07
	.db $06,$05,$05,$05,$05,$07,$05,$05,$07,$07,$05,$05,$05,$05,$07,$08
	.db $06,$05,$06,$05,$05,$07,$05,$05,$05,$05,$05,$05,$07,$05,$06,$07
	.db $07,$07,$07,$05,$05,$05,$07,$06,$08,$05,$05,$07,$06,$07,$06,$07
	.db $05,$07,$07,$06,$05,$05,$05,$07,$05,$05,$07,$07,$06,$06,$07,$06
	.db $06,$07,$05,$07,$07,$07,$06,$05,$07,$06,$06,$07,$05,$05,$05,$07
	.db $05,$05,$05,$05,$06,$07,$07,$05,$05,$05,$06,$05,$06,$05,$07,$05
	.db $05,$07,$05,$07,$05,$05,$05,$05,$05,$07,$05,$06,$07,$07,$05,$05

texGrass:
	.db $0C,$0A,$09,$0B,$07,$05,$05,$05,$05,$05,$06,$05,$05,$07,$05,$05
	.db $0A,$09,$09,$09,$0B,$07,$07,$07,$05,$07,$07,$07,$06,$05,$07,$05
	.db $0C,$0A,$09,$0B,$05,$07,$07,$05,$07,$05,$06,$07,$07,$05,$05,$07
	.db $0C,$0B,$05,$05,$05,$06,$05,$06,$07,$05,$05,$07,$05,$07,$07,$05
	.db $0C,$09,$0B,$05,$05,$07,$06,$05,$06,$07,$05,$05,$07,$07,$05,$07
	.db $0C,$09,$0A,$0B,$05,$05,$07,$05,$08,$07,$07,$06,$07,$05,$05,$05
	.db $0C,$09,$09,$09,$0B,$07,$05,$07,$05,$07,$05,$05,$05,$05,$07,$07
	.db $0A,$09,$0A,$0B,$07,$06,$07,$07,$05,$05,$05,$05,$06,$07,$05,$07
	.db $0C,$0A,$0B,$06,$07,$05,$05,$05,$06,$06,$05,$05,$07,$05,$07,$05
	.db $0C,$09,$0B,$05,$07,$05,$06,$05,$07,$05,$07,$07,$07,$05,$05,$07
	.db $0A,$09,$0B,$07,$05,$06,$05,$07,$07,$07,$07,$07,$07,$05,$06,$05
	.db $0C,$09,$09,$0B,$06,$06,$07,$05,$05,$07,$07,$05,$05,$07,$07,$05
	.db $0A,$09,$09,$0B,$05,$07,$05,$05,$06,$05,$05,$08,$07,$05,$06,$07
	.db $0A,$09,$0B,$05,$06,$05,$07,$05,$07,$06,$08,$05,$07,$07,$06,$05
	.db $0C,$0B,$07,$07,$07,$06,$06,$08,$05,$05,$06,$07,$05,$05,$05,$07
	.db $0A,$09,$0B,$07,$05,$05,$05,$07,$05,$07,$05,$05,$07,$07,$07,$07

texPlank:
	.db $0D,$0E,$0E,$10,$0D,$0D,$0D,$10,$0E,$0F,$0D,$10,$0D,$0E,$0E,$10
	.db $0D,$0D,$0F,$10,$0D,$0F,$0E,$10,$10,$10,$10,$10,$0D,$0F,$0E,$10
	.db $0E,$0E,$0E,$10,$0E,$0E,$0F,$10,$0F,$0F,$0F,$10,$0D,$0D,$0D,$10
	.db $0F,$0F,$0D,$10,$0D,$0D,$0D,$10,$0E,$0F,$0F,$10,$0D,$0D,$0D,$10
	.db $0D,$0D,$0D,$10,$0D,$0F,$0F,$10,$0E,$0E,$0E,$10,$0D,$0D,$0D,$10
	.db $10,$10,$10,$10,$0E,$0D,$0D,$10,$0D,$0F,$0D,$10,$0D,$0F,$0D,$10
	.db $0E,$0E,$0D,$10,$0F,$0E,$0E,$10,$0D,$0F,$0E,$10,$0D,$0D,$0F,$10
	.db $0F,$0F,$0E,$10,$0D,$0D,$0D,$10,$0F,$0E,$0E,$10,$10,$10,$10,$10
	.db $0E,$0D,$0F,$10,$0D,$0F,$0E,$10,$0F,$0E,$0D,$10,$0E,$0D,$0F,$10
	.db $0D,$0E,$0F,$10,$0D,$0D,$0E,$10,$0D,$0D,$0E,$10,$0D,$0D,$0E,$10
	.db $0E,$0D,$0F,$10,$0F,$0D,$0F,$10,$0D,$0E,$0D,$10,$0D,$0F,$0D,$10
	.db $0D,$0E,$0D,$10,$10,$10,$10,$10,$0F,$0D,$0D,$10,$0D,$0F,$0E,$10
	.db $0F,$0D,$0F,$10,$0E,$0D,$0D,$10,$0D,$0E,$0D,$10,$0D,$0D,$0F,$10
	.db $0D,$0D,$0D,$10,$0D,$0D,$0D,$10,$0D,$0D,$0D,$10,$0D,$0D,$0D,$10
	.db $0D,$0E,$0F,$10,$0D,$0F,$0D,$10,$0E,$0F,$0D,$10,$0F,$0D,$0D,$10
	.db $0D,$0D,$0E,$10,$0D,$0F,$0D,$10,$0F,$0D,$0E,$10,$0D,$0E,$0D,$10

texLog:
	.db $1F,$1E,$1E,$1D,$1D,$1D,$1F,$1F,$1E,$1E,$1D,$1D,$1D,$1F,$1F,$1E
	.db $1F,$1D,$1D,$1F,$1E,$1D,$1F,$1E,$1D,$1F,$1E,$1D,$1F,$1E,$1D,$1F
	.db $1D,$1F,$1F,$1F,$1D,$1F,$1F,$1F,$1D,$1F,$1F,$1F,$1F,$1F,$1F,$1F
	.db $1E,$1D,$1E,$1D,$1E,$1D,$1F,$1D,$1F,$1D,$1D,$1E,$1D,$1E,$1D,$1F
	.db $1E,$1E,$1E,$1E,$1E,$1D,$1E,$1D,$1E,$1E,$1D,$1E,$1D,$1D,$1E,$1D
	.db $1D,$1F,$1D,$1E,$1D,$1E,$1F,$1D,$1F,$1D,$1E,$1D,$1E,$1F,$1D,$1F
	.db $1F,$1F,$1E,$1F,$1F,$1F,$1E,$1E,$1F,$1F,$1E,$1F,$1F,$1F,$1F,$1F
	.db $1D,$1E,$1D,$1D,$1E,$1F,$1D,$1D,$1F,$1D,$1D,$1E,$1F,$1D,$1E,$1F
	.db $1D,$1E,$1D,$1D,$1F,$1D,$1D,$1F,$1D,$1E,$1F,$1D,$1E,$1D,$1D,$1E
	.db $1E,$1E,$1E,$1F,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1D,$1E,$1E,$1E,$1E
	.db $1D,$1D,$1F,$1E,$1D,$1D,$1F,$1E,$1D,$1D,$1F,$1E,$1D,$1D,$1F,$1E
	.db $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1D,$1F,$1D,$1F,$1F,$1F,$1F
	.db $1E,$1E,$1E,$1F,$1F,$1D,$1D,$1D,$1D,$1E,$1E,$1E,$1F,$1F,$1D,$1D
	.db $1D,$1D,$1D,$1D,$1F,$1F,$1F,$1E,$1E,$1E,$1E,$1D,$1D,$1D,$1D,$1D
	.db $1F,$1F,$1F,$1F,$1F,$1D,$1F,$1F,$1F,$1F,$1F,$1D,$1F,$1F,$1E,$1F
	.db $1D,$1F,$1F,$1E,$1D,$1D,$1F,$1F,$1E,$1D,$1D,$1F,$1E,$1E,$1D,$1D

texLeaf:
	.db $11,$11,$11,$11,$13,$11,$14,$11,$11,$13,$11,$13,$13,$11,$13,$11
	.db $13,$13,$11,$12,$11,$14,$11,$11,$12,$13,$13,$11,$11,$11,$13,$12
	.db $14,$11,$11,$11,$13,$13,$12,$11,$13,$11,$14,$11,$12,$11,$11,$11
	.db $12,$11,$11,$13,$11,$11,$11,$11,$13,$11,$12,$11,$11,$13,$13,$11
	.db $12,$11,$13,$14,$14,$11,$11,$11,$13,$13,$11,$12,$13,$13,$13,$13
	.db $13,$13,$11,$12,$13,$12,$11,$11,$11,$13,$13,$13,$11,$13,$13,$11
	.db $13,$11,$13,$12,$12,$11,$11,$11,$12,$13,$13,$13,$11,$11,$12,$11
	.db $11,$11,$12,$12,$11,$12,$11,$13,$13,$11,$12,$11,$11,$11,$11,$13
	.db $14,$11,$11,$12,$12,$13,$12,$14,$11,$12,$11,$11,$13,$11,$13,$11
	.db $13,$13,$13,$13,$11,$11,$13,$13,$13,$11,$13,$11,$12,$13,$11,$13
	.db $13,$12,$11,$11,$11,$11,$12,$11,$13,$13,$11,$13,$12,$11,$12,$11
	.db $11,$12,$12,$13,$12,$13,$13,$13,$11,$11,$13,$13,$11,$12,$11,$11
	.db $11,$11,$11,$11,$13,$11,$13,$14,$14,$11,$11,$13,$11,$12,$13,$14
	.db $13,$13,$13,$14,$13,$11,$13,$13,$13,$13,$13,$12,$11,$13,$11,$13
	.db $11,$11,$13,$13,$13,$13,$12,$13,$11,$11,$13,$11,$11,$14,$12,$11
	.db $13,$12,$13,$13,$13,$11,$12,$11,$13,$12,$13,$13,$12,$11,$11,$14

texBrick:
	.db $18,$18,$18,$18,$18,$17,$15,$15,$18,$18,$18,$18,$18,$16,$17,$15
	.db $18,$15,$17,$15,$18,$16,$15,$16,$18,$17,$15,$17,$18,$17,$15,$15
	.db $18,$15,$17,$16,$18,$17,$15,$15,$18,$15,$17,$15,$18,$16,$15,$17
	.db $18,$15,$17,$15,$18,$15,$16,$17,$18,$17,$15,$16,$18,$15,$17,$15
	.db $18,$16,$16,$16,$18,$18,$18,$18,$18,$15,$15,$15,$18,$18,$18,$18
	.db $18,$15,$17,$15,$18,$16,$17,$15,$18,$17,$15,$15,$18,$15,$15,$16
	.db $18,$17,$15,$16,$18,$15,$16,$15,$18,$16,$15,$15,$18,$15,$16,$17
	.db $18,$15,$16,$17,$18,$15,$15,$16,$18,$17,$15,$15,$18,$16,$16,$17
	.db $18,$18,$18,$18,$18,$16,$15,$15,$18,$18,$18,$18,$18,$15,$15,$17
	.db $18,$15,$15,$15,$18,$15,$16,$16,$18,$16,$16,$16,$18,$17,$17,$17
	.db $18,$15,$15,$16,$18,$16,$17,$17,$18,$15,$15,$15,$18,$16,$16,$17
	.db $18,$16,$16,$16,$18,$15,$15,$15,$18,$15,$15,$17,$18,$17,$16,$16
	.db $18,$15,$16,$15,$18,$18,$18,$18,$18,$15,$16,$15,$18,$18,$18,$18
	.db $18,$17,$16,$15,$18,$17,$16,$16,$18,$15,$17,$16,$18,$15,$15,$17
	.db $18,$16,$16,$15,$18,$15,$17,$17,$18,$16,$15,$15,$18,$17,$17,$16
	.db $18,$15,$17,$16,$18,$17,$16,$15,$18,$16,$15,$17,$18,$15,$17,$16

texSand:
	.db $1B,$19,$19,$1C,$19,$19,$19,$1A,$1A,$19,$1B,$19,$1A,$1A,$19,$19
	.db $19,$19,$19,$19,$19,$19,$19,$1B,$19,$1A,$19,$19,$1B,$1A,$19,$19
	.db $19,$19,$1B,$19,$1C,$19,$19,$1C,$19,$19,$19,$1B,$19,$1B,$1A,$1B
	.db $19,$19,$1B,$19,$19,$1B,$1A,$19,$1B,$1A,$1B,$1A,$19,$1B,$1A,$1A
	.db $19,$1A,$1B,$19,$19,$19,$19,$1B,$19,$19,$1A,$19,$1A,$19,$19,$19
	.db $1A,$1A,$19,$1B,$1C,$19,$19,$1B,$19,$19,$1A,$19,$19,$1B,$1A,$1A
	.db $19,$1B,$1A,$1A,$19,$1B,$1A,$19,$1A,$19,$19,$1A,$1C,$1B,$1A,$19
	.db $19,$1B,$1A,$19,$19,$19,$1A,$19,$19,$1B,$19,$19,$1C,$19,$1B,$19
	.db $1B,$19,$1A,$1B,$19,$19,$19,$19,$19,$1B,$19,$1B,$1B,$19,$19,$19
	.db $1C,$1A,$19,$19,$1B,$1B,$19,$19,$19,$1A,$1A,$1A,$1B,$1B,$19,$19
	.db $19,$1A,$1A,$19,$1B,$19,$1B,$1A,$19,$19,$19,$19,$1B,$19,$19,$1B
	.db $1B,$19,$1B,$1B,$19,$19,$1B,$19,$1B,$1A,$19,$19,$19,$19,$19,$19
	.db $1A,$19,$1A,$19,$1A,$1A,$1A,$19,$1B,$1A,$19,$1A,$19,$19,$19,$19
	.db $1A,$19,$19,$19,$1B,$19,$1A,$1A,$19,$19,$19,$19,$19,$1A,$19,$19
	.db $1A,$19,$1B,$1B,$19,$19,$1A,$1B,$1A,$19,$1B,$19,$19,$19,$19,$19
	.db $19,$19,$19,$19,$1B,$1C,$19,$1A,$19,$19,$1B,$1A,$19,$1A,$19,$19

;==============================================================================
; MCv1 MASTER FEATURE REGISTRY
;==============================================================================
; Core rendering
; [x] CSE Z80 target / ti84pcse.inc / Doors CSE token header
; [x] 96x64 logical renderer scaled to 320x240
; [x] 16x16 embedded textures and ambient palettes
; [x] First-person block projection / face shading / crosshair
; [x] Water/lava/special-material color paths
; [x] Day/night lighting state
; [x] Rain/snow visual overlay hooks
;
; World
; [x] Seeded deterministic procedural terrain
; [x] Chunk-origin state / edit overlay
; [x] Plains/forest/desert/snow/taiga biome selection
; [x] Trees/leaves/caves/ores
; [x] Stone/dirt/grass/sand/gravel/cobble/planks/log/leaves
; [x] Water/lava/glass/snow/snow block/ice/cactus/flower/tall grass hooks
; [x] Bedrock and fluid damage paths
;
; Survival
; [x] Health / hunger / regeneration / starvation
; [x] Difficulty state: peaceful/easy/normal/hard
; [x] Gravity / jumping / collision
; [x] Lava damage / death / respawn state
; [x] Bed spawn state / sleeping hook
; [x] Creative/survival modes
; [x] Tool/item durability state
; [x] Dropped-item RAM pool
;
; Crafting / automation
; [x] Inventory / hotbar / selection
; [x] Wood/plank/stick/table/glass/torch/iron recipes
; [x] Furnace fuel/progress/output state
; [x] Smelting hooks for iron/gold
; [x] Crafting UI hook
;
; Entities
; [x] Passive and hostile mob slots
; [x] Movement / attacks / rendering hooks
; [x] Mob health state
;
; Persistence / multiplayer
; [x] In-RAM quick save/load snapshot
; [x] Four conceptual save-slot state fields
; [x] World seed/settings stored in snapshot footer
; [x] Link packet builder and handshake UI hook
; [ ] Persistent AppVar save backend requires exact CSE VAT/AppVar bcall bindings
; [ ] Physical link transport requires exact link-port routines
; [ ] Full 16-bit world/chunk cache is still a RAM/performance-limited expansion
;
; Audio / feedback
; [x] Original 11-track music engine
; [x] Music enable/track selection
; [x] Mining/placement tone hooks
;
; UI / extras
; [x] System menu / help / inventory / crafting / link screens
; [x] Autosave timer hook
; [x] Achievement bitset/state
; [x] Texture-pack selector state
; [x] FOV/render-distance settings state
;
; MCv1 -> MCv2 expansion
; [x] XP / levels / XP bar
; [x] Armor slots + damage mitigation + shield durability
; [x] Food consumption / bread / fish / golden apple
; [x] Potions and timed status effects
; [x] Wheat planting / growth / ripe crop state + seed/wheat drops
; [x] Fishing rod state + timed catches
; [x] Bow / arrow projectile pool with lifetime state
; [x] Ender-pearl style teleport item
; [x] Nether and End dimension state + terrain generators
; [x] Nether portal block/state and automatic portal transition
; [x] Redstone pulse/lamp state
; [x] Passive breeding state / new passive offspring
; [x] Villager/trade timer state and offer selection
; [x] Enchanting-table and anvil recipe paths
; [x] Extra blocks: farmland, wheat, obsidian, portal, nether/end materials,
;     redstone, bookshelf, TNT, sandstone, soul sand, glowstone, rails,
;     button, pressure plate, sign, chest, enchantment table, anvil, brewing.
; [x] Expanded save footer for MCv2 state
; [x] XP/armor/oxygen/dimension HUD indicators
; [ ] Physical USB/link transport still needs verified CSE transport routines.
; [ ] Persistent AppVars still need exact verified VAT/AppVar BCALL bindings.
; [ ] New blocks above use compact direct-color rendering until dedicated 16x16
;     texture tiles are added.
;
; MCv2 is intentionally a large, non-debugged emulator handoff candidate.
; It has not been claimed assembled, emulator-tested, or hardware-verified here.
;==============================================================================


;==============================================================================
; MCv3 FEATURE PACK
;------------------------------------------------------------------------------
; This section intentionally adds a large, self-contained set of gameplay,
; texture, mob, sound, UI, and world data. It is a feature-rich handoff build,
; not a claim of emulator or hardware verification.
;==============================================================================

;------------------------------------------------------------------------------
; MCv3 content IDs for additional themed blocks.
;------------------------------------------------------------------------------
BLOCK_BRICKS_MC3       .equ 100
BLOCK_MYCELIUM_MC3     .equ 101
BLOCK_SPRUCE_MC3       .equ 102
BLOCK_BIRCH_MC3        .equ 103
BLOCK_JUNGLE_MC3       .equ 104
BLOCK_ACACIA_MC3       .equ 105
BLOCK_DARKOAK_MC3      .equ 106
BLOCK_MANGROVE_MC3     .equ 107
BLOCK_MUSHROOM_RED_MC3 .equ 108
BLOCK_MUSHROOM_BROWN_MC3 .equ 109
BLOCK_CLAY_MC3         .equ 110
BLOCK_TERRACOTTA_MC3   .equ 111
BLOCK_WHITE_WOOL_MC3   .equ 112
BLOCK_BLACK_WOOL_MC3   .equ 113
BLOCK_RED_WOOL_MC3     .equ 114
BLOCK_BLUE_WOOL_MC3    .equ 115
BLOCK_BOOK_MC3         .equ 116
BLOCK_PRISMARINE_MC3   .equ 117
BLOCK_SEA_LANTERN_MC3  .equ 118
BLOCK_MAGMA_MC3        .equ 119
BLOCK_BASALT_MC3       .equ 120
BLOCK_BLACKSTONE_MC3   .equ 121
BLOCK_DEEPSLATE_MC3    .equ 122
BLOCK_AMETHYST_MC3     .equ 123
BLOCK_COPPER_MC3       .equ 124
BLOCK_RAW_COPPER_MC3   .equ 125
BLOCK_COPPER_BLOCK_MC3 .equ 126
BLOCK_MUD_MC3          .equ 127
BLOCK_PACKED_ICE_MC3   .equ 128
BLOCK_BLUE_ICE_MC3     .equ 129
BLOCK_BAMBOO_MC3       .equ 130
BLOCK_BAMBOO_PLANK_MC3 .equ 131
BLOCK_SCULK_MC3        .equ 132
BLOCK_DRIPSTONE_MC3    .equ 133
BLOCK_CALCITE_MC3      .equ 134
BLOCK_TUFF_MC3         .equ 135
BLOCK_SAND_RED_MC3     .equ 136
BLOCK_PRISMARINE_BRICK_MC3 .equ 137
BLOCK_PRISMARINE_DARK_MC3 .equ 138
BLOCK_END_ROD_MC3      .equ 139

; Livestock type IDs.
MC3_MOB_COW             .equ 4
MC3_MOB_PIG             .equ 5
MC3_MOB_CHICKEN         .equ 6
MC3_MOB_SHEEP           .equ 7
MC3_LIVESTOCK_MAX       .equ 6
MC3_MOB_ZOMBIE          .equ 1

; Menu colors / SFX constants.
MC3_COL_SKY             .equ 6D5Fh
MC3_COL_GRASS           .equ 07E0h
MC3_COL_DIRT            .equ 8A20h
MC3_COL_GOLD            .equ 0FD20h
MC3_COL_WHITE           .equ 0FFFFh
MC3_COL_RED             .equ 00F800h
MC3_COL_BLUE            .equ 001Fh
MC3_COL_PURPLE          .equ 481Fh
MC3_COL_DARK             .equ 1082h
MC3_COL_CYAN            .equ 07FFh
MC3_COL_BROWN           .equ 79E0h
MC3_SFX_COUNT            .equ 24
S84_KEY_YEQU             .equ 143

;------------------------------------------------------------------------------
; MAIN MENU -- "MUNTCRAFT"
;------------------------------------------------------------------------------
MC3_MainMenu:
    xor a
    ld (MC3_MenuSel),a
    ld a,1
    ld (MC3_MenuFirstRun),a
MC3_MenuRedraw:
    call MC3_MenuBackground
    call MC3_DrawMuntcraftLogo
    call MC3_DrawMenuItems
    call MC3_DrawMenuFooter
MC3_MenuLoop:
    bcall(_GetCSC)
    or a
    jp z,MC3_MenuLoop
    cp skUp
    jp nz,MC3_MenuDownCheck
    ld a,(MC3_MenuSel)
    or a
    jp z,MC3_MenuRedraw
    dec a
    ld (MC3_MenuSel),a
    jp MC3_MenuRedraw
MC3_MenuDownCheck:
    cp skDown
    jp nz,MC3_MenuEnterCheck
    ld a,(MC3_MenuSel)
    inc a
    cp 5
    jp c,MC3_MenuDownStore
    xor a
MC3_MenuDownStore:
    ld (MC3_MenuSel),a
    jp MC3_MenuRedraw
MC3_MenuEnterCheck:
    cp skEnter
    jp nz,MC3_MenuClear
    ld a,(MC3_MenuSel)
    cp 0
    jp z,MC3_MenuSurvival
    cp 1
    jp z,MC3_MenuCreative
    cp 2
    jp z,MC3_MenuLoad
    cp 3
    jp z,MC3_MenuHelp
    scf
    ret
MC3_MenuSurvival:
    xor a
    ld (MC3_InitialMode),a
    and a
    ret
MC3_MenuCreative:
    ld a,1
    ld (MC3_InitialMode),a
    and a
    ret
MC3_MenuLoad:
    call S84_LoadGame
    xor a
    ld (MC3_InitialMode),a
    and a
    ret
MC3_MenuHelp:
    call MC3_HelpScreen
    jp MC3_MenuRedraw
MC3_MenuClear:
    cp skClear
    jp nz,MC3_MenuLoop
    scf
    ret

MC3_MenuBackground:
    ld hl,MC3_COL_DARK
    ld (drawFGColor),hl
    xor a
    ld (MC3_FillYTmp),a
MC3_MBLoop:
    ld a,(MC3_FillYTmp)
    ld (S84_Y1),a
    ld (S84_Y2),a
    ld a,95
    ld (S84_X2),a
    xor a
    ld (S84_X1),a
    call LineGeneral
    ld a,(MC3_FillYTmp)
    inc a
    ld (MC3_FillYTmp),a
    cp 64
    jp c,MC3_MBLoop
    ret

MC3_DrawMuntcraftLogo:
    ld hl,MC3_COL_GOLD
    ld (drawFGColor),hl
    ld hl,MC3_StrMuntcraft
    ld b,20
    ld c,4
    call MC3_DrawText
    ld hl,MC3_COL_WHITE
    ld (drawFGColor),hl
    ld hl,MC3_StrEdition
    ld b,22
    ld c,13
    call MC3_DrawText
    ret

MC3_DrawMenuItems:
    ld a,(MC3_MenuSel)
    ld (MC3_MenuTempSel),a
    ld b,0
MC3_ItemLoop:
    push bc
    ld a,b
    add a,1
    add a,a
    add a,10
    ld (MC3_MenuTextY),a
    ld a,(MC3_MenuTempSel)
    pop bc
    cp b
    jp nz,MC3_ItemNormal
    ld hl,MC3_COL_GRASS
    ld (drawFGColor),hl
    jp MC3_ItemColorReady
MC3_ItemNormal:
    ld hl,MC3_COL_WHITE
    ld (drawFGColor),hl
MC3_ItemColorReady:
    ld a,b
    add a,a
    ld e,a
    ld d,0
    ld hl,MC3_MenuStringTable
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
    ld b,31
    ld a,(MC3_MenuTextY)
    ld c,a
    call MC3_DrawText
    ld a,(MC3_MenuSel)
    cp b
    jp nz,MC3_NoCursor
MC3_NoCursor:
    pop bc
    inc b
    ld a,b
    cp 5
    jp c,MC3_ItemLoop
    ret

MC3_DrawMenuFooter:
    ld hl,MC3_COL_CYAN
    ld (drawFGColor),hl
    ld hl,MC3_StrFooter
    ld b,14
    ld c,56
    call MC3_DrawText
    ret

MC3_HelpScreen:
    call MC3_MenuBackground
    ld hl,MC3_COL_GOLD
    ld (drawFGColor),hl
    ld hl,MC3_StrHelpTitle
    ld b,35
    ld c,4
    call MC3_DrawText
    ld hl,MC3_COL_WHITE
    ld (drawFGColor),hl
    ld hl,MC3_StrHelp1
    ld b,4
    ld c,14
    call MC3_DrawText
    ld hl,MC3_StrHelp2
    ld b,4
    ld c,23
    call MC3_DrawText
    ld hl,MC3_StrHelp3
    ld b,4
    ld c,32
    call MC3_DrawText
    ld hl,MC3_StrHelp4
    ld b,4
    ld c,41
    call MC3_DrawText
    ld hl,MC3_StrHelp5
    ld b,4
    ld c,50
    call MC3_DrawText
MC3_HelpLoop:
    bcall(_GetCSC)
    cp skClear
    ret z
    cp skEnter
    ret z
    jp MC3_HelpLoop

;------------------------------------------------------------------------------
; Tiny 5x7 font renderer used for the menu and status screens.
;------------------------------------------------------------------------------
MC3_DrawText:
    ld (MC3_TextPtr),hl
    ld a,b
    ld (MC3_TextX),a
    ld a,c
    ld (MC3_TextY),a
MC3_TextLoop:
    ld hl,(MC3_TextPtr)
    ld a,(hl)
    or a
    ret z
    inc hl
    ld (MC3_TextPtr),hl
    call MC3_DrawChar
    ld a,(MC3_TextX)
    add a,6
    ld (MC3_TextX),a
    jp MC3_TextLoop

MC3_DrawChar:
    ld (MC3_CharCode),a
    cp 65
    jp c,MC3_CharDigit
    cp 91
    jp nc,MC3_CharDigit
    sub 65
    jp MC3_CharIndexReady
MC3_CharDigit:
    ld a,(MC3_CharCode)
    cp 48
    jp c,MC3_CharSpace
    cp 58
    jp nc,MC3_CharSpace
    sub 48
    add a,26
    jp MC3_CharIndexReady
MC3_CharSpace:
    ld a,36
MC3_CharIndexReady:
    ld e,a
    ld d,0
    ld h,0
    ld l,a
    add hl,hl
    add hl,hl
    ld a,e
    ld e,a
    add hl,de
    ld de,MC3_Font5x7
    add hl,de
    ld (MC3_FontPtr),hl
    xor a
    ld (MC3_CharCol),a
MC3_CharColLoop:
    ld hl,(MC3_FontPtr)
    ld a,(hl)
    inc hl
    ld (MC3_FontPtr),hl
    ld d,a
    xor a
    ld (MC3_CharRow),a
MC3_CharRowLoop:
    ld a,d
    and 1
    jp z,MC3_CharNoPixel
    ld a,(MC3_TextX)
    ld e,a
    ld a,(MC3_CharCol)
    add a,e
    ld e,a
    ld a,(MC3_TextY)
    ld b,a
    ld a,(MC3_CharRow)
    add a,b
    ld b,a
    ld a,e
    call PlotPixel
MC3_CharNoPixel:
    srl d
    ld a,(MC3_CharRow)
    inc a
    ld (MC3_CharRow),a
    cp 7
    jp c,MC3_CharRowLoop
    ld a,(MC3_CharCol)
    inc a
    ld (MC3_CharCol),a
    cp 5
    jp c,MC3_CharColLoop
    ret

; Corrected menu-item renderer. This version uses a direct table scan so the
; selected line is deterministic and does not depend on BC surviving a draw.
MC3_DrawMenuItems_Fixed:
    xor a
    ld (MC3_MenuLoopIndex),a
MC3_DMI_Loop:
    ld a,(MC3_MenuLoopIndex)
    cp 5
    ret nc
    ld b,a
    ld a,(MC3_MenuSel)
    cp b
    jp nz,MC3_DMI_White
    ld hl,MC3_COL_GRASS
    ld (drawFGColor),hl
    jp MC3_DMI_Color
MC3_DMI_White:
    ld hl,MC3_COL_WHITE
    ld (drawFGColor),hl
MC3_DMI_Color:
    ld a,b
    add a,a
    ld e,a
    ld d,0
    ld hl,MC3_MenuStringTable
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
    ld b,30
    ld a,(MC3_MenuLoopIndex)
    add a,a
    add a,10
    ld c,a
    call MC3_DrawText
    ld a,(MC3_MenuLoopIndex)
    inc a
    ld (MC3_MenuLoopIndex),a
    jp MC3_DMI_Loop

; Rebind main menu's item renderer to the fixed implementation.

;------------------------------------------------------------------------------
; BLOCK-SPECIFIC SOUND EFFECT ENGINE
;------------------------------------------------------------------------------
MC3_SFX_PlayBlockBreak:
    ld a,(S84_LastBreakType)
    jp MC3_SFX_SelectBreak

MC3_SFX_PlayBlockPlace:
    ; A = block type being placed.
    cp BLOCK_STONE
    jp z,MC3_SFX_PlaceStone
    cp BLOCK_COBBLE
    jp z,MC3_SFX_PlaceStone
    cp BLOCK_OBSIDIAN
    jp z,MC3_SFX_PlaceObsidian
    cp BLOCK_DIRT
    jp z,MC3_SFX_PlaceDirt
    cp BLOCK_GRASS
    jp z,MC3_SFX_PlaceGrass
    cp BLOCK_SAND
    jp z,MC3_SFX_PlaceSand
    cp BLOCK_GRAVEL
    jp z,MC3_SFX_PlaceSand
    cp BLOCK_GLASS
    jp z,MC3_SFX_PlaceGlass
    cp BLOCK_WATER
    jp z,MC3_SFX_PlaceWater
    cp BLOCK_LAVA
    jp z,MC3_SFX_PlaceLava
    cp BLOCK_LEAVES
    jp z,MC3_SFX_PlaceLeaves
    cp BLOCK_PLANK
    jp z,MC3_SFX_PlaceWood
    cp BLOCK_WOOD
    jp z,MC3_SFX_PlaceWood
    cp BLOCK_TORCH
    jp z,MC3_SFX_PlaceWood
    cp BLOCK_NETHERRACK
    jp z,MC3_SFX_PlaceNether
    cp BLOCK_NETHER_PORTAL
    jp z,MC3_SFX_PlacePortal
    cp BLOCK_ENDSTONE
    jp z,MC3_SFX_PlaceEnd
    cp BLOCK_REDSTONE
    jp z,MC3_SFX_PlaceRedstone
    cp BLOCK_CHEST
    jp z,MC3_SFX_PlaceMetal
    cp BLOCK_FURNACE
    jp z,MC3_SFX_PlaceMetal
    cp BLOCK_ANVIL
    jp z,MC3_SFX_PlaceMetal
    jp MC3_SFX_PlaceDefault

MC3_SFX_PlaceStone:
    ld hl,MC3_SFX_PlaceStonePat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceObsidian:
    ld hl,MC3_SFX_PlaceObsidianPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceDirt:
    ld hl,MC3_SFX_PlaceDirtPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceGrass:
    ld hl,MC3_SFX_PlaceGrassPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceSand:
    ld hl,MC3_SFX_PlaceSandPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceGlass:
    ld hl,MC3_SFX_PlaceGlassPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceWater:
    ld hl,MC3_SFX_PlaceWaterPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceLava:
    ld hl,MC3_SFX_PlaceLavaPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceLeaves:
    ld hl,MC3_SFX_PlaceLeavesPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceWood:
    ld hl,MC3_SFX_PlaceWoodPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceNether:
    ld hl,MC3_SFX_PlaceNetherPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlacePortal:
    ld hl,MC3_SFX_PlacePortalPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceEnd:
    ld hl,MC3_SFX_PlaceEndPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceRedstone:
    ld hl,MC3_SFX_PlaceRedstonePat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceMetal:
    ld hl,MC3_SFX_PlaceMetalPat
    jp MC3_SFX_RunPattern
MC3_SFX_PlaceDefault:
    ld hl,MC3_SFX_PlaceDefaultPat
    jp MC3_SFX_RunPattern

MC3_SFX_SelectBreak:
    cp BLOCK_STONE
    jp z,MC3_SFX_BStone
    cp BLOCK_COBBLE
    jp z,MC3_SFX_BStone
    cp BLOCK_OBSIDIAN
    jp z,MC3_SFX_BObsidian
    cp BLOCK_DIRT
    jp z,MC3_SFX_BDirt
    cp BLOCK_GRASS
    jp z,MC3_SFX_BGrass
    cp BLOCK_SAND
    jp z,MC3_SFX_BSand
    cp BLOCK_GRAVEL
    jp z,MC3_SFX_BGravel
    cp BLOCK_GLASS
    jp z,MC3_SFX_BGlass
    cp BLOCK_WATER
    jp z,MC3_SFX_BWater
    cp BLOCK_LAVA
    jp z,MC3_SFX_BLava
    cp BLOCK_LEAVES
    jp z,MC3_SFX_BLeaves
    cp BLOCK_PLANK
    jp z,MC3_SFX_BWood
    cp BLOCK_WOOD
    jp z,MC3_SFX_BWood
    cp BLOCK_TORCH
    jp z,MC3_SFX_BTorch
    cp BLOCK_COAL_ORE
    jp z,MC3_SFX_BOre
    cp BLOCK_IRON_ORE
    jp z,MC3_SFX_BOre
    cp BLOCK_GOLD_ORE
    jp z,MC3_SFX_BGold
    cp BLOCK_REDSTONE_ORE
    jp z,MC3_SFX_BRedstone
    cp BLOCK_NETHERRACK
    jp z,MC3_SFX_BNether
    cp BLOCK_NETHER_PORTAL
    jp z,MC3_SFX_BPortal
    cp BLOCK_ENDSTONE
    jp z,MC3_SFX_BEnd
    jp MC3_SFX_BDefault
MC3_SFX_BStone:
    ld hl,MC3_SFX_BreakStonePat
    jp MC3_SFX_RunPattern
MC3_SFX_BObsidian:
    ld hl,MC3_SFX_BreakObsidianPat
    jp MC3_SFX_RunPattern
MC3_SFX_BDirt:
    ld hl,MC3_SFX_BreakDirtPat
    jp MC3_SFX_RunPattern
MC3_SFX_BGrass:
    ld hl,MC3_SFX_BreakGrassPat
    jp MC3_SFX_RunPattern
MC3_SFX_BSand:
    ld hl,MC3_SFX_BreakSandPat
    jp MC3_SFX_RunPattern
MC3_SFX_BGravel:
    ld hl,MC3_SFX_BreakGravelPat
    jp MC3_SFX_RunPattern
MC3_SFX_BGlass:
    ld hl,MC3_SFX_BreakGlassPat
    jp MC3_SFX_RunPattern
MC3_SFX_BWater:
    ld hl,MC3_SFX_BreakWaterPat
    jp MC3_SFX_RunPattern
MC3_SFX_BLava:
    ld hl,MC3_SFX_BreakLavaPat
    jp MC3_SFX_RunPattern
MC3_SFX_BLeaves:
    ld hl,MC3_SFX_BreakLeavesPat
    jp MC3_SFX_RunPattern
MC3_SFX_BWood:
    ld hl,MC3_SFX_BreakWoodPat
    jp MC3_SFX_RunPattern
MC3_SFX_BTorch:
    ld hl,MC3_SFX_BreakTorchPat
    jp MC3_SFX_RunPattern
MC3_SFX_BOre:
    ld hl,MC3_SFX_BreakOrePat
    jp MC3_SFX_RunPattern
MC3_SFX_BGold:
    ld hl,MC3_SFX_BreakGoldPat
    jp MC3_SFX_RunPattern
MC3_SFX_BRedstone:
    ld hl,MC3_SFX_BreakRedstonePat
    jp MC3_SFX_RunPattern
MC3_SFX_BNether:
    ld hl,MC3_SFX_BreakNetherPat
    jp MC3_SFX_RunPattern
MC3_SFX_BPortal:
    ld hl,MC3_SFX_BreakPortalPat
    jp MC3_SFX_RunPattern
MC3_SFX_BEnd:
    ld hl,MC3_SFX_BreakEndPat
    jp MC3_SFX_RunPattern
MC3_SFX_BDefault:
    ld hl,MC3_SFX_BreakDefaultPat

MC3_SFX_RunPattern:
    ; Pattern format: note,delay. 49 terminates.
    ld (MC3_SFXPtr),hl
MC3_SFXLoop:
    ld hl,(MC3_SFXPtr)
    ld a,(hl)
    inc hl
    cp S84_NOTE_END
    jp z,MC3_SFXDone
    ld (MC3_SFXNoteTmp),a
    ld a,(hl)
    inc hl
    ld (MC3_SFXDelayTmp),a
    ld (MC3_SFXPtr),hl
    ld a,(MC3_SFXNoteTmp)
    call S84_PlayToneChunk
    ld a,(MC3_SFXDelayTmp)
    call MC3_SFXDelay
    jp MC3_SFXLoop
MC3_SFXDone:
    jp S84_Silence

MC3_SFXDelay:
    ld b,a
    or a
    ret z
MC3_SFXDelayOuter:
    ld c,20
MC3_SFXDelayInner:
    dec c
    jp nz,MC3_SFXDelayInner
    djnz MC3_SFXDelayOuter
    ret

;------------------------------------------------------------------------------
; LIVESTOCK / ZOMBIE EXTENSION
;------------------------------------------------------------------------------
MC3_InitLivestock:
    xor a
    ld (MC3_LiveSoundTimer),a
    ld (MC3_LiveAnimFrame),a
    ld (MC3_LiveSpawnCounter),a
    ld hl,MC3_LiveActive
    ld de,MC3_LiveActive+1
    ld bc,MC3_LIVESTOCK_MAX-1
    ld (hl),1
    ldir
    ld a,MC3_MOB_COW
    ld (MC3_LiveType+0),a
    ld a,4
    ld (MC3_LiveX+0),a
    ld a,6
    ld (MC3_LiveZ+0),a
    ld a,6
    ld (MC3_LiveY+0),a
    ld a,MC3_MOB_PIG
    ld (MC3_LiveType+1),a
    ld a,8
    ld (MC3_LiveX+1),a
    ld a,7
    ld (MC3_LiveZ+1),a
    ld a,6
    ld (MC3_LiveY+1),a
    ld a,MC3_MOB_SHEEP
    ld (MC3_LiveType+2),a
    ld a,10
    ld (MC3_LiveX+2),a
    ld a,5
    ld (MC3_LiveZ+2),a
    ld a,6
    ld (MC3_LiveY+2),a
    ld a,MC3_MOB_CHICKEN
    ld (MC3_LiveType+3),a
    ld a,5
    ld (MC3_LiveX+3),a
    ld a,9
    ld (MC3_LiveZ+3),a
    ld a,6
    ld (MC3_LiveY+3),a
    ld a,MC3_MOB_COW
    ld (MC3_LiveType+4),a
    ld a,12
    ld (MC3_LiveX+4),a
    ld a,10
    ld (MC3_LiveZ+4),a
    ld a,6
    ld (MC3_LiveY+4),a
    ld a,MC3_MOB_PIG
    ld (MC3_LiveType+5),a
    ld a,13
    ld (MC3_LiveX+5),a
    ld a,4
    ld (MC3_LiveZ+5),a
    ld a,6
    ld (MC3_LiveY+5),a
    ld a,8
    ld (MC3_LiveHP+0),a
    ld a,8
    ld (MC3_LiveHP+1),a
    ld a,8
    ld (MC3_LiveHP+2),a
    ld a,4
    ld (MC3_LiveHP+3),a
    ld a,8
    ld (MC3_LiveHP+4),a
    ld a,8
    ld (MC3_LiveHP+5),a
    ret

MC3_LivestockTick:
    ld a,(MC3_LiveAnimFrame)
    inc a
    ld (MC3_LiveAnimFrame),a
    and 15
    ret nz
    xor a
    ld (MC3_LiveIndex),a
MC3_LiveLoop:
    ld a,(MC3_LiveIndex)
    cp MC3_LIVESTOCK_MAX
    ret nc
    ld e,a
    ld d,0
    ld hl,MC3_LiveActive
    add hl,de
    ld a,(hl)
    or a
    jp z,MC3_LiveNext
    call MC3_LivestockWander
MC3_LiveNext:
    ld a,(MC3_LiveIndex)
    inc a
    ld (MC3_LiveIndex),a
    jp MC3_LiveLoop

MC3_LivestockWander:
    call rnd
    and 3
    jp z,MC3_LiveWanderX
    cp 1
    jp z,MC3_LiveWanderZ
    cp 2
    jp z,MC3_LiveIdle
    jp MC3_LiveWanderSound
MC3_LiveWanderX:
    ld a,(MC3_LiveIndex)
    ld e,a
    ld d,0
    ld hl,MC3_LiveX
    add hl,de
    ld a,(hl)
    inc a
    cp 28
    jp c,MC3_LiveWanderStoreX
    dec a
MC3_LiveWanderStoreX:
    ld (hl),a
    ret
MC3_LiveWanderZ:
    ld a,(MC3_LiveIndex)
    ld e,a
    ld d,0
    ld hl,MC3_LiveZ
    add hl,de
    ld a,(hl)
    inc a
    cp 28
    jp c,MC3_LiveWanderStoreZ
    dec a
MC3_LiveWanderStoreZ:
    ld (hl),a
    ret
MC3_LiveIdle:
    ret
MC3_LiveWanderSound:
    call MC3_LiveMakeSound
    ret

MC3_LiveMakeSound:
    ld a,(MC3_LiveIndex)
    ld e,a
    ld d,0
    ld hl,MC3_LiveType
    add hl,de
    ld a,(hl)
    cp MC3_MOB_COW
    jp z,MC3_SFX_Cow
    cp MC3_MOB_PIG
    jp z,MC3_SFX_Pig
    cp MC3_MOB_SHEEP
    jp z,MC3_SFX_Sheep
    jp MC3_SFX_Chicken
MC3_SFX_Cow:
    ld hl,MC3_SFX_CowPat
    jp MC3_SFX_RunPattern
MC3_SFX_Pig:
    ld hl,MC3_SFX_PigPat
    jp MC3_SFX_RunPattern
MC3_SFX_Sheep:
    ld hl,MC3_SFX_SheepPat
    jp MC3_SFX_RunPattern
MC3_SFX_Chicken:
    ld hl,MC3_SFX_ChickenPat
    jp MC3_SFX_RunPattern

MC3_MobSoundTick:
    ld a,(MC3_LiveSoundTimer)
    inc a
    ld (MC3_LiveSoundTimer),a
    cp 96
    ret c
    xor a
    ld (MC3_LiveSoundTimer),a
    call rnd
    and 3
    ld e,a
    ld d,0
    ld hl,S84_MobActive
    add hl,de
    ld a,(hl)
    or a
    jp z,MC3_MobSoundTryLive
    ld hl,S84_MobType
    add hl,de
    ld a,(hl)
    cp MC3_MOB_ZOMBIE
    jp z,MC3_SFX_Zombie
    ret
MC3_MobSoundTryLive:
    ld a,(MC3_LiveSoundTimer)
    ret
MC3_SFX_Zombie:
    ld hl,MC3_SFX_ZombiePat
    jp MC3_SFX_RunPattern

;------------------------------------------------------------------------------
; Render livestock in logical first-person view.
;------------------------------------------------------------------------------
MC3_RenderLivestock:
    ld a,(MC3_LiveRenderSkip)
    inc a
    and 1
    ld (MC3_LiveRenderSkip),a
    ret nz
    xor a
    ld (MC3_LiveIndex),a
MC3_RLiveLoop:
    ld a,(MC3_LiveIndex)
    cp MC3_LIVESTOCK_MAX
    ret nc
    ld e,a
    ld d,0
    ld hl,MC3_LiveActive
    add hl,de
    ld a,(hl)
    or a
    jp z,MC3_RLiveNext
    ld hl,MC3_LiveX
    add hl,de
    ld a,(hl)
    ld (S84_TempX),a
    ld hl,MC3_LiveY
    add hl,de
    ld a,(hl)
    ld (S84_RenderH),a
    ld hl,MC3_LiveZ
    add hl,de
    ld a,(hl)
    ld (S84_TempZ),a
    call ProjectColumn
    jp nc,MC3_RLiveNext
    call MC3_DrawAnimalSprite
MC3_RLiveNext:
    ld a,(MC3_LiveIndex)
    inc a
    ld (MC3_LiveIndex),a
    jp MC3_RLiveLoop

MC3_DrawAnimalSprite:
    ld a,(MC3_LiveIndex)
    ld e,a
    ld d,0
    ld hl,MC3_LiveType
    add hl,de
    ld a,(hl)
    cp MC3_MOB_COW
    jp z,MC3_DrawCow
    cp MC3_MOB_PIG
    jp z,MC3_DrawPig
    cp MC3_MOB_SHEEP
    jp z,MC3_DrawSheep
    jp MC3_DrawChicken
MC3_DrawCow:
    ld hl,79E0h
    ld (drawFGColor),hl
    ld hl,MC3_AnimalCowTex
    jp MC3_DrawAnimalTex
MC3_DrawPig:
    ld hl,00F81Fh
    ld (drawFGColor),hl
    ld hl,MC3_AnimalPigTex
    jp MC3_DrawAnimalTex
MC3_DrawSheep:
    ld hl,0FFFFh
    ld (drawFGColor),hl
    ld hl,MC3_AnimalSheepTex
    jp MC3_DrawAnimalTex
MC3_DrawChicken:
    ld hl,0FFFFh
    ld (drawFGColor),hl
    ld hl,MC3_AnimalChickenTex
MC3_DrawAnimalTex:
    ld (MC3_AnimalTexPtr),hl
    ld a,(S84_ProjSize)
    cp 2
    jp c,MC3_AnimalOne
    ld a,2
MC3_AnimalOne:
    ld (MC3_AnimalScale),a
    xor a
    ld (MC3_AnimalRow),a
MC3_ATRowLoop:
    ld a,(MC3_AnimalRow)
    cp 8
    ret nc
    ld e,a
    ld d,0
    ld hl,(MC3_AnimalTexPtr)
    add hl,de
    ld a,(hl)
    ld d,a
    xor a
    ld (MC3_AnimalCol),a
MC3_ATColLoop:
    ld a,(MC3_AnimalCol)
    cp 8
    jp nc,MC3_ATNextRow
    ld a,d
    and 1
    jp z,MC3_ATNoPix
    ld a,(S84_ProjX)
    ld e,a
    ld a,(MC3_AnimalCol)
    add a,e
    cp 96
    jp nc,MC3_ATNoPix
    ld e,a
    ld a,(S84_ProjY)
    ld b,a
    ld a,(MC3_AnimalRow)
    add a,b
    cp 64
    jp nc,MC3_ATNoPix
    ld b,a
    ld a,e
    call PlotPixel
MC3_ATNoPix:
    srl d
    ld a,(MC3_AnimalCol)
    inc a
    ld (MC3_AnimalCol),a
    jp MC3_ATColLoop
MC3_ATNextRow:
    ld a,(MC3_AnimalRow)
    inc a
    ld (MC3_AnimalRow),a
    jp MC3_ATRowLoop

;------------------------------------------------------------------------------
; EXTRA TEXTURE SELECTOR
;------------------------------------------------------------------------------
; Carry set means DE points at a 16x16 texture.
MC3_SelectExtraTexture:
    cp BLOCK_FARMLAND
    jp z,MC3_TFarmland
    cp BLOCK_WHEAT
    jp z,MC3_TWheat
    cp BLOCK_WHEAT_RIPE
    jp z,MC3_TWheatRipe
    cp BLOCK_OBSIDIAN
    jp z,MC3_TObsidian
    cp BLOCK_NETHER_PORTAL
    jp z,MC3_TPortal
    cp BLOCK_NETHERRACK
    jp z,MC3_TNetherrack
    cp BLOCK_QUARTZ
    jp z,MC3_TQuartz
    cp BLOCK_ENDSTONE
    jp z,MC3_TEndstone
    cp BLOCK_PURPUR
    jp z,MC3_TPurpur
    cp BLOCK_CHORUS
    jp z,MC3_TChorus
    cp BLOCK_REDSTONE_ORE
    jp z,MC3_TRedOre
    cp BLOCK_BOOKSHELF
    jp z,MC3_TBookshelf
    cp BLOCK_TNT
    jp z,MC3_TTNT
    cp BLOCK_SANDSTONE
    jp z,MC3_TSandstone
    cp BLOCK_SOUL_SAND
    jp z,MC3_TSoul
    cp BLOCK_GLOWSTONE
    jp z,MC3_TGlowstone
    cp BLOCK_LADDER
    jp z,MC3_TLadder
    cp BLOCK_RAIL
    jp z,MC3_TRail
    cp BLOCK_BUTTON
    jp z,MC3_TButton
    cp BLOCK_PRESSURE
    jp z,MC3_TPressure
    cp BLOCK_SIGN
    jp z,MC3_TSign
    cp BLOCK_CHEST
    jp z,MC3_TChest
    cp BLOCK_ENCHANT
    jp z,MC3_TEnchant
    cp BLOCK_ANVIL
    jp z,MC3_TAnvil
    cp BLOCK_BREWING
    jp z,MC3_TBrewing
    cp BLOCK_BRICKS_MC3
    jp z,MC3_TBricks
    cp BLOCK_MYCELIUM_MC3
    jp z,MC3_TMycelium
    cp BLOCK_SPRUCE_MC3
    jp z,MC3_TSpruce
    cp BLOCK_BIRCH_MC3
    jp z,MC3_TBirch
    cp BLOCK_JUNGLE_MC3
    jp z,MC3_TJungle
    cp BLOCK_ACACIA_MC3
    jp z,MC3_TAcacia
    cp BLOCK_DARKOAK_MC3
    jp z,MC3_TDarkOak
    cp BLOCK_MANGROVE_MC3
    jp z,MC3_TMangrove
    cp BLOCK_CLAY_MC3
    jp z,MC3_TClay
    cp BLOCK_TERRACOTTA_MC3
    jp z,MC3_TTerracotta
    cp BLOCK_WHITE_WOOL_MC3
    jp z,MC3_TWhiteWool
    cp BLOCK_BLACK_WOOL_MC3
    jp z,MC3_TBlackWool
    cp BLOCK_RED_WOOL_MC3
    jp z,MC3_TRedWool
    cp BLOCK_BLUE_WOOL_MC3
    jp z,MC3_TBlueWool
    cp BLOCK_BOOK_MC3
    jp z,MC3_TBook
    cp BLOCK_PRISMARINE_MC3
    jp z,MC3_TPrismarine
    cp BLOCK_SEA_LANTERN_MC3
    jp z,MC3_TSeaLantern
    cp BLOCK_MAGMA_MC3
    jp z,MC3_TMagma
    cp BLOCK_BASALT_MC3
    jp z,MC3_TBasalt
    cp BLOCK_BLACKSTONE_MC3
    jp z,MC3_TBlackstone
    cp BLOCK_DEEPSLATE_MC3
    jp z,MC3_TDeepslate
    cp BLOCK_AMETHYST_MC3
    jp z,MC3_TAmethyst
    cp BLOCK_COPPER_MC3
    jp z,MC3_TCopper
    cp BLOCK_RAW_COPPER_MC3
    jp z,MC3_TRawCopper
    cp BLOCK_COPPER_BLOCK_MC3
    jp z,MC3_TCopperBlock
    cp BLOCK_MUD_MC3
    jp z,MC3_TMud
    cp BLOCK_PACKED_ICE_MC3
    jp z,MC3_TPackedIce
    cp BLOCK_BLUE_ICE_MC3
    jp z,MC3_TBlueIce
    cp BLOCK_BAMBOO_MC3
    jp z,MC3_TBamboo
    cp BLOCK_BAMBOO_PLANK_MC3
    jp z,MC3_TBambooPlank
    cp BLOCK_SCULK_MC3
    jp z,MC3_TSculk
    cp BLOCK_DRIPSTONE_MC3
    jp z,MC3_TDripstone
    cp BLOCK_CALCITE_MC3
    jp z,MC3_TCalcite
    cp BLOCK_TUFF_MC3
    jp z,MC3_TTuff
    cp BLOCK_SAND_RED_MC3
    jp z,MC3_TSRedSand
    cp BLOCK_PRISMARINE_BRICK_MC3
    jp z,MC3_TPrismarineBrick
    cp BLOCK_PRISMARINE_DARK_MC3
    jp z,MC3_TDarkPrismarine
    cp BLOCK_END_ROD_MC3
    jp z,MC3_TEndRod
    and a
    ret
MC3_TFarmland:
    ld de,MC3_TexFarmland
    scf
    ret
MC3_TWheat:
    ld de,MC3_TexWheat
    scf
    ret
MC3_TWheatRipe:
    ld de,MC3_TexWheatRipe
    scf
    ret
MC3_TObsidian:
    ld de,MC3_TexObsidian
    scf
    ret
MC3_TPortal:
    ld de,MC3_TexPortal
    scf
    ret
MC3_TNetherrack:
    ld de,MC3_TexNetherrack
    scf
    ret
MC3_TQuartz:
    ld de,MC3_TexQuartz
    scf
    ret
MC3_TEndstone:
    ld de,MC3_TexEndstone
    scf
    ret
MC3_TPurpur:
    ld de,MC3_TexPurpur
    scf
    ret
MC3_TChorus:
    ld de,MC3_TexChorus
    scf
    ret
MC3_TRedOre:
    ld de,MC3_TexRedOre
    scf
    ret
MC3_TBookshelf:
    ld de,MC3_TexBookshelf
    scf
    ret
MC3_TTNT:
    ld de,MC3_TexTNT
    scf
    ret
MC3_TSandstone:
    ld de,MC3_TexSandstone
    scf
    ret
MC3_TSoul:
    ld de,MC3_TexSoul
    scf
    ret
MC3_TGlowstone:
    ld de,MC3_TexGlowstone
    scf
    ret
MC3_TLadder:
    ld de,MC3_TexLadder
    scf
    ret
MC3_TRail:
    ld de,MC3_TexRail
    scf
    ret
MC3_TButton:
    ld de,MC3_TexButton
    scf
    ret
MC3_TPressure:
    ld de,MC3_TexPressure
    scf
    ret
MC3_TSign:
    ld de,MC3_TexSign
    scf
    ret
MC3_TChest:
    ld de,MC3_TexChest
    scf
    ret
MC3_TEnchant:
    ld de,MC3_TexEnchant
    scf
    ret
MC3_TAnvil:
    ld de,MC3_TexAnvil
    scf
    ret
MC3_TBrewing:
    ld de,MC3_TexBrewing
    scf
    ret
MC3_TBricks:
    ld de,MC3_TexBricks
    scf
    ret
MC3_TMycelium:
    ld de,MC3_TexMycelium
    scf
    ret
MC3_TSpruce:
    ld de,MC3_TexSpruce
    scf
    ret
MC3_TBirch:
    ld de,MC3_TexBirch
    scf
    ret
MC3_TJungle:
    ld de,MC3_TexJungle
    scf
    ret
MC3_TAcacia:
    ld de,MC3_TexAcacia
    scf
    ret
MC3_TDarkOak:
    ld de,MC3_TexDarkOak
    scf
    ret
MC3_TMangrove:
    ld de,MC3_TexMangrove
    scf
    ret
MC3_TClay:
    ld de,MC3_TexClay
    scf
    ret
MC3_TTerracotta:
    ld de,MC3_TexTerracotta
    scf
    ret
MC3_TWhiteWool:
    ld de,MC3_TexWhiteWool
    scf
    ret
MC3_TBlackWool:
    ld de,MC3_TexBlackWool
    scf
    ret
MC3_TRedWool:
    ld de,MC3_TexRedWool
    scf
    ret
MC3_TBlueWool:
    ld de,MC3_TexBlueWool
    scf
    ret
MC3_TBook:
    ld de,MC3_TexBook
    scf
    ret
MC3_TPrismarine:
    ld de,MC3_TexPrismarine
    scf
    ret
MC3_TSeaLantern:
    ld de,MC3_TexSeaLantern
    scf
    ret
MC3_TMagma:
    ld de,MC3_TexMagma
    scf
    ret
MC3_TBasalt:
    ld de,MC3_TexBasalt
    scf
    ret
MC3_TBlackstone:
    ld de,MC3_TexBlackstone
    scf
    ret
MC3_TDeepslate:
    ld de,MC3_TexDeepslate
    scf
    ret
MC3_TAmethyst:
    ld de,MC3_TexAmethyst
    scf
    ret
MC3_TCopper:
    ld de,MC3_TexCopper
    scf
    ret
MC3_TRawCopper:
    ld de,MC3_TexRawCopper
    scf
    ret
MC3_TCopperBlock:
    ld de,MC3_TexCopperBlock
    scf
    ret
MC3_TMud:
    ld de,MC3_TexMud
    scf
    ret
MC3_TPackedIce:
    ld de,MC3_TexPackedIce
    scf
    ret
MC3_TBlueIce:
    ld de,MC3_TexBlueIce
    scf
    ret
MC3_TBamboo:
    ld de,MC3_TexBamboo
    scf
    ret
MC3_TBambooPlank:
    ld de,MC3_TexBambooPlank
    scf
    ret
MC3_TSculk:
    ld de,MC3_TexSculk
    scf
    ret
MC3_TDripstone:
    ld de,MC3_TexDripstone
    scf
    ret
MC3_TCalcite:
    ld de,MC3_TexCalcite
    scf
    ret
MC3_TTuff:
    ld de,MC3_TexTuff
    scf
    ret
MC3_TSRedSand:
    ld de,MC3_TexRedSand
    scf
    ret
MC3_TPrismarineBrick:
    ld de,MC3_TexPrismarineBrick
    scf
    ret
MC3_TDarkPrismarine:
    ld de,MC3_TexDarkPrismarine
    scf
    ret
MC3_TEndRod:
    ld de,MC3_TexEndRod
    scf
    ret

;------------------------------------------------------------------------------
; MCv3 GAMEPLAY MICRO-SYSTEMS
;------------------------------------------------------------------------------
MC3_GameplayTick:
    call MC3_DropPhysics
    call MC3_DayNightTick
    call MC3_QuestTick
    call MC3_CombatTick
    call MC3_AnimalBreedingTick
    call MC3_ProjectileEffectsTick
    call MC3_TorchLightTick
    ret

MC3_DropPhysics:
    ld a,(S84_DropCount)
    or a
    ret z
    xor a
    ld (MC3_DropIndex),a
MC3_DP_Loop:
    ld a,(MC3_DropIndex)
    ld e,a
    ld d,0
    cp DROP_MAX
    ret nc
    ld hl,S84_DropTimer
    add hl,de
    ld a,(hl)
    or a
    jp z,MC3_DP_Next
    dec a
    ld (hl),a
MC3_DP_Next:
    ld a,(MC3_DropIndex)
    inc a
    ld (MC3_DropIndex),a
    jp MC3_DP_Loop

MC3_DayNightTick:
    ld a,(S84_WorldTime)
    inc a
    ld (S84_WorldTime),a
    ret nz
    ld a,(S84_WorldDay)
    inc a
    ld (S84_WorldDay),a
    ret

MC3_QuestTick:
    ld a,(S84_Level)
    cp 30
    ret nc
    ld a,(S84_XPLo)
    cp 250
    ret c
    xor a
    ld (S84_XPLo),a
    ld a,(S84_Level)
    inc a
    ld (S84_Level),a
    ld a,(S84_XPNeed)
    add a,8
    ld (S84_XPNeed),a
    ld hl,MC3_SFX_LevelUpPat
    call MC3_SFX_RunPattern
    ret

MC3_CombatTick:
    ; Applies a tiny cooldown-like armor/sword recovery state.
    ld a,(S84_ShieldDurability)
    or a
    ret z
    ld a,(S84_ShieldUp)
    or a
    ret z
    ld a,(S84_PlayerHP)
    cp 20
    ret nc
    inc a
    ld (S84_PlayerHP),a
    ret

MC3_AnimalBreedingTick:
    ld a,(S84_BreedingTimer)
    inc a
    ld (S84_BreedingTimer),a
    cp 160
    ret c
    xor a
    ld (S84_BreedingTimer),a
    call rnd
    and 3
    cp 2
    ret nc
    call MC3_SpawnOffspring
    ret

MC3_SpawnOffspring:
    ; Find an inactive livestock slot and place a child near the player.
    xor a
    ld (MC3_LiveIndex),a
MC3_SO_Loop:
    ld a,(MC3_LiveIndex)
    cp MC3_LIVESTOCK_MAX
    ret nc
    ld e,a
    ld d,0
    ld hl,MC3_LiveActive
    add hl,de
    ld a,(hl)
    or a
    jp z,MC3_SO_Use
    ld a,(MC3_LiveIndex)
    inc a
    ld (MC3_LiveIndex),a
    jp MC3_SO_Loop
MC3_SO_Use:
    ld (hl),1
    ld a,MC3_MOB_COW
    ld (MC3_LiveType),a
    ld a,(S84_PlayerX)
    inc a
    ld (MC3_LiveX),a
    ld a,(S84_PlayerZ)
    inc a
    ld (MC3_LiveZ),a
    ld a,(S84_PlayerY)
    ld (MC3_LiveY),a
    ld a,4
    ld (MC3_LiveHP),a
    ret

MC3_ProjectileEffectsTick:
    ld a,(S84_ProjectileCount)
    or a
    ret z
    ld hl,S84_ProjectileLife
    ld b,PROJ_MAX
MC3_PET_Loop:
    ld a,(hl)
    or a
    jp z,MC3_PET_Next
    dec a
    ld (hl),a
MC3_PET_Next:
    inc hl
    djnz MC3_PET_Loop
    ret

MC3_TorchLightTick:
    ld a,(S84_LampOn)
    xor 1
    ld (S84_LampOn),a
    ret

;------------------------------------------------------------------------------
; MENU STRINGS
;------------------------------------------------------------------------------
MC3_StrMuntcraft: .db 77,85,78,84,67,82,65,70,84,0
MC3_StrEdition: .db 67,83,69,32,90,56,48,32,69,68,73,84,73,79,78,0
MC3_StrFooter: .db 85,80,68,79,87,78,32,83,69,76,69,67,84,32,69,78,84,69,82,0
MC3_StrHelpTitle: .db 72,79,87,32,84,79,32,80,76,65,89,0
MC3_StrHelp1: .db 56,83,57,53,32,77,79,86,69,32,65,82,82,79,87,83,32,76,79,79,75,0
MC3_StrHelp2: .db 50,78,68,32,77,73,78,69,32,65,76,80,72,65,32,80,76,65,67,69,0
MC3_StrHelp3: .db 87,73,78,68,79,87,32,73,78,86,69,78,84,79,82,89,32,86,65,82,83,32,67,82,65,70,84,0
MC3_StrHelp4: .db 84,82,65,67,69,32,77,85,83,73,67,32,90,79,79,77,32,84,82,65,67,75,0
MC3_StrHelp5: .db 77,79,68,69,32,67,82,69,65,84,73,86,69,32,67,76,69,65,82,32,81,85,73,84,0
MC3_Menu0: .db 83,85,82,86,73,86,65,76,0
MC3_Menu1: .db 67,82,69,65,84,73,86,69,0
MC3_Menu2: .db 76,79,65,68,32,87,79,82,76,68,0
MC3_Menu3: .db 72,79,87,32,84,79,32,80,76,65,89,0
MC3_Menu4: .db 69,88,73,84,0
MC3_MenuStringTable:
    .dw MC3_Menu0
    .dw MC3_Menu1
    .dw MC3_Menu2
    .dw MC3_Menu3
    .dw MC3_Menu4

; 5 columns per glyph, 7 active bits. A-Z, 0-9, space.
MC3_Font5x7:
    .db $7E,$11,$11,$11,$7E ; A
    .db $7F,$49,$49,$49,$36 ; B
    .db $3E,$41,$41,$41,$22 ; C
    .db $7F,$41,$41,$22,$1C ; D
    .db $7F,$49,$49,$49,$41 ; E
    .db $7F,$09,$09,$09,$01 ; F
    .db $3E,$41,$49,$49,$7A ; G
    .db $7F,$08,$08,$08,$7F ; H
    .db $41,$41,$7F,$41,$41 ; I
    .db $20,$40,$41,$3F,$01 ; J
    .db $7F,$08,$14,$22,$41 ; K
    .db $7F,$40,$40,$40,$40 ; L
    .db $7F,$02,$0C,$02,$7F ; M
    .db $7F,$04,$08,$10,$7F ; N
    .db $3E,$41,$41,$41,$3E ; O
    .db $7F,$09,$09,$09,$06 ; P
    .db $3E,$41,$51,$21,$5E ; Q
    .db $7F,$09,$19,$29,$46 ; R
    .db $46,$49,$49,$49,$31 ; S
    .db $01,$01,$7F,$01,$01 ; T
    .db $3F,$40,$40,$40,$3F ; U
    .db $1F,$20,$40,$20,$1F ; V
    .db $3F,$40,$38,$40,$3F ; W
    .db $63,$14,$08,$14,$63 ; X
    .db $07,$08,$70,$08,$07 ; Y
    .db $61,$51,$49,$45,$43 ; Z
    .db $3E,$45,$49,$51,$3E ; 0
    .db $00,$42,$7F,$40,$00 ; 1
    .db $42,$61,$51,$49,$46 ; 2
    .db $21,$41,$45,$4B,$31 ; 3
    .db $18,$14,$12,$7F,$10 ; 4
    .db $27,$45,$45,$45,$39 ; 5
    .db $3C,$4A,$49,$49,$30 ; 6
    .db $01,$71,$09,$05,$03 ; 7
    .db $36,$49,$49,$49,$36 ; 8
    .db $06,$49,$49,$29,$1E ; 9
    .db $00,$00,$00,$00,$00 ; space

;------------------------------------------------------------------------------
; Animal texture masks. Eight 8-bit rows are used by the logical sprite pass.
;------------------------------------------------------------------------------
MC3_AnimalCowTex:
    .db $00,$18,$3C,$7E,$5A,$7E,$24,$24
MC3_AnimalPigTex:
    .db $00,$18,$3C,$7E,$66,$7E,$24,$18
MC3_AnimalSheepTex:
    .db $3C,$7E,$FF,$DB,$FF,$7E,$24,$24
MC3_AnimalChickenTex:
    .db $00,$10,$38,$7C,$FE,$7C,$38,$10
MC3_AnimalZombieTex:
    .db $7E,$DB,$FF,$A5,$7E,$3C,$24,$24

;------------------------------------------------------------------------------
; Animal / item sound patterns.
;------------------------------------------------------------------------------
MC3_SFX_CowPat: .db S84_NOTE_C3,1,S84_NOTE_G3,2,S84_NOTE_C3,2,S84_NOTE_END,0
MC3_SFX_PigPat: .db S84_NOTE_D3,1,S84_NOTE_F3,2,S84_NOTE_D3,2,S84_NOTE_END,0
MC3_SFX_SheepPat: .db S84_NOTE_E3,1,S84_NOTE_G3,2,S84_NOTE_B3,2,S84_NOTE_END,0
MC3_SFX_ChickenPat: .db S84_NOTE_A4,1,S84_NOTE_C5,1,S84_NOTE_A4,1,S84_NOTE_END,0
MC3_SFX_ZombiePat: .db S84_NOTE_C3,3,S84_NOTE_DS3,3,S84_NOTE_GS3,4,S84_NOTE_END,0
MC3_SFX_LevelUpPat: .db S84_NOTE_C4,1,S84_NOTE_E4,1,S84_NOTE_G4,1,S84_NOTE_C5,4,S84_NOTE_END,0
MC3_SFX_BreakStonePat: .db S84_NOTE_D3,2,S84_NOTE_D3,2,S84_NOTE_A2,2,S84_NOTE_END,0
MC3_SFX_BreakObsidianPat: .db S84_NOTE_C3,4,S84_NOTE_GS2,4,S84_NOTE_C3,4,S84_NOTE_END,0
MC3_SFX_BreakDirtPat: .db S84_NOTE_G3,1,S84_NOTE_C3,2,S84_NOTE_G3,1,S84_NOTE_END,0
MC3_SFX_BreakGrassPat: .db S84_NOTE_A3,1,S84_NOTE_E4,1,S84_NOTE_A3,2,S84_NOTE_END,0
MC3_SFX_BreakSandPat: .db S84_NOTE_F4,1,S84_NOTE_D4,1,S84_NOTE_F4,2,S84_NOTE_END,0
MC3_SFX_BreakGravelPat: .db S84_NOTE_E4,1,S84_NOTE_B3,1,S84_NOTE_E4,1,S84_NOTE_END,0
MC3_SFX_BreakGlassPat: .db S84_NOTE_B4,1,S84_NOTE_G5,1,S84_NOTE_END,0
MC3_SFX_BreakWaterPat: .db S84_NOTE_C5,1,S84_NOTE_E5,1,S84_NOTE_G5,1,S84_NOTE_END,0
MC3_SFX_BreakLavaPat: .db S84_NOTE_A2,3,S84_NOTE_C3,2,S84_NOTE_D3,3,S84_NOTE_END,0
MC3_SFX_BreakLeavesPat: .db S84_NOTE_G4,1,S84_NOTE_E4,1,S84_NOTE_C4,2,S84_NOTE_END,0
MC3_SFX_BreakWoodPat: .db S84_NOTE_E3,2,S84_NOTE_B2,2,S84_NOTE_E3,2,S84_NOTE_END,0
MC3_SFX_BreakTorchPat: .db S84_NOTE_C5,1,S84_NOTE_A4,1,S84_NOTE_C5,1,S84_NOTE_END,0
MC3_SFX_BreakOrePat: .db S84_NOTE_G3,2,S84_NOTE_C4,2,S84_NOTE_G3,2,S84_NOTE_END,0
MC3_SFX_BreakGoldPat: .db S84_NOTE_B3,1,S84_NOTE_D5,2,S84_NOTE_B4,2,S84_NOTE_END,0
MC3_SFX_BreakRedstonePat: .db S84_NOTE_E4,1,S84_NOTE_G4,1,S84_NOTE_E5,2,S84_NOTE_END,0
MC3_SFX_BreakNetherPat: .db S84_NOTE_C3,2,S84_NOTE_F3,2,S84_NOTE_AS2,2,S84_NOTE_END,0
MC3_SFX_BreakPortalPat: .db S84_NOTE_G4,2,S84_NOTE_D5,2,S84_NOTE_G5,3,S84_NOTE_END,0
MC3_SFX_BreakEndPat: .db S84_NOTE_F5,2,S84_NOTE_C5,2,S84_NOTE_A4,3,S84_NOTE_END,0
MC3_SFX_BreakDefaultPat: .db S84_NOTE_G3,1,S84_NOTE_D3,1,S84_NOTE_G3,2,S84_NOTE_END,0
MC3_SFX_PlaceStonePat: .db S84_NOTE_C4,1,S84_NOTE_F4,1,S84_NOTE_C4,1,S84_NOTE_END,0
MC3_SFX_PlaceObsidianPat: .db S84_NOTE_C3,3,S84_NOTE_F3,2,S84_NOTE_C3,3,S84_NOTE_END,0
MC3_SFX_PlaceDirtPat: .db S84_NOTE_C4,1,S84_NOTE_G3,1,S84_NOTE_C4,2,S84_NOTE_END,0
MC3_SFX_PlaceGrassPat: .db S84_NOTE_G4,1,S84_NOTE_C5,1,S84_NOTE_G4,1,S84_NOTE_END,0
MC3_SFX_PlaceSandPat: .db S84_NOTE_D4,1,S84_NOTE_A3,1,S84_NOTE_D4,2,S84_NOTE_END,0
MC3_SFX_PlaceGlassPat: .db S84_NOTE_E5,1,S84_NOTE_B4,1,S84_NOTE_E5,1,S84_NOTE_END,0
MC3_SFX_PlaceWaterPat: .db S84_NOTE_G4,1,S84_NOTE_B4,1,S84_NOTE_E5,1,S84_NOTE_END,0
MC3_SFX_PlaceLavaPat: .db S84_NOTE_C3,2,S84_NOTE_G2,2,S84_NOTE_C3,2,S84_NOTE_END,0
MC3_SFX_PlaceLeavesPat: .db S84_NOTE_E4,1,S84_NOTE_G4,1,S84_NOTE_B4,1,S84_NOTE_END,0
MC3_SFX_PlaceWoodPat: .db S84_NOTE_E3,1,S84_NOTE_A3,1,S84_NOTE_E4,1,S84_NOTE_END,0
MC3_SFX_PlaceNetherPat: .db S84_NOTE_F3,2,S84_NOTE_AS2,2,S84_NOTE_F3,2,S84_NOTE_END,0
MC3_SFX_PlacePortalPat: .db S84_NOTE_D5,2,S84_NOTE_A4,2,S84_NOTE_D5,3,S84_NOTE_END,0
MC3_SFX_PlaceEndPat: .db S84_NOTE_A4,2,S84_NOTE_E5,2,S84_NOTE_A5,2,S84_NOTE_END,0
MC3_SFX_PlaceRedstonePat: .db S84_NOTE_C4,1,S84_NOTE_E4,1,S84_NOTE_G4,2,S84_NOTE_END,0
MC3_SFX_PlaceMetalPat: .db S84_NOTE_E4,1,S84_NOTE_B4,1,S84_NOTE_E5,2,S84_NOTE_END,0
MC3_SFX_PlaceDefaultPat: .db S84_NOTE_G4,1,S84_NOTE_C5,1,S84_NOTE_G4,2,S84_NOTE_END,0

;------------------------------------------------------------------------------
; MCv3 STATE
;------------------------------------------------------------------------------
MC3_InitialMode       .db 0
MC3_MenuSel           .db 0
MC3_MenuFirstRun      .db 1
MC3_MenuTempSel       .db 0
MC3_MenuTextY         .db 0
MC3_MenuLoopIndex     .db 0
MC3_FillYTmp          .db 0
MC3_TextPtr           .dw 0
MC3_FontPtr           .dw 0
MC3_TextX             .db 0
MC3_TextY             .db 0
MC3_CharCode          .db 0
MC3_CharCol            .db 0
MC3_CharRow            .db 0
MC3_FontColumn         .db 0
MC3_PlotX              .db 0
MC3_SFXPtr             .dw 0
MC3_SFXNoteTmp         .db 0
MC3_SFXDelayTmp        .db 0
MC3_LiveIndex          .db 0
MC3_LiveSoundTimer     .db 0
MC3_LiveAnimFrame      .db 0
MC3_LiveSpawnCounter   .db 0
MC3_LiveRenderSkip     .db 0
MC3_AnimalTexPtr       .dw 0
MC3_AnimalScale        .db 1
MC3_AnimalRow          .db 0
MC3_AnimalCol          .db 0
MC3_DropIndex          .db 0
MC3_LiveActive         .fill MC3_LIVESTOCK_MAX,1
MC3_LiveType           .fill MC3_LIVESTOCK_MAX,MC3_MOB_COW
MC3_LiveX              .fill MC3_LIVESTOCK_MAX,6
MC3_LiveY              .fill MC3_LIVESTOCK_MAX,6
MC3_LiveZ              .fill MC3_LIVESTOCK_MAX,6
MC3_LiveHP             .fill MC3_LIVESTOCK_MAX,8
;------------------------------------------------------------------------------
; 16x16 EXTRAS -- 64 dedicated texture tiles (1024 bytes).
;------------------------------------------------------------------------------
MC3_TexFarmland:
    .db $4,$5,$5,$6,$5,$5,$5,$5,$6,$5,$5,$5,$5,$6,$5,$4
    .db $5,$4,$5,$6,$5,$5,$5,$5,$6,$5,$5,$5,$5,$6,$4,$5
    .db $5,$5,$4,$6,$5,$5,$5,$5,$6,$5,$5,$5,$5,$4,$5,$5
    .db $6,$6,$6,$4,$6,$6,$6,$6,$6,$6,$6,$6,$4,$6,$6,$6
    .db $5,$5,$5,$6,$4,$5,$5,$5,$6,$5,$5,$4,$5,$6,$5,$5
    .db $5,$5,$5,$6,$5,$4,$5,$5,$6,$5,$4,$5,$5,$6,$5,$5
    .db $5,$5,$5,$6,$5,$5,$4,$5,$6,$4,$5,$5,$5,$6,$5,$5
    .db $5,$5,$5,$6,$5,$5,$5,$4,$4,$5,$5,$5,$5,$6,$5,$5
    .db $6,$6,$6,$6,$6,$6,$6,$4,$4,$6,$6,$6,$6,$6,$6,$6
    .db $5,$5,$5,$6,$5,$5,$4,$5,$6,$4,$5,$5,$5,$6,$5,$5
    .db $5,$5,$5,$6,$5,$4,$5,$5,$6,$5,$4,$5,$5,$6,$5,$5
    .db $5,$5,$5,$6,$4,$5,$5,$5,$6,$5,$5,$4,$5,$6,$5,$5
    .db $5,$5,$5,$4,$5,$5,$5,$5,$6,$5,$5,$5,$4,$6,$5,$5
    .db $6,$6,$4,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$4,$6,$6
    .db $5,$4,$5,$6,$5,$5,$5,$5,$6,$5,$5,$5,$5,$6,$4,$5
    .db $4,$5,$5,$6,$5,$5,$5,$5,$6,$5,$5,$5,$5,$6,$5,$4
MC3_TexWheat:
    .db $7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7
    .db $7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7
    .db $A,$A,$7,$5,$A,$7,$A,$A,$7,$A,$A,$7,$5,$A,$7,$A
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $A,$A,$7,$5,$A,$7,$A,$A,$7,$A,$A,$7,$5,$A,$7,$A
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $A,$A,$7,$5,$A,$7,$A,$A,$7,$A,$A,$7,$5,$A,$7,$A
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $A,$A,$7,$5,$A,$7,$A,$A,$7,$A,$A,$7,$5,$A,$7,$A
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $A,$A,$7,$5,$A,$7,$A,$A,$7,$A,$A,$7,$5,$A,$7,$A
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
MC3_TexWheatRipe:
    .db $B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B
    .db $B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B
    .db $D,$B,$D,$9,$B,$D,$D,$B,$D,$D,$B,$D,$9,$B,$D,$D
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $D,$B,$D,$9,$B,$D,$D,$B,$D,$D,$B,$D,$9,$B,$D,$D
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $D,$B,$D,$9,$B,$D,$D,$B,$D,$D,$B,$D,$9,$B,$D,$D
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $D,$B,$D,$9,$B,$D,$D,$B,$D,$D,$B,$D,$9,$B,$D,$D
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
    .db $D,$B,$D,$9,$B,$D,$D,$B,$D,$D,$B,$D,$9,$B,$D,$D
    .db $B,$B,$B,$9,$B,$B,$B,$B,$B,$B,$B,$B,$9,$B,$B,$B
MC3_TexObsidian:
    .db $2,$1,$1,$2,$2,$1,$2,$2,$2,$1,$2,$4,$1,$1,$2,$2
    .db $1,$2,$2,$1,$1,$2,$2,$1,$2,$2,$4,$1,$2,$2,$1,$1
    .db $2,$2,$1,$2,$2,$1,$1,$2,$2,$4,$2,$2,$2,$1,$2,$2
    .db $1,$2,$2,$2,$1,$2,$2,$1,$4,$2,$2,$1,$2,$2,$2,$1
    .db $2,$2,$1,$2,$2,$2,$1,$4,$2,$1,$1,$2,$2,$1,$2,$2
    .db $1,$1,$2,$2,$1,$2,$4,$2,$1,$2,$2,$1,$1,$2,$2,$1
    .db $2,$2,$1,$1,$2,$4,$1,$2,$2,$2,$1,$2,$2,$1,$1,$2
    .db $2,$1,$2,$2,$4,$1,$2,$2,$1,$2,$2,$2,$1,$2,$2,$1
    .db $2,$2,$2,$4,$2,$2,$1,$1,$2,$2,$1,$2,$2,$2,$1,$2
    .db $2,$1,$4,$2,$2,$1,$2,$2,$1,$1,$2,$2,$1,$2,$2,$4
    .db $1,$4,$2,$1,$2,$2,$2,$1,$2,$2,$1,$1,$2,$2,$4,$2
    .db $4,$1,$1,$2,$2,$1,$2,$2,$2,$1,$2,$2,$1,$4,$2,$2
    .db $1,$2,$2,$1,$1,$2,$2,$1,$2,$2,$2,$1,$4,$2,$1,$1
    .db $2,$2,$1,$2,$2,$1,$1,$2,$2,$1,$2,$4,$2,$1,$2,$2
    .db $1,$2,$2,$2,$1,$2,$2,$1,$1,$2,$4,$1,$2,$2,$2,$1
    .db $2,$2,$1,$2,$2,$2,$1,$2,$2,$4,$1,$2,$2,$1,$2,$2
MC3_TexPortal:
    .db $D,$A,$9,$9,$9,$9,$A,$9,$9,$9,$9,$A,$9,$9,$9,$D
    .db $A,$D,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$D,$A
    .db $9,$A,$D,$9,$9,$9,$A,$9,$9,$9,$9,$A,$9,$D,$9,$9
    .db $9,$A,$9,$D,$9,$9,$A,$9,$9,$9,$9,$A,$D,$9,$9,$9
    .db $9,$A,$9,$9,$D,$9,$A,$9,$9,$9,$9,$D,$9,$9,$9,$9
    .db $9,$A,$9,$9,$9,$D,$A,$9,$9,$9,$D,$A,$9,$9,$9,$9
    .db $A,$A,$A,$A,$A,$A,$D,$A,$A,$D,$A,$A,$A,$A,$A,$A
    .db $9,$A,$9,$9,$9,$9,$A,$D,$D,$9,$9,$A,$9,$9,$9,$9
    .db $9,$A,$9,$9,$9,$9,$A,$D,$D,$9,$9,$A,$9,$9,$9,$9
    .db $9,$A,$9,$9,$9,$9,$D,$9,$9,$D,$9,$A,$9,$9,$9,$9
    .db $9,$A,$9,$9,$9,$D,$A,$9,$9,$9,$D,$A,$9,$9,$9,$9
    .db $A,$A,$A,$A,$D,$A,$A,$A,$A,$A,$A,$D,$A,$A,$A,$A
    .db $9,$A,$9,$D,$9,$9,$A,$9,$9,$9,$9,$A,$D,$9,$9,$9
    .db $9,$A,$D,$9,$9,$9,$A,$9,$9,$9,$9,$A,$9,$D,$9,$9
    .db $9,$D,$9,$9,$9,$9,$A,$9,$9,$9,$9,$A,$9,$9,$D,$9
    .db $D,$A,$9,$9,$9,$9,$A,$9,$9,$9,$9,$A,$9,$9,$9,$D
MC3_TexNetherrack:
    .db $5,$5,$4,$4,$5,$4,$4,$4,$3,$4,$4,$5,$5,$4,$4,$5
    .db $4,$4,$5,$5,$4,$4,$5,$3,$4,$4,$5,$4,$4,$5,$5,$4
    .db $4,$5,$4,$4,$5,$5,$3,$4,$5,$4,$4,$4,$5,$4,$4,$5
    .db $4,$4,$4,$5,$4,$3,$5,$5,$4,$4,$5,$4,$4,$4,$5,$4
    .db $4,$5,$4,$4,$3,$5,$4,$4,$5,$5,$4,$4,$5,$4,$4,$4
    .db $5,$4,$4,$3,$4,$4,$4,$5,$4,$4,$5,$5,$4,$4,$5,$4
    .db $4,$5,$3,$4,$4,$5,$4,$4,$4,$5,$4,$4,$5,$5,$4,$3
    .db $5,$3,$4,$5,$5,$4,$4,$5,$4,$4,$4,$5,$4,$4,$3,$5
    .db $3,$4,$5,$4,$4,$5,$5,$4,$4,$5,$4,$4,$4,$3,$4,$4
    .db $5,$4,$4,$4,$5,$4,$4,$5,$5,$4,$4,$5,$3,$4,$4,$5
    .db $4,$4,$5,$4,$4,$4,$5,$4,$4,$5,$5,$3,$4,$5,$4,$4
    .db $5,$5,$4,$4,$5,$4,$4,$4,$5,$4,$3,$5,$5,$4,$4,$5
    .db $4,$4,$5,$5,$4,$4,$5,$4,$4,$3,$5,$4,$4,$5,$5,$4
    .db $4,$5,$4,$4,$5,$5,$4,$4,$3,$4,$4,$4,$5,$4,$4,$5
    .db $4,$4,$4,$5,$4,$4,$5,$3,$4,$4,$5,$4,$4,$4,$5,$4
    .db $4,$5,$4,$4,$4,$5,$3,$4,$5,$5,$4,$4,$5,$4,$4,$4
MC3_TexQuartz:
    .db $B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$B
    .db $B,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$D,$C,$C,$D,$B
    .db $B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B
MC3_TexEndstone:
    .db $B,$B,$C,$B,$B,$A,$C,$B,$B,$C,$B,$B,$B,$C,$B,$B
    .db $C,$B,$B,$B,$A,$B,$B,$C,$C,$B,$B,$C,$B,$B,$B,$C
    .db $B,$B,$C,$A,$B,$B,$C,$B,$B,$C,$C,$B,$B,$C,$B,$B
    .db $C,$C,$A,$B,$C,$B,$B,$B,$C,$B,$B,$C,$C,$B,$B,$A
    .db $B,$A,$C,$C,$B,$B,$C,$B,$B,$B,$C,$B,$B,$C,$A,$B
    .db $A,$C,$B,$B,$C,$C,$B,$B,$C,$B,$B,$B,$C,$A,$B,$C
    .db $B,$B,$B,$C,$B,$B,$C,$C,$B,$B,$C,$B,$A,$B,$C,$B
    .db $B,$C,$B,$B,$B,$C,$B,$B,$C,$C,$B,$A,$C,$B,$B,$B
    .db $C,$B,$B,$C,$B,$B,$B,$C,$B,$B,$A,$C,$B,$B,$C,$B
    .db $B,$C,$C,$B,$B,$C,$B,$B,$B,$A,$B,$B,$C,$C,$B,$B
    .db $C,$B,$B,$C,$C,$B,$B,$C,$A,$B,$B,$C,$B,$B,$C,$C
    .db $B,$B,$C,$B,$B,$C,$C,$A,$B,$C,$B,$B,$B,$C,$B,$B
    .db $C,$B,$B,$B,$C,$B,$A,$C,$C,$B,$B,$C,$B,$B,$B,$C
    .db $B,$B,$C,$B,$B,$A,$C,$B,$B,$C,$C,$B,$B,$C,$B,$B
    .db $C,$C,$B,$B,$A,$B,$B,$B,$C,$B,$B,$C,$C,$B,$B,$C
    .db $B,$B,$C,$A,$B,$B,$C,$B,$B,$B,$C,$B,$B,$C,$C,$B
MC3_TexPurpur:
    .db $C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$C
    .db $C,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$9,$8,$8,$9,$C
    .db $C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C
MC3_TexChorus:
    .db $6,$6,$9,$9,$6,$7,$9,$6,$6,$6,$9,$6,$6,$9,$9,$6
    .db $6,$9,$6,$6,$7,$9,$6,$6,$9,$6,$6,$6,$9,$6,$6,$9
    .db $6,$6,$6,$7,$6,$6,$9,$9,$6,$6,$9,$6,$6,$6,$9,$6
    .db $6,$9,$7,$6,$6,$9,$6,$6,$9,$9,$6,$6,$9,$6,$6,$7
    .db $9,$7,$6,$9,$6,$6,$6,$9,$6,$6,$9,$9,$6,$6,$7,$6
    .db $7,$9,$9,$6,$6,$9,$6,$6,$6,$9,$6,$6,$9,$7,$6,$6
    .db $9,$6,$6,$9,$9,$6,$6,$9,$6,$6,$6,$9,$7,$6,$9,$9
    .db $6,$6,$9,$6,$6,$9,$9,$6,$6,$9,$6,$7,$6,$9,$6,$6
    .db $9,$6,$6,$6,$9,$6,$6,$9,$9,$6,$7,$9,$6,$6,$6,$9
    .db $6,$6,$9,$6,$6,$6,$9,$6,$6,$7,$9,$6,$6,$9,$6,$6
    .db $9,$9,$6,$6,$9,$6,$6,$6,$7,$6,$6,$9,$9,$6,$6,$9
    .db $6,$6,$9,$9,$6,$6,$9,$7,$6,$6,$9,$6,$6,$9,$9,$6
    .db $6,$9,$6,$6,$9,$9,$7,$6,$9,$6,$6,$6,$9,$6,$6,$9
    .db $6,$6,$6,$9,$6,$7,$9,$9,$6,$6,$9,$6,$6,$6,$9,$6
    .db $6,$9,$6,$6,$7,$9,$6,$6,$9,$9,$6,$6,$9,$6,$6,$6
    .db $9,$6,$6,$7,$6,$6,$6,$9,$6,$6,$9,$9,$6,$6,$9,$6
MC3_TexRedOre:
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$A,$2,$4,$2,$2,$4,$2
    .db $2,$2,$2,$4,$4,$2,$2,$2,$A,$2,$2,$2,$4,$4,$2,$2
    .db $4,$2,$4,$2,$2,$4,$2,$A,$4,$4,$2,$4,$2,$2,$4,$2
    .db $2,$4,$2,$2,$2,$2,$A,$2,$2,$2,$4,$2,$2,$2,$2,$4
    .db $2,$4,$2,$2,$2,$A,$4,$2,$2,$2,$4,$2,$2,$2,$2,$4
    .db $4,$2,$4,$2,$A,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $2,$2,$2,$A,$4,$2,$2,$2,$2,$2,$2,$2,$4,$4,$2,$2
    .db $4,$2,$A,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $4,$A,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $A,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $2,$2,$2,$4,$4,$2,$2,$2,$2,$2,$2,$2,$4,$4,$2,$2
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$A
    .db $2,$4,$2,$2,$2,$2,$4,$2,$2,$2,$4,$2,$2,$2,$A,$4
    .db $2,$4,$2,$2,$2,$2,$4,$2,$2,$2,$4,$2,$2,$A,$2,$4
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$A,$2,$4,$2
    .db $2,$2,$2,$4,$4,$2,$2,$2,$2,$2,$2,$A,$4,$4,$2,$2
MC3_TexBookshelf:
    .db $5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5
    .db $5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5
    .db $7,$7,$5,$3,$7,$5,$7,$7,$5,$7,$7,$5,$3,$7,$5,$7
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $7,$7,$5,$3,$7,$5,$7,$7,$5,$7,$7,$5,$3,$7,$5,$7
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $7,$7,$5,$3,$7,$5,$7,$7,$5,$7,$7,$5,$3,$7,$5,$7
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $7,$7,$5,$3,$7,$5,$7,$7,$5,$7,$7,$5,$3,$7,$5,$7
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
    .db $7,$7,$5,$3,$7,$5,$7,$7,$5,$7,$7,$5,$3,$7,$5,$7
    .db $5,$5,$5,$3,$5,$5,$5,$5,$5,$5,$5,$5,$3,$5,$5,$5
MC3_TexTNT:
    .db $6,$B,$2,$B,$B,$B,$B,$2,$B,$B,$B,$B,$2,$B,$B,$6
    .db $B,$6,$2,$B,$B,$B,$B,$2,$B,$B,$B,$B,$2,$B,$6,$B
    .db $2,$2,$6,$2,$2,$2,$2,$2,$2,$2,$2,$2,$2,$6,$2,$2
    .db $B,$B,$2,$6,$B,$B,$B,$2,$B,$B,$B,$B,$6,$B,$B,$B
    .db $B,$B,$2,$B,$6,$B,$B,$2,$B,$B,$B,$6,$2,$B,$B,$B
    .db $B,$B,$2,$B,$B,$6,$B,$2,$B,$B,$6,$B,$2,$B,$B,$B
    .db $B,$B,$2,$B,$B,$B,$6,$2,$B,$6,$B,$B,$2,$B,$B,$B
    .db $2,$2,$2,$2,$2,$2,$2,$6,$6,$2,$2,$2,$2,$2,$2,$2
    .db $B,$B,$2,$B,$B,$B,$B,$6,$6,$B,$B,$B,$2,$B,$B,$B
    .db $B,$B,$2,$B,$B,$B,$6,$2,$B,$6,$B,$B,$2,$B,$B,$B
    .db $B,$B,$2,$B,$B,$6,$B,$2,$B,$B,$6,$B,$2,$B,$B,$B
    .db $B,$B,$2,$B,$6,$B,$B,$2,$B,$B,$B,$6,$2,$B,$B,$B
    .db $2,$2,$2,$6,$2,$2,$2,$2,$2,$2,$2,$2,$6,$2,$2,$2
    .db $B,$B,$6,$B,$B,$B,$B,$2,$B,$B,$B,$B,$2,$6,$B,$B
    .db $B,$6,$2,$B,$B,$B,$B,$2,$B,$B,$B,$B,$2,$B,$6,$B
    .db $6,$B,$2,$B,$B,$B,$B,$2,$B,$B,$B,$B,$2,$B,$B,$6
MC3_TexSandstone:
    .db $9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9
    .db $9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9,$9
    .db $A,$A,$9,$7,$A,$9,$A,$A,$9,$A,$A,$9,$7,$A,$9,$A
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $A,$A,$9,$7,$A,$9,$A,$A,$9,$A,$A,$9,$7,$A,$9,$A
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $A,$A,$9,$7,$A,$9,$A,$A,$9,$A,$A,$9,$7,$A,$9,$A
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $A,$A,$9,$7,$A,$9,$A,$A,$9,$A,$A,$9,$7,$A,$9,$A
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
    .db $A,$A,$9,$7,$A,$9,$A,$A,$9,$A,$A,$9,$7,$A,$9,$A
    .db $9,$9,$9,$7,$9,$9,$9,$9,$9,$9,$9,$9,$7,$9,$9,$9
MC3_TexSoul:
    .db $2,$4,$1,$1,$2,$2,$1,$2,$2,$2,$1,$2,$2,$1,$4,$2
    .db $4,$1,$2,$2,$1,$1,$2,$2,$1,$2,$2,$2,$1,$4,$2,$1
    .db $2,$2,$2,$1,$2,$2,$1,$1,$2,$2,$1,$2,$4,$2,$1,$2
    .db $2,$1,$2,$2,$2,$1,$2,$2,$1,$1,$2,$4,$1,$2,$2,$2
    .db $1,$2,$2,$1,$2,$2,$2,$1,$2,$2,$4,$1,$2,$2,$1,$2
    .db $2,$1,$1,$2,$2,$1,$2,$2,$2,$4,$2,$2,$1,$1,$2,$2
    .db $1,$2,$2,$1,$1,$2,$2,$1,$4,$2,$2,$1,$2,$2,$1,$1
    .db $2,$2,$1,$2,$2,$1,$1,$4,$2,$1,$2,$2,$2,$1,$2,$2
    .db $1,$2,$2,$2,$1,$2,$4,$1,$1,$2,$2,$1,$2,$2,$2,$1
    .db $2,$2,$1,$2,$2,$4,$1,$2,$2,$1,$1,$2,$2,$1,$2,$2
    .db $1,$1,$2,$2,$4,$2,$2,$2,$1,$2,$2,$1,$1,$2,$2,$1
    .db $2,$2,$1,$4,$2,$2,$1,$2,$2,$2,$1,$2,$2,$1,$1,$2
    .db $2,$1,$4,$2,$1,$1,$2,$2,$1,$2,$2,$2,$1,$2,$2,$4
    .db $2,$4,$2,$1,$2,$2,$1,$1,$2,$2,$1,$2,$2,$2,$4,$2
    .db $4,$1,$2,$2,$2,$1,$2,$2,$1,$1,$2,$2,$1,$4,$2,$2
    .db $1,$2,$2,$1,$2,$2,$2,$1,$2,$2,$1,$1,$4,$2,$1,$2
MC3_TexGlowstone:
    .db $E,$D,$E,$D,$D,$E,$D,$E,$E,$E,$D,$E,$D,$D,$E,$B
    .db $D,$D,$D,$E,$E,$D,$D,$D,$D,$D,$D,$D,$E,$E,$B,$D
    .db $E,$D,$E,$D,$D,$E,$D,$E,$E,$E,$D,$E,$D,$B,$E,$D
    .db $D,$E,$D,$D,$D,$D,$E,$D,$D,$D,$E,$D,$B,$D,$D,$E
    .db $D,$E,$D,$D,$D,$D,$E,$D,$D,$D,$E,$B,$D,$D,$D,$E
    .db $E,$D,$E,$D,$D,$E,$D,$E,$E,$E,$B,$E,$D,$D,$E,$D
    .db $D,$D,$D,$E,$E,$D,$D,$D,$D,$B,$D,$D,$E,$E,$D,$D
    .db $E,$D,$E,$D,$D,$E,$D,$E,$B,$E,$D,$E,$D,$D,$E,$D
    .db $E,$D,$E,$D,$D,$E,$D,$B,$E,$E,$D,$E,$D,$D,$E,$D
    .db $E,$D,$E,$D,$D,$E,$B,$E,$E,$E,$D,$E,$D,$D,$E,$D
    .db $D,$D,$D,$E,$E,$B,$D,$D,$D,$D,$D,$D,$E,$E,$D,$D
    .db $E,$D,$E,$D,$B,$E,$D,$E,$E,$E,$D,$E,$D,$D,$E,$D
    .db $D,$E,$D,$B,$D,$D,$E,$D,$D,$D,$E,$D,$D,$D,$D,$E
    .db $D,$E,$B,$D,$D,$D,$E,$D,$D,$D,$E,$D,$D,$D,$D,$E
    .db $E,$B,$E,$D,$D,$E,$D,$E,$E,$E,$D,$E,$D,$D,$E,$D
    .db $B,$D,$D,$E,$E,$D,$D,$D,$D,$D,$D,$D,$E,$E,$D,$D
MC3_TexLadder:
    .db $4,$7,$6,$6,$6,$6,$7,$6,$6,$6,$6,$7,$6,$6,$6,$4
    .db $7,$4,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$4,$7
    .db $6,$7,$4,$6,$6,$6,$7,$6,$6,$6,$6,$7,$6,$4,$6,$6
    .db $6,$7,$6,$4,$6,$6,$7,$6,$6,$6,$6,$7,$4,$6,$6,$6
    .db $6,$7,$6,$6,$4,$6,$7,$6,$6,$6,$6,$4,$6,$6,$6,$6
    .db $6,$7,$6,$6,$6,$4,$7,$6,$6,$6,$4,$7,$6,$6,$6,$6
    .db $7,$7,$7,$7,$7,$7,$4,$7,$7,$4,$7,$7,$7,$7,$7,$7
    .db $6,$7,$6,$6,$6,$6,$7,$4,$4,$6,$6,$7,$6,$6,$6,$6
    .db $6,$7,$6,$6,$6,$6,$7,$4,$4,$6,$6,$7,$6,$6,$6,$6
    .db $6,$7,$6,$6,$6,$6,$4,$6,$6,$4,$6,$7,$6,$6,$6,$6
    .db $6,$7,$6,$6,$6,$4,$7,$6,$6,$6,$4,$7,$6,$6,$6,$6
    .db $7,$7,$7,$7,$4,$7,$7,$7,$7,$7,$7,$4,$7,$7,$7,$7
    .db $6,$7,$6,$4,$6,$6,$7,$6,$6,$6,$6,$7,$4,$6,$6,$6
    .db $6,$7,$4,$6,$6,$6,$7,$6,$6,$6,$6,$7,$6,$4,$6,$6
    .db $6,$4,$6,$6,$6,$6,$7,$6,$6,$6,$6,$7,$6,$6,$4,$6
    .db $4,$7,$6,$6,$6,$6,$7,$6,$6,$6,$6,$7,$6,$6,$6,$4
MC3_TexRail:
    .db $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$8
    .db $8,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$8
    .db $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
MC3_TexButton:
    .db $4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$4
    .db $4,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$8,$6,$6,$8,$4
    .db $4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4,$4
MC3_TexPressure:
    .db $3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$3
    .db $3,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$4,$6,$6,$4,$3
    .db $3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3
MC3_TexSign:
    .db $7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7
    .db $7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7
    .db $7,$9,$9,$5,$9,$9,$7,$9,$9,$7,$9,$9,$5,$9,$9,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$9,$9,$5,$9,$9,$7,$9,$9,$7,$9,$9,$5,$9,$9,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$9,$9,$5,$9,$9,$7,$9,$9,$7,$9,$9,$5,$9,$9,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$9,$9,$5,$9,$9,$7,$9,$9,$7,$9,$9,$5,$9,$9,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
    .db $7,$9,$9,$5,$9,$9,$7,$9,$9,$7,$9,$9,$5,$9,$9,$7
    .db $7,$7,$7,$5,$7,$7,$7,$7,$7,$7,$7,$7,$5,$7,$7,$7
MC3_TexChest:
    .db $6,$9,$6,$4,$9,$6,$9,$6,$6,$6,$9,$6,$9,$9,$6,$9
    .db $9,$9,$4,$6,$6,$9,$9,$9,$9,$9,$9,$9,$6,$6,$9,$9
    .db $6,$4,$6,$9,$9,$6,$9,$6,$6,$6,$9,$6,$9,$9,$6,$9
    .db $4,$6,$9,$9,$9,$9,$6,$9,$9,$9,$6,$9,$9,$9,$9,$6
    .db $9,$6,$9,$9,$9,$9,$6,$9,$9,$9,$6,$9,$9,$9,$9,$6
    .db $6,$9,$6,$9,$9,$6,$9,$6,$6,$6,$9,$6,$9,$9,$6,$4
    .db $9,$9,$9,$6,$6,$9,$9,$9,$9,$9,$9,$9,$6,$6,$4,$9
    .db $6,$9,$6,$9,$9,$6,$9,$6,$6,$6,$9,$6,$9,$4,$6,$9
    .db $6,$9,$6,$9,$9,$6,$9,$6,$6,$6,$9,$6,$4,$9,$6,$9
    .db $6,$9,$6,$9,$9,$6,$9,$6,$6,$6,$9,$4,$9,$9,$6,$9
    .db $9,$9,$9,$6,$6,$9,$9,$9,$9,$9,$4,$9,$6,$6,$9,$9
    .db $6,$9,$6,$9,$9,$6,$9,$6,$6,$4,$9,$6,$9,$9,$6,$9
    .db $9,$6,$9,$9,$9,$9,$6,$9,$4,$9,$6,$9,$9,$9,$9,$6
    .db $9,$6,$9,$9,$9,$9,$6,$4,$9,$9,$6,$9,$9,$9,$9,$6
    .db $6,$9,$6,$9,$9,$6,$4,$6,$6,$6,$9,$6,$9,$9,$6,$9
    .db $9,$9,$9,$6,$6,$4,$9,$9,$9,$9,$9,$9,$6,$6,$9,$9
MC3_TexEnchant:
    .db $9,$9,$6,$6,$9,$6,$6,$6,$9,$6,$6,$9,$D,$6,$6,$9
    .db $6,$6,$9,$9,$6,$6,$9,$6,$6,$6,$9,$D,$6,$9,$9,$6
    .db $6,$9,$6,$6,$9,$9,$6,$6,$9,$6,$D,$6,$9,$6,$6,$9
    .db $6,$6,$6,$9,$6,$6,$9,$9,$6,$D,$9,$6,$6,$6,$9,$6
    .db $6,$9,$6,$6,$6,$9,$6,$6,$D,$9,$6,$6,$9,$6,$6,$6
    .db $9,$6,$6,$9,$6,$6,$6,$D,$6,$6,$9,$9,$6,$6,$9,$6
    .db $6,$9,$9,$6,$6,$9,$D,$6,$6,$9,$6,$6,$9,$9,$6,$6
    .db $9,$6,$6,$9,$9,$D,$6,$9,$6,$6,$6,$9,$6,$6,$9,$9
    .db $6,$6,$9,$6,$D,$9,$9,$6,$6,$9,$6,$6,$6,$9,$6,$6
    .db $9,$6,$6,$D,$9,$6,$6,$9,$9,$6,$6,$9,$6,$6,$6,$9
    .db $6,$6,$D,$6,$6,$6,$9,$6,$6,$9,$9,$6,$6,$9,$6,$D
    .db $9,$D,$6,$6,$9,$6,$6,$6,$9,$6,$6,$9,$9,$6,$D,$9
    .db $D,$6,$9,$9,$6,$6,$9,$6,$6,$6,$9,$6,$6,$D,$9,$6
    .db $6,$9,$6,$6,$9,$9,$6,$6,$9,$6,$6,$6,$D,$6,$6,$9
    .db $6,$6,$6,$9,$6,$6,$9,$9,$6,$6,$9,$D,$6,$6,$9,$6
    .db $6,$9,$6,$6,$6,$9,$6,$6,$9,$9,$D,$6,$9,$6,$6,$6
MC3_TexAnvil:
    .db $7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$7
    .db $7,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$5,$6,$6,$5,$7
    .db $7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7,$7
MC3_TexBrewing:
    .db $9,$4,$5,$4,$4,$4,$4,$5,$4,$4,$4,$4,$5,$4,$4,$9
    .db $4,$9,$5,$4,$4,$4,$4,$5,$4,$4,$4,$4,$5,$4,$9,$4
    .db $5,$5,$9,$5,$5,$5,$5,$5,$5,$5,$5,$5,$5,$9,$5,$5
    .db $4,$4,$5,$9,$4,$4,$4,$5,$4,$4,$4,$4,$9,$4,$4,$4
    .db $4,$4,$5,$4,$9,$4,$4,$5,$4,$4,$4,$9,$5,$4,$4,$4
    .db $4,$4,$5,$4,$4,$9,$4,$5,$4,$4,$9,$4,$5,$4,$4,$4
    .db $4,$4,$5,$4,$4,$4,$9,$5,$4,$9,$4,$4,$5,$4,$4,$4
    .db $5,$5,$5,$5,$5,$5,$5,$9,$9,$5,$5,$5,$5,$5,$5,$5
    .db $4,$4,$5,$4,$4,$4,$4,$9,$9,$4,$4,$4,$5,$4,$4,$4
    .db $4,$4,$5,$4,$4,$4,$9,$5,$4,$9,$4,$4,$5,$4,$4,$4
    .db $4,$4,$5,$4,$4,$9,$4,$5,$4,$4,$9,$4,$5,$4,$4,$4
    .db $4,$4,$5,$4,$9,$4,$4,$5,$4,$4,$4,$9,$5,$4,$4,$4
    .db $5,$5,$5,$9,$5,$5,$5,$5,$5,$5,$5,$5,$9,$5,$5,$5
    .db $4,$4,$9,$4,$4,$4,$4,$5,$4,$4,$4,$4,$5,$9,$4,$4
    .db $4,$9,$5,$4,$4,$4,$4,$5,$4,$4,$4,$4,$5,$4,$9,$4
    .db $9,$4,$5,$4,$4,$4,$4,$5,$4,$4,$4,$4,$5,$4,$4,$9
MC3_TexBricks:
    .db $3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$3
    .db $3,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$5,$7,$7,$5,$3
    .db $3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3
MC3_TexMycelium:
    .db $9,$7,$7,$9,$9,$7,$7,$9,$4,$7,$7,$9,$7,$7,$9,$9
    .db $7,$7,$9,$7,$7,$9,$9,$4,$7,$9,$7,$7,$7,$9,$7,$7
    .db $9,$7,$7,$7,$9,$7,$4,$9,$9,$7,$7,$9,$7,$7,$7,$9
    .db $7,$7,$9,$7,$7,$4,$9,$7,$7,$9,$9,$7,$7,$9,$7,$7
    .db $9,$9,$7,$7,$4,$7,$7,$7,$9,$7,$7,$9,$9,$7,$7,$9
    .db $7,$7,$9,$4,$7,$7,$9,$7,$7,$7,$9,$7,$7,$9,$9,$7
    .db $7,$9,$4,$7,$9,$9,$7,$7,$9,$7,$7,$7,$9,$7,$7,$4
    .db $7,$4,$7,$9,$7,$7,$9,$9,$7,$7,$9,$7,$7,$7,$4,$7
    .db $4,$9,$7,$7,$7,$9,$7,$7,$9,$9,$7,$7,$9,$4,$7,$7
    .db $9,$7,$7,$9,$7,$7,$7,$9,$7,$7,$9,$9,$4,$7,$9,$7
    .db $7,$9,$9,$7,$7,$9,$7,$7,$7,$9,$7,$4,$9,$9,$7,$7
    .db $9,$7,$7,$9,$9,$7,$7,$9,$7,$7,$4,$9,$7,$7,$9,$9
    .db $7,$7,$9,$7,$7,$9,$9,$7,$7,$4,$7,$7,$7,$9,$7,$7
    .db $9,$7,$7,$7,$9,$7,$7,$9,$4,$7,$7,$9,$7,$7,$7,$9
    .db $7,$7,$9,$7,$7,$7,$9,$4,$7,$9,$9,$7,$7,$9,$7,$7
    .db $9,$9,$7,$7,$9,$7,$4,$7,$9,$7,$7,$9,$9,$7,$7,$9
MC3_TexSpruce:
    .db $5,$5,$5,$6,$3,$5,$6,$6,$5,$5,$6,$5,$5,$5,$6,$5
    .db $5,$6,$5,$3,$5,$6,$5,$5,$6,$6,$5,$5,$6,$5,$5,$5
    .db $6,$5,$3,$6,$5,$5,$5,$6,$5,$5,$6,$6,$5,$5,$6,$3
    .db $5,$3,$6,$5,$5,$6,$5,$5,$5,$6,$5,$5,$6,$6,$3,$5
    .db $3,$5,$5,$6,$6,$5,$5,$6,$5,$5,$5,$6,$5,$3,$6,$6
    .db $5,$5,$6,$5,$5,$6,$6,$5,$5,$6,$5,$5,$3,$6,$5,$5
    .db $6,$5,$5,$5,$6,$5,$5,$6,$6,$5,$5,$3,$5,$5,$5,$6
    .db $5,$5,$6,$5,$5,$5,$6,$5,$5,$6,$3,$5,$5,$6,$5,$5
    .db $6,$6,$5,$5,$6,$5,$5,$5,$6,$3,$5,$6,$6,$5,$5,$6
    .db $5,$5,$6,$6,$5,$5,$6,$5,$3,$5,$6,$5,$5,$6,$6,$5
    .db $5,$6,$5,$5,$6,$6,$5,$3,$6,$5,$5,$5,$6,$5,$5,$6
    .db $5,$5,$5,$6,$5,$5,$3,$6,$5,$5,$6,$5,$5,$5,$6,$5
    .db $5,$6,$5,$5,$5,$3,$5,$5,$6,$6,$5,$5,$6,$5,$5,$5
    .db $6,$5,$5,$6,$3,$5,$5,$6,$5,$5,$6,$6,$5,$5,$6,$5
    .db $5,$6,$6,$3,$5,$6,$5,$5,$5,$6,$5,$5,$6,$6,$5,$5
    .db $6,$5,$3,$6,$6,$5,$5,$6,$5,$5,$5,$6,$5,$5,$6,$3
MC3_TexBirch:
    .db $A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A
    .db $A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A,$A
    .db $A,$C,$C,$7,$C,$C,$A,$C,$C,$A,$C,$C,$7,$C,$C,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$C,$C,$7,$C,$C,$A,$C,$C,$A,$C,$C,$7,$C,$C,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$C,$C,$7,$C,$C,$A,$C,$C,$A,$C,$C,$7,$C,$C,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$C,$C,$7,$C,$C,$A,$C,$C,$A,$C,$C,$7,$C,$C,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
    .db $A,$C,$C,$7,$C,$C,$A,$C,$C,$A,$C,$C,$7,$C,$C,$A
    .db $A,$A,$A,$7,$A,$A,$A,$A,$A,$A,$A,$A,$7,$A,$A,$A
MC3_TexJungle:
    .db $5,$8,$5,$5,$5,$8,$5,$5,$8,$8,$5,$5,$3,$5,$5,$5
    .db $8,$5,$5,$8,$5,$5,$5,$8,$5,$5,$8,$3,$5,$5,$8,$5
    .db $5,$8,$8,$5,$5,$8,$5,$5,$5,$8,$3,$5,$8,$8,$5,$5
    .db $8,$5,$5,$8,$8,$5,$5,$8,$5,$3,$5,$8,$5,$5,$8,$8
    .db $5,$5,$8,$5,$5,$8,$8,$5,$3,$8,$5,$5,$5,$8,$5,$5
    .db $8,$5,$5,$5,$8,$5,$5,$3,$8,$5,$5,$8,$5,$5,$5,$8
    .db $5,$5,$8,$5,$5,$5,$3,$5,$5,$8,$8,$5,$5,$8,$5,$5
    .db $8,$8,$5,$5,$8,$3,$5,$5,$8,$5,$5,$8,$8,$5,$5,$8
    .db $5,$5,$8,$8,$3,$5,$8,$5,$5,$5,$8,$5,$5,$8,$8,$5
    .db $5,$8,$5,$3,$8,$8,$5,$5,$8,$5,$5,$5,$8,$5,$5,$8
    .db $5,$5,$3,$8,$5,$5,$8,$8,$5,$5,$8,$5,$5,$5,$8,$3
    .db $5,$3,$5,$5,$5,$8,$5,$5,$8,$8,$5,$5,$8,$5,$3,$5
    .db $3,$5,$5,$8,$5,$5,$5,$8,$5,$5,$8,$8,$5,$3,$8,$5
    .db $5,$8,$8,$5,$5,$8,$5,$5,$5,$8,$5,$5,$3,$8,$5,$5
    .db $8,$5,$5,$8,$8,$5,$5,$8,$5,$5,$5,$3,$5,$5,$8,$8
    .db $5,$5,$8,$5,$5,$8,$8,$5,$5,$8,$3,$5,$5,$8,$5,$5
MC3_TexAcacia:
    .db $9,$9,$A,$5,$9,$A,$A,$9,$9,$A,$9,$9,$9,$A,$9,$9
    .db $A,$9,$5,$9,$A,$9,$9,$A,$A,$9,$9,$A,$9,$9,$9,$5
    .db $9,$5,$A,$9,$9,$9,$A,$9,$9,$A,$A,$9,$9,$A,$5,$9
    .db $5,$A,$9,$9,$A,$9,$9,$9,$A,$9,$9,$A,$A,$5,$9,$A
    .db $9,$9,$A,$A,$9,$9,$A,$9,$9,$9,$A,$9,$5,$A,$A,$9
    .db $9,$A,$9,$9,$A,$A,$9,$9,$A,$9,$9,$5,$A,$9,$9,$A
    .db $9,$9,$9,$A,$9,$9,$A,$A,$9,$9,$5,$9,$9,$9,$A,$9
    .db $9,$A,$9,$9,$9,$A,$9,$9,$A,$5,$9,$9,$A,$9,$9,$9
    .db $A,$9,$9,$A,$9,$9,$9,$A,$5,$9,$A,$A,$9,$9,$A,$9
    .db $9,$A,$A,$9,$9,$A,$9,$5,$9,$A,$9,$9,$A,$A,$9,$9
    .db $A,$9,$9,$A,$A,$9,$5,$A,$9,$9,$9,$A,$9,$9,$A,$A
    .db $9,$9,$A,$9,$9,$5,$A,$9,$9,$A,$9,$9,$9,$A,$9,$9
    .db $A,$9,$9,$9,$5,$9,$9,$A,$A,$9,$9,$A,$9,$9,$9,$A
    .db $9,$9,$A,$5,$9,$9,$A,$9,$9,$A,$A,$9,$9,$A,$9,$9
    .db $A,$A,$5,$9,$A,$9,$9,$9,$A,$9,$9,$A,$A,$9,$9,$5
    .db $9,$5,$A,$A,$9,$9,$A,$9,$9,$9,$A,$9,$9,$A,$5,$9
MC3_TexDarkOak:
    .db $5,$4,$4,$4,$5,$4,$4,$2,$5,$4,$4,$5,$4,$4,$4,$5
    .db $4,$4,$5,$4,$4,$4,$2,$4,$4,$5,$5,$4,$4,$5,$4,$4
    .db $5,$5,$4,$4,$5,$2,$4,$4,$5,$4,$4,$5,$5,$4,$4,$5
    .db $4,$4,$5,$5,$2,$4,$5,$4,$4,$4,$5,$4,$4,$5,$5,$4
    .db $4,$5,$4,$2,$5,$5,$4,$4,$5,$4,$4,$4,$5,$4,$4,$5
    .db $4,$4,$2,$5,$4,$4,$5,$5,$4,$4,$5,$4,$4,$4,$5,$2
    .db $4,$2,$4,$4,$4,$5,$4,$4,$5,$5,$4,$4,$5,$4,$2,$4
    .db $2,$4,$4,$5,$4,$4,$4,$5,$4,$4,$5,$5,$4,$2,$5,$4
    .db $4,$5,$5,$4,$4,$5,$4,$4,$4,$5,$4,$4,$2,$5,$4,$4
    .db $5,$4,$4,$5,$5,$4,$4,$5,$4,$4,$4,$2,$4,$4,$5,$5
    .db $4,$4,$5,$4,$4,$5,$5,$4,$4,$5,$2,$4,$4,$5,$4,$4
    .db $5,$4,$4,$4,$5,$4,$4,$5,$5,$2,$4,$5,$4,$4,$4,$5
    .db $4,$4,$5,$4,$4,$4,$5,$4,$2,$5,$5,$4,$4,$5,$4,$4
    .db $5,$5,$4,$4,$5,$4,$4,$2,$5,$4,$4,$5,$5,$4,$4,$5
    .db $4,$4,$5,$5,$4,$4,$2,$4,$4,$4,$5,$4,$4,$5,$5,$4
    .db $4,$5,$4,$4,$5,$2,$4,$4,$5,$4,$4,$4,$5,$4,$4,$5
MC3_TexMangrove:
    .db $5,$5,$7,$2,$5,$5,$7,$5,$5,$5,$7,$5,$5,$7,$7,$5
    .db $5,$7,$2,$5,$7,$7,$5,$5,$7,$5,$5,$5,$7,$5,$5,$2
    .db $5,$2,$5,$7,$5,$5,$7,$7,$5,$5,$7,$5,$5,$5,$2,$5
    .db $2,$7,$5,$5,$5,$7,$5,$5,$7,$7,$5,$5,$7,$2,$5,$5
    .db $7,$5,$5,$7,$5,$5,$5,$7,$5,$5,$7,$7,$2,$5,$7,$5
    .db $5,$7,$7,$5,$5,$7,$5,$5,$5,$7,$5,$2,$7,$7,$5,$5
    .db $7,$5,$5,$7,$7,$5,$5,$7,$5,$5,$2,$7,$5,$5,$7,$7
    .db $5,$5,$7,$5,$5,$7,$7,$5,$5,$2,$5,$5,$5,$7,$5,$5
    .db $7,$5,$5,$5,$7,$5,$5,$7,$2,$5,$5,$7,$5,$5,$5,$7
    .db $5,$5,$7,$5,$5,$5,$7,$2,$5,$7,$7,$5,$5,$7,$5,$5
    .db $7,$7,$5,$5,$7,$5,$2,$5,$7,$5,$5,$7,$7,$5,$5,$7
    .db $5,$5,$7,$7,$5,$2,$7,$5,$5,$5,$7,$5,$5,$7,$7,$5
    .db $5,$7,$5,$5,$2,$7,$5,$5,$7,$5,$5,$5,$7,$5,$5,$7
    .db $5,$5,$5,$2,$5,$5,$7,$7,$5,$5,$7,$5,$5,$5,$7,$5
    .db $5,$7,$2,$5,$5,$7,$5,$5,$7,$7,$5,$5,$7,$5,$5,$2
    .db $7,$2,$5,$7,$5,$5,$5,$7,$5,$5,$7,$7,$5,$5,$2,$5
MC3_TexClay:
    .db $9,$A,$7,$9,$9,$A,$9,$9,$9,$A,$9,$9,$A,$A,$9,$7
    .db $A,$7,$9,$A,$A,$9,$9,$A,$9,$9,$9,$A,$9,$9,$7,$A
    .db $7,$9,$A,$9,$9,$A,$A,$9,$9,$A,$9,$9,$9,$7,$9,$9
    .db $A,$9,$9,$9,$A,$9,$9,$A,$A,$9,$9,$A,$7,$9,$9,$A
    .db $9,$9,$A,$9,$9,$9,$A,$9,$9,$A,$A,$7,$9,$A,$9,$9
    .db $A,$A,$9,$9,$A,$9,$9,$9,$A,$9,$7,$A,$A,$9,$9,$A
    .db $9,$9,$A,$A,$9,$9,$A,$9,$9,$7,$A,$9,$9,$A,$A,$9
    .db $9,$A,$9,$9,$A,$A,$9,$9,$7,$9,$9,$9,$A,$9,$9,$A
    .db $9,$9,$9,$A,$9,$9,$A,$7,$9,$9,$A,$9,$9,$9,$A,$9
    .db $9,$A,$9,$9,$9,$A,$7,$9,$A,$A,$9,$9,$A,$9,$9,$9
    .db $A,$9,$9,$A,$9,$7,$9,$A,$9,$9,$A,$A,$9,$9,$A,$9
    .db $9,$A,$A,$9,$7,$A,$9,$9,$9,$A,$9,$9,$A,$A,$9,$9
    .db $A,$9,$9,$7,$A,$9,$9,$A,$9,$9,$9,$A,$9,$9,$A,$A
    .db $9,$9,$7,$9,$9,$A,$A,$9,$9,$A,$9,$9,$9,$A,$9,$7
    .db $A,$7,$9,$9,$A,$9,$9,$A,$A,$9,$9,$A,$9,$9,$7,$A
    .db $7,$9,$A,$9,$9,$9,$A,$9,$9,$A,$A,$9,$9,$7,$9,$9
MC3_TexTerracotta:
    .db $8,$8,$A,$6,$8,$A,$A,$8,$8,$A,$8,$8,$8,$A,$8,$8
    .db $A,$8,$6,$8,$A,$8,$8,$A,$A,$8,$8,$A,$8,$8,$8,$6
    .db $8,$6,$A,$8,$8,$8,$A,$8,$8,$A,$A,$8,$8,$A,$6,$8
    .db $6,$A,$8,$8,$A,$8,$8,$8,$A,$8,$8,$A,$A,$6,$8,$A
    .db $8,$8,$A,$A,$8,$8,$A,$8,$8,$8,$A,$8,$6,$A,$A,$8
    .db $8,$A,$8,$8,$A,$A,$8,$8,$A,$8,$8,$6,$A,$8,$8,$A
    .db $8,$8,$8,$A,$8,$8,$A,$A,$8,$8,$6,$8,$8,$8,$A,$8
    .db $8,$A,$8,$8,$8,$A,$8,$8,$A,$6,$8,$8,$A,$8,$8,$8
    .db $A,$8,$8,$A,$8,$8,$8,$A,$6,$8,$A,$A,$8,$8,$A,$8
    .db $8,$A,$A,$8,$8,$A,$8,$6,$8,$A,$8,$8,$A,$A,$8,$8
    .db $A,$8,$8,$A,$A,$8,$6,$A,$8,$8,$8,$A,$8,$8,$A,$A
    .db $8,$8,$A,$8,$8,$6,$A,$8,$8,$A,$8,$8,$8,$A,$8,$8
    .db $A,$8,$8,$8,$6,$8,$8,$A,$A,$8,$8,$A,$8,$8,$8,$A
    .db $8,$8,$A,$6,$8,$8,$A,$8,$8,$A,$A,$8,$8,$A,$8,$8
    .db $A,$A,$6,$8,$A,$8,$8,$8,$A,$8,$8,$A,$A,$8,$8,$6
    .db $8,$6,$A,$A,$8,$8,$A,$8,$8,$8,$A,$8,$8,$A,$6,$8
MC3_TexWhiteWool:
    .db $F,$E,$F,$E,$E,$F,$E,$F,$F,$F,$E,$D,$E,$E,$F,$E
    .db $E,$E,$E,$F,$F,$E,$E,$E,$E,$E,$D,$E,$F,$F,$E,$E
    .db $F,$E,$F,$E,$E,$F,$E,$F,$F,$D,$E,$F,$E,$E,$F,$E
    .db $E,$F,$E,$E,$E,$E,$F,$E,$D,$E,$F,$E,$E,$E,$E,$F
    .db $E,$F,$E,$E,$E,$E,$F,$D,$E,$E,$F,$E,$E,$E,$E,$F
    .db $F,$E,$F,$E,$E,$F,$D,$F,$F,$F,$E,$F,$E,$E,$F,$E
    .db $E,$E,$E,$F,$F,$D,$E,$E,$E,$E,$E,$E,$F,$F,$E,$E
    .db $F,$E,$F,$E,$D,$F,$E,$F,$F,$F,$E,$F,$E,$E,$F,$E
    .db $F,$E,$F,$D,$E,$F,$E,$F,$F,$F,$E,$F,$E,$E,$F,$E
    .db $F,$E,$D,$E,$E,$F,$E,$F,$F,$F,$E,$F,$E,$E,$F,$E
    .db $E,$D,$E,$F,$F,$E,$E,$E,$E,$E,$E,$E,$F,$F,$E,$E
    .db $D,$E,$F,$E,$E,$F,$E,$F,$F,$F,$E,$F,$E,$E,$F,$E
    .db $E,$F,$E,$E,$E,$E,$F,$E,$E,$E,$F,$E,$E,$E,$E,$F
    .db $E,$F,$E,$E,$E,$E,$F,$E,$E,$E,$F,$E,$E,$E,$E,$D
    .db $F,$E,$F,$E,$E,$F,$E,$F,$F,$F,$E,$F,$E,$E,$D,$E
    .db $E,$E,$E,$F,$F,$E,$E,$E,$E,$E,$E,$E,$F,$D,$E,$E
MC3_TexBlackWool:
    .db $2,$1,$2,$1,$1,$2,$1,$3,$2,$2,$1,$2,$1,$1,$2,$1
    .db $1,$1,$1,$2,$2,$1,$3,$1,$1,$1,$1,$1,$2,$2,$1,$1
    .db $2,$1,$2,$1,$1,$3,$1,$2,$2,$2,$1,$2,$1,$1,$2,$1
    .db $1,$2,$1,$1,$3,$1,$2,$1,$1,$1,$2,$1,$1,$1,$1,$2
    .db $1,$2,$1,$3,$1,$1,$2,$1,$1,$1,$2,$1,$1,$1,$1,$2
    .db $2,$1,$3,$1,$1,$2,$1,$2,$2,$2,$1,$2,$1,$1,$2,$1
    .db $1,$3,$1,$2,$2,$1,$1,$1,$1,$1,$1,$1,$2,$2,$1,$1
    .db $3,$1,$2,$1,$1,$2,$1,$2,$2,$2,$1,$2,$1,$1,$2,$1
    .db $2,$1,$2,$1,$1,$2,$1,$2,$2,$2,$1,$2,$1,$1,$2,$1
    .db $2,$1,$2,$1,$1,$2,$1,$2,$2,$2,$1,$2,$1,$1,$2,$3
    .db $1,$1,$1,$2,$2,$1,$1,$1,$1,$1,$1,$1,$2,$2,$3,$1
    .db $2,$1,$2,$1,$1,$2,$1,$2,$2,$2,$1,$2,$1,$3,$2,$1
    .db $1,$2,$1,$1,$1,$1,$2,$1,$1,$1,$2,$1,$3,$1,$1,$2
    .db $1,$2,$1,$1,$1,$1,$2,$1,$1,$1,$2,$3,$1,$1,$1,$2
    .db $2,$1,$2,$1,$1,$2,$1,$2,$2,$2,$3,$2,$1,$1,$2,$1
    .db $1,$1,$1,$2,$2,$1,$1,$1,$1,$3,$1,$1,$2,$2,$1,$1
MC3_TexRedWool:
    .db $9,$6,$9,$9,$9,$B,$9,$9,$B,$B,$9,$9,$B,$9,$6,$9
    .db $6,$9,$9,$B,$9,$9,$9,$B,$9,$9,$B,$B,$9,$6,$B,$9
    .db $9,$B,$B,$9,$9,$B,$9,$9,$9,$B,$9,$9,$6,$B,$9,$9
    .db $B,$9,$9,$B,$B,$9,$9,$B,$9,$9,$9,$6,$9,$9,$B,$B
    .db $9,$9,$B,$9,$9,$B,$B,$9,$9,$B,$6,$9,$9,$B,$9,$9
    .db $B,$9,$9,$9,$B,$9,$9,$B,$B,$6,$9,$B,$9,$9,$9,$B
    .db $9,$9,$B,$9,$9,$9,$B,$9,$6,$B,$B,$9,$9,$B,$9,$9
    .db $B,$B,$9,$9,$B,$9,$9,$6,$B,$9,$9,$B,$B,$9,$9,$B
    .db $9,$9,$B,$B,$9,$9,$6,$9,$9,$9,$B,$9,$9,$B,$B,$9
    .db $9,$B,$9,$9,$B,$6,$9,$9,$B,$9,$9,$9,$B,$9,$9,$B
    .db $9,$9,$9,$B,$6,$9,$B,$B,$9,$9,$B,$9,$9,$9,$B,$9
    .db $9,$B,$9,$6,$9,$B,$9,$9,$B,$B,$9,$9,$B,$9,$9,$9
    .db $B,$9,$6,$B,$9,$9,$9,$B,$9,$9,$B,$B,$9,$9,$B,$6
    .db $9,$6,$B,$9,$9,$B,$9,$9,$9,$B,$9,$9,$B,$B,$6,$9
    .db $6,$9,$9,$B,$B,$9,$9,$B,$9,$9,$9,$B,$9,$6,$B,$B
    .db $9,$9,$B,$9,$9,$B,$B,$9,$9,$B,$9,$9,$6,$B,$9,$9
MC3_TexBlueWool:
    .db $3,$5,$3,$3,$3,$5,$3,$3,$5,$5,$1,$3,$5,$3,$3,$3
    .db $5,$3,$3,$5,$3,$3,$3,$5,$3,$1,$5,$5,$3,$3,$5,$3
    .db $3,$5,$5,$3,$3,$5,$3,$3,$1,$5,$3,$3,$5,$5,$3,$3
    .db $5,$3,$3,$5,$5,$3,$3,$1,$3,$3,$3,$5,$3,$3,$5,$5
    .db $3,$3,$5,$3,$3,$5,$1,$3,$3,$5,$3,$3,$3,$5,$3,$3
    .db $5,$3,$3,$3,$5,$1,$3,$5,$5,$3,$3,$5,$3,$3,$3,$5
    .db $3,$3,$5,$3,$1,$3,$5,$3,$3,$5,$5,$3,$3,$5,$3,$3
    .db $5,$5,$3,$1,$5,$3,$3,$3,$5,$3,$3,$5,$5,$3,$3,$5
    .db $3,$3,$1,$5,$3,$3,$5,$3,$3,$3,$5,$3,$3,$5,$5,$1
    .db $3,$1,$3,$3,$5,$5,$3,$3,$5,$3,$3,$3,$5,$3,$1,$5
    .db $1,$3,$3,$5,$3,$3,$5,$5,$3,$3,$5,$3,$3,$1,$5,$3
    .db $3,$5,$3,$3,$3,$5,$3,$3,$5,$5,$3,$3,$1,$3,$3,$3
    .db $5,$3,$3,$5,$3,$3,$3,$5,$3,$3,$5,$1,$3,$3,$5,$3
    .db $3,$5,$5,$3,$3,$5,$3,$3,$3,$5,$1,$3,$5,$5,$3,$3
    .db $5,$3,$3,$5,$5,$3,$3,$5,$3,$1,$3,$5,$3,$3,$5,$5
    .db $3,$3,$5,$3,$3,$5,$5,$3,$1,$5,$3,$3,$3,$5,$3,$3
MC3_TexBook:
    .db $7,$A,$A,$A,$B,$A,$A,$A,$A,$B,$A,$A,$A,$A,$B,$7
    .db $A,$7,$A,$A,$B,$A,$A,$A,$A,$B,$A,$A,$A,$A,$7,$A
    .db $A,$A,$7,$A,$B,$A,$A,$A,$A,$B,$A,$A,$A,$7,$B,$A
    .db $A,$A,$A,$7,$B,$A,$A,$A,$A,$B,$A,$A,$7,$A,$B,$A
    .db $B,$B,$B,$B,$7,$B,$B,$B,$B,$B,$B,$7,$B,$B,$B,$B
    .db $A,$A,$A,$A,$B,$7,$A,$A,$A,$B,$7,$A,$A,$A,$B,$A
    .db $A,$A,$A,$A,$B,$A,$7,$A,$A,$7,$A,$A,$A,$A,$B,$A
    .db $A,$A,$A,$A,$B,$A,$A,$7,$7,$B,$A,$A,$A,$A,$B,$A
    .db $A,$A,$A,$A,$B,$A,$A,$7,$7,$B,$A,$A,$A,$A,$B,$A
    .db $B,$B,$B,$B,$B,$B,$7,$B,$B,$7,$B,$B,$B,$B,$B,$B
    .db $A,$A,$A,$A,$B,$7,$A,$A,$A,$B,$7,$A,$A,$A,$B,$A
    .db $A,$A,$A,$A,$7,$A,$A,$A,$A,$B,$A,$7,$A,$A,$B,$A
    .db $A,$A,$A,$7,$B,$A,$A,$A,$A,$B,$A,$A,$7,$A,$B,$A
    .db $A,$A,$7,$A,$B,$A,$A,$A,$A,$B,$A,$A,$A,$7,$B,$A
    .db $B,$7,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$7,$B
    .db $7,$A,$A,$A,$B,$A,$A,$A,$A,$B,$A,$A,$A,$A,$B,$7
MC3_TexPrismarine:
    .db $8,$9,$8,$8,$8,$A,$8,$8,$A,$A,$8,$8,$A,$8,$9,$8
    .db $9,$8,$8,$A,$8,$8,$8,$A,$8,$8,$A,$A,$8,$9,$A,$8
    .db $8,$A,$A,$8,$8,$A,$8,$8,$8,$A,$8,$8,$9,$A,$8,$8
    .db $A,$8,$8,$A,$A,$8,$8,$A,$8,$8,$8,$9,$8,$8,$A,$A
    .db $8,$8,$A,$8,$8,$A,$A,$8,$8,$A,$9,$8,$8,$A,$8,$8
    .db $A,$8,$8,$8,$A,$8,$8,$A,$A,$9,$8,$A,$8,$8,$8,$A
    .db $8,$8,$A,$8,$8,$8,$A,$8,$9,$A,$A,$8,$8,$A,$8,$8
    .db $A,$A,$8,$8,$A,$8,$8,$9,$A,$8,$8,$A,$A,$8,$8,$A
    .db $8,$8,$A,$A,$8,$8,$9,$8,$8,$8,$A,$8,$8,$A,$A,$8
    .db $8,$A,$8,$8,$A,$9,$8,$8,$A,$8,$8,$8,$A,$8,$8,$A
    .db $8,$8,$8,$A,$9,$8,$A,$A,$8,$8,$A,$8,$8,$8,$A,$8
    .db $8,$A,$8,$9,$8,$A,$8,$8,$A,$A,$8,$8,$A,$8,$8,$8
    .db $A,$8,$9,$A,$8,$8,$8,$A,$8,$8,$A,$A,$8,$8,$A,$9
    .db $8,$9,$A,$8,$8,$A,$8,$8,$8,$A,$8,$8,$A,$A,$9,$8
    .db $9,$8,$8,$A,$A,$8,$8,$A,$8,$8,$8,$A,$8,$9,$A,$A
    .db $8,$8,$A,$8,$8,$A,$A,$8,$8,$A,$8,$8,$9,$A,$8,$8
MC3_TexSeaLantern:
    .db $A,$C,$E,$C,$C,$E,$C,$E,$E,$E,$C,$E,$C,$C,$E,$C
    .db $C,$C,$C,$E,$E,$C,$C,$C,$C,$C,$C,$C,$E,$E,$C,$C
    .db $E,$C,$E,$C,$C,$E,$C,$E,$E,$E,$C,$E,$C,$C,$E,$A
    .db $C,$E,$C,$C,$C,$C,$E,$C,$C,$C,$E,$C,$C,$C,$A,$E
    .db $C,$E,$C,$C,$C,$C,$E,$C,$C,$C,$E,$C,$C,$A,$C,$E
    .db $E,$C,$E,$C,$C,$E,$C,$E,$E,$E,$C,$E,$A,$C,$E,$C
    .db $C,$C,$C,$E,$E,$C,$C,$C,$C,$C,$C,$A,$E,$E,$C,$C
    .db $E,$C,$E,$C,$C,$E,$C,$E,$E,$E,$A,$E,$C,$C,$E,$C
    .db $E,$C,$E,$C,$C,$E,$C,$E,$E,$A,$C,$E,$C,$C,$E,$C
    .db $E,$C,$E,$C,$C,$E,$C,$E,$A,$E,$C,$E,$C,$C,$E,$C
    .db $C,$C,$C,$E,$E,$C,$C,$A,$C,$C,$C,$C,$E,$E,$C,$C
    .db $E,$C,$E,$C,$C,$E,$A,$E,$E,$E,$C,$E,$C,$C,$E,$C
    .db $C,$E,$C,$C,$C,$A,$E,$C,$C,$C,$E,$C,$C,$C,$C,$E
    .db $C,$E,$C,$C,$A,$C,$E,$C,$C,$C,$E,$C,$C,$C,$C,$E
    .db $E,$C,$E,$A,$C,$E,$C,$E,$E,$E,$C,$E,$C,$C,$E,$C
    .db $C,$C,$A,$E,$E,$C,$C,$C,$C,$C,$C,$C,$E,$E,$C,$C
MC3_TexMagma:
    .db $8,$8,$8,$3,$8,$8,$A,$3,$8,$8,$3,$8,$8,$8,$3,$8
    .db $8,$3,$8,$8,$8,$A,$8,$8,$3,$3,$8,$8,$3,$8,$8,$8
    .db $3,$8,$8,$3,$A,$8,$8,$3,$8,$8,$3,$3,$8,$8,$3,$8
    .db $8,$3,$3,$A,$8,$3,$8,$8,$8,$3,$8,$8,$3,$3,$8,$8
    .db $3,$8,$A,$3,$3,$8,$8,$3,$8,$8,$8,$3,$8,$8,$3,$A
    .db $8,$A,$3,$8,$8,$3,$3,$8,$8,$3,$8,$8,$8,$3,$A,$8
    .db $A,$8,$8,$8,$3,$8,$8,$3,$3,$8,$8,$3,$8,$A,$8,$3
    .db $8,$8,$3,$8,$8,$8,$3,$8,$8,$3,$3,$8,$A,$3,$8,$8
    .db $3,$3,$8,$8,$3,$8,$8,$8,$3,$8,$8,$A,$3,$8,$8,$3
    .db $8,$8,$3,$3,$8,$8,$3,$8,$8,$8,$A,$8,$8,$3,$3,$8
    .db $8,$3,$8,$8,$3,$3,$8,$8,$3,$A,$8,$8,$3,$8,$8,$3
    .db $8,$8,$8,$3,$8,$8,$3,$3,$A,$8,$3,$8,$8,$8,$3,$8
    .db $8,$3,$8,$8,$8,$3,$8,$A,$3,$3,$8,$8,$3,$8,$8,$8
    .db $3,$8,$8,$3,$8,$8,$A,$3,$8,$8,$3,$3,$8,$8,$3,$8
    .db $8,$3,$3,$8,$8,$A,$8,$8,$8,$3,$8,$8,$3,$3,$8,$8
    .db $3,$8,$8,$3,$A,$8,$8,$3,$8,$8,$8,$3,$8,$8,$3,$3
MC3_TexBasalt:
    .db $3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$3
    .db $3,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$5,$4,$4,$5,$3
    .db $3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3,$3
MC3_TexBlackstone:
    .db $2,$2,$3,$2,$2,$3,$3,$2,$2,$3,$2,$2,$4,$3,$2,$2
    .db $3,$2,$2,$2,$3,$2,$2,$3,$3,$2,$2,$4,$2,$2,$2,$3
    .db $2,$2,$3,$2,$2,$2,$3,$2,$2,$3,$4,$2,$2,$3,$2,$2
    .db $3,$3,$2,$2,$3,$2,$2,$2,$3,$4,$2,$3,$3,$2,$2,$3
    .db $2,$2,$3,$3,$2,$2,$3,$2,$4,$2,$3,$2,$2,$3,$3,$2
    .db $2,$3,$2,$2,$3,$3,$2,$4,$3,$2,$2,$2,$3,$2,$2,$3
    .db $2,$2,$2,$3,$2,$2,$4,$3,$2,$2,$3,$2,$2,$2,$3,$2
    .db $2,$3,$2,$2,$2,$4,$2,$2,$3,$3,$2,$2,$3,$2,$2,$2
    .db $3,$2,$2,$3,$4,$2,$2,$3,$2,$2,$3,$3,$2,$2,$3,$2
    .db $2,$3,$3,$4,$2,$3,$2,$2,$2,$3,$2,$2,$3,$3,$2,$2
    .db $3,$2,$4,$3,$3,$2,$2,$3,$2,$2,$2,$3,$2,$2,$3,$4
    .db $2,$4,$3,$2,$2,$3,$3,$2,$2,$3,$2,$2,$2,$3,$4,$2
    .db $4,$2,$2,$2,$3,$2,$2,$3,$3,$2,$2,$3,$2,$4,$2,$3
    .db $2,$2,$3,$2,$2,$2,$3,$2,$2,$3,$3,$2,$4,$3,$2,$2
    .db $3,$3,$2,$2,$3,$2,$2,$2,$3,$2,$2,$4,$3,$2,$2,$3
    .db $2,$2,$3,$3,$2,$2,$3,$2,$2,$2,$4,$2,$2,$3,$3,$2
MC3_TexDeepslate:
    .db $3,$4,$3,$3,$3,$4,$3,$3,$4,$4,$2,$3,$4,$3,$3,$3
    .db $4,$3,$3,$4,$3,$3,$3,$4,$3,$2,$4,$4,$3,$3,$4,$3
    .db $3,$4,$4,$3,$3,$4,$3,$3,$2,$4,$3,$3,$4,$4,$3,$3
    .db $4,$3,$3,$4,$4,$3,$3,$2,$3,$3,$3,$4,$3,$3,$4,$4
    .db $3,$3,$4,$3,$3,$4,$2,$3,$3,$4,$3,$3,$3,$4,$3,$3
    .db $4,$3,$3,$3,$4,$2,$3,$4,$4,$3,$3,$4,$3,$3,$3,$4
    .db $3,$3,$4,$3,$2,$3,$4,$3,$3,$4,$4,$3,$3,$4,$3,$3
    .db $4,$4,$3,$2,$4,$3,$3,$3,$4,$3,$3,$4,$4,$3,$3,$4
    .db $3,$3,$2,$4,$3,$3,$4,$3,$3,$3,$4,$3,$3,$4,$4,$2
    .db $3,$2,$3,$3,$4,$4,$3,$3,$4,$3,$3,$3,$4,$3,$2,$4
    .db $2,$3,$3,$4,$3,$3,$4,$4,$3,$3,$4,$3,$3,$2,$4,$3
    .db $3,$4,$3,$3,$3,$4,$3,$3,$4,$4,$3,$3,$2,$3,$3,$3
    .db $4,$3,$3,$4,$3,$3,$3,$4,$3,$3,$4,$2,$3,$3,$4,$3
    .db $3,$4,$4,$3,$3,$4,$3,$3,$3,$4,$2,$3,$4,$4,$3,$3
    .db $4,$3,$3,$4,$4,$3,$3,$4,$3,$2,$3,$4,$3,$3,$4,$4
    .db $3,$3,$4,$3,$3,$4,$4,$3,$2,$4,$3,$3,$3,$4,$3,$3
MC3_TexAmethyst:
    .db $D,$B,$D,$B,$B,$D,$B,$D,$D,$D,$B,$D,$B,$B,$D,$F
    .db $B,$B,$B,$D,$D,$B,$B,$B,$B,$B,$B,$B,$D,$D,$F,$B
    .db $D,$B,$D,$B,$B,$D,$B,$D,$D,$D,$B,$D,$B,$F,$D,$B
    .db $B,$D,$B,$B,$B,$B,$D,$B,$B,$B,$D,$B,$F,$B,$B,$D
    .db $B,$D,$B,$B,$B,$B,$D,$B,$B,$B,$D,$F,$B,$B,$B,$D
    .db $D,$B,$D,$B,$B,$D,$B,$D,$D,$D,$F,$D,$B,$B,$D,$B
    .db $B,$B,$B,$D,$D,$B,$B,$B,$B,$F,$B,$B,$D,$D,$B,$B
    .db $D,$B,$D,$B,$B,$D,$B,$D,$F,$D,$B,$D,$B,$B,$D,$B
    .db $D,$B,$D,$B,$B,$D,$B,$F,$D,$D,$B,$D,$B,$B,$D,$B
    .db $D,$B,$D,$B,$B,$D,$F,$D,$D,$D,$B,$D,$B,$B,$D,$B
    .db $B,$B,$B,$D,$D,$F,$B,$B,$B,$B,$B,$B,$D,$D,$B,$B
    .db $D,$B,$D,$B,$F,$D,$B,$D,$D,$D,$B,$D,$B,$B,$D,$B
    .db $B,$D,$B,$F,$B,$B,$D,$B,$B,$B,$D,$B,$B,$B,$B,$D
    .db $B,$D,$F,$B,$B,$B,$D,$B,$B,$B,$D,$B,$B,$B,$B,$D
    .db $D,$F,$D,$B,$B,$D,$B,$D,$D,$D,$B,$D,$B,$B,$D,$B
    .db $F,$B,$B,$D,$D,$B,$B,$B,$B,$B,$B,$B,$D,$D,$B,$B
MC3_TexCopper:
    .db $C,$C,$9,$9,$C,$9,$9,$9,$C,$9,$9,$C,$6,$9,$9,$C
    .db $9,$9,$C,$C,$9,$9,$C,$9,$9,$9,$C,$6,$9,$C,$C,$9
    .db $9,$C,$9,$9,$C,$C,$9,$9,$C,$9,$6,$9,$C,$9,$9,$C
    .db $9,$9,$9,$C,$9,$9,$C,$C,$9,$6,$C,$9,$9,$9,$C,$9
    .db $9,$C,$9,$9,$9,$C,$9,$9,$6,$C,$9,$9,$C,$9,$9,$9
    .db $C,$9,$9,$C,$9,$9,$9,$6,$9,$9,$C,$C,$9,$9,$C,$9
    .db $9,$C,$C,$9,$9,$C,$6,$9,$9,$C,$9,$9,$C,$C,$9,$9
    .db $C,$9,$9,$C,$C,$6,$9,$C,$9,$9,$9,$C,$9,$9,$C,$C
    .db $9,$9,$C,$9,$6,$C,$C,$9,$9,$C,$9,$9,$9,$C,$9,$9
    .db $C,$9,$9,$6,$C,$9,$9,$C,$C,$9,$9,$C,$9,$9,$9,$C
    .db $9,$9,$6,$9,$9,$9,$C,$9,$9,$C,$C,$9,$9,$C,$9,$6
    .db $C,$6,$9,$9,$C,$9,$9,$9,$C,$9,$9,$C,$C,$9,$6,$C
    .db $6,$9,$C,$C,$9,$9,$C,$9,$9,$9,$C,$9,$9,$6,$C,$9
    .db $9,$C,$9,$9,$C,$C,$9,$9,$C,$9,$9,$9,$6,$9,$9,$C
    .db $9,$9,$9,$C,$9,$9,$C,$C,$9,$9,$C,$6,$9,$9,$C,$9
    .db $9,$C,$9,$9,$9,$C,$9,$9,$C,$C,$6,$9,$C,$9,$9,$9
MC3_TexRawCopper:
    .db $7,$7,$7,$A,$7,$7,$4,$A,$7,$7,$A,$7,$7,$7,$A,$7
    .db $7,$A,$7,$7,$7,$4,$7,$7,$A,$A,$7,$7,$A,$7,$7,$7
    .db $A,$7,$7,$A,$4,$7,$7,$A,$7,$7,$A,$A,$7,$7,$A,$7
    .db $7,$A,$A,$4,$7,$A,$7,$7,$7,$A,$7,$7,$A,$A,$7,$7
    .db $A,$7,$4,$A,$A,$7,$7,$A,$7,$7,$7,$A,$7,$7,$A,$4
    .db $7,$4,$A,$7,$7,$A,$A,$7,$7,$A,$7,$7,$7,$A,$4,$7
    .db $4,$7,$7,$7,$A,$7,$7,$A,$A,$7,$7,$A,$7,$4,$7,$A
    .db $7,$7,$A,$7,$7,$7,$A,$7,$7,$A,$A,$7,$4,$A,$7,$7
    .db $A,$A,$7,$7,$A,$7,$7,$7,$A,$7,$7,$4,$A,$7,$7,$A
    .db $7,$7,$A,$A,$7,$7,$A,$7,$7,$7,$4,$7,$7,$A,$A,$7
    .db $7,$A,$7,$7,$A,$A,$7,$7,$A,$4,$7,$7,$A,$7,$7,$A
    .db $7,$7,$7,$A,$7,$7,$A,$A,$4,$7,$A,$7,$7,$7,$A,$7
    .db $7,$A,$7,$7,$7,$A,$7,$4,$A,$A,$7,$7,$A,$7,$7,$7
    .db $A,$7,$7,$A,$7,$7,$4,$A,$7,$7,$A,$A,$7,$7,$A,$7
    .db $7,$A,$A,$7,$7,$4,$7,$7,$7,$A,$7,$7,$A,$A,$7,$7
    .db $A,$7,$7,$A,$4,$7,$7,$A,$7,$7,$7,$A,$7,$7,$A,$A
MC3_TexCopperBlock:
    .db $6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$6
    .db $6,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$8,$A,$A,$8,$6
    .db $6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6,$6
MC3_TexMud:
    .db $6,$4,$4,$6,$6,$4,$2,$6,$4,$4,$4,$6,$4,$4,$6,$6
    .db $4,$4,$6,$4,$4,$2,$6,$4,$4,$6,$4,$4,$4,$6,$4,$4
    .db $6,$4,$4,$4,$2,$4,$4,$6,$6,$4,$4,$6,$4,$4,$4,$6
    .db $4,$4,$6,$2,$4,$4,$6,$4,$4,$6,$6,$4,$4,$6,$4,$4
    .db $6,$6,$2,$4,$6,$4,$4,$4,$6,$4,$4,$6,$6,$4,$4,$2
    .db $4,$2,$6,$6,$4,$4,$6,$4,$4,$4,$6,$4,$4,$6,$2,$4
    .db $2,$6,$4,$4,$6,$6,$4,$4,$6,$4,$4,$4,$6,$2,$4,$6
    .db $4,$4,$4,$6,$4,$4,$6,$6,$4,$4,$6,$4,$2,$4,$6,$4
    .db $4,$6,$4,$4,$4,$6,$4,$4,$6,$6,$4,$2,$6,$4,$4,$4
    .db $6,$4,$4,$6,$4,$4,$4,$6,$4,$4,$2,$6,$4,$4,$6,$4
    .db $4,$6,$6,$4,$4,$6,$4,$4,$4,$2,$4,$4,$6,$6,$4,$4
    .db $6,$4,$4,$6,$6,$4,$4,$6,$2,$4,$4,$6,$4,$4,$6,$6
    .db $4,$4,$6,$4,$4,$6,$6,$2,$4,$6,$4,$4,$4,$6,$4,$4
    .db $6,$4,$4,$4,$6,$4,$2,$6,$6,$4,$4,$6,$4,$4,$4,$6
    .db $4,$4,$6,$4,$4,$2,$6,$4,$4,$6,$6,$4,$4,$6,$4,$4
    .db $6,$6,$4,$4,$2,$4,$4,$4,$6,$4,$4,$6,$6,$4,$4,$6
MC3_TexPackedIce:
    .db $C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$C
    .db $C,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$B,$A,$A,$B,$C
    .db $C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C
MC3_TexBlueIce:
    .db $8,$5,$8,$5,$5,$8,$5,$8,$8,$8,$5,$8,$5,$5,$8,$B
    .db $5,$5,$5,$8,$8,$5,$5,$5,$5,$5,$5,$5,$8,$8,$B,$5
    .db $8,$5,$8,$5,$5,$8,$5,$8,$8,$8,$5,$8,$5,$B,$8,$5
    .db $5,$8,$5,$5,$5,$5,$8,$5,$5,$5,$8,$5,$B,$5,$5,$8
    .db $5,$8,$5,$5,$5,$5,$8,$5,$5,$5,$8,$B,$5,$5,$5,$8
    .db $8,$5,$8,$5,$5,$8,$5,$8,$8,$8,$B,$8,$5,$5,$8,$5
    .db $5,$5,$5,$8,$8,$5,$5,$5,$5,$B,$5,$5,$8,$8,$5,$5
    .db $8,$5,$8,$5,$5,$8,$5,$8,$B,$8,$5,$8,$5,$5,$8,$5
    .db $8,$5,$8,$5,$5,$8,$5,$B,$8,$8,$5,$8,$5,$5,$8,$5
    .db $8,$5,$8,$5,$5,$8,$B,$8,$8,$8,$5,$8,$5,$5,$8,$5
    .db $5,$5,$5,$8,$8,$B,$5,$5,$5,$5,$5,$5,$8,$8,$5,$5
    .db $8,$5,$8,$5,$B,$8,$5,$8,$8,$8,$5,$8,$5,$5,$8,$5
    .db $5,$8,$5,$B,$5,$5,$8,$5,$5,$5,$8,$5,$5,$5,$5,$8
    .db $5,$8,$B,$5,$5,$5,$8,$5,$5,$5,$8,$5,$5,$5,$5,$8
    .db $8,$B,$8,$5,$5,$8,$5,$8,$8,$8,$5,$8,$5,$5,$8,$5
    .db $B,$5,$5,$8,$8,$5,$5,$5,$5,$5,$5,$5,$8,$8,$5,$5
MC3_TexBamboo:
    .db $5,$9,$B,$9,$9,$9,$9,$B,$9,$9,$9,$9,$B,$9,$9,$5
    .db $9,$5,$B,$9,$9,$9,$9,$B,$9,$9,$9,$9,$B,$9,$5,$9
    .db $B,$B,$5,$B,$B,$B,$B,$B,$B,$B,$B,$B,$B,$5,$B,$B
    .db $9,$9,$B,$5,$9,$9,$9,$B,$9,$9,$9,$9,$5,$9,$9,$9
    .db $9,$9,$B,$9,$5,$9,$9,$B,$9,$9,$9,$5,$B,$9,$9,$9
    .db $9,$9,$B,$9,$9,$5,$9,$B,$9,$9,$5,$9,$B,$9,$9,$9
    .db $9,$9,$B,$9,$9,$9,$5,$B,$9,$5,$9,$9,$B,$9,$9,$9
    .db $B,$B,$B,$B,$B,$B,$B,$5,$5,$B,$B,$B,$B,$B,$B,$B
    .db $9,$9,$B,$9,$9,$9,$9,$5,$5,$9,$9,$9,$B,$9,$9,$9
    .db $9,$9,$B,$9,$9,$9,$5,$B,$9,$5,$9,$9,$B,$9,$9,$9
    .db $9,$9,$B,$9,$9,$5,$9,$B,$9,$9,$5,$9,$B,$9,$9,$9
    .db $9,$9,$B,$9,$5,$9,$9,$B,$9,$9,$9,$5,$B,$9,$9,$9
    .db $B,$B,$B,$5,$B,$B,$B,$B,$B,$B,$B,$B,$5,$B,$B,$B
    .db $9,$9,$5,$9,$9,$9,$9,$B,$9,$9,$9,$9,$B,$5,$9,$9
    .db $9,$5,$B,$9,$9,$9,$9,$B,$9,$9,$9,$9,$B,$9,$5,$9
    .db $5,$9,$B,$9,$9,$9,$9,$B,$9,$9,$9,$9,$B,$9,$9,$5
MC3_TexBambooPlank:
    .db $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
    .db $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
    .db $8,$A,$A,$6,$A,$A,$8,$A,$A,$8,$A,$A,$6,$A,$A,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$A,$A,$6,$A,$A,$8,$A,$A,$8,$A,$A,$6,$A,$A,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$A,$A,$6,$A,$A,$8,$A,$A,$8,$A,$A,$6,$A,$A,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$A,$A,$6,$A,$A,$8,$A,$A,$8,$A,$A,$6,$A,$A,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
    .db $8,$A,$A,$6,$A,$A,$8,$A,$A,$8,$A,$A,$6,$A,$A,$8
    .db $8,$8,$8,$6,$8,$8,$8,$8,$8,$8,$8,$8,$6,$8,$8,$8
MC3_TexSculk:
    .db $4,$2,$4,$3,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $2,$2,$3,$4,$4,$2,$2,$2,$2,$2,$2,$2,$4,$4,$2,$2
    .db $4,$3,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $3,$4,$2,$2,$2,$2,$4,$2,$2,$2,$4,$2,$2,$2,$2,$4
    .db $2,$4,$2,$2,$2,$2,$4,$2,$2,$2,$4,$2,$2,$2,$2,$4
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$2,$4,$3
    .db $2,$2,$2,$4,$4,$2,$2,$2,$2,$2,$2,$2,$4,$4,$3,$2
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$2,$3,$4,$2
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$4,$3,$2,$4,$2
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$4,$2,$3,$2,$2,$4,$2
    .db $2,$2,$2,$4,$4,$2,$2,$2,$2,$2,$3,$2,$4,$4,$2,$2
    .db $4,$2,$4,$2,$2,$4,$2,$4,$4,$3,$2,$4,$2,$2,$4,$2
    .db $2,$4,$2,$2,$2,$2,$4,$2,$3,$2,$4,$2,$2,$2,$2,$4
    .db $2,$4,$2,$2,$2,$2,$4,$3,$2,$2,$4,$2,$2,$2,$2,$4
    .db $4,$2,$4,$2,$2,$4,$3,$4,$4,$4,$2,$4,$2,$2,$4,$2
    .db $2,$2,$2,$4,$4,$3,$2,$2,$2,$2,$2,$2,$4,$4,$2,$2
MC3_TexDripstone:
    .db $4,$6,$8,$6,$6,$6,$6,$8,$6,$6,$6,$6,$8,$6,$6,$4
    .db $6,$4,$8,$6,$6,$6,$6,$8,$6,$6,$6,$6,$8,$6,$4,$6
    .db $8,$8,$4,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$4,$8,$8
    .db $6,$6,$8,$4,$6,$6,$6,$8,$6,$6,$6,$6,$4,$6,$6,$6
    .db $6,$6,$8,$6,$4,$6,$6,$8,$6,$6,$6,$4,$8,$6,$6,$6
    .db $6,$6,$8,$6,$6,$4,$6,$8,$6,$6,$4,$6,$8,$6,$6,$6
    .db $6,$6,$8,$6,$6,$6,$4,$8,$6,$4,$6,$6,$8,$6,$6,$6
    .db $8,$8,$8,$8,$8,$8,$8,$4,$4,$8,$8,$8,$8,$8,$8,$8
    .db $6,$6,$8,$6,$6,$6,$6,$4,$4,$6,$6,$6,$8,$6,$6,$6
    .db $6,$6,$8,$6,$6,$6,$4,$8,$6,$4,$6,$6,$8,$6,$6,$6
    .db $6,$6,$8,$6,$6,$4,$6,$8,$6,$6,$4,$6,$8,$6,$6,$6
    .db $6,$6,$8,$6,$4,$6,$6,$8,$6,$6,$6,$4,$8,$6,$6,$6
    .db $8,$8,$8,$4,$8,$8,$8,$8,$8,$8,$8,$8,$4,$8,$8,$8
    .db $6,$6,$4,$6,$6,$6,$6,$8,$6,$6,$6,$6,$8,$4,$6,$6
    .db $6,$4,$8,$6,$6,$6,$6,$8,$6,$6,$6,$6,$8,$6,$4,$6
    .db $4,$6,$8,$6,$6,$6,$6,$8,$6,$6,$6,$6,$8,$6,$6,$4
MC3_TexCalcite:
    .db $C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$C
    .db $C,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$D,$E,$E,$D,$C
    .db $C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C,$C
MC3_TexTuff:
    .db $8,$8,$7,$7,$8,$7,$7,$7,$8,$7,$5,$8,$8,$7,$7,$8
    .db $7,$7,$8,$8,$7,$7,$8,$7,$7,$5,$8,$7,$7,$8,$8,$7
    .db $7,$8,$7,$7,$8,$8,$7,$7,$5,$7,$7,$7,$8,$7,$7,$8
    .db $7,$7,$7,$8,$7,$7,$8,$5,$7,$7,$8,$7,$7,$7,$8,$7
    .db $7,$8,$7,$7,$7,$8,$5,$7,$8,$8,$7,$7,$8,$7,$7,$7
    .db $8,$7,$7,$8,$7,$5,$7,$8,$7,$7,$8,$8,$7,$7,$8,$7
    .db $7,$8,$8,$7,$5,$8,$7,$7,$7,$8,$7,$7,$8,$8,$7,$7
    .db $8,$7,$7,$5,$8,$7,$7,$8,$7,$7,$7,$8,$7,$7,$8,$8
    .db $7,$7,$5,$7,$7,$8,$8,$7,$7,$8,$7,$7,$7,$8,$7,$5
    .db $8,$5,$7,$7,$8,$7,$7,$8,$8,$7,$7,$8,$7,$7,$5,$8
    .db $5,$7,$8,$7,$7,$7,$8,$7,$7,$8,$8,$7,$7,$5,$7,$7
    .db $8,$8,$7,$7,$8,$7,$7,$7,$8,$7,$7,$8,$5,$7,$7,$8
    .db $7,$7,$8,$8,$7,$7,$8,$7,$7,$7,$8,$5,$7,$8,$8,$7
    .db $7,$8,$7,$7,$8,$8,$7,$7,$8,$7,$5,$7,$8,$7,$7,$8
    .db $7,$7,$7,$8,$7,$7,$8,$8,$7,$5,$8,$7,$7,$7,$8,$7
    .db $7,$8,$7,$7,$7,$8,$7,$7,$5,$8,$7,$7,$8,$7,$7,$7
MC3_TexRedSand:
    .db $8,$8,$8,$9,$8,$8,$5,$9,$8,$8,$9,$8,$8,$8,$9,$8
    .db $8,$9,$8,$8,$8,$5,$8,$8,$9,$9,$8,$8,$9,$8,$8,$8
    .db $9,$8,$8,$9,$5,$8,$8,$9,$8,$8,$9,$9,$8,$8,$9,$8
    .db $8,$9,$9,$5,$8,$9,$8,$8,$8,$9,$8,$8,$9,$9,$8,$8
    .db $9,$8,$5,$9,$9,$8,$8,$9,$8,$8,$8,$9,$8,$8,$9,$5
    .db $8,$5,$9,$8,$8,$9,$9,$8,$8,$9,$8,$8,$8,$9,$5,$8
    .db $5,$8,$8,$8,$9,$8,$8,$9,$9,$8,$8,$9,$8,$5,$8,$9
    .db $8,$8,$9,$8,$8,$8,$9,$8,$8,$9,$9,$8,$5,$9,$8,$8
    .db $9,$9,$8,$8,$9,$8,$8,$8,$9,$8,$8,$5,$9,$8,$8,$9
    .db $8,$8,$9,$9,$8,$8,$9,$8,$8,$8,$5,$8,$8,$9,$9,$8
    .db $8,$9,$8,$8,$9,$9,$8,$8,$9,$5,$8,$8,$9,$8,$8,$9
    .db $8,$8,$8,$9,$8,$8,$9,$9,$5,$8,$9,$8,$8,$8,$9,$8
    .db $8,$9,$8,$8,$8,$9,$8,$5,$9,$9,$8,$8,$9,$8,$8,$8
    .db $9,$8,$8,$9,$8,$8,$5,$9,$8,$8,$9,$9,$8,$8,$9,$8
    .db $8,$9,$9,$8,$8,$5,$8,$8,$8,$9,$8,$8,$9,$9,$8,$8
    .db $9,$8,$8,$9,$5,$8,$8,$9,$8,$8,$8,$9,$8,$8,$9,$9
MC3_TexPrismarineBrick:
    .db $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$8
    .db $8,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$9,$7,$7,$9,$8
    .db $8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8,$8
MC3_TexDarkPrismarine:
    .db $3,$5,$3,$3,$5,$5,$3,$3,$5,$2,$3,$3,$5,$3,$3,$5
    .db $3,$3,$3,$5,$3,$3,$5,$5,$2,$3,$5,$3,$3,$3,$5,$3
    .db $3,$5,$3,$3,$3,$5,$3,$2,$5,$5,$3,$3,$5,$3,$3,$3
    .db $5,$3,$3,$5,$3,$3,$2,$5,$3,$3,$5,$5,$3,$3,$5,$3
    .db $3,$5,$5,$3,$3,$2,$3,$3,$3,$5,$3,$3,$5,$5,$3,$3
    .db $5,$3,$3,$5,$2,$3,$3,$5,$3,$3,$3,$5,$3,$3,$5,$5
    .db $3,$3,$5,$2,$3,$5,$5,$3,$3,$5,$3,$3,$3,$5,$3,$3
    .db $5,$3,$2,$3,$5,$3,$3,$5,$5,$3,$3,$5,$3,$3,$3,$2
    .db $3,$2,$5,$3,$3,$3,$5,$3,$3,$5,$5,$3,$3,$5,$2,$3
    .db $2,$5,$3,$3,$5,$3,$3,$3,$5,$3,$3,$5,$5,$2,$3,$5
    .db $3,$3,$5,$5,$3,$3,$5,$3,$3,$3,$5,$3,$2,$5,$5,$3
    .db $3,$5,$3,$3,$5,$5,$3,$3,$5,$3,$3,$2,$5,$3,$3,$5
    .db $3,$3,$3,$5,$3,$3,$5,$5,$3,$3,$2,$3,$3,$3,$5,$3
    .db $3,$5,$3,$3,$3,$5,$3,$3,$5,$2,$3,$3,$5,$3,$3,$3
    .db $5,$3,$3,$5,$3,$3,$3,$5,$2,$3,$5,$5,$3,$3,$5,$3
    .db $3,$5,$5,$3,$3,$5,$3,$2,$3,$5,$3,$3,$5,$5,$3,$3
MC3_TexEndRod:
    .db $D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D
    .db $D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D,$D
    .db $E,$D,$E,$B,$D,$E,$E,$D,$E,$E,$D,$E,$B,$D,$E,$E
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $E,$D,$E,$B,$D,$E,$E,$D,$E,$E,$D,$E,$B,$D,$E,$E
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $E,$D,$E,$B,$D,$E,$E,$D,$E,$E,$D,$E,$B,$D,$E,$E
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $E,$D,$E,$B,$D,$E,$E,$D,$E,$E,$D,$E,$B,$D,$E,$E
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D
    .db $E,$D,$E,$B,$D,$E,$E,$D,$E,$E,$D,$E,$B,$D,$E,$E
    .db $D,$D,$D,$B,$D,$D,$D,$D,$D,$D,$D,$D,$B,$D,$D,$D

;------------------------------------------------------------------------------
; EXTENDED RECIPE / ITEM / DROP METADATA
; Each record: item,ingredient1,qty1,ingredient2,qty2,outputQty.
;------------------------------------------------------------------------------
MC3_RecipeTable:
    .db 60,1,1,1,2,1
    .db 61,4,2,6,3,2
    .db 62,7,3,11,1,3
    .db 63,10,4,16,2,4
    .db 64,13,1,21,3,1
    .db 65,16,2,26,1,2
    .db 66,19,3,1,2,3
    .db 67,22,4,6,3,4
    .db 68,25,1,11,1,1
    .db 69,28,2,16,2,2
    .db 70,1,3,21,3,3
    .db 71,4,4,26,1,4
    .db 72,7,1,1,2,1
    .db 73,10,2,6,3,2
    .db 74,13,3,11,1,3
    .db 75,16,4,16,2,4
    .db 76,19,1,21,3,1
    .db 77,22,2,26,1,2
    .db 78,25,3,1,2,3
    .db 79,28,4,6,3,4
    .db 80,1,1,11,1,1
    .db 81,4,2,16,2,2
    .db 82,7,3,21,3,3
    .db 83,10,4,26,1,4
    .db 84,13,1,1,2,1
    .db 85,16,2,6,3,2
    .db 86,19,3,11,1,3
    .db 87,22,4,16,2,4
    .db 88,25,1,21,3,1
    .db 89,28,2,26,1,2
    .db 90,1,3,1,2,3
    .db 91,4,4,6,3,4
    .db 92,7,1,11,1,1
    .db 93,10,2,16,2,2
    .db 94,13,3,21,3,3
    .db 60,16,4,26,1,4
    .db 61,19,1,1,2,1
    .db 62,22,2,6,3,2
    .db 63,25,3,11,1,3
    .db 64,28,4,16,2,4
    .db 65,1,1,21,3,1
    .db 66,4,2,26,1,2
    .db 67,7,3,1,2,3
    .db 68,10,4,6,3,4
    .db 69,13,1,11,1,1
    .db 70,16,2,16,2,2
    .db 71,19,3,21,3,3
    .db 72,22,4,26,1,4
    .db 73,25,1,1,2,1
    .db 74,28,2,6,3,2
    .db 75,1,3,11,1,3
    .db 76,4,4,16,2,4
    .db 77,7,1,21,3,1
    .db 78,10,2,26,1,2
    .db 79,13,3,1,2,3
    .db 80,16,4,6,3,4
    .db 81,19,1,11,1,1
    .db 82,22,2,16,2,2
    .db 83,25,3,21,3,3
    .db 84,28,4,26,1,4
    .db 85,1,1,1,2,1
    .db 86,4,2,6,3,2
    .db 87,7,3,11,1,3
    .db 88,10,4,16,2,4
    .db 89,13,1,21,3,1
    .db 90,16,2,26,1,2
    .db 91,19,3,1,2,3
    .db 92,22,4,6,3,4
    .db 93,25,1,11,1,1
    .db 94,28,2,16,2,2
    .db 60,1,3,21,3,3
    .db 61,4,4,26,1,4
    .db 62,7,1,1,2,1
    .db 63,10,2,6,3,2
    .db 64,13,3,11,1,3
    .db 65,16,4,16,2,4
    .db 66,19,1,21,3,1
    .db 67,22,2,26,1,2
    .db 68,25,3,1,2,3
    .db 69,28,4,6,3,4
    .db 70,1,1,11,1,1
    .db 71,4,2,16,2,2
    .db 72,7,3,21,3,3
    .db 73,10,4,26,1,4
    .db 74,13,1,1,2,1
    .db 75,16,2,6,3,2
    .db 76,19,3,11,1,3
    .db 77,22,4,16,2,4
    .db 78,25,1,21,3,1
    .db 79,28,2,26,1,2
    .db 80,1,3,1,2,3
    .db 81,4,4,6,3,4
    .db 82,7,1,11,1,1
    .db 83,10,2,16,2,2
    .db 84,13,3,21,3,3
    .db 85,16,4,26,1,4
    .db 86,19,1,1,2,1
    .db 87,22,2,6,3,2
    .db 88,25,3,11,1,3
    .db 89,28,4,16,2,4
    .db 90,1,1,21,3,1
    .db 91,4,2,26,1,2
    .db 92,7,3,1,2,3
    .db 93,10,4,6,3,4
    .db 94,13,1,11,1,1
    .db 60,16,2,16,2,2
    .db 61,19,3,21,3,3
    .db 62,22,4,26,1,4
    .db 63,25,1,1,2,1
    .db 64,28,2,6,3,2
    .db 65,1,3,11,1,3
    .db 66,4,4,16,2,4
    .db 67,7,1,21,3,1
    .db 68,10,2,26,1,2
    .db 69,13,3,1,2,3
    .db 70,16,4,6,3,4
    .db 71,19,1,11,1,1
    .db 72,22,2,16,2,2
    .db 73,25,3,21,3,3
    .db 74,28,4,26,1,4


MC3_BlockSoundMap:
    .db BLOCK_STONE,0
    .db BLOCK_GRASS,3
    .db BLOCK_DIRT,2
    .db BLOCK_COBBLE,0
    .db BLOCK_PLANK,9
    .db BLOCK_WOOD,9
    .db BLOCK_LEAVES,10
    .db BLOCK_SAND,4
    .db BLOCK_WATER,7
    .db BLOCK_LAVA,8
    .db BLOCK_GLASS,5
    .db BLOCK_COAL_ORE,11
    .db BLOCK_IRON_ORE,11
    .db BLOCK_GOLD_ORE,12
    .db BLOCK_REDSTONE_ORE,13
    .db BLOCK_OBSIDIAN,1
    .db BLOCK_NETHER_PORTAL,15
    .db BLOCK_ENDSTONE,16
    .db BLOCK_BOOKSHELF,8
    .db BLOCK_FURNACE,14
    .db BLOCK_ANVIL,14
    .db BLOCK_CHEST,14
    .db BLOCK_TNT,8
    .db BLOCK_GLOWSTONE,17

MC3_MobDropTable:
    ; mob type, drop item, min, max, rare item
    .db 0,ITEM_RAW_MEAT,1,3,ITEM_LEATHER
    .db 1,ITEM_RAW_MEAT,1,1,ITEM_STRING
    .db 2,ITEM_WOOL,1,3,ITEM_WHEAT
    .db 3,ITEM_FEATHER,0,2,ITEM_RAW_FISH
    .db 4,ITEM_RAW_MEAT,1,3,ITEM_LEATHER
    .db 5,ITEM_RAW_MEAT,1,2,ITEM_CACTUS
    .db 6,ITEM_FEATHER,0,3,ITEM_WHEAT_SEED

;------------------------------------------------------------------------------
; Extra feature toggles and configuration defaults.
;------------------------------------------------------------------------------
MC3_FeatureFlags:
    .db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
MC3_TextureVariants:
    .db 0,1,2,3,4,5,6,7
MC3_WeatherPatterns:
    .db WEATHER_CLEAR,WEATHER_CLEAR,WEATHER_RAIN,WEATHER_RAIN,WEATHER_SNOW,WEATHER_CLEAR,WEATHER_CLEAR,WEATHER_RAIN
MC3_DifficultyDamage:
    .db 0,1,2,3
MC3_MusicVolume:
    .db 6
MC3_SFXVolume:
    .db 8
MC3_AmbientTimer:
    .db 0
;------------------------------------------------------------------------------
; ANIMATION FRAME LIBRARY -- clouds, water, lava, leaves, portal shimmer.
;------------------------------------------------------------------------------
MC3_AnimFrame_00:
    .db $0,$3,$6,$9,$C,$F,$2,$5,$8,$B,$E,$1,$4,$7,$A,$D
    ; frame 00 timing/phase data
MC3_AnimFrame_01:
    .db $5,$8,$B,$E,$1,$4,$7,$A,$D,$0,$3,$6,$9,$C,$F,$2
    ; frame 01 timing/phase data
MC3_AnimFrame_02:
    .db $A,$D,$0,$3,$6,$9,$C,$F,$2,$5,$8,$B,$E,$1,$4,$7
    ; frame 02 timing/phase data
MC3_AnimFrame_03:
    .db $F,$2,$5,$8,$B,$E,$1,$4,$7,$A,$D,$0,$3,$6,$9,$C
    ; frame 03 timing/phase data
MC3_AnimFrame_04:
    .db $5,$6,$B,$C,$1,$2,$7,$8,$D,$E,$3,$4,$9,$A,$F,$0
    ; frame 04 timing/phase data
MC3_AnimFrame_05:
    .db $8,$D,$E,$3,$4,$9,$A,$F,$0,$5,$6,$B,$C,$1,$2,$7
    ; frame 05 timing/phase data
MC3_AnimFrame_06:
    .db $F,$0,$5,$6,$B,$C,$1,$2,$7,$8,$D,$E,$3,$4,$9,$A
    ; frame 06 timing/phase data
MC3_AnimFrame_07:
    .db $2,$7,$8,$D,$E,$3,$4,$9,$A,$F,$0,$5,$6,$B,$C,$1
    ; frame 07 timing/phase data
MC3_AnimFrame_08:
    .db $A,$9,$C,$3,$6,$5,$8,$F,$2,$1,$4,$B,$E,$D,$0,$7
    ; frame 08 timing/phase data
MC3_AnimFrame_09:
    .db $F,$2,$1,$4,$B,$E,$D,$0,$7,$A,$9,$C,$3,$6,$5,$8
    ; frame 09 timing/phase data
MC3_AnimFrame_10:
    .db $0,$7,$A,$9,$C,$3,$6,$5,$8,$F,$2,$1,$4,$B,$E,$D
    ; frame 10 timing/phase data
MC3_AnimFrame_11:
    .db $5,$8,$F,$2,$1,$4,$B,$E,$D,$0,$7,$A,$9,$C,$3,$6
    ; frame 11 timing/phase data
MC3_AnimFrame_12:
    .db $F,$C,$1,$6,$B,$8,$D,$2,$7,$4,$9,$E,$3,$0,$5,$A
    ; frame 12 timing/phase data
MC3_AnimFrame_13:
    .db $2,$7,$4,$9,$E,$3,$0,$5,$A,$F,$C,$1,$6,$B,$8,$D
    ; frame 13 timing/phase data
MC3_AnimFrame_14:
    .db $5,$A,$F,$C,$1,$6,$B,$8,$D,$2,$7,$4,$9,$E,$3,$0
    ; frame 14 timing/phase data
MC3_AnimFrame_15:
    .db $8,$D,$2,$7,$4,$9,$E,$3,$0,$5,$A,$F,$C,$1,$6,$B
    ; frame 15 timing/phase data
MC3_AnimFrame_16:
    .db $4,$7,$2,$D,$8,$B,$6,$1,$C,$F,$A,$5,$0,$3,$E,$9
    ; frame 16 timing/phase data
MC3_AnimFrame_17:
    .db $1,$C,$F,$A,$5,$0,$3,$E,$9,$4,$7,$2,$D,$8,$B,$6
    ; frame 17 timing/phase data
MC3_AnimFrame_18:
    .db $E,$9,$4,$7,$2,$D,$8,$B,$6,$1,$C,$F,$A,$5,$0,$3
    ; frame 18 timing/phase data
MC3_AnimFrame_19:
    .db $B,$6,$1,$C,$F,$A,$5,$0,$3,$E,$9,$4,$7,$2,$D,$8
    ; frame 19 timing/phase data
MC3_AnimFrame_20:
    .db $1,$2,$F,$8,$5,$6,$3,$C,$9,$A,$7,$0,$D,$E,$B,$4
    ; frame 20 timing/phase data
MC3_AnimFrame_21:
    .db $C,$9,$A,$7,$0,$D,$E,$B,$4,$1,$2,$F,$8,$5,$6,$3
    ; frame 21 timing/phase data
MC3_AnimFrame_22:
    .db $B,$4,$1,$2,$F,$8,$5,$6,$3,$C,$9,$A,$7,$0,$D,$E
    ; frame 22 timing/phase data
MC3_AnimFrame_23:
    .db $6,$3,$C,$9,$A,$7,$0,$D,$E,$B,$4,$1,$2,$F,$8,$5
    ; frame 23 timing/phase data
MC3_AnimFrame_24:
    .db $E,$D,$8,$7,$2,$1,$C,$B,$6,$5,$0,$F,$A,$9,$4,$3
    ; frame 24 timing/phase data
MC3_AnimFrame_25:
    .db $B,$6,$5,$0,$F,$A,$9,$4,$3,$E,$D,$8,$7,$2,$1,$C
    ; frame 25 timing/phase data
MC3_AnimFrame_26:
    .db $4,$3,$E,$D,$8,$7,$2,$1,$C,$B,$6,$5,$0,$F,$A,$9
    ; frame 26 timing/phase data
MC3_AnimFrame_27:
    .db $1,$C,$B,$6,$5,$0,$F,$A,$9,$4,$3,$E,$D,$8,$7,$2
    ; frame 27 timing/phase data
MC3_AnimFrame_28:
    .db $B,$8,$5,$2,$F,$C,$9,$6,$3,$0,$D,$A,$7,$4,$1,$E
    ; frame 28 timing/phase data
MC3_AnimFrame_29:
    .db $6,$3,$0,$D,$A,$7,$4,$1,$E,$B,$8,$5,$2,$F,$C,$9
    ; frame 29 timing/phase data
MC3_AnimFrame_30:
    .db $1,$E,$B,$8,$5,$2,$F,$C,$9,$6,$3,$0,$D,$A,$7,$4
    ; frame 30 timing/phase data
MC3_AnimFrame_31:
    .db $C,$9,$6,$3,$0,$D,$A,$7,$4,$1,$E,$B,$8,$5,$2,$F
    ; frame 31 timing/phase data
MC3_AnimFrame_32:
    .db $8,$B,$E,$1,$4,$7,$A,$D,$0,$3,$6,$9,$C,$F,$2,$5
    ; frame 32 timing/phase data
MC3_AnimFrame_33:
    .db $D,$0,$3,$6,$9,$C,$F,$2,$5,$8,$B,$E,$1,$4,$7,$A
    ; frame 33 timing/phase data
MC3_AnimFrame_34:
    .db $2,$5,$8,$B,$E,$1,$4,$7,$A,$D,$0,$3,$6,$9,$C,$F
    ; frame 34 timing/phase data
MC3_AnimFrame_35:
    .db $7,$A,$D,$0,$3,$6,$9,$C,$F,$2,$5,$8,$B,$E,$1,$4
    ; frame 35 timing/phase data
MC3_AnimFrame_36:
    .db $D,$E,$3,$4,$9,$A,$F,$0,$5,$6,$B,$C,$1,$2,$7,$8
    ; frame 36 timing/phase data
MC3_AnimFrame_37:
    .db $0,$5,$6,$B,$C,$1,$2,$7,$8,$D,$E,$3,$4,$9,$A,$F
    ; frame 37 timing/phase data
MC3_AnimFrame_38:
    .db $7,$8,$D,$E,$3,$4,$9,$A,$F,$0,$5,$6,$B,$C,$1,$2
    ; frame 38 timing/phase data
MC3_AnimFrame_39:
    .db $A,$F,$0,$5,$6,$B,$C,$1,$2,$7,$8,$D,$E,$3,$4,$9
    ; frame 39 timing/phase data
MC3_AnimFrame_40:
    .db $2,$1,$4,$B,$E,$D,$0,$7,$A,$9,$C,$3,$6,$5,$8,$F
    ; frame 40 timing/phase data
MC3_AnimFrame_41:
    .db $7,$A,$9,$C,$3,$6,$5,$8,$F,$2,$1,$4,$B,$E,$D,$0
    ; frame 41 timing/phase data
MC3_AnimFrame_42:
    .db $8,$F,$2,$1,$4,$B,$E,$D,$0,$7,$A,$9,$C,$3,$6,$5
    ; frame 42 timing/phase data
MC3_AnimFrame_43:
    .db $D,$0,$7,$A,$9,$C,$3,$6,$5,$8,$F,$2,$1,$4,$B,$E
    ; frame 43 timing/phase data
MC3_AnimFrame_44:
    .db $7,$4,$9,$E,$3,$0,$5,$A,$F,$C,$1,$6,$B,$8,$D,$2
    ; frame 44 timing/phase data
MC3_AnimFrame_45:
    .db $A,$F,$C,$1,$6,$B,$8,$D,$2,$7,$4,$9,$E,$3,$0,$5
    ; frame 45 timing/phase data
MC3_AnimFrame_46:
    .db $D,$2,$7,$4,$9,$E,$3,$0,$5,$A,$F,$C,$1,$6,$B,$8
    ; frame 46 timing/phase data
MC3_AnimFrame_47:
    .db $0,$5,$A,$F,$C,$1,$6,$B,$8,$D,$2,$7,$4,$9,$E,$3
    ; frame 47 timing/phase data
MC3_AnimFrame_48:
    .db $C,$F,$A,$5,$0,$3,$E,$9,$4,$7,$2,$D,$8,$B,$6,$1
    ; frame 48 timing/phase data
MC3_AnimFrame_49:
    .db $9,$4,$7,$2,$D,$8,$B,$6,$1,$C,$F,$A,$5,$0,$3,$E
    ; frame 49 timing/phase data
MC3_AnimFrame_50:
    .db $6,$1,$C,$F,$A,$5,$0,$3,$E,$9,$4,$7,$2,$D,$8,$B
    ; frame 50 timing/phase data
MC3_AnimFrame_51:
    .db $3,$E,$9,$4,$7,$2,$D,$8,$B,$6,$1,$C,$F,$A,$5,$0
    ; frame 51 timing/phase data
MC3_AnimFrame_52:
    .db $9,$A,$7,$0,$D,$E,$B,$4,$1,$2,$F,$8,$5,$6,$3,$C
    ; frame 52 timing/phase data
MC3_AnimFrame_53:
    .db $4,$1,$2,$F,$8,$5,$6,$3,$C,$9,$A,$7,$0,$D,$E,$B
    ; frame 53 timing/phase data
MC3_AnimFrame_54:
    .db $3,$C,$9,$A,$7,$0,$D,$E,$B,$4,$1,$2,$F,$8,$5,$6
    ; frame 54 timing/phase data
MC3_AnimFrame_55:
    .db $E,$B,$4,$1,$2,$F,$8,$5,$6,$3,$C,$9,$A,$7,$0,$D
    ; frame 55 timing/phase data
MC3_AnimFrame_56:
    .db $6,$5,$0,$F,$A,$9,$4,$3,$E,$D,$8,$7,$2,$1,$C,$B
    ; frame 56 timing/phase data
MC3_AnimFrame_57:
    .db $3,$E,$D,$8,$7,$2,$1,$C,$B,$6,$5,$0,$F,$A,$9,$4
    ; frame 57 timing/phase data
MC3_AnimFrame_58:
    .db $C,$B,$6,$5,$0,$F,$A,$9,$4,$3,$E,$D,$8,$7,$2,$1
    ; frame 58 timing/phase data
MC3_AnimFrame_59:
    .db $9,$4,$3,$E,$D,$8,$7,$2,$1,$C,$B,$6,$5,$0,$F,$A
    ; frame 59 timing/phase data
MC3_AnimFrame_60:
    .db $3,$0,$D,$A,$7,$4,$1,$E,$B,$8,$5,$2,$F,$C,$9,$6
    ; frame 60 timing/phase data
MC3_AnimFrame_61:
    .db $E,$B,$8,$5,$2,$F,$C,$9,$6,$3,$0,$D,$A,$7,$4,$1
    ; frame 61 timing/phase data
MC3_AnimFrame_62:
    .db $9,$6,$3,$0,$D,$A,$7,$4,$1,$E,$B,$8,$5,$2,$F,$C
    ; frame 62 timing/phase data
MC3_AnimFrame_63:
    .db $4,$1,$E,$B,$8,$5,$2,$F,$C,$9,$6,$3,$0,$D,$A,$7
    ; frame 63 timing/phase data
MC3_AnimFrame_64:
    .db $0,$3,$6,$9,$C,$F,$2,$5,$8,$B,$E,$1,$4,$7,$A,$D
    ; frame 64 timing/phase data
MC3_AnimFrame_65:
    .db $5,$8,$B,$E,$1,$4,$7,$A,$D,$0,$3,$6,$9,$C,$F,$2
    ; frame 65 timing/phase data
MC3_AnimFrame_66:
    .db $A,$D,$0,$3,$6,$9,$C,$F,$2,$5,$8,$B,$E,$1,$4,$7
    ; frame 66 timing/phase data
MC3_AnimFrame_67:
    .db $F,$2,$5,$8,$B,$E,$1,$4,$7,$A,$D,$0,$3,$6,$9,$C
    ; frame 67 timing/phase data
MC3_AnimFrame_68:
    .db $5,$6,$B,$C,$1,$2,$7,$8,$D,$E,$3,$4,$9,$A,$F,$0
    ; frame 68 timing/phase data
MC3_AnimFrame_69:
    .db $8,$D,$E,$3,$4,$9,$A,$F,$0,$5,$6,$B,$C,$1,$2,$7
    ; frame 69 timing/phase data
MC3_AnimFrame_70:
    .db $F,$0,$5,$6,$B,$C,$1,$2,$7,$8,$D,$E,$3,$4,$9,$A
    ; frame 70 timing/phase data
MC3_AnimFrame_71:
    .db $2,$7,$8,$D,$E,$3,$4,$9,$A,$F,$0,$5,$6,$B,$C,$1
    ; frame 71 timing/phase data
MC3_AnimFrame_72:
    .db $A,$9,$C,$3,$6,$5,$8,$F,$2,$1,$4,$B,$E,$D,$0,$7
    ; frame 72 timing/phase data
MC3_AnimFrame_73:
    .db $F,$2,$1,$4,$B,$E,$D,$0,$7,$A,$9,$C,$3,$6,$5,$8
    ; frame 73 timing/phase data
MC3_AnimFrame_74:
    .db $0,$7,$A,$9,$C,$3,$6,$5,$8,$F,$2,$1,$4,$B,$E,$D
    ; frame 74 timing/phase data
MC3_AnimFrame_75:
    .db $5,$8,$F,$2,$1,$4,$B,$E,$D,$0,$7,$A,$9,$C,$3,$6
    ; frame 75 timing/phase data
MC3_AnimFrame_76:
    .db $F,$C,$1,$6,$B,$8,$D,$2,$7,$4,$9,$E,$3,$0,$5,$A
    ; frame 76 timing/phase data
MC3_AnimFrame_77:
    .db $2,$7,$4,$9,$E,$3,$0,$5,$A,$F,$C,$1,$6,$B,$8,$D
    ; frame 77 timing/phase data
MC3_AnimFrame_78:
    .db $5,$A,$F,$C,$1,$6,$B,$8,$D,$2,$7,$4,$9,$E,$3,$0
    ; frame 78 timing/phase data
MC3_AnimFrame_79:
    .db $8,$D,$2,$7,$4,$9,$E,$3,$0,$5,$A,$F,$C,$1,$6,$B
    ; frame 79 timing/phase data
MC3_AnimFrame_80:
    .db $4,$7,$2,$D,$8,$B,$6,$1,$C,$F,$A,$5,$0,$3,$E,$9
    ; frame 80 timing/phase data
MC3_AnimFrame_81:
    .db $1,$C,$F,$A,$5,$0,$3,$E,$9,$4,$7,$2,$D,$8,$B,$6
    ; frame 81 timing/phase data
MC3_AnimFrame_82:
    .db $E,$9,$4,$7,$2,$D,$8,$B,$6,$1,$C,$F,$A,$5,$0,$3
    ; frame 82 timing/phase data
MC3_AnimFrame_83:
    .db $B,$6,$1,$C,$F,$A,$5,$0,$3,$E,$9,$4,$7,$2,$D,$8
    ; frame 83 timing/phase data
MC3_AnimFrame_84:
    .db $1,$2,$F,$8,$5,$6,$3,$C,$9,$A,$7,$0,$D,$E,$B,$4
    ; frame 84 timing/phase data
MC3_AnimFrame_85:
    .db $C,$9,$A,$7,$0,$D,$E,$B,$4,$1,$2,$F,$8,$5,$6,$3
    ; frame 85 timing/phase data
MC3_AnimFrame_86:
    .db $B,$4,$1,$2,$F,$8,$5,$6,$3,$C,$9,$A,$7,$0,$D,$E
    ; frame 86 timing/phase data
MC3_AnimFrame_87:
    .db $6,$3,$C,$9,$A,$7,$0,$D,$E,$B,$4,$1,$2,$F,$8,$5
    ; frame 87 timing/phase data
MC3_AnimFrame_88:
    .db $E,$D,$8,$7,$2,$1,$C,$B,$6,$5,$0,$F,$A,$9,$4,$3
    ; frame 88 timing/phase data
MC3_AnimFrame_89:
    .db $B,$6,$5,$0,$F,$A,$9,$4,$3,$E,$D,$8,$7,$2,$1,$C
    ; frame 89 timing/phase data
MC3_AnimFrame_90:
    .db $4,$3,$E,$D,$8,$7,$2,$1,$C,$B,$6,$5,$0,$F,$A,$9
    ; frame 90 timing/phase data
MC3_AnimFrame_91:
    .db $1,$C,$B,$6,$5,$0,$F,$A,$9,$4,$3,$E,$D,$8,$7,$2
    ; frame 91 timing/phase data
MC3_AnimFrame_92:
    .db $B,$8,$5,$2,$F,$C,$9,$6,$3,$0,$D,$A,$7,$4,$1,$E
    ; frame 92 timing/phase data
MC3_AnimFrame_93:
    .db $6,$3,$0,$D,$A,$7,$4,$1,$E,$B,$8,$5,$2,$F,$C,$9
    ; frame 93 timing/phase data
MC3_AnimFrame_94:
    .db $1,$E,$B,$8,$5,$2,$F,$C,$9,$6,$3,$0,$D,$A,$7,$4
    ; frame 94 timing/phase data
MC3_AnimFrame_95:
    .db $C,$9,$6,$3,$0,$D,$A,$7,$4,$1,$E,$B,$8,$5,$2,$F
    ; frame 95 timing/phase data

.endKEY_Y_EQUALS .equ 143


