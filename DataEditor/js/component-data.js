/**
 * component-data.js
 * Handles loading, saving, and management of component data
 */

// Components database
export let componentDatabase = {
    ship: {},
    capacitor: {},
    generator: {},
    shield: {},
    armor: {},
    thruster: {},
    turning: {},
    weapon: {}
};

/**
 * Process component data and add it to the database
 * @param {Object} data - The component data to process
 * @param {string} filename - The filename for component type determination
 */
export function processComponentData(data, filename) {
    // If no data or empty object, skip
    if (!data || Object.keys(data).length === 0) return;
    
    // Check if data already has component type structure
    if (data.ship || data.capacitor || data.generator || data.shield || 
        data.armor || data.thruster || data.turning || data.weapon) {
        // Merge with existing database instead of replacing
        Object.keys(data).forEach(type => {
            if (componentDatabase[type]) {
                Object.assign(componentDatabase[type], data[type]);
            }
        });
    } 
    // If data is just a list of components
    else {
        // Determine component type based on filename
        let defaultType = filename.replace('.json', '');
        
        // If the filename doesn't match a known type, try to identify by properties
        if (!componentDatabase[defaultType]) {
            defaultType = 'ship'; // Default fallback
        }
        
        // Process each component
        for (const [itemId, componentData] of Object.entries(data)) {
            let componentType = defaultType;
            
            // Determine component type by properties if not determined by filename
            if (defaultType === 'ship' || !componentDatabase[defaultType]) {
                if ('max_velocity' in componentData || 'max_hull_health' in componentData) {
                    componentType = 'ship';
                } else if ('max_capacity' in componentData) {
                    componentType = 'capacitor';
                } else if ('generation_rate' in componentData) {
                    componentType = 'generator';
                } else if ('max_shield' in componentData) {
                    componentType = 'shield';
                } else if ('armor_rating' in componentData) {
                    componentType = 'armor';
                } else if ('thrust' in componentData) {
                    // Differentiate between thruster and turning based on name or description
                    if (componentData.equipment_name && 
                        componentData.equipment_name.toLowerCase().includes('turn')) {
                        componentType = 'turning';
                    } else {
                        componentType = 'thruster';
                    }
                } else if ('damage' in componentData || 'fire_rate' in componentData) {
                    componentType = 'weapon';
                }
            }
            
            // Add component to the appropriate category
            componentDatabase[componentType][itemId] = componentData;
        }
    }
}

/**
 * Save a specific component type to a file
 * @param {string} type - The component type to save
 */
export function saveComponentTypeToFile(type) {
    const jsonString = JSON.stringify(componentDatabase[type], null, 2);
    const blob = new Blob([jsonString], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = `${type}.json`;
    a.click();
    
    URL.revokeObjectURL(url);
}

/**
 * Load component data from uploaded files
 * @param {FileList} files - The uploaded files
 * @param {Function} onComplete - Callback function when all files are processed
 * @param {Function} onProgress - Callback function for progress updates
 */
export function loadComponentFiles(files, onComplete, onProgress) {
    if (files.length === 0) return;
    
    let filesProcessed = 0;
    const totalFiles = files.length;
    
    // Process each file
    Array.from(files).forEach(file => {
        const reader = new FileReader();
        reader.onload = event => {
            try {
                const data = JSON.parse(event.target.result);
                processComponentData(data, file.name);
                
                filesProcessed++;
                if (onProgress) {
                    onProgress(filesProcessed, totalFiles, null);
                }
                
                if (filesProcessed === totalFiles && onComplete) {
                    onComplete();
                }
            } catch (error) {
                console.error('Error parsing JSON:', error);
                
                filesProcessed++;
                if (onProgress) {
                    onProgress(filesProcessed, totalFiles, `Error in ${file.name}`);
                }
                
                if (filesProcessed === totalFiles && onComplete) {
                    onComplete();
                }
            }
        };
        reader.readAsText(file);
    });
}

/**
 * Get a component by ID and type
 * @param {string} type - Component type
 * @param {string} id - Component ID
 * @returns {Object|null} - The component data or null if not found
 */
export function getComponent(type, id) {
    if (componentDatabase[type] && componentDatabase[type][id]) {
        return componentDatabase[type][id];
    }
    return null;
}

/**
 * Save a component to the database
 * @param {string} type - Component type
 * @param {string} id - Component ID
 * @param {Object} data - Component data
 */
export function saveComponent(type, id, data) {
    if (type && id && data) {
        componentDatabase[type][id] = data;
        return true;
    }
    return false;
}

/**
 * Delete a component from the database
 * @param {string} type - Component type
 * @param {string} id - Component ID
 * @returns {boolean} - Success status
 */
export function deleteComponent(type, id) {
    if (componentDatabase[type] && componentDatabase[type][id]) {
        delete componentDatabase[type][id];
        return true;
    }
    return false;
}

/**
 * Get all component IDs for a specific type
 * @param {string} type - Component type
 * @returns {string[]} - Array of component IDs
 */
export function getComponentIdsForType(type) {
    if (componentDatabase[type]) {
        return Object.keys(componentDatabase[type]);
    }
    return [];
}

/**
 * Get all components of a specific type
 * @param {string} type - Component type
 * @returns {Object} - Object containing all components of the specified type
 */
export function getComponentsOfType(type) {
    return componentDatabase[type] || {};
}
