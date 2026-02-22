/**
 * hub.js
 * Controls the Lobby / Portal logic. Fetches user metadata and handles navigation checks.
 */

document.addEventListener("DOMContentLoaded", async () => {
    // Standard Global Session Check
    const { data: { session }, error } = await supabase.auth.getSession();

    if (!session) {
        window.location.href = 'index.html';
        return;
    }

    // Load User Profile Data
    await loadUserProfile(session.user);

    // Logout Handler
    document.getElementById('logoutBtn').addEventListener('click', async () => {
        await supabase.auth.signOut();
        window.location.href = 'index.html';
    });
});

async function loadUserProfile(user) {
    try {
        const { data: profile, error } = await supabase
            .from('profiles')
            .select('full_name, rank, role, store_scope')
            .eq('id', user.id)
            .single();

        if (error) {
            console.error("Error fetching profile:", error.message);
            document.getElementById('userNameDisplay').textContent = user.email.split('@')[0].toUpperCase();
            return;
        }

        // Store profile object globally in window for apps to use if needed
        window.userProfile = profile;

        // Display Name & Role in Navbar
        document.getElementById('userNameDisplay').textContent = profile.full_name;

        let roleString = profile.rank || profile.role.toUpperCase();
        if (profile.role === 'store' && profile.store_scope) {
            roleString += ` (${profile.store_scope})`;
        }
        document.getElementById('userRoleDisplay').textContent = roleString;

    } catch (err) {
        console.error("Failed to parse profile context.", err);
    }
}
