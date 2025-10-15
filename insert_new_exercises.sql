-- Insertion des nouveaux exercices avec UUIDs générés
-- Date: 2025-10-15

BEGIN;

-- Cable Crossover / Écarté poulie (Chest/Pectoraux)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'a1b2c3d4-e5f6-4789-a0b1-c2d3e4f5a6b7',
  'Cable Crossover',
  'Écarté poulie',
  'Chest',
  'Chest',
  'Pectoraux',
  'Cable machine',
  '',
  false,
  true,
  true
);

-- Burpees (Full body/Corps complet)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'b2c3d4e5-f6a7-4890-b1c2-d3e4f5a6b7c8',
  'Burpees',
  'Burpees',
  'Full body',
  'Full body',
  'Corps complet',
  'Bodyweight',
  '',
  false,
  true,
  true
);

-- Russian Twist (Core/Abdos)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'c3d4e5f6-a7b8-4901-c2d3-e4f5a6b7c8d9',
  'Russian Twist',
  'Russian twist',
  'Core',
  'Core',
  'Abdos',
  'Bodyweight, Medicine ball',
  '',
  false,
  true,
  true
);

-- Running / Course (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'd4e5f6a7-b8c9-4012-d3e4-f5a6b7c8d9e0',
  'Running',
  'Course',
  'Cardio',
  'Cardio',
  'Cardio',
  'None',
  '',
  false,
  true,
  true
);

-- Jump Rope / Corde à sauter (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'e5f6a7b8-c9d0-4123-e4f5-a6b7c8d9e0f1',
  'Jump Rope',
  'Corde à sauter',
  'Cardio',
  'Cardio',
  'Cardio',
  'Jump rope',
  '',
  false,
  true,
  true
);

-- Battle Ropes (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'f6a7b8c9-d0e1-4234-f5a6-b7c8d9e0f1a2',
  'Battle Ropes',
  'Battle ropes',
  'Cardio',
  'Cardio',
  'Cardio',
  'Battle ropes',
  '',
  false,
  true,
  true
);

-- Ski Erg (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'a7b8c9d0-e1f2-4345-a6b7-c8d9e0f1a2b3',
  'Ski Erg',
  'Ski erg',
  'Cardio',
  'Cardio',
  'Cardio',
  'Ski erg machine',
  '',
  false,
  true,
  true
);

-- Assault Bike (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'b8c9d0e1-f2a3-4456-b7c8-d9e0f1a2b3c4',
  'Assault Bike',
  'Assault bike',
  'Cardio',
  'Cardio',
  'Cardio',
  'Assault bike',
  '',
  false,
  true,
  true
);

-- Stair Climber / Montée d'escalier (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'c9d0e1f2-a3b4-4567-c8d9-e0f1a2b3c4d5',
  'Stair Climber',
  'Montée d''escalier',
  'Cardio',
  'Cardio',
  'Cardio',
  'Stair climber machine',
  '',
  false,
  true,
  true
);

-- Elliptical / Elliptique (Cardio)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'd0e1f2a3-b4c5-4678-d9e0-f1a2b3c4d5e6',
  'Elliptical',
  'Elliptique',
  'Cardio',
  'Cardio',
  'Cardio',
  'Elliptical machine',
  '',
  false,
  true,
  true
);

-- Sled Push / Poussée traîneau (Full body/Corps complet)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'e1f2a3b4-c5d6-4789-e0f1-a2b3c4d5e6f7',
  'Sled Push',
  'Poussée traîneau',
  'Full body',
  'Full body',
  'Corps complet',
  'Sled',
  '',
  false,
  true,
  true
);

-- Sled Pull / Traction traîneau (Full body/Corps complet)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'f2a3b4c5-d6e7-4890-f1a2-b3c4d5e6f7a8',
  'Sled Pull',
  'Traction traîneau',
  'Full body',
  'Full body',
  'Corps complet',
  'Sled',
  '',
  false,
  true,
  true
);

-- Tire Flip / Retournement de pneu (Full body/Corps complet)
INSERT INTO exercises (id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment, description, is_custom, is_public, is_verified)
VALUES (
  'a3b4c5d6-e7f8-4901-a2b3-c4d5e6f7a8b9',
  'Tire Flip',
  'Retournement de pneu',
  'Full body',
  'Full body',
  'Corps complet',
  'Tire',
  '',
  false,
  true,
  true
);

COMMIT;

-- Vérification : Afficher les nouveaux exercices
SELECT id, name_en, name_fr, muscle_group, muscle_group_en, muscle_group_fr, equipment
FROM exercises
WHERE id IN (
  'a1b2c3d4-e5f6-4789-a0b1-c2d3e4f5a6b7',
  'b2c3d4e5-f6a7-4890-b1c2-d3e4f5a6b7c8',
  'c3d4e5f6-a7b8-4901-c2d3-e4f5a6b7c8d9',
  'd4e5f6a7-b8c9-4012-d3e4-f5a6b7c8d9e0',
  'e5f6a7b8-c9d0-4123-e4f5-a6b7c8d9e0f1',
  'f6a7b8c9-d0e1-4234-f5a6-b7c8d9e0f1a2',
  'a7b8c9d0-e1f2-4345-a6b7-c8d9e0f1a2b3',
  'b8c9d0e1-f2a3-4456-b7c8-d9e0f1a2b3c4',
  'c9d0e1f2-a3b4-4567-c8d9-e0f1a2b3c4d5',
  'd0e1f2a3-b4c5-4678-d9e0-f1a2b3c4d5e6',
  'e1f2a3b4-c5d6-4789-e0f1-a2b3c4d5e6f7',
  'f2a3b4c5-d6e7-4890-f1a2-b3c4d5e6f7a8',
  'a3b4c5d6-e7f8-4901-a2b3-c4d5e6f7a8b9'
)
ORDER BY muscle_group_en, name_en;

-- Compter le nouveau total d'exercices
SELECT COUNT(*) as total_exercises FROM exercises;
