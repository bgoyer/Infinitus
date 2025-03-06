/**
 * component-data.js
 * Handles loading, saving, and management of component data
 */

// Components database
let componentDatabase = {
    ship: {},
    capacitor: {},
    generator: {},
    shield: {},
    armor: {},
    thruster: {},
    turning: {},
    weapon: {},
    fleet: {}
};

/**
 * Process component data and add it to the database
 * @param {Object} data - The component data to process
 * @param {string} filename - The filename for component type determination
 */
function processComponentData(data, filename) {
    // If no data or empty object, skip
    if (!data || Object.keys(data).length === 0) return;
    
    // Check if data already has component type structure
    if (data.ship || data.capacitor || data.generator || data.shield || 
        data.armor || data.thruster || data.turning || data.weapon || data.fleet) {
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
            
            // Determine component type by properties if not already set in data
            if ((defaultType === 'ship' || !componentDatabase[defaultType]) && !componentData.type) {
                if ('max_velocity' in componentData || 'max_hull_health' in componentData || 'hardpoints' in componentData) {
                    componentType = 'ship';
                } else if ('max_capacity' in componentData || componentData.equipment_name?.toLowerCase().includes('capacitor')) {
                    componentType = 'capacitor';
                } else if ('generation_rate' in componentData || componentData.equipment_name?.toLowerCase().includes('generator')) {
                    componentType = 'generator';
                } else if ('max_shield' in componentData || 'shield_color' in componentData || componentData.equipment_name?.toLowerCase().includes('shield')) {
                    componentType = 'shield';
                } else if ('armor_rating' in componentData || 'resistances' in componentData || componentData.equipment_name?.toLowerCase().includes('armor')) {
                    componentType = 'armor';
                } else if ('thrust' in componentData) {
                    // Differentiate between thruster and turning based on name, description, or equipment_name
                    if ((componentData.equipment_name && componentData.equipment_name.toLowerCase().includes('turn')) ||
                        (componentData.name && componentData.name.toLowerCase().includes('turn')) ||
                        (componentData.description && componentData.description.toLowerCase().includes('turn'))) {
                        componentType = 'turning';
                    } else {
                        componentType = 'thruster';
                    }
                } else if ('damage' in componentData || 'fire_rate' in componentData || 'weapon_name' in componentData) {
                    componentType = 'weapon';
                } else if ('flagship' in componentData || 'formation' in componentData) {
                    componentType = 'fleet';
                }
            } else if (componentData.type) {
                // Use the type field if available
                switch(componentData.type) {
                    case 'capacitor':
                        componentType = 'capacitor';
                        break;
                    case 'generator':
                        componentType = 'generator';
                        break;
                    case 'shield':
                        componentType = 'shield';
                        break;
                    case 'armor':
                        componentType = 'armor';
                        break;
                    case 'thruster':
                        componentType = 'thruster';
                        break;
                    case 'turning':
                        componentType = 'turning';
                        break;
                    case 'gun':
                    case 'turret':
                    case 'missile_launcher':
                        componentType = 'weapon';
                        break;
                    // No need for a default case as componentType is already set to defaultType
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
function saveComponentTypeToFile(type) {
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
function loadComponentFiles(files, onComplete, onProgress) {
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
function getComponent(type, id) {
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
function saveComponent(type, id, data) {
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
function deleteComponent(type, id) {
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
function getComponentIdsForType(type) {
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
function getComponentsOfType(type) {
    return componentDatabase[type] || {};
}

/**
 * Merge component data with existing database
 * @param {Object} data - Component data to merge
 * @param {string} type - Component type
 */
function mergeComponentData(data, type) {
    if (!data || !type || !componentDatabase[type]) return;
    
    Object.assign(componentDatabase[type], data);
}

/**
 * Export all component data as a combined JSON object
 * @returns {Object} - All component data
 */
function exportAllComponentData() {
    return JSON.parse(JSON.stringify(componentDatabase));
}

/**
 * Import component data from a JSON object
 * @param {Object} data - Component data to import
 * @returns {boolean} - Success status
 */
function importComponentData(data) {
    if (!data) return false;
    
    try {
        // Merge each component type
        Object.keys(data).forEach(type => {
            if (componentDatabase[type]) {
                Object.assign(componentDatabase[type], data[type]);
            } else {
                // Create new type if needed
                componentDatabase[type] = data[type];
            }
        });
        
        return true;
    } catch (error) {
        console.error('Error importing component data:', error);
        return false;
    }
}