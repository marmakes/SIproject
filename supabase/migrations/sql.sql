-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    user_type TEXT CHECK (user_type IN ('client', 'advocate')) NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Advocate profiles (detailed information)
CREATE TABLE public.advocate_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    bar_number TEXT UNIQUE,
    specialization TEXT[],
    years_of_experience INTEGER,
    hourly_rate DECIMAL(10,2),
    languages TEXT[],
    education JSONB[],
    certifications JSONB[],
    bio TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    office_address TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    zip_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Client profiles (additional client info)
CREATE TABLE public.client_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    date_of_birth DATE,
    address TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    zip_code TEXT,
    preferred_language TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Case categories
CREATE TABLE public.case_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cases table
CREATE TABLE public.cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_number TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    client_id UUID REFERENCES public.client_profiles(id) ON DELETE CASCADE NOT NULL,
    advocate_id UUID REFERENCES public.advocate_profiles(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.case_categories(id),
    status TEXT CHECK (status IN ('pending', 'active', 'on_hold', 'closed', 'archived')) DEFAULT 'pending',
    priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
    filed_date DATE,
    hearing_date TIMESTAMP WITH TIME ZONE,
    verdict TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Case documents storage
CREATE TABLE public.case_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    file_type TEXT,
    uploaded_by UUID REFERENCES auth.users(id),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Appointments/Consultations
CREATE TABLE public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE,
    client_id UUID REFERENCES public.client_profiles(id) NOT NULL,
    advocate_id UUID REFERENCES public.advocate_profiles(id) NOT NULL,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    status TEXT CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'rescheduled')) DEFAULT 'scheduled',
    meeting_link TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages between clients and advocates
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    attachments TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews and ratings
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE UNIQUE,
    client_id UUID REFERENCES public.client_profiles(id) NOT NULL,
    advocate_id UUID REFERENCES public.advocate_profiles(id) NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    comment TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Case timeline/activity log
CREATE TABLE public.case_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE NOT NULL,
    activity_type TEXT NOT NULL,
    description TEXT,
    created_by UUID REFERENCES auth.users(id),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Favorite advocates for clients
CREATE TABLE public.favorite_advocates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES public.client_profiles(id) ON DELETE CASCADE NOT NULL,
    advocate_id UUID REFERENCES public.advocate_profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(client_id, advocate_id)
);

-- Create indexes for better performance
CREATE INDEX idx_cases_client_id ON public.cases(client_id);
CREATE INDEX idx_cases_advocate_id ON public.cases(advocate_id);
CREATE INDEX idx_cases_status ON public.cases(status);
CREATE INDEX idx_appointments_advocate_id ON public.appointments(advocate_id);
CREATE INDEX idx_appointments_scheduled_time ON public.appointments(scheduled_time);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX idx_reviews_advocate_id ON public.reviews(advocate_id);

-- Row Level Security (RLS) Policies

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Anyone can view advocate profiles" ON public.profiles FOR SELECT USING (user_type = 'advocate');

-- Advocate profiles
ALTER TABLE public.advocate_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view advocate profiles" ON public.advocate_profiles FOR SELECT USING (true);
CREATE POLICY "Advocates can update their own profile" ON public.advocate_profiles FOR UPDATE USING (auth.uid() = user_id);

-- Cases
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Clients can view their own cases" ON public.cases FOR SELECT USING (auth.uid() IN (SELECT user_id FROM client_profiles WHERE id = client_id));
CREATE POLICY "Advocates can view cases assigned to them" ON public.cases FOR SELECT USING (auth.uid() IN (SELECT user_id FROM advocate_profiles WHERE id = advocate_id));
CREATE POLICY "Clients can create cases" ON public.cases FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM client_profiles WHERE id = client_id));
CREATE POLICY "Advocates can update assigned cases" ON public.cases FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM advocate_profiles WHERE id = advocate_id));

-- Messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view messages they sent or received" ON public.messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can send messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view public reviews" ON public.reviews FOR SELECT USING (is_public = true);
CREATE POLICY "Clients can create reviews for their cases" ON public.reviews FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM client_profiles WHERE id = client_id));

-- Functions and Triggers

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_advocate_profiles_updated_at BEFORE UPDATE ON public.advocate_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cases_updated_at BEFORE UPDATE ON public.cases FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Calculate advocate rating
CREATE OR REPLACE FUNCTION update_advocate_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.advocate_profiles
    SET 
        rating = (SELECT AVG(rating) FROM public.reviews WHERE advocate_id = NEW.advocate_id),
        total_reviews = (SELECT COUNT(*) FROM public.reviews WHERE advocate_id = NEW.advocate_id)
    WHERE id = NEW.advocate_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_rating_after_review
AFTER INSERT OR UPDATE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION update_advocate_rating();

-- Insert sample case categories
INSERT INTO public.case_categories (name, description) VALUES
('Criminal Law', 'Criminal defense and prosecution cases'),
('Family Law', 'Divorce, child custody, adoption cases'),
('Corporate Law', 'Business formation, contracts, mergers'),
('Civil Litigation', 'Lawsuits, disputes, claims'),
('Intellectual Property', 'Patents, trademarks, copyrights'),
('Real Estate', 'Property disputes, transactions, leases'),
('Immigration', 'Visa, citizenship, deportation cases'),
('Employment Law', 'Workplace disputes, labor rights'),
('Tax Law', 'Tax disputes, planning, compliance'),
('Personal Injury', 'Accidents, injury claims, compensation');