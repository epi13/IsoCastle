import { expect, test } from "@playwright/test";
import { writeFile } from "node:fs/promises";

const KEY_G = 71;
const KEY_V = 86;

async function snapshot(page) {
  return page.evaluate(() => structuredClone(window.IsoCastleTest ?? {}));
}

async function waitForScreen(page, screen) {
  await expect.poll(async () => (await snapshot(page)).screen).toBe(screen);
}

async function capture(page, testInfo, name) {
  await page.screenshot({ path: testInfo.outputPath(`${name}.png`) });
}

async function openSettings(page) {
  await page.mouse.click(350, 596);
  await waitForScreen(page, "settings");
}

async function scrollSettingsToBottom(page) {
  await page.mouse.move(700, 590);
  await page.mouse.wheel(0, 1600);
  await page.waitForTimeout(150);
}

async function openInputEditor(page) {
  await scrollSettingsToBottom(page);
  await page.mouse.click(620, 579);
  await waitForScreen(page, "input_remapping");
}

async function startNewJourney(page) {
  await page.mouse.click(350, 416);
  await waitForScreen(page, "intro");
  await page.mouse.click(640, 540);
  await waitForScreen(page, "character_creation");
  await page.mouse.move(800, 600);
  await page.mouse.wheel(0, 1600);
  await page.waitForTimeout(150);
  await page.mouse.click(620, 459);
  await waitForScreen(page, "gameplay");
}

async function returnFromInputEditor(page) {
  await page.mouse.click(510, 674);
  await waitForScreen(page, "settings");
}

test("Web export supports persistence, remapping, gameplay, and inventory dragging", async ({ page, browser }, testInfo) => {
  const consoleMessages = [];
  const consoleErrors = [];
  const pageErrors = [];
  const failedRequests = [];
  const assetResponses = { wasm: null, pck: null };

  page.on("console", (message) => {
    const record = { type: message.type(), text: message.text() };
    consoleMessages.push(record);
    if (message.type() === "error") consoleErrors.push(record);
  });
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("requestfailed", (request) => {
    failedRequests.push({ url: request.url(), failure: request.failure()?.errorText ?? "unknown" });
  });
  page.on("response", (response) => {
    if (response.url().endsWith(".wasm")) assetResponses.wasm = { status: response.status(), type: response.headers()["content-type"] };
    if (response.url().endsWith(".pck")) assetResponses.pck = { status: response.status(), type: response.headers()["content-type"] };
  });

  const response = await page.goto("/index.html", { waitUntil: "domcontentloaded" });
  expect(response?.status()).toBe(200);
  await waitForScreen(page, "title");
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator("canvas")).toBeVisible();
  await capture(page, testInfo, "title");
  await expect.poll(() => assetResponses.wasm?.status).toBe(200);
  await expect.poll(() => assetResponses.pck?.status).toBe(200);
  expect(assetResponses.wasm?.type).toContain("application/wasm");
  expect(assetResponses.pck?.type).toContain("application/octet-stream");

  await openSettings(page);
  await page.mouse.click(485, 143);
  await expect.poll(async () => Number((await snapshot(page)).setting_master_volume)).toBeLessThanOrEqual(0.05);
  await page.mouse.click(850, 143);
  await page.mouse.click(600, 178);
  await page.mouse.click(650, 248);
  const changedSettings = await snapshot(page);
  expect(changedSettings.setting_master_volume).toBeGreaterThan(0.7);
  expect(changedSettings.setting_music_volume).toBeGreaterThan(0.15);
  expect(changedSettings.setting_music_volume).toBeLessThan(0.4);
  expect(changedSettings.setting_effects_volume).toBeGreaterThan(0.3);
  expect(changedSettings.setting_effects_volume).toBeLessThan(0.55);

  await openInputEditor(page);
  await capture(page, testInfo, "input-remapping");
  await page.mouse.click(338, 580);
  await page.keyboard.press("g");
  await expect.poll(async () => (await snapshot(page)).bindings.search[0].physical_keycode).toBe(KEY_G);
  await returnFromInputEditor(page);
  await expect.poll(async () => Boolean((await snapshot(page)).settings_save_ok)).toBe(true);

  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForScreen(page, "title");
  const persistedSettings = await snapshot(page);
  expect(persistedSettings.bindings.search[0].physical_keycode).toBe(KEY_G);
  expect(persistedSettings.setting_music_volume).toBeCloseTo(changedSettings.setting_music_volume, 1);
  expect(persistedSettings.setting_effects_volume).toBeCloseTo(changedSettings.setting_effects_volume, 1);

  await startNewJourney(page);
  await expect.poll(async () => Boolean((await snapshot(page)).audio_requested)).toBe(true);
  await expect.poll(async () => Boolean((await snapshot(page)).user_interaction)).toBe(true);
  await capture(page, testInfo, "gameplay");
  const turnBeforeSearch = Number((await snapshot(page)).turn);
  await page.keyboard.press("g");
  await expect.poll(async () => Number((await snapshot(page)).turn)).toBe(turnBeforeSearch + 1);

  await page.keyboard.press("F8");
  await expect.poll(async () => Boolean((await snapshot(page)).save_ok)).toBe(true);
  await expect.poll(async () => Boolean((await snapshot(page)).storage_persistent)).toBe(true);
  // Godot's Web filesystem flush is asynchronous even after force_fs_sync().
  await page.waitForTimeout(6000);
  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForScreen(page, "title");
  expect((await snapshot(page)).has_save).toBe(true);

  await openSettings(page);
  await openInputEditor(page);
  await page.mouse.click(552, 580);
  await expect.poll(async () => (await snapshot(page)).bindings.search[0].physical_keycode).toBe(KEY_V);
  await returnFromInputEditor(page);
  await scrollSettingsToBottom(page);
  await page.mouse.click(620, 637);
  await waitForScreen(page, "title");
  await expect.poll(async () => (await snapshot(page)).bindings.search[0].physical_keycode).toBe(KEY_V);

  await page.mouse.click(350, 476);
  await waitForScreen(page, "gameplay");
  await page.keyboard.press("i");
  await waitForScreen(page, "inventory");
  const inventoryBefore = await snapshot(page);
  const totalUnits = inventoryBefore.inventory_units + inventoryBefore.equipment_units;
  expect(inventoryBefore.inventory).toContain("armor_wool_undertunic:1");
  expect(inventoryBefore.equipment.body).toBeUndefined();

  await page.mouse.move(194, 267);
  await page.mouse.down();
  await page.mouse.move(653, 449, { steps: 18 });
  await capture(page, testInfo, "inventory-drag-and-drop");
  await page.mouse.up();
  await expect.poll(async () => (await snapshot(page)).equipment.body).toBe("armor_wool_undertunic");
  const inventoryAfter = await snapshot(page);
  expect(inventoryAfter.inventory_units + inventoryAfter.equipment_units).toBe(totalUnits);
  expect(inventoryAfter.inventory).not.toContain("armor_wool_undertunic:1");

  await page.keyboard.press("Escape");
  await waitForScreen(page, "gameplay");
  const scrollBefore = await page.evaluate(() => window.scrollY);
  await page.keyboard.press("ArrowUp");
  await page.keyboard.press("Space");
  expect(await page.evaluate(() => window.scrollY)).toBe(scrollBefore);
  await page.mouse.click(100, 100, { button: "right" });
  await expect.poll(async () => (await snapshot(page)).screen).toBe("gameplay");

  await page.keyboard.press("F8");
  await expect.poll(async () => Boolean((await snapshot(page)).save_ok)).toBe(true);
  await page.waitForTimeout(6000);
  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForScreen(page, "title");
  await page.mouse.click(350, 476);
  await waitForScreen(page, "gameplay");
  await expect.poll(async () => (await snapshot(page)).equipment.body).toBe("armor_wool_undertunic");
  await page.evaluate(() => document.activeElement?.blur());
  await page.mouse.click(640, 360);
  await page.keyboard.press("i");
  await waitForScreen(page, "inventory");
  await page.keyboard.press("Escape");
  await waitForScreen(page, "gameplay");

  const fatalConsole = consoleErrors.filter(({ text }) => /fatal|uncaught|abort|exception|failed to start/i.test(text));
  expect(pageErrors).toEqual([]);
  expect(failedRequests).toEqual([]);
  expect(fatalConsole).toEqual([]);
  const diagnosticPath = testInfo.outputPath("browser-diagnostics.json");
  await writeFile(diagnosticPath, JSON.stringify({
      browser: testInfo.project.name,
      version: browser.version(),
      assetResponses,
      consoleMessages,
      consoleErrors,
      pageErrors,
      failedRequests,
    }, null, 2));
  await testInfo.attach("browser-diagnostics.json", { path: diagnosticPath, contentType: "application/json" });
});
