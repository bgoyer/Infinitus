/**
 * ui-manager.js
 * Handles UI updates, item lists, and JSON display
 */

// Current state
let currentType = '';
let currentId = '';

/**
 * Update component list for the current type
 * @param {string} type - Component type
 * @param {Function} onItemClick - Callback for item click
 */
function updateItemList(type, onItemClick) {
    currentType = type;
    const itemList = document.getElementById('itemList');
    if (!itemList) return;
    
    itemList.innerHTML = '';
    
    const items = getComponentIdsForType(type);
    
    items.forEach(id => {
        const component = getComponent(type, id);
        const item = document.createElement('div');
        item.textContent = component?.name || id;
        item.dataset.id = id;
        
        item.addEventListener('click', () => {
            // Update current selection
            currentId = id;
            
            // Highlight selected item
            const selectedItems = itemList.querySelectorAll('.selected');
            selectedItems.forEach(el => el.classList.remove('selected'));
            item.classList.add('selected');
            
            // Trigger callback
            if (onItemClick) {
                onItemClick(id);
            }
        });
        
        itemList.appendChild(item);
    });
}

/**
 * Update JSON output display
 * @param {string} type - Component type
 * @param {string} id - Component ID or null for all
 * @param {Object} customData - Custom data to display instead of database component
 */
function updateJsonOutput(type, id, customData = null) {
    const jsonOutput = document.getElementById('jsonOutput');
    if (!jsonOutput) return;
    
    let json;
    
    if (customData) {
        // Use custom data if provided
        json = JSON.stringify(customData, null, 2);
    } else if (id) {
        // Show selected component
        const component = getComponent(type, id);
        if (component) {
            const componentObj = {};
            componentObj[id] = component;
            json = JSON.stringify(componentObj, null, 2);
        } else {
            json = '{}';
        }
    } else {
        // Show all components of current type
        const components = getComponentIdsForType(type).reduce((acc, id) => {
            acc[id] = getComponent(type, id);
            return acc;
        }, {});
        
        json = JSON.stringify(components, null, 2);
    }
    
    jsonOutput.textContent = json;
}

/**
 * Set up tab switching
 */
function setupTabs() {
    const tabButtons = document.querySelectorAll('.tab-button');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const tabId = button.dataset.tab;
            
            // Deactivate all tabs
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));
            
            // Activate selected tab
            button.classList.add('active');
            document.getElementById(tabId).classList.add('active');
        });
    });
}

/**
 * Create initial loading interface
 * @param {Function} onLoadFiles - Callback for loading files
 */
function createInitialLoadInterface(onLoadFiles) {
    // Create a new element for initial component loading
    const initialLoadButton = document.createElement('button');
    initialLoadButton.id = 'initialLoadButton';
    initialLoadButton.textContent = 'Load Component Files';
    initialLoadButton.style.padding = '15px 20px';
    initialLoadButton.style.fontSize = '16px';
    initialLoadButton.style.margin = '20px auto';
    initialLoadButton.style.display = 'block';
    initialLoadButton.style.backgroundColor = '#f5c2e7';
    initialLoadButton.style.color = '#1e1e2e';
    
    // Create initial load message
    const initialLoadMessage = document.createElement('div');
    initialLoadMessage.id = 'initialLoadMessage';
    initialLoadMessage.innerHTML = '<h2>Welcome to Spaceship Component Editor</h2>' +
        '<p>Please load your component files to get started.</p>' +
        '<p>You can select multiple JSON files at once.</p>' +
        '<p><strong>Expected files:</strong> ' + defaultComponentFiles.join(', ') + '</p>';
    initialLoadMessage.style.textAlign = 'center';
    initialLoadMessage.style.padding = '40px 20px';
    
    // Container for initial load
    const initialLoadContainer = document.createElement('div');
    initialLoadContainer.id = 'initialLoadContainer';
    initialLoadContainer.appendChild(initialLoadMessage);
    initialLoadContainer.appendChild(initialLoadButton);
    initialLoadContainer.style.backgroundColor = '#313244';
    initialLoadContainer.style.borderRadius = '8px';
    initialLoadContainer.style.margin = '40px auto';
    initialLoadContainer.style.maxWidth = '600px';
    
    // Add to document
    document.querySelector('.container').appendChild(initialLoadContainer);
    
    // Hide editor until files are loaded
    const editorContainer = document.querySelector('.editor-container');
    editorContainer.style.display = 'none';
    
    // Initial load button handler
    initialLoadButton.addEventListener('click', () => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';
        input.multiple = true;
        
        input.onchange = e => {
            if (onLoadFiles) {
                onLoadFiles(e.target.files);
            }
        };
        
        input.click();
    });
    
    return initialLoadContainer;
}

/**
 * Update loading progress display
 * @param {number} filesProcessed - Number of files processed
 * @param {number} totalFiles - Total number of files
 * @param {string|null} errorMessage - Optional error message
 */
function updateLoadingProgress(filesProcessed, totalFiles, errorMessage = null) {
    const loadingProgress = document.getElementById('loadingProgress');
    if (loadingProgress) {
        if (errorMessage) {
            loadingProgress.textContent = 
                `${filesProcessed}/${totalFiles} files processed (${errorMessage})`;
        } else {
            loadingProgress.textContent = 
                `${filesProcessed}/${totalFiles} files processed`;
        }
    }
}

/**
 * Show loading screen
 * @param {number} totalFiles - Total number of files to process
 */
function showLoadingScreen(totalFiles) {
    const initialLoadMessage = document.getElementById('initialLoadMessage');
    const initialLoadButton = document.getElementById('initialLoadButton');
    
    if (initialLoadMessage) {
        initialLoadMessage.innerHTML = '<h2>Loading Component Files</h2>' + 
            '<p>Please wait while your files are processed...</p>' +
            '<div id="loadingProgress">0/' + totalFiles + ' files processed</div>';
    }
    
    if (initialLoadButton) {
        initialLoadButton.style.display = 'none';
    }
}

/**
 * Hide loading screen and show editor
 */
function hideLoadingShowEditor() {
    const initialLoadContainer = document.getElementById('initialLoadContainer');
    const editorContainer = document.querySelector('.editor-container');
    
    if (initialLoadContainer) {
        initialLoadContainer.style.display = 'none';
    }
    
    if (editorContainer) {
        editorContainer.style.display = 'flex';
    }
}

/**
 * Set up dropdown for saving components
 * @param {Function} onSaveType - Callback for saving specific component type
 * @param {Function} onSaveAll - Callback for saving all component types
 */
function setupSaveDropdown(onSaveType, onSaveAll) {
    const headerSaveContainer = document.querySelector('.header > div');
    if (!headerSaveContainer) return;
    
    // Remove any existing dropdown
    const existingDropdown = document.getElementById('saveTypeSelector');
    if (existingDropdown) {
        existingDropdown.remove();
    }
    
    // Remove existing save button
    const existingSaveButton = document.getElementById('newSaveButton');
    if (existingSaveButton) {
        existingSaveButton.remove();
    }
    
    // Create dropdown for save options
    const saveDropdown = document.createElement('select');
    saveDropdown.id = 'saveTypeSelector';
    saveDropdown.style.padding = '10px';
    saveDropdown.style.marginRight = '10px';
    saveDropdown.style.backgroundColor = '#45475a';
    saveDropdown.style.color = '#cdd6f4';
    saveDropdown.style.border = 'none';
    saveDropdown.style.borderRadius = '4px';
    
    // Add option for saving all types
    const allOption = document.createElement('option');
    allOption.value = 'all';
    allOption.textContent = 'All Types';
    saveDropdown.appendChild(allOption);
    
    // Add options for each component type
    Object.keys(getComponentTypes()).forEach(type => {
        const option = document.createElement('option');
        option.value = type;
        option.textContent = type.charAt(0).toUpperCase() + type.slice(1) + 's';
        saveDropdown.appendChild(option);
    });
    
    // Create new save button
    const newSaveButton = document.createElement('button');
    newSaveButton.id = 'newSaveButton';
    newSaveButton.textContent = 'Save Selected';
    
    // Add event listener for save button
    newSaveButton.addEventListener('click', () => {
        const selectedType = saveDropdown.value;
        
        if (selectedType === 'all') {
            if (onSaveAll) {
                onSaveAll();
            }
        } else {
            if (onSaveType) {
                onSaveType(selectedType);
            }
        }
    });
    
    // Add elements to the header
    headerSaveContainer.innerHTML = '';
    headerSaveContainer.appendChild(saveDropdown);
    headerSaveContainer.appendChild(newSaveButton);
    
    // Re-add load button
    const loadAllButton = document.createElement('button');
    loadAllButton.id = 'loadAllButton';
    loadAllButton.textContent = 'Load Components';
    loadAllButton.addEventListener('click', () => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';
        input.multiple = true;
        
        input.onchange = e => {
            if (onLoadFiles) {
                onLoadFiles(e.target.files);
            }
        };
        
        input.click();
    });
    
    headerSaveContainer.appendChild(loadAllButton);
}

/**
 * Get component types from definitions
 * @returns {Object} - Object containing component type names
 */
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
 * Show/hide hardpoints tab based on component type
 * @param {string} type - Component type
 */
function toggleHardpointsTab(type) {
    const hardpointsTab = document.querySelector('.tab-button[data-tab="hardpointsTab"]');
    const hardpointsTabContent = document.getElementById('hardpointsTab');
    
    if (!hardpointsTab || !hardpointsTabContent) return;
    
    if (type === 'ship') {
        // Show tab for ships
        hardpointsTab.style.display = 'block';
    } else {
        // Hide tab for other component types
        hardpointsTab.style.display = 'none';
        
        // Show placeholder message
        hardpointsTabContent.innerHTML = '';
        const notAvailableMessage = document.createElement('div');
        notAvailableMessage.className = 'centered-text';
        notAvailableMessage.textContent = 'Hardpoint editor is only available for ship components.';
        hardpointsTabContent.appendChild(notAvailableMessage);
    }
}

/**
 * Get current component type and ID
 * @returns {Object} - Object with type and id properties
 */
function getCurrentSelection() {
    return { type: currentType, id: currentId };
}

/**
 * Set current component type and ID
 * @param {string} type - Component type
 * @param {string} id - Component ID
 */
function setCurrentSelection(type, id) {
    currentType = type;
    currentId = id;
}