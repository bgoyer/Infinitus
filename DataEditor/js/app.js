/**
 * app.js
 * Main application entry point and initialization
 */

// Initialize the editor
document.addEventListener('DOMContentLoaded', () => {
    // Get DOM elements
    const componentTypeSelect = document.getElementById('componentType');
    const itemIdInput = document.getElementById('itemId');
    const specificTabContent = document.getElementById('specificTab');
    const advancedTabContent = document.getElementById('advancedTab');
    const hardpointsTabContent = document.getElementById('hardpointsTab');
    
    const saveButton = document.getElementById('saveButton');
    const newButton = document.getElementById('newButton');
    const deleteButton = document.getElementById('deleteButton');
    const copyButton = document.getElementById('copyButton');
    
    // Set up tabs
    setupTabs();
    
    // Create initial loading interface
    const initialLoadContainer = createInitialLoadInterface((files) => {
        showLoadingScreen(files.length);
        
        loadComponentFiles(
            files,
            // onComplete
            () => {
                hideLoadingShowEditor();
                updateItemList(componentTypeSelect.value, (id) => loadComponentData(id));
                updateJsonOutput(componentTypeSelect.value);
                updateTypeSpecificFields();
                setupSaveDropdown(
                    // Save specific type
                    (type) => {
                        if (getComponentIdsForType(type).length > 0) {
                            saveComponentTypeToFile(type);
                            alert(`${type}.json saved!`);
                        } else {
                            alert(`No components found for type: ${type}`);
                        }
                    },
                    // Save all types
                    () => {
                        Object.keys(getComponentTypes()).forEach(type => {
                            if (getComponentIdsForType(type).length > 0) {
                                saveComponentTypeToFile(type);
                            }
                        });
                        
                        alert('All component types saved to separate files!');
                    }
                );
            },
            // onProgress
            (filesProcessed, totalFiles, errorMessage) => {
                updateLoadingProgress(filesProcessed, totalFiles, errorMessage);
            }
        );
    });
    
    // Initialize sprite functionality
    initializeSpriteFunctionality();
    
    // Handle component type change
    componentTypeSelect.addEventListener('change', () => {
        const newType = componentTypeSelect.value;
        setCurrentSelection(newType, '');
        updateTypeSpecificFields();
        updateItemList(newType, (id) => loadComponentData(id));
        
        // Add sprite selector to form if we have sprites and this is a ship
        if (newType === 'ship') {
            setTimeout(() => {
                const currentId = document.getElementById('itemId').value;
                addSpriteFieldToShipForm(currentId);
            }, 100);
        }
    });
    
    // Save component button
    saveButton.addEventListener('click', () => {
        const id = itemIdInput.value.trim();
        
        if (!id) {
            alert('Please enter a component ID');
            return;
        }
        
        // Get current type
        const type = getCurrentSelection().type || componentTypeSelect.value;
        
        // Collect basic form data
        const data = collectFormData(type, id);
        
        // Handle special data for ships
        if (type === 'ship') {
            // Add sprite if available
            const spriteData = getSpriteData();
            if (spriteData) {
                data.sprite = spriteData;
            }
            
            // Add hardpoints if available
            const hardpoints = getHardpointData();
            if (hardpoints) {
                data.hardpoints = hardpoints;
            }
            
            // Add equipment
            const equipment = getEquipmentData();
            if (equipment) {
                data.equipment = equipment;
            }
        }
        
        // Save to database
        saveComponent(type, id, data);
        setCurrentSelection(type, id);
        
        // Update UI
        updateItemList(type, (id) => loadComponentData(id));
        updateJsonOutput(type, id);
        
        alert(`Component ${id} saved!`);
    });
    
    // New component button
    newButton.addEventListener('click', () => {
        const type = getCurrentSelection().type || componentTypeSelect.value;
        
        clearForm();
        setCurrentSelection(type, '');
        itemIdInput.value = '';
        
        // Reset equipment for ships
        if (type === 'ship') {
            resetEquipment();
            resetShipData();
            rebuildEquipmentSelectors();
            recreateHardpointEditor();
        }
        
        updateJsonOutput(type);
    });
    
    // Delete component button
    deleteButton.addEventListener('click', () => {
        const { type, id } = getCurrentSelection();
        
        if (id && getComponent(type, id)) {
            if (confirm(`Are you sure you want to delete ${id}?`)) {
                deleteComponent(type, id);
                updateItemList(type, (id) => loadComponentData(id));
                clearForm();
                updateJsonOutput(type);
            }
        } else {
            alert('No component selected to delete.');
        }
    });
    
    // Copy JSON button
    copyButton.addEventListener('click', () => {
        const jsonOutput = document.getElementById('jsonOutput');
        if (!jsonOutput) return;
        
        const jsonText = jsonOutput.textContent;
        navigator.clipboard.writeText(jsonText)
            .then(() => {
                alert('JSON copied to clipboard!');
            })
            .catch(err => {
                console.error('Failed to copy: ', err);
                alert('Failed to copy JSON. See console for details.');
            });
    });
    
    // Function to update type-specific fields
    function updateTypeSpecificFields() {
        const type = getCurrentSelection().type || componentTypeSelect.value;
        
        // Create type-specific fields
        createTypeSpecificFields(type, specificTabContent, advancedTabContent);
        
        // Handle special fields for ships
        if (type === 'ship') {
            // Create equipment selector
            const equipmentSelector = createEquipmentSelector(() => {
                updateJsonOutput(type, getCurrentSelection().id);
            });
            advancedTabContent.appendChild(equipmentSelector);
            
            // Create hardpoint editor
            recreateHardpointEditor();
        }
        
        // Toggle hardpoints tab visibility
        toggleHardpointsTab(type);
        
        // Update JSON output
        updateJsonOutput(type);
    }
    
    // Function to recreate hardpoint editor
    function recreateHardpointEditor() {
        // Clear and recreate hardpoint editor
        const type = getCurrentSelection().type || componentTypeSelect.value;
        if (type === 'ship') {
            createHardpointEditor(hardpointsTabContent);
        }
    }
    
    // Function to load component data into form
    function loadComponentData(id) {
        const type = getCurrentSelection().type || componentTypeSelect.value;
        const data = getComponent(type, id);
        
        if (!data) return;
        
        // Set current selection
        setCurrentSelection(type, id);
        
        // Clear form first
        clearForm();
        
        // Set basic fields
        itemIdInput.value = id;
        document.getElementById('name').value = data.name || '';
        document.getElementById('description').value = data.description || '';
        document.getElementById('mass').value = data.mass || 0;
        document.getElementById('value').value = data.value || 0;
        document.getElementById('volume').value = data.volume || 0;
        
        // Set specific fields
        Object.keys(data).forEach(key => {
            const input = document.getElementById(key);
            if (input) {
                if (input.type === 'checkbox') {
                    input.checked = data[key] || false;
                } else {
                    input.value = data[key] !== undefined ? data[key] : '';
                }
            }
        });
        
        // Special handling for ship data
        if (type === 'ship') {
            // Reset ship data
            resetShipData();
            
            // Load sprite if available
            if (data.sprite) {
                setShipData({
                    sprite: data.sprite,
                    hardpoints: data.hardpoints || []
                });
            }
            
            // Reset equipment data
            resetEquipment();
            
            // Load equipment from data
            if (data.equipment) {
                setEquipment(data.equipment);
            }
            
            // Rebuild equipment selectors with the latest data
            rebuildEquipmentSelectors();
            
            // Rebuild hardpoint editor
            recreateHardpointEditor();
            
            // Add sprite selector
            setTimeout(() => {
                addSpriteFieldToShipForm(id);
            }, 100);
        }
        
        // Special handling for weapon subtypes
        if (type === 'weapon') {
            // Handle weapon type-specific fields
            const weaponType = data.type;
            const typeSelect = document.getElementById('type');
            if (typeSelect) {
                typeSelect.value = weaponType || 'gun';
                typeSelect.dispatchEvent(new Event('change'));
                
                // Set type-specific fields
                if (weaponType === 'gun' && data.spread_angle !== undefined) {
                    const spreadAngle = document.getElementById('gun_spread_angle');
                    if (spreadAngle) spreadAngle.value = data.spread_angle;
                } else if (weaponType === 'turret') {
                    if (data.rotation_speed !== undefined) {
                        const rotationSpeed = document.getElementById('turret_rotation_speed');
                        if (rotationSpeed) rotationSpeed.value = data.rotation_speed;
                    }
                    if (data.aim_ahead_factor !== undefined) {
                        const aimAhead = document.getElementById('turret_aim_ahead_factor');
                        if (aimAhead) aimAhead.value = data.aim_ahead_factor;
                    }
                    if (data.fire_arc !== undefined) {
                        const fireArc = document.getElementById('turret_fire_arc');
                        if (fireArc) fireArc.value = data.fire_arc;
                    }
                    if (data.base_inaccuracy !== undefined) {
                        const baseInaccuracy = document.getElementById('turret_base_inaccuracy');
                        if (baseInaccuracy) baseInaccuracy.value = data.base_inaccuracy;
                    }
                } else if (weaponType === 'missile_launcher') {
                    if (data.missile_tracking_time !== undefined) {
                        const trackingTime = document.getElementById('missile_tracking_time');
                        if (trackingTime) trackingTime.value = data.missile_tracking_time;
                    }
                    if (data.missile_turning_speed !== undefined) {
                        const turningSpeed = document.getElementById('missile_turning_speed');
                        if (turningSpeed) turningSpeed.value = data.missile_turning_speed;
                    }
                    if (data.missile_acceleration !== undefined) {
                        const acceleration = document.getElementById('missile_acceleration');
                        if (acceleration) acceleration.value = data.missile_acceleration;
                    }
                    if (data.missile_max_speed !== undefined) {
                        const maxSpeed = document.getElementById('missile_max_speed');
                        if (maxSpeed) maxSpeed.value = data.missile_max_speed;
                    }
                    if (data.missile_blast_radius !== undefined) {
                        const blastRadius = document.getElementById('missile_blast_radius');
                        if (blastRadius) blastRadius.value = data.missile_blast_radius;
                    }
                    if (data.salvo_size !== undefined) {
                        const salvoSize = document.getElementById('missile_salvo_size');
                        if (salvoSize) salvoSize.value = data.salvo_size;
                    }
                }
            }
        }
        
        // Trigger change events to update conditional fields
        const typeSelect = document.getElementById('type');
        if (typeSelect) {
            typeSelect.dispatchEvent(new Event('change'));
        }
        
        // Update JSON output
        updateJsonOutput(type, id);
    }
    
    // Function to clear form fields
    function clearForm() {
        const type = getCurrentSelection().type || componentTypeSelect.value;
        clearFormFields(type);
    }
    
    // Initialize with default type
    updateTypeSpecificFields();
});

/**
 * Add sprite loading functionality to the app
 */
function initializeSpriteFunctionality() {
    // Create button for loading sprites
    const loadSpritesBtn = document.createElement('button');
    loadSpritesBtn.id = 'loadSpritesBtn';
    loadSpritesBtn.textContent = 'Load Ship Sprites';
    loadSpritesBtn.style.marginLeft = '10px';
    
    // Add event listener
    loadSpritesBtn.addEventListener('click', () => {
        handleSpriteFolderSelection((files) => {
            showProgressLoadingScreen(files.length, 'sprites');
            
            loadSpriteFiles(
                files,
                // Progress callback
                (processed, total) => {
                    updateProgressBar(processed, total);
                },
                // Complete callback
                (loadedSprites) => {
                    hideProgressLoadingScreen();
                    
                    // Show success message
                    const message = `Successfully loaded ${loadedSprites.length} sprites`;
                    alert(message);
                    
                    // If on ship type, refresh the hardpoint editor
                    const componentType = document.getElementById('componentType');
                    if (componentType && componentType.value === 'ship') {
                        recreateHardpointEditor();
                    }
                }
            );
        });
    });
    
    // Add to header
    const addSpritesButtonToHeader = () => {
        const headerContainer = document.querySelector('.header > div');
        if (headerContainer && !document.getElementById('loadSpritesBtn')) {
            headerContainer.appendChild(loadSpritesBtn);
        }
    };
    
    // Add to header if editor is already visible
    if (document.querySelector('.editor-container').style.display !== 'none') {
        addSpritesButtonToHeader();
    }
    
    // Add to initial loading screen if present
    const initialLoadContainer = document.getElementById('initialLoadContainer');
    if (initialLoadContainer && !document.getElementById('initialLoadSpritesBtn')) {
        const initialLoadSpritesBtn = document.createElement('button');
        initialLoadSpritesBtn.id = 'initialLoadSpritesBtn';
        initialLoadSpritesBtn.textContent = 'Load Ship Sprites First (Optional)';
        initialLoadSpritesBtn.style.padding = '10px';
        initialLoadSpritesBtn.style.marginTop = '10px';
        initialLoadSpritesBtn.style.backgroundColor = '#94e2d5';
        initialLoadSpritesBtn.style.color = '#1e1e2e';
        
        initialLoadSpritesBtn.addEventListener('click', () => {
            handleSpriteFolderSelection((files) => {
                showProgressLoadingScreen(files.length, 'sprites');
                
                loadSpriteFiles(
                    files,
                    // Progress callback
                    (processed, total) => {
                        updateProgressBar(processed, total);
                    },
                    // Complete callback
                    (loadedSprites) => {
                        hideProgressLoadingScreen();
                        
                        // Update message
                        const initialLoadMessage = document.getElementById('initialLoadMessage');
                        if (initialLoadMessage) {
                            initialLoadMessage.innerHTML = '<h2>Sprites Loaded Successfully!</h2>' + 
                                `<p>Loaded ${loadedSprites.length} sprite files.</p>` +
                                '<p>Now please load your component files to get started.</p>' +
                                '<p>You can select multiple JSON files at once.</p>' +
                                '<p><strong>Expected files:</strong> ' + defaultComponentFiles.join(', ') + '</p>';
                        }
                    }
                );
            });
        });
        
        const initialLoadButton = document.getElementById('initialLoadButton');
        if (initialLoadButton) {
            initialLoadContainer.insertBefore(initialLoadSpritesBtn, initialLoadButton);
        } else {
            initialLoadContainer.appendChild(initialLoadSpritesBtn);
        }
    }
}

/**
 * Add sprite selector to a ship component form
 * @param {string} shipId - Current ship ID
 */
function addSpriteFieldToShipForm(shipId) {
    // Only proceed if we have sprites and we're on a ship component
    if (getSpriteNames().length === 0 || document.getElementById('sprite-select')) {
        return;
    }
    
    // Find a good place to add the sprite selector
    const specificTabContent = document.getElementById('specificTab');
    if (!specificTabContent) return;
    
    // Create the sprite selector field
    const formGroup = document.createElement('div');
    formGroup.className = 'form-group';
    
    const label = document.createElement('label');
    label.textContent = 'Ship Sprite:';
    formGroup.appendChild(label);
    
    // Create sprite selector
    const shipData = getComponent('ship', shipId);
    let currentSpriteName = '';
    
    // Try to find matching sprite for this ship
    if (shipData && shipData.sprite) {
        const spriteNames = getSpriteNames();
        for (const name of spriteNames) {
            if (getSprite(name) === shipData.sprite) {
                currentSpriteName = name;
                break;
            }
        }
    }
    
    // Create sprite select element
    const spriteSelectorContainer = document.createElement('div');
    createSpriteSelector(spriteSelectorContainer, currentSpriteName, (spriteName) => {
        if (spriteName) {
            const spriteData = getSprite(spriteName);
            if (spriteData) {
                // Update form data
                const shipId = document.getElementById('itemId').value;
                const shipData = getComponent('ship', shipId);
                
                if (shipData) {
                    shipData.sprite = spriteData;
                }
                
                // Update hardpoint editor if visible
                if (document.getElementById('sprite-container')) {
                    updateSpriteDisplay(spriteData);
                }
                
                // Update JSON output
                updateJsonOutput('ship', shipId);
            }
        }
    });
    
    formGroup.appendChild(spriteSelectorContainer);
    
    // Add to the form at the top
    specificTabContent.insertBefore(formGroup, specificTabContent.firstChild);
}

// Helper function to get component types
function getComponentTypes() {
    return {
        ship: 'Ships',
        capacitor: 'Capacitors',
        generator: 'Generators',
        shield: 'Shields',
        armor: 'Armor',
        thruster: 'Thrusters',
        turning: 'Turning Systems',
        weapon: 'Weapons'
    };
}

/**
 * Handle sprite folder selection with browser compatibility
 * @param {Function} onFilesSelected - Callback when files are selected
 */
function handleSpriteFolderSelection(onFilesSelected) {
    // Check if directory selection is supported
    const input = document.createElement('input');
    input.type = 'file';
    
    // Modern approach with directory selection
    if ('webkitdirectory' in input || 'directory' in input) {
        input.accept = 'image/*';
        input.multiple = true;
        input.webkitdirectory = true;
        input.directory = true;
        
        input.onchange = e => {
            if (e.target.files && e.target.files.length > 0) {
                onFilesSelected(e.target.files);
            }
        };
        
        input.click();
    } 
    // Fallback to multiple file selection with a message
    else {
        // Show message about directory selection not being supported
        const message = 'Directory selection is not supported in your browser. ' +
                      'Please select multiple sprite image files instead.';
        alert(message);
        
        input.accept = 'image/*';
        input.multiple = true;
        
        input.onchange = e => {
            if (e.target.files && e.target.files.length > 0) {
                onFilesSelected(e.target.files);
            }
        };
        
        input.click();
    }
}

/**
 * Show better loading UI with progress bar
 * @param {number} total - Total items to process
 * @param {string} type - Type of items being processed
 */
function showProgressLoadingScreen(total, type = 'files') {
    // Create or get loading container
    let loadingContainer = document.getElementById('loading-progress-container');
    
    if (!loadingContainer) {
        loadingContainer = document.createElement('div');
        loadingContainer.id = 'loading-progress-container';
        loadingContainer.className = 'loading-container';
        
        // Add to page
        document.querySelector('.container').appendChild(loadingContainer);
    }
    
    // Set content
    loadingContainer.innerHTML = `
        <h3>Loading ${type}</h3>
        <p id="loading-progress-text">0/${total} ${type} processed</p>
        <div class="loading-bar">
            <div id="loading-progress-bar" class="loading-bar-progress"></div>
        </div>
        <p id="loading-status"></p>
    `;
    
    // Show the container
    loadingContainer.style.display = 'block';
}

/**
 * Update the progress bar
 * @param {number} current - Current progress
 * @param {number} total - Total items
 * @param {string} message - Optional status message
 */
function updateProgressBar(current, total, message = null) {
    const progressText = document.getElementById('loading-progress-text');
    const progressBar = document.getElementById('loading-progress-bar');
    const statusElement = document.getElementById('loading-status');
    
    if (progressText && progressBar) {
        // Update text
        progressText.textContent = `${current}/${total} processed`;
        
        // Update progress bar
        const percentage = (current / total) * 100;
        progressBar.style.width = `${percentage}%`;
        
        // Update status message if provided
        if (statusElement && message) {
            statusElement.textContent = message;
        }
    }
}

/**
 * Hide loading screen
 */
function hideProgressLoadingScreen() {
    const loadingContainer = document.getElementById('loading-progress-container');
    if (loadingContainer) {
        // Fade out and remove
        loadingContainer.style.opacity = '0';
        loadingContainer.style.transition = 'opacity 0.5s ease';
        
        setTimeout(() => {
            loadingContainer.remove();
        }, 500);
    }
}