/**
 * form-fields.js
 * Creates and manages form field elements for the editor
 */

/**
 * Create form field based on field definition
 * @param {Object} field - Field definition
 * @returns {HTMLElement} - Form field container element
 */
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
            
        case 'position':
            // Create position editor (x, y coordinates)
            const positionContainer = document.createElement('div');
            positionContainer.className = 'position-editor';
            
            const positionInputs = {};
            
            // X input
            const xLabel = document.createElement('span');
            xLabel.className = 'position-label';
            xLabel.textContent = 'X:';
            positionContainer.appendChild(xLabel);
            
            const xInput = document.createElement('input');
            xInput.type = 'number';
            xInput.value = field.default?.x || 0;
            xInput.dataset.axis = 'x';
            positionInputs.x = xInput;
            positionContainer.appendChild(xInput);
            
            // Y input
            const yLabel = document.createElement('span');
            yLabel.className = 'position-label';
            yLabel.textContent = 'Y:';
            positionContainer.appendChild(yLabel);
            
            const yInput = document.createElement('input');
            yInput.type = 'number';
            yInput.value = field.default?.y || 0;
            yInput.dataset.axis = 'y';
            positionInputs.y = yInput;
            positionContainer.appendChild(yInput);
            
            formGroup.appendChild(positionContainer);
            
            // Store inputs reference for later data retrieval
            input = positionInputs;
            break;
            
        case 'resistances':
            // Create resistances editor for armor
            const resistancesContainer = document.createElement('div');
            resistancesContainer.className = 'resistances-editor';
            
            const resistanceTypes = [
                { id: 'kinetic', label: 'Kinetic' },
                { id: 'energy', label: 'Energy' },
                { id: 'explosive', label: 'Explosive' },
                { id: 'thermal', label: 'Thermal' }
            ];
            
            const resistanceInputs = {};
            
            // Create fields for each resistance type
            resistanceTypes.forEach(type => {
                const row = document.createElement('div');
                row.className = 'resistance-row';
                
                const label = document.createElement('span');
                label.className = 'resistance-label';
                label.textContent = type.label + ':';
                row.appendChild(label);
                
                const resistanceInput = document.createElement('input');
                resistanceInput.type = 'number';
                resistanceInput.className = 'resistance-value';
                resistanceInput.min = 0;
                resistanceInput.step = 0.1;
                resistanceInput.value = field.default?.[type.id] || 1.0;
                resistanceInputs[type.id] = resistanceInput;
                row.appendChild(resistanceInput);
                
                const effectLabel = document.createElement('span');
                
                // Update effect label based on value
                const updateEffectLabel = () => {
                    const value = parseFloat(resistanceInput.value);
                    let effect;
                    
                    if (value < 1.0) {
                        effect = 'Resistant';
                        effectLabel.style.color = '#a6e3a1'; // Green for resistance
                    } else if (value > 1.0) {
                        effect = 'Vulnerable';
                        effectLabel.style.color = '#f38ba8'; // Red for vulnerability
                    } else {
                        effect = 'Neutral';
                        effectLabel.style.color = '#cdd6f4'; // Normal color for neutral
                    }
                    
                    effectLabel.textContent = effect;
                };
                
                resistanceInput.addEventListener('input', updateEffectLabel);
                updateEffectLabel(); // Initial label
                
                row.appendChild(effectLabel);
                resistancesContainer.appendChild(row);
            });
            
            formGroup.appendChild(resistancesContainer);
            
            // Store inputs reference for later data retrieval
            input = resistanceInputs;
            break;
            
        case 'collisionShape':
            // Create collision shape editor
            const collisionShapeContainer = document.createElement('div');
            const collisionShapeEditor = createCollisionShapeEditor(field.default);
            collisionShapeContainer.appendChild(collisionShapeEditor);
            formGroup.appendChild(collisionShapeContainer);
            
            // This field doesn't have a standard input
            input = { type: 'collisionShape' };
            break;
            
        default: // text, number, etc.
            input = document.createElement('input');
            input.type = field.type || 'text';
            input.value = field.default !== undefined ? field.default : '';
            
            if (field.min !== undefined) input.min = field.min;
            if (field.max !== undefined) input.max = field.max;
            if (field.step !== undefined) input.step = field.step;
            if (field.disabled !== undefined) input.disabled = field.disabled;
            break;
    }
    
    // Set common attributes
    if (input.id !== undefined) { // For non-complex fields
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

/**
 * Set form field value from component data
 * @param {string} fieldId - Field ID
 * @param {*} value - Field value
 * @param {string} fieldType - Field type
 */
function setFormFieldValue(fieldId, value, fieldType) {
    const input = document.getElementById(fieldId);
    if (!input) return;
    
    if (fieldType === 'checkbox') {
        input.checked = value || false;
    } else {
        input.value = value !== undefined ? value : '';
    }
}

/**
 * Get form field value
 * @param {string} fieldId - Field ID
 * @param {string} fieldType - Field type
 * @returns {*} - Field value
 */
function getFormFieldValue(fieldId, fieldType) {
    const input = document.getElementById(fieldId);
    if (!input) return null;
    
    if (fieldType === 'checkbox') {
        return input.checked;
    } else if (fieldType === 'number') {
        return parseFloat(input.value);
    } else {
        return input.value;
    }
}

/**
 * Get color field values
 * @param {string} fieldId - Base field ID
 * @returns {Object} - RGBA color object
 */
function getColorFieldValues(fieldId) {
    const colorComponents = ['r', 'g', 'b', 'a'];
    const colorData = {};
    
    colorComponents.forEach(comp => {
        const input = document.querySelector(`input[data-component="${comp}"]`);
        if (input) {
            colorData[comp] = parseFloat(input.value);
        }
    });
    
    return colorData;
}

/**
 * Set color field values
 * @param {Object} colorData - RGBA color object
 */
function setColorFieldValues(colorData) {
    if (!colorData) return;
    
    const colorComponents = ['r', 'g', 'b', 'a'];
    
    colorComponents.forEach(comp => {
        const input = document.querySelector(`input[data-component="${comp}"]`);
        if (input && colorData[comp] !== undefined) {
            input.value = colorData[comp];
        }
    });
    
    // Update preview
    const colorPreview = document.querySelector('.color-preview');
    if (colorPreview) {
        const r = parseFloat(colorData.r || 0);
        const g = parseFloat(colorData.g || 0);
        const b = parseFloat(colorData.b || 0);
        const a = parseFloat(colorData.a || 1);
        
        colorPreview.style.backgroundColor = `rgba(${r*255}, ${g*255}, ${b*255}, ${a})`;
    }
}

/**
 * Get position field values
 * @param {string} fieldId - Base field ID
 * @returns {Object} - Position object with x and y coordinates
 */
function getPositionFieldValues(fieldId) {
    const positionData = { x: 0, y: 0 };
    
    const xInput = document.querySelector(`input[data-axis="x"]`);
    const yInput = document.querySelector(`input[data-axis="y"]`);
    
    if (xInput) positionData.x = parseInt(xInput.value) || 0;
    if (yInput) positionData.y = parseInt(yInput.value) || 0;
    
    return positionData;
}

/**
 * Set position field values
 * @param {Object} positionData - Position object with x and y coordinates
 */
function setPositionFieldValues(positionData) {
    if (!positionData) return;
    
    const xInput = document.querySelector(`input[data-axis="x"]`);
    const yInput = document.querySelector(`input[data-axis="y"]`);
    
    if (xInput) xInput.value = positionData.x || 0;
    if (yInput) yInput.value = positionData.y || 0;
}

/**
 * Get resistances field values
 * @returns {Object} - Resistances object with resistance values by type
 */
function getResistancesFieldValues() {
    const resistanceTypes = ['kinetic', 'energy', 'explosive', 'thermal'];
    const resistances = {};
    
    resistanceTypes.forEach(type => {
        const input = document.querySelector(`.resistance-row .resistance-value[data-type="${type}"]`);
        if (input) {
            resistances[type] = parseFloat(input.value) || 1.0;
        } else {
            // Try to find by traversing the DOM structure
            const inputs = document.querySelectorAll('.resistance-value');
            if (inputs.length > 0) {
                const index = resistanceTypes.indexOf(type);
                if (index >= 0 && index < inputs.length) {
                    resistances[type] = parseFloat(inputs[index].value) || 1.0;
                } else {
                    resistances[type] = 1.0; // Default value
                }
            } else {
                resistances[type] = 1.0; // Default value
            }
        }
    });
    
    return resistances;
}

/**
 * Set resistances field values
 * @param {Object} resistancesData - Resistances object with values by type
 */
function setResistancesFieldValues(resistancesData) {
    if (!resistancesData) return;
    
    const resistanceTypes = ['kinetic', 'energy', 'explosive', 'thermal'];
    
    resistanceTypes.forEach((type, index) => {
        const input = document.querySelector(`.resistance-row .resistance-value[data-type="${type}"]`);
        if (input && resistancesData[type] !== undefined) {
            input.value = resistancesData[type];
            // Trigger input event to update labels
            input.dispatchEvent(new Event('input'));
        } else {
            // Try to find by traversing the DOM structure
            const inputs = document.querySelectorAll('.resistance-value');
            if (inputs.length > 0 && index < inputs.length && resistancesData[type] !== undefined) {
                inputs[index].value = resistancesData[type];
                // Trigger input event to update labels
                inputs[index].dispatchEvent(new Event('input'));
            }
        }
    });
}

/**
 * Create type-specific fields for a component type
 * @param {string} componentType - Component type
 * @param {HTMLElement} specificTabContent - Container for specific fields
 * @param {HTMLElement} advancedTabContent - Container for advanced fields
 */
function createTypeSpecificFields(componentType, specificTabContent, advancedTabContent) {
    // Clear current fields
    specificTabContent.innerHTML = '';
    advancedTabContent.innerHTML = '';
    
    // Get field definitions for current type
    const specificFields = fieldDefinitions[componentType].specific || [];
    const advancedFields = fieldDefinitions[componentType].advanced || [];
    
    // Add specific fields
    specificFields.forEach(field => {
        const formGroup = createFormField(field);
        specificTabContent.appendChild(formGroup);
    });
    
    // Add advanced fields (excluding equipment which is handled separately)
    advancedFields.forEach(field => {
        if (field.type !== 'equipment') {
            const formGroup = createFormField(field);
            advancedTabContent.appendChild(formGroup);
        }
    });
}

/**
 * Clear all form fields
 * @param {string} componentType - Current component type
 */
function clearFormFields(componentType) {
    // Reset basic fields
    document.getElementById('name').value = '';
    document.getElementById('description').value = '';
    document.getElementById('mass').value = '10';
    document.getElementById('value').value = '100';
    document.getElementById('volume').value = '5';
    
    // Reset specific fields
    const specificFields = fieldDefinitions[componentType].specific || [];
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
    const advancedFields = fieldDefinitions[componentType].advanced || [];
    advancedFields.forEach(field => {
        if (field.type === 'color') {
            // Handle color fields
            const colorComponents = ['r', 'g', 'b', 'a'];
            colorComponents.forEach(comp => {
                const input = document.querySelector(`input[data-component="${comp}"]`);
                if (input) {
                    input.value = field.default[comp] || 0;
                }
            });
            
            // Update preview
            const colorPreview = document.querySelector('.color-preview');
            if (colorPreview) {
                const r = parseFloat(field.default.r || 0);
                const g = parseFloat(field.default.g || 0);
                const b = parseFloat(field.default.b || 0);
                const a = parseFloat(field.default.a || 1);
                
                colorPreview.style.backgroundColor = `rgba(${r*255}, ${g*255}, ${b*255}, ${a})`;
            }
        } else if (field.type === 'position') {
            // Handle position fields
            setPositionFieldValues(field.default || { x: 0, y: 0 });
        } else if (field.type === 'resistances') {
            // Handle resistances fields
            setResistancesFieldValues(field.default || {
                kinetic: 1.0,
                energy: 1.0,
                explosive: 1.0,
                thermal: 1.0
            });
        } else if (field.type === 'collisionShape') {
            // Handle collision shape
            const shapeData = field.default || { type: 'rectangle', size: { x: 100, y: 100 } };
            setCollisionShapeData(shapeData);
        } else if (field.type !== 'equipment') {
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

/**
 * Collect form field data for a component
 * @param {string} type - Component type
 * @param {string} id - Component ID
 * @returns {Object} - Collected component data
 */
function collectFormData(type, id) {
    // Prepare data object
    const data = {
        name: document.getElementById('name').value,
        description: document.getElementById('description').value,
        mass: parseInt(document.getElementById('mass').value),
        value: parseInt(document.getElementById('value').value),
        volume: parseInt(document.getElementById('volume').value)
    };
    
    // Add specific fields
    const specificFields = fieldDefinitions[type].specific || [];
    specificFields.forEach(field => {
        if (field.type === 'position') {
            data[field.id] = getPositionFieldValues(field.id);
        } else if (field.type === 'color') {
            data[field.id] = getColorFieldValues(field.id);
        } else {
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
    
    // Add advanced fields
    const advancedFields = fieldDefinitions[type].advanced || [];
    advancedFields.forEach(field => {
        if (field.type === 'equipment') {
            // Equipment is handled separately
            return;
        }
        
        if (field.type === 'color') {
            // Handle color fields
            data[field.id] = getColorFieldValues(field.id);
        } else if (field.type === 'position') {
            // Handle position fields
            data[field.id] = getPositionFieldValues(field.id);
        } else if (field.type === 'resistances') {
            // Handle resistances
            data[field.id] = getResistancesFieldValues();
        } else if (field.type === 'collisionShape') {
            // Handle collision shape
            data[field.id] = getCollisionShapeData();
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
    if (type === 'weapon') {
        const weaponType = document.getElementById('type').value;
        
        // Rename specific fields based on weapon type
        if (weaponType === 'gun') {
            const gunSpreadAngle = document.getElementById('spread_angle');
            if (gunSpreadAngle) {
                data.spread_angle = parseFloat(gunSpreadAngle.value);
            }
        } else if (weaponType === 'turret') {
            const rotationSpeed = document.getElementById('rotation_speed');
            const aimAheadFactor = document.getElementById('aim_ahead_factor');
            const fireArc = document.getElementById('fire_arc');
            const baseInaccuracy = document.getElementById('base_inaccuracy');
            
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
            const salvoSize = document.getElementById('salvo_size');
            
            if (trackingTime) data.missile_tracking_time = parseFloat(trackingTime.value);
            if (turningSpeed) data.missile_turning_speed = parseFloat(turningSpeed.value);
            if (acceleration) data.missile_acceleration = parseFloat(acceleration.value);
            if (maxSpeed) data.missile_max_speed = parseFloat(maxSpeed.value);
            if (blastRadius) data.missile_blast_radius = parseFloat(blastRadius.value);
            if (salvoSize) data.salvo_size = parseInt(salvoSize.value);
        }
    }
    
    return data;
}