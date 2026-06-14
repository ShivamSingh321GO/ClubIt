-- =============================================
-- ClubIt Chat System — Supabase Migration
-- =============================================
-- Run this in your Supabase SQL Editor.
-- Creates: chats, chat_participants, messages
-- Plus indexes and RLS policies.
-- =============================================

-- 1. ENUM for chat type
DO $$ BEGIN
    CREATE TYPE chat_type AS ENUM ('individual', 'group', 'event');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. ENUM for participant role
DO $$ BEGIN
    CREATE TYPE chat_participant_role AS ENUM ('admin', 'member');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 3. ENUM for participant status
DO $$ BEGIN
    CREATE TYPE chat_participant_status AS ENUM ('accepted', 'pending');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================
-- TABLE: chats
-- =============================================
CREATE TABLE IF NOT EXISTS public.chats (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type            chat_type NOT NULL DEFAULT 'individual',
    name            text,
    description     text,
    icon            text,
    club_id         uuid REFERENCES public.clubs(id) ON DELETE SET NULL,
    parent_chat_id  uuid REFERENCES public.chats(id) ON DELETE CASCADE,
    created_by      uuid NOT NULL REFERENCES public.users(id),
    created_at      timestamptz DEFAULT now()
);

-- =============================================
-- TABLE: chat_participants
-- =============================================
CREATE TABLE IF NOT EXISTS public.chat_participants (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id         uuid NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    user_id         uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role            chat_participant_role NOT NULL DEFAULT 'member',
    status          chat_participant_status NOT NULL DEFAULT 'accepted',
    is_pinned       boolean NOT NULL DEFAULT false,
    is_archived     boolean NOT NULL DEFAULT false,
    is_muted        boolean NOT NULL DEFAULT false,
    last_read_at    timestamptz DEFAULT now(),
    joined_at       timestamptz DEFAULT now(),

    UNIQUE (chat_id, user_id)
);

-- =============================================
-- TABLE: messages
-- =============================================
CREATE TABLE IF NOT EXISTS public.messages (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id         uuid NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id       uuid NOT NULL REFERENCES public.users(id),
    content         text NOT NULL,
    attachment_url  text,
    created_at      timestamptz DEFAULT now()
);

-- =============================================
-- INDEXES for performance
-- =============================================
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON public.chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_id ON public.chat_participants(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chats_parent_chat_id ON public.chats(parent_chat_id);
CREATE INDEX IF NOT EXISTS idx_chats_created_by ON public.chats(created_by);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

-- Enable RLS on all chat tables
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- CHATS: Users can see chats they participate in
CREATE POLICY "Users can view chats they participate in"
    ON public.chats FOR SELECT
    USING (
        id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid()
        )
        OR
        parent_chat_id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid()
        )
    );

-- CHATS: Authenticated users can create chats
CREATE POLICY "Authenticated users can create chats"
    ON public.chats FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- CHATS: Chat creator or admin can update
CREATE POLICY "Chat creator or admin can update chats"
    ON public.chats FOR UPDATE
    USING (
        created_by = auth.uid()
        OR id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- CHATS: Chat creator can delete
CREATE POLICY "Chat creator can delete chats"
    ON public.chats FOR DELETE
    USING (created_by = auth.uid());

-- CHAT_PARTICIPANTS: Users can view participants of their chats
CREATE POLICY "Users can view participants of their chats"
    ON public.chat_participants FOR SELECT
    USING (
        chat_id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid()
        )
    );

-- CHAT_PARTICIPANTS: Authenticated users can insert participants
CREATE POLICY "Authenticated users can insert participants"
    ON public.chat_participants FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- CHAT_PARTICIPANTS: Users can update their own participant record
CREATE POLICY "Users can update their own participant record"
    ON public.chat_participants FOR UPDATE
    USING (user_id = auth.uid());

-- CHAT_PARTICIPANTS: Chat admins can delete participants
CREATE POLICY "Chat admins can remove participants"
    ON public.chat_participants FOR DELETE
    USING (
        user_id = auth.uid()
        OR chat_id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- MESSAGES: Users can view messages in their chats
CREATE POLICY "Users can view messages in their chats"
    ON public.messages FOR SELECT
    USING (
        chat_id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid()
        )
    );

-- MESSAGES: Participants can insert messages
CREATE POLICY "Participants can send messages"
    ON public.messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND chat_id IN (
            SELECT chat_id FROM public.chat_participants
            WHERE user_id = auth.uid() AND status = 'accepted'
        )
    );

-- MESSAGES: Sender can delete their own messages
CREATE POLICY "Users can delete their own messages"
    ON public.messages FOR DELETE
    USING (sender_id = auth.uid());

-- =============================================
-- Enable Realtime for messages table
-- =============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_participants;
