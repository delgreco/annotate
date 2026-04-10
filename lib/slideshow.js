let currentIndex = 0;
let previousIndex = -1;
let isPaused = false;
let isSlideshowEnabled = true;
let slideshowInterval;

function updateHighlights() {
    // Remove all highlights first
    document.querySelectorAll('a[data-filename]').forEach(a => {
        a.classList.remove('highlight', 'highlight-current', 'highlight-previous');
    });

    const markersContainer = document.getElementById('scrollbar_markers');
    const scrollContainer = document.getElementById('scroll_container');
    if (markersContainer) markersContainer.innerHTML = '';

    const addMarker = (index, isCurrent) => {
        if (index >= 0 && index < images.length) {
            const img = images[index];
            const link = document.querySelector(`a[data-filename="${img.filename}"]`);
            if (link) {
                link.classList.add('highlight');
                link.classList.add(isCurrent ? 'highlight-current' : 'highlight-previous');
                if (isCurrent) {
                    link.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
                if (markersContainer && scrollContainer) {
                    const rect = scrollContainer.getBoundingClientRect();
                    const linkRect = link.getBoundingClientRect();
                    const containerTop = scrollContainer.scrollTop;
                    const relativeTop = link.offsetTop;
                    const totalHeight = scrollContainer.scrollHeight;
                    const markerTopPercent = (relativeTop / totalHeight) * 100;
                    
                    const marker = document.createElement('div');
                    marker.style.position = 'absolute';
                    marker.style.top = markerTopPercent + '%';
                    marker.style.right = '0';
                    marker.style.width = '100%';
                    marker.style.height = '4px';
                    marker.style.backgroundColor = isCurrent ? '#FFD700' : '#FFFFCC'; // Bright yellow for current, pale for previous
                    marker.style.border = '1px solid #999';
                    marker.style.borderRadius = '2px';
                    marker.style.zIndex = '1000';
                    markersContainer.appendChild(marker);
                }
            }
        }
    };

    // Highlight current
    addMarker(currentIndex, true);

    // Highlight previous
    addMarker(previousIndex, false);
}

window.onresize = updateHighlights;

function showImg(filename, notes) {
    const image = document.getElementById('img');
    image.src = filename;
    const img_link = document.getElementById('img_link');
    img_link.href = filename;
    const captionElement = document.getElementById('caption');
    if ( notes ) {
        captionElement.textContent = filename + ': ' + notes;
    }
    else {
        captionElement.textContent = filename;
    }

    // Update currentIndex and previousIndex when manually selecting an image
    previousIndex = currentIndex;
    currentIndex = images.findIndex(img => img.filename === filename);
    updateHighlights();

    // Turn off slideshow when a specific image is clicked
    if (isSlideshowEnabled) {
        toggleSlideshow();
    }
}

function toggleSlideshow() {
    isSlideshowEnabled = !isSlideshowEnabled;
    updateSlideshowUI();
}

function updateSlideshowUI() {
    const cb = document.getElementById('slideshow_toggle');
    if (cb) {
        cb.checked = isSlideshowEnabled;
    }
    const container = document.getElementById('slideshow_duration_container');
    if (container) {
        container.style.display = isSlideshowEnabled ? 'inline' : 'none';
    }
    updateSlideshowInterval();
}

function updateSlideshowInterval() {
    if (slideshowInterval) {
        clearInterval(slideshowInterval);
    }
    
    if (!isSlideshowEnabled) return;
    
    if (typeof images === 'undefined' || images.length <= 1) return;

    const durationInput = document.getElementById('slideshow_duration');
    const seconds = durationInput ? parseInt(durationInput.value) : 30;
    const ms = (seconds || 30) * 1000;

    slideshowInterval = setInterval(nextSlide, ms);
}

function nextSlide() {
    if (!isSlideshowEnabled || isPaused) return;
    
    previousIndex = currentIndex;
    
    // Select a random image, but try to avoid picking the same one twice in a row
    let nextIndex;
    if (images.length > 1) {
        do {
            nextIndex = Math.floor(Math.random() * images.length);
        } while (nextIndex === currentIndex);
    } else {
        nextIndex = 0;
    }
    
    currentIndex = nextIndex;
    const nextImg = images[currentIndex];
    const imgElement = document.getElementById('img');
    const imgLink = document.getElementById('img_link');
    const captionElement = document.getElementById('caption');

    // Simple fade effect using opacity
    imgElement.style.transition = 'opacity 1s ease-in-out';
    imgElement.style.opacity = 0;

    setTimeout(() => {
        imgElement.src = nextImg.filename;
        imgLink.href = nextImg.filename;
        captionElement.textContent = nextImg.caption;
        imgElement.style.opacity = 1;
        updateHighlights();
    }, 1000);
}

function startSlideshow() {
    updateSlideshowUI();
    
    // Set initial currentIndex based on the random image shown
    const initialImg = document.getElementById('img');
    if (initialImg) {
        const src = initialImg.getAttribute('src');
        if (typeof images !== 'undefined') {
            currentIndex = images.findIndex(img => img.filename === src);
            if (currentIndex === -1) currentIndex = 0;
            updateHighlights();
        }
    }

    if (typeof images === 'undefined' || images.length <= 1) {
        const ctrl = document.getElementById('slideshow_control');
        if (ctrl) ctrl.style.display = 'none';
        return;
    }
}

window.onload = startSlideshow;
