/**
 * engine-point-editor.js
 * Manages the ship engine point editor functionality
 */

/**
 * Create engine point editor
 * @param {HTMLElement} container - Container element for engine point editor
 * @param {Function} onChange - Callback for when engine points change
 */
function createEnginePointEditor(container) {
    if (!container) return;
    
    container.innerHTML = '';
    
    const editorContainer = document.createElement('div');
    editorContainer.className = 'engine-point-editor';
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
                    updateSpriteDisplayForEngine(spriteData);
                    
                    // Update in hardpoint editor if it exists
                    const hardpointSpriteContainer = document.getElementById('sprite-container');
                    if (hardpointSpriteContainer) {
                        updateSpriteDisplay(spriteData);
                    }
                    
                    // Update the ship component in the database
                    const shipId = document.getElementById('itemId').value;
                    if (shipId) {
                        const shipData = getComponent('ship', shipId);
                        if (shipData) {
                            shipData.sprite = spriteData;
                            updateJsonOutput('ship', shipId);
                        }
                    }
                }
            } else {
                // Clear sprite if none selected
                currentShipData.sprite = null;
                
                // Update UI
                const engineSpriteContainer = document.getElementById('engine-sprite-container');
                if (engineSpriteContainer) {
                    resetSpriteContainerForEngine(engineSpriteContainer);
                }
                
                // Update the ship component in the database
                const shipId = document.getElementById('itemId').value;
                if (shipId) {
                    const shipData = getComponent('ship', shipId);
                    if (shipData) {
                        delete shipData.sprite;
                        updateJsonOutput('ship', shipId);
                    }
                }
            }
        });
    }
    
    // Create sprite upload section - or reuse existing sprite container from hardpoint editor
    let engineSpriteContainer = document.getElementById('engine-sprite-container');
    const hardpointSpriteContainer = document.getElementById('sprite-container');
    
    // Check if the hardpoint sprite container exists and already has an image
    if (hardpointSpriteContainer && hardpointSpriteContainer.querySelector('img')) {
        // Create a reference to the existing sprite container instead of a new one
        engineSpriteContainer = document.createElement('div');
        engineSpriteContainer.className = 'engine-sprite-reference';
        engineSpriteContainer.innerHTML = '<p>Using sprite from Hardpoints tab. Please add and edit engine points there.</p>';
        editorContainer.appendChild(engineSpriteContainer);
        
        // Use the same sprite image
        const spriteImage = hardpointSpriteContainer.querySelector('img');
        if (spriteImage) {
            // Create a clone of the sprite container for engine points
            const clonedContainer = hardpointSpriteContainer.cloneNode(true);
            clonedContainer.id = 'engine-sprite-container';
            
            // Replace the reference with the actual container
            engineSpriteContainer.replaceWith(clonedContainer);
            engineSpriteContainer = clonedContainer;
            
            // Make sure the sprite info is set correctly
            const clonedImage = engineSpriteContainer.querySelector('img');
            if (clonedImage) {
                clonedImage.onload = function() {
                    // Save sprite dimensions
                    spriteInfo.element = clonedImage;
                    spriteInfo.naturalWidth = clonedImage.naturalWidth;
                    spriteInfo.naturalHeight = clonedImage.naturalHeight;
                    spriteInfo.displayWidth = clonedImage.width;
                    spriteInfo.displayHeight = clonedImage.height;
                    
                    // Render engine point markers
                    renderEnginePointMarkers();
                };
                // Force the onload event
                if (clonedImage.complete) {
                    clonedImage.onload();
                }
            }
        }
    } else {
        // Create new sprite container if no existing one is available
        engineSpriteContainer = document.createElement('div');
        engineSpriteContainer.className = 'sprite-container';
        engineSpriteContainer.id = 'engine-sprite-container';
        editorContainer.appendChild(engineSpriteContainer);
        
        // Placeholder text when no sprite is uploaded
        const placeholderText = document.createElement('div');
        placeholderText.textContent = 'Drag & drop a sprite image or click to upload';
        placeholderText.id = 'engine-sprite-placeholder';
        engineSpriteContainer.appendChild(placeholderText);
        
        // Sprite upload button
        const uploadButton = document.createElement('button');
        uploadButton.className = 'sprite-upload-btn';
        uploadButton.textContent = 'Upload Sprite';
        uploadButton.id = 'engine-sprite-upload-btn';
        engineSpriteContainer.appendChild(uploadButton);
        
        // Hidden file input for sprite upload
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.id = 'engine-sprite-file-input';
        fileInput.accept = 'image/*';
        fileInput.style.display = 'none';
        engineSpriteContainer.appendChild(fileInput);
        
        // Add event listeners
        uploadButton.addEventListener('click', () => {
            fileInput.click();
        });
        
        fileInput.addEventListener('change', handleSpriteUploadForEngine);
        
        // Setup drag and drop for the sprite container
        engineSpriteContainer.addEventListener('dragover', (e) => {
            e.preventDefault();
            engineSpriteContainer.style.borderColor = '#f5c2e7';
            engineSpriteContainer.style.backgroundColor = 'rgba(245, 194, 231, 0.1)';
        });
        
        engineSpriteContainer.addEventListener('dragleave', () => {
            engineSpriteContainer.style.borderColor = '#45475a';
            engineSpriteContainer.style.backgroundColor = 'transparent';
        });
        
        engineSpriteContainer.addEventListener('drop', (e) => {
            e.preventDefault();
            engineSpriteContainer.style.borderColor = '#45475a';
            engineSpriteContainer.style.backgroundColor = 'transparent';
            
            if (e.dataTransfer.files.length > 0) {
                const file = e.dataTransfer.files[0];
                if (file.type.startsWith('image/')) {
                    handleSpriteFileForEngine(file);
                }
            }
        });
        
        // Initialize sprite if already available
        if (currentShipData.sprite) {
            updateSpriteDisplayForEngine(currentShipData.sprite);
        }
    }
    
    // Engine point controls
    const controlsContainer = document.createElement('div');
    controlsContainer.className = 'engine-point-controls';
    editorContainer.appendChild(controlsContainer);
    
    // Add engine point button
    const addEnginePointBtn = document.createElement('button');
    addEnginePointBtn.textContent = 'Add Engine Point';
    addEnginePointBtn.id = 'add-engine-point-btn';
    addEnginePointBtn.className = 'add-equipment-btn';
    controlsContainer.appendChild(addEnginePointBtn);
    
    // Clear all engine points button
    const clearEnginePointsBtn = document.createElement('button');
    clearEnginePointsBtn.textContent = 'Clear All Engine Points';
    clearEnginePointsBtn.id = 'clear-engine-points-btn';
    clearEnginePointsBtn.className = 'remove-equipment-btn';
    controlsContainer.appendChild(clearEnginePointsBtn);
    
    // Engine points table
    const enginePointTableContainer = document.createElement('div');
    enginePointTableContainer.className = 'engine-point-table-container';
    editorContainer.appendChild(enginePointTableContainer);
    
    const enginePointTable = document.createElement('table');
    enginePointTable.className = 'engine-point-table';
    enginePointTable.id = 'engine-point-table';
    enginePointTableContainer.appendChild(enginePointTable);
    
    // Create table header
    const thead = document.createElement('thead');
    enginePointTable.appendChild(thead);
    
    const headerRow = document.createElement('tr');
    thead.appendChild(headerRow);
    
    ['ID', 'X Position', 'Y Position', 'Particles', 'Actions'].forEach(headerText => {
        const th = document.createElement('th');
        th.textContent = headerText;
        headerRow.appendChild(th);
    });
    
    // Create table body
    const tbody = document.createElement('tbody');
    tbody.id = 'engine-point-tbody';
    enginePointTable.appendChild(tbody);
    
    // Initialize engine points if data exists
    initializeEnginePoints();
    
    // Click on sprite to add engine point - only add this listener if we created a new sprite container
    engineSpriteContainer.addEventListener('click', (e) => {
        // Only handle clicks on the sprite, not on buttons or other controls
        if (e.target.tagName === 'IMG') {
            const rect = e.target.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            // Convert click position to sprite coordinates
            const spriteX = Math.round((x / spriteInfo.displayWidth) * spriteInfo.naturalWidth);
            const spriteY = Math.round((y / spriteInfo.displayHeight) * spriteInfo.naturalHeight);
            
            // Add engine point
            addEnginePoint(spriteX, spriteY);
            
            // Update the ship component in the database
            const shipId = document.getElementById('itemId').value;
            if (shipId) {
                const shipData = getComponent('ship', shipId);
                if (shipData) {
                    // Make sure engine_points array exists
                    shipData.engine_points = shipData.engine_points || [];
                    // Update with current engine points
                    shipData.engine_points = [...currentShipData.engine_points];
                    // Update JSON display
                    updateJsonOutput('ship', shipId);
                }
            }
        }
    });
    
    // Add engine point button
    addEnginePointBtn.addEventListener('click', () => {
        // Generate next available ID
        let nextId = 1;
        if (currentShipData.engine_points && currentShipData.engine_points.length > 0) {
            nextId = Math.max(...currentShipData.engine_points.map(p => p.id)) + 1;
        }
        
        addEnginePoint(0, 0, nextId);
        updateJsonOutput();
    });
    
    // Clear all engine points button
    clearEnginePointsBtn.addEventListener('click', () => {
        if (confirm('Are you sure you want to clear all engine points?')) {
            currentShipData.engine_points = [];
            updateEnginePointTable();
            removeAllEnginePointMarkers();
            
            // Update the ship component in the database
            const shipId = document.getElementById('itemId').value;
            if (shipId) {
                const shipData = getComponent('ship', shipId);
                if (shipData) {
                    shipData.engine_points = [];
                    updateJsonOutput('ship', shipId);
                }
            }
        }
    });
}

function resetSpriteContainerForEngine(engineSpriteContainer) {
    engineSpriteContainer.innerHTML = '';
    engineSpriteContainer.classList.remove('has-image');
    
    // Add placeholder
    const placeholderText = document.createElement('div');
    placeholderText.textContent = 'Drag & drop a sprite image or click to upload';
    placeholderText.id = 'engine-sprite-placeholder';
    engineSpriteContainer.appendChild(placeholderText);
    
    // Add upload button
    const uploadButton = document.createElement('button');
    uploadButton.className = 'sprite-upload-btn';
    uploadButton.textContent = 'Upload Sprite';
    uploadButton.id = 'engine-sprite-upload-btn';
    
    uploadButton.addEventListener('click', () => {
        const fileInput = document.getElementById('engine-sprite-file-input');
        if (fileInput) fileInput.click();
    });
    
    engineSpriteContainer.appendChild(uploadButton);
    
    // Add file input
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.id = 'engine-sprite-file-input';
    fileInput.accept = 'image/*';
    fileInput.style.display = 'none';
    fileInput.addEventListener('change', handleSpriteUploadForEngine);
    engineSpriteContainer.appendChild(fileInput);
}

function handleSpriteUploadForEngine(e) {
    const file = e.target.files[0];
    if (file) {
        handleSpriteFileForEngine(file);
    }
}

function handleSpriteFileForEngine(file) {
    const reader = new FileReader();
    reader.onload = (e) => {
        // Store sprite data
        currentShipData.sprite = e.target.result;
        
        // Add to sprite database
        let spriteName = file.name.replace(/\.[^/.]+$/, "");
        addSprite(spriteName, e.target.result);
        
        // Update sprite in both editors
        updateSpriteDisplayForEngine(e.target.result);
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
        
        // Update the ship component in the database
        const shipId = document.getElementById('itemId').value;
        if (shipId) {
            const shipData = getComponent('ship', shipId);
            if (shipData) {
                shipData.sprite = e.target.result;
                updateJsonOutput('ship', shipId);
            }
        }
    };
    reader.readAsDataURL(file);
}

function updateSpriteDisplayForEngine(spriteData) {
    const engineSpriteContainer = document.getElementById('engine-sprite-container');
    if (!engineSpriteContainer) return;
    
    // Clear container
    engineSpriteContainer.innerHTML = '';
    engineSpriteContainer.classList.add('has-image');
    
    // Create image
    const img = document.createElement('img');
    img.src = spriteData;
    img.id = 'engine-sprite-image';
    
    img.onload = function() {
        // Save sprite dimensions
        spriteInfo.element = img;
        spriteInfo.naturalWidth = img.naturalWidth;
        spriteInfo.naturalHeight = img.naturalHeight;
        spriteInfo.displayWidth = img.width;
        spriteInfo.displayHeight = img.height;
        
        // Add engine point markers
        renderEnginePointMarkers();
    };
    
    engineSpriteContainer.appendChild(img);
    
    // Add file input back
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.id = 'engine-sprite-file-input';
    fileInput.accept = 'image/*';
    fileInput.style.display = 'none';
    fileInput.addEventListener('change', handleSpriteUploadForEngine);
    engineSpriteContainer.appendChild(fileInput);
    
    // Add upload button
    const uploadButton = document.createElement('button');
    uploadButton.className = 'sprite-upload-btn';
    uploadButton.textContent = 'Change Sprite';
    uploadButton.addEventListener('click', () => {
        fileInput.click();
    });
    engineSpriteContainer.appendChild(uploadButton);
}

/**
 * Initialize engine points from saved data
 */
function initializeEnginePoints() {
    // Add engine point markers
    renderEnginePointMarkers();
    
    // Update engine point table
    updateEnginePointTable();
}

/**
 * Add a new engine point
 * @param {number} x - X coordinate
 * @param {number} y - Y coordinate
 * @param {number|null} id - Optional engine point ID
 * @param {boolean} particles - Whether the engine point emits particles
 */
function addEnginePoint(x, y, id = null, particles = true) {
    if (!currentShipData.engine_points) {
        currentShipData.engine_points = [];
    }
    
    // Generate ID if not provided
    if (id === null) {
        id = currentShipData.engine_points.length > 0 ? 
            Math.max(...currentShipData.engine_points.map(p => p.id)) + 1 : 1;
    }
    
    // Add engine point to array
    currentShipData.engine_points.push({ 
        id, 
        position: { x, y },
        particles 
    });
    
    // Update UI
    updateEnginePointTable();
    addEnginePointMarker(id, x, y, particles);
}

/**
 * Update engine point table UI
 */
function updateEnginePointTable() {
    const tbody = document.getElementById('engine-point-tbody');
    if (!tbody) return;
    
    // Clear table
    tbody.innerHTML = '';
    
    // Add rows for each engine point
    if (currentShipData.engine_points && currentShipData.engine_points.length > 0) {
        currentShipData.engine_points.forEach((enginePoint, index) => {
            const row = document.createElement('tr');
            
            // ID cell
            const idCell = document.createElement('td');
            const idInput = document.createElement('input');
            idInput.type = 'number';
            idInput.min = 1;
            idInput.value = enginePoint.id || (index + 1);
            idInput.style.width = '60px';
            
            idInput.addEventListener('change', () => {
                const oldId = enginePoint.id;
                const newId = parseInt(idInput.value) || (index + 1);
                
                // Update ID in data
                enginePoint.id = newId;
                
                // Update marker attribute
                const marker = document.querySelector(`.engine-point-marker[data-id="${oldId}"]`);
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
            xInput.value = enginePoint.position?.x || 0;
            xInput.style.width = '80px';
            
            xInput.addEventListener('change', () => {
                const newX = parseInt(xInput.value) || 0;
                
                // Update position in data
                if (!enginePoint.position) enginePoint.position = { x: 0, y: 0 };
                enginePoint.position.x = newX;
                
                // Update marker position
                updateEnginePointMarkerPosition(enginePoint.id);
                
                updateJsonOutput();
            });
            
            xCell.appendChild(xInput);
            
            // Y position cell
            const yCell = document.createElement('td');
            const yInput = document.createElement('input');
            yInput.type = 'number';
            yInput.value = enginePoint.position?.y || 0;
            yInput.style.width = '80px';
            
            yInput.addEventListener('change', () => {
                const newY = parseInt(yInput.value) || 0;
                
                // Update position in data
                if (!enginePoint.position) enginePoint.position = { x: 0, y: 0 };
                enginePoint.position.y = newY;
                
                // Update marker position
                updateEnginePointMarkerPosition(enginePoint.id);
                
                updateJsonOutput();
            });
            
            yCell.appendChild(yInput);
            
            // Particles checkbox cell
            const particlesCell = document.createElement('td');
            const particlesCheckbox = document.createElement('input');
            particlesCheckbox.type = 'checkbox';
            particlesCheckbox.checked = enginePoint.particles !== false;
            
            particlesCheckbox.addEventListener('change', () => {
                // Update particles flag in data
                enginePoint.particles = particlesCheckbox.checked;
                
                // Update marker appearance
                const marker = document.querySelector(`.engine-point-marker[data-id="${enginePoint.id}"]`);
                if (marker) {
                    if (particlesCheckbox.checked) {
                        marker.classList.add('particles-enabled');
                    } else {
                        marker.classList.remove('particles-enabled');
                    }
                }
                
                updateJsonOutput();
            });
            
            particlesCell.appendChild(particlesCheckbox);
            
            // Actions cell
            const actionsCell = document.createElement('td');
            
            // Remove button
            const removeButton = document.createElement('button');
            removeButton.className = 'remove-equipment-btn';
            removeButton.textContent = 'Remove';
            
            removeButton.addEventListener('click', () => {
                // Remove from data
                currentShipData.engine_points.splice(index, 1);
                
                // Remove marker
                const marker = document.querySelector(`.engine-point-marker[data-id="${enginePoint.id}"]`);
                if (marker) {
                    marker.remove();
                }
                
                // Update table
                updateEnginePointTable();
                updateJsonOutput();
            });
            
            actionsCell.appendChild(removeButton);
            
            // Add cells to row
            row.appendChild(idCell);
            row.appendChild(xCell);
            row.appendChild(yCell);
            row.appendChild(particlesCell);
            row.appendChild(actionsCell);
            
            // Add row to table
            tbody.appendChild(row);
        });
    }
}

/**
 * Add a visual marker for an engine point on the sprite
 * @param {number} id - Engine point ID
 * @param {number} x - X coordinate
 * @param {number} y - Y coordinate
 * @param {boolean} particles - Whether the engine point emits particles
 */
function addEnginePointMarker(id, x, y, particles = true) {
    const spriteContainer = document.getElementById('sprite-container') || document.getElementById('engine-sprite-container');
    const spriteImage = document.getElementById('sprite-image');
    if (!spriteContainer || !spriteInfo.element) return;
    
    // Create marker
    const marker = document.createElement('div');
    marker.className = 'engine-point-marker';
    if (particles) {
        marker.classList.add('particles-enabled');
    }
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
    marker.title = `Engine Point ${id} (${x}, ${y})${particles ? ' - Particles Enabled' : ''}`;
    
    // Make draggable
    marker.draggable = true;
    
    // Add event listeners for dragging
    marker.addEventListener('dragstart', (e) => {
        // Store initial position for calculations
        e.dataTransfer.setData('text/plain', `engine,${id},${marker.style.left},${marker.style.top}`);
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
    if (!spriteContainer.hasAttribute('data-engine-drop-initialized')) {
        spriteContainer.setAttribute('data-engine-drop-initialized', 'true');
        
        // Extend existing drop handler if it exists
        const existingDropHandler = spriteContainer.ondrop;
        
        spriteContainer.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
        });
        
        spriteContainer.addEventListener('drop', (e) => {
            e.preventDefault();
            
            // Get data of dragged marker
            const data = e.dataTransfer.getData('text/plain').split(',');
            const type = data[0];
            
            // Only handle engine points in this handler
            if (type === 'engine') {
                const markerId = parseInt(data[1]);
                
                // Calculate new position
                const rect = spriteInfo.element.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                
                // Convert to sprite coordinates
                const spriteX = Math.round((x / rect.width) * spriteInfo.naturalWidth);
                const spriteY = Math.round((y / rect.height) * spriteInfo.naturalHeight);
                
                // Update data
                const enginePoint = currentShipData.engine_points.find(p => p.id === markerId);
                if (enginePoint) {
                    if (!enginePoint.position) enginePoint.position = { x: 0, y: 0 };
                    enginePoint.position.x = spriteX;
                    enginePoint.position.y = spriteY;
                    
                    // Update table
                    updateEnginePointTable();
                    
                    // Update marker position
                    updateEnginePointMarkerPosition(markerId);
                    
                    // Update JSON
                    updateJsonOutput();
                }
            } else if (existingDropHandler) {
                // Call existing handler for other types
                existingDropHandler(e);
            }
        });
    }
}

/**
 * Update position of an engine point marker
 * @param {number} id - Engine point ID
 */
function updateEnginePointMarkerPosition(id) {
    const marker = document.querySelector(`.engine-point-marker[data-id="${id}"]`);
    const spriteImage = document.getElementById('sprite-image');
    if (!marker || !spriteImage) return;
    
    // Find engine point data
    const enginePoint = currentShipData.engine_points.find(p => p.id === id);
    if (!enginePoint || !enginePoint.position) return;
    
    // Get the actual displayed size of the image
    const rect = spriteImage.getBoundingClientRect();
    
    // Calculate display position
    const displayX = (enginePoint.position.x / spriteInfo.naturalWidth) * rect.width;
    const displayY = (enginePoint.position.y / spriteInfo.naturalHeight) * rect.height;
    
    // Update marker position
    marker.style.left = `${spriteImage.offsetLeft + displayX}px`;
    marker.style.top = `${spriteImage.offsetTop + displayY}px`;
    
    // Update tooltip
    marker.title = `Engine Point ${id} (${enginePoint.position.x}, ${enginePoint.position.y})${enginePoint.particles ? ' - Particles Enabled' : ''}`;
}

/**
 * Render all engine point markers
 */
function renderEnginePointMarkers() {
    // Remove existing markers
    removeAllEnginePointMarkers();
    
    // Add markers for each engine point
    if (currentShipData.engine_points && currentShipData.engine_points.length > 0) {
        currentShipData.engine_points.forEach(enginePoint => {
            addEnginePointMarker(
                enginePoint.id, 
                enginePoint.position?.x || 0, 
                enginePoint.position?.y || 0,
                enginePoint.particles !== false
            );
        });
    }
}

/**
 * Remove all engine point markers
 */
function removeAllEnginePointMarkers() {
    const markers = document.querySelectorAll('.engine-point-marker');
    markers.forEach(marker => marker.remove());
}

/**
 * Get engine point data for saving
 * @returns {Array|null} - Array of engine points or null if none
 */
function getEnginePointData() {
    if (currentShipData.engine_points && currentShipData.engine_points.length > 0) {
        return [...currentShipData.engine_points];
    }
    return null;
}