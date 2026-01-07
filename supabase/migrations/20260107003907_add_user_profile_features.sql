-- Location: supabase/migrations/20260107003907_add_user_profile_features.sql
-- Schema Analysis: Existing tables - user_profiles, memes, meme_likes
-- Integration Type: Extension - Adding followers and achievements to existing user system
-- Dependencies: user_profiles, memes

-- Step 1: Add bio column to existing user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN bio TEXT DEFAULT '';

-- Step 2: Create user_follows table for followers/following functionality
CREATE TABLE public.user_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- Step 3: Create user_achievements table for achievement badges
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    achievement_name TEXT NOT NULL,
    achievement_description TEXT NOT NULL,
    is_unlocked BOOLEAN DEFAULT false,
    progress INTEGER DEFAULT 0,
    required_count INTEGER DEFAULT 0,
    unlocked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Step 4: Create indexes
CREATE INDEX idx_user_follows_follower_id ON public.user_follows(follower_id);
CREATE INDEX idx_user_follows_following_id ON public.user_follows(following_id);
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_type ON public.user_achievements(achievement_type);

-- Step 5: Enable RLS
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- Step 6: RLS Policies

-- User follows policies - users can view all follows, manage their own
CREATE POLICY "public_can_read_user_follows"
ON public.user_follows
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_follows"
ON public.user_follows
FOR ALL
TO authenticated
USING (follower_id = auth.uid())
WITH CHECK (follower_id = auth.uid());

-- User achievements policies - users can view all achievements, system manages them
CREATE POLICY "public_can_read_user_achievements"
ON public.user_achievements
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Step 7: Functions for automatic achievement unlocking
CREATE OR REPLACE FUNCTION public.check_and_unlock_achievement()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.user_achievements
    SET 
        is_unlocked = true,
        unlocked_at = CURRENT_TIMESTAMP
    WHERE 
        user_id = NEW.user_id
        AND achievement_type = NEW.achievement_type
        AND is_unlocked = false
        AND progress >= required_count;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_achievement_progress_update
AFTER UPDATE OF progress ON public.user_achievements
FOR EACH ROW
EXECUTE FUNCTION public.check_and_unlock_achievement();

-- Step 8: Function to initialize default achievements for users
CREATE OR REPLACE FUNCTION public.initialize_user_achievements()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_achievements (user_id, achievement_type, achievement_name, achievement_description, required_count)
    VALUES
        (NEW.id, 'first_meme', 'First Meme', 'Create your first meme', 1),
        (NEW.id, 'viral_creator', 'Viral Creator', 'Get 100 likes on a single meme', 100),
        (NEW.id, 'ai_master', 'AI Master', 'Generate 50 memes with AI', 50),
        (NEW.id, 'social_butterfly', 'Social Butterfly', 'Get 100 followers', 100),
        (NEW.id, 'prolific_creator', 'Prolific Creator', 'Create 100 memes', 100);
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_user_profile_create
AFTER INSERT ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION public.initialize_user_achievements();

-- Step 9: Mock data for existing users
DO $$
DECLARE
    existing_user_id UUID;
BEGIN
    -- Get existing user IDs
    FOR existing_user_id IN 
        SELECT id FROM public.user_profiles LIMIT 2
    LOOP
        -- Initialize achievements for existing users if not already present
        INSERT INTO public.user_achievements (user_id, achievement_type, achievement_name, achievement_description, required_count, is_unlocked, progress)
        VALUES
            (existing_user_id, 'first_meme', 'First Meme', 'Create your first meme', 1, true, 1),
            (existing_user_id, 'viral_creator', 'Viral Creator', 'Get 100 likes on a single meme', 100, false, 1),
            (existing_user_id, 'ai_master', 'AI Master', 'Generate 50 memes with AI', 50, false, 1),
            (existing_user_id, 'social_butterfly', 'Social Butterfly', 'Get 100 followers', 100, false, 0),
            (existing_user_id, 'prolific_creator', 'Prolific Creator', 'Create 100 memes', 100, false, 2)
        ON CONFLICT DO NOTHING;
    END LOOP;
    
    -- Create some sample follow relationships
    INSERT INTO public.user_follows (follower_id, following_id)
    SELECT u1.id, u2.id
    FROM public.user_profiles u1
    CROSS JOIN public.user_profiles u2
    WHERE u1.id != u2.id
    LIMIT 2
    ON CONFLICT DO NOTHING;
END $$;