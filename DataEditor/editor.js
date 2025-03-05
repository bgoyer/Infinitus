// List of component file names to load
const defaultComponentFiles = [
    'ship.json',
    'capacitor.json', 
    'generator.json',
    'shield.json',
    'armor.json',
    'thruster.json',
    'turning.json',
    'weapon.json'
];

// Components database
let componentDatabase = {
    ship: {},
    capacitor: {},
    generator: {},
    shield: {},
    armor: {},
    thruster: {},
    turning: {},
    weapon: {}
};

// Currently selected component
let currentType = 'ship';
let currentId = '';

// Field definitions for each component type
const fieldDefinitions = {
    ship: {
        specific: [
            { id: 'max_velocity', label: 'Max Velocity', type: 'number', default: 1000 },
            { id: 'max_hull_health', label: 'Max Hull Health', type: 'number', default: 100 },
            { id: 'faction', label: 'Faction', type: 'select', options: ['neutral', 'pirate', 'police', 'trader'], default: 'neutral' },
            { id: 'scene_path', label: 'Scene Path (optional)', type: 'text', default: '' }
        ],
        advanced: [
            { id: 'equipment', label: 'Equipment Configuration', type: 'equipment', default: {} }
        ]
    },
    capacitor: {
        specific: [
            { id: 'max_capacity', label: 'Max Capacity', type: 'number', default: 100 },
            { id: 'discharge_efficiency', label: 'Discharge Efficiency', type: 'number', default: 1.0, step: 0.05 },
            { id: 'recharge_efficiency', label: 'Recharge Efficiency', type: 'number', default: 1.0, step: 0.05 },
            { id: 'discharge_rate_limit', label: 'Discharge Rate Limit', type: 'number', default: 50.0 }
        ],
        advanced: []
    },
    generator: {
        specific: [
            { id: 'generation_rate', label: 'Generation Rate', type: 'number', default: 10.0 },
            { id: 'efficiency', label: 'Efficiency', type: 'number', default: 1.0, step: 0.05 },
            { id: 'power_up_time', label: 'Power Up Time (s)', type: 'number', default: 0.5, step: 0.1 }
        ],
        advanced: [
            { id: 'heat_generation', label: 'Heat Generation', type: 'number', default: 1.0, step: 0.1 },
            { id: 'overload_threshold', label: 'Overload Threshold', type: 'number', default: 1.5, step: 0.1 }
        ]
    },
    shield: {
        specific: [
            { id: 'max_shield', label: 'Max Shield Points', type: 'number', default: 50 },
            { id: 'recharge_rate', label: 'Recharge Rate (points/s)', type: 'number', default: 5.0 },
            { id: 'recharge_delay', label: 'Recharge Delay (s)', type: 'number', default: 3.0, step: 0.1 },
            { id: 'energy_drain', label: 'Energy Drain (per second)', type: 'number', default: 1.0, step: 0.1 }
        ],
        advanced: [
            { id: 'hit_energy_cost', label: 'Energy Cost per Hit Point', type: 'number', default: 2.0, step: 0.1 },
            { id: 'projectile_reflection_chance', label: 'Projectile Reflection Chance', type: 'number', default: 0, min: 0, max: 1, step: 0.01 },
            { id: 'damage_conversion', label: 'Damage to Energy Conversion', type: 'number', default: 0, min: 0, max: 1, step: 0.01 },
            { id: 'shield_color', label: 'Shield Color', type: 'color', default: { r: 0.3, g: 0.5, b: 1.0, a: 0.7 } }
        ]
    },
    armor: {
        specific: [
            { id: 'armor_rating', label: 'Armor Rating', type: 'number', default: 10 },
            { id: 'damage_threshold', label: 'Damage Threshold', type: 'number', default: 5 },
            { id: 'max_absorption', label: 'Max Absorption (0-1)', type: 'number', default: 0.8, min: 0, max: 1, step: 0.05 }
        ],
        advanced: [
            { id: 'kinetic_resistance', label: 'Kinetic Resistance', type: 'number', default: 1.0, step: 0.1 },
            { id: 'energy_resistance', label: 'Energy Resistance', type: 'number', default: 1.0, step: 0.1 },
            { id: 'explosive_resistance', label: 'Explosive Resistance', type: 'number', default: 1.0, step: 0.1 },
            { id: 'thermal_resistance', label: 'Thermal Resistance', type: 'number', default: 1.0, step: 0.1 }
        ]
    },
    thruster: {
        specific: [
            { id: 'thrust', label: 'Thrust', type: 'number', default: 25 },
            { id: 'drain', label: 'Energy Drain', type: 'number', default: 1 },
            { id: 'capacitor_need', label: 'Capacitor Need', type: 'number', default: 1 },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Standard Thruster' }
        ],
        advanced: []
    },
    turning: {
        specific: [
            { id: 'thrust', label: 'Turning Force', type: 'number', default: 4 },
            { id: 'drain', label: 'Energy Drain', type: 'number', default: 1 },
            { id: 'capacitor_need', label: 'Capacitor Need', type: 'number', default: 1 },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Standard Turning System' }
        ],
        advanced: []
    },
    weapon: {
        specific: [
            { id: 'type', label: 'Weapon Type', type: 'select', options: ['gun', 'turret', 'missile_launcher'], default: 'gun' },
            { id: 'damage', label: 'Damage', type: 'number', default: 10 },
            { id: 'fire_rate', label: 'Fire Rate (shots/s)', type: 'number', default: 1.0, step: 0.1 },
            { id: 'range_distance', label: 'Range', type: 'number', default: 1000.0 },
            { id: 'projectile_speed', label: 'Projectile Speed', type: 'number', default: 800.0 },
            { id: 'energy_cost', label: 'Energy Cost per Shot', type: 'number', default: 5 },
            { id: 'weapon_name', label: 'Weapon Name', type: 'text', default: 'Generic Weapon' }
        ],
        advanced: [
            { id: 'accuracy', label: 'Accuracy (0-1)', type: 'number', default: 1.0, min: 0, max: 1, step: 0.05 },
            { id: 'auto_target', label: 'Auto Target', type: 'checkbox', default: false },
            { id: 'ammo_capacity', label: 'Ammo Capacity (-1 for unlimited)', type: 'number', default: -1 },
            { id: 'projectile_scene', label: 'Projectile Scene Path', type: 'text', default: 'res://Scenes/Projectiles/DefaultProjectile.tscn' },
            
            // Gun-specific
            { id: 'gun_spread_angle', label: 'Spread Angle (Gun)', type: 'number', default: 0.0, showIf: {field: 'type', value: 'gun'} },
            
            // Turret-specific
            { id: 'turret_rotation_speed', label: 'Rotation Speed (Turret)', type: 'number', default: 3.0, showIf: {field: 'type', value: 'turret'} },
            { id: 'turret_aim_ahead_factor', label: 'Aim Ahead Factor (Turret)', type: 'number', default: 1.0, step: 0.1, showIf: {field: 'type', value: 'turret'} },
            { id: 'turret_fire_arc', label: 'Fire Arc (Turret)', type: 'number', default: 180.0, showIf: {field: 'type', value: 'turret'} },
            { id: 'turret_base_inaccuracy', label: 'Base Inaccuracy (Turret)', type: 'number', default: 0.1, min: 0, max: 1, step: 0.05, showIf: {field: 'type', value: 'turret'} },
            
            // Missile launcher-specific
            { id: 'missile_tracking_time', label: 'Tracking Time (Missile)', type: 'number', default: 5.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_turning_speed', label: 'Turning Speed (Missile)', type: 'number', default: 2.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_acceleration', label: 'Acceleration (Missile)', type: 'number', default: 100.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_max_speed', label: 'Max Speed (Missile)', type: 'number', default: 500.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_blast_radius', label: 'Blast Radius (Missile)', type: 'number', default: 50.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_salvo_size', label: 'Salvo Size (Missile)', type: 'number', default: 1, min: 1, showIf: {field: 'type', value: 'missile_launcher'} }
        ]
    }
};

// Equipment types for ship configuration
const equipmentTypes = [
    { id: 'thruster', label: 'Thruster' },
    { id: 'turning', label: 'Turning' },
    { id: 'capacitor', label: 'Capacitor' },
    { id: 'generator', label: 'Generator' },
    { id: 'shield', label: 'Shield' },
    { id: 'armor', label: 'Armor' }
];

// Function to process component data and add it to the database
function processComponentData(data, filename) {
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

// Initialize the editor
document.addEventListener('DOMContentLoaded', () => {
    // Get DOM elements
    const componentTypeSelect = document.getElementById('componentType');
    const itemIdInput = document.getElementById('itemId');
    const nameInput = document.getElementById('name');
    const descriptionInput = document.getElementById('description');
    const massInput = document.getElementById('mass');
    const valueInput = document.getElementById('value');
    const volumeInput = document.getElementById('volume');
    
    const specificTabContent = document.getElementById('specificTab');
    const advancedTabContent = document.getElementById('advancedTab');
    const jsonOutput = document.getElementById('jsonOutput');
    const itemList = document.getElementById('itemList');
    
    const saveButton = document.getElementById('saveButton');
    const newButton = document.getElementById('newButton');
    const deleteButton = document.getElementById('deleteButton');
    const copyButton = document.getElementById('copyButton');
    const saveAllButton = document.getElementById('saveAllButton');
    const loadAllButton = document.getElementById('loadAllButton');
    
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
    
    // Current equipment configuration for ships
    let currentEquipment = {
        thruster: '',
        turning: '',
        capacitor: '',
        generator: '',
        shield: '',
        armor: '',
        weapons: []
    };
    
    // Set up tab switching
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
    
    // Initialize fields for the current component type
    updateTypeSpecificFields();
    
    // Initial load button handler
    initialLoadButton.addEventListener('click', () => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';
        input.multiple = true;
        
        input.onchange = e => {
            const files = e.target.files;
            if (files.length === 0) return;
            
            let filesProcessed = 0;
            const totalFiles = files.length;
            
            // Show loading indicator
            initialLoadMessage.innerHTML = '<h2>Loading Component Files</h2>' + 
                '<p>Please wait while your files are processed...</p>' +
                '<div id="loadingProgress">0/' + totalFiles + ' files processed</div>';
            initialLoadButton.style.display = 'none';
            
            // Process each file
            Array.from(files).forEach(file => {
                const reader = new FileReader();
                reader.onload = event => {
                    try {
                        const data = JSON.parse(event.target.result);
                        processComponentData(data, file.name);
                        
                        filesProcessed++;
                        document.getElementById('loadingProgress').textContent = 
                            filesProcessed + '/' + totalFiles + ' files processed';
                        
                        // If all files are processed, show the editor
                        if (filesProcessed === totalFiles) {
                            console.log('All component files loaded');
                            initialLoadContainer.style.display = 'none';
                            editorContainer.style.display = 'flex';
                            updateItemList();
                            updateJsonOutput();
                            updateTypeSpecificFields();
                        }
                    } catch (error) {
                        console.error('Error parsing JSON:', error);
                        filesProcessed++;
                        document.getElementById('loadingProgress').textContent = 
                            filesProcessed + '/' + totalFiles + ' files processed (Error in ' + file.name + ')';
                        
                        if (filesProcessed === totalFiles) {
                            initialLoadContainer.style.display = 'none';
                            editorContainer.style.display = 'flex';
                            updateItemList();
                            updateJsonOutput();
                            updateTypeSpecificFields();
                        }
                    }
                };
                reader.readAsText(file);
            });
        };
        
        input.click();
    });
    
    // Handle component type change
    componentTypeSelect.addEventListener('change', () => {
        currentType = componentTypeSelect.value;
        updateTypeSpecificFields();
        updateItemList();
    });
    
    // Save component button
    saveButton.addEventListener('click', saveComponent);
    
    // New component button
    newButton.addEventListener('click', () => {
        clearForm();
        currentId = '';
        itemIdInput.value = '';
        
        // Reset equipment for ships
        if (currentType === 'ship') {
            currentEquipment = {
                thruster: '',
                turning: '',
                capacitor: '',
                generator: '',
                shield: '',
                armor: '',
                weapons: []
            };
            rebuildEquipmentSelectors();
        }
    });
    
    // Delete component button
    deleteButton.addEventListener('click', () => {
        if (currentId && componentDatabase[currentType][currentId]) {
            if (confirm(`Are you sure you want to delete ${currentId}?`)) {
                delete componentDatabase[currentType][currentId];
                updateItemList();
                clearForm();
                updateJsonOutput();
            }
        } else {
            alert('No component selected to delete.');
        }
    });
    
    // Copy JSON button
    copyButton.addEventListener('click', () => {
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
    
    // Save all components button
    saveAllButton.addEventListener('click', () => {
        const jsonString = JSON.stringify(componentDatabase, null, 2);
        const blob = new Blob([jsonString], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = 'component_database.json';
        a.click();
        
        URL.revokeObjectURL(url);
    });
    
    // Load components button
    loadAllButton.addEventListener('click', () => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';
        input.multiple = true;
        
        input.onchange = e => {
            const files = e.target.files;
            if (files.length === 0) return;
            
            let filesProcessed = 0;
            
            Array.from(files).forEach(file => {
                const reader = new FileReader();
                reader.onload = event => {
                    try {
                        const data = JSON.parse(event.target.result);
                        processComponentData(data, file.name);
                        
                        filesProcessed++;
                        if (filesProcessed === files.length) {
                            // All files processed
                            updateItemList();
                            updateJsonOutput();
                            updateTypeSpecificFields();
                            alert('Components loaded successfully!');
                        }
                    } catch (error) {
                        console.error('Error parsing JSON:', error);
                        alert(`Error loading file ${file.name}: Invalid JSON format.`);
                        
                        filesProcessed++;
                        if (filesProcessed === files.length) {
                            updateItemList();
                            updateJsonOutput();
                            updateTypeSpecificFields();
                        }
                    }
                };
                reader.readAsText(file);
            });
        };
        
        input.click();
    });
    
    // Function to update type-specific fields
    function updateTypeSpecificFields() {
        // Clear current fields
        specificTabContent.innerHTML = '';
        advancedTabContent.innerHTML = '';
        
        // Get field definitions for current type
        const specificFields = fieldDefinitions[currentType].specific || [];
        const advancedFields = fieldDefinitions[currentType].advanced || [];
        
        // Add specific fields
        specificFields.forEach(field => {
            const formGroup = createFormField(field);
            specificTabContent.appendChild(formGroup);
        });
        
        // Add advanced fields
        advancedFields.forEach(field => {
            if (field.type === 'equipment' && currentType === 'ship') {
                // Special handling for equipment config in ships
                const formGroup = createEquipmentSelector();
                advancedTabContent.appendChild(formGroup);
            } else {
                const formGroup = createFormField(field);
                advancedTabContent.appendChild(formGroup);
            }
        });
        
        // Update item list for new type
        updateItemList();
        
        // Generate initial JSON output
        updateJsonOutput();
    }
    
    // Create equipment selector for ships
    function createEquipmentSelector() {
        const container = document.createElement('div');
        container.className = 'form-group';
        
        const label = document.createElement('label');
        label.textContent = 'Equipment Configuration';
        container.appendChild(label);
        
        // Create container for equipment entries
        const equipmentContainer = document.createElement('div');
        equipmentContainer.className = 'equipment-list';
        equipmentContainer.id = 'equipment-container';
        container.appendChild(equipmentContainer);
        
        // Create sections for different equipment types
        equipmentTypes.forEach(eqType => {
            const equipmentEntry = document.createElement('div');
            equipmentEntry.className = 'equipment-entry';
            
            const equipmentLabel = document.createElement('label');
            equipmentLabel.textContent = eqType.label + ':';
            equipmentLabel.style.width = '80px';
            equipmentEntry.appendChild(equipmentLabel);
            
            const selector = document.createElement('select');
            selector.id = `equipment-${eqType.id}`;
            selector.className = 'equipment-selector';
            
            // Add empty option
            const emptyOption = document.createElement('option');
            emptyOption.value = '';
            emptyOption.textContent = '-- None --';
            selector.appendChild(emptyOption);
            
            // Add available items from componentDatabase
            if (componentDatabase[eqType.id]) {
                Object.keys(componentDatabase[eqType.id]).forEach(itemId => {
                    const itemData = componentDatabase[eqType.id][itemId];
                    const option = document.createElement('option');
                    option.value = itemId;
                    option.textContent = itemData.name || itemId;
                    selector.appendChild(option);
                });
            }
            
            // Set current value
            selector.value = currentEquipment[eqType.id] || '';
            
            // Handle changes
            selector.addEventListener('change', () => {
                currentEquipment[eqType.id] = selector.value;
                updateJsonOutput();
            });
            
            equipmentEntry.appendChild(selector);
            equipmentContainer.appendChild(equipmentEntry);
        });
        
        // Create weapons section
        const weaponsContainer = document.createElement('div');
        weaponsContainer.className = 'equipment-entry';
        
        const weaponLabel = document.createElement('label');
        weaponLabel.textContent = 'Weapons:';
        weaponLabel.style.width = '80px';
        weaponsContainer.appendChild(weaponLabel);
        
        const weaponsList = document.createElement('div');
        weaponsList.id = 'weapons-list';
        weaponsList.style.flex = '1';
        weaponsContainer.appendChild(weaponsList);
        
        // Render existing weapons
        function renderWeapons() {
            weaponsList.innerHTML = '';
            
            if (currentEquipment.weapons && currentEquipment.weapons.length > 0) {
                currentEquipment.weapons.forEach((weapon, index) => {
                    const weaponEntry = document.createElement('div');
                    weaponEntry.style.display = 'flex';
                    weaponEntry.style.marginBottom = '5px';
                    weaponEntry.style.gap = '5px';
                    
                    const weaponSelector = document.createElement('select');
                    weaponSelector.style.flex = '1';
                    
                    // Add empty option
                    const emptyOption = document.createElement('option');
                    emptyOption.value = '';
                    emptyOption.textContent = '-- None --';
                    weaponSelector.appendChild(emptyOption);
                    
                    // Add weapons from database
                    if (componentDatabase.weapon) {
                        Object.keys(componentDatabase.weapon).forEach(itemId => {
                            const itemData = componentDatabase.weapon[itemId];
                            const option = document.createElement('option');
                            option.value = itemId;
                            option.textContent = itemData.name || itemId;
                            weaponSelector.appendChild(option);
                        });
                    }
                    
                    // Set current value
                    weaponSelector.value = weapon.id || '';
                    
                    // Handle weapon selection change
                    weaponSelector.addEventListener('change', () => {
                        currentEquipment.weapons[index].id = weaponSelector.value;
                        updateJsonOutput();
                    });
                    
                    const hardpointInput = document.createElement('input');
                    hardpointInput.type = 'number';
                    hardpointInput.min = 1;
                    hardpointInput.value = weapon.hardpoint || 1;
                    hardpointInput.style.width = '60px';
                    hardpointInput.placeholder = 'Slot';
                    
                    // Handle hardpoint change
                    hardpointInput.addEventListener('change', () => {
                        currentEquipment.weapons[index].hardpoint = parseInt(hardpointInput.value) || 1;
                        updateJsonOutput();
                    });
                    
                    const removeButton = document.createElement('button');
                    removeButton.className = 'remove-equipment-btn';
                    removeButton.textContent = 'X';
                    removeButton.addEventListener('click', () => {
                        currentEquipment.weapons.splice(index, 1);
                        renderWeapons();
                        updateJsonOutput();
                    });
                    
                    weaponEntry.appendChild(weaponSelector);
                    weaponEntry.appendChild(hardpointInput);
                    weaponEntry.appendChild(removeButton);
                    weaponsList.appendChild(weaponEntry);
                });
            }
            
            // Add button for new weapon
            const addWeaponBtn = document.createElement('button');
            addWeaponBtn.className = 'add-equipment-btn';
            addWeaponBtn.textContent = 'Add Weapon';
            addWeaponBtn.addEventListener('click', () => {
                if (!currentEquipment.weapons) {
                    currentEquipment.weapons = [];
                }
                currentEquipment.weapons.push({ id: '', hardpoint: currentEquipment.weapons.length + 1 });
                renderWeapons();
                updateJsonOutput();
            });
            
            weaponsList.appendChild(addWeaponBtn);
        }
        
        renderWeapons();
        equipmentContainer.appendChild(weaponsContainer);
        
        return container;
    }
    
    // Function to completely rebuild equipment selectors after loading data
    function rebuildEquipmentSelectors() {
        if (currentType !== 'ship') return;
        
        const equipmentContainer = document.getElementById('equipment-container');
        if (!equipmentContainer) {
            // If container doesn't exist, recreate the advanced tab
            updateTypeSpecificFields();
            return;
        }
        
        // Update equipment selectors
        equipmentTypes.forEach(eqType => {
            const selector = document.getElementById(`equipment-${eqType.id}`);
            if (selector) {
                // Clear existing options
                selector.innerHTML = '';
                
                // Add empty option
                const emptyOption = document.createElement('option');
                emptyOption.value = '';
                emptyOption.textContent = '-- None --';
                selector.appendChild(emptyOption);
                
                // Add available items from componentDatabase
                if (componentDatabase[eqType.id]) {
                    Object.keys(componentDatabase[eqType.id]).forEach(itemId => {
                        const itemData = componentDatabase[eqType.id][itemId];
                        const option = document.createElement('option');
                        option.value = itemId;
                        option.textContent = itemData.name || itemId;
                        selector.appendChild(option);
                    });
                }
                
                // Set current value
                selector.value = currentEquipment[eqType.id] || '';
            }
        });
        
        // Rebuild weapons list
        const weaponsList = document.getElementById('weapons-list');
        if (weaponsList) {
            weaponsList.innerHTML = '';
            
            if (currentEquipment.weapons && currentEquipment.weapons.length > 0) {
                currentEquipment.weapons.forEach((weapon, index) => {
                    const weaponEntry = document.createElement('div');
                    weaponEntry.style.display = 'flex';
                    weaponEntry.style.marginBottom = '5px';
                    weaponEntry.style.gap = '5px';
                    
                    const weaponSelector = document.createElement('select');
                    weaponSelector.style.flex = '1';
                    
                    // Add empty option
                    const emptyOption = document.createElement('option');
                    emptyOption.value = '';
                    emptyOption.textContent = '-- None --';
                    weaponSelector.appendChild(emptyOption);
                    
                    // Add weapons from database
                    if (componentDatabase.weapon) {
                        Object.keys(componentDatabase.weapon).forEach(itemId => {
                            const itemData = componentDatabase.weapon[itemId];
                            const option = document.createElement('option');
                            option.value = itemId;
                            option.textContent = itemData.name || itemId;
                            weaponSelector.appendChild(option);
                        });
                    }
                    
                    // Set current value
                    weaponSelector.value = weapon.id || '';
                    
                    // Handle weapon selection change
                    weaponSelector.addEventListener('change', () => {
                        currentEquipment.weapons[index].id = weaponSelector.value;
                        updateJsonOutput();
                    });
                    
                    const hardpointInput = document.createElement('input');
                    hardpointInput.type = 'number';
                    hardpointInput.min = 1;
                    hardpointInput.value = weapon.hardpoint || 1;
                    hardpointInput.style.width = '60px';
                    hardpointInput.placeholder = 'Slot';
                    
                    // Handle hardpoint change
                    hardpointInput.addEventListener('change', () => {
                        currentEquipment.weapons[index].hardpoint = parseInt(hardpointInput.value) || 1;
                        updateJsonOutput();
                    });
                    
                    const removeButton = document.createElement('button');
                    removeButton.className = 'remove-equipment-btn';
                    removeButton.textContent = 'X';
                    removeButton.addEventListener('click', () => {
                        currentEquipment.weapons.splice(index, 1);
                        rebuildEquipmentSelectors();
                        updateJsonOutput();
                    });
                    
                    weaponEntry.appendChild(weaponSelector);
                    weaponEntry.appendChild(hardpointInput);
                    weaponEntry.appendChild(removeButton);
                    weaponsList.appendChild(weaponEntry);
                });
            }
            
            // Add button for new weapon
            const addWeaponBtn = document.createElement('button');
            addWeaponBtn.className = 'add-equipment-btn';
            addWeaponBtn.textContent = 'Add Weapon';
            addWeaponBtn.addEventListener('click', () => {
                if (!currentEquipment.weapons) {
                    currentEquipment.weapons = [];
                }
                currentEquipment.weapons.push({ id: '', hardpoint: currentEquipment.weapons.length + 1 });
                rebuildEquipmentSelectors();
                updateJsonOutput();
            });
            
            weaponsList.appendChild(addWeaponBtn);
        }
    }
    
    // Create form field based on field definition
    function createFormField(field) {
        const formGroup = document.createElement('div');
        formGroup.className = 'form-group';
        
        const label = document.createElement('label');
        label.setAttribute('for', field.id);
        label.textContent = field.label || field.id;
        formGroup.appendChild(label);
        
        let input;
        
        switch (field.type) {
            case 'select':
                input = document.createElement('select');
                field.options.forEach(option => {
                    const optionElement = document.createElement('option');
                    optionElement.value = option;
                    optionElement.textContent = option;
                    input.appendChild(optionElement);
                });
                break;
                
            case 'checkbox':
                input = document.createElement('input');
                input.type = 'checkbox';
                input.checked = field.default;
                break;
                
            case 'color':
                // Create color picker with preview
                const colorContainer = document.createElement('div');
                colorContainer.className = 'color-picker';
                
                const colorPreview = document.createElement('div');
                colorPreview.className = 'color-preview';
                
                // Create inputs for RGBA
                const colorComponents = ['r', 'g', 'b', 'a'];
                const colorInputs = {};
                
                colorComponents.forEach(comp => {
                    const colorInput = document.createElement('input');
                    colorInput.type = 'number';
                    colorInput.min = 0;
                    colorInput.max = comp === 'a' ? 1 : 1;
                    colorInput.step = 0.05;
                    colorInput.value = field.default[comp];
                    colorInput.style.width = '60px';
                    colorInput.dataset.component = comp;
                    
                    colorInput.addEventListener('input', () => {
                        updateColorPreview();
                    });
                    
                    colorInputs[comp] = colorInput;
                    
                    const compLabel = document.createElement('span');
                    compLabel.textContent = comp.toUpperCase() + ':';
                    
                    const compContainer = document.createElement('div');
                    compContainer.style.display = 'inline-block';
                    compContainer.appendChild(compLabel);
                    compContainer.appendChild(colorInput);
                    
                    colorContainer.appendChild(compContainer);
                });
                
                colorContainer.appendChild(colorPreview);
                formGroup.appendChild(colorContainer);
                
                // Update color preview
                function updateColorPreview() {
                    const r = parseFloat(colorInputs.r.value);
                    const g = parseFloat(colorInputs.g.value);
                    const b = parseFloat(colorInputs.b.value);
                    const a = parseFloat(colorInputs.a.value);
                    
                    colorPreview.style.backgroundColor = `rgba(${r*255}, ${g*255}, ${b*255}, ${a})`;
                }
                
                updateColorPreview();
                
                // Store inputs reference for later data retrieval
                input = colorInputs;
                break;
                
            default: // text, number, etc.
                input = document.createElement('input');
                input.type = field.type || 'text';
                input.value = field.default !== undefined ? field.default : '';
                
                if (field.min !== undefined) input.min = field.min;
                if (field.max !== undefined) input.max = field.max;
                if (field.step !== undefined) input.step = field.step;
                break;
        }
        
        // Set common attributes
        if (input.id !== undefined) { // For non-color fields
            input.id = field.id;
            input.name = field.id;
            
            // Handle conditional display based on other fields
            if (field.showIf) {
                const dependsOnField = document.getElementById(field.showIf.field);
                
                if (dependsOnField) {
                    const updateVisibility = () => {
                        if (dependsOnField.value === field.showIf.value) {
                            formGroup.style.display = 'block';
                        } else {
                            formGroup.style.display = 'none';
                        }
                    };
                    
                    dependsOnField.addEventListener('change', updateVisibility);
                    
                    // Initial check
                    updateVisibility();
                }
            }
            
            formGroup.appendChild(input);
        }
        
        return formGroup;
    }
    
    // Update item list for current component type
    function updateItemList() {
        itemList.innerHTML = '';
        
        const items = Object.keys(componentDatabase[currentType] || {});
        
        items.forEach(id => {
            const item = document.createElement('div');
            item.textContent = componentDatabase[currentType][id].name || id;
            item.dataset.id = id;
            
            item.addEventListener('click', () => {
                currentId = id;
                loadComponentData(id);
            });
            
            itemList.appendChild(item);
        });
    }
    
    // Load component data into form
    function loadComponentData(id) {
        const data = componentDatabase[currentType][id];
        
        if (!data) return;
        
        // Set basic fields
        itemIdInput.value = id;
        nameInput.value = data.name || '';
        descriptionInput.value = data.description || '';
        massInput.value = data.mass || 0;
        valueInput.value = data.value || 0;
        volumeInput.value = data.volume || 0;
        
        // Set specific fields
        const specificFields = fieldDefinitions[currentType].specific || [];
        specificFields.forEach(field => {
            const input = document.getElementById(field.id);
            if (input) {
                if (field.type === 'checkbox') {
                    input.checked = data[field.id] || false;
                } else {
                    input.value = data[field.id] !== undefined ? data[field.id] : (field.default || '');
                }
            }
        });
        
        // Special handling for ship equipment
        if (currentType === 'ship' && data.equipment) {
            // Reset current equipment
            currentEquipment = {
                thruster: '',
                turning: '',
                capacitor: '',
                generator: '',
                shield: '',
                armor: '',
                weapons: []
            };
            
            // Load equipment from data
            if (data.equipment.thruster) currentEquipment.thruster = data.equipment.thruster;
            if (data.equipment.turning) currentEquipment.turning = data.equipment.turning;
            if (data.equipment.capacitor) currentEquipment.capacitor = data.equipment.capacitor;
            if (data.equipment.generator) currentEquipment.generator = data.equipment.generator;
            if (data.equipment.shield) currentEquipment.shield = data.equipment.shield;
            if (data.equipment.armor) currentEquipment.armor = data.equipment.armor;
            
            // Load weapons
            if (data.equipment.weapons && Array.isArray(data.equipment.weapons)) {
                currentEquipment.weapons = [...data.equipment.weapons];
            }
            
            // Completely rebuild equipment selectors with the latest data
            rebuildEquipmentSelectors();
        }
        
        // Set advanced fields
        const advancedFields = fieldDefinitions[currentType].advanced || [];
        advancedFields.forEach(field => {
            if (field.type === 'equipment') {
                // Equipment is handled separately
                return;
            }
            
            if (field.type === 'color') {
                // Handle color fields
                if (data[field.id]) {
                    const colorComponents = ['r', 'g', 'b', 'a'];
                    colorComponents.forEach(comp => {
                        const input = document.querySelector(`input[data-component="${comp}"]`);
                        if (input) {
                            input.value = data[field.id][comp] || 0;
                        }
                    });
                }
            } else {
                // Handle regular fields
                const input = document.getElementById(field.id);
                
                if (input) {
                    if (field.type === 'checkbox') {
                        input.checked = data[field.id] || false;
                    } else {
                        // Special handling for weapon subtypes
                        if (currentType === 'weapon') {
                            if (field.id === 'gun_spread_angle' && data.type === 'gun') {
                                input.value = data.spread_angle || field.default || 0;
                            } else if (field.id === 'turret_rotation_speed' && data.type === 'turret') {
                                input.value = data.rotation_speed || field.default || 0;
                            } else if (field.id === 'turret_aim_ahead_factor' && data.type === 'turret') {
                                input.value = data.aim_ahead_factor || field.default || 0;
                            } else if (field.id === 'turret_fire_arc' && data.type === 'turret') {
                                input.value = data.fire_arc || field.default || 0;
                            } else if (field.id === 'turret_base_inaccuracy' && data.type === 'turret') {
                                input.value = data.base_inaccuracy || field.default || 0;
                            } else if (field.id === 'missile_tracking_time' && data.type === 'missile_launcher') {
                                input.value = data.missile_tracking_time || field.default || 0;
                            } else if (field.id === 'missile_turning_speed' && data.type === 'missile_launcher') {
                                input.value = data.missile_turning_speed || field.default || 0;
                            } else if (field.id === 'missile_acceleration' && data.type === 'missile_launcher') {
                                input.value = data.missile_acceleration || field.default || 0;
                            } else if (field.id === 'missile_max_speed' && data.type === 'missile_launcher') {
                                input.value = data.missile_max_speed || field.default || 0;
                            } else if (field.id === 'missile_blast_radius' && data.type === 'missile_launcher') {
                                input.value = data.missile_blast_radius || field.default || 0;
                            } else if (field.id === 'missile_salvo_size' && data.type === 'missile_launcher') {
                                input.value = data.salvo_size || field.default || 1;
                            } else {
                                input.value = data[field.id] !== undefined ? data[field.id] : (field.default || '');
                            }
                        } else {
                            input.value = data[field.id] !== undefined ? data[field.id] : (field.default || '');
                        }
                    }
                }
            }
        });
        
        // Trigger change events to update conditional fields
        const typeSelect = document.getElementById('type');
        if (typeSelect) {
            typeSelect.dispatchEvent(new Event('change'));
        }
        
        // Update JSON output
        updateJsonOutput();
    }
    
    // Update equipment selectors with current values
    function updateEquipmentSelectors() {
        // Update equipment select values
        equipmentTypes.forEach(eqType => {
            const selector = document.getElementById(`equipment-${eqType.id}`);
            if (selector) {
                selector.value = currentEquipment[eqType.id] || '';
            }
        });
        
        // Update weapons list (needs to redraw the entire list)
        const weaponsList = document.getElementById('weapons-list');
        if (weaponsList) {
            weaponsList.innerHTML = '';
            
            // Re-render weapons (basically calling renderWeapons but on existing DOM)
            if (currentEquipment.weapons && currentEquipment.weapons.length > 0) {
                currentEquipment.weapons.forEach((weapon, index) => {
                    const weaponEntry = document.createElement('div');
                    weaponEntry.style.display = 'flex';
                    weaponEntry.style.marginBottom = '5px';
                    weaponEntry.style.gap = '5px';
                    
                    const weaponSelector = document.createElement('select');
                    weaponSelector.style.flex = '1';
                    
                    // Add empty option
                    const emptyOption = document.createElement('option');
                    emptyOption.value = '';
                    emptyOption.textContent = '-- None --';
                    weaponSelector.appendChild(emptyOption);
                    
                    // Add weapons from database
                    if (componentDatabase.weapon) {
                        Object.keys(componentDatabase.weapon).forEach(itemId => {
                            const itemData = componentDatabase.weapon[itemId];
                            const option = document.createElement('option');
                            option.value = itemId;
                            option.textContent = itemData.name || itemId;
                            weaponSelector.appendChild(option);
                        });
                    }
                    
                    // Set current value
                    weaponSelector.value = weapon.id || '';
                    
                    // Handle weapon selection change
                    weaponSelector.addEventListener('change', () => {
                        currentEquipment.weapons[index].id = weaponSelector.value;
                        updateJsonOutput();
                    });
                    
                    const hardpointInput = document.createElement('input');
                    hardpointInput.type = 'number';
                    hardpointInput.min = 1;
                    hardpointInput.value = weapon.hardpoint || 1;
                    hardpointInput.style.width = '60px';
                    hardpointInput.placeholder = 'Slot';
                    
                    // Handle hardpoint change
                    hardpointInput.addEventListener('change', () => {
                        currentEquipment.weapons[index].hardpoint = parseInt(hardpointInput.value) || 1;
                        updateJsonOutput();
                    });
                    
                    const removeButton = document.createElement('button');
                    removeButton.className = 'remove-equipment-btn';
                    removeButton.textContent = 'X';
                    removeButton.addEventListener('click', () => {
                        currentEquipment.weapons.splice(index, 1);
                        updateEquipmentSelectors();
                        updateJsonOutput();
                    });
                    
                    weaponEntry.appendChild(weaponSelector);
                    weaponEntry.appendChild(hardpointInput);
                    weaponEntry.appendChild(removeButton);
                    weaponsList.appendChild(weaponEntry);
                });
            }
            
            // Add button for new weapon
            const addWeaponBtn = document.createElement('button');
            addWeaponBtn.className = 'add-equipment-btn';
            addWeaponBtn.textContent = 'Add Weapon';
            addWeaponBtn.addEventListener('click', () => {
                if (!currentEquipment.weapons) {
                    currentEquipment.weapons = [];
                }
                currentEquipment.weapons.push({ id: '', hardpoint: currentEquipment.weapons.length + 1 });
                updateEquipmentSelectors();
                updateJsonOutput();
            });
            
            weaponsList.appendChild(addWeaponBtn);
        }
    }
    
    // Save component data
    function saveComponent() {
        const id = itemIdInput.value.trim();
        
        if (!id) {
            alert('Please enter a component ID');
            return;
        }
        
        // Prepare data object
        const data = {
            name: nameInput.value,
            description: descriptionInput.value,
            mass: parseInt(massInput.value),
            value: parseInt(valueInput.value),
            volume: parseInt(volumeInput.value)
        };
        
        // Add specific fields
        const specificFields = fieldDefinitions[currentType].specific || [];
        specificFields.forEach(field => {
            const input = document.getElementById(field.id);
            if (input) {
                if (field.type === 'checkbox') {
                    data[field.id] = input.checked;
                } else if (field.type === 'number') {
                    data[field.id] = parseFloat(input.value);
                } else {
                    data[field.id] = input.value;
                }
            }
        });
        
        // Handle equipment for ships
        if (currentType === 'ship') {
            const equipment = {};
            
            // Add basic equipment if selected
            equipmentTypes.forEach(eqType => {
                const eqId = currentEquipment[eqType.id];
                if (eqId) {
                    equipment[eqType.id] = eqId;
                }
            });
            
            // Add weapons if present
            if (currentEquipment.weapons && currentEquipment.weapons.length > 0) {
                // Filter out empty weapons
                const validWeapons = currentEquipment.weapons.filter(w => w.id);
                if (validWeapons.length > 0) {
                    equipment.weapons = validWeapons;
                }
            }
            
            // Add to data if we have any equipment
            if (Object.keys(equipment).length > 0) {
                data.equipment = equipment;
            }
        }
        
        // Add advanced fields
        const advancedFields = fieldDefinitions[currentType].advanced || [];
        advancedFields.forEach(field => {
            if (field.type === 'equipment') {
                // Equipment is handled separately
                return;
            }
            
            if (field.type === 'color') {
                // Handle color fields
                const colorComponents = ['r', 'g', 'b', 'a'];
                const colorData = {};
                
                colorComponents.forEach(comp => {
                    const input = document.querySelector(`input[data-component="${comp}"]`);
                    if (input) {
                        colorData[comp] = parseFloat(input.value);
                    }
                });
                
                data[field.id] = colorData;
            } else {
                // Handle regular fields
                const input = document.getElementById(field.id);
                
                if (input) {
                    if (field.type === 'checkbox') {
                        data[field.id] = input.checked;
                    } else if (field.type === 'number') {
                        data[field.id] = parseFloat(input.value);
                    } else {
                        data[field.id] = input.value;
                    }
                }
            }
        });
        
        // Special handling for weapon subtypes
        if (currentType === 'weapon') {
            const weaponType = document.getElementById('type').value;
            
            // Rename specific fields based on weapon type
            if (weaponType === 'gun') {
                const gunSpreadAngle = document.getElementById('gun_spread_angle');
                if (gunSpreadAngle) {
                    data.spread_angle = parseFloat(gunSpreadAngle.value);
                }
            } else if (weaponType === 'turret') {
                const rotationSpeed = document.getElementById('turret_rotation_speed');
                const aimAheadFactor = document.getElementById('turret_aim_ahead_factor');
                const fireArc = document.getElementById('turret_fire_arc');
                const baseInaccuracy = document.getElementById('turret_base_inaccuracy');
                
                if (rotationSpeed) data.rotation_speed = parseFloat(rotationSpeed.value);
                if (aimAheadFactor) data.aim_ahead_factor = parseFloat(aimAheadFactor.value);
                if (fireArc) data.fire_arc = parseFloat(fireArc.value);
                if (baseInaccuracy) data.base_inaccuracy = parseFloat(baseInaccuracy.value);
            } else if (weaponType === 'missile_launcher') {
                const trackingTime = document.getElementById('missile_tracking_time');
                const turningSpeed = document.getElementById('missile_turning_speed');
                const acceleration = document.getElementById('missile_acceleration');
                const maxSpeed = document.getElementById('missile_max_speed');
                const blastRadius = document.getElementById('missile_blast_radius');
                const salvoSize = document.getElementById('missile_salvo_size');
                
                if (trackingTime) data.missile_tracking_time = parseFloat(trackingTime.value);
                if (turningSpeed) data.missile_turning_speed = parseFloat(turningSpeed.value);
                if (acceleration) data.missile_acceleration = parseFloat(acceleration.value);
                if (maxSpeed) data.missile_max_speed = parseFloat(maxSpeed.value);
                if (blastRadius) data.missile_blast_radius = parseFloat(blastRadius.value);
                if (salvoSize) data.salvo_size = parseInt(salvoSize.value);
            }
        }
        
        // Save to database
        componentDatabase[currentType][id] = data;
        currentId = id;
        
        // Update UI
        updateItemList();
        updateJsonOutput();
        
        alert(`Component ${id} saved!`);
    }
    
    // Clear form fields
    function clearForm() {
        nameInput.value = '';
        descriptionInput.value = '';
        massInput.value = '10';
        valueInput.value = '100';
        volumeInput.value = '5';
        
        // Reset specific fields
        const specificFields = fieldDefinitions[currentType].specific || [];
        specificFields.forEach(field => {
            const input = document.getElementById(field.id);
            if (input) {
                if (field.type === 'checkbox') {
                    input.checked = field.default || false;
                } else {
                    input.value = field.default !== undefined ? field.default : '';
                }
            }
        });
        
        // Reset advanced fields
        const advancedFields = fieldDefinitions[currentType].advanced || [];
        advancedFields.forEach(field => {
            if (field.type === 'equipment') {
                // Reset equipment for ships
                if (currentType === 'ship') {
                    currentEquipment = {
                        thruster: '',
                        turning: '',
                        capacitor: '',
                        generator: '',
                        shield: '',
                        armor: '',
                        weapons: []
                    };
                    updateEquipmentSelectors();
                }
                return;
            }
            
            if (field.type === 'color') {
                // Handle color fields
                const colorComponents = ['r', 'g', 'b', 'a'];
                colorComponents.forEach(comp => {
                    const input = document.querySelector(`input[data-component="${comp}"]`);
                    if (input) {
                        input.value = field.default[comp] || 0;
                    }
                });
            } else {
                // Handle regular fields
                const input = document.getElementById(field.id);
                
                if (input) {
                    if (field.type === 'checkbox') {
                        input.checked = field.default || false;
                    } else {
                        input.value = field.default !== undefined ? field.default : '';
                    }
                }
            }
        });
        
        // Trigger change events to update conditional fields
        const typeSelect = document.getElementById('type');
        if (typeSelect) {
            typeSelect.dispatchEvent(new Event('change'));
        }
    }
    
    // Update JSON output display
    function updateJsonOutput() {
        let json;
        
        if (currentId && componentDatabase[currentType][currentId]) {
            // Show selected component
            const componentObj = {};
            componentObj[currentId] = componentDatabase[currentType][currentId];
            json = JSON.stringify(componentObj, null, 2);
        } else {
            // Show all components of current type
            json = JSON.stringify(componentDatabase[currentType], null, 2);
        }
        
        jsonOutput.textContent = json;
    }
    
    // Initialize with default type
    updateTypeSpecificFields();
});