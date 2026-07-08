import SwiftUI
import AVFoundation

private enum VideoWallpaperAsset {
    static let name = "coffee_live_wallpaper"
    static let fileExtension = "mp4"
    static let subdirectory = "Media"

    static var url: URL? {
        Bundle.main.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) ?? Bundle.main.url(
            forResource: name,
            withExtension: fileExtension
        )
    }
}

struct VideoWallpaperBackground: View {
    enum Style {
        case hero
        case quiet
        case onboarding

        var baseDimOpacity: Double {
            switch self {
            case .hero:
                return 0.48
            case .quiet:
                return 0.62
            case .onboarding:
                return 0.56
            }
        }

    }

    let style: Style
    let isMasked: Bool

    init(style: Style = .hero, isMasked: Bool = true) {
        self.style = style
        self.isMasked = isMasked
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05) // Deep solid obsidian
            
            if isMasked {
                ZStack {
                    LoopingVideoPlayerView()
                    Color.black.opacity(style.baseDimOpacity)
                }
                .mask(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .opacity(0.4)
            } else {
                LoopingVideoPlayerView()
                Color.black.opacity(style.baseDimOpacity)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct LoopingVideoPlayerView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SeamlessLoopingVideoView {
        let view = SeamlessLoopingVideoView()
        
        guard let url = VideoWallpaperAsset.url else {
            view.backgroundColor = UIColor.black
            assertionFailure("Missing bundled wallpaper video: \(VideoWallpaperAsset.name).\(VideoWallpaperAsset.fileExtension)")
            return view
        }
        
        let controller = SeamlessVideoLoopController(url: url)
        controller.attach(to: view)
        controller.play()
        context.coordinator.controller = controller

        return view
    }

    func updateUIView(_ uiView: SeamlessLoopingVideoView, context: Context) {
        context.coordinator.controller?.attach(to: uiView)
        context.coordinator.controller?.play()
    }

    static func dismantleUIView(_ uiView: SeamlessLoopingVideoView, coordinator: Coordinator) {
        coordinator.controller?.stop()
    }

    final class Coordinator {
        var controller: SeamlessVideoLoopController?
    }
}

private final class SeamlessVideoLoopController {
    private let overlapDuration: TimeInterval = 0.45
    private let duration: TimeInterval
    private var primaryPlayer: AVPlayer
    private var secondaryPlayer: AVPlayer
    private weak var view: SeamlessLoopingVideoView?
    private var activeSlot: Slot = .primary
    private var observer: Any?
    private weak var observedPlayer: AVPlayer?
    private var isCrossfading = false
    
    private enum Slot {
        case primary
        case secondary
    }
    
    init(url: URL) {
        let asset = AVURLAsset(url: url)
        let loadedDuration = asset.duration.seconds
        duration = loadedDuration.isFinite && loadedDuration > 0 ? loadedDuration : 0
        
        primaryPlayer = Self.makePlayer(url: url)
        secondaryPlayer = Self.makePlayer(url: url)
    }
    
    deinit {
        stop()
    }
    
    func attach(to view: SeamlessLoopingVideoView) {
        self.view = view
        view.primaryPlayerView.playerLayer.player = primaryPlayer
        view.secondaryPlayerView.playerLayer.player = secondaryPlayer
        view.primaryPlayerView.alpha = activeSlot == .primary ? 1 : 0
        view.secondaryPlayerView.alpha = activeSlot == .secondary ? 1 : 0
    }
    
    func play() {
        observeActivePlayer()
        activePlayer.playImmediately(atRate: 0.45)
    }
    
    func stop() {
        removeObserverIfNeeded()
        
        primaryPlayer.pause()
        secondaryPlayer.pause()
        view?.primaryPlayerView.playerLayer.player = nil
        view?.secondaryPlayerView.playerLayer.player = nil
    }
    
    private var activePlayer: AVPlayer {
        activeSlot == .primary ? primaryPlayer : secondaryPlayer
    }
    
    private var standbyPlayer: AVPlayer {
        activeSlot == .primary ? secondaryPlayer : primaryPlayer
    }
    
    private var activePlayerView: PlayerHostView? {
        activeSlot == .primary ? view?.primaryPlayerView : view?.secondaryPlayerView
    }
    
    private var standbyPlayerView: PlayerHostView? {
        activeSlot == .primary ? view?.secondaryPlayerView : view?.primaryPlayerView
    }
    
    private func observeActivePlayer() {
        removeObserverIfNeeded()
        
        guard duration > overlapDuration else { return }
        
        observedPlayer = activePlayer
        observer = activePlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.handlePlaybackTick(time.seconds)
        }
    }
    
    private func handlePlaybackTick(_ seconds: Double) {
        guard duration > overlapDuration, !isCrossfading else { return }
        
        let remaining = duration - seconds
        if remaining <= overlapDuration {
            startCrossfade()
        }
    }
    
    private func startCrossfade() {
        guard let activeView = activePlayerView, let standbyView = standbyPlayerView else { return }
        
        isCrossfading = true
        
        standbyPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        standbyPlayer.playImmediately(atRate: 0.45)
        
        standbyView.alpha = 0
        UIView.animate(withDuration: overlapDuration, delay: 0, options: [.curveLinear]) {
            standbyView.alpha = 1
            activeView.alpha = 0
        } completion: { [weak self] _ in
            self?.completeCrossfade()
        }
    }
    
    private func completeCrossfade() {
        let previousActive = activePlayer
        previousActive.pause()
        previousActive.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        
        activeSlot = activeSlot == .primary ? .secondary : .primary
        standbyPlayerView?.alpha = 0
        activePlayerView?.alpha = 1
        isCrossfading = false
        
        observeActivePlayer()
        activePlayer.playImmediately(atRate: 0.45)
    }
    
    private func removeObserverIfNeeded() {
        if let observer, let observedPlayer {
            observedPlayer.removeTimeObserver(observer)
        }
        
        observer = nil
        observedPlayer = nil
    }
    
    private static func makePlayer(url: URL) -> AVPlayer {
        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .timeDomain
        
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.volume = 0
        player.actionAtItemEnd = .pause
        player.automaticallyWaitsToMinimizeStalling = false
        
        return player
    }
}

private final class SeamlessLoopingVideoView: UIView {
    let primaryPlayerView = PlayerHostView()
    let secondaryPlayerView = PlayerHostView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .black
        clipsToBounds = true
        
        addSubview(primaryPlayerView)
        addSubview(secondaryPlayerView)
        
        primaryPlayerView.alpha = 1
        secondaryPlayerView.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        primaryPlayerView.frame = bounds
        secondaryPlayerView.frame = bounds
    }
}

private final class PlayerHostView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("Expected AVPlayerLayer backing layer")
        }
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}
