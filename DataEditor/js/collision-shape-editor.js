/**
 * collision-shape-editor.js
 * Manages the ship collision shape editor functionality
 */

/**
 * Create a form field for collision shape editor
 * @param {Object} collisionShape - Current collision shape data
 * @param {Function} onChange - Callback when collision shape changes
 * @returns {HTMLElement} - Collision shape editor form
 */
function createCollisionShapeEditor(collisionShape = null, onChange = null) {
    const container = document.createElement('div');
    container.className = 'collision-shape-editor';
    
    // Default to rectangle if no shape provided
    if (!collisionShape) {
        collisionShape = { type: 'rectangle', size: { x: 100, y: 100 } };
    }
    
    // Shape type selector
    const typeContainer = document.createElement('div');
    typeContainer.className = 'form-group';
    
    const typeLabel = document.createElement('label');
    typeLabel.textContent = 'Collision Shape Type:';
    typeContainer.appendChild(typeLabel);
    
    const typeSelect = document.createElement('select');
    typeSelect.id = 'collision-shape-type';
    
    // Add shape type options
    collisionShapeTypes.forEach(shapeType => {
        const option = document.createElement('option');
        option.value = shapeType.id;
        option.textContent = shapeType.label;
        typeSelect.appendChild(option);
    });
    
    // Set current shape type
    typeSelect.value = collisionShape.type || 'rectangle';
    
    typeContainer.appendChild(typeSelect);
    container.appendChild(typeContainer);
    
    // Properties container (will be updated based on type)
    const propertiesContainer = document.createElement('div');
    propertiesContainer.id = 'collision-shape-properties';
    container.appendChild(propertiesContainer);
    
    // Preview container
    const previewContainer = document.createElement('div');
    previewContainer.className = 'collision-shape-preview-container';
    
    const previewLabel = document.createElement('label');
    previewLabel.textContent = 'Shape Preview:';
    previewContainer.appendChild(previewLabel);
    
    const preview = document.createElement('div');
    preview.className = 'collision-shape-preview';
    preview.id = 'collision-shape-preview';
    previewContainer.appendChild(preview);
    
    container.appendChild(previewContainer);
    
    // Function to update shape properties form
    const updateShapeProperties = () => {
        const shapeType = typeSelect.value;
        propertiesContainer.innerHTML = '';
        
        if (shapeType === 'rectangle') {
            // Rectangle properties (width and height)
            const widthContainer = document.createElement('div');
            widthContainer.className = 'form-group';
            
            const widthLabel = document.createElement('label');
            widthLabel.textContent = 'Width (X):';
            widthContainer.appendChild(widthLabel);
            
            const widthInput = document.createElement('input');
            widthInput.type = 'number';
            widthInput.id = 'collision-shape-width';
            widthInput.min = 1;
            widthInput.value = collisionShape.size?.x || 100;
            
            widthInput.addEventListener('change', () => {
                collisionShape.size = collisionShape.size || {};
                collisionShape.size.x = parseInt(widthInput.value) || 100;
                updatePreview();
                if (onChange) onChange(collisionShape);
            });
            
            widthContainer.appendChild(widthInput);
            propertiesContainer.appendChild(widthContainer);
            
            const heightContainer = document.createElement('div');
            heightContainer.className = 'form-group';
            
            const heightLabel = document.createElement('label');
            heightLabel.textContent = 'Height (Y):';
            heightContainer.appendChild(heightLabel);
            
            const heightInput = document.createElement('input');
            heightInput.type = 'number';
            heightInput.id = 'collision-shape-height';
            heightInput.min = 1;
            heightInput.value = collisionShape.size?.y || 100;
            
            heightInput.addEventListener('change', () => {
                collisionShape.size = collisionShape.size || {};
                collisionShape.size.y = parseInt(heightInput.value) || 100;
                updatePreview();
                if (onChange) onChange(collisionShape);
            });
            
            heightContainer.appendChild(heightInput);
            propertiesContainer.appendChild(heightContainer);
            
        } else if (shapeType === 'circle') {
            // Circle properties (radius)
            const radiusContainer = document.createElement('div');
            radiusContainer.className = 'form-group';
            
            const radiusLabel = document.createElement('label');
            radiusLabel.textContent = 'Radius:';
            radiusContainer.appendChild(radiusLabel);
            
            const radiusInput = document.createElement('input');
            radiusInput.type = 'number';
            radiusInput.id = 'collision-shape-radius';
            radiusInput.min = 1;
            radiusInput.value = collisionShape.radius || 50;
            
            radiusInput.addEventListener('change', () => {
                collisionShape.radius = parseInt(radiusInput.value) || 50;
                updatePreview();
                if (onChange) onChange(collisionShape);
            });
            
            radiusContainer.appendChild(radiusInput);
            propertiesContainer.appendChild(radiusContainer);
        }
    };
    
    // Function to update the preview
    const updatePreview = () => {
        const preview = document.getElementById('collision-shape-preview');
        if (!preview) return;
        
        preview.innerHTML = '';
        
        // Save current shape type
        collisionShape.type = typeSelect.value;
        
        // Check if we have a ship sprite to use as background
        let backgroundImage = null;
        if (currentShipData && currentShipData.sprite) {
            backgroundImage = currentShipData.sprite;
        }
        
        if (backgroundImage) {
            // Create background sprite image
            const bgImg = document.createElement('img');
            bgImg.src = backgroundImage;
            bgImg.className = 'collision-shape-bg-image';
            bgImg.style.maxWidth = '100%';
            bgImg.style.maxHeight = '100%';
            bgImg.style.objectFit = 'contain';
            bgImg.style.position = 'absolute';
            bgImg.style.top = '50%';
            bgImg.style.left = '50%';
            bgImg.style.transform = 'translate(-50%, -50%)';
            bgImg.style.opacity = '0.5';
            preview.appendChild(bgImg);
        }
        
        if (collisionShape.type === 'rectangle') {
            const width = collisionShape.size?.x || 100;
            const height = collisionShape.size?.y || 100;
            
            // Scale down for preview
            const maxPreviewSize = 200;
            const scale = Math.min(maxPreviewSize / width, maxPreviewSize / height);
            
            const displayWidth = width * scale;
            const displayHeight = height * scale;
            
            // Create rectangle shape
            const rect = document.createElement('div');
            rect.className = 'preview-shape rectangle';
            rect.style.width = `${displayWidth}px`;
            rect.style.height = `${displayHeight}px`;
            rect.style.position = 'absolute';
            rect.style.top = '50%';
            rect.style.left = '50%';
            rect.style.transform = 'translate(-50%, -50%)';
            
            preview.appendChild(rect);
            
        } else if (collisionShape.type === 'circle') {
            const radius = collisionShape.radius || 50;
            
            // Scale down for preview
            const maxPreviewSize = 200;
            const scale = maxPreviewSize / (radius * 2);
            
            const displayRadius = radius * scale;
            
            // Create circle shape
            const circle = document.createElement('div');
            circle.className = 'preview-shape circle';
            circle.style.width = `${displayRadius * 2}px`;
            circle.style.height = `${displayRadius * 2}px`;
            circle.style.borderRadius = '50%';
            circle.style.position = 'absolute';
            circle.style.top = '50%';
            circle.style.left = '50%';
            circle.style.transform = 'translate(-50%, -50%)';
            
            preview.appendChild(circle);
        }
    };
    
    // Handle shape type change
    typeSelect.addEventListener('change', () => {
        const newType = typeSelect.value;
        
        // Update collision shape type
        collisionShape.type = newType;
        
        // Initialize properties for the shape type
        if (newType === 'rectangle') {
            collisionShape.size = collisionShape.size || { x: 100, y: 100 };
            // Remove circle properties
            delete collisionShape.radius;
        } else if (newType === 'circle') {
            collisionShape.radius = collisionShape.radius || 50;
            // Remove rectangle properties
            delete collisionShape.size;
        }
        
        // Update properties form and preview
        updateShapeProperties();
        updatePreview();
        
        // Notify of change
        if (onChange) onChange(collisionShape);
    });
    
    // Initialize
    updateShapeProperties();
    updatePreview();
    
    return container;
}

/**
 * Get collision shape data
 * @param {Object} data - Current form data
 * @returns {Object} - Collision shape data
 */
function getCollisionShapeData() {
    const typeSelect = document.getElementById('collision-shape-type');
    if (!typeSelect) return { type: 'rectangle', size: { x: 100, y: 100 } };
    
    const shapeType = typeSelect.value;
    let shapeData = { type: shapeType };
    
    if (shapeType === 'rectangle') {
        const widthInput = document.getElementById('collision-shape-width');
        const heightInput = document.getElementById('collision-shape-height');
        
        shapeData.size = {
            x: parseInt(widthInput?.value) || 100,
            y: parseInt(heightInput?.value) || 100
        };
    } else if (shapeType === 'circle') {
        const radiusInput = document.getElementById('collision-shape-radius');
        shapeData.radius = parseInt(radiusInput?.value) || 50;
    }
    
    return shapeData;
}

/**
 * Set collision shape data in form
 * @param {Object} shapeData - Collision shape data
 */
function setCollisionShapeData(shapeData) {
    if (!shapeData) return;
    
    const typeSelect = document.getElementById('collision-shape-type');
    if (!typeSelect) return;
    
    // Set shape type
    typeSelect.value = shapeData.type || 'rectangle';
    
    // Trigger change event to update properties form
    typeSelect.dispatchEvent(new Event('change'));
    
    // Set shape properties
    if (shapeData.type === 'rectangle' && shapeData.size) {
        const widthInput = document.getElementById('collision-shape-width');
        const heightInput = document.getElementById('collision-shape-height');
        
        if (widthInput) widthInput.value = shapeData.size.x || 100;
        if (heightInput) heightInput.value = shapeData.size.y || 100;
    } else if (shapeData.type === 'circle') {
        const radiusInput = document.getElementById('collision-shape-radius');
        if (radiusInput) radiusInput.value = shapeData.radius || 50;
    }
    
    // Update preview
    const preview = document.getElementById('collision-shape-preview');
    if (preview) {
        // Trigger a redraw
        const event = new Event('change');
        if (shapeData.type === 'rectangle') {
            const widthInput = document.getElementById('collision-shape-width');
            if (widthInput) widthInput.dispatchEvent(event);
        } else if (shapeData.type === 'circle') {
            const radiusInput = document.getElementById('collision-shape-radius');
            if (radiusInput) radiusInput.dispatchEvent(event);
        }
    }
}

/**
 * Update the collision shape preview with the ship sprite
 */
function updateCollisionShapePreview() {
    const preview = document.getElementById('collision-shape-preview');
    if (!preview) return;
    
    // Remove existing background image if any
    const existingBg = preview.querySelector('.collision-shape-bg-image');
    if (existingBg) {
        existingBg.remove();
    }
    
    // Check if we have a ship sprite to use as background
    if (currentShipData && currentShipData.sprite) {
        // Create background sprite image
        const bgImg = document.createElement('img');
        bgImg.src = currentShipData.sprite;
        bgImg.className = 'collision-shape-bg-image';
        bgImg.style.maxWidth = '100%';
        bgImg.style.maxHeight = '100%';
        bgImg.style.objectFit = 'contain';
        bgImg.style.position = 'absolute';
        bgImg.style.top = '50%';
        bgImg.style.left = '50%';
        bgImg.style.transform = 'translate(-50%, -50%)';
        bgImg.style.opacity = '0.5';
        
        // Insert before any other children to be in background
        if (preview.firstChild) {
            preview.insertBefore(bgImg, preview.firstChild);
        } else {
            preview.appendChild(bgImg);
        }
    }
}