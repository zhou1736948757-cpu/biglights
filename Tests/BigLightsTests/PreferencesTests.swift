import Foundation
import Testing
@testable import BigLights

private func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
    let suiteName = "BigLightsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    try body(defaults)
}

@Test func preferenceDefaultsAreUsable() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults, preferredLanguages: ["zh-Hans-CN"])
        #expect(preferences.language == .simplifiedChinese)
        #expect(preferences.menuBarIconVisible)
        #expect(preferences.enabled)
        #expect(preferences.size == 28)
        #expect(preferences.spacing == 0)
        #expect(preferences.style == .macOS)
        #expect(preferences.hiddenTrafficLightsEnabled)
        #expect(preferences.hiddenTrafficLightRevealMode == .nearest)
        #expect(!preferences.showInFullScreen)
        #expect(preferences.activeAppOnly)
        #expect(preferences.maxRefreshRate == .hz120)
        // launchAtLogin initial value is intentionally not asserted here:
        // it reflects SMAppService status, which is environment-dependent.
        #expect(preferences.dockClickMinimizesActiveWindow)
        #expect(preferences.stageManagerCloseButtonsEnabled)
        #expect(preferences.closeBehavior == .closeWindow)
        #expect(preferences.minimizeBehavior == .minimizeWindow)
        #expect(preferences.zoomBehavior == .zoomWindow)
    }
}

@Test func recommendedHiddenTrafficLightCopyIsStable() {
    #expect(AppLocalization.string(.overlayEnabled, language: .simplifiedChinese) == "放大窗口按钮")
    #expect(AppLocalization.string(.overlayEnabled, language: .english) == "Enlarged Window Controls")
    #expect(AppLocalization.string(.hiddenTrafficLights, language: .simplifiedChinese) == "隐藏式按钮（推荐）")
    #expect(AppLocalization.string(.hiddenTrafficLights, language: .english) == "Hidden Buttons (Recommended)")
    #expect(AppLocalization.string(.dockClickMinimize, language: .simplifiedChinese) == "Dock 栏最小化")
        #expect(AppLocalization.string(.dockClickMinimize, language: .english) == "Dock Click to Minimize")
        #expect(AppLocalization.string(.stageManagerCloseButtons, language: .simplifiedChinese) == "台前调度关闭按钮")
        #expect(AppLocalization.string(.stageManagerCloseButtons, language: .english) == "Stage Manager Close Buttons")
    #expect(AppLocalization.string(.menuBarIconVisible, language: .simplifiedChinese) == "显示菜单栏图标")
    #expect(AppLocalization.string(.menuBarIconVisible, language: .english) == "Show Menu Bar Icon")
    #expect(HiddenTrafficLightRevealMode.group.title(language: .english) == "Group")
    #expect(HiddenTrafficLightRevealMode.nearest.title(language: .english) == "Single (Recommended)")
}

@Test func systemLanguageSelectionMapsChineseToSimplifiedChineseAndOthersToEnglish() {
    #expect(AppLanguage.systemDefault(preferredLanguages: ["zh-Hans-CN"]) == .simplifiedChinese)
    #expect(AppLanguage.systemDefault(preferredLanguages: ["zh-Hant-TW"]) == .simplifiedChinese)
    #expect(AppLanguage.systemDefault(preferredLanguages: ["en-US"]) == .english)
    #expect(AppLanguage.systemDefault(preferredLanguages: ["fr-FR"]) == .english)
    #expect(AppLanguage.systemDefault(preferredLanguages: []) == .english)
}

@Test func languagePreferencePersistsAndCorruptValuesFollowTheSystem() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults, preferredLanguages: ["en-US"])
        #expect(preferences.language == .english)

        preferences.language = .simplifiedChinese
        #expect(Preferences(defaults: defaults, preferredLanguages: ["en-US"]).language == .simplifiedChinese)

        defaults.set("unknown", forKey: "appLanguage")
        let recovered = Preferences(defaults: defaults, preferredLanguages: ["en-US"])
        #expect(recovered.language == .english)
        #expect(defaults.string(forKey: "appLanguage") == AppLanguage.english.rawValue)
    }
}

@Test func bothLocalizationTablesContainEveryApplicationString() {
    #expect(AppLocalization.missingKeys(for: .simplifiedChinese).isEmpty)
    #expect(AppLocalization.missingKeys(for: .english).isEmpty)
}

@Test func dockClickFeatureCanStayEnabledWhileOverlaysAreDisabled() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults)
        preferences.enabled = false

        #expect(!preferences.enabled)
        #expect(preferences.dockClickMinimizesActiveWindow)
    }
}

@Test func fullScreenPreferenceIsDisabledWhileTheFeatureIsInDevelopment() {
    withDefaults { defaults in
        defaults.set(true, forKey: "showInFullScreen")

        let preferences = Preferences(defaults: defaults)

        #expect(!preferences.showInFullScreen)
        #expect(!defaults.bool(forKey: "showInFullScreen"))
    }
}

@Test func preferencesPersist() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults)
        preferences.language = .english
        preferences.menuBarIconVisible = false
        preferences.enabled = false
        preferences.size = 42
        preferences.spacing = 12
        preferences.style = .edgeSquares
        preferences.hiddenTrafficLightsEnabled = false
        preferences.hiddenTrafficLightRevealMode = .group
        preferences.activeAppOnly = false
        preferences.maxRefreshRate = .hz60
        preferences.dockClickMinimizesActiveWindow = false
        preferences.stageManagerCloseButtonsEnabled = false
        preferences.closeBehavior = .hideApplication
        preferences.minimizeBehavior = .zoomWindow
        preferences.zoomBehavior = .doNothing

        let restored = Preferences(defaults: defaults)
        #expect(restored.language == .english)
        #expect(!restored.menuBarIconVisible)
        #expect(!restored.enabled)
        #expect(restored.size == 42)
        #expect(restored.spacing == 12)
        #expect(restored.style == .edgeSquares)
        #expect(!restored.hiddenTrafficLightsEnabled)
        #expect(restored.hiddenTrafficLightRevealMode == .group)
        #expect(!restored.showInFullScreen)
        #expect(!restored.activeAppOnly)
        #expect(restored.maxRefreshRate == .hz60)
        #expect(!restored.dockClickMinimizesActiveWindow)
        #expect(!restored.stageManagerCloseButtonsEnabled)
        #expect(restored.closeBehavior == .hideApplication)
        #expect(restored.minimizeBehavior == .zoomWindow)
        #expect(restored.zoomBehavior == .doNothing)
    }
}

@Test func hiddenMenuBarIconReopensSettingsOnTheNextLaunch() {
    #expect(!AppDelegate.shouldOpenSettingsAtLaunch(menuBarIconVisible: true))
    #expect(AppDelegate.shouldOpenSettingsAtLaunch(menuBarIconVisible: false))
}


@Test func corruptStoredRevealModeFallsBackToNearest() {
    withDefaults { defaults in
        defaults.set("unknown", forKey: "hiddenTrafficLightRevealMode")
        #expect(Preferences(defaults: defaults).hiddenTrafficLightRevealMode == .nearest)
    }
}

@Test func corruptStoredBehaviorsFallBackToNativeDefaults() {
    withDefaults { defaults in
        defaults.set("unknown", forKey: "closeButtonBehavior")
        defaults.set("unknown", forKey: "minimizeButtonBehavior")
        defaults.set("unknown", forKey: "zoomButtonBehavior")

        let preferences = Preferences(defaults: defaults)
        #expect(preferences.closeBehavior == .closeWindow)
        #expect(preferences.minimizeBehavior == .minimizeWindow)
        #expect(preferences.zoomBehavior == .zoomWindow)
    }
}

@Test func buttonBehaviorNativeActionMappingIsStable() {
    #expect(ButtonBehavior.closeWindow.nativeWindowAction == .close)
    #expect(ButtonBehavior.minimizeWindow.nativeWindowAction == .minimize)
    #expect(ButtonBehavior.zoomWindow.nativeWindowAction == .zoom)
    #expect(ButtonBehavior.hideApplication.nativeWindowAction == nil)
    #expect(ButtonBehavior.doNothing.nativeWindowAction == nil)
}

@Test func corruptStoredSizeIsClamped() {
    withDefaults { defaults in
        defaults.set(500, forKey: "controlSize")
        #expect(Preferences(defaults: defaults).size == 48)

        defaults.set(-20, forKey: "controlSize")
        #expect(Preferences(defaults: defaults).size == 18)

        defaults.set(Double.nan, forKey: "controlSize")
        #expect(Preferences(defaults: defaults).size == ControlLayout.defaultSize)

        defaults.set(Double.infinity, forKey: "controlSize")
        #expect(Preferences(defaults: defaults).size == ControlLayout.defaultSize)
    }
}

@Test func corruptStoredSpacingIsClamped() {
    withDefaults { defaults in
        defaults.set(500, forKey: "controlSpacingAdjustment")
        #expect(Preferences(defaults: defaults).spacing == 32)

        defaults.set(-500, forKey: "controlSpacingAdjustment")
        #expect(Preferences(defaults: defaults).spacing == -8)

        defaults.set(Double.nan, forKey: "controlSpacingAdjustment")
        #expect(Preferences(defaults: defaults).spacing == ControlLayout.defaultSpacingAdjustment)

        defaults.set(-Double.infinity, forKey: "controlSpacingAdjustment")
        #expect(Preferences(defaults: defaults).spacing == ControlLayout.defaultSpacingAdjustment)
    }
}

@Test func activeAppOnlyDefaultsToTrueAndPersists() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults)
        #expect(preferences.activeAppOnly)

        preferences.activeAppOnly = false
        #expect(!Preferences(defaults: defaults).activeAppOnly)

        preferences.activeAppOnly = true
        #expect(Preferences(defaults: defaults).activeAppOnly)
    }
}

@Test func activeAppOnlyLocalizationKeysExistInBothLanguages() {
    #expect(AppLocalization.string(.activeAppOnly, language: .simplifiedChinese) == "仅前台应用")
    #expect(AppLocalization.string(.activeAppOnly, language: .english) == "Frontmost App Only")
    #expect(AppLocalization.string(.activeAppOnlyHelp, language: .simplifiedChinese) == "仅对最前台的应用显示放大按钮，降低 CPU 占用")
    #expect(AppLocalization.string(.activeAppOnlyHelp, language: .english) == "Show enlarged window controls only for the frontmost application to reduce CPU usage")
}

@Test func maxRefreshRateDefaultsToHZ120AndPersists() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults)
        #expect(preferences.maxRefreshRate == .hz120)
        #expect(preferences.maxRefreshRate.interval == 1.0 / 120.0)

        preferences.maxRefreshRate = .hz60
        #expect(Preferences(defaults: defaults).maxRefreshRate == .hz60)
        #expect(Preferences(defaults: defaults).maxRefreshRate.interval == 1.0 / 60.0)
    }
}

@Test func corruptStoredMaxRefreshRateFallsBackToHZ120() {
    withDefaults { defaults in
        defaults.set(999.0, forKey: "maxRefreshRate")
        #expect(Preferences(defaults: defaults).maxRefreshRate == .hz120)

        defaults.set(0.0, forKey: "maxRefreshRate")
        #expect(Preferences(defaults: defaults).maxRefreshRate == .hz120)
    }
}

@Test func maxRefreshRateLocalizationKeysExistInBothLanguages() {
    #expect(AppLocalization.string(.maxRefreshRate, language: .simplifiedChinese) == "最高刷新率")
    #expect(AppLocalization.string(.maxRefreshRate, language: .english) == "Max Refresh Rate")
    #expect(AppLocalization.string(.refreshRate60, language: .simplifiedChinese) == "60 Hz")
    #expect(AppLocalization.string(.refreshRate60, language: .english) == "60 Hz")
    #expect(AppLocalization.string(.refreshRate120, language: .simplifiedChinese) == "120 Hz")
    #expect(AppLocalization.string(.refreshRate120, language: .english) == "120 Hz")
}

@Test func launchAtLoginLocalizationKeysExistInBothLanguages() {
    #expect(AppLocalization.string(.launchAtLogin, language: .simplifiedChinese) == "开机自启")
    #expect(AppLocalization.string(.launchAtLogin, language: .english) == "Launch at Login")
}

@Test func launchAtLoginWritesToDefaults() {
    withDefaults { defaults in
        let preferences = Preferences(defaults: defaults)
        preferences.launchAtLogin = false  // unregister any previous test side effect
        defaults.set(false, forKey: "launchAtLogin")

        preferences.launchAtLogin = true
        #expect(defaults.bool(forKey: "launchAtLogin"))

        preferences.launchAtLogin = false
        #expect(!defaults.bool(forKey: "launchAtLogin"))
    }
}
