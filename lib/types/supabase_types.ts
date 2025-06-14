export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      cardio_activities: {
        Row: {
          activity_type: string
          created_at: string | null
          id: string
          is_custom: boolean | null
          name_en: string
          name_fr: string
          user_id: string | null
        }
        Insert: {
          activity_type: string
          created_at?: string | null
          id?: string
          is_custom?: boolean | null
          name_en: string
          name_fr: string
          user_id?: string | null
        }
        Update: {
          activity_type?: string
          created_at?: string | null
          id?: string
          is_custom?: boolean | null
          name_en?: string
          name_fr?: string
          user_id?: string | null
        }
        Relationships: []
      }
      cardio_sessions: {
        Row: {
          activity_title: string
          activity_type: string
          average_speed_kmh: number | null
          calories: number | null
          created_at: string | null
          current_speed_kmh: number | null
          distance_km: number | null
          duration_seconds: number | null
          end_time: string | null
          format_title: string
          id: string
          is_paused: boolean | null
          is_running: boolean | null
          notes: string | null
          start_time: string
          steps: number | null
          target_distance_km: number | null
          target_duration_seconds: number | null
          user_id: string
        }
        Insert: {
          activity_title: string
          activity_type: string
          average_speed_kmh?: number | null
          calories?: number | null
          created_at?: string | null
          current_speed_kmh?: number | null
          distance_km?: number | null
          duration_seconds?: number | null
          end_time?: string | null
          format_title: string
          id?: string
          is_paused?: boolean | null
          is_running?: boolean | null
          notes?: string | null
          start_time: string
          steps?: number | null
          target_distance_km?: number | null
          target_duration_seconds?: number | null
          user_id: string
        }
        Update: {
          activity_title?: string
          activity_type?: string
          average_speed_kmh?: number | null
          calories?: number | null
          created_at?: string | null
          current_speed_kmh?: number | null
          distance_km?: number | null
          duration_seconds?: number | null
          end_time?: string | null
          format_title?: string
          id?: string
          is_paused?: boolean | null
          is_running?: boolean | null
          notes?: string | null
          start_time?: string
          steps?: number | null
          target_distance_km?: number | null
          target_duration_seconds?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "cardio_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      exercise_sets: {
        Row: {
          created_at: string | null
          id: string
          is_completed: boolean | null
          reps: number
          set_order: number
          weight: number
          workout_exercise_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          is_completed?: boolean | null
          reps: number
          set_order?: number
          weight: number
          workout_exercise_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          is_completed?: boolean | null
          reps?: number
          set_order?: number
          weight?: number
          workout_exercise_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "exercise_sets_workout_exercise_id_fkey"
            columns: ["workout_exercise_id"]
            isOneToOne: false
            referencedRelation: "workout_exercises"
            referencedColumns: ["id"]
          },
        ]
      }
      exercises: {
        Row: {
          created_at: string | null
          description: string | null
          equipment: string | null
          id: string
          is_custom: boolean | null
          muscle_group: string
          name_en: string
          name_fr: string
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          equipment?: string | null
          id?: string
          is_custom?: boolean | null
          muscle_group: string
          name_en: string
          name_fr: string
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          equipment?: string | null
          id?: string
          is_custom?: boolean | null
          muscle_group?: string
          name_en?: string
          name_fr?: string
          user_id?: string | null
        }
        Relationships: []
      }
      foods: {
        Row: {
          calories: number
          carbs: number
          category: string | null
          created_at: string | null
          fats: number
          id: string
          is_custom: boolean | null
          name_en: string
          name_fr: string
          proteins: number
          user_id: string | null
        }
        Insert: {
          calories: number
          carbs?: number
          category?: string | null
          created_at?: string | null
          fats?: number
          id?: string
          is_custom?: boolean | null
          name_en: string
          name_fr: string
          proteins?: number
          user_id?: string | null
        }
        Update: {
          calories?: number
          carbs?: number
          category?: string | null
          created_at?: string | null
          fats?: number
          id?: string
          is_custom?: boolean | null
          name_en?: string
          name_fr?: string
          proteins?: number
          user_id?: string | null
        }
        Relationships: []
      }
      hiit_sessions: {
        Row: {
          created_at: string | null
          current_phase: string | null
          current_round: number | null
          end_time: string | null
          id: string
          is_completed: boolean | null
          start_time: string
          user_id: string
          workout_id: string | null
        }
        Insert: {
          created_at?: string | null
          current_phase?: string | null
          current_round?: number | null
          end_time?: string | null
          id?: string
          is_completed?: boolean | null
          start_time: string
          user_id: string
          workout_id?: string | null
        }
        Update: {
          created_at?: string | null
          current_phase?: string | null
          current_round?: number | null
          end_time?: string | null
          id?: string
          is_completed?: boolean | null
          start_time?: string
          user_id?: string
          workout_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "hiit_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      hiit_workouts: {
        Row: {
          created_at: string | null
          description_en: string | null
          description_fr: string | null
          id: string
          is_custom: boolean | null
          rest_duration: number
          title_en: string
          title_fr: string
          total_duration: number
          total_rounds: number
          user_id: string | null
          work_duration: number
        }
        Insert: {
          created_at?: string | null
          description_en?: string | null
          description_fr?: string | null
          id?: string
          is_custom?: boolean | null
          rest_duration: number
          title_en: string
          title_fr: string
          total_duration: number
          total_rounds: number
          user_id?: string | null
          work_duration: number
        }
        Update: {
          created_at?: string | null
          description_en?: string | null
          description_fr?: string | null
          id?: string
          is_custom?: boolean | null
          rest_duration?: number
          title_en?: string
          title_fr?: string
          total_duration?: number
          total_rounds?: number
          user_id?: string | null
          work_duration?: number
        }
        Relationships: []
      }
      location_points: {
        Row: {
          altitude: number | null
          cardio_session_id: string | null
          created_at: string | null
          id: string
          latitude: number
          longitude: number
          recorded_at: string
          speed_kmh: number | null
        }
        Insert: {
          altitude?: number | null
          cardio_session_id?: string | null
          created_at?: string | null
          id?: string
          latitude: number
          longitude: number
          recorded_at: string
          speed_kmh?: number | null
        }
        Update: {
          altitude?: number | null
          cardio_session_id?: string | null
          created_at?: string | null
          id?: string
          latitude?: number
          longitude?: number
          recorded_at?: string
          speed_kmh?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "location_points_cardio_session_id_fkey"
            columns: ["cardio_session_id"]
            isOneToOne: false
            referencedRelation: "cardio_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_food_items: {
        Row: {
          calories: number
          created_at: string | null
          food_id: string | null
          id: string
          meal_id: string | null
          portion: string
        }
        Insert: {
          calories: number
          created_at?: string | null
          food_id?: string | null
          id?: string
          meal_id?: string | null
          portion: string
        }
        Update: {
          calories?: number
          created_at?: string | null
          food_id?: string | null
          id?: string
          meal_id?: string | null
          portion?: string
        }
        Relationships: [
          {
            foreignKeyName: "meal_food_items_meal_id_fkey"
            columns: ["meal_id"]
            isOneToOne: false
            referencedRelation: "meals"
            referencedColumns: ["id"]
          },
        ]
      }
      meals: {
        Row: {
          created_at: string | null
          date: string
          id: string
          meal_time: string
          name: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          date: string
          id?: string
          meal_time: string
          name: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          date?: string
          id?: string
          meal_time?: string
          name?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "meals_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      recipes: {
        Row: {
          created_at: string | null
          difficulty: string | null
          duration: string | null
          id: string
          image_url: string | null
          ingredients: Json
          is_custom: boolean | null
          name_en: string
          name_fr: string
          servings: number
          steps_en: string[]
          steps_fr: string[]
          tags: string[] | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          difficulty?: string | null
          duration?: string | null
          id?: string
          image_url?: string | null
          ingredients: Json
          is_custom?: boolean | null
          name_en: string
          name_fr: string
          servings: number
          steps_en: string[]
          steps_fr: string[]
          tags?: string[] | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          difficulty?: string | null
          duration?: string | null
          id?: string
          image_url?: string | null
          ingredients?: Json
          is_custom?: boolean | null
          name_en?: string
          name_fr?: string
          servings?: number
          steps_en?: string[]
          steps_fr?: string[]
          tags?: string[] | null
          user_id?: string | null
        }
        Relationships: []
      }
      users: {
        Row: {
          created_at: string | null
          email: string | null
          id: string
          is_onboarded: boolean | null
          name: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          email?: string | null
          id: string
          is_onboarded?: boolean | null
          name?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          email?: string | null
          id?: string
          is_onboarded?: boolean | null
          name?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      workout_exercises: {
        Row: {
          created_at: string | null
          exercise_id: string | null
          id: string
          order_index: number
          session_id: string | null
        }
        Insert: {
          created_at?: string | null
          exercise_id?: string | null
          id?: string
          order_index?: number
          session_id?: string | null
        }
        Update: {
          created_at?: string | null
          exercise_id?: string | null
          id?: string
          order_index?: number
          session_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "workout_exercises_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "workout_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      workout_sessions: {
        Row: {
          created_at: string | null
          end_time: string | null
          id: string
          is_completed: boolean | null
          name: string
          start_time: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          end_time?: string | null
          id?: string
          is_completed?: boolean | null
          name: string
          start_time: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          end_time?: string | null
          id?: string
          is_completed?: boolean | null
          name?: string
          start_time?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "workout_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      simplified_data_stats: {
        Row: {
          custom_count: number | null
          data_type: string | null
          global_count: number | null
          total_count: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      get_cardio_activities_localized: {
        Args: { user_language?: string }
        Returns: {
          id: string
          activity_type: string
          name: string
          is_custom: boolean
          user_id: string
        }[]
      }
      get_exercises_localized: {
        Args: { user_language?: string }
        Returns: {
          id: string
          name: string
          muscle_group: string
          equipment: string
          description: string
          is_custom: boolean
          user_id: string
        }[]
      }
      get_foods_localized: {
        Args: { user_language?: string }
        Returns: {
          id: string
          name: string
          calories: number
          proteins: number
          carbs: number
          fats: number
          category: string
          is_custom: boolean
          user_id: string
        }[]
      }
      get_hiit_workouts_localized: {
        Args: { user_language?: string }
        Returns: {
          id: string
          title: string
          description: string
          work_duration: number
          rest_duration: number
          total_duration: number
          total_rounds: number
          is_custom: boolean
          user_id: string
        }[]
      }
      get_recipes_localized: {
        Args: { user_language?: string }
        Returns: {
          id: string
          name: string
          ingredients: Json
          steps: string[]
          image_url: string
          duration: string
          servings: number
          difficulty: string
          tags: string[]
          is_custom: boolean
          user_id: string
        }[]
      }
      get_user_cardio_history: {
        Args: { target_user_id: string; start_date?: string; end_date?: string }
        Returns: {
          session_id: string
          session_date: string
          activity_type: string
          activity_title: string
          start_time: string
          end_time: string
          duration_minutes: number
          distance_km: number
          average_speed_kmh: number
          steps: number
          calories: number
          notes: string
        }[]
      }
      get_user_daily_summary: {
        Args: { target_user_id: string; target_date?: string }
        Returns: {
          summary_date: string
          total_meals: number
          total_calories_nutrition: number
          workout_sessions: number
          hiit_sessions: number
          cardio_sessions: number
          total_calories_burned: number
        }[]
      }
      get_user_hiit_history: {
        Args: { target_user_id: string; start_date?: string; end_date?: string }
        Returns: {
          session_id: string
          session_date: string
          workout_title: string
          start_time: string
          end_time: string
          duration_minutes: number
          current_round: number
          total_rounds: number
          is_completed: boolean
        }[]
      }
      get_user_nutrition_history: {
        Args: { target_user_id: string; start_date?: string; end_date?: string }
        Returns: {
          meal_id: string
          meal_date: string
          meal_time: string
          meal_name: string
          food_name: string
          portion: string
          calories: number
          created_at: string
        }[]
      }
      get_user_workout_history: {
        Args: { target_user_id: string; start_date?: string; end_date?: string }
        Returns: {
          session_id: string
          session_name: string
          session_date: string
          start_time: string
          end_time: string
          duration_minutes: number
          exercise_name: string
          sets_count: number
          total_reps: number
          total_weight: number
          is_completed: boolean
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const 