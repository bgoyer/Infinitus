/**
 * definitions.js
 * Contains all field definitions, configurations, and constant data for the editor
 */

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

// Equipment types for ship configuration
const equipmentTypes = [
    { id: 'thruster', label: 'Thruster' },
    { id: 'turning', label: 'Turning' },
    { id: 'capacitor', label: 'Capacitor' },
    { id: 'generator', label: 'Generator' },
    { id: 'shield', label: 'Shield' },
    { id: 'armor', label: 'Armor' }
];

// Field definitions for each component type
const fieldDefinitions = {
    ship: {
        specific: [
            { id: 'max_velocity', label: 'Max Velocity', type: 'number', default: 1000 },
            { id: 'max_hull_health', label: 'Max Hull Health', type: 'number', default: 100 },
            { id: 'faction', label: 'Faction', type: 'select', options: ['neutral', 'pirate', 'police', 'trader', 'player'], default: 'neutral' },
            { id: 'sprite_texture', label: 'Sprite Texture Name', type: 'text', default: '' },
            { id: 'sprite_scale', label: 'Sprite Scale', type: 'number', default: 1.0, step: 0.1 },
            { id: 'scene_path', label: 'Scene Path (optional)', type: 'text', default: '' }
        ],
        advanced: [
            { id: 'equipment', label: 'Equipment Configuration', type: 'equipment', default: {} },
            { id: 'collision_shape', label: 'Collision Shape', type: 'collisionShape', default: { type: 'rectangle', size: {x: 100, y: 100} } },
            { id: 'health_component', label: 'Has Health Component', type: 'checkbox', default: true },
            { id: 'energy_component', label: 'Has Energy Component', type: 'checkbox', default: true },
            { id: 'max_energy', label: 'Max Energy', type: 'number', default: 100 },
            { id: 'energy_recharge_rate', label: 'Energy Recharge Rate', type: 'number', default: 10 },
            { id: 'shield_max', label: 'Shield Max', type: 'number', default: 50 },
            { id: 'shield_recharge_rate', label: 'Shield Recharge Rate', type: 'number', default: 5 },
            { id: 'armor_value', label: 'Armor Value', type: 'number', default: 5 },
            { id: 'tracked', label: 'Is Tracked on HUD', type: 'checkbox', default: true },
            { id: 'indicator_name', label: 'HUD Indicator Name', type: 'text', default: '' },
            { id: 'indicator_color', label: 'HUD Indicator Color', type: 'color', default: { r: 0.2, g: 0.6, b: 1.0, a: 1.0 } }
        ],
        hardpoints: [
            { id: 'hardpoints', label: 'Hardpoint Locations', type: 'hardpointList', default: [] }
        ],
        enginePoints: [
            { id: 'engine_points', label: 'Engine Point Locations', type: 'enginePointList', default: [] }
        ]
    },
    capacitor: {
        specific: [
            { id: 'type', label: 'Type', type: 'text', default: 'capacitor', disabled: true },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Energy Capacitor' },
            { id: 'max_capacity', label: 'Max Capacity', type: 'number', default: 100 },
            { id: 'discharge_efficiency', label: 'Discharge Efficiency', type: 'number', default: 1.0, step: 0.05 },
            { id: 'recharge_efficiency', label: 'Recharge Efficiency', type: 'number', default: 1.0, step: 0.05 },
            { id: 'discharge_rate_limit', label: 'Discharge Rate Limit', type: 'number', default: 50.0 }
        ],
        advanced: []
    },
    generator: {
        specific: [
            { id: 'type', label: 'Type', type: 'text', default: 'generator', disabled: true },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Power Generator' },
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
            { id: 'type', label: 'Type', type: 'text', default: 'shield', disabled: true },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Shield Generator' },
            { id: 'max_shield', label: 'Max Shield Points', type: 'number', default: 50 },
            { id: 'recharge_rate', label: 'Recharge Rate (points/s)', type: 'number', default: 5.0 },
            { id: 'recharge_delay', label: 'Recharge Delay (s)', type: 'number', default: 3.0, step: 0.1 },
            { id: 'energy_drain', label: 'Energy Drain (per second)', type: 'number', default: 1.0, step: 0.1 }
        ],
        advanced: [
            { id: 'hit_energy_cost', label: 'Energy Cost per Hit Point', type: 'number', default: 2.0, step: 0.1 },
            { id: 'projectile_reflection_chance', label: 'Projectile Reflection Chance', type: 'number', default: 0, min: 0, max: 1, step: 0.01 },
            { id: 'damage_conversion', label: 'Damage to Energy Conversion', type: 'number', default: 0, min: 0, max: 1, step: 0.01 },
            { id: 'shield_color', label: 'Shield Color', type: 'color', default: { r: 0.3, g: 0.5, b: 1.0, a: 0.7 } },
            { id: 'shield_texture', label: 'Shield Texture', type: 'text', default: 'shield_bubble' },
            { id: 'shield_scale', label: 'Shield Scale', type: 'number', default: 1.2, step: 0.1 }
        ]
    },
    armor: {
        specific: [
            { id: 'type', label: 'Type', type: 'text', default: 'armor', disabled: true },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Hull Plating' },
            { id: 'armor_rating', label: 'Armor Rating', type: 'number', default: 10 },
            { id: 'damage_threshold', label: 'Damage Threshold', type: 'number', default: 5 },
            { id: 'max_absorption', label: 'Max Absorption (0-1)', type: 'number', default: 0.8, min: 0, max: 1, step: 0.05 }
        ],
        advanced: [
            { id: 'resistances', label: 'Damage Resistances', type: 'resistances', default: {
                kinetic: 1.0,
                energy: 1.0,
                explosive: 1.0,
                thermal: 1.0
            }}
        ]
    },
    thruster: {
        specific: [
            { id: 'type', label: 'Type', type: 'text', default: 'thruster', disabled: true },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Standard Thruster' },
            { id: 'thrust', label: 'Thrust', type: 'number', default: 25 },
            { id: 'drain', label: 'Energy Drain', type: 'number', default: 1 },
            { id: 'capacitor_need', label: 'Capacitor Need', type: 'number', default: 1 }
        ],
        advanced: []
    },
    turning: {
        specific: [
            { id: 'type', label: 'Type', type: 'text', default: 'turning', disabled: true },
            { id: 'equipment_name', label: 'Equipment Name', type: 'text', default: 'Standard Turning System' },
            { id: 'thrust', label: 'Turning Force', type: 'number', default: 4 },
            { id: 'drain', label: 'Energy Drain', type: 'number', default: 1 },
            { id: 'capacitor_need', label: 'Capacitor Need', type: 'number', default: 1 }
        ],
        advanced: []
    },
    weapon: {
        specific: [
            { id: 'type', label: 'Weapon Type', type: 'select', options: ['gun', 'turret', 'missile_launcher'], default: 'gun' },
            { id: 'weapon_name', label: 'Weapon Name', type: 'text', default: 'Generic Weapon' },
            { id: 'damage', label: 'Damage', type: 'number', default: 10 },
            { id: 'fire_rate', label: 'Fire Rate (shots/s)', type: 'number', default: 1.0, step: 0.1 },
            { id: 'range_distance', label: 'Range', type: 'number', default: 1000.0 },
            { id: 'projectile_speed', label: 'Projectile Speed', type: 'number', default: 800.0 },
            { id: 'energy_cost', label: 'Energy Cost per Shot', type: 'number', default: 5 }
        ],
        advanced: [
            { id: 'accuracy', label: 'Accuracy (0-1)', type: 'number', default: 1.0, min: 0, max: 1, step: 0.05 },
            { id: 'auto_target', label: 'Auto Target', type: 'checkbox', default: false },
            { id: 'ammo_capacity', label: 'Ammo Capacity (-1 for unlimited)', type: 'number', default: -1 },
            { id: 'sprite', label: 'Weapon Sprite', type: 'text', default: 'weapon_sprite' },
            { id: 'projectile_sprite', label: 'Projectile Sprite', type: 'text', default: 'projectile_sprite' },
            { id: 'muzzle_position', label: 'Muzzle Position', type: 'position', default: {x: 0, y: -20} },
            
            // Gun-specific
            { id: 'spread_angle', label: 'Spread Angle (Gun)', type: 'number', default: 0.0, showIf: {field: 'type', value: 'gun'} },
            
            // Turret-specific
            { id: 'rotation_speed', label: 'Rotation Speed (Turret)', type: 'number', default: 3.0, showIf: {field: 'type', value: 'turret'} },
            { id: 'aim_ahead_factor', label: 'Aim Ahead Factor (Turret)', type: 'number', default: 1.0, step: 0.1, showIf: {field: 'type', value: 'turret'} },
            { id: 'fire_arc', label: 'Fire Arc (Turret)', type: 'number', default: 180.0, showIf: {field: 'type', value: 'turret'} },
            { id: 'base_inaccuracy', label: 'Base Inaccuracy (Turret)', type: 'number', default: 0.1, min: 0, max: 1, step: 0.05, showIf: {field: 'type', value: 'turret'} },
            { id: 'inaccuracy_from_movement', label: 'Inaccuracy from Movement (Turret)', type: 'number', default: 0.2, min: 0, max: 1, step: 0.05, showIf: {field: 'type', value: 'turret'} },
            
            // Missile launcher-specific
            { id: 'missile_tracking_time', label: 'Tracking Time (Missile)', type: 'number', default: 5.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_turning_speed', label: 'Turning Speed (Missile)', type: 'number', default: 2.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_acceleration', label: 'Acceleration (Missile)', type: 'number', default: 100.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_max_speed', label: 'Max Speed (Missile)', type: 'number', default: 500.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'missile_blast_radius', label: 'Blast Radius (Missile)', type: 'number', default: 50.0, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'salvo_size', label: 'Salvo Size (Missile)', type: 'number', default: 1, min: 1, showIf: {field: 'type', value: 'missile_launcher'} },
            { id: 'salvo_delay', label: 'Salvo Delay (Missile)', type: 'number', default: 0.1, showIf: {field: 'type', value: 'missile_launcher'} }
        ]
    },
    fleet: {
        specific: [
            { id: 'name', label: 'Fleet Name', type: 'text', default: 'New Fleet' },
            { id: 'faction', label: 'Faction', type: 'select', options: ['neutral', 'pirate', 'police', 'trader', 'player'], default: 'neutral' },
            { id: 'flagship', label: 'Flagship Ship ID', type: 'text', default: '' },
            { id: 'formation', label: 'Formation Type', type: 'select', 
              options: ['line', 'v_formation', 'wedge', 'circle', 'square'], default: 'v_formation' },
            { id: 'formation_spacing', label: 'Formation Spacing', type: 'number', default: 200.0 },
            { id: 'default_behavior', label: 'Default Behavior', type: 'select', 
              options: ['defensive', 'offensive', 'patrol', 'trade', 'aggressive'], default: 'defensive' }
        ],
        advanced: [
            { id: 'ships', label: 'Fleet Ships', type: 'shipList', default: [] }
        ]
    }
};

// Default empty equipment configuration for ships
const defaultEquipment = {
    thruster: '',
    turning: '',
    capacitor: '',
    generator: '',
    shield: '',
    armor: '',
    weapons: []
};

// Default ship data for hardpoints and engine points
const defaultShipData = {
    hardpoints: [],
    engine_points: [],
    sprite: null
};

// Default sprite information
const defaultSpriteInfo = {
    element: null,
    naturalWidth: 0,
    naturalHeight: 0,
    displayWidth: 0,
    displayHeight: 0,
    offsetX: 0,
    offsetY: 0,
    scale: 1
};

// Collision shape types
const collisionShapeTypes = [
    { id: 'rectangle', label: 'Rectangle' },
    { id: 'circle', label: 'Circle' }
];