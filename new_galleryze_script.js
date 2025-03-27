// Save the favorites to localStorage so they persist
function toggleFavorite(element, photoId) {
    element.classList.toggle('active');
    const photoItem = element.closest('.photo-item');
    
    if (element.classList.contains('active')) {
        element.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#f44336"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>';
        photoItem.setAttribute('data-favorite', 'true');
        
        // Store favorite status
        localStorage.setItem('photo_' + photoId + '_favorite', 'true');
    } else {
        element.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg>';
        photoItem.setAttribute('data-favorite', 'false');
        
        // Remove favorite status
        localStorage.removeItem('photo_' + photoId + '_favorite');
        
        // If we're in favorites view, hide this item
        const currentFilter = document.querySelector('.current-filter').getAttribute('data-filter');
        if (currentFilter === 'favorites') {
            photoItem.style.display = 'none';
        }
    }
    
    return false;
}

// Category modal functions
function openCategoryModal(photoId) {
    const modal = document.getElementById('categoryModal');
    modal.style.display = 'flex';
    document.getElementById('currentPhotoId').innerText = photoId;
    
    // Get current categories for this photo
    const photoItem = document.querySelector(`.photo-item[data-id="${photoId}"]`);
    const categories = photoItem.dataset.categories ? photoItem.dataset.categories.split(',') : [];
    
    // Reset all checkboxes first
    document.querySelectorAll('.category-checkbox').forEach(checkbox => {
        checkbox.checked = false;
    });
    
    // Set the checkboxes for existing categories
    categories.forEach(category => {
        const checkbox = document.getElementById(`category-${category}`);
        if (checkbox) {
            checkbox.checked = true;
        }
    });
    
    return false;
}

function closeCategoryModal() {
    const modal = document.getElementById('categoryModal');
    modal.style.display = 'none';
}

function saveCategories() {
    const photoId = document.getElementById('currentPhotoId').innerText;
    const photoItem = document.querySelector(`.photo-item[data-id="${photoId}"]`);
    
    // Get selected categories
    const selectedCategories = [];
    document.querySelectorAll('.category-checkbox:checked').forEach(checkbox => {
        selectedCategories.push(checkbox.dataset.category);
    });
    
    // Update photo item with categories
    photoItem.setAttribute('data-categories', selectedCategories.join(','));
    
    // Save to localStorage
    localStorage.setItem('photo_' + photoId + '_categories', selectedCategories.join(','));
    
    // Close modal
    closeCategoryModal();
    
    // Apply category filter if one is active
    applyCurrentFilter();
}

// Navigate to different filters
function navigateToFilter(filter) {
    // Remove selection from all chips first
    document.querySelectorAll('.chip').forEach(chip => {
        chip.classList.remove('selected');
    });
    
    if (filter === 'favorites') {
        // Select the favorites chip
        const favoritesChip = document.querySelector(`.chip[onclick="navigateToFilter('favorites')"]`);
        if (favoritesChip) {
            favoritesChip.classList.add('selected');
        }
        
        // Show only favorite items
        const photoItems = document.querySelectorAll('.photo-item');
        photoItems.forEach(item => {
            const isFavorite = item.getAttribute('data-favorite') === 'true';
            item.style.display = isFavorite ? '' : 'none';
        });
        
        // Update current filter
        const currentFilterEl = document.querySelector('.current-filter');
        if (currentFilterEl) {
            currentFilterEl.setAttribute('data-filter', 'favorites');
        }
    } else if (['Recent', 'Vacation', 'Family', 'Food'].includes(filter)) {
        // Find and select the clicked chip
        const clickedChip = document.querySelector(`.chip[onclick="navigateToFilter('${filter}')"]`);
        if (clickedChip) {
            clickedChip.classList.add('selected');
        }
        
        filterByCategory(filter);
    } else {
        // All photos - select the "all" chip
        const allChip = document.querySelector(`.chip[onclick="navigateToFilter('all')"]`);
        if (allChip) {
            allChip.classList.add('selected');
        }
        
        // Show all items
        const photoItems = document.querySelectorAll('.photo-item');
        photoItems.forEach(item => {
            item.style.display = '';
        });
        
        // Update current filter
        const currentFilterEl = document.querySelector('.current-filter');
        if (currentFilterEl) {
            currentFilterEl.setAttribute('data-filter', 'all');
        }
    }
}

function filterByCategory(category) {
    const photoItems = document.querySelectorAll('.photo-item');
    
    photoItems.forEach(item => {
        if (category === 'all') {
            item.style.display = '';
        } else {
            const itemCategories = item.dataset.categories ? item.dataset.categories.split(',') : [];
            if (itemCategories.includes(category)) {
                item.style.display = '';
            } else {
                item.style.display = 'none';
            }
        }
    });
    
    // Set data-filter attribute for the current filter
    const currentFilterEl = document.querySelector('.current-filter');
    if (currentFilterEl) {
        currentFilterEl.setAttribute('data-filter', category);
    }
}

function applyCurrentFilter() {
    const currentFilterEl = document.querySelector('.current-filter');
    // Check if the element exists before trying to get attribute
    if (!currentFilterEl) return;
    
    const currentFilter = currentFilterEl.getAttribute('data-filter');
    
    if (currentFilter === 'favorites') {
        // Show only favorites
        const photoItems = document.querySelectorAll('.photo-item');
        photoItems.forEach(item => {
            const isFavorite = item.getAttribute('data-favorite') === 'true';
            item.style.display = isFavorite ? '' : 'none';
        });
    } else if (currentFilter !== 'all' && ['Recent', 'Vacation', 'Family', 'Food'].includes(currentFilter)) {
        filterByCategory(currentFilter);
    }
}

// Apply filter when the page loads
window.addEventListener('DOMContentLoaded', function() {
    const currentFilterEl = document.querySelector('.current-filter');
    const currentFilter = currentFilterEl ? currentFilterEl.getAttribute('data-filter') : 'all';
    
    // Load favorite statuses from localStorage
    const photoItems = document.querySelectorAll('.photo-item');
    photoItems.forEach(function(item) {
        const photoId = item.getAttribute('data-id');
        
        // Load favorite status
        const isFavorite = localStorage.getItem('photo_' + photoId + '_favorite') === 'true';
        item.setAttribute('data-favorite', isFavorite ? 'true' : 'false');
        
        const favBtn = item.querySelector('.favorite-btn');
        if (isFavorite && favBtn) {
            favBtn.classList.add('active');
            favBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#f44336"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>';
        }
        
        // Load categories
        const savedCategories = localStorage.getItem('photo_' + photoId + '_categories');
        if (savedCategories) {
            item.setAttribute('data-categories', savedCategories);
        }
    });
    
    // If we're on the favorites page (URL contains /favorites), set the filter properly
    if (window.location.pathname.includes('/favorites')) {
        // Select favorites chip
        const favoritesChip = document.querySelector(`.chip[onclick="navigateToFilter('favorites')"]`);
        if (favoritesChip) {
            // Remove selection from all chips
            document.querySelectorAll('.chip').forEach(chip => {
                chip.classList.remove('selected');
            });
            
            favoritesChip.classList.add('selected');
        }
        
        // Set current filter
        if (currentFilterEl) {
            currentFilterEl.setAttribute('data-filter', 'favorites');
        }
        
        // Show only favorite items
        photoItems.forEach(item => {
            const isFavorite = item.getAttribute('data-favorite') === 'true';
            item.style.display = isFavorite ? '' : 'none';
        });
    } else {
        // Apply current filter
        applyCurrentFilter();
    }
});