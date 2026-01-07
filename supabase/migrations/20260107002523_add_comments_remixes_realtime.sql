-- Location: supabase/migrations/20260107002523_add_comments_remixes_realtime.sql
-- Schema Analysis: Existing memes, meme_likes, user_profiles tables
-- Integration Type: Addition - Adding comments and remixes functionality
-- Dependencies: memes (id), user_profiles (id)

-- 1. Add count columns to existing memes table
ALTER TABLE public.memes
ADD COLUMN IF NOT EXISTS comment_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS remix_count INTEGER DEFAULT 0;

-- 2. Create meme_comments table
CREATE TABLE public.meme_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meme_id UUID NOT NULL REFERENCES public.memes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create meme_remixes table
CREATE TABLE public.meme_remixes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_meme_id UUID NOT NULL REFERENCES public.memes(id) ON DELETE CASCADE,
    remixed_meme_id UUID NOT NULL REFERENCES public.memes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_remix UNIQUE(original_meme_id, remixed_meme_id)
);

-- 4. Create indexes for performance
CREATE INDEX idx_meme_comments_meme_id ON public.meme_comments(meme_id);
CREATE INDEX idx_meme_comments_user_id ON public.meme_comments(user_id);
CREATE INDEX idx_meme_comments_created_at ON public.meme_comments(created_at);
CREATE INDEX idx_meme_remixes_original_meme_id ON public.meme_remixes(original_meme_id);
CREATE INDEX idx_meme_remixes_remixed_meme_id ON public.meme_remixes(remixed_meme_id);
CREATE INDEX idx_meme_remixes_user_id ON public.meme_remixes(user_id);

-- 5. Create trigger functions for auto-updating counts
CREATE OR REPLACE FUNCTION public.update_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.memes
        SET comment_count = comment_count + 1
        WHERE id = NEW.meme_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.memes
        SET comment_count = GREATEST(0, comment_count - 1)
        WHERE id = OLD.meme_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$func$;

CREATE OR REPLACE FUNCTION public.update_remix_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.memes
        SET remix_count = remix_count + 1
        WHERE id = NEW.original_meme_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.memes
        SET remix_count = GREATEST(0, remix_count - 1)
        WHERE id = OLD.original_meme_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$func$;

-- 6. Enable RLS
ALTER TABLE public.meme_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meme_remixes ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies
-- Comments: Users can read all public meme comments, manage their own
CREATE POLICY "public_read_comments"
ON public.meme_comments
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_comments"
ON public.meme_comments
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Remixes: Users can read all remixes, create their own remixes
CREATE POLICY "public_read_remixes"
ON public.meme_remixes
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_create_remixes"
ON public.meme_remixes
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_remixes"
ON public.meme_remixes
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- 8. Create triggers
CREATE TRIGGER on_comment_change
AFTER INSERT OR DELETE ON public.meme_comments
FOR EACH ROW
EXECUTE FUNCTION public.update_comment_count();

CREATE TRIGGER on_remix_change
AFTER INSERT OR DELETE ON public.meme_remixes
FOR EACH ROW
EXECUTE FUNCTION public.update_remix_count();

-- 9. Mock data (references existing memes and users)
DO $$
DECLARE
    existing_meme_id UUID;
    existing_user_id UUID;
    second_user_id UUID;
BEGIN
    -- Get existing meme and user IDs
    SELECT id INTO existing_meme_id FROM public.memes WHERE visibility = 'public' LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1 OFFSET 0;
    SELECT id INTO second_user_id FROM public.user_profiles LIMIT 1 OFFSET 1;
    
    -- Add sample comments if data exists
    IF existing_meme_id IS NOT NULL AND existing_user_id IS NOT NULL THEN
        INSERT INTO public.meme_comments (meme_id, user_id, content)
        VALUES
            (existing_meme_id, existing_user_id, 'This is hilarious! Love the creativity.'),
            (existing_meme_id, second_user_id, 'Best meme of the day!');
    END IF;
END $$;