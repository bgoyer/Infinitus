/**
 * sprite-manager.js
 * Manages loading and storage of ship sprites
 */

// Store for all loaded ship sprites
let spriteDatabase = {};

/**
 * Get sprite by name
 * @param {string} name - Sprite name or ID
 * @returns {string|null} - Sprite data URL or null if not found
 */
function getSprite(name) {
    return spriteDatabase[name] || null;
}

/**
 * Get all sprite names
 * @returns {string[]} - Array of sprite names
 */
function getSpriteNames() {
    return Object.keys(spriteDatabase);
}

/**
 * Add sprite to database
 * @param {string} name - Sprite name or ID
 * @param {string} dataUrl - Sprite data URL
 */
function addSprite(name, dataUrl) {
    spriteDatabase[name] = dataUrl;
}

/**
 * Process image file and add to sprite database
 * @param {File} file - Image file
 * @param {Function} onComplete - Callback when processing complete
 */
function processSprite(file, onComplete) {
    const reader = new FileReader();
    reader.onload = (e) => {
        // Extract filename without extension for sprite name
        let spriteName = file.name;
        // Remove file extension
        spriteName = spriteName.replace(/\.[^/.]+$/, "");
        
        // Add to database
        addSprite(spriteName, e.target.result);
        
        if (onComplete) {
            onComplete(spriteName);
        }
    };
    reader.readAsDataURL(file);
}

/**
 * Load multiple sprite files
 * @param {FileList} files - Image files to load
 * @param {Function} onProgress - Progress callback
 * @param {Function} onComplete - Callback when all files loaded
 */
function loadSpriteFiles(files, onProgress, onComplete) {
    let processed = 0;
    const total = files.length;
    const validImageTypes = ['image/png', 'image/jpeg', 'image/gif', 'image/webp'];
    const loadedSprites = [];
    
    // Filter to only include image files
    const imageFiles = Array.from(files).filter(file => 
        validImageTypes.includes(file.type)
    );
    
    if (imageFiles.length === 0) {
        if (onComplete) onComplete([]);
        return;
    }
    
    // Process each image file
    imageFiles.forEach(file => {
        processSprite(file, (spriteName) => {
            processed++;
            loadedSprites.push(spriteName);
            
            if (onProgress) {
                onProgress(processed, imageFiles.length);
            }
            
            if (processed === imageFiles.length && onComplete) {
                onComplete(loadedSprites);
            }
        });
    });
}

/**
 * Create sprite selector interface
 * @param {HTMLElement} container - Container to append selector to
 * @param {string} currentSprite - Currently selected sprite name
 * @param {Function} onSelect - Callback when sprite selected
 */
function createSpriteSelector(container, currentSprite, onSelect) {
    // Create selector container
    const selectorContainer = document.createElement('div');
    selectorContainer.className = 'sprite-selector-container';
    selectorContainer.style.marginTop = '10px';
    selectorContainer.style.marginBottom = '10px';
    
    // Create label
    const label = document.createElement('label');
    label.textContent = 'Select sprite: ';
    label.htmlFor = 'sprite-select';
    selectorContainer.appendChild(label);
    
    // Create select element
    const select = document.createElement('select');
    select.id = 'sprite-select';
    select.style.minWidth = '200px';
    
    // Add option for no sprite
    const noneOption = document.createElement('option');
    noneOption.value = '';
    noneOption.textContent = '-- Select Sprite --';
    select.appendChild(noneOption);
    
    // Add options for all sprites
    getSpriteNames().forEach(name => {
        const option = document.createElement('option');
        option.value = name;
        option.textContent = name;
        select.appendChild(option);
    });
    
    // Set current value if provided
    if (currentSprite) {
        select.value = currentSprite;
    }
    
    // Handle selection change
    select.addEventListener('change', () => {
        if (onSelect) {
            onSelect(select.value);
        }
    });
    
    selectorContainer.appendChild(select);
    
    // Add to container
    container.appendChild(selectorContainer);
    
    return select;
}