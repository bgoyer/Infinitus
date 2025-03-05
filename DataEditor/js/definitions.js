/**
 * definitions.js
 * Contains all field definitions, configurations, and constant data for the editor
 */

// List of component file names to load
export const defaultComponentFiles = [
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
export const equipmentTypes = [
    { id: 'thruster', label: 'Thruster' },
    { id: 'turning', label: 'Turning' },
    { id: 'capacitor', label: 'Capacitor' },
    { id: 'generator', label: 'Generator' },
    { id: 'shield', label: 'Shield' },
    { id: 'armor', label: 'Armor' }
];

// Field definitions for each component type
export const fieldDefinitions = {
    ship: {
        specific: [
            { id: 'max_velocity', label: 'Max Velocity', type: 'number', default: 1000 },
            { id: 'max_hull_health', label: 'Max Hull Health', type: 'number', default: 100 },
            { id: 'faction', label: 'Faction', type: 'select', options: ['neutral', 'pirate', 'police', 'trader'], default: 'neutral' },
            { id: 'scene_path', label: 'Scene Path (optional)', type: 'text', default: '' }
        ],
        advanced: [
            { id: 'equipment', label: 'Equipment Configuration', type: 'equipment', default: {} }
        ],
        hardpoints: [
            { id: 'hardpoints', label: 'Hardpoint Locations', type: 'hardpointList', default: [] }
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

// Default empty equipment configuration for ships
export const defaultEquipment = {
    thruster: '',
    turning: '',
    capacitor: '',
    generator: '',
    shield: '',
    armor: '',
    weapons: []
};

// Default ship data for hardpoints
export const defaultShipData = {
    hardpoints: [],
    sprite: null
};

// Default sprite information
export const defaultSpriteInfo = {
    element: null,
    naturalWidth: 0,
    naturalHeight: 0,
    displayWidth: 0,
    displayHeight: 0,
    offsetX: 0,
    offsetY: 0,
    scale: 1
};
