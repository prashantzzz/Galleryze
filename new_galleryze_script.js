// User state management
let currentUser = null;

// Fetch current user info when page loads
async function fetchCurrentUser() {
    try {
        const response = await fetch('/api/user');
        const data = await response.json();
        
        if (data.user) {
            currentUser = data.user;
            console.log('Current user:', currentUser);
            return currentUser;
        }
    } catch (error) {
        console.error('Error fetching user:', error);
    }
    return null;
}

// Initialize user data when page loads
document.addEventListener('DOMContentLoaded', async () => {
    await fetchCurrentUser();
    
    // Once we have the user, fetch their favorites
    if (currentUser) {
        await syncFavorites();
    }
});

// Save favorites to server using API
async function toggleFavorite(element, photoId) {
    element.classList.toggle('active');
    const photoItem = element.closest('.photo-item');
    const isFavorite = element.classList.contains('active');
    
    if (isFavorite) {
        element.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#f44336"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>';
        photoItem.setAttribute('data-favorite', 'true');
    } else {
        element.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg>';
        photoItem.setAttribute('data-favorite', 'false');
        
        // If we're in favorites view, hide this item
        const currentFilter = document.querySelector('.current-filter').getAttribute('data-filter');
        if (currentFilter === 'favorites') {
            photoItem.style.display = 'none';
        }
    }
    
    // Optimistically update UI (above) but also save to server
    if (currentUser) {
        try {
            // Use our server API endpoint that will connect to Supabase
            const response = await fetch('/api/favorites', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    photoId: photoId,
                    isFavorite: isFavorite
                })
            });
            
            const result = await response.json();
            if (!result.success) {
                console.error('Failed to save favorite:', result.message);
                // Revert UI change on error
                element.classList.toggle('active');
                photoItem.setAttribute('data-favorite', !isFavorite);
            }
        } catch (error) {
            console.error('Error saving favorite:', error);
            // Fallback to localStorage if server save fails
            if (isFavorite) {
                localStorage.setItem('photo_' + photoId + '_favorite', 'true');
            } else {
                localStorage.removeItem('photo_' + photoId + '_favorite');
            }
        }
    } else {
        // Fallback to localStorage if not logged in
        if (isFavorite) {
            localStorage.setItem('photo_' + photoId + '_favorite', 'true');
        } else {
            localStorage.removeItem('photo_' + photoId + '_favorite');
        }
    }
    
    return false;
}

// Sync favorites from server
async function syncFavorites() {
    if (!currentUser) return;
    
    try {
        const response = await fetch('/api/favorites');
        const data = await response.json();
        
        if (data.favorites) {
            // Update UI for each favorite
            data.favorites.forEach(fav => {
                const photoItem = document.querySelector(`.photo-item[data-id="${fav.photo_id}"]`);
                if (photoItem) {
                    const favBtn = photoItem.querySelector('.favorite-btn');
                    photoItem.setAttribute('data-favorite', 'true');
                    favBtn.classList.add('active');
                    favBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#f44336"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>';
                }
            });
        }
    } catch (error) {
        console.error('Error syncing favorites:', error);
        
        // Fallback to localStorage
        const photoItems = document.querySelectorAll('.photo-item');
        photoItems.forEach(item => {
            const photoId = item.getAttribute('data-id');
            const isFavorite = localStorage.getItem('photo_' + photoId + '_favorite') === 'true';
            
            if (isFavorite) {
                const favBtn = item.querySelector('.favorite-btn');
                item.setAttribute('data-favorite', 'true');
                favBtn.classList.add('active');
                favBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#f44336"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>';
            }
        });
    }
}

// Functions for custom category creation
function openCreateCategoryModal() {
    const modal = document.getElementById('createCategoryModal');
    if (modal) {
        modal.style.display = 'flex';
        // Clear the input field
        document.getElementById('newCategoryName').value = '';
    }
}

function closeCreateCategoryModal() {
    const modal = document.getElementById('createCategoryModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

async function createNewCategory() {
    const categoryName = document.getElementById('newCategoryName').value.trim();
    
    if (!categoryName) {
        alert('Please enter a category name');
        return;
    }
    
    try {
        const response = await fetch('/api/categories/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ categoryName })
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Add the new category to the category filter
            const categoryFilter = document.querySelector('.category-filter');
            const addChip = document.querySelector('.add-chip');
            
            // Create new chip for the category
            const newChip = document.createElement('span');
            newChip.className = 'chip';
            newChip.setAttribute('onclick', `navigateToFilter('${categoryName}')`);
            newChip.textContent = categoryName;
            
            // Insert before the + Add chip
            categoryFilter.insertBefore(newChip, addChip);
            
            // Add to category modal
            const categoryModal = document.getElementById('categoryModal');
            if (categoryModal) {
                const saveButton = categoryModal.querySelector('.action-btn');
                
                // Create new category option
                const newOption = document.createElement('div');
                newOption.className = 'category-option';
                newOption.innerHTML = `
                    <input type="checkbox" id="category-${categoryName}" class="category-checkbox" data-category="${categoryName}">
                    <label for="category-${categoryName}">${categoryName}</label>
                `;
                
                // Insert before save button
                categoryModal.insertBefore(newOption, saveButton);
            }
            
            // Close the modal
            closeCreateCategoryModal();
            
            // Store the new category in localStorage as a fallback
            const categories = JSON.parse(localStorage.getItem('custom_categories') || '[]');
            if (!categories.includes(categoryName)) {
                categories.push(categoryName);
                localStorage.setItem('custom_categories', JSON.stringify(categories));
            }
            
            alert(`Category '${categoryName}' created successfully!`);
        } else {
            alert(result.message || 'Failed to create category');
        }
    } catch (error) {
        console.error('Error creating category:', error);
        alert('An error occurred while creating the category. Please try again.');
        
        // Fallback to localStorage
        const categories = JSON.parse(localStorage.getItem('custom_categories') || '[]');
        if (!categories.includes(categoryName)) {
            categories.push(categoryName);
            localStorage.setItem('custom_categories', JSON.stringify(categories));
            
            // Add the new category to UI
            // (Similar to above, but simplified for the fallback case)
            alert(`Category '${categoryName}' created in local storage.`);
            window.location.reload(); // Simple reload to show the new category
        }
    }
}

// Load custom categories on page load
document.addEventListener('DOMContentLoaded', function() {
    // Check if we have custom categories in localStorage as a fallback
    const categories = JSON.parse(localStorage.getItem('custom_categories') || '[]');
    if (categories.length > 0) {
        const categoryFilter = document.querySelector('.category-filter');
        const addChip = document.querySelector('.add-chip');
        const categoryModal = document.getElementById('categoryModal');
        const saveButton = categoryModal ? categoryModal.querySelector('.action-btn') : null;
        const categoryList = document.querySelector('.category-list');
        
        categories.forEach(category => {
            // Add to filter chips
            if (categoryFilter && addChip) {
                const newChip = document.createElement('span');
                newChip.className = 'chip';
                newChip.setAttribute('onclick', `navigateToFilter('${category}')`);
                newChip.textContent = category;
                categoryFilter.insertBefore(newChip, addChip);
            }
            
            // Add to category modal
            if (categoryModal && saveButton) {
                const newOption = document.createElement('div');
                newOption.className = 'category-option';
                newOption.innerHTML = `
                    <input type="checkbox" id="category-${category}" class="category-checkbox" data-category="${category}">
                    <label for="category-${category}">${category}</label>
                `;
                categoryModal.insertBefore(newOption, saveButton);
            }
            
            // Add to categories page if we're on that page
            if (categoryList && window.location.pathname.includes('/categories')) {
                const randomColor = ['blue', 'red', 'purple', 'orange', 'green', 'amber']
                    [Math.floor(Math.random() * 6)];
                    
                const randomIcon = ['image', 'photo_camera', 'portrait', 'landscape', 'circle', 'star']
                    [Math.floor(Math.random() * 6)];
                
                const newCategoryItem = document.createElement('div');
                newCategoryItem.className = 'category-item';
                newCategoryItem.innerHTML = `
                    <div class="category-icon ${randomColor}">
                        <i>${randomIcon}</i>
                    </div>
                    <div class="category-name">${category}</div>
                    <div class="category-actions">
                        <button class="icon-btn small"><i>edit</i></button>
                        <button class="icon-btn small"><i>delete</i></button>
                    </div>
                `;
                
                categoryList.appendChild(newCategoryItem);
            }
        });
    }
});

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
    } else if (filter !== 'all') {
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
    } else if (currentFilter !== 'all') {
        filterByCategory(currentFilter);
    }
}

// Sort photos by date or size
function toggleSortOptions() {
    const sortOptionsDiv = document.getElementById('sort-options');
    if (sortOptionsDiv.style.display === 'none' || !sortOptionsDiv.style.display) {
        sortOptionsDiv.style.display = 'block';
    } else {
        sortOptionsDiv.style.display = 'none';
    }
}

function sortPhotos(method, direction) {
    const photoGrid = document.querySelector('.photo-grid');
    if (!photoGrid) return;
    
    const photos = Array.from(photoGrid.querySelectorAll('.photo-item'));
    
    // Close sort options
    document.getElementById('sort-options').style.display = 'none';
    
    // Update sort button to show current sort
    updateSortButtonText(method, direction);
    
    // If we're sorting by date
    if (method === 'date') {
        photos.sort((a, b) => {
            const dateA = a.getAttribute('data-date') ? new Date(a.getAttribute('data-date')) : new Date(0);
            const dateB = b.getAttribute('data-date') ? new Date(b.getAttribute('data-date')) : new Date(0);
            
            return direction === 'asc' ? dateA - dateB : dateB - dateA;
        });
    } 
    // If we're sorting by size
    else if (method === 'size') {
        photos.sort((a, b) => {
            const sizeA = parseInt(a.getAttribute('data-size') || '0');
            const sizeB = parseInt(b.getAttribute('data-size') || '0');
            
            return direction === 'asc' ? sizeA - sizeB : sizeB - sizeA;
        });
    }
    
    // Remove all photos and re-append them in the sorted order
    photos.forEach(photo => photoGrid.appendChild(photo));
    
    // Save sort preferences
    localStorage.setItem('sort_method', method);
    localStorage.setItem('sort_direction', direction);
    
    // Apply current filter after sorting
    applyCurrentFilter();
}

function updateSortButtonText(method, direction) {
    const sortButton = document.querySelector('.sort-btn');
    if (!sortButton) return;
    
    // Update icon based on sort direction
    const directionIcon = direction === 'asc' ? 
        '<path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/>' : 
        '<path d="M20 12l-1.41-1.41L13 16.17V4h-2v12.17l-5.58-5.59L4 12l8 8 8-8z"/>';
    
    // Set the text
    sortButton.setAttribute('title', `Sorted by ${method} (${direction === 'asc' ? 'Oldest First' : 'Newest First'})`);
    
    // Set the icon SVG based on method and direction
    sortButton.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#666">
            <path d="M0 0h24v24H0z" fill="none"/>
            ${directionIcon}
        </svg>
    `;
}

// Photo details modal functions
function openPhotoDetailsModal(photoId) {
    const modal = document.getElementById('photoDetailsModal');
    const photoItem = document.querySelector(`.photo-item[data-id="${photoId}"]`);
    
    if (!modal || !photoItem) return;
    
    // Fill in photo details
    document.getElementById('photoDetailsId').innerText = photoId;
    document.getElementById('photoDetailsDate').innerText = photoItem.getAttribute('data-date') || 'Unknown';
    document.getElementById('photoDetailsSize').innerText = photoItem.getAttribute('data-size') || '0';
    document.getElementById('photoDetailsCategories').innerText = photoItem.getAttribute('data-categories') || 'None';
    document.getElementById('photoDetailsFavorite').innerText = photoItem.getAttribute('data-favorite') === 'true' ? 'Yes' : 'No';
    
    // Set preview
    const preview = document.getElementById('photoDetailsPreview');
    if (preview) {
        preview.innerText = photoItem.querySelector('.photo-placeholder').innerText;
    }
    
    // Show modal
    modal.style.display = 'flex';
    
    return false;
}

function closePhotoDetailsModal() {
    const modal = document.getElementById('photoDetailsModal');
    if (modal) {
        modal.style.display = 'none';
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
        
        // Add click handler for the photo item to show details
        item.querySelector('.photo-placeholder').addEventListener('click', function() {
            openPhotoDetailsModal(photoId);
        });
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