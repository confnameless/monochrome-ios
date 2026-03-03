import Foundation
import AVFoundation
import MediaPlayer
import Observation
import UIKit

@Observable
class AudioPlayerService {
    var player: AVQueuePlayer?
    var isPlaying: Bool = false
    var currentTrackTitle: String = "No Track"
    var currentArtistName: String = "Unknown Artist"
    var currentAlbumTitle: String = ""
    var currentCoverUrl: URL? = nil
    var currentTrack: Track? = nil

    // Playback state
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private var timeObserverToken: Any?
    private var nowPlayingArtwork: MPMediaItemArtwork?

    // Queue support
    var queuedTracks: [Track] = []
    var playHistory: [Track] = []

    var hasPreviousTrack: Bool { !playHistory.isEmpty }
    var hasNextTrack: Bool { !queuedTracks.isEmpty }

    init() {
        setupRemoteCommandCenter()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    func play(track: Track, queue: [Track] = []) {
        // Clean up previous observer if any
        removeTimeObserver()

        // Push current track to history before switching
        if let current = currentTrack {
            playHistory.append(current)
        }

        self.queuedTracks = queue
        self.currentTrack = track

        Task {
            if let streamUrlStr = try? await MonochromeAPI().fetchStreamUrl(trackId: track.id),
               let url = URL(string: streamUrlStr) {

                let asset = AVURLAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)

                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(playerItemDidReachEnd),
                                                       name: .AVPlayerItemDidPlayToEndTime,
                                                       object: playerItem)

                await MainActor.run {
                    if self.player == nil {
                        self.player = AVQueuePlayer(playerItem: playerItem)
                    } else {
                        self.player?.removeAllItems()
                        if self.player?.canInsert(playerItem, after: nil) == true {
                            self.player?.insert(playerItem, after: nil)
                        }
                    }

                    self.player?.play()

                    self.isPlaying = true
                    self.currentTrackTitle = track.title
                    self.currentArtistName = track.artist?.name ?? "Unknown Artist"
                    self.currentAlbumTitle = track.album?.title ?? ""
                    self.currentCoverUrl = MonochromeAPI().getImageUrl(id: track.album?.cover)
                    self.currentTime = 0
                    self.duration = 0

                    self.addTimeObserver()
                    self.updateNowPlayingInfo()
                }

                // Load duration asynchronously
                if let durationSeconds = try? await asset.load(.duration).seconds, !durationSeconds.isNaN {
                    await MainActor.run {
                        self.duration = durationSeconds
                        self.updateNowPlayingInfo()
                    }
                }

                // Load artwork asynchronously
                if let coverUrl = MonochromeAPI().getImageUrl(id: track.album?.cover) {
                    if let (data, _) = try? await URLSession.shared.data(from: coverUrl), let image = UIImage(data: data) {
                        await MainActor.run {
                            self.nowPlayingArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
                            self.updateNowPlayingInfo()
                        }
                    }
                } else {
                    await MainActor.run {
                        self.nowPlayingArtwork = nil
                        self.updateNowPlayingInfo()
                    }
                }
            }
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        nextTrack()
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }

    func seek(to time: TimeInterval) {
        guard let customPlayer = player else { return }

        let targetTime = CMTime(seconds: time, preferredTimescale: 1000)
        customPlayer.seek(to: targetTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    func nextTrack() {
        guard !queuedTracks.isEmpty else {
            player?.pause()
            isPlaying = false
            updateNowPlayingInfo()
            return
        }

        let next = queuedTracks.removeFirst()
        play(track: next, queue: queuedTracks)
    }

    func previousTrack() {
        // If more than 3 seconds in, restart current track
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        guard !playHistory.isEmpty else {
            seek(to: 0)
            return
        }

        // Put current track back at front of queue
        if let current = currentTrack {
            queuedTracks.insert(current, at: 0)
        }

        let previous = playHistory.removeLast()
        // Use internal play without pushing to history again
        removeTimeObserver()
        self.currentTrack = previous

        Task {
            if let streamUrlStr = try? await MonochromeAPI().fetchStreamUrl(trackId: previous.id),
               let url = URL(string: streamUrlStr) {

                let asset = AVURLAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)

                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(playerItemDidReachEnd),
                                                       name: .AVPlayerItemDidPlayToEndTime,
                                                       object: playerItem)

                await MainActor.run {
                    self.player?.removeAllItems()
                    if self.player?.canInsert(playerItem, after: nil) == true {
                        self.player?.insert(playerItem, after: nil)
                    }

                    self.player?.play()
                    self.isPlaying = true
                    self.currentTrackTitle = previous.title
                    self.currentArtistName = previous.artist?.name ?? "Unknown Artist"
                    self.currentAlbumTitle = previous.album?.title ?? ""
                    self.currentCoverUrl = MonochromeAPI().getImageUrl(id: previous.album?.cover)
                    self.currentTime = 0
                    self.duration = 0

                    self.addTimeObserver()
                    self.updateNowPlayingInfo()
                }

                if let durationSeconds = try? await asset.load(.duration).seconds, !durationSeconds.isNaN {
                    await MainActor.run {
                        self.duration = durationSeconds
                        self.updateNowPlayingInfo()
                    }
                }

                if let coverUrl = MonochromeAPI().getImageUrl(id: previous.album?.cover) {
                    if let (data, _) = try? await URLSession.shared.data(from: coverUrl), let image = UIImage(data: data) {
                        await MainActor.run {
                            self.nowPlayingArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
                            self.updateNowPlayingInfo()
                        }
                    }
                }
            }
        }
    }

    private func addTimeObserver() {
        guard let customPlayer = player else { return }

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = customPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let customPlayer = player {
            customPlayer.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrackTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentArtistName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = currentAlbumTitle

        if let artwork = nowPlayingArtwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    deinit {
        removeTimeObserver()
    }
}
