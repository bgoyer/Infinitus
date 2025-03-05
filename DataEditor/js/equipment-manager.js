/**
 * equipment-manager.js
 * Handles ship equipment configuration functionality
 */

// Current equipment configuration state
let currentEquipment = { ...defaultEquipment };

/**
 * Reset equipment configuration to default
 */
function resetEquipment() {
    currentEquipment = {
        thruster: '',
        turning: '',
        capacitor: '',
        generator: '',
        shield: '',
        armor: '',
        weapons: []
    };
}

/**
 * Get current equipment configuration
 * @returns {Object} - Current equipment configuration
 */
function getEquipment() {
    return { ...currentEquipment };
}

/**
 * Set equipment configuration
 * @param {Object} equipment - Equipment configuration to set
 */
function setEquipment(equipment) {
    if (!equipment) return;
    
    resetEquipment();
    
    // Copy equipment properties
    equipmentTypes.forEach(eqType => {
        if (equipment[eqType.id]) {
            currentEquipment[eqType.id] = equipment[eqType.id];
        }
    });
    
    // Copy weapons array
    if (equipment.weapons && Array.isArray(equipment.weapons)) {
        currentEquipment.weapons = [...equipment.weapons];
    }
}

/**
 * Create equipment selector for ships
 * @param {Function} onChange - Callback for when equipment changes
 * @returns {HTMLElement} - Equipment selector element
 */
function createEquipmentSelector(onChange) {
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
            if (onChange) onChange();
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
    
    // Render weapons
    renderWeapons(weaponsList, onChange);
    
    equipmentContainer.appendChild(weaponsContainer);
    
    return container;
}

/**
 * Render weapons list
 * @param {HTMLElement} weaponsList - Container for weapons list
 * @param {Function} onChange - Callback for when weapons change
 */
function renderWeapons(weaponsList, onChange) {
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
                if (onChange) onChange();
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
                if (onChange) onChange();
            });
            
            const removeButton = document.createElement('button');
            removeButton.className = 'remove-equipment-btn';
            removeButton.textContent = 'X';
            removeButton.addEventListener('click', () => {
                currentEquipment.weapons.splice(index, 1);
                renderWeapons(weaponsList, onChange);
                if (onChange) onChange();
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
        renderWeapons(weaponsList, onChange);
        if (onChange) onChange();
    });
    
    weaponsList.appendChild(addWeaponBtn);
}

/**
 * Update equipment selectors with current values
 */
function updateEquipmentSelectors() {
    // Update equipment select values
    equipmentTypes.forEach(eqType => {
        const selector = document.getElementById(`equipment-${eqType.id}`);
        if (selector) {
            selector.value = currentEquipment[eqType.id] || '';
        }
    });
    
    // Update weapons list
    const weaponsList = document.getElementById('weapons-list');
    if (weaponsList) {
        renderWeapons(weaponsList, () => updateJsonOutput());
    }
}

/**
 * Rebuild equipment selectors after loading new component data
 */
function rebuildEquipmentSelectors() {
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
        renderWeapons(weaponsList, () => updateJsonOutput());
    }
}

/**
 * Get equipment data for saving
 * @returns {Object|null} - Equipment data object or null if empty
 */
function getEquipmentData() {
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
    
    // Return null if no equipment configured
    if (Object.keys(equipment).length === 0) {
        return null;
    }
    
    return equipment;
}