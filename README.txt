CHANGE UK — GitHub Pages Website
================================

FILES
- index.html      Public website
- member.html     Member-only sign-in/dashboard
- control.html    Hidden admin control room (not linked publicly)
- style.css       Full responsive design + animations
- app.js          Public website logic, policy quiz, joining flow
- control.js      Control room logic
- config.js       Supabase public configuration
- supabase.sql    Database tables + RLS policies + starter manifesto
- logo.png        Your supplied Change UK logo

SETUP
1) Create a Supabase project.
2) Open supabase.sql in the Supabase SQL Editor and run it.
3) In Supabase > Authentication > URL Configuration, add your GitHub Pages URL.
4) Copy Project URL + PUBLIC anon key into config.js. Never put a service-role key in GitHub.
5) Upload every file in this ZIP to the ROOT of your GitHub repository.
6) Enable GitHub Pages for the main branch/root.
7) Join once through the public website using your admin email.
8) In Supabase SQL Editor, run the final commented UPDATE in supabase.sql with your email.
9) Open /control.html and sign in. You can now change MP, councillor and council figures, homepage notice, policies, quiz questions and news.

MEMBERSHIP
- Adults: 18+
- Youth: 12+
- Both are free in this build.
- Supabase Auth handles passwords; the site never stores plaintext passwords.
- Youth accounts use a separate membership type so you can show different member-only content later.

SECURITY
The control page being "hidden" is only cosmetic. Real security comes from Supabase Row Level Security (RLS) and profiles.is_admin. Keep RLS enabled and NEVER publish your Supabase service-role key.

QUIZ
The public policy quiz compares the visitor's 1–5 answers to the manifesto position stored for each published policy. It explicitly presents the result as a comparison, not a voting recommendation.
