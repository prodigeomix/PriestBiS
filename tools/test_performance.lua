-- tools/test_performance.lua
-- Performance & CPU profiling regression suite for PriestBiS (Vanilla 1.12.1 / Turtle WoW)

dofile("tools/test_priest_bis.lua")

print("================================================================================")
print("PRIESTBIS PERFORMANCE & CPU BENCHMARK SUITE")
print("================================================================================")

local testItems = {
    "item:16817:0:0:0", -- Girdle of Prophecy (22-line Tier 1 set belt)
    "item:16814:0:0:0", -- Pants of Prophecy (9-line Tier 1 set legs)
    "item:16819:0:0:0", -- Vambraces of Prophecy (9-line Tier 1 set bracers)
    "item:19958:0:0:0", -- Hazza'rah's Charm of Healing (Trinket with special effect)
    "item:19406:0:0:0", -- Drake Fang Talisman (Trinket)
    "item:22406:0:0:0", -- Redemption (1H Mace)
    "item:19820:0:0:0", -- Consecrated Caduceus (Offhand)
    "item:13346:0:0:0", -- Robes of the Exalted (Chest)
    "item:19890:0:0:0", -- Jin'do's Hexxer (Mainhand)
    "item:16923:0:0:0", -- Robes of Transcendence (Tier 2 set chest)
}

-- -------------------------------------------------------------
-- 1. Uncached Item Scan Throughput
-- -------------------------------------------------------------
print("\n>>> Benchmark 1: Uncached Tooltip Scan Burst...")
local uncachedIterations = 100
local tStart = os.clock()
for i = 1, uncachedIterations do
    UA.ClearCache()
    for _, link in ipairs(testItems) do
        UA.ScanItemStats(nil, link)
    end
end
local uncachedTotalTime = os.clock() - tStart
local totalScans = uncachedIterations * table.getn(testItems)
local uncachedPerItemMs = (uncachedTotalTime / totalScans) * 1000

print(string.format("    Total scans: %d in %.4f s", totalScans, uncachedTotalTime))
print(string.format("    Uncached scan speed: %.3f ms/item", uncachedPerItemMs))
assert(uncachedPerItemMs < 5.0, string.format("Uncached scan speed (%.3f ms) exceeded 5.0ms budget!", uncachedPerItemMs))
print("    [PASS] Uncached scan performance within budget (< 5.0 ms/item)")

-- -------------------------------------------------------------
-- 2. Cached Item Lookup Throughput
-- -------------------------------------------------------------
print("\n>>> Benchmark 2: Memoized Cache Lookup Throughput...")
-- Ensure all items are in cache
for _, link in ipairs(testItems) do
    UA.ScanItemStats(nil, link)
end

local cachedIterations = 20000
tStart = os.clock()
for i = 1, cachedIterations do
    for _, link in ipairs(testItems) do
        local stats = UA.ScanItemStats(nil, link)
        if not stats then error("Cache returned nil") end
    end
end
local cachedTotalTime = os.clock() - tStart
local totalCachedLookups = cachedIterations * table.getn(testItems)
local cachedPerLookupUs = (cachedTotalTime / totalCachedLookups) * 1000000

print(string.format("    Total lookups: %d in %.4f s", totalCachedLookups, cachedTotalTime))
print(string.format("    Cached lookup speed: %.4f µs/lookup", cachedPerLookupUs))
assert(cachedPerLookupUs < 50.0, string.format("Cached lookup speed (%.4f µs) exceeded 50µs budget!", cachedPerLookupUs))
print("    [PASS] Memoized cache lookup performance within budget (< 50 µs/lookup)")

-- -------------------------------------------------------------
-- 3. Cross-Key Cache Resolution (itemID <-> itemLink)
-- -------------------------------------------------------------
print("\n>>> Benchmark 3: Cross-Key Cache Hit Verification...")
UA.ClearCache()
-- First scan by itemID
UA.ScanItemStats(16817)

-- Measure scan by link string of the same item
tStart = os.clock()
for i = 1, 10000 do
    local stats = UA.ScanItemStats(nil, "item:16817:0:0:0")
    if not stats or stats.name ~= "Girdle of Prophecy" then
        error("Failed to retrieve stats via cross-key cache lookup")
    end
end
local crossKeyTime = os.clock() - tStart
local crossKeyPerLookupUs = (crossKeyTime / 10000) * 1000000
print(string.format("    10,000 cross-key lookups: %.4f s (%.4f µs/lookup)", crossKeyTime, crossKeyPerLookupUs))
assert(crossKeyPerLookupUs < 20.0, "Cross-key cache resolution should be instantaneous O(1)")
print("    [PASS] Cross-key cache hit verified without redundant tooltip reset")

-- -------------------------------------------------------------
-- 4. Bag Scan Dirty-Flag Invariant & Debouncing
-- -------------------------------------------------------------
print("\n>>> Benchmark 4: Bag Scan Dirty-Flag Invariant...")
UA.bagCacheDirty = true
UA.ScanBagsForBestOffhand()
assert(UA.bagCacheDirty == false, "bagCacheDirty must be false after scan")

tStart = os.clock()
for i = 1, 10000 do
    local oh = UA.ScanBagsForBestOffhand()
    if not oh then error("Expected cached offhand") end
end
local bagCacheTime = os.clock() - tStart
local bagPerLookupUs = (bagCacheTime / 10000) * 1000000
print(string.format("    10,000 clean bag queries: %.4f s (%.4f µs/lookup)", bagCacheTime, bagPerLookupUs))
assert(bagPerLookupUs < 20.0, "Bag scan when not dirty must be O(1)")
print("    [PASS] Bag scan dirty-flag debouncing verified")

-- -------------------------------------------------------------
-- 5. Tooltip Hook & Upgrade Evaluation Render Overhead
-- -------------------------------------------------------------
print("\n>>> Benchmark 5: Tooltip Hook Render Overhead...")
local mockTT = _G.GameTooltip

tStart = os.clock()
for i = 1, 1000 do
    mockTT._uaAppendedLink = nil
    UA.AppendTooltipUpgradeInfo(mockTT, "item:22406:0:0:0")
end
local renderTotalTime = os.clock() - tStart
local renderPerCallMs = (renderTotalTime / 1000) * 1000
print(string.format("    1,000 tooltip upgrade renders: %.4f s (%.3f ms/render)", renderTotalTime, renderPerCallMs))
assert(renderPerCallMs < 1.0, string.format("Tooltip render overhead (%.3f ms) exceeded 1.0ms budget!", renderPerCallMs))
print("    [PASS] Tooltip upgrade hook render overhead within budget (< 1.0 ms/render)")

print("\n================================================================================")
print("ALL PERFORMANCE BENCHMARKS PASSED PERFECTLY!")
print("================================================================================")
