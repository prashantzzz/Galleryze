// Initialize Supabase client
// Using script version for browser
// Note: in a production setup, we would use a proper frontend build system

// These values should be replaced with actual values from your Supabase project
const supabaseUrl = 'your_supabase_url'; 
const supabaseKey = 'your_supabase_key';

// Create a single supabase client for interacting with your database
const supabase = supabaseClient.createClient(supabaseUrl, supabaseKey);

// Authentication functions
// Create a global object to expose functions
window.galleryzeApi = {};

// Authentication functions
galleryzeApi.signUp = async function(email, password) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
  });
  return { data, error };
};

galleryzeApi.signIn = async function(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  return { data, error };
};

galleryzeApi.signOut = async function() {
  const { error } = await supabase.auth.signOut();
  return { error };
};

galleryzeApi.getCurrentUser = async function() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
};

// Database operations
galleryzeApi.savePhotoCategory = async function(userId, photoId, categories) {
  // First check if entry exists
  const { data: existingData } = await supabase
    .from('photo_categories')
    .select('*')
    .eq('user_id', userId)
    .eq('photo_id', photoId)
    .single();

  if (existingData) {
    // Update existing record
    const { data, error } = await supabase
      .from('photo_categories')
      .update({ categories })
      .eq('user_id', userId)
      .eq('photo_id', photoId);
    return { data, error };
  } else {
    // Insert new record
    const { data, error } = await supabase
      .from('photo_categories')
      .insert([
        { user_id: userId, photo_id: photoId, categories }
      ]);
    return { data, error };
  }
};

galleryzeApi.getPhotoCategories = async function(userId, photoId = null) {
  let query = supabase
    .from('photo_categories')
    .select('*')
    .eq('user_id', userId);
  
  if (photoId) {
    query = query.eq('photo_id', photoId);
  }
  
  const { data, error } = await query;
  return { data, error };
};

galleryzeApi.saveFavorite = async function(userId, photoId, isFavorite) {
  // First check if entry exists
  const { data: existingData } = await supabase
    .from('photo_favorites')
    .select('*')
    .eq('user_id', userId)
    .eq('photo_id', photoId)
    .single();

  if (existingData) {
    // Update existing record
    const { data, error } = await supabase
      .from('photo_favorites')
      .update({ is_favorite: isFavorite })
      .eq('user_id', userId)
      .eq('photo_id', photoId);
    return { data, error };
  } else {
    // Insert new record
    const { data, error } = await supabase
      .from('photo_favorites')
      .insert([
        { user_id: userId, photo_id: photoId, is_favorite: isFavorite }
      ]);
    return { data, error };
  }
};

galleryzeApi.getFavorites = async function(userId) {
  const { data, error } = await supabase
    .from('photo_favorites')
    .select('*')
    .eq('user_id', userId)
    .eq('is_favorite', true);
  
  return { data, error };
};