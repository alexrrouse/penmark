import ProjectDescription

let project = Project(
    name: "Penmark",
    organizationName: "Penmark",
    options: .options(
        defaultKnownRegions: ["en"],
        developmentRegion: "en"
    ),
    targets: [
        .target(
            name: "Penmark",
            destinations: .macOS,
            product: .app,
            bundleId: "com.penmark.app",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .file(path: "Sources/Info.plist"),
            sources: ["Sources/**/*.swift"],
            resources: ["Sources/Assets.xcassets"],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": "1.0.0",
                    "CURRENT_PROJECT_VERSION": "1",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "ENABLE_HARDENED_RUNTIME": "YES",
                    "CODE_SIGN_STYLE": "Automatic",
                ],
                defaultSettings: .recommended(excluding: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS"])
            )
        )
    ]
)
