import 'package:flutter/material.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.mediaUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % widget.mediaUrls.length;
              });
            },
            itemCount: null, // Circular scrolling
            itemBuilder: (context, index) {
              final actualIndex = index % widget.mediaUrls.length;
              final mediaUrl = widget.mediaUrls[actualIndex];
              final isVideo = _isVideoUrl(mediaUrl);

              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: isVideo
                      ? _buildFullScreenVideo(mediaUrl)
                      : Image.network(
                          mediaUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.broken_image, size: 100, color: Colors.white),
                        ),
                ),
              );
            },
          ),
          
          // Navigation arrows for full-screen
          if (widget.mediaUrls.length > 1) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
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
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
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
          
          // Bottom indicator dots
          if (widget.mediaUrls.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.mediaUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullScreenVideo(String videoUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.network(
          videoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) =>
              const Icon(Icons.video_library, size: 100, color: Colors.white),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(20),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 60,
          ),
        ),
      ],
    );
  }
}