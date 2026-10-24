import Foundation
import IOKit.pwr_mgt
import CoreGraphics
import AppKit

public struct VideoPlaybackStatus: Sendable, Equatable {
    public let isVideoPlaying: Bool
    public let isDisplayOn: Bool
    public let playingProcessName: String?

    public init(isVideoPlaying: Bool, isDisplayOn: Bool, playingProcessName: String?) {
        self.isVideoPlaying = isVideoPlaying
        self.isDisplayOn = isDisplayOn
        self.playingProcessName = playingProcessName
    }
}

public protocol VideoPlaybackDetecting: Sendable {
    func checkStatus() -> VideoPlaybackStatus
}

public final class VideoPlaybackDetector: VideoPlaybackDetecting, @unchecked Sendable {
    public static let shared = VideoPlaybackDetector()

    private let knownMediaProcesses: Set<String> = [
        "safari", "google chrome", "chrome", "arc", "brave browser", "brave",
        "firefox", "microsoft edge", "edge", "opera", "vivaldi", "orion",
        "quicktime player", "vlc", "iina", "mpv", "tv", "plex", "infuse",
        "elmedia player", "keynote", "powerpoint", "youtube", "netflix",
        "subler", "omniplayer"
    ]

    private let ignoredSystemProcesses: Set<String> = [
        "powerd", "bluetoothd", "sharingd", "windowserver", "mds", "backupd"
    ]

    public init() {}

    public func checkStatus() -> VideoPlaybackStatus {
        let isDisplayOn = (CGDisplayIsAsleep(CGMainDisplayID()) == 0) && !NSScreen.screens.isEmpty
        guard isDisplayOn else {
            return VideoPlaybackStatus(isVideoPlaying: false, isDisplayOn: false, playingProcessName: nil)
        }

        var assertionsByProcess: Unmanaged<CFDictionary>?
        let status = IOPMCopyAssertionsByProcess(&assertionsByProcess)
        guard status == kIOReturnSuccess,
              let dict = assertionsByProcess?.takeRetainedValue() as? [NSNumber: [CFDictionary]] else {
            return VideoPlaybackStatus(isVideoPlaying: false, isDisplayOn: isDisplayOn, playingProcessName: nil)
        }

        for (_, assertionsList) in dict {
            for assertion in assertionsList {
                guard let info = assertion as? [String: Any] else { continue }

                let type = info["AssertType"] as? String ?? ""
                let trueType = info["AssertionTrueType"] as? String ?? ""
                let level = info["AssertLevel"] as? Int ?? 0

                let isDisplaySleepAssertion = (type == "PreventUserIdleDisplaySleep" ||
                                               trueType == "PreventUserIdleDisplaySleep" ||
                                               type == "NoDisplaySleepAssertion") && level > 0

                guard isDisplaySleepAssertion else { continue }

                let procName = (info["Process Name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let lowerProc = procName.lowercased()

                if ignoredSystemProcesses.contains(lowerProc) {
                    continue
                }

                let assertName = (info["AssertName"] as? String ?? "").lowercased()

                let isMediaApp = knownMediaProcesses.contains(lowerProc) ||
                                 lowerProc.contains("webkit") ||
                                 lowerProc.contains("chrome")
                let isMediaAssertion = assertName.contains("htmlmediaelement") ||
                                       assertName.contains("video") ||
                                       assertName.contains("playback") ||
                                       assertName.contains("screen wake lock") ||
                                       assertName.contains("powersaveblocker") ||
                                       assertName.contains("webrtc")

                if isMediaApp || isMediaAssertion {
                    return VideoPlaybackStatus(
                        isVideoPlaying: true,
                        isDisplayOn: true,
                        playingProcessName: procName.isEmpty ? nil : procName
                    )
                }
            }
        }

        return VideoPlaybackStatus(isVideoPlaying: false, isDisplayOn: true, playingProcessName: nil)
    }
}
