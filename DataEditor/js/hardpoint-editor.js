/**
 * hardpoint-editor.js
 * Manages the ship hardpoint editor functionality
 */

// Current ship data for hardpoints
let currentShipData = {
    hardpoints: [],
    sprite: null
};

// Ship sprite information
let spriteInfo = {
    element: null,
    naturalWidth: 0,
    naturalHeight: 0,
    displayWidth: 0,
    displayHeight: 0,
    offsetX: 0,
    offsetY: 0,
    scale: 1
};

/**
 * Reset ship data for hardpoints
 */
function resetShipData() {
    currentShipData = {
        hardpoints: [],
        sprite: null
    };
    
    spriteInfo = {
        element: null,
        naturalWidth: 0,
        naturalHeight: 0,
        displayWidth: 0,
        displayHeight: 0,
        offsetX: 0,
        offsetY: 0,
        scale: 1
    };
}

/**
 * Get current ship data
 * @returns {Object} - Current ship data
 */
function getShipData() {
    return { ...currentShipData };
}

/**
 * Set ship data
 * @param {Object} data - Ship data to set
 */
function setShipData(data) {
    if (!data) return;
    
    resetShipData();
    
    // Copy sprite if available
    if (data.sprite) {
        currentShipData.sprite = data.sprite;
    }
    
    // Copy hardpoints if available
    if (data.hardpoints && Array.isArray(data.hardpoints)) {
        currentShipData.hardpoints = [...data.hardpoints];
    }
}

/**
 * Create hardpoint editor
 * @param {HTMLElement} container - Container element for hardpoint editor
 * @param {Function} onChange - Callback for when hardpoints change
 */
function createHardpointEditor(container) {
    if (!container) return;
    
    container.innerHTML = '';
    
    const editorContainer = document.createElement('div');
    editorContainer.className = 'hardpoint-editor';
    container.appendChild(editorContainer);
    
    // Add sprite selector if we have sprites
    if (getSpriteNames().length > 0) {
        // Extract current sprite name from data URL if available
        let currentSpriteName = '';
        if (currentShipData.sprite) {
            // Try to find matching sprite in database
            const spriteNames = getSpriteNames();
            for (const name of spriteNames) {
                if (getSprite(name) === currentShipData.sprite) {
                    currentSpriteName = name;
                    break;
                }
            }
        }
        
        // Create selector that updates the ship sprite when changed
        createSpriteSelector(editorContainer, currentSpriteName, (spriteName) => {
            if (spriteName) {
                const spriteData = getSprite(spriteName);
                if (spriteData) {
                    // Update current ship data
                    currentShipData.sprite = spriteData;
                    
                    // Update sprite in UI
                    updateSpriteDisplay(spriteData);
                }
            } else {
                // Clear sprite if none selected
                currentShipData.sprite = null;
                
                // Update UI
                const spriteContainer = document.getElementById('sprite-container');
                if (spriteContainer) {
                    resetSpriteContainer(spriteContainer);
                }
            }
        });
    }
    
    // Create sprite upload section
    const spriteContainer = document.createElement('div');
    spriteContainer.className = 'sprite-container';
    spriteContainer.id = 'sprite-container';
    editorContainer.appendChild(spriteContainer);
    
    // Placeholder text when no sprite is uploaded
    const placeholderText = document.createElement('div');
    placeholderText.textContent = 'Drag & drop a sprite image or click to upload';
    placeholderText.id = 'sprite-placeholder';
    spriteContainer.appendChild(placeholderText);
    
    // Sprite upload button
    const uploadButton = document.createElement('button');
    uploadButton.className = 'sprite-upload-btn';
    uploadButton.textContent = 'Upload Sprite';
    uploadButton.id = 'sprite-upload-btn';
    spriteContainer.appendChild(uploadButton);
    
    // Hidden file input for sprite upload
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.id = 'sprite-file-input';
    fileInput.accept = 'image/*';
    fileInput.style.display = 'none';
    spriteContainer.appendChild(fileInput);
    
    // Hardpoint controls
    const controlsContainer = document.createElement('div');
    controlsContainer.className = 'hardpoint-controls';
    editorContainer.appendChild(controlsContainer);
    
    // Add hardpoint button
    const addHardpointBtn = document.createElement('button');
    addHardpointBtn.textContent = 'Add Hardpoint';
    addHardpointBtn.id = 'add-hardpoint-btn';
    addHardpointBtn.className = 'add-equipment-btn';
    controlsContainer.appendChild(addHardpointBtn);
    
    // Clear all hardpoints button
    const clearHardpointsBtn = document.createElement('button');
    clearHardpointsBtn.textContent = 'Clear All Hardpoints';
    clearHardpointsBtn.id = 'clear-hardpoints-btn';
    clearHardpointsBtn.className = 'remove-equipment-btn';
    controlsContainer.appendChild(clearHardpointsBtn);
    
    // Hardpoints table
    const hardpointTableContainer = document.createElement('div');
    hardpointTableContainer.className = 'hardpoint-table-container';
    editorContainer.appendChild(hardpointTableContainer);
    
    const hardpointTable = document.createElement('table');
    hardpointTable.className = 'hardpoint-table';
    hardpointTable.id = 'hardpoint-table';
    hardpointTableContainer.appendChild(hardpointTable);
    
    // Create table header
    const thead = document.createElement('thead');
    hardpointTable.appendChild(thead);
    
    const headerRow = document.createElement('tr');
    thead.appendChild(headerRow);
    
    ['ID', 'X Position', 'Y Position', 'Actions'].forEach(headerText => {
        const th = document.createElement('th');
        th.textContent = headerText;
        headerRow.appendChild(th);
    });
    
    // Create table body
    const tbody = document.createElement('tbody');
    tbody.id = 'hardpoint-tbody';
    hardpointTable.appendChild(tbody);
    
    // Initialize sprite and hardpoints if data exists
    initializeSpriteAndHardpoints();
    
    // Add event listeners
    uploadButton.addEventListener('click', () => {
        fileInput.click();
    });
    
    fileInput.addEventListener('change', handleSpriteUpload);
    
    // Setup drag and drop for the sprite container
    spriteContainer.addEventListener('dragover', (e) => {
        e.preventDefault();
        spriteContainer.style.borderColor = '#f5c2e7';
        spriteContainer.style.backgroundColor = 'rgba(245, 194, 231, 0.1)';
    });
    
    spriteContainer.addEventListener('dragleave', () => {
        spriteContainer.style.borderColor = '#45475a';
        spriteContainer.style.backgroundColor = 'transparent';
    });
    
    spriteContainer.addEventListener('drop', (e) => {
        e.preventDefault();
        spriteContainer.style.borderColor = '#45475a';
        spriteContainer.style.backgroundColor = 'transparent';
        
        if (e.dataTransfer.files.length > 0) {
            const file = e.dataTransfer.files[0];
            if (file.type.startsWith('image/')) {
                handleSpriteFile(file);
            }
        }
    });
    
    // Click on sprite to add hardpoint
    spriteContainer.addEventListener('click', (e) => {
        // Only handle clicks on the sprite, not on buttons or other controls
        if (e.target.tagName === 'IMG') {
            const rect = e.target.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            // Convert click position to sprite coordinates
            const spriteX = Math.round((x / spriteInfo.displayWidth) * spriteInfo.naturalWidth);
            const spriteY = Math.round((y / spriteInfo.displayHeight) * spriteInfo.naturalHeight);
            
            addHardpoint(spriteX, spriteY);
            updateJsonOutput();
        }
    });
    
    // Add hardpoint button
    addHardpointBtn.addEventListener('click', () => {
        // Generate next available ID
        let nextId = 1;
        if (currentShipData.hardpoints && currentShipData.hardpoints.length > 0) {
            nextId = Math.max(...currentShipData.hardpoints.map(h => h.id)) + 1;
        }
        
        addHardpoint(0, 0, nextId);
        updateJsonOutput();
    });
    
    // Clear all hardpoints button
    clearHardpointsBtn.addEventListener('click', () => {
        if (confirm('Are you sure you want to clear all hardpoints?')) {
            currentShipData.hardpoints = [];
            updateHardpointTable();
            removeAllHardpointMarkers();
            updateJsonOutput();
        }
    });
}

/**
 * Update sprite display with new sprite data
 * @param {string} spriteData - Sprite data URL
 */
function updateSpriteDisplay(spriteData) {
    const spriteContainer = document.getElementById('sprite-container');
    if (!spriteContainer) return;
    
    // Clear container
    spriteContainer.innerHTML = '';
    spriteContainer.classList.add('has-image');
    
    // Create image
    const img = document.createElement('img');
    img.src = spriteData;
    img.id = 'sprite-image';
    
    img.onload = function() {
        // Save sprite dimensions
        spriteInfo.element = img;
        spriteInfo.naturalWidth = img.naturalWidth;
        spriteInfo.naturalHeight = img.naturalHeight;
        spriteInfo.displayWidth = img.width;
        spriteInfo.displayHeight = img.height;
        
        // Add hardpoint markers
        renderHardpointMarkers();
    };
    
    spriteContainer.appendChild(img);
    
    // Add file input back
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.id = 'sprite-file-input';
    fileInput.accept = 'image/*';
    fileInput.style.display = 'none';
    fileInput.addEventListener('change', handleSpriteUpload);
    spriteContainer.appendChild(fileInput);
    
    // Add upload button
    const uploadButton = document.createElement('button');
    uploadButton.className = 'sprite-upload-btn';
    uploadButton.textContent = 'Change Sprite';
    uploadButton.addEventListener('click', () => {
        fileInput.click();
    });
    spriteContainer.appendChild(uploadButton);
}

/**
 * Reset sprite container to empty state
 * @param {HTMLElement} spriteContainer - Sprite container element
 */
function resetSpriteContainer(spriteContainer) {
    spriteContainer.innerHTML = '';
    spriteContainer.classList.remove('has-image');
    
    // Add placeholder
    const placeholderText = document.createElement('div');
    placeholderText.textContent = 'Drag & drop a sprite image or click to upload';
    placeholderText.id = 'sprite-placeholder';
    spriteContainer.appendChild(placeholderText);
    
    // Add upload button
    const uploadButton = document.createElement('button');
    uploadButton.className = 'sprite-upload-btn';
    uploadButton.textContent = 'Upload Sprite';
    uploadButton.id = 'sprite-upload-btn';
    
    uploadButton.addEventListener('click', () => {
        const fileInput = document.getElementById('sprite-file-input');
        if (fileInput) fileInput.click();
    });
    
    spriteContainer.appendChild(uploadButton);
    
    // Add file input
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.id = 'sprite-file-input';
    fileInput.accept = 'image/*';
    fileInput.style.display = 'none';
    fileInput.addEventListener('change', handleSpriteUpload);
    spriteContainer.appendChild(fileInput);
}

/**
 * Initialize sprite and hardpoints from saved data
 */
function initializeSpriteAndHardpoints() {
    // Check if we have sprite data
    if (currentShipData.sprite) {
        // Create image element
        const img = document.createElement('img');
        img.src = currentShipData.sprite;
        img.id = 'sprite-image';
        img.onload = function() {
            // Save sprite dimensions
            spriteInfo.element = img;
            spriteInfo.naturalWidth = img.naturalWidth;
            spriteInfo.naturalHeight = img.naturalHeight;
            spriteInfo.displayWidth = img.width;
            spriteInfo.displayHeight = img.height;
            
            // Add hardpoint markers
            renderHardpointMarkers();
        };
        
        // Add to container
        const spriteContainer = document.getElementById('sprite-container');
        if (spriteContainer) {
            // Clear placeholder
            spriteContainer.innerHTML = '';
            spriteContainer.appendChild(img);
            spriteContainer.classList.add('has-image');
            
            // Add file input back
            const fileInput = document.createElement('input');
            fileInput.type = 'file';
            fileInput.id = 'sprite-file-input';
            fileInput.accept = 'image/*';
            fileInput.style.display = 'none';
            fileInput.addEventListener('change', handleSpriteUpload);
            spriteContainer.appendChild(fileInput);
            
            // Add upload button
            const uploadButton = document.createElement('button');
            uploadButton.className = 'sprite-upload-btn';
            uploadButton.textContent = 'Change Sprite';
            uploadButton.addEventListener('click', () => {
                fileInput.click();
            });
            spriteContainer.appendChild(uploadButton);
        }
    }
    
    // Update hardpoint table
    updateHardpointTable();
}

/**
 * Handle sprite file upload
 * @param {Event} e - File input change event
 */
function handleSpriteUpload(e) {
    const file = e.target.files[0];
    if (file) {
        handleSpriteFile(file);
    }
}

/**
 * Process sprite file
 * @param {File} file - Sprite image file
 */
function handleSpriteFile(file) {
    const reader = new FileReader();
    reader.onload = (e) => {
        // Store sprite data
        currentShipData.sprite = e.target.result;
        
        // Add to sprite database
        let spriteName = file.name.replace(/\.[^/.]+$/, "");
        addSprite(spriteName, e.target.result);
        
        // Update sprite in UI
        updateSpriteDisplay(e.target.result);
        
        // Update sprite selector if it exists
        const spriteSelect = document.getElementById('sprite-select');
        if (spriteSelect) {
            // Check if we already have this sprite
            let optionExists = false;
            for (let i = 0; i < spriteSelect.options.length; i++) {
                if (spriteSelect.options[i].value === spriteName) {
                    spriteSelect.value = spriteName;
                    optionExists = true;
                    break;
                }
            }
            
            // Add new option if needed
            if (!optionExists) {
                const option = document.createElement('option');
                option.value = spriteName;
                option.textContent = spriteName;
                spriteSelect.appendChild(option);
                spriteSelect.value = spriteName;
            }
        }
        
        // Update JSON output
        updateJsonOutput();
    };
    reader.readAsDataURL(file);
}

/**
 * Add a new hardpoint
 * @param {number} x - X coordinate
 * @param {number} y - Y coordinate
 * @param {number|null} id - Optional hardpoint ID
 */
function addHardpoint(x, y, id = null) {
    if (!currentShipData.hardpoints) {
        currentShipData.hardpoints = [];
    }
    
    // Generate ID if not provided
    if (id === null) {
        id = currentShipData.hardpoints.length > 0 ? 
            Math.max(...currentShipData.hardpoints.map(h => h.id)) + 1 : 1;
    }
    
    // Add hardpoint to array
    currentShipData.hardpoints.push({ id, x, y });
    
    // Update UI
    updateHardpointTable();
    addHardpointMarker(id, x, y);
}

/**
 * Update hardpoint table UI
 */
function updateHardpointTable() {
    const tbody = document.getElementById('hardpoint-tbody');
    if (!tbody) return;
    
    // Clear table
    tbody.innerHTML = '';
    
    // Add rows for each hardpoint
    if (currentShipData.hardpoints && currentShipData.hardpoints.length > 0) {
        currentShipData.hardpoints.forEach((hardpoint, index) => {
            const row = document.createElement('tr');
            
            // ID cell
            const idCell = document.createElement('td');
            const idInput = document.createElement('input');
            idInput.type = 'number';
            idInput.min = 1;
            idInput.value = hardpoint.id || (index + 1);
            idInput.style.width = '60px';
            
            idInput.addEventListener('change', () => {
                const oldId = hardpoint.id;
                const newId = parseInt(idInput.value) || (index + 1);
                
                // Update ID in data
                hardpoint.id = newId;
                
                // Update marker attribute
                const marker = document.querySelector(`.hardpoint-marker[data-id="${oldId}"]`);
                if (marker) {
                    marker.dataset.id = newId;
                }
                
                updateJsonOutput();
            });
            
            idCell.appendChild(idInput);
            
            // X position cell
            const xCell = document.createElement('td');
            const xInput = document.createElement('input');
            xInput.type = 'number';
            xInput.value = hardpoint.x || 0;
            xInput.style.width = '80px';
            
            xInput.addEventListener('change', () => {
                const newX = parseInt(xInput.value) || 0;
                
                // Update position in data
                hardpoint.x = newX;
                
                // Update marker position
                updateHardpointMarkerPosition(hardpoint.id);
                
                updateJsonOutput();
            });
            
            xCell.appendChild(xInput);
            
            // Y position cell
            const yCell = document.createElement('td');
            const yInput = document.createElement('input');
            yInput.type = 'number';
            yInput.value = hardpoint.y || 0;
            yInput.style.width = '80px';
            
            yInput.addEventListener('change', () => {
                const newY = parseInt(yInput.value) || 0;
                
                // Update position in data
                hardpoint.y = newY;
                
                // Update marker position
                updateHardpointMarkerPosition(hardpoint.id);
                
                updateJsonOutput();
            });
            
            yCell.appendChild(yInput);
            
            // Actions cell
            const actionsCell = document.createElement('td');
            
            // Remove button
            const removeButton = document.createElement('button');
            removeButton.className = 'remove-equipment-btn';
            removeButton.textContent = 'Remove';
            
            removeButton.addEventListener('click', () => {
                // Remove from data
                currentShipData.hardpoints.splice(index, 1);
                
                // Remove marker
                const marker = document.querySelector(`.hardpoint-marker[data-id="${hardpoint.id}"]`);
                if (marker) {
                    marker.remove();
                }
                
                // Update table
                updateHardpointTable();
                updateJsonOutput();
            });
            
            actionsCell.appendChild(removeButton);
            
            // Add cells to row
            row.appendChild(idCell);
            row.appendChild(xCell);
            row.appendChild(yCell);
            row.appendChild(actionsCell);
            
            // Add row to table
            tbody.appendChild(row);
        });
    }
}

/**
 * Add a visual marker for a hardpoint on the sprite
 * @param {number} id - Hardpoint ID
 * @param {number} x - X coordinate
 * @param {number} y - Y coordinate
 */
function addHardpointMarker(id, x, y) {
    const spriteContainer = document.getElementById('sprite-container');
    const spriteImage = document.getElementById('sprite-image');
    if (!spriteContainer || !spriteInfo.element) return;
    
    // Create marker
    const marker = document.createElement('div');
    marker.className = 'hardpoint-marker';
    marker.dataset.id = id;
    
    // Position marker
    // Calculate the actual displayed size of the image
    const rect = spriteImage.getBoundingClientRect();
    const displayX = (x / spriteInfo.naturalWidth) * rect.width;
    const displayY = (y / spriteInfo.naturalHeight) * rect.height;
    
    // Calculate position with respect to the container and accounting for the image's position
    marker.style.left = `${spriteImage.offsetLeft + displayX}px`;
    marker.style.top = `${spriteImage.offsetTop + displayY}px`;
    
    // Label with ID
    marker.title = `Hardpoint ${id} (${x}, ${y})`;
    
    // Make draggable
    marker.draggable = true;
    
    // Add event listeners for dragging
    marker.addEventListener('dragstart', (e) => {
        // Store initial position for calculations
        e.dataTransfer.setData('text/plain', `${id},${marker.style.left},${marker.style.top}`);
        e.dataTransfer.effectAllowed = 'move';
        
        // Add some transparency during drag
        setTimeout(() => {
            marker.style.opacity = '0.5';
        }, 0);
    });
    
    marker.addEventListener('dragend', () => {
        marker.style.opacity = '1';
    });
    
    // Add to container
    spriteContainer.appendChild(marker);
    
    // Make container a drop target for markers
    if (!spriteContainer.hasAttribute('data-drop-initialized')) {
        spriteContainer.setAttribute('data-drop-initialized', 'true');
        
        spriteContainer.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
        });
        
        spriteContainer.addEventListener('drop', (e) => {
            e.preventDefault();
            
            // Get ID of dragged marker
            const data = e.dataTransfer.getData('text/plain').split(',');
            const markerId = parseInt(data[0]);
            
            // Calculate new position
            const rect = spriteInfo.element.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            // Convert to sprite coordinates
            const spriteX = Math.round((x / rect.width) * spriteInfo.naturalWidth);
            const spriteY = Math.round((y / rect.height) * spriteInfo.naturalHeight);
            
            // Update data
            const hardpoint = currentShipData.hardpoints.find(h => h.id === markerId);
            if (hardpoint) {
                hardpoint.x = spriteX;
                hardpoint.y = spriteY;
                
                // Update table
                updateHardpointTable();
                
                // Update marker position
                updateHardpointMarkerPosition(markerId);
                
                // Update JSON
                updateJsonOutput();
            }
        });
    }
}


/**
 * Update position of a hardpoint marker
 * @param {number} id - Hardpoint ID
 */
function updateHardpointMarkerPosition(id) {
    const marker = document.querySelector(`.hardpoint-marker[data-id="${id}"]`);
    const spriteImage = document.getElementById('sprite-image');
    if (!marker || !spriteImage) return;
    
    // Find hardpoint data
    const hardpoint = currentShipData.hardpoints.find(h => h.id === id);
    if (!hardpoint) return;
    
    // Get the actual displayed size of the image
    const rect = spriteImage.getBoundingClientRect();
    
    // Calculate display position
    const displayX = (hardpoint.x / spriteInfo.naturalWidth) * rect.width;
    const displayY = (hardpoint.y / spriteInfo.naturalHeight) * rect.height;
    
    // Update marker position
    marker.style.left = `${spriteImage.offsetLeft + displayX}px`;
    marker.style.top = `${spriteImage.offsetTop + displayY}px`;
    
    // Update tooltip
    marker.title = `Hardpoint ${id} (${hardpoint.x}, ${hardpoint.y})`;
}
/**
 * Render all hardpoint markers
 */
function renderHardpointMarkers() {
    // Remove existing markers
    removeAllHardpointMarkers();
    
    // Add markers for each hardpoint
    if (currentShipData.hardpoints && currentShipData.hardpoints.length > 0) {
        currentShipData.hardpoints.forEach(hardpoint => {
            addHardpointMarker(hardpoint.id, hardpoint.x, hardpoint.y);
        });
    }
}

/**
 * Remove all hardpoint markers
 */
function removeAllHardpointMarkers() {
    const markers = document.querySelectorAll('.hardpoint-marker');
    markers.forEach(marker => marker.remove());
}

/**
 * Get hardpoint data for saving
 * @returns {Array|null} - Array of hardpoints or null if none
 */
function getHardpointData() {
    if (currentShipData.hardpoints && currentShipData.hardpoints.length > 0) {
        return [...currentShipData.hardpoints];
    }
    return null;
}

/**
 * Get sprite data for saving
 * @returns {string|null} - Sprite data URI or null if none
 */
function getSpriteData() {
    return currentShipData.sprite || null;
}