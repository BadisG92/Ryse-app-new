"""
Exercises Dataset - Comprehensive collection of exercises for strength, cardio, and flexibility
Each exercise includes detailed instructions, muscle groups, and difficulty levels
"""

EXERCISES_DATASET = [
    # Chest Exercises
    {
        "name": "Push-ups",
        "category": "strength",
        "muscle_group": "chest",
        "secondary_muscles": ["shoulders", "triceps", "core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start in a plank position with hands slightly wider than shoulder-width",
            "Keep your body in a straight line from head to heels",
            "Lower your chest toward the floor by bending your elbows",
            "Push back up to the starting position",
            "Keep your core engaged throughout the movement"
        ],
        "tips": [
            "Keep your elbows at a 45-degree angle to your body",
            "Don't let your hips sag or pike up",
            "Breathe in on the way down, out on the way up"
        ],
        "calories_per_minute": 8,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Bench Press",
        "category": "strength",
        "muscle_group": "chest",
        "secondary_muscles": ["shoulders", "triceps"],
        "equipment": "barbell",
        "difficulty": "intermediate",
        "instructions": [
            "Lie flat on the bench with feet firmly on the floor",
            "Grip the barbell with hands slightly wider than shoulder-width",
            "Unrack the bar and position it over your chest",
            "Lower the bar to your chest with control",
            "Press the bar back up to the starting position"
        ],
        "tips": [
            "Keep your shoulder blades retracted",
            "Maintain a slight arch in your back",
            "Don't bounce the bar off your chest"
        ],
        "calories_per_minute": 6,
        "duration_minutes": 1,
        "sets": 4,
        "reps": 8,
        "rest_seconds": 90,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Back Exercises
    {
        "name": "Pull-ups",
        "category": "strength",
        "muscle_group": "back",
        "secondary_muscles": ["biceps", "shoulders"],
        "equipment": "pull_up_bar",
        "difficulty": "intermediate",
        "instructions": [
            "Hang from a pull-up bar with palms facing away",
            "Start with arms fully extended",
            "Pull your body up until your chin clears the bar",
            "Lower yourself back down with control",
            "Repeat for desired reps"
        ],
        "tips": [
            "Engage your lats and squeeze your shoulder blades",
            "Avoid swinging or using momentum",
            "Focus on controlled movement"
        ],
        "calories_per_minute": 10,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 6,
        "rest_seconds": 90,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Bent-over Row",
        "category": "strength",
        "muscle_group": "back",
        "secondary_muscles": ["biceps", "shoulders"],
        "equipment": "barbell",
        "difficulty": "intermediate",
        "instructions": [
            "Stand with feet hip-width apart, holding a barbell",
            "Hinge at the hips and lean forward about 45 degrees",
            "Keep your back straight and core engaged",
            "Pull the bar toward your lower chest/upper abdomen",
            "Lower the bar back down with control"
        ],
        "tips": [
            "Keep your elbows close to your body",
            "Squeeze your shoulder blades together at the top",
            "Don't round your back"
        ],
        "calories_per_minute": 7,
        "duration_minutes": 1,
        "sets": 4,
        "reps": 10,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Leg Exercises
    {
        "name": "Squats",
        "category": "strength",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand with feet shoulder-width apart",
            "Keep your chest up and core engaged",
            "Lower your body by bending at the hips and knees",
            "Go down until your thighs are parallel to the floor",
            "Push through your heels to return to standing"
        ],
        "tips": [
            "Keep your knees in line with your toes",
            "Don't let your knees cave inward",
            "Keep your weight on your heels"
        ],
        "calories_per_minute": 9,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 15,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Deadlifts",
        "category": "strength",
        "muscle_group": "legs",
        "secondary_muscles": ["back", "glutes", "core"],
        "equipment": "barbell",
        "difficulty": "advanced",
        "instructions": [
            "Stand with feet hip-width apart, bar over mid-foot",
            "Bend at the hips and knees to grip the bar",
            "Keep your back straight and chest up",
            "Drive through your heels and hips to lift the bar",
            "Stand tall, then lower the bar back down"
        ],
        "tips": [
            "Keep the bar close to your body",
            "Don't round your back",
            "Engage your lats to keep the bar close"
        ],
        "calories_per_minute": 8,
        "duration_minutes": 1,
        "sets": 4,
        "reps": 6,
        "rest_seconds": 120,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Lunges",
        "category": "strength",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand tall with feet hip-width apart",
            "Step forward with one leg",
            "Lower your body until both knees are at 90 degrees",
            "Push back to the starting position",
            "Repeat with the other leg"
        ],
        "tips": [
            "Keep your torso upright",
            "Don't let your front knee go past your toes",
            "Step far enough forward for proper form"
        ],
        "calories_per_minute": 8,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Shoulder Exercises
    {
        "name": "Shoulder Press",
        "category": "strength",
        "muscle_group": "shoulders",
        "secondary_muscles": ["triceps", "core"],
        "equipment": "dumbbells",
        "difficulty": "intermediate",
        "instructions": [
            "Stand or sit with dumbbells at shoulder height",
            "Keep your core engaged and back straight",
            "Press the weights overhead until arms are fully extended",
            "Lower the weights back to shoulder height",
            "Repeat for desired reps"
        ],
        "tips": [
            "Don't arch your back excessively",
            "Keep your wrists straight",
            "Control the weight on the way down"
        ],
        "calories_per_minute": 6,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Lateral Raises",
        "category": "strength",
        "muscle_group": "shoulders",
        "secondary_muscles": [],
        "equipment": "dumbbells",
        "difficulty": "beginner",
        "instructions": [
            "Stand with dumbbells at your sides",
            "Keep a slight bend in your elbows",
            "Raise the weights out to the sides",
            "Lift until your arms are parallel to the floor",
            "Lower the weights back down slowly"
        ],
        "tips": [
            "Don't use momentum to lift the weights",
            "Keep your shoulders down and back",
            "Focus on controlled movement"
        ],
        "calories_per_minute": 5,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Arm Exercises
    {
        "name": "Bicep Curls",
        "category": "strength",
        "muscle_group": "arms",
        "secondary_muscles": [],
        "equipment": "dumbbells",
        "difficulty": "beginner",
        "instructions": [
            "Stand with dumbbells at your sides",
            "Keep your elbows close to your body",
            "Curl the weights up toward your shoulders",
            "Squeeze your biceps at the top",
            "Lower the weights back down slowly"
        ],
        "tips": [
            "Don't swing the weights",
            "Keep your wrists straight",
            "Focus on the bicep contraction"
        ],
        "calories_per_minute": 4,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Tricep Dips",
        "category": "strength",
        "muscle_group": "arms",
        "secondary_muscles": ["shoulders", "chest"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Sit on the edge of a chair or bench",
            "Place your hands beside your hips",
            "Slide your body off the edge",
            "Lower your body by bending your elbows",
            "Push back up to the starting position"
        ],
        "tips": [
            "Keep your elbows pointing backward",
            "Don't go too low if you feel shoulder discomfort",
            "Keep your body close to the chair"
        ],
        "calories_per_minute": 7,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Core Exercises
    {
        "name": "Plank",
        "category": "strength",
        "muscle_group": "core",
        "secondary_muscles": ["shoulders", "back"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start in a push-up position",
            "Lower down to your forearms",
            "Keep your body in a straight line",
            "Hold this position",
            "Breathe normally throughout"
        ],
        "tips": [
            "Don't let your hips sag or pike up",
            "Keep your core tight",
            "Look down to keep your neck neutral"
        ],
        "calories_per_minute": 5,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 1,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Crunches",
        "category": "strength",
        "muscle_group": "core",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Lie on your back with knees bent",
            "Place your hands behind your head",
            "Lift your shoulders off the ground",
            "Squeeze your abs at the top",
            "Lower back down slowly"
        ],
        "tips": [
            "Don't pull on your neck",
            "Focus on using your abs",
            "Keep your lower back on the ground"
        ],
        "calories_per_minute": 4,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 15,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Mountain Climbers",
        "category": "cardio",
        "muscle_group": "core",
        "secondary_muscles": ["shoulders", "legs"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Start in a plank position",
            "Bring one knee toward your chest",
            "Quickly switch legs",
            "Continue alternating legs rapidly",
            "Keep your core engaged throughout"
        ],
        "tips": [
            "Keep your hips level",
            "Don't let your form break down",
            "Maintain a steady rhythm"
        ],
        "calories_per_minute": 12,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 20,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Cardio Exercises
    {
        "name": "Jumping Jacks",
        "category": "cardio",
        "muscle_group": "full_body",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand with feet together and arms at your sides",
            "Jump while spreading your legs shoulder-width apart",
            "Simultaneously raise your arms overhead",
            "Jump back to the starting position",
            "Repeat at a steady pace"
        ],
        "tips": [
            "Land softly on the balls of your feet",
            "Keep your core engaged",
            "Maintain good posture throughout"
        ],
        "calories_per_minute": 10,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 30,
        "rest_seconds": 30,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Burpees",
        "category": "cardio",
        "muscle_group": "full_body",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "advanced",
        "instructions": [
            "Start standing with feet shoulder-width apart",
            "Squat down and place hands on the floor",
            "Jump your feet back into a plank position",
            "Do a push-up (optional)",
            "Jump your feet back to squat position",
            "Jump up with arms overhead"
        ],
        "tips": [
            "Move at your own pace",
            "Modify by stepping instead of jumping",
            "Keep your core engaged throughout"
        ],
        "calories_per_minute": 15,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 8,
        "rest_seconds": 90,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "High Knees",
        "category": "cardio",
        "muscle_group": "legs",
        "secondary_muscles": ["core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand with feet hip-width apart",
            "Run in place lifting your knees high",
            "Aim to bring knees up to hip level",
            "Pump your arms as you run",
            "Maintain a quick pace"
        ],
        "tips": [
            "Stay on the balls of your feet",
            "Keep your core tight",
            "Maintain good posture"
        ],
        "calories_per_minute": 11,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 30,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Flexibility/Stretching
    {
        "name": "Downward Dog",
        "category": "flexibility",
        "muscle_group": "full_body",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start on hands and knees",
            "Tuck your toes under",
            "Lift your hips up and back",
            "Straighten your legs as much as possible",
            "Hold the position and breathe deeply"
        ],
        "tips": [
            "Keep your hands shoulder-width apart",
            "Press through your palms",
            "Pedal your feet to stretch your calves"
        ],
        "calories_per_minute": 3,
        "duration_minutes": 1,
        "sets": 1,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Child's Pose",
        "category": "flexibility",
        "muscle_group": "back",
        "secondary_muscles": ["shoulders"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start on hands and knees",
            "Sit back on your heels",
            "Extend your arms forward on the ground",
            "Lower your forehead to the floor",
            "Hold and breathe deeply"
        ],
        "tips": [
            "Relax your shoulders",
            "Breathe into your back",
            "Hold for as long as comfortable"
        ],
        "calories_per_minute": 2,
        "duration_minutes": 1,
        "sets": 1,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Hamstring Stretch",
        "category": "flexibility",
        "muscle_group": "legs",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Sit on the floor with one leg extended",
            "Bend the other leg with foot against inner thigh",
            "Reach forward toward your extended foot",
            "Hold the stretch",
            "Switch legs and repeat"
        ],
        "tips": [
            "Keep your back straight",
            "Don't bounce",
            "Breathe deeply during the stretch"
        ],
        "calories_per_minute": 2,
        "duration_minutes": 1,
        "sets": 2,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Additional Strength Exercises
    {
        "name": "Incline Push-ups",
        "category": "strength",
        "muscle_group": "chest",
        "secondary_muscles": ["shoulders", "triceps"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Place hands on an elevated surface (bench, step, etc.)",
            "Keep body in straight line from head to heels",
            "Lower chest toward the elevated surface",
            "Push back up to starting position",
            "Keep core engaged throughout"
        ],
        "tips": [
            "Higher elevation = easier exercise",
            "Keep elbows at 45-degree angle",
            "Control the movement"
        ],
        "calories_per_minute": 6,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Diamond Push-ups",
        "category": "strength",
        "muscle_group": "arms",
        "secondary_muscles": ["chest", "shoulders"],
        "equipment": "bodyweight",
        "difficulty": "advanced",
        "instructions": [
            "Start in push-up position",
            "Form diamond shape with hands under chest",
            "Lower body while keeping elbows close",
            "Push back up to starting position",
            "Maintain straight body line"
        ],
        "tips": [
            "Focus on tricep engagement",
            "Keep core tight",
            "Modify on knees if needed"
        ],
        "calories_per_minute": 9,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 8,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Pike Push-ups",
        "category": "strength",
        "muscle_group": "shoulders",
        "secondary_muscles": ["triceps", "core"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Start in downward dog position",
            "Walk feet closer to hands",
            "Lower head toward ground",
            "Push back up to pike position",
            "Keep legs as straight as possible"
        ],
        "tips": [
            "Great shoulder builder",
            "Progress toward handstand push-ups",
            "Keep weight on hands"
        ],
        "calories_per_minute": 8,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 8,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Bulgarian Split Squats",
        "category": "strength",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Stand 2 feet in front of a bench",
            "Place rear foot on bench behind you",
            "Lower into lunge position",
            "Push through front heel to return up",
            "Complete all reps before switching legs"
        ],
        "tips": [
            "Keep most weight on front leg",
            "Don't push off back foot",
            "Maintain upright torso"
        ],
        "calories_per_minute": 9,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Single-Leg Glute Bridges",
        "category": "strength",
        "muscle_group": "glutes",
        "secondary_muscles": ["hamstrings", "core"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Lie on back with knees bent",
            "Extend one leg straight out",
            "Lift hips up squeezing glutes",
            "Lower with control",
            "Complete all reps before switching legs"
        ],
        "tips": [
            "Squeeze glutes at the top",
            "Keep core engaged",
            "Don't arch your back"
        ],
        "calories_per_minute": 6,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Wall Sit",
        "category": "strength",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand with back against wall",
            "Slide down until thighs parallel to floor",
            "Keep knees at 90 degrees",
            "Hold position",
            "Keep back flat against wall"
        ],
        "tips": [
            "Breathe normally during hold",
            "Keep weight on heels",
            "Start with shorter holds"
        ],
        "calories_per_minute": 5,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 1,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Russian Twists",
        "category": "strength",
        "muscle_group": "core",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Sit with knees bent, feet off ground",
            "Lean back slightly, keep chest up",
            "Rotate torso left and right",
            "Touch ground beside hips",
            "Keep feet elevated throughout"
        ],
        "tips": [
            "Keep core engaged",
            "Control the rotation",
            "Add weight for more challenge"
        ],
        "calories_per_minute": 7,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 20,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Dead Bug",
        "category": "strength",
        "muscle_group": "core",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Lie on back, arms up toward ceiling",
            "Knees bent at 90 degrees",
            "Lower opposite arm and leg slowly",
            "Return to starting position",
            "Alternate sides"
        ],
        "tips": [
            "Keep lower back pressed to floor",
            "Move slowly and controlled",
            "Breathe throughout movement"
        ],
        "calories_per_minute": 4,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Bird Dog",
        "category": "strength",
        "muscle_group": "core",
        "secondary_muscles": ["back", "glutes"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start on hands and knees",
            "Extend opposite arm and leg",
            "Hold for a few seconds",
            "Return to starting position",
            "Alternate sides"
        ],
        "tips": [
            "Keep hips level",
            "Don't arch your back",
            "Focus on balance and control"
        ],
        "calories_per_minute": 4,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # More Cardio Exercises
    {
        "name": "Jump Squats",
        "category": "cardio",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Start in squat position",
            "Jump up explosively",
            "Land softly back in squat",
            "Immediately go into next rep",
            "Keep chest up throughout"
        ],
        "tips": [
            "Land softly on balls of feet",
            "Use arms for momentum",
            "Keep knees aligned with toes"
        ],
        "calories_per_minute": 12,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 15,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Butt Kickers",
        "category": "cardio",
        "muscle_group": "legs",
        "secondary_muscles": ["core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand with feet hip-width apart",
            "Run in place kicking heels to glutes",
            "Keep knees pointing down",
            "Pump arms naturally",
            "Maintain quick pace"
        ],
        "tips": [
            "Stay on balls of feet",
            "Keep core engaged",
            "Focus on heel-to-glute contact"
        ],
        "calories_per_minute": 10,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 30,
        "rest_seconds": 45,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Skaters",
        "category": "cardio",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Start standing on one leg",
            "Leap sideways to other leg",
            "Land softly, swing arms across body",
            "Immediately leap back to other side",
            "Continue alternating sides"
        ],
        "tips": [
            "Land on one foot each time",
            "Use arms for balance and momentum",
            "Keep chest up and core engaged"
        ],
        "calories_per_minute": 11,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 20,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Star Jumps",
        "category": "cardio",
        "muscle_group": "full_body",
        "secondary_muscles": [],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start in squat position",
            "Jump up spreading arms and legs wide",
            "Form star shape in air",
            "Land back in squat position",
            "Repeat immediately"
        ],
        "tips": [
            "Land softly in squat",
            "Fully extend arms and legs",
            "Keep core engaged"
        ],
        "calories_per_minute": 13,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Plank Jacks",
        "category": "cardio",
        "muscle_group": "core",
        "secondary_muscles": ["shoulders", "legs"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Start in plank position",
            "Jump feet apart like jumping jack",
            "Jump feet back together",
            "Keep plank position throughout",
            "Maintain steady rhythm"
        ],
        "tips": [
            "Keep hips level",
            "Don't let hips sag",
            "Land softly on balls of feet"
        ],
        "calories_per_minute": 9,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 20,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # More Flexibility/Yoga Exercises
    {
        "name": "Cat-Cow Stretch",
        "category": "flexibility",
        "muscle_group": "back",
        "secondary_muscles": ["core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Start on hands and knees",
            "Arch back and look up (cow)",
            "Round back and tuck chin (cat)",
            "Flow smoothly between positions",
            "Breathe with the movement"
        ],
        "tips": [
            "Move slowly and controlled",
            "Breathe deeply",
            "Feel the stretch through spine"
        ],
        "calories_per_minute": 3,
        "duration_minutes": 1,
        "sets": 1,
        "reps": 10,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Cobra Stretch",
        "category": "flexibility",
        "muscle_group": "back",
        "secondary_muscles": ["chest"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Lie face down on floor",
            "Place palms under shoulders",
            "Press up lifting chest",
            "Keep hips on ground",
            "Hold and breathe deeply"
        ],
        "tips": [
            "Don't overextend",
            "Keep shoulders away from ears",
            "Feel stretch in front body"
        ],
        "calories_per_minute": 2,
        "duration_minutes": 1,
        "sets": 1,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Pigeon Pose",
        "category": "flexibility",
        "muscle_group": "legs",
        "secondary_muscles": ["hips"],
        "equipment": "bodyweight",
        "difficulty": "intermediate",
        "instructions": [
            "Start in downward dog",
            "Bring right knee to right wrist",
            "Extend left leg back",
            "Lower hips toward ground",
            "Hold, then switch sides"
        ],
        "tips": [
            "Use props if needed",
            "Don't force the stretch",
            "Breathe deeply and relax"
        ],
        "calories_per_minute": 2,
        "duration_minutes": 2,
        "sets": 2,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Warrior I",
        "category": "flexibility",
        "muscle_group": "legs",
        "secondary_muscles": ["core", "shoulders"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Step left foot back 3-4 feet",
            "Turn left foot out 45 degrees",
            "Bend right knee over ankle",
            "Raise arms overhead",
            "Hold, then switch sides"
        ],
        "tips": [
            "Keep front knee over ankle",
            "Square hips forward",
            "Reach up through fingertips"
        ],
        "calories_per_minute": 3,
        "duration_minutes": 1,
        "sets": 2,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Triangle Pose",
        "category": "flexibility",
        "muscle_group": "legs",
        "secondary_muscles": ["back", "core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Stand with feet wide apart",
            "Turn right foot out 90 degrees",
            "Reach right hand toward floor",
            "Extend left arm toward ceiling",
            "Hold, then switch sides"
        ],
        "tips": [
            "Keep both legs straight",
            "Don't put weight on bottom hand",
            "Look up at top hand if comfortable"
        ],
        "calories_per_minute": 3,
        "duration_minutes": 1,
        "sets": 2,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Seated Spinal Twist",
        "category": "flexibility",
        "muscle_group": "back",
        "secondary_muscles": ["core"],
        "equipment": "bodyweight",
        "difficulty": "beginner",
        "instructions": [
            "Sit with legs extended",
            "Cross right foot over left leg",
            "Place right hand behind you",
            "Twist spine to the right",
            "Hold, then switch sides"
        ],
        "tips": [
            "Sit up tall",
            "Twist from the core",
            "Breathe deeply during twist"
        ],
        "calories_per_minute": 2,
        "duration_minutes": 1,
        "sets": 2,
        "reps": 1,
        "rest_seconds": 0,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    
    # Equipment-based Exercises
    {
        "name": "Dumbbell Rows",
        "category": "strength",
        "muscle_group": "back",
        "secondary_muscles": ["biceps"],
        "equipment": "dumbbells",
        "difficulty": "intermediate",
        "instructions": [
            "Hinge at hips holding dumbbells",
            "Keep back straight, core engaged",
            "Pull weights to lower ribs",
            "Squeeze shoulder blades together",
            "Lower with control"
        ],
        "tips": [
            "Don't round your back",
            "Lead with elbows",
            "Feel the squeeze between shoulder blades"
        ],
        "calories_per_minute": 7,
        "duration_minutes": 1,
        "sets": 4,
        "reps": 10,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Goblet Squats",
        "category": "strength",
        "muscle_group": "legs",
        "secondary_muscles": ["glutes", "core"],
        "equipment": "dumbbells",
        "difficulty": "beginner",
        "instructions": [
            "Hold dumbbell at chest level",
            "Stand with feet shoulder-width apart",
            "Squat down keeping chest up",
            "Go down until thighs parallel",
            "Drive through heels to stand"
        ],
        "tips": [
            "Keep weight close to chest",
            "Don't let knees cave in",
            "Keep core engaged"
        ],
        "calories_per_minute": 8,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 60,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Chest Flyes",
        "category": "strength",
        "muscle_group": "chest",
        "secondary_muscles": ["shoulders"],
        "equipment": "dumbbells",
        "difficulty": "intermediate",
        "instructions": [
            "Lie on bench holding dumbbells",
            "Start with arms extended over chest",
            "Lower weights in wide arc",
            "Feel stretch in chest",
            "Bring weights back together"
        ],
        "tips": [
            "Keep slight bend in elbows",
            "Control the weight",
            "Focus on chest squeeze"
        ],
        "calories_per_minute": 6,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 12,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Overhead Press",
        "category": "strength",
        "muscle_group": "shoulders",
        "secondary_muscles": ["triceps", "core"],
        "equipment": "dumbbells",
        "difficulty": "intermediate",
        "instructions": [
            "Stand holding dumbbells at shoulders",
            "Keep core engaged",
            "Press weights straight overhead",
            "Lower back to shoulder level",
            "Maintain neutral spine"
        ],
        "tips": [
            "Don't arch back excessively",
            "Press in straight line",
            "Keep core tight"
        ],
        "calories_per_minute": 6,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 10,
        "rest_seconds": 75,
        "image_url": None,
        "video_url": None,
        "is_public": True
    },
    {
        "name": "Renegade Rows",
        "category": "strength",
        "muscle_group": "back",
        "secondary_muscles": ["core", "shoulders"],
        "equipment": "dumbbells",
        "difficulty": "advanced",
        "instructions": [
            "Start in plank holding dumbbells",
            "Row one weight to ribs",
            "Lower with control",
            "Row other arm",
            "Keep hips level throughout"
        ],
        "tips": [
            "Don't rotate hips",
            "Keep core super tight",
            "Use lighter weights"
        ],
        "calories_per_minute": 10,
        "duration_minutes": 1,
        "sets": 3,
        "reps": 8,
        "rest_seconds": 90,
        "image_url": None,
        "video_url": None,
        "is_public": True
    }
]

def get_exercises_dataset():
    """Return the complete exercises dataset"""
    return EXERCISES_DATASET

def get_exercises_by_category(category):
    """Get exercises filtered by category"""
    return [ex for ex in EXERCISES_DATASET if ex['category'] == category]

def get_exercises_by_muscle_group(muscle_group):
    """Get exercises filtered by muscle group"""
    return [ex for ex in EXERCISES_DATASET if ex['muscle_group'] == muscle_group]

def get_exercises_by_equipment(equipment):
    """Get exercises filtered by equipment"""
    return [ex for ex in EXERCISES_DATASET if ex['equipment'] == equipment]

def get_exercises_by_difficulty(difficulty):
    """Get exercises filtered by difficulty"""
    return [ex for ex in EXERCISES_DATASET if ex['difficulty'] == difficulty]

if __name__ == "__main__":
    exercises = get_exercises_dataset()
    print(f"Generated {len(exercises)} exercises")
    print("\nExercises by category:")
    categories = set(ex['category'] for ex in exercises)
    for category in categories:
        count = len(get_exercises_by_category(category))
        print(f"  {category}: {count} exercises")
    
    print("\nSample exercises:")
    for i, exercise in enumerate(exercises[:5]):
        print(f"{i+1}. {exercise['name']} ({exercise['category']}) - {exercise['muscle_group']}") 