-- Location: supabase/migrations/20260107001959_memeforge_auth_and_storage.sql
-- Schema Analysis: No existing schema - FRESH_PROJECT
-- Integration Type: Complete authentication and meme cloud storage system
-- Module: Authentication + Meme Storage

-- 1. Types
CREATE TYPE public.user_role AS ENUM ('free', 'premium', 'admin');
CREATE TYPE public.meme_visibility AS ENUM ('private', 'public', 'unlisted');

-- 2. Core Tables - User Profiles
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE,
    avatar_url TEXT,
    role public.user_role DEFAULT 'free'::public.user_role,
    storage_used BIGINT DEFAULT 0,
    storage_limit BIGINT DEFAULT 104857600, -- 100MB for free users
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Meme Storage Tables
CREATE TABLE public.memes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    visibility public.meme_visibility DEFAULT 'private'::public.meme_visibility,
    tags TEXT[] DEFAULT '{}',
    view_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    file_size BIGINT NOT NULL,
    width INT,
    height INT,
    format TEXT,
    ai_generated BOOLEAN DEFAULT false,
    ai_prompt TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Meme likes/favorites
CREATE TABLE public.meme_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    meme_id UUID REFERENCES public.memes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, meme_id)
);

-- Meme collections/albums
CREATE TABLE public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    meme_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Collection items
CREATE TABLE public.collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID REFERENCES public.collections(id) ON DELETE CASCADE,
    meme_id UUID REFERENCES public.memes(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, meme_id)
);

-- 4. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX idx_memes_user_id ON public.memes(user_id);
CREATE INDEX idx_memes_visibility ON public.memes(visibility);
CREATE INDEX idx_memes_created_at ON public.memes(created_at DESC);
CREATE INDEX idx_memes_tags ON public.memes USING gin(tags);
CREATE INDEX idx_meme_likes_user_id ON public.meme_likes(user_id);
CREATE INDEX idx_meme_likes_meme_id ON public.meme_likes(meme_id);
CREATE INDEX idx_collections_user_id ON public.collections(user_id);
CREATE INDEX idx_collection_items_collection_id ON public.collection_items(collection_id);

-- 5. Functions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, username, avatar_url, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'free'::public.user_role)
  );
  RETURN NEW;
END;
$func$;

CREATE OR REPLACE FUNCTION public.update_storage_used()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.user_profiles
    SET storage_used = storage_used + NEW.file_size
    WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.user_profiles
    SET storage_used = GREATEST(0, storage_used - OLD.file_size)
    WHERE id = OLD.user_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$func$;

CREATE OR REPLACE FUNCTION public.update_collection_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.collections
    SET meme_count = meme_count + 1
    WHERE id = NEW.collection_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.collections
    SET meme_count = GREATEST(0, meme_count - 1)
    WHERE id = OLD.collection_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$func$;

CREATE OR REPLACE FUNCTION public.update_like_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.memes
    SET like_count = like_count + 1
    WHERE id = NEW.meme_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.memes
    SET like_count = GREATEST(0, like_count - 1)
    WHERE id = OLD.meme_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$func$;

-- 6. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meme_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_items ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies
-- User profiles - Pattern 1: Core user table
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Public profile viewing
CREATE POLICY "public_view_user_profiles"
ON public.user_profiles
FOR SELECT
TO public
USING (true);

-- Memes - Pattern 2: Simple user ownership + public read
CREATE POLICY "users_manage_own_memes"
ON public.memes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "public_view_public_memes"
ON public.memes
FOR SELECT
TO public
USING (visibility = 'public'::public.meme_visibility);

-- Meme likes - Pattern 2: Simple user ownership
CREATE POLICY "users_manage_own_meme_likes"
ON public.meme_likes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Collections - Pattern 2: Simple user ownership
CREATE POLICY "users_manage_own_collections"
ON public.collections
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "public_view_public_collections"
ON public.collections
FOR SELECT
TO public
USING (is_public = true);

-- Collection items - access through collection ownership
CREATE POLICY "users_manage_own_collection_items"
ON public.collection_items
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.collections c
    WHERE c.id = collection_id AND c.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.collections c
    WHERE c.id = collection_id AND c.user_id = auth.uid()
  )
);

-- 8. Triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_meme_storage_change
  AFTER INSERT OR DELETE ON public.memes
  FOR EACH ROW EXECUTE FUNCTION public.update_storage_used();

CREATE TRIGGER on_collection_item_change
  AFTER INSERT OR DELETE ON public.collection_items
  FOR EACH ROW EXECUTE FUNCTION public.update_collection_count();

CREATE TRIGGER on_like_change
  AFTER INSERT OR DELETE ON public.meme_likes
  FOR EACH ROW EXECUTE FUNCTION public.update_like_count();

-- 9. Mock Data
DO $$
DECLARE
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    meme1_id UUID := gen_random_uuid();
    meme2_id UUID := gen_random_uuid();
    collection1_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'demo@memeforge.ai', crypt('Demo@123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Demo User", "username": "demo_creator"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'premium@memeforge.ai', crypt('Premium@123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Premium User", "username": "meme_master", "role": "premium"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create sample memes
    INSERT INTO public.memes (id, user_id, title, description, image_url, thumbnail_url, visibility, tags, file_size, ai_generated)
    VALUES
        (meme1_id, user1_id, 'My First Meme', 'Created with AI', 
         'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=800', 
         'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=300',
         'public'::public.meme_visibility, ARRAY['funny', 'ai'], 150000, true),
        (meme2_id, user2_id, 'Premium Meme Collection', 'High quality content',
         'https://images.unsplash.com/photo-1613963923668-b7a1cd1e918e?w=800',
         'https://images.unsplash.com/photo-1613963923668-b7a1cd1e918e?w=300',
         'public'::public.meme_visibility, ARRAY['trending', 'premium'], 200000, false);

    -- Create sample collection
    INSERT INTO public.collections (id, user_id, name, description, is_public)
    VALUES (collection1_id, user1_id, 'My Favorites', 'Collection of my best memes', true);

    -- Add meme to collection
    INSERT INTO public.collection_items (collection_id, meme_id)
    VALUES (collection1_id, meme1_id);

    -- Add sample like
    INSERT INTO public.meme_likes (user_id, meme_id)
    VALUES (user2_id, meme1_id);
END $$;