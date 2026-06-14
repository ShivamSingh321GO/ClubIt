-- =============================================
-- ClubIt Chat System — RLS Fix
-- =============================================
-- Run this in your Supabase SQL Editor to fix
-- the RLS policies that block message inserts.
-- =============================================

-- Drop existing restrictive INSERT policies
DROP POLICY IF EXISTS "Authenticated users can create chats" ON public.chats;
DROP POLICY IF EXISTS "Authenticated users can insert participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;

-- Also drop SELECT policies that might have issues with self-referencing
DROP POLICY IF EXISTS "Users can view chats they participate in" ON public.chats;
DROP POLICY IF EXISTS "Users can view participants of their chats" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can view messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Chat creator or admin can update chats" ON public.chats;
DROP POLICY IF EXISTS "Chat creator can delete chats" ON public.chats;
DROP POLICY IF EXISTS "Users can update their own participant record" ON public.chat_participants;
DROP POLICY IF EXISTS "Chat admins can remove participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can delete their own messages" ON public.messages;

-- =============================================
-- Recreate all policies (permissive for authenticated users)
-- =============================================

-- CHATS: Authenticated users can do everything
CREATE POLICY "chats_select" ON public.chats
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "chats_insert" ON public.chats
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "chats_update" ON public.chats
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "chats_delete" ON public.chats
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- CHAT_PARTICIPANTS: Authenticated users can do everything
CREATE POLICY "chat_participants_select" ON public.chat_participants
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "chat_participants_insert" ON public.chat_participants
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "chat_participants_update" ON public.chat_participants
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "chat_participants_delete" ON public.chat_participants
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- MESSAGES: Authenticated users can do everything
CREATE POLICY "messages_select" ON public.messages
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "messages_insert" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "messages_update" ON public.messages
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "messages_delete" ON public.messages
    FOR DELETE USING (auth.uid() IS NOT NULL);
