import 'package:flutter/material.dart';

class MediaCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final double aspectRatio;
  final VoidCallback? onFullScreen;
  final bool showFullScreenButton;
  final bool showNavigationArrows;
  final bool showDotIndicators;

  const MediaCarousel({
    super.key,
    required this.mediaUrls,
    this.aspectRatio = 16 / 9,
    this.onFullScreen,
    this.showFullScreenButton = true,
    this.showNavigationArrows = true,
    this.showDotIndicators = true,
  });

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isVideoUrl(String url) {
    return url.toLowerCase().contains('.mp4') ||
        url.toLowerCase().contains('.mov') ||
        url.toLowerCase().contains('.avi') ||
        url.toLowerCase().contains('.webm');
  }

  void _onMediaTap(int index) {
    if (widget.onFullScreen != null) {
      widget.onFullScreen!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image,
            size: 100,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index % widget.mediaUrls.length;
                  });
                },
                itemCount: null, // Infinite circular scrolling
                itemBuilder: (context, index) {
                  final actualIndex = index % widget.mediaUrls.length;
                  final mediaUrl = widget.mediaUrls[actualIndex];
                  
                  return GestureDetector(
                    onTap: () => _onMediaTap(actualIndex),
                    child: _buildMediaItem(mediaUrl),
                  );
                },
              ),
            ),
            
            // Full-screen button overlay
            if (widget.showFullScreenButton && widget.onFullScreen != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: widget.onFullScreen,
                  ),
                ),
              ),
            
            // Navigation arrows
            if (widget.showNavigationArrows && widget.mediaUrls.length > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Dot indicators
        if (widget.showDotIndicators && widget.mediaUrls.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.mediaUrls.length,
                (index) {
                  final isVideo = _isVideoUrl(widget.mediaUrls[index]);
                  final isActive = _currentIndex == index;
                  
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                      child: isActive && isVideo
                          ? const Icon(
                              Icons.play_circle_fill,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaItem(String mediaUrl) {
    final isVideo = _isVideoUrl(mediaUrl);

    if (isVideo) {
      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.video_library, size: 100, color: Colors.white),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Image.network(
        mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.broken_image, size: 100),
      );
    }
  }
}