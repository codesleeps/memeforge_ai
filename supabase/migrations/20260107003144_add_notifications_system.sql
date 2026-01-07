-- Location: supabase/migrations/20260107003144_add_notifications_system.sql
-- Schema Analysis: Existing meme engagement tables (meme_likes, meme_comments, meme_remixes)
-- Integration Type: NEW_MODULE - Adding notifications for engagement events
-- Dependencies: user_profiles, memes, meme_likes, meme_comments, meme_remixes

-- ==================== TYPES ====================

CREATE TYPE public.notification_type AS ENUM ('like', 'comment', 'remix');

-- ==================== TABLES ====================

CREATE TABLE public.user_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    notification_type public.notification_type NOT NULL,
    meme_id UUID NOT NULL REFERENCES public.memes(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==================== INDEXES ====================

CREATE INDEX idx_user_notifications_user_id ON public.user_notifications(user_id);
CREATE INDEX idx_user_notifications_meme_id ON public.user_notifications(meme_id);
CREATE INDEX idx_user_notifications_created_at ON public.user_notifications(created_at DESC);
CREATE INDEX idx_user_notifications_is_read ON public.user_notifications(is_read);
CREATE INDEX idx_user_notifications_type ON public.user_notifications(notification_type);

-- ==================== FUNCTIONS ====================

-- Function to create notification for new like
CREATE OR REPLACE FUNCTION public.notify_like()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    meme_owner_id UUID;
BEGIN
    -- Get meme owner
    SELECT user_id INTO meme_owner_id FROM public.memes WHERE id = NEW.meme_id;
    
    -- Only create notification if someone else liked (not self-like)
    IF NEW.user_id != meme_owner_id THEN
        INSERT INTO public.user_notifications (
            user_id,
            notification_type,
            meme_id,
            actor_id,
            content
        ) VALUES (
            meme_owner_id,
            'like'::public.notification_type,
            NEW.meme_id,
            NEW.user_id,
            'liked your meme'
        );
    END IF;
    
    RETURN NEW;
END;
$func$;

-- Function to create notification for new comment
CREATE OR REPLACE FUNCTION public.notify_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    meme_owner_id UUID;
BEGIN
    -- Get meme owner
    SELECT user_id INTO meme_owner_id FROM public.memes WHERE id = NEW.meme_id;
    
    -- Only create notification if someone else commented (not self-comment)
    IF NEW.user_id != meme_owner_id THEN
        INSERT INTO public.user_notifications (
            user_id,
            notification_type,
            meme_id,
            actor_id,
            content
        ) VALUES (
            meme_owner_id,
            'comment'::public.notification_type,
            NEW.meme_id,
            NEW.user_id,
            'commented on your meme'
        );
    END IF;
    
    RETURN NEW;
END;
$func$;

-- Function to create notification for new remix
CREATE OR REPLACE FUNCTION public.notify_remix()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    original_meme_owner_id UUID;
BEGIN
    -- Get original meme owner
    SELECT user_id INTO original_meme_owner_id 
    FROM public.memes 
    WHERE id = NEW.original_meme_id;
    
    -- Only create notification if someone else remixed (not self-remix)
    IF NEW.user_id != original_meme_owner_id THEN
        INSERT INTO public.user_notifications (
            user_id,
            notification_type,
            meme_id,
            actor_id,
            content
        ) VALUES (
            original_meme_owner_id,
            'remix'::public.notification_type,
            NEW.original_meme_id,
            NEW.user_id,
            'remixed your meme'
        );
    END IF;
    
    RETURN NEW;
END;
$func$;

-- ==================== ENABLE RLS ====================

ALTER TABLE public.user_notifications ENABLE ROW LEVEL SECURITY;

-- ==================== RLS POLICIES ====================

-- Users can only view their own notifications
CREATE POLICY "users_view_own_notifications"
ON public.user_notifications
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can only update their own notifications (mark as read)
CREATE POLICY "users_update_own_notifications"
ON public.user_notifications
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- System creates notifications (users cannot insert directly)
CREATE POLICY "system_creates_notifications"
ON public.user_notifications
FOR INSERT
TO authenticated
WITH CHECK (false);

-- ==================== TRIGGERS ====================

-- Trigger for like notifications
CREATE TRIGGER on_like_notification
AFTER INSERT ON public.meme_likes
FOR EACH ROW
EXECUTE FUNCTION public.notify_like();

-- Trigger for comment notifications
CREATE TRIGGER on_comment_notification
AFTER INSERT ON public.meme_comments
FOR EACH ROW
EXECUTE FUNCTION public.notify_comment();

-- Trigger for remix notifications
CREATE TRIGGER on_remix_notification
AFTER INSERT ON public.meme_remixes
FOR EACH ROW
EXECUTE FUNCTION public.notify_remix();